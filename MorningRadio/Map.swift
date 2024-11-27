import SwiftUI
import MapLibre

struct MapView: View {
    let latitude: Double
    let longitude: Double
    let zoomLevel: Double
    
    init(latitude: Double, longitude: Double, zoomLevel: Double = 8) {
        self.latitude = latitude
        self.longitude = longitude
        self.zoomLevel = zoomLevel
    }
    
    var body: some View {
        MapViewRepresentable(
            latitude: latitude,
            longitude: longitude,
            zoomLevel: zoomLevel
        )
    }
}




// MARK: - MapViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    let latitude: Double
    let longitude: Double
    let zoomLevel: Double
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)
        
        // Configure the map
        mapView.styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        
        // Hide default controls
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        // Set initial position
        let coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        mapView.setCenter(coordinate, zoomLevel: zoomLevel, animated: false)
        
        // Add a marker at the location
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
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
