import SwiftUI
import CoreData

/// Form view for adding or editing a medication schedule
struct ScheduleFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case add
        case edit(Schedule)

        var title: String {
            switch self {
            case .add: return "Add Schedule"
            case .edit: return "Edit Schedule"
            }
        }

        var saveButtonTitle: String {
            switch self {
            case .add: return "Add"
            case .edit: return "Save"
            }
        }
    }

    let medication: Medication
    let mode: Mode

    // Form fields
    @State private var selectedTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var frequency: String = "daily"
    @State private var selectedDays: Set<Int> = Set(0...6) // All days selected by default
    @State private var isEnabled: Bool = true

    // Validation and state
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    // Frequency options
    private let frequencyOptions = ["daily", "weekly", "as needed"]

    // Days of the week
    private let daysOfWeek = [
        (0, "Sun"),
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri"),
        (6, "Sat")
    ]

    init(medication: Medication, mode: Mode) {
        self.medication = medication
        self.mode = mode

        // Pre-populate fields if editing
        if case .edit(let schedule) = mode {
            _selectedTime = State(initialValue: schedule.timeOfDay)
            _frequency = State(initialValue: schedule.frequency ?? "daily")
            _isEnabled = State(initialValue: schedule.isEnabled)

            // Convert daysOfWeek bitmask to Set
            let daysValue = Int(schedule.daysOfWeek)
            var days = Set<Int>()
            for i in 0...6 {
                if (daysValue & (1 << i)) != 0 {
                    days.insert(i)
                }
            }
            _selectedDays = State(initialValue: days)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Dose Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if frequency == "weekly" {
                    Section("Days of Week") {
                        ForEach(daysOfWeek, id: \.0) { day in
                            Toggle(day.1, isOn: Binding(
                                get: { selectedDays.contains(day.0) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDays.insert(day.0)
                                    } else {
                                        selectedDays.remove(day.0)
                                    }
                                }
                            ))
                        }
                    }
                } else if frequency == "daily" {
                    Section("Days of Week") {
                        Text("Every day")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Status") {
                    Toggle("Enabled", isOn: $isEnabled)
                }

                Section {
                    Text(scheduleDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(mode.saveButtonTitle) {
                        saveSchedule()
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var isFormValid: Bool {
        if frequency == "weekly" {
            return !selectedDays.isEmpty
        }
        return true
    }

    private var frequencyDescription: String {
        switch frequency {
        case "daily":
            return "every day"
        case "weekly":
            if selectedDays.count == 7 {
                return "every day"
            } else {
                let dayNames = selectedDays.sorted().map { daysOfWeek[$0].1 }
                return "on \(dayNames.joined(separator: ", "))"
            }
        case "as needed":
            return "as needed"
        default:
            return ""
        }
    }

    private var scheduleDescription: String {
        let medicationName = medication.name ?? "this medication"
        let time = formatTime(selectedTime)
        return "This schedule will create dose reminders for \(medicationName) at \(time) \(frequencyDescription)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveSchedule() {
        guard isFormValid else {
            validationMessage = "Please select at least one day for weekly schedules"
            showingValidationError = true
            return
        }

        isSaving = true

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0

        // Convert selectedDays to bitmask
        var daysOfWeekValue = 0
        if frequency == "daily" {
            daysOfWeekValue = 127 // All days (0b1111111)
        } else if frequency == "weekly" {
            for day in selectedDays {
                daysOfWeekValue |= (1 << day)
            }
        } else {
            daysOfWeekValue = 127 // As needed - all days
        }

        let scheduleService = ScheduleService()

        do {
            switch mode {
            case .add:
                try scheduleService.create(
                    for: medication,
                    hour: Int16(hour),
                    minute: Int16(minute),
                    frequency: frequency,
                    daysOfWeek: Int16(daysOfWeekValue),
                    in: viewContext
                )

            case .edit(let schedule):
                try scheduleService.updateTime(
                    schedule,
                    hour: Int16(hour),
                    minute: Int16(minute),
                    in: viewContext
                )

                try scheduleService.updateDays(
                    schedule,
                    daysOfWeek: Int16(daysOfWeekValue),
                    in: viewContext
                )

                schedule.frequency = frequency

                if isEnabled {
                    try scheduleService.enable(schedule, in: viewContext)
                } else {
                    try scheduleService.disable(schedule, in: viewContext)
                }

                try viewContext.save()
            }

            dismiss()
        } catch {
            validationMessage = error.localizedDescription
            showingValidationError = true
            isSaving = false
        }
    }
}

#Preview("Add Mode") {
    ScheduleFormView(
        medication: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.name = "Aspirin"
            return medication
        }(),
        mode: .add
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Edit Mode") {
    ScheduleFormView(
        medication: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.name = "Aspirin"
            return medication
        }(),
        mode: .edit({
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.name = "Aspirin"

            let schedule = Schedule(context: context)
            schedule.medication = medication

            // Set time to 9:00 AM
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            schedule.timeOfDay = Calendar.current.date(from: components) ?? Date()

            schedule.frequency = "daily"
            schedule.daysOfWeek = 127
            schedule.isEnabled = true
            return schedule
        }())
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
