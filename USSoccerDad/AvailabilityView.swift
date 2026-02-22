//
//  AvailabilityView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//  Updated by Claude on 2/9/26.
//

import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameStore: GameStore

    let gameId: UUID
    let team: TeamSettings

    // For now we use the in-memory player repo which is persistent via AppStorage
    private let playerRepo = InMemoryPlayerRepository()

    @State private var players: [Player] = []
    @State private var availability: [UUID: Bool] = [:]
    @State private var errorMessage: String?
    
    // Lineup Generator View Variables
    @State private var showGameView = false
    @State private var availableIds: Set<UUID> = []
    @State private var intensity: SubstitutionIntensity = .balanced
    
    var body: some View {
        ZStack {
            List {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(themeManager.colors.error)
                }

                Section {
                    // Substitution intensity picker
                    Picker("Substitution Frequency", selection: $intensity) {
                        ForEach(SubstitutionIntensity.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(intensity.description)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                        .padding(.top, 4)
                }
                
                Section {
                    Button("Start Game") {
                        showGameView = true
                    }
                    .disabled(availableIds.isEmpty)
                }
                
                Section("Player Availability") {
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
            }
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
            .navigationTitle("Availability")
            
            // Hidden NavigationLink
            NavigationLink(
                destination: gameViewDestination,
                isActive: $showGameView
            ) {
                EmptyView()
            }
            .hidden()
        }
    }
    
    @ViewBuilder
    private var gameViewDestination: some View {
        if let game = gameStore.game(withId: gameId) {
            GameView(
                gameId: gameId,
                game: game,
                teamId: team.id,
                playerRepo: playerRepo,
                config: GameConfig(
                    minutesPerPeriod: game.minutesPerPeriod,
                    periods: game.numberOfPeriods,
                    playersOnField: game.playersOnField,
                    minPlayersToStart: min(game.playersOnField, 3),
                    ageGroup: team.ageGroup
                ),
                intensity: intensity,
                availablePlayerIds: availableIds
            )
        } else {
            Text("Game not found")
                .foregroundColor(themeManager.colors.error)
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
                updateAvailableIds()
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
            
            updateAvailableIds()
            
        #if DEBUG
        assert(
            gameStore.game(withId: gameId) != nil,
            "AvailabilityView: Game must exist when loading availability"
        )
        #endif
            
        } catch {
            errorMessage = "Failed to load players: \(error.localizedDescription)"
        }
    }

    private func save() {
        gameStore.updateAvailability(for: gameId, availability: availability)
        
    #if DEBUG
    let stored = gameStore.game(withId: gameId)?.availability
    assert(
        stored == availability,
        "AvailabilityView: Saved availability does not match stored availability"
    )
    #endif
    }
    
    private func updateAvailableIds() {
        availableIds = Set(
            players
                .filter { player in availability[player.id] ?? true }
                .map { $0.id }
        )
    }
}
