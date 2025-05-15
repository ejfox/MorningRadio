import WidgetKit
import SwiftUI

@main
struct MorningRadioWidgetBundle: WidgetBundle {
    var body: some Widget {
        MorningRadioWidget()
        MorningRadioConfigurableWidget()
        TypographyWidget()
    }
}

struct MorningRadioConfigurableWidget: Widget {
    private let kind = "MorningRadioConfigurableWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: ConfigurableProvider()
        ) { entry in
            ConfigurableWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .configurationDisplayName("Indexed Radio")
        .description("Start displaying scraps from a specific index.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct ConfigurableWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ConfigurableProvider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            BrutalistScrapView(
                scrap: entry.scraps.isEmpty ? Scrap.placeholder : entry.scraps[min(entry.configuration.startIndex, max(0, entry.scraps.count - 1))]
            )
        case .systemMedium:
            BrutalistMatrixView(
                scraps: Array(entry.scraps.dropFirst(min(entry.configuration.startIndex, max(0, entry.scraps.count - 1))).prefix(4))
            )
        case .systemLarge:
            BrutalistInfoDenseView(
                scraps: Array(entry.scraps.dropFirst(min(entry.configuration.startIndex, max(0, entry.scraps.count - 1))).prefix(3))
            )
        case .systemExtraLarge:
            BrutalistFullFeedView(
                scraps: Array(entry.scraps.dropFirst(min(entry.configuration.startIndex, max(0, entry.scraps.count - 1))).prefix(6))
            )
        @unknown default:
            BrutalistScrapView(
                scrap: entry.scraps.isEmpty ? Scrap.placeholder : entry.scraps[min(entry.configuration.startIndex, max(0, entry.scraps.count - 1))]
            )
        }
    }
}

struct ConfigurableEntry: TimelineEntry {
    let date: Date
    let scraps: [Scrap]
    let configuration: ConfigurationIntent
}

struct ConfigurableProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ConfigurableEntry {
        ConfigurableEntry(
            date: Date(),
            scraps: Array(repeating: Scrap.placeholder, count: 10),
            configuration: ConfigurationIntent()
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ConfigurableEntry) -> Void) {
        let entry = ConfigurableEntry(
            date: Date(),
            scraps: fetchScraps(count: 10),
            configuration: configuration
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<ConfigurableEntry>) -> Void) {
        let scraps = fetchScraps(count: 20)
        let currentDate = Date()
        
        // Update every hour or when new content is available
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        let entry = ConfigurableEntry(
            date: currentDate,
            scraps: scraps,
            configuration: configuration
        )
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

// MARK: - Customizable Widget Views

struct CustomCyberpunkView: View {
    let scrap: Scrap
    let configuration: ConfigurationIntent
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Grid lines
            if configuration.showGridBackground {
                GridBackgroundView(primaryColor: configuration.colorTheme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Timestamp
                Text(formattedDate(scrap.timestamp ?? Date()))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(configuration.colorTheme.secondaryColor)
                
                // Title
                Text(scrap.title ?? "Untitled Scrap")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(configuration.colorTheme.primaryColor)
                    .lineLimit(2)
                
                Spacer(minLength: 2)
                
                // Content preview
                Text(scrap.content.prefix(50) + "...")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(configuration.colorTheme.accentColor.opacity(0.8))
                    .lineLimit(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Overlay glitch effect
            if configuration.showGlitchEffect {
                GlitchOverlayView(color: configuration.colorTheme.primaryColor)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct CustomMatrixView: View {
    let scraps: [Scrap]
    let configuration: ConfigurationIntent
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Grid lines
            if configuration.showGridBackground {
                GridBackgroundView(primaryColor: configuration.colorTheme.primaryColor)
            }
            
            // Content grid
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    ForEach(scraps.prefix(2), id: \.self) { scrap in
                        CustomThumbnailView(scrap: scrap, configuration: configuration)
                    }
                }
                
                if scraps.count > 2 {
                    HStack(spacing: 1) {
                        ForEach(scraps.dropFirst(2).prefix(2), id: \.self) { scrap in
                            CustomThumbnailView(scrap: scrap, configuration: configuration)
                        }
                    }
                }
            }
            .padding(4)
            
            // Overlay glitch effect
            if configuration.showGlitchEffect {
                GlitchOverlayView(color: configuration.colorTheme.primaryColor)
            }
        }
    }
}

struct CustomInfoDenseView: View {
    let scraps: [Scrap]
    let configuration: ConfigurationIntent
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Grid lines
            if configuration.showGridBackground {
                GridBackgroundView(primaryColor: configuration.colorTheme.primaryColor)
            }
            
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
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(configuration.colorTheme.primaryColor, lineWidth: 1)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(configuration.colorTheme.primaryColor, lineWidth: 1)
                                        )
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(configuration.colorTheme.primaryColor, lineWidth: 1)
                                )
                        }
                        
                        // Text content
                        VStack(alignment: .leading, spacing: 2) {
                            // Timestamp
                            Text(formattedDate(scrap.timestamp ?? Date()))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(configuration.colorTheme.secondaryColor)
                            
                            // Title
                            Text(scrap.title ?? "Untitled Scrap")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(configuration.colorTheme.primaryColor)
                                .lineLimit(1)
                            
                            // Content
                            Text(scrap.content.prefix(120) + "...")
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundColor(configuration.colorTheme.accentColor.opacity(0.8))
                                .lineLimit(5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(8)
            
            // Overlay glitch effect
            if configuration.showGlitchEffect {
                GlitchOverlayView(color: configuration.colorTheme.primaryColor)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter.string(from: date)
    }
}

struct CustomFullFeedView: View {
    let scraps: [Scrap]
    let configuration: ConfigurationIntent
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Grid lines
            if configuration.showGridBackground {
                GridBackgroundView(primaryColor: configuration.colorTheme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("MORNING RADIO FEED")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(configuration.colorTheme.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                // Status line
                HStack {
                    Text("LAST UPDATE: \(formattedDate(Date()))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(configuration.colorTheme.secondaryColor)
                    
                    Spacer()
                    
                    Text("START INDEX: \(configuration.startIndex)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(configuration.colorTheme.secondaryColor)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                // Divider
                Rectangle()
                    .fill(configuration.colorTheme.primaryColor)
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
                                    .foregroundColor(configuration.colorTheme.secondaryColor)
                                    .frame(width: 20)
                                
                                // Content
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scrap.title ?? "Untitled Scrap")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(configuration.colorTheme.primaryColor)
                                        .lineLimit(1)
                                    
                                    Text(scrap.content.prefix(80) + "...")
                                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                                        .foregroundColor(configuration.colorTheme.accentColor.opacity(0.8))
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            
            // Overlay glitch effect
            if configuration.showGlitchEffect {
                GlitchOverlayView(color: configuration.colorTheme.primaryColor)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct CustomThumbnailView: View {
    let scrap: Scrap
    let configuration: ConfigurationIntent
    
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
                    .foregroundColor(configuration.colorTheme.secondaryColor)
                
                Text(scrap.title ?? "Untitled Scrap")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(configuration.colorTheme.accentColor)
                    .lineLimit(2)
            }
            .padding(6)
            .background(Color.black.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(configuration.colorTheme.primaryColor, lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct GridBackgroundView: View {
    var primaryColor: Color = .cyan
    
    var body: some View {
        ZStack {
            // Horizontal lines
            VStack(spacing: 15) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(primaryColor.opacity(0.15))
                        .frame(height: 0.5)
                }
            }
            
            // Vertical lines
            HStack(spacing: 15) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(primaryColor.opacity(0.15))
                        .frame(width: 0.5)
                }
            }
        }
    }
}

struct GlitchOverlayView: View {
    @State private var glitchOpacity = 0.0
    var color: Color = .cyan
    
    var body: some View {
        ZStack {
            // Scan line effect
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
            
            // Random glitch effect
            Rectangle()
                .fill(color.opacity(glitchOpacity))
                .blendMode(.screen)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true).delay(Double.random(in: 1...5))) {
                        glitchOpacity = Double.random(in: 0.01...0.05)
                    }
                }
        }
    }
} 