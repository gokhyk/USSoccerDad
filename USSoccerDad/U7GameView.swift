//
//  U7GameView.swift
//  USSoccerDad
//
//  Refactored with all fixes applied
//

import SwiftUI

struct U7GameView: View {
    @ObservedObject var vm: U7GameViewModel
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let state = vm.gameState {
                    // Game Status Header
                    gameStatusHeader(state: state)
                    
                    // Main Control Section
                    if state.status != .finished {
                        mainControls(state: state)
                    }
                    
                    Divider()
                    
                    // Substitution Alert (only during active play, NOT at quarter breaks)
                    if let pending = vm.pendingSub, !vm.isAtQuarterEnd {
                        substitutionAlert(pending: pending, state: state)
                    }
                    
                    // Players Section
                    playersOnField(state: state)
                    
                    playersBench(state: state)
                    
                    // End of Game Actions
                    if state.status == .finished {
                        Divider()
                        endOfGameActions(state: state)
                    }
                    
                } else {
                    Text("No game started")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("U5/6/7 Game")
        .onReceive(timer) { _ in
            vm.tickOneSecond()
        }
    }
    
    // MARK: - Game Status Header
    
    private func gameStatusHeader(state: GameState) -> some View {
        VStack(spacing: 12) {
            // Only show status badge if it's NOT normalGame (most common case)
            if state.status != .normalGame {
                HStack {
                    Image(systemName: statusIcon(state.status))
                        .foregroundStyle(statusColor(state.status))
                    Text(state.status.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor(state.status))
                }
                .font(.headline)
            }
            
            // Quarter/Period Info - FIXED: Now shows correct total periods
            if state.currentQuarter > 0 && state.currentQuarter <= state.config.periods {
                Text("Quarter \(state.currentQuarter) of \(state.config.periods)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Game Clock - only show during active quarters
            if vm.isRunning && state.status != .finished {
                HStack {
                    Image(systemName: "clock.fill")
                    Text(vm.gameClockText)
                }
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            }
            
            // Total Game Time
            let totalMinutes = state.totalSecondsElapsed / 60
            Text("Total: \(totalMinutes) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Main Controls
    
    private func mainControls(state: GameState) -> some View {
        VStack(spacing: 16) {
            if !vm.isRunning {
                // Start Game or Start Next Quarter
                if state.currentQuarter == 1 && state.totalSecondsElapsed == 0 {
                    Button {
                        vm.startWhistle()
                    } label: {
                        Label("START GAME", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if vm.isAtQuarterEnd && state.currentQuarter <= state.config.periods {
                    VStack(spacing: 12) {
                        Text("Quarter \(state.currentQuarter) Complete!")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        // Show next quarter starters if applicable
                        if state.currentQuarter < state.config.periods {
                            nextQuarterStartersPreview(state: state)
                        }
                        
                        Button {
                            vm.endCurrentQuarter()
                            if state.currentQuarter < state.config.periods {
                                // Auto-start next quarter after a brief moment
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    vm.startWhistle()
                                }
                            }
                        } label: {
                            if state.currentQuarter < state.config.periods {
                                Label("START QUARTER \(state.currentQuarter + 1)", systemImage: "play.circle.fill")
                            } else {
                                Label("END GAME", systemImage: "flag.checkered")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(Color(.systemGreen).opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                // Pause/Resume button
                HStack(spacing: 16) {
                    Button {
                        vm.togglePause()
                    } label: {
                        Label(
                            vm.isPaused ? "Resume" : "Pause",
                            systemImage: vm.isPaused ? "play.fill" : "pause.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                // Speed Control (only show when running)
                if !vm.isPaused {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Speed", selection: $vm.speedMultiplier) {
                            Text("1×").tag(1)
                            Text("5×").tag(5)
                            Text("10×").tag(10)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }
    
    // MARK: - Next Quarter Starters Preview
    
    private func nextQuarterStartersPreview(state: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Quarter Starters:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Preview who will start (using the rebalance logic)
            let nextStarters = vm.previewNextQuarterStarters()
            
            ForEach(nextStarters.prefix(state.config.playersOnField), id: \.id) { player in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(player.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(player.minutesThisGame) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Substitution Alert
    
    private func substitutionAlert(pending: PendingSubstitution, state: GameState) -> some View {
        VStack(spacing: 16) {
            // Countdown Display
            HStack {
                Image(systemName: pending.secondsRemaining <= 15 ? "exclamationmark.triangle.fill" : "clock.badge.checkmark")
                    .foregroundStyle(pending.secondsRemaining <= 15 ? .red : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Substitution Ready")
                        .font(.headline)
                    Text(formatCountdown(pending.secondsRemaining))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(pending.secondsRemaining <= 15 ? .red : .orange)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Substitution Details
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(pending.pairs.enumerated()), id: \.offset) { _, pair in
                    HStack {
                        // Player coming IN
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.green)
                            Text(playerName(pair.in, in: state))
                                .fontWeight(.semibold)
                        }
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(.secondary)
                        
                        // Player coming OUT
                        HStack {
                            Text(playerName(pair.out, in: state))
                            Image(systemName: "arrow.left.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.subheadline)
                }
            }
            
            // Confirm Button
            Button {
                vm.confirmSubstitution()
            } label: {
                Label("Confirm Substitution", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(pending.secondsRemaining <= 15 ? Color.red : Color.orange, lineWidth: 2)
        )
    }
    
    // MARK: - Players on Field
    
    private func playersOnField(state: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
                Text("On Field")
                    .font(.headline)
                Spacer()
                Text("\(state.players.filter { $0.isOnField }.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            let onFieldPlayers = state.players.filter { $0.isOnField }
            
            if onFieldPlayers.isEmpty {
                Text("No players on field")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(onFieldPlayers) { player in
                        playerRow(player: player, state: state, isOnField: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Players on Bench
    
    private func playersBench(state: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.seated.side")
                    .foregroundStyle(.blue)
                Text("Bench")
                    .font(.headline)
                Spacer()
                let benchCount = state.players.filter { !$0.isOnField && $0.isAvailable }.count
                Text("\(benchCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            let benchPlayers = state.players.filter { !$0.isOnField && $0.isAvailable }
            
            if benchPlayers.isEmpty {
                Text("No players on bench")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(benchPlayers) { player in
                        playerRow(player: player, state: state, isOnField: false)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Player Row
    
    private func playerRow(player: PlayerGameRuntime, state: GameState, isOnField: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .fontWeight(.medium)
                    
                    if player.isInjured {
                        Image(systemName: "cross.case.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 12) {
                    // Playing time this game
                    Label("\(player.minutesThisGame) min", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Continuous time (only if on field)
                    if isOnField {
                        Label("↻ \(player.continuousMinutesThisGame) min", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            if isOnField {
                Button {
                    vm.markInjured(player.id)
                } label: {
                    Image(systemName: "cross.case")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else if player.isInjured {
                Button {
                    vm.markRecovered(player.id)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - End of Game Actions
    
    private func endOfGameActions(state: GameState) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.largeTitle)
                .foregroundStyle(.green)
            
            Text("Game Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            Button {
                Task {
                    await vm.applyGameMinutesToPlayers()
                }
            } label: {
                Label("Save Minutes to Season", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            
            NavigationLink {
                GameReportView(state: state)
            } label: {
                Label("View Game Report", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func statusIcon(_ status: GameStatus) -> String {
        switch status {
        case .notStarted: return "clock"
        case .forfeit: return "xmark.circle"
        case .noSubGame: return "person.2"
        case .normalGame: return "play.circle"
        case .finished: return "flag.checkered"
        }
    }
    
    private func statusColor(_ status: GameStatus) -> Color {
        switch status {
        case .notStarted: return .gray
        case .forfeit: return .red
        case .noSubGame: return .orange
        case .normalGame: return .green
        case .finished: return .blue
        }
    }
    
    private func playerName(_ id: PlayerID, in state: GameState) -> String {
        state.players.first(where: { $0.id == id })?.name ?? "Unknown"
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let minutes = absSeconds / 60
        let remainingSeconds = absSeconds % 60
        let sign = seconds < 0 ? "-" : ""
        return "\(sign)\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

// MARK: - Game Report View

struct GameReportView: View {
    let state: GameState
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Report")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(state.config.periods) quarters × \(state.config.minutesPerPeriod) min")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Playing Time Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Playing Time")
                        .font(.headline)
                    
                    let available = state.players.filter { $0.isAvailable && !$0.isInjured }
                    
                    ForEach(available.sorted(by: { $0.minutesThisGame > $1.minutesThisGame })) { player in
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text("\(player.minutesThisGame) min")
                                .fontWeight(.semibold)
                            
                            // Fairness indicator
                            let targetMinutes = (state.config.minutesPerPeriod * state.config.periods * state.config.playersOnField) / available.count
                            let diff = player.minutesThisGame - targetMinutes
                            
                            if abs(diff) <= 1 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if abs(diff) <= 2 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    // Statistics
                    let minutes = available.map { $0.minutesThisGame }
                    if let min = minutes.min(), let max = minutes.max() {
                        HStack {
                            Text("Spread:")
                            Spacer()
                            Text("\(max - min) min")
                                .foregroundStyle(max - min <= 2 ? .green : .orange)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Injured Players
                let injured = state.players.filter { $0.isInjured }
                if !injured.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Injuries")
                            .font(.headline)
                        
                        ForEach(injured) { player in
                            HStack {
                                Image(systemName: "cross.case.fill")
                                    .foregroundStyle(.red)
                                Text(player.name)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Unavailable Players
                let unavailable = state.players.filter { !$0.isAvailable }
                if !unavailable.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Absent")
                            .font(.headline)
                        
                        ForEach(unavailable) { player in
                            Text(player.name)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Share Button
                Button {
                    showShareSheet = true
                } label: {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Game Report")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: generateReportText())
        }
    }
    
    private func generateReportText() -> String {
        var text = "⚽️ Game Report\n\n"
        text += "Format: \(state.config.periods) quarters × \(state.config.minutesPerPeriod) minutes\n\n"
        
        text += "📊 Playing Time:\n"
        let available = state.players.filter { $0.isAvailable && !$0.isInjured }
            .sorted(by: { $0.minutesThisGame > $1.minutesThisGame })
        
        for player in available {
            text += "• \(player.name): \(player.minutesThisGame) min\n"
        }
        
        let minutes = available.map { $0.minutesThisGame }
        if let min = minutes.min(), let max = minutes.max() {
            text += "\nSpread: \(max - min) minutes\n"
        }
        
        let injured = state.players.filter { $0.isInjured }
        if !injured.isEmpty {
            text += "\n🚑 Injuries:\n"
            for player in injured {
                text += "• \(player.name)\n"
            }
        }
        
        let unavailable = state.players.filter { !$0.isAvailable }
        if !unavailable.isEmpty {
            text += "\n❌ Absent:\n"
            for player in unavailable {
                text += "• \(player.name)\n"
            }
        }
        
        return text
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
