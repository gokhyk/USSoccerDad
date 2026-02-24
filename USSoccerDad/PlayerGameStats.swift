//
//  PlayerGameStats.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Tracks a player's statistics during an active game session
struct PlayerGameStats: Identifiable, Equatable {
    let id: UUID // player ID
    let playerName: String
    
    /// Total seconds played in this game so far
    var secondsPlayed: Int = 0
    
    /// Continuous seconds in current stint (resets when subbed out)
    var continuousSecondsPlayed: Int = 0
    
    /// Whether the player is currently on the field
    var isOnField: Bool = false
    
    /// Whether the player was marked as available/present for this game
    var wasPresent: Bool = true
    
    /// Track if player arrived late (after game started)
    var arrivedLate: Bool = false
    
    /// Time in seconds when player was marked present (for late arrivals)
    var arrivalTime: Int = 0
    
    /// Track if player left early (before game ended)
    var leftEarly: Bool = false

    /// Time in seconds when player left (for early departures)
    var departureTime: Int = 0

    /// Whether the player is currently injured (excluded from sub logic)
    var isInjured: Bool = false

    /// Whether the player is the designated goalkeeper this half
    var isGoalkeeper: Bool = false
    
    /// Player's cumulative season minutes before this game (for prioritization)
    var seasonSecondsBeforeGame: Int = 0
    
    init(
        playerId: UUID,
        playerName: String,
        isOnField: Bool = false,
        wasPresent: Bool = true,
        seasonSecondsBeforeGame: Int = 0
    ) {
        self.id = playerId
        self.playerName = playerName
        self.isOnField = isOnField
        self.wasPresent = wasPresent
        self.seasonSecondsBeforeGame = seasonSecondsBeforeGame
    }
    
    /// Total time including season (for substitution prioritization)
    var totalSeasonSeconds: Int {
        seasonSecondsBeforeGame + secondsPlayed
    }
    
    /// Format seconds as MM:SS for display
    var formattedSecondsPlayed: String {
        let minutes = secondsPlayed / 60
        let seconds = secondsPlayed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format continuous time as MM:SS for display
    var formattedContinuousTime: String {
        let minutes = continuousSecondsPlayed / 60
        let seconds = continuousSecondsPlayed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
