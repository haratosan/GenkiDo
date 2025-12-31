import SwiftUI
import SwiftData
import WidgetKit

@main
struct GenkiDoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExerciseRecord.self,
            Meal.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.ch.budo-team.GenkiDo"),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
