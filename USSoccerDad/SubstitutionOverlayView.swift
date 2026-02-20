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
            return .green
        } else if secondsUntilSub > 15 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Countdown timer
            VStack(spacing: 8) {
                Text("Substitution in")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(secondsUntilSub)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("seconds")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(countdownColor)
            .cornerRadius(20)
            
            // Players out
            VStack(alignment: .leading, spacing: 12) {
                Text("Coming Out")
                    .font(.headline)
                    .foregroundColor(.red)
                
                ForEach(playersOut, id: \.id) { player in
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                        Text(player.playerName)
                            .font(.body)
                        Spacer()
                        Text(player.formattedContinuousTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            // Players in
            VStack(alignment: .leading, spacing: 12) {
                Text("Coming In")
                    .font(.headline)
                    .foregroundColor(.green)
                
                ForEach(playersIn, id: \.id) { player in
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text(player.playerName)
                            .font(.body)
                        Spacer()
                        Text(player.formattedSecondsPlayed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Manual complete button (if auto-complete is off)
            if !viewModel.autoCompleteSubstitutions && secondsUntilSub <= 0 {
                Button(action: {
                    viewModel.executeSubstitution(plan: plan)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Substitution Complete")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
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
