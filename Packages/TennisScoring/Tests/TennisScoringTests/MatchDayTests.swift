//
//  MatchDayTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
import TennisScoring

extension Calendar {
    /// Fixed, so day boundaries don't depend on the machine running the tests.
    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }
}

struct MatchDayTests {
    /// 8 November 2026 at the given UTC time.
    func nov8(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let components = DateComponents(year: 2026, month: 11, day: 8 + dayOffset, hour: hour, minute: minute)
        return Calendar.utc.date(from: components)!
    }

    @Test func aLateMatchPastMidnightIsStillTheSameDay() {
        // Last point at 23:58, app opened again at 00:03
        #expect(MatchDay.isSameDay(nov8(23, 58), as: nov8(0, 3, dayOffset: 1), calendar: .utc))
    }

    @Test func theDayEndsAt2am() {
        #expect(MatchDay.isSameDay(nov8(1, 59), as: nov8(1, 59), calendar: .utc))
        #expect(!MatchDay.isSameDay(nov8(1, 59), as: nov8(2, 1), calendar: .utc))
    }

    @Test func aMatchLeftOvernightIsAnEarlierDay() {
        // Rained off at 16:00, app opened at 09:00 the next morning
        #expect(!MatchDay.isSameDay(nov8(16), as: nov8(9, dayOffset: 1), calendar: .utc))
    }

    @Test func aLongRainDelayTheSameDayIsTheSameDay() {
        #expect(MatchDay.isSameDay(nov8(10), as: nov8(19, 30), calendar: .utc))
    }

    @Test func theDayStartsAt2am() {
        #expect(MatchDay(containing: nov8(15), calendar: .utc).start == nov8(2))
        #expect(MatchDay(containing: nov8(1, 30, dayOffset: 1), calendar: .utc).start == nov8(2))
    }
}
