//
//  LiveScoreboardMessage.swift
//  TennisScoring
//

import Foundation

/// What a Live Scoreboard shows of the Scorer's Match: the score as it stands,
/// without the point-by-point history, so it stays small enough to send every point.
public struct LiveMatch: Codable, Equatable, Sendable {
    public let id: UUID
    public let player1: PlayerInfo
    public let player2: PlayerInfo
    public let rules: MatchRules
    public let player1Points: String
    public let player2Points: String
    public let player1SetScore: [Int]
    public let player2SetScore: [Int]
    public let currentSet: Int
    /// Nil when the Scorer is not tracking serve.
    public let server: Player?
    /// Nil until the Match is won.
    public let winner: Player?

    public init(id: UUID, player1: PlayerInfo, player2: PlayerInfo, score: MatchScore) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.rules = score.rules
        self.player1Points = score.player1Points
        self.player2Points = score.player2Points
        self.player1SetScore = score.player1SetScore
        self.player2SetScore = score.player2SetScore
        self.currentSet = score.currentSet
        self.server = score.tracksServe ? score.server : nil
        self.winner = score.winner
    }

    /// No point played yet in the current game: the start of a Match, game, set or tiebreak.
    public var isBetweenGames: Bool {
        let love = MatchScore.pointValues[0]
        return winner == nil && player1Points == love && player2Points == love
    }
}

/// One update from the Scorer to a Live Scoreboard, sent as a WatchConnectivity dictionary.
public struct LiveScoreboardMessage: Codable, Equatable, Sendable {
    /// When the Scorer sent it, so late arrivals can be ignored.
    public let sentAt: Date
    /// Nil when the Scorer has no Match in progress.
    public let match: LiveMatch?

    public init(sentAt: Date, match: LiveMatch?) {
        self.sentAt = sentAt
        self.match = match
    }

    private static let key = "liveScoreboard"

    /// A property-list dictionary for `WCSession`.
    public var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    /// Nil when the dictionary is not a Live Scoreboard update.
    public init?(dictionary: [String: Any]) {
        guard let data = dictionary[Self.key] as? Data,
              let message = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = message
    }
}
