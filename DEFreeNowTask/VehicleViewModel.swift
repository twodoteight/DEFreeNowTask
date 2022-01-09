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
    
    private let hamburgFirstPoint: Coordinate = Coordinate(latitude: 53.694865, longitude: 9.757589)
    private let hamburgSecondPoint: Coordinate = Coordinate(latitude: 53.394655, longitude: 10.099891)
    private var locationManager: CLLocationManager?
    private var fetchTimer: Timer?
    private var updating: Bool = false
    
    func fetchAllVehicles() {

        fetchVehiclesInArea(p1: hamburgFirstPoint, p2: hamburgSecondPoint) {[weak self] (poiData: PoiData?) in
            let tempList: [Vehicle] = poiData?.poiList ?? []
            self?.vehicleList = tempList
            print(self?.vehicleList[0] ?? "no vehicle!!!!")
            for vehicle in tempList {}
        }
        
        //        let urlString = "https://poi-api.mytaxi.com/PoiService/poi/v1?p2Lat=\(secondPoint.latitude)&p1Lon=\(firstPoint.longitude)&p1Lat=\(firstPoint.latitude)&p2Lon=\(secondPoint.longitude)"
        //        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        //
        //        let apiRequest = APIRequest(url: url)
        //        apiRequest.perform { [weak self] (poiData: PoiData?) in
        //            self?.vehicleList = poiData?.poiList ?? []
        //            var tempList: [Vehicle] = poiData?.poiList ?? []
        //            print(tempList[0])
        //            for vehicle in tempList {}
        //        }
    }
    
    func startMapUpdate() {
        updating = true
        fetchVehiclesOnMap()
    }
    func stopMapUpdate() {
        updating = false
    }
    
    func fetchVehiclesOnMap() {
        if !updating {
            return
        }
        
        let northWestPoint = Coordinate(latitude: region.center.latitude + (region.span.latitudeDelta / 2.0),
                                        longitude: region.center.longitude - (region.span.longitudeDelta / 2.0))
        let southEastPoint = Coordinate(latitude: region.center.latitude - (region.span.latitudeDelta / 2.0),
                                        longitude: region.center.longitude + (region.span.longitudeDelta / 2.0))
                
        fetchVehiclesInArea(p1: northWestPoint, p2: southEastPoint) { [weak self] (poiData: PoiData?) in
            let tempList: [Vehicle] = poiData?.poiList ?? []
            self?.vehiclesInViewList = tempList
            self?.fetchVehiclesOnMap()
        }
    
    }
    
    func fetchVehiclesInArea(p1: Coordinate, p2: Coordinate, completion: @escaping (PoiData?) -> Void) {
        
        let urlString = "https://poi-api.mytaxi.com/PoiService/poi/v1?p2Lat=\(p2.latitude)&p1Lon=\(p1.longitude)&p1Lat=\(p1.latitude)&p2Lon=\(p2.longitude)"
        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        let apiRequest = APIRequest(url: url)
        apiRequest.perform { (poiData: PoiData?) in
            completion(poiData)
        }
    }
    
    // MARK: - Location manager setup and permisson handling
    func checkIfLocationServicesIsEnabled() {
        print("Checking location service permissions")
        if CLLocationManager.locationServicesEnabled() {
            // Init locationManager and assign the delegate.
            // Force unwrap is feasible since the object is created above.
            self.locationManager = CLLocationManager()
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
        print("User changed location manager access")
        checkLocationAuthorization()
    }
}
