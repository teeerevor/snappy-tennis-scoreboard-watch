//
//  MatchHistory.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import Observation
import TennisScoring

/// Match History on this device, newest Match first, for Home and the Match History screen.
@Observable
final class MatchHistory {
    private(set) var records: [MatchRecord] = []
    private let store: MatchHistoryStore

    init(store: MatchHistoryStore = .standard) {
        self.store = store
        reload()
    }

    /// The Scorer saves every point straight to the store, so this catches up with it.
    func reload() {
        do {
            records = try store.load().sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Failed to load match history: \(error)")
            records = []
        }
    }

    func delete(_ record: MatchRecord) {
        do {
            try store.delete(id: record.id)
        } catch {
            print("Failed to delete match: \(error)")
        }
        reload()
    }
}

extension MatchRecord {
    /// Sets that have started, at least the first.
    var playedSetCount: Int {
        let lastStarted = player1SetScore.indices.last { player1SetScore[$0] + (player2SetScore.indices.contains($0) ? player2SetScore[$0] : 0) > 0 } ?? 0
        return min(lastStarted + 1, rules.setsToPlay)
    }

    func setScores(for player: Player) -> [Int] {
        Array((player == .player1 ? player1SetScore : player2SetScore).prefix(playedSetCount))
    }

    func player(_ player: Player) -> PlayerInfo {
        player == .player1 ? player1 : player2
    }

    /// "6-3 4-6 7-5", from Player 1's side.
    var setsSummary: String {
        zip(setScores(for: .player1), setScores(for: .player2)).map { "\($0)-\($1)" }.joined(separator: " ")
    }
}
