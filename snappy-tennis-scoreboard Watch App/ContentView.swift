//
//  ContentView.swift
//  Snappy Tennis Scordboard Watch App
//
//  Created by aldus on 25/6/2025.
//

import SwiftUI
import WatchKit
import TennisScoring

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

/// Whether Player 2 is shown on the left. Readable mode keeps the server on the left;
/// otherwise the sides chosen for the Match apply.
func isScoreboardSwapped(displayMode: DisplayMode, serverSetting: ServerSetting,
                         isPlayer1Serving: Bool, player1OnLeft: Bool) -> Bool {
    if displayMode == .readable && serverSetting != .off {
        return !isPlayer1Serving
    }
    return !player1OnLeft
}

struct ContentView: View {
    // The live score, and what the scoreboard shows (lags behind during a celebration)
    @State private var match = MatchScore(rules: MatchRules())
    @State private var shown = MatchScore(rules: MatchRules())

    // Match History
    private let historyStore = MatchHistoryStore.standard
    @State private var matchID = UUID()
    @State private var matchStartedAt = Date.now

    // Settings
    @State private var showingSettings = false
    @State private var showingNewMatch = false
    @State private var player1OnLeft = true
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
    @State private var playMode: PlayMode = .match

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

        // "gameMode" key and its old "Game" value predate the Match/Practice naming
        if let playModeString = UserDefaults.standard.string(forKey: "gameMode"),
           let mode = PlayMode(rawValue: playModeString) {
            playMode = mode
        } else {
            playMode = .match
        }

        player1OnLeft = UserDefaults.standard.object(forKey: "player1OnLeft") as? Bool ?? true

        syncRules()
        // Sync serving state with server setting
        if serverSetting != .off {
            match.setServer(serverSetting == .player1 ? .player1 : .player2)
            shown = match
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
        UserDefaults.standard.set(playMode.rawValue, forKey: "gameMode")
        UserDefaults.standard.set(player1OnLeft, forKey: "player1OnLeft")
    }

    // Rules changed in settings apply to the Match in progress
    func syncRules() {
        match.rules = MatchRules(setsToPlay: setsToPlay, tieBreakRule: tieBreakRule, deuceType: deuceType)
        match.tracksServe = serverSetting != .off
    }

    // Computed property for dynamic set display
    var setsToShow: Int {
        return setsToPlay  // Always show all sets for the match type
    }

    var swapDisplay: Bool {
        isScoreboardSwapped(displayMode: displayMode, serverSetting: serverSetting,
                            isPlayer1Serving: match.isPlayer1Serving, player1OnLeft: player1OnLeft)
    }

    // MARK: - Live Scoreboard

    /// What the Companion App's Live Scoreboard shows: nothing until the first point,
    /// and never a Practice Session.
    var liveMatch: LiveMatch? {
        guard playMode == .match, !match.points.isEmpty else { return nil }
        return LiveMatch(
            id: matchID,
            player1: PlayerInfo(name: player1Name, colorName: player1Color.name ?? "blue"),
            player2: PlayerInfo(name: player2Name, colorName: player2Color.name ?? "green"),
            score: match
        )
    }

    // MARK: - Match History

    // Saved after every change, so a Match that is never finished is kept as Unfinished
    func recordMatch() {
        do {
            if match.points.isEmpty {
                try historyStore.delete(id: matchID)
            } else {
                try historyStore.save(MatchRecord(
                    id: matchID,
                    startedAt: matchStartedAt,
                    updatedAt: .now,
                    player1: PlayerInfo(name: player1Name, colorName: player1Color.name ?? "blue"),
                    player2: PlayerInfo(name: player2Name, colorName: player2Color.name ?? "green"),
                    score: match
                ))
            }
        } catch {
            print("Failed to save match history: \(error)")
        }
    }

    func undoLastChange() {
        match.undo()
        shown = match
        recordMatch()
    }

    func playOn() {
        syncRules()
        match.playOn()
        shown = match
        setsToPlay = match.rules.setsToPlay
        isMatchComplete = false
        recordMatch()
    }

    func triggerCelebration(type: CelebrationType) {
        celebrationType = type
        showingCelebration = true
    }

    func resetAllScores() {
        match = MatchScore(rules: match.rules, isPlayer1Serving: serverSetting == .player1)
        syncRules()
        shown = match
        matchID = UUID()
        matchStartedAt = .now
        isMatchComplete = false
        player1PracticeScore = 0
        player2PracticeScore = 0
        practiceHistory.removeAll()
    }

    func startNewMatch(server: ServerSetting, player1OnLeft: Bool) {
        serverSetting = server
        self.player1OnLeft = player1OnLeft
        resetAllScores()
    }

    /// Watch Sync: the Companion App handed over a Match, so start it here with its setup.
    func startSyncedMatch(_ start: WatchMatchStart) {
        player1Name = start.player1.name
        player2Name = start.player2.name
        player1Color = Color.fromName(start.player1.colorName) ?? .blue
        player2Color = Color.fromName(start.player2.colorName) ?? .green
        setsToPlay = start.rules.setsToPlay
        tieBreakRule = start.rules.tieBreakRule
        deuceType = start.rules.deuceType
        serverSetting = switch start.server {
        case .player1: .player1
        case .player2: .player2
        case nil: .off
        }
        player1OnLeft = start.player1OnLeft
        playMode = .match
        resetAllScores()
        // Shared with the Companion App, so its Live Scoreboard knows this is the Match it handed over
        matchID = start.id
        showingSettings = false
        showingNewMatch = false
        showingCelebration = false
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

    func updateScore(_ player: Player) {
        if match.points.isEmpty {
            matchStartedAt = .now
        }
        syncRules()
        let event = match.score(player)
        if serverSetting != .off { serverSetting = match.isPlayer1Serving ? .player1 : .player2 }
        recordMatch()

        switch event {
        case .match, .set, .game:
            triggerCelebration(type: event == .match ? .match : event == .set ? .set : .game)

            // Update score when returning to scoreboard
            let updated = match
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                shown = updated
            }
        case .point:
            // No celebration, update immediately
            shown = match

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scoreUpdateAnimation.toggle()
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if playMode == .practice {
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(player1OnLeft ? player1PracticeDisplay : player2PracticeDisplay)
                                .largeScoreText()
                                .foregroundColor(player1OnLeft ? player1Color : player2Color)
                                .onTapGesture {
                                    updatePracticeScore(player1OnLeft ? "player1" : "player2")
                                }
                                .accessibilityIdentifier("practice.left")
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(.clear)
                        }
                        VStack(spacing: 2) {
                            Text(player1OnLeft ? player2PracticeDisplay : player1PracticeDisplay)
                                .largeScoreText()
                                .foregroundColor(player1OnLeft ? player2Color : player1Color)
                                .onTapGesture {
                                    updatePracticeScore(player1OnLeft ? "player2" : "player1")
                                }
                                .accessibilityIdentifier("practice.right")
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
                        .accessibilityIdentifier("button.undo")
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                        .accessibilityIdentifier("button.settings")
                    }
                }
            } else if isMatchComplete {
                GameResultView(
                    player1SetScore: shown.player1SetScore,
                    player2SetScore: shown.player2SetScore,
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
                        playOn()
                    },
                    onReturn: {
                        showingNewMatch = true
                    },
                    language: language
                )
            } else {
                // Active match view
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        let leftPlayer: Player = swapDisplay ? .player2 : .player1
                        let rightPlayer: Player = swapDisplay ? .player1 : .player2
                        let leftPoints = swapDisplay ? shown.player2Points : shown.player1Points
                        let rightPoints = swapDisplay ? shown.player1Points : shown.player2Points
                        let leftColor = swapDisplay ? player2Color : player1Color
                        let rightColor = swapDisplay ? player1Color : player2Color

                        VStack(spacing: 2) {
                            Text(leftPoints)
                                .largeScoreText()
                                .foregroundColor(leftColor)
                                .onTapGesture {
                                    updateScore(leftPlayer)
                                }
                                .accessibilityIdentifier("score.left")

                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(serverSetting != .off && (swapDisplay ? !match.isPlayer1Serving : match.isPlayer1Serving) ? leftColor : .clear)
                        }

                        VStack(spacing: 2) {
                            Text(rightPoints)
                                .largeScoreText()
                                .foregroundColor(rightColor)
                                .onTapGesture {
                                    updateScore(rightPlayer)
                                }
                                .accessibilityIdentifier("score.right")

                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(serverSetting != .off && (swapDisplay ? match.isPlayer1Serving : !match.isPlayer1Serving) ? rightColor : .clear)
                        }
                    }
                }

                VStack(spacing: 12) {
                    let leftSetScore = swapDisplay ? shown.player2SetScore : shown.player1SetScore
                    let rightSetScore = swapDisplay ? shown.player1SetScore : shown.player2SetScore
                    let leftSetColor = swapDisplay ? player2Color : player1Color
                    let rightSetColor = swapDisplay ? player1Color : player2Color

                    if setsToPlay == 1 {
                        // Horizontal layout for single set — swap follows server in readable mode
                        HStack(spacing: 8) {
                            FlipText(text: "\(leftSetScore[0])", color: leftSetColor)
                            Text("-")
                                .mediumScoreText()
                                .foregroundColor(.white)
                                .opacity(0.6)
                            FlipText(text: "\(rightSetScore[0])", color: rightSetColor)
                        }
                    } else {
                        // Vertical layout — top row always player1, bottom always player2
                        VStack {
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(shown.player1SetScore[setIndex])",
                                           color: setIndex <= match.currentSet ? player1Color : .gray,
                                           useSmallFont: true,
                                           opacity: setIndex <= match.currentSet ? 1.0 : 0.6)
                                }
                            }
                            HStack(spacing: setsToPlay == 5 ? 12 : 16) {
                                ForEach(0..<setsToShow, id: \.self) { setIndex in
                                    FlipText(text: "\(shown.player2SetScore[setIndex])",
                                           color: setIndex <= match.currentSet ? player2Color : .gray,
                                           useSmallFont: true,
                                           opacity: setIndex <= match.currentSet ? 1.0 : 0.6)
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
                        .accessibilityIdentifier("button.undo")

                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                        .accessibilityIdentifier("button.settings")
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
                displayMode: $displayMode,
                playMode: $playMode,
                tracksServe: Binding(
                    get: { serverSetting != .off },
                    // Turning tracking on keeps whoever the Match says is serving
                    set: { serverSetting = $0 ? (match.isPlayer1Serving ? .player1 : .player2) : .off }
                ),
                serverSetting: serverSetting,
                player1OnLeft: player1OnLeft,
                onNewMatch: startNewMatch
            )
        }
        .sheet(isPresented: $showingNewMatch) {
            NavigationStack {
                NewMatchView(
                    player1Name: player1Name,
                    player2Name: player2Name,
                    player1Color: player1Color,
                    player2Color: player2Color,
                    playMode: playMode,
                    language: language,
                    serverSetting: serverSetting,
                    player1OnLeft: player1OnLeft,
                    onStart: { server, onLeft in
                        startNewMatch(server: server, player1OnLeft: onLeft)
                        showingNewMatch = false
                    }
                )
            }
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
            CompanionAppLink.shared.send(liveMatch)
        }
        .onChange(of: liveMatch) { _, newValue in
            CompanionAppLink.shared.send(newValue)
        }
        .onChange(of: CompanionAppLink.shared.receivedStart) { _, start in
            if let start { startSyncedMatch(start) }
        }
        .onChange(of: player1Name) { _, _ in saveSettings() }
        .onChange(of: player2Name) { _, _ in saveSettings() }
        .onChange(of: player1Color) { _, _ in saveSettings() }
        .onChange(of: player2Color) { _, _ in saveSettings() }
        .onChange(of: setsToPlay) { _, _ in
            saveSettings()
            syncRules()
        }
        .onChange(of: tieBreakRule) { _, _ in
            saveSettings()
            syncRules()
        }
        .onChange(of: deuceType) { _, _ in
            saveSettings()
            syncRules()
        }
        .onChange(of: language) { _, _ in saveSettings() }
        .onChange(of: serverSetting) { _, _ in
            saveSettings()
            // Update serving state when setting changes manually
            syncRules()
            if serverSetting != .off {
                match.setServer(serverSetting == .player1 ? .player1 : .player2)
            }
        }
        .onChange(of: displayMode) { _, _ in saveSettings() }
        .onChange(of: player1OnLeft) { _, _ in saveSettings() }
        .onChange(of: playMode) { _, newValue in
            saveSettings()
            if newValue == .practice { isMatchComplete = false }
        }
    }
}

#Preview {
    ContentView()
}
