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
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text("\(winnerName) wins!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 4) {
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
        onSettings: {}
    )
}
