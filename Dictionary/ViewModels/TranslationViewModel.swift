//
//  TranslationViewModel.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//
import UIKit
import SwiftUI
import SQLite

class TranslationViewModel: ObservableObject, Identifiable {
    let dbManager: DatabaseManager
    private var translation: TranslationShort
    
    var id: String {
        return translation.word
    }
    var word: String {
        return translation.word
    }
    
    var shortTranslation: String {
        return translation.shortTranslationEdited
    }
    
    @Published var fullTranslation: AttributedString = ""
    var transcription: String = ""
    @Published var isExpanded: Bool = false {
        didSet {
            getForExpanded(newValue: isExpanded)
        }
    }
    
    init(translation: TranslationShort, dbManager: DatabaseManager) {
        self.translation = translation
        self.dbManager = dbManager
        
    }
    
    func getForExpanded(newValue: Bool) {
        if newValue {
            let full = translation.shortTranslation
            let links = addLinks(to: full)
            let html = getStaticHTML(for: links)
            fullTranslation = convertHTML(text: html)
        } else {
            fullTranslation = ""
        }
    }
    
    func getFullTranslation(for shortTranslation: TranslationShort) -> String {
        if shortTranslation.isRuDict {
            return fullTranslationForRus(ruWord: shortTranslation.word, with: shortTranslation.shortTranslation)
        } else {
            return fullTranslationForEng(word: shortTranslation.word)
        }
        
    }
    
    private func fullTranslationForRus(ruWord: String, with engTranslations: String) -> String {
        guard let engWordsArray = enTranslations(for: engTranslations) else { return "" }
        var fullArticle = ""
        for row in engWordsArray {
            let engWord = row[0] as? String ?? ""
            let translation = row[1] as? String ?? ""
            let engTranslatedArticle = getTranslateOnly(for: ruWord, in: translation, engWord: engWord)
            fullArticle += "<LI>\(engTranslatedArticle)</LI>"
        }
        fullArticle += ""

        return fullArticle
        
    }
    
    private func fullTranslationForEng(word: String) -> String {
        guard let rows = dbManager.fetchRows(sql: "SELECT translation, transcription FROM \(Dictionaries.enRu.rawValue) WHERE word = '\(word)' LIMIT 1") else { return "" }
        var iterator = rows.makeIterator()
        guard let firstRow = iterator.next() else { return "" }
        let fullTranslation = firstRow[0] as? String ?? ""
        self.transcription = firstRow[1] as? String ?? ""
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

    // MARK: - Replacement as Callback (start to end)
    func replaceAllByRegexp(_ pattern: String, _ text: String, with callback: (String) -> String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let mutableText = NSMutableString(string: text)
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            var offset = 0
            
            for match in matches {
                let matchedText = nsText.substring(with: match.range)
                let replacementText = callback(matchedText)
                let adjustedRange = NSRange(location: match.range.location + offset, length: match.range.length)
                mutableText.replaceCharacters(in: adjustedRange, with: replacementText)
                offset += replacementText.count - match.range.length
            }
            
            return mutableText as String
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
            return text
        }
    }

    
    private func addLinks(to article: String) -> String {
        //return article
        let links = article.replacingOccurrences(of: "[\\w']+(?![^<]*>)(?![^<>]*?</abbr>)", with: "<a href='$0'>$0</a>", options: .regularExpression, range: nil)
        return links
    }
    
    func numberLists(in text: String) -> String {
        if findByRegexp(by: "<li>.+<li>", in: text) == nil {
            return text
        }
        
        var index = 0
        return replaceAllByRegexp("<li>", text) { match in
            index += 1
            return "<li>\(index). "
        }
    }
    
    private func getStaticHTML(for string: String) -> String {
        var article = string
            .replacingOccurrences(of: "<E>", with: "<E>")
            .replacingOccurrences(of: "</E>", with: "</E>")
            .replacingOccurrences(of: "<P>", with: "<li>")
            .replacingOccurrences(of: "</P>", with: "</li>")
            .replacingOccurrences(of: "\n\n", with: "\n")
        article = numberLists(in: article)
        
        print(article)
        
        return """
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
                    H5{text-align:right;}
                    p{
                        margin:0;
                        padding:0;
                    }
                </style>
            <H5>\(self.transcription)</H5>
            <OL>
                \(article)
            </OL>
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
