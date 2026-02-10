//
//  ActiveGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct ActiveGameView: View {
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
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                    
                    Text("Total: \(session.formattedTotalElapsed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
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
                                        .foregroundColor(.red)
                                }
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
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
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
                                    
                                    Button("Arrived") {
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
                
                // Next substitution info
                if let nextSub = session.substitutionPlans.first(where: { !$0.isCompleted }) {
                    VStack {
                        Text("Next sub at \(nextSub.formattedTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
