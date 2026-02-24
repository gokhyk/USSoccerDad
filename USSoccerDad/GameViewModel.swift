//
//  GameViewModel.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation
import SwiftUI
import Combine
import UIKit

/// Represents a forced substitution initiated by the coach pressing X on a field player
struct ForcedSubProposal {
    let playerOutId: UUID
    let playerOutName: String
    let proposedPlayerInId: UUID
    let proposedPlayerInName: String
    /// Countdown seconds remaining (-1 = no auto-complete, 0+ = counting down)
    var countdownSeconds: Int
    /// True when the injured player was the goalkeeper — replacement should inherit GK role
    var isReplacingGoalkeeper: Bool = false
}

@MainActor
class GameViewModel: ObservableObject {
    let teamId: UUID
    private let playerRepo: PlayerRepository
    
    @Published var players: [Player] = []
    @Published var session: GameSession? {
        didSet {
            // When session changes, subscribe to its changes
            sessionCancellable?.cancel()
            sessionCancellable = session?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Timer for game clock
    private var gameTimer: Timer?
    private var sessionCancellable: AnyCancellable?

    // Background/foreground tracking
    private var backgroundedAt: Date?
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    
    // Auto-complete substitution setting
    @Published var autoCompleteSubstitutions = false
    
    // Auto-start after break setting
    @Published var autoStartAfterBreak = false
    
    // Skip break countdown setting
    @Published var skipBreakCountdown = false

    // Speed multiplier for testing (1 = normal, 5 = 5x fast)
    @Published var speedMultiplier: Int = 1

    // Forced substitution proposal (coach pressed X on a field player)
    @Published var forcedSubProposal: ForcedSubProposal?
    
    // Pending game configuration (for delayed initialization)
    var pendingGameConfig: (gameId: UUID, config: GameConfig, intensity: SubstitutionIntensity, availablePlayerIds: Set<UUID>)?
    
    init(teamId: UUID, playerRepo: PlayerRepository) {
        self.teamId = teamId
        self.playerRepo = playerRepo
        subscribeToAppLifecycle()
    }

    deinit {
        if let obs = backgroundObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = foregroundObserver { NotificationCenter.default.removeObserver(obs) }
    }

    private func subscribeToAppLifecycle() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.backgroundedAt = Date()
            self?.stopTimer()
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleForeground()
            }
        }
    }

    private func handleForeground() {
        guard let session = session,
              let backgroundedAt = backgroundedAt else { return }
        let missedSeconds = max(0, Int(Date().timeIntervalSince(backgroundedAt)))
        self.backgroundedAt = nil
        guard missedSeconds > 0 else { return }

        switch session.phase {
        case .running, .pendingSubstitution:
            applyMissedGameSeconds(missedSeconds)
            if case .running = session.phase { startTimer() }
            else if case .pendingSubstitution = session.phase { startTimer() }
        case .periodBreak(let periodNumber, let breakSeconds):
            applyMissedBreakSeconds(missedSeconds, periodNumber: periodNumber, totalBreakSeconds: breakSeconds)
            if case .periodBreak = session.phase { startTimer() }
        default:
            break
        }
    }

    private func applyMissedGameSeconds(_ missed: Int) {
        guard let session = session else { return }
        let remaining = session.config.periodSeconds - session.periodElapsedSeconds
        let effective = min(missed, remaining)

        session.periodElapsedSeconds += effective
        for i in 0..<session.playerStats.count {
            if session.playerStats[i].isOnField && !session.playerStats[i].leftEarly {
                session.playerStats[i].secondsPlayed += effective
                session.playerStats[i].continuousSecondsPlayed += effective
            }
        }
        updateAbsentPlayerTimes()

        if session.periodElapsedSeconds >= session.config.periodSeconds {
            handlePeriodEnd()
        } else {
            checkForUpcomingSubstitution()
        }
    }

    private func applyMissedBreakSeconds(_ missed: Int, periodNumber: Int, totalBreakSeconds: Int) {
        guard let session = session else { return }
        session.breakElapsedSeconds = min(session.breakElapsedSeconds + missed, totalBreakSeconds)

        if session.breakElapsedSeconds >= totalBreakSeconds {
            if skipBreakCountdown || autoStartAfterBreak {
                startPeriod()
            } else {
                stopTimer()
            }
        }
    }
    
    // MARK: - Setup
    
    func loadPlayers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            players = try await playerRepo.listPlayers(teamId: teamId, search: nil)
        } catch {
            errorMessage = "Failed to load players: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Game Start
    
    func startGame(
        gameId: UUID,
        config: GameConfig,
        intensity: SubstitutionIntensity,
        availablePlayerIds: Set<UUID>
    ) {
        // Create game session and assign immediately so assignGoalkeeperForHalf() can use self.session
        let newSession = GameSession(
            gameId: gameId,
            teamId: teamId,
            config: config,
            intensity: intensity,
            players: players,
            availablePlayerIds: availablePlayerIds
        )
        session = newSession

        // Assign goalkeeper now so PreGameView can display the designation before kick-off
        assignGoalkeeperForHalf()

        // Calculate GK-aware starters (GK slot is already filled above)
        let starters = SubstitutionEngine.calculateStarters(
            availablePlayers: newSession.availablePlayers,
            playersOnField: config.playersOnField
        )

        newSession.starterIds = starters

        // Set starters as on field
        for i in 0..<newSession.playerStats.count {
            if starters.contains(newSession.playerStats[i].id) {
                newSession.playerStats[i].isOnField = true
            }
        }
    }
    
    // MARK: - Game Control
    
    /// Start the game clock (coach presses "Whistle")
    func startGameClock() {
        guard let session = session else { return }

        // Assign goalkeeper for the first half before calculating starters
        assignGoalkeeperForHalf()

        // Recalculate starters so GK is already on field and non-GK slots are filled
        let starters = SubstitutionEngine.calculateStarters(
            availablePlayers: session.availablePlayers,
            playersOnField: session.config.playersOnField
        )
        for i in 0..<session.playerStats.count {
            if session.playerStats[i].wasPresent && !session.playerStats[i].leftEarly {
                session.playerStats[i].isOnField = starters.contains(session.playerStats[i].id)
            }
        }

        // Generate substitution plans for first period
        generateSubstitutionPlans(for: session.currentPeriod)

        session.phase = .running
        startTimer()
    }
    
    /// Start period after break
    func startPeriod() {
        guard let session = session else { return }

        // Reassign goalkeeper at the start of the second half
        let periodsPerHalf = max(1, session.config.periods / 2)
        if session.currentPeriod == periodsPerHalf + 1 {
            assignGoalkeeperForHalf()
        }

        // Calculate lineup for new period
        let newLineup = SubstitutionEngine.calculateNextPeriodLineup(session: session)
        
        // Update field status
        for i in 0..<session.playerStats.count {
            let playerId = session.playerStats[i].id
            session.playerStats[i].isOnField = newLineup.contains(playerId)
            
            // Reset continuous time for everyone
            session.playerStats[i].continuousSecondsPlayed = 0
        }
        
        // Generate substitution plans for this period
        generateSubstitutionPlans(for: session.currentPeriod)
        
        session.phase = .running
        startTimer()
    }
    
    private func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func tick() {
        guard let session = session else { return }
        
        switch session.phase {
        case .running:
            handleRunningTick()
            
        case .pendingSubstitution(let plan):
            handleSubstitutionCountdownTick(plan: plan)
            
        case .periodBreak(let periodNumber, let breakSeconds):
            handleBreakTick(periodNumber: periodNumber, totalBreakSeconds: breakSeconds)
            
        default:
            break
        }
    }
    
    private func handleRunningTick() {
        guard let session = session else { return }

        // Increment period time
        session.periodElapsedSeconds += speedMultiplier

        // Update player statistics for those on field (and haven't left early)
        for i in 0..<session.playerStats.count {
            if session.playerStats[i].isOnField && !session.playerStats[i].leftEarly {
                session.playerStats[i].secondsPlayed += speedMultiplier
                session.playerStats[i].continuousSecondsPlayed += speedMultiplier
            }
        }
        
        // Update absent players with expected time
        updateAbsentPlayerTimes()
        
        // Tick forced sub countdown (if any)
        tickForcedSubCountdown()

        // Check for period end
        if session.periodElapsedSeconds >= session.config.periodSeconds {
            handlePeriodEnd()
            return
        }

        // Check for upcoming substitution
        checkForUpcomingSubstitution()
    }
    
    private func handleSubstitutionCountdownTick(plan: SubstitutionPlan) {
        guard let session = session else { return }

        session.periodElapsedSeconds += speedMultiplier

        // Update player statistics (excluding those who left early)
        for i in 0..<session.playerStats.count {
            if session.playerStats[i].isOnField && !session.playerStats[i].leftEarly {
                session.playerStats[i].secondsPlayed += speedMultiplier
                session.playerStats[i].continuousSecondsPlayed += speedMultiplier
            }
        }
        
        updateAbsentPlayerTimes()

        // Tick forced sub countdown (if any)
        tickForcedSubCountdown()

        // Check if it's time to execute substitution
        if session.periodElapsedSeconds >= plan.scheduledTime {
            if autoCompleteSubstitutions && forcedSubProposal == nil {
                executeSubstitution(plan: plan)
            }
            // Otherwise wait for coach to press "Sub Complete"
        }
        
        // Check for period end during countdown
        if session.periodElapsedSeconds >= session.config.periodSeconds {
            handlePeriodEnd()
        }
    }
    
    private func handleBreakTick(periodNumber: Int, totalBreakSeconds: Int) {
        guard let session = session else { return }
        
        session.breakElapsedSeconds += speedMultiplier
        
        if session.breakElapsedSeconds >= totalBreakSeconds {
            // Break is over
            if skipBreakCountdown || autoStartAfterBreak {
                startPeriod()
            } else {
                // Wait for coach to start next period
                stopTimer()
            }
        }
    }
    
    private func checkForUpcomingSubstitution() {
        guard forcedSubProposal == nil else { return }
        guard let session = session else { return }
        
        // Find next scheduled substitution within 60 seconds
        // Use <= 60 (not == 60) so fast-forward mode doesn't skip the trigger window
        let upcomingSub = session.substitutionPlans
            .filter { !$0.isCompleted }
            .first {
                let remaining = $0.scheduledTime - session.periodElapsedSeconds
                return remaining <= 60 && remaining > 0
            }
        
        if let sub = upcomingSub {
            // 60 seconds until substitution - calculate actual players
            let updatedPlan = SubstitutionEngine.calculateSubstitution(
                session: session,
                scheduledTime: sub.scheduledTime
            )
            
            // Update the plan
            if let index = session.substitutionPlans.firstIndex(where: { $0.id == sub.id }) {
                session.substitutionPlans[index] = updatedPlan
            }
            
            session.phase = .pendingSubstitution(updatedPlan)
        }
    }
    
    func executeSubstitution(plan: SubstitutionPlan) {
        guard let session = session else { return }
        
        // Swap players
        for i in 0..<session.playerStats.count {
            let playerId = session.playerStats[i].id
            
            if plan.playersOut.contains(playerId) {
                // Sub out: reset continuous time
                session.playerStats[i].isOnField = false
                session.playerStats[i].continuousSecondsPlayed = 0
            }
            
            if plan.playersIn.contains(playerId) {
                // Sub in
                session.playerStats[i].isOnField = true
            }
        }
        
        // Mark substitution as completed
        if let index = session.substitutionPlans.firstIndex(where: { $0.id == plan.id }) {
            session.substitutionPlans[index].isCompleted = true
        }
        
        session.phase = .running
    }
    
    private func handlePeriodEnd() {
        guard let session = session else { return }

        // Dismiss any pending forced sub proposal at period boundary
        forcedSubProposal = nil

        stopTimer()
        
        // Reset continuous time for all players
        for i in 0..<session.playerStats.count {
            session.playerStats[i].continuousSecondsPlayed = 0
        }
        
        // Update absent players one final time for this period
        updateAbsentPlayerTimes()
        
        // Check if game is over
        if session.currentPeriod >= session.config.periods {
            handleGameEnd()
            return
        }
        
        // Move to break
        let breakSeconds = session.config.breakAfterPeriod(session.currentPeriod)
        session.currentPeriod += 1
        session.periodElapsedSeconds = 0
        session.breakElapsedSeconds = 0
        session.phase = .periodBreak(periodNumber: session.currentPeriod - 1, breakSeconds: breakSeconds)
        
        if !skipBreakCountdown {
            startTimer()
        }
    }
    
    private func handleGameEnd() {
        guard let session = session else { return }
        
        stopTimer()
        session.phase = .postGame
    }
    
    private func generateSubstitutionPlans(for period: Int) {
        guard let session = session else { return }
        
        let subTimes = SubstitutionEngine.generateSubstitutionTimes(
            periodSeconds: session.config.periodSeconds,
            intensity: session.intensity,
            ageGroup: session.config.ageGroup
        )
        
        session.substitutionPlans = subTimes.map { time in
            SubstitutionPlan(scheduledTime: time)
        }
    }
    
    private func updateAbsentPlayerTimes() {
        guard let session = session else { return }
        
        let expectedSeconds = session.expectedSecondsForAbsentPlayers()
        
        for i in 0..<session.playerStats.count {
            if !session.playerStats[i].wasPresent {
                session.playerStats[i].secondsPlayed = expectedSeconds
            }
        }
    }
    
    // MARK: - Forced Substitutions

    /// Coach pressed X on a field player — mark them injured, move to bench, propose a replacement.
    func forcedSubOut(playerId: UUID) {
        guard let session = session else { return }
        guard let outIndex = session.playerStats.firstIndex(where: { $0.id == playerId }),
              session.playerStats[outIndex].isOnField else { return }

        // Remember if this player was goalkeeper, then clear designation
        let wasGoalkeeper = session.playerStats[outIndex].isGoalkeeper
        session.playerStats[outIndex].isGoalkeeper = false

        // Mark injured and move off field
        session.playerStats[outIndex].isInjured = true
        session.playerStats[outIndex].isOnField = false
        session.playerStats[outIndex].continuousSecondsPlayed = 0

        // Find best replacement: bench player with least playing time, excluding injured and GK
        var benchCandidates = session.playerStats.filter {
            !$0.isOnField && $0.wasPresent && !$0.leftEarly
            && !$0.isInjured && !$0.isGoalkeeper && $0.id != playerId
        }

        // If replacing a GK, prefer canPlayGK-flagged bench players; fall back to full bench if none
        if wasGoalkeeper {
            let gkQualified = benchCandidates.filter { stat in
                players.first(where: { $0.id == stat.id })?.canPlayGK == true
            }
            if !gkQualified.isEmpty {
                benchCandidates = gkQualified
            }
        }

        guard let proposed = benchCandidates.min(by: { lhs, rhs in
            if lhs.secondsPlayed != rhs.secondsPlayed { return lhs.secondsPlayed < rhs.secondsPlayed }
            return lhs.totalSeasonSeconds < rhs.totalSeasonSeconds
        }) else {
            // No bench players available — injured player just sits on bench
            return
        }

        forcedSubProposal = ForcedSubProposal(
            playerOutId: playerId,
            playerOutName: session.playerStats[outIndex].playerName,
            proposedPlayerInId: proposed.id,
            proposedPlayerInName: proposed.playerName,
            countdownSeconds: autoCompleteSubstitutions ? 15 : -1,
            isReplacingGoalkeeper: wasGoalkeeper
        )
    }

    /// Execute the pending forced sub proposal (move proposed player onto field).
    func confirmForcedSub() {
        guard let proposal = forcedSubProposal, let session = session else { return }

        // Verify proposed player is still available on bench
        if let inIndex = session.playerStats.firstIndex(where: {
            $0.id == proposal.proposedPlayerInId && !$0.isOnField && $0.wasPresent && !$0.leftEarly
        }) {
            session.playerStats[inIndex].isOnField = true
            // Inherit goalkeeper role if replacing an injured GK
            if proposal.isReplacingGoalkeeper {
                session.playerStats[inIndex].isGoalkeeper = true
            }
        }

        forcedSubProposal = nil
    }

    /// Dismiss the forced sub proposal without sending anyone on.
    func dismissForcedSub() {
        forcedSubProposal = nil
    }

    /// Heal an injured bench player — removes the INJURED flag and returns them to normal bench pool.
    func healInjuredPlayer(playerId: UUID) {
        guard let session = session else { return }
        guard let index = session.playerStats.firstIndex(where: { $0.id == playerId }) else { return }
        session.playerStats[index].isInjured = false
    }

    /// Designate one goalkeeper for the current half.
    /// Clears all previous GK designations first, then picks the qualifying player with
    /// the least total season time and places them on the field.
    private func assignGoalkeeperForHalf() {
        guard let session = session else { return }

        // Clear existing GK designations
        for i in 0..<session.playerStats.count {
            session.playerStats[i].isGoalkeeper = false
        }

        // Pool: present, not injured, not left early
        let candidates = session.playerStats.filter {
            $0.wasPresent && !$0.isInjured && !$0.leftEarly
        }

        // Prefer canPlayGK players; fall back to everyone if none flagged
        let gkQualified = candidates.filter { stat in
            players.first(where: { $0.id == stat.id })?.canPlayGK == true
        }
        let pool = gkQualified.isEmpty ? candidates : gkQualified

        guard let chosen = pool.min(by: { $0.totalSeasonSeconds < $1.totalSeasonSeconds }) else { return }

        if let idx = session.playerStats.firstIndex(where: { $0.id == chosen.id }) {
            session.playerStats[idx].isGoalkeeper = true
            session.playerStats[idx].isOnField = true
        }
    }

    /// Tick forced sub auto-complete countdown; fires confirmForcedSub when it reaches zero.
    private func tickForcedSubCountdown() {
        guard autoCompleteSubstitutions,
              var proposal = forcedSubProposal,
              proposal.countdownSeconds > 0 else { return }

        proposal.countdownSeconds = max(0, proposal.countdownSeconds - speedMultiplier)
        forcedSubProposal = proposal

        if proposal.countdownSeconds <= 0 {
            confirmForcedSub()
        }
    }

    // MARK: - Late Arrivals

    func markPlayerPresent(playerId: UUID) {
        guard let session = session else { return }
        session.markPlayerPresent(playerId: playerId)
    }

    // MARK: - Bench → Absent

    /// Coach pressed X on a bench player — remove them from the available pool.
    /// They appear in the Absent section and can be restored with "Arrived".
    func markBenchPlayerAbsent(playerId: UUID) {
        guard let session = session else { return }
        guard let index = session.playerStats.firstIndex(where: { $0.id == playerId }),
              !session.playerStats[index].isOnField,
              session.playerStats[index].wasPresent,
              !session.playerStats[index].leftEarly else { return }

        // If this player was the proposed sub-in, dismiss the stale proposal
        if forcedSubProposal?.proposedPlayerInId == playerId {
            forcedSubProposal = nil
        }

        // Move to absent (reversible via "Arrived" button)
        session.playerStats[index].wasPresent = false
    }

    // MARK: - Early Departures

    func markPlayerLeftEarly(playerId: UUID) {
        guard let session = session else { return }
        session.markPlayerLeftEarly(playerId: playerId)
    }
    
    // MARK: - Game Completion
    
    func completeGame(game: Game, gameStore: GameStore) async {
        guard let session = session else { return }
        
        // Create completed game record
        let record = CompletedGameRecord.from(session: session, game: game)
        
        // Update player season totals
        for playerStat in session.playerStats {
            if let playerIndex = players.firstIndex(where: { $0.id == playerStat.id }) {
                let additionalMinutes = (playerStat.secondsPlayed + 30) / 60 // round to nearest minute
                players[playerIndex].totalMinutesPlayed += additionalMinutes
                
                // Save to repository
                do {
                    try await playerRepo.upsert(player: players[playerIndex])
                } catch {
                    print("Failed to update player stats: \(error)")
                }
            }
        }
        
        // Save final score
        gameStore.updateScore(gameId: session.gameId, ourScore: session.ourScore, opponentScore: session.opponentScore)

        // Mark the game as completed so it cannot be restarted
        gameStore.markCompleted(gameId: session.gameId)

        // Clear session
        self.session = nil
    }
}
