import SwiftUI
import WatchKit

// MARK: - String Extensions
extension String {
    func sanitizedHTML() -> String {
        // Simple HTML tag removal
        var result = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Replace common HTML entities
        let entities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&nbsp;": " "
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - WatchOptimizedImage
struct WatchOptimizedImage: View {
    let url: String?
    let size: CGSize
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width * 0.5, height: size.height * 0.5)
                    .foregroundColor(.gray)
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = url, let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        // For Watch, we want to optimize for smaller images
        let optimizedUrl = optimizeImageUrl(url, for: size)
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: optimizedUrl)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func optimizeImageUrl(_ url: URL, for size: CGSize) -> URL {
        // Simple optimization for Cloudinary URLs
        // In a real app, you'd use the CloudinaryService from the main app
        var urlString = url.absoluteString
        
        if urlString.contains("cloudinary.com") || urlString.contains("cloudinary.net") {
            // Extract width and height based on device scale
            let scale = WKInterfaceDevice.current().screenScale
            let width = Int(size.width * scale)
            let height = Int(size.height * scale)
            
            // Add transformations for Cloudinary
            if urlString.contains("/image/upload/") {
                urlString = urlString.replacingOccurrences(
                    of: "/image/upload/",
                    with: "/image/upload/w_\(width),h_\(height),c_fill,q_70,f_auto/"
                )
            }
        }
        
        return URL(string: urlString) ?? url
    }
} 