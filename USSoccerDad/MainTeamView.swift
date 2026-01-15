//
//  MainTeamView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/17/25.
//

import SwiftUI

struct MainTeamView: View {
    @EnvironmentObject var teamStore: TeamStore
    //@EnvironmentObject var gameStore: GameStore
    
    var team: TeamSettings
    
    var body: some View {
        List {
            // Team name only – tap to edit settings
            Section {
                NavigationLink {
                    EditTeamView(team: team) { updated in
                        // Save back to store
                        teamStore.setActiveTeam(updated)
                    }
                } label: {
                    Text(team.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            // Other navigation options
            Section {
                NavigationLink("Manage Roster") {
                    RosterView(
                        teamId: team.id,
                        playerRepo: InMemoryPlayerRepository()
                    )
                }

                NavigationLink("Upcoming Games") {
                    GameListView(team: team)
                }
                
                NavigationLink("Lineup Generator (manual)") {
                    Text("Direct lineup view (optional)")
                }
                
            }
        }
        .navigationTitle("Team")
    }
    
}
