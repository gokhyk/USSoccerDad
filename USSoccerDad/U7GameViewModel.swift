//
//  U7GameViewModel.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/1/25.
//

struct PendingSubstitution {
    let scheduledAtMinute: Int
    let countdownSeconds: Int          // e.g., 60
    var secondsRemaining: Int
    let inIDs: [PlayerID]
    let outIDs: [PlayerID]
    let pairs: [(in: PlayerID, out: PlayerID)] // “in replaces out”
}

import Foundation

struct EndOfGameReport {
    struct LineItem: Identifiable {
        let id: UUID
        let name: String
        let minutes: Int
        let seasonBefore: Int
    }

    let minutesPlayed: [LineItem]
    let notAvailable: [LineItem]
    let injured: [LineItem]   // you’ll fill this once you track injuries
}

@MainActor
final class U7GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var players: [Player] = []
    
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var gameClockSeconds: Int = 0
    @Published var pendingSub: PendingSubstitution? = nil

    @Published var speedMultiplier: Int = 1   // 1, 5, 10
    
    @Published var autoApplyWhenCountdownHitsZero: Bool = false


    
    let teamId: UUID
    private let playerRepo: PlayerRepository
    private let engine: U7LineupEngine
    
    init(
        teamId: UUID,
        playerRepo: PlayerRepository,
        engine: U7LineupEngine = DefaultU7LineupEngine()
    ) {
        self.teamId = teamId
        self.playerRepo = playerRepo
        self.engine = engine
    }
    
    func loadPlayers() async {
        do {
            let result = try await playerRepo.listPlayers(teamId: teamId, search: nil)
            self.players = result.sorted { a, b in
                let ja = a.jerseyNumber ?? Int.max
                let jb = b.jerseyNumber ?? Int.max
                if ja != jb { return ja < jb }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch {
            print("Failed to load players: \(error)")
        }
    }
    
    func startGame(
        config: GameConfig,
        intensity: SubstitutionIntensity,
        availableIds: Set<UUID>
    ) {        
        let snapshots = players.seasonSnapshotsForLineup()
        let availability = players.availabilityList(availableIds: availableIds)
        
        let state = engine.initializeGame(
            config: config,
            intensity: intensity,
            roster: snapshots,
            availability: availability
        )
        
        self.gameState = state
    }

    func applyGameMinutesToPlayers() async {
        guard let state = gameState, state.status == .finished else { return }
        var updatedPlayers = players

        let totalGameMinutes = state.config.playersOnField * (state.config.minutesPerPeriod * state.config.periods)
        let availableCount = state.players.filter { $0.isAvailable && !$0.isInjured }.count
        let absentCredit = availableCount > 0
            ? Int((Double(totalGameMinutes) / Double(availableCount)).rounded())
            : 0

        for i in updatedPlayers.indices {
            let id = updatedPlayers[i].id

            if let runtime = state.players.first(where: { $0.id == id }) {
                let addMinutes: Int

                if runtime.isAvailable {
                    addMinutes = runtime.minutesThisGame
                } else {
                    addMinutes = absentCredit
                }

                if addMinutes > 0 {
                    updatedPlayers[i].totalMinutesPlayed += addMinutes
                    do {
                        try await playerRepo.upsert(player: updatedPlayers[i])
                    } catch {
                        print("Failed to upsert player \(updatedPlayers[i].name): \(error)")
                    }
                }
            }
        }
        self.players = updatedPlayers
    }
    
    func markInjured(_ id: PlayerID) {
        guard var state = gameState else { return }
        // engine needs to be `var` or the methods above should be non-mutating; easiest is to make engine var in VM
        // or make markInjured/markRecovered non-mutating helpers inside the struct.
        //(engine as? DefaultU7LineupEngine)?.markInjured(playerId: id, state: &state)
        _ = engine.markInjured(playerId: id, state: &state)
        gameState = state
    }

    func markRecovered(_ id: PlayerID) {
        guard var state = gameState else { return }
        //(engine as? DefaultU7LineupEngine)?.markRecovered(playerId: id, state: &state)
        _ = engine.markRecovered(playerId: id, state: &state)
        gameState = state
    }

    func startWhistle() {
        isRunning = true
        isPaused = false
        gameClockSeconds = 0
        pendingSub = nil
    }

    func tickOneSecond() {
        guard isRunning, !isPaused else { return }
        guard var state = gameState else { return }

        let delta = max(1, speedMultiplier)

        // ---- Stop at end of period/half (clamp) ----
        let periodDurationSec = state.config.minutesPerPeriod * 60
        if gameClockSeconds >= periodDurationSec {
            gameClockSeconds = periodDurationSec
            isRunning = false
            gameState = state
            return
        }

        // ---- Advance wall clock seconds (clamped) ----
        let oldSeconds = gameClockSeconds
        let newSeconds = min(oldSeconds + delta, periodDurationSec)
        let actualDelta = newSeconds - oldSeconds
        gameClockSeconds = newSeconds
        
        // ---- Per-second playtime stats ----
        if actualDelta > 0 {
            for i in state.players.indices {
                if state.players[i].isOnField {
                    state.players[i].secondsPlayedThisGame += actualDelta
                    state.players[i].continuousSecondsPlayedThisGame += actualDelta
                }
            }
        }
        


        // ---- Countdown handling (DO NOT return; do not freeze engine) ----
        if var p = pendingSub {
            // If auto-apply is OFF, let it go negative.
            // If auto-apply is ON, apply when it crosses <= 0.
            p.secondsRemaining -= actualDelta

            if autoApplyWhenCountdownHitsZero, p.secondsRemaining <= 0 {
                // Apply automatically at the moment we hit/passed zero.
                engine.applySubstitution(
                    state: &state,
                    inIDs: p.inIDs,
                    outIDs: p.outIDs,
                    timeMinute: state.totalMinutesElapsed
                )
                pendingSub = nil
            } else {
                pendingSub = p
            }
        }

        // ---- Advance engine on minute boundaries (even during pendingSub) ----
        let oldMinute = oldSeconds / 60
        let newMinute = newSeconds / 60
        let minutesToAdvance = newMinute - oldMinute

        if minutesToAdvance > 0 {
            for _ in 0..<minutesToAdvance {
                _ = engine.advanceOneMinute(state: &state)

                // Only start a new pending sub if none is pending already
                if pendingSub == nil, shouldTriggerCheckpoint(state: state) {
                    startPendingSubstitution(state: state)
                }
            }
        }

        // ---- Stop at end (in case we hit exactly) ----
        if gameClockSeconds >= periodDurationSec {
            isRunning = false
            // keep pendingSub as-is so coach can still hit OK if desired
        }

        for i in state.players.indices {
            state.players[i].minutesThisGame = state.players[i].secondsPlayedThisGame / 60
            state.players[i].continuousMinutesThisGame = state.players[i].continuousSecondsPlayedThisGame / 60
        }

        gameState = state
    }



    func confirmSubstitutionOK() {
        guard var state = gameState else { return }
        guard let p = pendingSub else { return }

        engine.applySubstitution(
            state: &state,
            inIDs: p.inIDs,
            outIDs: p.outIDs,
            timeMinute: state.totalMinutesElapsed
        )

        gameState = state
        pendingSub = nil
    }

    func togglePause() {
        isPaused.toggle()
    }


    
    var gameClockText: String {
        let m = gameClockSeconds / 60
        let s = gameClockSeconds % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    private func checkpointminutesPerPeriod(
        intensity: SubstitutionIntensity,
        minutesPerPeriod: Int
    ) -> Set<Int> {
        // minuteInQuarter is 0...(minutesPerPeriod-1) AFTER your advance logic.
        // With your current engine, checkpoint at 2 means "after 2 minutes played".
        switch intensity {
        case .frequent:
            return [2, 4, 6, 8].filter { $0 < minutesPerPeriod }.asSet()
        case .balanced:
            return [3, 6, 9].filter { $0 < minutesPerPeriod }.asSet()
        case .infrequent:
            return [5].filter { $0 < minutesPerPeriod }.asSet()
        }
    }

    private func shouldTriggerCheckpoint(state: GameState) -> Bool {
        guard state.status == .normalGame else { return false }
        let checkpoints = checkpointminutesPerPeriod(
            intensity: state.intensity,
            minutesPerPeriod: state.config.minutesPerPeriod
        )
        return checkpoints.contains(state.minuteInQuarter)
    }

    private func startPendingSubstitution(state: GameState) {
        guard state.status == .normalGame else { return }

        let proposal = engine.proposeSubstitution(state: state)
        guard !proposal.inIDs.isEmpty else { return }

        let pairs = zip(proposal.inIDs, proposal.outIDs).map { (in: $0.0, out: $0.1) }

        pendingSub = PendingSubstitution(
            scheduledAtMinute: state.totalMinutesElapsed,
            countdownSeconds: 60,
            secondsRemaining: 60,
            inIDs: proposal.inIDs,
            outIDs: proposal.outIDs,
            pairs: pairs
        )
    }

}

private extension Array where Element == Int {
    func asSet() -> Set<Int> { Set(self) }
}
