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
    
    @StateObject private var viewModel = VehicleViewModel()
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            VehicleMapView(region: $viewModel.region,
                           userTrackingMode: $userTrackingMode,
                           vehicleList: viewModel.vehiclesInViewList)
                .onAppear {
                    viewModel.checkIfLocationServicesIsEnabled()
                    viewModel.startMapUpdate()
                }
                .onDisappear {
                    viewModel.stopMapUpdate()
                }
                            
            List {
                Section(header: ListHeader(), footer: ListFooter()) {
                    ForEach(viewModel.vehicleList, id: \.id) { vehicle in
                        VehicleItem(item: vehicle)
                    }
                }

            }
            .listStyle(DefaultListStyle())
            .onAppear {
                viewModel.fetchAllVehicles()
            }
        }
        
    }
}

struct VehicleMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MapUserTrackingMode
    var vehicleList: [Vehicle]
    
    @State private var expanded = false

    var body: some View {
        
        ZStack() {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: vehicleList) {vehicle in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: vehicle.coordinate.latitude, longitude: vehicle.coordinate.longitude)) {
                    Image(systemName: "arrow.right.circle.fill")
                        .rotationEffect(Angle.degrees(vehicle.heading - 90))
                }

            }
            .accentColor(Color(.systemIndigo))
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button() {
                        withAnimation {
                            expanded.toggle()
                        }
                    } label: {
                        Image(systemName: expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(Color.pink)
                    .font(.title3)
                    .clipShape(Circle())
                    .padding([.trailing, .bottom])
                }
            }
            
        }
        .edgesIgnoringSafeArea([.top])
        .frame(
            width: UIScreen.main.bounds.width,
            height: self.expanded ? UIScreen.main.bounds.height : UIScreen.main.bounds.height / 3,
            alignment: Alignment(horizontal: .center, vertical: .top))
//        Text("Cars")
//            .font(.system(size: 30))
//            .padding(10)
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
        
        HStack(alignment: .top, spacing: 0) {
            Text("Cars")
                .font(.system(size: 30))
        
}
    }
//        .zIndex(1)
//        .frame(height: 60)
    
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
