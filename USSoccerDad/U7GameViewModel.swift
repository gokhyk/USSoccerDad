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
        intensity: SubstitutionIntensity,
        availableIds: Set<UUID>
    ) {
        let config = GameConfig(
            minutesPerPeriod: 10,
            periods: 4,
            playersOnField: 4,
            minPlayersToStart: 3
        )
        
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
//    
//    func advanceOneMinute() {
//        guard var state = gameState else { return }
//        _ = engine.advanceOneMinute(state: &state)
//        gameState = state
//    }
//    
//    func simulateFullGame() {
//        guard var state = gameState else { return }
//        let final = engine.simulateFullGame(state: &state)
//        gameState = final
//    }
//    
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

        // ✅ Game clock always runs
        let oldSeconds = gameClockSeconds
        gameClockSeconds += delta

        // ✅ Countdown also runs (and runs faster when delta > 1)
        if var p = pendingSub {
            p.secondsRemaining = max(0, p.secondsRemaining - delta)
            pendingSub = p

            // ✅ IMPORTANT: while countdown is active, we do NOT advance the engine minutes,
            // because lineup changes must wait for coach OK.
            return
        }

        // 🟢 Only when not in countdown: advance engine minutes on minute boundaries
        let oldMinute = oldSeconds / 60
        let newMinute = gameClockSeconds / 60
        let minutesToAdvance = newMinute - oldMinute

        if minutesToAdvance > 0 {
            for _ in 0..<minutesToAdvance {
                _ = engine.advanceOneMinute(state: &state)
                gameState = state

                // If checkpoint minute hit, start countdown and stop advancing further
                if shouldTriggerCheckpoint(state: state) {
                    startPendingSubstitution(state: state)
                    break
                }
            }
        }
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
