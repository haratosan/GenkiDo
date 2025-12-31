import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseRecords: [ExerciseRecord]
    @Query private var meals: [Meal]

    init(date: Date) {
        self.date = date
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!

        _exerciseRecords = Query(
            filter: #Predicate<ExerciseRecord> { record in
                record.date == dayStart
            },
            sort: \.exerciseType
        )

        _meals = Query(
            filter: #Predicate<Meal> { meal in
                meal.timestamp >= dayStart && meal.timestamp < dayEnd
            },
            sort: \.timestamp
        )
    }

    private var dayRecord: DayRecord {
        DayRecord(date: date, exerciseRecords: exerciseRecords, meals: meals)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Header
                StatusHeaderView(dayRecord: dayRecord)

                // Fitness Section
                FitnessSectionView(exerciseRecords: exerciseRecords)

                // Meals Section
                MealsSectionView(meals: meals)
            }
            .padding()
        }
        .navigationTitle(date.formatted(.dateTime.weekday(.wide).day().month()))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StatusHeaderView: View {
    let dayRecord: DayRecord

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: dayRecord.isDayComplete ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(dayRecord.isDayComplete ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text(dayRecord.isDayComplete ? "Tag erfolgreich!" : "Tag nicht abgeschlossen")
                    .font(.title2)
                    .fontWeight(.semibold)

                if !dayRecord.allExercisesCompleted {
                    Text("Übungen nicht vollständig")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if dayRecord.hasMealAfterFastingCutoff {
                    Text("Mahlzeit nach 18:00")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FitnessSectionView: View {
    let exerciseRecords: [ExerciseRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fitness")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Exercise.allCases) { exercise in
                    let record = exerciseRecords.first { $0.exerciseType == exercise.rawValue }
                    let count = record?.count ?? 0
                    let isCompleted = count >= Exercise.dailyGoal

                    HStack {
                        Image(systemName: exercise.systemImage)
                            .frame(width: 24)
                            .foregroundStyle(isCompleted ? .green : .primary)

                        Text(exercise.displayName)

                        Spacer()

                        Text("\(count)/\(Exercise.dailyGoal)")
                            .fontWeight(.medium)
                            .foregroundStyle(isCompleted ? .green : .secondary)

                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isCompleted ? .green : .secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

struct MealsSectionView: View {
    let meals: [Meal]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mahlzeiten (\(meals.count))")
                .font(.headline)

            if meals.isEmpty {
                Text("Keine Mahlzeiten erfasst")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(meals, id: \.timestamp) { meal in
                        MealCardView(meal: meal)
                    }
                }
            }
        }
    }
}

struct MealCardView: View {
    let meal: Meal

    var body: some View {
        VStack(spacing: 0) {
            if let data = meal.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.secondary.opacity(0.2))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            HStack {
                Text(meal.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                if meal.isAfterFastingCutoff {
                    Image(systemName: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(8)
            .background(.regularMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        DayDetailView(date: .now)
    }
    .modelContainer(for: [ExerciseRecord.self, Meal.self], inMemory: true)
}
