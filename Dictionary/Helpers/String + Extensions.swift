//
//  String + Extensions.swift
//  Dictionary
//
//  Created by Elena Kim on 4/24/24.
//

import Foundation

extension String {
    var containsCyrillic: Bool {
        return self.range(of: "[а-яА-ЯёЁ]", options: .regularExpression) != nil
    }
    
    /// Removes stress marks (combining diacritical marks) from the string
    var removingStressMarks: String {
        // Remove common stress marks: acute accent (U+0301), grave accent (U+0300), etc.
        return self.replacingOccurrences(of: "\u{0301}", with: "")
                   .replacingOccurrences(of: "\u{0300}", with: "")
                   .replacingOccurrences(of: "\u{0341}", with: "")
    }
}
