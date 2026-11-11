//
//  Scorer.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import Observation
import TennisScoring

/// This device as the Scorer: the Match or Practice Session being kept here.
@Observable
final class Scorer {
    /// A game, set or Match just won, shown briefly over the scoreboard.
    struct Celebration: Equatable {
        let id = UUID()
        let event: ScoreEvent
        let winner: Player
    }

    private(set) var setup: MatchSetup
    private(set) var session: MatchSession
    private(set) var practice = PracticeScore()
    private(set) var celebration: Celebration?

    private let history: MatchHistoryStore
    private let defaults: UserDefaults
    private let now: () -> Date

    /// Picks up the Match in Progress this device was scoring when the app was closed.
    init(history: MatchHistoryStore = .standard, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }) {
        self.history = history
        self.defaults = defaults
        self.now = now
        guard let current = CurrentMatch.load(from: defaults) else {
            let setup = MatchSetup.load(from: defaults)
            self.setup = setup
            self.session = Self.newSession(setup, history: history)
            return
        }
        self.setup = current.setup
        let record = try? history.load().first { $0.id == current.matchID }
        // Left until the day of tennis ended, it is an Unfinished Match rather than one to continue
        if let record, !record.isFinished, let lastPoint = record.points.last, !current.setup.isPracticeSession,
           MatchDay.isSameDay(lastPoint.at, as: now()) {
            self.session = MatchSession(resuming: record, history: history)
        } else {
            self.session = Self.newSession(current.setup, history: history)
        }
    }

    /// How the next New Match starts: the last one started, as changed in Settings since.
    var nextSetup: MatchSetup {
        MatchSetup.load(from: defaults)
    }

    func saveNextSetup(_ setup: MatchSetup) {
        setup.save(to: defaults)
    }

    /// Watch Sync started since launch; after a relaunch only a live watch Match counts as in progress.
    private(set) var hasStartedWatchSync = false

    /// The Match as the scoreboard shows it.
    var scoreboard: LiveMatch {
        LiveMatch(id: session.id, player1: session.player1, player2: session.player2, score: session.score)
    }

    /// A Match in Progress or a Practice Session under way, so a watch Match should not take over the screen
    /// and starting another needs confirming.
    var isScoring: Bool {
        if setup.isPracticeSession { return practice.canUndo }
        guard let lastPoint = session.score.points.last, session.score.winner == nil else { return false }
        return MatchDay.isSameDay(lastPoint.at, as: now())
    }

    var canUndo: Bool {
        setup.isPracticeSession ? practice.canUndo : session.score.canUndo
    }

    /// Same as the Watch App: a 5-set Match can't go any longer.
    var canPlayOn: Bool {
        session.score.winner != nil && session.score.rules.setsToPlay != 5
    }

    func scorePoint(_ player: Player) {
        if setup.isPracticeSession {
            practice.score(player)
            return
        }
        guard session.score.winner == nil else { return }
        let event = session.scorePoint(player)
        if event != .point {
            celebration = Celebration(event: event, winner: player)
        }
    }

    func undo() {
        if setup.isPracticeSession {
            practice.undo()
        } else {
            session.undo()
        }
    }

    func playOn() {
        session.playOn()
    }

    func endCelebration(_ ended: Celebration) {
        if celebration == ended { celebration = nil }
    }

    /// The Match being replaced stays in Match History as it stands.
    func start(_ setup: MatchSetup) {
        self.setup = setup
        setup.save(to: defaults)
        session = Self.newSession(setup, history: history)
        CurrentMatch(setup: setup, matchID: session.id).save(to: defaults)
        practice = PracticeScore()
        celebration = nil
        hasStartedWatchSync = setup.startsWithWatchSync
    }

    private static func newSession(_ setup: MatchSetup, history: MatchHistoryStore) -> MatchSession {
        MatchSession(
            player1: setup.player1,
            player2: setup.player2,
            rules: setup.rules,
            server: setup.tracksServe ? setup.firstServer : nil,
            history: history
        )
    }
}

/// Casual scoring for a Practice Session: a count per Player, never kept in Match History.
struct PracticeScore {
    private(set) var player1 = 0
    private(set) var player2 = 0
    private var previous: [(player1: Int, player2: Int)] = []

    var canUndo: Bool { !previous.isEmpty }

    func count(for player: Player) -> Int {
        player == .player1 ? player1 : player2
    }

    mutating func score(_ player: Player) {
        previous.append((player1, player2))
        switch player {
        case .player1: player1 = player1 >= 99 ? 0 : player1 + 1
        case .player2: player2 = player2 >= 99 ? 0 : player2 + 1
        }
    }

    mutating func undo() {
        guard let last = previous.popLast() else { return }
        (player1, player2) = last
    }
}
