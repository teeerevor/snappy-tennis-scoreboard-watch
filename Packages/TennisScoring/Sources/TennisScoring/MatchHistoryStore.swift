//
//  MatchHistoryStore.swift
//  TennisScoring
//

import Foundation

/// Keeps Match History on this device as a single JSON file.
public struct MatchHistoryStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The store in the app's Application Support directory.
    public static var standard: MatchHistoryStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return MatchHistoryStore(fileURL: directory.appendingPathComponent("match-history.json"))
    }

    public func load() throws -> [MatchRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([MatchRecord].self, from: data)
    }

    /// Adds the record, or replaces the one with the same id.
    public func save(_ record: MatchRecord) throws {
        var records = try load()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        try write(records)
    }

    public func delete(id: UUID) throws {
        let records = try load()
        let remaining = records.filter { $0.id != id }
        if remaining.count != records.count {
            try write(remaining)
        }
    }

    private func write(_ records: [MatchRecord]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Self.encoder.encode(records).write(to: fileURL, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
