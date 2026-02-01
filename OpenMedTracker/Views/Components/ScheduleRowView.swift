import SwiftUI

/// A row view displaying schedule information
struct ScheduleRowView: View {
    let schedule: Schedule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let medication = schedule.medication {
                    Text(medication.name ?? "Unknown Medication")
                        .font(.headline)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatTime())
                            .font(.subheadline)
                    }

                    if let frequency = schedule.frequency {
                        Text(frequency.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(.secondary)

                if schedule.daysOfWeek != 127 { // Not every day
                    Text(formatDaysOfWeek())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !schedule.isEnabled {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .opacity(schedule.isEnabled ? 1.0 : 0.5)
    }

    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: schedule.timeOfDay)
    }

    private func formatDaysOfWeek() -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var selectedDays: [String] = []
        let daysValue = Int(schedule.daysOfWeek)

        for (index, dayName) in days.enumerated() {
            if (daysValue & (1 << index)) != 0 {
                selectedDays.append(dayName)
            }
        }

        return selectedDays.joined(separator: ", ")
    }
}

#Preview {
    List {
        ScheduleRowView(schedule: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.name = "Aspirin"

            let schedule = Schedule(context: context)
            schedule.id = UUID()
            schedule.medication = medication

            // Set time to 9:00 AM
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            schedule.timeOfDay = Calendar.current.date(from: components) ?? Date()

            schedule.frequency = "daily"
            schedule.daysOfWeek = 127 // Every day
            schedule.isEnabled = true
            return schedule
        }())
    }
}
