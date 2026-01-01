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
        GenkiDoWidgetEntry(date: .now, completedExercises: 3, totalExercises: 5, hasMealAfterCutoff: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (GenkiDoWidgetEntry) -> Void) {
        let entry = GenkiDoWidgetEntry(date: .now, completedExercises: 3, totalExercises: 5, hasMealAfterCutoff: false)
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
        var totalCount = 5
        var hasMealOutsideWindow = false

        do {
            let container = try ModelContainer(
                for: ExerciseRecord.self, Meal.self, CustomExercise.self,
                configurations: ModelConfiguration(
                    groupContainer: .identifier("group.ch.budo-team.GenkiDo")
                )
            )
            let context = ModelContext(container)

            // Fetch active custom exercises
            let customExerciseDescriptor = FetchDescriptor<CustomExercise>(
                predicate: #Predicate { $0.isActive },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let customExercises = try context.fetch(customExerciseDescriptor)

            if !customExercises.isEmpty {
                totalCount = customExercises.count

                // Fetch today's exercise records
                let exerciseDescriptor = FetchDescriptor<ExerciseRecord>(
                    predicate: #Predicate { $0.date == today }
                )
                let exerciseRecords = try context.fetch(exerciseDescriptor)

                // Count completed exercises
                completedCount = customExercises.filter { exercise in
                    let exerciseId = exercise.id.uuidString
                    guard let record = exerciseRecords.first(where: { $0.exerciseType == exerciseId }) else {
                        return false
                    }

                    switch exercise.exerciseType {
                    case .done:
                        return record.count > 0
                    case .reps, .timed:
                        return record.isCompleted(goal: exercise.goal)
                    }
                }.count
            }

            // Fetch meals and check eating window
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            let mealDescriptor = FetchDescriptor<Meal>(
                predicate: #Predicate { $0.timestamp >= today && $0.timestamp < dayEnd }
            )
            let meals = try context.fetch(mealDescriptor)
            hasMealOutsideWindow = meals.contains { $0.isOutsideEatingWindow }
        } catch {
            print("Widget fetch error: \(error)")
        }

        return GenkiDoWidgetEntry(
            date: .now,
            completedExercises: completedCount,
            totalExercises: totalCount,
            hasMealAfterCutoff: hasMealOutsideWindow
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

            Text("Exercises")
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

                Text(isComplete ? "Complete!" : "Keep going!")
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
                    Text("Fasting")
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
        .description("Daily fitness and fasting status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    GenkiDoWidget()
} timeline: {
    GenkiDoWidgetEntry(date: .now, completedExercises: 3, totalExercises: 5, hasMealAfterCutoff: false)
    GenkiDoWidgetEntry(date: .now, completedExercises: 5, totalExercises: 5, hasMealAfterCutoff: false)
}

#Preview(as: .systemMedium) {
    GenkiDoWidget()
} timeline: {
    GenkiDoWidgetEntry(date: .now, completedExercises: 3, totalExercises: 5, hasMealAfterCutoff: true)
}
