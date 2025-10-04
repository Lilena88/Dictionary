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
    var word: String { translation.displayWord }
    var actualWord: String { translation.word }
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
            
            let stress = row[2] as? String
            let displayWord = stress ?? engWord
            
            let translatedArticles = extractAllTranslationsForWord(translation, engWord: engWord, displayWord: displayWord)
            return translatedArticles.joined()
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
    
    private func extractAllTranslationsForWord(_ article: String, engWord: String, displayWord: String) -> [String] {
        // First, extract all <P>...</P> blocks
        let allPBlocksPattern = "<P>.*?</P>"
        let allPBlocks = RegexHelper.findAllMatches(pattern: allPBlocksPattern, in: article)
        
        // Filter blocks that contain the target word at the beginning with word boundaries
        let matchingBlocks = allPBlocks.filter { pBlock in
            // Remove <P> tag to get the content
            let content = pBlock.replacingOccurrences(of: "<P>", with: "")
            
            // Check if the word appears at the beginning of the content with word boundary
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: translation.word))\\b"
            return RegexHelper.findMatch(pattern: pattern, in: content) != nil
        }
        
        if matchingBlocks.isEmpty {
            return ["<LI>\(displayWord)</LI>"]
        }
        
        return matchingBlocks.map { pBlock in
            // Remove the outer <P> and </P> tags
            let content = "\(displayWord) ― \(pBlock)"
                .replacingOccurrences(of: "<P>", with: "")
                .replacingOccurrences(of: "</P>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return "<LI>\(content)</LI>"
        }
    }
    
    // MARK: - Speech Synthesis
    
    func pronounceWord() {
        // Use the actual word (without stress marks) for pronunciation
        speechSynthesizer.pronounceWord(actualWord, forceRussian: translation.isRuDict)
    }
}
