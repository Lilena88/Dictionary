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
    
    // MARK: - Private SQL Execution
    
    /// Executes raw SQL query - internal use only
    private func execute(sql: String) -> Statement? {
        do {
            print("Executing SQL: \(sql)")
            return try db.prepare(sql)
        } catch {
            print("SQL error: \(error)")
            return nil
        }
    }
    
    /// Escapes single quotes in SQL string literals to prevent syntax errors
    private func escapeSQLString(_ string: String) -> String {
        return string.replacingOccurrences(of: "'", with: "''")
    }
    
    // MARK: - Public Database Operations
    
    /// Searches for words with fuzzy matching support
    func searchWordsWithFuzzyMatching(in tableName: String, searchTerm: String) -> [TranslationShort] {
        let cleanValue = searchTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isRuDict = searchTerm.containsCyrillic
        
        guard cleanValue.count > 2 else {
            return getExactWordMatches(in: tableName, searchTerm: cleanValue, isRuDict: isRuDict)
        }
        
        // Try exact match first
        var results = getExactWordMatches(in: tableName, searchTerm: cleanValue, isRuDict: isRuDict)
        if !results.isEmpty { return results }
        
        // Try with one character removed
        results = getExactWordMatches(in: tableName, searchTerm: String(cleanValue.dropLast()), isRuDict: isRuDict)
        if !results.isEmpty { return results }
        
        // Try with two characters removed
        return getExactWordMatches(in: tableName, searchTerm: String(cleanValue.dropLast(2)), isRuDict: isRuDict)
    }
    
    /// Gets exact word matches for the given search term
    func getExactWordMatches(in tableName: String, searchTerm: String, isRuDict: Bool) -> [TranslationShort] {
        let escapedSearchTerm = escapeSQLString(searchTerm)
        
        // If no search term, sort by popularity; otherwise sort alphabetically
        let orderClause = searchTerm.isEmpty
        ? "ORDER BY popularity DESC, LENGTH(word), word COLLATE NOCASE"
        : "ORDER BY word COLLATE NOCASE"
        
        guard let statement = execute(sql: """
            SELECT word, SUBSTR(translation, 1, 100) AS translation, stress, popularity
            FROM \(tableName)
            WHERE word LIKE '\(escapedSearchTerm)%'
            \(orderClause)
            LIMIT 100
            """) else { return [] }
        
        return statement.map { row in
            TranslationShort(
                isRuDict: isRuDict,
                word: row[0] as? String ?? "",
                shortTranslation: row[1] as? String ?? "",
                stress: row[2] as? String,
                popularity: row[3] as? Double
            )
        }
    }
    
    /// Finds English translations for multiple Russian words
    func getEnglishTranslationsForWords(_ words: [String]) -> Statement? {
        let escapedWords = words.map { escapeSQLString($0) }
        let wordList = escapedWords.joined(separator: "\",\"")
        return execute(sql: """
            SELECT word, translation, stress
            FROM enRu
            WHERE word IN ("\(wordList)")
            ORDER BY instr(",\(words.joined(separator: ",")),", ',' || word || ',')
            """)
    }
    
    /// Gets full translation and transcription for a specific English word
    func getFullTranslationAndTranscription(forWord word: String) -> (translation: String, transcription: String)? {
        let escapedWord = escapeSQLString(word)
        guard let statement = execute(sql: """
            SELECT translation, transcription 
            FROM enRu 
            WHERE word = '\(escapedWord)' 
            LIMIT 1
            """),
              let firstRow = statement.makeIterator().next() else { return nil }
        
        let translation = firstRow[0] as? String ?? ""
        let transcription = firstRow[1] as? String ?? ""
        return (translation: translation, transcription: transcription)
    }
    
    // MARK: - Helper Methods
    
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
    let stress: String?
    let popularity: Double?
    
    var displayWord: String {
        stress ?? word
    }
    
    var formattedTranslation: String {
        shortTranslation
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ", ")
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    /// Returns the number of stars (0-3) based on frequency per million words
    var popularityStars: Int {
        guard let frequency = popularity, frequency > 0 else { return 0 }
        
        // Very high frequency (100+ per million) = 3 stars
        if frequency >= 100 { return 3 }
        // High frequency (10-99 per million) = 2 stars
        if frequency >= 10 { return 2 }
        // Medium frequency (1-9 per million) = 1 star
        if frequency >= 1 { return 1 }
        // Low frequency (< 1 per million) = "Rare" label
        return 0
    }
}
