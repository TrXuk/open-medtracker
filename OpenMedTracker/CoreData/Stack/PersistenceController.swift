//
//  PersistenceController.swift
//  OpenMedTracker
//
//  Core Data stack management
//

import CoreData
import Foundation

/// Manages the Core Data persistence stack for the application
public final class PersistenceController {

    // MARK: - Singleton

    /// Shared instance for production use
    public static let shared = PersistenceController()

    /// Preview instance for SwiftUI previews with sample data
    public static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample data for previews
        do {
            // Sample medication
            let medication = Medication(context: context)
            medication.id = UUID()
            medication.name = "Aspirin"
            medication.dosageAmount = 500
            medication.dosageUnit = "mg"
            medication.instructions = "Take with food"
            medication.startDate = Date()
            medication.isActive = true
            medication.createdAt = Date()
            medication.updatedAt = Date()

            // Sample schedule
            let schedule = Schedule(context: context)
            schedule.id = UUID()
            schedule.timeOfDay = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
            schedule.frequency = "daily"
            schedule.daysOfWeek = 127 // All days
            schedule.isEnabled = true
            schedule.createdAt = Date()
            schedule.updatedAt = Date()
            schedule.medication = medication

            try context.save()
        } catch {
            print("Failed to create preview data: \(error)")
        }

        return controller
    }()

    // MARK: - Properties

    /// The persistent container for the application
    public let container: NSPersistentContainer

    /// Main view context for UI operations
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    /// Initialize the persistence controller
    /// - Parameter inMemory: If true, uses in-memory store for testing/previews
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "OpenMedTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure persistent store description
        if let description = container.persistentStoreDescriptions.first {
            // Enable persistent history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable lightweight migration
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        // Load persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this error appropriately
                fatalError("Failed to load Core Data stack: \(error)")
            }

            print("Core Data store loaded: \(description.url?.absoluteString ?? "unknown")")
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up notifications for persistent store remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Context Management

    /// Creates a new background context for performing operations off the main thread
    /// - Returns: A new background managed object context
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Performs a block on a background context
    /// - Parameter block: The block to execute with the background context
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // MARK: - Save Operations

    /// Saves the view context if it has changes
    /// - Throws: Core Data error if save fails
    public func saveViewContext() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }

    /// Saves a background context if it has changes
    /// - Parameter context: The context to save
    /// - Throws: Core Data error if save fails
    public func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        if context.concurrencyType == .mainQueueConcurrencyType {
            try context.save()
        } else {
            var saveError: Error?
            context.performAndWait {
                do {
                    try context.save()
                } catch {
                    saveError = error
                }
            }
            if let error = saveError {
                throw error
            }
        }
    }

    /// Saves a context with error handling
    /// - Parameter context: The context to save
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    public func trySave(_ context: NSManagedObjectContext) -> Bool {
        do {
            try saveContext(context)
            return true
        } catch {
            print("Failed to save context: \(error)")
            return false
        }
    }

    // MARK: - Batch Operations

    /// Deletes all data from the specified entity
    /// - Parameter entityName: Name of the entity to delete all records from
    /// - Throws: Core Data error if batch delete fails
    public func deleteAll(entity entityName: String) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        guard let objectIDArray = result?.result as? [NSManagedObjectID] else { return }

        let changes = [NSDeletedObjectsKey: objectIDArray]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
    }

    // MARK: - Private Methods

    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        // Handle remote changes (e.g., from CloudKit)
        viewContext.perform {
            // The view context will automatically merge changes due to automaticallyMergesChangesFromParent
            print("Received remote change notification")
        }
    }

    // MARK: - Development Helpers

    #if DEBUG
    /// Destroys and recreates the persistent store (for development only)
    public func resetStore() throws {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw NSError(domain: "PersistenceController", code: -1, userInfo: [NSLocalizedDescriptionKey: "No store URL found"])
        }

        let coordinator = container.persistentStoreCoordinator

        // Remove all persistent stores
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }

        // Delete the store file
        try FileManager.default.removeItem(at: storeURL)

        // Reload persistent stores
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to reload Core Data stack: \(error)")
            }
        }
    }
    #endif
}

// MARK: - Error Types

public enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case validationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}
