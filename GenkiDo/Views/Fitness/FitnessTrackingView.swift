import SwiftUI
import SwiftData

struct FitnessTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseRecords: [ExerciseRecord]
    @State private var activeTimerExercise: Exercise?
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Exercise.allCases) { exercise in
                        if exercise.isTimed {
                            TimedExerciseRowView(
                                exercise: exercise,
                                isCompleted: isCompleted(exercise),
                                isActive: activeTimerExercise == exercise,
                                timeRemaining: activeTimerExercise == exercise ? timeRemaining : exercise.timerDuration,
                                onStart: { startTimer(for: exercise) },
                                onUndo: { undoExercise(exercise) }
                            )
                        } else {
                            ExerciseRowView(
                                exercise: exercise,
                                isCompleted: isCompleted(exercise),
                                onComplete: { completeExercise(exercise) },
                                onUndo: { undoExercise(exercise) }
                            )
                        }
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

        // Check if all exercises are now completed and cancel today's reminder
        checkAndCancelReminder()
    }

    private func checkAndCancelReminder() {
        let completedCount = Exercise.allCases.filter { isCompleted($0) }.count + 1 // +1 for the one just completed
        let allCompleted = completedCount >= Exercise.allCases.count
        NotificationService.shared.cancelTodayReminderIfNeeded(allExercisesCompleted: allCompleted)
    }

    private func undoExercise(_ exercise: Exercise) {
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = exerciseRecords.first(where: {
            $0.exerciseType == exercise.rawValue && $0.date == today
        }) {
            existing.count = 0
        }

        // Reschedule today's reminder if before notification time
        Task {
            await NotificationService.shared.rescheduleIfNeeded()
        }
    }

    private func startTimer(for exercise: Exercise) {
        UIApplication.shared.isIdleTimerDisabled = true
        activeTimerExercise = exercise
        timeRemaining = exercise.timerDuration

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                completeExercise(exercise)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        activeTimerExercise = nil
        UIApplication.shared.isIdleTimerDisabled = false
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

struct TimedExerciseRowView: View {
    let exercise: Exercise
    let isCompleted: Bool
    let isActive: Bool
    let timeRemaining: Int
    let onStart: () -> Void
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
            } else if isActive {
                Text("\(timeRemaining)s")
                    .font(.title)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                    .frame(width: 100)
            } else {
                Button {
                    onStart()
                } label: {
                    Text("Start")
                        .fontWeight(.medium)
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
        .background(isActive ? Color.orange.opacity(0.1) : Color.clear)
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
                    if exercise.isTimed {
                        Text("\(totalCount(for: exercise) / Exercise.dailyGoal) Min")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    } else {
                        Text("\(totalCount(for: exercise))")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
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
