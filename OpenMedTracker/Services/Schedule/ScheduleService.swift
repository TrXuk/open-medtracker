//
//  ScheduleService.swift
//  OpenMedTracker
//
//  CRUD operations for Schedule entity
//

import Foundation
import CoreData

/// Service for managing Schedule entities
public final class ScheduleService {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// Creates a new schedule
    /// - Parameters:
    ///   - medication: The medication this schedule is for
    ///   - timeOfDay: Time when medication should be taken
    ///   - frequency: Frequency string (e.g., "daily")
    ///   - daysOfWeek: Bitmask for days of week
    ///   - isEnabled: Whether the schedule is active
    ///   - context: Optional context
    /// - Returns: The created schedule
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        for medication: Medication,
        timeOfDay: Date,
        frequency: String = "daily",
        daysOfWeek: Int16 = 127,
        isEnabled: Bool = true,
        in context: NSManagedObjectContext? = nil
    ) throws -> Schedule {
        let ctx = context ?? persistenceController.viewContext

        let schedule = Schedule(context: ctx)
        schedule.medication = medication
        schedule.timeOfDay = timeOfDay
        schedule.frequency = frequency
        schedule.daysOfWeek = daysOfWeek
        schedule.isEnabled = isEnabled

        do {
            try persistenceController.saveContext(ctx)
            return schedule
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Creates a schedule with specific time components
    /// - Parameters:
    ///   - medication: The medication this schedule is for
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute of hour (0-59)
    ///   - frequency: Frequency string
    ///   - daysOfWeek: Bitmask for days of week
    ///   - context: Optional context
    /// - Returns: The created schedule
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        for medication: Medication,
        hour: Int,
        minute: Int,
        frequency: String = "daily",
        daysOfWeek: Int16 = 127,
        in context: NSManagedObjectContext? = nil
    ) throws -> Schedule {
        let calendar = Calendar.current
        let now = Date()

        guard let timeOfDay = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else {
            throw PersistenceError.validationFailed("Invalid time components")
        }

        return try create(
            for: medication,
            timeOfDay: timeOfDay,
            frequency: frequency,
            daysOfWeek: daysOfWeek,
            in: context
        )
    }

    // MARK: - Read

    /// Fetches all schedules
    /// - Parameters:
    ///   - includeDisabled: Whether to include disabled schedules
    ///   - context: Optional context
    /// - Returns: Array of schedules
    /// - Throws: PersistenceError if fetch fails
    public func fetchAll(
        includeDisabled: Bool = false,
        in context: NSManagedObjectContext? = nil
    ) throws -> [Schedule] {
        let ctx = context ?? persistenceController.viewContext
        let request = Schedule.fetchRequest()

        if !includeDisabled {
            request.predicate = NSPredicate(format: "isEnabled == YES")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Schedule.timeOfDay, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches a schedule by ID
    /// - Parameters:
    ///   - id: The schedule's UUID
    ///   - context: Optional context
    /// - Returns: The schedule, or nil if not found
    /// - Throws: PersistenceError if fetch fails
    public func fetch(
        id: UUID,
        in context: NSManagedObjectContext? = nil
    ) throws -> Schedule? {
        let ctx = context ?? persistenceController.viewContext
        let request = Schedule.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try ctx.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches schedules for a specific medication
    /// - Parameters:
    ///   - medication: The medication
    ///   - includeDisabled: Whether to include disabled schedules
    ///   - context: Optional context
    /// - Returns: Array of schedules
    /// - Throws: PersistenceError if fetch fails
    public func fetchSchedules(
        for medication: Medication,
        includeDisabled: Bool = false,
        in context: NSManagedObjectContext? = nil
    ) throws -> [Schedule] {
        let ctx = context ?? persistenceController.viewContext
        let request = Schedule.fetchRequest()

        var predicates = [NSPredicate(format: "medication == %@", medication)]

        if !includeDisabled {
            predicates.append(NSPredicate(format: "isEnabled == YES"))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Schedule.timeOfDay, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches schedules due on a specific date
    /// - Parameters:
    ///   - date: The date to check
    ///   - context: Optional context
    /// - Returns: Array of schedules due on that date
    /// - Throws: PersistenceError if fetch fails
    public func fetchSchedulesDue(
        on date: Date,
        in context: NSManagedObjectContext? = nil
    ) throws -> [Schedule] {
        let allSchedules = try fetchAll(includeDisabled: false, in: context)

        return allSchedules.filter { $0.isDueOn(date: date) }
    }

    // MARK: - Update

    /// Updates a schedule
    /// - Parameters:
    ///   - schedule: The schedule to update
    ///   - timeOfDay: Optional new time
    ///   - frequency: Optional new frequency
    ///   - daysOfWeek: Optional new days bitmask
    ///   - isEnabled: Optional new enabled status
    /// - Throws: PersistenceError if update fails
    public func update(
        _ schedule: Schedule,
        timeOfDay: Date? = nil,
        frequency: String? = nil,
        daysOfWeek: Int16? = nil,
        isEnabled: Bool? = nil
    ) throws {
        if let timeOfDay = timeOfDay { schedule.timeOfDay = timeOfDay }
        if let frequency = frequency { schedule.frequency = frequency }
        if let daysOfWeek = daysOfWeek { schedule.daysOfWeek = daysOfWeek }
        if let isEnabled = isEnabled { schedule.isEnabled = isEnabled }

        do {
            try persistenceController.saveContext(schedule.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Enables a schedule
    /// - Parameter schedule: The schedule to enable
    /// - Throws: PersistenceError if update fails
    public func enable(_ schedule: Schedule) throws {
        schedule.isEnabled = true

        do {
            try persistenceController.saveContext(schedule.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Disables a schedule
    /// - Parameter schedule: The schedule to disable
    /// - Throws: PersistenceError if update fails
    public func disable(_ schedule: Schedule) throws {
        schedule.isEnabled = false

        do {
            try persistenceController.saveContext(schedule.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    // MARK: - Delete

    /// Deletes a schedule
    /// - Parameter schedule: The schedule to delete
    /// - Throws: PersistenceError if delete fails
    public func delete(_ schedule: Schedule) throws {
        guard let context = schedule.managedObjectContext else {
            throw PersistenceError.deleteFailed(
                NSError(domain: "ScheduleService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Schedule has no context"
                ])
            )
        }

        context.delete(schedule)

        do {
            try persistenceController.saveContext(context)
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    /// Deletes all schedules for a medication
    /// - Parameter medication: The medication
    /// - Throws: PersistenceError if delete fails
    public func deleteSchedules(for medication: Medication) throws {
        let schedules = try fetchSchedules(for: medication, includeDisabled: true)

        for schedule in schedules {
            medication.managedObjectContext?.delete(schedule)
        }

        do {
            try persistenceController.saveContext(medication.managedObjectContext!)
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    // MARK: - Helper Methods

    /// Gets the next scheduled time across all schedules
    /// - Parameter afterDate: Reference date (defaults to now)
    /// - Returns: The next scheduled time, or nil if no schedules
    public func nextScheduledTime(after afterDate: Date = Date()) throws -> Date? {
        let schedules = try fetchAll(includeDisabled: false)

        let nextTimes = schedules.compactMap { $0.nextScheduledTime(after: afterDate) }

        return nextTimes.min()
    }

    /// Gets count of all schedules
    /// - Parameter includeDisabled: Whether to include disabled schedules
    /// - Returns: Count of schedules
    public func count(includeDisabled: Bool = false) throws -> Int {
        let request = Schedule.fetchRequest()

        if !includeDisabled {
            request.predicate = NSPredicate(format: "isEnabled == YES")
        }

        do {
            return try persistenceController.viewContext.count(for: request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }
}
