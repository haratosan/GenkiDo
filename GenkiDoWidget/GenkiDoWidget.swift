import WidgetKit
import SwiftUI
import SwiftData

struct GenkiDoWidgetEntry: TimelineEntry {
    let date: Date
    let completedExercises: Int
    let totalExercises: Int
    let hasMealAfterCutoff: Bool
}

struct GenkiDoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GenkiDoWidgetEntry {
        GenkiDoWidgetEntry(date: .now, completedExercises: 2, totalExercises: 4, hasMealAfterCutoff: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (GenkiDoWidgetEntry) -> Void) {
        let entry = GenkiDoWidgetEntry(date: .now, completedExercises: 2, totalExercises: 4, hasMealAfterCutoff: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GenkiDoWidgetEntry>) -> Void) {
        let entry = fetchTodayData()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchTodayData() -> GenkiDoWidgetEntry {
        let today = Calendar.current.startOfDay(for: .now)
        var completedCount = 0
        var hasMealAfterCutoff = false

        do {
            let container = try ModelContainer(
                for: ExerciseRecord.self, Meal.self,
                configurations: ModelConfiguration(
                    groupContainer: .identifier("group.ch.budo-team.GenkiDo")
                )
            )
            let context = ModelContext(container)

            // Fetch exercises
            let exerciseDescriptor = FetchDescriptor<ExerciseRecord>(
                predicate: #Predicate { $0.date == today }
            )
            let exercises = try context.fetch(exerciseDescriptor)
            completedCount = exercises.filter { $0.count >= 50 }.count

            // Fetch meals
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            let mealDescriptor = FetchDescriptor<Meal>(
                predicate: #Predicate { $0.timestamp >= today && $0.timestamp < dayEnd }
            )
            let meals = try context.fetch(mealDescriptor)
            hasMealAfterCutoff = meals.contains { meal in
                Calendar.current.component(.hour, from: meal.timestamp) >= 18
            }
        } catch {
            print("Widget fetch error: \(error)")
        }

        return GenkiDoWidgetEntry(
            date: .now,
            completedExercises: completedCount,
            totalExercises: 4,
            hasMealAfterCutoff: hasMealAfterCutoff
        )
    }
}

struct GenkiDoWidgetEntryView: View {
    var entry: GenkiDoWidgetEntry
    @Environment(\.widgetFamily) var family

    var isComplete: Bool {
        entry.completedExercises == entry.totalExercises && !entry.hasMealAfterCutoff
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    var smallWidget: some View {
        VStack(spacing: 8) {
            Image(systemName: isComplete ? "checkmark.seal.fill" : "figure.run")
                .font(.system(size: 32))
                .foregroundStyle(isComplete ? .green : .blue)

            Text("\(entry.completedExercises)/\(entry.totalExercises)")
                .font(.title)
                .fontWeight(.bold)

            Text("Übungen")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entry.hasMealAfterCutoff {
                Image(systemName: "moon.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var mediumWidget: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: isComplete ? "checkmark.seal.fill" : "figure.run")
                    .font(.system(size: 40))
                    .foregroundStyle(isComplete ? .green : .blue)

                Text(isComplete ? "Geschafft!" : "Weiter so!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fitness")
                        .font(.headline)
                    Spacer()
                    Text("\(entry.completedExercises)/\(entry.totalExercises)")
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.completedExercises == entry.totalExercises ? .green : .primary)
                }

                ProgressView(value: Double(entry.completedExercises), total: Double(entry.totalExercises))
                    .tint(entry.completedExercises == entry.totalExercises ? .green : .blue)

                HStack {
                    Text("Fasten")
                        .font(.headline)
                    Spacer()
                    Image(systemName: entry.hasMealAfterCutoff ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(entry.hasMealAfterCutoff ? .orange : .green)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct GenkiDoWidget: Widget {
    let kind: String = "GenkiDoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenkiDoWidgetProvider()) { entry in
            GenkiDoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GenkiDo")
        .description("Tagesstatus für Fitness und Fasten")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    GenkiDoWidget()
} timeline: {
    GenkiDoWidgetEntry(date: .now, completedExercises: 2, totalExercises: 4, hasMealAfterCutoff: false)
    GenkiDoWidgetEntry(date: .now, completedExercises: 4, totalExercises: 4, hasMealAfterCutoff: false)
}

#Preview(as: .systemMedium) {
    GenkiDoWidget()
} timeline: {
    GenkiDoWidgetEntry(date: .now, completedExercises: 3, totalExercises: 4, hasMealAfterCutoff: true)
}
