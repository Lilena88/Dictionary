//
//  ContentView.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: MainModelView
    
    init(viewModel: MainModelView? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MainModelView())
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 1.0),
                    .white,
                    Color(red: 0.8, green: 0.9, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            List {
                if !viewModel.recentSearches.isEmpty {
                    Section("Recent") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.recentSearches, id: \.self) { term in
                                    Button {
                                        viewModel.searchText = term
                                        viewModel.commitSearch(term)
                                    } label: {
                                        Text(term)
                                            .lineLimit(1)
                                    }
                                    .buttonStyle(GlassChipStyle())
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                Section {
                    ForEach(viewModel.translations) { translation in
                        TranslationView(
                            viewModel: translation,
                            linkedWord: $viewModel.searchText,
                            onWordTapped: { term in
                                viewModel.commitSearch(term)
                            }
                        )
                    }
                }
                footer: {
                    Spacer()
                        .frame(height: 100)
                        .listRowInsets(EdgeInsets())

                }
                .listRowBackground(Color.white.opacity(0.3))
              
            }
            .offset(y: -10)
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .transaction { t in t.animation = nil }
            .ignoresSafeArea(edges: .bottom)
            
            VStack {
                Spacer()
                SearchBar(text: $viewModel.searchText,
                          backgroundColor: .constant(Color.clear),
                          prompt: "word/слово",
                          onSubmit: { viewModel.commitSearch() })
                    .padding(.horizontal, 16)
            }
        }
        .textInputAutocapitalization(.never)
        .scrollDismissesKeyboard(.immediately)
        .onAppear(perform: viewModel.restoreLastSearchOrInitial)
        .gesture(
            DragGesture().onEnded(handleBackSwipe(_:))
        )
    }
}


#Preview {
    ContentView(viewModel: MainModelView(previewData: true))
}

private extension ContentView {
    func handleBackSwipe(_ value: DragGesture.Value) {
        guard value.startLocation.x < value.location.x - 24,
              viewModel.history.count > 1 else { return }
        viewModel.history.removeLast()
        if let last = viewModel.history.last {
            viewModel.searchText = last
        }
    }
}

private struct TranslationView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @Binding var linkedWord: String
    var onWordTapped: ((String) -> Void)? = nil
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { viewModel.isExpanded },
                set: { viewModel.isExpanded = $0 }
            ),
            content: {
                Text(viewModel.fullTranslation)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .environment(\.openURL, OpenURLAction { url in
                        let word = String(url.path(percentEncoded: false).dropFirst())
                        linkedWord = word
                        onWordTapped?(word)
                        return .handled
                    })

            },
            label: {
                HStack {
                    Button(action: viewModel.pronounceWord) {
                        Image(systemName: "speaker.2.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(viewModel.word)
                        .lineLimit(1)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    Text(viewModel.shortTranslation)
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
            }
        )
    }
}

private struct GlassChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Color.white.opacity(0.3),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
