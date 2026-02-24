//
//  ActiveGameView.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import SwiftUI

struct ActiveGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    let opponentName: String

    var session: GameSession? { viewModel.session }

    var absentPlayers: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playerStats.filter { !$0.wasPresent }
    }

    var playersLeftEarly: [PlayerGameStats] {
        guard let session = session else { return [] }
        return session.playersLeftEarly
    }

    private let twoColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            if let session = session {

                // Compact clock row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Period \(session.currentPeriod) of \(session.config.periods)")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.textSecondary)
                        Text(session.formattedPeriodElapsed)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(themeManager.colors.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        // 5x speed toggle for testing
                        Button {
                            viewModel.speedMultiplier = viewModel.speedMultiplier == 1 ? 5 : 1
                        } label: {
                            Text(viewModel.speedMultiplier == 5 ? "5x" : "1x")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(viewModel.speedMultiplier == 5
                                    ? themeManager.colors.warning
                                    : themeManager.colors.surface)
                                .foregroundColor(viewModel.speedMultiplier == 5
                                    ? .white
                                    : themeManager.colors.textTertiary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        if let nextSub = session.substitutionPlans.first(where: { !$0.isCompleted }) {
                            Text("Next Sub \(nextSub.formattedTime)")
                                .font(.caption2)
                                .foregroundColor(themeManager.colors.primary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(themeManager.colors.surface.opacity(0.15))

                // Score row
                HStack(spacing: 0) {
                    // Our score
                    HStack(spacing: 14) {
                        Button {
                            session.ourScore = max(0, session.ourScore - 1)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundColor(themeManager.colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 1) {
                            Text("\(session.ourScore)")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.colors.textPrimary)
                            Text("Us")
                                .font(.caption2)
                                .foregroundColor(themeManager.colors.textSecondary)
                        }

                        Button {
                            session.ourScore += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.colors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)

                    Text("–")
                        .font(.title)
                        .foregroundColor(themeManager.colors.textTertiary)

                    // Opponent score
                    HStack(spacing: 14) {
                        Button {
                            session.opponentScore = max(0, session.opponentScore - 1)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundColor(themeManager.colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 1) {
                            Text("\(session.opponentScore)")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.colors.textPrimary)
                            Text(opponentName.isEmpty ? "Opp" : opponentName)
                                .font(.caption2)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .lineLimit(1)
                        }

                        Button {
                            session.opponentScore += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.colors.error)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(themeManager.colors.surface.opacity(0.08))

                Divider()

                // Injury sub proposal banner
                if let proposal = viewModel.forcedSubProposal {
                    VStack(spacing: 6) {
                        HStack {
                            Label("INJURY SUB", systemImage: "bandage.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.warning)
                            Spacer()
                            if viewModel.autoCompleteSubstitutions && proposal.countdownSeconds > 0 {
                                Text("Auto in \(proposal.countdownSeconds)s")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                        }
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Coming off")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.colors.textTertiary)
                                Text(proposal.playerOutName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.textPrimary)
                            }
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Going in")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.colors.success)
                                Text(proposal.proposedPlayerInName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.success)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button("Skip") {
                                    viewModel.dismissForcedSub()
                                }
                                .font(.footnote)
                                .foregroundColor(themeManager.colors.textTertiary)
                                .buttonStyle(.plain)
                                Button("Sub In") {
                                    viewModel.confirmForcedSub()
                                }
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(themeManager.colors.success)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(themeManager.colors.warning.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(themeManager.colors.warning.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // All player sections — no scroll
                VStack(alignment: .leading, spacing: 10) {

                    // On Field
                    playerSection("On Field (\(session.playersOnField.count))", color: themeManager.colors.success) {
                        LazyVGrid(columns: twoColumns, spacing: 8) {
                            ForEach(session.playersOnField.sorted { $0.playerName < $1.playerName }) { player in
                                onFieldCard(player)
                            }
                        }
                    }

                    // On Bench
                    playerSection("Bench (\(session.playersOffField.count))", color: themeManager.colors.textSecondary) {
                        LazyVGrid(columns: twoColumns, spacing: 8) {
                            ForEach(session.playersOffField.sorted { $0.playerName < $1.playerName }) { player in
                                benchCard(player)
                            }
                        }
                    }

                    // Absent
                    if !absentPlayers.isEmpty {
                        playerSection("Absent (\(absentPlayers.count))", color: themeManager.colors.error) {
                            LazyVGrid(columns: twoColumns, spacing: 8) {
                                ForEach(absentPlayers.sorted { $0.playerName < $1.playerName }) { player in
                                    absentCard(player)
                                }
                            }
                        }
                    }

                    // Left Early
                    if !playersLeftEarly.isEmpty {
                        playerSection("Left Early (\(playersLeftEarly.count))", color: themeManager.colors.warning) {
                            LazyVGrid(columns: twoColumns, spacing: 8) {
                                ForEach(playersLeftEarly.sorted { $0.playerName < $1.playerName }) { player in
                                    leftEarlyCard(player)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Game Running")
        .background(themeManager.colors.background)
    }

    // MARK: - Section header

    @ViewBuilder
    private func playerSection<Content: View>(_ title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .textCase(.uppercase)
            content()
        }
    }

    // MARK: - Player cards

    @ViewBuilder
    private func onFieldCard(_ player: PlayerGameStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(themeManager.colors.success)
                    .frame(width: 10, height: 10)
                Text(player.playerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.textPrimary)
                    .lineLimit(1)
                if player.isGoalkeeper {
                    Text("GK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.18))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                Spacer(minLength: 2)
                Button {
                    // X on field player = injury sub out (mark injured, move to bench, propose replacement)
                    viewModel.forcedSubOut(playerId: player.id)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(themeManager.colors.error)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
            }
            Text(player.formattedSecondsPlayed)
                .font(.footnote)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.success.opacity(0.12))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func benchCard(_ player: PlayerGameStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(player.isInjured ? themeManager.colors.error : themeManager.colors.textTertiary)
                    .frame(width: 10, height: 10)
                Text(player.playerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.textPrimary)
                    .lineLimit(1)
                if player.isInjured {
                    Text("INJURED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(themeManager.colors.error.opacity(0.15))
                        .foregroundColor(themeManager.colors.error)
                        .cornerRadius(4)
                } else if player.isGoalkeeper {
                    Text("GK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.18))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                Spacer(minLength: 2)
                if player.isInjured {
                    // Green heal button for injured players
                    Button {
                        viewModel.healInjuredPlayer(playerId: player.id)
                    } label: {
                        Image(systemName: "cross.circle.fill")
                            .foregroundColor(themeManager.colors.success)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                } else {
                    // X on normal bench player = move to Absent (reversible via "Arrived")
                    Button {
                        viewModel.markBenchPlayerAbsent(playerId: player.id)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(themeManager.colors.error)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(player.formattedSecondsPlayed)
                .font(.footnote)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(player.isInjured
            ? themeManager.colors.error.opacity(0.08)
            : themeManager.colors.surface.opacity(0.3))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func absentCard(_ player: PlayerGameStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(player.playerName)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.error)
                .lineLimit(1)
            Button("Arrived") {
                viewModel.markPlayerPresent(playerId: player.id)
            }
            .font(.footnote)
            .buttonStyle(.bordered)
            .tint(themeManager.colors.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.error.opacity(0.08))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func leftEarlyCard(_ player: PlayerGameStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.playerName)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.warning)
                .strikethrough()
                .lineLimit(1)
            Text(player.formattedSecondsPlayed)
                .font(.footnote)
                .foregroundColor(themeManager.colors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.warning.opacity(0.08))
        .cornerRadius(10)
    }
}

struct PlayerStatRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let player: PlayerGameStats
    let isOnField: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isOnField ? themeManager.colors.success : themeManager.colors.textTertiary)
                .frame(width: 8, height: 8)

            Text(player.playerName)
                .font(.body)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(player.formattedSecondsPlayed)
                    .font(.body)
                    .fontWeight(.semibold)

                if isOnField && player.continuousSecondsPlayed > 0 {
                    Text("(\(player.formattedContinuousTime) cont.)")
                        .font(.caption2)
                        .foregroundColor(themeManager.colors.textSecondary)
                }
            }
        }
    }
}
