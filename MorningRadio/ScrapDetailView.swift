import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct ScrapDetailView: View {
    // MARK: - Properties
    let scrap: Scrap
    let uiImage: UIImage?
    let dismissAction: () -> Void
    
    // MARK: - State
    @State private var showShareSheet = false
    @State private var isAppearing = false
    @State private var currentFactIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    @GestureState private var dragState = DragState.inactive
    @State private var position: CGFloat = 0
    @EnvironmentObject private var settings: UserSettings
    
    // MARK: - Constants
    private let navigationBarHeight: CGFloat = 0.08
    private let horizontalPadding: CGFloat = 24
    private let verticalSpacing: CGFloat = 24
    
    // Animation timing curves
    private let appearanceAnimation = Animation.easeOut(duration: 0.8)
    private let carouselAnimation = Animation.easeInOut(duration: 0.3)
    private let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Helper Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var facts: [String] {
        processFacts(from: scrap.summary)
    }
    
    // MARK: - View Body
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                // Background Image (if available)
                if uiImage != nil {
                    Image(uiImage: uiImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 20)
                        .opacity(0.15)
                        .ignoresSafeArea()
                } else if scrap.screenshotUrl != nil {
                    OptimizedImage(
                        url: scrap.screenshotUrl,
                        size: geometry.size,
                        mode: .fill,
                        contentMode: .fill
                    )
                    .blur(radius: 20)
                    .opacity(0.15)
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = scrap.title {
                            Text(title)
                                .dynamicFont(.title)
                                .foregroundColor(textColor)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, geometry.size.height * 0.05)
                                .padding(.horizontal, horizontalPadding)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                        }
                        
                        if let url = scrap.url {
                            Text(url)
                                .dynamicFont(.caption)
                                .foregroundColor(textColor.opacity(0.6))
                                .lineLimit(1)
                                .padding(.horizontal, horizontalPadding)
                                .opacity(isAppearing ? 0.6 : 0)
                                .offset(y: isAppearing ? 0 : 10)
                        }
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .padding(.bottom, verticalSpacing)
                    
                    // Fact carousel
                    if !facts.isEmpty {
                        FactCarouselView(
                            facts: facts,
                            currentIndex: $currentFactIndex,
                            textColor: textColor,
                            geometry: geometry
                        )
                        .padding(.horizontal, horizontalPadding)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 30)
                    } else {
                        ScrollView {
                            Text(scrap.content.sanitizedHTML())
                                .dynamicFont(.body)
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, horizontalPadding)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 30)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(textColor)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(textColor.opacity(0.1)))
                        }
                        .accessibilityLabel("Share")
                        
                        Spacer()
                        
                        Button(action: dismissAction) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(textColor)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(textColor.opacity(0.1)))
                        }
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, geometry.size.height * 0.05)
                    .opacity(isAppearing ? 1 : 0)
                }
                .frame(width: geometry.size.width)
            }
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        state = .dragging(translation: value.translation)
                    }
                    .onEnded { value in
                        let threshold = geometry.size.height * 0.25
                        if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
                            dismissAction()
                        }
                    }
            )
            .offset(y: dragState.translation?.height ?? 0)
            .animation(springAnimation, value: dragState.translation)
            .onAppear {
                withAnimation(appearanceAnimation) {
                    isAppearing = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: scrap.content, url: scrap.url)
                    .environmentObject(settings)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func processFacts(from summary: String?) -> [String] {
        guard let summary = summary else { return [] }
        
        // Split by newlines and filter out empty lines
        let lines = summary.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return lines
    }
}

// MARK: - Fact Carousel View
struct FactCarouselView: View {
    let facts: [String]
    @Binding var currentIndex: Int
    let textColor: Color
    let geometry: GeometryProxy
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(spacing: 16) {
            // Fact content
            ZStack {
                ForEach(0..<facts.count, id: \.self) { index in
                    VStack {
                        Text(facts[index])
                            .dynamicFont(.body)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(width: geometry.size.width - 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(textColor.opacity(0.05))
                            )
                    }
                    .opacity(currentIndex == index ? 1 : 0)
                    .scaleEffect(currentIndex == index ? 1 : 0.8)
                    .offset(x: CGFloat(index - currentIndex) * geometry.size.width)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 && currentIndex < facts.count - 1 {
                                    withAnimation {
                                        currentIndex += 1
                                    }
                                    if settings.useHaptics {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                } else if value.translation.width > 50 && currentIndex > 0 {
                                    withAnimation {
                                        currentIndex -= 1
                                    }
                                    if settings.useHaptics {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                }
                            }
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Fact \(index + 1) of \(facts.count)")
                    .accessibilityValue(facts[index])
                    .accessibilityHint("Swipe left or right to navigate between facts")
                }
            }
            
            // Pagination indicators
            HStack(spacing: 8) {
                ForEach(0..<facts.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? textColor : textColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentIndex == index ? 1.2 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        .onTapGesture {
                            withAnimation {
                                currentIndex = index
                            }
                            if settings.useHaptics {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        }
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Drag State
enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize? {
        switch self {
        case .inactive:
            return nil
        case .dragging(let translation):
            return translation
        }
    }
}
