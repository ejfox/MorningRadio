import SwiftUI

// Only use @main when not building for complications
#if !WIDGET_EXTENSION
@main
#endif
struct MorningRadioWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 