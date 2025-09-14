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
    let engRegex = "^[a-zA-Z]+$"
    let ruRegex = "^[а-яА-ЯёЁ]+$"
    let dbManager = DatabaseManager(databaseName: databaseName)
    private var currentText = ""
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

    func search(word: String) -> [TranslationShort] {
        var tableName: Dictionaries = .enRu
        if word.containsCyrillic {
            tableName = .ruEn
        }
        guard let words = dbManager.findRecordWithShortTranslation(tableName: tableName.rawValue, columnName: "word", searchValue: word) else { return [] }
        return words.map {
            return TranslationShort(isRuDict: word.containsCyrillic,
                                    id: $0[0] as? Int64 ?? 0,
                                    word: $0[1] as? String ?? "" ,
                                    shortTranslation: $0[2] as? String ?? "")
            
        }
        
    }
}
