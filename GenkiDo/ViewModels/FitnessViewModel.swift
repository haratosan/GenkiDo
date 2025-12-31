import Foundation
import Observation

@Observable
final class FitnessViewModel {
    var selectedDate: Date = .now

    var startOfSelectedDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
