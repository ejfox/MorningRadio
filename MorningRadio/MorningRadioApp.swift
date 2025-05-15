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
    @StateObject private var settings = UserSettings.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(settings.colorScheme)
                .environmentObject(settings)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        // Update notification content with latest scrap when app becomes active
                        if settings.enableWakeUpNotification {
                            NotificationManager.shared.updateNotificationContent()
                        }
                        
                        // Update widget data when app becomes active
                        #if !WIDGET_EXTENSION
                        WidgetDataManager.shared.updateWidgetData()
                        #endif
                    }
                }
        }
    }
}
