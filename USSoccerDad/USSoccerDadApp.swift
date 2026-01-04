////
////  USSoccerDadApp.swift
////  USSoccerDad
////
////  Created by Ayse Kula on 11/17/25.
////


import SwiftUI

@main
struct USSoccerDadApp: App {
    @StateObject private var teamStore = TeamStore()    //LEARN: one object is created in the top view
    @StateObject private var gameStore = GameStore()    //LEARN: one object is created in the top view

    var body: some Scene {
        WindowGroup {
            RootView()          //LEARN: RootView is user defined.
                .environmentObject(teamStore)       //LEARN: Environment is a dependency-injection system in SwiftUI.
                .environmentObject(gameStore)       //LEARN: Environment is a dependency-injection system in SwiftUI.

        }
    }
}
