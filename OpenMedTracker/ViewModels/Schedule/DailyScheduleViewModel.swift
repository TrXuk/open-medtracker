//
//  DailyScheduleViewModel.swift
//  OpenMedTracker
//
//  View model for managing daily schedule view and dose tracking
//

import Foundation
import Combine
import CoreData

/// View model for displaying daily dose schedule
@MainActor
public final class DailyScheduleViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Currently selected date
    @Published public var selectedDate: Date = Date()

    /// Doses for the selected date
    @Published public private(set) var todayDoses: [DoseHistory] = []

    /// Current loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current error, if any
    @Published public private(set) var error: ViewModelError?

    // MARK: - Private Properties

    private let doseHistoryService: DoseHistoryService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with optional dose history service
    public nonisolated init(doseHistoryService: DoseHistoryService = DoseHistoryService()) {
        self.doseHistoryService = doseHistoryService
    }

    // MARK: - Public Methods

    /// Load schedule data for the selected date
    public func loadScheduleData() {
        isLoading = true
        error = nil

        Task {
            do {
                let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate

                todayDoses = try await doseHistoryService.fetchDoseHistory(
                    startDate: startOfDay,
                    endDate: endOfDay,
                    status: nil,
                    medication: nil
                )

                isLoading = false
            } catch {
                self.error = ViewModelError.from(persistenceError: error)
                isLoading = false
            }
        }
    }

    /// Select a new date and load its doses
    public func selectDate(_ date: Date) {
        selectedDate = date
        loadScheduleData()
    }

    /// Mark a dose as taken
    public func markDoseAsTaken(_ dose: DoseHistory) {
        Task {
            do {
                try await doseHistoryService.markAsTaken(dose, at: Date())
                loadScheduleData()
            } catch {
                self.error = ViewModelError.from(persistenceError: error)
            }
        }
    }

    /// Mark a dose as skipped
    public func markDoseAsSkipped(_ dose: DoseHistory) {
        Task {
            do {
                try await doseHistoryService.markAsSkipped(dose)
                loadScheduleData()
            } catch {
                self.error = ViewModelError.from(persistenceError: error)
            }
        }
    }

    /// Mark a dose as missed
    public func markDoseAsMissed(_ dose: DoseHistory) {
        Task {
            do {
                try await doseHistoryService.markAsMissed(dose)
                loadScheduleData()
            } catch {
                self.error = ViewModelError.from(persistenceError: error)
            }
        }
    }

    /// Clear any errors
    public func clearError() {
        error = nil
    }
}
