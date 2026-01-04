//
//  EndOfGameReportView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/18/25.
//


import SwiftUI

struct EndOfGameReportView: View {
    let state: GameState

    var body: some View {
        List {
            Section("Minutes Played") {
                ForEach(minutesPlayed) { p in
                    Text("\(p.name): \(p.minutesThisGame) min")
                }
            }

            Section("Not Available") {
                let na = state.players.filter { !$0.isAvailable }
                if na.isEmpty {
                    Text("None")
                } else {
                    ForEach(na) { p in
                        Text(p.name)
                    }
                }
            }

            Section("Injured") {
                let injured = state.players.filter { $0.isInjured }
                if injured.isEmpty {
                    Text("None")
                } else {
                    ForEach(injured) { p in
                        Text(p.name)
                    }
                }
            }
        }
        .navigationTitle("End of Game Report")
    }

    private var minutesPlayed: [PlayerGameRuntime] {
        state.players
            .filter { $0.isAvailable }
            .sorted { $0.minutesThisGame > $1.minutesThisGame }
    }
}
