//
//  PlayerFields.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI
import TennisScoring

/// A Player's name and colour, as set on New Match and in Settings.
struct PlayerFields: View {
    @Binding var player: PlayerInfo
    let placeholder: String
    /// For the colour menu.
    let accessibilityID: String

    var body: some View {
        HStack {
            TextField(placeholder, text: $player.name)
                .textInputAutocapitalization(.words)
            colorMenu
                .accessibilityIdentifier(accessibilityID)
        }
    }

    /// A Menu with its own label: a menu-style Picker draws its label itself, keeping the first
    /// colour and jumping in width each time the name changes.
    private var colorMenu: some View {
        let color = PlayerColor.color(named: player.colorName)
        return Menu {
            Picker(placeholder, selection: $player.colorName) {
                ForEach(PlayerColor.names, id: \.self) { name in
                    Label {
                        Text(name.capitalized)
                    } icon: {
                        // Menu items draw images in one tint unless the colour is baked in
                        Image(uiImage: Self.swatch(PlayerColor.color(named: name)))
                    }
                    .tag(name)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                Text(player.colorName.capitalized)
                    // Wide enough for every name, so the row doesn't resize
                    .frame(minWidth: 84, alignment: .leading)
                    .contentTransition(.opacity)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(color)
            .animation(.easeInOut(duration: 0.2), value: player.colorName)
        }
        .accessibilityLabel("\(placeholder) colour")
        .accessibilityValue(player.colorName.capitalized)
    }

    private static func swatch(_ color: Color) -> UIImage {
        let image = UIImage(systemName: "circle.fill") ?? UIImage()
        return image.withTintColor(UIColor(color), renderingMode: .alwaysOriginal)
    }
}
