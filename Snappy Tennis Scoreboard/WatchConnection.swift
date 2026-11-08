//
//  WatchConnection.swift
//  Snappy Tennis Scoreboard
//

import Foundation
import Observation
import TennisScoring
import WatchConnectivity

/// The link to the paired Apple Watch: hands it Matches for Watch Sync, and keeps the Live Scoreboard
/// of the Match it is scoring up to date.
@Observable
final class WatchConnection: NSObject, WCSessionDelegate {
    private var feed = LiveScoreboardFeed()
    /// Moves on every minute, so a Match the watch stopped sending eventually disappears.
    private var now = Date.now
    @ObservationIgnored private var clock: Timer?
    /// Waiting for the session to activate.
    @ObservationIgnored private var pendingStart: WatchMatchStart?

    /// Nil when the watch has no Match in progress.
    var match: LiveMatch? { feed.match(at: now) }

    /// Watch Sync needs the Watch App on the paired Apple Watch.
    private(set) var isWatchAppInstalled = false

    /// False on a device that can't pair with an Apple Watch, such as an iPad.
    var isSupported: Bool { WCSession.isSupported() }

    override init() {
        super.init()
        clock = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = .now }
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Hands a Match to the watch, which starts it and becomes its Scorer.
    func startMatch(_ start: WatchMatchStart) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            pendingStart = start
            return
        }
        deliver(start)
    }

    private func deliver(_ start: WatchMatchStart) {
        let session = WCSession.default
        guard session.isPaired, session.isWatchAppInstalled else { return }
        do {
            // Reaches the watch even if the Watch App is not running right now
            try session.updateApplicationContext(start.dictionary)
        } catch {
            print("Failed to update Watch Sync context: \(error)")
        }
        // Instant when the Watch App is open
        if session.isReachable {
            session.sendMessage(start.dictionary, replyHandler: nil) { error in
                print("Failed to send Watch Sync start: \(error)")
            }
        }
    }

    private func receive(_ message: LiveScoreboardMessage?) {
        guard let message else { return }
        feed.receive(message)
        now = .now
    }

    private func activated(watchAppInstalled: Bool) {
        isWatchAppInstalled = watchAppInstalled
        guard let start = pendingStart else { return }
        pendingStart = nil
        deliver(start)
    }

    // MARK: - WCSessionDelegate (called off the main thread)

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // The watch's latest update, sent while this app was not running
        let message = LiveScoreboardMessage(dictionary: session.receivedApplicationContext)
        let installed = activationState == .activated && session.isPaired && session.isWatchAppInstalled
        Task { @MainActor in
            self.receive(message)
            if activationState == .activated { self.activated(watchAppInstalled: installed) }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let installed = session.isPaired && session.isWatchAppInstalled
        Task { @MainActor in self.isWatchAppInstalled = installed }
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
