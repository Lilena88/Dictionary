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
        log("Database initialized at: \(dbPath)")
    }
    
    // MARK: - Private SQL Execution
    
    /// Logs SQL operations with timestamp
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [SQL] \(message)")
    }
    
    /// Executes raw SQL query - internal use only
    private func execute(sql: String) -> Statement? {
        let startTime = Date()
        log("Executing query: \(sql)")
        
        do {
            let statement = try db.prepare(sql)
            let executionTime = Date().timeIntervalSince(startTime)
            log("Query executed successfully in \(String(format: "%.3f", executionTime))s")
            return statement
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            log("Query failed after \(String(format: "%.3f", executionTime))s - Error: \(error)")
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
        log("searchWordsWithFuzzyMatching called for '\(searchTerm)' in \(tableName)")
        let cleanValue = searchTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isRuDict = searchTerm.containsCyrillic
        
        guard cleanValue.count > 2 else {
            log("Fuzzy matching: search term too short, using exact match only")
            return getExactWordMatches(in: tableName, searchTerm: cleanValue, isRuDict: isRuDict)
        }
        
        // Try exact match first
        log("Fuzzy matching: trying exact match")
        var results = getExactWordMatches(in: tableName, searchTerm: cleanValue, isRuDict: isRuDict)
        if !results.isEmpty { 
            log("Fuzzy matching: exact match succeeded with \(results.count) results")
            return results 
        }
        
        // Try with one character removed
        log("Fuzzy matching: trying with 1 character removed")
        results = getExactWordMatches(in: tableName, searchTerm: String(cleanValue.dropLast()), isRuDict: isRuDict)
        if !results.isEmpty { 
            log("Fuzzy matching: match with 1 char removed succeeded with \(results.count) results")
            return results 
        }
        
        // Try with two characters removed
        log("Fuzzy matching: trying with 2 characters removed")
        results = getExactWordMatches(in: tableName, searchTerm: String(cleanValue.dropLast(2)), isRuDict: isRuDict)
        log("Fuzzy matching: final attempt returned \(results.count) results")
        return results
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
            """) else { 
            log("getExactWordMatches returned 0 results (query failed)")
            return []
        }
        
        let results = statement.map { row in
            TranslationShort(
                isRuDict: isRuDict,
                word: row[0] as? String ?? "",
                shortTranslation: row[1] as? String ?? "",
                stress: row[2] as? String,
                popularity: row[3] as? Double
            )
        }
        
        log("getExactWordMatches returned \(results.count) results for '\(searchTerm)' in \(tableName)")
        return results
    }
    
    /// Finds English translations for multiple Russian words
    func getEnglishTranslationsForWords(_ words: [String]) -> Statement? {
        log("getEnglishTranslationsForWords called with \(words.count) words: [\(words.joined(separator: ", "))]")
        let escapedWords = words.map { escapeSQLString($0) }
        let wordList = escapedWords.joined(separator: "\",\"")
        let statement = execute(sql: """
            SELECT word, translation, stress
            FROM enRu
            WHERE word IN ("\(wordList)")
            ORDER BY instr(",\(words.joined(separator: ",")),", ',' || word || ',')
            """)
        if statement != nil {
            log("getEnglishTranslationsForWords query succeeded")
        }
        return statement
    }
    
    /// Gets full translation and transcription for a specific English word
    func getFullTranslationAndTranscription(forWord word: String) -> (translation: String, transcription: String)? {
        log("getFullTranslationAndTranscription called for word: '\(word)'")
        let escapedWord = escapeSQLString(word)
        guard let statement = execute(sql: """
            SELECT translation, transcription 
            FROM enRu 
            WHERE word = '\(escapedWord)' 
            LIMIT 1
            """),
              let firstRow = statement.makeIterator().next() else { 
            log("getFullTranslationAndTranscription returned nil (no results found)")
            return nil
        }
        
        let translation = firstRow[0] as? String ?? ""
        let transcription = firstRow[1] as? String ?? ""
        log("getFullTranslationAndTranscription returned result for '\(word)'")
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
