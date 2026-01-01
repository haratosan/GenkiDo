import Foundation
import SwiftData

@MainActor
enum ExerciseService {
    /// Initialize default exercises if none exist
    static func initializeDefaultsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CustomExercise>()

        do {
            let existingExercises = try context.fetch(descriptor)
            if existingExercises.isEmpty {
                createDefaultExercises(context: context)
            }
        } catch {
            print("Error checking exercises: \(error)")
        }
    }

    private static func createDefaultExercises(context: ModelContext) {
        let defaults = CustomExercise.createDefaultExercises()
        for exercise in defaults {
            context.insert(exercise)
        }
        try? context.save()
    }

    /// Get all active exercises sorted by sortOrder
    static func activeExercises(context: ModelContext) -> [CustomExercise] {
        var descriptor = FetchDescriptor<CustomExercise>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get all exercises (including inactive) sorted by sortOrder
    static func allExercises(context: ModelContext) -> [CustomExercise] {
        var descriptor = FetchDescriptor<CustomExercise>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Find exercise by UUID string
    static func findExercise(byId id: String, context: ModelContext) -> CustomExercise? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        let descriptor = FetchDescriptor<CustomExercise>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }

    /// Update sort orders after drag and drop
    static func updateSortOrders(_ exercises: [CustomExercise], context: ModelContext) {
        for (index, exercise) in exercises.enumerated() {
            exercise.sortOrder = index
        }
        try? context.save()
    }

    /// Create a new exercise
    static func createExercise(name: String, type: ExerciseType, goal: Int, context: ModelContext) -> CustomExercise {
        let allExercises = allExercises(context: context)
        let maxSortOrder = allExercises.map(\.sortOrder).max() ?? -1

        let exercise = CustomExercise(
            name: name,
            type: type,
            goal: goal,
            sortOrder: maxSortOrder + 1
        )
        context.insert(exercise)
        try? context.save()
        return exercise
    }

    /// Deactivate an exercise (keeps data, hides from active list)
    static func deactivateExercise(_ exercise: CustomExercise, context: ModelContext) {
        exercise.isActive = false
        try? context.save()
    }

    /// Reactivate an exercise
    static func activateExercise(_ exercise: CustomExercise, context: ModelContext) {
        exercise.isActive = true
        try? context.save()
    }
}
