import SwiftUI
import CoreData

/// Main schedule view showing today's doses and upcoming schedules
struct ScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DailyScheduleViewModel
    @State private var showingDatePicker = false

    init() {
        _viewModel = StateObject(wrappedValue: DailyScheduleViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading schedule...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadScheduleData()
                    }
                } else {
                    scheduleContent
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDatePicker.toggle()
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("Select date")
                    .accessibilityHint("Opens calendar to choose a different date")
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate) {
                    viewModel.selectDate(viewModel.selectedDate)
                }
            }
            .refreshable {
                viewModel.loadScheduleData()
            }
            .onAppear {
                viewModel.loadScheduleData()
            }
        }
    }

    private var scheduleContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date header
                dateHeaderSection

                // Today's doses
                if viewModel.todayDoses.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: isToday ? "No Doses Today" : "No Doses",
                        message: isToday
                            ? "You don't have any medications scheduled for today"
                            : "No medications scheduled for \(formatDate(viewModel.selectedDate))"
                    )
                    .padding(.top, 60)
                } else {
                    dosesSection
                }
            }
            .padding()
        }
    }

    private var dateHeaderSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    viewModel.selectDate(previousDay)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                .accessibilityLabel("Previous day")
                .accessibilityHint("Shows schedule for the previous day")

                Spacer()

                VStack(spacing: 4) {
                    Text(formatDate(viewModel.selectedDate))
                        .font(.headline)

                    if isToday {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(formatDate(viewModel.selectedDate))\(isToday ? ", Today" : "")")

                Spacer()

                Button {
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    viewModel.selectDate(nextDay)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
                .accessibilityLabel("Next day")
                .accessibilityHint("Shows schedule for the next day")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if !isToday {
                Button("Jump to Today") {
                    viewModel.selectDate(Date())
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityHint("Returns to today's schedule")
            }
        }
    }

    private var dosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doses")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(viewModel.todayDoses, id: \.id) { dose in
                DoseCard(
                    dose: dose,
                    onMarkTaken: {
                        viewModel.markDoseAsTaken(dose)
                    },
                    onMarkSkipped: {
                        viewModel.markDoseAsSkipped(dose)
                    },
                    onMarkMissed: {
                        viewModel.markDoseAsMissed(dose)
                    }
                )
            }
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// Card view for displaying a single dose
struct DoseCard: View {
    let dose: DoseHistory
    let onMarkTaken: () -> Void
    let onMarkSkipped: () -> Void
    let onMarkMissed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.medicationName)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatTime(dose.scheduledTime))
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(doseAccessibilityLabel)

                Spacer()

                StatusBadgeView(status: dose.status)
            }

            if dose.status == "pending" {
                HStack(spacing: 12) {
                    Button {
                        onMarkTaken()
                    } label: {
                        Label("Take", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Mark \(dose.medicationName ?? "dose") as taken")
                    .accessibilityHint("Records this dose as taken at the current time")

                    Button {
                        onMarkSkipped()
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Skip \(dose.medicationName ?? "dose")")
                    .accessibilityHint("Marks this dose as intentionally skipped")
                }
            } else if dose.status == "taken", let actualTime = dose.actualTime {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Taken at \(formatTime(actualTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Dose taken at \(formatTime(actualTime))")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var doseAccessibilityLabel: String {
        var label = dose.medicationName ?? "Unknown medication"
        if let scheduledTime = dose.scheduledTime {
            label += " scheduled for \(formatTime(scheduledTime))"
        }
        return label
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Date picker sheet
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let onSelect: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelect()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScheduleView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
