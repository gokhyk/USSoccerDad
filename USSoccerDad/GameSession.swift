//
//  GameSession.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Represents an active game session with all current state
class GameSession: ObservableObject {
    let gameId: UUID
    let teamId: UUID
    let config: GameConfig
    let intensity: SubstitutionIntensity
    
    /// All players and their statistics for this game
    @Published var playerStats: [PlayerGameStats]
    
    /// Current game phase
    @Published var phase: GamePhase = .preGame
    
    /// Current period number (1-based)
    @Published var currentPeriod: Int = 1
    
    /// Elapsed seconds in the current period
    @Published var periodElapsedSeconds: Int = 0
    
    /// Elapsed seconds in current break
    @Published var breakElapsedSeconds: Int = 0
    
    /// Planned substitutions for current period
    @Published var substitutionPlans: [SubstitutionPlan] = []

    /// Live score — updated by coach tapping +/− during the game
    @Published var ourScore: Int = 0
    @Published var opponentScore: Int = 0
    
    /// Starting lineup (player IDs)
    var starterIds: Set<UUID> = []
    
    init(
        gameId: UUID,
        teamId: UUID,
        config: GameConfig,
        intensity: SubstitutionIntensity,
        players: [Player],
        availablePlayerIds: Set<UUID>
    ) {
        self.gameId = gameId
        self.teamId = teamId
        self.config = config
        self.intensity = intensity
        
        // Initialize player stats
        self.playerStats = players.map { player in
            let isAvailable = availablePlayerIds.contains(player.id)
            return PlayerGameStats(
                playerId: player.id,
                playerName: player.name,
                isOnField: false,
                wasPresent: isAvailable,
                seasonSecondsBeforeGame: player.totalMinutesPlayed * 60
            )
        }
    }
    
    /// Get players currently on field
    var playersOnField: [PlayerGameStats] {
        playerStats.filter { $0.isOnField && !$0.leftEarly }
    }
    
    /// Get players currently off field but present
    var playersOffField: [PlayerGameStats] {
        playerStats.filter { !$0.isOnField && $0.wasPresent && !$0.leftEarly }
    }
    
    /// Get available (present) players
    var availablePlayers: [PlayerGameStats] {
        playerStats.filter { $0.wasPresent && !$0.leftEarly }
    }
    
    /// Get players who left early
    var playersLeftEarly: [PlayerGameStats] {
        playerStats.filter { $0.leftEarly }
    }
    
    /// Total elapsed game time in seconds (across all periods)
    var totalElapsedSeconds: Int {
        (currentPeriod - 1) * config.periodSeconds + periodElapsedSeconds
    }
    
    /// Format total elapsed time as MM:SS
    var formattedTotalElapsed: String {
        let minutes = totalElapsedSeconds / 60
        let seconds = totalElapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format period elapsed time as MM:SS
    var formattedPeriodElapsed: String {
        let minutes = periodElapsedSeconds / 60
        let seconds = periodElapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Calculate expected playing time for absent players at current point
    func expectedSecondsForAbsentPlayers() -> Int {
        let presentCount = availablePlayers.count
        guard presentCount > 0 else { return 0 }
        
        let totalGameTime = totalElapsedSeconds
        let playersOnFieldCount = config.playersOnField
        
        // Formula: game_time * players_on_field / players_present
        return (totalGameTime * playersOnFieldCount) / presentCount
    }
    
    /// Restore a player to the available pool (late arrival or returning from bench-absent).
    func markPlayerPresent(playerId: UUID) {
        guard let index = playerStats.firstIndex(where: { $0.id == playerId }) else { return }

        playerStats[index].wasPresent = true

        // Only credit expected time for true late arrivals (no prior playing time).
        // Players who were benched then temporarily marked absent keep their existing stats.
        if playerStats[index].secondsPlayed == 0 {
            playerStats[index].arrivedLate = true
            playerStats[index].arrivalTime = totalElapsedSeconds
            let expectedSeconds = expectedSecondsForAbsentPlayers()
            playerStats[index].secondsPlayed = expectedSeconds
        }
    }
    
    /// Mark a player as having left early
    func markPlayerLeftEarly(playerId: UUID) {
        guard let index = playerStats.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        // If player is currently on field, sub them out
        if playerStats[index].isOnField {
            playerStats[index].isOnField = false
            playerStats[index].continuousSecondsPlayed = 0
        }
        
        playerStats[index].leftEarly = true
        playerStats[index].departureTime = totalElapsedSeconds
        // Note: We keep their wasPresent = true so their stats are preserved
    }
}
