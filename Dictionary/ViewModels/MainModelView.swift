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
    let dbManager = DatabaseManager(databaseName: databaseName)
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
            if translations.count == 1 {
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
        var tableName: Dictionaries = .enRu
        if word.containsCyrillic {
            tableName = .ruEn
        }
        guard let words = dbManager.findRecordWithShortTranslation(tableName: tableName.rawValue, columnName: "word", searchValue: word) else { return [] }
        return words.map {
            return TranslationShort(isRuDict: word.containsCyrillic,
                                    word: $0[0] as? String ?? "" ,
                                    shortTranslation: $0[1] as? String ?? "")
            
        }
        
    }
}
