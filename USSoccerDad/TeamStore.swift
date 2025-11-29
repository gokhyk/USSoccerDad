//
//  TeamStore.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/17/25.
//


import Foundation
import SwiftUI

@MainActor
final class TeamStore: ObservableObject {
    @Published private(set) var activeTeam: TeamSettings?

    @AppStorage("activeTeamJSON") private var activeTeamJSON: String = ""

    init() {
        loadFromStorage()
    }

    private func loadFromStorage() {
        guard !activeTeamJSON.isEmpty,
              let data = activeTeamJSON.data(using: .utf8) else {
            activeTeam = nil
            return
        }

        do {
            let decoded = try JSONDecoder().decode(TeamSettings.self, from: data)
            activeTeam = decoded
        } catch {
            print("Failed to decode stored team: \(error)")
            activeTeam = nil
        }
    }

    func setActiveTeam(_ team: TeamSettings) {
        activeTeam = team
        persistToStorage(team)
    }

    func clearTeam() {
        activeTeam = nil
        activeTeamJSON = ""
    }

    private func persistToStorage(_ team: TeamSettings) {
        do {
            let data = try JSONEncoder().encode(team)
            if let jsonString = String(data: data, encoding: .utf8) {
                activeTeamJSON = jsonString
            }
        } catch {
            print("Failed to encode team: \(error)")
        }
    }
}
