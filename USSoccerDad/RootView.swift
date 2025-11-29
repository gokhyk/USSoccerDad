//
//  RootView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/17/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var teamStore: TeamStore
    
    var body: some View {
        NavigationView {
            Group {
                if let team = teamStore.activeTeam {
                    MainTeamView(team: team)
                } else {
                    SetupTeamView()
                }
            }
        }
    }
}
