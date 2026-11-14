//
//  ScorecardView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// A Scorecard: a Match's result as a card to share, finished or Unfinished,
/// lit up like an old courtside dot-matrix scoreboard under a Snappy lime header.
struct ScorecardView: View {
    let record: MatchRecord
    /// The small card on Home leaves out the date and whether the Match was finished.
    var isCompact = false

    /// The distance between dots on the board.
    private var pitch: CGFloat { isCompact ? 1.8 : 2.6 }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.snappyLime
                SnappyLogo(size: isCompact ? 9.4 : 15)
            }
            .frame(height: isCompact ? 15.8 : 28)
            board
        }
        .clipShape(.rect(cornerRadius: isCompact ? 17.3 : 22))
        // The same card whatever the appearance, so a shared image looks the same everywhere
        .environment(\.colorScheme, .light)
    }

    private var board: some View {
        VStack(spacing: isCompact ? 7.2 : 14) {
            row(.player1)
            DotMatrixText(text: "VS", pitch: pitch * 0.6, gap: 1, color: .white.opacity(0.6))
            row(.player2)
            if !isCompact {
                HStack {
                    DotMatrixText(text: record.startedAt.formatted(.dateTime.day().month(.abbreviated).year()),
                                  pitch: pitch * 0.45, gap: 1, color: .white.opacity(0.45))
                    Spacer()
                    DotMatrixText(text: record.isFinished ? "FINAL" : "UNFINISHED",
                                  pitch: pitch * 0.45, gap: 1, color: .white.opacity(0.45))
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, isCompact ? 14.4 : 30)
        .padding(.top, isCompact ? 14.4 : 30)
        .padding(.bottom, isCompact ? 14.4 : 18)
        .frame(maxWidth: .infinity)
        .background {
            Color(light: 0x30322F, dark: 0x30322F)
            DotGrid(pitch: pitch, dotSize: pitch * 0.42).fill(.white.opacity(0.07))
        }
    }

    private func row(_ player: Player) -> some View {
        let isWinner = record.winner == player
        return HStack(spacing: isCompact ? 11.5 : 20) {
            FittingDotMatrixText(text: record.player(player).name, pitch: pitch)
            HStack(spacing: isCompact ? 7.2 : 16) {
                ForEach(Array(record.setScores(for: player).enumerated()), id: \.offset) { set, games in
                    DotMatrixText(text: "\(games)", pitch: pitch, gap: 1)
                        // Both rows' columns line up even when one Player has a two-digit set
                        .frame(width: setWidth(set))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.player(player).name)\(isWinner ? ", winner" : ""), \(record.setScores(for: player).map(String.init).joined(separator: ", "))")
    }

    private func setWidth(_ set: Int) -> CGFloat {
        let digits = [Player.player1, .player2]
            .compactMap { record.setScores(for: $0).dropFirst(set).first.map { String($0).count } }
            .max() ?? 1
        return CGFloat(digits * 6 - 1) * pitch
    }
}

/// The Snappy Sports wordmark, in translucent black on the lime header, like the primary buttons.
private struct SnappyLogo: View {
    let size: CGFloat

    var body: some View {
        Text("Snappy")
            .font(.snappyHeading(size))
            .foregroundStyle(.black)
            .overlay(alignment: .bottom) {
                Text("SPORTS")
                    .font(.system(size: size * 0.24, weight: .heavy))
                    .tracking(size * 0.04)
                    .foregroundStyle(.black)
                    .offset(x: -size * 0.3, y: size * 0.1)
            }
            // The condensed system font has no italic, and the wordmark leans forward
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.22, d: 1, tx: size * 0.15, ty: 0))
            // Faded as one, so SPORTS isn't darker where it overlaps Snappy
            .compositingGroup()
            .opacity(0.8)
            .accessibilityLabel("Snappy Sports")
    }
}

extension MatchRecord {
    /// The Scorecard as an image for the share sheet.
    @MainActor
    var scorecardImage: Image {
        let renderer = ImageRenderer(content: ScorecardView(record: self).frame(width: 420).padding(24))
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "sportscourt")
    }

    var scorecardTitle: String {
        "\(player1.name) v \(player2.name)"
    }
}

/// Opens the share sheet with a Match's Scorecard.
struct ShareScorecardLink<Label: View>: View {
    let record: MatchRecord
    @ViewBuilder let label: Label

    var body: some View {
        let image = record.scorecardImage
        ShareLink(
            item: image,
            message: Text("\(record.scorecardTitle): \(record.setsSummary)"),
            preview: SharePreview(record.scorecardTitle, image: image)
        ) {
            label
        }
    }
}

#Preview {
    // Roger wins 6-3 4-6 6-2
    var score = MatchScore(rules: MatchRules())
    for (roger, boris) in [(6, 3), (4, 6), (6, 2)] {
        for game in 0..<(roger + boris) {
            let winner: Player = game < min(roger, boris) * 2 ? (game.isMultiple(of: 2) ? .player1 : .player2)
                : (roger > boris ? .player1 : .player2)
            for _ in 0..<4 { score.score(winner) }
        }
    }
    return ScorecardView(record: MatchRecord(
        id: UUID(), startedAt: .now, updatedAt: .now,
        player1: PlayerInfo(name: "Roger", colorName: "blue"),
        player2: PlayerInfo(name: "Boris", colorName: "green"),
        score: score
    ))
    .padding()
}
