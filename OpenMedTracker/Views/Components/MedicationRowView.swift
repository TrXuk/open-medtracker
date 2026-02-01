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
                    .sorted(by: { getMinutesFromMidnight($0.timeOfDay) < getMinutesFromMidnight($1.timeOfDay) })
                    .first {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatTime(nextSchedule.timeOfDay))
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

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func getMinutesFromMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
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
