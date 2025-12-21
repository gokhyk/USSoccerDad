//
//  LineupGeneratorEngineTests.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/20/25.
//


import XCTest
@testable import USSoccerDad

final class LineupGeneratorEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeRuntimePlayer(
        _ name: String,
        minutes: Int,
        available: Bool,
        id: UUID = UUID()
    ) -> PlayerGameRuntime {
        PlayerGameRuntime(
            id: id,
            name: name,
            seasonMinutesBeforeGame: minutes,
            isAvailable: available,
            isOnField: false,
            minutesThisGame: 0,
            continuousMinutesThisGame: 0
        )
    }

    // MARK: - Tests

    func testStartersCountEqualsPlayersOnFieldWhenEnoughAvailable() {
        let config = TeamSettings(
            id: UUID(),
            name: "TestTeam",
            ageGroup: "U8",
            playersOnField: 4,
            minutesPerHalf: 10,
            numberOfPeriods: 4,
            hasDedicatedGoalkeeper: false
        )

        var players: [PlayerGameRuntime] = []
        for i in 0..<10 {
            players.append(makeRuntimePlayer("P\(i)", minutes: i * 10, available: true))
        }

        // --- CALL YOUR ENGINE HERE ---
        // Replace this line with your actual engine call
        let starters = pickStarters(players: players, playersOnField: config.playersOnField)

        XCTAssertEqual(starters.count, 4)
    }

    func testStartersExcludeUnavailablePlayers() {
        let playersOnField = 4

        let absentID = UUID()
        let players: [PlayerGameRuntime] = [
            makeRuntimePlayer("A", minutes: 0, available: true),
            makeRuntimePlayer("B", minutes: 10, available: true),
            makeRuntimePlayer("ABSENT", minutes: 1, available: false, id: absentID),
            makeRuntimePlayer("D", minutes: 20, available: true),
            makeRuntimePlayer("E", minutes: 30, available: true),
            makeRuntimePlayer("F", minutes: 40, available: true),
        ]

        // --- CALL YOUR ENGINE HERE ---
        let starters = pickStarters(players: players, playersOnField: playersOnField)

        XCTAssertEqual(starters.count, 4)
        XCTAssertFalse(starters.map(\.id).contains(absentID))
    }

    func testStartersPreferLowestSeasonMinutes() {
        let playersOnField = 3

        let low1 = makeRuntimePlayer("Low1", minutes: 5, available: true)
        let low2 = makeRuntimePlayer("Low2", minutes: 10, available: true)
        let low3 = makeRuntimePlayer("Low3", minutes: 15, available: true)
        let high = makeRuntimePlayer("High", minutes: 999, available: true)

        // Intentionally scrambled input order
        let players = [high, low2, low3, low1]

        // --- CALL YOUR ENGINE HERE ---
        let starters = pickStarters(players: players, playersOnField: playersOnField)
        let starterIDs = Set(starters.map(\.id))

        XCTAssertEqual(starterIDs, Set([low1.id, low2.id, low3.id]))
        XCTAssertFalse(starterIDs.contains(high.id))
    }

    func testIfNotEnoughAvailableStartersReturnsOnlyAvailable() {
        let playersOnField = 6

        let available = (0..<4).map { i in
            makeRuntimePlayer("A\(i)", minutes: i, available: true)
        }
        let unavailable = (0..<10).map { i in
            makeRuntimePlayer("U\(i)", minutes: i, available: false)
        }

        // --- CALL YOUR ENGINE HERE ---
        let starters = pickStarters(players: available + unavailable, playersOnField: playersOnField)

        XCTAssertEqual(starters.count, 4)
        XCTAssertEqual(Set(starters.map(\.id)), Set(available.map(\.id)))
    }
}
