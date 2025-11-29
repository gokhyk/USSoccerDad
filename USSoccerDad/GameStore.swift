//
//  GameStore.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var games: [Game] = []

    @AppStorage("gamesJSON") private var gamesJSON: String = ""

    init() {
        loadFromStorage()
    }

    // MARK: - Public API

    func games(for teamId: UUID) -> [Game] {
        games
            .filter { $0.teamId == teamId }
            .sorted { $0.date < $1.date }
    }

    func game(withId id: UUID) -> Game? {
        games.first { $0.id == id }
    }

    func upsert(_ game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        } else {
            games.append(game)
        }
        persist()
    }

    func delete(gameId: UUID) {
        games.removeAll { $0.id == gameId }
        persist()
    }

    func updateAvailability(for gameId: UUID, availability: [UUID: Bool]) {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[index].availability = availability
        persist()
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        guard !gamesJSON.isEmpty,
              let data = gamesJSON.data(using: .utf8) else {
            games = []
            return
        }

        do {
            games = try JSONDecoder().decode([Game].self, from: data)
        } catch {
            print("Failed to decode games: \(error)")
            games = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(games)
            if let json = String(data: data, encoding: .utf8) {
                gamesJSON = json
            }
        } catch {
            print("Failed to encode games: \(error)")
        }
    }
}
