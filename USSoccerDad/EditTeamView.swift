//
//  EditTeamView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/18/25.
//


import SwiftUI

struct EditTeamView: View {
    @State private var team: TeamSettings
    var onSave: (TeamSettings) -> Void

    @Environment(\.dismiss) private var dismiss

    // Local validation
    @State private var showValidationError = false

    init(team: TeamSettings, onSave: @escaping (TeamSettings) -> Void) {
        _team = State(initialValue: team)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text("Team Info")) {
                TextField("Team Name", text: $team.name)

                Picker("Age Group", selection: $team.ageGroup) {
                    ForEach(AgeGroup.allCases) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
            }

            Section(header: Text("Game Settings")) {
                Stepper("Players on Field: \(team.playersOnField)",
                        value: $team.playersOnField,
                        in: 3...11)

                Stepper("Number of Periods: \(team.numberOfPeriods)",
                        value: $team.numberOfPeriods,
                        in: 1...6)

                Stepper("Minutes per Period: \(team.minutesPerPeriod)",
                        value: $team.minutesPerPeriod,
                        in: 5...60)

                Toggle("Dedicated Goalkeeper", isOn: $team.hasDedicatedGoalkeeper)
            }

            if showValidationError {
                Section {
                    Text("Please enter a team name.")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Team")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
            }
        }
    }

    private func save() {
        let trimmedName = team.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }

        team.name = trimmedName
        onSave(team)
        dismiss()
    }
}
