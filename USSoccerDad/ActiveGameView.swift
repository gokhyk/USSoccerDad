//
//  ActiveGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct ActiveGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
        VStack(spacing: 16) {
            if let session = session {
                // Game clock display
                VStack(spacing: 8) {
                    Text("Period \(session.currentPeriod) of \(session.config.periods)")
                        .font(.headline)
                    
                    Text(session.formattedPeriodElapsed)
                        .font(.system(size: 45, weight: .bold, design: .monospaced))
                    
                    Text("Total: \(session.formattedTotalElapsed)")
                        .font(.caption)
                        //.foregroundColor(.secondary)
                        .foregroundColor(themeManager.colors.textPrimary) // <- NEW THEME MANAGER
                }
                //.padding()
                //.background(Color.blue.opacity(0.1))
                .background(themeManager.colors.surface.opacity(0.1)) // <- NEW THEME MANAGER
                .cornerRadius(12)
                
                // Current lineup
                List {
                    Section("On Field (\(session.playersOnField.count))") {
                        ForEach(session.playersOnField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                PlayerStatRow(player: player, isOnField: true)
                                
                                Button {
                                    viewModel.markPlayerLeftEarly(playerId: player.id)
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(themeManager.colors.error)    // <- NEW THEME MANAGER
                                }
                                .tint(themeManager.colors.primary)    // <- NEW THEME MANAGER
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Section("On Bench (\(session.playersOffField.count))") {
                        ForEach(session.playersOffField.sorted(by: { $0.playerName < $1.playerName })) { player in
                            HStack {
                                PlayerStatRow(player: player, isOnField: false)
                                
                                Button {
                                    viewModel.markPlayerLeftEarly(playerId: player.id)
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(themeManager.colors.error)    // <- NEW THEME MANAGER
                                }
                                .tint(themeManager.colors.primary)    // <- NEW THEME MANAGER
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    if !absentPlayers.isEmpty {
                        Section("Absent Players") {
                            ForEach(absentPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        .foregroundColor(themeManager.colors.error)     // <- NEW THEME MANAGER
                                    
                                    Spacer()
                                    
                                    Button("Arrived") {
                                        viewModel.markPlayerPresent(playerId: player.id)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .tint(themeManager.colors.primary)    // <- NEW THEME MANAGER
                                }
                            }
                        }
                    }
                    
                    if !playersLeftEarly.isEmpty {
                        Section("Left Early") {
                            ForEach(playersLeftEarly.sorted(by: { $0.playerName < $1.playerName })) { player in
                                HStack {
                                    Text(player.playerName)
                                        //.foregroundColor(.orange)
                                        .foregroundColor(themeManager.colors.warning)    // <- NEW THEME MANAGER
                                        .strikethrough()
                                    
                                    Spacer()
                                    
                                    Text(player.formattedSecondsPlayed)
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondary)    // <- NEW THEME MANAGER
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)           // Better looking <- NEW THEME MANAGER
                .scrollContentBackground(.hidden)   // Remove default background <- NEW THEME MANAGER
                .background(themeManager.colors.background)  // Add themed background <- NEW THEME MANAGER
                
                // Next substitution info
                if let nextSub = session.substitutionPlans.first(where: { !$0.isCompleted }) {
                    VStack {
                        Text("Next sub at \(nextSub.formattedTime)")
                            .font(.caption)
                            //.foregroundColor(.secondary)
                            .foregroundColor(themeManager.colors.secondary)    // <- NEW THEME MANAGER
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Game Running")
    }
}

struct PlayerStatRow: View {
    let player: PlayerGameStats
    let isOnField: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isOnField ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(player.playerName)
                .font(.body)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(player.formattedSecondsPlayed)
                    .font(.body)
                    .fontWeight(.semibold)
                
                if isOnField && player.continuousSecondsPlayed > 0 {
                    Text("(\(player.formattedContinuousTime) cont.)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
