//
//  Models.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import Foundation

struct Scrap: Identifiable, Decodable {
    let id: UUID
    let content: String
    let summary: String?
    let metadata: Metadata?
    let screenshotUrl: String?  // Consistently camelCase
    let longitude: Double?
    let latitude: Double?
}

// MARK: - Metadata Struct
struct Metadata: Decodable {
    let href: String?
    let url: String?
    let visibility: String?
    let reblogCount: Int?
    let renoteCount: Int?
    let latitude: Double?
    let longitude: Double?
    let location: String?
    let screenshotUrl: String?
    let base64Image: String?
    
    private enum CodingKeys: String, CodingKey {
        case href
        case url
        case visibility
        case reblogCount = "reblog_count"
        case renoteCount = "renote_count"
        case latitude
        case longitude
        case location
        case screenshotUrl = "screenshot_url"
        case base64Image = "base64_image"
    }
}
