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
                Section {
                    StreakView(currentStreak: currentStreak, longestStreak: longestStreak)
                }

                Section {
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
            }
            .navigationTitle("Verlauf")
        }
    }

    private var currentStreak: Int {
        var streak = 0
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now))!

        for offset in 0..<365 {
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: yesterday) else { break }
            let record = dayRecord(for: date)
            if record.isDayComplete {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var longestStreak: Int {
        var longest = 0
        var current = 0

        for offset in 1...365 {
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Calendar.current.startOfDay(for: .now)) else { break }
            let record = dayRecord(for: date)
            if record.isDayComplete {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
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

                HStack(spacing: 12) {
                    Label("\(completedExerciseCount)/\(Exercise.allCases.count)", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(dayRecord.meals.count)", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if dayRecord.hasMealAfterFastingCutoff {
                        Image(systemName: "moon.fill")
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

struct StreakView: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(currentStreak > 0 ? .green : .secondary)
                Text("Aktuelle Serie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 4) {
                Text("\(longestStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.orange)
                Text("Längste Serie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
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
