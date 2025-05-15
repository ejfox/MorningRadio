//
//  ContentView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI
import CoreData
import Foundation

struct ContentView: View {
    @State private var scraps: [Scrap] = []
    @State private var currentIndex: Int = 0
    @State private var showError: Bool = false
    @State private var selectedScrap: Scrap? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isLoading = true
    @State private var showSettings = false
    
    // Add a timer to check for stuck detail views
    @State private var detailViewTimer: Timer? = nil
    @State private var detailViewStartTime: Date? = nil
    
    // Access user settings
    @EnvironmentObject private var settings: UserSettings

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(scraps: scraps)
                    .transition(.opacity)
            } else if showError {
                ErrorView(retryAction: fetchScraps)
                    .transition(.opacity)
            } else {
                VerticalPagingView(scraps: scraps, selectedScrap: $selectedScrap, selectedImage: $selectedImage)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .shadow(radius: 2)
                        }
                        .padding([.top, .trailing], 16)
                        .accessibilityLabel("Settings")
                    }
            }

            if let scrap = selectedScrap {
                ScrapDetailView(scrap: scrap, uiImage: selectedImage) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedScrap = nil
                        selectedImage = nil
                        detailViewTimer?.invalidate()
                        detailViewTimer = nil
                        detailViewStartTime = nil
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .ignoresSafeArea()
                .onAppear {
                    // Start a timer to detect stuck detail views
                    detailViewStartTime = Date()
                    startDetailViewTimer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: showError)
        .onAppear(perform: fetchScraps)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func fetchScraps() {
        isLoading = true
        showError = false
        
        Task {
            do {
                let rawResponse = try await SupabaseManager.shared.client
                    .from("scraps")
                    .select("id, content, title, summary, metadata, screenshot_url, latitude, longitude, url")
                    .order("created_at", ascending: false)
                    .execute()
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedScraps = try decoder.decode([Scrap].self, from: rawResponse.data)
                
                // Filter out invalid scraps
                let validScraps = decodedScraps.filter { scrap in
                    !scrap.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    scrap.title != nil &&
                    !scrap.title!.isEmpty
                }

                // Prefetch the first few images while loading
                if settings.prefetchImages {
                    prefetchInitialImages(scraps: validScraps)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.scraps = validScraps
                        self.isLoading = false
                    }
                }

                // Update widget data when scraps are loaded
                #if !WIDGET_EXTENSION
                WidgetDataManager.shared.updateWidgetData()
                #endif

            } catch {
                print("Fetch error: \(error)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.showError = true
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func prefetchInitialImages(scraps: [Scrap]) {
        // Prefetch the first 5 images for immediate display
        let initialScraps = Array(scraps.prefix(5))
        let screenSize = UIScreen.main.bounds.size
        
        // Prefetch at different sizes for different views
        // Main view size
        ImagePrefetcher.prefetch(
            urls: initialScraps.map { $0.screenshotUrl },
            size: screenSize,
            mode: .fill
        )
        
        // Detail view size (slightly smaller)
        let detailSize = CGSize(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.7
        )
        ImagePrefetcher.prefetch(
            urls: initialScraps.map { $0.screenshotUrl },
            size: detailSize,
            mode: .fill
        )
    }
    
    // Start a timer to detect stuck detail views
    private func startDetailViewTimer() {
        detailViewTimer?.invalidate()
        detailViewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // If the detail view has been open for more than 30 seconds, provide an escape hatch
            if let startTime = detailViewStartTime, 
               Date().timeIntervalSince(startTime) > 30.0 {
                // Add a triple tap gesture recognizer to dismiss the detail view
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
                tapGesture.numberOfTapsRequired = 3
                UIApplication.shared.windows.first?.addGestureRecognizer(tapGesture)
                
                // Only do this once
                detailViewTimer?.invalidate()
                detailViewTimer = nil
            }
        }
    }
    
    @objc private func handleTripleTap() {
        // Emergency escape hatch for stuck detail views
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedScrap = nil
            selectedImage = nil
            detailViewStartTime = nil
        }
        
        // Remove the gesture recognizer
        if let window = UIApplication.shared.windows.first,
           let recognizers = window.gestureRecognizers {
            for recognizer in recognizers {
                if let tapRecognizer = recognizer as? UITapGestureRecognizer,
                   tapRecognizer.numberOfTapsRequired == 3 {
                    window.removeGestureRecognizer(tapRecognizer)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings.shared)
}
