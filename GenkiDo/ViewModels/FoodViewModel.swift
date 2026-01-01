import Foundation
import Observation

@Observable
final class FoodViewModel {
    var selectedDate: Date = .now

    var isFastingTime: Bool {
        FastingSettings.isFastingTimeNow
    }

    var currentFastingCutoffHour: Int {
        FastingSettings.cutoffHour(for: .now)
    }

    var startOfSelectedDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
