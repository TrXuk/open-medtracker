import SwiftUI
import CoreData

/// Main view displaying a list of all medications
struct MedicationListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: MedicationListViewModel
    @State private var showingAddMedication = false
    @State private var selectedMedication: Medication?

    init() {
        // Initialize with default context - will be replaced by environment
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: MedicationListViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading medications...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadMedications()
                    }
                } else if viewModel.medications.isEmpty {
                    EmptyStateView(
                        icon: "pill.fill",
                        title: "No Medications",
                        message: viewModel.searchText.isEmpty
                            ? "Add your first medication to start tracking"
                            : "No medications found matching '\(viewModel.searchText)'",
                        actionTitle: viewModel.searchText.isEmpty ? "Add Medication" : nil,
                        action: viewModel.searchText.isEmpty ? { showingAddMedication = true } : nil
                    )
                } else {
                    medicationList
                }
            }
            .navigationTitle("Medications")
            .searchable(text: $viewModel.searchText, prompt: "Search medications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Active Only", isOn: $viewModel.showActiveOnly)
                            .onChange(of: viewModel.showActiveOnly) { _ in
                                viewModel.loadMedications()
                            }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter medications")
                    .accessibilityHint("Shows filter options to display only active medications")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add medication")
                    .accessibilityHint("Opens form to add a new medication")
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                MedicationFormView(mode: .add)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear {
                        viewModel.loadMedications()
                    }
            }
            .sheet(item: $selectedMedication) { medication in
                NavigationStack {
                    MedicationDetailView(medication: medication)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .refreshable {
                viewModel.loadMedications()
            }
            .onAppear {
                // Update viewModel context with environment context
                viewModel.loadMedications()
            }
        }
    }

    private var medicationList: some View {
        List {
            ForEach(viewModel.medications, id: \.id) { medication in
                Button {
                    selectedMedication = medication
                } label: {
                    MedicationRowView(medication: medication)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(medicationAccessibilityLabel(for: medication))
                .accessibilityHint("Double tap to view details. Swipe left for more options.")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteMedication(medication)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(medication.name ?? "medication")")
                    .accessibilityHint("Permanently removes this medication and all its data")

                    Button {
                        viewModel.toggleActive(medication)
                    } label: {
                        Label(
                            medication.isActive ? "Deactivate" : "Activate",
                            systemImage: medication.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                    .tint(medication.isActive ? .orange : .green)
                    .accessibilityLabel("\(medication.isActive ? "Deactivate" : "Activate") \(medication.name ?? "medication")")
                    .accessibilityHint(medication.isActive ? "Stops tracking doses for this medication" : "Resumes tracking doses for this medication")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func medicationAccessibilityLabel(for medication: Medication) -> String {
        var label = medication.name ?? "Unknown medication"

        if let dosageAmount = medication.dosageAmount, let dosageUnit = medication.dosageUnit {
            label += ", \(dosageAmount, specifier: "%.1f") \(dosageUnit)"
        }

        if !medication.isActive {
            label += ", Inactive"
        }

        if let schedules = medication.schedules as? Set<Schedule>,
           let nextSchedule = schedules.filter({ $0.isEnabled }).first {
            label += ", Next dose scheduled"
        }

        return label
    }
}

#Preview {
    MedicationListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
