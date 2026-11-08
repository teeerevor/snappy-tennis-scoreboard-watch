//
//  HomeView.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// Home: the Companion App's starting screen, for starting or continuing a Match and opening
/// Match History, sharing a Scorecard and Settings.
struct HomeView: View {
    let watchConnection: WatchConnection
    let history: MatchHistory
    /// What Continue Match goes back to, or nil when no Match is in progress.
    let matchInProgress: String?
    let onNewMatch: () -> Void
    let onContinueMatch: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height
            ScrollView {
                Group {
                    if isWide {
                        wideLayout(height: geometry.size.height)
                    } else {
                        tallLayout(width: geometry.size.width)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background { CourtLines().ignoresSafeArea() }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: history.reload)
    }

    // MARK: - Layouts

    private func tallLayout(width: CGFloat) -> some View {
        VStack(spacing: 20) {
            topBar
            Spacer(minLength: 0)
            SnappyBallLogo()
                // Smaller with Continue Match, so the tiles still fit without scrolling
                .frame(width: min(width * (matchInProgress == nil ? 0.6 : 0.48), 300))
                .padding(.vertical, 8)
            Spacer(minLength: 0)
            actions(tileHeight: 230)
        }
        // Keeps the column readable on iPad
        .frame(maxWidth: 520)
    }

    private func wideLayout(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            topBar
            HStack(spacing: 32) {
                SnappyBallLogo()
                    .frame(width: min(height * 0.6, 340))
                    .frame(maxWidth: .infinity)
                actions(tileHeight: max(130, height - (matchInProgress == nil ? 230 : 318)))
                    .frame(maxWidth: 520)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var topBar: some View {
        HStack {
            WatchStatusPill(watchConnection: watchConnection)
            Spacer()
            NavigationLink(value: HomeDestination.settings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .frame(width: 52, height: 52)
                    .background(Color.tileFill, in: .circle)
                    .overlay { Circle().strokeBorder(Color.tileStroke) }
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("button.settings")
        }
        .padding(.top, 8)
    }

    private func actions(tileHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            if let matchInProgress {
                ContinueMatchButton(detail: matchInProgress, action: onContinueMatch)
            }
            NewMatchButton(action: onNewMatch)
            HStack(spacing: 14) {
                NavigationLink(value: HomeDestination.matchHistory) {
                    MatchHistoryTile(records: history.records, height: tileHeight)
                }
                .buttonStyle(TileButtonStyle())
                .accessibilityIdentifier("button.matchHistory")

                ShareMatchTile(latest: history.records.first, height: tileHeight)
            }
        }
    }
}

/// Where Home's buttons lead.
enum HomeDestination: Hashable {
    case match
    case matchHistory
    case settings
}

// MARK: - Pieces

/// Faint court lines behind Home, as if looking down on the court from the umpire's chair.
private struct CourtLines: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var lines = Path()
            for x in [0.1, 0.2, 0.8, 0.9] {
                lines.move(to: CGPoint(x: w * x, y: 0))
                lines.addLine(to: CGPoint(x: w * x, y: h))
            }
            // Service line and centre service line
            lines.move(to: CGPoint(x: w * 0.2, y: h * 0.39))
            lines.addLine(to: CGPoint(x: w * 0.8, y: h * 0.39))
            lines.move(to: CGPoint(x: w * 0.5, y: h * 0.39))
            lines.addLine(to: CGPoint(x: w * 0.5, y: h))
            context.stroke(lines, with: .color(.courtLine), lineWidth: 3)
        }
        .background(Color.courtBackground)
        .accessibilityHidden(true)
    }
}

/// The Snappy tennis ball inside its ring. The ring follows light and dark mode; the ball is the artwork.
struct SnappyBallLogo: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.ringStart, .ringEnd], startPoint: .bottomLeading, endPoint: .topTrailing))
                    .shadow(color: .black.opacity(0.18), radius: size * 0.08, y: size * 0.04)
                // The artwork's ball is 75% of its width, inside a fixed light-blue ring
                Image("SnappyBall")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle().inset(by: size * 0.126))
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Snappy Sports")
        .accessibilityAddTraits(.isImage)
    }
}

/// Whether the paired Apple Watch is ready for Watch Sync or scoring a Match. Hidden on an iPad.
private struct WatchStatusPill: View {
    let watchConnection: WatchConnection

    var body: some View {
        if watchConnection.isSupported {
            let (text, isReady) = status
            HStack(spacing: 10) {
                Circle()
                    .fill(isReady ? Color.watchReady : Color.inkSecondary)
                    .frame(width: 10, height: 10)
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.tileFill, in: .capsule)
            .overlay { Capsule().strokeBorder(Color.tileStroke) }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("label.watchStatus")
        }
    }

    private var status: (String, Bool) {
        if watchConnection.match != nil { return ("Watch scoring live", true) }
        if watchConnection.isWatchAppInstalled { return ("Watch ready", true) }
        return ("No watch app", false)
    }
}

/// The big yellow NEW MATCH button.
private struct NewMatchButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("NEW MATCH")
                    .font(.snappyHeading(44))
                    .foregroundStyle(Color.onBall)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.leading, 28)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.ballYellow)
                    .frame(width: 64, height: 64)
                    .background(Color.onBall, in: .circle)
                    .padding(.trailing, 12)
            }
            .frame(height: 88)
            .background(Color.ballYellow, in: .capsule)
            .shadow(color: Color.ballYellow.opacity(0.35), radius: 18)
        }
        .buttonStyle(TileButtonStyle())
        .accessibilityLabel("New Match")
        .accessibilityIdentifier("button.newMatch")
    }
}

/// Goes back to the Match in progress.
private struct ContinueMatchButton: View {
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.onBall)
                    .frame(width: 48, height: 48)
                    .background(Color.ballYellow, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTINUE MATCH")
                        .font(.snappyHeading(26))
                        .foregroundStyle(Color.ink)
                    Text(detail)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 72)
            .background(Color.tileFill, in: .capsule)
            .overlay { Capsule().strokeBorder(Color.tileStroke) }
        }
        .buttonStyle(TileButtonStyle())
        .accessibilityIdentifier("button.continueMatch")
    }
}

/// A rounded tile on Home, with its title and subtitle at the bottom.
private struct Tile<Content: View>: View {
    let title: String
    let subtitle: String
    let height: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
                .clipped()
            // The title always shows in full; a short tile (landscape) crops its content instead
            Group {
                Text(title)
                    .font(.snappyHeading(26))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .background(Color.tileFill, in: .rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tileStroke) }
        .contentShape(.rect(cornerRadius: 28))
    }
}

/// The latest three Matches, opening the Match History screen.
private struct MatchHistoryTile: View {
    let records: [MatchRecord]
    let height: CGFloat

    var body: some View {
        Tile(title: "Match History", subtitle: subtitle, height: height) {
            VStack(spacing: 8) {
                if records.isEmpty {
                    Text("No matches yet")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                ForEach(Array(records.prefix(height >= 220 ? 3 : 1).enumerated()), id: \.element.id) { index, record in
                    row(record)
                        .opacity(1 - Double(index) * 0.2)
                }
            }
        }
    }

    private var subtitle: String {
        records.count == 1 ? "1 match" : "\(records.count) matches"
    }

    private func row(_ record: MatchRecord) -> some View {
        HStack(spacing: 6) {
            Text("\(record.player1.name) v \(record.player2.name)")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let winner = record.winner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(PlayerColor.color(named: record.player(winner).colorName))
                    .accessibilityLabel("\(record.player(winner).name) won")
            } else {
                Text("–")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
                    .accessibilityLabel("Unfinished")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.tileRow, in: .rect(cornerRadius: 10))
    }
}

/// The latest Match's Scorecard, opening the share sheet.
private struct ShareMatchTile: View {
    let latest: MatchRecord?
    let height: CGFloat

    var body: some View {
        if let latest {
            ShareScorecardLink(record: latest) {
                tile(subtitle: "Scorecard ready") {
                    ScorecardView(record: latest, isCompact: true)
                        .rotationEffect(.degrees(-4))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .padding(.top, 6)
                }
            }
            .buttonStyle(TileButtonStyle())
            .accessibilityIdentifier("button.shareMatch")
        } else {
            tile(subtitle: "Play a match first") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
            }
            .accessibilityIdentifier("button.shareMatch")
        }
    }

    private func tile(subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        Tile(title: "Share Match", subtitle: subtitle, height: height, content: content)
    }
}

/// Shrinks a little while pressed, without tinting the custom-drawn label.
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
