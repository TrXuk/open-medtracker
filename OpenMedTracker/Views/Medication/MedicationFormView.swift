import SwiftUI
import CoreData

/// Form view for adding or editing a medication
struct MedicationFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case add
        case edit(Medication)

        var title: String {
            switch self {
            case .add: return "Add Medication"
            case .edit: return "Edit Medication"
            }
        }

        var saveButtonTitle: String {
            switch self {
            case .add: return "Add"
            case .edit: return "Save"
            }
        }
    }

    let mode: Mode

    // Form fields
    @State private var name: String = ""
    @State private var dosageAmount: String = ""
    @State private var dosageUnit: String = "mg"
    @State private var instructions: String = ""
    @State private var prescribedBy: String = ""
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    // Validation and state
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    // Common dosage units
    private let dosageUnits = ["mg", "g", "mcg", "mL", "tablets", "capsules", "drops", "puffs", "units"]

    init(mode: Mode) {
        self.mode = mode

        // Pre-populate fields if editing
        if case .edit(let medication) = mode {
            _name = State(initialValue: medication.name ?? "")
            _dosageAmount = State(initialValue: medication.dosageAmount != nil ? String(medication.dosageAmount!) : "")
            _dosageUnit = State(initialValue: medication.dosageUnit ?? "mg")
            _instructions = State(initialValue: medication.instructions ?? "")
            _prescribedBy = State(initialValue: medication.prescribedBy ?? "")
            _startDate = State(initialValue: medication.startDate ?? Date())
            _hasEndDate = State(initialValue: medication.endDate != nil)
            _endDate = State(initialValue: medication.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Medication Name", text: $name)
                        .autocapitalization(.words)

                    HStack {
                        TextField("Dosage Amount", text: $dosageAmount)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(dosageUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField("Prescribed By (Optional)", text: $prescribedBy)
                        .autocapitalization(.words)
                }

                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }

                Section("Schedule") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Set End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
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
                        saveMedication()
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosageAmount.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(dosageAmount) != nil
    }

    private func saveMedication() {
        guard isFormValid else {
            validationMessage = "Please fill in all required fields with valid values"
            showingValidationError = true
            return
        }

        guard let amount = Double(dosageAmount) else {
            validationMessage = "Please enter a valid dosage amount"
            showingValidationError = true
            return
        }

        if hasEndDate && endDate <= startDate {
            validationMessage = "End date must be after start date"
            showingValidationError = true
            return
        }

        isSaving = true

        let medicationService = MedicationService()

        do {
            switch mode {
            case .add:
                try medicationService.create(
                    name: name.trimmingCharacters(in: .whitespaces),
                    dosageAmount: amount,
                    dosageUnit: dosageUnit,
                    instructions: instructions.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instructions,
                    prescribedBy: prescribedBy.trimmingCharacters(in: .whitespaces).isEmpty ? nil : prescribedBy,
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil,
                    in: viewContext
                )

            case .edit(let medication):
                try medicationService.update(
                    medication,
                    name: name.trimmingCharacters(in: .whitespaces),
                    dosageAmount: amount,
                    dosageUnit: dosageUnit,
                    instructions: instructions.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instructions,
                    prescribedBy: prescribedBy.trimmingCharacters(in: .whitespaces).isEmpty ? nil : prescribedBy,
                    in: viewContext
                )

                // Update dates separately if needed
                medication.startDate = startDate
                medication.endDate = hasEndDate ? endDate : nil
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
    MedicationFormView(mode: .add)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Edit Mode") {
    MedicationFormView(mode: .edit({
        let context = PersistenceController.preview.container.viewContext
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Aspirin"
        medication.dosageAmount = 500
        medication.dosageUnit = "mg"
        medication.instructions = "Take with food"
        medication.prescribedBy = "Dr. Johnson"
        medication.startDate = Date()
        return medication
    }()))
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
