//
//  LineupGeneratorView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import SwiftUI

struct LineupGeneratorView: View {
    let gameId: UUID
    let team: TeamSettings

    var body: some View {
        VStack(spacing: 16) {
            Text("Lineup Generator")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Here we will use:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("• Team settings (players on field, minutes per half)")
                Text("• Player positions (GK / Attack / Defense)")
                Text("• Availability for this game")
                Text("• Total minutes played as tiebreaker")
            }
            .font(.subheadline)

            Spacer()
        }
        .padding()
        .navigationTitle("Lineup")
    }
}
