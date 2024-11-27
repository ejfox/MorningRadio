import SwiftUI
import CoreData
import Foundation
import MapLibre

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
        return text.components(separatedBy: .newlines) // Split by newlines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Remove extra spaces
            .filter { !$0.isEmpty } // Exclude empty lines
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
            ZStack(alignment: .bottom) {
                // Background
                backgroundColor
                
                // Main Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: verticalSpacing) {
                        // Title
                        Text(scrap.content.sanitizedHTML())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .padding(.top, geometry.size.height * navigationBarHeight)
                            .frame(maxWidth: geometry.size.width - (horizontalPadding * 2), alignment: .leading)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Facts Content Area
                        if let summary = scrap.summary {
                            let facts = formatBulletPoints(summary.sanitizedHTML())
                            
                            if !facts.isEmpty {
                                // Current Fact
                                Text(facts[currentFactIndex])
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                    .id(currentFactIndex)
                                    .padding(.bottom, verticalSpacing)
                                    .frame(minHeight: 100) // Prevent layout shift
                            }
                        }
                        
                        // Map (when coordinates available)
                        if let latitude = scrap.latitude,
                           let longitude = scrap.longitude {
                            MapView(
                                latitude: latitude,
                                longitude: longitude,
                                zoomLevel: 13
                            )
                            .frame(height: mapHeight)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 20)
                        }
                        
                        // Metadata
                        if let metadataDictionary = metadataAsDictionary(scrap.metadata) {
                            ScrapMetadataView(metadata: metadataDictionary)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 50)
                        }
                        
                        Spacer(minLength: 120) // Space for bottom controls
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .frame(width: geometry.size.width)
                
                // Bottom Controls Area with Share Button
                VStack {
                    Spacer()
                    
                    // Navigation Controls
                    if let summary = scrap.summary {
                        let facts = formatBulletPoints(summary.sanitizedHTML())
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
                                        Circle()
                                            .fill(index == currentFactIndex ? textColor : textColor.opacity(0.2))
                                            .frame(width: 4, height: 4)
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
                            .padding(.bottom, 8) // Small gap above safe area
                        }
                    }
                    
                    // Share Button
                    HStack {
                        Spacer()
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred(intensity: 0.7)
                            withAnimation(springAnimation) {
                                showShareSheet = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(textColor.opacity(0.6))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, max(horizontalPadding, geometry.safeAreaInsets.trailing + 16))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
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
            Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ?
            .white :
            .black
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
