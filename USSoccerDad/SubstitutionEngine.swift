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

        guard !playersOnField.isEmpty, !playersOffField.isEmpty else {
            return SubstitutionPlan(scheduledTime: scheduledTime)
        }

        // Decide how many players to swap based on actual playing-time gaps
        let numberOfSubs = calculateOptimalSubCount(
            playersOnField: playersOnField,
            playersOffField: playersOffField
        )

        let playersOut = selectPlayersToSubOut(
            playersOnField: playersOnField,
            count: numberOfSubs
        )

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

    /// Determine how many players should swap to best equalize playing time.
    ///
    /// Works by pairing the most-overdue on-field player with the most-rested
    /// bench player, then the second-most overdue with the second-most rested, etc.
    /// Each pair where the gap exceeds the threshold justifies one substitution.
    /// Result is clamped to 1–5 (and limited by how many players are available).
    private static func calculateOptimalSubCount(
        playersOnField: [PlayerGameStats],
        playersOffField: [PlayerGameStats]
    ) -> Int {
        // A gap of more than 90 seconds between the on-field player's total time
        // and the bench player's total time justifies swapping that pair.
        let threshold = 90

        // GK never rotates; injured players are not available
        let sortedOut = playersOnField.filter { !$0.isGoalkeeper }.sorted { $0.secondsPlayed > $1.secondsPlayed }
        let sortedIn  = playersOffField.filter { !$0.isInjured && !$0.isGoalkeeper }.sorted { $0.secondsPlayed < $1.secondsPlayed }

        let maxPossible = min(sortedOut.count, sortedIn.count, 5)

        var count = 0
        for i in 0..<maxPossible {
            let gap = sortedOut[i].secondsPlayed - sortedIn[i].secondsPlayed
            if gap > threshold {
                count += 1
            } else {
                break   // once the gap is small the remaining pairs need it even less
            }
        }

        return max(1, count)
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
        // GK is never subbed out by the engine
        let sorted = playersOnField.filter { !$0.isGoalkeeper }.sorted { p1, p2 in
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
        // Injured and GK-designated bench players are never brought in by the engine
        let sorted = playersOffField.filter { !$0.isInjured && !$0.isGoalkeeper }.sorted { p1, p2 in
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
        // GK is already on field — keep them and fill remaining spots from non-GK players
        let gkIds = Set(availablePlayers.filter { $0.isGoalkeeper }.map { $0.id })
        let nonGK = availablePlayers.filter { !$0.isGoalkeeper }

        // Sort by season time (ascending) - players with least season time start
        let sorted = nonGK.sorted { $0.totalSeasonSeconds < $1.totalSeasonSeconds }
        let fieldSlots = max(0, playersOnField - gkIds.count)
        let starters = Array(sorted.prefix(fieldSlots))
        return Set(starters.map { $0.id }).union(gkIds)
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
    /// Uses same logic as regular substitutions but rotates entire lineup.
    /// GK always carries over; injured players are excluded from the field pool.
    static func calculateNextPeriodLineup(
        session: GameSession
    ) -> Set<UUID> {
        let all = session.playersOnField + session.playersOffField

        // GK always stays on field (or on bench if they're the second-half GK just assigned)
        let gkIds = Set(all.filter { $0.isGoalkeeper }.map { $0.id })

        // Field pool: non-GK, non-injured players from both on-field and bench
        let fieldPool = all.filter { !$0.isGoalkeeper && !$0.isInjured }

        let spotsNeeded = max(0, session.config.playersOnField - gkIds.count)
        let fieldStarters = selectPlayersToSubIn(playersOffField: fieldPool, count: spotsNeeded)

        return Set(fieldStarters.map { $0.id }).union(gkIds)
    }
}
