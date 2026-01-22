//
//  AddEditGameView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//


import SwiftUI

struct AddEditGameView: View {
    let team: TeamSettings

    @State private var game: Game
    var onSave: (Game) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var opponent: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var minutesPerPeriod: Int = 25
    @State private var playersOnField: Int = 7
    @State private var showValidationError = false

    init(team: TeamSettings,
         game: Game,
         onSave: @escaping (Game) -> Void,
         onCancel: @escaping () -> Void) {
        self.team = team
        _game = State(initialValue: game)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Opponent", text: $opponent)
                DatePicker("Date & Time", selection: $date)
                TextField("Location", text: $location)
            }

            Section(header: Text("Game Settings")) {
                Stepper("Minutes per Half: \(minutesPerPeriod)",
                        value: $minutesPerPeriod,
                        in: 5...60)

                Stepper("Players on Field: \(playersOnField)",
                        value: $playersOnField,
                        in: 3...11)
            }

//            Section(header: Text("Notes")) {
//                TextField("Notes", text: $notes, axis: .vertical)
//                    .lineLimit(1...4)
//            }

            if showValidationError {
                Section {
                    Text("Please enter at least an opponent or some description.")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Game")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
            }
        }
        .onAppear {
            opponent = game.opponent
            location = game.location ?? ""
            notes = game.notes ?? ""
            date = game.date
            minutesPerPeriod = game.minutesPerPeriod
            playersOnField = game.playersOnField
        }
    }

    private func save() {
        // Very light validation
        let trimmedOpponent = opponent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedOpponent.isEmpty && notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError = true
            return
        }

        game.opponent = trimmedOpponent
        game.location = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location
        game.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        game.date = date
        game.minutesPerPeriod = minutesPerPeriod
        game.playersOnField = playersOnField

        onSave(game)
        dismiss()
    }
}
