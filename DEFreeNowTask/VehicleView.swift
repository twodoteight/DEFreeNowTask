//
//  TaxiView.swift
//  DEFreeNowTask
//
//  Created by Kerem on 26.12.2021.
//
import MapKit
import SwiftUI
import CoreData

struct VehicleView: View {
    
    
    @StateObject private var model = VehicleViewModel()
    
    //@State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(coordinateRegion: $model.region, showsUserLocation: true)
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height / 3,
                    alignment: Alignment(horizontal: .center, vertical: .top))
                .accentColor(Color(.systemIndigo))
                .onAppear {
                    model.checkIfLocationServicesIsEnabled()
                }
            
            Text("Cars")
                .font(.system(size: 30))
                .padding(10)
            
            List {
                ListHeader().zIndex(1)               // << header
                    .frame(height: 60)
                ForEach(model.vehicleList, id: \.id) { vehicle in
                    VehicleItem(item: vehicle)
                }
            }
            .listStyle(DefaultListStyle())
            .onAppear(perform: model.fetchAllVehicles)
            .navigationTitle("Cars")
            
        }
        
    }
}
struct VehicleItem: View {
    let type: String
    let state: String
    let distance: String
    let ett: String
    var body: some View {
        HStack(alignment: .center, spacing: 40.0) {
            Circle().frame(width: 60, height: 60, alignment: .center)
            VStack(alignment: .leading, spacing: 20.0) {
                Text(type)
                    .font(.headline)
                Text(state)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                HStack() {
                    if #available(iOS 15.0, *) {
                        Badge(text: distance, imageName: "arrowtriangle.up.circle")
                            .foregroundColor(.teal)
                    } else {
                        Badge(text: distance, imageName: "arrowtriangle.up.circle")
                            .foregroundColor(.blue)
                    }
                    Badge(text: ett, imageName: "ellipses.bubble")
                        .padding(.leading, 96.0)
                        .foregroundColor(.orange)
                }
                .font(.callout)
                .padding(.bottom)
            }
        }
        .padding(.top, 16.0)
    }
}

extension VehicleItem {
    init(item: Vehicle) {
        type = item.type.rawValue
        distance = "5"
        ett = "5"
        state = "Currently " + item.state.rawValue
    }
}

struct Badge: View {
    let text: String
    let imageName: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
            Text(text)
        }
    }
}

struct Annotation: View {
    let imageName: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
        }
    }
}

struct ListHeader: View {
    var body: some View {
        HStack {
            Text("Cars")
                .font(.system(size: 20))
        }
    }
}

struct ListFooter: View {
    var body: some View {
        HStack {
            Text("DotEight")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VehicleView()
        }
    }
}

public extension MKMapView {
    
    var newBounds: MapBounds {
        let originPoint = CGPoint(x: bounds.origin.x + bounds.size.width, y: bounds.origin.y)
        let rightBottomPoint = CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height)
        
        let originCoordinates = convert(originPoint, toCoordinateFrom: self)
        let rightBottomCoordinates = convert(rightBottomPoint, toCoordinateFrom: self)
        
        return MapBounds(
            firstBound: CLLocation(latitude: originCoordinates.latitude, longitude: originCoordinates.longitude),
            secondBound: CLLocation(latitude: rightBottomCoordinates.latitude, longitude: rightBottomCoordinates.longitude)
        )
    }
}

public struct MapBounds {
    let firstBound: CLLocation
    let secondBound: CLLocation
}
