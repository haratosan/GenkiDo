import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var selectedTime = Date()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Tägliche Erinnerung", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            Task {
                                await handleReminderToggle(newValue)
                            }
                        }

                    if reminderEnabled {
                        DatePicker(
                            "Uhrzeit",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: selectedTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            reminderHour = components.hour ?? 8
                            reminderMinute = components.minute ?? 0
                            Task {
                                await scheduleReminder()
                            }
                        }
                    }
                } header: {
                    Text("Benachrichtigungen")
                } footer: {
                    if reminderEnabled {
                        Text("Du wirst täglich um \(reminderHour):\(String(format: "%02d", reminderMinute)) Uhr erinnert.")
                    }
                }

                if notificationStatus == .denied {
                    Section {
                        Button("Einstellungen öffnen") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } footer: {
                        Text("Benachrichtigungen sind deaktiviert. Aktiviere sie in den Einstellungen.")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                setupInitialTime()
                Task {
                    await checkNotificationStatus()
                }
            }
        }
    }

    private func setupInitialTime() {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        if let date = Calendar.current.date(from: components) {
            selectedTime = date
        }
    }

    private func checkNotificationStatus() async {
        notificationStatus = await NotificationService.shared.checkPermissionStatus()
    }

    private func handleReminderToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                await scheduleReminder()
            } else {
                reminderEnabled = false
            }
            await checkNotificationStatus()
        } else {
            NotificationService.shared.cancelDailyReminder()
        }
    }

    private func scheduleReminder() async {
        await NotificationService.shared.scheduleDailyReminder(at: reminderHour, minute: reminderMinute)
    }
}

#Preview {
    SettingsView()
}
