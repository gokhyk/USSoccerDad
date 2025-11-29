//
//  InMemoryPlayerRepository.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/18/25.
//

import Foundation
import SwiftUI

@MainActor
final class InMemoryPlayerRepository: PlayerRepository {
    // In-memory cache
    private var players: [UUID: Player] = [:]

    // Persistent storage
    @AppStorage("playersJSON") private var playersJSON: String = ""

    init() {
        loadFromStorage()
    }

    // MARK: - PlayerRepository

    func listPlayers(teamId: UUID, search: String?) async throws -> [Player] {
        // Work on the in-memory cache; it's already loaded from storage
        let allForTeam = players.values.filter { $0.teamId == teamId }

        guard let q = search?.lowercased(), !q.isEmpty else {
            return allForTeam.sorted(by: sortPlayers)
        }

        return allForTeam
            .filter { player in
                let nameMatch = player.name.lowercased().contains(q)
                let numberMatch = player.jerseyNumber
                    .map { String($0) }
                    .map { $0.contains(q) } ?? false
                return nameMatch || numberMatch
            }
            .sorted(by: sortPlayers)
    }

    func upsert(player: Player) async throws {
        players[player.id] = player
        saveToStorage()
    }

    func delete(playerId: UUID) async throws {
        players.removeValue(forKey: playerId)
        saveToStorage()
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        guard !playersJSON.isEmpty,
              let data = playersJSON.data(using: .utf8) else {
            players = [:]
            return
        }

        do {
            let decoded = try JSONDecoder().decode([Player].self, from: data)
            var dict: [UUID: Player] = [:]
            for p in decoded {
                dict[p.id] = p
            }
            players = dict
        } catch {
            print("Failed to decode stored players: \(error)")
            players = [:]
        }
    }

    private func saveToStorage() {
        do {
            let allPlayers = Array(players.values)
            let data = try JSONEncoder().encode(allPlayers)
            if let json = String(data: data, encoding: .utf8) {
                playersJSON = json
            }
        } catch {
            print("Failed to encode players: \(error)")
        }
    }

    // MARK: - Helpers

    private func sortPlayers(_ a: Player, _ b: Player) -> Bool {
        let ja = a.jerseyNumber ?? Int.max
        let jb = b.jerseyNumber ?? Int.max
        if ja != jb { return ja < jb }
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
}
