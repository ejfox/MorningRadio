import SwiftUI
import WidgetKit

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), title: "Morning Radio", content: "Latest news and updates")
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let entry = ComplicationEntry(date: Date(), title: "Morning Radio", content: "Latest news and updates")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        // Fetch the latest scrap
        Task {
            do {
                let rawResponse = try await SupabaseManager.shared.client
                    .from("scraps")
                    .select("id, content, title")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedScraps = try decoder.decode([Scrap].self, from: rawResponse.data)
                
                if let latestScrap = decodedScraps.first {
                    let content = latestScrap.content.sanitizedHTML()
                    let title = latestScrap.title ?? "Morning Radio"
                    
                    // Create an entry with the latest content
                    let entry = ComplicationEntry(
                        date: Date(),
                        title: title,
                        content: content.prefix(50) + (content.count > 50 ? "..." : "")
                    )
                    
                    // Update every hour
                    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                    
                    completion(timeline)
                } else {
                    let entry = ComplicationEntry(date: Date(), title: "Morning Radio", content: "Check for updates")
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
                    completion(timeline)
                }
            } catch {
                let entry = ComplicationEntry(date: Date(), title: "Morning Radio", content: "Unable to update")
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
}

struct ComplicationView: View {
    var entry: ComplicationProvider.Entry

    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .accessoryCorner:
            Image(systemName: "radio")
                .font(.title3)
        case .accessoryCircular:
            VStack {
                Image(systemName: "radio")
                    .font(.caption)
                Text("MR")
                    .font(.caption2)
            }
        case .accessoryRectangular, .accessoryInline:
            VStack(alignment: .leading) {
                Text(entry.title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(entry.content)
                    .font(.caption2)
                    .lineLimit(1)
            }
        @unknown default:
            Text("Morning Radio")
        }
    }
}

@main
struct MorningRadioComplication: Widget {
    let kind: String = "MorningRadioComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Morning Radio")
        .description("See the latest content from Morning Radio.")
        .supportedFamilies([
            .accessoryCorner,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
} 