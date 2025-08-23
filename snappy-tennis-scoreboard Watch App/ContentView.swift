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
    @State private var isFlipping = false
    @State private var previousText: String = ""

    init(text: String, color: Color, useSmallFont: Bool = false) {
        self.text = text
        self.color = color
        self.useSmallFont = useSmallFont
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
            .rotation3DEffect(
                .degrees(isFlipping ? 85 : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.3
            )
            .opacity(isFlipping ? 0 : 1)

            // Foreground text (new value)
            Group {
                if useSmallFont {
                    Text(text).smallScoreText()
                } else {
                    Text(text).mediumScoreText()
                }
            }
            .foregroundColor(color)
            .rotation3DEffect(
                .degrees(isFlipping ? 0 : -85),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.3
            )
            .opacity(isFlipping ? 1 : 0)
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
    @State private var language = Language.english

    // Celebration
    @State private var showingCelebration = false
    @State private var celebrationType: CelebrationType = .game
    @State private var scoreUpdateAnimation = false

    // Match completion
    @State private var isMatchComplete = false
    @State private var matchWinner = ""

    let pointValues = ["00", "15", "30", "40"]
    let deuceValues = ["AD", "-"]
    let gameText = "GAME"
    let setText = "SET"
    let matchText = "MATCH"
    let longDeuce = false

    // History tracking
    @State private var gameHistory: [(player2Points: String, player1Points: String, player2SetScore: [Int], player1SetScore: [Int], currentSet: Int)] = []
    
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
        
        if let languageString = UserDefaults.standard.string(forKey: "language"),
           let lang = Language(rawValue: languageString) {
            language = lang
        } else {
            language = .english
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(player1Name, forKey: "player1Name")
        UserDefaults.standard.set(player2Name, forKey: "player2Name")
        UserDefaults.standard.set(player1Color.name ?? "blue", forKey: "player1Color")
        UserDefaults.standard.set(player2Color.name ?? "green", forKey: "player2Color")
        UserDefaults.standard.set(setsToPlay, forKey: "setsToPlay")
        UserDefaults.standard.set(tieBreakRule.rawValue, forKey: "tieBreakRule")
        UserDefaults.standard.set(language.rawValue, forKey: "language")
    }

    // Computed property for dynamic set display
    var setsToShow: Int {
        return setsToPlay  // Always show all sets for the match type
    }

    func cycleScore(_ currentScore: String) -> String {
        if longDeuce {
          // TODO: Implement long deuce
        }
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
            currentSet: currentSet
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
    }

    func hasWonTieBreak(_ personScore: Int, _ opponentScore: Int) -> Bool {
      return personScore >= 7 && personScore - opponentScore >= 2 ? true : false
    }

    func hasWonGame(_ personScore: String) -> Bool {
      return personScore == "40" ? true : false
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
                }
                
                // Check if this is the end of the final set (regardless of match win)
                let completedSetNumber = currentSet + 1  // currentSet is 0-based, convert to 1-based
                if completedSetNumber >= setsToPlay {
                    matchWon = true  // Force match completion view
                }

                playerPoints = "00"
                // Note: resetGameScores() will be called in the delayed update
            }
        } else {
            if hasWonGame(playerPoints) {
                playerSetScore[currentSet] += 1
                gameWon = true

                let opponentSetScore = isPlayer1 ? player2SetScore : player1SetScore
                if hasWonSet(playerSetScore[currentSet], opponentSetScore[currentSet]) {
                    setWon = true

                    if hasWonMatch(playerSetScore, opponentSetScore) {
                        matchWon = true
                    } else {
                        currentSet += 1
                    }
                    
                    // Check if this is the end of the final set (regardless of match win)
                    let completedSetNumber = currentSet + 1  // currentSet is 0-based, convert to 1-based
                    if completedSetNumber >= setsToPlay {
                        matchWon = true  // Force match completion view
                    }

                    playerPoints = "00"
                    // Note: resetGameScores() will be called in the delayed update
                } else {
                    // Check if we should continue or reset points
                    playerPoints = "00"
                    // Note: resetGameScores() will be called in the delayed update
                }
            } else {
                playerPoints = cycleScore(playerPoints)
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
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
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
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
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
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
                }
                resetGameScores()
            }
        } else {
            // No celebration, update immediately
            if isPlayer1 {
                player1Points = finalPlayerPoints
                player1SetScore = finalPlayerSetScore
            } else {
                player2Points = finalPlayerPoints
                player2SetScore = finalPlayerSetScore
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scoreUpdateAnimation.toggle()
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if isMatchComplete {
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
                            // Final set of 3 set match -> switch to 5 set match
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
                HStack(spacing: 12) {
                    Text(player1Points)
                        .largeScoreText()
                        .foregroundColor(player1Color)
                        .onTapGesture {
                            updateScore("player1")
                        }
                    Text(player2Points)
                        .largeScoreText()
                        .foregroundColor(player2Color)
                        .onTapGesture {
                            updateScore("player2")
                        }
                }

                VStack(spacing: 12) {
                    if setsToPlay == 1 {
                        // Horizontal layout for single set
                        HStack(spacing: 8) {
                            FlipText(text: "\(player1SetScore[0])", color: player1Color)
                            Text("-")
                                .mediumScoreText()
                                .foregroundColor(.white)
                                .opacity(0.6)
                            FlipText(text: "\(player2SetScore[0])", color: player2Color)
                        }
                    } else {
                        // Vertical layout for multiple sets
                        VStack {
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(player1SetScore[setIndex])", color: player1Color, useSmallFont: true)
                                }
                            }
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(player2SetScore[setIndex])", color: player2Color, useSmallFont: true)
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
                language: $language,
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
        .onChange(of: language) { _, _ in saveSettings() }
    }
}

#Preview {
    ContentView()
}
