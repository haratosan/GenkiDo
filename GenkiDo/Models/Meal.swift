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

    /// Returns true if meal was logged outside the eating window
    var isOutsideEatingWindow: Bool {
        FastingSettings.isOutsideEatingWindow(timestamp)
    }

    /// Returns true if meal was logged before the start time
    var isBeforeStartTime: Bool {
        FastingSettings.isBeforeStart(timestamp)
    }

    /// Returns true if meal was logged after the end time
    var isAfterEndTime: Bool {
        FastingSettings.isAfterEnd(timestamp)
    }

    /// Returns the eating window start hour for the day of this meal
    var eatingWindowStart: Int {
        FastingSettings.startHour(for: timestamp)
    }

    /// Returns the eating window end hour for the day of this meal
    var eatingWindowEnd: Int {
        FastingSettings.endHour(for: timestamp)
    }

    // MARK: - Legacy compatibility

    /// Alias for isOutsideEatingWindow (backwards compatibility)
    var isAfterFastingCutoff: Bool {
        isOutsideEatingWindow
    }

    /// Alias for eatingWindowEnd (backwards compatibility)
    var fastingCutoffHour: Int {
        eatingWindowEnd
    }
}
