//
//  Views.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI
import UIKit

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
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isAppearing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Morning gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.2, blue: 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ForEach(scraps.indices, id: \.self) { index in
                    ScrapView(
                        scrap: scraps[index],
                        selectedScrap: $selectedScrap,
                        selectedImage: $selectedImage
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: CGFloat(index - currentIndex) * geometry.size.height + dragOffset)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: currentIndex)
                    .opacity(isAppearing ? 1 : 0)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    isAppearing = true
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold = geometry.size.height / 3
                        var newIndex = currentIndex
                        
                        if value.translation.height < -threshold {
                            newIndex = min(newIndex + 1, scraps.count - 1)
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred()
                        } else if value.translation.height > threshold {
                            newIndex = max(newIndex - 1, 0)
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred()
                        }
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentIndex = newIndex
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
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
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Group {
                    if let image = uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        .black.opacity(0.4),
                                        .black.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.2),
                                Color(red: 0.2, green: 0.2, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                }
                .opacity(isAppearing ? 1 : 0)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        Text(try! AttributedString(markdown: scrap.content))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Summary
                        if let summary = scrap.summary {
                            Text(try! AttributedString(markdown: summary))
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 3)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                        }
                        
                        // Image
                        if let image = uiImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geometry.size.width - 48) // Account for horizontal padding
                                .cornerRadius(16)
                                .shadow(radius: 10)
                                .padding(.vertical, 16)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 40)
                        }
                        
                        // Metadata
                        if let metadata = scrap.metadata {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.top, 16)
                                
                                ForEach(metadata.displayableProperties(), id: \.key) { item in
                                    HStack(alignment: .top) {
                                        Text("\(item.key.capitalized):")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("\(item.value)")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(100, geometry.size.height - contentHeight))
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ContentHeightPreferenceKey.self,
                                value: proxy.size.height
                            )
                        }
                    )
                }
                .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                    contentHeight = height
                }
                .coordinateSpace(name: "scroll")
                
                // Share Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding(20)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .padding(24)
                        .sheet(isPresented: $showShareSheet) {
                            if let href = scrap.metadata?.href, let url = URL(string: href) {
                                ShareSheet(items: [url])
                            } else {
                                ShareSheet(items: [scrap.content])
                            }
                        }
                        .scaleEffect(isAppearing ? 1 : 0.5)
                        .opacity(isAppearing ? 1 : 0)
                    }
                }
            }
        }
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
        .animation(.easeInOut(duration: 0.3), value: showShareSheet)
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.3)) {
                dismissAction()
            }
        }
    }
}

// Add this preference key at the bottom of your Views.swift file
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
