//
//  Theme.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import UIKit

/// The Night Court colours and type used on Home and the screens it opens, in light and dark mode.
extension Color {
    static let courtBackground = Color(light: 0xE6F0F8, dark: 0x17304D)
    static let ballYellow = Color(light: 0xDEE76E, dark: 0xE4EB7A)
    static let onBall = Color(light: 0x1C2414, dark: 0x1C2414)
    static let ink = Color(light: 0x17304D, dark: 0xFFFFFF)
    static let inkSecondary = Color(light: 0x17304D, lightAlpha: 0.62, dark: 0xFFFFFF, darkAlpha: 0.68)
    static let tileFill = Color(light: 0xFFFFFF, lightAlpha: 0.72, dark: 0xFFFFFF, darkAlpha: 0.06)
    static let tileStroke = Color(light: 0x17304D, lightAlpha: 0.08, dark: 0xFFFFFF, darkAlpha: 0.13)
    static let tileRow = Color(light: 0x17304D, lightAlpha: 0.06, dark: 0xFFFFFF, darkAlpha: 0.10)
    static let ringStart = Color(light: 0x9CCBEA, dark: 0x22618C)
    static let ringEnd = Color(light: 0xD8EBF7, dark: 0x5E8AA7)
    static let watchReady = Color(light: 0x5DAA2A, dark: 0xA6D96A)
    /// The primary buttons and the Scorecard's header.
    static let snappyLime = Color(light: 0xE0F097, dark: 0xE0F097)

    init(light: UInt32, lightAlpha: CGFloat = 1, dark: UInt32, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Font {
    /// The heavy condensed italic of the Snappy logo, for headings like NEW MATCH.
    static func snappyHeading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).italic().width(.condensed)
    }
}

/// How the Companion App picks light or dark mode, chosen in Settings.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String { rawValue.capitalized }

    /// Nil follows the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static let storageKey = "appearance"
}

/// Settings stored in UserDefaults, by key.
enum SettingsKey {
    /// Kept courtside, so by default the screen stays on.
    static let keepsScreenAwake = "keepsScreenAwake"
}
