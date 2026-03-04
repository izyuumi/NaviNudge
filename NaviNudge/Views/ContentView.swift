import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CircularDestinationView()
            }
            .tabItem {
                Label("Home", systemImage: "circle.grid.cross")
            }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
        }
    }
}
