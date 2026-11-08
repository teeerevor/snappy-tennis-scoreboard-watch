//
//  You_cannot_be_seriousApp.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 25/6/2025.
//

import SwiftUI
import TennisScoring

@main
struct snappy_tennis_scoreboard_Watch_AppApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            Self.resetForUITesting()
        }
        CompanionAppLink.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // UI tests start from default settings and an empty Match History,
    // then apply any settings passed as UITEST_DEFAULT_<key> environment variables
    private static func resetForUITesting() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        try? FileManager.default.removeItem(at: MatchHistoryStore.standard.fileURL)

        let prefix = "UITEST_DEFAULT_"
        for (key, value) in ProcessInfo.processInfo.environment where key.hasPrefix(prefix) {
            let settingKey = String(key.dropFirst(prefix.count))
            if let number = Int(value) {
                UserDefaults.standard.set(number, forKey: settingKey)
            } else {
                UserDefaults.standard.set(value, forKey: settingKey)
            }
        }
    }
}
