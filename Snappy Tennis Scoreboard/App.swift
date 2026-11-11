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
    @State private var watchConnection = WatchConnection()
    @AppStorage(SettingsKey.keepsScreenAwake) private var keepsScreenAwake = true

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTesting") {
            Self.resetForUITesting()
        }
        // Simulators used for screenshots have no paired watch to turn Watch Sync on with
        if arguments.contains("-uiTestingWatchSync") {
            var setup = MatchSetup()
            setup.syncsWithWatch = true
            setup.save(to: .standard)
        }
        _scorer = State(initialValue: Scorer())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(scorer: scorer, watchConnection: watchConnection)
                .onChange(of: keepsScreenAwake, initial: true) { _, keepsAwake in
                    // Kept courtside, so by default the screen stays on
                    UIApplication.shared.isIdleTimerDisabled = keepsAwake
                }
        }
    }

    /// UI tests start from the default Match setup and settings, no Match in progress and an empty Match History.
    /// Settings such as `-appearance dark` can still be given as launch arguments.
    private static func resetForUITesting() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        try? FileManager.default.removeItem(at: MatchHistoryStore.standard.fileURL)
    }
}
