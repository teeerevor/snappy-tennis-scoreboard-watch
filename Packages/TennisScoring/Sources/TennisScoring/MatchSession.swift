//
//  MatchSession.swift
//  TennisScoring
//

import Foundation

/// A Match as kept by its Scorer: the score, who is playing, and its place in Match History.
/// Every change is saved straight away, so a Match that is never finished is kept as Unfinished.
public struct MatchSession: Sendable {
    public let id: UUID
    public private(set) var startedAt: Date
    public let player1: PlayerInfo
    public let player2: PlayerInfo
    public private(set) var score: MatchScore

    private let history: MatchHistoryStore

    /// - Parameter server: who serves first, or nil to not track serve.
    public init(
        player1: PlayerInfo,
        player2: PlayerInfo,
        rules: MatchRules,
        server: Player?,
        history: MatchHistoryStore,
        id: UUID = UUID(),
        now: Date = .now
    ) {
        self.id = id
        self.startedAt = now
        self.player1 = player1
        self.player2 = player2
        self.score = MatchScore(rules: rules, isPlayer1Serving: server != .player2, tracksServe: server != nil)
        self.history = history
    }

    /// Picks up a Match kept in Match History where it stopped, for example after the app was closed.
    /// Every point is played again with its recorded server, so undo works as if the Match never stopped.
    public init(resuming record: MatchRecord, history: MatchHistoryStore) {
        self.id = record.id
        self.startedAt = record.startedAt
        self.player1 = record.player1
        self.player2 = record.player2
        let firstServer = record.points.first?.server
        var score = MatchScore(rules: record.rules, isPlayer1Serving: firstServer != .player2, tracksServe: firstServer != nil)
        for point in record.points {
            if let server = point.server { score.setServer(server) }
            score.score(point.winner, at: point.at)
        }
        self.score = score
        self.history = history
    }

    /// Continue Match: the Match in Progress with this id, or nil if it was won, never had a point,
    /// or the day of tennis of its last point has ended (it is then an Unfinished Match).
    public init?(continuing id: UUID, history: MatchHistoryStore, now: Date = .now, calendar: Calendar = .current) {
        guard let record = try? history.load().first(where: { $0.id == id }),
              !record.isFinished,
              let lastPoint = record.points.last,
              MatchDay.isSameDay(lastPoint.at, as: now, calendar: calendar)
        else { return nil }
        self.init(resuming: record, history: history)
    }

    @discardableResult
    public mutating func scorePoint(_ winner: Player, at date: Date = .now) -> ScoreEvent {
        if score.points.isEmpty {
            startedAt = date
        }
        let event = score.score(winner, at: date)
        save(at: date)
        return event
    }

    /// Removes the last point as if it was never played.
    public mutating func undo(at date: Date = .now) {
        score.undo()
        save(at: date)
    }

    /// Continues a finished Match as a longer one. It is still the same Match.
    public mutating func playOn(at date: Date = .now) {
        score.playOn()
        save(at: date)
    }

    /// A Match with no points left is not kept in Match History.
    private func save(at date: Date) {
        do {
            guard !score.points.isEmpty else {
                try history.delete(id: id)
                return
            }
            try history.save(MatchRecord(
                id: id,
                startedAt: startedAt,
                updatedAt: date,
                player1: player1,
                player2: player2,
                score: score
            ))
        } catch {
            print("Failed to save match history: \(error)")
        }
    }
}
