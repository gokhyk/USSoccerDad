//
// LineupGeneratorView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/1/25.
//





import SwiftUI

struct LineupGeneratorView: View {
    @EnvironmentObject var gameStore: GameStore   // lowercased

    let gameId: UUID
    let team: TeamSettings

    @StateObject private var vm: U7GameViewModel

    @State private var availableIds: Set<UUID> = []
    @State private var intensity: SubstitutionIntensity = .balanced
    @State private var showGameView = false
    @State private var isLoading = true

    init(gameId: UUID, team: TeamSettings, playerRepo: PlayerRepository) {
        self.gameId = gameId
        self.team = team

        _vm = StateObject(
            wrappedValue: U7GameViewModel(
                teamId: team.id,
                playerRepo: playerRepo
            )
        )
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading players…")
            } else {
                Form {
                    Section("Substitution Style TBD") {
                        Picker("Style", selection: $intensity) {
                            Text("Frequent").tag(SubstitutionIntensity.frequent)
                            Text("Balanced").tag(SubstitutionIntensity.balanced)
                            Text("Infrequent").tag(SubstitutionIntensity.infrequent)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Who is here today?") {
                        ForEach(vm.players) { player in
                            HStack {
                                Text(displayName(for: player))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { availableIds.contains(player.id) },
                                    set: { isOn in
                                        if isOn {
                                            availableIds.insert(player.id)
                                        } else {
                                            availableIds.remove(player.id)
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                        }
                    }

                    Section {
                        Button("Start Game") {
                            let playersonField = gameStore.game(withId: gameId)?.playersOnField ?? team.playersOnField
                            let minutesPerPeriod = gameStore.game(withId: gameId)?.minutesPerPeriod ?? 25
                            let config = GameConfig(
                                minutesPerPeriod: minutesPerPeriod,
                                periods: 2,
                                playersOnField: playersonField,
                                minPlayersToStart: min(playersonField, 3)
                            )
                            
                            vm.startGame(config: config, intensity: intensity, availableIds: availableIds)
                            showGameView = true
                        }
                        .disabled(availableIds.isEmpty)
                    }
                }
            }

            NavigationLink(
                destination: U7GameView(vm: vm),
                isActive: $showGameView
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("Lineup U? TBD")
        .task {
            await load()
            
            #if DEBUG
            let availabilityCount =
                gameStore.game(withId: gameId)?.availability.count ?? 0

            assert(
                availabilityCount > 0,
                "LineupGenerator: Availability must be loaded before generating lineup"
            )
            #endif
            
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        // 1. Load players
        await vm.loadPlayers()

        // 2. Load availability from GameStore (for this game)
        let availDict = gameStore.game(withId: gameId)?.availability ?? [:]

        // Default: if not in dict, treat as available (true)
        let presentIds = vm.players
            .filter { player in
                availDict[player.id] ?? true
            }
            .map(\.id)

        // If there is no availability saved yet, everyone will end up in presentIds anyway.
        availableIds = Set(presentIds)
    }

    private func displayName(for player: Player) -> String {
        if let number = player.jerseyNumber {
            return "#\(number) \(player.name)"
        } else {
            return player.name
        }
    }
}
