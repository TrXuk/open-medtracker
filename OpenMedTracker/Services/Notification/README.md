# NotificationService

Service for managing local notifications for medication reminders in OpenMedTracker.

## Overview

`NotificationService` handles all aspects of medication reminder notifications including:
- Scheduling notifications based on medication schedules
- Handling timezone changes by automatically rescheduling notifications
- Supporting notification actions (Mark as Taken, Skip, Snooze)
- Integrating with `DoseHistoryService` to record dose events

## Features

### Notification Scheduling

The service schedules local notifications for all active medication schedules up to 7 days in advance. Notifications are automatically created based on:
- Schedule time of day
- Days of week the medication should be taken
- Medication details (name, dosage)

### Timezone Awareness

When the device timezone changes, the service:
1. Listens to `TimezoneManager.timezoneDidChangeNotification`
2. Cancels all existing notifications
3. Reschedules all notifications in the new timezone

This ensures users always receive reminders at the correct local time.

### Notification Actions

Users can interact with notifications without opening the app:

- **Mark as Taken**: Records the dose as taken at the current time
- **Snooze 10 min**: Reschedules the reminder for 10 minutes later
- **Skip**: Marks the dose as skipped

All actions automatically create corresponding `DoseHistory` records.

## Usage

### Basic Setup

```swift
let notificationService = NotificationService()

// Request permission (do this once on app launch or onboarding)
let granted = try await notificationService.requestAuthorization()

if granted {
    // Schedule all notifications
    try await notificationService.scheduleAllNotifications()
}
```

### Check Authorization Status

```swift
let status = await notificationService.checkAuthorizationStatus()

switch status {
case .authorized:
    // Notifications enabled
case .denied:
    // Show settings prompt
case .notDetermined:
    // Request authorization
default:
    break
}
```

### Schedule Notifications for a Specific Schedule

```swift
let schedule = // ... fetch schedule
try await notificationService.scheduleNotifications(for: schedule, daysAhead: 7)
```

### Cancel Notifications

```swift
// Cancel for specific schedule
await notificationService.cancelNotifications(for: schedule)

// Cancel all notifications
notificationService.cancelAllNotifications()
```

### Handle Timezone Changes

Timezone changes are handled automatically. The service observes `TimezoneManager.timezoneDidChangeNotification` and reschedules all notifications when a change is detected.

## Integration

### With DoseHistoryService

When users interact with notification actions, the service automatically:
1. Creates a `DoseHistory` record for the scheduled dose
2. Updates the record based on the action (taken, skipped, etc.)
3. Saves the changes to Core Data

### With ScheduleService

The service fetches active schedules and uses their properties to:
- Determine when notifications should fire
- Calculate future notification dates
- Generate notification content

### With TimezoneManager

The service listens for timezone change events and reschedules all notifications to maintain correct local times across timezone transitions.

## Architecture

### Delegate Pattern

`NotificationService` implements `UNUserNotificationCenterDelegate` to handle:
- Foreground notification presentation
- User responses to notifications
- Action button taps

### Notification Identifiers

Notifications use unique identifiers based on:
- Schedule UUID
- Scheduled date and time

Format: `med-{scheduleID}-{yyyyMMdd-HHmm}`

This allows precise cancellation and prevents duplicate notifications.

### User Info Dictionary

Each notification includes:
- `scheduleID`: UUID of the schedule
- `medicationName`: Name of the medication
- `scheduledTime`: Unix timestamp of scheduled time

This data is used to create `DoseHistory` records when users respond to notifications.

## Error Handling

The service defines `NotificationError` enum for:
- `authorizationFailed(Error)`: Permission request failed
- `schedulingFailed(Error)`: Failed to schedule notification
- `invalidNotificationData`: Notification missing required data
- `scheduleNotFound`: Schedule no longer exists

## Best Practices

### Schedule Ahead Window

Default scheduling window is 7 days ahead. This balances:
- Ensuring timely notifications
- Avoiding excessive scheduled notifications
- Allowing for schedule changes

### Rescheduling After Changes

When schedules are modified, always:
1. Cancel old notifications for that schedule
2. Reschedule with new parameters

```swift
await notificationService.cancelNotifications(for: schedule)
try await notificationService.scheduleNotifications(for: schedule)
```

### Badge Management

Consider implementing badge count updates based on:
- Pending doses
- Overdue doses
- Unacknowledged notifications

## Limitations

### iOS Notification Limits

iOS has a limit of 64 pending notifications per app. The service:
- Schedules 7 days ahead by default to stay under this limit
- Requires periodic rescheduling (handled automatically)

### Background Execution

Notification scheduling requires:
- App to be launched at least once
- Background app refresh enabled
- Notification permission granted

## Testing Considerations

Testing notifications requires:
- Device or simulator (not just unit tests)
- Time-based testing (waiting for triggers)
- Manual verification of notification appearance

For automated testing, consider:
- Mocking `UNUserNotificationCenter`
- Testing business logic separately
- Integration tests for end-to-end flows

## Future Enhancements

Potential improvements:
- Customizable snooze duration
- Smart scheduling based on adherence patterns
- Notification grouping for multiple medications
- Rich notifications with images
- Custom notification sounds per medication
- Critical alerts for important medications
- Location-based reminders

## Related Components

- `DoseHistoryService`: Records dose events from notification actions
- `ScheduleService`: Provides schedule data for notification creation
- `TimezoneManager`: Notifies of timezone changes
- `PersistenceController`: Core Data stack access
