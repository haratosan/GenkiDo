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
                    Label("Essen", systemImage: "fork.knife")
                }

            HistoryView()
                .tabItem {
                    Label("Verlauf", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
