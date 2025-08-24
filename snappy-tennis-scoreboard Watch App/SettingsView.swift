//
//  SettingsView.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 11/7/2025.
//

import SwiftUI

enum TieBreakRule: String, CaseIterable {
    case at66 = "6-6"
    case at55 = "5-5"
    case none = "None"
}

enum DeuceType: String, CaseIterable {
    case short = "Short Deuce"
    case long = "Long Deuce"
}

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chinese = "zh"
    case hindi = "hi"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .chinese: return "中文"
        case .hindi: return "हिन्दी"
        }
    }
}

struct LocalizedStrings {
    static func getString(_ key: String, language: Language) -> String {
        let translations: [Language: [String: String]] = [
            .english: [
                "game": "GAME",
                "set": "SET",
                "match": "MATCH",
                "player": "Player",
                "name": "Name",
                "color": "Color",
                "colour": "Color",
                "playOn": "Play On",
                "newGame": "New Game",
                "reset": "Reset Scores",
                "settings": "Settings",
                "numberOfSets": "Number of Sets",
                "tieBreakRule": "Tie-Break Rule",
                "playerNames": "Player Names",
                "language": "Language",
                "deuceType": "Deuce Type",
                "tapForOptions": "Tap for options",
                "wins": "wins!"
            ],
            .spanish: [
                "game": "JUEGO",
                "set": "SET",
                "match": "PARTIDO",
                "player": "Jugador",
                "name": "Nombre",
                "color": "Color",
                "colour": "Color",
                "playOn": "Continuar",
                "newGame": "Nuevo Juego",
                "reset": "Reiniciar Puntuación",
                "settings": "Configuración",
                "numberOfSets": "Número de Sets",
                "tieBreakRule": "Regla de Tie-Break",
                "playerNames": "Nombres de Jugadores",
                "language": "Idioma",
                "deuceType": "Tipo de Deuce",
                "tapForOptions": "Tocar para opciones",
                "wins": "¡gana!"
            ],
            .french: [
                "game": "JEU",
                "set": "SET",
                "match": "MATCH",
                "player": "Joueur",
                "name": "Nom",
                "color": "Couleur",
                "colour": "Couleur",
                "playOn": "Continuer",
                "newGame": "Nouveau Jeu",
                "reset": "Réinitialiser Scores",
                "settings": "Paramètres",
                "numberOfSets": "Nombre de Sets",
                "tieBreakRule": "Règle de Tie-Break",
                "playerNames": "Noms des Joueurs",
                "language": "Langue",
                "deuceType": "Type de Deuce",
                "tapForOptions": "Appuyer pour options",
                "wins": "gagne!"
            ],
            .german: [
                "game": "SPIEL",
                "set": "SATZ",
                "match": "MATCH",
                "player": "Spieler",
                "name": "Name",
                "color": "Farbe",
                "colour": "Farbe",
                "playOn": "Weiterspielen",
                "newGame": "Neues Spiel",
                "reset": "Punkte Zurücksetzen",
                "settings": "Einstellungen",
                "numberOfSets": "Anzahl der Sätze",
                "tieBreakRule": "Tie-Break-Regel",
                "playerNames": "Spielernamen",
                "language": "Sprache",
                "deuceType": "Deuce-Typ",
                "tapForOptions": "Für Optionen tippen",
                "wins": "gewinnt!"
            ],
            .italian: [
                "game": "GIOCO",
                "set": "SET",
                "match": "PARTITA",
                "player": "Giocatore",
                "name": "Nome",
                "color": "Colore",
                "colour": "Colore",
                "playOn": "Continuare",
                "newGame": "Nuova Partita",
                "reset": "Azzera Punteggi",
                "settings": "Impostazioni",
                "numberOfSets": "Numero di Set",
                "tieBreakRule": "Regola del Tie-Break",
                "playerNames": "Nomi Giocatori",
                "language": "Lingua",
                "deuceType": "Tipo di Deuce",
                "tapForOptions": "Tocca per opzioni",
                "wins": "vince!"
            ],
            .portuguese: [
                "game": "JOGO",
                "set": "SET",
                "match": "PARTIDA",
                "player": "Jogador",
                "name": "Nome",
                "color": "Cor",
                "colour": "Cor",
                "playOn": "Continuar",
                "newGame": "Novo Jogo",
                "reset": "Reiniciar Pontuação",
                "settings": "Configurações",
                "numberOfSets": "Número de Sets",
                "tieBreakRule": "Regra do Tie-Break",
                "playerNames": "Nomes dos Jogadores",
                "language": "Idioma",
                "deuceType": "Tipo de Deuce",
                "tapForOptions": "Toque para opções",
                "wins": "vence!"
            ],
            .chinese: [
                "game": "局",
                "set": "盘",
                "match": "比赛",
                "player": "选手",
                "name": "姓名",
                "color": "颜色",
                "colour": "颜色",
                "playOn": "继续比赛",
                "newGame": "新比赛",
                "reset": "重置比分",
                "settings": "设置",
                "numberOfSets": "盘数",
                "tieBreakRule": "抢七规则",
                "playerNames": "选手姓名",
                "language": "语言",
                "deuceType": "平分类型",
                "tapForOptions": "点击查看选项",
                "wins": "获胜！"
            ],
            .hindi: [
                "game": "गेम",
                "set": "सेट",
                "match": "मैच",
                "player": "खिलाड़ी",
                "name": "नाम",
                "color": "रंग",
                "colour": "रंग",
                "playOn": "जारी रखें",
                "newGame": "नया गेम",
                "reset": "स्कोर रीसेट करें",
                "settings": "सेटिंग्स",
                "numberOfSets": "सेटों की संख्या",
                "tieBreakRule": "टाई-ब्रेक नियम",
                "playerNames": "खिलाड़ियों के नाम",
                "language": "भाषा",
                "deuceType": "ड्यूस प्रकार",
                "tapForOptions": "विकल्पों के लिए टैप करें",
                "wins": "जीत गया!"
            ]
        ]
        
        return translations[language]?[key] ?? translations[.english]?[key] ?? key
    }
}

struct SettingsView: View {
    @Binding var player1Name: String
    @Binding var player2Name: String
    @Binding var player1Color: Color
    @Binding var player2Color: Color
    @Binding var setsToPlay: Int
    @Binding var tieBreakRule: TieBreakRule
    @Binding var deuceType: DeuceType
    @Binding var language: Language
    
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let colorOptions: [Color] = [ .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .indigo]
    
    var body: some View {
        NavigationView {
            List {
                Section(LocalizedStrings.getString("numberOfSets", language: language)) {
                        HStack(spacing: 12) {
                            ForEach([1, 3, 5], id: \.self) { setCount in
                                Button(action: {
                                    setsToPlay = setCount
                                }) {
                                    Text("\(setCount)")
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(setsToPlay == setCount ? .bold : .regular)
                                        .foregroundColor(setsToPlay == setCount ? .white : .secondary)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(setsToPlay == setCount ? Color.blue : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                }
                
                Section(LocalizedStrings.getString("tieBreakRule", language: language)) {
                    VStack(spacing: 8) {
                        ForEach(TieBreakRule.allCases, id: \.self) { rule in
                            Button(action: {
                                tieBreakRule = rule
                            }) {
                                HStack {
                                    Text(rule.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if tieBreakRule == rule {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(LocalizedStrings.getString("deuceType", language: language)) {
                    VStack(spacing: 8) {
                        ForEach(DeuceType.allCases, id: \.self) { type in
                            Button(action: {
                                deuceType = type
                            }) {
                                HStack {
                                    Text(type.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if deuceType == type {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        onReset()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(LocalizedStrings.getString("reset", language: language))
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("\(player1Name) \(LocalizedStrings.getString("colour", language: language))") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: player1Color == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    player1Color = color
                                }
                        }
                    }
                }
                
                Section("\(player2Name) \(LocalizedStrings.getString("colour", language: language))") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: player2Color == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    player2Color = color
                                }
                        }
                    }
                }
                
                Section(LocalizedStrings.getString("playerNames", language: language)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(LocalizedStrings.getString("player", language: language)) 1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("\(LocalizedStrings.getString("player", language: language)) 1", text: $player1Name)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(LocalizedStrings.getString("player", language: language)) 2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("\(LocalizedStrings.getString("player", language: language)) 2", text: $player2Name)
                    }
                }
                
                Section(LocalizedStrings.getString("language", language: language)) {
                    VStack(spacing: 8) {
                        ForEach(Language.allCases) { lang in
                            Button(action: {
                                language = lang
                            }) {
                                HStack {
                                    Text(lang.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if language == lang {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                

            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
