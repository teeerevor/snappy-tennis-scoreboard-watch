//
//  GameAnnouncementView.swift
//  You cannot be serious Watch App
//
//  Created by aldus on 11/7/2025.
//

import SwiftUI

enum CelebrationType {
    case game
    case set
    case match
    
    func words(language: Language) -> [String] {
        switch self {
        case .game:
            return [LocalizedStrings.getString("game", language: language)]
        case .set:
            return [LocalizedStrings.getString("game", language: language), LocalizedStrings.getString("set", language: language)]
        case .match:
            return [LocalizedStrings.getString("game", language: language), LocalizedStrings.getString("set", language: language), LocalizedStrings.getString("match", language: language)]
        }
    }
}

func fontSizeAnnouncementText() -> CGFloat {
    let width = WKInterfaceDevice.current().screenBounds.width
    switch width {
    case 198...: // Ultra 49mm
        return 50
    case 184...: // 45/44mm
        return 50
    default: // 42/40/38mm and others
        return 40
    }
}

struct GameAnnouncementView: View {
    let celebrationType: CelebrationType
    let language: Language
    let onDismiss: () -> Void
    
    @State private var currentWordIndex = 0
    @State private var wordOpacity: Double = 0.0
    @State private var wordOffset: CGFloat = -50
    
    private let words: [String]
    
    init(celebrationType: CelebrationType, language: Language, onDismiss: @escaping () -> Void) {
        self.celebrationType = celebrationType
        self.language = language
        self.onDismiss = onDismiss
        self.words = celebrationType.words(language: language)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            if currentWordIndex < words.count {
                Text(words[currentWordIndex])
                    .font(.system(size:fontSizeAnnouncementText()))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .opacity(wordOpacity)
                    .offset(y: wordOffset - 20)
            }
        }
        .onAppear {
            showNextWord()
        }
        .interactiveDismissDisabled()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
    }
    
    private func showNextWord() {
        guard currentWordIndex < words.count else {
            // All words shown, start dismissing
            withAnimation(.easeInOut(duration: 0.3)) {
                wordOpacity = 0.0
                wordOffset = 50
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
            return
        }
        
        // Animate word in
        withAnimation(.easeOut(duration: 0.4)) {
            wordOpacity = 1.0
            wordOffset = 0
        }
        
        // Hold for a moment, then fade out and show next word
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                wordOpacity = 0.0
                wordOffset = 50
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentWordIndex += 1
                wordOffset = -50
                showNextWord()
            }
        }
    }
}

#Preview {
    GameAnnouncementView(
        celebrationType: .match,
        language: .english,
        onDismiss: {}
    )
}
