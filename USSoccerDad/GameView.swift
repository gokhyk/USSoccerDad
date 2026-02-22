//
//  GameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var viewModel: GameViewModel
    @EnvironmentObject var gameStore: GameStore

    let game: Game

    @Environment(\.dismiss) var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        Group {
            if let session = viewModel.session {
                switch session.phase {
                case .preGame:
                    PreGameView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Exit") {
                                    showExitConfirmation = true
                                }
                                .foregroundColor(themeManager.colors.error)
                            }
                        }

                case .running:
                    ActiveGameView(viewModel: viewModel, opponentName: game.opponent)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Toggle("Auto-complete subs", isOn: $viewModel.autoCompleteSubstitutions)
                                    Toggle("Auto-start after break", isOn: $viewModel.autoStartAfterBreak)
                                    Toggle("Skip break countdown", isOn: $viewModel.skipBreakCountdown)
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }

                case .pendingSubstitution(let plan):
                    SubstitutionOverlayView(viewModel: viewModel, plan: plan)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Menu {
                                    Toggle("Auto-complete subs", isOn: $viewModel.autoCompleteSubstitutions)
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }

                case .periodBreak(let periodNumber, let breakSeconds):
                    PeriodBreakView(
                        viewModel: viewModel,
                        periodNumber: periodNumber,
                        totalBreakSeconds: breakSeconds
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Toggle("Auto-start after break", isOn: $viewModel.autoStartAfterBreak)
                                Toggle("Skip break countdown", isOn: $viewModel.skipBreakCountdown)
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }

                case .postGame:
                    PostGameView(viewModel: viewModel, game: game)
                        .onDisappear {
                            dismiss()
                        }
                }
            } else {
                VStack {
                    ProgressView()
                    Text("Loading game...")
                        .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(viewModel.session != nil)
        .navigationTitle(game.opponent)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Exit Pre-Game?", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) { dismiss() }
            Button("Stay", role: .cancel) { }
        } message: {
            Text("The game setup will be lost. You can restart it from Availability.")
        }
        .task {
            if viewModel.session == nil, let pending = viewModel.pendingGameConfig {
                await viewModel.loadPlayers()
                viewModel.startGame(
                    gameId: pending.gameId,
                    config: pending.config,
                    intensity: pending.intensity,
                    availablePlayerIds: pending.availablePlayerIds
                )
                viewModel.pendingGameConfig = nil
            }
        }
    }
}

// MARK: - Convenience Initializer

extension GameView {
    init(
        gameId: UUID,
        game: Game,
        teamId: UUID,
        playerRepo: PlayerRepository,
        config: GameConfig,
        intensity: SubstitutionIntensity,
        availablePlayerIds: Set<UUID>
    ) {
        self.game = game
        
        let vm = GameViewModel(teamId: teamId, playerRepo: playerRepo)
        _viewModel = StateObject(wrappedValue: vm)
        
        // Store params for later initialization in onAppear
        vm.pendingGameConfig = (gameId, config, intensity, availablePlayerIds)
    }
}
