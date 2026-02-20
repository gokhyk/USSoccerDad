//
//  USSoccerDadTests.swift
//  USSoccerDadTests
//
//  Comprehensive tests for Youth Soccer Management
//

import XCTest
@testable import USSoccerDad

final class USSoccerDadTests: XCTestCase {
    
    // MARK: - Player Tests
    
    func testPlayerCreation() {
        // Given
        let teamId = UUID()
        
        // When
        let player = Player(
            id: UUID(),
            teamId: teamId,
            name: "John Smith",
            jerseyNumber: 10,
            notes: "Strong defender",
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true,
            totalMinutesPlayed: 150
        )
        
        // Then
        XCTAssertEqual(player.name, "John Smith")
        XCTAssertEqual(player.jerseyNumber, 10)
        XCTAssertEqual(player.notes, "Strong defender")
        XCTAssertFalse(player.canPlayGK)
        XCTAssertTrue(player.canPlayAttack)
        XCTAssertTrue(player.canPlayDefense)
        XCTAssertEqual(player.totalMinutesPlayed, 150)
    }
    
    func testPlayerEquality() {
        // Given
        let id = UUID()
        let teamId = UUID()
        
        let player1 = Player(
            id: id,
            teamId: teamId,
            name: "Test Player",
            jerseyNumber: 5,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true,
            totalMinutesPlayed: 0
        )
        
        let player2 = Player(
            id: id,
            teamId: teamId,
            name: "Test Player",
            jerseyNumber: 5,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true,
            totalMinutesPlayed: 0
        )
        
        // Then
        XCTAssertEqual(player1, player2, "Players with same properties should be equal")
    }
    
    func testPlayerWithoutJerseyNumber() {
        // Given/When
        let player = Player(
            id: UUID(),
            teamId: UUID(),
            name: "New Player",
            jerseyNumber: nil,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true
        )
        
        // Then
        XCTAssertNil(player.jerseyNumber, "Player should be created without jersey number")
        XCTAssertEqual(player.totalMinutesPlayed, 0, "Default minutes should be 0")
    }
    
    // MARK: - Age Group Tests
    
    func testAgeGroupCases() {
        // Test all age groups exist
        let allAges: [AgeGroup] = [.u5, .u6, .u7, .u8, .u9, .u10, .u11, .u12, .u13, .u14, .u15, .u16, .u17]
        
        XCTAssertEqual(AgeGroup.allCases.count, 13, "Should have 13 age groups")
        
        for age in allAges {
            XCTAssertNotNil(age.rawValue, "Age group should have raw value")
            XCTAssertEqual(age.id, age.rawValue, "ID should match raw value")
        }
    }
    
    func testAgeGroupRawValues() {
        XCTAssertEqual(AgeGroup.u5.rawValue, "U5")
        XCTAssertEqual(AgeGroup.u10.rawValue, "U10")
        XCTAssertEqual(AgeGroup.u17.rawValue, "U17")
    }
    
    // MARK: - TeamSettings Tests
    
    func testTeamSettingsU7Defaults() {
        // When
        let team = TeamSettings.defaults(for: .u7, name: "Blue Dragons")
        
        // Then
        XCTAssertEqual(team.name, "Blue Dragons")
        XCTAssertEqual(team.ageGroup, .u7)
        XCTAssertEqual(team.playersOnField, 4, "U7 should have 4 players on field")
        XCTAssertEqual(team.numberOfPeriods, 4, "U7 should have 4 periods")
        XCTAssertEqual(team.minutesPerPeriod, 10, "U7 periods should be 10 minutes")
        XCTAssertFalse(team.hasDedicatedGoalkeeper, "U7 should not have dedicated GK")
    }
    
    func testTeamSettingsU9Defaults() {
        // When
        let team = TeamSettings.defaults(for: .u9, name: "Red Lions")
        
        // Then
        XCTAssertEqual(team.ageGroup, .u9)
        XCTAssertEqual(team.playersOnField, 6, "U9 should have 6 players on field")
        XCTAssertEqual(team.numberOfPeriods, 2, "U9 should have 2 periods")
        XCTAssertEqual(team.minutesPerPeriod, 25, "U9 periods should be 25 minutes")
        XCTAssertTrue(team.hasDedicatedGoalkeeper, "U9 should have dedicated GK")
    }
    
    func testTeamSettingsU11Defaults() {
        // When
        let team = TeamSettings.defaults(for: .u11, name: "Green Warriors")
        
        // Then
        XCTAssertEqual(team.playersOnField, 8, "U11 should have 8 players on field")
        XCTAssertEqual(team.numberOfPeriods, 2, "U11 should have 2 periods")
        XCTAssertEqual(team.minutesPerPeriod, 30, "U11 periods should be 30 minutes")
        XCTAssertTrue(team.hasDedicatedGoalkeeper, "U11 should have dedicated GK")
    }
    
    func testTeamSettingsU17Defaults() {
        // When
        let team = TeamSettings.defaults(for: .u17, name: "Elite Squad")
        
        // Then
        XCTAssertEqual(team.playersOnField, 11, "U17 should have 11 players on field")
        XCTAssertEqual(team.numberOfPeriods, 2, "U17 should have 2 periods")
        XCTAssertEqual(team.minutesPerPeriod, 35, "U17 periods should be 35 minutes")
        XCTAssertTrue(team.hasDedicatedGoalkeeper, "U17 should have dedicated GK")
    }
    
    func testTeamSettingsEquality() {
        // Given
        let team1 = TeamSettings.defaults(for: .u10, name: "Team A")
        let team2 = TeamSettings.defaults(for: .u10, name: "Team A")
        
        // When - Modify to have same ID
        var team2Modified = team2
        team2Modified.id = team1.id
        
        // Then
        XCTAssertEqual(team1, team2Modified, "Teams with same properties should be equal")
    }
    
    // MARK: - SubstitutionIntensity Tests
    
    func testSubstitutionIntensityU7Frequent() {
        // Given
        let intensity = SubstitutionIntensity.frequent
        let periodSeconds = 600 // 10 minutes
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u7)
        
        // Then
        XCTAssertEqual(times.count, 3, "U7 Frequent should have 3 subs")
        XCTAssertEqual(times[0], 150, "First sub at 2.5 min (150s)")
        XCTAssertEqual(times[1], 300, "Second sub at 5 min (300s)")
        XCTAssertEqual(times[2], 450, "Third sub at 7.5 min (450s)")
        
        // Verify no sub within 90s of period end
        for time in times {
            XCTAssertLessThanOrEqual(time, periodSeconds - 90, "No sub within 90s of end")
        }
    }
    
    func testSubstitutionIntensityU9Frequent() {
        // Given
        let intensity = SubstitutionIntensity.frequent
        let periodSeconds = 1500 // 25 minutes
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u9)
        
        // Then
        XCTAssertEqual(times.count, 4, "U9 Frequent should have 4 subs")
        XCTAssertEqual(times[0], 300, "First sub at 5 min")
        XCTAssertEqual(times[1], 600, "Second sub at 10 min")
        XCTAssertEqual(times[2], 900, "Third sub at 15 min")
        XCTAssertEqual(times[3], 1200, "Fourth sub at 20 min")
    }
    
    func testSubstitutionIntensityU7Balanced() {
        // Given
        let intensity = SubstitutionIntensity.balanced
        let periodSeconds = 600
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u7)
        
        // Then
        XCTAssertEqual(times.count, 2, "U7 Balanced should have 2 subs")
        XCTAssertEqual(times[0], 200, "First sub at 3.33 min")
        XCTAssertEqual(times[1], 400, "Second sub at 6.67 min")
    }
    
    func testSubstitutionIntensityU11Balanced() {
        // Given
        let intensity = SubstitutionIntensity.balanced
        let periodSeconds = 1800 // 30 minutes
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u11)
        
        // Then
        XCTAssertEqual(times.count, 3, "U11 Balanced should have 3 subs")
        XCTAssertEqual(times[0], 450, "First sub at 7.5 min")
        XCTAssertEqual(times[1], 900, "Second sub at 15 min")
        XCTAssertEqual(times[2], 1350, "Third sub at 22.5 min")
    }
    
    func testSubstitutionIntensityU7Infrequent() {
        // Given
        let intensity = SubstitutionIntensity.infrequent
        let periodSeconds = 600
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u7)
        
        // Then
        XCTAssertEqual(times.count, 1, "U7 Infrequent should have 1 sub")
        XCTAssertEqual(times[0], 300, "Sub at 5 min (halfway)")
    }
    
    func testSubstitutionIntensityU11Infrequent() {
        // Given
        let intensity = SubstitutionIntensity.infrequent
        let periodSeconds = 1800
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u11)
        
        // Then
        XCTAssertEqual(times.count, 2, "U11 Infrequent should have 2 subs")
        XCTAssertEqual(times[0], 600, "First sub at 10 min")
        XCTAssertEqual(times[1], 1200, "Second sub at 20 min")
    }
    
    func testSubstitutionIntensityFilters90SecondRule() {
        // Given: A short period where last sub would be too close to end
        let intensity = SubstitutionIntensity.frequent
        let periodSeconds = 300 // 5 minutes
        
        // When
        let times = intensity.substitutionTimes(periodSeconds: periodSeconds, ageGroup: .u7)
        
        // Then: Should only include subs more than 90s before end
        for time in times {
            XCTAssertLessThanOrEqual(time, periodSeconds - 90,
                                    "Sub at \(time)s violates 90-second rule")
        }
    }
    
    func testSubstitutionIntensityDescriptions() {
        XCTAssertEqual(SubstitutionIntensity.frequent.description,
                      "More frequent substitutions (3-4 per period)")
        XCTAssertEqual(SubstitutionIntensity.balanced.description,
                      "Balanced substitutions (2-3 per period)")
        XCTAssertEqual(SubstitutionIntensity.infrequent.description,
                      "Less frequent substitutions (1-2 per period)")
    }
    
    func testSubstitutionIntensityAllCases() {
        let allCases = SubstitutionIntensity.allCases
        
        XCTAssertEqual(allCases.count, 3, "Should have 3 intensity levels")
        XCTAssertTrue(allCases.contains(.frequent))
        XCTAssertTrue(allCases.contains(.balanced))
        XCTAssertTrue(allCases.contains(.infrequent))
    }
    
    // MARK: - GameConfig Tests
    
    func testGameConfigInitialization() {
        // When
        let config = GameConfig(
            minutesPerPeriod: 25,
            periods: 2,
            playersOnField: 7,
            minPlayersToStart: 5,
            ageGroup: .u9
        )
        
        // Then
        XCTAssertEqual(config.minutesPerPeriod, 25)
        XCTAssertEqual(config.periods, 2)
        XCTAssertEqual(config.playersOnField, 7)
        XCTAssertEqual(config.minPlayersToStart, 5)
        XCTAssertEqual(config.ageGroup, .u9)
    }
    
    func testGameConfigPeriodSeconds() {
        // Given
        let config = GameConfig(
            minutesPerPeriod: 30,
            periods: 2,
            playersOnField: 9,
            minPlayersToStart: 7,
            ageGroup: .u11
        )
        
        // Then
        XCTAssertEqual(config.periodSeconds, 1800, "30 minutes = 1800 seconds")
    }
    
    func testGameConfigTotalGameSeconds() {
        // Given
        let config = GameConfig(
            minutesPerPeriod: 10,
            periods: 4,
            playersOnField: 5,
            minPlayersToStart: 4,
            ageGroup: .u7
        )
        
        // Then
        XCTAssertEqual(config.totalGameSeconds, 2400, "4 × 10 min = 2400 seconds")
    }
    
    func testGameConfigDefaultBreakDurations() {
        // Given
        let config = GameConfig(
            minutesPerPeriod: 10,
            periods: 4,
            playersOnField: 5,
            minPlayersToStart: 4,
            ageGroup: .u7
        )
        
        // Then
        XCTAssertEqual(config.breakDurations.count, 9, "Should have pregame + 4 periods + 3 breaks + postgame")
        XCTAssertEqual(config.breakDurations[0], 0, "Pregame break should be 0")
        XCTAssertEqual(config.breakDurations[8], 0, "Postgame break should be 0")
    }
    
    func testGameConfigBreakAfterPeriod() {
        // Given
        let config = GameConfig(
            minutesPerPeriod: 25,
            periods: 2,
            playersOnField: 7,
            minPlayersToStart: 5,
            ageGroup: .u9
        )
        
        // When
        let breakAfterPeriod1 = config.breakAfterPeriod(1)
        
        // Then
        XCTAssertEqual(breakAfterPeriod1, 600, "U9 halftime should be 10 min (600s)")
    }
    
    func testGameConfigCustomBreakDurations() {
        // Given
        let customBreaks = [0, 600, 120, 600, 300, 600, 120, 600, 0]
        
        // When
        let config = GameConfig(
            minutesPerPeriod: 10,
            periods: 4,
            playersOnField: 5,
            minPlayersToStart: 4,
            ageGroup: .u7,
            breakDurations: customBreaks
        )
        
        // Then
        XCTAssertEqual(config.breakDurations, customBreaks, "Should use custom break durations")
    }
    
    func testGameConfigEquality() {
        // Given
        let config1 = GameConfig(
            minutesPerPeriod: 25,
            periods: 2,
            playersOnField: 7,
            minPlayersToStart: 5,
            ageGroup: .u9
        )
        
        let config2 = GameConfig(
            minutesPerPeriod: 25,
            periods: 2,
            playersOnField: 7,
            minPlayersToStart: 5,
            ageGroup: .u9
        )
        
        // Then
        XCTAssertEqual(config1, config2, "Configs with same properties should be equal")
    }
    
    // MARK: - Integration Tests
    
    func testTeamSettingsToGameConfig() {
        // Given
        let team = TeamSettings.defaults(for: .u9, name: "Test Team")
        
        // When
        let config = GameConfig(
            minutesPerPeriod: team.minutesPerPeriod,
            periods: team.numberOfPeriods,
            playersOnField: team.playersOnField,
            minPlayersToStart: max(3, team.playersOnField - 2),
            ageGroup: team.ageGroup
        )
        
        // Then
        XCTAssertEqual(config.minutesPerPeriod, 25)
        XCTAssertEqual(config.periods, 2)
        XCTAssertEqual(config.playersOnField, 6)
        XCTAssertEqual(config.ageGroup, .u9)
    }
    
    func testPlayerMinutesAccumulation() {
        // Given
        var player = Player(
            id: UUID(),
            teamId: UUID(),
            name: "Test Player",
            jerseyNumber: 10,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true,
            totalMinutesPlayed: 100
        )
        
        // When: Player plays 25 more minutes
        player.totalMinutesPlayed += 25
        
        // Then
        XCTAssertEqual(player.totalMinutesPlayed, 125, "Minutes should accumulate")
    }
    
    // MARK: - Edge Case Tests
    
    func testMinimumPlayersRequired() {
        // Given
        let config = GameConfig(
            minutesPerPeriod: 25,
            periods: 2,
            playersOnField: 7,
            minPlayersToStart: 5,
            ageGroup: .u9
        )
        
        // Then
        XCTAssertLessThan(config.minPlayersToStart, config.playersOnField,
                         "Min players should be less than players on field")
    }
    
    func testTeamWithoutName() {
        // When
        let team = TeamSettings.defaults(for: .u10, name: "")
        
        // Then
        XCTAssertEqual(team.name, "", "Team should allow empty name during setup")
    }
    
    func testAllAgeGroupsHaveDefaults() {
        // Test that all age groups can create default settings
        for ageGroup in AgeGroup.allCases {
            let team = TeamSettings.defaults(for: ageGroup, name: "Test")
            
            XCTAssertNotNil(team)
            XCTAssertGreaterThan(team.playersOnField, 0)
            XCTAssertGreaterThan(team.numberOfPeriods, 0)
            XCTAssertGreaterThan(team.minutesPerPeriod, 0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testSubstitutionCalculationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = SubstitutionIntensity.frequent.substitutionTimes(
                    periodSeconds: 1800,
                    ageGroup: .u11
                )
            }
        }
    }
    
    func testTeamSettingsCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = TeamSettings.defaults(for: .u10, name: "Performance Test")
            }
        }
    }
}

// MARK: - Mock Player Repository

class MockPlayerRepository: PlayerRepository {
    private var players: [Player] = []
    
    func listPlayers(teamId: UUID, search: String?) async throws -> [Player] {
        var filtered = players.filter { $0.teamId == teamId }
        
        if let search = search, !search.isEmpty {
            filtered = filtered.filter { $0.name.lowercased().contains(search.lowercased()) }
        }
        
        return filtered
    }
    
    func upsert(player: Player) async throws {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        } else {
            players.append(player)
        }
    }
    
    func delete(playerId: UUID) async throws {
        players.removeAll { $0.id == playerId }
    }
    
    // Test helper
    func addTestPlayer(_ player: Player) {
        players.append(player)
    }
    
    // Test helper
    func getAllPlayers() -> [Player] {
        return players
    }
}

// MARK: - PlayerRepository Tests

final class PlayerRepositoryTests: XCTestCase {
    var repository: MockPlayerRepository!
    let teamId = UUID()
    
    override func setUp() {
        super.setUp()
        repository = MockPlayerRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testListPlayersEmpty() async throws {
        // When
        let players = try await repository.listPlayers(teamId: teamId, search: nil)
        
        // Then
        XCTAssertEqual(players.count, 0, "Should start with no players")
    }
    
    func testUpsertNewPlayer() async throws {
        // Given
        let player = Player(
            id: UUID(),
            teamId: teamId,
            name: "New Player",
            jerseyNumber: 5,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true
        )
        
        // When
        try await repository.upsert(player: player)
        let players = try await repository.listPlayers(teamId: teamId, search: nil)
        
        // Then
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players.first?.name, "New Player")
    }
    
    func testUpsertUpdatePlayer() async throws {
        // Given
        let playerId = UUID()
        var player = Player(
            id: playerId,
            teamId: teamId,
            name: "Original Name",
            jerseyNumber: 5,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true
        )
        
        try await repository.upsert(player: player)
        
        // When: Update the player
        player.name = "Updated Name"
        player.totalMinutesPlayed = 50
        try await repository.upsert(player: player)
        
        let players = try await repository.listPlayers(teamId: teamId, search: nil)
        
        // Then
        XCTAssertEqual(players.count, 1, "Should still have only 1 player")
        XCTAssertEqual(players.first?.name, "Updated Name")
        XCTAssertEqual(players.first?.totalMinutesPlayed, 50)
    }
    
    func testDeletePlayer() async throws {
        // Given
        let player = Player(
            id: UUID(),
            teamId: teamId,
            name: "To Delete",
            jerseyNumber: 10,
            notes: nil,
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true
        )
        
        try await repository.upsert(player: player)
        
        // When
        try await repository.delete(playerId: player.id)
        let players = try await repository.listPlayers(teamId: teamId, search: nil)
        
        // Then
        XCTAssertEqual(players.count, 0, "Player should be deleted")
    }
    
    func testSearchPlayers() async throws {
        // Given
        let players = [
            Player(id: UUID(), teamId: teamId, name: "John Smith", jerseyNumber: 1, notes: nil, canPlayGK: true, canPlayAttack: true, canPlayDefense: true),
            Player(id: UUID(), teamId: teamId, name: "Jane Doe", jerseyNumber: 2, notes: nil, canPlayGK: false, canPlayAttack: true, canPlayDefense: true),
            Player(id: UUID(), teamId: teamId, name: "Bob Johnson", jerseyNumber: 3, notes: nil, canPlayGK: false, canPlayAttack: true, canPlayDefense: true)
        ]
        
        for player in players {
            try await repository.upsert(player: player)
        }
        
        // When
        let searchResults = try await repository.listPlayers(teamId: teamId, search: "john")
        
        // Then
        XCTAssertEqual(searchResults.count, 2, "Should find John Smith and Bob Johnson")
    }
}
