//
//  MatchDay.swift
//  TennisScoring
//

import Foundation

/// A day of tennis, which ends at 2am rather than midnight so a Match played late under lights
/// stays in progress. A Match in Progress stops being in progress when the day of its last point ends.
public struct MatchDay: Equatable, Sendable {
    /// The hour, in local time, that one day of tennis ends and the next begins.
    public static let endHour = 2

    /// When this day of tennis began.
    public let start: Date

    public init(containing date: Date, calendar: Calendar = .current) {
        let shifted = calendar.date(byAdding: .hour, value: -Self.endHour, to: date) ?? date
        let midnight = calendar.startOfDay(for: shifted)
        start = calendar.date(byAdding: .hour, value: Self.endHour, to: midnight) ?? midnight
    }

    /// Whether something last touched at `last` is still part of the day of tennis at `now`.
    public static func isSameDay(_ last: Date, as now: Date, calendar: Calendar = .current) -> Bool {
        MatchDay(containing: last, calendar: calendar) == MatchDay(containing: now, calendar: calendar)
    }
}
