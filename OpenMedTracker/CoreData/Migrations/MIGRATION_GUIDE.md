# Core Data Migration Guide

## Overview

This document describes how to handle Core Data migrations for the OpenMedTracker application.

## Migration Types

### Lightweight Migration

Lightweight migrations are automatic and handle simple changes like:
- Adding new attributes with default values
- Removing attributes
- Making non-optional attributes optional
- Making optional attributes non-optional (if they have a default value)
- Renaming entities or attributes (using renaming identifiers)

**Lightweight migrations are enabled by default** in `PersistenceController.swift`:
```swift
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
```

### Heavyweight Migration

Heavyweight migrations are required for complex changes like:
- Changing attribute types
- Changing relationship cardinality
- Complex data transformations
- Splitting/merging entities

Use `MigrationManager` for heavyweight migrations.

## Migration Strategy

### 1. Create New Model Version

1. Select the `.xcdatamodeld` file in Xcode
2. Editor → Add Model Version
3. Name it appropriately (e.g., `OpenMedTracker_v2`)
4. Make your changes in the new version
5. Set the new version as current

### 2. Test Migration

Before releasing:
```swift
let migrationManager = MigrationManager(
    modelName: "OpenMedTracker",
    storeURL: persistenceController.container.persistentStoreDescriptions.first!.url!
)

if try migrationManager.requiresMigration() {
    // Create backup before migrating
    let backupURL = try migrationManager.createBackup()
    print("Backup created at: \(backupURL)")

    // Attempt migration
    try migrationManager.performProgressiveMigration()
}
```

### 3. Handle Migration Failures

Always create backups before migration:
```swift
do {
    try migrationManager.performProgressiveMigration()
} catch {
    print("Migration failed: \(error)")
    // Optionally restore from backup
    try migrationManager.restoreFromBackup(backupURL)
}
```

## Version History

### Version 1.0 (Current)

**Entities:**
- Medication
- Schedule
- DoseHistory
- TimezoneEvent

**Initial release schema**

## Common Migration Scenarios

### Adding a New Attribute

1. Add attribute in new model version with default value
2. Lightweight migration handles automatically

### Renaming an Attribute

1. Add new model version
2. Add renaming identifier in the model editor:
   - Select attribute
   - Data Model Inspector → Renaming ID
   - Set to old name

### Changing Data Types

Requires heavyweight migration with custom mapping model:

1. Create new model version
2. Create custom mapping model (.xcmappingmodel)
3. Implement custom entity migration policy if needed

### Example: String to Integer Migration

```swift
// Create custom NSEntityMigrationPolicy subclass
class StringToIntegerMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        try super.createDestinationInstances(
            forSource: sInstance,
            in: mapping,
            manager: manager
        )

        guard let destinationInstances = manager.destinationInstances(
            forEntityMappingName: mapping.name,
            sourceInstances: [sInstance]
        ) else { return }

        for destinationInstance in destinationInstances {
            if let stringValue = sInstance.value(forKey: "oldAttribute") as? String {
                let intValue = Int(stringValue) ?? 0
                destinationInstance.setValue(intValue, forKey: "newAttribute")
            }
        }
    }
}
```

## Best Practices

1. **Always test migrations** with production data before release
2. **Create backups** before attempting migrations
3. **Use lightweight migrations** when possible
4. **Version your models** clearly (v1, v2, v3, etc.)
5. **Document breaking changes** in this file
6. **Test on devices** with existing data
7. **Implement rollback strategy** for failed migrations
8. **Monitor migration performance** for large datasets

## Debugging Migrations

### Enable Migration Logging

Add launch argument in Xcode scheme:
```
-com.apple.CoreData.MigrationDebug 1
-com.apple.CoreData.SQLDebug 1
```

### Check Migration Status

```swift
let manager = MigrationManager(modelName: "OpenMedTracker", storeURL: storeURL)

if try manager.requiresMigration() {
    print("Migration required")
    print("Current version: \(manager.currentStoreVersion() ?? "unknown")")
} else {
    print("No migration needed")
}
```

## Emergency Procedures

### If Migration Fails in Production

1. Restore from backup:
```swift
try migrationManager.restoreFromBackup(backupURL)
```

2. If no backup available:
   - User data is preserved in SQLite file
   - Can be manually migrated using SQL scripts
   - Contact support with store file for recovery

### Preventing Data Loss

The app automatically creates backups before migration. Backups are stored in:
```
<Application Support>/Backups/OpenMedTracker_Backup_<timestamp>.sqlite
```

Retain backups for at least 30 days after successful migration.
