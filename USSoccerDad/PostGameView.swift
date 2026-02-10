//
//  PostGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PostGameView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var gameStore: GameStore
    
    let game: Game
    
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var isSaving = false
    
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
            
            if let session = session {
                // Game summary
                VStack(spacing: 8) {
                    Text(game.opponent)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(session.config.periods) × \(session.config.minutesPerPeriod) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
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
                                        .foregroundColor(.orange)
                                } else if player.arrivedLate {
                                    Text("(Late)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(player.formattedSecondsPlayed)
                                        .font(.headline)
                                    
                                    Text("\((player.secondsPlayed * 100) / session.totalElapsedSeconds)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if !absentPlayers.isEmpty {
                        Section("Absent") {
                            ForEach(absentPlayers) { player in
                                Text(player.playerName)
                                    .foregroundColor(.secondary)
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
                    .background(Color.blue)
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
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
            }
            .padding()
        }
        .navigationTitle("Final Stats")
        .navigationBarBackButtonHidden(true)
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
        
        isSaving = true
        
        Task {
            await viewModel.completeGame(game: game, gameStore: gameStore)
            isSaving = false
            
            // Navigation back will be handled by the parent view
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
