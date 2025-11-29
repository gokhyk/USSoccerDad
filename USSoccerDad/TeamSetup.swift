////
////  AgeGroup.swift
////  USSoccerDad
////
////  Created by Ayse Kula on 11/17/25.
////
//
//
//// USSD – TeamSetup Module (v0)
//// First‑run screen: if no team exists, ask for Team Name + Age Group (U6…U17),
//// then prefill defaults (on‑field, periods, minutes/period, goalkeepers) with
//// ability to edit before saving. Offline, protocol‑driven, loosely coupled.
//
//import SwiftUI
//
//// MARK: - Age Group ➜ Defaults
//
//public enum AgeGroup: String, CaseIterable, Identifiable {
//    case U6, U7, U8, U9, U10, U11, U12, U13, U14, U15, U16, U17
//    public var id: String { rawValue }
//}
//
//public struct TeamDefaults {
//    public var onField: Int
//    public var periods: Int
//    public var minutesPerPeriod: Int
//    public var hasDedicatedGK: Bool
//}
//
///// Heuristics based on common US youth formats (editable in UI):
///// - U6–U8: 4v4, no GK, typically 4 short periods
///// - U9–U10: 7v7 with GK
///// - U11–U12: 9v9 with GK
///// - U13+: 11v11 with GK
//public func defaults(for age: AgeGroup) -> TeamDefaults {
//    switch age {
//    case .U6, .U7, .U8:   return .init(onField: 4, periods: 2, minutesPerPeriod: 10, hasDedicatedGK: false)
//    case .U9, .U10:       return .init(onField: 7, periods: 2, minutesPerPeriod: 25, hasDedicatedGK: true)
//    case .U11, .U12:      return .init(onField: 9, periods: 2, minutesPerPeriod: 30, hasDedicatedGK: true)
//    case .U13, .U14, .U15, .U16, .U17:
//        return .init(onField: 11, periods: 2, minutesPerPeriod: 35, hasDedicatedGK: true)
//    }
//}
//
//// MARK: - Team Profile persistence (separate from Team to avoid changing existing model)
//
//public struct TeamProfile: Identifiable, Codable, Equatable {
//    public var id: UUID // profile id
//    public var teamId: UUID
//    public var ageGroup: String // AgeGroup.rawValue
//    public var onField: Int
//    public var periods: Int
//    public var minutesPerPeriod: Int
//    public var hasDedicatedGK: Bool
//    public var notes: String?
//    public var createdAt: Date = .now
//}
//
//public protocol TeamProfileRepository {
//    func getProfile(teamId: UUID) async throws -> TeamProfile?
//    func upsert(profile: TeamProfile) async throws
//}
//
//@MainActor
//public final class InMemoryTeamProfileRepository: TeamProfileRepository {
//    private var store: [UUID: TeamProfile] = [:] // keyed by teamId
//    public init() {}
//    public func getProfile(teamId: UUID) async throws -> TeamProfile? { store[teamId] }
//    public func upsert(profile: TeamProfile) async throws { store[profile.teamId] = profile }
//}
//
//// MARK: - VM
//
//@MainActor
//public final class TeamSetupViewModel: ObservableObject {
//    @Published public var teamName: String = ""
//    @Published public var ageGroup: AgeGroup = .U10
//    @Published public var onField: Int = 7
//    @Published public var periods: Int = 2
//    @Published public var minutesPerPeriod: Int = 25
//    @Published public var hasDedicatedGK: Bool = true
//    @Published public var notes: String = ""
//
//    @Published public private(set) var isLoading = false
//    @Published public private(set) var errorMessage: String?
//    //@Published public private(set) var existingTeam: Team? = nil
//    @Published private(set) var existingTeam: Team? = nil
//    
//    private let teamRepo: TeamRepository
//    private let profileRepo: TeamProfileRepository
//    public let teamId: UUID // If you want to control it externally
//
//    init(teamRepo: TeamRepository, profileRepo: TeamProfileRepository, teamId: UUID = UUID()) {
//        self.teamRepo = teamRepo
//        self.profileRepo = profileRepo
//        self.teamId = teamId
//        // initialize defaults based on starting ageGroup
//        applyDefaults(for: ageGroup)
//    }
//
//    public func load() async {
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            let teams = try await teamRepo.listTeams()
//            existingTeam = teams.first
//        } catch { errorMessage = error.localizedDescription }
//    }
//
//    public func onAgeGroupChanged(_ new: AgeGroup) {
//        applyDefaults(for: new)
//    }
//
//    public func clearError() { errorMessage = nil }
//    
//    private func applyDefaults(for age: AgeGroup) {
//        let d = defaults(for: age)
//        self.onField = d.onField
//        self.periods = d.periods
//        self.minutesPerPeriod = d.minutesPerPeriod
//        self.hasDedicatedGK = d.hasDedicatedGK
//    }
//
//    public func saveNewTeam() async -> Bool {
//        guard !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            errorMessage = "Please enter a team name."
//            return false
//        }
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            let team = Team(id: teamId, name: teamName.trimmingCharacters(in: .whitespacesAndNewlines))
//            try await teamRepo.upsert(team: team)
//            let profile = TeamProfile(
//                id: UUID(),
//                teamId: team.id,
//                ageGroup: ageGroup.rawValue,
//                onField: onField,
//                periods: periods,
//                minutesPerPeriod: minutesPerPeriod,
//                hasDedicatedGK: hasDedicatedGK,
//                notes: notes.isEmpty ? nil : notes
//            )
//            try await profileRepo.upsert(profile: profile)
//            existingTeam = team
//            return true
//        } catch {
//            errorMessage = error.localizedDescription
//            return false
//        }
//    }
//}
//
//// MARK: - View
//
//public struct TeamSetupView: View {
//    @StateObject private var vm: TeamSetupViewModel
//    var onContinue: (_ team: Team) -> Void
//
//    init(teamRepo: TeamRepository, profileRepo: TeamProfileRepository, prechosenTeamId: UUID? = nil, onContinue: @escaping (_ team: Team) -> Void) {
//        _vm = StateObject(wrappedValue: TeamSetupViewModel(teamRepo: teamRepo, profileRepo: profileRepo, teamId: prechosenTeamId ?? UUID()))
//        self.onContinue = onContinue
//    }
//
//    public var body: some View {
//        Group {
//            if let team = vm.existingTeam {
//                existingTeamCard(team)
//            } else {
//                setupForm
//            }
//        }
//        .task { await vm.load() }
//        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil },
//                set: { _ in vm.clearError() })) {
//            
//            //set: { _ in vm.clearError() })
//            Button("OK", role: .cancel) {}
//        } message: { Text(vm.errorMessage ?? "") }
//        .navigationTitle("Team Setup")
//    }
//
//    // MARK: Existing team path
//    private func existingTeamCard(_ team: Team) -> some View {
//        VStack(spacing: 12) {
//            Image(systemName: "soccerball")
//                .font(.system(size: 48))
//            Text("Welcome back!").font(.title2).bold()
//            Text("Team: \(team.name)")
//                .foregroundStyle(.secondary)
//            Button {
//                onContinue(team)
//            } label: {
//                Text("Continue")
//                    .frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.borderedProminent)
//            .padding(.horizontal)
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//    }
//
//    // MARK: New team path
//    private var setupForm: some View {
//        Form {
//            Section("Team") {
//                TextField("Team name (e.g., U10 Tigers)", text: $vm.teamName)
//                Picker("Age group", selection: $vm.ageGroup) {
//                    ForEach(AgeGroup.allCases) { ag in
//                        Text(ag.rawValue).tag(ag)
//                    }
//                }
//                .onChange(of: vm.ageGroup) { _, new in vm.onAgeGroupChanged(new) }
//            }
//
//            Section("Defaults (editable)") {
//                Stepper(value: $vm.onField, in: 3...11) { Text("Players on field: \(vm.onField)") }
//                Stepper(value: $vm.periods, in: 2...4) { Text("# of periods: \(vm.periods)") }
//                Stepper(value: $vm.minutesPerPeriod, in: 5...45) { Text("Minutes per period: \(vm.minutesPerPeriod)") }
//                Toggle("Dedicated goalkeepers?", isOn: $vm.hasDedicatedGK)
//            }
//
//            Section("Notes (optional)") {
//                TextField("Any league‑specific rules or notes", text: $vm.notes, axis: .vertical)
//                    .lineLimit(3, reservesSpace: true)
//            }
//
//            Section {
//                Button {
//                    Task {
//                        if await vm.saveNewTeam() {
//                            if let team = vm.existingTeam { onContinue(team) }
//                        }
//                    }
//                } label: { Text("Save & Continue") }
//                .disabled(vm.teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//            }
//        }
//    }
//}
//
//// MARK: - Minimal preview (requires InMemory repos from your project)
//#if DEBUG
//struct TeamSetupView_Previews: PreviewProvider {
//    static var teamRepo = InMemoryTeamRepository()
//    static var profileRepo = InMemoryTeamProfileRepository()
//
//    static var previews: some View {
//        NavigationStack {
//            TeamSetupView(teamRepo: teamRepo, profileRepo: profileRepo) { team in
//                Text("Continue to app for team: \(team.name)")
//            }
//        }
//    }
//}
//#endif
