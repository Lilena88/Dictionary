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
    
    func findRecordInTable<T>(tableName: String, columnName: String, searchValue: T) -> [Row] {
        do {
            let table = Table(tableName)
            let column = Expression<String>(columnName)
            let query = table.filter(column.like("\(searchValue)%")).limit(100)
            return try Array(db.prepare(query))
        } catch {
            print("Error finding records: \(error)")
            return []
        }
    }
    
    func findMultipleValues(tableName: String, columnName: String, searchValues: [String]) -> [Row] {
        do {
            let table = Table(tableName)
            let column = Expression<String>(columnName)
            
            let query = table.filter(searchValues.contains(column))
            return try Array(db.prepare(query))
        } catch {
            print("Error finding multiple values: \(error)")
            return []
        }
    }
    //new
    func findRecordWithShortTranslation(tableName: String, columnName: String, searchValue: String) -> Statement? {
        do {
            let query = """
           SELECT id, word, substr(translation, 0, 100) AS shortTranslation
           FROM \(tableName)
           WHERE word LIKE '\(searchValue)%'
           LIMIT 100
           """
            let results = try db.prepare(query)
            return results
        } catch {
            print("Database error: \(error)")
            return nil
        }
    }
}

struct Translation {
    let isRuDict: Bool
    let id: Int
    let word: String
    let translation: String
    let transcription: String
    var translationShort: String {
        return String(translation.prefix(100)).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

struct TranslationShort {
    let isRuDict: Bool
    let id: Int64
    let word: String
    let shortTranslation: String
}
