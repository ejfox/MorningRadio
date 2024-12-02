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
            }

            if let scrap = selectedScrap {
                ScrapDetailView(scrap: scrap, uiImage: selectedImage) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedScrap = nil
                        selectedImage = nil
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear(perform: fetchScraps)
    }

    private func fetchScraps() {
        Task {
            do {
                let rawResponse = try await SupabaseManager.shared.client
                    .from("scraps")
                    .select("id, content, title, summary, metadata, screenshot_url, latitude, longitude, url")
                    .order("created_at", ascending: false)
                    .limit(64)
                    .execute()

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedScraps = try decoder.decode([Scrap].self, from: rawResponse.data)
                
                // Filter out invalid scraps - now includes title check
                let validScraps = decodedScraps.filter { scrap in
                    !scrap.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    scrap.title != nil &&
                    !scrap.title!.isEmpty
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.scraps = validScraps
                        self.isLoading = false
                    }
                }
            } catch {
                print("Fetch error: \(error)")
                DispatchQueue.main.async {
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
