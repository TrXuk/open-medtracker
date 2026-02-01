import Foundation
import CoreData
import Combine

/// ViewModel for the schedule view
@MainActor
class ScheduleViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var todayDoses: [DoseHistory] = []
    @Published var upcomingSchedules: [Schedule] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var selectedDate: Date = Date()

    // MARK: - Private Properties

    private let scheduleService: ScheduleService
    private let doseHistoryService: DoseHistoryService
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(
        scheduleService: ScheduleService = ScheduleService(),
        doseHistoryService: DoseHistoryService = DoseHistoryService(),
        context: NSManagedObjectContext
    ) {
        self.scheduleService = scheduleService
        self.doseHistoryService = doseHistoryService
        self.context = context
    }

    // MARK: - Public Methods

    /// Loads today's doses and upcoming schedules
    func loadScheduleData() {
        isLoading = true
        error = nil

        do {
            // Load doses for selected date
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            todayDoses = try doseHistoryService.fetchDoseHistory(
                from: startOfDay,
                to: endOfDay,
                in: context
            ).sorted { ($0.scheduledTime ?? Date.distantPast) < ($1.scheduledTime ?? Date.distantPast) }

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Marks a dose as taken
    func markDoseAsTaken(_ dose: DoseHistory, at time: Date = Date()) {
        do {
            try doseHistoryService.markAsTaken(dose, at: time, in: context)
            loadScheduleData()
        } catch {
            self.error = error
        }
    }

    /// Marks a dose as skipped
    func markDoseAsSkipped(_ dose: DoseHistory, reason: String? = nil) {
        do {
            try doseHistoryService.markAsSkipped(dose, reason: reason, in: context)
            loadScheduleData()
        } catch {
            self.error = error
        }
    }

    /// Marks a dose as missed
    func markDoseAsMissed(_ dose: DoseHistory) {
        do {
            try doseHistoryService.markAsMissed(dose, in: context)
            loadScheduleData()
        } catch {
            self.error = error
        }
    }

    /// Changes the selected date
    func selectDate(_ date: Date) {
        selectedDate = date
        loadScheduleData()
    }
}
