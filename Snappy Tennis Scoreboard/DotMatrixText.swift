//
//  DotMatrixText.swift
//  Snappy Tennis Scoreboard
//

import SwiftUI

/// Text lit up in dots, like the lettering on an old courtside scoreboard: five dots wide, seven tall.
struct DotMatrixText: View {
    let text: String
    /// The distance between dot centres.
    let pitch: CGFloat
    /// Empty columns between characters.
    var gap = 2
    var color: Color = .white

    var body: some View {
        Group {
            if let glyphs = DotMatrixFont.glyphs(for: text) {
                let columns = max(glyphs.count * (5 + gap) - gap, 0)
                Canvas { context, _ in
                    var dots = Path()
                    for (index, glyph) in glyphs.enumerated() {
                        for (row, bits) in glyph.enumerated() {
                            for column in 0..<5 where bits & (0b10000 >> column) != 0 {
                                let x = CGFloat(index * (5 + gap) + column) * pitch
                                dots.addEllipse(in: CGRect(x: x, y: CGFloat(row) * pitch, width: pitch, height: pitch)
                                    .insetBy(dx: pitch * 0.14, dy: pitch * 0.14))
                            }
                        }
                    }
                    context.fill(dots, with: .color(color))
                }
                .frame(width: CGFloat(columns) * pitch, height: 7 * pitch)
            } else {
                // A name in a script the dot font doesn't have is still lit in dots, from the system font
                let label = Text(text.uppercased()).font(.system(size: 6 * pitch, weight: .heavy, design: .rounded))
                label.hidden()
                    .overlay { DotGrid(pitch: pitch * 0.7, dotSize: pitch * 0.55).fill(color).mask { label } }
                    // The same height as the dot font, so both rows of the board stay level
                    .frame(height: 7 * pitch)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(text)
    }
}

/// Dot-matrix text shrunk until it fits the width it's given, for Player names of any length.
struct FittingDotMatrixText: View {
    let text: String
    let pitch: CGFloat
    var color: Color = .white

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach([1, 0.85, 0.7, 0.55], id: \.self) { scale in
                DotMatrixText(text: text, pitch: pitch * scale, color: color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

/// An even grid of dots, for unlit scoreboard bulbs.
struct DotGrid: Shape {
    let pitch: CGFloat
    let dotSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = (pitch - dotSize) / 2
        var y = rect.minY
        while y < rect.maxY {
            var x = rect.minX
            while x < rect.maxX {
                path.addEllipse(in: CGRect(x: x + inset, y: y + inset, width: dotSize, height: dotSize))
                x += pitch
            }
            y += pitch
        }
        return path
    }
}

/// The scoreboard's characters, one 5-bit row per line from the top.
private enum DotMatrixFont {
    /// Nil when the text has a character the font doesn't have.
    static func glyphs(for text: String) -> [[UInt8]]? {
        let folded = text.folding(options: .diacriticInsensitive, locale: nil).uppercased()
        var glyphs: [[UInt8]] = []
        for character in folded {
            guard let glyph = font[character] else { return nil }
            glyphs.append(glyph)
        }
        return glyphs
    }

    private static let font: [Character: [UInt8]] = [
        "A": [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "B": [0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110],
        "C": [0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110],
        "D": [0b11100, 0b10010, 0b10001, 0b10001, 0b10001, 0b10010, 0b11100],
        "E": [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111],
        "F": [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000],
        "G": [0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01111],
        "H": [0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "I": [0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
        "J": [0b00111, 0b00010, 0b00010, 0b00010, 0b00010, 0b10010, 0b01100],
        "K": [0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001],
        "L": [0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111],
        "M": [0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001],
        "N": [0b10001, 0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001],
        "O": [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
        "P": [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000],
        "Q": [0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101],
        "R": [0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001],
        "S": [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110],
        "T": [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100],
        "U": [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
        "V": [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100],
        "W": [0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010],
        "X": [0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001],
        "Y": [0b10001, 0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100],
        "Z": [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111],
        "0": [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
        "1": [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
        "2": [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111],
        "3": [0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110],
        "4": [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010],
        "5": [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110],
        "6": [0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110],
        "7": [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000],
        "8": [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110],
        "9": [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100],
        " ": [0, 0, 0, 0, 0, 0, 0],
        "-": [0, 0, 0, 0b11111, 0, 0, 0],
        ".": [0, 0, 0, 0, 0, 0b01100, 0b01100],
        ",": [0, 0, 0, 0, 0b01100, 0b00100, 0b01000],
        "'": [0b01100, 0b00100, 0b01000, 0, 0, 0, 0],
        "’": [0b01100, 0b00100, 0b01000, 0, 0, 0, 0],
        "&": [0b01100, 0b10010, 0b10100, 0b01000, 0b10101, 0b10010, 0b01101],
        "/": [0, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0],
    ]
}
