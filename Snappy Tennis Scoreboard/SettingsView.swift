//
//  SettingsView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Settings for the Companion App: appearance, the courtside screen, and how each New Match starts.
struct SettingsView: View {
    let scorer: Scorer
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @AppStorage(SettingsKey.keepsScreenAwake) private var keepsScreenAwake = true
    /// Saved as it changes, so the next New Match starts from it.
    @State private var defaults: MatchSetup

    init(scorer: Scorer) {
        self.scorer = scorer
        _defaults = State(initialValue: scorer.nextSetup)
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("picker.appearance")
            }

            Section {
                Toggle("Keep screen awake", isOn: $keepsScreenAwake)
                    .accessibilityIdentifier("toggle.keepScreenAwake")
            } header: {
                Text("Courtside")
            } footer: {
                Text("Stops the screen locking while the app is open, so the score stays visible.")
            }

            Section {
                PlayerFields(player: $defaults.player1, placeholder: "Player 1", accessibilityID: "menu.defaultPlayer1Color")
                PlayerFields(player: $defaults.player2, placeholder: "Player 2", accessibilityID: "menu.defaultPlayer2Color")
            } header: {
                Text("New Match Players")
            } footer: {
                Text("Players are just a name and a colour. Changing them on New Match updates these too.")
            }

            Section("New Match Rules") {
                Picker("Sets", selection: $defaults.rules.setsToPlay) {
                    Text("1").tag(1)
                    Text("3").tag(3)
                    Text("5").tag(5)
                }
                .pickerStyle(.segmented)
                Picker("Tiebreak", selection: $defaults.rules.tieBreakRule) {
                    ForEach(TieBreakRule.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Deuce", selection: $defaults.rules.deuceType) {
                    ForEach(DeuceType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Toggle("Track serve", isOn: $defaults.tracksServe)
            }

            Section {
                LabeledContent("Version", value: Self.version)
                Label("Snappy Tennis keeps score on your Apple Watch. This app adds a big-screen scoreboard, Match History and Scorecards.", systemImage: "applewatch")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: defaults) { _, newValue in
            scorer.saveNextSetup(newValue)
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}
