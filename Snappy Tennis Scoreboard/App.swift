//
//  App.swift
//  Snappy Tennis Scoreboard
//
//  Created by boris on 28/5/2026.
//

import SwiftUI
import TennisScoring

@main
struct SnappyTennisApp: App {
    @State private var scorer: Scorer
    /// Activates WatchConnectivity as the app launches.
    @State private var watchLiveScoreboard = WatchLiveScoreboard()

    init() {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            Self.resetForUITesting()
        }
        _scorer = State(initialValue: Scorer())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(scorer: scorer, watchLiveScoreboard: watchLiveScoreboard)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Kept courtside, so the screen stays on
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }

    /// UI tests start from the default Match setup and an empty Match History.
    private static func resetForUITesting() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        try? FileManager.default.removeItem(at: MatchHistoryStore.standard.fileURL)
    }
}
