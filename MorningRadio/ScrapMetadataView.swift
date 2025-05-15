//
//  ScrapMetadataView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/18/24.
//

import SwiftUI

struct ScrapMetadataView: View {
    let metadata: [String: Any]
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Dynamically render all metadata fields
            ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                if let value = metadata[key] {
                    MetadataRow(key: key, value: "\(value)")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Metadata")
    }
}

// MARK: - MetadataRow
struct MetadataRow: View {
    let key: String
    let value: String
    @EnvironmentObject private var settings: UserSettings
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(key.capitalized):")
                .dynamicFont(.subheadline, weight: .semibold)
                .foregroundColor(.primary.opacity(0.7))
                .frame(minWidth: 100, alignment: .trailing) // Minimum width for alignment
            
            Text(value)
                .dynamicFont(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true) // Allow multiline
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key): \(value)")
    }
}

#Preview {
    ScrapMetadataView(metadata: sampleMetadata)
        .environmentObject(UserSettings())
}

// MARK: - Sample Metadata
private let sampleMetadata: [String: Any] = [
    "source": "blog",
    "content": "An amazing scrap of content.",
    "tags": ["swift", "ios", "app"],
    "location": "New York, NY",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "type": "article",
    "published_at": "2024-11-17",
    "url": "https://example.com"
]
