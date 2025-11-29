//
//  GameDetailView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject var gameStore: GameStore

    let gameId: UUID
    let team: TeamSettings

    @State private var game: Game?

    var body: some View {
        Group {
            if let g = game {
                List {
                    Section(header: Text("Details")) {
                        Text(g.opponent.isEmpty ? "Opponent: TBD" : "Opponent: \(g.opponent)")
                        Text("Date: \(dateString(for: g.date))")
                        if let location = g.location {
                            Text("Location: \(location)")
                        }
                        Text("Minutes per Half: \(g.minutesPerHalf)")
                        Text("Players on Field: \(g.playersOnField)")
                    }

                    if let note = g.notes, !note.isEmpty {
                        Section(header: Text("Notes")) {
                            Text(note)
                        }
                    }

                    Section {
                        NavigationLink("Set Availability") {
                            AvailabilityView(gameId: g.id, team: team)
                        }

                        NavigationLink("Lineup Generator") {
                            LineupGeneratorView(gameId: g.id, team: team)
                        }
                    }
                }
            } else {
                Text("Game not found.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Game")
        .onAppear {
            reload()
        }
        .onReceive(gameStore.$games) { _ in
            reload()
        }
    }

    private func reload() {
        game = gameStore.game(withId: gameId)
    }

    private func dateString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
