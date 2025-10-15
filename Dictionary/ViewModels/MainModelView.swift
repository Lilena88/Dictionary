//
//  MainModelView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import Foundation
import SwiftUI
import SQLite
import NaturalLanguage

let databaseName = "dict"
enum Dictionaries: String {
    case enRu
    case ruEn
}

class MainModelView: ObservableObject {
    static let lastSearchKey = "LastSearchedWord"
    static let recentSearchesKey = "RecentSearches"
    let engRegex = "^[a-zA-Z]+$"
    let ruRegex = "^[а-яА-ЯёЁ]+$"
    
    lazy var dbManager: DatabaseManager = {
        do {
            return try DatabaseManager(databaseName: databaseName)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }()
    
    private var currentText = ""
    // Simple score that can be incremented by user interactions
    @Published var score: Int = 0
    @Published var searchText = "" {
        didSet {
            guard searchText != currentText else {
                return
            }
            currentText = searchText
            if history.isEmpty {
                self.history.append(searchText)
            } else if history.last != searchText {
                self.history.append(searchText)
            }
            
            let searchResult = self.search(word: searchText)
            translations = searchResult.map {
                let vm = TranslationViewModel(translation: $0, dbManager: self.dbManager)
                return vm
            }
            
            // Expand word if there's a full match with searched word or only one result
            if let exactMatch = findExactMatch(searchTerm: searchText, in: translations) {
                exactMatch.isExpanded = true
            } else if translations.count == 1 {
                translations[0].isExpanded = true
            }

            // Persist last non-empty search
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: Self.lastSearchKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: Self.lastSearchKey)
            }
        }
    }
    @Published var translations: [TranslationViewModel] = []
    var history: [String] = []
    @Published var recentSearches: [String] = []
    private let maxRecentCount = 20

    init() {
        loadRecentSearches()
    }
    
    // Convenience initializer for preview mode
    init(previewData: Bool) {
        if previewData {
            recentSearches = [
                "hello",
                "привет", 
                "world",
                "мир",
                "tree",
                "красивый",
                "language",
                "язык",
                "dictionary",
                "словарь"
            ]
        } else {
            loadRecentSearches()
        }
    }

    // MARK: - Score
    func incrementScore(by amount: Int = 1) {
        guard amount != 0 else { return }
        score += amount
    }
    
    // Load initial list on app start (empty request)
    func loadInitial() {
        let searchResult = self.search(word: "")
        translations = searchResult.map {
            let vm = TranslationViewModel(translation: $0, dbManager: self.dbManager)
            return vm
        }
        if translations.count == 1 {
            translations[0].isExpanded = true
        }
    }

    // Load the last searched word if available; otherwise show initial list
    func restoreLastSearchOrInitial() {
        if let last = UserDefaults.standard.string(forKey: Self.lastSearchKey), !last.isEmpty {
            self.searchText = last
        } else {
            loadInitial()
        }
    }

    // MARK: - Recents
    func commitSearch(_ term: String? = nil) {
        let raw = term ?? self.searchText
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = recentSearches.firstIndex(of: trimmed) {
            recentSearches.remove(at: idx)
        }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > maxRecentCount {
            recentSearches = Array(recentSearches.prefix(maxRecentCount))
        }
        saveRecentSearches()
        UserDefaults.standard.set(trimmed, forKey: Self.lastSearchKey)
    }

    private func loadRecentSearches() {
        if let arr = UserDefaults.standard.array(forKey: Self.recentSearchesKey) as? [String] {
            recentSearches = arr
        }
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
    }

    func search(word: String) -> [TranslationShort] {
        // If input contains Cyrillic, search Russian dictionary
        if word.containsCyrillic {
            return dbManager.searchWordsWithFuzzyMatching(in: Dictionaries.ruEn.rawValue, searchTerm: word)
        }
        
        // For Latin input, check if it might be transliterated Russian
        if TransliterationDetector.looksLikeTransliteration(word) {
            // Try transliterating to Cyrillic and searching Russian dictionary
            let cyrillicVariants = TransliterationDetector.transliterateToCyrillic(word)
            
            for variant in cyrillicVariants {
                let results = dbManager.searchWordsWithFuzzyMatching(
                    in: Dictionaries.ruEn.rawValue, 
                    searchTerm: variant
                )
                if !results.isEmpty {
                    return results
                }
            }
        }
        
        // Default: search English dictionary
        return dbManager.searchWordsWithFuzzyMatching(in: Dictionaries.enRu.rawValue, searchTerm: word)
    }
    
    // MARK: - Helper Methods
    
    /// Finds an exact match for the search term in the translations list
    private func findExactMatch(searchTerm: String, in translations: [TranslationViewModel]) -> TranslationViewModel? {
        let cleanSearchTerm = searchTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSearchTerm.isEmpty else { return nil }
        
        return translations.first { translation in
            translation.actualWord.lowercased() == cleanSearchTerm
        }
    }
}
