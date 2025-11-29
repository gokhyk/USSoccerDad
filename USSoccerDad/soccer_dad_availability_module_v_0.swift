//// SoccerDad – Availability Module (v0)
//// Pre-game Availability Picker: mark players Available/Missing, validate on-field count, persist locally.
//// Loosely-coupled via repository protocols; no networking in v1.
//
//import SwiftUI
//
//// MARK: - Domain Models (new in this module)
//
//struct Game: Identifiable, Equatable, Codable {
//    var id: UUID
//    var teamId: UUID
//    var name: String? // e.g., "vs Tigers" (optional)
//    var minutesPerHalf: Int
//    var createdAt: Date = .now
//}
//
//enum AvailabilityStatus: String, Codable, CaseIterable, Equatable {
//    case available = "AVAILABLE"
//    case missing = "MISSING"
//    case injured = "INJURED" // used during game; kept here for consistency
//}
//
//struct GamePlayer: Identifiable, Equatable, Codable {
//    var id: UUID // stable per (gameId, playerId)
//    var gameId: UUID
//    var playerId: UUID
//    var status: AvailabilityStatus
//    var lateStartMinute: Int? // if player arrives late; nil = available from kickoff
//    var minutesPlayed: Int // accrued; 0 at pre-game
//}
//
//// MARK: - Repository Protocols
//
//protocol GameRepository {
//    func getGame(id: UUID) async throws -> Game?
//    func upsert(game: Game) async throws
//}
//
//protocol GamePlayerRepository {
//    func listGamePlayers(gameId: UUID) async throws -> [GamePlayer]
//    func upsert(gamePlayer: GamePlayer) async throws
//    func bulkUpsert(gamePlayers: [GamePlayer]) async throws
//}
//
//// MARK: - ViewModel
//
//@MainActor
//final class AvailabilityViewModel: ObservableObject {
//    struct Row: Identifiable, Equatable {
//        let id: UUID
//        let playerId: UUID
//        let name: String
//        let jerseyNumber: Int?
//        var status: AvailabilityStatus
//    }
//
//    @Published private(set) var rows: [Row] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    let teamId: UUID
//    let gameId: UUID
//    let onFieldCount: Int
//
//    private let playerRepo: PlayerRepository
//    private let gamePlayerRepo: GamePlayerRepository
//
//    init(teamId: UUID, gameId: UUID, onFieldCount: Int, playerRepo: PlayerRepository, gamePlayerRepo: GamePlayerRepository) {
//        self.teamId = teamId
//        self.gameId = gameId
//        self.onFieldCount = onFieldCount
//        self.playerRepo = playerRepo
//        self.gamePlayerRepo = gamePlayerRepo
//    }
//
//    var availableCount: Int { rows.filter { $0.status == .available }.count }
//    var isValid: Bool { availableCount >= onFieldCount }
//
//    func load() async {
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            let players = try await playerRepo.listPlayers(teamId: teamId, search: nil)
//                .sorted { (a, b) in
//                    let ja = a.jerseyNumber ?? Int.max
//                    let jb = b.jerseyNumber ?? Int.max
//                    if ja != jb { return ja < jb }
//                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
//                }
//            let gps = try await gamePlayerRepo.listGamePlayers(gameId: gameId)
//            let byPid = Dictionary(uniqueKeysWithValues: gps.map { ($0.playerId, $0) })
//
//            self.rows = players.map { p in
//                let status = byPid[p.id]?.status ?? .available // default all available pre-game
//                return Row(id: p.id, playerId: p.id, name: p.name, jerseyNumber: p.jerseyNumber, status: status)
//            }
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//
//    func setAll(_ status: AvailabilityStatus) {
//        rows = rows.map { Row(id: $0.id, playerId: $0.playerId, name: $0.name, jerseyNumber: $0.jerseyNumber, status: status) }
//    }
//
//    func toggle(row: Row) {
//        guard let idx = rows.firstIndex(of: row) else { return }
//        rows[idx].status = (row.status == .available) ? .missing : .available
//    }
//
//    func save() async {
//        do {
//            let gps: [GamePlayer] = rows.map { r in
//                GamePlayer(
//                    id: stableGamePlayerId(gameId: gameId, playerId: r.playerId),
//                    gameId: gameId,
//                    playerId: r.playerId,
//                    status: r.status,
//                    lateStartMinute: nil,
//                    minutesPlayed: 0
//                )
//            }
//            try await gamePlayerRepo.bulkUpsert(gamePlayers: gps)
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//
//    private func stableGamePlayerId(gameId: UUID, playerId: UUID) -> UUID {
//        // Derive a stable UUID from (gameId, playerId) by hashing. For demo only.
//        var hasher = Hasher()
//        hasher.combine(gameId)
//        hasher.combine(playerId)
//        let hash = hasher.finalize()
//        // Create a pseudo-UUID from hash bytes
//        let data = withUnsafeBytes(of: hash.bigEndian, Array.init)
//        var uuidBytes = [UInt8](repeating: 0, count: 16)
//        for i in 0..<min(16, data.count) { uuidBytes[i] = data[i] }
//        let uuid = UUID(uuid: uuid_t(uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3], uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7], uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11], uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]))
//        return uuid
//    }
//}
//
//// MARK: - View
//
//struct AvailabilityView: View {
//    @StateObject private var vm: AvailabilityViewModel
//    var onContinue: () -> Void
//
//    init(teamId: UUID, gameId: UUID, onFieldCount: Int, playerRepo: PlayerRepository, gamePlayerRepo: GamePlayerRepository, onContinue: @escaping () -> Void) {
//        _vm = StateObject(wrappedValue: AvailabilityViewModel(teamId: teamId, gameId: gameId, onFieldCount: onFieldCount, playerRepo: playerRepo, gamePlayerRepo: gamePlayerRepo))
//        self.onContinue = onContinue
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            header
//            banner
//            list
//            footer
//        }
//        .task { await vm.load() }
//        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
//            Button("OK", role: .cancel) {}
//        } message: { Text(vm.errorMessage ?? "") }
//    }
//
//    private var header: some View {
//        HStack(alignment: .firstTextBaseline) {
//            VStack(alignment: .leading) {
//                Text("Availability").font(.title2).bold()
//                Text("Mark who can play today").foregroundStyle(.secondary)
//            }
//            Spacer()
//            Menu {
//                Button("All Available") { vm.setAll(.available) }
//                Button("None (All Missing)") { vm.setAll(.missing) }
//            } label: {
//                Label("Bulk", systemImage: "checkmark.circle")
//            }
//            .buttonStyle(.bordered)
//        }
//        .padding([.horizontal, .top])
//    }
//
//    private var banner: some View {
//        HStack {
//            Image(systemName: vm.isValid ? "checkmark.seal" : "exclamationmark.triangle")
//            Text("Available: \(vm.availableCount) • Need on field: \(vm.onFieldCount)")
//                .fontWeight(.semibold)
//            Spacer()
//        }
//        .foregroundStyle(vm.isValid ? .green : .orange)
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
//        .padding(.horizontal)
//    }
//
//    private var list: some View {
//        List {
//            ForEach(vm.rows) { row in
//                HStack {
//                    Text("#" + jerseyText(row.jerseyNumber))
//                        .monospacedDigit()
//                        .frame(width: 36, alignment: .leading)
//                        .foregroundStyle(.secondary)
//                    Text(row.name)
//                    Spacer()
//                    Toggle("Available", isOn: Binding(
//                        get: { row.status == .available },
//                        set: { isOn in
//                            var r = row
//                            r.status = isOn ? .available : .missing
//                            vm.toggle(row: row) // toggle uses current row to flip
//                        }
//                    ))
//                    .labelsHidden()
//                }
//            }
//        }
//        .listStyle(.insetGrouped)
//    }
//
//    private var footer: some View {
//        VStack(spacing: 8) {
//            if !vm.isValid {
//                Text("You need at least \(vm.onFieldCount) players Available to proceed.")
//                    .font(.footnote)
//                    .foregroundStyle(.orange)
//            }
//            Button {
//                Task { await vm.save(); if vm.isValid { onContinue() } }
//            } label: {
//                Text("Continue to Lineup Generator")
//                    .frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(!vm.isValid)
//            .padding(.horizontal)
//            .padding(.bottom)
//        }
//    }
//
//    private func jerseyText(_ n: Int?) -> String { n.map { String(format: "%02d", $0) } ?? "–" }
//}
//
//// MARK: - In-Memory Repos for Preview/Dev
//
//@MainActor
//final class InMemoryGameRepository: GameRepository {
//    private var games: [UUID: Game] = [:]
//    func getGame(id: UUID) async throws -> Game? { games[id] }
//    func upsert(game: Game) async throws { games[game.id] = game }
//}
//
//@MainActor
//final class InMemoryGamePlayerRepository: GamePlayerRepository {
//    // ONE entry per (gameId, playerId)
//    private var items: [String: GamePlayer] = [:]
//
//    private func key(_ gid: UUID, _ pid: UUID) -> String { gid.uuidString + "|" + pid.uuidString }
//
//    func listGamePlayers(gameId: UUID) async throws -> [GamePlayer] {
//        items.values.filter { $0.gameId == gameId }
//    }
//
//    func upsert(gamePlayer: GamePlayer) async throws {
//        items[key(gamePlayer.gameId, gamePlayer.playerId)] = gamePlayer
//    }
//
//    func bulkUpsert(gamePlayers: [GamePlayer]) async throws {
//        for gp in gamePlayers { items[key(gp.gameId, gp.playerId)] = gp }
//    }
//}
//
//
//// MARK: - Preview
//
//#if DEBUG
//struct AvailabilityView_Previews: PreviewProvider {
//    static let teamId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID()
//    static let gameId = UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID()
//
//    static var playerRepo = InMemoryPlayerRepository()
//    static var gameRepo = InMemoryGameRepository()
//    static var gpRepo = InMemoryGamePlayerRepository()
//
//    static func seed() {
//        // Seed some players
//        let names = [(10, "Mia"), (4, "Leo"), (7, "Ava"), (3, "Max"), (2, "Eli"), (12, "Zoe"), (6, "Ana"), (5, "Kai"), (8, "Ray")]
//        for (num, name) in names {
//            let p = Player(id: UUID(), teamId: teamId, name: name, jerseyNumber: num)
//            try? awaitSync { try await playerRepo.upsert(player: p) }
//        }
//        // Seed a game
//        let g = Game(id: gameId, teamId: teamId, name: "vs Tigers", minutesPerHalf: 25)
//        try? awaitSync { try await gameRepo.upsert(game: g) }
//    }
//
//    static var previews: some View {
//        seed()
//        return AvailabilityView(teamId: teamId, gameId: gameId, onFieldCount: 7, playerRepo: playerRepo, gamePlayerRepo: gpRepo) {
//            // onContinue
//        }
//    }
//}
//
//// Helper to run async from previews safely
////func awaitSync(_ op: @escaping () async throws -> Void) rethrows {
////    let sema = DispatchSemaphore(value: 0)
////    Task { try? await op(); sema.signal() }
////    sema.wait()
////}
//#endif
