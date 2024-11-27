import SwiftUI
import Combine

struct LoadingView: View {
    // MARK: - State
    @State private var progressValue: Double = 0
    @State private var isInitialLoad: Bool = true
    @State private var minimumLoadingTimeElapsed = false
    @State private var currentTitleIndex: Int = 0
    @State private var showTitles: Bool = false
    
    // MARK: - Properties
    var scraps: [Scrap] = [] {
        didSet {
            if !scraps.isEmpty {
                startTitleScrolling()
            }
        }
    }
    
    // MARK: - Constants
    private let loadingDuration: Double = 2.0
    private let titleScrollDuration: Double = 0.15  // Duration per title
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Title
                    Text("MORNING RADIO")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .opacity(0.8)
                    
                    // Date
                    Text(Date().formatted(.dateTime.weekday().month().day()))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .opacity(0.6)
                    
                    // Scrolling Titles
                    if showTitles && !scraps.isEmpty {
                        Text(truncateTitle(scraps[currentTitleIndex].content))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .opacity(0.4)
                            .lineLimit(1)
                            .transition(.move(edge: .trailing))
                            .id(currentTitleIndex)  // Force view update
                    }
                }
                
                // Border Text
                BorderTextView(
                    topText: "MORNING",
                    bottomText: "LOADING",
                    leftText: "YOU ARE WHAT YOU EAT",
                    rightText: "LIVE IN UNCERTAINTY"
                )
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .opacity(0.3)
                
                // Edge Tracing Line
                ScreenEdgeShape()
                    .trim(from: 0, to: progressValue)
                    .stroke(Color.red, lineWidth: 2)
                    .opacity(1.0)
                    .animation(.linear(duration: loadingDuration), value: progressValue)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
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
        showTitles = true
        animateNextTitle()
    }
    
    private func animateNextTitle() {
        guard !scraps.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: titleScrollDuration)) {
            currentTitleIndex = (currentTitleIndex + 1) % scraps.count
        }
        
        // Schedule next title change
        DispatchQueue.main.asyncAfter(deadline: .now() + titleScrollDuration) {
            if !minimumLoadingTimeElapsed {
                animateNextTitle()
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

// Add this new shape struct at the bottom of LoadingView.swift
struct ScreenEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Get actual device corner radius
        let cornerRadius: CGFloat = 47  // iPhone 14/15 Pro corner radius
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

// Add BorderTextView struct:
struct BorderTextView: View {
    let topText: String
    let bottomText: String
    let leftText: String
    let rightText: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top Text
                Text(topText)
                    .rotationEffect(.degrees(0))
                    .position(x: geometry.size.width/2, y: 20)
                
                // Bottom Text
                Text(bottomText)
                    .rotationEffect(.degrees(0))
                    .position(x: geometry.size.width/2, y: geometry.size.height - 20)
                
                // Left Text
                Text(leftText)
                    .rotationEffect(.degrees(-90))
                    .position(x: 20, y: geometry.size.height/2)
                
                // Right Text
                Text(rightText)
                    .rotationEffect(.degrees(90))
                    .position(x: geometry.size.width - 20, y: geometry.size.height/2)
            }
        }
    }
}

#Preview {
    LoadingView()
}
