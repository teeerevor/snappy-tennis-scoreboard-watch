//
//  CompanionAppLink.swift
//  snappy-tennis-scoreboard Watch App
//

import Foundation
import Observation
import TennisScoring
import WatchConnectivity

/// The link to the Companion App: sends it the Match in progress for its Live Scoreboard,
/// and receives the Matches it hands over for Watch Sync.
/// The Watch App works the same when the Companion App is not installed or not reachable.
@Observable
final class CompanionAppLink: NSObject, WCSessionDelegate {
    static let shared = CompanionAppLink()

    /// The latest Match the Companion App handed over for Watch Sync, for this device to start and score.
    private(set) var receivedStart: WatchMatchStart?

    /// Waiting for the session to activate.
    @ObservationIgnored private var pending: LiveScoreboardMessage?

    private static let lastStartIDKey = "lastWatchSyncStartID"

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// - Parameter match: nil when there is no Match in progress, which clears the Live Scoreboard.
    func send(_ match: LiveMatch?) {
        let message = LiveScoreboardMessage(sentAt: .now, match: match)
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            pending = message
            return
        }
        deliver(message)
    }

    private func deliver(_ message: LiveScoreboardMessage) {
        let session = WCSession.default
        guard session.isCompanionAppInstalled else { return }
        do {
            // Reaches the iPhone even if the Companion App is not running right now
            try session.updateApplicationContext(message.dictionary)
        } catch {
            print("Failed to update Live Scoreboard context: \(error)")
        }
        // Instant when the Companion App is open courtside
        if session.isReachable {
            session.sendMessage(message.dictionary, replyHandler: nil) { error in
                print("Failed to send Live Scoreboard update: \(error)")
            }
        }
    }

    /// WatchConnectivity redelivers the last start every time this app launches,
    /// so each start is taken only once, or it would restart the Match in progress.
    private func receive(_ start: WatchMatchStart?) {
        guard let start, !start.isStale() else { return }
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Self.lastStartIDKey) != start.id.uuidString else { return }
        defaults.set(start.id.uuidString, forKey: Self.lastStartIDKey)
        receivedStart = start
    }

    // MARK: - WCSessionDelegate (called off the main thread)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // The Companion App's latest start, sent while this app was not running
        let start = WatchMatchStart(dictionary: session.receivedApplicationContext)
        DispatchQueue.main.async {
            self.receive(start)
            guard activationState == .activated, let message = self.pending else { return }
            self.pending = nil
            self.deliver(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let start = WatchMatchStart(dictionary: applicationContext)
        DispatchQueue.main.async { self.receive(start) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let start = WatchMatchStart(dictionary: message)
        DispatchQueue.main.async { self.receive(start) }
    }
}
