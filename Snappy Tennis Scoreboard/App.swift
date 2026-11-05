//
//  App.swift
//  Snappy Tennis Scoreboard
//
//  Created by boris on 28/5/2026.
//

import SwiftUI

@main
struct SnappyTennisApp: App {
    @State private var scorer = Scorer()
    /// Activates WatchConnectivity as the app launches.
    @State private var watchLiveScoreboard = WatchLiveScoreboard()

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
}
