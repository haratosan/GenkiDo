import SwiftUI
import SwiftData

struct FitnessTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseRecords: [ExerciseRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Exercise.allCases) { exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            isCompleted: isCompleted(exercise),
                            onComplete: { completeExercise(exercise) },
                            onUndo: { undoExercise(exercise) }
                        )
                    }

                    Divider()
                        .padding(.vertical, 8)

                    TotalStatsView(exerciseRecords: exerciseRecords)
                }
                .padding()
            }
            .navigationTitle("Fitness")
        }
    }

    private func isCompleted(_ exercise: Exercise) -> Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return exerciseRecords.first {
            $0.exerciseType == exercise.rawValue && $0.date == today
        }?.isCompleted ?? false
    }

    private func completeExercise(_ exercise: Exercise) {
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = exerciseRecords.first(where: {
            $0.exerciseType == exercise.rawValue && $0.date == today
        }) {
            existing.count = Exercise.dailyGoal
        } else {
            let newRecord = ExerciseRecord(exercise: exercise, count: Exercise.dailyGoal, date: .now)
            modelContext.insert(newRecord)
        }
    }

    private func undoExercise(_ exercise: Exercise) {
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = exerciseRecords.first(where: {
            $0.exerciseType == exercise.rawValue && $0.date == today
        }) {
            existing.count = 0
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let isCompleted: Bool
    let onComplete: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            }

            Text(exercise.displayName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(isCompleted ? .secondary : .primary)

            Spacer()

            if isCompleted {
                Button {
                    onUndo()
                } label: {
                    Text("Rückgängig")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            } else {
                Button {
                    onComplete()
                } label: {
                    Text("Erledigt")
                        .fontWeight(.medium)
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TotalStatsView: View {
    let exerciseRecords: [ExerciseRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gesamt seit Beginn")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(Exercise.allCases) { exercise in
                HStack {
                    Text(exercise.displayName)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(totalCount(for: exercise))")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func totalCount(for exercise: Exercise) -> Int {
        exerciseRecords
            .filter { $0.exerciseType == exercise.rawValue }
            .reduce(0) { $0 + $1.count }
    }
}

#Preview {
    FitnessTrackingView()
        .modelContainer(for: ExerciseRecord.self, inMemory: true)
}
