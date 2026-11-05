//
//  snappy_tennis_scoreboard_Watch_AppTests.swift
//  snappy-tennis-scoreboard Watch AppTests
//
//  Created by aldus on 10/8/2025.
//

import Testing
@testable import snappy_tennis_scoreboard_watch

struct ScoreboardSidesTests {

    @Test(arguments: [true, false])
    func staticModeFollowsChosenSides(isPlayer1Serving: Bool) {
        #expect(!isScoreboardSwapped(displayMode: .static, serverSetting: .player1,
                                     isPlayer1Serving: isPlayer1Serving, player1OnLeft: true))
        #expect(isScoreboardSwapped(displayMode: .static, serverSetting: .player1,
                                    isPlayer1Serving: isPlayer1Serving, player1OnLeft: false))
    }

    @Test(arguments: [true, false])
    func readableModeKeepsServerOnLeft(player1OnLeft: Bool) {
        #expect(!isScoreboardSwapped(displayMode: .readable, serverSetting: .player1,
                                     isPlayer1Serving: true, player1OnLeft: player1OnLeft))
        #expect(isScoreboardSwapped(displayMode: .readable, serverSetting: .player2,
                                    isPlayer1Serving: false, player1OnLeft: player1OnLeft))
    }

    @Test func readableModeWithoutServeTrackingFollowsChosenSides() {
        #expect(!isScoreboardSwapped(displayMode: .readable, serverSetting: .off,
                                     isPlayer1Serving: false, player1OnLeft: true))
        #expect(isScoreboardSwapped(displayMode: .readable, serverSetting: .off,
                                    isPlayer1Serving: true, player1OnLeft: false))
    }
}
