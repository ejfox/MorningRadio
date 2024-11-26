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
    @State private var isLoading: Bool = true
    @State private var showError: Bool = false
    @State private var selectedScrap: Scrap? = nil
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else if showError {
                ErrorView(retryAction: fetchScraps)
            } else {
                VerticalPagingView(scraps: scraps, selectedScrap: $selectedScrap, selectedImage: $selectedImage)
                    .edgesIgnoringSafeArea(.all)
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
                .ignoresSafeArea()  // Add this
            }
        }
        .onAppear(perform: fetchScraps)
    }

    private func fetchScraps() {
        Task {
            do {
                let rawResponse = try await SupabaseManager.shared.client
                    .from("scraps")
                    .select("id, content, summary, metadata, screenshot_url, latitude, longitude")
                    .order("created_at", ascending: false)
                    .limit(64)
                    .execute()

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase  // This handles the conversion
                let decodedScraps = try decoder.decode([Scrap].self, from: rawResponse.data)

                DispatchQueue.main.async {
                    withAnimation {
                        self.scraps = decodedScraps
                        self.isLoading = false
                    }
                }
            } catch {
                print("Fetch error: \(error)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                        self.showError = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
