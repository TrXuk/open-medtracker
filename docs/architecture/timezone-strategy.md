# Timezone Handling Strategy

## Overview

Open MedTracker is designed for international travelers who need to maintain consistent medication schedules across time zones. This document outlines our comprehensive timezone handling strategy.

## Core Principles

### 1. UTC Storage with Reference Timezone

**Storage Rule**: All absolute timestamps are stored in UTC (Coordinated Universal Time).

**Reference Timezone Rule**: When a user creates a schedule with local times (e.g., "8:00 AM", "2:00 PM"), we store:
1. The reference timezone (IANA identifier) where the schedule was created
2. The local times as defined by the user
3. A clear association between the schedule and its timezone context

This approach allows us to:
- Calculate the next dose time accurately regardless of current timezone
- Preserve user intent ("I want to take medication at 8 AM local time")
- Support different timezone adjustment strategies during travel

### 2. Explicit Timezone Transitions

Rather than implicitly handling timezone changes, we:
- Explicitly detect and record timezone transitions (via `TimezoneEvent`)
- Prompt users to choose their preferred adjustment strategy
- Maintain a clear audit trail of when and how schedules were adjusted

### 3. Multiple Adjustment Strategies

Users can choose how their medication schedules adapt to timezone changes:

| Strategy | Description | Use Case | Example |
|----------|-------------|----------|---------|
| **Keep Local Time** | Maintain same local times in new timezone | Most common for daily medications | 8:00 AM EST → 8:00 AM PST (5 hour shift in UTC) |
| **Keep Absolute Time** | Maintain same UTC time | Critical medications with strict timing | 8:00 AM EST → 5:00 AM PST (same UTC) |
| **Gradual Shift** | Shift times gradually over days | Minimize disruption for long flights | 8:00 AM EST → 6:00 AM Day 1 → 7:00 AM Day 2 → 8:00 AM PST Day 3 |
| **Custom** | User manually adjusts times | Complex medication regimens | User-defined adjustment |

## Implementation Details

### Schedule Time Calculation

When calculating the next scheduled dose time, the system follows this algorithm:

```
function calculateNextDoseTime(schedule, currentDateTime, currentTimezone):
    if schedule.type == "timeBased":
        // Get reference timezone from schedule
        referenceTimezone = schedule.referenceTimezone

        // Convert current time to reference timezone
        currentTimeInRef = convertTimezone(currentDateTime, currentTimezone, referenceTimezone)

        // Find next scheduled time in reference timezone
        nextLocalTime = findNextScheduledTime(schedule.timeBasedSchedule.times, currentTimeInRef)

        // Convert back to UTC for storage
        nextDoseTimeUTC = convertToUTC(nextLocalTime, referenceTimezone)

        return nextDoseTimeUTC

    else if schedule.type == "intervalBased":
        // Interval-based is timezone-independent (pure duration)
        lastDoseTime = getLastDoseTime(schedule)
        intervalSeconds = schedule.intervalBasedSchedule.intervalHours * 3600
        nextDoseTimeUTC = lastDoseTime + intervalSeconds

        return nextDoseTimeUTC

    else if schedule.type == "asNeeded":
        // No scheduled time for as-needed medications
        return null
```

### Timezone Change Detection

The app monitors for timezone changes through multiple methods:

#### 1. Automatic Detection (Primary)
```swift
// iOS example using TimeZone
NotificationCenter.default.addObserver(
    forName: NSNotification.Name.NSSystemTimeZoneDidChange,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.handleTimezoneChange()
}
```

#### 2. Periodic Check (Backup)
```
Every app launch and every hour:
    currentDeviceTimezone = TimeZone.current.identifier
    if currentDeviceTimezone != lastRecordedTimezone:
        triggerTimezoneChangeFlow(currentDeviceTimezone)
```

#### 3. Manual Entry (User-Initiated)
Users can manually record timezone changes through the UI, useful when:
- Device timezone is not updated (e.g., flight mode)
- User wants to preemptively adjust before travel
- User wants to maintain home timezone temporarily

### Timezone Change Workflow

When a timezone change is detected:

```
1. Detect Change
   ├─ Get previous timezone (from last TimezoneEvent or device default)
   ├─ Get new timezone (current device timezone)
   └─ Record transition time (current UTC time)

2. User Confirmation
   ├─ Show notification: "Timezone change detected: EST → PST"
   ├─ Ask: "Update medication schedules?"
   └─ Wait for user response

3. If Confirmed:
   ├─ Create TimezoneEvent record
   ├─ For each active schedule:
   │   ├─ Present adjustment strategy options
   │   ├─ Calculate new times based on selected strategy
   │   ├─ Show before/after preview
   │   └─ Wait for confirmation
   │
   └─ Apply Adjustments:
       ├─ Update schedule.referenceTimezone (if keeping local time)
       ├─ Keep schedule.referenceTimezone same (if keeping absolute time)
       ├─ Create ScheduleAdjustment records
       └─ Recalculate upcoming notifications

4. If Declined:
   └─ Record TimezoneEvent with userConfirmed = false
      (may prompt again later or on next app launch)
```

### Edge Cases and Solutions

#### 1. Daylight Saving Time (DST) Transitions

**Challenge**: Local times shift during DST transitions.

**Solution**:
- Store schedules with IANA timezone identifiers (which handle DST)
- When converting local time to UTC, the timezone library handles DST automatically
- Example: "America/New_York" knows about EST/EDT transitions

```
Schedule: 8:00 AM in "America/New_York"
- Before DST (EST): 8:00 AM EST = 13:00 UTC
- After DST (EDT):  8:00 AM EDT = 12:00 UTC

System automatically recalculates based on date when computing next dose.
```

#### 2. International Date Line Crossing

**Challenge**: Date changes when crossing the International Date Line.

**Solution**:
- UTC storage prevents date confusion
- Display logic handles date rendering in local timezone
- Dose history maintains UTC timeline (no "lost" or "duplicate" doses)

#### 3. Schedule Created in Different Timezone Than Current

**Challenge**: User creates schedule while traveling.

**Solution**:
- Always store the timezone where schedule was created as `referenceTimezone`
- When displaying, show both:
  - Original times in reference timezone
  - Equivalent times in current timezone
- User can choose to "migrate" schedule to current timezone if desired

#### 4. Rapid Timezone Changes (Multiple Layovers)

**Challenge**: Multiple timezone transitions in short period.

**Solution**:
- Each TimezoneEvent is independent
- User can choose to delay schedule adjustments
- "Temporary timezone" option: acknowledge change but don't adjust schedules
- System asks: "You've traveled through 3 timezones today. Adjust schedules to final destination?"

#### 5. Ambiguous Times During DST "Fall Back"

**Challenge**: During "fall back," 1:30 AM occurs twice.

**Solution**:
- IANA timezone database disambiguates based on date
- Medication schedules unlikely to be during 1-2 AM window
- If user does schedule during this window, system uses first occurrence by default
- Edge case: If dose is due during the "repeated hour," mark as taken after first occurrence

## Data Flows

### Creating a Time-Based Schedule

```
User Action: "I want to take medication at 8:00 AM and 8:00 PM daily"

1. User Input
   ├─ times: ["08:00", "20:00"]
   └─ currentTimezone: "America/New_York"

2. System Processing
   ├─ Validate times format
   ├─ Get device timezone: "America/New_York"
   └─ Create Schedule:
       ├─ type: "timeBased"
       ├─ referenceTimezone: "America/New_York"
       ├─ timeBasedSchedule.times: ["08:00", "20:00"]
       └─ createdAt: 2026-02-01T15:30:00.000Z (UTC)

3. Notification Scheduling
   ├─ Calculate next 8:00 AM in America/New_York
   ├─ Convert to UTC: 13:00 UTC (assuming EST, not EDT)
   └─ Schedule local notification for that UTC time
```

### Recording a Dose

```
User Action: "Mark 8:00 AM dose as taken" (currently in Tokyo)

1. User Input
   ├─ Click "Take" on scheduled 8:00 AM dose
   └─ Current device timezone: "Asia/Tokyo"

2. System Processing
   ├─ Get current UTC time: 2026-02-01T23:00:00.000Z
   ├─ Get current device timezone: "Asia/Tokyo"
   └─ Create DoseHistory:
       ├─ medicationId: <uuid>
       ├─ scheduleId: <uuid>
       ├─ status: "taken"
       ├─ scheduledTime: 2026-02-01T13:00:00.000Z (UTC for 8 AM EST)
       ├─ actualTime: 2026-02-01T23:00:00.000Z (current UTC)
       ├─ recordedTimezone: "Asia/Tokyo"
       └─ createdAt: 2026-02-01T23:00:00.000Z

3. Display to User
   ├─ Scheduled: "8:00 AM EST" (from schedule's referenceTimezone)
   ├─ Taken: "8:00 AM JST" (converted from UTC to recordedTimezone)
   └─ Note: "10 hours late" (difference between scheduled and actual)
```

### Traveling from New York to Tokyo

```
Travel Event: User flies from New York (EST) to Tokyo (JST)

1. Detection
   ├─ Last timezone: "America/New_York" (UTC-5)
   ├─ New timezone: "Asia/Tokyo" (UTC+9)
   └─ Time difference: +14 hours

2. User Notification
   ├─ "Timezone changed: New York → Tokyo (+14 hours)"
   ├─ "You have 2 active medication schedules"
   └─ "How would you like to adjust?"

3. User Choice: "Keep Local Time" for both medications

4. System Adjustment
   For medication with schedule times ["08:00", "20:00"]:

   ├─ Create TimezoneEvent:
   │   ├─ previousTimezone: "America/New_York"
   │   ├─ newTimezone: "Asia/Tokyo"
   │   ├─ transitionTime: 2026-02-01T18:00:00.000Z
   │   └─ detectionMethod: "automatic"
   │
   ├─ Create ScheduleAdjustment:
   │   ├─ scheduleId: <uuid>
   │   ├─ strategy: "keepLocalTime"
   │   ├─ oldTimes: ["08:00", "20:00"] (in EST)
   │   └─ newTimes: ["08:00", "20:00"] (in JST)
   │
   └─ Update Schedule:
       ├─ referenceTimezone: "Asia/Tokyo" (changed)
       └─ timeBasedSchedule.times: ["08:00", "20:00"] (unchanged)

   Result: User still takes medication at 8 AM and 8 PM,
           but now in Tokyo time instead of New York time
```

## Best Practices for Developers

### 1. Never Use Device Local Time Directly
```swift
// ❌ BAD
let now = Date()
let formatter = DateFormatter()
formatter.dateFormat = "HH:mm"
let timeString = formatter.string(from: now)

// ✅ GOOD
let now = Date() // Always UTC
let timezone = TimeZone.current.identifier // Explicitly get timezone
let localTime = convertToLocalTime(now, timezone)
```

### 2. Always Store UTC, Convert for Display
```swift
// Storage
let doseHistory = DoseHistory(
    actualTime: Date(), // UTC
    recordedTimezone: TimeZone.current.identifier
)

// Display
func formatDoseTime(_ doseHistory: DoseHistory) -> String {
    let timezone = TimeZone(identifier: doseHistory.recordedTimezone)!
    let formatter = DateFormatter()
    formatter.timeZone = timezone
    formatter.dateFormat = "h:mm a zzz"
    return formatter.string(from: doseHistory.actualTime)
}
```

### 3. Test Across Timezones
```swift
func testScheduleCalculation() {
    let timezones = [
        "America/New_York",
        "Europe/London",
        "Asia/Tokyo",
        "Australia/Sydney",
        "Pacific/Auckland",
        "America/Los_Angeles"
    ]

    for tz in timezones {
        // Test schedule calculation in each timezone
        let result = calculateNextDose(schedule, timezone: tz)
        XCTAssertNotNil(result)
    }
}
```

### 4. Handle Timezone Initialization Gracefully
```swift
// Always have a fallback
func getScheduleTimezone(_ schedule: Schedule) -> TimeZone {
    if let tz = TimeZone(identifier: schedule.referenceTimezone) {
        return tz
    } else {
        // Log error but don't crash
        logger.error("Invalid timezone: \(schedule.referenceTimezone)")
        return TimeZone.current // Fallback to device timezone
    }
}
```

## Testing Strategy

### Unit Tests
- [ ] UTC conversion accuracy
- [ ] Local time formatting in various timezones
- [ ] Schedule time calculation across DST boundaries
- [ ] Timezone change adjustment calculations

### Integration Tests
- [ ] Full timezone change workflow
- [ ] Notification scheduling after timezone change
- [ ] Dose recording in different timezone than schedule
- [ ] Historical data display across timezone changes

### Manual Test Cases
1. Create schedule in New York, travel to London, verify times
2. Create schedule, wait for DST transition, verify times adjust
3. Cross International Date Line, verify dates are correct
4. Multiple rapid timezone changes (simulate multi-leg flight)
5. Schedule during DST "fall back" hour (1-2 AM)

## Migration Strategy

If updating from a system without proper timezone handling:

1. **Add referenceTimezone to existing schedules**
   - Default to user's current timezone
   - Or prompt user: "What timezone were these schedules created in?"

2. **Convert existing timestamps**
   - If stored as local times: convert to UTC using assumed timezone
   - Add migration flag to track which records were migrated

3. **Preserve historical data**
   - Don't modify existing DoseHistory records
   - Add disclaimer: "Timezone data not available for doses before [date]"

## Future Enhancements

1. **Smart Predictions**
   - Learn user's travel patterns
   - Suggest adjustment strategies based on history
   - Auto-detect frequent destinations

2. **Travel Mode**
   - Temporarily suspend automatic timezone changes
   - "I'm traveling but want to stay on home time"

3. **Multiple Timezone Display**
   - Show dose times in multiple timezones simultaneously
   - Useful for coordinating with doctor in home timezone

4. **Timezone Reminders**
   - "Don't forget to adjust your medication times" before travel
   - Integration with calendar for upcoming trips

## References

- [IANA Time Zone Database](https://www.iana.org/time-zones)
- [ISO 8601 Date and Time Format](https://www.iso.org/iso-8601-date-and-time-format.html)
- [UTC (Coordinated Universal Time)](https://en.wikipedia.org/wiki/Coordinated_Universal_Time)
- [Daylight Saving Time Transitions](https://en.wikipedia.org/wiki/Daylight_saving_time)
