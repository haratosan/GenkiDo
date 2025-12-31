import Foundation

enum Exercise: String, CaseIterable, Codable, Identifiable {
    case pushUps = "pushUps"
    case slDeadlifts = "slDeadlifts"
    case towelRows = "towelRows"
    case squats = "squats"
    case planks = "planks"

    var id: String { rawValue }

    static let dailyGoal: Int = 50

    var displayName: String {
        switch self {
        case .pushUps: return "Pushups"
        case .slDeadlifts: return "SL Deadlifts"
        case .squats: return "Squats"
        case .towelRows: return "Towel Rows"
        case .planks: return "Planks"
        }
    }

    var isTimed: Bool {
        self == .planks
    }

    var timerDuration: Int {
        switch self {
        case .planks: return 60
        default: return 0
        }
    }
}
