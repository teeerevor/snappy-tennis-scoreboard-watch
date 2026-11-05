//
//  PlayerColor.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI

/// The colours a Player can pick, by the names Match History and the Watch App store.
enum PlayerColor {
    static let names = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "cyan", "mint", "indigo"]

    static func color(named name: String) -> Color {
        switch name {
        case "red": .red
        case "orange": .orange
        case "yellow": .yellow
        case "green": .green
        case "purple": .purple
        case "pink": .pink
        case "cyan": .cyan
        case "mint": .mint
        case "indigo": .indigo
        default: .blue
        }
    }
}
