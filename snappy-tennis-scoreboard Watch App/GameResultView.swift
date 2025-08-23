//
//  GameResultView.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 16/7/2025.
//

import SwiftUI

struct GameResultView: View {
    let player1SetScore: [Int]
    let player2SetScore: [Int]
    let player1Color: Color
    let player2Color: Color
    let loserColor: Color
    let player1Name: String
    let player2Name: String
    let setsToShow: Int
    let totalSets: Int
    let onUndo: () -> Void
    let onSettings: () -> Void
    let onPlayOn: () -> Void
    let onReturn: () -> Void
    let language: Language
    
    @State private var showingOptions = false
    
    
    private var player1Won: Bool {
        let player1Wins = player1SetScore.filter { $0 == 6 }.count
        let setsToWin = (totalSets + 1) / 2
        return player1Wins >= setsToWin
    }
    
    private var winnerName: String {
        return player1Won ? player1Name : player2Name
    }
    
    private var player1Opacity: Double {
        return player1Won ? 1.0 : 0.4
    }
    
    private var player2Opacity: Double {
        return player1Won ? 0.4 : 1.0
    }

    private var player1DisplayColor: Color {
        return player1Won ? player1Color : loserColor
    }
    
    private var player2DisplayColor: Color {
        return player1Won ? loserColor : player2Color
    }
    
    private var canPlayOn: Bool {
        // Play on button should always be visible except on the 5th set of a 5-set match
        let currentSetNumber = setsToShow
        return !(totalSets == 5 && currentSetNumber == 5)
    }
    
    private func countSetsWon(_ playerSetScore: [Int], _ opponentSetScore: [Int]) -> Int {
        var setsWon = 0
        for i in 0..<playerSetScore.count {
            if hasWonSet(playerSetScore[i], opponentSetScore[i]) {
                setsWon += 1
            }
        }
        return setsWon
    }
    
    private func hasWonSet(_ personSetScore: Int, _ opponentSetScore: Int) -> Bool {
        // Simplified set win logic (matches the one from ContentView)
        return (personSetScore >= 6 && opponentSetScore <= 4) ||
               (personSetScore == 7 && opponentSetScore == 5) ||
               (personSetScore == 7 && opponentSetScore == 6)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text("\(winnerName) \(LocalizedStrings.getString("wins", language: language))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 4) {
                if totalSets == 1 {
                    // Horizontal layout for single set
                    HStack(spacing: 8) {
                        Text("\(player1SetScore[0])")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(player1DisplayColor)
                            .opacity(player1Opacity)
                        Text("-")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .opacity(0.6)
                        Text("\(player2SetScore[0])")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(player2DisplayColor)
                            .opacity(player2Opacity)
                    }
                } else {
                    // Vertical layout for multiple sets
                    VStack {
                        HStack(spacing: 20) {
                            ForEach(0..<setsToShow, id: \.self) { setIndex in
                                Text("\(player1SetScore[setIndex])")
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.medium)
                                    .foregroundColor(player1DisplayColor)
                                    .opacity(player1Opacity)
                            }
                        }
                        HStack(spacing: 20) {
                            ForEach(0..<setsToShow, id: \.self) { setIndex in
                                Text("\(player2SetScore[setIndex])")
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.medium)
                                    .foregroundColor(player2DisplayColor)
                                    .opacity(player2Opacity)
                            }
                        }
                    }
                }
            }
            
            if !showingOptions {
                Text(LocalizedStrings.getString("tapForOptions", language: language))
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.6)
            } else {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        if canPlayOn {
                            Button(action: onPlayOn) {
                                Text(LocalizedStrings.getString("playOn", language: language))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: onReturn) {
                            Text(LocalizedStrings.getString("newGame", language: language))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray)
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack(spacing: 80) {
                        Button(action: onUndo) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(8)
                        }
                        .buttonStyle(TransparentButtonStyle())
                        
                        Button(action: onSettings) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingOptions.toggle()
            }
        }
    }
}

#Preview {
    GameResultView(
        player1SetScore: [6, 4, 6],
        player2SetScore: [4, 6, 2],
        player1Color: .mint,
        player2Color: .indigo,
        loserColor: .gray,
        player1Name: "Bob",
        player2Name: "Bob",
        setsToShow: 3,
        totalSets: 3,
        onUndo: {},
        onSettings: {},
        onPlayOn: {},
        onReturn: {},
        language: .english
    )
}
