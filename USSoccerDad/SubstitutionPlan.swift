//
//  SubstitutionPlan.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Represents a planned substitution with players coming in and out
struct SubstitutionPlan: Identifiable, Equatable {
    let id = UUID()
    
    /// Time in seconds when this substitution should occur
    let scheduledTime: Int
    
    /// Players to substitute out (currently on field)
    var playersOut: [UUID]
    
    /// Players to substitute in (currently off field)
    var playersIn: [UUID]
    
    /// Whether this substitution has been completed
    var isCompleted: Bool = false
    
    init(scheduledTime: Int, playersOut: [UUID] = [], playersIn: [UUID] = []) {
        self.scheduledTime = scheduledTime
        self.playersOut = playersOut
        self.playersIn = playersIn
    }
    
    /// Format scheduled time as MM:SS for display
    var formattedTime: String {
        let minutes = scheduledTime / 60
        let seconds = scheduledTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Check if substitution involves any players
    var hasSubstitutions: Bool {
        !playersOut.isEmpty && !playersIn.isEmpty
    }
}
