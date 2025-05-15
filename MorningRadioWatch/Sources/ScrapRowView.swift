import SwiftUI

struct ScrapRowView: View {
    let scrap: Scrap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = scrap.title {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Text(scrap.content.sanitizedHTML())
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
} 