import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FitnessTrackingView()
                .tabItem {
                    Label("Fitness", systemImage: "figure.run")
                }

            FoodTrackingView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
