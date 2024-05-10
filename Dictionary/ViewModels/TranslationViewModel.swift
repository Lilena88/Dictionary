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
            return fullTranslationForRus(ruWord: shortTranslation.word, with: shortTranslation.shortTranslation)
        } else {
            return fullTranslationForEng(wordID: shortTranslation.id)
        }
        
    }
    
    private func fullTranslationForRus(ruWord: String, with engTranslations: String) -> String {
        guard let engWordsArray = enTranslations(for: engTranslations) else { return "" }
        var fullArticle = ""
        for row in engWordsArray {
            let engWord = row[1] as? String ?? ""
            let translation = row[2] as? String ?? ""
            let engTranslatedArticle = getTranslateOnly(for: ruWord, in: translation, engWord: engWord)
            fullArticle += "<LI>\(engTranslatedArticle)</LI>"
        }
        fullArticle += ""

        return fullArticle
        
    }
    
    private func fullTranslationForEng(wordID: Int64) -> String {
        let rows = dbManager.findRecordInTable(tableName: Dictionaries.enRu.rawValue, columnName: "id", searchValue: wordID)
        guard let firstRow = rows.first else { return "" }
        var fullTranslation = firstRow[Expression<String>("translation")]
        self.transcription = firstRow[Expression<String>("transcription")]
        return fullTranslation
        
    }
  
    private func enTranslations(for ruWords: String) -> Statement? {
        let words = ruWords.components(separatedBy: ",")
        return dbManager.findMultipleValues(words: words)
    }
    
    private func getTranslateOnly(for ruWord: String, in article: String, engWord: String) -> String {
        let pattern = "[^\n]*?\(ruWord)[^\n]*"
        
        if var match = findByRegexp(by: pattern, in: article) {
            match = match
                .replacingOccurrences(of: "<P>", with: "")
                .replacingOccurrences(of: "</P>", with: "")
            return "\(engWord) ― \(match)"
        }
        return engWord
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
        //return article
        let links = article.replacingOccurrences(of: "[\\w']+(?![^<]*>)(?![^<>]*?</abbr>)", with: "<a href='$0'>$0</a>", options: .regularExpression, range: nil)
        return links
    }
    
    private func getStaticHTML(for string: String) -> String {
        var article = string
            .replacingOccurrences(of: "<E>", with: "<UL><E>")
            .replacingOccurrences(of: "</E>", with: "</E></UL>")
            .replacingOccurrences(of: "<P>", with: "<LI>")
            .replacingOccurrences(of: "</P>", with: "</LI>")
        
        print(article)
        
        return """
            <!doctype html>
            <head>
                <meta charset="utf-8">
                <style type="text/css">
                    BODY {
                        font: -apple-system-body;
                        color: \(Color.black);
                    }
                    ABBR {
                        color: \(Color.green)
                    }
                    E {
                        color: \(Color.gray);
                        display: list-item;
                    }
                    HR {
                      display:none;
                    }
                    A {
                        font: inherit;
                        color: inherit;
                        text-decoration: inherit;
                    }
                    OL,LI {
                        padding: 0px;
                        margin: 0px;
                    }
                    H5{text-align:right;}
                </style>
            </head>
            <body>
            <H5>\(self.transcription)</H5>
            <OL>
                \(article)
            </OL>
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
