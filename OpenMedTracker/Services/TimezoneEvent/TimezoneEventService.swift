//
//  TimezoneEventService.swift
//  OpenMedTracker
//
//  CRUD operations for TimezoneEvent entity
//

import Foundation
import CoreData

/// Service for managing TimezoneEvent entities
public final class TimezoneEventService {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// Creates a new timezone event
    /// - Parameters:
    ///   - previousTimezone: The previous timezone identifier
    ///   - newTimezone: The new timezone identifier
    ///   - transitionTime: When the timezone change occurred
    ///   - location: Optional location description
    ///   - notes: Optional notes
    ///   - context: Optional context
    /// - Returns: The created timezone event
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        previousTimezone: String,
        newTimezone: String,
        transitionTime: Date = Date(),
        location: String? = nil,
        notes: String? = nil,
        in context: NSManagedObjectContext? = nil
    ) throws -> TimezoneEvent {
        let ctx = context ?? persistenceController.viewContext

        let event = TimezoneEvent(context: ctx)
        event.previousTimezone = previousTimezone
        event.newTimezone = newTimezone
        event.transitionTime = transitionTime
        event.location = location
        event.notes = notes

        do {
            try persistenceController.saveContext(ctx)
            return event
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Creates a timezone event using TimeZone objects
    /// - Parameters:
    ///   - previousTimezone: The previous timezone
    ///   - newTimezone: The new timezone
    ///   - transitionTime: When the timezone change occurred
    ///   - location: Optional location description
    ///   - notes: Optional notes
    ///   - context: Optional context
    /// - Returns: The created timezone event
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        from previousTimezone: TimeZone,
        to newTimezone: TimeZone,
        at transitionTime: Date = Date(),
        location: String? = nil,
        notes: String? = nil,
        in context: NSManagedObjectContext? = nil
    ) throws -> TimezoneEvent {
        return try create(
            previousTimezone: previousTimezone.identifier,
            newTimezone: newTimezone.identifier,
            transitionTime: transitionTime,
            location: location,
            notes: notes,
            in: context
        )
    }

    /// Creates a timezone event for the current timezone change
    /// Automatically detects the current timezone
    /// - Parameters:
    ///   - previousTimezone: The previous timezone identifier
    ///   - location: Optional location description
    ///   - notes: Optional notes
    ///   - context: Optional context
    /// - Returns: The created timezone event
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func recordCurrentTimezoneChange(
        from previousTimezone: String,
        location: String? = nil,
        notes: String? = nil,
        in context: NSManagedObjectContext? = nil
    ) throws -> TimezoneEvent {
        return try create(
            previousTimezone: previousTimezone,
            newTimezone: TimeZone.current.identifier,
            transitionTime: Date(),
            location: location,
            notes: notes,
            in: context
        )
    }

    // MARK: - Read

    /// Fetches all timezone events
    /// - Parameter context: Optional context
    /// - Returns: Array of timezone events
    /// - Throws: PersistenceError if fetch fails
    public func fetchAll(
        in context: NSManagedObjectContext? = nil
    ) throws -> [TimezoneEvent] {
        let ctx = context ?? persistenceController.viewContext
        let request = TimezoneEvent.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimezoneEvent.transitionTime, ascending: false)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches a timezone event by ID
    /// - Parameters:
    ///   - id: The timezone event's UUID
    ///   - context: Optional context
    /// - Returns: The timezone event, or nil if not found
    /// - Throws: PersistenceError if fetch fails
    public func fetch(
        id: UUID,
        in context: NSManagedObjectContext? = nil
    ) throws -> TimezoneEvent? {
        let ctx = context ?? persistenceController.viewContext
        let request = TimezoneEvent.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try ctx.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches timezone events within a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    ///   - context: Optional context
    /// - Returns: Array of timezone events
    /// - Throws: PersistenceError if fetch fails
    public func fetchEvents(
        from startDate: Date,
        to endDate: Date,
        in context: NSManagedObjectContext? = nil
    ) throws -> [TimezoneEvent] {
        let ctx = context ?? persistenceController.viewContext
        let request = TimezoneEvent.fetchRequest()

        request.predicate = NSPredicate(
            format: "transitionTime >= %@ AND transitionTime <= %@",
            startDate as CVarArg,
            endDate as CVarArg
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimezoneEvent.transitionTime, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches the most recent timezone event
    /// - Parameter context: Optional context
    /// - Returns: The most recent timezone event, or nil if none exist
    /// - Throws: PersistenceError if fetch fails
    public func fetchMostRecent(
        in context: NSManagedObjectContext? = nil
    ) throws -> TimezoneEvent? {
        let ctx = context ?? persistenceController.viewContext
        let request = TimezoneEvent.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimezoneEvent.transitionTime, ascending: false)
        ]
        request.fetchLimit = 1

        do {
            return try ctx.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    // MARK: - Update

    /// Updates a timezone event
    /// - Parameters:
    ///   - event: The timezone event to update
    ///   - previousTimezone: Optional new previous timezone
    ///   - newTimezone: Optional new new timezone
    ///   - transitionTime: Optional new transition time
    ///   - location: Optional new location
    ///   - notes: Optional new notes
    /// - Throws: PersistenceError if update fails
    public func update(
        _ event: TimezoneEvent,
        previousTimezone: String? = nil,
        newTimezone: String? = nil,
        transitionTime: Date? = nil,
        location: String? = nil,
        notes: String? = nil
    ) throws {
        if let previousTimezone = previousTimezone { event.previousTimezone = previousTimezone }
        if let newTimezone = newTimezone { event.newTimezone = newTimezone }
        if let transitionTime = transitionTime { event.transitionTime = transitionTime }
        if let location = location { event.location = location }
        if let notes = notes { event.notes = notes }

        do {
            try persistenceController.saveContext(event.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    // MARK: - Delete

    /// Deletes a timezone event
    /// - Parameter event: The timezone event to delete
    /// - Throws: PersistenceError if delete fails
    public func delete(_ event: TimezoneEvent) throws {
        guard let context = event.managedObjectContext else {
            throw PersistenceError.deleteFailed(
                NSError(domain: "TimezoneEventService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "TimezoneEvent has no context"
                ])
            )
        }

        context.delete(event)

        do {
            try persistenceController.saveContext(context)
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    /// Deletes timezone events older than a certain date
    /// - Parameter date: Cutoff date
    /// - Throws: PersistenceError if delete fails
    public func deleteEvents(olderThan date: Date) throws {
        let request = TimezoneEvent.fetchRequest()
        request.predicate = NSPredicate(format: "transitionTime < %@", date as CVarArg)

        do {
            let oldEvents = try persistenceController.viewContext.fetch(request)

            for event in oldEvents {
                persistenceController.viewContext.delete(event)
            }

            try persistenceController.saveViewContext()
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    // MARK: - Dose Association

    /// Associates affected doses with a timezone event
    /// - Parameters:
    ///   - event: The timezone event
    ///   - doses: Doses to associate
    /// - Throws: PersistenceError if update fails
    public func associateDoses(
        with event: TimezoneEvent,
        doses: [DoseHistory]
    ) throws {
        for dose in doses {
            dose.timezoneEvent = event
        }

        do {
            try persistenceController.saveContext(event.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Finds and associates doses that may be affected by a timezone event
    /// - Parameter event: The timezone event
    /// - Throws: PersistenceError if operation fails
    public func autoAssociateDoses(with event: TimezoneEvent) throws {
        let doseService = DoseHistoryService(persistenceController: persistenceController)

        // Find doses scheduled around the transition time
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .hour, value: -24, to: event.transitionTime),
              let endDate = calendar.date(byAdding: .hour, value: 24, to: event.transitionTime) else {
            return
        }

        let doses = try doseService.fetchDoses(
            from: startDate,
            to: endDate,
            in: event.managedObjectContext
        )

        try associateDoses(with: event, doses: doses)
    }

    // MARK: - Statistics

    /// Gets count of all timezone events
    /// - Returns: Count of timezone events
    public func count() throws -> Int {
        let request = TimezoneEvent.fetchRequest()

        do {
            return try persistenceController.viewContext.count(for: request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }
}
