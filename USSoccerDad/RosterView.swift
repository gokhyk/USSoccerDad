//
//  RosterView.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 11/18/25.
//
import Foundation
import SwiftUI

@MainActor
final class RosterViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var search: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let teamId: UUID
    private let playerRepo: PlayerRepository

    init(teamId: UUID, playerRepo: PlayerRepository) {
        self.teamId = teamId
        self.playerRepo = playerRepo
    }

    func load() async {
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await playerRepo.listPlayers(teamId: teamId, search: search)
            self.players = result
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to load players: \(error.localizedDescription)"
        }
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets {
            guard players.indices.contains(index) else { continue }
            let player = players[index]
            do {
                try await playerRepo.delete(playerId: player.id)
            } catch {
                errorMessage = "Failed to delete player: \(error.localizedDescription)"
            }
        }
        await refresh()
    }

    func save(player: Player) async {
        do {
            try await playerRepo.upsert(player: player)
            await refresh()
        } catch {
            errorMessage = "Failed to save player: \(error.localizedDescription)"
        }
    }

    func makeNewPlayer() -> Player {
        Player(
            id: UUID(),
            teamId: teamId,
            name: "",
            jerseyNumber: nil,
            notes: nil,
            
            canPlayGK: false,
            canPlayAttack: true,
            canPlayDefense: true,
            
            totalMinutesPlayed: 0      // NEW (optional but explicit)
        )
    }
}


import SwiftUI

struct RosterView: View {
    @StateObject private var vm: RosterViewModel

    //@State private var isPresentingEditor = false
    @State private var editingPlayer: Player?

    init(teamId: UUID, playerRepo: PlayerRepository) {
        _vm = StateObject(wrappedValue: RosterViewModel(teamId: teamId, playerRepo: playerRepo))
    }

    var body: some View {
        List {
            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            ForEach(vm.players) { player in
                Button {
                    editingPlayer = player
                    
                } label: {
                    HStack {
                        if let number = player.jerseyNumber {
                            Text("#\(number)")
                                .font(.headline)
                                .frame(width: 40, alignment: .leading)
                        } else {
                            Text("—")
                                .frame(width: 40, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.body)

                            Text("Minutes: \(player.totalMinutesPlayed)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }


                        Spacer()

                        HStack(spacing: 6) {
                            if player.canPlayGK {
                                Image(systemName: "shield.lefthalf.filled")   // GK
                                    .foregroundColor(.blue)
                            }
                            if player.canPlayDefense {
                                Image(systemName: "shield.fill")              // Defense
                                    .foregroundColor(.green)
                            }
                            if player.canPlayAttack {
                                Image(systemName: "bolt.fill")                // Attack
                                    .foregroundColor(.red)
                            }


                            if let notes = player.notes, !notes.isEmpty {
                                Image(systemName: "note.text")
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    }
                }
            }
            .onDelete { offsets in
                Task {
                    await vm.delete(at: offsets)
                }
            }
        }
        .navigationTitle("Roster")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingPlayer = vm.makeNewPlayer()
                    //isPresentingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $vm.search)
        .onChange(of: vm.search) { 
            Task { await vm.refresh() }
        }
        .task {
            await vm.load()
        }
        .sheet(item: $editingPlayer) { player in
            NavigationStack {
                AddEditPlayerView(player: player) { updated in
                    Task {
                        await vm.save(player: updated)
                    }
                    editingPlayer = nil
                } onCancel: {
                    editingPlayer = nil
                }
            }
        }
    }
}
