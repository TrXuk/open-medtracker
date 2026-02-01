import SwiftUI
import CoreData

/// Detail view for a single medication showing all information and schedules
struct MedicationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MedicationDetailViewModel
    @State private var showingEditMedication = false
    @State private var showingAddSchedule = false
    @State private var showingDeleteAlert = false

    init(medication: Medication) {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: MedicationDetailViewModel(
            medication: medication,
            context: context
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Medication details section
                medicationDetailsSection

                // Schedules section
                schedulesSection

                // Delete button
                deleteButton
            }
            .padding()
        }
        .navigationTitle(viewModel.medication.name ?? "Medication")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditMedication = true
                }
                .accessibilityHint("Edit medication details")
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .accessibilityHint("Close medication details")
            }
        }
        .sheet(isPresented: $showingEditMedication) {
            MedicationFormView(mode: .edit(viewModel.medication))
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    viewModel.loadSchedules()
                }
        }
        .sheet(isPresented: $showingAddSchedule) {
            ScheduleFormView(medication: viewModel.medication, mode: .add)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    viewModel.loadSchedules()
                }
        }
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete handled in parent view
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this medication? All schedules and dose history will be removed.")
        }
    }

    private var medicationDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(
                    label: "Name",
                    value: viewModel.medication.name ?? "Unknown"
                )

                if let dosageAmount = viewModel.medication.dosageAmount,
                   let dosageUnit = viewModel.medication.dosageUnit {
                    DetailRow(
                        label: "Dosage",
                        value: "\(dosageAmount, specifier: "%.1f") \(dosageUnit)"
                    )
                }

                if let prescribedBy = viewModel.medication.prescribedBy {
                    DetailRow(
                        label: "Prescribed By",
                        value: prescribedBy
                    )
                }

                if let startDate = viewModel.medication.startDate {
                    DetailRow(
                        label: "Start Date",
                        value: formatDate(startDate)
                    )
                }

                if let endDate = viewModel.medication.endDate {
                    DetailRow(
                        label: "End Date",
                        value: formatDate(endDate)
                    )
                }

                DetailRow(
                    label: "Status",
                    value: viewModel.medication.isActive ? "Active" : "Inactive"
                )

                if let instructions = viewModel.medication.instructions {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(instructions)
                            .font(.body)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schedules")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddSchedule = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add schedule")
                .accessibilityHint("Creates a new dose schedule for this medication")
            }

            if viewModel.schedules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)

                    Text("No schedules yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Add Schedule") {
                        showingAddSchedule = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Creates a new dose schedule for this medication")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.schedules, id: \.id) { schedule in
                        ScheduleRowView(schedule: schedule)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .accessibilityHint("Swipe left for more options")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteSchedule(schedule)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityLabel("Delete schedule")
                                .accessibilityHint("Permanently removes this schedule")

                                Button {
                                    viewModel.toggleSchedule(schedule)
                                } label: {
                                    Label(
                                        schedule.isEnabled ? "Disable" : "Enable",
                                        systemImage: schedule.isEnabled ? "pause.circle" : "play.circle"
                                    )
                                }
                                .tint(schedule.isEnabled ? .orange : .green)
                                .accessibilityLabel("\(schedule.isEnabled ? "Disable" : "Enable") schedule")
                                .accessibilityHint(schedule.isEnabled ? "Stops automatic dose tracking for this schedule" : "Resumes automatic dose tracking for this schedule")
                            }
                    }
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Text("Delete Medication")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.15))
                .foregroundColor(.red)
                .cornerRadius(12)
        }
        .padding(.top, 20)
        .accessibilityHint("Permanently deletes this medication and all associated data")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// Helper view for displaying detail rows
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        MedicationDetailView(medication: {
            let context = PersistenceController.preview.container.viewContext
            let medication = Medication(context: context)
            medication.id = UUID()
            medication.name = "Lisinopril"
            medication.dosageAmount = 10.0
            medication.dosageUnit = "mg"
            medication.instructions = "Take once daily with food"
            medication.prescribedBy = "Dr. Smith"
            medication.startDate = Date()
            medication.isActive = true
            return medication
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
