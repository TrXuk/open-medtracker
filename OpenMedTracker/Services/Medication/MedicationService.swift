//
//  MedicationService.swift
//  OpenMedTracker
//
//  CRUD operations for Medication entity
//

import Foundation
import CoreData

/// Service for managing Medication entities
public final class MedicationService {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// Creates a new medication
    /// - Parameters:
    ///   - name: Medication name
    ///   - dosageAmount: Amount per dose
    ///   - dosageUnit: Unit of measurement
    ///   - instructions: Optional instructions
    ///   - prescribedBy: Optional prescriber name
    ///   - startDate: Start date (defaults to now)
    ///   - endDate: Optional end date
    ///   - context: Optional context (defaults to view context)
    /// - Returns: The created medication
    /// - Throws: PersistenceError if creation fails
    @discardableResult
    public func create(
        name: String,
        dosageAmount: Double,
        dosageUnit: String,
        instructions: String? = nil,
        prescribedBy: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        in context: NSManagedObjectContext? = nil
    ) throws -> Medication {
        let ctx = context ?? persistenceController.viewContext

        let medication = Medication(context: ctx)
        medication.name = name
        medication.dosageAmount = dosageAmount
        medication.dosageUnit = dosageUnit
        medication.instructions = instructions
        medication.prescribedBy = prescribedBy
        medication.startDate = startDate
        medication.endDate = endDate

        do {
            try persistenceController.saveContext(ctx)
            return medication
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    // MARK: - Read

    /// Fetches all medications
    /// - Parameters:
    ///   - includeInactive: Whether to include inactive medications
    ///   - context: Optional context
    /// - Returns: Array of medications
    /// - Throws: PersistenceError if fetch fails
    public func fetchAll(
        includeInactive: Bool = false,
        in context: NSManagedObjectContext? = nil
    ) throws -> [Medication] {
        let ctx = context ?? persistenceController.viewContext
        let request = Medication.fetchRequest()

        if !includeInactive {
            request.predicate = NSPredicate(format: "isActive == YES")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Medication.name, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches a medication by ID
    /// - Parameters:
    ///   - id: The medication's UUID
    ///   - context: Optional context
    /// - Returns: The medication, or nil if not found
    /// - Throws: PersistenceError if fetch fails
    public func fetch(
        id: UUID,
        in context: NSManagedObjectContext? = nil
    ) throws -> Medication? {
        let ctx = context ?? persistenceController.viewContext
        let request = Medication.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try ctx.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Fetches medications that are currently active
    /// - Parameter context: Optional context
    /// - Returns: Array of active medications
    /// - Throws: PersistenceError if fetch fails
    public func fetchActive(
        in context: NSManagedObjectContext? = nil
    ) throws -> [Medication] {
        let ctx = context ?? persistenceController.viewContext
        let request = Medication.fetchRequest()

        let now = Date()
        let activePredicate = NSPredicate(format: "isActive == YES AND startDate <= %@", now as CVarArg)
        let noEndDatePredicate = NSPredicate(format: "endDate == nil")
        let endDateInFuturePredicate = NSPredicate(format: "endDate >= %@", now as CVarArg)

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            activePredicate,
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                noEndDatePredicate,
                endDateInFuturePredicate
            ])
        ])

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Medication.name, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    /// Searches medications by name
    /// - Parameters:
    ///   - searchText: Text to search for
    ///   - context: Optional context
    /// - Returns: Array of matching medications
    /// - Throws: PersistenceError if fetch fails
    public func search(
        _ searchText: String,
        in context: NSManagedObjectContext? = nil
    ) throws -> [Medication] {
        let ctx = context ?? persistenceController.viewContext
        let request = Medication.fetchRequest()

        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Medication.name, ascending: true)
        ]

        do {
            return try ctx.fetch(request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }

    // MARK: - Update

    /// Updates a medication
    /// - Parameters:
    ///   - medication: The medication to update
    ///   - name: Optional new name
    ///   - dosageAmount: Optional new dosage amount
    ///   - dosageUnit: Optional new dosage unit
    ///   - instructions: Optional new instructions
    ///   - prescribedBy: Optional new prescriber
    ///   - startDate: Optional new start date
    ///   - endDate: Optional new end date
    ///   - isActive: Optional new active status
    /// - Throws: PersistenceError if update fails
    public func update(
        _ medication: Medication,
        name: String? = nil,
        dosageAmount: Double? = nil,
        dosageUnit: String? = nil,
        instructions: String? = nil,
        prescribedBy: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool? = nil
    ) throws {
        if let name = name { medication.name = name }
        if let dosageAmount = dosageAmount { medication.dosageAmount = dosageAmount }
        if let dosageUnit = dosageUnit { medication.dosageUnit = dosageUnit }
        if let instructions = instructions { medication.instructions = instructions }
        if let prescribedBy = prescribedBy { medication.prescribedBy = prescribedBy }
        if let startDate = startDate { medication.startDate = startDate }
        if let endDate = endDate { medication.endDate = endDate }
        if let isActive = isActive { medication.isActive = isActive }

        do {
            try persistenceController.saveContext(medication.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Deactivates a medication
    /// - Parameter medication: The medication to deactivate
    /// - Throws: PersistenceError if update fails
    public func deactivate(_ medication: Medication) throws {
        medication.deactivate()

        do {
            try persistenceController.saveContext(medication.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Reactivates a medication
    /// - Parameter medication: The medication to reactivate
    /// - Throws: PersistenceError if update fails
    public func reactivate(_ medication: Medication) throws {
        medication.reactivate()

        do {
            try persistenceController.saveContext(medication.managedObjectContext!)
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    // MARK: - Delete

    /// Deletes a medication
    /// - Parameter medication: The medication to delete
    /// - Throws: PersistenceError if delete fails
    public func delete(_ medication: Medication) throws {
        guard let context = medication.managedObjectContext else {
            throw PersistenceError.deleteFailed(
                NSError(domain: "MedicationService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Medication has no context"
                ])
            )
        }

        context.delete(medication)

        do {
            try persistenceController.saveContext(context)
        } catch {
            throw PersistenceError.deleteFailed(error)
        }
    }

    /// Deletes all medications
    /// - Parameter includeActive: Whether to delete active medications (defaults to false)
    /// - Throws: PersistenceError if delete fails
    public func deleteAll(includeActive: Bool = false) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Medication")

        if !includeActive {
            fetchRequest.predicate = NSPredicate(format: "isActive == NO")
        }

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

    /// Gets count of all medications
    /// - Parameter includeInactive: Whether to include inactive medications
    /// - Returns: Count of medications
    public func count(includeInactive: Bool = false) throws -> Int {
        let request = Medication.fetchRequest()

        if !includeInactive {
            request.predicate = NSPredicate(format: "isActive == YES")
        }

        do {
            return try persistenceController.viewContext.count(for: request)
        } catch {
            throw PersistenceError.fetchFailed(error)
        }
    }
}
