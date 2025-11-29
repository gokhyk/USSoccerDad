//// SoccerDad – Lineup Generator Module (v0)
//// Builds an initial rotation plan from Availability settings.
//// Loosely coupled via protocol-driven engine + repositories; offline-only v1.
//// NOTE: This file references types/protocols from the Roster & Availability modules:
//// - Player, PlayerRepository
//// - Game, GamePlayer, GamePlayerRepository, AvailabilityStatus
//// If you compiled those modules, DO NOT re-declare these types.
//
//import SwiftUI
//
//// MARK: - Rotation Domain
//
//enum RotationMode: String, CaseIterable, Codable {
//    case minRotations = "MIN_ROTATIONS"
//    case minShiftMinutes = "MIN_SHIFT_MINUTES"
//    case balanced = "BALANCED"
//}
//
//struct RotationSettings: Equatable, Codable {
//    var minutesPerHalf: Int = 10
//    var mode: RotationMode = .balanced
//    var minRotationsPerGame: Int? = 2           // used when mode == .minRotations
//    var minShiftMinutes: Int? = 4               // used when mode == .minShiftMinutes
//    var onFieldCount: Int = 4                   // 7v7 default
//}
//
//struct RotationWindow: Identifiable, Equatable, Codable {
//    var id: UUID = UUID()
//    var start: Int // minute
//    var end: Int   // minute (exclusive)
//}
//
//struct RotationAssignment: Identifiable, Equatable, Codable {
//    var id: UUID = UUID()
//    var window: RotationWindow
//    var onFieldPlayerIds: [UUID] // exactly onFieldCount entries
//}
//
//struct Rotation: Identifiable, Equatable, Codable {
//    var id: UUID
//    var gameId: UUID
//    var playerId: UUID
//    var startMinute: Int
//    var endMinute: Int
//}
//
//protocol RotationRepository {
//    func listRotations(gameId: UUID) async throws -> [Rotation]
//    func bulkReplace(gameId: UUID, with rotations: [Rotation]) async throws
//}
//
//// MARK: - Rotation Engine Protocol + Simple Impl
//
//protocol RotationEngine {
//    func buildWindows(totalMinutes: Int, settings: RotationSettings, startMinute: Int) throws -> [RotationWindow]
//    func assignPlayers(windows: [RotationWindow], eligible: [UUID], onFieldCount: Int) -> [RotationAssignment]
//}
//
//enum RotationConfigError: LocalizedError {
//    case invalid(String)
//    case impossible(String)
//
//    var errorDescription: String? {
//        switch self {
//        case .invalid(let s): return s
//        case .impossible(let s): return s
//        }
//    }
//}
//
//final class SimpleRotationEngine: RotationEngine {
//    func buildWindows(totalMinutes: Int, settings: RotationSettings, startMinute: Int = 0) throws -> [RotationWindow] {
//        guard totalMinutes > 0 else { throw RotationConfigError.invalid("Total minutes must be > 0") }
//        let mode = settings.mode
//        let W: Int
//        switch mode {
//        case .minRotations:
//            guard let R = settings.minRotationsPerGame, R >= 1 else { throw RotationConfigError.invalid("Set minRotationsPerGame ≥ 1") }
//            let maxShiftCap = 20
//            W = max(R, Int(ceil(Double(totalMinutes) / Double(maxShiftCap))))
//        case .minShiftMinutes:
//            guard let S = settings.minShiftMinutes, S >= 3 else { throw RotationConfigError.invalid("Set minShiftMinutes ≥ 3") }
//            W = max(1, Int(ceil(Double(totalMinutes) / Double(S))))
//        case .balanced:
//            let target = 10 // aim 8–12
//            W = max(1, Int(round(Double(totalMinutes) / Double(target))))
//        }
//        let base = totalMinutes / W
//        guard base >= 3 && W <= 32 else { throw RotationConfigError.impossible("Unreasonable window count/length. Adjust settings.") }
//
//        var windows: [RotationWindow] = []
//        var t = startMinute
//        for i in 0..<W {
//            let len = base + (i < (totalMinutes % W) ? 1 : 0)
//            windows.append(RotationWindow(start: t, end: t + len))
//            t += len
//        }
//        return windows
//    }
//
//    func assignPlayers(windows: [RotationWindow], eligible: [UUID], onFieldCount: Int) -> [RotationAssignment] {
//        let uniqueEligible = Array(Set(eligible))
//        guard !uniqueEligible.isEmpty else { return windows.map { RotationAssignment(window: $0, onFieldPlayerIds: []) } }
//
//        let totalMinutes = (windows.last?.end ?? 0) - (windows.first?.start ?? 0)
//        let targetPerPlayer = Int(round(Double(totalMinutes * onFieldCount) / Double(uniqueEligible.count)))
//
//        var minutesPlayed = Dictionary(uniqueKeysWithValues: uniqueEligible.map { ($0, 0) })
//        var wasOnLast: Set<UUID> = []
//        var result: [RotationAssignment] = []
//
//        for w in windows {
//            let len = w.end - w.start
//            let sortedEligible = uniqueEligible.sorted { a, b in
//                let d1 = targetPerPlayer - (minutesPlayed[a] ?? 0)
//                let d2 = targetPerPlayer - (minutesPlayed[b] ?? 0)
//                if d1 != d2 { return d1 > d2 }
//                let r1 = wasOnLast.contains(a) ? 0 : 1
//                let r2 = wasOnLast.contains(b) ? 0 : 1
//                if r1 != r2 { return r1 > r2 }
//                return a.uuidString < b.uuidString
//            }
//            let pick = Array(sortedEligible.prefix(onFieldCount))
//            result.append(RotationAssignment(window: w, onFieldPlayerIds: pick))
//            wasOnLast.removeAll()
//            for id in pick {
//                minutesPlayed[id, default: 0] += len
//                wasOnLast.insert(id)
//            }
//        }
//        return result
//    }
//
//}
//
//// MARK: - ViewModel
//
//@MainActor
//final class LineupGeneratorViewModel: ObservableObject {
//    @Published var settings: RotationSettings
//    @Published private(set) var windows: [RotationWindow] = []
//    @Published private(set) var plan: [RotationAssignment] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    let teamId: UUID
//    let gameId: UUID
//
//    let playerRepo: PlayerRepository
//    private let gamePlayerRepo: GamePlayerRepository
//    private let rotationRepo: RotationRepository
//    private let engine: RotationEngine
//
//    init(teamId: UUID, gameId: UUID, playerRepo: PlayerRepository, gamePlayerRepo: GamePlayerRepository, rotationRepo: RotationRepository, engine: RotationEngine = SimpleRotationEngine()) {
//        self.teamId = teamId
//        self.gameId = gameId
//        self.playerRepo = playerRepo
//        self.gamePlayerRepo = gamePlayerRepo
//        self.rotationRepo = rotationRepo
//        self.engine = engine
//        self.settings = RotationSettings()
//    }
//
//    var totalMinutes: Int { settings.minutesPerHalf * 2 }
//
//    func generate() async {
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            // 1) Build windows
//            let ws = try engine.buildWindows(totalMinutes: totalMinutes, settings: settings, startMinute: 0)
//            self.windows = ws
//
//            // 2) Get eligible players (Available at kickoff)
//            // LineupGeneratorViewModel.generate()
//            let gps = try await gamePlayerRepo.listGamePlayers(gameId: gameId)
//            let eligible = Array(Set(gps.filter { $0.status == .available }.map { $0.playerId }))
//
//            guard eligible.count >= settings.onFieldCount else {
//                throw RotationConfigError.impossible("Not enough available players (need at least \(settings.onFieldCount)).")
//            }
//
//            // 3) Assign
//            self.plan = engine.assignPlayers(windows: ws, eligible: eligible, onFieldCount: settings.onFieldCount)
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//
//    func savePlan() async {
//        do {
//            // Flatten plan to Rotation rows
//            var rows: [Rotation] = []
//            for a in plan {
//                for pid in a.onFieldPlayerIds {
//                    rows.append(Rotation(id: UUID(), gameId: gameId, playerId: pid, startMinute: a.window.start, endMinute: a.window.end))
//                }
//            }
//            try await rotationRepo.bulkReplace(gameId: gameId, with: rows)
//        } catch {
//            self.errorMessage = error.localizedDescription
//        }
//    }
//    
//    
//    // Inside LineupGeneratorViewModel
//    func playerLabelMap() async -> [UUID: String] {
//        do {
//            let players = try await playerRepo.listPlayers(teamId: teamId, search: nil)
//            let map: [UUID: String] = Dictionary(uniqueKeysWithValues: players.map { p in
//                let jersey = p.jerseyNumber.map { String(format: "%02d", $0) } ?? "–"
//                return (p.id, "#\(jersey) \(p.name)")
//            })
//            return map
//        } catch {
//            return [:]
//        }
//    }
//}
//
//// MARK: - View
//
//struct LineupGeneratorView: View {
//    @StateObject private var vm: LineupGeneratorViewModel
//    @State private var previewRows: [DisplayRow] = []
//
//    struct DisplayRow: Identifiable { let id = UUID(); let title: String; let detail: String }
//
//    init(teamId: UUID, gameId: UUID, playerRepo: PlayerRepository, gamePlayerRepo: GamePlayerRepository, rotationRepo: RotationRepository) {
//        _vm = StateObject(wrappedValue: LineupGeneratorViewModel(teamId: teamId, gameId: gameId, playerRepo: playerRepo, gamePlayerRepo: gamePlayerRepo, rotationRepo: rotationRepo))
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            form
//            actions
//            preview
//        }
//        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
//            Button("OK", role: .cancel) {}
//        } message: { Text(vm.errorMessage ?? "") }
//        .navigationTitle("Lineup Generator")
//    }
//
//    private var form: some View {
//        Form {
//            Section("Game Settings") {
//                Stepper(value: $vm.settings.minutesPerHalf, in: 10...45) {
//                    Text("Minutes per half: \(vm.settings.minutesPerHalf)")
//                }
//                Stepper(value: $vm.settings.onFieldCount, in: 3...11) {
//                    Text("On-field count: \(vm.settings.onFieldCount)")
//                }
//            }
//            Section("Rotation Mode") {
//                Picker("Mode", selection: $vm.settings.mode) {
//                    Text("Balanced").tag(RotationMode.balanced)
//                    Text("Min Rotations").tag(RotationMode.minRotations)
//                    Text("Min Shift Minutes").tag(RotationMode.minShiftMinutes)
//                }.pickerStyle(.segmented)
//
//                if vm.settings.mode == .minRotations {
//                    Stepper(value: Binding(get: { vm.settings.minRotationsPerGame ?? 3 }, set: { vm.settings.minRotationsPerGame = $0 }), in: 1...12) {
//                        Text("Rotations per game: \(vm.settings.minRotationsPerGame ?? 3)")
//                    }
//                }
//                if vm.settings.mode == .minShiftMinutes {
//                    Stepper(value: Binding(get: { vm.settings.minShiftMinutes ?? 8 }, set: { vm.settings.minShiftMinutes = $0 }), in: 3...20) {
//                        Text("Min shift minutes: \(vm.settings.minShiftMinutes ?? 8)")
//                    }
//                }
//            }
//        }
//    }
//
//    private var actions: some View {
//        HStack {
//            Button {
//                Task { await vm.generate(); await buildDisplayRows() }
//            } label: {
//                Label("Generate", systemImage: "gear")
//            }
//            .buttonStyle(.borderedProminent)
//
//            Button {
//                Task { await vm.savePlan() }
//            } label: {
//                Label("Use This Plan", systemImage: "checkmark")
//            }
//            .buttonStyle(.bordered)
//            .disabled(vm.plan.isEmpty)
//
//            Spacer()
//        }
//        .padding([.horizontal, .bottom])
//    }
//
//    private var preview: some View {
//        List(previewRows) { row in
//            VStack(alignment: .leading) {
//                Text(row.title).bold()
//                Text(row.detail).font(.footnote).foregroundStyle(.secondary)
//            }
//        }
//        .listStyle(.insetGrouped)
//    }
//
//
//    private func buildDisplayRows() async {
//        // Need player names to show pretty rows
//        do {
//            let players = try await vm.playerRepo.listPlayers(teamId: vm.teamId, search: nil)
//            let nameById = Dictionary(uniqueKeysWithValues: players.map { ($0.id, "#\($0.jerseyNumber ?? 0) \($0.name)") })
//            previewRows = vm.plan.enumerated().map { (idx, a) in
//                let t = "W\(idx+1)  \(a.window.start)'–\(a.window.end)'"
//                let detail = a.onFieldPlayerIds.map { nameById[$0] ?? $0.uuidString }.joined(separator: ", ")
//                return DisplayRow(title: t, detail: detail)
//            }
//        } catch {
//            previewRows = vm.plan.enumerated().map { (idx, a) in
//                let t = "W\(idx+1)  \(a.window.start)'–\(a.window.end)'"
//                let detail = a.onFieldPlayerIds.map { $0.uuidString }.joined(separator: ", ")
//                return DisplayRow(title: t, detail: detail)
//            }
//        }
//    }
//    
//    // Inside LineupGeneratorView
////    private func buildDisplayRows() async {
////        let nameById = await vm.playerLabelMap()
////        previewRows = vm.plan.enumerated().map { (idx, a) in
////            let t = "W\(idx+1)  \(a.window.start)'–\(a.window.end)'"
////            let detail = a.onFieldPlayerIds.map { nameById[$0] ?? $0.uuidString }.joined(separator: ", ")
////            return DisplayRow(title: t, detail: detail)
////        }
////    }
//
//}
//
//// MARK: - In-Memory Rotation Repo + Preview
//
//@MainActor
//final class InMemoryRotationRepository: RotationRepository {
//    private var items: [UUID: [Rotation]] = [:] // keyed by gameId
//    func listRotations(gameId: UUID) async throws -> [Rotation] { items[gameId] ?? [] }
//    func bulkReplace(gameId: UUID, with rotations: [Rotation]) async throws { items[gameId] = rotations }
//}
//
////#if DEBUG
//struct LineupGeneratorView_Previews: PreviewProvider {
//    static let teamId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID()
//    static let gameId = UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID()
//
//    static var playerRepo = InMemoryPlayerRepository()
//    static var gamePlayerRepo = InMemoryGamePlayerRepository()
//    static var rotationRepo = InMemoryRotationRepository()
//
//    static func seed() {
//        // players
//        let names = [(10,"Mia"),(4,"Leo"),(7,"Ava"),(3,"Max"),(2,"Eli"),(12,"Zoe"),(6,"Ana"),(5,"Kai"),(8,"Ray")]
//        for (num, name) in names {
//            awaitSync { try await playerRepo.upsert(player: Player(id: UUID(), teamId: teamId, name: name, jerseyNumber: num)) }
//        }
//        // availability: mark all available for kickoff
//        let pList = awaitSyncRet { try await playerRepo.listPlayers(teamId: teamId, search: nil) } ?? []
//        for p in pList {
//            let gp = GamePlayer(id: UUID(), gameId: gameId, playerId: p.id, status: .available, lateStartMinute: nil, minutesPlayed: 0)
//            awaitSync { try await gamePlayerRepo.upsert(gamePlayer: gp) }
//        }
//    }
//
//    static var previews: some View {
//        seed()
//        return NavigationStack {
//            LineupGeneratorView(teamId: teamId, gameId: gameId, playerRepo: playerRepo, gamePlayerRepo: gamePlayerRepo, rotationRepo: rotationRepo)
//        }
//    }
//}
//
//func awaitSync(_ op: @escaping () async throws -> Void)  {
//    let sema = DispatchSemaphore(value: 0)
//    Task { try? await op(); sema.signal() }
//    sema.wait()
//}
//
//func awaitSyncRet<T>(_ op: @escaping () async throws -> T) -> T?  {
//    let sema = DispatchSemaphore(value: 0)
//    var out: T?
//    Task { out = try? await op(); sema.signal() }
//    sema.wait()
//    return out
//}
////#endif
