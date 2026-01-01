import Foundation

enum ExerciseType: String, Codable, CaseIterable {
    case reps = "reps"      // Count repetitions
    case timed = "timed"    // Countdown timer
    case done = "done"      // Simply mark as done

    var displayName: String {
        switch self {
        case .reps: return "Reps"
        case .timed: return "Timed"
        case .done: return "Done"
        }
    }

    var unitName: String {
        switch self {
        case .reps: return "reps"
        case .timed: return "sec"
        case .done: return ""
        }
    }
}
