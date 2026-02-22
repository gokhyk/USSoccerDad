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
                    Section(header: Text("Starters").foregroundColor(themeManager.colors.textSecondary)) {
                        ForEach(session.playersOnField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                Text(player.playerName)
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.textPrimary)
                                Spacer()
                                Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                            .listRowBackground(themeManager.colors.surface)
                        }
                    }

                    Section(header: Text("On Bench (\(session.playersOffField.count))").foregroundColor(themeManager.colors.textSecondary)) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(session.playersOffField.sorted(by: { $0.playerName < $1.playerName })) { player in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(player.playerName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .lineLimit(1)
                                    Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                        .font(.caption2)
                                        .foregroundColor(themeManager.colors.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(themeManager.colors.surfaceElevated)
                                .cornerRadius(8)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(themeManager.colors.surface)
                    }

                    if !absentPlayers.isEmpty {
                        Section(header: Text("Absent (\(absentPlayers.count))").foregroundColor(themeManager.colors.error)) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(absentPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(player.playerName)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.error)
                                            .lineLimit(1)
                                        Button("Mark Present") {
                                            viewModel.markPlayerPresent(playerId: player.id)
                                        }
                                        .font(.caption2)
                                        .buttonStyle(.bordered)
                                        .tint(themeManager.colors.success)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(themeManager.colors.error.opacity(0.08))
                                    .cornerRadius(8)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                            .listRowSeparator(.hidden)
                            .listRowBackground(themeManager.colors.surface)
                        }
                    }

                    if !playersLeftEarly.isEmpty {
                        Section(header: Text("Left Early").foregroundColor(themeManager.colors.warning)) {
                            ForEach(playersLeftEarly.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(themeManager.colors.warning)
                                        .strikethrough()
                                    Spacer()
                                    Text(player.formattedSecondsPlayed)
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                }
                                .listRowBackground(themeManager.colors.surface)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                
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
