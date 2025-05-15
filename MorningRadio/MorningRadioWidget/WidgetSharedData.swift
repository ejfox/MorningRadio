import Foundation
import CoreData
import WidgetKit

// MARK: - App Group Constants

struct AppGroupConstants {
    static let appGroupIdentifier = "group.com.morningradio.widget"
    static let widgetDataFileName = "widget_data.json"
    
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    }
    
    static var widgetDataURL: URL {
        containerURL.appendingPathComponent(widgetDataFileName)
    }
}

// MARK: - Widget Data Model

struct WidgetData: Codable {
    let lastUpdated: Date
    let scraps: [ScrapData]
}

struct ScrapData: Codable, Hashable {
    let id: String
    let title: String?
    let content: String
    let timestamp: Date?
    let screenshotUrl: String?
    let url: String?
    
    init(from scrap: Scrap) {
        self.id = scrap.id?.uuidString ?? UUID().uuidString
        self.title = scrap.title
        self.content = scrap.content
        self.timestamp = scrap.timestamp
        self.screenshotUrl = scrap.screenshotUrl
        self.url = scrap.url
    }
}

// MARK: - Widget Data Manager

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private init() {}
    
    // Update widget data from Core Data
    func updateWidgetData() {
        let scraps = fetchScrapsFromCoreData()
        let widgetData = WidgetData(
            lastUpdated: Date(),
            scraps: scraps.map { ScrapData(from: $0) }
        )
        
        saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Fetch scraps from Core Data
    private func fetchScrapsFromCoreData() -> [Scrap] {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Scrap> = Scrap.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Scrap.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 20
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching scraps for widget: \(error)")
            return []
        }
    }
    
    // Save widget data to shared container
    private func saveWidgetData(_ data: WidgetData) {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: AppGroupConstants.widgetDataURL)
        } catch {
            print("Error saving widget data: \(error)")
        }
    }
    
    // Load widget data from shared container
    func loadWidgetData() -> WidgetData? {
        do {
            let jsonData = try Data(contentsOf: AppGroupConstants.widgetDataURL)
            let decoder = JSONDecoder()
            return try decoder.decode(WidgetData.self, from: jsonData)
        } catch {
            print("Error loading widget data: \(error)")
            return nil
        }
    }
} 