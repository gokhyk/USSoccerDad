//
//  U7GameViewModel.swift
//  USSoccerDad
//
//  Rewritten with proper quarter handling
//

import Foundation

struct PendingSubstitution {
    let scheduledAtSecond: Int
    var secondsRemaining: Int
    let pairs: [(in: PlayerID, out: PlayerID)]
    
    var inIDs: [PlayerID] {
        pairs.map { $0.in }
    }
    
    var outIDs: [PlayerID] {
        pairs.map { $0.out }
    }
}

@MainActor
final class U7GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var players: [Player] = []
    
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var gameClockSeconds: Int = 0
    @Published var pendingSub: PendingSubstitution? = nil
    @Published var speedMultiplier: Int = 1
    
    let teamId: UUID
    private let playerRepo: PlayerRepository
    private let engine: U7LineupEngine
    
    // Constants
    private let substitutionWarningSeconds = 60  // Warn 60 seconds before sub
    
    init(
        teamId: UUID,
        playerRepo: PlayerRepository,
        engine: U7LineupEngine = DefaultU7LineupEngine()
    ) {
        self.teamId = teamId
        self.playerRepo = playerRepo
        self.engine = engine
    }
    
    // MARK: - Setup
    
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
        self.gameClockSeconds = 0
        self.isRunning = false
        self.isPaused = false
        self.pendingSub = nil
    }
    
    // MARK: - Game Control
    
    func startWhistle() {
        guard gameState != nil else { return }
        
        isRunning = true
        isPaused = false
        pendingSub = nil
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func endCurrentQuarter() {
        guard var state = gameState else { return }
        
        // Stop the clock
        isRunning = false
        pendingSub = nil
        
        // Clear any pending subs
        gameClockSeconds = 0
        
        // Log the quarter break and advance
        engine.advanceToNextQuarter(state: &state)
        
        // The engine handles setting .finished if needed
        
        gameState = state
    }
    
    // MARK: - Time Management
    
    func tickOneSecond() {
        guard isRunning, !isPaused else { return }
        guard var state = gameState else { return }
        guard state.status == .normalGame || state.status == .noSubGame else { return }
        
        let delta = speedMultiplier
        
        // Check if we've reached end of quarter
        let quarterDurationSeconds = state.config.minutesPerPeriod * 60
        if gameClockSeconds >= quarterDurationSeconds {
            gameClockSeconds = quarterDurationSeconds
            isRunning = false
            gameState = state
            return
        }
        
        // Advance clock (clamped to quarter duration)
        let oldSeconds = gameClockSeconds
        let newSeconds = min(oldSeconds + delta, quarterDurationSeconds)
        let actualDelta = newSeconds - oldSeconds
        gameClockSeconds = newSeconds
        
        // Update game state seconds
        state.totalSecondsElapsed += actualDelta
        
        // Update player playing time
        for i in state.players.indices {
            if state.players[i].isOnField {
                state.players[i].secondsPlayedThisGame += actualDelta
                state.players[i].continuousSecondsPlayedThisGame += actualDelta
            }
        }
        
        // Handle pending substitution countdown
        if var pending = pendingSub {
            pending.secondsRemaining -= actualDelta
            pendingSub = pending
        }
        
        // Check if it's time to schedule a substitution
        // BUT NOT if we're at or near quarter end
        let timeRemainingInQuarter = quarterDurationSeconds - gameClockSeconds
        
        if state.status == .normalGame && pendingSub == nil && timeRemainingInQuarter > substitutionWarningSeconds {
            if state.totalSecondsElapsed >= state.nextSubAtSecond - substitutionWarningSeconds {
                scheduleSubstitution(state: state)
            }
        }
        
        // Stop at end of quarter
        if gameClockSeconds >= quarterDurationSeconds {
            isRunning = false
        }
        
        gameState = state
    }
    
    // MARK: - Substitutions
    
    private func scheduleSubstitution(state: GameState) {
        guard pendingSub == nil else { return }
        guard state.status == .normalGame else { return }
        
        let proposal = engine.proposeSubstitution(state: state)
        guard !proposal.inIDs.isEmpty else { return }
        
        let pairs = zip(proposal.inIDs, proposal.outIDs).map { (in: $0, out: $1) }
        
        let timeUntilSub = state.nextSubAtSecond - state.totalSecondsElapsed
        
        pendingSub = PendingSubstitution(
            scheduledAtSecond: state.nextSubAtSecond,
            secondsRemaining: timeUntilSub,
            pairs: pairs
        )
    }
    
    func confirmSubstitution() {
        guard var state = gameState else { return }
        guard let pending = pendingSub else { return }
        
        engine.applySubstitution(
            state: &state,
            inIDs: pending.inIDs,
            outIDs: pending.outIDs
        )
        
        gameState = state
        pendingSub = nil
    }
    
    // MARK: - Injury Management
    
    func markInjured(_ playerId: PlayerID) {
        guard var state = gameState else { return }
        engine.markInjured(playerId: playerId, state: &state)
        gameState = state
    }
    
    func markRecovered(_ playerId: PlayerID) {
        guard var state = gameState else { return }
        engine.markRecovered(playerId: playerId, state: &state)
        gameState = state
    }
    
    // MARK: - Game Completion
    
    func applyGameMinutesToPlayers() async {
        guard let state = gameState, state.status == .finished else { return }
        
        var updatedPlayers = players
        
        // Calculate absent player credit
        let totalGameSeconds = state.config.playersOnField * 
                               state.config.minutesPerPeriod * 
                               state.config.periods * 60
        let eligibleCount = state.players.filter { $0.isAvailable && !$0.isInjured }.count
        let absentCreditMinutes = eligibleCount > 0 
            ? (totalGameSeconds / 60) / eligibleCount 
            : 0
        
        for i in updatedPlayers.indices {
            let playerId = updatedPlayers[i].id
            
            if let runtime = state.players.first(where: { $0.id == playerId }) {
                let minutesToAdd: Int
                
                if runtime.isAvailable {
                    minutesToAdd = runtime.minutesThisGame
                } else {
                    minutesToAdd = absentCreditMinutes
                }
                
                if minutesToAdd > 0 {
                    updatedPlayers[i].totalMinutesPlayed += minutesToAdd
                    
                    do {
                        try await playerRepo.upsert(player: updatedPlayers[i])
                    } catch {
                        print("Failed to update player \(updatedPlayers[i].name): \(error)")
                    }
                }
            }
        }
        
        self.players = updatedPlayers
    }
    
    // MARK: - Computed Properties
    
    var gameClockText: String {
        let minutes = gameClockSeconds / 60
        let seconds = gameClockSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var isAtQuarterEnd: Bool {
        guard let state = gameState else { return false }
        let quarterDuration = state.config.minutesPerPeriod * 60
        return gameClockSeconds >= quarterDuration
    }
    
    func previewNextQuarterStarters() -> [PlayerGameRuntime] {
        guard let state = gameState else { return [] }
        
        var eligible = state.players.filter { $0.isAvailable && !$0.isInjured }
        
        // Shuffle for fairness
        eligible.shuffle()
        
        // Sort by least total seconds played
        eligible.sort { p1, p2 in
            if p1.secondsPlayedThisGame != p2.secondsPlayedThisGame {
                return p1.secondsPlayedThisGame < p2.secondsPlayedThisGame
            }
            // Tie-breaker: season minutes
            return p1.seasonMinutesBeforeGame < p2.seasonMinutesBeforeGame
        }
        
        return eligible
    }
}

// MARK: - Helper Extensions

extension Array where Element == Player {
    func seasonSnapshotsForLineup() -> [PlayerSeasonSnapshot] {
        map { $0.seasonSnapshotForLineup }
    }
    
    func availabilityList(availableIds: Set<UUID>) -> [PlayerAvailability] {
        map { player in
            player.availability(isAvailable: availableIds.contains(player.id))
        }
    }
}
