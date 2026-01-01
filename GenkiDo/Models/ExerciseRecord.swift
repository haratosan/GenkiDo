import Foundation
import SwiftData

@Model
final class ExerciseRecord {
    var exerciseType: String = ""
    var count: Int = 0
    var date: Date = Date.now

    init(customExercise: CustomExercise, count: Int = 0, date: Date = .now) {
        self.exerciseType = customExercise.id.uuidString
        self.count = count
        self.date = Calendar.current.startOfDay(for: date)
    }

    /// Check if completed with given goal
    func isCompleted(goal: Int) -> Bool {
        count >= goal
    }

    /// Calculate progress with given goal
    func progress(goal: Int) -> Double {
        guard goal > 0 else { return count > 0 ? 1.0 : 0.0 }
        return min(Double(count) / Double(goal), 1.0)
    }
}
