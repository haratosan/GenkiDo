import Foundation
import SwiftData

@Model
final class ExerciseRecord {
    var exerciseType: String = Exercise.pushUps.rawValue
    var count: Int = 0
    var date: Date = Date.now

    init(exercise: Exercise, count: Int = 0, date: Date = .now) {
        self.exerciseType = exercise.rawValue
        self.count = count
        self.date = Calendar.current.startOfDay(for: date)
    }

    var exercise: Exercise {
        Exercise(rawValue: exerciseType) ?? .pushUps
    }

    var isCompleted: Bool {
        count >= Exercise.dailyGoal
    }

    var progress: Double {
        min(Double(count) / Double(Exercise.dailyGoal), 1.0)
    }
}
