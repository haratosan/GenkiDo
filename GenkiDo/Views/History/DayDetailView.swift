import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseRecords: [ExerciseRecord]
    @Query private var meals: [Meal]
    @Query(filter: #Predicate<CustomExercise> { $0.isActive }, sort: \CustomExercise.sortOrder)
    private var activeExercises: [CustomExercise]

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
        DayRecord(date: date, exerciseRecords: exerciseRecords, meals: meals, activeExercises: activeExercises)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatusHeaderView(dayRecord: dayRecord)
                FitnessSectionView(exerciseRecords: exerciseRecords, exercises: activeExercises)
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
                Text(dayRecord.isDayComplete ? "Day completed!" : "Day incomplete")
                    .font(.title2)
                    .fontWeight(.semibold)

                if !dayRecord.allExercisesCompleted {
                    Text("Exercises: \(dayRecord.completedExerciseCount)/\(dayRecord.totalExerciseCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if dayRecord.hasMealOutsideEatingWindow {
                    Text("Meal outside \(dayRecord.eatingWindowStart):00-\(dayRecord.eatingWindowEnd):00")
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
    let exercises: [CustomExercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fitness")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    let isCompleted = isExerciseCompleted(exercise)

                    HStack {
                        Text(exercise.name)

                        Spacer()

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

    private func isExerciseCompleted(_ exercise: CustomExercise) -> Bool {
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
            Text("Meals (\(meals.count))")
                .font(.headline)

            if meals.isEmpty {
                Text("No meals logged")
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

                if meal.isOutsideEatingWindow {
                    HStack(spacing: 2) {
                        Image(systemName: "moon.fill")
                        if meal.isBeforeStartTime {
                            Text("<\(meal.eatingWindowStart):00")
                        } else {
                            Text(">\(meal.eatingWindowEnd):00")
                        }
                    }
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
    .modelContainer(for: [ExerciseRecord.self, Meal.self, CustomExercise.self], inMemory: true)
}
