//
//  LiveScoreboardSender.swift
//  snappy-tennis-scoreboard Watch App
//

import Foundation
import TennisScoring
import WatchConnectivity

/// Sends the Match in progress to the Companion App's Live Scoreboard.
/// The Watch App works the same when the Companion App is not installed or not reachable.
final class LiveScoreboardSender: NSObject, WCSessionDelegate {
    static let shared = LiveScoreboardSender()

    /// Waiting for the session to activate.
    private var pending: LiveScoreboardMessage?

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

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            guard activationState == .activated, let message = self.pending else { return }
            self.pending = nil
            self.deliver(message)
        }
    }
}
