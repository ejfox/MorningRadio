import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry

struct ScrapEntry: TimelineEntry {
    let date: Date
    let scraps: [Scrap]
    let configuration: ConfigurationIntent
}

// MARK: - Provider

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ScrapEntry {
        ScrapEntry(date: Date(), scraps: Array(repeating: Scrap.placeholder, count: 5), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ScrapEntry) -> Void) {
        let entry = ScrapEntry(date: Date(), scraps: fetchScraps(count: 5), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<ScrapEntry>) -> Void) {
        let scraps = fetchScraps(count: 10)
        let currentDate = Date()
        
        // Update every hour or when new content is available
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        let entry = ScrapEntry(date: currentDate, scraps: scraps, configuration: configuration)
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

// MARK: - Widget Views

struct MorningRadioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            BrutalistScrapView(scrap: entry.scraps.first ?? Scrap.placeholder)
        case .systemMedium:
            BrutalistMatrixView(scraps: Array(entry.scraps.prefix(4)))
        case .systemLarge:
            BrutalistInfoDenseView(scraps: Array(entry.scraps.prefix(3)))
        case .systemExtraLarge:
            BrutalistFullFeedView(scraps: Array(entry.scraps.prefix(6)))
        @unknown default:
            BrutalistScrapView(scrap: entry.scraps.first ?? Scrap.placeholder)
        }
    }
}

// MARK: - Widget Configuration

@main
struct MorningRadioWidget: Widget {
    private let kind = "MorningRadioWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider()
        ) { entry in
            MorningRadioWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .configurationDisplayName("Morning Radio")
        .description("Stay updated with your latest scraps.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

// MARK: - Brutalist Widget Styles

struct BrutalistScrapView: View {
    let scrap: Scrap
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            VStack(alignment: .leading, spacing: 4) {
                // Timestamp
                Text(formattedDate(scrap.timestamp ?? Date()))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                // Title
                Text(scrap.title ?? "Untitled Scrap")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer(minLength: 2)
                
                // Content preview
                Text(scrap.content.prefix(50) + "...")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Simple scanline effect (very subtle)
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct BrutalistMatrixView: View {
    let scraps: [Scrap]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Content grid
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    ForEach(scraps.prefix(2), id: \.self) { scrap in
                        BrutalistThumbnailView(scrap: scrap)
                    }
                }
                
                if scraps.count > 2 {
                    HStack(spacing: 1) {
                        ForEach(scraps.dropFirst(2).prefix(2), id: \.self) { scrap in
                            BrutalistThumbnailView(scrap: scrap)
                        }
                    }
                }
            }
            .padding(4)
            
            // Simple scanline effect (very subtle)
            ScanlineView()
        }
    }
}

struct BrutalistInfoDenseView: View {
    let scraps: [Scrap]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            VStack(spacing: 8) {
                ForEach(scraps, id: \.self) { scrap in
                    HStack(alignment: .top, spacing: 8) {
                        // Screenshot
                        if let screenshotUrl = scrap.screenshotUrl, !screenshotUrl.isEmpty {
                            AsyncImage(url: URL(string: screenshotUrl)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        
                        // Text content
                        VStack(alignment: .leading, spacing: 2) {
                            // Timestamp
                            Text(formattedDate(scrap.timestamp ?? Date()))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            // Title
                            Text(scrap.title ?? "Untitled Scrap")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            // Content
                            Text(scrap.content.prefix(120) + "...")
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(4)
                    .background(Color.black)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(8)
            
            // Simple scanline effect (very subtle)
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

struct BrutalistFullFeedView: View {
    let scraps: [Scrap]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("MORNING RADIO FEED")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                // Status line
                HStack {
                    Text("LAST UPDATE: \(formattedDate(Date()))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("ENTRIES: \(scraps.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                // Divider
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                
                // Scraps list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(scraps, id: \.self) { scrap in
                            HStack(alignment: .top, spacing: 8) {
                                // Index number
                                Text("#\(scraps.firstIndex(of: scrap)?.description ?? "?")")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 20)
                                
                                // Content
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scrap.title ?? "Untitled Scrap")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(scrap.content.prefix(80) + "...")
                                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.black)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            
            // Simple scanline effect (very subtle)
            ScanlineView()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

struct BrutalistThumbnailView: View {
    let scrap: Scrap
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background or screenshot
            if let screenshotUrl = scrap.screenshotUrl, !screenshotUrl.isEmpty {
                AsyncImage(url: URL(string: screenshotUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
            } else {
                Color.gray.opacity(0.2)
            }
            
            // Title overlay
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate(scrap.timestamp ?? Date()))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(scrap.title ?? "Untitled Scrap")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(6)
            .background(Color.black.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct ScanlineView: View {
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<50, id: \.self) { i in
                if i % 2 == 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                }
            }
        }
    }
}

// MARK: - Placeholder Data

extension Scrap {
    static var placeholder: Scrap {
        let scrap = Scrap()
        scrap.title = "Morning Radio Feed"
        scrap.content = "Loading latest information..."
        scrap.timestamp = Date()
        return scrap
    }
} 