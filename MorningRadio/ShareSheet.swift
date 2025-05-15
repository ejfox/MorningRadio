import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    let url: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: UserSettings
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let (items, activities) = prepareShareContent()
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: activities
        )
        
        configureController(controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    // MARK: - Helper Methods
    private func prepareShareContent() -> (items: [Any], activities: [UIActivity]) {
        var items: [Any] = []
        var activities: [UIActivity] = []
        
        // Add URL if available
        if let urlString = url, let url = URL(string: urlString) {
            activities.append(CopyURLActivity(url: url))
            items.append(url)
        }
        
        // Add text content
        let cleanText = text.sanitizedHTML()
        items.append(cleanText)
        activities.append(CopyTextActivity(text: cleanText))
        
        return (items, activities)
    }
    
    private func configureController(_ controller: UIActivityViewController) {
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .saveToCameraRoll
        ]
        
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                DispatchQueue.main.async {
                    dismiss()
                }
                
                if settings.useHaptics {
                    HapticFeedback.success()
                }
            }
        }
    }
}

// MARK: - Custom Activities
private class CopyURLActivity: UIActivity {
    private let url: URL
    
    init(url: URL) { self.url = url }
    
    override var activityTitle: String? { "Copy URL" }
    override var activityImage: UIImage? { UIImage(systemName: "link") }
    override var activityType: UIActivity.ActivityType { .copyURL }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        UIPasteboard.general.url = url
        HapticFeedback.success()
    }
}

private class CopyTextActivity: UIActivity {
    private let text: String
    
    init(text: String) { self.text = text }
    
    override var activityTitle: String? { "Copy Text" }
    override var activityImage: UIImage? { UIImage(systemName: "doc.on.doc") }
    override var activityType: UIActivity.ActivityType { .copyText }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        UIPasteboard.general.string = text
        HapticFeedback.success()
    }
}

// MARK: - Activity Types
private extension UIActivity.ActivityType {
    static let copyURL = UIActivity.ActivityType("com.morningradio.copyURL")
    static let copyText = UIActivity.ActivityType("com.morningradio.copyText")
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// MARK: - String Extension
extension String {
    func sanitizedHTML() -> String {
        // Simple HTML tag removal
        var result = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Replace common HTML entities
        let entities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&nbsp;": " "
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
