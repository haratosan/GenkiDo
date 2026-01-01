import SwiftUI
import SwiftData

struct FitnessTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseRecords: [ExerciseRecord]
    @Query(filter: #Predicate<CustomExercise> { $0.isActive }, sort: \CustomExercise.sortOrder)
    private var activeExercises: [CustomExercise]
    @State private var activeTimerExercise: CustomExercise?
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(activeExercises) { exercise in
                        switch exercise.exerciseType {
                        case .timed:
                            TimedExerciseRowView(
                                exercise: exercise,
                                isCompleted: isCompleted(exercise),
                                isActive: activeTimerExercise?.id == exercise.id,
                                timeRemaining: activeTimerExercise?.id == exercise.id ? timeRemaining : exercise.goal,
                                onStart: { startTimer(for: exercise) },
                                onUndo: { undoExercise(exercise) }
                            )
                        case .done:
                            DoneExerciseRowView(
                                exercise: exercise,
                                isCompleted: isCompleted(exercise),
                                onComplete: { completeExercise(exercise) },
                                onUndo: { undoExercise(exercise) }
                            )
                        case .reps:
                            RepsExerciseRowView(
                                exercise: exercise,
                                isCompleted: isCompleted(exercise),
                                onComplete: { completeExercise(exercise) },
                                onUndo: { undoExercise(exercise) }
                            )
                        }
                    }

                    if !activeExercises.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        TotalStatsView(
                            exerciseRecords: exerciseRecords,
                            exercises: activeExercises
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Fitness")
            .onAppear {
                ExerciseService.initializeDefaultsIfNeeded(context: modelContext)
            }
        }
    }

    private func isCompleted(_ exercise: CustomExercise) -> Bool {
        let today = Calendar.current.startOfDay(for: .now)
        guard let record = findRecord(for: exercise, on: today) else { return false }

        switch exercise.exerciseType {
        case .done:
            return record.count > 0
        case .reps, .timed:
            return record.isCompleted(goal: exercise.goal)
        }
    }

    private func findRecord(for exercise: CustomExercise, on date: Date) -> ExerciseRecord? {
        let exerciseId = exercise.id.uuidString
        return exerciseRecords.first { $0.exerciseType == exerciseId && $0.date == date }
    }

    private func completeExercise(_ exercise: CustomExercise) {
        let today = Calendar.current.startOfDay(for: .now)
        let exerciseId = exercise.id.uuidString

        if let existing = findRecord(for: exercise, on: today) {
            switch exercise.exerciseType {
            case .done:
                existing.count = 1
            case .reps, .timed:
                existing.count = exercise.goal
            }
        } else {
            let count = exercise.exerciseType == .done ? 1 : exercise.goal
            let newRecord = ExerciseRecord(customExercise: exercise, count: count, date: .now)
            modelContext.insert(newRecord)
        }

        checkAndCancelReminder()
    }

    private func checkAndCancelReminder() {
        let completedCount = activeExercises.filter { isCompleted($0) }.count + 1
        let allCompleted = completedCount >= activeExercises.count
        NotificationService.shared.cancelTodayReminderIfNeeded(allExercisesCompleted: allCompleted)
    }

    private func undoExercise(_ exercise: CustomExercise) {
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = findRecord(for: exercise, on: today) {
            existing.count = 0
        }

        Task {
            await NotificationService.shared.rescheduleIfNeeded()
        }
    }

    private func startTimer(for exercise: CustomExercise) {
        UIApplication.shared.isIdleTimerDisabled = true
        activeTimerExercise = exercise
        timeRemaining = exercise.goal

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

// MARK: - Reps Exercise Row

struct RepsExerciseRowView: View {
    let exercise: CustomExercise
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

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                Text("\(exercise.goal) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isCompleted {
                Button {
                    onUndo()
                } label: {
                    Text("Undo")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            } else {
                Button {
                    onComplete()
                } label: {
                    Text("Done")
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

// MARK: - Timed Exercise Row

struct TimedExerciseRowView: View {
    let exercise: CustomExercise
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

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                Text("\(exercise.goal) sec")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isCompleted {
                Button {
                    onUndo()
                } label: {
                    Text("Undo")
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

// MARK: - Done Exercise Row

struct DoneExerciseRowView: View {
    let exercise: CustomExercise
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

            Text(exercise.name)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(isCompleted ? .secondary : .primary)

            Spacer()

            if isCompleted {
                Button {
                    onUndo()
                } label: {
                    Text("Undo")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            } else {
                Button {
                    onComplete()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.medium)
                        .frame(width: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Total Stats View

struct TotalStatsView: View {
    let exerciseRecords: [ExerciseRecord]
    let exercises: [CustomExercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total since start")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(exercises) { exercise in
                HStack {
                    Text(exercise.name)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedTotal(for: exercise))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func totalCount(for exercise: CustomExercise) -> Int {
        let exerciseId = exercise.id.uuidString
        return exerciseRecords
            .filter { $0.exerciseType == exerciseId }
            .reduce(0) { $0 + $1.count }
    }

    private func formattedTotal(for exercise: CustomExercise) -> String {
        let total = totalCount(for: exercise)
        switch exercise.exerciseType {
        case .timed:
            let minutes = total / 60
            return "\(minutes) Min"
        case .done:
            return "\(total)x"
        case .reps:
            return "\(total)"
        }
    }
}

#Preview {
    FitnessTrackingView()
        .modelContainer(for: [ExerciseRecord.self, CustomExercise.self], inMemory: true)
}
