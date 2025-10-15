//
//  TransliterationDetector.swift
//  Dictionary
//
//  Created by Elena Kim
//

import Foundation

/// Detects and converts transliterated Russian words typed in Latin letters
final class TransliterationDetector {
    
    // MARK: - Transliteration Mapping
    
    /// Maps Latin character sequences to Cyrillic equivalents
    /// Ordered by length (longest first) to handle multi-char sequences like "shch" before "sh"
    private static let transliterationMap: [(latin: String, cyrillic: String)] = [
        // 4-character sequences
        ("shch", "щ"),
        
        // 3-character sequences  
        ("sch", "щ"),
        ("tch", "ч"),
        ("y''", "ъ"),
        
        // 2-character sequences
        ("zh", "ж"),
        ("kh", "х"),
        ("ts", "ц"),
        ("ch", "ч"),
        ("sh", "ш"),
        ("yu", "ю"),
        ("ya", "я"),
        ("ye", "е"),
        ("yo", "ё"),
        ("iy", "ий"),
        ("yy", "ый"),
        ("y'", "ь"),
        ("''", "ъ"),
        
        // 1-character sequences
        ("a", "а"),
        ("b", "б"),
        ("v", "в"),
        ("g", "г"),
        ("d", "д"),
        ("e", "е"),
        ("z", "з"),
        ("i", "и"),
        ("j", "й"),
        ("k", "к"),
        ("l", "л"),
        ("m", "м"),
        ("n", "н"),
        ("o", "о"),
        ("p", "п"),
        ("r", "р"),
        ("s", "с"),
        ("t", "т"),
        ("u", "у"),
        ("f", "ф"),
        ("h", "х"),
        ("c", "к"),
        ("w", "в"),
        ("x", "кс"),
        ("y", "ы"),
        ("'", "ь"),
    ]
    
    // MARK: - Pattern Detection
    
    /// Character sequences that strongly suggest transliterated Russian
    private static let russianPatterns = [
        "zh", "kh", "shch", "sch", "tch", "ts", "ch", "sh",
        "yu", "ya", "ye", "yo"
    ]
    
    /// Word endings common in Russian transliteration
    private static let russianEndings = [
        "ov", "ova", "ovich", "evich", "ovna", "evna",
        "sky", "skaya", "skiy", "skoi", "aya", "yy", "iy"
    ]
    
    // MARK: - Public Methods
    
    /// Checks if the text looks like transliterated Russian based on patterns
    static func looksLikeTransliteration(_ text: String) -> Bool {
        let lower = text.lowercased()
        
        // Check for Russian-specific character combinations
        for pattern in russianPatterns {
            if lower.contains(pattern) {
                return true
            }
        }
        
        // Check for common Russian word endings
        for ending in russianEndings {
            if lower.hasSuffix(ending) {
                return true
            }
        }
        
        return false
    }
    
    /// Converts Latin text to Cyrillic using transliteration rules
    /// Returns multiple variants to handle ambiguous cases
    static func transliterateToCyrillic(_ text: String) -> [String] {
        var variants: Set<String> = []
        
        // Main transliteration
        let mainVariant = transliterateWithMap(text.lowercased())
        variants.insert(mainVariant)
        
        // Handle ambiguous 'e' → both 'е' and 'э'
        if text.lowercased().contains("e") {
            let withE = transliterateWithMap(text.lowercased())
            let withEh = text.lowercased().replacingOccurrences(of: "e", with: "э")
            variants.insert(withE)
            variants.insert(transliterateWithMap(withEh))
        }
        
        // Handle 'yo' vs 'e' (ё vs е)
        if text.lowercased().contains("yo") || text.lowercased().contains("ё") {
            let withYo = text.lowercased().replacingOccurrences(of: "e", with: "yo")
            variants.insert(transliterateWithMap(withYo))
        }
        
        // Handle 'y' ambiguity → и, й, ы
        if text.lowercased().contains("y") && !text.lowercased().contains("ya") 
            && !text.lowercased().contains("yu") && !text.lowercased().contains("ye") {
            let withI = text.lowercased().replacingOccurrences(of: "y", with: "i")
            let withJ = text.lowercased().replacingOccurrences(of: "y", with: "j")
            variants.insert(transliterateWithMap(withI))
            variants.insert(transliterateWithMap(withJ))
        }
        
        // Handle 'c' → к or ц
        if text.lowercased().contains("c") && !text.lowercased().contains("ch") 
            && !text.lowercased().contains("sch") {
            let withK = text.lowercased().replacingOccurrences(of: "c", with: "k")
            let withTs = text.lowercased().replacingOccurrences(of: "c", with: "ts")
            variants.insert(transliterateWithMap(withK))
            variants.insert(transliterateWithMap(withTs))
        }
        
        return Array(variants).filter { !$0.isEmpty }
    }
    
    // MARK: - Private Methods
    
    /// Performs transliteration using the mapping table
    private static func transliterateWithMap(_ text: String) -> String {
        let result = text
        var position = 0
        var converted = ""
        
        while position < result.count {
            let remainingText = String(result.dropFirst(position))
            var matched = false
            
            // Try to match sequences from longest to shortest
            for (latin, cyrillic) in transliterationMap {
                if remainingText.lowercased().hasPrefix(latin) {
                    converted += cyrillic
                    position += latin.count
                    matched = true
                    break
                }
            }
            
            // If no match found, keep the original character
            if !matched {
                if position < result.count {
                    let index = result.index(result.startIndex, offsetBy: position)
                    converted.append(result[index])
                }
                position += 1
            }
        }
        
        return converted
    }
}

