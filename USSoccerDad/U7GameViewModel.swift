//
//  U7GameViewModel.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/1/25.
//


import Foundation

@MainActor
final class U7GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var players: [Player] = []

    let teamId: UUID
    private let playerRepo: PlayerRepository
    private let engine: U7LineupEngine

    init(
        teamId: UUID,
        playerRepo: PlayerRepository,
        engine: U7LineupEngine = DefaultU7LineupEngine()
    ) {
        self.teamId = teamId
        self.playerRepo = playerRepo
        self.engine = engine
    }

    func loadPlayers() async {
        do {
            let result = try await playerRepo.listPlayers(teamId: teamId, search: nil)
            self.players = result.sorted { a, b in
                let ja = a.jerseyNumber ?? Int.max
                let jb = b.jerseyNumber ?? Int.max
                if ja != jb { return ja < jb }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch {
            print("Failed to load players: \(error)")
        }
    }

    func startGame(
        intensity: SubstitutionIntensity,
        availableIds: Set<UUID>
    ) {
        let config = GameConfig(
            minutesPerQuarter: 10,
            quarters: 4,
            playersOnField: 4,
            minPlayersToStart: 3
        )

        let snapshots = players.seasonSnapshotsForLineup()
        let availability = players.availabilityList(availableIds: availableIds)

        let state = engine.initializeGame(
            config: config,
            intensity: intensity,
            roster: snapshots,
            availability: availability
        )

        self.gameState = state
    }

    func advanceOneMinute() {
        guard var state = gameState else { return }
        _ = engine.advanceOneMinute(state: &state)
        gameState = state
    }

    func simulateFullGame() {
        guard var state = gameState else { return }
        let final = engine.simulateFullGame(state: &state)
        gameState = final
    }

    func applyGameMinutesToPlayers() async {
        guard let state = gameState, state.status == .finished else { return }

        let minutesById = Dictionary(uniqueKeysWithValues:
            state.players.map { ($0.id, $0.minutesThisGame) }
        )

        var updatedPlayers = players

        for i in updatedPlayers.indices {
            let id = updatedPlayers[i].id
            if let gameMinutes = minutesById[id], gameMinutes > 0 {
                updatedPlayers[i].totalMinutesPlayed += gameMinutes
                do {
                    try await playerRepo.upsert(player: updatedPlayers[i])
                } catch {
                    print("Failed to upsert player \(updatedPlayers[i].name): \(error)")
                }
            }
        }

        self.players = updatedPlayers
    }
}
