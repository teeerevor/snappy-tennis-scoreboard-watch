//
//  ScorecardView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// A Scorecard: a Match's result as a card to share, finished or Unfinished.
struct ScorecardView: View {
    let record: MatchRecord
    /// The small card on Home leaves out the date and app name.
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 10) {
            HStack {
                Text(record.isFinished ? "FINAL" : "UNFINISHED")
                    .font(.system(size: isCompact ? 10 : 15, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.black.opacity(0.55))
                Spacer()
                if !isCompact {
                    Text(record.startedAt, format: .dateTime.day().month().year())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.black.opacity(0.45))
                }
            }
            row(.player1)
            row(.player2)
            Capsule()
                .fill(Color(light: 0xE4EB7A, dark: 0xE4EB7A))
                .frame(height: isCompact ? 6 : 10)
                .padding(.top, isCompact ? 2 : 6)
            if !isCompact {
                Text("Snappy Tennis Scoreboard")
                    .font(.snappyHeading(16))
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .padding(isCompact ? 12 : 24)
        .background(.white, in: .rect(cornerRadius: isCompact ? 14 : 24))
        // Always a white card, whatever the appearance, so a shared image looks the same everywhere
        .environment(\.colorScheme, .light)
    }

    private func row(_ player: Player) -> some View {
        let isWinner = record.winner == player
        let isLoser = record.winner == player.opponent
        return HStack(alignment: .firstTextBaseline) {
            Text(record.player(player).name)
                .font(.snappyHeading(isCompact ? 17 : 32))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 8)
            HStack(spacing: isCompact ? 4 : 10) {
                ForEach(Array(record.setScores(for: player).enumerated()), id: \.offset) { _, games in
                    Text("\(games)")
                }
            }
            .font(.system(size: isCompact ? 17 : 32, weight: .heavy, design: .rounded))
            .monospacedDigit()
        }
        .foregroundStyle(.black.opacity(isLoser ? 0.5 : 0.88))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.player(player).name)\(isWinner ? ", winner" : ""), \(record.setScores(for: player).map(String.init).joined(separator: ", "))")
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
    var score = MatchScore(rules: MatchRules())
    for _ in 0..<24 { score.score(.player1) }
    for _ in 0..<10 { score.score(.player2) }
    return ScorecardView(record: MatchRecord(
        id: UUID(), startedAt: .now, updatedAt: .now,
        player1: PlayerInfo(name: "Ana", colorName: "blue"),
        player2: PlayerInfo(name: "Bob", colorName: "green"),
        score: score
    ))
    .padding()
}
