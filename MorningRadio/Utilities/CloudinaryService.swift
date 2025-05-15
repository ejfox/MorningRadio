import Foundation
import UIKit
import SwiftUI

/// A service for optimizing and caching Cloudinary images
@Observable class CloudinaryService {
    // MARK: - Singleton
    static let shared = CloudinaryService()
    
    // MARK: - Properties
    private let imageCache = NSCache<NSString, UIImage>()
    private var ongoingTasks: [URL: Task<UIImage?, Error>] = [:]
    private let lock = NSLock()
    
    // MARK: - Constants
    private let defaultQuality = 80
    private let defaultFormat = "auto"
    private let defaultFetchFormat = "auto"
    
    // MARK: - Initialization
    private init() {
        // Configure cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Public Methods
    
    /// Optimizes a Cloudinary URL for the given size
    /// - Parameters:
    ///   - url: The original Cloudinary URL
    ///   - size: The target size for the image
    ///   - scale: The device scale factor (default: UIScreen.main.scale)
    ///   - mode: The crop mode (default: .fill)
    /// - Returns: An optimized URL
    func optimizedURL(from url: URL, size: CGSize, scale: CGFloat = UIScreen.main.scale, mode: CropMode = .fill) -> URL? {
        guard isCloudinaryURL(url) else { return url }
        
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        
        var urlString = url.absoluteString
        
        // Check if URL already has transformations
        if urlString.contains("/image/upload/") {
            // Insert transformations after /image/upload/
            let transformations = "w_\(width),h_\(height),c_\(mode.rawValue),q_\(defaultQuality),f_\(defaultFormat),fl_progressive/"
            urlString = urlString.replacingOccurrences(
                of: "/image/upload/",
                with: "/image/upload/\(transformations)"
            )
        } else if let cloudName = extractCloudName(from: url) {
            // Try to construct a proper Cloudinary URL
            let publicId = url.lastPathComponent.components(separatedBy: ".").first ?? url.lastPathComponent
            urlString = "https://res.cloudinary.com/\(cloudName)/image/upload/w_\(width),h_\(height),c_\(mode.rawValue),q_\(defaultQuality),f_\(defaultFormat),fl_progressive/\(publicId)"
        } else {
            // If URL doesn't follow Cloudinary pattern, return original
            return url
        }
        
        return URL(string: urlString)
    }
    
    /// Loads an image from a URL with optimizations
    /// - Parameters:
    ///   - url: The image URL
    ///   - size: The target size for the image
    ///   - mode: The crop mode (default: .fill)
    /// - Returns: A task that resolves to a UIImage
    func loadImage(from urlString: String, size: CGSize, mode: CropMode = .fill) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw CloudinaryError.invalidURL
        }
        
        // Check cache first
        let cacheKey = NSString(string: "\(urlString)-\(Int(size.width))-\(Int(size.height))")
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Get optimized URL
        let optimizedURL = self.optimizedURL(from: url, size: size, mode: mode) ?? url
        
        // Check if there's an ongoing task for this URL
        lock.lock()
        if let existingTask = ongoingTasks[optimizedURL] {
            lock.unlock()
            return try await existingTask.value ?? UIImage()
        }
        
        // Create a new task
        let task = Task<UIImage?, Error> {
            defer {
                lock.lock()
                ongoingTasks[optimizedURL] = nil
                lock.unlock()
            }
            
            let (data, _) = try await URLSession.shared.data(from: optimizedURL)
            guard let image = UIImage(data: data) else {
                throw CloudinaryError.invalidImageData
            }
            
            // Cache the image
            self.imageCache.setObject(image, forKey: cacheKey, cost: data.count)
            
            return image
        }
        
        // Store the task
        ongoingTasks[optimizedURL] = task
        lock.unlock()
        
        // Await the result
        return try await task.value ?? UIImage()
    }
    
    /// Prefetches an image and stores it in the cache
    /// - Parameters:
    ///   - url: The image URL
    ///   - size: The target size for the image
    ///   - mode: The crop mode (default: .fill)
    func prefetchImage(from urlString: String, size: CGSize, mode: CropMode = .fill) {
        Task {
            do {
                _ = try await loadImage(from: urlString, size: size, mode: mode)
            } catch {
                // Silently fail for prefetching
                print("Prefetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the image cache
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Private Methods
    
    /// Checks if a URL is a Cloudinary URL
    /// - Parameter url: The URL to check
    /// - Returns: True if the URL is a Cloudinary URL
    private func isCloudinaryURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        return urlString.contains("cloudinary.com") || 
               urlString.contains("res.cloudinary.com") ||
               urlString.contains("cloudinary.net")
    }
    
    /// Extracts the cloud name from a Cloudinary URL
    /// - Parameter url: The Cloudinary URL
    /// - Returns: The cloud name, if found
    private func extractCloudName(from url: URL) -> String? {
        let urlString = url.absoluteString
        
        // Pattern 1: res.cloudinary.com/cloud-name/
        if let regex = try? NSRegularExpression(pattern: "res\\.cloudinary\\.com/([^/]+)/", options: []) {
            if let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)) {
                if let range = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[range])
                }
            }
        }
        
        // Pattern 2: cloud-name.cloudinary.net/
        if let regex = try? NSRegularExpression(pattern: "([^.]+)\\.cloudinary\\.net/", options: []) {
            if let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)) {
                if let range = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[range])
                }
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Crop modes for Cloudinary images
enum CropMode: String {
    case fill = "fill"      // Resizes to fill the specified dimensions while maintaining aspect ratio
    case crop = "crop"      // Extracts a region of the specified dimensions
    case scale = "scale"    // Changes the size without cropping
    case fit = "fit"        // Resizes to fit within the specified dimensions while maintaining aspect ratio
    case limit = "limit"    // Same as fit but only if the original image is larger than the specified dimensions
    case thumb = "thumb"    // Creates a thumbnail using face detection
    case face = "face"      // Same as thumb but with improved face detection
}

/// Errors that can occur when working with Cloudinary images
enum CloudinaryError: Error {
    case invalidURL
    case invalidImageData
    case networkError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidImageData:
            return "Invalid image data"
        case .networkError:
            return "Network error"
        case .unknown:
            return "Unknown error"
        }
    }
}

// MARK: - SwiftUI Extensions

/// A SwiftUI view that displays an optimized Cloudinary image
struct OptimizedImage: View {
    // MARK: - Properties
    let url: String?
    let size: CGSize
    let mode: CropMode
    let contentMode: ContentMode
    
    // MARK: - State
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var error: Error?
    
    // MARK: - Initialization
    init(
        url: String?,
        size: CGSize,
        mode: CropMode = .fill,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.size = size
        self.mode = mode
        self.contentMode = contentMode
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, _ in
            loadImage()
        }
    }
    
    // MARK: - Private Methods
    private func loadImage() {
        guard let urlString = url, !urlString.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let loadedImage = try await CloudinaryService.shared.loadImage(
                    from: urlString,
                    size: size,
                    mode: mode
                )
                
                await MainActor.run {
                    withAnimation {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Prefetcher

/// A utility for prefetching images
struct ImagePrefetcher {
    /// Prefetches a list of images
    /// - Parameters:
    ///   - urls: The image URLs to prefetch
    ///   - size: The target size for the images
    ///   - mode: The crop mode (default: .fill)
    static func prefetch(urls: [String?], size: CGSize, mode: CropMode = .fill) {
        for urlString in urls.compactMap({ $0 }) {
            CloudinaryService.shared.prefetchImage(from: urlString, size: size, mode: mode)
        }
    }
} 