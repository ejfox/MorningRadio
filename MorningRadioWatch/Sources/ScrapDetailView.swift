import SwiftUI

struct ScrapDetailView: View {
    let scrap: Scrap
    
    @State private var currentPage = 0
    @State private var facts: [String] = []
    @State private var showShareSheet = false
    @State private var scrollAmount: CGFloat = 0
    
    // For haptic feedback
    @State private var lastFeedbackValue = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            if facts.isEmpty {
                // Initial content view with loading state
                VStack {
                    ProgressView("Preparing content...")
                        .progressViewStyle(.circular)
                        .padding()
                }
                .onAppear {
                    // Split content into facts
                    splitContentIntoFacts()
                }
            } else {
                // Paginated facts view
                TabView(selection: $currentPage) {
                    // First page with image
                    VStack(spacing: 8) {
                        if let screenshotUrl = scrap.screenshotUrl {
                            GeometryReader { geo in
                                WatchOptimizedImage(
                                    url: screenshotUrl,
                                    size: CGSize(width: geo.size.width, height: geo.size.width * 0.6)
                                )
                                .cornerRadius(8)
                            }
                            .frame(height: 80)
                            .padding(.horizontal)
                        }
                        
                        if let title = scrap.title {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal)
                        }
                        
                        Text("Swipe or rotate crown to read")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .tag(0)
                    
                    // Content pages
                    ForEach(0..<facts.count, id: \.self) { index in
                        VStack {
                            Text(facts[index])
                                .font(.system(size: index == facts.count - 1 ? 16 : 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // Show share button on last page
                            if index == facts.count - 1 {
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                .padding(.bottom)
                            }
                        }
                        .tag(index + 1) // +1 because the first page is the image/title
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                // Digital Crown scrolling
                .focusable()
                .digitalCrownRotation(
                    $scrollAmount,
                    from: 0,
                    through: Double(facts.count),
                    by: 0.1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: scrollAmount) { oldValue, newValue in
                    // Update the current page based on scroll amount
                    let newPage = Int(newValue.rounded())
                    if newPage != currentPage && newPage >= 0 && newPage <= facts.count {
                        currentPage = newPage
                        
                        // Provide haptic feedback when changing pages
                        let feedbackValue = Int(newValue)
                        if feedbackValue != lastFeedbackValue {
                            WKInterfaceDevice.current().play(.click)
                            lastFeedbackValue = feedbackValue
                        }
                    }
                }
                .onChange(of: currentPage) { oldValue, newValue in
                    // Keep scrollAmount in sync with currentPage
                    if abs(Double(newValue) - scrollAmount) > 0.5 {
                        scrollAmount = Double(newValue)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareView(text: scrap.content, title: scrap.title ?? "Morning Radio")
        }
    }
    
    private func splitContentIntoFacts() {
        // Split content into sentences or paragraphs
        let content = scrap.content.sanitizedHTML()
        
        // First try to split by sentences
        var sentences = content.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // If we have too few sentences, use the whole content
        if sentences.count < 2 {
            facts = [content]
        } else {
            // Add periods back to sentences
            facts = sentences.map { $0.hasSuffix(".") ? $0 : $0 + "." }
            
            // Add a final page with share option
            facts.append("Thanks for reading!")
        }
        
        // Check if metadata contains facts
        if let metadataFacts = scrap.metadata?.facts, !metadataFacts.isEmpty {
            facts = metadataFacts
        }
    }
}

struct ShareView: View {
    let text: String
    let title: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Share this content?")
                .font(.headline)
                .padding(.top)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Share") {
                    shareContent()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }
    
    private func shareContent() {
        // In a real implementation, this would use WatchKit to share content
        // For now, we'll just dismiss the sheet
        dismiss()
    }
} 