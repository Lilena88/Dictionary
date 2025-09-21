//
//  TranslationViewModel.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//

import UIKit
import SwiftUI
import SQLite

/// A view model that manages dictionary translation data and provides
/// formatted display content with HTML rendering.
final class TranslationViewModel: ObservableObject, Identifiable {
    let dbManager: DatabaseManager
    private let translation: TranslationShort
    private let speechSynthesizer = SpeechSynthesizer()
    
    var id: String { translation.word }
    var word: String { translation.word }
    var shortTranslation: String { translation.formattedTranslation }
    
    @Published var fullTranslation: AttributedString = ""
    @Published private(set) var transcription: String = ""
    @Published var isExpanded: Bool = false {
        didSet {
            updateFullTranslation()
        }
    }
    
    init(translation: TranslationShort, dbManager: DatabaseManager) {
        self.translation = translation
        self.dbManager = dbManager
    }
    
    // MARK: - Translation Management
    
    private func updateFullTranslation() {
        guard isExpanded else {
            fullTranslation = ""
            return
        }
        
        let fullText = getFullTranslation()
        let htmlContent = HTMLProcessor.formatAsHTML(fullText, transcription: transcription)
        fullTranslation = HTMLProcessor.convertHTMLToAttributedString(htmlContent)
    }
    
    private func getFullTranslation() -> String {
        return translation.isRuDict 
            ? getRussianTranslation() 
            : getEnglishTranslation()
    }
    
    private func getRussianTranslation() -> String {
        guard let engWordsArray = getEnglishTranslations() else { return "" }
        
        return engWordsArray.compactMap { row in
            guard let engWord = row[0] as? String,
                  let translation = row[1] as? String else { return nil }
            
            let translatedArticle = extractTranslationForWord(translation, engWord: engWord)
            return "<LI>\(translatedArticle)</LI>"
        }.joined()
    }
    
    private func getEnglishTranslation() -> String {
        guard let result = dbManager.getFullTranslationAndTranscription(forWord: translation.word) else { 
            return "" 
        }
        
        self.transcription = result.transcription
        return result.translation
    }
    
    private func getEnglishTranslations() -> Statement? {
        let words = translation.shortTranslation.components(separatedBy: ",")
        return dbManager.getEnglishTranslationsForWords(words)
    }
    
    private func extractTranslationForWord(_ article: String, engWord: String) -> String {
        let pattern = "[^\n]*?\(translation.word)[^\n]*"
        
        if let match = RegexHelper.findMatch(pattern: pattern, in: article) {
            let cleanMatch = match
                .replacingOccurrences(of: "<P>", with: "")
                .replacingOccurrences(of: "</P>", with: "")
            return "\(engWord) ― \(cleanMatch)"
        }
        return engWord
    }
    
    // MARK: - Speech Synthesis
    
    func pronounceWord() {
        // Auto-detection inside synthesizer handles language; provide override only if needed.
        speechSynthesizer.pronounceWord(word, forceRussian: translation.isRuDict)
    }
}
