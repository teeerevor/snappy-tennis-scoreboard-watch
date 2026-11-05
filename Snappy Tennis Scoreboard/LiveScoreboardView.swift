//
//  LiveScoreboardView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// A read-only view of the Match the Apple Watch is scoring. Only the Scorer can change the score.
struct LiveScoreboardView: View {
    let match: LiveMatch
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Live from Apple Watch", systemImage: "applewatch.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Close", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("button.closeLive")
            }

            ScoreboardView(match: match)

            if let winner = match.winner {
                Text("\(match.player(winner).name) wins!")
                    .font(.largeTitle.bold())
            }
        }
        .padding()
    }
}
