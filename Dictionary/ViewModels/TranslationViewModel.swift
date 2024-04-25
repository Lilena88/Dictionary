//
//  TranslationViewModel.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//

import SwiftUI
import SQLite

class TranslationViewModel: ObservableObject, Identifiable {
    let dbManager: DatabaseManager
    private var translation: TranslationShort
    
    var id: Int64 {
        return translation.id
    }
    var word: String {
        return translation.word
    }
    
    var shortTranslation: String {
        return translation.shortTranslationEdited
    }
    
    var fullTranslation: AttributedString = ""
    var transcription: String = ""
    
    @Published var isExpanded: Bool = false {
        willSet {
            if newValue {
                let full = getFullTranslation(for: translation)
                let links = addLinks(to: full)
                let html = getStaticHTML(for: links)
                fullTranslation = convertHTML(text: html)
            } else {
                fullTranslation = ""
            }
        }
    }
    
    init(translation: TranslationShort, dbManager: DatabaseManager) {
        self.translation = translation
        self.dbManager = dbManager
    }
    
    
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
        guard let firstRow = rows.first else { return "" }
        let fullTranslation = firstRow[Expression<String>("translation")]
        self.transcription = firstRow[Expression<String>("transcription")]
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
            return "<P>\(engWord) - \(match)</P>"
        }
        return article
    }
    
//MARK: Work with strings
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
    private func addLinks(to article: String) -> String {
        let links = article.replacingOccurrences(of: "[\\w']+(?![^<]*>)(?![^<>]*?</abbr>)", with: "<a href='$0'>$0</a>", options: .regularExpression, range: nil)
        return links
    }
    
    private func getStaticHTML(for string: String) -> String {
        return """
            <!doctype html>
            <head>
                <meta charset="utf-8">
                <style type="text/css">
                    body {
                        font: -apple-system-body;
                        color: \(Color.black);
                    }
            
                    h1, h2, h3, h4, h5, h6 {
                        color: \(UIColor.green);
                    }
            
                    abbr {
                        color: \(Color.green)
                    }
                    E {
                        color: \(Color.gray);
                    }
                    hr {
                      display:none;
                    }
                    a {
                        font: -apple-system-body;
                        color: \(Color.black);
                        text-decoration: none;
                    }
                </style>
            </head>
            <body>
            \(string.replacingOccurrences(of: "<E>", with: "<br><E>"))
            </body>
            </html>
            """
    }
    
    private func convertHTML(text: String) -> AttributedString {
        if let nsAttributedString = try? NSAttributedString(data: Data(text.utf8), options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil),
           let attributedString = try? AttributedString(nsAttributedString, including: \.uiKit) {
            return attributedString
        } else {
            return AttributedString(text)
        }
    }
}
