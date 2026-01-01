import Foundation
import SwiftData

@Model
final class CustomExercise {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = ExerciseType.reps.rawValue
    var goal: Int = 50
    var sortOrder: Int = 0
    var isActive: Bool = true

    init(id: UUID = UUID(), name: String, type: ExerciseType, goal: Int = 50, sortOrder: Int = 0, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.goal = goal
        self.sortOrder = sortOrder
        self.isActive = isActive
    }

    var exerciseType: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .reps }
        set { typeRaw = newValue.rawValue }
    }
}

// MARK: - Default Exercises

extension CustomExercise {
    static func createDefaultExercises() -> [CustomExercise] {
        [
            CustomExercise(name: "Pushups", type: .reps, goal: 50, sortOrder: 0),
            CustomExercise(name: "SL Deadlifts", type: .reps, goal: 50, sortOrder: 1),
            CustomExercise(name: "Towel Rows", type: .reps, goal: 50, sortOrder: 2),
            CustomExercise(name: "Squats", type: .reps, goal: 50, sortOrder: 3),
            CustomExercise(name: "Planks", type: .timed, goal: 60, sortOrder: 4),
        ]
    }
}
