//
//  ShareMatchView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Share Match: a Match's Scorecard, with the Players' names editable for this share only.
struct ShareMatchView: View {
    let record: MatchRecord
    @State private var player1Name: String
    @State private var player2Name: String

    init(record: MatchRecord) {
        self.record = record
        _player1Name = State(initialValue: record.player1.name)
        _player2Name = State(initialValue: record.player2.name)
    }

    /// The Match as it will be shared. Match History keeps the names it was scored with.
    private var scorecard: MatchRecord {
        var scorecard = record
        scorecard.player1.name = Self.name(player1Name, else: record.player1.name)
        scorecard.player2.name = Self.name(player2Name, else: record.player2.name)
        return scorecard
    }

    var body: some View {
        Form {
            Section {
                ScorecardView(record: scorecard)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                nameField("Player 1", text: $player1Name, colorName: record.player1.colorName, id: "field.player1Name")
                nameField("Player 2", text: $player2Name, colorName: record.player2.colorName, id: "field.player2Name")
            } header: {
                Text("Names on the Scorecard")
            } footer: {
                Text("Only changes this Scorecard. Match History keeps the names the Match was scored with.")
            }

            Section {
                ShareScorecardLink(record: scorecard) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22, weight: .bold))
                        Text("SHARE")
                            .font(.snappyHeading(30))
                    }
                    .foregroundStyle(.black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.snappyLime, in: .capsule)
                }
                .buttonStyle(TileButtonStyle())
                .accessibilityLabel("Share Scorecard")
                .accessibilityIdentifier("button.share")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Share Match")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nameField(_ label: String, text: Binding<String>, colorName: String, id: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(PlayerColor.color(named: colorName))
                .frame(width: 12, height: 12)
            TextField(label, text: text)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .accessibilityIdentifier(id)
        }
    }

    /// A cleared field shares the name the Match was scored with.
    private static func name(_ edited: String, else original: String) -> String {
        let trimmed = edited.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? original : trimmed
    }
}
