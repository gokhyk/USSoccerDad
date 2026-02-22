//
//  PeriodBreakView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct PeriodBreakView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
            return themeManager.colors.primary
        } else {
            return themeManager.colors.error
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Break title
            Text(isHalfTime ? "Half Time" : "Break")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Countdown — tappable to start period when auto-start is off
            let countdownContent = VStack(spacing: 8) {
                Text(formatTime(remainingSeconds))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(breakColor)

                Text("remaining")
                    .font(.headline)
                    .foregroundColor(themeManager.colors.textSecondary)

                if !viewModel.autoStartAfterBreak {
                    Text("Tap to start period \(periodNumber + 1)")
                        .font(.caption)
                        .foregroundColor(breakColor.opacity(0.8))
                        .padding(.top, 4)
                }
            }
            .padding(40)
            .background(breakColor.opacity(0.1))
            .cornerRadius(20)

            if viewModel.autoStartAfterBreak {
                countdownContent
            } else {
                Button(action: { viewModel.startPeriod() }) {
                    countdownContent
                }
                .buttonStyle(.plain)
            }

            // Next period lineup preview
            if let session = session {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Next Period Lineup")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.colors.success)

                    let nextLineup = SubstitutionEngine.calculateNextPeriodLineup(session: session)
                    let nextPlayers = session.playerStats.filter { nextLineup.contains($0.id) }

                    ForEach(nextPlayers.sorted(by: { $0.playerName < $1.playerName })) { player in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(themeManager.colors.success)
                                .font(.body)
                            Text(player.playerName)
                                .font(.system(size: 19))
                                .foregroundColor(themeManager.colors.success)
                            Spacer()
                            Text(player.formattedSecondsPlayed)
                                .font(.footnote)
                                .foregroundColor(themeManager.colors.success.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(themeManager.colors.success.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()
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
