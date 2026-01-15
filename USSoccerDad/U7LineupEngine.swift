//
//  U7LineupEngine.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/28/25.
//

import Foundation
// MARK: - Shared Types

typealias PlayerID = UUID

enum SubstitutionIntensity: String, Codable {
    case frequent    // interval = minutesPerQuarter / 5
    case balanced    // interval = minutesPerQuarter / 4
    case infrequent  // interval = minutesPerQuarter / 3
}

struct GameConfig: Codable, Equatable {
    let minutesPerQuarter: Int       // e.g. 10
    let quarters: Int                // e.g. 4
    let playersOnField: Int          // e.g. 4
    let minPlayersToStart: Int       // e.g. 3
}

// Season snapshot before this game
struct PlayerSeasonSnapshot: Identifiable, Codable {
    let id: PlayerID
    let name: String
    var seasonMinutesPlayed: Int     // total minutes before this game
}

// Availability per game
struct PlayerAvailability: Identifiable, Codable {
    let id: PlayerID
    var isAvailable: Bool
}

// Runtime stats for this game
struct PlayerGameRuntime: Identifiable, Codable {
    let id: PlayerID

    let name: String
    var seasonMinutesBeforeGame: Int

    var isAvailable: Bool
    var isInjured: Bool
    var isOnField: Bool
    var minutesThisGame: Int
    var continuousMinutesThisGame: Int
    
}

enum GameStatus: String, Codable {
    case notStarted
    case forfeit            // < minPlayersToStart available
    case noSubGame          // 3 or 4 available: no subs
    case normalGame         // >= 5 available: full substitution logic
    case finished
}

enum LineupEventType: String, Codable {
    case initialLineup
    case substitution
    case quarterBreak
    case injury
    case recovery
}

struct LineupEvent: Codable {
    let timeMinute: Int              // from start of game, 0-based
    let type: LineupEventType
    let playersOnField: [PlayerID]
    let playersIn: [PlayerID]
    let playersOut: [PlayerID]
}

struct GameState: Codable {
    var config: GameConfig
    var intensity: SubstitutionIntensity
    var status: GameStatus

    var currentQuarter: Int          // 0 if not started / forfeit, else 1...quarters
    var minuteInQuarter: Int         // 0...(minutesPerQuarter - 1)
    var totalMinutesElapsed: Int     // 0...(minutesPerQuarter * quarters)

    var players: [PlayerGameRuntime]
    var events: [LineupEvent]
}

// MARK: - Engine Protocol


protocol U7LineupEngine {
    func initializeGame(
        config: GameConfig,
        intensity: SubstitutionIntensity,
        roster: [PlayerSeasonSnapshot],
        availability: [PlayerAvailability]
    ) -> GameState

    func advanceOneMinute(state: inout GameState) -> [LineupEvent]
    func simulateFullGame(state: inout GameState) -> GameState

    // ✅ add these
    func proposeSubstitution(state: GameState) -> (inIDs: [PlayerID], outIDs: [PlayerID])

    @discardableResult
    func applySubstitution(
        state: inout GameState,
        inIDs: [PlayerID],
        outIDs: [PlayerID],
        timeMinute: Int
    ) -> [LineupEvent]

    @discardableResult
    func markInjured(playerId: PlayerID, state: inout GameState) -> [LineupEvent]

    @discardableResult
    func markRecovered(playerId: PlayerID, state: inout GameState) -> [LineupEvent]

}


// MARK: - Default Implementation

struct DefaultU7LineupEngine: U7LineupEngine {
    
    // MARK: Public API
    
    func initializeGame(
        config: GameConfig,
        intensity: SubstitutionIntensity,
        roster: [PlayerSeasonSnapshot],
        availability: [PlayerAvailability]
    ) -> GameState {
        
        let availabilityMap = Dictionary(
            uniqueKeysWithValues: availability.map { ($0.id, $0.isAvailable) }
        )
        //print(availabilityMap)
        
        var players: [PlayerGameRuntime] = roster.map { snapshot in
            PlayerGameRuntime(
                id: snapshot.id,
                name: snapshot.name,
                seasonMinutesBeforeGame: snapshot.seasonMinutesPlayed,
                isAvailable: availabilityMap[snapshot.id] ?? false,
                isInjured: false,
                isOnField: false,
                minutesThisGame: 0,
                continuousMinutesThisGame: 0
            )
        }
        //print(players)
        
        let available = players.filter { $0.isAvailable && !$0.isInjured}
        let availableCount = available.count
        
        // 1. Forfeit: fewer than minPlayersToStart (3)
        if availableCount < config.minPlayersToStart {
            return GameState(
                config: config,
                intensity: intensity,
                status: .forfeit,
                currentQuarter: 0,
                minuteInQuarter: 0,
                totalMinutesElapsed: 0,
                players: players,
                events: []
            )
        }
        
        // 2. No-sub game: exactly 3 or 4 available
        if availableCount == config.minPlayersToStart || availableCount == config.playersOnField {
            // everyone who is available plays the whole game, no subs
            for i in players.indices {
                if players[i].isAvailable {
                    players[i].isOnField = true
                }
            }
            
            let onFieldIDs = players
                .filter { $0.isOnField }
                .map { $0.id }
            
            let initialEvent = LineupEvent(
                timeMinute: 0,
                type: .initialLineup,
                playersOnField: onFieldIDs,
                playersIn: onFieldIDs,
                playersOut: []
            )
            
            return GameState(
                config: config,
                intensity: intensity,
                status: .noSubGame,
                currentQuarter: 1,
                minuteInQuarter: 0,
                totalMinutesElapsed: 0,
                players: players,
                events: [initialEvent]
            )
        }
        
        // 3. Normal game with substitutions (>=5 available)
        // Initial lineup selection:
        //   - Least season minutes
        //   - Random tie-breaker
        var availablePlayers = players.filter { $0.isAvailable }.shuffled()
        availablePlayers.sort {
            $0.seasonMinutesBeforeGame < $1.seasonMinutesBeforeGame
        }
        
        let starters = Array(availablePlayers.prefix(config.playersOnField))
        let starterIDs = Set(starters.map { $0.id })
        
        for i in players.indices {
            if starterIDs.contains(players[i].id) {
                players[i].isOnField = true
            }
        }
        
        let onFieldIDs = players
            .filter { $0.isOnField }
            .map { $0.id }
        
        let initialEvent = LineupEvent(
            timeMinute: 0,
            type: .initialLineup,
            playersOnField: onFieldIDs,
            playersIn: onFieldIDs,
            playersOut: []
        )
        //print(initialEvent)
        
        return GameState(
            config: config,
            intensity: intensity,
            status: .normalGame,
            currentQuarter: 1,
            minuteInQuarter: 0,
            totalMinutesElapsed: 0,
            players: players,
            events: [initialEvent]
        )
    }
    
    func advanceOneMinute( state: inout GameState) -> [LineupEvent] {
        
        // Forfeit / finished: no further changes
        if state.status == .forfeit || state.status == .finished {
            return []
        }
        
        let eventsBefore = state.events.count
        
        // 1. Update per-player minutes
        for i in state.players.indices {
            if state.players[i].isOnField {
                state.players[i].minutesThisGame += 1
                state.players[i].continuousMinutesThisGame += 1
            }
        }
        
        // 2. Advance clock
        state.minuteInQuarter += 1
        state.totalMinutesElapsed += 1
        
        
        // 3. End of quarter?
        if state.minuteInQuarter == state.config.minutesPerQuarter {
            handleQuarterEnd(&state)
        } else {
            // mid-quarter: only normal games have subs
            if state.status == .normalGame {
                handleSubstitutionCheckpointIfNeeded(&state)
            }
        }
        
        let eventsAfter = state.events.count
        if eventsAfter > eventsBefore {
            return Array(state.events[eventsBefore..<eventsAfter])
        } else {
            return []
        }
    }
    
    func simulateFullGame(
        state: inout GameState
    ) -> GameState {
        while state.status != .finished && state.status != .forfeit {
            _ = advanceOneMinute(state: &state)
        }
        return state
    }
    
    // MARK: - Private helpers
    
    private func substitutionInterval(for state: GameState) -> Int {
        let base = Double(state.config.minutesPerQuarter)
        let raw: Double
        
        switch state.intensity {
        case .frequent:
            raw = base / 5.0
        case .balanced:
            raw = base / 4.0
        case .infrequent:
            raw = base / 3.0
        }
        
        let rounded = Int((raw).rounded())
        return max(1, rounded)
    }
    
    private func benchCount(_ state: GameState) -> Int {
        state.players.filter { $0.isAvailable && !$0.isInjured && !$0.isOnField }.count
    }
    
    private func playersToSubstituteCount(_ state: GameState) -> Int {
        let bench = benchCount(state)
        if bench == 0 { return 0 }
        
        let baseN: Int
        switch state.intensity {
        case .frequent:
            baseN = Int(ceil(Double(bench) / 4.0))
        case .balanced:
            baseN = Int(ceil(Double(bench) / 2.0))
        case .infrequent:
            baseN = bench
        }
        
        var N = max(1, baseN)
        N = min(N, state.config.playersOnField)
        N = min(N, bench)
        return N
    }
    
    private func selectPlayersToComeIn(_ state: GameState, count N: Int) -> [PlayerID] {
        var bench = state.players
            .filter { $0.isAvailable && !$0.isInjured && !$0.isOnField }
            .shuffled() // random tie-breaker
        
        bench.sort { lhs, rhs in
            if lhs.minutesThisGame != rhs.minutesThisGame {
                return lhs.minutesThisGame < rhs.minutesThisGame
            }
            if lhs.seasonMinutesBeforeGame != rhs.seasonMinutesBeforeGame {
                return lhs.seasonMinutesBeforeGame < rhs.seasonMinutesBeforeGame
            }
            return false
        }
        
        return Array(bench.prefix(N)).map { $0.id }
    }
    
    private func selectPlayersToGoOut(_ state: GameState, count N: Int) -> [PlayerID] {
        var field = state.players
            .filter { $0.isAvailable && !$0.isInjured  && $0.isOnField }
            .shuffled() // random tie-breaker for perfect ties
        
        field.sort { lhs, rhs in
            if lhs.continuousMinutesThisGame != rhs.continuousMinutesThisGame {
                return lhs.continuousMinutesThisGame > rhs.continuousMinutesThisGame
            }
            if lhs.minutesThisGame != rhs.minutesThisGame {
                return lhs.minutesThisGame > rhs.minutesThisGame
            }
            if lhs.seasonMinutesBeforeGame != rhs.seasonMinutesBeforeGame {
                return lhs.seasonMinutesBeforeGame > rhs.seasonMinutesBeforeGame
            }
            return false
        }
        
        return Array(field.prefix(N)).map { $0.id }
    }
    
//    private func applySubstitution(_ state: inout GameState) {
//        guard state.status == .normalGame else { return }
//        
//        let N = playersToSubstituteCount(state)
//        if N == 0 { return }
//        
//        let inIDs = selectPlayersToComeIn(state, count: N)
//        let outIDs = selectPlayersToGoOut(state, count: N)
//        
//        // Swap states
//        for i in state.players.indices {
//            let id = state.players[i].id
//            if inIDs.contains(id) {
//                state.players[i].isOnField = true
//                // continuousMinutes continues from next minute
//            } else if outIDs.contains(id) {
//                state.players[i].isOnField = false
//                state.players[i].continuousMinutesThisGame = 0
//            }
//        }
//        
//        let fieldIDs = state.players
//            .filter { $0.isOnField }
//            .map { $0.id }
//        
//        let event = LineupEvent(
//            timeMinute: state.totalMinutesElapsed,
//            type: .substitution,
//            playersOnField: fieldIDs,
//            playersIn: inIDs,
//            playersOut: outIDs
//        )
//        state.events.append(event)
//    }
//    
    @discardableResult
    func applySubstitution(
        state: inout GameState,
        inIDs: [PlayerID],
        outIDs: [PlayerID],
        timeMinute: Int
    ) -> [LineupEvent] {
        guard state.status == .normalGame else { return [] }
        guard inIDs.count == outIDs.count else { return [] }

        for i in state.players.indices {
            let id = state.players[i].id
            if inIDs.contains(id) {
                state.players[i].isOnField = true
            } else if outIDs.contains(id) {
                state.players[i].isOnField = false
                state.players[i].continuousMinutesThisGame = 0
            }
        }

        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }

        let event = LineupEvent(
            timeMinute: timeMinute,
            type: .substitution,
            playersOnField: fieldIDs,
            playersIn: inIDs,
            playersOut: outIDs
        )
        state.events.append(event)
        return [event]
    }

    
    func checkpointMinutesPerQuarter(intensity: SubstitutionIntensity, minutesPerQuarter: Int) -> Set<Int> {
        switch intensity {
        case .frequent:   return [2,4,6,8]
        case .balanced:   return [3,6,9]
        case .infrequent: return [5]
        }
    }

    
    private func handleQuarterEnd(_ state: inout GameState) {
        // Quarter break event (no automatic ins/outs yet)
        let fieldIDs = state.players
            .filter { $0.isOnField }
            .map { $0.id }
        
        let breakEvent = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            type: .quarterBreak,
            playersOnField: fieldIDs,
            playersIn: [],
            playersOut: []
        )
        state.events.append(breakEvent)
        
        // Everyone gets a "rest" -> reset continuous minutes
        for i in state.players.indices {
            state.players[i].continuousMinutesThisGame = 0
        }
        
        // Move to next quarter or finish
        state.currentQuarter += 1
        state.minuteInQuarter = 0
        
        if state.currentQuarter > state.config.quarters {
            state.status = .finished
        }
        

    }
    
    private func handleSubstitutionCheckpointIfNeeded(_ state: inout GameState) {
//        guard state.status == .normalGame else { return }
//        
//        let interval = substitutionInterval(for: state)
//        guard interval > 0 else { return }
//        
//        // e.g. interval 2 -> checkpoints at minuteInQuarter 2, 4, 6, 8
//        if state.minuteInQuarter % interval == 0 {
//            applySubstitution(&state)
//        }
    }

    @discardableResult
    func markInjured(playerId: PlayerID, state: inout GameState) -> [LineupEvent] {
        guard state.status == .normalGame || state.status == .noSubGame else { return [] }
        guard let idx = state.players.firstIndex(where: { $0.id == playerId }) else { return [] }
        guard state.players[idx].isAvailable else { return [] }
        guard !state.players[idx].isInjured else { return [] }

        state.players[idx].isInjured = true

        // If they're on the field, immediately take them out
        let wasOnField = state.players[idx].isOnField
        if wasOnField {
            state.players[idx].isOnField = false
            state.players[idx].continuousMinutesThisGame = 0

            // If normal game and someone is on the bench, bring one in immediately
            if state.status == .normalGame {
                let inIDs = selectPlayersToComeIn(state, count: 1)
                if let inId = inIDs.first,
                   let inIdx = state.players.firstIndex(where: { $0.id == inId }) {
                    state.players[inIdx].isOnField = true
                }
            }
        }

        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }

        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            type: .injury,
            playersOnField: fieldIDs,
            playersIn: [],
            playersOut: [playerId]
        )
        state.events.append(event)
        return [event]
    }

    @discardableResult
    func markRecovered(playerId: PlayerID, state: inout GameState) -> [LineupEvent] {
        guard let idx = state.players.firstIndex(where: { $0.id == playerId }) else { return [] }
        guard state.players[idx].isInjured else { return [] }
        guard state.players[idx].isOnField == false else { return [] } // your rule

        state.players[idx].isInjured = false

        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }

        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            type: .recovery,
            playersOnField: fieldIDs,
            playersIn: [playerId],
            playersOut: []
        )
        state.events.append(event)
        return [event]
    }

    
    func proposeSubstitution(state: GameState) -> (inIDs: [PlayerID], outIDs: [PlayerID]) {
        let N = playersToSubstituteCount(state)
        if N == 0 { return ([], []) }
        let inIDs = selectPlayersToComeIn(state, count: N)
        let outIDs = selectPlayersToGoOut(state, count: N)
        return (inIDs, outIDs)
    }

    
    
}

//
//import Foundation
//
//func pickStarters(players: [PlayerGameRuntime], playersOnField: Int) -> [PlayerGameRuntime] {
//    let available = players.filter { $0.isAvailable }
//
//    // Your rule: least season minutes gets priority
//    let sorted = available.sorted { $0.seasonMinutesBeforeGame < $1.seasonMinutesBeforeGame }
//
//    return Array(sorted.prefix(playersOnField))
//}
