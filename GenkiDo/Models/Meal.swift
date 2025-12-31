import Foundation
import SwiftData

@Model
final class Meal {
    var timestamp: Date = Date.now
    @Attribute(.externalStorage) var photoData: Data?
    var aiAnalysis: String?

    init(timestamp: Date = .now, photoData: Data? = nil, aiAnalysis: String? = nil) {
        self.timestamp = timestamp
        self.photoData = photoData
        self.aiAnalysis = aiAnalysis
    }

    var date: Date {
        Calendar.current.startOfDay(for: timestamp)
    }

    /// Returns true if meal was logged after the fasting cutoff time (18:00)
    var isAfterFastingCutoff: Bool {
        let hour = Calendar.current.component(.hour, from: timestamp)
        return hour >= 18
    }
}
