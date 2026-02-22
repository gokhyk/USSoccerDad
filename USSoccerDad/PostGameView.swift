//
//  PostGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PostGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var gameStore: GameStore
    
    let game: Game
    
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var isSaving = false
    @State private var ourScore: Int = 0
    @State private var opponentScore: Int = 0
    
    var session: GameSession? {
        viewModel.session
    }
    
    var sortedPlayers: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats
            .filter { $0.wasPresent }
            .sorted { $0.secondsPlayed > $1.secondsPlayed }
    }
    
    var absentPlayers: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats
            .filter { !$0.wasPresent }
            .sorted { $0.playerName < $1.playerName }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Score entry
            VStack(spacing: 8) {
                Text(game.opponent.isEmpty ? "Final Score" : "vs \(game.opponent)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.textSecondary)

                HStack(spacing: 0) {
                    // Our score
                    HStack(spacing: 16) {
                        Button { ourScore = max(0, ourScore - 1) } label: {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(themeManager.colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 2) {
                            Text("\(ourScore)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.colors.textPrimary)
                            Text("Us")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                        }

                        Button { ourScore += 1 } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.colors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)

                    Text("–")
                        .font(.largeTitle)
                        .foregroundColor(themeManager.colors.textTertiary)

                    // Opponent score
                    HStack(spacing: 16) {
                        Button { opponentScore = max(0, opponentScore - 1) } label: {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(themeManager.colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 2) {
                            Text("\(opponentScore)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.colors.textPrimary)
                            Text(game.opponent.isEmpty ? "Opp" : game.opponent)
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .lineLimit(1)
                        }

                        Button { opponentScore += 1 } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.colors.error)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(themeManager.colors.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            .padding(.horizontal)

            if let session = session {
                // Game summary
                VStack(spacing: 8) {
                    Text("\(session.config.periods) × \(session.config.minutesPerPeriod) min")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
                .padding(.vertical, 4)
                
                // Player statistics
                List {
                    Section("Playing Time") {
                        ForEach(sortedPlayers) { player in
                            HStack {
                                Text(player.playerName)
                                    .font(.body)
                                
                                if player.leftEarly {
                                    Text("(Left Early)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.warning)
                                } else if player.arrivedLate {
                                    Text("(Late)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.warning)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(player.formattedSecondsPlayed)
                                        .font(.headline)
                                    
                                    Text("\((player.secondsPlayed * 100) / session.totalElapsedSeconds)%")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    if !absentPlayers.isEmpty {
                        Section("Absent") {
                            ForEach(absentPlayers) { player in
                                Text(player.playerName)
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                        }
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: exportStatistics) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("Share")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: saveGame) {
                    VStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Save & Exit")
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.success)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
            }
            .padding()
        }
        .navigationTitle("Final Stats")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            ourScore = viewModel.session?.ourScore ?? 0
            opponentScore = viewModel.session?.opponentScore ?? 0
        }
        .sheet(isPresented: $showShareSheet) {
            if #available(iOS 16.0, *) {
                ShareSheet(activityItems: [shareText])
            } else {
                Text("Share feature requires iOS 16+")
            }
        }
    }
    
    private func exportStatistics() {
        guard let session = session else { return }
        
        let record = CompletedGameRecord.from(session: session, game: game)
        shareText = record.generateTextSummary()
        showShareSheet = true
    }
    
    private func saveGame() {
        guard let session = session else { return }

        // Write the (possibly adjusted) score back into the session before saving
        session.ourScore = ourScore
        session.opponentScore = opponentScore

        isSaving = true
        Task {
            await viewModel.completeGame(game: game, gameStore: gameStore)
            isSaving = false
        }
    }
}

// Share sheet for iOS 16+
@available(iOS 16.0, *)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
