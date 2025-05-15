import Foundation

// MARK: - Scrap Model
public struct Scrap: Identifiable, Codable, Hashable {
    public let id: UUID
    public let content: String
    public let title: String?
    public let summary: String?
    public let metadata: Metadata?
    public let screenshotUrl: String?
    public let longitude: Double?
    public let latitude: Double?
    public let url: String?
    
    public init(
        id: UUID,
        content: String,
        title: String? = nil,
        summary: String? = nil,
        metadata: Metadata? = nil,
        screenshotUrl: String? = nil,
        longitude: Double? = nil,
        latitude: Double? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.content = content
        self.title = title
        self.summary = summary
        self.metadata = metadata
        self.screenshotUrl = screenshotUrl
        self.longitude = longitude
        self.latitude = latitude
        self.url = url
    }
}

// MARK: - Metadata Model
public struct Metadata: Codable, Hashable {
    public let href: String?
    public let url: String?
    public let visibility: String?
    public let facts: [String]?
    
    public init(
        href: String? = nil,
        url: String? = nil,
        visibility: String? = nil,
        facts: [String]? = nil
    ) {
        self.href = href
        self.url = url
        self.visibility = visibility
        self.facts = facts
    }
} 