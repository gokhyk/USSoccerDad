//
//  Game.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import Foundation

struct Game: Identifiable, Codable, Equatable {
    var id: UUID
    var teamId: UUID

    var opponent: String
    var date: Date
    var location: String?

    var durations: [Int]
    var numberOfPeriods: Int
    var minutesPerPeriod: Int
    var playersOnField: Int
    var notes: String?

    // playerId -> isAvailable
    var availability: [UUID: Bool] = [:]

    /// Set to true after Save & Exit — prevents the game from being restarted
    var isCompleted: Bool = false
}


enum RunPhase {
    case preKickoff          // show starters, waiting for Start button
    case running             // game clock running
    case pendingSubstitution // countdown shown, waiting for OK
    case halfTime
    case paused
    case finished
}



