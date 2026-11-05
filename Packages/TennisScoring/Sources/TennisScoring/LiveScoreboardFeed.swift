//
//  LiveScoreboardFeed.swift
//  TennisScoring
//

import Foundation

/// The Match a Live Scoreboard shows, built from the Scorer's updates as they arrive.
public struct LiveScoreboardFeed: Equatable, Sendable {
    private var latestMatch: LiveMatch?
    private var latestSentAt: Date?

    /// Updates older than this are from a Match long over (WatchConnectivity redelivers
    /// the last update on launch), but a long rain delay still counts as in progress.
    public static let maximumAge: TimeInterval = 2 * 60 * 60

    public init() {}

    public mutating func receive(_ message: LiveScoreboardMessage) {
        if let latestSentAt, message.sentAt <= latestSentAt { return }
        latestSentAt = message.sentAt
        latestMatch = message.match
    }

    /// The Match to show at `now`: nil when the Scorer has no Match in progress, or has gone
    /// quiet for too long (its app was closed mid-Match, so no update ever cleared it).
    public func match(at now: Date = .now) -> LiveMatch? {
        guard let latestSentAt, now.timeIntervalSince(latestSentAt) <= Self.maximumAge else { return nil }
        return latestMatch
    }
}
