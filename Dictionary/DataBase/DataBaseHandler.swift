//
//  DataBaseHandler.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import Foundation
import SQLite

class DatabaseManager {
    var db: Connection

    init(databaseName: String) {
        do {
            guard let dbPath = Bundle.main.path(forResource: databaseName, ofType: "sqlite3") else {
                fatalError("Database file not found in the resources.")
            }
            self.db = try Connection(dbPath)
        } catch {
            fatalError("Error connecting to the database: \(error)")
        }
    }

    // Метод для поиска записи в таблице
    func findRecordInTable(tableName: String, columnName: String, searchValue: String) -> [Translation] {
        do {
            let table = Table(tableName)
            let column = Expression<String>(columnName)
            var translations: [Translation] = []
            let query = table.filter(column.like("\(searchValue)%")).limit(100)
            let records = try db.prepare(query)
            for record in records {
                let translation = Translation(
                    id: record[Expression<Int>("id")],
                    word: record[column],
                    translationShort: record[Expression<String>("translationShort")],
                    translationId: record[Expression<Int>("translationId")])
                translations.append(translation)
                
            }
            return translations
        } catch {
            print("Error finding records: \(error)")
            return []
        }
    }
    
    func getFullTranslation(word: Translation) -> String? {
        print(#function)
        let table = Table("Translations")
        let column = Expression<Int>("id")
        let query = table.filter(word.translationId == column)
        
        do {
            guard let record = try db.pluck(query) else { 
                print("Error to catch full translation")
                return nil }
            return record[Expression<String>("translation")]
        } catch {
            print("Error to catch full translation", error)
            return nil
        }
    }
}

struct Translation {
    let id: Int
    let word: String
    let translationShort: String
    let translationId: Int
}
