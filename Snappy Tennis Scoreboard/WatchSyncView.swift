//
//  WatchSyncView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Watch Sync: the Live Scoreboard of the Match the Apple Watch is scoring, full screen. Only the watch can change the score.
struct WatchSyncView: View {
    let match: LiveMatch
    var player1OnLeft = true
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ScoreboardView(match: match, player1OnLeft: player1OnLeft, showsSetsBetweenGames: true)
                .overlay {
                    if let winner = match.winner {
                        Text("\(match.player(winner).name) wins!")
                            .font(.largeTitle.bold())
                            .padding(24)
                            .background(.regularMaterial, in: .rect(cornerRadius: 24))
                    }
                }

            Button("Home", systemImage: "house", action: onHome)
                .labelStyle(.iconOnly)
                .font(.title2)
                .buttonStyle(.bordered)
                .tint(.primary)
                .accessibilityIdentifier("button.home")
        }
        .padding()
        // Nothing but the score, for players glancing over from the court
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
