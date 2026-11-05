//
//  MatchRules.swift
//  TennisScoring
//

import Foundation

public enum Player: String, Codable, Sendable {
    case player1
    case player2

    public var opponent: Player {
        self == .player1 ? .player2 : .player1
    }
}

public enum TieBreakRule: String, CaseIterable, Codable, Sendable {
    case at66 = "6-6"
    case at55 = "5-5"
    case none = "None"
}

public enum DeuceType: String, CaseIterable, Codable, Sendable {
    case short = "Short Deuce"
    case long = "Long Deuce"
}

public struct MatchRules: Codable, Equatable, Sendable {
    public var setsToPlay: Int
    public var tieBreakRule: TieBreakRule
    public var deuceType: DeuceType

    public init(setsToPlay: Int = 3, tieBreakRule: TieBreakRule = .at66, deuceType: DeuceType = .short) {
        self.setsToPlay = setsToPlay
        self.tieBreakRule = tieBreakRule
        self.deuceType = deuceType
    }

    public var setsToWin: Int {
        (setsToPlay + 1) / 2  // 1->1, 3->2, 5->3
    }
}
