//
//  MatchScore.swift
//  TennisScoring
//

import Foundation

/// What a scored point completed, so the Scorer can celebrate it.
public enum ScoreEvent: Sendable {
    case point
    case game
    case set
    case match
}

/// One point of a Match, as it stands after any undos.
public struct Point: Codable, Equatable, Sendable {
    public let winner: Player
    /// Who served the point, or nil when serve tracking was off.
    public let server: Player?
    public let at: Date

    public init(winner: Player, server: Player?, at: Date) {
        self.winner = winner
        self.server = server
        self.at = at
    }
}

/// The live score of a Match and the rules for moving it on.
public struct MatchScore: Codable, Equatable, Sendable {
    public static let pointValues = ["00", "15", "30", "40"]

    /// Rules can change mid-match; scoring always uses the current ones.
    public var rules: MatchRules
    /// When false, points are recorded without a server.
    public var tracksServe: Bool

    public private(set) var player1Points = "00"
    public private(set) var player2Points = "00"
    public private(set) var player1SetScore = [0, 0, 0, 0, 0]
    public private(set) var player2SetScore = [0, 0, 0, 0, 0]
    public private(set) var currentSet = 0
    public private(set) var isPlayer1Serving: Bool
    public private(set) var tieBreakServeCount = 0
    public private(set) var winner: Player?
    public private(set) var points: [Point] = []

    private var history: [Snapshot] = []

    private struct Snapshot: Codable, Equatable, Sendable {
        let player1Points: String
        let player2Points: String
        let player1SetScore: [Int]
        let player2SetScore: [Int]
        let currentSet: Int
        let isPlayer1Serving: Bool
        let tieBreakServeCount: Int
        let winner: Player?
    }

    public init(rules: MatchRules, isPlayer1Serving: Bool = true, tracksServe: Bool = true) {
        self.rules = rules
        self.isPlayer1Serving = isPlayer1Serving
        self.tracksServe = tracksServe
    }

    public var server: Player {
        isPlayer1Serving ? .player1 : .player2
    }

    public var canUndo: Bool {
        !history.isEmpty
    }

    public mutating func setServer(_ player: Player) {
        isPlayer1Serving = player == .player1
    }

    // MARK: - Rules

    public func hasWonTieBreak(_ personScore: Int, _ opponentScore: Int) -> Bool {
        personScore >= 7 && personScore - opponentScore >= 2
    }

    public func hasWonGame(_ personScore: String, _ opponentScore: String) -> Bool {
        if rules.deuceType == .short {
            return personScore == "40"
        } else {
            // Long deuce: need to win by 2 when both at 40
            if personScore == "40" && opponentScore != "40" {
                return true
            }
            // Win from advantage
            return personScore == "AD"
        }
    }

    public func hasWonSet(_ personSetScore: Int, _ opponentSetScore: Int) -> Bool {
        switch rules.tieBreakRule {
        case .at66:
            // Win at 6 games if opponent has less than 6, or 7-6 after tie break
            return (personSetScore >= 6 && opponentSetScore <= 4) ||
                   (personSetScore == 7 && opponentSetScore == 5) ||
                   (personSetScore == 7 && opponentSetScore == 6)
        case .at55:
            // Win at 6 games if opponent has less than 5, or 6-5 after tie break
            return (personSetScore >= 6 && opponentSetScore <= 3) ||
                   (personSetScore == 6 && opponentSetScore == 4) ||
                   (personSetScore == 6 && opponentSetScore == 5)
        case .none:
            // Traditional tennis: must win by 2 and have at least 6
            return personSetScore >= 6 && personSetScore - opponentSetScore >= 2
        }
    }

    public func hasWonMatch(_ playerSetScore: [Int], _ opponentSetScore: [Int]) -> Bool {
        var setsWon = 0
        for i in 0..<playerSetScore.count where hasWonSet(playerSetScore[i], opponentSetScore[i]) {
            setsWon += 1
        }
        return setsWon >= rules.setsToWin
    }

    public var isTieBreak: Bool {
        switch rules.tieBreakRule {
        case .at66:
            return player1SetScore[currentSet] == 6 && player2SetScore[currentSet] == 6
        case .at55:
            return player1SetScore[currentSet] == 5 && player2SetScore[currentSet] == 5
        case .none:
            return false
        }
    }

    // MARK: - Scoring

    @discardableResult
    public mutating func score(_ pointWinner: Player, at date: Date = .now) -> ScoreEvent {
        history.append(snapshot)
        points.append(Point(winner: pointWinner, server: tracksServe ? server : nil, at: date))

        let isPlayer1 = pointWinner == .player1
        var playerPoints = isPlayer1 ? player1Points : player2Points
        var playerSetScore = isPlayer1 ? player1SetScore : player2SetScore
        let opponentPoints = isPlayer1 ? player2Points : player1Points
        let opponentSetScore = isPlayer1 ? player2SetScore : player1SetScore
        var event = ScoreEvent.point

        if isTieBreak {
            var playerTieBreakPoints = Int(playerPoints) ?? 0
            let opponentTieBreakPoints = Int(opponentPoints) ?? 0
            playerTieBreakPoints += 1
            playerPoints = playerTieBreakPoints >= 10 ? "\(playerTieBreakPoints)" : "0\(playerTieBreakPoints)"

            // First server serves 1 point, then alternates every 2 points
            tieBreakServeCount += 1
            if (tieBreakServeCount == 1) || (tieBreakServeCount > 1 && (tieBreakServeCount - 1) % 2 == 0) {
                isPlayer1Serving.toggle()
            }

            if hasWonTieBreak(playerTieBreakPoints, opponentTieBreakPoints) {
                switch rules.tieBreakRule {
                case .at66:
                    playerSetScore[currentSet] = 7  // Winner gets 7 in 7-6 score
                case .at55:
                    playerSetScore[currentSet] = 6  // Winner gets 6 in 6-5 score
                case .none:
                    playerSetScore[currentSet] += 1
                }
                event = .set

                // Whoever received first in the tiebreak serves first after it.
                // Serve has switched after point 1, 3, 5…, so undo those switches to find the first server.
                let switchesDuringTieBreak = (tieBreakServeCount + 1) / 2
                let isPlayer1FirstTieBreakServer = isPlayer1Serving != (switchesDuringTieBreak % 2 == 1)
                isPlayer1Serving = !isPlayer1FirstTieBreakServer
                tieBreakServeCount = 0

                if hasWonMatch(playerSetScore, opponentSetScore) {
                    event = .match
                } else {
                    currentSet += 1
                }
            }
        } else if hasWonGame(playerPoints, opponentPoints) {
            playerSetScore[currentSet] += 1
            event = .game
            // Switch serve at end of game
            isPlayer1Serving.toggle()

            if hasWonSet(playerSetScore[currentSet], opponentSetScore[currentSet]) {
                event = .set

                if hasWonMatch(playerSetScore, opponentSetScore) {
                    event = .match
                } else {
                    currentSet += 1
                    // Switch serve for new set (undo the game switch since set changes serving order)
                    isPlayer1Serving.toggle()
                }
            }
        } else if rules.deuceType == .long && playerPoints == "40" && opponentPoints == "40" {
            // From 40-40 to advantage
            playerPoints = "AD"
        } else if rules.deuceType == .long && playerPoints == "-" && opponentPoints == "AD" {
            // From disadvantage back to deuce
            playerPoints = "40"
        } else {
            playerPoints = Self.cycleScore(playerPoints)
        }

        // Opponent drops to disadvantage, or back to deuce, under long deuce
        var finalOpponentPoints = opponentPoints
        if rules.deuceType == .long && event == .point {
            if playerPoints == "AD" && opponentPoints == "40" {
                finalOpponentPoints = "-"
            } else if playerPoints == "40" && opponentPoints == "AD" {
                finalOpponentPoints = "40"
            }
        }

        if event != .point {
            // A new game starts at love-all
            playerPoints = "00"
            finalOpponentPoints = "00"
        }

        if isPlayer1 {
            player1Points = playerPoints
            player1SetScore = playerSetScore
            player2Points = finalOpponentPoints
        } else {
            player2Points = playerPoints
            player2SetScore = playerSetScore
            player1Points = finalOpponentPoints
        }

        if event == .match {
            winner = pointWinner
        }
        return event
    }

    /// Removes the last point as if it was never played.
    public mutating func undo() {
        guard let previous = history.popLast() else { return }
        points.removeLast()
        player1Points = previous.player1Points
        player2Points = previous.player2Points
        player1SetScore = previous.player1SetScore
        player2SetScore = previous.player2SetScore
        currentSet = previous.currentSet
        isPlayer1Serving = previous.isPlayer1Serving
        tieBreakServeCount = previous.tieBreakServeCount
        winner = previous.winner
    }

    /// Continues a finished Match as a longer one: 1 set becomes 3, and 3 sets become 5 after the 3rd set.
    public mutating func playOn() {
        player1Points = "00"
        player2Points = "00"

        let currentSetNumber = currentSet + 1  // 1-based set number
        if rules.setsToPlay == 1 {
            rules.setsToPlay = 3
        } else if rules.setsToPlay == 3 && currentSetNumber == 3 {
            rules.setsToPlay = 5
        }
        currentSet += 1
        winner = nil
    }

    private var snapshot: Snapshot {
        Snapshot(
            player1Points: player1Points,
            player2Points: player2Points,
            player1SetScore: player1SetScore,
            player2SetScore: player2SetScore,
            currentSet: currentSet,
            isPlayer1Serving: isPlayer1Serving,
            tieBreakServeCount: tieBreakServeCount,
            winner: winner
        )
    }

    private static func cycleScore(_ currentScore: String) -> String {
        if let currentIndex = pointValues.firstIndex(of: currentScore) {
            return pointValues[(currentIndex + 1) % pointValues.count]
        }
        return "00"
    }
}
