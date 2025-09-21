//
//  TranslationViewModel.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//

import UIKit
import SwiftUI
import SQLite
import AVFoundation

/// A view model that manages dictionary translation data and provides
/// formatted display content with HTML rendering and speech synthesis.
final class TranslationViewModel: ObservableObject, Identifiable {
    let dbManager: DatabaseManager
    private let translation: TranslationShort
    
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
        guard let rows = dbManager.execute(sql: "SELECT translation, transcription FROM \(Dictionaries.enRu.rawValue) WHERE word = '\(translation.word)' LIMIT 1"),
              let firstRow = rows.makeIterator().next() else { return "" }
        
        let fullTranslation = firstRow[0] as? String ?? ""
        self.transcription = firstRow[1] as? String ?? ""
        return fullTranslation
    }
    
    private func getEnglishTranslations() -> Statement? {
        let words = translation.shortTranslation.components(separatedBy: ",")
        return dbManager.findTranslations(for: words)
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
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: word)
        
        utterance.voice = AVSpeechSynthesisVoice(
            language: translation.isRuDict ? "ru-RU" : "en-US"
        )
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}
