//
//  DictionaryApp.swift
//  Dictionary
//
//  Created by Elena Kim on 4/3/24.
//

import SwiftUI

@main
struct DictionaryApp: App {
    let vm = MainModelView()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environment(\.colorScheme, .light)
        }
    }
}
