import WidgetKit
import SwiftUI
import CoreData

// MARK: - Typography Widget

struct TypographyWidget: Widget {
    private let kind = "TypographyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: TypographyProvider()
        ) { entry in
            TypographyWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .configurationDisplayName("Typography Feed")
        .description("Display scrap titles in a brutalist typography style.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Provider

struct TypographyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TypographyEntry {
        TypographyEntry(
            date: Date(),
            titles: ["LOADING CONTENT", "PLEASE WAIT", "STAND BY"]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TypographyEntry) -> Void) {
        let scraps = fetchScraps(count: 5)
        let titles = scraps.compactMap { $0.title?.uppercased() ?? "UNTITLED SCRAP" }
        let entry = TypographyEntry(date: Date(), titles: titles)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TypographyEntry>) -> Void) {
        let scraps = fetchScraps(count: 10)
        let titles = scraps.compactMap { $0.title?.uppercased() ?? "UNTITLED SCRAP" }
        
        let currentDate = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        let entry = TypographyEntry(date: currentDate, titles: titles)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    // Fetch scraps from Core Data
    private func fetchScraps(count: Int) -> [Scrap] {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Scrap> = Scrap.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Scrap.timestamp, ascending: false)]
        fetchRequest.fetchLimit = count
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching scraps: \(error)")
            return []
        }
    }
}

// MARK: - Entry

struct TypographyEntry: TimelineEntry {
    let date: Date
    let titles: [String]
}

// MARK: - Widget Views

struct TypographyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TypographyProvider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SingleTitleView(title: entry.titles.first ?? "NO CONTENT")
        case .systemMedium:
            ThreeTitlesView(titles: Array(entry.titles.prefix(3)))
        case .systemLarge:
            AllTitlesView(titles: Array(entry.titles.prefix(6)))
        @unknown default:
            SingleTitleView(title: entry.titles.first ?? "NO CONTENT")
        }
    }
}

// MARK: - Typography Views

struct SingleTitleView: View {
    let title: String
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("LATEST")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                Text(formattedDate(Date()))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Simple scanline effect
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

struct ThreeTitlesView: View {
    let titles: [String]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Titles
            VStack(alignment: .leading, spacing: 8) {
                Text("FEED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                ForEach(0..<min(3, titles.count), id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 20, alignment: .leading)
                        
                        Text(titles[index])
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                
                Spacer()
                
                Text(formattedDate(Date()))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Simple scanline effect
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

struct AllTitlesView: View {
    let titles: [String]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Titles
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("MORNING RADIO FEED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formattedDate(Date()))
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 8)
                
                // Divider
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1)
                    .padding(.bottom, 12)
                
                ForEach(0..<min(6, titles.count), id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 20, alignment: .leading)
                        
                        Text(titles[index])
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 6)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Simple scanline effect
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
} 