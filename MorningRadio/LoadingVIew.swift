import SwiftUI
import Combine
import Shiny
import ScreenCorners

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: UserSettings
    
    // MARK: - State
    @State private var progressValue: Double = 0
    @State private var isInitialLoad: Bool = true
    @State private var minimumLoadingTimeElapsed = false
    @State private var currentTitleIndex: Int = 0
    @State private var showTitles: Bool = true
    
    // MARK: - Properties
    let scraps: [Scrap]
    
    // MARK: - Constants
    private let loadingDuration: Double = 2.0
    private let titleScrollDuration: Double = 0.5
    
    // Update color properties to be computed
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? .blue : .blue.opacity(0.7)
    }
    
    // Adjust glow properties based on color scheme
    private var glowOpacity: Double {
        colorScheme == .dark ? 0.6 : 0.4
    }
    
    private var glowRadius: CGFloat {
        colorScheme == .dark ? 8.0 : 6.0
    }
    
    private var lineWidth: CGFloat {
        colorScheme == .dark ? 3.0 : 2.5
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                // Edge Tracing Line with enhanced shine and glow
                ScreenEdgeShape(cornerRadius: UIScreen.main.displayCornerRadius)
                    .trim(from: 0, to: progressValue)
                    .stroke(primaryColor, lineWidth: lineWidth)
                    .shadow(color: accentColor.opacity(glowOpacity), radius: glowRadius)
                    .opacity(1.0)
                    .animation(.linear(duration: loadingDuration), value: progressValue)
                    .shiny(Gradient(stops: [
                        .init(color: primaryColor, location: 0),
                        .init(color: accentColor.opacity(0.5), location: 0.3),
                        .init(color: primaryColor, location: 0.6),
                        .init(color: accentColor.opacity(0.5), location: 1.0)
                    ]))
                
                VStack(spacing: 40) {
                    // Title with shiny effect
                    Text("MORNING RADIO")
                        .dynamicFont(.headline)
                        .foregroundColor(primaryColor)
                        .opacity(0.8)
                        .shiny(Gradient(stops: [
                            .init(color: primaryColor, location: 0),
                            .init(color: Color.clear, location: 0.5),
                            .init(color: primaryColor, location: 1)
                        ]))
                    
                    // Date with subtle shine
                    Text(Date().formatted(.dateTime.weekday().month().day()))
                        .dynamicFont(.caption)
                        .foregroundColor(primaryColor)
                        .opacity(0.6)
                        .shiny(Gradient(stops: [
                            .init(color: primaryColor, location: 0),
                            .init(color: accentColor.opacity(0.5), location: 0.5),
                            .init(color: primaryColor, location: 1)
                        ]))
                    
                    // Scrolling Titles
                    if showTitles && !scraps.isEmpty {
                        Text(truncateTitle(scraps[currentTitleIndex].content))
                            .dynamicFont(.caption2)
                            .foregroundColor(primaryColor)
                            .opacity(0.4)
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id(currentTitleIndex)
                            .shiny(Gradient(stops: [
                                .init(color: primaryColor, location: 0),
                                .init(color: Color.clear, location: 0.3),
                                .init(color: primaryColor.opacity(0.5), location: 0.7),
                                .init(color: Color.clear, location: 1)
                            ]))
                            .accessibilityLabel("Loading content: \(truncateTitle(scraps[currentTitleIndex].content))")
                    }
                }
                
                // Border Text
                BorderTextView(
                    topText: "MORNING",
                    bottomText: "LOADING",
                    leftText: "YOU ARE WHAT YOU EAT",
                    rightText: "LIVE IN UNCERTAINTY",
                    textColor: primaryColor,
                    shineGradient: Gradient(stops: [
                        .init(color: primaryColor.opacity(0.8), location: 0),
                        .init(color: Color.clear, location: 0.5),
                        .init(color: primaryColor.opacity(0.3), location: 1)
                    ])
                )
                .dynamicFont(.caption2)
                .opacity(0.3)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            if !scraps.isEmpty {
                startTitleScrolling()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Morning Radio")
        .accessibilityValue("\(Int(progressValue * 100))% complete")
    }
    
    // MARK: - Helper Functions
    private func truncateTitle(_ title: String) -> String {
        let cleaned = title.sanitizedHTML()
        let maxLength = 24
        if cleaned.count > maxLength {
            let index = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
            return String(cleaned[..<index]) + "..."
        }
        return cleaned
    }
    
    private func startTitleScrolling() {
        guard !scraps.isEmpty else { return }
        
        // Start the title animation loop
        Timer.scheduledTimer(withTimeInterval: titleScrollDuration, repeats: true) { timer in
            if minimumLoadingTimeElapsed {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: titleScrollDuration/2)) {
                currentTitleIndex = (currentTitleIndex + 1) % scraps.count
            }
        }
    }
    
    // MARK: - Animation Control
    private func startAnimations() {
        // Reset all states
        isInitialLoad = true
        progressValue = 0
        minimumLoadingTimeElapsed = false
        
        // Start the edge line animation
        withAnimation(.linear(duration: loadingDuration)) {
            progressValue = 1.0
        }
        
        // Set minimum loading time completion
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
            withAnimation {
                minimumLoadingTimeElapsed = true
                isInitialLoad = false
            }
        }
    }
    
    var shouldDismissLoading: Bool {
        progressValue >= 1.0 && minimumLoadingTimeElapsed
    }
}

// Update ScreenEdgeShape to use the correct corner radius
struct ScreenEdgeShape: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let padding: CGFloat = 0  // Remove padding to go right to the edge
        
        let innerRect = CGRect(
            x: padding,
            y: padding,
            width: rect.width - (padding * 2),
            height: rect.height - (padding * 2)
        )
        
        // Start from top-left and trace clockwise
        path.move(to: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY))
        
        // Top-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY - cornerRadius))
        
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.maxY))
        
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.minY + cornerRadius))
        
        // Top-left corner
        path.addArc(
            center: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        return path
    }
}

// Add this extension to get the device's corner radius
extension UIScreen {
    var displayCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let cornerRadius = value(forKey: key) as? CGFloat {
            return cornerRadius
        }
        return 39 // Default iPhone corner radius if we can't get the actual value
    }
}

// Update BorderTextView
struct BorderTextView: View {
    let topText: String
    let bottomText: String
    let leftText: String
    let rightText: String
    let textColor: Color
    let shineGradient: Gradient
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top Text
                Text(topText)
                    .dynamicFont(.caption2)
                    .foregroundColor(textColor)
                    .shiny(shineGradient)
                    .position(x: geometry.size.width / 2, y: 20)
                
                // Bottom Text
                Text(bottomText)
                    .dynamicFont(.caption2)
                    .foregroundColor(textColor)
                    .shiny(shineGradient)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 20)
                
                // Left Text (rotated)
                Text(leftText)
                    .dynamicFont(.caption2)
                    .foregroundColor(textColor)
                    .shiny(shineGradient)
                    .rotationEffect(Angle(degrees: -90))
                    .position(x: 20, y: geometry.size.height / 2)
                
                // Right Text (rotated)
                Text(rightText)
                    .dynamicFont(.caption2)
                    .foregroundColor(textColor)
                    .shiny(shineGradient)
                    .rotationEffect(Angle(degrees: 90))
                    .position(x: geometry.size.width - 20, y: geometry.size.height / 2)
            }
        }
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

#Preview {
    LoadingView(scraps: [
        Scrap(id: UUID(), content: "Loading content example 1", title: "Example 1"),
        Scrap(id: UUID(), content: "Loading content example 2", title: "Example 2"),
        Scrap(id: UUID(), content: "Loading content example 3", title: "Example 3")
    ])
    .environmentObject(UserSettings.shared)
}
