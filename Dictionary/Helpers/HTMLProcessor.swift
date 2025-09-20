//
//  HTMLProcessor.swift
//  Dictionary
//
//  Created by Elena Kim on 4/25/24.
//

import Foundation
import SwiftUI

/// A utility class for processing and formatting HTML content for dictionary translations.
struct HTMLProcessor {
    
    // MARK: - Main Processing
    
    /// Formats raw content as HTML with styling and structure.
    static func formatAsHTML(_ content: String, transcription: String = "") -> String {
        let processedContent = addLinksToWords(content)
        return generateHTMLDocument(processedContent, transcription: transcription)
    }
    
    /// Converts HTML string to AttributedString for SwiftUI display.
    static func convertHTMLToAttributedString(_ html: String) -> AttributedString {
        guard let data = html.data(using: .utf8),
              let nsAttributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: NSUTF8StringEncoding],
                documentAttributes: nil
              ),
              let attributedString = try? AttributedString(nsAttributedString, including: \.uiKit) else {
            return AttributedString(html)
        }
        return attributedString
    }
    
    // MARK: - Private Processing Methods
    
    private static func addLinksToWords(_ text: String) -> String {
        return text.replacingOccurrences(
            of: "[\\w']+(?![^<]*>)(?![^<>]*?</abbr>)",
            with: "<a href='$0'>$0</a>",
            options: .regularExpression
        )
    }
    
    private static func generateHTMLDocument(_ content: String, transcription: String) -> String {
        let formattedContent = formatContent(content)
        let numberedContent = addNumberedLists(to: formattedContent)
        
        return """
        <style type="text/css">
            BODY { font: -apple-system-body; color: \(Color.black); }
            ABBR { color: \(Color.green) }
            E { color: \(Color.gray); display: list-item; }
            HR { display: none; }
            A { font: inherit; color: inherit; text-decoration: inherit; }
            H5 { text-align: right; }
            p { margin: 0; padding: 0; }
        </style>
        <H5>\(transcription)</H5>
        <OL>\(numberedContent)</OL>
        """
    }
    
    private static func formatContent(_ content: String) -> String {
        return content
            .replacingOccurrences(of: "<E>", with: "<E>")
            .replacingOccurrences(of: "</E>", with: "</E>")
            .replacingOccurrences(of: "<P>", with: "<li>")
            .replacingOccurrences(of: "</P>", with: "</li>")
            .replacingOccurrences(of: "\n\n", with: "\n")
            .replacingOccurrences(of: ",(?! )", with: ", ", options: .regularExpression)
    }
    
    private static func addNumberedLists(to text: String) -> String {
        guard RegexHelper.findMatch(pattern: "<li>.+<li>", in: text) != nil else { return text }
        
        var index = 0
        return RegexHelper.replaceAllMatches(pattern: "<li>", in: text) { _ in
            index += 1
            return "<li>\(index). "
        }
    }
}