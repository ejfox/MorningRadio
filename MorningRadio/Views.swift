//
//  Views.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI
import UIKit

extension CGFloat {
    var degrees: Angle {
        Angle(degrees: Double(self))
    }
}



// MARK: - VerticalPagingView
struct VerticalPagingView: View {
    let scraps: [Scrap]
    @Binding var selectedScrap: Scrap?
    @Binding var selectedImage: UIImage?
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isAppearing = false
    @State private var velocityY: CGFloat = 0
    @State private var lastDragTime: Date = Date()
    @State private var lastDragPosition: CGFloat = 0
    
    // Animation and interaction constants
    private let velocityThreshold: CGFloat = 200
    private let dragThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let springAnimation = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 100,
        damping: 20,
        initialVelocity: 0
    )
    
    // And let's break up that complex transform calculation:
    private func calculateTransforms(
        for index: Int,
        geometry: GeometryProxy
    ) -> (offset: CGFloat, scale: CGFloat, rotation: Angle, opacity: CGFloat) {
        let offset = CGFloat(index - currentIndex)
        let dragProgress = dragOffset / geometry.size.height
        
        // Calculate offset
        let baseOffset = CGFloat(index - currentIndex) * geometry.size.height
        let dragInfluence = dragOffset * (1 - abs(offset) * 0.5)
        let finalOffset = baseOffset + dragInfluence
        
        // Calculate scale
        let scale = 1 - abs(offset + dragProgress) * 0.1
        
        // Calculate rotation
        let rotationBase = dragProgress * 2
        let rotationAmount = offset == 0 ? rotationBase : rotationBase * (1 / (abs(offset) + 1))
        let rotation = Angle(degrees: Double(rotationAmount))
        
        // Calculate opacity
        let opacityBase = 1 - abs(offset + dragProgress) * 0.3
        let opacityBoost = max(0, 1 - abs(dragProgress) * 2)
        let opacity = min(1, opacityBase + (index == currentIndex ? opacityBoost * 0.2 : 0))

        return (finalOffset, scale, rotation, opacity)
    }
    
    private let visibleRange = 1 // How many views to keep loaded before/after current
    private var visibleIndices: Range<Int> {
        let start = max(0, currentIndex - visibleRange)
        let end = min(scraps.count, currentIndex + visibleRange + 1)
        return start..<end
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.2, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: min(abs(dragOffset) / 50, 10))
                .ignoresSafeArea()
                
                // Scrap cards
                ForEach(scraps.indices, id: \.self) { index in
                    if visibleIndices.contains(index) {
                        let transforms = calculateTransforms(for: index, geometry: geometry)
                        
                        ScrapView(
                            scrap: scraps[index],
                            selectedScrap: $selectedScrapa ,
                            selectedImage: $selectedImage,
                            currentIndex: $currentIndex,
                            index: index
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .offset(y: transforms.offset)
                        .scaleEffect(transforms.scale)
                        .rotation3DEffect(
                            transforms.rotation,
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .center,
                            anchorZ: 0,
                            perspective: 1
                        )
                        .opacity(transforms.opacity)
                        // Add subtle shadow animation
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 20 * (1 - abs(CGFloat(index - currentIndex)) * 0.5),
                            x: 0,
                            y: 10
                        )
                        // Add subtle blur based on movement
                        .blur(radius: abs(dragOffset) / 200)
                        // Custom spring animation for each property
                        .animation(
                            .interpolatingSpring(
                                mass: 1.0,
                                stiffness: 100,
                                damping: 20,
                                initialVelocity: velocityY / 1000
                            ),
                            value: currentIndex
                        )
                        // Separate animation for drag
                        .animation(
                            .interactiveSpring(
                                response: 0.3,
                                dampingFraction: 0.7,
                                blendDuration: 0.1
                            ),
                            value: dragOffset
                        )
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Calculate velocity
                        let currentTime = Date()
                        let timeDelta = currentTime.timeIntervalSince(lastDragTime)
                        let position = value.translation.height
                        velocityY = CGFloat((position - lastDragPosition) / timeDelta)
                        
                        // Update drag state
                        dragOffset = value.translation.height
                        lastDragTime = currentTime
                        lastDragPosition = position
                        
                        // Haptic feedback
                        if abs(dragOffset).truncatingRemainder(dividingBy: 50) < 1 {
                            let generator = UIImpactFeedbackGenerator(style: .soft)
                            generator.prepare()
                            generator.impactOccurred(intensity: min(abs(velocityY) / 1000, 1))
                        }
                    }
                    .onEnded { value in
                        let velocity = velocityY
                        let translation = value.translation.height
                        
                        // Determine if we should change page
                        let shouldChangePage = abs(velocity) > velocityThreshold ||
                                            abs(translation) > dragThreshold
                        
                        if shouldChangePage {
                            let direction = translation > 0 ? -1 : 1
                            let newIndex = max(0, min(scraps.count - 1, currentIndex + direction))
                            
                            if newIndex != currentIndex {
                                // Clear any selected scrap when changing pages
                                if selectedScrap != nil {
                                    selectedScrap = nil
                                    selectedImage = nil
                                }
                                
                                withAnimation(springAnimation) {
                                    currentIndex = newIndex
                                }
                                
                                // Haptic feedback for page change
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        }
                        
                        // Reset states
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                        velocityY = 0
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func calculateOffset(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let baseOffset = CGFloat(index - currentIndex) * geometry.size.height
        let dragInfluence = dragOffset * (1 - abs(CGFloat(index - currentIndex)) * 0.5)
        return baseOffset + dragInfluence
    }
}

// MARK: - ScrapView
struct ScrapView: View {
    let scrap: Scrap
    @Binding var selectedScrap: Scrap?
    @Binding var selectedImage: UIImage?
    @State private var uiImage: UIImage?
    @State private var isAppearing = false
    @State private var isImageLoading = true
    @EnvironmentObject private var settings: UserSettings
    
    // Add a reference to the parent's current index
    @Binding var currentIndex: Int
    // Add the index of this scrap
    let index: Int
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                if let title = scrap.title {
                    Text(title)
                        .dynamicFont(.title)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                }
                
                // Sanitize HTML content
                Text(scrap.content.sanitizedHTML())
                    .dynamicFont(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(4)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
            }
            .padding(24)
            .cornerRadius(24)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(scrap.title ?? "Article")")
            .accessibilityValue(scrap.content.sanitizedHTML())
            .accessibilityHint("Tap to view details")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            GeometryReader { geo in
                OptimizedImage(
                    url: scrap.screenshotUrl,
                    size: geo.size,
                    mode: .fill,
                    contentMode: .fill
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.2),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isAppearing ? 1 : 0)
                .onAppear {
                    // Prefetch the next few images for smoother scrolling
                    if settings.prefetchImages, let index = getCurrentIndex(), index < scraps.count - 3 {
                        let nextScraps = Array(scraps[index+1..<min(index+4, scraps.count)])
                        let urls = nextScraps.map { $0.screenshotUrl }
                        ImagePrefetcher.prefetch(urls: urls, size: geo.size)
                    }
                }
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
            
            // Load the image for detail view
            loadImageForDetailView()
        }
        .onDisappear {
            isAppearing = false
            uiImage = nil
        }
        .onTapGesture {
            // Only allow taps when this is the current card
            guard index == currentIndex else { return }
            
            if settings.useHaptics {
                let impact = UIImpactFeedbackGenerator(style: .soft)
                impact.impactOccurred()
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedScrap = scrap
                selectedImage = uiImage
            }
        }
    }
    
    // Get the current index of this scrap in the global scraps array
    private func getCurrentIndex() -> Int? {
        return scraps.firstIndex(where: { $0.id == scrap.id })
    }
    
    // Load the image for detail view (we still need this for the detail view transition)
    private func loadImageForDetailView() {
        guard uiImage == nil, let urlString = scrap.screenshotUrl else { return }
        
        isImageLoading = true
        
        Task {
            do {
                let image = try await CloudinaryService.shared.loadImage(
                    from: urlString,
                    size: UIScreen.main.bounds.size,
                    mode: settings.highQualityImages ? .fill : .fit
                )
                
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.uiImage = image
                        self.isImageLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isImageLoading = false
                }
            }
        }
    }
    
    // Access to global scraps array for prefetching
    private var scraps: [Scrap] {
        if let parentView = findParentView(ofType: VerticalPagingView.self) {
            return parentView.scraps
        }
        return []
    }
    
    // Helper to find parent view
    private func findParentView<T: View>(ofType type: T.Type) -> T? {
        var currentView: Any = self
        while let responder = Mirror(reflecting: currentView).superclassMirror {
            if let parent = responder.value as? T {
                return parent
            }
            currentView = responder.value
        }
        return nil
    }
}




// MARK: - WelcomeView
struct WelcomeView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Good Morning")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("Your morning thoughts and discoveries await...")
                .font(.system(size: 18, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : 20)
        .animation(.easeOut(duration: 1.0), value: isShowing)
    }
}

// MARK: - ContentHeightPreferenceKey
private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


// MARK: - Metadata Extension
extension Metadata {
    func displayableProperties() -> [(key: String, value: Any)] {
        let mirror = Mirror(reflecting: self)
        let excludedKeys = ["embedding", "embeddings", "base64Image"]
        
        return mirror.children
            .compactMap { child in
                guard let label = child.label,
                      !excludedKeys.contains(label),
                      let value = child.value as? CustomStringConvertible else {
                    return nil
                }
                return (key: label, value: value)
            }
    }
}

// Add this BlurView somewhere in your Views.swift:
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
