//
//  MatchRecord.swift
//  TennisScoring
//

import Foundation

/// A side in a Match: just a name and a colour, never a saved profile.
public struct PlayerInfo: Codable, Equatable, Sendable {
    public var name: String
    public var colorName: String

    public init(name: String, colorName: String) {
        self.name = name
        self.colorName = colorName
    }
}

/// A Match as kept in Match History: every point that stands, and how it ended.
public struct MatchRecord: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public var updatedAt: Date
    public var player1: PlayerInfo
    public var player2: PlayerInfo
    public var rules: MatchRules
    public var points: [Point]
    public var player1SetScore: [Int]
    public var player2SetScore: [Int]
    /// Nil for an Unfinished Match.
    public var winner: Player?

    public init(
        id: UUID,
        startedAt: Date,
        updatedAt: Date,
        player1: PlayerInfo,
        player2: PlayerInfo,
        score: MatchScore
    ) {
        self.id = id
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.player1 = player1
        self.player2 = player2
        self.rules = score.rules
        self.points = score.points
        self.player1SetScore = score.player1SetScore
        self.player2SetScore = score.player2SetScore
        self.winner = score.winner
    }

    public var isFinished: Bool {
        winner != nil
    }
}
