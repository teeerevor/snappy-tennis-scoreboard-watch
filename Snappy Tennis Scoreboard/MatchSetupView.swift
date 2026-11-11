//
//  MatchSetupView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Sets up the next Match or Practice Session on this device.
struct MatchSetupView: View {
    @State var setup: MatchSetup
    /// Nil on a device that can't pair with an Apple Watch, such as an iPad.
    var watchAppInstalled: Bool?
    /// Asked before Start when it would replace a Match in Progress or Practice Session.
    var confirmation: StartConfirmation?
    let onStart: (MatchSetup) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingStart = false

    var body: some View {
        NavigationStack {
            Form {
                if !setup.isPracticeSession && setup.tracksServe {
                    Section {
                        SwapRow(
                            leading: setup.player(setup.firstServer),
                            trailing: setup.player(setup.firstServer.opponent),
                            accessibilityID: "button.swapServer"
                        ) {
                            setup.firstServer = setup.firstServer.opponent
                        }
                    } header: {
                        SwapHeader(leading: "Server", trailing: "Receiver")
                    }
                }

                Section {
                    SwapRow(
                        leading: setup.player1OnLeft ? setup.player1 : setup.player2,
                        trailing: setup.player1OnLeft ? setup.player2 : setup.player1,
                        accessibilityID: "button.swapSides"
                    ) {
                        setup.player1OnLeft.toggle()
                    }
                } header: {
                    SwapHeader(leading: "Left", trailing: "Right")
                }

                if !setup.isPracticeSession, let watchAppInstalled {
                    Section {
                        Toggle("Sync with Apple Watch", isOn: $setup.syncsWithWatch)
                            // Can always be turned off, even after the Watch App is removed
                            .disabled(!watchAppInstalled && !setup.syncsWithWatch)
                            .accessibilityIdentifier("toggle.watchSync")
                    } footer: {
                        Text(watchAppInstalled
                             ? "Score on your Apple Watch. This screen shows the score."
                             : "Install Snappy Tennis on your Apple Watch first.")
                    }
                }

                Section("Players") {
                    PlayerFields(player: $setup.player1, placeholder: "Player 1", accessibilityID: "menu.player1Color")
                    PlayerFields(player: $setup.player2, placeholder: "Player 2", accessibilityID: "menu.player2Color")
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
                        Toggle("Track serve", isOn: $setup.tracksServe)
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
                        if confirmation == nil {
                            start()
                        } else {
                            confirmingStart = true
                        }
                    }
                    .accessibilityIdentifier("button.start")
                }
            }
            .confirmationDialog(
                confirmation?.title ?? "",
                isPresented: $confirmingStart,
                titleVisibility: .visible,
                presenting: confirmation
            ) { confirmation in
                Button(confirmation.action, role: .destructive, action: start)
                    .accessibilityIdentifier("button.confirmStart")
            } message: { confirmation in
                Text(confirmation.message)
            }
        }
    }

    private func start() {
        onStart(setup)
        dismiss()
    }
}

/// What starting a New Match would end, for Start to confirm first.
struct StartConfirmation {
    let title: String
    let message: String
    /// The confirming button's title.
    let action: String
}


/// A Section header naming the two ends of a SwapRow, e.g. Server and Receiver.
private struct SwapHeader: View {
    let leading: String
    let trailing: String

    var body: some View {
        HStack {
            Text(leading)
            Spacer()
            Text(trailing)
        }
    }
}

/// Two Players facing each other, as on the Watch App's New Match screen: tap to swap them,
/// e.g. who serves first or who is shown on the left.
private struct SwapRow: View {
    let leading: PlayerInfo
    let trailing: PlayerInfo
    let accessibilityID: String
    let onSwap: () -> Void
    @Namespace private var names

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) { onSwap() }
        } label: {
            HStack(spacing: 12) {
                name(leading, alignment: .leading)
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.secondary)
                name(trailing, alignment: .trailing)
            }
            .font(.body.weight(.semibold))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityLabel("\(leading.name), \(trailing.name)")
        .accessibilityHint("Swaps them")
    }

    private func name(_ player: PlayerInfo, alignment: Alignment) -> some View {
        Text(player.name)
            .lineLimit(1)
            .foregroundStyle(PlayerColor.color(named: player.colorName))
            // Each name slides across to the other end rather than jumping
            .matchedGeometryEffect(id: player.colorName + player.name, in: names)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}
