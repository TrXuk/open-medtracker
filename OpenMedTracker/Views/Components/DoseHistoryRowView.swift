import SwiftUI

/// A row view displaying dose history information
struct DoseHistoryRowView: View {
    let doseHistory: DoseHistory

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status icon
            StatusBadgeView(status: doseHistory.status ?? "pending")
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                // Medication name
                Text(doseHistory.medicationName ?? "Unknown")
                    .font(.headline)

                // Scheduled time
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(formatDate(doseHistory.scheduledTime))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)

                // Actual time if taken
                if doseHistory.status == "taken", let actualTime = doseHistory.actualTime {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                        Text("Taken: \(formatDate(actualTime))")
                            .font(.caption)

                        // Show time difference
                        if let diff = doseHistory.timeDifferenceMinutes {
                            if diff > 0 {
                                Text("(\(Int(diff))m late)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if diff < 0 {
                                Text("(\(Int(abs(diff)))m early)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                }

                // Timezone info
                Text("Timezone: \(doseHistory.timezoneIdentifier)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Notes
                if let notes = doseHistory.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    List {
        DoseHistoryRowView(doseHistory: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.name = "Lisinopril"

            let schedule = Schedule(context: context)
            schedule.medication = medication

            let dose = DoseHistory(context: context)
            dose.id = UUID()
            dose.schedule = schedule
            dose.status = "taken"
            dose.scheduledTime = Date()
            dose.actualTime = Date().addingTimeInterval(300) // 5 minutes later
            dose.timezoneIdentifier = "America/New_York"
            return dose
        }())
    }
}
