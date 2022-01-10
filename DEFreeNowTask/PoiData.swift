//
//  Taxi.swift
//  DEFreeNowTask
//
//  Created by Kerem on 31.12.2021.
//

import Foundation

// MARK: - PoiData
// Root data
struct PoiData: Decodable {
    var poiList: [Vehicle]
}

// MARK: - Vehicle
// Named vehicle to encapsulate other possible types
struct Vehicle: Identifiable  {
    let id: Int
    var coordinate: Coordinate
    var state: VehicleState
    let type: VehicleType
    var heading: Double
    var distance: Double = 0
    var ett: Double = 0
}

extension Vehicle: Decodable {
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case coordinate = "coordinate"
            case state = "state"
            case type = "type"
            case heading = "heading"
        }
}

// MARK: - Coordinate
// Struct decoding the nested coordinate data
struct Coordinate {
    var latitude: Double
    var longitude: Double
    //var location: CLLocation
}

extension Coordinate: Decodable {
    enum CodingKeys: String, CodingKey {
        case latitude = "latitude"
        case longitude = "longitude"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        //location = CLLocation(latitude: latitude, longitude: longitude)
    }
    
}
// MARK: - Types
enum VehicleState: String, Decodable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
}

enum VehicleType: String, Decodable {
    case taxi = "TAXI"
}

// MARK: - Formatting
extension Int {
    var toString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension Double {
    var distanceString: String {
        let distanceFormatter = MeasurementFormatter()
        distanceFormatter.unitOptions = .providedUnit
        let measurement = Measurement(value: self, unit: UnitLength.meters)
        return distanceFormatter.string(from: measurement)
    }
}
