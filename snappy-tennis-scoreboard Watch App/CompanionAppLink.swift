//
//  CompanionAppLink.swift
//  snappy-tennis-scoreboard Watch App
//

import Foundation
import Observation
import TennisScoring
import WatchConnectivity

/// The link to the Companion App: sends it the Match in progress for its Live Scoreboard and every
/// Match for its Match History, and receives the Matches it hands over for Watch Sync.
/// The Watch App works the same when the Companion App is not installed or not reachable.
@Observable
final class CompanionAppLink: NSObject, WCSessionDelegate {
    static let shared = CompanionAppLink()

    /// The latest Match the Companion App handed over for Watch Sync, for this device to start and score.
    private(set) var receivedStart: WatchMatchStart?

    /// Waiting for the session to activate.
    @ObservationIgnored private var pending: LiveScoreboardMessage?
    private static let lastStartIDKey = "lastWatchSyncStartID"
    /// Set once Match History from before this feature, or from before the Companion App was installed, is due to be sent.
    private static let sentMatchHistoryKey = "sentMatchHistoryToCompanionApp"
    /// Matches changed since the Companion App last confirmed it has them, kept across launches.
    private static let unsentMatchesKey = "matchesUnsentToCompanionApp"

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

    /// Keeps the Companion App's Match History in step with this device's, so watch Matches can be shared there.
    /// A Match stays on the unsent list until the Companion App confirms it, so nothing is lost while it is away.
    func sendToMatchHistory(_ update: MatchHistoryUpdate) {
        unsentMatches.insert(update.matchID)
        // Otherwise it goes when the session activates
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        deliver(update)
    }

    private var unsentMatches: Set<UUID> {
        get {
            Set((UserDefaults.standard.stringArray(forKey: Self.unsentMatchesKey) ?? []).compactMap(UUID.init(uuidString:)))
        }
        set {
            UserDefaults.standard.set(newValue.map(\.uuidString), forKey: Self.unsentMatchesKey)
        }
    }

    /// Every unsent Match as it now stands in Match History, or as deleted if it is no longer there.
    private func sendUnsentMatches() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isCompanionAppInstalled else { return }
        let defaults = UserDefaults.standard
        do {
            let records = try MatchHistoryStore.standard.load()
            if !defaults.bool(forKey: Self.sentMatchHistoryKey) {
                unsentMatches.formUnion(records.map(\.id))
                defaults.set(true, forKey: Self.sentMatchHistoryKey)
            }
            for id in unsentMatches {
                deliver(records.first { $0.id == id }.map(MatchHistoryUpdate.saved) ?? .deleted(id: id))
            }
        } catch {
            print("Failed to send Match History: \(error)")
        }
    }

    private func deliver(_ update: MatchHistoryUpdate) {
        let session = WCSession.default
        // Sent along with the rest of Match History once the Companion App is installed
        guard session.isCompanionAppInstalled else { return }
        // Only the latest version of a Match matters, so it replaces any still waiting to go
        for transfer in session.outstandingUserInfoTransfers
        where !transfer.isTransferring && MatchHistoryUpdate(dictionary: transfer.userInfo)?.matchID == update.matchID {
            transfer.cancel()
        }
        // Instant when the Companion App is open; the system's queue can hold transfers back for minutes
        if session.isReachable {
            session.sendMessage(update.dictionary, replyHandler: { _ in
                DispatchQueue.main.async { self.unsentMatches.remove(update.matchID) }
            }, errorHandler: { _ in
                DispatchQueue.main.async { session.transferUserInfo(update.dictionary) }
            })
        } else {
            // Delivered once the iPhone is reachable, even if the Companion App is not running
            session.transferUserInfo(update.dictionary)
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
            guard activationState == .activated else { return }
            self.sendUnsentMatches()
            guard let message = self.pending else { return }
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

    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        DispatchQueue.main.async { self.sendUnsentMatches() }
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard error == nil, let update = MatchHistoryUpdate(dictionary: userInfoTransfer.userInfo) else { return }
        DispatchQueue.main.async { self.unsentMatches.remove(update.matchID) }
    }
}
