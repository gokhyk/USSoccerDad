//
//  TeamModels.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/25/25.
//






import Foundation

enum AgeGroup: String, CaseIterable, Identifiable, Codable {
    case u5 = "U5"
    case u6 = "U6"
    case u7 = "U7"
    case u8 = "U8"
    case u9 = "U9"
    case u10 = "U10"
    case u11 = "U11"
    case u12 = "U12"
    case u13 = "U13"
    case u14 = "U14"
    case u15 = "U15"
    case u16 = "U16"
    case u17 = "U17"

    var id: String { rawValue }
}

struct TeamSettings: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var ageGroup: AgeGroup

    var playersOnField: Int
    var numberOfPeriods: Int
    var minutesPerPeriod: Int
    var durations: [Int]
    var hasDedicatedGoalkeeper: Bool

    // You can add more later:
    // var allowUnlimitedSubs: Bool
    // var leagueName: String?
}

extension TeamSettings {
    static func defaults(for ageGroup: AgeGroup, name: String = "") -> TeamSettings {
        // You can tweak these rules however you like
        switch ageGroup {
        case .u5, .u6, .u7:
            return TeamSettings(
                id: UUID(),
                name: name,
                ageGroup: ageGroup,
                playersOnField: 4,
                numberOfPeriods: 4,
                minutesPerPeriod: 10,
                durations: [0, 10, 2, 10, 5, 10, 2, 10, 0],
                hasDedicatedGoalkeeper: false
            )
        case .u8, .u9:
            return TeamSettings(
                id: UUID(),
                name: name,
                ageGroup: ageGroup,
                playersOnField: 6,
                numberOfPeriods: 2,
                minutesPerPeriod: 25,
                durations: [0, 25, 10, 25, 0],
                hasDedicatedGoalkeeper: true
            )
        case .u10, .u11:
            return TeamSettings(
                id: UUID(),
                name: name,
                ageGroup: ageGroup,
                playersOnField: 8,
                numberOfPeriods: 2,
                minutesPerPeriod: 30,
                durations: [0, 30, 12, 30, 0],
                hasDedicatedGoalkeeper: true
            )
        case .u12, .u13, .u14, .u15, .u16, .u17:
            return TeamSettings(
                id: UUID(),
                name: name,
                ageGroup: ageGroup,
                playersOnField: 11,
                numberOfPeriods: 2,
                minutesPerPeriod: 35,
                durations: [0, 35, 12, 35, 0],
                hasDedicatedGoalkeeper: true
            )
        }
    }
}

