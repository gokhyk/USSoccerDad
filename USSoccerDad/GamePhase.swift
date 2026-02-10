//
//  GamePhase.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

/// Represents the current phase of the game
enum GamePhase: Equatable {
    case preGame                    // Showing starters, waiting for "Whistle" button
    case running                    // Game clock actively running
    case pendingSubstitution(SubstitutionPlan)  // Countdown to substitution
    case periodBreak(periodNumber: Int, breakSeconds: Int)  // Break between periods
    case postGame                   // Game finished, showing statistics
    
    var isGameActive: Bool {
        switch self {
        case .running, .pendingSubstitution:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .preGame:
            return "Pre-Game"
        case .running:
            return "Game Running"
        case .pendingSubstitution:
            return "Substitution Pending"
        case .periodBreak(let periodNumber, _):
            return "Break after Period \(periodNumber)"
        case .postGame:
            return "Game Complete"
        }
    }
}
