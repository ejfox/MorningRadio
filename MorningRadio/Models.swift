//
//  Models.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import Foundation

// MARK: - Scrap Model
struct Scrap: Identifiable, Decodable {
    let id: UUID
    let content: String
    let summary: String?
    let metadata: Metadata?
}

// MARK: - Metadata Struct
struct Metadata: Decodable {
    let href: String?
    let url: String?
    let visibility: String?
    let reblogsCount: Int?
    let favouritesCount: Int?
    let latitude: Double?
    let longitude: Double?
    let location: String?
    let screenshotUrl: String?
    let base64Image: String?
}
