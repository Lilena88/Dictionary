//
//  DatabaseManager.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import Foundation
import SQLite

/// Manages SQLite database operations for the dictionary app
final class DatabaseManager {
    private let db: Connection
    
    init(databaseName: String) throws {
        guard let dbPath = Bundle.main.path(forResource: databaseName, ofType: "sqlite3") else {
            throw DatabaseError.fileNotFound
        }
        self.db = try Connection(dbPath)
    }
    
    /// Executes raw SQL query
    func execute(sql: String) -> Statement? {
        do {
            print("Executing SQL: \(sql)")
            return try db.prepare(sql)
        } catch {
            print("SQL error: \(error)")
            return nil
        }
    }
    
    /// Finds translations for multiple words
    func findTranslations(for words: [String]) -> Statement? {
        let wordList = words.joined(separator: "\",\"")
        return execute(sql: """
            SELECT word, translation
            FROM enRu
            WHERE word IN ("\(wordList)")
            ORDER BY instr(",\(words.joined(separator: ",")),", ',' || word || ',')
            """)
    }
    
    /// Searches with fuzzy matching (tries progressively shorter strings)
    func fuzzySearch(in tableName: String, for searchValue: String) -> Statement? {
        let cleanValue = searchValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard cleanValue.count > 2 else {
            return findExactMatch(in: tableName, for: cleanValue)
        }
        
        // Try exact match first
        var result = findExactMatch(in: tableName, for: cleanValue)
        if hasResults(result) { return result }
        
        // Try with one character removed
        result = findExactMatch(in: tableName, for: String(cleanValue.dropLast()))
        if hasResults(result) { return result }
        
        // Try with two characters removed
        return findExactMatch(in: tableName, for: String(cleanValue.dropLast(2)))
    }
    
    private func findExactMatch(in tableName: String, for searchValue: String) -> Statement? {
        return execute(sql: """
            SELECT word, SUBSTR(translation, 1, 100) AS translation
            FROM \(tableName)
            WHERE word LIKE '\(searchValue)%'
            LIMIT 100
            """)
    }
    
    private func hasResults(_ statement: Statement?) -> Bool {
        guard let statement = statement else { return false }
        return statement.makeIterator().next() != nil
    }
}

// MARK: - Database Error
enum DatabaseError: Error {
    case fileNotFound
    case connectionFailed
}
// MARK: - Translation Models
struct Translation {
    let isRuDict: Bool
    let word: String
    let translation: String
    let transcription: String
    
    var shortTranslation: String {
        translation.prefix(100)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

struct TranslationShort {
    let isRuDict: Bool
    let word: String
    let shortTranslation: String
    
    var formattedTranslation: String {
        shortTranslation
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ", ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}
