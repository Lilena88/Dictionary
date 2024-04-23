//
//  AttributedText.swift
//  Dictionary
//
//  Created by Elena Kim on 4/8/24.
//

import SwiftUI

struct TestHTMLText: View {
    var html: String
    var body: some View {
        Text(convertHTML(text: html))
    }
    
    private func convertHTML(text: String) -> AttributedString {
        if let nsAttributedString = try? NSAttributedString(data: Data(html.utf8), options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil),
           let attributedString = try? AttributedString(nsAttributedString, including: \.uiKit) {
            return attributedString
        } else {
            return AttributedString(html)
        }
    }
    
}

extension String {
    var containsCyrillic: Bool {
        return self.range(of: "[а-яА-ЯёЁ]", options: .regularExpression) != nil
    }
}
