import SwiftUI
import CoreData
import Foundation

#if os(iOS)
import UIKit
#endif


/// A detailed view for displaying a scrap's content, summary facts, location, and metadata
/// Features:
/// - Fact carousel with gesture-based navigation
/// - Interactive map (when coordinates are available)
/// - Share functionality
/// - Dark mode support
/// - Haptic feedback
/// - Fluid animations and transitions
struct ScrapDetailView: View {
    // MARK: - Properties
    let scrap: Scrap
    let uiImage: UIImage?
    let dismissAction: () -> Void
    
    // MARK: - State
    @State private var showShareSheet: Bool = false
    @State private var isAppearing = false
    @State private var currentFactIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAllFacts: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var dragVelocity: CGFloat = 0
    @GestureState private var isDragging = false
    
    // MARK: - Constants
    private let navigationBarHeight: CGFloat = 0.08 // 8% of screen height
    private let carouselButtonSize: CGFloat = 60
    private let shareButtonSize: CGFloat = 50
    private let mapHeight: CGFloat = 180
    private let horizontalPadding: CGFloat = 24
    private let verticalSpacing: CGFloat = 24
    private let cornerRadius: CGFloat = 16
    
    // Animation timing curves
    private let appearanceAnimation = Animation.easeOut(duration: 0.8)
    private let carouselAnimation = Animation.easeInOut(duration: 0.3)
    private let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Helper Functions

    /// Splits text by newlines and cleans up whitespace
    private func formatBulletPoints(_ text: String) -> [String] {
        var facts = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Add map if we have valid location
        if hasValidLocation {
            facts.append("MAP_VIEW_PLACEHOLDER")
        }
        
        // Add metadata if we have any
        if let metadata = scrap.metadata,
           !metadata.displayableProperties().isEmpty {
            facts.append("METADATA_VIEW_PLACEHOLDER")
        }
        
        return facts
    }
    
    /// Navigates to the next or previous fact with haptic feedback
    private func navigateFacts(forward: Bool, totalCount: Int) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(carouselAnimation) {
            if forward {
                currentFactIndex = (currentFactIndex + 1) % totalCount
            } else {
                currentFactIndex = (currentFactIndex - 1 + totalCount) % totalCount
            }
        }
    }
    
    // MARK: - View Body
    var body: some View {
        GeometryReader { geometry in
            // Extract facts processing to a computed property
            let facts = processFacts(from: scrap.summary)
            
            ZStack(alignment: .bottom) {
                // Background
                backgroundColor
                
                // Main Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: verticalSpacing) {
                        // Title section
                        if shouldShowTitle(for: facts) {
                            titleSection(geometry: geometry)
                        }
                        
                        // Facts Content Area
                        if !facts.isEmpty {
                            factContent(facts: facts, geometry: geometry)
                        }
                        
                        // Metadata section
                        metadataSection
                        
                        Spacer(minLength: 120)
                    }
                }
                .frame(width: geometry.size.width)
                
                // All Facts Overlay
                if showAllFacts {
                    factsOverlay(facts: facts)
                }
                
                // Bottom Controls
                bottomControls(facts: facts, geometry: geometry)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showShareSheet) {
                if let urlString = scrap.metadata?.href,
                   let url = URL(string: urlString) {
                    ShareSheet(items: [url])
                } else {
                    ShareSheet(items: [scrap.content.sanitizedHTML()])
                }
            }
            .gesture(
                DragGesture()
                    .updating($isDragging) { value, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        // Only allow downward dragging
                        let translation = value.translation.height
                        if translation > 0 {
                            dragOffset = translation
                            // Use the built-in velocity property
                            dragVelocity = value.predictedEndTranslation.height - value.translation.height
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        
                        // Dismiss if dragged down more than 20% of screen height or with sufficient velocity
                        if translation > UIScreen.main.bounds.height * 0.2 || velocity > 500 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dismissAction()
                            }
                        } else {
                            // Reset if not dragged enough
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .offset(y: dragOffset)
            .opacity(max(0, min(1, 1.0 - (dragOffset / (UIScreen.main.bounds.height / 2)))))
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(appearanceAnimation) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            withAnimation(carouselAnimation) {
                dismissAction()
            }
        }
    }
    
    // MARK: - Helper Properties
    private func metadataAsDictionary(_ metadata: Metadata?) -> [String: Any]? {
        guard let metadata = metadata else { return nil }
        return metadata.displayableProperties().reduce(into: [String: Any]()) { dict, item in
            dict[item.key] = item.value
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ?
            Color(red: 0.1, green: 0.1, blue: 0.2) :
            Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var textColor: Color {
        colorScheme == .dark ?
            .white :
            .black
    }
    
    // First, add a computed property to check for valid location
    private var hasValidLocation: Bool {
        guard let lat = scrap.latitude,
              let lon = scrap.longitude else {
            return false
        }
        // Basic validation that coordinates are reasonable
        return lat != 0 && lon != 0
    }
    
    // Helper functions to break up the complexity:
    private func processFacts(from summary: String?) -> [String] {
        guard let summary = summary else { return [] }
        return formatBulletPoints(summary.sanitizedHTML())
    }
    
    private func shouldShowTitle(for facts: [String]) -> Bool {
        !facts.isEmpty && facts[currentFactIndex] != "MAP_VIEW_PLACEHOLDER"
    }
    
    private func titleSection(geometry: GeometryProxy) -> some View {
        Text(scrap.content.sanitizedHTML())
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .multilineTextAlignment(.leading)
            .padding(.top, geometry.size.height * navigationBarHeight)
            .frame(maxWidth: geometry.size.width - (horizontalPadding * 2), alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .opacity(isAppearing ? 1 : 0)
            .offset(y: isAppearing ? 0 : 30)
    }
    
    private func factContent(facts: [String], geometry: GeometryProxy) -> some View {
        Group {
            if facts[currentFactIndex] == "MAP_VIEW_PLACEHOLDER" {
                mapView(geometry: geometry)
            } else if facts[currentFactIndex] == "METADATA_VIEW_PLACEHOLDER" {
                metadataView(geometry: geometry)
            } else {
                regularFactView(fact: facts[currentFactIndex], geometry: geometry)
            }
        }
    }
    
    // Add other helper views...

    private func mapView(geometry: GeometryProxy) -> some View {
        MapView(
            latitude: scrap.latitude!,
            longitude: scrap.longitude!,
            zoomLevel: 8,
            startZoomLevel: 0
        )
        .frame(maxWidth: UIScreen.main.bounds.width)
        .frame(height: UIScreen.main.bounds.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
        .edgesIgnoringSafeArea(.all)
        .transition(.asymmetric(
            insertion: .opacity,
            removal: .opacity
        ))
    }

    private func metadataView(geometry: GeometryProxy) -> some View {
        if let metadataDictionary = metadataAsDictionary(scrap.metadata) {
            return ScrapMetadataView(metadata: metadataDictionary)
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.7)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .eraseToAnyView()
        } else {
            return EmptyView().eraseToAnyView()
        }
    }

    private func regularFactView(fact: String, geometry: GeometryProxy) -> some View {
        VStack {
            Text(fact)
                .font(.system(
                    size: fact.count > 200 ? 24 : 32,
                    weight: .regular,
                    design: .rounded
                ))
                .foregroundColor(textColor.opacity(0.9))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalSpacing)
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height * 0.5,
                    maxHeight: .infinity,
                    alignment: .center
                )
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func factsOverlay(facts: [String]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                    if fact != "MAP_VIEW_PLACEHOLDER" && fact != "METADATA_VIEW_PLACEHOLDER" {
                        Text(fact)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(textColor.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? 
                                        Color.white.opacity(0.1) : 
                                        Color.black.opacity(0.05)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        index == currentFactIndex ? 
                                            textColor.opacity(0.3) : 
                                            Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            BlurView(style: colorScheme == .dark ? .dark : .light)
                .opacity(0.98)
        )
        .transition(.opacity)
    }

    private func bottomControls(facts: [String], geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            // Navigation Controls
            if !facts.isEmpty {
                HStack {
                    // Previous Button with large touch target
                    Button(action: { navigateFacts(forward: false, totalCount: facts.count) }) {
                        HStack {
                            Color.clear
                                .frame(width: geometry.size.width * 0.3, height: carouselButtonSize)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(textColor.opacity(0.6))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Progress Indicators
                    HStack(spacing: 6) {
                        ForEach(0..<facts.count, id: \.self) { index in
                            if facts[index] == "MAP_VIEW_PLACEHOLDER" {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(index == currentFactIndex ? textColor : textColor.opacity(0.2))
                            } else if facts[index] == "METADATA_VIEW_PLACEHOLDER" {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(index == currentFactIndex ? textColor : textColor.opacity(0.2))
                            } else {
                                Circle()
                                    .fill(index == currentFactIndex ? textColor : textColor.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Next Button with large touch target
                    Button(action: { navigateFacts(forward: true, totalCount: facts.count) }) {
                        HStack {
                            Color.clear
                                .frame(width: geometry.size.width * 0.3, height: carouselButtonSize)
                                .overlay(
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(textColor.opacity(0.6))
                                )
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 8)
            }
        }
    }

    // Add this computed property after the other helper views:

    private var metadataSection: some View {
        Group {
            if let metadataDictionary = metadataAsDictionary(scrap.metadata),
               !metadataDictionary.isEmpty {
                ScrapMetadataView(metadata: metadataDictionary)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 50)
            }
        }
    }
}

// MARK: - String Extension
extension String {
    func sanitizedHTML() -> String {
        // First try a simple cleanup if possible
        let cleanedString = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                               .replacingOccurrences(of: "&[^;]+;", with: "", options: .regularExpression, range: nil)
        
        // Only attempt NSAttributedString conversion if we have actual HTML
        guard self.contains("<") || self.contains("&"),
              let data = self.data(using: .utf8) else {
            return cleanedString
        }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(data: data,
                                                        options: options,
                                                        documentAttributes: nil)
            return attributedString.string
        } catch {
            print("HTML sanitization failed: \(error)")
            return cleanedString // Fallback to basic cleanup
        }
    }
}

// Add this extension for type erasure
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
