# Architecture Overview

## Introduction

Open MedTracker is an iOS application designed to help users track medication schedules with robust support for international travel and timezone changes. This document provides a high-level overview of the system architecture, design principles, and key components.

## Project Vision

### Problem Statement

Travelers who take regular medications face significant challenges when crossing time zones:
- Confusion about when to take medications in the new timezone
- Risk of missed or doubled doses during transitions
- Difficulty maintaining consistent medication schedules
- Lack of tools that understand timezone complexities (DST, International Date Line, etc.)

### Solution

Open MedTracker provides:
- **Timezone-aware scheduling**: Intelligent handling of medication schedules across timezone changes
- **Flexible adjustment strategies**: Multiple options for how schedules adapt to travel
- **Clear audit trail**: Complete history of doses taken and timezone transitions
- **Travel-focused UX**: Designed specifically for the needs of international travelers

## Design Principles

### 1. Timezone Safety First

Every architectural decision prioritizes correct timezone handling:
- **UTC storage**: All absolute timestamps stored in UTC to prevent ambiguity
- **Reference timezone**: Local times stored with explicit timezone context
- **Explicit transitions**: Timezone changes are detected, recorded, and user-confirmed
- **No assumptions**: Never assume device timezone equals schedule timezone

See: [Timezone Strategy](./timezone-strategy.md)

### 2. Data Integrity and Auditability

Medical data requires the highest standards of integrity:
- **Immutable history**: Dose records are never modified, only created
- **Complete audit trail**: All timezone changes and schedule adjustments are logged
- **Timestamp everything**: All records include creation and update timestamps
- **Soft deletes**: Medications are marked inactive rather than deleted

See: [Data Schema](./data-schema.md)

### 3. User Control and Transparency

Users must understand and control their medication data:
- **Explicit consent**: Timezone changes require user confirmation
- **Multiple strategies**: Users choose how schedules adjust to timezone changes
- **Clear visualization**: Show both scheduled and actual times with timezone context
- **Privacy by design**: Sensitive data (location, notes) is optional

### 4. Offline-First Architecture

The app must work reliably without internet connectivity:
- **Local database**: All data stored locally on device using Core Data (iOS)
- **Background processing**: Notifications and reminders work offline
- **Sync when available**: Optional cloud sync for backup and multi-device support
- **No internet required**: Core functionality works completely offline

### 5. Simple, Focused Scope

Resist feature creep to maintain quality:
- **Core use case**: Medication tracking with timezone support
- **No medical advice**: App provides tracking, not medical recommendations
- **No social features**: Focus on individual user experience
- **Extensible foundation**: Architecture allows future expansion without redesign

## System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS Application                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │              │  │              │  │              │     │
│  │  UI Layer    │  │  Business    │  │  Data        │     │
│  │  (SwiftUI)   │  │  Logic       │  │  Layer       │     │
│  │              │  │              │  │  (Core Data) │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │             │
│         └─────────────────┴─────────────────┘             │
│                           │                               │
└───────────────────────────┼───────────────────────────────┘
                            │
                            ├─ Local Notifications (iOS)
                            ├─ Timezone Detection (iOS)
                            ├─ Location Services (optional)
                            └─ CloudKit Sync (future)
```

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
├─────────────────────────────────────────────────────────────┤
│  • MedicationListView                                       │
│  • MedicationDetailView                                     │
│  • ScheduleEditorView                                       │
│  • DoseHistoryView                                          │
│  • TimezoneAdjustmentView                                   │
│  • NotificationSettingsView                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Business Logic Layer                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ Medication      │  │ Timezone         │                 │
│  │ Manager         │  │ Manager          │                 │
│  │                 │  │                  │                 │
│  │ • Create/Edit   │  │ • Detect changes │                 │
│  │ • Activate      │  │ • Record events  │                 │
│  │ • Refill track  │  │ • Adjust schedules│                │
│  └─────────────────┘  └──────────────────┘                 │
│                                                             │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │ Schedule        │  │ Dose History     │                 │
│  │ Manager         │  │ Manager          │                 │
│  │                 │  │                  │                 │
│  │ • Calculate next│  │ • Record dose    │                 │
│  │ • Adjust times  │  │ • Query history  │                 │
│  │ • Validate      │  │ • Statistics     │                 │
│  └─────────────────┘  └──────────────────┘                 │
│                                                             │
│  ┌──────────────────────────────────────┐                  │
│  │ Notification Manager                 │                  │
│  │                                      │                  │
│  │ • Schedule notifications             │                  │
│  │ • Update on timezone change          │                  │
│  │ • Handle user actions                │                  │
│  └──────────────────────────────────────┘                  │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐                  │
│  │ Core Data Stack                      │                  │
│  │                                      │                  │
│  │ • Persistent Container               │                  │
│  │ • Managed Object Context             │                  │
│  │ • Data Models (see data-models.md)   │                  │
│  └──────────────────────────────────────┘                  │
│                                                             │
│  ┌──────────────────────────────────────┐                  │
│  │ Repository Pattern                   │                  │
│  │                                      │                  │
│  │ • MedicationRepository               │                  │
│  │ • ScheduleRepository                 │                  │
│  │ • DoseHistoryRepository              │                  │
│  │ • TimezoneEventRepository            │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Medication Manager

**Responsibilities**:
- CRUD operations for medications
- Validation of medication data
- Refill tracking and reminders
- Activation/deactivation of medications

**Key APIs**:
```swift
protocol MedicationManagerProtocol {
    func createMedication(_ data: MedicationData) async throws -> Medication
    func updateMedication(_ id: UUID, with data: MedicationData) async throws
    func getMedications(for userId: UUID, activeOnly: Bool) async throws -> [Medication]
    func deactivateMedication(_ id: UUID) async throws
    func updateRefillQuantity(_ id: UUID, quantity: Int) async throws
}
```

### 2. Schedule Manager

**Responsibilities**:
- Schedule creation and management
- Calculation of next dose times (timezone-aware)
- Schedule validation
- Adjustment after timezone changes

**Key APIs**:
```swift
protocol ScheduleManagerProtocol {
    func createSchedule(_ data: ScheduleData) async throws -> Schedule
    func updateSchedule(_ id: UUID, with data: ScheduleData) async throws
    func calculateNextDoseTime(for schedule: Schedule, after: Date, in timezone: TimeZone) -> Date?
    func adjustScheduleForTimezone(_ id: UUID, strategy: AdjustmentStrategy, newTimezone: TimeZone) async throws
    func getActiveSchedules(for medicationId: UUID) async throws -> [Schedule]
}
```

### 3. Timezone Manager

**Responsibilities**:
- Detect timezone changes
- Record timezone events
- Coordinate schedule adjustments
- Manage user confirmation workflow

**Key APIs**:
```swift
protocol TimezoneManagerProtocol {
    func detectTimezoneChange() async -> TimezoneChange?
    func recordTimezoneEvent(from: TimeZone, to: TimeZone, method: DetectionMethod) async throws -> TimezoneEvent
    func proposeScheduleAdjustments(for event: TimezoneEvent) async throws -> [ScheduleAdjustmentProposal]
    func applyAdjustments(_ adjustments: [ScheduleAdjustment]) async throws
}
```

### 4. Dose History Manager

**Responsibilities**:
- Record dose events (taken, skipped, missed)
- Query dose history
- Calculate adherence statistics
- Generate reports

**Key APIs**:
```swift
protocol DoseHistoryManagerProtocol {
    func recordDose(_ data: DoseData) async throws -> DoseHistory
    func getDoseHistory(for medicationId: UUID, from: Date, to: Date) async throws -> [DoseHistory]
    func calculateAdherence(for medicationId: UUID, period: DateInterval) async throws -> AdherenceStatistics
    func getMissedDoses(for userId: UUID) async throws -> [DoseHistory]
}
```

### 5. Notification Manager

**Responsibilities**:
- Schedule local notifications for doses
- Update notifications after timezone changes
- Handle notification responses
- Badge count management

**Key APIs**:
```swift
protocol NotificationManagerProtocol {
    func scheduleNotifications(for schedule: Schedule) async throws
    func cancelNotifications(for scheduleId: UUID) async throws
    func updateNotificationsAfterTimezoneChange() async throws
    func handleNotificationResponse(_ response: UNNotificationResponse) async
}
```

## Data Flow Examples

### Creating a New Medication with Schedule

```
1. User Input (UI)
   └─> MedicationDetailView
       • Name: "Lisinopril"
       • Dosage: "10mg"
       • Times: ["08:00", "20:00"]

2. Business Logic
   └─> MedicationManager.createMedication()
       ├─> Validate input data
       ├─> Create Medication record
       └─> Return medication ID

   └─> ScheduleManager.createSchedule()
       ├─> Validate schedule times
       ├─> Get current timezone
       ├─> Create Schedule record with referenceTimezone
       └─> Return schedule ID

3. Notifications
   └─> NotificationManager.scheduleNotifications()
       ├─> Calculate next dose times (in UTC)
       ├─> Create UNNotificationRequest for each time
       └─> Register with UNUserNotificationCenter

4. Data Layer
   └─> Core Data
       ├─> Insert Medication entity
       ├─> Insert Schedule entity
       └─> Save context

5. UI Update
   └─> MedicationListView refreshes
       └─> Shows new medication with next dose time
```

### Taking a Scheduled Dose

```
1. Notification
   └─> User taps notification "Time to take Lisinopril (10mg)"

2. App Opens
   └─> NotificationManager.handleNotificationResponse()
       ├─> Extract medication and schedule IDs
       └─> Navigate to dose confirmation screen

3. User Confirms
   └─> DoseHistoryManager.recordDose()
       ├─> Get current UTC time
       ├─> Get current timezone
       ├─> Create DoseHistory record:
       │   • status: "taken"
       │   • actualTime: <current UTC>
       │   • recordedTimezone: <current timezone>
       │   • scheduledTime: <from notification>
       └─> Save to database

4. Side Effects
   └─> MedicationManager.updateRefillQuantity()
       ├─> Decrement remaining quantity
       └─> Check if below reminder threshold

   └─> NotificationManager.updateBadgeCount()
       └─> Recalculate number of pending doses

5. UI Update
   └─> DoseHistoryView refreshes
       └─> Shows newly recorded dose with timestamp
```

### Crossing Time Zones

```
1. Detection
   └─> TimezoneManager (running in background)
       ├─> Monitors TimeZone.current
       ├─> Detects change: EST → PST
       └─> Triggers timezone change workflow

2. User Notification
   └─> TimezoneAdjustmentView appears
       ├─> "Timezone changed: New York → Los Angeles (-3 hours)"
       ├─> "You have 2 active medications"
       └─> "How would you like to adjust schedules?"

3. User Selects Strategy
   └─> For each schedule:
       ├─> User chooses "Keep Local Time"
       └─> Shows preview:
           • Old: 8:00 AM EST, 8:00 PM EST
           • New: 8:00 AM PST, 8:00 PM PST
           • Note: "Times shift 3 hours earlier in UTC"

4. Apply Adjustments
   └─> TimezoneManager.recordTimezoneEvent()
       ├─> Create TimezoneEvent record
       └─> For each schedule:
           ├─> Create ScheduleAdjustment record
           ├─> Update Schedule.referenceTimezone to "America/Los_Angeles"
           └─> Times remain ["08:00", "20:00"] but now in PST

5. Update Notifications
   └─> NotificationManager.updateNotificationsAfterTimezoneChange()
       ├─> Cancel all scheduled notifications
       ├─> Recalculate dose times in new timezone
       └─> Schedule new notifications

6. Confirmation
   └─> UI shows success message
       └─> "2 medication schedules adjusted to Pacific Time"
```

## Technology Stack

### iOS Application

| Component | Technology | Rationale |
|-----------|------------|-----------|
| UI Framework | SwiftUI | Modern, declarative, native iOS |
| Data Persistence | Core Data | Offline-first, robust, iOS-native |
| Notifications | UNUserNotificationCenter | Local notifications, no server needed |
| Timezone Handling | Foundation TimeZone | Native IANA timezone support |
| Architecture Pattern | MVVM + Repository | Clean separation, testable |
| Async/Await | Swift Concurrency | Modern, safe concurrency |

### Development Tools

- **Xcode**: Primary IDE
- **Swift**: Programming language (Swift 5.9+)
- **iOS SDK**: Target iOS 17+ for latest features
- **Git**: Version control
- **GitHub**: Repository hosting, issue tracking

### Testing

- **XCTest**: Unit and integration tests
- **XCUITest**: UI automation tests
- **Manual Testing**: Timezone scenarios, edge cases

## Security & Privacy

### Data Security

1. **Local Storage Encryption**
   - Core Data uses iOS Data Protection
   - Files encrypted at rest on device
   - Keychain for sensitive credentials

2. **Privacy Controls**
   - Location data is optional
   - No analytics without consent
   - No third-party data sharing

3. **Access Control**
   - Biometric authentication (Face ID / Touch ID) optional
   - App lock after timeout

### Compliance

- **HIPAA**: Not a covered entity, but following best practices
- **GDPR**: User data export and deletion
- **Privacy Policy**: Clear disclosure of data usage

## Performance Considerations

### Database Optimization

- **Indexes**: Strategic indexes on frequently queried fields (see data-schema.md)
- **Fetch Requests**: Batch size limits, predicates, and fault minimization
- **Background Contexts**: Long-running operations on background contexts
- **Partitioning**: Consider partitioning large dose_history table

### Memory Management

- **Lazy Loading**: Load detailed data only when needed
- **Pagination**: Paginate long lists (e.g., dose history)
- **Image Assets**: Use asset catalogs, appropriate resolutions

### Battery Efficiency

- **Background Refresh**: Minimal background processing
- **Location Services**: Only when explicitly needed
- **Notifications**: Efficient scheduling, batch updates

## Testing Strategy

### Unit Tests

Test individual components in isolation:
- Timezone conversion logic
- Schedule calculation algorithms
- Data validation
- Adherence statistics calculations

### Integration Tests

Test component interactions:
- Medication creation workflow
- Timezone change workflow
- Dose recording and notification updates

### UI Tests

Test user flows:
- Create medication and schedule
- Record doses
- Adjust schedules after timezone change
- View dose history

### Edge Case Testing

Critical scenarios to test:
- DST transitions
- International Date Line crossing
- Rapid timezone changes (multiple layovers)
- Schedule during DST "fall back" hour
- First app launch in different timezone than schedule creation
- Offline operation

## Deployment & Distribution

### App Store

- **Distribution**: Apple App Store
- **Pricing**: Free (consider premium features later)
- **Target**: iOS 17+ (iPhone and iPad)

### Beta Testing

- **TestFlight**: Internal and external testing
- **Beta Testers**: Focus on international travelers
- **Feedback Channels**: GitHub issues, in-app feedback

## Future Enhancements

### Phase 2 (Post-MVP)

1. **Cloud Sync**
   - CloudKit integration
   - Multi-device support
   - Backup and restore

2. **Apple Watch**
   - Watchface complication (next dose)
   - Quick dose logging
   - Watch notifications

3. **Health App Integration**
   - Export dose history to Health app
   - Import medication data from Health

### Phase 3 (Future)

1. **Advanced Features**
   - Medication interaction checking
   - Photo identification of pills
   - Medication barcode scanning
   - Prescription import

2. **Analytics & Insights**
   - Adherence trends
   - Side effect correlations
   - Time-of-day effectiveness

3. **Sharing & Collaboration**
   - Share with caregivers
   - Export reports for doctor
   - Family medication management

## Development Roadmap

### Phase 1: Core Functionality (Current)

- [x] Phase 1.1: Project setup and requirements
- [ ] **Phase 1.2: Architecture design** (This document)
- [ ] Phase 1.3: Data layer implementation (Core Data models)
- [ ] Phase 1.4: Business logic implementation
- [ ] Phase 1.5: UI implementation
- [ ] Phase 1.6: Notification system
- [ ] Phase 1.7: Testing and bug fixes

### Phase 2: Polish & Beta

- [ ] Phase 2.1: UI/UX refinement
- [ ] Phase 2.2: Edge case handling
- [ ] Phase 2.3: Performance optimization
- [ ] Phase 2.4: Beta testing
- [ ] Phase 2.5: Bug fixes and iteration

### Phase 3: Release

- [ ] Phase 3.1: App Store submission
- [ ] Phase 3.2: Marketing materials
- [ ] Phase 3.3: Launch
- [ ] Phase 3.4: Post-launch support

## Contributing

This is an open-source project. Contributions are welcome!

### Development Setup

1. Clone the repository
2. Open in Xcode
3. Build and run on simulator or device

### Code Standards

- Swift style guide: [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- SwiftLint for code quality
- Comprehensive unit tests for business logic
- UI tests for critical user flows

### Documentation

- Code comments for complex logic
- Update architecture docs when making structural changes
- Maintain CHANGELOG.md

## Conclusion

Open MedTracker is designed from the ground up to solve the unique challenges of medication tracking during international travel. The architecture prioritizes:

1. **Correctness**: Robust timezone handling ensures doses are never missed or doubled
2. **User Control**: Clear choices and transparency in how schedules adapt
3. **Privacy**: User data stays on device, no unnecessary tracking
4. **Reliability**: Offline-first design works anywhere
5. **Simplicity**: Focused on core use case, avoiding feature creep

This foundation supports immediate needs while allowing for future expansion.

## Document Index

- [Data Models](./data-models.md) - Detailed data model specifications
- [Timezone Strategy](./timezone-strategy.md) - Comprehensive timezone handling approach
- [Data Schema](./data-schema.md) - Database schema and implementation details
- [Architecture Overview](./overview.md) - This document

---

**Last Updated**: 2026-02-01
**Version**: 1.0.0
**Author**: Open MedTracker Team
