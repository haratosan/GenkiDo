import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseRecord.date, order: .reverse) private var exerciseRecords: [ExerciseRecord]
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]

    private var last30Days: [Date] {
        (0..<30).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Calendar.current.startOfDay(for: .now))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(last30Days, id: \.self) { date in
                    NavigationLink {
                        DayDetailView(date: date)
                    } label: {
                        DayRowView(
                            date: date,
                            dayRecord: dayRecord(for: date)
                        )
                    }
                }
            }
            .navigationTitle("Verlauf")
        }
    }

    private func dayRecord(for date: Date) -> DayRecord {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!

        let dayExercises = exerciseRecords.filter { $0.date == dayStart }
        let dayMeals = meals.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }

        return DayRecord(date: date, exerciseRecords: dayExercises, meals: dayMeals)
    }
}

struct DayRowView: View {
    let date: Date
    let dayRecord: DayRecord

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var statusColor: Color {
        if isToday {
            return .blue
        }
        return dayRecord.isDayComplete ? .green : .red
    }

    private var statusIcon: String {
        if isToday {
            return "circle.dotted"
        }
        return dayRecord.isDayComplete ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(date, format: .dateTime.weekday(.wide).day().month())
                    .font(.headline)

                HStack(spacing: 16) {
                    Label("\(completedExerciseCount)/4", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(dayRecord.meals.count)", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if dayRecord.hasMealAfterFastingCutoff {
                        Label("Nach 18:00", systemImage: "moon.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            if !dayRecord.meals.isEmpty {
                MealThumbnailStack(meals: dayRecord.meals)
            }
        }
        .padding(.vertical, 4)
    }

    private var completedExerciseCount: Int {
        dayRecord.exerciseRecords.filter { $0.isCompleted }.count
    }
}

struct MealThumbnailStack: View {
    let meals: [Meal]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(meals.prefix(3), id: \.timestamp) { meal in
                if let data = meal.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.background, lineWidth: 2))
                }
            }
            if meals.count > 3 {
                Text("+\(meals.count - 3)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [ExerciseRecord.self, Meal.self], inMemory: true)
}
