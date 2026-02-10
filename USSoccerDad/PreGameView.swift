//
//  PreGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PreGameView: View {
    @ObservedObject var viewModel: GameViewModel
    
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
        VStack(spacing: 20) {
            if let session = session {
                Text("Starting Lineup")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(session.config.playersOnField) players on field")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                List {
                    Section("Starters") {
                        ForEach(session.playersOnField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                Text(player.playerName)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("On Bench") {
                        ForEach(session.playersOffField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                Text(player.playerName)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Season: \(formatMinutes(player.seasonSecondsBeforeGame))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !absentPlayers.isEmpty {
                        Section("Absent Players") {
                            ForEach(absentPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Button("Mark Present") {
                                        viewModel.markPlayerPresent(playerId: player.id)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .tint(.green)
                                }
                            }
                        }
                    }
                    
                    if !playersLeftEarly.isEmpty {
                        Section("Left Early") {
                            ForEach(playersLeftEarly.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(.orange)
                                        .strikethrough()
                                    
                                    Spacer()
                                    
                                    Text(player.formattedSecondsPlayed)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    print("🎺 Blow Whistle tapped!")
                    print("   Session exists: \(viewModel.session != nil)")
                    print("   Current phase: \(viewModel.session?.phase.displayName ?? "nil")")
                    viewModel.startGameClock()
                    print("   After start phase: \(viewModel.session?.phase.displayName ?? "nil")")
                }) {
                    HStack {
                        Image(systemName: "sportscourt")
                        Text("Blow Whistle")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            } else {
                Text("No game session available")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Pre-Game")
    }
    
    private func formatMinutes(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }
}
