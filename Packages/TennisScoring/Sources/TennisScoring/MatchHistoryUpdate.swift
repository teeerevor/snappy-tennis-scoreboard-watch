//
//  MatchHistoryUpdate.swift
//  TennisScoring
//

import Foundation

/// A change to a watch-scored Match in Match History, sent from the Watch App to the Companion App
/// so the Match can be found and shared on the iPhone.
public enum MatchHistoryUpdate: Codable, Equatable, Sendable {
    /// The Match as it now stands, every point included.
    case saved(MatchRecord)
    /// Every point was undone, so the Match is no longer kept.
    case deleted(id: UUID)

    public var matchID: UUID {
        switch self {
        case .saved(let record): record.id
        case .deleted(let id): id
        }
    }

    private static let key = "matchHistoryUpdate"

    /// A property-list dictionary for `WCSession`.
    public var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    /// Nil when the dictionary is not a Match History update.
    public init?(dictionary: [String: Any]) {
        guard let data = dictionary[Self.key] as? Data,
              let update = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = update
    }
}

extension MatchHistoryStore {
    /// Keeps a Match sent from another device. A saved Match never replaces a later version of itself,
    /// so an update that arrives late can't take points away.
    public func apply(_ update: MatchHistoryUpdate) throws {
        switch update {
        case .saved(let record):
            if let kept = try load().first(where: { $0.id == record.id }), kept.updatedAt > record.updatedAt {
                return
            }
            try save(record)
        case .deleted(let id):
            try delete(id: id)
        }
    }
}
