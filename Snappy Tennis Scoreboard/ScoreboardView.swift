//
//  ScoreboardView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// A Match as two Player rows: name, sets and the points in the current game.
/// Tapping a row scores a point for that Player when `onScore` is given; otherwise it is read-only.
struct ScoreboardView: View {
    let match: LiveMatch
    var onScore: ((Player) -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            row(for: .player1)
            row(for: .player2)
        }
    }

    private func row(for player: Player) -> some View {
        let info = match.player(player)
        return ScoreRow(
            name: info.name,
            color: PlayerColor.color(named: info.colorName),
            isServing: match.server == player && match.winner == nil,
            isWinner: match.winner == player,
            sets: Array(match.sets(for: player).prefix(match.rules.setsToPlay)),
            currentSet: match.currentSet,
            points: match.winner == nil ? match.points(for: player) : nil,
            accessibilityID: player == .player1 ? "score.player1" : "score.player2",
            onTap: onScore.map { onScore in { onScore(player) } }
        )
    }
}

extension LiveMatch {
    func player(_ player: Player) -> PlayerInfo {
        player == .player1 ? player1 : player2
    }

    func points(for player: Player) -> String {
        player == .player1 ? player1Points : player2Points
    }

    func sets(for player: Player) -> [Int] {
        player == .player1 ? player1SetScore : player2SetScore
    }
}

/// One Player's row on a scoreboard, sized to fill the space it is given.
struct ScoreRow: View {
    let name: String
    let color: Color
    var isServing = false
    var isWinner = false
    var sets: [Int] = []
    var currentSet = 0
    /// Nil once the Match is over.
    var points: String?
    var accessibilityID: String
    var onTap: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.height, geometry.size.width / 3)
            HStack(spacing: size * 0.12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isServing ? color : .clear)
                            .frame(width: size * 0.08, height: size * 0.08)
                            .accessibilityLabel(isServing ? "Serving" : "")
                        Text(name)
                            .font(.system(size: size * 0.16, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if isWinner {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: size * 0.14))
                                .foregroundStyle(.yellow)
                        }
                    }
                    HStack(spacing: size * 0.08) {
                        ForEach(sets.indices, id: \.self) { index in
                            Text("\(sets[index])")
                                .font(.system(size: size * 0.2, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .opacity(index <= currentSet ? 1 : 0.35)
                        }
                    }
                }
                Spacer(minLength: 0)
                if let points {
                    Text(points)
                        .font(.system(size: size * 0.55, weight: .heavy, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, size * 0.12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.15), in: .rect(cornerRadius: 24))
            .contentShape(.rect(cornerRadius: 24))
            .onTapGesture { onTap?() }
            .animation(.snappy, value: points)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
    }
}

#Preview {
    var score = MatchScore(rules: MatchRules())
    for _ in 0..<5 { score.score(.player1) }
    return ScoreboardView(
        match: LiveMatch(
            id: UUID(),
            player1: PlayerInfo(name: "Ana", colorName: "blue"),
            player2: PlayerInfo(name: "Bob", colorName: "green"),
            score: score
        ),
        onScore: { _ in }
    )
    .padding()
    .preferredColorScheme(.dark)
}
