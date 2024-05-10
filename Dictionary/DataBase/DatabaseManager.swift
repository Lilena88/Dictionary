//
//  DatabaseManager.swift
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
    
    func fetchRows(sql: String) -> Statement? {
        do {
            let results = try db.prepare(sql)
            return results
        } catch {
            print("[fetchRows] error: \(error) sql: \(sql)")
            return nil
        }
    }
    
    func findMultipleValues(words: [String]) -> Statement? {
        return fetchRows(sql: """
        select id, word, translation
        from enRu
        where word IN ("\(words.joined(separator: "\",\""))")
        order by instr(",\(words.joined(separator: ",")),",     ',' || word || ',');
        """)
    }
    
    func findRecordWithShortTranslation(tableName: String, columnName: String, searchValue: String) -> Statement? {
        let preparedValue = searchValue
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        var result = findByWordWithShortTranslation(tableName: tableName, searchValue: searchValue)
        
        if preparedValue.count <= 2 {
            return result
        }
        
        if (result?.reduce(0) { $0 + $1.count } ?? 0) == 0 {
            result = findByWordWithShortTranslation(tableName: tableName, searchValue: substr(string: preparedValue, endOffset: -1))
        }
        
        if (result?.reduce(0) { $0 + $1.count } ?? 0) == 0 {
            result = findByWordWithShortTranslation(tableName: tableName, searchValue: substr(string: preparedValue, endOffset: -2))
        }
        
        return result
    }
    
    func substr(string: String, endOffset: Int) -> String {
        let endIndex = string.index(string.endIndex, offsetBy: endOffset)
        return String(string[..<endIndex])
    }
    
    func findByWordWithShortTranslation(tableName: String, searchValue: String) -> Statement? {
        return fetchRows(sql: """
           SELECT id, word, substr(translation, 0, 100) AS shortTranslation
           FROM \(tableName)
           WHERE word LIKE '\(searchValue)%'
           LIMIT 100
           """)
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
    var shortTranslationEdited: String {
        return shortTranslation
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ", ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}
