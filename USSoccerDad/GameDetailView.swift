//
//  GameDetailView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/19/25.
//

import EventKit
import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject var gameStore: GameStore

    let gameId: UUID
    let team: TeamSettings
    let playerRepo: PlayerRepository

    @State private var game: Game?
    @State private var errorMessage: String?
    
    @State private var showCalendarSheet = false
    @State private var calendarEvent: EKEvent?
    @State private var calendarError: String?

    private let eventStore = EKEventStore()



    var body: some View {
        Group {
            if let g = game {
                Form {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }

                    Section(header: Text("Details")) {
                        TextField("Opponent", text: bindingString(\.opponent))

                        DatePicker(
                            "Date",
                            selection: bindingDate(\.date),
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        TextField("Location", text: bindingOptionalString(\.location))

                        Stepper(
                            "Minutes per Period: \(g.minutesPerPeriod)",
                            value: bindingInt(\.minutesPerPeriod),
                            in: 5...60
                        )

                        Stepper(
                            "Players on Field: \(g.playersOnField)",
                            value: bindingInt(\.playersOnField),
                            in: 3...11
                        )
                    }

//                    Section(header: Text("Notes")) {
//                        TextField("Notes", text: bindingOptionalString(\.notes), axis: .vertical)
//                            .lineLimit(3...8)
//                    }

                    Section {
                        Button("Save Changes") {
                            gameStore.upsert(g)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section {
                        NavigationLink("Set Availability") {
                            AvailabilityView(gameId: g.id, team: team)
                        }

                        NavigationLink("Lineup Generator") {
                            LineupGeneratorView(gameId: g.id, team: team, playerRepo: playerRepo)
                        }
                    }
                    
                    Section(header: Text("Calendar")) {
                        if let calendarError {
                            Text(calendarError)
                                .foregroundStyle(.red)
                        }

                        Button("Add to Calendar") {
                            Task { await addToCalendar() }
                        }
                    }


                }
            } else {
                Text("Game not found.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Game")
        .onAppear { reload() }
        .onReceive(gameStore.$games) { _ in reload() }
    }

    private func reload() {
        game = gameStore.game(withId: gameId)
    }

    // MARK: - Bindings into @State game

    private func bindingString(_ keyPath: WritableKeyPath<Game, String>) -> Binding<String> {
        Binding(
            get: { game?[keyPath: keyPath] ?? "" },
            set: { game?[keyPath: keyPath] = $0 }
        )
    }

    private func bindingOptionalString(_ keyPath: WritableKeyPath<Game, String?>) -> Binding<String> {
        Binding(
            get: { game?[keyPath: keyPath] ?? "" },
            set: { game?[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func bindingInt(_ keyPath: WritableKeyPath<Game, Int>) -> Binding<Int> {
        Binding(
            get: { game?[keyPath: keyPath] ?? 0 },
            set: { game?[keyPath: keyPath] = $0 }
        )
    }

    private func bindingDate(_ keyPath: WritableKeyPath<Game, Date>) -> Binding<Date> {
        Binding(
            get: { game?[keyPath: keyPath] ?? Date() },
            set: { game?[keyPath: keyPath] = $0 }
        )
    }
    
    private func makeCalendarEvent(from game: Game) -> EKEvent {
        let ev = EKEvent(eventStore: eventStore)

        // Title
        let opponentPart = game.opponent.isEmpty ? "Game" : "vs \(game.opponent)"
        ev.title = "Soccer \(opponentPart)"

        // Start/end
        ev.startDate = game.date

        // Simple duration: 2 halves. (You can adjust later to add breaks.)
        let durationMinutes = max(10, game.minutesPerPeriod * 2)
        ev.endDate = game.date.addingTimeInterval(TimeInterval(durationMinutes * 60))

        // Location/notes
        if let loc = game.location, !loc.isEmpty {
            ev.location = loc
        }
        if let notes = game.notes, !notes.isEmpty {
            ev.notes = notes
        }

        ev.calendar = eventStore.defaultCalendarForNewEvents
        return ev
    }

    private func addToCalendar() async {
        calendarError = nil

        guard let g = game else {
            calendarError = "Game is not loaded."
            return
        }

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                calendarError = "Calendar access was not granted."
                return
            }

            // Prepare event and open Apple's editor UI so user can confirm/save
            calendarEvent = makeCalendarEvent(from: g)
            showCalendarSheet = true

        } catch {
            calendarError = "Calendar access error: \(error.localizedDescription)"
        }
    }

}
