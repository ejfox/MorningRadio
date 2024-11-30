import SwiftUI

struct MapView: View {
    let latitude: Double
    let longitude: Double
    let zoomLevel: Double
    let startZoomLevel: Double
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Map Placeholder\n(\(latitude), \(longitude))")
                    .multilineTextAlignment(.center)
            )
    }
}
