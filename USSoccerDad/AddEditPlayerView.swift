//
//  AddEditPlayerView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/18/25.
//


import SwiftUI

struct AddEditPlayerView: View {
    @State private var player: Player

    var onSave: (Player) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var jerseyText: String = ""
    @State private var notes: String = ""
    
    @State private var canPlayGK: Bool = false
    @State private var canPlayAttack: Bool = false
    @State private var canPlayDefense: Bool = false
    
    @State private var minutesText: String = ""

    
    @State private var showValidationError = false

    init(player: Player,
         onSave: @escaping (Player) -> Void,
         onCancel: @escaping () -> Void) {
        _player = State(initialValue: player)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        Form {
            Section(header: Text("Player Info")) {
                TextField("Name", text: $name)

                TextField("Jersey Number", text: $jerseyText)
                    .keyboardType(.numberPad)

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(1...4)
            }
            Section(header: Text("Positions")) {
                Toggle("Goalkeeper", isOn: $canPlayGK)
                Toggle("Defense", isOn: $canPlayDefense)
                Toggle("Attack", isOn: $canPlayAttack)

            }
            
            Section(header: Text("Season Stats")) {
                TextField("Total Minutes Played", text: $minutesText)
                    .keyboardType(.numberPad)
            }


            if showValidationError {
                Section {
                    Text("Please enter a name.")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(player.name.isEmpty ? "New Player" : "Edit Player")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    onCancel()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
            }
        }
        .onAppear {
            name = player.name
            if let num = player.jerseyNumber {
                jerseyText = String(num)
            }
            notes = player.notes ?? ""
            canPlayGK = player.canPlayGK
            canPlayDefense = player.canPlayDefense
            canPlayAttack = player.canPlayAttack

            
            // NEW
            minutesText = String(player.totalMinutesPlayed)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }

        player.name = trimmedName
        player.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedJersey = jerseyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let n = Int(trimmedJersey) {
            player.jerseyNumber = n
        } else {
            player.jerseyNumber = nil
        }
        
        player.canPlayGK = canPlayGK
        player.canPlayAttack = canPlayAttack
        player.canPlayDefense = canPlayDefense

        // NEW: parse minutes
        let trimmedMinutes = minutesText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let m = Int(trimmedMinutes), m >= 0 {
            player.totalMinutesPlayed = m
        } else {
            player.totalMinutesPlayed = 0
        }

        
        onSave(player)
    }
}
