import SwiftUI

struct EatingWindowSettingsView: View {
    @State private var startTimes: [Int: Date] = [:]
    @State private var endTimes: [Int: Date] = [:]

    var body: some View {
        List {
            Section {
                ForEach(FastingSettings.weekdayNames, id: \.weekday) { item in
                    EatingWindowRow(
                        weekday: item.weekday,
                        name: item.name,
                        startTime: binding(for: item.weekday, in: $startTimes, isStart: true),
                        endTime: binding(for: item.weekday, in: $endTimes, isStart: false)
                    )
                }
            } footer: {
                Text("Meals outside this time window are considered a fasting violation.")
            }
        }
        .navigationTitle("Eating Window")
        .onAppear {
            loadEatingWindows()
        }
    }

    private func loadEatingWindows() {
        for item in FastingSettings.weekdayNames {
            let startHour = FastingSettings.startHour(for: item.weekday)
            let endHour = FastingSettings.endHour(for: item.weekday)
            startTimes[item.weekday] = dateFrom(hour: startHour)
            endTimes[item.weekday] = dateFrom(hour: endHour)
        }
    }

    private func dateFrom(hour: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }

    private func binding(for weekday: Int, in dict: Binding<[Int: Date]>, isStart: Bool) -> Binding<Date> {
        Binding(
            get: {
                let defaultHour = isStart ? FastingSettings.defaultStartHour : FastingSettings.defaultEndHour
                return dict.wrappedValue[weekday] ?? dateFrom(hour: defaultHour)
            },
            set: { newValue in
                dict.wrappedValue[weekday] = newValue
                let hour = Calendar.current.component(.hour, from: newValue)
                if isStart {
                    FastingSettings.setStartHour(hour, for: weekday)
                } else {
                    FastingSettings.setEndHour(hour, for: weekday)
                }
            }
        )
    }
}

struct EatingWindowRow: View {
    let weekday: Int
    let name: String
    @Binding var startTime: Date
    @Binding var endTime: Date

    private var shortName: String {
        String(name.prefix(3))
    }

    var body: some View {
        HStack {
            Text(shortName)
                .frame(width: 50, alignment: .leading)

            Spacer()

            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(width: 80)

            Text("-")
                .foregroundStyle(.secondary)

            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(width: 80)
        }
    }
}

#Preview {
    NavigationStack {
        EatingWindowSettingsView()
    }
}
