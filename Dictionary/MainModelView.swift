//
//  MainModelView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import Foundation
import SQLite

class MainModelView: ObservableObject {
    let dbManager = DatabaseManager(databaseName: "english-russian")
    
    func search(word: String) -> [Translation] {
        guard let firstLetter = word.first else { return [] }
        let tableName = "Caches\(firstLetter.uppercased())"
        return dbManager.findRecordInTable(tableName: tableName, columnName: "word", searchValue: word).sorted { $0.word.count < $1.word.count }
    }
    
    func fullTranslation(for word: Translation) -> String {
        let translation = dbManager.getFullTranslation(word: word)
        print("Full translations", translation)
        return translation ?? ""
    }
}
