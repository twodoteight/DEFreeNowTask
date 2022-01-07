//
//  NewsModel.swift
//  HackerNews
//
//  Created by Matteo Manferdini on 21/10/2020.
//

import Foundation
import MapKit

enum MapInfo {
    static let startingLocation = CLLocationCoordinate2D(
        latitude: 53.694865,
        longitude: 9.757589)
    static let initialSpan = MKCoordinateSpan(
        latitudeDelta: 0.01,
        longitudeDelta: 0.01)
}

class VehicleViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var vehicleList: [Vehicle] = []
    @Published var vehiclesInViewList: [Vehicle] = []
    @Published var region = MKCoordinateRegion(
        center: MapInfo.startingLocation,
        span: MapInfo.initialSpan
    )
    
    var locationManager: CLLocationManager?
    
    func fetchAllVehicles() {
        let firstPoint: Coordinate = Coordinate(latitude: 53.694865, longitude: 9.757589)
        let secondPoint: Coordinate = Coordinate(latitude: 53.394655, longitude: 10.099891)
        
        let urlString = "https://poi-api.mytaxi.com/PoiService/poi/v1?p2Lat=\(secondPoint.latitude)&p1Lon=\(firstPoint.longitude)&p1Lat=\(firstPoint.latitude)&p2Lon=\(secondPoint.longitude)"
        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        let apiRequest = APIRequest(url: url)
        apiRequest.perform { [weak self] (poiData: PoiData?) in
            self?.vehicleList = poiData?.poiList ?? []
            var tempList: [Vehicle] = poiData?.poiList ?? []
            print(tempList[0])
            for vehicle in tempList {
                
            }
        }
    }
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager = CLLocationManager()
            // Assign the delegate to locationManager objet.
            // Force unwrap is feasible since the object is created above.
            self.locationManager!.delegate = self
            
        } else {
            print("Inform user to enable location services")
        }
    }
    private func checkLocationAuthorization() {
        guard let locationManager = self.locationManager else { return }
        switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Location restirected alert")
            case .denied:
                print("User denied service aske them to fix it")
            case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(
                center: locationManager.location!.coordinate,
                span: MapInfo.initialSpan
            )
            @unknown default:
                break
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
