import SwiftUI
import UIKit
import CoreLocation

struct CircularDestinationView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @Environment(\.openURL) private var openURL

    @State private var transport: TransportMode = .driving

    // Interaction state moved into RingView to simplify body

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                GeometryReader { geo in
                    RingView(
                        size: geo.size,
                        onComplete: { source, target in
                            openAppleMaps(from: source, to: target)
                        },
                        onRequestManage: { showingManage = true },
                        onRequestEdit: { dest in editingDestination = dest }
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 24)
                
                // Transportation mode picker at the bottom
                Picker("Mode", selection: $transport) {
                    Image(systemName: "car.fill").tag(TransportMode.driving)
                    Image(systemName: "figure.walk").tag(TransportMode.walking)
                    Image(systemName: "bus.fill").tag(TransportMode.transit)
                    Image(systemName: "bicycle").tag(TransportMode.biking)
                }
                .pickerStyle(.segmented)
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
        .sheet(item: $editingDestination) { dest in
            EditDestinationView(destination: dest) { updated in
                destinationManager.update(updated)
            }
        }
    }

    @State private var showingManage = false
    @State private var showingSettings = false
    @State private var editingDestination: Destination? = nil

    private func openAppleMaps(from source: Endpoint, to destination: Endpoint) {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "maps.apple.com"
        var items: [URLQueryItem] = []

        // saddr
        switch source {
        case .current:
            items.append(URLQueryItem(name: "saddr", value: "Current Location"))
        case .saved(let dest):
            items.append(URLQueryItem(name: "saddr", value: "\(dest.coordinate.latitude),\(dest.coordinate.longitude)"))
        }

        // daddr
        switch destination {
        case .current:
            items.append(URLQueryItem(name: "daddr", value: "Current Location"))
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
    let onRequestEdit: (Destination) -> Void

    @State private var dragPoint: CGPoint? = nil
    @State private var startEndpoint: Endpoint? = nil
    @State private var hoverEndpoint: Endpoint? = nil
    @State private var hapticsPrepared: Bool = false
    @State private var positionsCache: [Endpoint: CGPoint] = [:]
    @State private var dragVelocity: CGPoint = .zero
    @State private var lastDragPoint: CGPoint? = nil
    @State private var dragStartTime: Date? = nil

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
            }
            .position(center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current Location")

            // Dynamic slots - 4 initially, 8 after first destination is set
            let hasDestinations = !destinationManager.destinations.isEmpty
            let slotCount = hasDestinations ? 8 : 4
            let slots = calculateSlots(count: slotCount)
            
            ForEach(0..<slotCount, id: \.self) { idx in
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
                    .contentShape(Rectangle())
                    .onTapGesture { onRequestEdit(destination) }
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
                
                // Create a dynamic curved path
                let (curvePath, curveControlPoint) = createDynamicCurvePath(from: startPos, to: endPos, velocity: dragVelocity)
                
                curvePath
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                // Enhanced arrowhead that follows the curve direction
                enhancedArrowHeadPath(from: startPos, to: endPos, control: curveControlPoint, size: 16, width: 12)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 2, x: 0, y: 1)
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
    
    // MARK: - Slot Calculation
    private func calculateSlots(count: Int) -> [Angle] {
        if count == 4 {
            // Four fixed cardinal slots (top, right, bottom, left)
            return [
                Angle(radians: -.pi/2), // top
                Angle(radians: 0),      // right
                Angle(radians: .pi/2),  // bottom
                Angle(radians: .pi)     // left
            ]
        } else {
            // Eight evenly spaced slots
            return (0..<8).map { idx in
                Angle(radians: Double(idx) * .pi / 4) // 45° intervals
            }
        }
    }

    // MARK: - Dynamic Curve Creation
    private func createDynamicCurvePath(from startPos: CGPoint, to endPos: CGPoint, velocity: CGPoint) -> (Path, CGPoint) {
        // Calculate control point for dynamic quadratic curve
        let midX = (startPos.x + endPos.x) / 2
        let midY = (startPos.y + endPos.y) / 2
        
        // Vector from start to end
        let dx = endPos.x - startPos.x
        let dy = endPos.y - startPos.y
        let distance = sqrt(dx * dx + dy * dy)
        
        var controlPoint: CGPoint = .zero
        
        let path = Path { path in
            path.move(to: startPos)
            
            // Only create curve if there's meaningful distance
            if distance > 20 {
                // Perpendicular vector (rotated 90 degrees)
                let perpX = -dy
                let perpY = dx
                
                // Normalize the perpendicular vector
                let perpLength = sqrt(perpX * perpX + perpY * perpY)
                
                // Dynamic curve factors based on velocity and distance
                let velocityMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
                let velocityFactor = min(velocityMagnitude / 10, 2.0) // Scale velocity impact
                let baseCurveFactor = min(distance * 0.4, 80) // Base curve intensity
                let dynamicCurveFactor = baseCurveFactor * (1.0 + velocityFactor * 0.8)
                
                // Add some directional bias based on drag velocity
                let velocityBias = velocity.x * perpX + velocity.y * perpY
                let directionFactor = velocityBias > 0 ? 1.2 : 0.8
                
                let finalCurveFactor = dynamicCurveFactor * directionFactor
                
                let controlX = midX + (perpX / perpLength) * finalCurveFactor
                let controlY = midY + (perpY / perpLength) * finalCurveFactor
                controlPoint = CGPoint(x: controlX, y: controlY)
                
                path.addQuadCurve(to: endPos, control: controlPoint)
            } else {
                // Fall back to straight line for very short distances
                controlPoint = CGPoint(x: midX, y: midY)
                path.addLine(to: endPos)
            }
        }
        
        return (path, controlPoint)
    }

    // MARK: - Helpers
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let currentTime = Date()
                
                // Calculate velocity
                if let lastPoint = lastDragPoint, let startTime = dragStartTime {
                    let timeDelta = currentTime.timeIntervalSince(startTime)
                    if timeDelta > 0.016 { // ~60fps throttle
                        let dx = value.location.x - lastPoint.x
                        let dy = value.location.y - lastPoint.y
                        let dt = timeDelta
                        
                        dragVelocity = CGPoint(
                            x: dx / dt * 0.3 + dragVelocity.x * 0.7, // Smooth velocity with exponential moving average
                            y: dy / dt * 0.3 + dragVelocity.y * 0.7
                        )
                        
                        lastDragPoint = value.location
                        dragStartTime = currentTime
                    }
                } else {
                    lastDragPoint = value.location
                    dragStartTime = currentTime
                }
                
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
        dragVelocity = .zero
        lastDragPoint = nil
        dragStartTime = nil
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

    // Enhanced arrowhead that follows the curve direction
    private func enhancedArrowHeadPath(from start: CGPoint, to end: CGPoint, control: CGPoint, size: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        
        // Calculate tangent direction at the end of the curve
        // For quadratic curve, tangent at end = 2 * (end - control)
        let tangentX = 2 * (end.x - control.x)
        let tangentY = 2 * (end.y - control.y)
        let tangentLength = sqrt(tangentX * tangentX + tangentY * tangentY)
        
        let angle: CGFloat
        if tangentLength > 0.001 {
            // Use curve tangent direction
            angle = atan2(tangentY, tangentX)
        } else {
            // Fallback to straight line direction
            let dx = end.x - start.x
            let dy = end.y - start.y
            angle = atan2(dy, dx)
        }
        
        // Tip at end
        let tip = end
        // Base center pulled back along the tangent by `size`
        let baseCenter = CGPoint(x: end.x - cos(angle) * size, y: end.y - sin(angle) * size)
        // Perpendicular to the tangent for base corners
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
        
        // Dynamic slot calculation
        let hasDestinations = !destinationManager.destinations.isEmpty
        let slotCount = hasDestinations ? 8 : 4
        let slots = calculateSlots(count: slotCount)
        
        let showCount = min(slotCount, destinationManager.destinations.count)
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
