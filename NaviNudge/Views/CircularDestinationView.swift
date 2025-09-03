import SwiftUI
import CoreLocation

struct CircularDestinationView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.openURL) private var openURL

    @State private var transport: TransportMode = .driving

    // Interaction state moved into RingView to simplify body

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                GeometryReader { geo in
                    RingView(size: geo.size) { source, target in
                        openAppleMaps(from: source, to: target)
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
            .padding(.vertical, 16)
        }
        .onAppear {
            if locationManager.currentCoordinate == nil {
                locationManager.start()
            }
        }
    }

    private func openAppleMaps(from source: Endpoint, to destination: Endpoint) {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "maps.apple.com"
        var items: [URLQueryItem] = []

        // saddr
        switch source {
        case .current:
            if let current = locationManager.currentCoordinate {
                items.append(URLQueryItem(name: "saddr", value: "\(current.latitude),\(current.longitude)"))
            } else {
                items.append(URLQueryItem(name: "saddr", value: "Current Location"))
            }
        case .saved(let dest):
            items.append(URLQueryItem(name: "saddr", value: "\(dest.coordinate.latitude),\(dest.coordinate.longitude)"))
        }

        // daddr
        switch destination {
        case .current:
            if let current = locationManager.currentCoordinate {
                items.append(URLQueryItem(name: "daddr", value: "\(current.latitude),\(current.longitude)"))
            } else {
                // Fallback to same as source if unknown; but generally destination won't be current
                items.append(URLQueryItem(name: "daddr", value: "Current Location"))
            }
        case .saved(let dest):
            items.append(URLQueryItem(name: "daddr", value: "\(dest.coordinate.latitude),\(dest.coordinate.longitude)"))
        }

        items.append(URLQueryItem(name: "dirflg", value: transport.dirflg))
        comps.queryItems = items

        if let url = comps.url {
            openURL(url)
        }
    }

}

// MARK: - Ring View (extracted)
private struct RingView: View {
    @EnvironmentObject private var destinationManager: DestinationManager

    let size: CGSize
    let onComplete: (Endpoint, Endpoint) -> Void

    @State private var dragPoint: CGPoint? = nil
    @State private var startEndpoint: Endpoint? = nil
    @State private var hoverEndpoint: Endpoint? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)

            let radius = min(size.width, size.height) * 0.38
            let center = CGPoint(x: size.width/2, y: size.height/2)

            // Center current-location node
            VStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(nodeFill(for: .current)))
                Text("You")
                    .foregroundStyle(.primary)
                    .font(.caption)
            }
            .position(center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current Location")

            // Ring of saved destinations
            ForEach(Array(destinationManager.destinations.enumerated()), id: \.1.id) { index, destination in
                let angle = Angle(radians: Double(index) / Double(max(destinationManager.destinations.count, 1)) * (.pi * 2))
                let pos = position(on: angle, radius: radius, in: size)
                VStack(spacing: 6) {
                    Image(systemName: destination.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(nodeFill(for: .saved(destination))))
                    Text(destination.name)
                        .foregroundStyle(.primary)
                        .font(.caption)
                }
                .position(pos)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(destination.name)
            }

            // Dynamic path indicator during drag
            if let start = startEndpoint, let startPos = nodePositions(in: size)[start] {
                let endPos: CGPoint = {
                    if let hover = hoverEndpoint, let pos = nodePositions(in: size)[hover] { return pos }
                    if let p = dragPoint { return p }
                    return startPos
                }()
                Path { path in
                    path.move(to: startPos)
                    path.addLine(to: endPos)
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .position(endPos)
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    // MARK: - Helpers
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragPoint = value.location
                let positions = nodePositions(in: size)
                if startEndpoint == nil {
                    startEndpoint = nearestEndpoint(to: value.location, positions: positions)
                } else {
                    let nearest = nearestEndpoint(to: value.location, positions: positions)
                    hoverEndpoint = (nearest == startEndpoint) ? nil : nearest
                }
            }
            .onEnded { _ in
                if let source = startEndpoint, let target = hoverEndpoint, source != target {
                    onComplete(source, target)
                }
                resetDragState()
            }
    }

    private func resetDragState() {
        dragPoint = nil
        startEndpoint = nil
        hoverEndpoint = nil
    }

    private func position(on angle: Angle, radius: CGFloat, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let x = center.x + radius * cos(CGFloat(angle.radians))
        let y = center.y + radius * sin(CGFloat(angle.radians))
        return CGPoint(x: x, y: y)
    }

    private func nodeFill(for endpoint: Endpoint) -> Color {
        if endpoint == startEndpoint { return .accentColor.opacity(0.25) }
        if endpoint == hoverEndpoint { return .accentColor.opacity(0.18) }
        return .secondary.opacity(0.12)
    }

    private func nodePositions(in size: CGSize) -> [Endpoint: CGPoint] {
        var map: [Endpoint: CGPoint] = [:]
        let center = CGPoint(x: size.width/2, y: size.height/2)
        map[.current] = center
        let radius = min(size.width, size.height) * 0.38
        for (index, dest) in destinationManager.destinations.enumerated() {
            let angle = Angle(radians: Double(index) / Double(max(destinationManager.destinations.count, 1)) * (.pi * 2))
            map[.saved(dest)] = position(on: angle, radius: radius, in: size)
        }
        return map
    }

    private func nearestEndpoint(to point: CGPoint, positions: [Endpoint: CGPoint]) -> Endpoint? {
        let baseThreshold: CGFloat = 44
        var best: (Endpoint, CGFloat)? = nil
        for (endpoint, pos) in positions {
            let d = hypot(point.x - pos.x, point.y - pos.y)
            if best == nil || d < best!.1 { best = (endpoint, d) }
        }
        if let best = best, best.1 <= baseThreshold { return best.0 }
        return nil
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

// Represents a draggable endpoint: current location or a saved destination
private enum Endpoint: Hashable, Identifiable {
    case current
    case saved(Destination)
    var id: String {
        switch self {
        case .current: return "current"
        case .saved(let d): return d.id.uuidString
        }
    }
}
