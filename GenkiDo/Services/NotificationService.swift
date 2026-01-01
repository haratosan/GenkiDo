import Foundation
import UserNotifications
import SwiftData

@MainActor
final class NotificationService: Sendable {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyReminder(at hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-exercise-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "GenkiDo"
        content.body = "Zeit für deine täglichen Übungen!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-exercise-reminder", content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-exercise-reminder"])
    }

    /// Cancel today's reminder if all exercises are completed
    func cancelTodayReminderIfNeeded(allExercisesCompleted: Bool) {
        guard allExercisesCompleted else { return }

        let center = UNUserNotificationCenter.current()

        // Remove today's pending notification
        center.getPendingNotificationRequests { requests in
            let hasReminder = requests.contains { $0.identifier == "daily-exercise-reminder" }
            if hasReminder {
                // Cancel and reschedule for tomorrow only
                center.removePendingNotificationRequests(withIdentifiers: ["daily-exercise-reminder"])

                Task { @MainActor in
                    await self.scheduleForTomorrow()
                }
            }
        }
    }

    private func scheduleForTomorrow() async {
        let reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        guard reminderEnabled else { return }

        let hour = UserDefaults.standard.integer(forKey: "reminderHour")
        let minute = UserDefaults.standard.integer(forKey: "reminderMinute")

        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "GenkiDo"
        content.body = "Zeit für deine täglichen Übungen!"
        content.sound = .default

        // Schedule for tomorrow at the set time
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "daily-exercise-reminder", content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule tomorrow notification: \(error)")
        }
    }

    /// Reschedule reminder when app becomes active (for next occurrence)
    func rescheduleIfNeeded() async {
        let reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        guard reminderEnabled else { return }

        let hour = UserDefaults.standard.integer(forKey: "reminderHour")
        let minute = UserDefaults.standard.integer(forKey: "reminderMinute")

        await scheduleDailyReminder(at: hour, minute: minute)
    }
}
