//
//  MatchSetup.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import TennisScoring

/// How a Match on this device is set up. The next one's is remembered between launches, and edited in Settings.
struct MatchSetup: Codable, Equatable {
    var player1 = PlayerInfo(name: "Ana", colorName: "blue")
    var player2 = PlayerInfo(name: "Bob", colorName: "green")
    var rules = MatchRules()
    var tracksServe = true
    var firstServer = Player.player1
    /// Which side of the scoreboard each Player is shown on: left in landscape, top in portrait.
    var player1OnLeft = true
    var isPracticeSession = false
    /// Watch Sync: the Apple Watch scores the Match and this device shows it full screen.
    var syncsWithWatch = false

    func player(_ player: Player) -> PlayerInfo {
        player == .player1 ? player1 : player2
    }

    /// A Practice Session is never handed to the watch, as its Live Scoreboard only shows Matches.
    var startsWithWatchSync: Bool { syncsWithWatch && !isPracticeSession }

    /// The Match handed to the Apple Watch when this setup starts with Watch Sync.
    func watchMatchStart(now: Date = .now) -> WatchMatchStart {
        WatchMatchStart(sentAt: now, player1: player1, player2: player2, rules: rules, server: tracksServe ? firstServer : nil, player1OnLeft: player1OnLeft)
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

/// The Match this device last started as Scorer, remembered so it can be continued after the app is closed.
struct CurrentMatch: Codable, Equatable {
    var setup: MatchSetup
    /// The Match's id in Match History.
    var matchID: UUID

    private static let key = "currentMatch"

    static func load(from defaults: UserDefaults) -> CurrentMatch? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CurrentMatch.self, from: data)
    }

    func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.key)
        }
    }
}

extension MatchSetup {
    private enum CodingKeys: String, CodingKey {
        case player1, player2, rules, tracksServe, firstServer, player1OnLeft, isPracticeSession, syncsWithWatch
    }

    /// A setup saved before a setting existed keeps its other settings and gets the new one's default.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = MatchSetup()
        player1 = try container.decodeIfPresent(PlayerInfo.self, forKey: .player1) ?? defaults.player1
        player2 = try container.decodeIfPresent(PlayerInfo.self, forKey: .player2) ?? defaults.player2
        rules = try container.decodeIfPresent(MatchRules.self, forKey: .rules) ?? defaults.rules
        tracksServe = try container.decodeIfPresent(Bool.self, forKey: .tracksServe) ?? defaults.tracksServe
        firstServer = try container.decodeIfPresent(Player.self, forKey: .firstServer) ?? defaults.firstServer
        player1OnLeft = try container.decodeIfPresent(Bool.self, forKey: .player1OnLeft) ?? defaults.player1OnLeft
        isPracticeSession = try container.decodeIfPresent(Bool.self, forKey: .isPracticeSession) ?? defaults.isPracticeSession
        syncsWithWatch = try container.decodeIfPresent(Bool.self, forKey: .syncsWithWatch) ?? defaults.syncsWithWatch
    }
}
