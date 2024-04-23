//
//  ContentView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var vm: MainModelView
    @State private var searchText = ""
    var searchResult: [TranslationShort] {
        guard !searchText.isEmpty else { return [] }
        print(vm.search(word: searchText))
        return vm.search(word: searchText)
    }
    var body: some View {
        NavigationStack {
            List(searchResult, id: \.id) { translation in
                ExtractedView(translation: translation)
                    .environmentObject(RowVM())
            }
            
        }
        .searchable(text: $searchText, prompt: "word/слово")
        .textInputAutocapitalization(.never)
        .scrollDismissesKeyboard(.immediately)
        
    }
}

#Preview {
    ContentView().environmentObject(MainModelView())
}

struct ExtractedView: View {
    @EnvironmentObject var vm: RowVM
    @State private var isExpanded = false
    var translation: TranslationShort
    var content: String {
        return getStaticHTML(for: vm.getFullTranslation(for: translation))
        
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                if isExpanded {
                    TestHTMLText(html: content)
                        .listRowInsets(EdgeInsets(top: 0,
                                                  leading: 0,
                                                  bottom: 0,
                                                  trailing: 16))
                }
            },
            label: {
                HStack {
                    Text(translation.word)
                    Text(translation.shortTranslation.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .lineLimit(1)
                        .foregroundColor(.gray)
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
                </style>
            </head>
            <body>
            \(string.replacingOccurrences(of: "<E>", with: "<br><E>"))
            </body>
            </html>
            """
    }
}


