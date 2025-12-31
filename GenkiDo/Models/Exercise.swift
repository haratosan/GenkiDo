import Foundation

enum Exercise: String, CaseIterable, Codable, Identifiable {
    case pushUps = "pushUps"
    case shoulderRaises = "shoulderRaises"
    case squats = "squats"
    case crunches = "crunches"

    var id: String { rawValue }

    static let dailyGoal: Int = 50

    var displayName: String {
        switch self {
        case .pushUps: return "Liegestütze"
        case .shoulderRaises: return "Schulterheber"
        case .squats: return "Kniebeugen"
        case .crunches: return "Rumpfbeugen"
        }
    }

    var systemImage: String {
        switch self {
        case .pushUps: return "figure.strengthtraining.traditional"
        case .shoulderRaises: return "figure.arms.open"
        case .squats: return "figure.squats"
        case .crunches: return "figure.core.training"
        }
    }
}
