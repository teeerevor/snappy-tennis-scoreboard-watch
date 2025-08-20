//
//  SettingsView.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 11/7/2025.
//

import SwiftUI

enum TieBreakRule: String, CaseIterable {
    case at66 = "6-6"
    case at55 = "5-5"
    case none = "None"
}

struct SettingsView: View {
    @Binding var player1Name: String
    @Binding var player2Name: String
    @Binding var player1Color: Color
    @Binding var player2Color: Color
    @Binding var setsToPlay: Int
    @Binding var tieBreakRule: TieBreakRule
    
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let colorOptions: [Color] = [.mint, .indigo, .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
    
    var body: some View {
        NavigationView {
            List {
                Section("\(player1Name) Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: player1Color == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    player1Color = color
                                }
                        }
                    }
                }
                
                Section("\(player2Name) Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: player2Color == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    player2Color = color
                                }
                        }
                    }
                }
                
                Section("Player Names") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Player 1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Player 1", text: $player1Name)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Player 2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Player 2", text: $player2Name)
                    }
                }
                
                Section("Number of Sets") {
                        HStack(spacing: 12) {
                            ForEach([1, 3, 5], id: \.self) { setCount in
                                Button(action: {
                                    setsToPlay = setCount
                                }) {
                                    Text("\(setCount)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(setsToPlay == setCount ? .bold : .regular)
                                        .foregroundColor(setsToPlay == setCount ? .white : .secondary)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(setsToPlay == setCount ? Color.blue : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                }
                
                Section("Tie-Break Rule") {
                    VStack(spacing: 8) {
                        ForEach(TieBreakRule.allCases, id: \.self) { rule in
                            Button(action: {
                                tieBreakRule = rule
                            }) {
                                HStack {
                                    Text(rule.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if tieBreakRule == rule {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        onReset()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset Scores")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
