//
//  AvailabilityView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject var gameStore: GameStore

    let gameId: UUID
    let team: TeamSettings

    // For now we use the in-memory player repo which is persistent via AppStorage
    private let playerRepo = InMemoryPlayerRepository()

    @State private var players: [Player] = []
    @State private var availability: [UUID: Bool] = [:]
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            ForEach(players) { player in
                Toggle(isOn: binding(for: player.id)) {
                    HStack {
                        if let num = player.jerseyNumber {
                            Text("#\(num)")
                                .frame(width: 40, alignment: .leading)
                        } else {
                            Text("—")
                                .frame(width: 40, alignment: .leading)
                        }

                        Text(player.name)
                    }
                }
            }
        }
        .navigationTitle("Availability")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
            }
        }
        .task {
            await load()
        }
        .onDisappear() {
            save()
        }
    }

    private func binding(for playerId: UUID) -> Binding<Bool> {
        Binding(
            get: {
                // default to true (everyone available) if not set
                availability[playerId, default: true]
            },
            set: { newValue in
                availability[playerId] = newValue
            }
        )
    }

    private func load() async {
        do {
            let result = try await playerRepo.listPlayers(teamId: team.id, search: nil)
            players = result

            if let game = gameStore.game(withId: gameId) {
                availability = game.availability
            }
        } catch {
            errorMessage = "Failed to load players: \(error.localizedDescription)"
        }
    }

    private func save() {
        gameStore.updateAvailability(for: gameId, availability: availability)
    }
}
