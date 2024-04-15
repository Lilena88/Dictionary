//
//  ContentView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: MainModelView
    @State private var searchText = ""
    var searchResult: [Translation] {
        guard !searchText.isEmpty else { return [] }
        return vm.search(word: searchText)
    }
    
    var body: some View {
        NavigationStack {
            List(searchResult, id: \.id) { translation in
                ExtractedView(translation: translation)
                    .environmentObject(vm)
            }
            
        }
        .searchable(text: $searchText)
        .textInputAutocapitalization(.never)
        
        
        
    }
}

#Preview {
    ContentView().environmentObject(MainModelView())
}

struct ExtractedView: View {
    @EnvironmentObject var vm: MainModelView
    @State private var isExpanded = false
    var translation: Translation
    
    var body: some View {
        DisclosureGroup(
            content: {
                let fullTranslation = vm.fullTranslation(for: translation)
                let html = getStaticHTML(for: fullTranslation)
                TestHTMLText(html: html)
            },
            label: {
                HStack {
                    Text(translation.word)
                    Text(translation.translationShort)
                        .lineLimit(1)
                }
            }
        )
    }
    
    private func getStaticHTML(for string: String) -> String {
        return """
            <!doctype html>
            <head>
                <meta charset="utf-8">
                <style type="text/css">
                    /*
                      Custom CSS styling of HTML formatted text.
                      Note, only a limited number of CSS features are supported by NSAttributedString/UITextView.
                    */

                    body {
                        font: -apple-system-body;
                        color: \(Color.green);
                    }

                    h1, h2, h3, h4, h5, h6 {
                        color: \(UIColor.green);
                    }

                    a {
                        color: \(UIColor.blue);
                    }

                    li:last-child {
                        margin-bottom: 1em;
                    }
                </style>
            </head>
            <body>
                \(string.replacingOccurrences(of: "\n", with: "<br>").replacingOccurrences(of: "\n\n", with: "<br>"))
            </body>
            </html>
            """
    }
    

    
}
