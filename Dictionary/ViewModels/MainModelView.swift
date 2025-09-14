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
//                vm.isExpanded = searchResult.count == 1  сразу развернеть если результат поиска состоит из одного значения
                return vm
            }
        }
    }
    @Published var translations: [TranslationViewModel] = []
    var history: [String] = []
    
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
