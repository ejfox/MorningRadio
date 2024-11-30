//
//  Models.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import Foundation
import SwiftUI

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
    public let reblogCount: Int?
    public let renoteCount: Int?
    public let latitude: Double?
    public let longitude: Double?
    public let location: String?
    public let screenshotUrl: String?
    public let base64Image: String?
    
    private enum CodingKeys: String, CodingKey {
        case href, url, visibility, latitude, longitude, location
        case reblogCount = "reblog_count"
        case renoteCount = "renote_count"
        case screenshotUrl = "screenshot_url"
        case base64Image = "base64_image"
    }
    
    public init(
        href: String? = nil,
        url: String? = nil,
        visibility: String? = nil,
        reblogCount: Int? = nil,
        renoteCount: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        location: String? = nil,
        screenshotUrl: String? = nil,
        base64Image: String? = nil
    ) {
        self.href = href
        self.url = url
        self.visibility = visibility
        self.reblogCount = reblogCount
        self.renoteCount = renoteCount
        self.latitude = latitude
        self.longitude = longitude
        self.location = location
        self.screenshotUrl = screenshotUrl
        self.base64Image = base64Image
    }
}
