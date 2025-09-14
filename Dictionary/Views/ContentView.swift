//
//  ContentView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var vm: MainModelView = MainModelView()
    var body: some View {
        NavigationStack {
            List($vm.translations) { $translation in
                TranslationView(vm: $translation, linkedWord: $vm.searchText)
                
            }
            
        }
        .searchable(text: $vm.searchText, prompt: "word/слово")
        .textInputAutocapitalization(.never)
        .scrollDismissesKeyboard(.immediately)
        .onAppear(perform: {
            vm.searchText = "tree"
        })
        
    }
}

#Preview {
    ContentView()
}

struct TranslationView: View {
    @Binding var vm: TranslationViewModel
    @Binding var linkedWord: String
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $vm.isExpanded,
            content: {
                Text(vm.fullTranslation)
                    .listRowInsets(EdgeInsets(top: 0,
                                              leading: 0,
                                              bottom: 0,
                                              trailing: 16))
                    .environment(\.openURL, OpenURLAction { url in
                        let word = url.path(percentEncoded: false).dropFirst()
                        linkedWord = String(word)
                           return .handled
                       })
                
            },
            label: {
                HStack {
                    Text(vm.word)
                        .lineLimit(1)
                        .layoutPriority(1)
                    Text(vm.shortTranslation)
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
            }
        )
        
    }

}


