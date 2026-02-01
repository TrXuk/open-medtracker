# OpenMedTracker Core Data Model

## Overview
This document describes the Core Data entities for the OpenMedTracker application, which helps users track medications with international travel support.

## Entities

### Medication
Represents a medication that the user is taking.

**Attributes:**
- `id` (UUID) - Unique identifier
- `name` (String) - Name of the medication
- `dosageAmount` (Double) - Amount per dose (e.g., 500 for 500mg)
- `dosageUnit` (String) - Unit of measurement (e.g., "mg", "ml", "tablet")
- `instructions` (String, optional) - Instructions for taking the medication
- `prescribedBy` (String, optional) - Name of the prescribing doctor
- `startDate` (Date) - When the user started taking this medication
- `endDate` (Date, optional) - When the user stopped or should stop taking this medication
- `isActive` (Bool) - Whether the medication is currently being taken
- `createdAt` (Date) - Record creation timestamp
- `updatedAt` (Date) - Record last update timestamp

**Relationships:**
- `schedules` (one-to-many to Schedule) - When this medication should be taken

**Deletion Rule:** Cascade to schedules (deleting a medication deletes its schedules)

---

### Schedule
Represents when a medication should be taken.

**Attributes:**
- `id` (UUID) - Unique identifier
- `timeOfDay` (Date) - Time when medication should be taken (time component used)
- `frequency` (String) - How often to take (e.g., "daily", "weekly", "as-needed")
- `daysOfWeek` (Int16) - Bitmask for days of week (bit 0 = Sunday, bit 6 = Saturday)
- `isEnabled` (Bool) - Whether this schedule is active
- `createdAt` (Date) - Record creation timestamp
- `updatedAt` (Date) - Record last update timestamp

**Relationships:**
- `medication` (many-to-one to Medication) - The medication this schedule is for
- `doseHistories` (one-to-many to DoseHistory) - History of doses for this schedule

**Deletion Rule:**
- Nullify medication reference
- Cascade to doseHistories

---

### DoseHistory
Represents a record of a dose (taken, missed, or skipped).

**Attributes:**
- `id` (UUID) - Unique identifier
- `scheduledTime` (Date) - When the dose was scheduled to be taken
- `actualTime` (Date, optional) - When the dose was actually taken
- `status` (String) - Status of the dose: "pending", "taken", "missed", "skipped"
- `notes` (String, optional) - User notes about this dose
- `timezoneIdentifier` (String) - Timezone where the dose was scheduled/taken
- `createdAt` (Date) - Record creation timestamp

**Relationships:**
- `schedule` (many-to-one to Schedule) - The schedule this dose belongs to
- `timezoneEvent` (many-to-one to TimezoneEvent, optional) - Associated timezone change event

**Deletion Rule:** Nullify references

---

### TimezoneEvent
Represents a timezone change event (e.g., international travel).

**Attributes:**
- `id` (UUID) - Unique identifier
- `previousTimezone` (String) - Timezone identifier before the change
- `newTimezone` (String) - Timezone identifier after the change
- `transitionTime` (Date) - When the timezone change occurred
- `location` (String, optional) - Location description (e.g., "Tokyo, Japan")
- `notes` (String, optional) - User notes about this event
- `createdAt` (Date) - Record creation timestamp

**Relationships:**
- `affectedDoses` (one-to-many to DoseHistory) - Doses affected by this timezone change

**Deletion Rule:** Nullify to affectedDoses (doses remain but lose timezone event reference)

---

## Relationship Graph

```
Medication (1) ←──→ (N) Schedule (1) ←──→ (N) DoseHistory (N) ←──→ (1) TimezoneEvent
```

## Status Values

### DoseHistory.status
- `"pending"` - Dose is scheduled but not yet due
- `"taken"` - Dose was taken
- `"missed"` - Dose was not taken and is past due
- `"skipped"` - User intentionally skipped the dose

### Schedule.frequency
- `"daily"` - Every day
- `"weekly"` - Once per week
- `"as-needed"` - No fixed schedule

## Days of Week Bitmask (Schedule.daysOfWeek)

```
Bit 0 (1)   = Sunday
Bit 1 (2)   = Monday
Bit 2 (4)   = Tuesday
Bit 3 (8)   = Wednesday
Bit 4 (16)  = Thursday
Bit 5 (32)  = Friday
Bit 6 (64)  = Saturday

Example: 127 (all bits set) = Every day
Example: 62 (bits 1-5) = Monday-Friday
```

## Version History

- **1.0** - Initial model with Medication, Schedule, DoseHistory, and TimezoneEvent entities
