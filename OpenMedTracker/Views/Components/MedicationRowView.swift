import SwiftUI

/// A row view displaying medication information in a list
struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.name ?? "Unknown Medication")
                    .font(.headline)

                Spacer()

                if !medication.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            HStack {
                if let dosageAmount = medication.dosageAmount,
                   let dosageUnit = medication.dosageUnit {
                    Text("\(dosageAmount, specifier: "%.1f") \(dosageUnit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let schedules = medication.schedules as? Set<Schedule>,
                   let nextSchedule = schedules
                    .filter({ $0.isEnabled })
                    .sorted(by: { ($0.timeHour ?? 0) * 60 + ($0.timeMinute ?? 0) < ($1.timeHour ?? 0) * 60 + ($1.timeMinute ?? 0) })
                    .first {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatTime(hour: Int(schedules.first?.timeHour ?? 0), minute: Int(schedules.first?.timeMinute ?? 0)))
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }

            if let instructions = medication.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
}

#Preview {
    List {
        MedicationRowView(medication: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.id = UUID()
            medication.name = "Lisinopril"
            medication.dosageAmount = 10.0
            medication.dosageUnit = "mg"
            medication.instructions = "Take once daily with food"
            medication.isActive = true
            return medication
        }())
    }
}
