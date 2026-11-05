//
//  MatchSetupView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Sets up the next Match or Practice Session on this device.
struct MatchSetupView: View {
    @State var setup: MatchSetup
    let onStart: (MatchSetup) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    playerFields($setup.player1, placeholder: "Player 1")
                    playerFields($setup.player2, placeholder: "Player 2")
                }

                Section {
                    Toggle("Practice Session", isOn: $setup.isPracticeSession)
                } footer: {
                    Text("Casual play, scored as a simple count. Never kept in Match History.")
                }

                if !setup.isPracticeSession {
                    Section("Match") {
                        Picker("Sets", selection: $setup.rules.setsToPlay) {
                            Text("1").tag(1)
                            Text("3").tag(3)
                            Text("5").tag(5)
                        }
                        .pickerStyle(.segmented)
                        Picker("Tiebreak", selection: $setup.rules.tieBreakRule) {
                            ForEach(TieBreakRule.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Deuce", selection: $setup.rules.deuceType) {
                            ForEach(DeuceType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    }

                    Section("Serve") {
                        Toggle("Track serve", isOn: $setup.tracksServe)
                        if setup.tracksServe {
                            Picker("First to serve", selection: $setup.firstServer) {
                                Text(setup.player1.name).tag(Player.player1)
                                Text(setup.player2.name).tag(Player.player2)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
            .navigationTitle(setup.isPracticeSession ? "New Practice Session" : "New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onStart(setup)
                        dismiss()
                    }
                    .accessibilityIdentifier("button.start")
                }
            }
        }
    }

    private func playerFields(_ player: Binding<PlayerInfo>, placeholder: String) -> some View {
        HStack {
            TextField(placeholder, text: player.name)
                .textInputAutocapitalization(.words)
            Picker(placeholder, selection: player.colorName) {
                ForEach(PlayerColor.names, id: \.self) { name in
                    Label(name.capitalized, systemImage: "circle.fill")
                        .tint(PlayerColor.color(named: name))
                        .tag(name)
                }
            }
            .labelsHidden()
            .tint(PlayerColor.color(named: player.wrappedValue.colorName))
        }
    }
}
