//
//  MorningRadioApp.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI

@main
struct MorningRadioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
