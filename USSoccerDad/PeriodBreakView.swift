//
//  PeriodBreakView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PeriodBreakView: View {
    @ObservedObject var viewModel: GameViewModel
    let periodNumber: Int
    let totalBreakSeconds: Int
    
    var session: GameSession? {
        viewModel.session
    }
    
    var remainingSeconds: Int {
        guard let session = session else { return 0 }
        return max(0, totalBreakSeconds - session.breakElapsedSeconds)
    }
    
    var isHalfTime: Bool {
        guard let session = session else { return false }
        return periodNumber == session.config.periods / 2
    }
    
    var breakColor: Color {
        if remainingSeconds > 15 {
            return .blue
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Break title
            Text(isHalfTime ? "Half Time" : "Break")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Countdown
            VStack(spacing: 8) {
                Text(formatTime(remainingSeconds))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(breakColor)
                
                Text("remaining")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .background(breakColor.opacity(0.1))
            .cornerRadius(20)
            
            // Next period lineup preview
            if let session = session {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Next Period Lineup")
                        .font(.headline)
                    
                    let nextLineup = SubstitutionEngine.calculateNextPeriodLineup(session: session)
                    let nextPlayers = session.playerStats.filter { nextLineup.contains($0.id) }
                    
                    ForEach(nextPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                        HStack {
                            Text(player.playerName)
                            Spacer()
                            Text(player.formattedSecondsPlayed)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Manual start button (if auto-start is off)
            if !viewModel.autoStartAfterBreak && remainingSeconds <= 0 {
                Button(action: {
                    viewModel.startPeriod()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Period \(periodNumber + 1)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle("Period \(periodNumber) Complete")
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
