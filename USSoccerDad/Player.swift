//
//  Player.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/18/25.
//


import Foundation

struct Player: Identifiable, Equatable, Codable {
    var id: UUID
    var teamId: UUID
    var name: String
    var jerseyNumber: Int?
    var notes: String?
    // You can add photo, position, etc later.
    
    var canPlayGK: Bool
    var canPlayAttack: Bool
    var canPlayDefense: Bool
    
    
    // NEW – total minutes played in the season
    var totalMinutesPlayed: Int = 0
}

protocol PlayerRepository {
    func listPlayers(teamId: UUID, search: String?) async throws -> [Player]
    func upsert(player: Player) async throws
    func delete(playerId: UUID) async throws
}
