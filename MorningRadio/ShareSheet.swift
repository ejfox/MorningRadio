import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ShareSheet: UIViewControllerRepresentable {
    let scrap: Scrap
    @Environment(\.dismiss) private var dismiss
    
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
        
        // Primary URL handling - prefer scrap.url over metadata.url
        if let urlString = scrap.url ?? scrap.metadata?.url,
           let url = URL(string: urlString) {
            activities.append(CopyURLActivity(url: url))
            items.append(url)
        }
        
        // Fallback to href if no primary URL is available
        else if let hrefString = scrap.metadata?.href,
                let href = URL(string: hrefString) {
            activities.append(CopyURLActivity(url: href))
            items.append(href)
        }
        
        // Summary handling
        if let summary = scrap.summary {
            activities.append(CopySummaryActivity(summary: summary))
            items.append(summary)
        }
        
        // Main content
        items.append(scrap.content)
        
        // Location if available
        if let location = scrap.metadata?.location {
            items.append("📍 \(location)")
        }
        
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

private class CopySummaryActivity: UIActivity {
    private let summary: String
    
    init(summary: String) { self.summary = summary }
    
    override var activityTitle: String? { "Copy Summary" }
    override var activityImage: UIImage? { UIImage(systemName: "doc.on.doc") }
    override var activityType: UIActivity.ActivityType { .copySummary }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        UIPasteboard.general.string = summary
        HapticFeedback.success()
    }
}

// MARK: - Activity Types
private extension UIActivity.ActivityType {
    static let copyURL = UIActivity.ActivityType("com.morningradio.copyURL")
    static let copySummary = UIActivity.ActivityType("com.morningradio.copySummary")
}
