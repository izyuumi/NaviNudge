import SwiftUI
import CoreLocation

struct CircularDestinationView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.openURL) private var openURL

    @State private var transport: TransportMode = .driving

    var body: some View {
        ZStack {
            LinearGradient(colors: [.green.opacity(0.7), .teal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("NaviNudge")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 2)
                        let radius = min(geo.size.width, geo.size.height) * 0.38
                        ForEach(Array(destinationManager.destinations.enumerated()), id: \.1.id) { index, destination in
                            let angle = Angle(radians: Double(index) / Double(max(destinationManager.destinations.count, 1)) * (.pi * 2))
                            DestinationButton(destination: destination)
                                .position(position(on: angle, radius: radius, in: geo.size))
                                .onTapGesture { openAppleMaps(to: destination.coordinate) }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 24)

                Picker("Mode", selection: $transport) {
                    Text("Drive").tag(TransportMode.driving)
                    Text("Walk").tag(TransportMode.walking)
                    Text("Transit").tag(TransportMode.transit)
                    Text("Bike").tag(TransportMode.biking)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            if locationManager.currentCoordinate == nil {
                locationManager.start()
            }
        }
    }

    private func position(on angle: Angle, radius: CGFloat, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let x = center.x + radius * cos(CGFloat(angle.radians))
        let y = center.y + radius * sin(CGFloat(angle.radians))
        return CGPoint(x: x, y: y)
    }

    private func openAppleMaps(to destination: CLLocationCoordinate2D) {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "maps.apple.com"
        var items: [URLQueryItem] = []

        if let current = locationManager.currentCoordinate {
            items.append(URLQueryItem(name: "saddr", value: "\(current.latitude),\(current.longitude)"))
        } else {
            items.append(URLQueryItem(name: "saddr", value: "Current Location"))
        }
        items.append(URLQueryItem(name: "daddr", value: "\(destination.latitude),\(destination.longitude)"))
        items.append(URLQueryItem(name: "dirflg", value: transport.dirflg))
        comps.queryItems = items

        if let url = comps.url {
            openURL(url)
        }
    }
}

private enum TransportMode: CaseIterable, Identifiable, Hashable {
    case driving, walking, transit, biking
    var id: Self { self }
    var dirflg: String {
        switch self {
        case .driving: return "d"
        case .walking: return "w"
        case .transit: return "r"
        case .biking: return "b"
        }
    }
}

