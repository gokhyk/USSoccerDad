//
//  SetupTeamView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/17/25.
//


import SwiftUI

struct SetupTeamView: View {
    @EnvironmentObject var teamStore: TeamStore

    @State private var teamName: String = ""
    @State private var selectedAgeGroup: AgeGroup = .u10

    // These are editable values derived from age group presets
    @State private var playersOnField: Int = 8
    @State private var numberOfPeriods: Int = 2
    @State private var minutesPerPeriod: Int = 30
    @State private var hasDedicatedGoalkeeper: Bool = true

    @State private var showValidationError = false

    var body: some View {
        Form {
            Section(header: Text("Team Info")) {
                TextField("Team Name", text: $teamName)

                Picker("Age Group", selection: $selectedAgeGroup) {
                    ForEach(AgeGroup.allCases) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
                .onChange(of: selectedAgeGroup) { _, newValue in
                    applyDefaults(for: newValue)
                }
            }

            
            Section(header: Text("Game Settings (auto-filled, but editable)")) {
                Stepper("Players on Field: \(playersOnField)", value: $playersOnField, in: 3...11)
                Stepper("Number of Periods: \(numberOfPeriods)", value: $numberOfPeriods, in: 1...6)
                Stepper("Minutes per Period: \(minutesPerPeriod)", value: $minutesPerPeriod, in: 5...60)

                Toggle("Dedicated Goalkeeper", isOn: $hasDedicatedGoalkeeper)
            }
            

            Section {
                Button(action: saveTeam) {
                    Text("Save Team & Continue")
                        .frame(maxWidth: .infinity)
                }
            }

            if showValidationError {
                Text("Please enter a team name.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Set Up Your Team")
        .onAppear {
            // Ensure defaults are applied when screen appears first time
            applyDefaults(for: selectedAgeGroup)
        }
    }

    private func applyDefaults(for ageGroup: AgeGroup) {
        let defaults = TeamSettings.defaults(for: ageGroup, name: teamName)
        playersOnField = defaults.playersOnField
        numberOfPeriods = defaults.numberOfPeriods
        minutesPerPeriod = defaults.minutesPerPeriod
        hasDedicatedGoalkeeper = defaults.hasDedicatedGoalkeeper
    }

    private func saveTeam() {
        guard !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showValidationError = true
            return
        }

        var team = TeamSettings.defaults(for: selectedAgeGroup, name: teamName.trimmed())
        team.playersOnField = playersOnField
        team.numberOfPeriods = numberOfPeriods
        team.minutesPerPeriod = minutesPerPeriod
        team.hasDedicatedGoalkeeper = hasDedicatedGoalkeeper

        teamStore.setActiveTeam(team)
    }
}

// Tiny helper so we don't keep repeating trim logic:
private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
