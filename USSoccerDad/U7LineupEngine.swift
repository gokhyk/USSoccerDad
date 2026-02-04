//
//  U7LineupEngine.swift
//  USSoccerDad
//
//  Refactored for better fairness and clarity
//

import Foundation

// MARK: - Shared Types

typealias PlayerID = UUID

enum SubstitutionIntensity: String, Codable {
    case frequent    // every 2 minutes
    case balanced    // every 3 minutes
    case infrequent  // every 6 minutes
}

struct GameConfig: Codable, Equatable {
    let minutesPerPeriod: Int       // e.g. 10
    let periods: Int                // e.g. 4 (quarters) or 2 (halves)
    let playersOnField: Int         // e.g. 4
    let minPlayersToStart: Int      // e.g. 3
}

struct PlayerSeasonSnapshot: Identifiable, Codable {
    let id: PlayerID
    let name: String
    var seasonMinutesPlayed: Int
}

struct PlayerAvailability: Identifiable, Codable {
    let id: PlayerID
    var isAvailable: Bool
}

struct PlayerGameRuntime: Identifiable, Codable {
    let id: PlayerID
    let name: String
    var seasonMinutesBeforeGame: Int
    
    var isAvailable: Bool
    var isInjured: Bool
    var isOnField: Bool
    
    // Track in seconds for precision
    var secondsPlayedThisGame: Int = 0
    var continuousSecondsPlayedThisGame: Int = 0
    
    // Computed properties for display
    var minutesThisGame: Int {
        secondsPlayedThisGame / 60
    }
    
    var continuousMinutesThisGame: Int {
        continuousSecondsPlayedThisGame / 60
    }
}

enum GameStatus: String, Codable {
    case notStarted
    case forfeit            // < minPlayersToStart available
    case noSubGame          // exactly playersOnField available: no subs needed
    case normalGame         // > playersOnField available: full substitution logic
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
    let timeMinute: Int
    let timeSecond: Int
    let type: LineupEventType
    let playersOnField: [PlayerID]
    let playersIn: [PlayerID]
    let playersOut: [PlayerID]
}

struct GameState: Codable {
    var config: GameConfig
    var intensity: SubstitutionIntensity
    var status: GameStatus
    
    var currentQuarter: Int
    var totalSecondsElapsed: Int
    
    // Substitution scheduling
    var subIntervalSeconds: Int
    var nextSubAtSecond: Int
    
    var players: [PlayerGameRuntime]
    var events: [LineupEvent]
    
    // Computed properties
    var totalMinutesElapsed: Int {
        totalSecondsElapsed / 60
    }
    
    var minuteInQuarter: Int {
        let quarterStartSecond = (currentQuarter - 1) * config.minutesPerPeriod * 60
        return (totalSecondsElapsed - quarterStartSecond) / 60
    }
}

// MARK: - Engine Protocol

protocol U7LineupEngine {
    func initializeGame(
        config: GameConfig,
        intensity: SubstitutionIntensity,
        roster: [PlayerSeasonSnapshot],
        availability: [PlayerAvailability]
    ) -> GameState
    
    func proposeSubstitution(state: GameState) -> (inIDs: [PlayerID], outIDs: [PlayerID])
    
    @discardableResult
    func applySubstitution(
        state: inout GameState,
        inIDs: [PlayerID],
        outIDs: [PlayerID]
    ) -> LineupEvent?
    
    @discardableResult
    func markInjured(playerId: PlayerID, state: inout GameState) -> LineupEvent?
    
    @discardableResult
    func markRecovered(playerId: PlayerID, state: inout GameState) -> LineupEvent?
    
    func advanceToNextQuarter(state: inout GameState)
}

// MARK: - Default Implementation

struct DefaultU7LineupEngine: U7LineupEngine {
    
    func initializeGame(
        config: GameConfig,
        intensity: SubstitutionIntensity,
        roster: [PlayerSeasonSnapshot],
        availability: [PlayerAvailability]
    ) -> GameState {
        
        let availabilityMap = Dictionary(
            uniqueKeysWithValues: availability.map { ($0.id, $0.isAvailable) }
        )
        
        var players: [PlayerGameRuntime] = roster.map { snapshot in
            PlayerGameRuntime(
                id: snapshot.id,
                name: snapshot.name,
                seasonMinutesBeforeGame: snapshot.seasonMinutesPlayed,
                isAvailable: availabilityMap[snapshot.id] ?? false,
                isInjured: false,
                isOnField: false
            )
        }
        
        let available = players.filter { $0.isAvailable && !$0.isInjured }
        let availableCount = available.count
        
        let intervalSeconds = substitutionIntervalSeconds(for: intensity)
        
        // 1. Forfeit: fewer than minimum players
        if availableCount < config.minPlayersToStart {
            return GameState(
                config: config,
                intensity: intensity,
                status: .forfeit,
                currentQuarter: 0,
                totalSecondsElapsed: 0,
                subIntervalSeconds: intervalSeconds,
                nextSubAtSecond: intervalSeconds,
                players: players,
                events: []
            )
        }
        
        // 2. No-sub game: exactly the right number of players
        if availableCount == config.playersOnField {
            for i in players.indices {
                if players[i].isAvailable {
                    players[i].isOnField = true
                }
            }
            
            let onFieldIDs = players.filter { $0.isOnField }.map { $0.id }
            
            let initialEvent = LineupEvent(
                timeMinute: 0,
                timeSecond: 0,
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
                totalSecondsElapsed: 0,
                subIntervalSeconds: intervalSeconds,
                nextSubAtSecond: intervalSeconds,
                players: players,
                events: [initialEvent]
            )
        }
        
        // 3. Normal game with substitutions
        let starters = selectInitialStarters(from: players, count: config.playersOnField)
        let starterIDs = Set(starters.map { $0.id })
        
        for i in players.indices {
            if starterIDs.contains(players[i].id) {
                players[i].isOnField = true
            }
        }
        
        let initialEvent = LineupEvent(
            timeMinute: 0,
            timeSecond: 0,
            type: .initialLineup,
            playersOnField: Array(starterIDs),
            playersIn: Array(starterIDs),
            playersOut: []
        )
        
        return GameState(
            config: config,
            intensity: intensity,
            status: .normalGame,
            currentQuarter: 1,
            totalSecondsElapsed: 0,
            subIntervalSeconds: intervalSeconds,
            nextSubAtSecond: intervalSeconds,
            players: players,
            events: [initialEvent]
        )
    }
    
    func proposeSubstitution(state: GameState) -> (inIDs: [PlayerID], outIDs: [PlayerID]) {
        guard state.status == .normalGame else {
            return ([], [])
        }
        
        let eligible = state.players.filter { $0.isAvailable && !$0.isInjured }
        let benchPlayers = eligible.filter { !$0.isOnField }
        let fieldPlayers = eligible.filter { $0.isOnField }
        
        guard !benchPlayers.isEmpty else {
            return ([], [])
        }
        
        // Calculate how many players to swap based on fairness gap
        let swapCount = calculateSwapCount(eligible: eligible, state: state)
        guard swapCount > 0 else {
            return ([], [])
        }
        
        // Target playing time for fairness
        let targetSeconds = calculateTargetSeconds(state: state)
        
        // Select players to come IN (most underplayed)
        let playersIn = selectPlayersToSwapIn(
            from: benchPlayers,
            count: swapCount,
            targetSeconds: targetSeconds
        )
        
        // Select players to come OUT (most overplayed or tired)
        let playersOut = selectPlayersToSwapOut(
            from: fieldPlayers,
            count: swapCount,
            targetSeconds: targetSeconds
        )
        
        return (playersIn.map(\.id), playersOut.map(\.id))
    }
    
    @discardableResult
    func applySubstitution(
        state: inout GameState,
        inIDs: [PlayerID],
        outIDs: [PlayerID]
    ) -> LineupEvent? {
        guard !inIDs.isEmpty, inIDs.count == outIDs.count else {
            return nil
        }
        
        // Apply the substitution
        for id in outIDs {
            if let idx = state.players.firstIndex(where: { $0.id == id }) {
                state.players[idx].isOnField = false
                state.players[idx].continuousSecondsPlayedThisGame = 0
            }
        }
        
        for id in inIDs {
            if let idx = state.players.firstIndex(where: { $0.id == id }) {
                state.players[idx].isOnField = true
                state.players[idx].continuousSecondsPlayedThisGame = 0
            }
        }
        
        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }
        
        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            timeSecond: state.totalSecondsElapsed,
            type: .substitution,
            playersOnField: fieldIDs,
            playersIn: inIDs,
            playersOut: outIDs
        )
        
        state.events.append(event)
        
        // Schedule next substitution
        state.nextSubAtSecond = state.totalSecondsElapsed + state.subIntervalSeconds
        
        return event
    }
    
    @discardableResult
    func markInjured(playerId: PlayerID, state: inout GameState) -> LineupEvent? {
        guard let idx = state.players.firstIndex(where: { $0.id == playerId }) else {
            return nil
        }
        guard state.players[idx].isAvailable, !state.players[idx].isInjured else {
            return nil
        }
        
        state.players[idx].isInjured = true
        let wasOnField = state.players[idx].isOnField
        
        if wasOnField {
            state.players[idx].isOnField = false
            state.players[idx].continuousSecondsPlayedThisGame = 0
            
            // Bring in a replacement if available
            if state.status == .normalGame {
                let eligible = state.players.filter {
                    $0.isAvailable && !$0.isInjured && !$0.isOnField
                }
                
                if let replacement = selectPlayersToSwapIn(
                    from: eligible,
                    count: 1,
                    targetSeconds: calculateTargetSeconds(state: state)
                ).first {
                    if let repIdx = state.players.firstIndex(where: { $0.id == replacement.id }) {
                        state.players[repIdx].isOnField = true
                        state.players[repIdx].continuousSecondsPlayedThisGame = 0
                    }
                }
            }
        }
        
        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }
        
        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            timeSecond: state.totalSecondsElapsed,
            type: .injury,
            playersOnField: fieldIDs,
            playersIn: [],
            playersOut: [playerId]
        )
        
        state.events.append(event)
        return event
    }
    
    @discardableResult
    func markRecovered(playerId: PlayerID, state: inout GameState) -> LineupEvent? {
        guard let idx = state.players.firstIndex(where: { $0.id == playerId }) else {
            return nil
        }
        guard state.players[idx].isInjured, !state.players[idx].isOnField else {
            return nil
        }
        
        state.players[idx].isInjured = false
        
        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }
        
        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            timeSecond: state.totalSecondsElapsed,
            type: .recovery,
            playersOnField: fieldIDs,
            playersIn: [playerId],
            playersOut: []
        )
        
        state.events.append(event)
        return event
    }
    
    func advanceToNextQuarter(state: inout GameState) {
        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }
        
        let breakEvent = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            timeSecond: state.totalSecondsElapsed,
            type: .quarterBreak,
            playersOnField: fieldIDs,
            playersIn: [],
            playersOut: []
        )
        state.events.append(breakEvent)
        
        // Reset continuous time for everyone (they all got a break)
        for i in state.players.indices {
            state.players[i].continuousSecondsPlayedThisGame = 0
        }
        
        state.currentQuarter += 1
        
        if state.currentQuarter > state.config.periods {
            state.status = .finished
            return
        }
        
        // At halftime (if 4 quarters, this is start of Q3; if 2 halves, start of H2)
        // Rebalance the lineup for maximum fairness
        if shouldRebalanceAtQuarterStart(quarter: state.currentQuarter, config: state.config) {
            rebalanceLineup(state: &state)
        }
        
        // Schedule first sub of new quarter
        state.nextSubAtSecond = state.totalSecondsElapsed + state.subIntervalSeconds
    }
    
    // MARK: - Private Helpers
    
    private func substitutionIntervalSeconds(for intensity: SubstitutionIntensity) -> Int {
        switch intensity {
        case .frequent:   return 2 * 60   // every 2 minutes
        case .balanced:   return 3 * 60   // every 3 minutes
        case .infrequent: return 6 * 60   // every 6 minutes
        }
    }
    
    private func selectInitialStarters(
        from players: [PlayerGameRuntime],
        count: Int
    ) -> [PlayerGameRuntime] {
        var available = players.filter { $0.isAvailable && !$0.isInjured }
        
        // Shuffle for randomness in ties
        available.shuffle()
        
        // Sort by least season minutes played
        available.sort { $0.seasonMinutesBeforeGame < $1.seasonMinutesBeforeGame }
        
        return Array(available.prefix(count))
    }
    
    private func calculateTargetSeconds(state: GameState) -> Double {
        let eligible = state.players.filter { $0.isAvailable && !$0.isInjured }
        guard !eligible.isEmpty else { return 0 }
        
        // Total player-seconds consumed so far
        let totalPlayerSeconds = Double(state.totalSecondsElapsed * state.config.playersOnField)
        
        // Fair share per player
        return totalPlayerSeconds / Double(eligible.count)
    }
    
    private func playingError(_ player: PlayerGameRuntime, targetSeconds: Double) -> Double {
        return Double(player.secondsPlayedThisGame) - targetSeconds
    }
    
    private func calculateSwapCount(eligible: [PlayerGameRuntime], state: GameState) -> Int {
        let benchCount = eligible.filter { !$0.isOnField }.count
        guard benchCount > 0 else { return 0 }
        
        let targetSeconds = calculateTargetSeconds(state: state)
        let errors = eligible.map { playingError($0, targetSeconds: targetSeconds) }
        
        guard let minError = errors.min(), let maxError = errors.max() else {
            return 1
        }
        
        let gapSeconds = maxError - minError
        
        // Determine swap count based on fairness gap
        var swapCount = 1
        if gapSeconds > 240 {      // More than 4 minutes gap
            swapCount = 3
        } else if gapSeconds > 120 {  // More than 2 minutes gap
            swapCount = 2
        }
        
        // Don't swap more than what's available
        swapCount = min(swapCount, benchCount)
        swapCount = min(swapCount, state.config.playersOnField)
        
        return max(1, swapCount)
    }
    
    private func selectPlayersToSwapIn(
        from benchPlayers: [PlayerGameRuntime],
        count: Int,
        targetSeconds: Double
    ) -> [PlayerGameRuntime] {
        var players = benchPlayers
        
        // Shuffle for fairness in ties
        players.shuffle()
        
        // Sort by most underplayed (lowest error = most negative)
        players.sort { playingError($0, targetSeconds: targetSeconds) < playingError($1, targetSeconds: targetSeconds) }
        
        return Array(players.prefix(count))
    }
    
    private func selectPlayersToSwapOut(
        from fieldPlayers: [PlayerGameRuntime],
        count: Int,
        targetSeconds: Double
    ) -> [PlayerGameRuntime] {
        var players = fieldPlayers
        
        // Shuffle for fairness in ties
        players.shuffle()
        
        // Sort by:
        // 1. Most overplayed (highest error = most positive)
        // 2. Longest continuous time (needs a rest)
        players.sort { p1, p2 in
            let error1 = playingError(p1, targetSeconds: targetSeconds)
            let error2 = playingError(p2, targetSeconds: targetSeconds)
            
            if abs(error1 - error2) > 10 {  // More than 10 seconds difference
                return error1 > error2
            }
            
            // If similar playing time, prioritize who needs rest
            return p1.continuousSecondsPlayedThisGame > p2.continuousSecondsPlayedThisGame
        }
        
        return Array(players.prefix(count))
    }
    
    private func shouldRebalanceAtQuarterStart(quarter: Int, config: GameConfig) -> Bool {
        // For 4 quarters: rebalance at start of Q3 (halftime)
        // For 2 halves: rebalance at start of H2
        let halfwayPoint = (config.periods / 2) + 1
        return quarter == halfwayPoint
    }
    
    private func rebalanceLineup(state: inout GameState) {
        var eligible = state.players.filter { $0.isAvailable && !$0.isInjured }
        guard eligible.count >= state.config.minPlayersToStart else { return }
        
        // Shuffle for fairness
        eligible.shuffle()
        
        // Sort by least total seconds played
        eligible.sort { p1, p2 in
            if p1.secondsPlayedThisGame != p2.secondsPlayedThisGame {
                return p1.secondsPlayedThisGame < p2.secondsPlayedThisGame
            }
            // Tie-breaker: season minutes
            return p1.seasonMinutesBeforeGame < p2.seasonMinutesBeforeGame
        }
        
        let onFieldCount = min(state.config.playersOnField, eligible.count)
        let newOnFieldIDs = Set(eligible.prefix(onFieldCount).map { $0.id })
        
        // Update who's on field
        for i in state.players.indices {
            let shouldBeOnField = newOnFieldIDs.contains(state.players[i].id)
            if state.players[i].isOnField != shouldBeOnField {
                state.players[i].isOnField = shouldBeOnField
                state.players[i].continuousSecondsPlayedThisGame = 0
            }
        }
        
        // Log the rebalance event
        let fieldIDs = state.players.filter { $0.isOnField }.map { $0.id }
        let event = LineupEvent(
            timeMinute: state.totalMinutesElapsed,
            timeSecond: state.totalSecondsElapsed,
            type: .substitution,
            playersOnField: fieldIDs,
            playersIn: [],
            playersOut: []
        )
        state.events.append(event)
    }
}
