//
//  VehicleViewModel.swift
//  DEFreeNowTask
//
//  Created by Kerem on 26.12.2021.
//

import Foundation
import MapKit
import SwiftUI

// Default map paramters
enum MapInfo {
    static let defaultLocation = CLLocationCoordinate2D(
        latitude: 53.551100,
        longitude: 9.993700)
    static let hamburgNW = CLLocationCoordinate2D(
        latitude: 53.694865,
        longitude: 9.757589)
    static let hamburgSE = CLLocationCoordinate2D(
        latitude: 53.394655,
        longitude: 10.099891)
    static let defaultSpan = MKCoordinateSpan(
        latitudeDelta: 0.01,
        longitudeDelta: 0.01)
}

class VehicleViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var vehicleList: [Vehicle] = []
    @Published var vehiclesInViewList: [Vehicle] = []
    @Published var region = MKCoordinateRegion(
        center: MapInfo.defaultLocation,
        span: MapInfo.defaultSpan
    )
    
    private var locationManager: CLLocationManager?
    private var fetchTimer: Timer?
    private var updating: Bool = false
    private var selectedVehicle: Vehicle? = nil
    
    func select(vehicle: Vehicle) {
        if selectedVehicle != nil {
            return
        }
        self.selectedVehicle = vehicle
    }
    
    // Fetches all vehicles in Hamburg, performs calculations, updates the data accordingly
    func fetchAllVehicles() {
        print("Fetching all vehicles")
        vehicleList.removeAll()
        
        fetchVehiclesInArea(p1: MapInfo.hamburgNW, p2: MapInfo.hamburgSE) {[weak self] ( poiData: PoiData?) in
            guard let poiData = poiData else {
                // TODO: Data is nil. Handle it
                print("poiData is nil")
                return
            }
            print("Car data fetched")
            var tempList: [Vehicle] = []
            for i in 0..<(poiData.poiList.count) {
                var vehicle = poiData.poiList[i]
                tempList.append(vehicle)
            }
            tempList.sort {
                $0.id < $1.id
            }
                        
            DispatchQueue.main.async {
                self?.vehicleList.append(contentsOf: tempList)
            }
        }
    }
    
    // Calls fetchVehiclesInArea function using currently visible map borders
    func fetchVehiclesOnMap() {
        if !updating {
            return
        }
        
        let northWestPoint = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta / 2.0),
                                                    longitude: region.center.longitude - (region.span.longitudeDelta / 2.0))
        let southEastPoint = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta / 2.0),
                                                    longitude: region.center.longitude + (region.span.longitudeDelta / 2.0))
        
        fetchVehiclesInArea(p1: northWestPoint, p2: southEastPoint) { [weak self] (poiData: PoiData?) in
            let tempList: [Vehicle] = poiData?.poiList ?? []
            DispatchQueue.main.async {
                self?.vehiclesInViewList = tempList
            }
            //self?.fetchVehiclesOnMap()
        }
    }
    
    // Initiates API calls for the visible map region
    func startMapUpdate() {
        updating = true
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            self?.fetchVehiclesOnMap()
        }
    }
    
    
    // Stops the map update (e.g. if the map view disappers)
    func stopMapUpdate() {
        updating = false
        if let fetchTimer = fetchTimer {
            fetchTimer.invalidate()
        }
    }
    
    // Fetches vehicles between the specified coordinates
    func fetchVehiclesInArea(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D, completion: @escaping (PoiData?) -> Void) {
        
        let urlString = "https://poi-api.mytaxi.com/PoiService/poi/v1?p2Lat=\(p2.latitude)&p1Lon=\(p1.longitude)&p1Lat=\(p1.latitude)&p2Lon=\(p2.longitude)"
        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        let apiRequest = APIRequest(url: url)
        apiRequest.perform { (poiData: PoiData?) in
            completion(poiData)
        }
    }
    
    // Calculate the distance and estimated travel time of potential transports
    func updateVehicleDistances(completion: @escaping () -> Void) {
        var tempList: [Vehicle] = []
        let group = DispatchGroup()

        for i in 0..<(vehicleList.count) {
            group.enter()
            var vehicle = vehicleList[i]
            getRoute(from: vehicle) { route in
                vehicle.distance = route?.distance
                vehicle.ett = route?.expectedTravelTime
                tempList.append(vehicle)
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.vehicleList = tempList
            //completion(tempList)
        }
    }
    
    // Helper function to get the first route
    func getRoute(from: Vehicle, completion: @escaping (_ route: MKRoute?) -> Void) {
        guard let locationCoordinates = locationManager?.location?.coordinate else {
            // Cannot access to current location
            print("Location cannot be inferred")
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
                completion(nil)
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
    
    // MARK: - Location manager setup and permisson handling
    func checkIfLocationServicesIsEnabled() {
        print("Checking location service permissions")
        if CLLocationManager.locationServicesEnabled() {
            // Init locationManager and assign the delegate.
            // Force unwrap is feasible since the object is created above.
            locationManager = CLLocationManager()
            checkLocationAuthorization()
            locationManager!.delegate = self
            centerOnUser()
            print("Location manager setup complete")
        } else {
            // TODO: Inform user to enable location services
            print("Location services are disabled")
        }
    }
    
    // Centers region on user
    func centerOnUser() {
        if let userCoordinates = locationManager!.location?.coordinate {
            region = MKCoordinateRegion(
                center: userCoordinates,
                span: MapInfo.defaultSpan
            )
        }
    }
    
    // Centers region on a specific area
    func centerMapOn(vehicle: Vehicle) {
        let coordinates = CLLocationCoordinate2D(
            latitude: vehicle.coordinate.latitude,
            longitude: vehicle.coordinate.longitude)
            region = MKCoordinateRegion(
                center: coordinates,
                span: MapInfo.defaultSpan
            )
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
