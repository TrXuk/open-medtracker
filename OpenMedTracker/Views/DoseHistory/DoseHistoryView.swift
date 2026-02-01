import SwiftUI
import CoreData

/// Main dose history view showing all dose records with filters and statistics
struct DoseHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DoseHistoryViewModel
    @State private var showingFilters = false

    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: DoseHistoryViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading history...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadDoseHistory()
                    }
                } else {
                    historyContent
                }
            }
            .navigationTitle("Dose History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter dose history")
                    .accessibilityHint(hasActiveFilters ? "Filters are currently active. Tap to modify filters" : "Opens filter options to narrow down dose history")
                }
            }
            .sheet(isPresented: $showingFilters) {
                DoseHistoryFiltersView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.loadDoseHistory()
            }
            .onAppear {
                viewModel.loadDoseHistory()
            }
        }
    }

    private var historyContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Statistics section
                statisticsSection

                // History list
                if viewModel.doseHistory.isEmpty {
                    EmptyStateView(
                        icon: "clock.fill",
                        title: "No History",
                        message: hasActiveFilters
                            ? "No dose history matches your filters"
                            : "Dose history will appear here as you take medications"
                    )
                    .padding(.top, 60)
                } else {
                    historyListSection
                }
            }
            .padding()
        }
    }

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Adherence rate
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adherence Rate")
                            .font(.headline)
                        Text("\(Int(viewModel.adherenceRate * 100))%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(adherenceColor)
                    }

                    Spacer()

                    CircularProgressView(progress: viewModel.adherenceRate, color: adherenceColor)
                        .frame(width: 80, height: 80)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Adherence rate \(Int(viewModel.adherenceRate * 100)) percent")
                .accessibilityValue(adherenceDescription)

                // Status counts
                HStack(spacing: 12) {
                    StatCard(
                        title: "Taken",
                        count: viewModel.takenCount,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    StatCard(
                        title: "Missed",
                        count: viewModel.missedCount,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                }

                HStack(spacing: 12) {
                    StatCard(
                        title: "Skipped",
                        count: viewModel.skippedCount,
                        color: .orange,
                        icon: "minus.circle.fill"
                    )

                    StatCard(
                        title: "Pending",
                        count: viewModel.pendingCount,
                        color: .blue,
                        icon: "clock.fill"
                    )
                }
            }
        }
    }

    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.title2)
                .fontWeight(.semibold)

            if hasActiveFilters {
                HStack {
                    Text("Filters active")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()

                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }

            LazyVStack(spacing: 8) {
                ForEach(viewModel.doseHistory, id: \.id) { dose in
                    DoseHistoryRowView(doseHistory: dose)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
        }
    }

    private var adherenceColor: Color {
        if viewModel.adherenceRate >= 0.9 {
            return .green
        } else if viewModel.adherenceRate >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }

    private var hasActiveFilters: Bool {
        viewModel.selectedMedication != nil || viewModel.selectedStatus != nil
    }

    private var adherenceDescription: String {
        if viewModel.adherenceRate >= 0.9 {
            return "Excellent adherence"
        } else if viewModel.adherenceRate >= 0.7 {
            return "Good adherence"
        } else {
            return "Needs improvement"
        }
    }
}

/// Statistics card view
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title.lowercased()) \(count == 1 ? "dose" : "doses")")
    }
}

/// Circular progress view for adherence rate
struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .accessibilityHidden(true) // Progress info is conveyed via parent label
    }
}

/// Filters sheet view
struct DoseHistoryFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DoseHistoryViewModel
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedStatus: String?

    init(viewModel: DoseHistoryViewModel) {
        self.viewModel = viewModel
        _startDate = State(initialValue: viewModel.startDate)
        _endDate = State(initialValue: viewModel.endDate)
        _selectedStatus = State(initialValue: viewModel.selectedStatus)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                    Button("Last 7 Days") {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        endDate = Date()
                    }
                    .accessibilityHint("Sets date range to the last 7 days")

                    Button("Last 30 Days") {
                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        endDate = Date()
                    }
                    .accessibilityHint("Sets date range to the last 30 days")

                    Button("Last 90 Days") {
                        startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
                        endDate = Date()
                    }
                    .accessibilityHint("Sets date range to the last 90 days")
                }

                Section("Status") {
                    Picker("Status", selection: $selectedStatus) {
                        Text("All").tag(nil as String?)
                        Text("Taken").tag("taken" as String?)
                        Text("Missed").tag("missed" as String?)
                        Text("Skipped").tag("skipped" as String?)
                        Text("Pending").tag("pending" as String?)
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button("Reset to Defaults") {
                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        endDate = Date()
                        selectedStatus = nil
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }

    private func applyFilters() {
        viewModel.setDateRange(start: startDate, end: endDate)
        viewModel.setStatusFilter(selectedStatus)
    }
}

#Preview {
    DoseHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
