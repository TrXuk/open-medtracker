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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteMedication(medication)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        viewModel.toggleActive(medication)
                    } label: {
                        Label(
                            medication.isActive ? "Deactivate" : "Activate",
                            systemImage: medication.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                    .tint(medication.isActive ? .orange : .green)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    MedicationListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
