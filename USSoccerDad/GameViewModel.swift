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
        // Create game session
        let newSession = GameSession(
            gameId: gameId,
            teamId: teamId,
            config: config,
            intensity: intensity,
            players: players,
            availablePlayerIds: availablePlayerIds
        )
        
        // Calculate starters
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
        
        session = newSession
    }
    
    // MARK: - Game Control
    
    /// Start the game clock (coach presses "Whistle")
    func startGameClock() {
        guard let session = session else { return }
        
        // Generate substitution plans for first period
        generateSubstitutionPlans(for: session.currentPeriod)
        
        session.phase = .running
        startTimer()
    }
    
    /// Start period after break
    func startPeriod() {
        guard let session = session else { return }
        
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
        
        // Check if it's time to execute substitution
        if session.periodElapsedSeconds >= plan.scheduledTime {
            if autoCompleteSubstitutions {
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
    
    // MARK: - Late Arrivals
    
    func markPlayerPresent(playerId: UUID) {
        guard let session = session else { return }
        session.markPlayerPresent(playerId: playerId)
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
        
        // Save completed game record to game store
        // TODO: Add CompletedGameRecord storage to GameStore
        
        // Clear session
        self.session = nil
    }
}
