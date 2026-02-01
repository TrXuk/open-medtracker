import Foundation
import CoreData
import Combine

/// ViewModel for the medication detail view
@MainActor
class MedicationDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var medication: Medication
    @Published var schedules: [Schedule] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Private Properties

    private let medicationService: MedicationService
    private let scheduleService: ScheduleService
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(
        medication: Medication,
        medicationService: MedicationService = MedicationService(),
        scheduleService: ScheduleService = ScheduleService(),
        context: NSManagedObjectContext
    ) {
        self.medication = medication
        self.medicationService = medicationService
        self.scheduleService = scheduleService
        self.context = context
        loadSchedules()
    }

    // MARK: - Public Methods

    /// Loads schedules for the medication
    func loadSchedules() {
        isLoading = true
        error = nil

        do {
            schedules = try scheduleService.fetchSchedules(
                for: medication,
                in: context
            )
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Updates medication details
    func updateMedication(
        name: String,
        dosageAmount: Double,
        dosageUnit: String,
        instructions: String?,
        prescribedBy: String?
    ) {
        do {
            try medicationService.update(
                medication,
                name: name,
                dosageAmount: dosageAmount,
                dosageUnit: dosageUnit,
                instructions: instructions,
                prescribedBy: prescribedBy,
                in: context
            )
        } catch {
            self.error = error
        }
    }

    /// Deletes a schedule
    func deleteSchedule(_ schedule: Schedule) {
        do {
            try scheduleService.delete(schedule, in: context)
            loadSchedules()
        } catch {
            self.error = error
        }
    }

    /// Toggles schedule enabled status
    func toggleSchedule(_ schedule: Schedule) {
        do {
            if schedule.isEnabled {
                try scheduleService.disable(schedule, in: context)
            } else {
                try scheduleService.enable(schedule, in: context)
            }
            loadSchedules()
        } catch {
            self.error = error
        }
    }
}
