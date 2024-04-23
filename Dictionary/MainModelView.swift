//
//  MainModelView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import Foundation
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


class RowVM: ObservableObject {

    let dbManager = DatabaseManager(databaseName: databaseName)
    
    func getFullTranslation(for shortTranslation: TranslationShort) -> String {
        if shortTranslation.isRuDict {
            return fullTranslationForRus(word: shortTranslation.word, with: shortTranslation.shortTranslation)
        } else {
            return fullTranslationForEng(wordID: shortTranslation.id)
        }
        
    }
    
    private func fullTranslationForRus(word: String, with engTranslations: String) -> String {
        let engWordsArray = enTranslations(for: engTranslations)
        let fullArticle = engWordsArray.reduce("") { partialResult, currentRow in
            let engTranslatedArticle = getTranslateOnly(for: word, in: currentRow[Expression<String>("translation")], engWord: currentRow[Expression<String>("word")])
            return partialResult + engTranslatedArticle
        }
        return fullArticle
        
    }
    
    private func fullTranslationForEng(wordID: Int64) -> String {
        let rows = dbManager.findRecordInTable(tableName: Dictionaries.enRu.rawValue, columnName: "id", searchValue: wordID)
        guard let fullTranslation = rows.first?[Expression<String>("translation")] else { return "" }
        return fullTranslation
        
    }
  
    private func enTranslations(for ruWords: String) -> [Row] {
        let words = ruWords.components(separatedBy: ",")
        return dbManager.findMultipleValues(
            tableName: Dictionaries.enRu.rawValue,
            columnName: "word",
            searchValues: words)
    }
    
    private func getTranslateOnly(for ruWord: String, in article: String, engWord: String) -> String {
        let pattern = "(?<=<P>)(?:(?!<P>)[\\s\\S])*?\\b\(ruWord)\\b.*?(?=</P>)"
        
        if let match = findByRegexp(by: pattern, in: article) {
            if match.lowercased().contains("<p>") {
                let p = match.replacingOccurrences(of: "<P>", with: "<P>\(engWord) - ")
                return match.replacingOccurrences(of: "<P>", with: "<P>\(engWord) - ")
            } else {
                return "<P>\(engWord) - \(match)</P>"
            }
            
        }
        
        return article
    }
    
    private func findByRegexp(by regex: String, in text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let nsRange = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: nsRange) {
                if let range = Range(match.range, in: text) {
                    let result = String(text[range])
                    return result
                }
            }
        } catch {
            print("Error: \(error.localizedDescription) Invalid regex: \(regex)")
        }
        
        print("No match found for regexp: \(regex) text: \(text)")
        return nil
    }
}
