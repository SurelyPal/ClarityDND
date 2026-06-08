//
//  ClarityApp.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: DNDCharacter.self)
    }
}

