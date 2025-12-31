import Foundation
import Observation

@Observable
final class FoodViewModel {
    var selectedDate: Date = .now

    static let fastingCutoffHour = 18

    var isFastingTime: Bool {
        Calendar.current.component(.hour, from: .now) >= Self.fastingCutoffHour
    }

    var startOfSelectedDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
