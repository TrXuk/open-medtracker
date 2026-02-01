# Open MedTracker

Open source medication tracker with international travel support for iPhone.

## Overview

Open MedTracker helps international travelers maintain consistent medication schedules across time zones. The app features intelligent timezone handling, flexible schedule adjustment strategies, and complete dose history tracking.

## Key Features

- **Timezone-Aware Scheduling**: Automatically detect timezone changes and adjust medication schedules
- **Flexible Adjustment Strategies**: Choose how your schedules adapt to travel (keep local time, keep absolute time, gradual shift, or custom)
- **Complete History**: Track all doses taken with full timezone context
- **Offline-First**: All data stored locally, no internet required
- **Privacy-Focused**: Your medication data stays on your device

## Project Structure

```
OpenMedTracker/
├── CoreData/
│   ├── Model/                          # Core Data model definition
│   ├── Stack/                          # PersistenceController
│   ├── Validation/                     # Validation logic
│   └── Migrations/                     # Migration support
├── Models/                             # NSManagedObject subclasses
├── Services/
│   ├── Medication/                     # MedicationService
│   ├── Schedule/                       # ScheduleService
│   ├── DoseHistory/                    # DoseHistoryService
│   ├── TimezoneEvent/                  # TimezoneEventService
│   └── TimezoneManager.swift           # Timezone management
└── Views/
    ├── App/                            # Main app and ContentView
    ├── Medication/                     # Medication list, detail, form
    ├── Schedule/                       # Schedule view and form
    ├── DoseHistory/                    # Dose history view
    ├── Components/                     # Reusable UI components
    └── ViewModels/                     # MVVM view models

Tests/
└── OpenMedTrackerTests/
    └── TimezoneManagerTests.swift      # Comprehensive test suite
```

## Features Implemented

### Phase 1.5: SwiftUI Views ✅

Complete user interface implementation with:

- **Main App Structure**: TabView with three main tabs (Medications, Schedule, History)
- **Medication Management**:
  - List view with search and filtering
  - Detail view with complete medication information
  - Form for adding/editing medications
  - Swipe actions for quick operations
- **Schedule Management**:
  - Daily dose schedule view
  - Date navigation and selection
  - Quick dose logging (take, skip)
  - Schedule form with time picker and frequency options
- **Dose History**:
  - Complete history with status tracking
  - Adherence statistics and visualizations
  - Filtering by date range and status
  - Color-coded status badges
- **Reusable Components**:
  - Row views for lists
  - Status badges
  - Empty states, loading, and error views

See [UI Implementation Guide](./docs/UI_IMPLEMENTATION.md) for detailed documentation.

### Phase 2.1: Core Data Stack ✅

Complete data layer implementation:

- **Core Data Models**: Medication, Schedule, DoseHistory, TimezoneEvent
- **CRUD Services**: Full service layer for all entities
- **Data Validation**: Comprehensive validation with business rules
- **Migration Support**: Lightweight and progressive migration capabilities

See [Implementation Summary](./IMPLEMENTATION_SUMMARY.md) for details.

### Phase 2.3: TimezoneManager Service ✅

The TimezoneManager is a singleton service that provides:

- **Timezone Change Detection**: Monitors system timezone changes and notifies the app
- **Conversion Utilities**:
  - UTC ↔ Reference Timezone (default: UTC)
  - UTC ↔ Local Timezone
  - Local ↔ Reference Timezone
- **Logging**: Comprehensive logging of timezone changes and conversions
- **Extension Utilities**: Convenient extensions for TimeZone and Date types

#### Quick Start

```swift
// Access the shared instance
let manager = TimezoneManager.shared

// Convert medication time to UTC for storage
var components = DateComponents()
components.hour = 8  // 8 AM local time
components.minute = 0
let utcTime = manager.convertLocalToUTC(components)

// Convert back for display
let localComponents = manager.convertUTCToLocal(utcTime)

// Listen for timezone changes
NotificationCenter.default.addObserver(
    forName: TimezoneManager.timezoneDidChangeNotification,
    object: nil,
    queue: .main
) { notification in
    // Update medication schedules when timezone changes
}
```

See [TimezoneManager.md](OpenMedTracker/Services/TimezoneManager.md) for detailed documentation.

## Project Status

Currently in **Phase 1: Core Development**

- ✅ Phase 1.1: Project setup
- ✅ Phase 1.2: Architecture design
- ✅ Phase 1.3: Data layer implementation (Phase 2.1)
- ✅ Phase 1.4: Business logic (Phase 2.1 Services)
- ✅ Phase 1.5: UI implementation
- 🔜 Phase 1.6: Notification system
- 🔜 Phase 1.7: Testing and polish

## Documentation

### Architecture Documentation

Comprehensive documentation is available:

**Architecture & Design:**
- **[Architecture Overview](./docs/architecture/overview.md)** - High-level system architecture and design principles
- **[Data Models](./docs/architecture/data-models.md)** - Detailed specifications for Medication, Schedule, DoseHistory, and TimezoneEvent
- **[Timezone Strategy](./docs/architecture/timezone-strategy.md)** - Comprehensive timezone handling approach
- **[Data Schema](./docs/architecture/data-schema.md)** - Complete database schema reference

**Implementation:**
- **[UI Implementation Guide](./docs/UI_IMPLEMENTATION.md)** - Complete SwiftUI views documentation
- **[Implementation Summary](./IMPLEMENTATION_SUMMARY.md)** - Phase 2.1 Core Data implementation details
- **[TimezoneManager](./OpenMedTracker/Services/TimezoneManager.md)** - Timezone service documentation

Start with the [Architecture Overview](./docs/architecture/overview.md) to understand the system design.

## Development

### Testing

Run the test suite to verify timezone functionality:

```bash
swift test
```

### Examples

Check out `TimezoneManagerExample.swift` for comprehensive usage examples including:
- Basic medication scheduling
- International travel scenarios
- Timezone change handling
- Offset calculations

## Technology Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Architecture**: MVVM + Repository Pattern

## Roadmap

**Completed:**
- ✅ Phase 1.2: Architecture design
- ✅ Phase 2.1: Core Data stack (Models, Services, Validation, Migrations)
- ✅ Phase 2.3: TimezoneManager Service
- ✅ Phase 1.5: SwiftUI UI implementation

**Next Steps:**
- 🔜 Phase 1.6: Notification Service (Local notifications for dose reminders)
- 🔜 Phase 1.7: Testing and bug fixes
- 🔜 Phase 2.0: Beta testing and polish
- 🔜 Phase 3.0: Advanced features (Apple Watch, HealthKit, CloudKit)

## Contributing

This is an open-source project and contributions are welcome! Please read the [Architecture Documentation](./docs/architecture/) to understand the system design before contributing.

## License

TBD

## Contact

Issues and discussions: [GitHub Issues](https://github.com/your-org/open-medtracker/issues)
