//
//  ContentView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Keeps score on this device, and shows the Apple Watch's Match live when it is scoring one.
struct ContentView: View {
    let scorer: Scorer
    let watchLiveScoreboard: WatchLiveScoreboard
    @State private var showingWatchMatch = false

    var body: some View {
        Group {
            if showingWatchMatch, let match = watchLiveScoreboard.match {
                LiveScoreboardView(match: match) { showingWatchMatch = false }
            } else {
                ScorerView(scorer: scorer, watchMatch: watchLiveScoreboard.match) {
                    showingWatchMatch = true
                }
            }
        }
        .animation(.default, value: showingWatchMatch)
        // A watch Match takes over the screen when it starts, unless this device is busy scoring
        .onChange(of: watchLiveScoreboard.match?.id) { _, newID in
            showingWatchMatch = newID != nil && !scorer.isScoring
        }
    }
}
