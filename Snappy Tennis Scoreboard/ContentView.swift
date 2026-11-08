//
//  ContentView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Home, and the screens it opens: keeping score on this device, or showing the Apple Watch's Match live.
struct ContentView: View {
    let scorer: Scorer
    let watchConnection: WatchConnection
    @State private var history = MatchHistory()
    @State private var path: [HomeDestination] = []
    @State private var showingWatchMatch = false
    @State private var showingSetup = false
    /// Set by Start on New Match, so the Match opens once the sheet has gone.
    @State private var opensMatchAfterSetup = false
    /// The Match last handed to the watch for Watch Sync.
    @State private var watchStart: WatchMatchStart?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                watchConnection: watchConnection,
                history: history,
                matchInProgress: matchInProgress,
                onNewMatch: { showingSetup = true },
                onContinueMatch: continueMatch
            )
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .match: matchScreen
                case .matchHistory: MatchHistoryView(history: history)
                case .settings: SettingsView(scorer: scorer)
                }
            }
        }
        // A watch Match takes over the screen when it starts, unless this device is busy scoring
        .onChange(of: watchConnection.match?.id) { _, newID in
            showingWatchMatch = newID != nil && !scorer.isScoring
            if showingWatchMatch && path.last != .match {
                path = [.match]
            }
        }
        .sheet(isPresented: $showingSetup, onDismiss: openMatchAfterSetup) {
            MatchSetupView(
                setup: scorer.nextSetup,
                watchAppInstalled: watchConnection.isSupported ? watchConnection.isWatchAppInstalled : nil,
                onStart: start
            )
        }
    }

    @ViewBuilder
    private var matchScreen: some View {
        Group {
            if scorer.setup.startsWithWatchSync {
                WatchSyncView(match: watchSyncMatch, player1OnLeft: scorer.setup.player1OnLeft, onHome: goHome)
            } else if showingWatchMatch, let match = watchConnection.match {
                LiveScoreboardView(match: match, onClose: goHome)
            } else {
                ScorerView(scorer: scorer, watchMatch: watchConnection.match) {
                    showingWatchMatch = true
                } onNewMatch: {
                    showingSetup = true
                } onHome: {
                    goHome()
                }
            }
        }
        .animation(.default, value: showingWatchMatch)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// What Continue Match on Home goes back to, or nil when nothing is in progress.
    private var matchInProgress: String? {
        if scorer.isScoring {
            let setup = scorer.setup
            if setup.isPracticeSession {
                let count = scorer.practice
                return "Practice Session · \(setup.player1.name) \(count.player1)–\(count.player2) \(setup.player2.name)"
            }
            return "\(setup.player1.name) v \(setup.player2.name) · \(scorer.scoreboard.setsSummary)"
        }
        if let match = watchConnection.match, match.winner == nil {
            return "\(match.player1.name) v \(match.player2.name) · live on Apple Watch"
        }
        if scorer.hasStartedWatchSync, watchConnection.match?.winner == nil {
            return "\(scorer.setup.player1.name) v \(scorer.setup.player2.name) · on Apple Watch"
        }
        return nil
    }

    /// 0–0 until the watch sends its first update, including after this app relaunches mid-Match.
    private var watchSyncMatch: LiveMatch {
        watchConnection.match ?? (watchStart ?? scorer.setup.watchMatchStart()).placeholder
    }

    private func continueMatch() {
        // This device's own Match comes first; otherwise it's the watch's
        showingWatchMatch = !scorer.isScoring && !scorer.hasStartedWatchSync && watchConnection.match != nil
        path = [.match]
    }

    private func goHome() {
        showingWatchMatch = false
        path = []
        history.reload()
    }

    private func openMatchAfterSetup() {
        guard opensMatchAfterSetup else { return }
        opensMatchAfterSetup = false
        if path.last != .match { path = [.match] }
    }

    private func start(_ setup: MatchSetup) {
        scorer.start(setup)
        showingWatchMatch = false
        opensMatchAfterSetup = true
        guard setup.startsWithWatchSync else {
            watchStart = nil
            return
        }
        let start = setup.watchMatchStart()
        watchStart = start
        watchConnection.startMatch(start)
    }
}

extension LiveMatch {
    /// "6-3 2-1", from Player 1's side, up to the set being played.
    var setsSummary: String {
        let sets = min(currentSet + 1, rules.setsToPlay)
        return zip(player1SetScore.prefix(sets), player2SetScore.prefix(sets)).map { "\($0)-\($1)" }.joined(separator: " ")
    }
}
