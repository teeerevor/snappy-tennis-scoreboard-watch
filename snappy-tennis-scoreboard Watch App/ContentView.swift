//
//  ContentView.swift
//  Snappy Tennis Scordboard Watch App
//
//  Created by aldus on 25/6/2025.
//

import SwiftUI
import WatchKit

func fontSizeForLargeScore() -> CGFloat {
    let width = WKInterfaceDevice.current().screenBounds.width
    switch width {
    case 198...: // Ultra 49mm
        return 76
    case 184...: // 45/44mm
        return 60
    case 162...: // 41/40mm
        return 58
    default: // 38mm and others
        return 48
    }
}

func fontSizeForMediumScore() -> CGFloat {
    let width = WKInterfaceDevice.current().screenBounds.width
    switch width {
    case 198...: // Ultra 49mm
        return 40
    case 184...: // 45/44mm
        return 34
    case 162...: // 41/40mm
        return 28
    default: // 38mm and others
        return 20
    }
}

func fontSizeForSmallScore() -> CGFloat {
    let width = WKInterfaceDevice.current().screenBounds.width
    switch width {
    case 198...: // Ultra 49mm
        return 28
    case 184...: // 45/44mm
        return 24
    case 162...: // 41/40mm
        return 20
    default: // 38mm and others
        return 16
    }
}

struct LargeScoreText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSizeForLargeScore(), design: .monospaced))
            .fontWeight(.heavy)
    }
}

struct MediumScoreText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSizeForMediumScore()))
            .fontWeight(.medium)
    }
}

struct SmallScoreText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSizeForSmallScore()))
            .fontWeight(.medium)
    }
}

struct TransparentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.clear)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FlipText: View {
    let text: String
    let color: Color
    let useSmallFont: Bool
    let opacity: Double
    @State private var isFlipping = false
    @State private var previousText: String = ""

    init(text: String, color: Color, useSmallFont: Bool = false, opacity: Double = 1.0) {
        self.text = text
        self.color = color
        self.useSmallFont = useSmallFont
        self.opacity = opacity
        self._previousText = State(initialValue: text)
    }

    var body: some View {
        let fontSize = useSmallFont ? fontSizeForSmallScore() : fontSizeForMediumScore()

        ZStack {
            // Background text (previous value)
            Group {
                if useSmallFont {
                    Text(previousText).smallScoreText()
                } else {
                    Text(previousText).mediumScoreText()
                }
            }
            .foregroundColor(color)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(isFlipping ? 85 : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.3
            )
            .opacity(isFlipping ? 0 : opacity)

            // Foreground text (new value)
            Group {
                if useSmallFont {
                    Text(text).smallScoreText()
                } else {
                    Text(text).mediumScoreText()
                }
            }
            .foregroundColor(color)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(isFlipping ? 0 : -85),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.3
            )
            .opacity(isFlipping ? opacity : 0)
        }
        .frame(width: fontSize * 0.8, height: fontSize * 1.2)
        .onChange(of: text) { oldValue, newValue in
            if oldValue != newValue {
                previousText = oldValue
                withAnimation(.easeInOut(duration: 0.6)) {
                    isFlipping = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    previousText = newValue
                    isFlipping = false
                }
            }
        }
    }
}

extension View {
    func largeScoreText() -> some View {
        modifier(LargeScoreText())
    }

    func mediumScoreText() -> some View {
        modifier(MediumScoreText())
    }

    func smallScoreText() -> some View {
        modifier(SmallScoreText())
    }
}

// MARK: - Settings Persistence
extension Color {
    static let colorMap: [String: Color] = [
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        "green": .green,
        "blue": .blue,
        "purple": .purple,
        "pink": .pink,
        "cyan": .cyan,
        "mint": .mint,
        "indigo": .indigo
    ]

    var name: String? {
        for (name, color) in Color.colorMap {
            if self == color {
                return name
            }
        }
        return nil
    }

    static func fromName(_ name: String) -> Color? {
        return colorMap[name]
    }
}

struct ContentView: View {
    @State private var player2Points = "00"
    @State private var player2SetScore = [0,0,0,0,0]
    @State private var player1Points = "00"
    @State private var player1SetScore = [0,0,0,0,0]
    @State private var currentSet = 0

    // Settings
    @State private var showingSettings = false
    @State private var player1Name = "Ana"
    @State private var player2Name = "Bob"
    @State private var player1Color = Color.blue
    @State private var player2Color = Color.green
    @State private var setsToPlay = 3
    @State private var tieBreakRule = TieBreakRule.at66
    @State private var deuceType = DeuceType.short
    @State private var language = Language.english
    @State private var serverSetting: ServerSetting = .player1
    @State private var displayMode: DisplayMode = .static
    @State private var gameMode: GameMode = .game

    // Practice mode
    @State private var player1PracticeScore = 0
    @State private var player2PracticeScore = 0
    @State private var practiceHistory: [(Int, Int)] = []

    // Celebration
    @State private var showingCelebration = false
    @State private var celebrationType: CelebrationType = .game
    @State private var scoreUpdateAnimation = false

    // Match completion
    @State private var isMatchComplete = false
    @State private var matchWinner = ""

    // Serving
    @State private var isPlayer1Serving = true
    @State private var tieBreakServeCount = 0

    let pointValues = ["00", "15", "30", "40"]
    let deuceValues = ["AD", "-"]
    let gameText = "GAME"
    let setText = "SET"
    let matchText = "MATCH"
    let longDeuce = false

    // History tracking
    @State private var gameHistory: [(player2Points: String, player1Points: String, player2SetScore: [Int], player1SetScore: [Int], currentSet: Int, isPlayer1Serving: Bool, tieBreakServeCount: Int)] = []

    // MARK: - Settings Persistence
    func loadSettings() {
        player1Name = UserDefaults.standard.string(forKey: "player1Name") ?? "Ana"
        player2Name = UserDefaults.standard.string(forKey: "player2Name") ?? "Bob"

        if let player1ColorName = UserDefaults.standard.string(forKey: "player1Color"),
           let color1 = Color.fromName(player1ColorName) {
            player1Color = color1
        } else {
            player1Color = .blue
        }

        if let player2ColorName = UserDefaults.standard.string(forKey: "player2Color"),
           let color2 = Color.fromName(player2ColorName) {
            player2Color = color2
        } else {
            player2Color = .green
        }

        setsToPlay = UserDefaults.standard.object(forKey: "setsToPlay") as? Int ?? 3

        if let tieBreakRuleString = UserDefaults.standard.string(forKey: "tieBreakRule"),
           let rule = TieBreakRule(rawValue: tieBreakRuleString) {
            tieBreakRule = rule
        } else {
            tieBreakRule = .at66
        }

        if let deuceTypeString = UserDefaults.standard.string(forKey: "deuceType"),
           let type = DeuceType(rawValue: deuceTypeString) {
            deuceType = type
        } else {
            deuceType = .short
        }

        if let languageString = UserDefaults.standard.string(forKey: "language"),
           let lang = Language(rawValue: languageString) {
            language = lang
        } else {
            language = .english
        }

        if let serverSettingString = UserDefaults.standard.string(forKey: "serverSetting"),
           let server = ServerSetting(rawValue: serverSettingString) {
            serverSetting = server
        } else {
            serverSetting = .player1
        }

        if let displayModeString = UserDefaults.standard.string(forKey: "displayMode"),
           let mode = DisplayMode(rawValue: displayModeString) {
            displayMode = mode
        } else {
            displayMode = .static
        }

        if let gameModeString = UserDefaults.standard.string(forKey: "gameMode"),
           let mode = GameMode(rawValue: gameModeString) {
            gameMode = mode
        } else {
            gameMode = .game
        }

        // Sync serving state with server setting
        if serverSetting != .off {
            isPlayer1Serving = (serverSetting == .player1)
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(player1Name, forKey: "player1Name")
        UserDefaults.standard.set(player2Name, forKey: "player2Name")
        UserDefaults.standard.set(player1Color.name ?? "blue", forKey: "player1Color")
        UserDefaults.standard.set(player2Color.name ?? "green", forKey: "player2Color")
        UserDefaults.standard.set(setsToPlay, forKey: "setsToPlay")
        UserDefaults.standard.set(tieBreakRule.rawValue, forKey: "tieBreakRule")
        UserDefaults.standard.set(deuceType.rawValue, forKey: "deuceType")
        UserDefaults.standard.set(language.rawValue, forKey: "language")
        UserDefaults.standard.set(serverSetting.rawValue, forKey: "serverSetting")
        UserDefaults.standard.set(displayMode.rawValue, forKey: "displayMode")
        UserDefaults.standard.set(gameMode.rawValue, forKey: "gameMode")
    }

    // Computed property for dynamic set display
    var setsToShow: Int {
        return setsToPlay  // Always show all sets for the match type
    }

    // When readable mode is active, swap scores so server is always on the left
    var swapDisplay: Bool {
        displayMode == .readable && serverSetting != .off && !isPlayer1Serving
    }

    func cycleScore(_ currentScore: String) -> String {
        if let currentIndex = pointValues.firstIndex(of: currentScore) {
            let nextIndex = (currentIndex + 1) % pointValues.count
            return pointValues[nextIndex]
        }
        return "00"
    }

    func saveCurrentState() {
        let currentState = (
            player2Points: player2Points,
            player1Points: player1Points,
            player2SetScore: player2SetScore,
            player1SetScore: player1SetScore,
            currentSet: currentSet,
            isPlayer1Serving: isPlayer1Serving,
            tieBreakServeCount: tieBreakServeCount
        )
        gameHistory.append(currentState)
    }

    func undoLastChange() {
        guard !gameHistory.isEmpty else { return }

        let previousState = gameHistory.removeLast()
        player2Points = previousState.player2Points
        player1Points = previousState.player1Points
        player2SetScore = previousState.player2SetScore
        player1SetScore = previousState.player1SetScore
        currentSet = previousState.currentSet
        isPlayer1Serving = previousState.isPlayer1Serving
        tieBreakServeCount = previousState.tieBreakServeCount
    }

    func hasWonTieBreak(_ personScore: Int, _ opponentScore: Int) -> Bool {
      return personScore >= 7 && personScore - opponentScore >= 2 ? true : false
    }

    func hasWonGame(_ personScore: String, _ opponentScore: String) -> Bool {
        if deuceType == .short {
            return personScore == "40"
        } else {
            // Long deuce: need to win by 2 when both at 40
            if personScore == "40" && opponentScore != "40" {
                return true
            }
            // Win from advantage
            return personScore == "AD"
        }
    }

    func hasWonSet(_ personSetScore: Int, _ opponentSetScore: Int) -> Bool {
        switch tieBreakRule {
        case .at66:
            // Win at 6 games if opponent has less than 6, or 7-6 after tie break
            return (personSetScore >= 6 && opponentSetScore <= 4) ||
                   (personSetScore == 7 && opponentSetScore == 5) ||
                   (personSetScore == 7 && opponentSetScore == 6)
        case .at55:
            // Win at 6 games if opponent has less than 5, or 6-5 after tie break
            return (personSetScore >= 6 && opponentSetScore <= 3) ||
                   (personSetScore == 6 && opponentSetScore == 4) ||
                   (personSetScore == 6 && opponentSetScore == 5)
        case .none:
            // Traditional tennis: must win by 2 and have at least 6
            return personSetScore >= 6 && personSetScore - opponentSetScore >= 2
        }
    }

    func hasWonMatch(_ playerSetScore: [Int], _ opponentSetScore: [Int]) -> Bool {
        var setsWon = 0
        for i in 0..<playerSetScore.count {
            if hasWonSet(playerSetScore[i], opponentSetScore[i]) {
                setsWon += 1
            }
        }
        let setsToWin = (setsToPlay + 1) / 2  // 1->1, 3->2, 5->3
        return setsWon >= setsToWin
    }

    func getMatchWinner() -> String? {
        var player1Wins = 0
        var player2Wins = 0

        for i in 0..<player1SetScore.count {
            if hasWonSet(player1SetScore[i], player2SetScore[i]) {
                player1Wins += 1
            } else if hasWonSet(player2SetScore[i], player1SetScore[i]) {
                player2Wins += 1
            }
        }

        let setsToWin = (setsToPlay + 1) / 2  // 1->1, 3->2, 5->3

        if player1Wins >= setsToWin {
            return player1Name
        } else if player2Wins >= setsToWin {
            return player2Name
        }

        // If we've completed all sets but no traditional winner, return whoever has more sets
        let completedSets = max(player1Wins + player2Wins, 1)  // At least 1 set completed
        if completedSets >= setsToPlay {
            if player1Wins > player2Wins {
                return player1Name
            } else if player2Wins > player1Wins {
                return player2Name
            }
            // If tied, return player with higher current set score
            let currentSetIndex = min(currentSet, player1SetScore.count - 1)
            if player1SetScore[currentSetIndex] > player2SetScore[currentSetIndex] {
                return player1Name
            } else {
                return player2Name
            }
        }

        return nil
    }

    func triggerCelebration(type: CelebrationType) {
        celebrationType = type
        showingCelebration = true
    }

    func resetGameScores() {
      player2Points = "00"
      player1Points = "00"
    }

    func resetAllScores() {
        player2Points = "00"
        player1Points = "00"
        player2SetScore = [0,0,0,0,0]
        player1SetScore = [0,0,0,0,0]
        currentSet = 0
        gameHistory.removeAll()
        isMatchComplete = false
        matchWinner = ""
        isPlayer1Serving = (serverSetting == .player1)
        tieBreakServeCount = 0
        player1PracticeScore = 0
        player2PracticeScore = 0
        practiceHistory.removeAll()
    }

    func updatePracticeScore(_ player: String) {
        practiceHistory.append((player1PracticeScore, player2PracticeScore))
        if player == "player1" {
            player1PracticeScore = player1PracticeScore >= 99 ? 0 : player1PracticeScore + 1
        } else {
            player2PracticeScore = player2PracticeScore >= 99 ? 0 : player2PracticeScore + 1
        }
    }

    func undoPracticeChange() {
        guard !practiceHistory.isEmpty else { return }
        let prev = practiceHistory.removeLast()
        player1PracticeScore = prev.0
        player2PracticeScore = prev.1
    }

    var player1PracticeDisplay: String {
        player1PracticeScore >= 10 ? "\(player1PracticeScore)" : "0\(player1PracticeScore)"
    }

    var player2PracticeDisplay: String {
        player2PracticeScore >= 10 ? "\(player2PracticeScore)" : "0\(player2PracticeScore)"
    }

    func isTieBreak() -> Bool {
        switch tieBreakRule {
        case .at66:
            return player1SetScore[currentSet] == 6 && player2SetScore[currentSet] == 6
        case .at55:
            return player1SetScore[currentSet] == 5 && player2SetScore[currentSet] == 5
        case .none:
            return false
        }
    }

    func updateScore(_ player: String) {
        saveCurrentState()

        let isPlayer1 = player == "player1"
        var playerPoints = isPlayer1 ? player1Points : player2Points
        var playerSetScore = isPlayer1 ? player1SetScore : player2SetScore
        var gameWon = false
        var setWon = false
        var matchWon = false

        if isTieBreak() {
            var playerTieBreakPoints = Int(playerPoints) ?? 0
            let opponentPoints = isPlayer1 ? player2Points : player1Points
            let opponentTieBreakPoints = Int(opponentPoints) ?? 0
            playerTieBreakPoints += 1
            playerPoints = playerTieBreakPoints >= 10 ? "\(playerTieBreakPoints)" :"0\(playerTieBreakPoints)"

            // Handle serve changes in tiebreak (first server serves 1 point, then alternates every 2 points)
            tieBreakServeCount += 1
            if (tieBreakServeCount == 1) || (tieBreakServeCount > 1 && (tieBreakServeCount - 1) % 2 == 0) {
                isPlayer1Serving.toggle()
                if serverSetting != .off { serverSetting = isPlayer1Serving ? .player1 : .player2 }
            }

            if hasWonTieBreak(playerTieBreakPoints, opponentTieBreakPoints) {
                // Set the correct final score based on tie break rule
                let opponentSetScore = isPlayer1 ? player2SetScore : player1SetScore
                switch tieBreakRule {
                case .at66:
                    playerSetScore[currentSet] = 7  // Winner gets 7 in 7-6 score
                    // Opponent stays at 6
                case .at55:
                    playerSetScore[currentSet] = 6  // Winner gets 6 in 6-5 score
                    // Opponent stays at 5
                case .none:
                    playerSetScore[currentSet] += 1
                }
                setWon = true

                if hasWonMatch(playerSetScore, opponentSetScore) {
                    matchWon = true
                } else {
                    currentSet += 1
                    // Reset tiebreak serve count and switch serve for next set
                    tieBreakServeCount = 0
                    isPlayer1Serving.toggle()
                    if serverSetting != .off { serverSetting = isPlayer1Serving ? .player1 : .player2 }
                }

                // Only force match completion if someone has won the required number of sets
                // Don't force completion just because we've played all sets

                playerPoints = "00"
                // Note: resetGameScores() will be called in the delayed update
            }
        } else {
            let opponentPoints = isPlayer1 ? player2Points : player1Points
            if hasWonGame(playerPoints, opponentPoints) {
                playerSetScore[currentSet] += 1
                gameWon = true
                // Switch serve at end of game
                isPlayer1Serving.toggle()
                if serverSetting != .off { serverSetting = isPlayer1Serving ? .player1 : .player2 }

                let opponentSetScore = isPlayer1 ? player2SetScore : player1SetScore
                if hasWonSet(playerSetScore[currentSet], opponentSetScore[currentSet]) {
                    setWon = true

                    if hasWonMatch(playerSetScore, opponentSetScore) {
                        matchWon = true
                    } else {
                        currentSet += 1
                        // Switch serve for new set (undo the game switch since set changes serving order)
                        isPlayer1Serving.toggle()
                        if serverSetting != .off { serverSetting = isPlayer1Serving ? .player1 : .player2 }
                    }

                    // Only force match completion if someone has won the required number of sets
                    // Don't force completion just because we've played all sets

                    playerPoints = "00"
                    // Note: resetGameScores() will be called in the delayed update
                } else {
                    // Check if we should continue or reset points
                    playerPoints = "00"
                    // Note: resetGameScores() will be called in the delayed update
                }
            } else {
                // Handle long deuce logic
                if deuceType == .long {
                    let opponentPoints = isPlayer1 ? player2Points : player1Points
                    if playerPoints == "40" && opponentPoints == "40" {
                        // From 40-40 to advantage
                        playerPoints = "AD"
                        // Set opponent to disadvantage (will be updated below)
                    } else if playerPoints == "-" && opponentPoints == "AD" {
                        // From disadvantage back to deuce
                        playerPoints = "40"
                        // Set opponent back to 40 (will be updated below)
                    } else {
                        playerPoints = cycleScore(playerPoints)
                    }
                } else {
                    playerPoints = cycleScore(playerPoints)
                }
            }
        }

        // Handle opponent score changes for long deuce
        var finalOpponentPoints = isPlayer1 ? player2Points : player1Points
        if deuceType == .long && !gameWon && !setWon && !matchWon {
            let opponentPoints = isPlayer1 ? player2Points : player1Points
            if playerPoints == "AD" && opponentPoints == "40" {
                // Player got advantage, opponent goes to disadvantage
                finalOpponentPoints = "-"
            } else if playerPoints == "40" && opponentPoints == "AD" {
                // Back to deuce from advantage
                finalOpponentPoints = "40"
            }
        }

        // Store the calculated values for delayed update
        let finalPlayerPoints = playerPoints
        let finalPlayerSetScore = playerSetScore

        // Trigger celebrations first, then update scores
        if matchWon {
            matchWinner = getMatchWinner() ?? ""
            triggerCelebration(type: .match)

            // Update score immediately when returning to scoreboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                if isPlayer1 {
                    player1Points = finalPlayerPoints
                    player1SetScore = finalPlayerSetScore
                    player2Points = finalOpponentPoints
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
                    player1Points = finalOpponentPoints
                }
                resetGameScores()
            }
        } else if setWon {
            triggerCelebration(type: .set)

            // Update score immediately when returning to scoreboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                if isPlayer1 {
                    player1Points = finalPlayerPoints
                    player1SetScore = finalPlayerSetScore
                    player2Points = finalOpponentPoints
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
                    player1Points = finalOpponentPoints
                }
                resetGameScores()
            }
        } else if gameWon {
            triggerCelebration(type: .game)

            // Update score immediately when returning to scoreboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                if isPlayer1 {
                    player1Points = finalPlayerPoints
                    player1SetScore = finalPlayerSetScore
                    player2Points = finalOpponentPoints
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
                    player1Points = finalOpponentPoints
                }
                resetGameScores()
            }
        } else {
            // No celebration, update immediately
            if isPlayer1 {
                player1Points = finalPlayerPoints
                player1SetScore = finalPlayerSetScore
                player2Points = finalOpponentPoints
            } else {
                player2Points = finalPlayerPoints
                player2SetScore = finalPlayerSetScore
                player1Points = finalOpponentPoints
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scoreUpdateAnimation.toggle()
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if gameMode == .practice {
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(player1PracticeDisplay)
                                .largeScoreText()
                                .foregroundColor(player1Color)
                                .onTapGesture {
                                    updatePracticeScore("player1")
                                }
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(.clear)
                        }
                        VStack(spacing: 2) {
                            Text(player2PracticeDisplay)
                                .largeScoreText()
                                .foregroundColor(player2Color)
                                .onTapGesture {
                                    updatePracticeScore("player2")
                                }
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(.clear)
                        }
                    }
                }
                VStack(spacing: 12) {
                    HStack(spacing: 80) {
                        Button(action: {
                            undoPracticeChange()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                    }
                }
            } else if isMatchComplete {
                GameResultView(
                    player1SetScore: player1SetScore,
                    player2SetScore: player2SetScore,
                    player1Color: player1Color,
                    player2Color: player2Color,
                    loserColor: .gray,
                    player1Name: player1Name,
                    player2Name: player2Name,
                    setsToShow: setsToShow,
                    totalSets: setsToPlay,
                    onUndo: {
                        undoLastChange()
                        isMatchComplete = false
                    },
                    onSettings: {
                        showingSettings = true
                    },
                    onPlayOn: {
                        // Reset game points for next set
                        player1Points = "00"
                        player2Points = "00"

                        // Handle match type transitions based on current state
                        let currentSetNumber = currentSet + 1  // 1-based set number

                        if setsToPlay == 1 {
                            // 1 set match -> switch to 3 set match
                            setsToPlay = 3
                            currentSet += 1
                        } else if setsToPlay == 3 && currentSetNumber == 3 {
                            // After 3rd set is complete -> switch to 5 set match
                            setsToPlay = 5
                            currentSet += 1
                        } else {
                            // 2nd set of 3 set match, or 3rd/4th set of 5 set match -> just continue
                            currentSet += 1
                        }

                        isMatchComplete = false
                    },
                    onReturn: {
                        resetAllScores()
                        isMatchComplete = false
                    },
                    language: language
                )
            } else {
                // Active match view
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        let leftPlayer = swapDisplay ? "player2" : "player1"
                        let rightPlayer = swapDisplay ? "player1" : "player2"
                        let leftPoints = swapDisplay ? player2Points : player1Points
                        let rightPoints = swapDisplay ? player1Points : player2Points
                        let leftColor = swapDisplay ? player2Color : player1Color
                        let rightColor = swapDisplay ? player1Color : player2Color

                        VStack(spacing: 2) {
                            Text(leftPoints)
                                .largeScoreText()
                                .foregroundColor(leftColor)
                                .onTapGesture {
                                    updateScore(leftPlayer)
                                }

                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(serverSetting != .off && (swapDisplay ? !isPlayer1Serving : isPlayer1Serving) ? leftColor : .clear)
                        }

                        VStack(spacing: 2) {
                            Text(rightPoints)
                                .largeScoreText()
                                .foregroundColor(rightColor)
                                .onTapGesture {
                                    updateScore(rightPlayer)
                                }

                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(serverSetting != .off && (swapDisplay ? isPlayer1Serving : !isPlayer1Serving) ? rightColor : .clear)
                        }
                    }
                }

                VStack(spacing: 12) {
                    let leftSetScore = swapDisplay ? player2SetScore : player1SetScore
                    let rightSetScore = swapDisplay ? player1SetScore : player2SetScore
                    let leftSetColor = swapDisplay ? player2Color : player1Color
                    let rightSetColor = swapDisplay ? player1Color : player2Color

                    if setsToPlay == 1 {
                        // Horizontal layout for single set
                        HStack(spacing: 8) {
                            FlipText(text: "\(leftSetScore[0])", color: leftSetColor)
                            Text("-")
                                .mediumScoreText()
                                .foregroundColor(.white)
                                .opacity(0.6)
                            FlipText(text: "\(rightSetScore[0])", color: rightSetColor)
                        }
                    } else {
                        // Vertical layout for multiple sets
                        VStack {
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(leftSetScore[setIndex])",
                                           color: setIndex <= currentSet ? leftSetColor : .gray,
                                           useSmallFont: true,
                                           opacity: setIndex <= currentSet ? 1.0 : 0.6)
                                }
                            }
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(rightSetScore[setIndex])",
                                           color: setIndex <= currentSet ? rightSetColor : .gray,
                                           useSmallFont: true,
                                           opacity: setIndex <= currentSet ? 1.0 : 0.6)
                                }
                            }
                        }
                    }
                    HStack(spacing: 80) {
                        Button(action: {
                            undoLastChange()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())

                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                player1Name: $player1Name,
                player2Name: $player2Name,
                player1Color: $player1Color,
                player2Color: $player2Color,
                setsToPlay: $setsToPlay,
                tieBreakRule: $tieBreakRule,
                deuceType: $deuceType,
                language: $language,
                serverSetting: $serverSetting,
                displayMode: $displayMode,
                gameMode: $gameMode,
                onReset: resetAllScores
            )
        }
        .fullScreenCover(isPresented: $showingCelebration) {
            GameAnnouncementView(
                celebrationType: celebrationType,
                language: language,
                onDismiss: {
                    showingCelebration = false

                    // Only show match complete view after match celebration is done
                    if case .match = celebrationType {
                        isMatchComplete = true
                    }

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        scoreUpdateAnimation.toggle()
                    }
                }
            )
            .interactiveDismissDisabled()
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: player1Name) { _, _ in saveSettings() }
        .onChange(of: player2Name) { _, _ in saveSettings() }
        .onChange(of: player1Color) { _, _ in saveSettings() }
        .onChange(of: player2Color) { _, _ in saveSettings() }
        .onChange(of: setsToPlay) { _, _ in saveSettings() }
        .onChange(of: tieBreakRule) { _, _ in saveSettings() }
        .onChange(of: deuceType) { _, _ in saveSettings() }
        .onChange(of: language) { _, _ in saveSettings() }
        .onChange(of: serverSetting) { _, _ in
            saveSettings()
            // Update serving state when setting changes manually
            if serverSetting != .off {
                isPlayer1Serving = (serverSetting == .player1)
            }
        }
        .onChange(of: displayMode) { _, _ in saveSettings() }
        .onChange(of: gameMode) { _, newValue in
            saveSettings()
            if newValue == .practice { isMatchComplete = false }
        }
    }
}

#Preview {
    ContentView()
}
