import SwiftUI
import Combine
import UserNotifications

/// Manages user settings and preferences for the app
class UserSettings: ObservableObject {
    // MARK: - Singleton
    static let shared = UserSettings()
    
    // MARK: - Published Properties
    
    /// Whether to respect the system's Dynamic Type settings
    @Published var useDynamicType: Bool {
        didSet {
            UserDefaults.standard.set(useDynamicType, forKey: "useDynamicType")
        }
    }
    
    /// Whether to use the system's dark mode setting or override it
    @Published var useSystemAppearance: Bool {
        didSet {
            UserDefaults.standard.set(useSystemAppearance, forKey: "useSystemAppearance")
        }
    }
    
    /// The app's appearance when not using system setting
    @Published var darkMode: Bool {
        didSet {
            UserDefaults.standard.set(darkMode, forKey: "darkMode")
        }
    }
    
    /// Whether to prefetch images for smoother scrolling (uses more data)
    @Published var prefetchImages: Bool {
        didSet {
            UserDefaults.standard.set(prefetchImages, forKey: "prefetchImages")
        }
    }
    
    /// Whether to show high-resolution images (uses more data)
    @Published var highQualityImages: Bool {
        didSet {
            UserDefaults.standard.set(highQualityImages, forKey: "highQualityImages")
        }
    }
    
    /// Whether to use haptic feedback
    @Published var useHaptics: Bool {
        didSet {
            UserDefaults.standard.set(useHaptics, forKey: "useHaptics")
        }
    }
    
    /// Font size adjustment (relative to system setting)
    @Published var fontSizeAdjustment: FontSizeAdjustment {
        didSet {
            UserDefaults.standard.set(fontSizeAdjustment.rawValue, forKey: "fontSizeAdjustment")
        }
    }
    
    /// Whether to enable wake-up notifications
    @Published var enableWakeUpNotification: Bool {
        didSet {
            UserDefaults.standard.set(enableWakeUpNotification, forKey: "enableWakeUpNotification")
            updateNotificationSchedule()
        }
    }
    
    /// Wake-up notification time (hour and minute components)
    @Published var wakeUpTime: Date {
        didSet {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: wakeUpTime)
            let minute = calendar.component(.minute, from: wakeUpTime)
            
            UserDefaults.standard.set(hour, forKey: "wakeUpHour")
            UserDefaults.standard.set(minute, forKey: "wakeUpMinute")
            
            updateNotificationSchedule()
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved settings or use defaults
        self.useDynamicType = UserDefaults.standard.bool(forKey: "useDynamicType", defaultValue: true)
        self.useSystemAppearance = UserDefaults.standard.bool(forKey: "useSystemAppearance", defaultValue: true)
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode", defaultValue: false)
        self.prefetchImages = UserDefaults.standard.bool(forKey: "prefetchImages", defaultValue: true)
        self.highQualityImages = UserDefaults.standard.bool(forKey: "highQualityImages", defaultValue: true)
        self.useHaptics = UserDefaults.standard.bool(forKey: "useHaptics", defaultValue: true)
        
        let rawFontSize = UserDefaults.standard.integer(forKey: "fontSizeAdjustment", defaultValue: FontSizeAdjustment.system.rawValue)
        self.fontSizeAdjustment = FontSizeAdjustment(rawValue: rawFontSize) ?? .system
        
        // Load notification settings
        self.enableWakeUpNotification = UserDefaults.standard.bool(forKey: "enableWakeUpNotification", defaultValue: false)
        
        // Default wake-up time is 8:30 AM
        var components = DateComponents()
        components.hour = UserDefaults.standard.integer(forKey: "wakeUpHour", defaultValue: 8)
        components.minute = UserDefaults.standard.integer(forKey: "wakeUpMinute", defaultValue: 30)
        
        let calendar = Calendar.current
        self.wakeUpTime = calendar.date(from: components) ?? calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
        
        // Request notification permissions when the app is launched
        requestNotificationPermissions()
    }
    
    // MARK: - Methods
    
    /// Reset all settings to default values
    func resetToDefaults() {
        useDynamicType = true
        useSystemAppearance = true
        darkMode = false
        prefetchImages = true
        highQualityImages = true
        useHaptics = true
        fontSizeAdjustment = .system
        
        // Reset notification settings
        enableWakeUpNotification = false
        
        let calendar = Calendar.current
        wakeUpTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
        
        // Clear any scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Get the current color scheme based on settings
    var colorScheme: ColorScheme? {
        if useSystemAppearance {
            return nil // Use system setting
        } else {
            return darkMode ? .dark : .light
        }
    }
    
    /// Get the font size adjustment factor
    var fontSizeMultiplier: CGFloat {
        return fontSizeAdjustment.multiplier
    }
    
    // MARK: - Notification Methods
    
    /// Request permission to send notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // If permissions were granted and notifications are enabled, schedule them
                    if self.enableWakeUpNotification {
                        self.updateNotificationSchedule()
                    }
                } else if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Update the notification schedule based on current settings
    func updateNotificationSchedule() {
        NotificationManager.shared.scheduleWakeUpNotification(
            at: wakeUpTime,
            enabled: enableWakeUpNotification
        )
    }
}

// MARK: - Font Size Adjustment Enum

enum FontSizeAdjustment: Int, CaseIterable, Identifiable {
    case extraSmall = 0
    case small = 1
    case system = 2
    case large = 3
    case extraLarge = 4
    
    var id: Int { self.rawValue }
    
    var name: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .system: return "System"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var multiplier: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .system: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
    
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return integer(forKey: key)
    }
}

// MARK: - Dynamic Font Modifier

struct DynamicTypeModifier: ViewModifier {
    @ObservedObject private var settings = UserSettings.shared
    let style: Font.TextStyle
    var weight: Font.Weight?
    
    init(style: Font.TextStyle, weight: Font.Weight? = nil) {
        self.style = style
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        if settings.useDynamicType {
            if let weight = weight {
                content
                    .font(.system(style, design: .default, weight: weight))
                    .dynamicTypeSize(.xSmall...(.accessibility5))
            } else {
                content
                    .font(.system(style))
                    .dynamicTypeSize(.xSmall...(.accessibility5))
            }
        } else {
            if let weight = weight {
                content
                    .font(.system(size: UIFont.preferredFont(forTextStyle: style.uiTextStyle).pointSize * settings.fontSizeMultiplier, weight: weight))
            } else {
                content
                    .font(.system(size: UIFont.preferredFont(forTextStyle: style.uiTextStyle).pointSize * settings.fontSizeMultiplier))
            }
        }
    }
}

// MARK: - Font Extensions

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

extension View {
    func dynamicFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        self.modifier(DynamicTypeModifier(style: style, weight: weight))
    }
} 