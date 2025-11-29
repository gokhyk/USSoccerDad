////
////  USSoccerDadApp.swift
////  USSoccerDad
////
////  Created by Ayse Kula on 11/17/25.
////
//
import SwiftUI
//
@main
struct USSoccerDadApp: App {
    @StateObject private var teamStore = TeamStore()
    @StateObject private var gameStore = GameStore()
//    //@StateObject private var container = AppContainer() // your DI container
//    private let teamRepo = InMemoryTeamRepository()
//    private let playerRepo = InMemoryPlayerRepository()
//    private let gameRepo = InMemoryGameRepository()
//    private let gamePlayerRepo = InMemoryGamePlayerRepository()
//    private let rotationRepo = InMemoryRotationRepository()
//    
//    @State private var currentTeam: Team? = nil
//
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(teamStore)
                .environmentObject(gameStore)
//            NavigationStack {
//                if let team = currentTeam {
//                    RosterView(teamId: team.id, playerRepo: playerRepo)
//                } else {
//                    TeamSetupView(
//                        teamRepo: teamRepo,
//                        profileRepo: InMemoryTeamProfileRepository()
//                    ) { team in
//                        currentTeam = team
//                    }
//                }
//            }
        }
    }
}
