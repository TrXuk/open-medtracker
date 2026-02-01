# Data Schema Reference

## Overview

This document provides a complete reference for the Open MedTracker data schema, including all tables, fields, constraints, and relationships suitable for database implementation.

## Schema Version

**Current Version**: 1.0.0
**Date**: 2026-02-01
**Status**: Initial Design

## Database Tables

### Table: `users`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique user identifier |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Account creation time (UTC) |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Last update time (UTC) |

**Indexes**:
- PRIMARY KEY on `id`
- UNIQUE INDEX on `email`

**Notes**:
- User table is minimal for now; expand with authentication fields as needed
- Consider adding: `name`, `phone`, `default_timezone`, `preferences_json`

---

### Table: `medications`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique medication identifier |
| `user_id` | UUID | NOT NULL, FOREIGN KEY → users(id) | Owning user |
| `name` | VARCHAR(255) | NOT NULL | Medication name |
| `generic_name` | VARCHAR(255) | NULL | Generic/chemical name |
| `dosage` | VARCHAR(100) | NOT NULL | Dosage amount (e.g., "10mg") |
| `form` | VARCHAR(50) | NOT NULL | Medication form (enum) |
| `instructions` | TEXT | NULL | Special instructions |
| `prescribed_by` | VARCHAR(255) | NULL | Prescribing physician |
| `purpose` | TEXT | NULL | Purpose of medication |
| `side_effects` | JSON | NULL | Array of side effect strings |
| `color` | VARCHAR(7) | NULL | Hex color code (e.g., "#FF5733") |
| `icon` | VARCHAR(50) | NULL | Icon identifier |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Active status |
| `start_date` | DATE | NOT NULL | Tracking start date |
| `end_date` | DATE | NULL | Tracking end date |
| `refill_reminder_enabled` | BOOLEAN | NOT NULL, DEFAULT FALSE | Refill reminder flag |
| `refill_total_quantity` | INTEGER | NULL | Total quantity in prescription |
| `refill_remaining_quantity` | INTEGER | NULL | Remaining quantity |
| `refill_reminder_threshold` | INTEGER | NULL | Remind when below this |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation (UTC) |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Last update (UTC) |
| `is_deleted` | BOOLEAN | NOT NULL, DEFAULT FALSE | Soft delete flag |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `user_id`
- INDEX on `is_active`
- INDEX on `start_date`
- COMPOSITE INDEX on `(user_id, is_active, is_deleted)`

**Foreign Keys**:
- `user_id` REFERENCES `users(id)` ON DELETE CASCADE

**Check Constraints**:
- `form` IN ('pill', 'capsule', 'liquid', 'injection', 'topical', 'inhaler', 'drops', 'patch', 'other')
- `color` MATCHES regex '^#[0-9A-Fa-f]{6}$' (if not null)
- `end_date` >= `start_date` (if not null)
- `refill_remaining_quantity` <= `refill_total_quantity` (if both not null)

---

### Table: `schedules`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique schedule identifier |
| `medication_id` | UUID | NOT NULL, FOREIGN KEY → medications(id) | Associated medication |
| `type` | VARCHAR(50) | NOT NULL | Schedule type (enum) |
| `reference_timezone` | VARCHAR(100) | NOT NULL | IANA timezone identifier |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Active status |
| `start_date` | DATE | NOT NULL | Schedule activation date |
| `end_date` | DATE | NULL | Schedule end date |
| `time_based_times` | JSON | NULL | Array of time strings ["08:00", "20:00"] |
| `time_based_days_of_week` | JSON | NULL | Array of integers [0,1,2,3,4,5,6] |
| `time_based_flexibility_minutes` | INTEGER | NULL | Minutes of flexibility |
| `interval_based_hours` | DECIMAL(5,2) | NULL | Hours between doses |
| `interval_based_first_dose_time` | TIMESTAMP | NULL | First dose anchor time (UTC) |
| `interval_based_max_doses_per_day` | INTEGER | NULL | Max doses per 24h |
| `as_needed_min_interval_hours` | DECIMAL(5,2) | NULL | Minimum hours between doses |
| `as_needed_max_doses_per_day` | INTEGER | NULL | Max doses per 24h |
| `as_needed_conditions` | JSON | NULL | Array of condition strings |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation (UTC) |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Last update (UTC) |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `medication_id`
- INDEX on `type`
- INDEX on `is_active`
- COMPOSITE INDEX on `(medication_id, is_active)`

**Foreign Keys**:
- `medication_id` REFERENCES `medications(id)` ON DELETE CASCADE

**Check Constraints**:
- `type` IN ('timeBased', 'intervalBased', 'asNeeded')
- `end_date` >= `start_date` (if not null)
- When `type` = 'timeBased': `time_based_times` IS NOT NULL
- When `type` = 'intervalBased': `interval_based_hours` IS NOT NULL AND `interval_based_first_dose_time` IS NOT NULL
- `interval_based_hours` > 0 (if not null)
- `time_based_flexibility_minutes` >= 0 (if not null)

**Validation Notes**:
- `reference_timezone` should be validated against IANA timezone database
- `time_based_times` elements should match format HH:mm (00:00 to 23:59)
- `time_based_days_of_week` elements should be 0-6

---

### Table: `dose_history`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique dose record identifier |
| `medication_id` | UUID | NOT NULL, FOREIGN KEY → medications(id) | Associated medication |
| `schedule_id` | UUID | NULL, FOREIGN KEY → schedules(id) | Associated schedule (null for as-needed) |
| `status` | VARCHAR(50) | NOT NULL | Dose status (enum) |
| `scheduled_time` | TIMESTAMP | NULL | Scheduled time (UTC) |
| `actual_time` | TIMESTAMP | NULL | Actual time taken (UTC) |
| `recorded_timezone` | VARCHAR(100) | NOT NULL | IANA timezone where recorded |
| `dosage_amount` | VARCHAR(100) | NULL | Actual dosage if different |
| `notes` | TEXT | NULL | User notes |
| `side_effects_reported` | JSON | NULL | Array of side effect strings |
| `location_latitude` | DECIMAL(10,8) | NULL | Latitude |
| `location_longitude` | DECIMAL(11,8) | NULL | Longitude |
| `location_city` | VARCHAR(255) | NULL | City name |
| `location_country` | VARCHAR(100) | NULL | Country name/code |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation (UTC) |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Last update (UTC) |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `medication_id`
- INDEX on `schedule_id`
- INDEX on `status`
- INDEX on `actual_time`
- COMPOSITE INDEX on `(medication_id, status, actual_time)`
- COMPOSITE INDEX on `(schedule_id, status, actual_time)`

**Foreign Keys**:
- `medication_id` REFERENCES `medications(id)` ON DELETE CASCADE
- `schedule_id` REFERENCES `schedules(id)` ON DELETE SET NULL

**Check Constraints**:
- `status` IN ('taken', 'skipped', 'missed', 'plannedSkip')
- When `status` = 'taken': `actual_time` IS NOT NULL
- `actual_time` <= CURRENT_TIMESTAMP (cannot be in future)
- `location_latitude` BETWEEN -90 AND 90 (if not null)
- `location_longitude` BETWEEN -180 AND 180 (if not null)
- Both `location_latitude` and `location_longitude` must be null or both must be non-null

**Immutability Notes**:
- Dose history records should be considered immutable after creation
- Updates should create new records rather than modifying existing ones
- Implement audit triggers if modification tracking is needed

---

### Table: `timezone_events`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique event identifier |
| `user_id` | UUID | NOT NULL, FOREIGN KEY → users(id) | User who experienced the change |
| `previous_timezone` | VARCHAR(100) | NOT NULL | IANA timezone before change |
| `new_timezone` | VARCHAR(100) | NOT NULL | IANA timezone after change |
| `transition_time` | TIMESTAMP | NOT NULL | When change occurred (UTC) |
| `detection_method` | VARCHAR(50) | NOT NULL | Detection method (enum) |
| `user_confirmed` | BOOLEAN | NOT NULL, DEFAULT FALSE | User confirmation flag |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation (UTC) |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `user_id`
- INDEX on `transition_time`
- COMPOSITE INDEX on `(user_id, transition_time DESC)`

**Foreign Keys**:
- `user_id` REFERENCES `users(id)` ON DELETE CASCADE

**Check Constraints**:
- `detection_method` IN ('automatic', 'manual', 'gps')
- `previous_timezone` != `new_timezone`
- `transition_time` <= CURRENT_TIMESTAMP

---

### Table: `schedule_adjustments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique adjustment identifier |
| `timezone_event_id` | UUID | NOT NULL, FOREIGN KEY → timezone_events(id) | Associated timezone event |
| `schedule_id` | UUID | NOT NULL, FOREIGN KEY → schedules(id) | Affected schedule |
| `strategy` | VARCHAR(50) | NOT NULL | Adjustment strategy (enum) |
| `old_times` | JSON | NULL | Previous scheduled times (local) |
| `new_times` | JSON | NULL | New scheduled times (local) |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation (UTC) |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `timezone_event_id`
- INDEX on `schedule_id`
- COMPOSITE INDEX on `(timezone_event_id, schedule_id)`

**Foreign Keys**:
- `timezone_event_id` REFERENCES `timezone_events(id)` ON DELETE CASCADE
- `schedule_id` REFERENCES `schedules(id)` ON DELETE CASCADE

**Check Constraints**:
- `strategy` IN ('keepLocalTime', 'keepAbsoluteTime', 'gradualShift', 'custom')

**Unique Constraints**:
- UNIQUE(`timezone_event_id`, `schedule_id`) - One adjustment per schedule per event

---

## Database Diagram (ERD)

```
┌─────────────────┐
│     users       │
├─────────────────┤
│ id (PK)         │
│ email           │
│ created_at      │
│ updated_at      │
└────────┬────────┘
         │
         │ 1:N
         │
    ┌────┴──────────────────────────┐
    │                               │
    │                               │
┌───▼──────────────┐      ┌─────────▼───────────┐
│  medications     │      │  timezone_events    │
├──────────────────┤      ├─────────────────────┤
│ id (PK)          │      │ id (PK)             │
│ user_id (FK)     │      │ user_id (FK)        │
│ name             │      │ previous_timezone   │
│ dosage           │      │ new_timezone        │
│ form             │      │ transition_time     │
│ is_active        │      │ detection_method    │
│ ...              │      │ user_confirmed      │
└───┬──────────────┘      └──┬──────────────────┘
    │                        │
    │ 1:N                    │ 1:N
    │                        │
┌───▼──────────────┐      ┌──▼──────────────────────┐
│  schedules       │      │  schedule_adjustments   │
├──────────────────┤      ├─────────────────────────┤
│ id (PK)          │◄─────┤ id (PK)                 │
│ medication_id(FK)│  1:N │ timezone_event_id (FK)  │
│ type             │      │ schedule_id (FK)        │
│ reference_tz     │      │ strategy                │
│ is_active        │      │ old_times               │
│ ...              │      │ new_times               │
└───┬──────────────┘      └─────────────────────────┘
    │
    │ 1:N
    │
┌───▼──────────────┐
│  dose_history    │
├──────────────────┤
│ id (PK)          │
│ medication_id(FK)│
│ schedule_id (FK) │
│ status           │
│ scheduled_time   │
│ actual_time      │
│ recorded_tz      │
│ ...              │
└──────────────────┘
```

## Data Types by Database

### PostgreSQL

```sql
-- UUID type
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Example table with PostgreSQL types
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    side_effects JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### SQLite (for iOS local storage)

```sql
-- UUID stored as TEXT
-- JSON stored as TEXT
CREATE TABLE medications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    side_effects TEXT, -- JSON as text
    created_at TEXT NOT NULL DEFAULT (datetime('now')), -- ISO 8601
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

### Core Data (iOS)

```swift
// Medication entity
@Entity(name: "Medication")
class Medication: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var userId: UUID
    @NSManaged var name: String
    @NSManaged var dosage: String
    @NSManaged var form: String
    @NSManaged var sideEffects: [String]? // Transformable
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date

    @NSManaged var user: User
    @NSManaged var schedules: Set<Schedule>
    @NSManaged var doseHistory: Set<DoseHistory>
}
```

## JSON Field Schemas

### medications.side_effects

```json
[
  "drowsiness",
  "nausea",
  "headache"
]
```

### schedules.time_based_times

```json
[
  "08:00",
  "14:00",
  "20:00"
]
```

### schedules.time_based_days_of_week

```json
[1, 2, 3, 4, 5]  // Monday through Friday
```

### schedules.as_needed_conditions

```json
[
  "headache",
  "pain level > 5",
  "anxiety"
]
```

### dose_history.side_effects_reported

```json
[
  "mild nausea",
  "dizziness"
]
```

### schedule_adjustments.old_times / new_times

```json
[
  "08:00",
  "20:00"
]
```

## Migration Scripts

### Initial Schema Creation (PostgreSQL)

```sql
-- Version 1.0.0: Initial schema
BEGIN;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Medications table
CREATE TABLE medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    generic_name VARCHAR(255),
    dosage VARCHAR(100) NOT NULL,
    form VARCHAR(50) NOT NULL CHECK (form IN ('pill', 'capsule', 'liquid', 'injection', 'topical', 'inhaler', 'drops', 'patch', 'other')),
    instructions TEXT,
    prescribed_by VARCHAR(255),
    purpose TEXT,
    side_effects JSONB,
    color VARCHAR(7) CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    icon VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE CHECK (end_date >= start_date),
    refill_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    refill_total_quantity INTEGER,
    refill_remaining_quantity INTEGER CHECK (refill_remaining_quantity <= refill_total_quantity),
    refill_reminder_threshold INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_medications_user_id ON medications(user_id);
CREATE INDEX idx_medications_is_active ON medications(is_active);
CREATE INDEX idx_medications_start_date ON medications(start_date);
CREATE INDEX idx_medications_user_active ON medications(user_id, is_active, is_deleted);

-- Schedules table
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('timeBased', 'intervalBased', 'asNeeded')),
    reference_timezone VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE CHECK (end_date >= start_date),
    time_based_times JSONB,
    time_based_days_of_week JSONB,
    time_based_flexibility_minutes INTEGER CHECK (time_based_flexibility_minutes >= 0),
    interval_based_hours DECIMAL(5,2) CHECK (interval_based_hours > 0),
    interval_based_first_dose_time TIMESTAMP WITH TIME ZONE,
    interval_based_max_doses_per_day INTEGER,
    as_needed_min_interval_hours DECIMAL(5,2),
    as_needed_max_doses_per_day INTEGER,
    as_needed_conditions JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_schedules_medication_id ON schedules(medication_id);
CREATE INDEX idx_schedules_type ON schedules(type);
CREATE INDEX idx_schedules_is_active ON schedules(is_active);
CREATE INDEX idx_schedules_medication_active ON schedules(medication_id, is_active);

-- Dose history table
CREATE TABLE dose_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES schedules(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('taken', 'skipped', 'missed', 'plannedSkip')),
    scheduled_time TIMESTAMP WITH TIME ZONE,
    actual_time TIMESTAMP WITH TIME ZONE CHECK (actual_time <= CURRENT_TIMESTAMP),
    recorded_timezone VARCHAR(100) NOT NULL,
    dosage_amount VARCHAR(100),
    notes TEXT,
    side_effects_reported JSONB,
    location_latitude DECIMAL(10,8) CHECK (location_latitude BETWEEN -90 AND 90),
    location_longitude DECIMAL(11,8) CHECK (location_longitude BETWEEN -180 AND 180),
    location_city VARCHAR(255),
    location_country VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK ((location_latitude IS NULL AND location_longitude IS NULL) OR (location_latitude IS NOT NULL AND location_longitude IS NOT NULL))
);

CREATE INDEX idx_dose_history_medication_id ON dose_history(medication_id);
CREATE INDEX idx_dose_history_schedule_id ON dose_history(schedule_id);
CREATE INDEX idx_dose_history_status ON dose_history(status);
CREATE INDEX idx_dose_history_actual_time ON dose_history(actual_time);
CREATE INDEX idx_dose_history_med_status_time ON dose_history(medication_id, status, actual_time);
CREATE INDEX idx_dose_history_sched_status_time ON dose_history(schedule_id, status, actual_time);

-- Timezone events table
CREATE TABLE timezone_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    previous_timezone VARCHAR(100) NOT NULL,
    new_timezone VARCHAR(100) NOT NULL CHECK (new_timezone != previous_timezone),
    transition_time TIMESTAMP WITH TIME ZONE NOT NULL CHECK (transition_time <= CURRENT_TIMESTAMP),
    detection_method VARCHAR(50) NOT NULL CHECK (detection_method IN ('automatic', 'manual', 'gps')),
    user_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_timezone_events_user_id ON timezone_events(user_id);
CREATE INDEX idx_timezone_events_transition_time ON timezone_events(transition_time);
CREATE INDEX idx_timezone_events_user_time ON timezone_events(user_id, transition_time DESC);

-- Schedule adjustments table
CREATE TABLE schedule_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timezone_event_id UUID NOT NULL REFERENCES timezone_events(id) ON DELETE CASCADE,
    schedule_id UUID NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
    strategy VARCHAR(50) NOT NULL CHECK (strategy IN ('keepLocalTime', 'keepAbsoluteTime', 'gradualShift', 'custom')),
    old_times JSONB,
    new_times JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(timezone_event_id, schedule_id)
);

CREATE INDEX idx_schedule_adjustments_tz_event ON schedule_adjustments(timezone_event_id);
CREATE INDEX idx_schedule_adjustments_schedule ON schedule_adjustments(schedule_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dose_history_updated_at BEFORE UPDATE ON dose_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;
```

## Data Retention Policies

### Active Data
- All active medications and schedules: Retained indefinitely
- Recent dose history (last 2 years): Retained in primary database

### Archival
- Dose history older than 2 years: Archive to cold storage, keep aggregated statistics
- Inactive medications after 1 year: Soft delete (is_deleted = true), retain for history
- Timezone events older than 1 year: Archive, keep summary statistics

### Deletion
- User requests deletion: Hard delete all user data after 30-day grace period
- Never delete: Aggregated, anonymized statistics

## Performance Considerations

### Query Optimization

1. **Upcoming doses query** (most frequent):
```sql
-- Find next scheduled dose for all active medications
SELECT m.id, m.name, s.id as schedule_id,
       -- Calculate next dose time logic here
FROM medications m
JOIN schedules s ON m.id = s.medication_id
WHERE m.user_id = ?
  AND m.is_active = true
  AND s.is_active = true
  AND m.is_deleted = false
```
**Optimization**: Composite index on `(user_id, is_active, is_deleted)`

2. **Recent dose history**:
```sql
-- Get dose history for last 30 days
SELECT * FROM dose_history
WHERE medication_id = ?
  AND actual_time >= NOW() - INTERVAL '30 days'
ORDER BY actual_time DESC
```
**Optimization**: Index on `(medication_id, actual_time)`

3. **Adherence statistics**:
```sql
-- Calculate adherence rate
SELECT
    COUNT(CASE WHEN status = 'taken' THEN 1 END)::float /
    COUNT(*)::float as adherence_rate
FROM dose_history
WHERE medication_id = ?
  AND actual_time >= NOW() - INTERVAL '30 days'
```
**Optimization**: Index on `(medication_id, status, actual_time)`

### Partitioning Strategy

For large datasets, consider partitioning `dose_history` by date:

```sql
-- Partition dose_history by month
CREATE TABLE dose_history (
    -- columns as before
) PARTITION BY RANGE (actual_time);

CREATE TABLE dose_history_2026_01 PARTITION OF dose_history
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE dose_history_2026_02 PARTITION OF dose_history
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- etc.
```

## Security Considerations

### Sensitive Data

Fields containing potentially sensitive information:
- `medications.name`, `medications.purpose`
- `dose_history.notes`, `dose_history.location_*`
- `medications.prescribed_by`

**Recommendations**:
- Encrypt at rest
- Implement field-level encryption for location data
- Use HTTPS/TLS for all data transmission
- Consider end-to-end encryption for notes

### Access Control

- Users can only access their own data (enforce via `user_id` filters)
- Implement row-level security (RLS) in PostgreSQL:

```sql
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY medications_user_policy ON medications
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::UUID);
```

## Backup Strategy

### Regular Backups
- Full database backup: Daily
- Incremental backup: Hourly
- Transaction log backup: Continuous

### Testing
- Restore test: Weekly
- Disaster recovery drill: Monthly

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-01 | Initial schema design |

## References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- SQLite Documentation: https://www.sqlite.org/docs.html
- Core Data Programming Guide: https://developer.apple.com/documentation/coredata
