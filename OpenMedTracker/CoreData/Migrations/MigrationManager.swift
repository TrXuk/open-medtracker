//
//  MigrationManager.swift
//  OpenMedTracker
//
//  Core Data migration management
//

import Foundation
import CoreData

/// Manages Core Data migrations
public final class MigrationManager {

    // MARK: - Properties

    private let modelName: String
    private let storeURL: URL

    // MARK: - Initialization

    /// Initialize the migration manager
    /// - Parameters:
    ///   - modelName: Name of the data model (without .xcdatamodeld extension)
    ///   - storeURL: URL of the persistent store
    public init(modelName: String = "OpenMedTracker", storeURL: URL) {
        self.modelName = modelName
        self.storeURL = storeURL
    }

    // MARK: - Migration Check

    /// Checks if migration is needed
    /// - Returns: True if migration is required
    /// - Throws: Error if unable to determine migration status
    public func requiresMigration() throws -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            // Store doesn't exist yet, no migration needed
            return false
        }

        guard let currentModel = NSManagedObjectModel.mergedModel(from: nil) else {
            throw MigrationError.modelNotFound
        }

        return !currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    /// Gets the current model version from the persistent store
    /// - Returns: Version identifier string, or nil if not found
    public func currentStoreVersion() -> String? {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            return nil
        }

        return metadata[NSStoreModelVersionIdentifiersKey] as? String
    }

    // MARK: - Lightweight Migration

    /// Performs lightweight migration
    /// - Returns: True if migration was successful
    /// - Throws: MigrationError if migration fails
    public func performLightweightMigration() throws -> Bool {
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        do {
            let coordinator = NSPersistentStoreCoordinator(
                managedObjectModel: NSManagedObjectModel.mergedModel(from: nil)!
            )

            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options
            )

            return true
        } catch {
            throw MigrationError.lightweightMigrationFailed(error)
        }
    }

    // MARK: - Progressive Migration

    /// Performs progressive migration through multiple model versions
    /// - Parameter targetVersion: Target model version (nil for latest)
    /// - Throws: MigrationError if migration fails
    public func performProgressiveMigration(to targetVersion: String? = nil) throws {
        guard try requiresMigration() else {
            print("No migration required")
            return
        }

        // Get source model
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            throw MigrationError.unableToReadMetadata
        }

        guard let sourceModel = compatibleModel(for: sourceMetadata) else {
            throw MigrationError.sourceModelNotFound
        }

        // Get destination model
        guard let destinationModel = NSManagedObjectModel.mergedModel(from: nil) else {
            throw MigrationError.destinationModelNotFound
        }

        // Perform migration
        try migrateStore(from: sourceModel, to: destinationModel)
    }

    // MARK: - Private Methods

    private func compatibleModel(for metadata: [String: Any]) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(
            from: nil,
            forStoreMetadata: metadata
        )
    }

    private func migrateStore(
        from sourceModel: NSManagedObjectModel,
        to destinationModel: NSManagedObjectModel
    ) throws {
        // Create migration manager
        guard let mappingModel = NSMappingModel(
            from: nil,
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        ) else {
            throw MigrationError.mappingModelNotFound
        }

        let manager = NSMigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )

        // Create temporary destination URL
        let destinationURL = storeURL.deletingLastPathComponent()
            .appendingPathComponent("OpenMedTracker_Migration.sqlite")

        // Perform migration
        do {
            try manager.migrateStore(
                from: storeURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: destinationURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )

            // Replace old store with migrated store
            try replaceStore(at: storeURL, with: destinationURL)

        } catch {
            throw MigrationError.migrationFailed(error)
        }
    }

    private func replaceStore(at targetURL: URL, with sourceURL: URL) throws {
        let fileManager = FileManager.default

        // Remove old store files
        let storeFiles = [
            targetURL,
            targetURL.deletingLastPathComponent().appendingPathComponent("\(modelName).sqlite-shm"),
            targetURL.deletingLastPathComponent().appendingPathComponent("\(modelName).sqlite-wal")
        ]

        for file in storeFiles {
            if fileManager.fileExists(atPath: file.path) {
                try fileManager.removeItem(at: file)
            }
        }

        // Move new store files
        try fileManager.moveItem(at: sourceURL, to: targetURL)

        let newSHM = sourceURL.deletingLastPathComponent()
            .appendingPathComponent("OpenMedTracker_Migration.sqlite-shm")
        let newWAL = sourceURL.deletingLastPathComponent()
            .appendingPathComponent("OpenMedTracker_Migration.sqlite-wal")

        let targetSHM = targetURL.deletingLastPathComponent()
            .appendingPathComponent("\(modelName).sqlite-shm")
        let targetWAL = targetURL.deletingLastPathComponent()
            .appendingPathComponent("\(modelName).sqlite-wal")

        if fileManager.fileExists(atPath: newSHM.path) {
            try fileManager.moveItem(at: newSHM, to: targetSHM)
        }

        if fileManager.fileExists(atPath: newWAL.path) {
            try fileManager.moveItem(at: newWAL, to: targetWAL)
        }
    }

    // MARK: - Backup

    /// Creates a backup of the current store
    /// - Returns: URL of the backup
    /// - Throws: Error if backup fails
    public func createBackup() throws -> URL {
        let backupURL = storeURL.deletingLastPathComponent()
            .appendingPathComponent("OpenMedTracker_Backup_\(Date().timeIntervalSince1970).sqlite")

        let fileManager = FileManager.default

        try fileManager.copyItem(at: storeURL, to: backupURL)

        print("Created backup at: \(backupURL.path)")
        return backupURL
    }

    /// Restores from a backup
    /// - Parameter backupURL: URL of the backup file
    /// - Throws: Error if restore fails
    public func restoreFromBackup(_ backupURL: URL) throws {
        let fileManager = FileManager.default

        // Remove current store
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }

        // Copy backup to store location
        try fileManager.copyItem(at: backupURL, to: storeURL)

        print("Restored from backup: \(backupURL.path)")
    }
}

// MARK: - Migration Errors

public enum MigrationError: LocalizedError {
    case modelNotFound
    case sourceModelNotFound
    case destinationModelNotFound
    case mappingModelNotFound
    case unableToReadMetadata
    case lightweightMigrationFailed(Error)
    case migrationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Could not find data model"

        case .sourceModelNotFound:
            return "Could not find source model for migration"

        case .destinationModelNotFound:
            return "Could not find destination model for migration"

        case .mappingModelNotFound:
            return "Could not find mapping model for migration"

        case .unableToReadMetadata:
            return "Unable to read persistent store metadata"

        case .lightweightMigrationFailed(let error):
            return "Lightweight migration failed: \(error.localizedDescription)"

        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        }
    }
}
