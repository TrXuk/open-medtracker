//
//  ScheduleViewModel.swift
//  OpenMedTracker
//
//  View model for managing medication schedules
//

import Foundation
import Combine
import CoreData

/// View model for creating and editing medication schedules
@MainActor
public final class ScheduleViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The schedule being viewed/edited
    @Published public private(set) var schedule: Schedule?

    /// The medication this schedule belongs to
    @Published public var medication: Medication?

    /// Time of day for the medication
    @Published public var timeOfDay: Date = Date()

    /// Frequency description
    @Published public var frequency: String = "daily"

    /// Selected days of the week
    @Published public var selectedDays: Set<Schedule.DayOfWeek> = Set(Schedule.DayOfWeek.allCases)

    /// Whether the schedule is enabled
    @Published public var isEnabled: Bool = true

    /// Current loading state
    @Published public private(set) var isLoading: Bool = false

    /// Current saving state
    @Published public private(set) var isSaving: Bool = false

    /// Current error, if any
    @Published public private(set) var error: ViewModelError?

    /// Validation errors
    @Published public private(set) var validationErrors: [String: String] = [:]

    /// Whether the form is valid
    @Published public private(set) var isValid: Bool = false

    /// Next scheduled time for this schedule
    @Published public private(set) var nextScheduledTime: Date?

    /// Formatted next scheduled time
    public var formattedNextScheduledTime: String? {
        guard let nextTime = nextScheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextTime)
    }

    /// Whether all days are selected
    public var isEveryday: Bool {
        selectedDays.count == 7
    }

    /// Whether only weekdays are selected
    public var isWeekdaysOnly: Bool {
        selectedDays == Set([.monday, .tuesday, .wednesday, .thursday, .friday])
    }

    /// Whether only weekends are selected
    public var isWeekendsOnly: Bool {
        selectedDays == Set([.saturday, .sunday])
    }

    // MARK: - Private Properties

    private let scheduleService: ScheduleService
    private var cancellables = Set<AnyCancellable>()
    private let isNewSchedule: Bool

    // MARK: - Initialization

    /// Initialize for creating a new schedule
    /// - Parameters:
    ///   - medication: The medication for this schedule
    ///   - scheduleService: Service for schedule operations
    public init(
        medication: Medication,
        scheduleService: ScheduleService = ScheduleService()
    ) {
        self.scheduleService = scheduleService
        self.medication = medication
        self.isNewSchedule = true
        setupValidation()
        updateNextScheduledTime()
    }

    /// Initialize for editing an existing schedule
    /// - Parameters:
    ///   - schedule: The schedule to edit
    ///   - scheduleService: Service for schedule operations
    public init(
        schedule: Schedule,
        scheduleService: ScheduleService = ScheduleService()
    ) {
        self.scheduleService = scheduleService
        self.schedule = schedule
        self.isNewSchedule = false

        // Populate fields from schedule
        self.medication = schedule.medication
        self.timeOfDay = schedule.timeOfDay
        self.frequency = schedule.frequency
        self.isEnabled = schedule.isEnabled
        self.selectedDays = Set(schedule.enabledDays)

        setupValidation()
        updateNextScheduledTime()
    }

    // MARK: - Setup

    private func setupValidation() {
        // Validate whenever relevant fields change
        Publishers.CombineLatest3(
            $medication,
            $selectedDays,
            $timeOfDay
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.validate()
            self?.updateNextScheduledTime()
        }
        .store(in: &cancellables)
    }

    // MARK: - Validation

    private func validate() {
        validationErrors.removeAll()

        // Validate medication
        if medication == nil {
            validationErrors["medication"] = "Medication is required"
        }

        // Validate days of week
        if selectedDays.isEmpty {
            validationErrors["days"] = "At least one day must be selected"
        }

        isValid = validationErrors.isEmpty
    }

    // MARK: - Public Methods

    /// Save the schedule
    /// - Returns: The saved schedule, or nil if save failed
    @discardableResult
    public func save() async -> Schedule? {
        validate()

        guard isValid else {
            error = .validationFailed(message: "Please correct the errors before saving")
            return nil
        }

        guard let medication = medication else {
            error = .validationFailed(message: "No medication selected")
            return nil
        }

        isSaving = true
        error = nil

        do {
            let savedSchedule: Schedule

            // Convert selected days to bitmask
            let daysOfWeek = selectedDays.reduce(Int16(0)) { result, day in
                result | day.bit
            }

            if isNewSchedule {
                // Create new schedule
                savedSchedule = try scheduleService.create(
                    for: medication,
                    timeOfDay: timeOfDay,
                    frequency: frequency,
                    daysOfWeek: daysOfWeek,
                    isEnabled: isEnabled
                )
            } else {
                // Update existing schedule
                guard let schedule = schedule else {
                    throw ViewModelError.invalidState("No schedule to update")
                }

                try scheduleService.update(
                    schedule,
                    timeOfDay: timeOfDay,
                    frequency: frequency,
                    daysOfWeek: daysOfWeek,
                    isEnabled: isEnabled
                )

                savedSchedule = schedule
            }

            self.schedule = savedSchedule
            updateNextScheduledTime()
            isSaving = false
            return savedSchedule

        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            isSaving = false
            return nil
        }
    }

    /// Delete the schedule
    public func delete() async -> Bool {
        guard let schedule = schedule else {
            error = .invalidState("No schedule to delete")
            return false
        }

        error = nil

        do {
            try scheduleService.delete(schedule)
            return true
        } catch {
            self.error = ViewModelError.from(persistenceError: error)
            return false
        }
    }

    /// Toggle a specific day
    /// - Parameter day: The day to toggle
    public func toggleDay(_ day: Schedule.DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    /// Select all days
    public func selectAllDays() {
        selectedDays = Set(Schedule.DayOfWeek.allCases)
    }

    /// Select weekdays only (Monday-Friday)
    public func selectWeekdays() {
        selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
    }

    /// Select weekends only (Saturday-Sunday)
    public func selectWeekends() {
        selectedDays = [.saturday, .sunday]
    }

    /// Clear all selected days
    public func clearDays() {
        selectedDays.removeAll()
    }

    /// Enable the schedule
    public func enable() {
        isEnabled = true
        updateNextScheduledTime()
    }

    /// Disable the schedule
    public func disable() {
        isEnabled = false
        nextScheduledTime = nil
    }

    /// Toggle schedule enabled state
    public func toggleEnabled() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    /// Update the next scheduled time
    private func updateNextScheduledTime() {
        guard isEnabled, !selectedDays.isEmpty else {
            nextScheduledTime = nil
            return
        }

        // Create a temporary schedule to calculate next time
        // (This is a bit hacky but avoids saving just to calculate)
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOfDay)
        let daysOfWeek = selectedDays.reduce(Int16(0)) { result, day in
            result | day.bit
        }

        // Try each day in the next week
        for dayOffset in 0..<7 {
            guard let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }

            guard let candidateWithTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: candidateDate
            ) else {
                continue
            }

            // Skip if this time has already passed today
            if dayOffset == 0 && candidateWithTime <= now {
                continue
            }

            // Check if this day is enabled
            let weekday = calendar.component(.weekday, from: candidateDate)
            if let day = Schedule.DayOfWeek(rawValue: weekday - 1) {
                if (daysOfWeek & day.bit) != 0 {
                    nextScheduledTime = candidateWithTime
                    return
                }
            }
        }

        nextScheduledTime = nil
    }

    /// Clear any current error
    public func clearError() {
        error = nil
    }

    /// Get validation error for a specific field
    /// - Parameter field: The field name
    /// - Returns: Error message if exists
    public func validationError(for field: String) -> String? {
        validationErrors[field]
    }

    /// Whether a specific field has an error
    /// - Parameter field: The field name
    /// - Returns: True if field has validation error
    public func hasError(for field: String) -> Bool {
        validationErrors[field] != nil
    }
}

// MARK: - Preview Helper

extension ScheduleViewModel {
    /// Create a preview instance for new schedule
    public static func previewNew() -> ScheduleViewModel? {
        let service = MedicationService(persistenceController: .preview)
        guard let medication = try? service.fetchAll().first else {
            return nil
        }
        return ScheduleViewModel(
            medication: medication,
            scheduleService: ScheduleService(persistenceController: .preview)
        )
    }

    /// Create a preview instance for existing schedule
    public static func previewExisting() -> ScheduleViewModel? {
        let medicationService = MedicationService(persistenceController: .preview)
        guard let medication = try? medicationService.fetchAll().first,
              let schedules = medication.schedules as? Set<Schedule>,
              let schedule = schedules.first else {
            return nil
        }
        return ScheduleViewModel(
            schedule: schedule,
            scheduleService: ScheduleService(persistenceController: .preview)
        )
    }
}
