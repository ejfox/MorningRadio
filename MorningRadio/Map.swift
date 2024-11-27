import SwiftUI
import MapLibre

struct MapView: View {
    let latitude: Double
    let longitude: Double
    let zoomLevel: Double
    let startZoomLevel: Double
    
    init(
        latitude: Double,
        longitude: Double,
        zoomLevel: Double = 13,
        startZoomLevel: Double = 1
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.zoomLevel = zoomLevel
        self.startZoomLevel = startZoomLevel
    }
    
    var body: some View {
        MapViewRepresentable(
            latitude: latitude,
            longitude: longitude,
            zoomLevel: zoomLevel,
            startZoomLevel: startZoomLevel
        )
    }
}




// MARK: - MapViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    let latitude: Double
    let longitude: Double
    let zoomLevel: Double
    let startZoomLevel: Double
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)
        
        // Configure the map
        mapView.styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        
        // Hide default controls
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        // Set initial position (zoomed way out)
        let coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        mapView.setCenter(coordinate, zoomLevel: startZoomLevel, animated: false)
        
        // Add a marker at the location
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Animate to final zoom level with a longer delay and duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {  // Doubled delay
            UIView.animate(withDuration: 4.0) {  // Doubled animation duration
                mapView.setCenter(coordinate, zoomLevel: zoomLevel, animated: true)
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        let coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        mapView.setCenter(coordinate, zoomLevel: zoomLevel, animated: true)
    }
}
