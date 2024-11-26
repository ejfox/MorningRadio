//
//  ScrapMetadataView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/18/24.
//

import SwiftUI

struct ScrapMetadataView: View {
    let metadata: [String: Any]
    
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
    }
}

// MARK: - MetadataRow
struct MetadataRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(key.capitalized):")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 100, alignment: .trailing) // Fixed width for alignment
            
            Text(value)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true) // Allow multiline
        }
    }
}

#Preview {
    ScrapMetadataView(metadata: sampleMetadata)
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
