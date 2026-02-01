# Core Data Models

## Overview

This document defines the core data models for the Open MedTracker application. These models are designed to support medication tracking with robust timezone handling for international travelers.

## Data Models

### 1. Medication

The `Medication` model represents a medication that a user is tracking.

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier for the medication |
| `userId` | UUID | Yes | Reference to the user who owns this medication |
| `name` | String | Yes | Name of the medication (e.g., "Lisinopril", "Vitamin D") |
| `genericName` | String | No | Generic/chemical name if different from brand name |
| `dosage` | String | Yes | Dosage amount (e.g., "10mg", "500mg", "1 tablet") |
| `form` | MedicationForm | Yes | Form of medication (pill, liquid, injection, etc.) |
| `instructions` | String | No | Special instructions (e.g., "Take with food") |
| `prescribedBy` | String | No | Prescribing physician name |
| `purpose` | String | No | What the medication is for |
| `sideEffects` | [String] | No | List of known side effects to monitor |
| `color` | String | No | Color code for UI display (hex format) |
| `icon` | String | No | Icon identifier for UI display |
| `isActive` | Boolean | Yes | Whether this medication is currently active |
| `startDate` | Date | Yes | Date when medication tracking started |
| `endDate` | Date | No | Date when medication was stopped (if applicable) |
| `refillReminder` | RefillReminder | No | Settings for refill reminders |
| `createdAt` | DateTime (UTC) | Yes | When this record was created |
| `updatedAt` | DateTime (UTC) | Yes | When this record was last updated |

#### Enums

**MedicationForm**
- `pill`
- `capsule`
- `liquid`
- `injection`
- `topical`
- `inhaler`
- `drops`
- `patch`
- `other`

#### Nested Types

**RefillReminder**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `enabled` | Boolean | Yes | Whether refill reminders are enabled |
| `totalQuantity` | Number | No | Total pills/doses in prescription |
| `remainingQuantity` | Number | No | Current remaining quantity |
| `reminderThreshold` | Number | No | Remind when quantity drops below this |

---

### 2. Schedule

The `Schedule` model defines when a medication should be taken. Multiple schedules can exist for a single medication.

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier for the schedule |
| `medicationId` | UUID | Yes | Reference to the associated medication |
| `type` | ScheduleType | Yes | Type of schedule (time-based, interval-based, etc.) |
| `referenceTimezone` | String | Yes | IANA timezone identifier when schedule was created (e.g., "America/New_York") |
| `timeBasedSchedule` | TimeBasedSchedule | Conditional | Required if type is `timeBased` |
| `intervalBasedSchedule` | IntervalBasedSchedule | Conditional | Required if type is `intervalBased` |
| `asNeededSchedule` | AsNeededSchedule | Conditional | Required if type is `asNeeded` |
| `isActive` | Boolean | Yes | Whether this schedule is currently active |
| `startDate` | Date | Yes | When this schedule becomes active |
| `endDate` | Date | No | When this schedule ends (if applicable) |
| `createdAt` | DateTime (UTC) | Yes | When this record was created |
| `updatedAt` | DateTime (UTC) | Yes | When this record was last updated |

#### Enums

**ScheduleType**
- `timeBased` - Specific times of day (e.g., 8:00 AM, 2:00 PM, 8:00 PM)
- `intervalBased` - Every X hours (e.g., every 6 hours)
- `asNeeded` - PRN (as needed), no fixed schedule

#### Nested Types

**TimeBasedSchedule**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `times` | [LocalTime] | Yes | Array of times in 24-hour format (e.g., ["08:00", "14:00", "20:00"]) |
| `daysOfWeek` | [DayOfWeek] | No | If specified, only applies on these days (0=Sunday, 6=Saturday) |
| `flexibilityMinutes` | Number | No | How many minutes before/after the scheduled time is acceptable |

**IntervalBasedSchedule**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `intervalHours` | Number | Yes | Hours between doses (e.g., 6 for "every 6 hours") |
| `firstDoseTime` | DateTime (UTC) | Yes | When the first dose should be taken (anchors the interval) |
| `maxDosesPerDay` | Number | No | Maximum number of doses allowed in 24 hours |

**AsNeededSchedule**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `minIntervalHours` | Number | No | Minimum hours between doses |
| `maxDosesPerDay` | Number | No | Maximum number of doses allowed in 24 hours |
| `conditions` | [String] | No | Conditions when it should be taken (e.g., ["headache", "pain"]) |

---

### 3. DoseHistory

The `DoseHistory` model records each time a medication dose is taken, skipped, or missed.

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier for this dose record |
| `medicationId` | UUID | Yes | Reference to the medication |
| `scheduleId` | UUID | No | Reference to the schedule (null for as-needed doses) |
| `status` | DoseStatus | Yes | Status of the dose |
| `scheduledTime` | DateTime (UTC) | No | When the dose was scheduled (null for as-needed) |
| `actualTime` | DateTime (UTC) | Conditional | When the dose was actually taken (required if status is `taken`) |
| `recordedTimezone` | String | Yes | IANA timezone where the dose was recorded (e.g., "Europe/London") |
| `dosageAmount` | String | No | Actual dosage if different from medication default |
| `notes` | String | No | User notes about this dose |
| `sideEffectsReported` | [String] | No | Any side effects experienced |
| `location` | GeoLocation | No | Location where dose was taken (optional privacy feature) |
| `createdAt` | DateTime (UTC) | Yes | When this record was created |
| `updatedAt` | DateTime (UTC) | Yes | When this record was last updated |

#### Enums

**DoseStatus**
- `taken` - Dose was taken
- `skipped` - User consciously skipped the dose
- `missed` - Scheduled dose was not taken (system marked)
- `plannedSkip` - User pre-marked to skip (e.g., before surgery)

#### Nested Types

**GeoLocation**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `latitude` | Number | Yes | Latitude coordinate |
| `longitude` | Number | Yes | Longitude coordinate |
| `city` | String | No | City name (derived or user-entered) |
| `country` | String | No | Country name or code |

---

### 4. TimezoneEvent

The `TimezoneEvent` model tracks timezone changes to maintain accurate medication schedules during travel.

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier for this timezone event |
| `userId` | UUID | Yes | Reference to the user |
| `previousTimezone` | String | Yes | IANA timezone identifier before the change |
| `newTimezone` | String | Yes | IANA timezone identifier after the change |
| `transitionTime` | DateTime (UTC) | Yes | When the timezone change occurred |
| `detectionMethod` | DetectionMethod | Yes | How the change was detected |
| `userConfirmed` | Boolean | Yes | Whether user confirmed the timezone change |
| `scheduleAdjustments` | [ScheduleAdjustment] | No | Record of how schedules were adjusted |
| `createdAt` | DateTime (UTC) | Yes | When this record was created |

#### Enums

**DetectionMethod**
- `automatic` - System detected based on device timezone
- `manual` - User manually recorded timezone change
- `gps` - Detected via GPS location change

#### Nested Types

**ScheduleAdjustment**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `scheduleId` | UUID | Yes | Reference to the affected schedule |
| `strategy` | AdjustmentStrategy | Yes | How the schedule was adjusted |
| `oldTimes` | [String] | No | Previous scheduled times (local) |
| `newTimes` | [String] | No | New scheduled times (local) |

**AdjustmentStrategy** (enum)
- `keepLocalTime` - Maintain same local times (e.g., 8:00 AM in both timezones)
- `keepAbsoluteTime` - Maintain same UTC time (times shift in local timezone)
- `gradualShift` - Gradually shift times over several days
- `custom` - User-defined adjustment

---

## Relationships

### Entity Relationship Diagram

```
User
 |
 +-- Medication (1:N)
      |
      +-- Schedule (1:N)
      |    |
      |    +-- DoseHistory (1:N, via medicationId and scheduleId)
      |
      +-- DoseHistory (1:N, direct for as-needed doses)

User
 |
 +-- TimezoneEvent (1:N)
      |
      +-- ScheduleAdjustment (1:N)
           |
           +-- Schedule (references via scheduleId)
```

### Key Relationships

1. **User → Medication**: One-to-Many
   - A user can have multiple medications

2. **Medication → Schedule**: One-to-Many
   - A medication can have multiple schedules (e.g., different schedules for weekdays/weekends, or schedule changes over time)

3. **Schedule → DoseHistory**: One-to-Many
   - A schedule generates multiple dose history records over time

4. **Medication → DoseHistory**: One-to-Many
   - As-needed medications have dose history without a schedule

5. **User → TimezoneEvent**: One-to-Many
   - A user's timezone changes are tracked over time

6. **TimezoneEvent → Schedule**: Many-to-Many (via ScheduleAdjustment)
   - A timezone change can affect multiple schedules
   - A schedule can be affected by multiple timezone changes over time

---

## Design Principles

### 1. Timezone Safety
- All timestamps stored in UTC
- Local times stored with reference timezone
- Timezone context always preserved

### 2. Schedule Flexibility
- Support for multiple schedule types
- Active/inactive flags for schedule management
- Historical schedule preservation

### 3. Audit Trail
- All modifications tracked via `createdAt`/`updatedAt`
- Dose history is immutable (updates create new records)
- Timezone changes explicitly recorded

### 4. Privacy by Design
- Location data is optional
- User controls what data is collected
- Sensitive information (prescriber, purpose) is optional

### 5. Extensibility
- Enum types allow for future additions
- Nested types can be expanded
- Foreign key relationships support future features

---

## Implementation Notes

### Storage Format

- **Dates**: ISO 8601 date format (YYYY-MM-DD)
- **DateTimes**: ISO 8601 with UTC timezone (YYYY-MM-DDTHH:mm:ss.sssZ)
- **LocalTime**: 24-hour format string (HH:mm)
- **Timezone**: IANA timezone database identifiers
- **UUID**: RFC 4122 v4 format

### Validation Rules

1. **Medication.dosage**: Non-empty string, recommended format: "{number}{unit}"
2. **Schedule.times**: Each time must be valid 24-hour format (00:00 to 23:59)
3. **Schedule.referenceTimezone**: Must be valid IANA timezone
4. **DoseHistory.actualTime**: Cannot be in the future
5. **TimezoneEvent.transitionTime**: Should be recent (within reasonable bounds)

### Indexes

Recommended database indexes for performance:

- `Medication`: `userId`, `isActive`, `startDate`
- `Schedule`: `medicationId`, `isActive`, `type`
- `DoseHistory`: `medicationId`, `scheduleId`, `status`, `actualTime`
- `TimezoneEvent`: `userId`, `transitionTime`

### Soft Deletes

Consider implementing soft deletes (is_deleted flag) for:
- Medications (preserve history even after deletion)
- Schedules (maintain dose history integrity)

DoseHistory and TimezoneEvent should never be deleted (immutable audit trail).
