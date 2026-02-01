import Foundation
import CoreData
import Combine

/// ViewModel for the dose history view
@MainActor
class DoseHistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var doseHistory: [DoseHistory] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var selectedMedication: Medication?
    @Published var selectedStatus: String?
    @Published var adherenceRate: Double = 0.0

    // MARK: - Private Properties

    private let doseHistoryService: DoseHistoryService
    private let context: NSManagedObjectContext

    // MARK: - Computed Properties

    var takenCount: Int {
        doseHistory.filter { $0.status == "taken" }.count
    }

    var missedCount: Int {
        doseHistory.filter { $0.status == "missed" }.count
    }

    var skippedCount: Int {
        doseHistory.filter { $0.status == "skipped" }.count
    }

    var pendingCount: Int {
        doseHistory.filter { $0.status == "pending" }.count
    }

    // MARK: - Initialization

    init(
        doseHistoryService: DoseHistoryService = DoseHistoryService(),
        context: NSManagedObjectContext
    ) {
        self.doseHistoryService = doseHistoryService
        self.context = context
    }

    // MARK: - Public Methods

    /// Loads dose history for the date range
    func loadDoseHistory() {
        isLoading = true
        error = nil

        do {
            var history = try doseHistoryService.fetchDoseHistory(
                from: startDate,
                to: endDate,
                in: context
            )

            // Apply medication filter
            if let medication = selectedMedication {
                history = history.filter { $0.schedule?.medication == medication }
            }

            // Apply status filter
            if let status = selectedStatus {
                history = history.filter { $0.status == status }
            }

            // Sort by scheduled time, most recent first
            doseHistory = history.sorted {
                ($0.scheduledTime ?? Date.distantPast) > ($1.scheduledTime ?? Date.distantPast)
            }

            // Calculate adherence
            calculateAdherence()

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Sets the date range filter
    func setDateRange(start: Date, end: Date) {
        startDate = start
        endDate = end
        loadDoseHistory()
    }

    /// Sets the medication filter
    func setMedicationFilter(_ medication: Medication?) {
        selectedMedication = medication
        loadDoseHistory()
    }

    /// Sets the status filter
    func setStatusFilter(_ status: String?) {
        selectedStatus = status
        loadDoseHistory()
    }

    /// Clears all filters
    func clearFilters() {
        selectedMedication = nil
        selectedStatus = nil
        loadDoseHistory()
    }

    // MARK: - Private Methods

    private func calculateAdherence() {
        do {
            adherenceRate = try doseHistoryService.calculateAdherence(
                from: startDate,
                to: endDate,
                in: context
            )
        } catch {
            adherenceRate = 0.0
        }
    }
}
