//
//  MatchSetup.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import TennisScoring

/// How the next Match on this device is set up. Remembered between launches.
struct MatchSetup: Codable, Equatable {
    var player1 = PlayerInfo(name: "Ana", colorName: "blue")
    var player2 = PlayerInfo(name: "Bob", colorName: "green")
    var rules = MatchRules()
    var tracksServe = true
    var firstServer = Player.player1
    var isPracticeSession = false

    func player(_ player: Player) -> PlayerInfo {
        player == .player1 ? player1 : player2
    }

    private static let key = "matchSetup"

    static func load(from defaults: UserDefaults) -> MatchSetup {
        guard let data = defaults.data(forKey: key),
              let setup = try? JSONDecoder().decode(MatchSetup.self, from: data) else { return MatchSetup() }
        return setup
    }

    func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
