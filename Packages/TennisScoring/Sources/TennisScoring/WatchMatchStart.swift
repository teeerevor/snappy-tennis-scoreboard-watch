//
//  WatchMatchStart.swift
//  TennisScoring
//

import Foundation

/// A Match the Companion App hands to the Apple Watch for Watch Sync: the watch starts it and becomes its Scorer.
/// Only the setup travels this way; the score always comes back as Live Scoreboard updates.
public struct WatchMatchStart: Codable, Equatable, Sendable {
    /// Becomes the Match's id on the watch, so its Live Scoreboard updates can be matched to this start.
    public let id: UUID
    public let sentAt: Date
    public let player1: PlayerInfo
    public let player2: PlayerInfo
    public let rules: MatchRules
    /// Who serves first, or nil to not track serve.
    public let server: Player?
    /// Which side of the scoreboard each Player is shown on.
    public let player1OnLeft: Bool

    public init(
        id: UUID = UUID(),
        sentAt: Date = .now,
        player1: PlayerInfo,
        player2: PlayerInfo,
        rules: MatchRules,
        server: Player?,
        player1OnLeft: Bool = true
    ) {
        self.id = id
        self.sentAt = sentAt
        self.player1 = player1
        self.player2 = player2
        self.rules = rules
        self.server = server
        self.player1OnLeft = player1OnLeft
    }

    /// The Match before its first point, shown until the watch sends its first update.
    public var placeholder: LiveMatch {
        LiveMatch(
            id: id,
            player1: player1,
            player2: player2,
            score: MatchScore(rules: rules, isPlayer1Serving: server != .player2, tracksServe: server != nil)
        )
    }

    /// A start the watch only receives on a later day of tennis than it was sent (its app was not
    /// opened in time) would replace whatever the watch has been scoring since, so it is ignored.
    public func isStale(at now: Date = .now, calendar: Calendar = .current) -> Bool {
        !MatchDay.isSameDay(sentAt, as: now, calendar: calendar)
    }

    private static let key = "watchMatchStart"

    /// A property-list dictionary for `WCSession`.
    public var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    /// Nil when the dictionary is not a Watch Sync start.
    public init?(dictionary: [String: Any]) {
        guard let data = dictionary[Self.key] as? Data,
              let start = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = start
    }
}

extension WatchMatchStart {
    private enum CodingKeys: String, CodingKey {
        case id, sentAt, player1, player2, rules, server, player1OnLeft
    }

    /// A start from a Companion App that predates sides still starts, with Player 1 on the left.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        player1 = try container.decode(PlayerInfo.self, forKey: .player1)
        player2 = try container.decode(PlayerInfo.self, forKey: .player2)
        rules = try container.decode(MatchRules.self, forKey: .rules)
        server = try container.decodeIfPresent(Player.self, forKey: .server)
        player1OnLeft = try container.decodeIfPresent(Bool.self, forKey: .player1OnLeft) ?? true
    }
}
