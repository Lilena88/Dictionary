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
        ZStack {
            List {
                Section {
                    ForEach($vm.translations) { $translation in
                        TranslationView(vm: translation, linkedWord: $vm.searchText)
                        
                    }
                    
                } footer: {
                    Spacer()
                        .frame(height: 100)
                        .listRowInsets(EdgeInsets())

                }
                .listRowBackground(Color.blue.opacity(0.05))
                
              
            }
            .offset(y: -25)
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
            
            VStack{
                Spacer()
                SearchBar(text: $vm.searchText, backgroundColor:.constant(.clear), prompt: "word/слово")
                    .padding(.horizontal, 16)
            }
        }

        .background(Color.secondary)
        .textInputAutocapitalization(.never)
        .scrollDismissesKeyboard(.immediately)
        .onAppear(perform: {
            vm.restoreLastSearchOrInitial()
        })
        .gesture(DragGesture()
            .onEnded({ value in
                if value.startLocation.x < value.location.x - 24 {
                    print("Hist", vm.history)
                    if vm.history.count > 1 {
                        vm.history.removeLast()
                        if let last = vm.history.last {
                            print(last)
                            vm.searchText = last
                        }
                    }
                }
            }))
    }
}


#Preview {
    ContentView()
}

struct TranslationView: View {
    @ObservedObject var vm: TranslationViewModel
    @Binding var linkedWord: String
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { vm.isExpanded },
                set: { vm.isExpanded = $0 }
            ),
            content: {
                Text(vm.fullTranslation)
                    .listRowInsets(EdgeInsets(top: 0,
                                              leading: 10,
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


struct MyDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label
                    Spacer()
                    Text(configuration.isExpanded ? "hide" : "show")
                        .foregroundColor(.accentColor)
                        .font(.caption.lowercaseSmallCaps())
                        .animation(nil, value: configuration.isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
