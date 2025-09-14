//
//  SearchBar.swift
//  Dictionary
//
//  Created by Elena Kim on 5/13/24.
//

import SwiftUI
enum FocusedTextField {
    case yes
}
struct SearchBar: View {
    @Binding var text: String 
    @Binding var backgroundColor: Color
    var prompt: String
    @FocusState private var isEditing: FocusedTextField?
    
    var body: some View {
        HStack {
            TextField(prompt, text: $text)
                .focused($isEditing, equals: .yes)
                .submitLabel(.search)
                .frame(height: 30)
                .padding(7)
                .padding(.horizontal, 25)
                .background(BlurView())
                .cornerRadius(30)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                                self.isEditing = .yes
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)
                .onTapGesture {
                    self.isEditing = .yes
                }
                .onSubmit {
                    self.isEditing = nil
                }
            
        }
        .padding(.top, 0)
        .padding(.bottom, 0)
        .offset(y: -10)
        .background(backgroundColor)
    
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant(""), backgroundColor: .constant(.blue), prompt: "Search")
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .regular
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
