import WidgetKit
import SwiftUI

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            title: "Morning Radio",
            content: "The latest news and updates from around the web",
            imageURL: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        // For previews, return a placeholder
        let entry = SimpleEntry(
            date: Date(),
            title: "Breaking News",
            content: "Scientists discover that coffee in the morning improves productivity by 73%",
            imageURL: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        Task {
            do {
                // Fetch the latest scrap from Supabase
                let rawResponse = try await SupabaseManager.shared.client
                    .from("scraps")
                    .select("id, content, title, screenshot_url")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scraps = try decoder.decode([Scrap].self, from: rawResponse.data)
                
                if let latestScrap = scraps.first {
                    // Create an entry with the latest scrap
                    let content = latestScrap.content.sanitizedHTML()
                    let entry = SimpleEntry(
                        date: Date(),
                        title: latestScrap.title ?? "Morning Radio",
                        content: content.truncated(to: 150),
                        imageURL: latestScrap.screenshotUrl
                    )
                    
                    // Update every 30 minutes
                    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
                    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                    
                    completion(timeline)
                } else {
                    // Fallback if no scraps are found
                    let entry = SimpleEntry(
                        date: Date(),
                        title: "Morning Radio",
                        content: "Check back later for updates",
                        imageURL: nil
                    )
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
                    completion(timeline)
                }
            } catch {
                // Handle errors
                print("Widget error: \(error)")
                let entry = SimpleEntry(
                    date: Date(),
                    title: "Morning Radio",
                    content: "Unable to load content",
                    imageURL: nil
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
    let imageURL: String?
}

// MARK: - Widget View
struct MorningRadioWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Background
            if let imageURL = entry.imageURL, let url = URL(string: imageURL) {
                OptimizedAsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                Rectangle()
                                    .fill(.black.opacity(0.6))
                            )
                    } else if phase.error != nil {
                        Color.black.opacity(0.8)
                    } else {
                        Color.black.opacity(0.8)
                    }
                }
                .ignoresSafeArea()
            } else {
                Color.black.opacity(0.8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(entry.content)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(family == .systemSmall ? 3 : 6)
                    .padding(.top, 2)
                
                Spacer()
                
                HStack {
                    Image(systemName: "radio")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Morning Radio")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .widgetURL(URL(string: "morningradio://latest"))
    }
}

// MARK: - Widget Configuration
struct MorningRadioWidget: Widget {
    let kind: String = "MorningRadioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MorningRadioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Latest Update")
        .description("See the most recent content from Morning Radio.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
struct MorningRadioWidget_Previews: PreviewProvider {
    static var previews: some View {
        MorningRadioWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            title: "Breaking News",
            content: "Scientists discover that coffee in the morning improves productivity by 73%",
            imageURL: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        MorningRadioWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            title: "Breaking News",
            content: "Scientists discover that coffee in the morning improves productivity by 73%. Further studies show that adding a pastry increases happiness levels.",
            imageURL: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
} 