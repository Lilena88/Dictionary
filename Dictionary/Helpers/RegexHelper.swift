//
//  RegexHelper.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//

import Foundation

/// A utility class for common regex operations used throughout the app.
struct RegexHelper {
    
    /// Finds the first regex match in the given text.
    static func findMatch(pattern: String, in text: String) -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            )
            let range = NSRange(text.startIndex..., in: text)
            
            guard let match = regex.firstMatch(in: text, options: [], range: range),
                  let stringRange = Range(match.range, in: text) else {
                return nil
            }
            
            return String(text[stringRange])
        } catch {
            return nil
        }
    }
    
    /// Replaces all matches of a pattern with the result of a replacement closure.
    static func replaceAllMatches(pattern: String, in text: String, with replacement: (String) -> String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let mutableText = NSMutableString(string: text)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            var offset = 0
            
            for match in matches {
                let matchedText = (text as NSString).substring(with: match.range)
                let replacementText = replacement(matchedText)
                let adjustedRange = NSRange(
                    location: match.range.location + offset,
                    length: match.range.length
                )
                mutableText.replaceCharacters(in: adjustedRange, with: replacementText)
                offset += replacementText.count - match.range.length
            }
            
            return mutableText as String
        } catch {
            return text
        }
    }
}