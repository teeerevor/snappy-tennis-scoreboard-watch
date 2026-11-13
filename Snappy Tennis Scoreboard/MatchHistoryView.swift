//
//  MatchHistoryView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Match History: every Match kept on this device, finished or Unfinished, newest first.
struct MatchHistoryView: View {
    let history: MatchHistory
    /// Opens Share Match for a Match.
    let onShare: (MatchRecord) -> Void

    var body: some View {
        List {
            ForEach(history.records) { record in
                MatchHistoryRow(record: record) { onShare(record) }
            }
            .onDelete { offsets in
                offsets.map { history.records[$0] }.forEach(history.delete)
            }
        }
        .overlay {
            if history.records.isEmpty {
                ContentUnavailableView(
                    "No Matches Yet",
                    systemImage: "sportscourt",
                    description: Text("Matches scored here or on Apple Watch are kept in Match History. Practice Sessions are not.")
                )
            }
        }
        .navigationTitle("Match History")
        .onAppear(perform: history.reload)
    }
}

/// One Match in Match History: both Players with their set scores, when it was played, and a Scorecard to share.
private struct MatchHistoryRow: View {
    let record: MatchRecord
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                player(.player1)
                player(.player2)
                HStack(spacing: 6) {
                    Text(record.startedAt, format: .dateTime.day().month().year().hour().minute())
                    if !record.isFinished {
                        Text("Unfinished")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: .capsule)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel("Share Match")
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("button.shareMatch.\(record.id)")
        }
        .padding(.vertical, 4)
    }

    private func player(_ player: Player) -> some View {
        let info = record.player(player)
        return HStack {
            Circle()
                .fill(PlayerColor.color(named: info.colorName))
                .frame(width: 10, height: 10)
            Text(info.name)
                .fontWeight(record.winner == player ? .bold : .regular)
            if record.winner == player {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
            Spacer()
            HStack(spacing: 10) {
                ForEach(Array(record.setScores(for: player).enumerated()), id: \.offset) { _, games in
                    Text("\(games)")
                }
            }
            .font(.body.monospacedDigit().weight(.semibold))
        }
    }
}
