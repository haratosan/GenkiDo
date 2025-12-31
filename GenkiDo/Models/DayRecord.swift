import Foundation

struct DayRecord {
    let date: Date
    let exerciseRecords: [ExerciseRecord]
    let meals: [Meal]

    var allExercisesCompleted: Bool {
        let completedTypes = Set(exerciseRecords.filter { $0.isCompleted }.map { $0.exerciseType })
        let allTypes = Set(Exercise.allCases.map { $0.rawValue })
        return completedTypes == allTypes
    }

    var hasMealAfterFastingCutoff: Bool {
        meals.contains { $0.isAfterFastingCutoff }
    }

    /// Day is successful when all exercises are done and no meal after 18:00
    var isDayComplete: Bool {
        allExercisesCompleted && !hasMealAfterFastingCutoff
    }

    var totalExerciseProgress: Double {
        guard !exerciseRecords.isEmpty else { return 0 }
        let totalProgress = exerciseRecords.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(Exercise.allCases.count)
    }
}
