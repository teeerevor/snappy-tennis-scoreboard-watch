//
//  WatchLiveScoreboard.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import Observation
import TennisScoring
import WatchConnectivity

/// The Live Scoreboard of a Match the paired Apple Watch is scoring, kept up to date over WatchConnectivity.
@Observable
final class WatchLiveScoreboard: NSObject, WCSessionDelegate {
    private var feed = LiveScoreboardFeed()
    /// Moves on every minute, so a Match the watch stopped sending eventually disappears.
    private var now = Date.now
    @ObservationIgnored private var clock: Timer?

    /// Nil when the watch has no Match in progress.
    var match: LiveMatch? { feed.match(at: now) }

    override init() {
        super.init()
        clock = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = .now }
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func receive(_ message: LiveScoreboardMessage?) {
        guard let message else { return }
        feed.receive(message)
        now = .now
    }

    // MARK: - WCSessionDelegate (called off the main thread)

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // The watch's latest update, sent while this app was not running
        let message = LiveScoreboardMessage(dictionary: session.receivedApplicationContext)
        Task { @MainActor in self.receive(message) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let message = LiveScoreboardMessage(dictionary: applicationContext)
        Task { @MainActor in self.receive(message) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let message = LiveScoreboardMessage(dictionary: message)
        Task { @MainActor in self.receive(message) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another Apple Watch
        session.activate()
    }
}
