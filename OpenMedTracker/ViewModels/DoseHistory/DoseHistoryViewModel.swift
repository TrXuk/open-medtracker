//
//  DoseHistoryViewModel.swift
//  OpenMedTracker
//
//  View model for managing dose history and adherence tracking
//

import Foundation
import Combine
import CoreData

/// View model for displaying and managing dose history
@MainActor
public final class DoseHistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of dose history records
    @Published public private(set) var doseHistory: [DoseHistory] = []

    /// Filtered dose history based on current filters
    @Published public private(set) var filteredDoseHistory: [DoseHistory] = []

    /// Start date for filtering
    @Published public var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    /// End date for filtering
    @Published public var endDate: Date = Date()

    /// Selected status filter (nil = all)
    @Published public var selectedStatus: DoseHistory.Status?

    /// Selected medication filter (nil = all)
    @Published public var selectedMedication: Medication?

    /// Current loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current error, if any
    @Published public private(set) var error: ViewModelError?

    /// Adherence rate (0.0 to 1.0)
    @Published public private(set) var adherenceRate: Double = 0.0

    /// Formatted adherence percentage
    public var adherencePercentage: String {
        String(format: "%.1f%%", adherenceRate * 100)
    }

    /// Count of doses by status
    @Published public private(set) var statusCounts: [DoseHistory.Status: Int] = [:]

    /// Overdue doses
    @Published public private(set) var overdueDoses: [DoseHistory] = []

    // MARK: - Computed Properties

    /// Total dose count
    public var totalDoses: Int {
        filteredDoseHistory.count
    }

    /// Taken dose count
    public var takenCount: Int {
        statusCounts[.taken] ?? 0
    }

    /// Missed dose count
    public var missedCount: Int {
        statusCounts[.missed] ?? 0
    }

    /// Skipped dose count
    public var skippedCount: Int {
        statusCounts[.skipped] ?? 0
    }

    /// Pending dose count
    public var pendingCount: Int {
        statusCounts[.pending] ?? 0
    }

    /// Overdue dose count
    public var overdueCount: Int {
        overdueDoses.count
    }

    // MARK: - Private Properties

    private let doseHistoryService: DoseHistoryService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with optional dose history service
    /// - Parameter doseHistoryService: Service for dose history operations
    public init(doseHistoryService: DoseHistoryService = DoseHistoryService()) {
        self.doseHistoryService = doseHistoryService
        setupPublishers()
    }

    // MARK: - Setup

    private func setupPublishers() {
        // Combine filters to update filtered dose history
        Publishers.CombineLatest4(
            $doseHistory,
            $selectedStatus,
            $selectedMedication,
            Publishers.CombineLatest($startDate, $endDate)
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .map { doseHistory, status, medication, dates in
            var filtered = doseHistory

            // Filter by date range
            let (start, end) = dates
            filtered = filtered.filter { dose in
                dose.scheduledTime >= start && dose.scheduledTime <= end
            }

            // Filter by status
            if let status = status {
                filtered = filtered.filter { $0.statusEnum == status }
            }

            // Filter by medication
            if let medication = medication {
                filtered = filtered.filter { $0.schedule?.medication == medication }
            }

            return filtered
        }
        .sink { [weak self] filtered in
            self?.filteredDoseHistory = filtered
            self?.updateStatistics()
        }
        .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load dose history for the current date range
    public func loadDoseHistory() {
        isLoading = true
        error = nil

        do {
            doseHistory = try doseHistoryService.fetchDoses(from: startDate, to: endDate)
            loadOverdueDoses()
            calculateAdherence()
            isLoading = false
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            doseHistory = []
            isLoading = false
        }
    }

    /// Load overdue doses
    private func loadOverdueDoses() {
        do {
            overdueDoses = try doseHistoryService.fetchOverdueDoses()
        } catch {
            // Don't set error for this, it's a secondary operation
            overdueDoses = []
        }
    }

    /// Refresh the dose history
    public func refresh() {
        loadDoseHistory()
    }

    /// Mark a dose as taken
    /// - Parameters:
    ///   - dose: The dose to mark as taken
    ///   - time: The time it was taken (defaults to now)
    ///   - notes: Optional notes
    public func markAsTaken(_ dose: DoseHistory, at time: Date = Date(), notes: String? = nil) {
        error = nil

        do {
            try doseHistoryService.markAsTaken(dose, at: time, notes: notes)
            refresh()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Mark a dose as missed
    /// - Parameters:
    ///   - dose: The dose to mark as missed
    ///   - notes: Optional notes
    public func markAsMissed(_ dose: DoseHistory, notes: String? = nil) {
        error = nil

        do {
            try doseHistoryService.markAsMissed(dose, notes: notes)
            refresh()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Mark a dose as skipped
    /// - Parameters:
    ///   - dose: The dose to mark as skipped
    ///   - notes: Optional notes
    public func markAsSkipped(_ dose: DoseHistory, notes: String? = nil) {
        error = nil

        do {
            try doseHistoryService.markAsSkipped(dose, notes: notes)
            refresh()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Reset a dose to pending status
    /// - Parameter dose: The dose to reset
    public func resetToPending(_ dose: DoseHistory) {
        error = nil

        do {
            try doseHistoryService.resetToPending(dose)
            refresh()
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
        }
    }

    /// Set date range to last 7 days
    public func setLast7Days() {
        endDate = Date()
        startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? Date()
        loadDoseHistory()
    }

    /// Set date range to last 30 days
    public func setLast30Days() {
        endDate = Date()
        startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? Date()
        loadDoseHistory()
    }

    /// Set date range to current month
    public func setCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? now
        loadDoseHistory()
    }

    /// Set date range to last month
    public func setLastMonth() {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)) ?? now
        endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? now
        loadDoseHistory()
    }

    /// Filter by status
    /// - Parameter status: The status to filter by (nil = all)
    public func filterByStatus(_ status: DoseHistory.Status?) {
        selectedStatus = status
    }

    /// Filter by medication
    /// - Parameter medication: The medication to filter by (nil = all)
    public func filterByMedication(_ medication: Medication?) {
        selectedMedication = medication
    }

    /// Clear all filters
    public func clearFilters() {
        selectedStatus = nil
        selectedMedication = nil
    }

    /// Calculate adherence rate for current date range
    private func calculateAdherence() {
        do {
            adherenceRate = try doseHistoryService.calculateAdherence(from: startDate, to: endDate)
        } catch {
            adherenceRate = 0.0
        }
    }

    /// Update statistics from filtered dose history
    private func updateStatistics() {
        statusCounts.removeAll()

        for status in DoseHistory.Status.allCases {
            let count = filteredDoseHistory.filter { $0.statusEnum == status }.count
            statusCounts[status] = count
        }
    }

    /// Clear any current error
    public func clearError() {
        error = nil
    }

    /// Get doses grouped by date
    /// - Returns: Dictionary of doses grouped by date string
    public func dosesByDate() -> [(date: String, doses: [DoseHistory])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredDoseHistory) { dose -> String in
            let dateOnly = calendar.startOfDay(for: dose.scheduledTime)
            return formatter.string(from: dateOnly)
        }

        return grouped.map { (date: $0.key, doses: $0.value) }
            .sorted { $0.date > $1.date }
    }

    /// Get doses for a specific medication
    /// - Parameter medication: The medication to get doses for
    /// - Returns: Array of doses for that medication
    public func doses(for medication: Medication) -> [DoseHistory] {
        filteredDoseHistory.filter { $0.schedule?.medication == medication }
    }

    /// Get adherence rate for a specific medication
    /// - Parameter medication: The medication to calculate adherence for
    /// - Returns: Adherence rate (0.0 to 1.0)
    public func adherenceRate(for medication: Medication) -> Double {
        let doses = self.doses(for: medication)
        guard !doses.isEmpty else { return 0.0 }

        let takenCount = doses.filter { $0.wasTaken }.count
        return Double(takenCount) / Double(doses.count)
    }
}

// MARK: - Preview Helper

extension DoseHistoryViewModel {
    /// Create a preview instance with mock data
    public static func preview() -> DoseHistoryViewModel {
        let viewModel = DoseHistoryViewModel(
            doseHistoryService: DoseHistoryService(persistenceController: .preview)
        )
        viewModel.loadDoseHistory()
        return viewModel
    }
}
