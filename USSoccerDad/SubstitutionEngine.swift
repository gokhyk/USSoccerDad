//
//  SubstitutionEngine.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Engine for calculating substitutions based on playing time and fairness
struct SubstitutionEngine {
    
    /// Calculate which players should be substituted at a given time
    /// - Parameters:
    ///   - session: Current game session
    ///   - scheduledTime: Time when substitution is scheduled
    /// - Returns: SubstitutionPlan with players in and out
    static func calculateSubstitution(
        session: GameSession,
        scheduledTime: Int
    ) -> SubstitutionPlan {
        let playersOnField = session.playersOnField
        let playersOffField = session.playersOffField
        
        // For now, substitute half the field (rounded down)
        // This can be made configurable later
        let numberOfSubs = max(1, playersOnField.count / 2)
        
        // Select players to come OUT: prioritize by continuous time, then game time, then season time
        let playersOut = selectPlayersToSubOut(
            playersOnField: playersOnField,
            count: numberOfSubs
        )
        
        // Select players to come IN: prioritize by lowest game time, then lowest season time
        let playersIn = selectPlayersToSubIn(
            playersOffField: playersOffField,
            count: numberOfSubs
        )
        
        return SubstitutionPlan(
            scheduledTime: scheduledTime,
            playersOut: playersOut.map { $0.id },
            playersIn: playersIn.map { $0.id }
        )
    }
    
    /// Select players to substitute out based on fatigue and playing time
    private static func selectPlayersToSubOut(
        playersOnField: [PlayerGameStats],
        count: Int
    ) -> [PlayerGameStats] {
        // Sort by:
        // 1. Continuous time (descending) - most tired first
        // 2. Game time (descending) - most played first
        // 3. Season time (descending) - most experienced first
        let sorted = playersOnField.sorted { p1, p2 in
            if p1.continuousSecondsPlayed != p2.continuousSecondsPlayed {
                return p1.continuousSecondsPlayed > p2.continuousSecondsPlayed
            }
            if p1.secondsPlayed != p2.secondsPlayed {
                return p1.secondsPlayed > p2.secondsPlayed
            }
            return p1.totalSeasonSeconds > p2.totalSeasonSeconds
        }
        
        return Array(sorted.prefix(count))
    }
    
    /// Select players to substitute in based on least playing time
    private static func selectPlayersToSubIn(
        playersOffField: [PlayerGameStats],
        count: Int
    ) -> [PlayerGameStats] {
        // Sort by:
        // 1. Game time (ascending) - least played first
        // 2. Season time (ascending) - least experienced first
        let sorted = playersOffField.sorted { p1, p2 in
            if p1.secondsPlayed != p2.secondsPlayed {
                return p1.secondsPlayed < p2.secondsPlayed
            }
            return p1.totalSeasonSeconds < p2.totalSeasonSeconds
        }
        
        return Array(sorted.prefix(count))
    }
    
    /// Calculate initial starters based on season statistics
    /// - Parameters:
    ///   - availablePlayers: Players present for the game
    ///   - playersOnField: Number of players needed on field
    /// - Returns: Set of player IDs for starters
    static func calculateStarters(
        availablePlayers: [PlayerGameStats],
        playersOnField: Int
    ) -> Set<UUID> {
        // Sort by season time (ascending) - players with least season time start
        let sorted = availablePlayers.sorted { p1, p2 in
            p1.totalSeasonSeconds < p2.totalSeasonSeconds
        }
        
        let starters = Array(sorted.prefix(playersOnField))
        return Set(starters.map { $0.id })
    }
    
    /// Generate all substitution plans for a period
    /// - Parameters:
    ///   - periodSeconds: Duration of period in seconds
    ///   - intensity: Substitution intensity setting
    ///   - ageGroup: Age group for frequency calculation
    /// - Returns: Array of substitution times in seconds
    static func generateSubstitutionTimes(
        periodSeconds: Int,
        intensity: SubstitutionIntensity,
        ageGroup: AgeGroup
    ) -> [Int] {
        return intensity.substitutionTimes(
            periodSeconds: periodSeconds,
            ageGroup: ageGroup
        )
    }
    
    /// Calculate lineup for next period (between period transitions)
    /// Uses same logic as regular substitutions but rotates entire lineup
    static func calculateNextPeriodLineup(
        session: GameSession
    ) -> Set<UUID> {
        let playersOnField = session.playersOnField
        let playersOffField = session.playersOffField
        
        // Rotate: bring in players with least game time
        let numberOfPlayersNeeded = session.config.playersOnField
        
        let playersToStart = selectPlayersToSubIn(
            playersOffField: session.playersOffField + playersOnField,
            count: numberOfPlayersNeeded
        )
        
        return Set(playersToStart.map { $0.id })
    }
}
