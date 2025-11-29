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

    var minutesPerHalf: Int
    var playersOnField: Int
    var notes: String?

    // playerId -> isAvailable
    var availability: [UUID: Bool] = [:]
}
