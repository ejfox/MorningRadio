import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var showNotificationPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Appearance Section
                Section(header: Text("Appearance").dynamicFont(.headline)) {
                    Toggle("Use System Appearance", isOn: $settings.useSystemAppearance)
                        .dynamicFont(.body)
                    
                    if !settings.useSystemAppearance {
                        Toggle("Dark Mode", isOn: $settings.darkMode)
                            .dynamicFont(.body)
                    }
                }
                
                // MARK: - Notifications Section
                Section(header: Text("Notifications").dynamicFont(.headline)) {
                    Toggle("Wake-up Notification", isOn: $settings.enableWakeUpNotification)
                        .dynamicFont(.body)
                        .onChange(of: settings.enableWakeUpNotification) { newValue in
                            if newValue {
                                checkNotificationPermissions()
                            }
                        }
                        .accessibilityHint("When enabled, you'll receive a daily notification with your morning update")
                    
                    if settings.enableWakeUpNotification {
                        DatePicker(
                            "Wake-up Time",
                            selection: $settings.wakeUpTime,
                            displayedComponents: .hourAndMinute
                        )
                        .dynamicFont(.body)
                        .accessibilityHint("Set the time for your daily wake-up notification")
                    }
                }
                
                // MARK: - Accessibility Section
                Section(header: Text("Accessibility").dynamicFont(.headline)) {
                    Toggle("Use Dynamic Type", isOn: $settings.useDynamicType)
                        .dynamicFont(.body)
                        .accessibilityHint("When enabled, text will adapt to your system font size settings")
                    
                    if !settings.useDynamicType {
                        Picker("Font Size", selection: $settings.fontSizeAdjustment) {
                            ForEach(FontSizeAdjustment.allCases) { size in
                                Text(size.name)
                                    .dynamicFont(.body)
                                    .tag(size)
                            }
                        }
                        .dynamicFont(.body)
                    }
                    
                    Toggle("Use Haptic Feedback", isOn: $settings.useHaptics)
                        .dynamicFont(.body)
                        .accessibilityHint("When enabled, you'll feel subtle vibrations when interacting with the app")
                }
                
                // MARK: - Data Usage Section
                Section(header: Text("Data Usage").dynamicFont(.headline)) {
                    Toggle("Prefetch Images", isOn: $settings.prefetchImages)
                        .dynamicFont(.body)
                        .accessibilityHint("When enabled, images will be downloaded in advance for smoother scrolling")
                    
                    Toggle("High Quality Images", isOn: $settings.highQualityImages)
                        .dynamicFont(.body)
                        .accessibilityHint("When enabled, higher resolution images will be displayed")
                }
                
                // MARK: - About Section
                Section(header: Text("About").dynamicFont(.headline)) {
                    HStack {
                        Text("Version")
                            .dynamicFont(.body)
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .dynamicFont(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        Text("Reset All Settings")
                            .dynamicFont(.body)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .dynamicFont(.body)
                }
            }
            .alert("Reset Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values?")
                    .dynamicFont(.body)
            }
            .alert("Notification Permission Required", isPresented: $showNotificationPermissionAlert) {
                Button("Cancel", role: .cancel) {
                    settings.enableWakeUpNotification = false
                }
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications in Settings to use this feature.")
                    .dynamicFont(.body)
            }
        }
        .preferredColorScheme(settings.colorScheme)
    }
    
    // MARK: - Helper Methods
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus != .authorized {
                    showNotificationPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
} 