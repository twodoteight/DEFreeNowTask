//
//  VehicleViewModel.swift
//  DEFreeNowTask
//
//  Created by Kerem on 26.12.2021.
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
    
    private var locationManager: CLLocationManager?
    private var fetchTimer: Timer?
    private var updating: Bool = false
    
    //
    func getRoute(from: Vehicle, completion: @escaping (MKRoute?) -> Void) {
        guard let locationCoordinates = locationManager?.location?.coordinate else {
            // Cannot access to current location
            return
        }
        
        let vehicleCoordinates =  CLLocationCoordinate2D(latitude: from.coordinate.latitude, longitude: from.coordinate.longitude)
        let request = createDirectionsRequest(from: vehicleCoordinates, to: locationCoordinates)
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            if error != nil {
                // TODO: Handle error
            }
            guard let response = response else {
                // TODO: Handle no response
                return
            }
            
            let route = response.routes[0]
            completion(route)
        }
    }
    
    // Helper for creating a MKDirections request
    func createDirectionsRequest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> MKDirections.Request {
        let source = MKPlacemark(coordinate: from)
        let destination = MKPlacemark(coordinate: to)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes =  false
        
        return request
    }
    
    // Calculate the distance and estimated travel time of potential transports
    func updateVehicleDistances() {
        for i in 0..<(vehicleList.count) {
            var vehicle = vehicleList[i]
            getRoute(from: vehicle) { [weak self] route in
                vehicle.ett = route?.expectedTravelTime ?? -1
                vehicle.distance = route?.distance ?? -1
                self?.vehicleList[i] = vehicle
            }
        }
    }
    
    // Fetches all vehicles in Hamburg, performs calculations, updates the data accordingly
    func fetchAllVehicles() {
        let hamburgFirstPoint: Coordinate = Coordinate(latitude: 53.694865, longitude: 9.757589)
        let hamburgSecondPoint: Coordinate = Coordinate(latitude: 53.394655, longitude: 10.099891)
        
        vehicleList.removeAll()
        fetchVehiclesInArea(p1: hamburgFirstPoint, p2: hamburgSecondPoint) {[weak self] ( poiData: PoiData?) in
            let tempList: [Vehicle] = poiData?.poiList ?? []
            //self?.vehicleList = tempList
            for i in 0..<(tempList.count) {
                let vehicle = tempList[i]
                self?.vehicleList.append(vehicle)
            }
            self?.updateVehicleDistances()
        }
    }
    
    // Initiates API calls for the visible map region
    func startMapUpdate() {
        updating = true
        fetchVehiclesOnMap()
    }
    // Stops the map update (e.g. if the map view disappers)
    func stopMapUpdate() {
        updating = false
    }
    
    // Calls fetchVehiclesInArea function using currently visible map borders
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
    
    // Fetches vehicles between the specified coordinates
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
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            centerOnUser()
            
        } else {
            // TODO: Inform user to enable location services
            print("Location services are disabled")
        }
    }
    
    // Centers region on user
    func centerOnUser() {
        if let userCoordinates = locationManager?.location?.coordinate {
            region = MKCoordinateRegion(
                center: userCoordinates,
                span: MapInfo.initialSpan
            )
        }
    }
    
    // Delegate functions
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else {
            // Something is wrong, location manager is nil
            return
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // TODO: Let user know
            print("Location restirected")
        case .denied:
            // TODO: Let user know
            print("User denied service ask them to fix it")
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location tracking authorized")
        @unknown default:
            break
        }
    }
    
    private func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("User changed location manager access")
        checkLocationAuthorization()
    }
}
