import Foundation

enum MapsURLParser {
    struct ParsedLocation {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    static func parse(_ url: URL) -> ParsedLocation? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("maps.apple.com") {
            return parseAppleMaps(url)
        }
        if url.scheme?.lowercased() == "geo" {
            return parseGeo(url)
        }
        return nil
    }

    private static func parseAppleMaps(_ url: URL) -> ParsedLocation? {
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        // Apple Maps sometimes embeds a URL in the fragment; attempt to parse that too.
        if comps.queryItems == nil || comps.queryItems?.isEmpty == true, let fragment = url.fragment, let fragURL = URL(string: "https://maps.apple.com/?" + fragment), let fragComps = URLComponents(url: fragURL, resolvingAgainstBaseURL: false) {
            comps = fragComps
        }

        let queryItems = comps.queryItems ?? []
        func value(_ name: String) -> String? { queryItems.first(where: { $0.name == name })?.value }

        // Try ll
        if let ll = value("ll")?.replacingOccurrences(of: " ", with: ""),
           let lat = Double(ll.split(separator: ",").first ?? ""),
           let lon = Double(ll.split(separator: ",").last ?? "")
        {
            let rawName = value("q") ?? value("address") ?? "Pinned Location"
            let name = decodePlus(rawName)
            return ParsedLocation(name: name, latitude: lat, longitude: lon)
        }

        // Try daddr (destination addr) if present
        if let daddr = value("daddr")?.replacingOccurrences(of: " ", with: ""), daddr.contains(",") {
            let parts = daddr.split(separator: ",")
            if parts.count >= 2, let lat = Double(parts[0]), let lon = Double(parts[1]) {
                let rawName = value("q") ?? value("address") ?? "Pinned Location"
                let name = decodePlus(rawName)
                return ParsedLocation(name: name, latitude: lat, longitude: lon)
            }
        }

        return nil
    }

    private static nonisolated func decodePlus(_ s: String) -> String {
        // Replace + with space then percent-decode
        let replaced = s.replacingOccurrences(of: "+", with: " ")
        return replaced.removingPercentEncoding ?? replaced
    }

    private static func parseGeo(_ url: URL) -> ParsedLocation? {
        // Format: geo:lat,lon?q=Name
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let schemeSpecific = url.absoluteString.drop(while: { $0 != ":" }).dropFirst() // after :
        let base = schemeSpecific.split(separator: "?").first.map(String.init) ?? ""
        let parts = base.split(separator: ",")
        guard parts.count >= 2, let lat = Double(parts[0]), let lon = Double(parts[1]) else { return nil }
        let name = comps.queryItems?.first(where: { $0.name == "q" })?.value.map(decodePlus) ?? "Pinned Location"
        return ParsedLocation(name: name, latitude: lat, longitude: lon)
    }
}
