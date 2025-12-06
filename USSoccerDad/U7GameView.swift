//
//  U7GameView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/1/25.
//


// U7GameView.swift

import SwiftUI

struct U7GameView: View {
    @ObservedObject var vm: U7GameViewModel

    var body: some View {
        VStack(spacing: 16) {
            if let state = vm.gameState {
                header(state: state)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("On Field")
                        .font(.headline)

                    ForEach(state.players.filter { $0.isOnField }) { p in
                        Text("\(p.name) – game: \(p.minutesThisGame) min, cont: \(p.continuousMinutesThisGame)")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Events")
                            .font(.headline)
                        ForEach(Array(state.events.enumerated()), id: \.offset) { _, event in
                            Text(describe(event: event))
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                HStack {
                    Button("Advance 1 Minute") {
                        vm.advanceOneMinute()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Simulate Full Game") {
                        vm.simulateFullGame()
                    }
                    .buttonStyle(.bordered)
                }

                if state.status == .finished {
                    Button("Apply Minutes to Season") {
                        Task { await vm.applyGameMinutesToPlayers() }
                    }
                }

            } else {
                Text("No game started.")
            }
        }
        .padding()
        .navigationTitle("U5/6/7 Game")
    }

    private func header(state: GameState) -> some View {
        VStack(spacing: 4) {
            Text("Status: \(state.status.rawValue)")
            Text("Quarter \(state.currentQuarter)/\(state.config.quarters)")
            Text("Minute in quarter: \(state.minuteInQuarter)")
            Text("Total minutes: \(state.totalMinutesElapsed)")
        }
        .font(.subheadline)
    }

    private func describe(event: LineupEvent) -> String {
        switch event.type {
        case .initialLineup:
            return "0': Initial lineup (\(event.playersOnField.count) players)"
        case .quarterBreak:
            return "\(event.timeMinute)': Quarter break"
        case .substitution:
            return "\(event.timeMinute)': Sub – in: \(event.playersIn.count), out: \(event.playersOut.count)"
        }
    }
}
