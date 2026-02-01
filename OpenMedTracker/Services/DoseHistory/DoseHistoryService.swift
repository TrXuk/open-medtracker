//
//  DoseHistoryService.swift
//  OpenMedTracker
//
//  CRUD operations for DoseHistory entity
//

import Foundation
import CoreData

/// Service for managing DoseHistory entities
public final class DoseHistoryService {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// Creates a new dose history record
    /// - Parameters:
    ///   - schedule: The schedule this dose belongs to
    ///   - scheduledTime: When the dose is scheduled
    ///   - status: Initial status (defaults to pending)
    ///   - timezoneIdentifier: Timezone (defaults to current)
    ///   - context: Optional context
    /// - Returns: The created dose history
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        for schedule: Schedule,
        scheduledTime: Date,
        status: DoseHistory.Status = .pending,
        timezoneIdentifier: String = TimeZone.current.identifier,
        in context: NSManagedObjectContext? = nil
    ) throws -> DoseHistory {
        let ctx = context ?? persistenceController.viewContext

        let doseHistory = DoseHistory(context: ctx)
        doseHistory.schedule = schedule
        doseHistory.scheduledTime = scheduledTime
        doseHistory.statusEnum = status
        doseHistory.timezoneIdentifier = timezoneIdentifier

        do {
            try persistenceController.saveContext(ctx)
            return doseHistory
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Creates dose history records for all schedules on a specific date
    /// - Parameters:
    ///   - date: The date to create doses for
    ///   - context: Optional context
    /// - Returns: Array of created dose histories
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func createDosesForDate(
        _ date: Date,
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let scheduleService = ScheduleService(persistenceController: persistenceController)
        let schedules = try scheduleService.fetchSchedulesDue(on: date, in: context)

        var createdDoses: [DoseHistory] = []

        for schedule in schedules {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.timeOfDay)

            guard let scheduledTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: date
            ) else {
                continue
            }

            let dose = try create(
                for: schedule,
                scheduledTime: scheduledTime,
                in: context
            )

            createdDoses.append(dose)
        }

        return createdDoses
    }

    // MARK: - Read

    /// Fetches all dose histories
    /// - Parameters:
    ///   - context: Optional context
    /// - Returns: Array of dose histories
    /// - Throws: PersistenceError if fetch fails
    public func fetchAll(
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DoseHistory.scheduledTime, ascending: false)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches a dose history by ID
    /// - Parameters:
    ///   - id: The dose history's UUID
    ///   - context: Optional context
    /// - Returns: The dose history, or nil if not found
    /// - Throws: PersistenceError if fetch fails
    public func fetch(
        id: UUID,
        in context: NSManagedObjectContext? = nil
    ) throws -> DoseHistory? {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try ctx.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches dose histories for a specific schedule
    /// - Parameters:
    ///   - schedule: The schedule
    ///   - context: Optional context
    /// - Returns: Array of dose histories
    /// - Throws: PersistenceError if fetch fails
    public func fetchHistory(
        for schedule: Schedule,
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()

        request.predicate = NSPredicate(format: "schedule == %@", schedule)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DoseHistory.scheduledTime, ascending: false)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches dose histories with a specific status
    /// - Parameters:
    ///   - status: The status to filter by
    ///   - context: Optional context
    /// - Returns: Array of dose histories
    /// - Throws: PersistenceError if fetch fails
    public func fetchDoses(
        withStatus status: DoseHistory.Status,
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()

        request.predicate = NSPredicate(format: "status == %@", status.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DoseHistory.scheduledTime, ascending: false)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches dose histories within a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    ///   - context: Optional context
    /// - Returns: Array of dose histories
    /// - Throws: PersistenceError if fetch fails
    public func fetchDoses(
        from startDate: Date,
        to endDate: Date,
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()

        request.predicate = NSPredicate(
            format: "scheduledTime >= %@ AND scheduledTime <= %@",
            startDate as CVarArg,
            endDate as CVarArg
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DoseHistory.scheduledTime, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches overdue doses
    /// - Parameters:
    ///   - context: Optional context
    /// - Returns: Array of overdue dose histories
    /// - Throws: PersistenceError if fetch fails
    public func fetchOverdueDoses(
        in context: NSManagedObjectContext? = nil
    ) throws -> [DoseHistory] {
        let ctx = context ?? persistenceController.viewContext
        let request = DoseHistory.fetchRequest()

        let now = Date()
        request.predicate = NSPredicate(
            format: "status == %@ AND scheduledTime < %@",
            DoseHistory.Status.pending.rawValue,
            now as CVarArg
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DoseHistory.scheduledTime, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    // MARK: - Update

    /// Updates a dose history
    /// - Parameters:
    ///   - doseHistory: The dose history to update
    ///   - status: Optional new status
    ///   - actualTime: Optional new actual time
    ///   - notes: Optional new notes
    /// - Throws: PersistenceError if update fails
    public func update(
        _ doseHistory: DoseHistory,
        status: DoseHistory.Status? = nil,
        actualTime: Date? = nil,
        notes: String? = nil
    ) throws {
        if let status = status { doseHistory.statusEnum = status }
        if let actualTime = actualTime { doseHistory.actualTime = actualTime }
        if let notes = notes { doseHistory.notes = notes }

        do {
            try persistenceController.saveContext(doseHistory.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Marks a dose as taken
    /// - Parameters:
    ///   - doseHistory: The dose history
    ///   - time: When it was taken (defaults to now)
    ///   - notes: Optional notes
    /// - Throws: PersistenceError if update fails
    public func markAsTaken(
        _ doseHistory: DoseHistory,
        at time: Date = Date(),
        notes: String? = nil
    ) throws {
        doseHistory.markAsTaken(at: time, notes: notes)

        do {
            try persistenceController.saveContext(doseHistory.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Marks a dose as missed
    /// - Parameters:
    ///   - doseHistory: The dose history
    ///   - notes: Optional notes
    /// - Throws: PersistenceError if update fails
    public func markAsMissed(
        _ doseHistory: DoseHistory,
        notes: String? = nil
    ) throws {
        doseHistory.markAsMissed(notes: notes)

        do {
            try persistenceController.saveContext(doseHistory.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Marks a dose as skipped
    /// - Parameters:
    ///   - doseHistory: The dose history
    ///   - notes: Optional notes
    /// - Throws: PersistenceError if update fails
    public func markAsSkipped(
        _ doseHistory: DoseHistory,
        notes: String? = nil
    ) throws {
        doseHistory.markAsSkipped(notes: notes)

        do {
            try persistenceController.saveContext(doseHistory.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    // MARK: - Delete

    /// Deletes a dose history
    /// - Parameter doseHistory: The dose history to delete
    /// - Throws: PersistenceError if delete fails
    public func delete(_ doseHistory: DoseHistory) throws {
        guard let context = doseHistory.managedObjectContext else {
            throw PersistenceError.deleteFailed(
                NSError(domain: "DoseHistoryService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "DoseHistory has no context"
                ])
            )
        }

        context.delete(doseHistory)

        do {
            try persistenceController.saveContext(context)
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    /// Deletes dose histories older than a certain date
    /// - Parameter date: Cutoff date
    /// - Throws: PersistenceError if delete fails
    public func deleteHistory(olderThan date: Date) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DoseHistory")
        fetchRequest.predicate = NSPredicate(format: "scheduledTime < %@", date as CVarArg)

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try persistenceController.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            guard let objectIDArray = result?.result as? [NSManagedObjectID] else { return }

            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [persistenceController.viewContext])
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    // MARK: - Statistics

    /// Calculates adherence rate for a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    /// - Returns: Adherence rate (0.0 to 1.0)
    /// - Throws: PersistenceError if fetch fails
    public func calculateAdherence(
        from startDate: Date,
        to endDate: Date
    ) throws -> Double {
        let doses = try fetchDoses(from: startDate, to: endDate)

        guard !doses.isEmpty else { return 0.0 }

        let takenCount = doses.filter { $0.wasTaken }.count
        return Double(takenCount) / Double(doses.count)
    }

    /// Gets count of doses by status
    /// - Parameter status: The status to count
    /// - Returns: Count of doses with that status
    public func count(withStatus status: DoseHistory.Status) throws -> Int {
        let request = DoseHistory.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status.rawValue)

        do {
            return try persistenceController.viewContext.count(for: request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }
}
