//
//  ScorerView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// This device keeping score: tap a Player's row to give them the point.
struct ScorerView: View {
    let scorer: Scorer
    let watchMatch: LiveMatch?
    let onShowWatchMatch: () -> Void
    let onNewMatch: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let watchMatch {
                Button(action: onShowWatchMatch) {
                    Label("\(watchMatch.player1.name) v \(watchMatch.player2.name) live on Apple Watch", systemImage: "applewatch.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("button.watchLive")
            }

            board

            HStack {
                Button("Undo", systemImage: "arrow.uturn.backward", action: scorer.undo)
                    .disabled(!scorer.canUndo)
                    .accessibilityIdentifier("button.undo")
                Spacer()
                Button("Home", systemImage: "house", action: onHome)
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("button.home")
                Spacer()
                Button(scorer.setup.isPracticeSession ? "New Session" : "New Match", systemImage: "plus", action: onNewMatch)
                .accessibilityIdentifier("button.scorerNewMatch")
            }
            .font(.title3)
            .buttonStyle(.bordered)
            .tint(.primary)
        }
        .padding()
        .overlay { celebrationBanner }
    }

    @ViewBuilder
    private var board: some View {
        if scorer.setup.isPracticeSession {
            practiceBoard
        } else {
            matchBoard
        }
    }

    private var matchBoard: some View {
        let match = scorer.scoreboard
        let onScore: ((Player) -> Void)? = match.winner == nil ? { scorer.scorePoint($0) } : nil
        return ScoreboardView(match: match, player1OnLeft: scorer.setup.player1OnLeft, onScore: onScore)
            .overlay {
                if let winner = match.winner {
                    matchResult(winner: match.player(winner).name)
                }
            }
    }

    private var practiceBoard: some View {
        let left: Player = scorer.setup.player1OnLeft ? .player1 : .player2
        return PlayerPanels {
            practiceRow(left, count: scorer.practice.count(for: left))
        } second: {
            practiceRow(left.opponent, count: scorer.practice.count(for: left.opponent))
        }
    }

    private func practiceRow(_ player: Player, count: Int) -> some View {
        let info = scorer.setup.player(player)
        return ScoreRow(
            name: info.name,
            color: PlayerColor.color(named: info.colorName),
            points: String(format: "%02d", count),
            accessibilityID: player == .player1 ? "practice.player1" : "practice.player2",
            onTap: { scorer.scorePoint(player) }
        )
    }

    private func matchResult(winner: String) -> some View {
        VStack(spacing: 16) {
            Text("\(winner) wins!")
                .font(.largeTitle.bold())
            HStack {
                if scorer.canPlayOn {
                    Button("Play On", action: scorer.playOn)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("button.playOn")
                }
                Button("New Match", action: onNewMatch)
                    .buttonStyle(.bordered)
                Button("Home", action: onHome)
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private var celebrationBanner: some View {
        if let celebration = scorer.celebration, celebration.event != .match {
            let name = scorer.setup.player(celebration.winner).name
            Text(celebration.event == .set ? "Set \(name)" : "Game \(name)")
                .font(.system(size: 48, weight: .heavy))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.regularMaterial, in: .capsule)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
                .task(id: celebration.id) {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { scorer.endCelebration(celebration) }
                }
        }
    }
}
