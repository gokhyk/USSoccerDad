//
//  GameListView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import SwiftUI

struct GameListView: View {
    @EnvironmentObject var gameStore: GameStore
    let team: TeamSettings

    @State private var editingGame: Game?

    var body: some View {
        let games = gameStore.games(for: team.id)

        List {
            if games.isEmpty {
                Text("No games yet. Tap + to add one.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(gameId: game.id, team: team, playerRepo: InMemoryPlayerRepository())
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.opponent.isEmpty ? "Opponent TBD" : game.opponent)
                                .font(.headline)

                            Text(dateString(for: game.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        gameStore.delete(gameId: games[index].id)
                    }
                }
            }
        }
        .navigationTitle("Games")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startNewGame()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingGame) { game in
            NavigationStack {
                AddEditGameView(team: team, game: game) { updated in
                    gameStore.upsert(updated)
                    editingGame = nil
                } onCancel: {
                    editingGame = nil
                }
            }
        }
    }

    private func startNewGame() {
        let newGame = Game(
            id: UUID(),
            teamId: team.id,
            opponent: "",
            date: Date(),
            location: nil,
            minutesPerPeriod: team.minutesPerPeriod,
            playersOnField: team.playersOnField,
            notes: nil,
            availability: [:]
        )
        editingGame = newGame
    }

    private func dateString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
