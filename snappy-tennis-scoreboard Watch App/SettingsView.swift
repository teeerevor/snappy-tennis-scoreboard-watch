//
//  SettingsView.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 11/7/2025.
//

import SwiftUI
import TennisScoring

enum ServerSetting: String, CaseIterable {
    case player1 = "Player 1"
    case player2 = "Player 2"
    case off = "Off"
}

enum DisplayMode: String, CaseIterable {
    case `static` = "Static"
    case readable = "Readable"
}

enum PlayMode: String, CaseIterable {
    case match = "Match"
    case practice = "Practice"
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
                "newMatch": "New Match",
                "start": "Start",
                "sides": "Sides",
                "serves": "serves",
                "trackServe": "Track serve",
                "server": "Server",
                "receiver": "Receiver",
                "settings": "Settings",
                "numberOfSets": "Number of Sets",
                "tieBreakRule": "Tie-Break Rule",
                "playerNames": "Player Names",
                "language": "Language",
                "deuceType": "Deuce Type",
                "serverSetting": "Server",
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
                "newMatch": "Nuevo Partido",
                "start": "Empezar",
                "sides": "Lados",
                "serves": "saca",
                "trackServe": "Seguir el saque",
                "server": "Sacador",
                "receiver": "Restador",
                "settings": "Configuración",
                "numberOfSets": "Número de Sets",
                "tieBreakRule": "Regla de Tie-Break",
                "playerNames": "Nombres de Jugadores",
                "language": "Idioma",
                "deuceType": "Tipo de Deuce",
                "serverSetting": "Servidor",
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
                "newMatch": "Nouveau Match",
                "start": "Commencer",
                "sides": "Côtés",
                "serves": "sert",
                "trackServe": "Suivre le service",
                "server": "Serveur",
                "receiver": "Relanceur",
                "settings": "Paramètres",
                "numberOfSets": "Nombre de Sets",
                "tieBreakRule": "Règle de Tie-Break",
                "playerNames": "Noms des Joueurs",
                "language": "Langue",
                "deuceType": "Type de Deuce",
                "serverSetting": "Serveur",
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
                "newMatch": "Neues Match",
                "start": "Starten",
                "sides": "Seiten",
                "serves": "schlägt auf",
                "trackServe": "Aufschlag verfolgen",
                "server": "Aufschläger",
                "receiver": "Rückschläger",
                "settings": "Einstellungen",
                "numberOfSets": "Anzahl der Sätze",
                "tieBreakRule": "Tie-Break-Regel",
                "playerNames": "Spielernamen",
                "language": "Sprache",
                "deuceType": "Deuce-Typ",
                "serverSetting": "Aufschläger",
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
                "newMatch": "Nuova Partita",
                "start": "Inizia",
                "sides": "Lati",
                "serves": "serve",
                "trackServe": "Segna il servizio",
                "server": "Battitore",
                "receiver": "Ribattitore",
                "settings": "Impostazioni",
                "numberOfSets": "Numero di Set",
                "tieBreakRule": "Regola del Tie-Break",
                "playerNames": "Nomi Giocatori",
                "language": "Lingua",
                "deuceType": "Tipo di Deuce",
                "serverSetting": "Servizio",
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
                "newMatch": "Nova Partida",
                "start": "Começar",
                "sides": "Lados",
                "serves": "saca",
                "trackServe": "Controlar o saque",
                "server": "Sacador",
                "receiver": "Recetor",
                "settings": "Configurações",
                "numberOfSets": "Número de Sets",
                "tieBreakRule": "Regra do Tie-Break",
                "playerNames": "Nomes dos Jogadores",
                "language": "Idioma",
                "deuceType": "Tipo de Deuce",
                "serverSetting": "Servidor",
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
                "newMatch": "新比赛",
                "start": "开始",
                "sides": "场地",
                "serves": "发球",
                "trackServe": "记录发球",
                "server": "发球方",
                "receiver": "接发球方",
                "settings": "设置",
                "numberOfSets": "盘数",
                "tieBreakRule": "抢七规则",
                "playerNames": "选手姓名",
                "language": "语言",
                "deuceType": "平分类型",
                "serverSetting": "发球方",
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
                "newMatch": "नया मैच",
                "start": "शुरू करें",
                "sides": "साइड",
                "serves": "सर्व करेगा",
                "trackServe": "सर्व ट्रैक करें",
                "server": "सर्वर",
                "receiver": "रिसीवर",
                "settings": "सेटिंग्स",
                "numberOfSets": "सेटों की संख्या",
                "tieBreakRule": "टाई-ब्रेक नियम",
                "playerNames": "खिलाड़ियों के नाम",
                "language": "भाषा",
                "deuceType": "ड्यूस प्रकार",
                "serverSetting": "सर्वर",
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
    @Binding var displayMode: DisplayMode
    @Binding var playMode: PlayMode

    @Binding var tracksServe: Bool

    // Changed only by starting a New Match (or turning serve tracking on/off)
    let serverSetting: ServerSetting
    let player1OnLeft: Bool
    let onNewMatch: (ServerSetting, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    let colorOptions: [Color] = [ .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .indigo]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        NewMatchView(
                            player1Name: player1Name,
                            player2Name: player2Name,
                            player1Color: player1Color,
                            player2Color: player2Color,
                            playMode: playMode,
                            language: language,
                            serverSetting: serverSetting,
                            player1OnLeft: player1OnLeft,
                            onStart: { server, onLeft in
                                onNewMatch(server, onLeft)
                                dismiss()
                            }
                        )
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(LocalizedStrings.getString("newMatch", language: language))
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("button.newMatch")
                }

                Section("Mode") {
                    HStack(spacing: 12) {
                        ForEach(PlayMode.allCases, id: \.self) { mode in
                            Button(action: {
                                playMode = mode
                            }) {
                                Text(mode.rawValue)
                                    .font(.body)
                                    .fontWeight(playMode == mode ? .bold : .regular)
                                    .foregroundColor(playMode == mode ? .white : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(playMode == mode ? Color.blue : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                if playMode == .match {
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

                Section(LocalizedStrings.getString("serverSetting", language: language)) {
                    Toggle(LocalizedStrings.getString("trackServe", language: language), isOn: $tracksServe)
                        .accessibilityIdentifier("settings.trackServe")
                }

                if serverSetting != .off {
                    Section("Display Mode") {
                        VStack(spacing: 8) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    displayMode = mode
                                }) {
                                    HStack {
                                        Text(mode.rawValue)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if displayMode == mode {
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
                } // end if playMode == .match

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
