//
//  CompletedGameRecord.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Record of a completed game with all player statistics
struct CompletedGameRecord: Identifiable, Codable, Equatable {
    let id: UUID // same as gameId
    let teamId: UUID
    let date: Date
    let opponent: String
    let location: String?
    
    /// Game configuration details
    let minutesPerPeriod: Int
    let numberOfPeriods: Int
    let playersOnField: Int
    let ageGroup: AgeGroup
    let intensity: SubstitutionIntensity
    
    /// Player statistics from this game
    let playerStatistics: [PlayerGameStatistics]
    
    struct PlayerGameStatistics: Codable, Equatable, Identifiable {
        let id: UUID // player ID
        let playerName: String
        let secondsPlayed: Int
        let wasPresent: Bool
        let arrivedLate: Bool
        let leftEarly: Bool
        
        /// Format playing time as MM:SS
        var formattedTime: String {
            let minutes = secondsPlayed / 60
            let seconds = secondsPlayed % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        /// Playing time in minutes (rounded)
        var minutesPlayed: Int {
            (secondsPlayed + 30) / 60 // round to nearest minute
        }
    }
    
    /// Create from a completed game session
    static func from(session: GameSession, game: Game) -> CompletedGameRecord {
        let stats = session.playerStats.map { playerStat in
            PlayerGameStatistics(
                id: playerStat.id,
                playerName: playerStat.playerName,
                secondsPlayed: playerStat.secondsPlayed,
                wasPresent: playerStat.wasPresent,
                arrivedLate: playerStat.arrivedLate,
                leftEarly: playerStat.leftEarly
            )
        }
        
        return CompletedGameRecord(
            id: session.gameId,
            teamId: session.teamId,
            date: game.date,
            opponent: game.opponent,
            location: game.location,
            minutesPerPeriod: session.config.minutesPerPeriod,
            numberOfPeriods: session.config.periods,
            playersOnField: session.config.playersOnField,
            ageGroup: session.config.ageGroup,
            intensity: session.intensity,
            playerStatistics: stats
        )
    }
    
    /// Total game duration in minutes
    var totalMinutes: Int {
        minutesPerPeriod * numberOfPeriods
    }
    
    /// Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Generate a text summary for export/sharing
    func generateTextSummary() -> String {
        var text = """
        Game Summary
        ============
        Date: \(formattedDate)
        Opponent: \(opponent)
        """
        
        if let location = location {
            text += "\nLocation: \(location)"
        }
        
        text += """
        
        
        Format: \(numberOfPeriods) periods × \(minutesPerPeriod) minutes
        Players on field: \(playersOnField)
        Age Group: \(ageGroup.rawValue)
        Substitution: \(intensity.rawValue)
        
        Player Statistics
        =================
        
        """
        
        // Sort by most minutes played
        let sortedStats = playerStatistics.sorted { $0.secondsPlayed > $1.secondsPlayed }
        
        for stat in sortedStats {
            var status = ""
            if !stat.wasPresent {
                status = " (Absent)"
            } else if stat.leftEarly {
                status = " (Left Early)"
            } else if stat.arrivedLate {
                status = " (Late)"
            }
            text += "\(stat.playerName): \(stat.formattedTime)\(status)\n"
        }
        
        return text
    }
}
