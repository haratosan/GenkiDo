import Foundation

enum Exercise: String, CaseIterable, Codable, Identifiable {
    case pushUps = "pushUps"
    case slDeadlifts = "slDeadlifts"
    case squats = "squats"
    case towelRows = "towelRows"

    var id: String { rawValue }

    static let dailyGoal: Int = 50

    var displayName: String {
        switch self {
        case .pushUps: return "Pushups"
        case .slDeadlifts: return "SL Deadlifts"
        case .squats: return "Squats"
        case .towelRows: return "Towel Rows"
        }
    }
}
