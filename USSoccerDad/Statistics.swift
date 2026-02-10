//import Foundation
//
//typealias PlayerID = UUID
//
//struct PlayerSeasonSnapshot: Identifiable, Codable {
//    let id: PlayerID
//    let name: String
//    var seasonMinutesPlayed: Int
//}
//
//struct PlayerAvailability: Identifiable, Codable {
//    let id: PlayerID
//    var isAvailable: Bool
//}
//
//struct PlayerGameRuntime: Identifiable, Codable {
//    let id: PlayerID
//    let name: String
//    var seasonMinutesBeforeGame: Int
//    
//    var isAvailable: Bool
//    var isInjured: Bool
//    var isOnField: Bool
//    
//    // Track in seconds for precision
//    var secondsPlayedThisGame: Int = 0
//    var continuousSecondsPlayedThisGame: Int = 0
//    
//    // Computed properties for display
//    var minutesThisGame: Int {
//        secondsPlayedThisGame / 60
//    }
//    
//    var continuousMinutesThisGame: Int {
//        continuousSecondsPlayedThisGame / 60
//    }
//}
//
//enum GameStatus: String, Codable {
//    case notStarted
//    case forfeit            // < minPlayersToStart available
//    case noSubGame          // exactly playersOnField available: no subs needed
//    case normalGame         // > playersOnField available: full substitution logic
//    case finished
//}
//
//enum LineupEventType: String, Codable {
//    case initialLineup
//    case substitution
//    case quarterBreak
//    case injury
//    case recovery
//}
//
//struct LineupEvent: Codable {
//    let timeMinute: Int
//    let timeSecond: Int
//    let type: LineupEventType
//    let playersOnField: [PlayerID]
//    let playersIn: [PlayerID]
//    let playersOut: [PlayerID]
//}
//
//struct GameState: Codable {
//    var config: GameConfig
//    var intensity: SubstitutionIntensity
//    var status: GameStatus
//    
//    var currentQuarter: Int
//    var totalSecondsElapsed: Int
//    
//    // Substitution scheduling
//    var subIntervalSeconds: Int
//    var nextSubAtSecond: Int
//    
//    var players: [PlayerGameRuntime]
//    var events: [LineupEvent]
//    
//    // Computed properties
//    var totalMinutesElapsed: Int {
//        totalSecondsElapsed / 60
//    }
//    
//    var minuteInQuarter: Int {
//        let quarterStartSecond = (currentQuarter - 1) * config.minutesPerPeriod * 60
//        return (totalSecondsElapsed - quarterStartSecond) / 60
//    }
//}
