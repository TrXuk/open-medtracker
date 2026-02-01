# TimezoneManager Service

## Overview

The `TimezoneManager` is a singleton service designed to handle all timezone-related functionality for the OpenMedTracker app. It provides robust timezone change detection, conversion utilities, and logging capabilities essential for tracking medication schedules across different timezones during international travel.

## Features

### 1. Singleton Pattern
- Single shared instance accessible via `TimezoneManager.shared`
- Ensures consistent timezone state across the application

### 2. Timezone Change Detection
- Monitors `NSSystemTimeZoneDidChange` notifications
- Posts custom notifications when timezone changes occur
- Automatically updates local timezone when system timezone changes
- Provides old and new timezone information in notification userInfo

### 3. Timezone Conversion Utilities

The manager provides comprehensive conversion methods between:
- **UTC ↔ Reference Timezone** (typically UTC for medical tracking)
- **UTC ↔ Local Timezone** (user's current timezone)
- **Local ↔ Reference Timezone** (direct conversion)

### 4. Logging
- Uses unified logging (`os.log`) for system-level logging
- Logs timezone initialization
- Logs timezone change events with detailed information:
  - Old and new timezone identifiers
  - UTC offsets
  - Offset changes
  - Timestamps

## Usage Examples

### Basic Setup

```swift
// Access the shared instance
let timezoneManager = TimezoneManager.shared

// Get current timezone information
let description = timezoneManager.currentTimezoneDescription()
print(description) // "America/New_York (EST, UTC-5)"
```

### Observing Timezone Changes

```swift
// Register for timezone change notifications
NotificationCenter.default.addObserver(
    forName: TimezoneManager.timezoneDidChangeNotification,
    object: nil,
    queue: .main
) { notification in
    if let oldTimezone = notification.userInfo?["oldTimezone"] as? TimeZone,
       let newTimezone = notification.userInfo?["newTimezone"] as? TimeZone {
        print("Timezone changed from \(oldTimezone.identifier) to \(newTimezone.identifier)")
        // Update medication schedules, UI, etc.
    }
}
```

### Converting Times for Medication Tracking

```swift
// Convert a medication time from local to UTC for storage
var localComponents = DateComponents()
localComponents.year = 2024
localComponents.month = 1
localComponents.day = 15
localComponents.hour = 8  // 8 AM local time
localComponents.minute = 0

if let utcDate = timezoneManager.convertLocalToUTC(localComponents) {
    // Store utcDate in database
    print("Stored as: \(utcDate.toUTCString())")
}

// Convert back from UTC to local for display
let storedUTCDate = Date() // Retrieved from database
let localComponents = timezoneManager.convertUTCToLocal(storedUTCDate)
print("Take medication at: \(localComponents.hour ?? 0):\(localComponents.minute ?? 0)")
```

### Formatting Dates in Different Timezones

```swift
let medicationTime = Date()

// Format in UTC
let utcString = timezoneManager.formatDate(
    medicationTime,
    in: TimeZone(identifier: "UTC")!,
    dateStyle: .short,
    timeStyle: .short
)

// Format in local timezone
let localString = timezoneManager.formatDate(
    medicationTime,
    in: timezoneManager.localTimezone,
    dateStyle: .medium,
    timeStyle: .medium
)

// Or use convenient Date extensions
print("UTC: \(medicationTime.toUTCString())")
print("Local: \(medicationTime.toLocalString())")
```

### Calculating Timezone Offsets

```swift
// Get offset between local and reference timezone
let offsetSeconds = timezoneManager.offsetBetweenLocalAndReference()
let offsetHours = offsetSeconds / 3600
print("Your timezone is \(offsetHours) hours from UTC")

// For a specific date (handles DST)
let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
let futureOffset = timezoneManager.offsetBetweenLocalAndReference(for: futureDate)
```

### Changing Reference Timezone

```swift
// Update reference timezone (e.g., for testing or special requirements)
let pacificTime = TimeZone(identifier: "America/Los_Angeles")!
timezoneManager.setReferenceTimezone(pacificTime)

// Reset to UTC
timezoneManager.setReferenceTimezone(TimeZone(identifier: "UTC")!)
```

## Architecture Decisions

### Why Singleton?
- Ensures single source of truth for timezone state
- Prevents multiple observers for system timezone changes
- Provides consistent timezone information across the app

### Why UTC as Reference?
- Medical schedules should be consistent regardless of travel
- UTC is the international standard for time coordination
- Simplifies backend synchronization and multi-device support

### Why Monitor System Notifications?
- Automatic detection when user crosses timezone boundaries
- Handles both manual and automatic timezone changes
- Enables real-time medication schedule updates

## Integration Points

The TimezoneManager is designed to integrate with:

1. **Medication Schedule Manager**: Convert scheduled times based on timezone
2. **Notification Service**: Update local notification times when timezone changes
3. **Data Persistence Layer**: Store all times in UTC, convert for display
4. **Analytics**: Track timezone changes for travel patterns
5. **UI Components**: Display times in user's preferred format/timezone

## Testing

Comprehensive unit tests are provided in `TimezoneManagerTests.swift`:

- Singleton pattern verification
- Notification posting and handling
- Conversion accuracy (UTC ↔ Local ↔ Reference)
- Round-trip conversion integrity
- Offset calculations
- Date formatting
- Reference timezone configuration

## Performance Considerations

- Lightweight singleton initialization
- Efficient date conversions using Calendar API
- No heavy computation in notification handlers
- Logging uses unified logging system (efficient in production)

## Future Enhancements

Potential additions for future phases:
- Timezone history tracking for travel logs
- Smart medication schedule adjustment suggestions
- Integration with HealthKit for comprehensive health tracking
- Timezone prediction based on location services
- Offline timezone database for air travel

## Related Documentation

- [Medication Scheduling](../Models/MedicationSchedule.md) (coming in Phase 2.4)
- [Data Persistence](../Utilities/DataStore.md) (coming in Phase 2.5)
- [Notification Service](../Services/NotificationService.md) (coming in Phase 3.1)
