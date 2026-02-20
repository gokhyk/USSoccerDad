//
//  PreGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PreGameView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager  // ← ADD THIS
    
    var session: GameSession? {
        viewModel.session
    }
    
    var absentPlayers: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats.filter { !$0.wasPresent }
    }
    
    var playersLeftEarly: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playersLeftEarly
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if let session = session {
                Text("Starting Lineup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.textPrimary)  // ← CHANGE
                
//                Text("\(session.config.playersOnField) players on field")
//                    .font(.subheadline)
//                    .foregroundColor(themeManager.colors.textSecondary)  // ← CHANGE
                
                List {
                    Section("Starters") {
                        ForEach(session.playersOnField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                Text(player.playerName)
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.textPrimary)  // ← ADD
                                
                                Spacer()
                                
                                Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.textSecondary)  // ← CHANGE
                            }
                        }
                    }
                    
                    Section("On Bench") {
                        ForEach(session.playersOffField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                Text(player.playerName)
                                    .foregroundColor(themeManager.colors.textSecondary)  // ← CHANGE
                                
                                Spacer()
                                
                                Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.textTertiary)  // ← CHANGE
                            }
                        }
                    }
                    
                    if !absentPlayers.isEmpty {
                        Section("Absent Players") {
                            ForEach(absentPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(themeManager.colors.error)  // ← CHANGE
                                    
                                    Spacer()
                                    
                                    Button("Mark Present") {
                                        viewModel.markPlayerPresent(playerId: player.id)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .tint(themeManager.colors.success)  // ← CHANGE
                                }
                            }
                        }
                    }
                    
                    if !playersLeftEarly.isEmpty {
                        Section("Left Early") {
                            ForEach(playersLeftEarly.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(themeManager.colors.warning)  // ← CHANGE
                                        .strikethrough()
                                    
                                    Spacer()
                                    
                                    Text(player.formattedSecondsPlayed)
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)  // ← CHANGE
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)  // ← ADD for better appearance
                .scrollContentBackground(.hidden)  // ← ADD
                .background(themeManager.colors.background)  // ← ADD
                
                Spacer()
                
                Button(action: {
//                    print("🎺 Blow Whistle tapped!")
//                    print("   Session exists: \(viewModel.session != nil)")
//                    print("   Current phase: \(viewModel.session?.phase.displayName ?? "nil")")
                    viewModel.startGameClock()
                    //print("   After start phase: \(viewModel.session?.phase.displayName ?? "nil")")
                }) {
                    HStack {
                        Image(systemName: "sportscourt")
                        Text("Blow Whistle")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.primary)  // ← CHANGE
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            } else {
                Text("No game session available")
                    .foregroundColor(themeManager.colors.error)  // ← CHANGE
            }
        }
        .navigationTitle("Pre-Game")
        .background(themeManager.colors.background)  // ← ADD
    }
    
    private func formatMinutes(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }
}
