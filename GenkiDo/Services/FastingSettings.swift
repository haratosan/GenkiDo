import Foundation

/// Manages eating window times per weekday
/// Weekday indices: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
enum FastingSettings {
    private static let startStorageKey = "fastingStartHours"
    private static let endStorageKey = "fastingCutoffHours"
    private static let appGroup = "group.ch.budo-team.GenkiDo"

    /// Default start hour (08:00)
    static let defaultStartHour = 8
    /// Default end/cutoff hour (18:00)
    static let defaultEndHour = 18

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    // MARK: - Initialization

    /// Initialize defaults if not set
    static func initializeIfNeeded() {
        if defaults.object(forKey: endStorageKey) == nil {
            let defaultEndHours: [Int: Int] = [
                1: defaultEndHour, 2: defaultEndHour, 3: defaultEndHour,
                4: defaultEndHour, 5: defaultEndHour, 6: defaultEndHour, 7: defaultEndHour
            ]
            saveEndHours(defaultEndHours)
        }
        if defaults.object(forKey: startStorageKey) == nil {
            let defaultStartHours: [Int: Int] = [
                1: defaultStartHour, 2: defaultStartHour, 3: defaultStartHour,
                4: defaultStartHour, 5: defaultStartHour, 6: defaultStartHour, 7: defaultStartHour
            ]
            saveStartHours(defaultStartHours)
        }
    }

    // MARK: - Start Hour (earliest eating time)

    /// Get start hour for a specific weekday (1-7)
    static func startHour(for weekday: Int) -> Int {
        let hours = loadStartHours()
        return hours[weekday] ?? defaultStartHour
    }

    /// Get start hour for a specific date
    static func startHour(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return startHour(for: weekday)
    }

    /// Set start hour for a specific weekday (1-7)
    static func setStartHour(_ hour: Int, for weekday: Int) {
        var hours = loadStartHours()
        hours[weekday] = hour
        saveStartHours(hours)
    }

    /// Get all start hours as dictionary
    static func allStartHours() -> [Int: Int] {
        initializeIfNeeded()
        return loadStartHours()
    }

    // MARK: - End Hour (latest eating time / cutoff)

    /// Get end/cutoff hour for a specific weekday (1-7)
    static func endHour(for weekday: Int) -> Int {
        let hours = loadEndHours()
        return hours[weekday] ?? defaultEndHour
    }

    /// Get end/cutoff hour for a specific date
    static func endHour(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return endHour(for: weekday)
    }

    /// Set end/cutoff hour for a specific weekday (1-7)
    static func setEndHour(_ hour: Int, for weekday: Int) {
        var hours = loadEndHours()
        hours[weekday] = hour
        saveEndHours(hours)
    }

    /// Get all end/cutoff hours as dictionary
    static func allEndHours() -> [Int: Int] {
        initializeIfNeeded()
        return loadEndHours()
    }

    // MARK: - Fasting Check

    /// Check if a given date/time is outside the eating window
    static func isOutsideEatingWindow(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        let start = startHour(for: date)
        let end = endHour(for: date)
        return hour < start || hour >= end
    }

    /// Check if meal is before the start time
    static func isBeforeStart(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        let start = startHour(for: date)
        return hour < start
    }

    /// Check if meal is after the end time
    static func isAfterEnd(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        let end = endHour(for: date)
        return hour >= end
    }

    /// Check if current time is outside eating window (fasting period)
    static var isFastingTimeNow: Bool {
        isOutsideEatingWindow(.now)
    }

    // MARK: - Legacy compatibility

    /// Alias for endHour (backwards compatibility)
    static func cutoffHour(for weekday: Int) -> Int {
        endHour(for: weekday)
    }

    /// Alias for endHour (backwards compatibility)
    static func cutoffHour(for date: Date) -> Int {
        endHour(for: date)
    }

    // MARK: - Private Storage

    private static func loadStartHours() -> [Int: Int] {
        guard let data = defaults.data(forKey: startStorageKey),
              let hours = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            return [:]
        }
        return hours
    }

    private static func saveStartHours(_ hours: [Int: Int]) {
        if let data = try? JSONEncoder().encode(hours) {
            defaults.set(data, forKey: startStorageKey)
        }
    }

    private static func loadEndHours() -> [Int: Int] {
        guard let data = defaults.data(forKey: endStorageKey),
              let hours = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            return [:]
        }
        return hours
    }

    private static func saveEndHours(_ hours: [Int: Int]) {
        if let data = try? JSONEncoder().encode(hours) {
            defaults.set(data, forKey: endStorageKey)
        }
    }

    /// Weekday names starting from Monday
    static let weekdayNames: [(weekday: Int, name: String)] = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
}
