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
                    viewModel.startMapUpdate()
                }
                .onDisappear {
                    viewModel.stopMapUpdate()
                }
            VehicleListView(viewModel: viewModel)
                .onAppear {
                    viewModel.fetchAllVehicles()
                }
        }                .onAppear {
            viewModel.checkIfLocationServicesIsEnabled()
        }
    }
}

// Map view that shows a specific region
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
                    // TODO: Add animation (might need to ditch SwiftUI) and custom icons
                    Image(systemName: "location.north.fill")
                        .resizable()
                        .foregroundColor(Color.pink)
                        .rotationEffect(Angle.degrees(vehicle.heading))
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
    }
}

// List that shows all cars
struct VehicleListView: View {
    @StateObject var viewModel: VehicleViewModel
    var body: some View {
        List {
            Section(header: ListHeader(), footer: ListFooter()) {
                ForEach(viewModel.vehicleList) { vehicle in
                    VehicleItem(viewModel: viewModel, vehicle: vehicle)
                }
            }
        }
        .listStyle(DefaultListStyle())
    }
}

// Rows
struct VehicleItem: View {
     var viewModel: VehicleViewModel
    @State var vehicle: Vehicle

    var body: some View {
        HStack(alignment: .center, spacing: 40.0) {
            // A placeholder for potential car-type icon
            if !vehicle.selected {
                TransportTypeBadge(
                    type: vehicle.type,
                    size: 40)
            }
            TransportStateInfoView(
                type: vehicle.type.rawValue,
                state: vehicle.state.rawValue)
            if vehicle.selected {
                Spacer()
                TransportDistanceInfoView(
                    distance: vehicle.distance?.distanceString ?? "NA",
                    ett: vehicle.ett?.timeString ?? "NA")
            }
        }
        .onTapGesture {
            withAnimation {
                if !vehicle.selected {
                    viewModel.getRoute(from: vehicle) { route in
                        vehicle.distance = route?.distance
                        vehicle.ett = route?.expectedTravelTime
                    }
                    viewModel.centerMapOn(vehicle: vehicle)
                }
                vehicle.selected.toggle()
            }
        }
    }
}

// MARK: - Helper views
struct TransportStateInfoView: View {
    let type: String
    let state: String
    var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            Text(type)
                .font(.headline)
            Text(state)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct TransportDistanceInfoView: View {
    let distance: String
    let ett: String
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Badge(text: distance, imageName: "arrowtriangle.up.circle")
                .foregroundColor(.blue)
            Badge(text: ett, imageName: "stopwatch")
                .foregroundColor(.pink)
        }
        .font(.callout)
        .padding(10)
        .cornerRadius(10)
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

struct TransportTypeBadge: View {
    let imageName: String
    let size: Double
    
    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(Color.pink)
    }
}

extension TransportTypeBadge {
    init(type: VehicleType, size: Double) {
        switch type {
        case .taxi:
            imageName = "car.circle.fill"
        default:
            imageName = "figure.wave.circle.fill"
        }
        self.size = size
    }
}

struct ListHeader: View {
    var body: some View {
        
        HStack(alignment: .bottom, spacing: 0) {
            Text("Available Cars")
                .font(.system(size: 24))
            Spacer()
            Text("Tap for details")
                .font(.system(size: 12))
        }
    }
}

struct ListFooter: View {
    var body: some View {
        HStack {
            Text("Kerem Donmez")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VehicleView()
        }
    }
}
