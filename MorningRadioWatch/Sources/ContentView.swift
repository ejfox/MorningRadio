import SwiftUI

struct ContentView: View {
    @State private var scraps: [Scrap] = []
    @State private var isLoading = true
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(.circular)
                } else if showError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .padding()
                        
                        Text("Couldn't load content")
                            .font(.headline)
                        
                        Button("Retry") {
                            fetchScraps()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .padding()
                    }
                } else if scraps.isEmpty {
                    Text("No content available")
                        .font(.headline)
                } else {
                    List {
                        ForEach(scraps.prefix(10)) { scrap in
                            NavigationLink(destination: ScrapDetailView(scrap: scrap)) {
                                ScrapRowView(scrap: scrap)
                            }
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("Morning Radio")
            .onAppear(perform: fetchScraps)
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
                    .limit(10) // Only get the 10 most recent for Watch
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

                await MainActor.run {
                    self.scraps = validScraps
                    self.isLoading = false
                }
            } catch {
                print("Fetch error: \(error)")
                await MainActor.run {
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
} 