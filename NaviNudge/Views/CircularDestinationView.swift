import SwiftUI
import CoreLocation
import UIKit

struct CircularDestinationView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.openURL) private var openURL

    @State private var transport: TransportMode = .driving

    // Interaction state moved into RingView to simplify body

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Transportation mode picker at the top
                Picker("Mode", selection: $transport) {
                    Text("Drive").tag(TransportMode.driving)
                    Text("Walk").tag(TransportMode.walking)
                    Text("Transit").tag(TransportMode.transit)
                    Text("Bike").tag(TransportMode.biking)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                
                GeometryReader { geo in
                    RingView(
                        size: geo.size,
                        onComplete: { source, target in
                            openAppleMaps(from: source, to: target)
                        },
                        onRequestManage: { showingManage = true }
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingManage) {
            ManageDestinationsView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            if locationManager.currentCoordinate == nil {
                locationManager.start()
            }
        }
    }

    @State private var showingManage = false
    @State private var showingSettings = false

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
    let onRequestManage: () -> Void

    @State private var dragPoint: CGPoint? = nil
    @State private var startEndpoint: Endpoint? = nil
    @State private var hoverEndpoint: Endpoint? = nil
    @State private var hapticsPrepared: Bool = false
    @State private var positionsCache: [Endpoint: CGPoint] = [:]

    var body: some View {
        ZStack {
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

            // Four fixed cardinal slots (top, right, bottom, left)
            let slots: [Angle] = [
                Angle(radians: -.pi/2), // top
                Angle(radians: 0),      // right
                Angle(radians: .pi/2),  // bottom
                Angle(radians: .pi)     // left
            ]
            ForEach(0..<4, id: \.self) { idx in
                let pos = position(on: slots[idx], radius: radius, in: size)
                if idx < destinationManager.destinations.count {
                    let destination = destinationManager.destinations[idx]
                    VStack(spacing: 6) {
                        Text(destination.icon)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(nodeFill(for: .saved(destination))))
                        Text(destination.name)
                            .foregroundStyle(.primary)
                            .font(.caption)
                    }
                    .position(pos)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(destination.name)
                } else {
                    Button(action: { onRequestManage() }) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle().fill(Color.secondary.opacity(0.12))
                                )
                            Text("Add")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(pos)
                    .accessibilityLabel("Add destination")
                }
            }

            // Dynamic path indicator during drag
            if let start = startEndpoint, let startPos = positionsCache[start] {
                let endPos: CGPoint = {
                    if let hover = hoverEndpoint, let pos = positionsCache[hover] { return pos }
                    if let p = dragPoint { return p }
                    return startPos
                }()
                Path { path in
                    path.move(to: startPos)
                    path.addLine(to: endPos)
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Arrowhead at the end of the line
                arrowHeadPath(from: startPos, to: endPos, size: 12, width: 9)
                    .fill(Color.accentColor)
            }
        }
        // Avoid implicit animations during high-frequency drag updates
        .animation(nil, value: dragPoint)
        .animation(nil, value: hoverEndpoint)
        .animation(nil, value: startEndpoint)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onAppear {
            if !hapticsPrepared {
                Haptics.prepareSelection()
                hapticsPrepared = true
            }
            updatePositionsCache()
        }
        .onChange(of: size) { _, _ in updatePositionsCache() }
        .onChange(of: destinationManager.destinations) { _, _ in updatePositionsCache() }
    }

    // MARK: - Helpers
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragPoint = value.location
                let positions = positionsCache
                if startEndpoint == nil {
                    let newly = nearestEndpoint(to: value.location, positions: positions)
                    if newly != nil { Haptics.selectionChanged() }
                    startEndpoint = newly
                } else {
                    let nearest = nearestEndpoint(to: value.location, positions: positions)
                    let nextHover = (nearest == startEndpoint) ? nil : nearest
                    if nextHover != hoverEndpoint, nextHover != nil { Haptics.selectionChanged() }
                    hoverEndpoint = nextHover
                }
            }
            .onEnded { _ in
                if let source = startEndpoint, let target = hoverEndpoint, source != target {
                    Haptics.impactLight()
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

    // Build an arrowhead triangle pointing from start to end
    private func arrowHeadPath(from start: CGPoint, to end: CGPoint, size: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        // Tip at end
        let tip = end
        // Base center pulled back along the line by `size`
        let baseCenter = CGPoint(x: end.x - cos(angle) * size, y: end.y - sin(angle) * size)
        // Perpendicular to the line for base corners
        let perpAngle = angle + .pi / 2
        let left = CGPoint(x: baseCenter.x + cos(perpAngle) * width/2, y: baseCenter.y + sin(perpAngle) * width/2)
        let right = CGPoint(x: baseCenter.x - cos(perpAngle) * width/2, y: baseCenter.y - sin(perpAngle) * width/2)
        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.addLine(to: tip)
        return path
    }

    private func updatePositionsCache() {
        var map: [Endpoint: CGPoint] = [:]
        let center = CGPoint(x: size.width/2, y: size.height/2)
        map[.current] = center
        let radius = min(size.width, size.height) * 0.38
        let slots: [Angle] = [
            Angle(radians: -.pi/2), // top
            Angle(radians: 0),      // right
            Angle(radians: .pi/2),  // bottom
            Angle(radians: .pi)     // left
        ]
        let showCount = min(4, destinationManager.destinations.count)
        if showCount > 0 {
            for i in 0..<showCount {
                let dest = destinationManager.destinations[i]
                map[.saved(dest)] = position(on: slots[i], radius: radius, in: size)
            }
        }
        positionsCache = map
    }

    private func nearestEndpoint(to point: CGPoint, positions: [Endpoint: CGPoint]) -> Endpoint? {
        let baseThreshold: CGFloat = 44
        var best: (Endpoint, CGFloat)? = nil
        for (endpoint, pos) in positions {
            // Compare squared distances to avoid sqrt cost
            let dx = point.x - pos.x
            let dy = point.y - pos.y
            let d2 = dx*dx + dy*dy
            if let current = best {
                if d2 < current.1 { best = (endpoint, d2) }
            } else {
                best = (endpoint, d2)
            }
        }
        if let best = best, best.1 <= baseThreshold*baseThreshold { return best.0 }
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
