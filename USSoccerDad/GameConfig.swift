//
//  GameConfig.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Configuration for a game session
struct GameConfig: Equatable {
    /// Duration of each period in minutes (converted to seconds internally)
    let minutesPerPeriod: Int
    
    /// Number of periods in the game
    let periods: Int
    
    /// Number of players on the field at a time
    let playersOnField: Int
    
    /// Minimum players required to start the game
    let minPlayersToStart: Int
    
    /// Age group for substitution calculation
    let ageGroup: AgeGroup
    
    /// Break durations in seconds [pregame, period1, break1, period2, break2, ...]
    /// Example U7: [0, 600, 120, 600, 300, 600, 120, 600, 0]
    let breakDurations: [Int]
    
    init(
        minutesPerPeriod: Int,
        periods: Int,
        playersOnField: Int,
        minPlayersToStart: Int,
        ageGroup: AgeGroup = .u7,
        breakDurations: [Int]? = nil
    ) {
        self.minutesPerPeriod = minutesPerPeriod
        self.periods = periods
        self.playersOnField = playersOnField
        self.minPlayersToStart = minPlayersToStart
        self.ageGroup = ageGroup
        
        // Auto-generate break durations if not provided
        if let breakDurations = breakDurations {
            self.breakDurations = breakDurations
        } else {
            self.breakDurations = Self.defaultBreakDurations(
                periods: periods,
                ageGroup: ageGroup
            )
        }
    }
    
    /// Period duration in seconds
    var periodSeconds: Int {
        minutesPerPeriod * 60
    }
    
    /// Total game duration in seconds (excludes breaks)
    var totalGameSeconds: Int {
        periodSeconds * periods
    }
    
    /// Generate default break durations based on age group
    static func defaultBreakDurations(periods: Int, ageGroup: AgeGroup) -> [Int] {
        var durations: [Int] = [0] // pregame
        
        let (shortBreak, halfTimeBreak) = breakDurationsForAgeGroup(ageGroup)
        
        for period in 1...periods {
            durations.append(0) // period itself (not a break)
            
            if period < periods {
                // Determine if this is halftime
                let isHalftime = (period == periods / 2)
                durations.append(isHalftime ? halfTimeBreak : shortBreak)
            }
        }
        
        durations.append(0) // postgame
        return durations
    }
    
    /// Get break durations for age group
    private static func breakDurationsForAgeGroup(_ ageGroup: AgeGroup) -> (shortBreak: Int, halfTime: Int) {
        switch ageGroup {
        case .u5, .u6, .u7:
            return (120, 300) // 2 min short, 5 min halftime
        case .u8, .u9:
            return (0, 600) // 0 min short (only 2 periods), 10 min halftime
        case .u10, .u11:
            return (0, 720) // 0 min short, 12 min halftime
        case .u12, .u13, .u14, .u15, .u16, .u17:
            return (0, 720) // 0 min short, 12 min halftime
        }
    }
    
    /// Get break duration for a specific period number
    func breakAfterPeriod(_ periodNumber: Int) -> Int {
        // breakDurations layout: [pregame, period1, break1, period2, break2, ...]
        let breakIndex = (periodNumber * 2)
        guard breakIndex < breakDurations.count else { return 0 }
        return breakDurations[breakIndex]
    }
}
