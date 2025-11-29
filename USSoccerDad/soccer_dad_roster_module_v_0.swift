//// SoccerDad – Roster Module (v0.1)
//// Loosely-coupled SwiftUI + MVVM with protocol-driven repos.
//// v1 is offline; repos can be backed by Core Data/SQLite later.
//// NOTE: If you add this file to an existing Xcode app that already has an @main App,
//// delete the demo app at the bottom (guarded with #if DEBUG) to avoid multiple @main errors.
//
//import SwiftUI
//
//// MARK: - Domain Models
//
//struct Team: Identifiable, Equatable, Codable {
//    var id: UUID
//    var name: String
//    var createdAt: Date = .now
//}
//
//struct Player: Identifiable, Equatable, Codable {
//    var id: UUID
//    var teamId: UUID
//    var name: String
//    var jerseyNumber: Int?
//    var photoAssetId: String? // local asset id / filename
//    var notes: String?
//}
//
//// MARK: - Repository Protocols (abstractions)
//
//protocol TeamRepository {
//    func listTeams() async throws -> [Team]
//    func upsert(team: Team) async throws
//    func delete(teamId: UUID) async throws
//}
//
//protocol PlayerRepository {
//    func listPlayers(teamId: UUID, search: String?) async throws -> [Player]
//    func upsert(player: Player) async throws
//    func delete(playerId: UUID) async throws
//}
//
//// MARK: - Roster ViewModel
//
//@MainActor
//final class RosterViewModel: ObservableObject {
//    @Published private(set) var players: [Player] = []
//    @Published var search = ""
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    let teamId: UUID
//    private let playerRepo: PlayerRepository
//
//    init(teamId: UUID, playerRepo: PlayerRepository) {
//        self.teamId = teamId
//        self.playerRepo = playerRepo
//    }
//
//    func load() async { await refresh() }
//
//    func refresh() async {
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            let result = try await playerRepo.listPlayers(teamId: teamId, search: search)
//            // Fallback comparator (works on all recent Swifts)
//            self.players = result.sorted { a, b in
//                let ja = a.jerseyNumber ?? Int.max
//                let jb = b.jerseyNumber ?? Int.max
//                if ja != jb { return ja < jb }
//                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
//            }
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//
//    func addOrUpdate(name: String, jersey: Int?) async {
//        let player = Player(id: UUID(), teamId: teamId, name: name.trimmed(), jerseyNumber: jersey)
//        do {
//            try await playerRepo.upsert(player: player)
//            await refresh()
//        } catch { self.errorMessage = error.localizedDescription }
//    }
//
//    func update(player: Player) async {
//        do {
//            try await playerRepo.upsert(player: player)
//            await refresh()
//        } catch { self.errorMessage = error.localizedDescription }
//    }
//
//    func delete(_ player: Player) async {
//        do {
//            try await playerRepo.delete(playerId: player.id)
//            await refresh()
//        } catch { self.errorMessage = error.localizedDescription }
//    }
//}
//
//// MARK: - Roster View
//
//struct RosterView: View {
//    @StateObject private var vm: RosterViewModel
//
//    @State private var showAddSheet = false
//    @State private var editPlayer: Player? = nil
//
//    init(teamId: UUID, playerRepo: PlayerRepository) {
//        _vm = StateObject(wrappedValue: RosterViewModel(teamId: teamId, playerRepo: playerRepo))
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            header
//            searchBar
//            contentList
//        }
//        .task { await vm.load() }
//        .sheet(isPresented: $showAddSheet) {
//            AddEditPlayerSheet(teamId: vm.teamId) { name, jersey in
//                await vm.addOrUpdate(name: name, jersey: jersey)
//            }
//            .presentationDetents([.medium])
//        }
//        .sheet(item: $editPlayer) { player in
//            AddEditPlayerSheet(teamId: vm.teamId, player: player) { name, jersey in
//                var updated = player
//                updated.name = name
//                updated.jerseyNumber = jersey
//                await vm.update(player: updated)
//            }
//            .presentationDetents([.medium])
//        }
//        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
//            Button("OK", role: .cancel) {}
//        } message: {
//            Text(vm.errorMessage ?? "")
//        }
//    }
//
//    private var header: some View {
//        HStack {
//            Text("Roster").font(.title2).bold()
//            Spacer()
//            Button { showAddSheet = true } label: {
//                Label("Add Player", systemImage: "plus")
//            }
//            .buttonStyle(.borderedProminent)
//        }
//        .padding([.horizontal, .top])
//    }
//
//    private var searchBar: some View {
//        HStack {
//            Image(systemName: "magnifyingglass")
//            TextField("Search players", text: $vm.search)
//                .textInputAutocapitalization(.words)
//                .onSubmit { Task { await vm.refresh() } }
//            if !vm.search.isEmpty {
//                Button(role: .destructive) { vm.search = ""; Task { await vm.refresh() } } label: {
//                    Image(systemName: "xmark.circle.fill")
//                }
//            }
//        }
//        .padding(10)
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
//        .padding([.horizontal, .bottom])
//    }
//
//    private var contentList: some View {
//        Group {
//            if vm.isLoading {
//                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else if vm.players.isEmpty {
//                VStack(spacing: 8) {
//                    Image(systemName: "list.bullet.rectangle.portrait").font(.largeTitle)
//                    Text("No players yet").bold()
//                    Text("Add your first player to build a roster.")
//                        .foregroundStyle(.secondary)
//                    Button("Add Player") { showAddSheet = true }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                List {
//                    ForEach(vm.players) { p in
//                        HStack {
//                            Text("#" + jerseyText(p.jerseyNumber))
//                                .monospacedDigit()
//                                .frame(width: 36, alignment: .leading)
//                                .foregroundStyle(.secondary)
//                            Text(p.name)
//                            Spacer()
//                            Button("Edit") { editPlayer = p }
//                            Button(role: .destructive, action: { Task { await vm.delete(p) } }) { Text("Delete") }
//                        }
//                    }
//                }
//                .listStyle(.insetGrouped)
//            }
//        }
//        .animation(.default, value: vm.players)
//    }
//
//    private func jerseyText(_ n: Int?) -> String {
//        guard let n = n else { return "–" }
//        return String(format: "%02d", n)
//    }
//}
//
//// MARK: - Add/Edit Sheet
//
//struct AddEditPlayerSheet: View {
//    let teamId: UUID
//    var player: Player? = nil
//    var onSave: (_ name: String, _ jersey: Int?) async -> Void
//
//    @Environment(\.dismiss) private var dismiss
//    @State private var name: String = ""
//    @State private var jersey: String = ""
//
//    init(teamId: UUID, player: Player? = nil, onSave: @escaping (_ name: String, _ jersey: Int?) async -> Void) {
//        self.teamId = teamId
//        self.player = player
//        self.onSave = onSave
//        _name = State(initialValue: player?.name ?? "")
//        _jersey = State(initialValue: player?.jerseyNumber.map(String.init) ?? "")
//    }
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Player") {
//                    TextField("Name", text: $name)
//                    TextField("Jersey #", text: $jersey)
//                        .keyboardType(.numberPad)
//                }
//            }
//            .navigationTitle(player == nil ? "Add Player" : "Edit Player")
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Save") { Task { await save() } }
//                        .disabled(name.trimmed().isEmpty)
//                }
//            }
//        }
//    }
//
//    private func save() async {
//        let jerseyInt = Int(jersey.trimmingCharacters(in: .whitespaces))
//        await onSave(name.trimmed(), jerseyInt)
//        await MainActor.run { dismiss() }
//    }
//}
//
//// MARK: - Mock In-Memory Implementations (for preview/dev)
//
//struct MemoryError: LocalizedError { var errorDescription: String? { "Memory store error" } }
//
//@MainActor
//final class InMemoryTeamRepository: TeamRepository {
//    private var teams: [UUID: Team] = [:]
//    func listTeams() async throws -> [Team] { Array(teams.values) }
//    func upsert(team: Team) async throws { teams[team.id] = team }
//    func delete(teamId: UUID) async throws { teams.removeValue(forKey: teamId) }
//}
//
//@MainActor
//final class InMemoryPlayerRepository: PlayerRepository {
//    private var players: [UUID: Player] = [:]
//    func listPlayers(teamId: UUID, search: String?) async throws -> [Player] {
//        let all = players.values.filter { $0.teamId == teamId }
//        if let q = search?.lowercased(), !q.isEmpty {
//            return all.filter { $0.name.lowercased().contains(q) || ($0.jerseyNumber.map { String($0) } ?? "").contains(q) }
//        }
//        return all
//    }
//    func upsert(player: Player) async throws { players[player.id] = player }
//    func delete(playerId: UUID) async throws { players.removeValue(forKey: playerId) }
//}
//
//// MARK: - Demo App Bootstrap (Preview Only)
//
//#if DEBUG
////@MainActor
////final class DemoContainer: ObservableObject {
////    let teamRepo = InMemoryTeamRepository()
////    let playerRepo = InMemoryPlayerRepository()
////}
////
////@main
////struct SoccerDadDemoApp: App {
////    @StateObject private var demo = DemoContainer()
////    @State private var teamId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID()
////
////    var body: some Scene {
////        WindowGroup {
////            RosterView(teamId: teamId, playerRepo: demo.playerRepo)
////                .task {
////                    // Seed once
////                    if (try? await demo.teamRepo.listTeams().isEmpty) == true {
////                        let team = Team(id: teamId, name: "U10 Tigers")
////                        try? await demo.teamRepo.upsert(team: team)
////                        let p: [Player] = [
////                            Player(id: UUID(), teamId: team.id, name: "Mia", jerseyNumber: 10),
////                            Player(id: UUID(), teamId: team.id, name: "Leo", jerseyNumber: 4),
////                            Player(id: UUID(), teamId: team.id, name: "Ava", jerseyNumber: 7),
////                            Player(id: UUID(), teamId: team.id, name: "Max", jerseyNumber: 3)
////                        ]
////                        for pl in p { try? await demo.playerRepo.upsert(player: pl) }
////                    }
////                }
////        }
////    }
////}
//#endif
//
//// MARK: - Utilities
//
//extension Optional where Wrapped == String {
//    var nonEmpty: String? { (self ?? "").isEmpty ? nil : self }
//}
//
//extension String {
//    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
//}
