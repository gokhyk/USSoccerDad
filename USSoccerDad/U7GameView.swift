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


    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()


    var body: some View {
        VStack(spacing: 16) {
            if let state = vm.gameState {
                header(state: state)
                if vm.isRunning {
                    Text("Game: \(vm.gameClockText)")
                        .font(.headline)
                }



                Picker("Speed", selection: $vm.speedMultiplier) {
                    Text("1×").tag(1)
                    Text("5×").tag(5)
                    Text("10×").tag(10)
                }
                .pickerStyle(.segmented)
                .disabled(!vm.isRunning)   // optional

                    

                
                // 🔴 PRIORITY: pending substitution
                if let p = vm.pendingSub {
                    pendingSubstitutionView(p)
                } else if !vm.isRunning {
                    // Pre-kickoff (starters already selected by startGame)
                    Button("START (Whistle)") {
                        vm.startWhistle()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // Running controls
                    Button(vm.isPaused ? "Resume" : "Pause") {
                        vm.togglePause()
                    }
                    .buttonStyle(.bordered)
                }


                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("On Field")
                        .font(.headline)

                    ForEach(state.players.filter { $0.isOnField }) { p in
                        HStack {
                            Text("\(p.name) – cont: \(p.continuousMinutesThisGame), game: \(p.minutesThisGame) min")
                            Spacer()
                            Button("Injured") {vm.markInjured(p.id)}
                                .buttonStyle(.bordered)
                            
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bench")
                        .font(.headline)

                    ForEach(state.players.filter { !$0.isOnField && $0.isAvailable }) { p in
                        HStack {
                            Text("\(p.name) \(p.isInjured ? "🚑" : "") – game: \(p.minutesThisGame) min")
                            Spacer()
                            if p.isInjured {
                                Button("Recovered") { vm.markRecovered(p.id) }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .font(.subheadline)
                    }
                }

                Divider()

//                ScrollView {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Events")
//                            .font(.headline)
////                        ForEach(Array(state.events.enumerated()), id: \.offset) { _, event in
////                            Text(describe(event: event))
////                                .font(.caption)
////                        }
//                        ForEach(Array(state.events.enumerated()), id: \.offset) { _, event in
//                            Text(describe(event: event, in: state))
//                                .font(.caption)
//                        }
//
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }

                Spacer()
//
//                HStack {
//                    Button("Advance 1 Minute") {
//                        vm.advanceOneMinute()
//                    }
//                    .buttonStyle(.borderedProminent)
//
//                    Button("Simulate Full Game") {
//                        vm.simulateFullGame()
//                    }
//                    .buttonStyle(.bordered)
//                }

                if state.status == .finished {
                    Button("Apply Minutes to Season") {
                        Task { await vm.applyGameMinutesToPlayers() }
                    }
                }
                
                if state.status == .finished {
                    NavigationLink("End of Game Report") {
                        EndOfGameReportView(state: state)
                    }
                }


            } else {
                Text("No game started.")
            }
        }
        .onReceive(timer) { _ in
            vm.tickOneSecond()
        }

        //.padding()
        //.navigationTitle("U5/6/7 Game")
    }

    private func header(state: GameState) -> some View {
        VStack(spacing: 4) {
            Text("Status: \(state.status.rawValue) Quarter \(state.currentQuarter)/\(state.config.periods)")
            //Text("Quarter \(state.currentQuarter)/\(state.config.periods)")
            Text("Minute in quarter: \(state.minuteInQuarter) Total minutes: \(state.totalMinutesElapsed)")
            //Text("Total minutes: \(state.totalMinutesElapsed)")
        }
        .font(.subheadline)
    }

//    private func describe(event: LineupEvent) -> String {
//        switch event.type {
//        case .initialLineup:
//            return "0': Initial lineup (\(event.playersOnField.count) players)"
//        case .quarterBreak:
//            return "\(event.timeMinute)': Quarter break"
//        case .substitution:
//            return "\(event.timeMinute)': Sub – in: \(event.playersIn.count), out: \(event.playersOut.count)"
//        }
//    }
    
    private func describe(event: LineupEvent, in state: GameState) -> String {
        let timeLabel = "\(event.timeMinute)'"

        switch event.type {
        case .initialLineup:
            let starters = event.playersOnField.compactMap { id in
                runtime(for: id, in: state)
            }

            let starterText = starters
                .map { p in "\(p.name) (\(statsSummary(p)))" }
                .joined(separator: ", ")

            return "\(timeLabel): INITIAL – \(starterText)"

        case .quarterBreak:
            return "\(timeLabel): QUARTER BREAK"

        case .substitution:
            let outs = event.playersOut.compactMap { id in
                runtime(for: id, in: state)
            }
            let ins = event.playersIn.compactMap { id in
                runtime(for: id, in: state)
            }

            let outsText = outs
                .map { p in "\(p.name) (\(statsSummary(p)))" }
                .joined(separator: ", ")

            let insText = ins
                .map { p in "\(p.name) (\(statsSummary(p)))" }
                .joined(separator: ", ")

            return "\(timeLabel): SUB – OUT: [\(outsText)]  IN: [\(insText)]"
            
        case .injury:
            // Convention: injured player id(s) stored in playersOut
            let injured = event.playersOut.compactMap { id in
                runtime(for: id, in: state)
            }

            let injuredText = injured
                .map { p in "\(p.name) (\(statsSummary(p)))" }
                .joined(separator: ", ")

            return "\(timeLabel): INJURY – [\(injuredText)]"

        case .recovery:
            // Convention: recovered player id(s) stored in playersIn
            let recovered = event.playersIn.compactMap { id in
                runtime(for: id, in: state)
            }

            let recoveredText = recovered
                .map { p in "\(p.name) (\(statsSummary(p)))" }
                .joined(separator: ", ")

            return "\(timeLabel): RECOVERY – [\(recoveredText)]"

        }
    }

    private func runtime(for id: PlayerID, in state: GameState) -> PlayerGameRuntime? {
        state.players.first { $0.id == id }
    }

    private func statsSummary(_ p: PlayerGameRuntime) -> String {
        // You can tweak this string however you like
        "c:\(p.continuousMinutesThisGame) g:\(p.minutesThisGame) s:\(p.seasonMinutesBeforeGame)"
    }

    
    private func name(_ id: PlayerID) -> String {
        vm.gameState?
            .players
            .first(where: { $0.id == id })?
            .name ?? "?"
    }

    private func pendingSubstitutionView(_ p: PendingSubstitution) -> some View {
        VStack(spacing: 16) {

            Text("Substitution in")
                .font(.headline)

            Text("\(p.secondsRemaining)s")
                .font(.largeTitle)
                .foregroundStyle(p.secondsRemaining <= 15 ? .red : .primary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(p.pairs.enumerated()), id: \.offset) { _, pair in
                    let inName = name(pair.in)
                    let outName = name(pair.out)

                    Text("\(inName) replaces \(outName)")
                        .font(.title3)
                }
            }

            Button("OK (Sub Done)") {
                vm.confirmSubstitutionOK()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

}
