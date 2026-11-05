//
//  NewMatchView.swift
//  snappy-tennis-scoreboard Watch App
//
//  Starts a new Match: choose which side each Player is on and who serves first.
//  Serve tracking itself is turned on/off in Settings.
//  Nothing changes until Start is tapped, so backing out keeps the current Match.
//

import SwiftUI

struct NewMatchView: View {
    let player1Name: String
    let player2Name: String
    let player1Color: Color
    let player2Color: Color
    let playMode: PlayMode
    let language: Language
    let onStart: (ServerSetting, Bool) -> Void

    /// Whether serve tracking is on; changed only in Settings.
    private let tracksServe: Bool
    @State private var player1Serves: Bool
    @State private var player1OnLeft: Bool

    init(
        player1Name: String,
        player2Name: String,
        player1Color: Color,
        player2Color: Color,
        playMode: PlayMode,
        language: Language,
        serverSetting: ServerSetting,
        player1OnLeft: Bool,
        onStart: @escaping (ServerSetting, Bool) -> Void
    ) {
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.player1Color = player1Color
        self.player2Color = player2Color
        self.playMode = playMode
        self.language = language
        self.onStart = onStart
        self.tracksServe = serverSetting != .off
        self._player1Serves = State(initialValue: serverSetting != .player2)
        self._player1OnLeft = State(initialValue: player1OnLeft)
    }

    private func text(_ key: String) -> String {
        LocalizedStrings.getString(key, language: language)
    }

    var body: some View {
        List {
            if playMode == .match {
                Section {
                    Button(action: {
                        player1Serves.toggle()
                    }) {
                        // Server on the left, receiver on the right
                        HStack {
                            Text(player1Serves ? player1Name : player2Name)
                                .foregroundColor(player1Serves ? player1Color : player2Color)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(player1Serves ? player2Name : player1Name)
                                .foregroundColor(player1Serves ? player2Color : player1Color)
                                .lineLimit(1)
                        }
                        .font(.body)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("newMatch.swapServer")
                } header: {
                    HStack {
                        Text(text("server"))
                        Spacer()
                        Text(text("receiver"))
                    }
                }
            }

            Section(text("sides")) {
                Button(action: {
                    player1OnLeft.toggle()
                }) {
                    HStack {
                        Text(player1OnLeft ? player1Name : player2Name)
                            .foregroundColor(player1OnLeft ? player1Color : player2Color)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(player1OnLeft ? player2Name : player1Name)
                            .foregroundColor(player1OnLeft ? player2Color : player1Color)
                            .lineLimit(1)
                    }
                    .font(.body)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("newMatch.swapSides")
            }

            Section {
                Button(action: {
                    // When serve tracking is off the pick is ignored.
                    let server: ServerSetting = tracksServe ? (player1Serves ? .player1 : .player2) : .off
                    onStart(server, player1OnLeft)
                }) {
                    Text(text("start"))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("newMatch.start")
            }
        }
        .navigationTitle(text("newMatch"))
    }
}

#Preview {
    NavigationStack {
        NewMatchView(
            player1Name: "Ana",
            player2Name: "Bob",
            player1Color: .blue,
            player2Color: .green,
            playMode: .match,
            language: .english,
            serverSetting: .player1,
            player1OnLeft: true,
            onStart: { _, _ in }
        )
    }
}
