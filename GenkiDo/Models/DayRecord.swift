import Foundation

struct DayRecord {
    let date: Date
    let exerciseRecords: [ExerciseRecord]
    let meals: [Meal]
    let activeExercises: [CustomExercise]

    init(date: Date, exerciseRecords: [ExerciseRecord], meals: [Meal], activeExercises: [CustomExercise]) {
        self.date = date
        self.exerciseRecords = exerciseRecords
        self.meals = meals
        self.activeExercises = activeExercises
    }

    var allExercisesCompleted: Bool {
        activeExercises.allSatisfy { isExerciseCompleted($0) }
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

    var completedExerciseCount: Int {
        activeExercises.filter { isExerciseCompleted($0) }.count
    }

    var totalExerciseCount: Int {
        activeExercises.count
    }

    var hasMealOutsideEatingWindow: Bool {
        meals.contains { $0.isOutsideEatingWindow }
    }

    /// Day is successful when all exercises are done and no meal outside eating window
    var isDayComplete: Bool {
        allExercisesCompleted && !hasMealOutsideEatingWindow
    }

    var totalExerciseProgress: Double {
        guard !activeExercises.isEmpty else { return 0 }
        return Double(completedExerciseCount) / Double(activeExercises.count)
    }

    // MARK: - Eating Window Info

    var eatingWindowStart: Int {
        FastingSettings.startHour(for: date)
    }

    var eatingWindowEnd: Int {
        FastingSettings.endHour(for: date)
    }
}
