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
            .font(.system(size: fontSizeForMediumScore(), design: .monospaced))
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
    @State private var isFlipping = false
    @State private var previousText: String = ""
    
    init(text: String, color: Color) {
        self.text = text
        self.color = color
        self._previousText = State(initialValue: text)
    }
    
    var body: some View {
        ZStack {
            // Background text (previous value)
            Text(previousText)
                .mediumScoreText()
                .foregroundColor(color)
                .rotation3DEffect(
                    .degrees(isFlipping ? 85 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    perspective: 0.3
                )
                .opacity(isFlipping ? 0 : 1)
            
            // Foreground text (new value)
            Text(text)
                .mediumScoreText()
                .foregroundColor(color)
                .rotation3DEffect(
                    .degrees(isFlipping ? 0 : -85),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    perspective: 0.3
                )
                .opacity(isFlipping ? 1 : 0)
        }
        .frame(width: fontSizeForMediumScore() * 0.8, height: fontSizeForMediumScore() * 1.2)
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
    @State private var player1Color = Color.mint
    @State private var player2Color = Color.indigo
    @State private var setsToPlay = 3
    @State private var tieBreakRule = TieBreakRule.at66
    
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
    
    // Computed property for dynamic set display
    var setsToShow: Int {
        if setsToPlay == 5 {
            // Start with 3 sets, expand to 4 when entering set 4, expand to 5 when entering set 5
            return min(max(3, currentSet + 1), 5)
        } else {
            return setsToPlay
        }
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
                
                playerPoints = "00"
                resetGameScores()
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
                    
                    playerPoints = "00"
                    resetGameScores()
                } else {
                    // Check if we should continue or reset points
                    playerPoints = "00"
                    resetGameScores()
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
            triggerCelebration(type: .match(setsToPlay: setsToPlay))
            
            // Update score immediately when returning to scoreboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                if isPlayer1 {
                    player1Points = finalPlayerPoints
                    player1SetScore = finalPlayerSetScore
                } else {
                    player2Points = finalPlayerPoints
                    player2SetScore = finalPlayerSetScore
                }
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
        VStack(spacing: 8) {
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
                    }
                )
            } else {
                // Active match view
                HStack(spacing: 12) {
                    Text(player1Points)
                        .largeScoreText()
                        .foregroundColor(player1Color)
                        .scaleEffect(scoreUpdateAnimation ? 1.1 : 1.0)
                        .onTapGesture {
                            updateScore("player1")
                        }
                    Text(player2Points)
                        .largeScoreText()
                        .foregroundColor(player2Color)
                        .scaleEffect(scoreUpdateAnimation ? 1.1 : 1.0)
                        .onTapGesture {
                            updateScore("player2")
                        }
                }
                
                VStack(spacing: 4) {
                    if setsToPlay == 1 {
                        // Horizontal layout for single set
                        HStack(spacing: 8) {
                            FlipText(text: "\(player1SetScore[0])", color: player1Color)
                                .scaleEffect(scoreUpdateAnimation ? 1.05 : 1.0)
                            Text("-")
                                .mediumScoreText()
                                .foregroundColor(.white)
                                .opacity(0.6)
                            FlipText(text: "\(player2SetScore[0])", color: player2Color)
                                .scaleEffect(scoreUpdateAnimation ? 1.05 : 1.0)
                        }
                    } else {
                        // Vertical layout for multiple sets
                        VStack {
                            HStack {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(player1SetScore[setIndex])", color: player1Color)
                                        .scaleEffect(scoreUpdateAnimation ? 1.05 : 1.0)
                                }
                            }
                            HStack {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(player2SetScore[setIndex])", color: player2Color)
                                        .scaleEffect(scoreUpdateAnimation ? 1.05 : 1.0)
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
                onReset: resetAllScores
            )
        }
        .fullScreenCover(isPresented: $showingCelebration) {
            GameAnnouncementView(
                celebrationType: celebrationType,
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
    }
}

#Preview {
    ContentView()
}
