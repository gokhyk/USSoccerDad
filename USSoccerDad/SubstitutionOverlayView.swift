//
//  SubstitutionOverlayView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct SubstitutionOverlayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    let plan: SubstitutionPlan
    
    var session: GameSession? {
        viewModel.session
    }
    
    var secondsUntilSub: Int {
        guard let session = session else { return 0 }
        return max(0, plan.scheduledTime - session.periodElapsedSeconds)
    }
    
    var countdownColor: Color {
        if secondsUntilSub > 30 {
            return themeManager.colors.success
        } else if secondsUntilSub > 15 {
            return themeManager.colors.warning
        } else {
            return themeManager.colors.error
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Countdown timer — tap to complete early
            let countdownContent = VStack(spacing: 8) {
                Text(secondsUntilSub > 0 ? "Substitution in" : "Make Substitution")
                    .font(.headline)
                    .foregroundColor(.white)

                if secondsUntilSub > 0 {
                    Text("\(secondsUntilSub)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("seconds")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                if secondsUntilSub > 0 {
                    Text(viewModel.autoCompleteSubstitutions ? "Tap to complete early · or auto" : "Tap to complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)
                }
            }
            .padding(32)
            .background(countdownColor)
            .cornerRadius(20)

            Button(action: { viewModel.executeSubstitution(plan: plan) }) {
                countdownContent
            }
            .buttonStyle(.plain)

            // Substitution pairs
            VStack(spacing: 10) {
                ForEach(Array(zip(playersOut, playersIn).enumerated()), id: \.offset) { _, pair in
                    let (out, inn) = pair
                    HStack(spacing: 0) {
                        // In player (green, left) — arrow points from here →
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(themeManager.colors.success)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(inn.playerName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.success)
                                    .lineLimit(1)
                                Text(inn.formattedSecondsPlayed)
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.success.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.textSecondary)
                            .padding(.horizontal, 8)

                        // Out player (red, right) — arrow points to here
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(out.playerName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.error)
                                    .lineLimit(1)
                                Text(out.formattedContinuousTime)
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.error.opacity(0.7))
                            }
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(themeManager.colors.error)
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [themeManager.colors.success.opacity(0.08), themeManager.colors.error.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var playersOut: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats.filter { plan.playersOut.contains($0.id) }
    }
    
    private var playersIn: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats.filter { plan.playersIn.contains($0.id) }
    }
}
