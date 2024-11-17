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


// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
                    let transforms = calculateTransforms(for: index, geometry: geometry)
                    
                    ScrapView(
                        scrap: scraps[index],
                        selectedScrap: $selectedScrap,
                        selectedImage: $selectedImage
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
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
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Text(try! AttributedString(markdown: scrap.content))
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
            }
            .padding(24)
            .background(.ultraThinMaterial.opacity(0.7))
            .cornerRadius(24)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
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
                        .clipped()
                        .opacity(isAppearing ? 1 : 0)
                }
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
            loadImage()
        }
        .onDisappear {
            isAppearing = false
        }
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                selectedScrap = scrap
                selectedImage = uiImage
            }
        }
    }
    
    private func loadImage() {
        guard uiImage == nil else { return }
        guard let metadata = scrap.metadata else { return }
        
        if let base64String = metadata.base64Image {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = Data(base64Encoded: base64String),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        withAnimation(.easeIn(duration: 0.3)) {
                            uiImage = image
                        }
                    }
                }
            }
        } else if let screenshotUrlString = metadata.screenshotUrl,
                  let url = URL(string: screenshotUrlString) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        withAnimation(.easeIn(duration: 0.3)) {
                            uiImage = image
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ScrapDetailView
struct ScrapDetailView: View {
    let scrap: Scrap
    let uiImage: UIImage?
    let dismissAction: () -> Void
    
    @State private var showShareSheet: Bool = false
    @State private var isAppearing = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // MARK: - Background Layer
                backgroundColor
                
                // MARK: - Content Layer
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with Percentage-based Top Padding
                        Text(try! AttributedString(markdown: scrap.content))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .padding(.top, geometry.size.height * 0.08)  // 8% of screen height
                            .frame(maxWidth: geometry.size.width - 48, alignment: .leading)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Summary
                        if let summary = scrap.summary {
                            Text(try! AttributedString(markdown: summary))
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(textColor.opacity(0.8))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: geometry.size.width - 48, alignment: .leading)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                        }
                        
                        // Metadata
                        if let metadata = scrap.metadata {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(textColor)
                                    .padding(.top, 16)
                                
                                ForEach(metadata.displayableProperties(), id: \.key) { item in
                                    HStack(alignment: .top) {
                                        Text("\(item.key.capitalized):")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(textColor.opacity(0.7))
                                        Text("\(item.value)")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(textColor)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: geometry.size.width - 64)
                                }
                            }
                            .padding(.vertical, 16)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        }
                        
                        // Bottom spacing for share button
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(width: geometry.size.width)
                
                // MARK: - Share Button Layer
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred(intensity: 0.7)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showShareSheet = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(textColor)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                        .offset(y: isAppearing ? 0 : 100)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showShareSheet) {
                if let href = scrap.metadata?.href,
                   let url = URL(string: href) {
                    ShareSheet(items: [url])
                } else {
                    ShareSheet(items: [scrap.content])
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
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
            withAnimation(.easeInOut(duration: 0.3)) {
                dismissAction()
            }
        }
    }
    
    // Computed properties for dynamic theming
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
