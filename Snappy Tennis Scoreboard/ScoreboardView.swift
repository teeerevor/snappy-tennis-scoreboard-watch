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
    /// Player 1 on the left in landscape, on top in portrait.
    var player1OnLeft = true
    /// Swaps the game score for larger set scores between games, for a scoreboard nobody taps.
    var showsSetsBetweenGames = false
    var onScore: ((Player) -> Void)?

    var body: some View {
        PlayerPanels {
            row(for: player1OnLeft ? .player1 : .player2)
        } second: {
            row(for: player1OnLeft ? .player2 : .player1)
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
            showsSetsOnly: showsSetsBetweenGames && match.isBetweenGames,
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

/// Two Player panels: stacked when the space is tall (portrait), side by side when it is wide (landscape).
struct PlayerPanels<First: View, Second: View>: View {
    @ViewBuilder let first: First
    @ViewBuilder let second: Second

    var body: some View {
        GeometryReader { geometry in
            let layout = geometry.size.width > geometry.size.height
                ? AnyLayout(HStackLayout(spacing: 12))
                : AnyLayout(VStackLayout(spacing: 12))
            layout {
                first
                second
            }
        }
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
    /// Between games: the set scores take the game score's place, larger.
    var showsSetsOnly = false
    var accessibilityID: String
    var onTap: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let inset = min(geometry.size.width, geometry.size.height) * 0.06
            let width = geometry.size.width - inset * 2
            let height = geometry.size.height - inset * 2
            Group {
                // Squarish panels (portrait) stack the points under the name; wide panels (landscape) put them side by side
                if geometry.size.width / geometry.size.height < 1.8 {
                    stacked(width: width, height: height)
                } else {
                    sideBySide(width: width, height: height)
                }
            }
            .foregroundStyle(.white)
            .padding(inset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color, in: .rect(cornerRadius: 24))
            .contentShape(.rect(cornerRadius: 24))
            .onTapGesture { onTap?() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
    }

    /// Measured: two heavy monospaced characters ("40", "AD") are about 1.2 times as wide as the
    /// font size, and digits are about 0.75 times as tall.
    private static let pointsWidthPerFontSize = 1.22
    private static let digitHeightPerFontSize = 0.75
    /// The blank space before a heavy monospaced digit's ink, as a fraction of the font size.
    private static let digitLeadingSpacePerFontSize = 0.03

    private func stacked(width: CGFloat, height: CGFloat) -> some View {
        // Three lines: name, game score, set scores. The game score and sets are centred, and the
        // name lines up with the score's left edge.
        let pointsSize = min(height * 0.56 / Self.digitHeightPerFontSize, width / Self.pointsWidthPerFontSize)
        return VStack(spacing: 0) {
            // Digits have blank space on their left, so the name is inset to line up with the ink
            nameLabel(size: height * 0.12)
                .padding(.leading, pointsSize * Self.digitLeadingSpacePerFontSize)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: height * 0.15)
            if showsSetsOnly {
                // Wider than the game score's column, which would otherwise shrink the sets to fit
                setsText(size: height * 0.55)
                    .frame(width: min(width, pointsSize * Self.pointsWidthPerFontSize * 1.1))
                    .frame(maxHeight: .infinity)
            } else {
                pointsText(size: pointsSize)
                    .frame(maxHeight: .infinity)
                setsText(size: height * 0.2)
                    .frame(height: height * 0.24)
            }
        }
        .frame(width: pointsSize * Self.pointsWidthPerFontSize)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func sideBySide(width: CGFloat, height: CGFloat) -> some View {
        if showsSetsOnly {
            HStack(spacing: width * 0.04) {
                nameLabel(size: height * 0.3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                setsText(size: height * 0.935)
            }
        } else {
            HStack(spacing: width * 0.04) {
                VStack(alignment: .leading, spacing: 0) {
                    nameLabel(size: height * 0.3)
                    setsText(size: height * 0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                pointsText(size: min(height * 0.85 / Self.digitHeightPerFontSize, width * 0.55 / Self.pointsWidthPerFontSize))
            }
        }
    }

    /// The name, then the serving dot or the winner's trophy after it.
    private func nameLabel(size: CGFloat) -> some View {
        HStack(spacing: size * 0.3) {
            Text(name)
                .font(.system(size: size, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            if isServing {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.45, height: size * 0.45)
                    .accessibilityLabel("Serving")
            }
            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: size * 0.85))
                    .foregroundStyle(.yellow)
            }
        }
    }

    /// One piece of text, so all the sets shrink together when space is short.
    private func setsText(size: CGFloat) -> some View {
        sets.indices.reduce(Text("")) { text, index in
            let set = Text("\(sets[index])").foregroundStyle(.white.opacity(index <= currentSet ? 1 : 0.4))
            return index == 0 ? set : Text("\(text) \(set)")
        }
        .font(.system(size: size, weight: .medium, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.3)
    }

    @ViewBuilder
    private func pointsText(size: CGFloat) -> some View {
        if let points {
            // Sized to the digits, so the taller line box would not fit the layout: draw it over
            // the space it is given instead of letting it push the panel bigger
            Color.clear
                .frame(width: size * Self.pointsWidthPerFontSize)
                .overlay {
                    Text(points)
                        .font(.system(size: size, weight: .heavy, design: .monospaced))
                        .lineLimit(1)
                        .fixedSize()
                }
        }
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
