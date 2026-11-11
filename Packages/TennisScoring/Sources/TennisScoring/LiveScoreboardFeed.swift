//
//  LiveScoreboardFeed.swift
//  TennisScoring
//

import Foundation

/// The Match a Live Scoreboard shows, built from the Scorer's updates as they arrive.
public struct LiveScoreboardFeed: Equatable, Sendable {
    private var latestMatch: LiveMatch?
    private var latestSentAt: Date?

    public init() {}

    public mutating func receive(_ message: LiveScoreboardMessage) {
        if let latestSentAt, message.sentAt <= latestSentAt { return }
        latestSentAt = message.sentAt
        latestMatch = message.match
    }

    /// The Match to show at `now`: nil when the Scorer has no Match in Progress, or its last update
    /// was on an earlier day of tennis. WatchConnectivity redelivers the last update on launch, and a
    /// Scorer closed mid-Match never sends one to clear it, but a long rain delay still counts as in progress.
    public func match(at now: Date = .now, calendar: Calendar = .current) -> LiveMatch? {
        guard let latestSentAt, MatchDay.isSameDay(latestSentAt, as: now, calendar: calendar) else { return nil }
        return latestMatch
    }
}
