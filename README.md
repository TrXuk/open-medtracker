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
├── Services/
│   ├── TimezoneManager.swift          # Core timezone management service
│   ├── TimezoneManager.md             # Detailed documentation
│   └── TimezoneManagerExample.swift   # Usage examples
├── Models/                             # (Coming soon)
└── Utilities/                          # (Coming soon)

Tests/
└── OpenMedTrackerTests/
    └── TimezoneManagerTests.swift      # Comprehensive test suite
```

## Features Implemented

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

Currently in **Phase 1: Architecture & Design**

- ✅ Phase 1.1: Project setup
- ✅ Phase 1.2: Architecture design
- ⏳ Phase 1.3: Data layer implementation
- ⏳ Phase 1.4: Business logic
- ⏳ Phase 1.5: UI implementation

## Documentation

### Architecture Documentation

Comprehensive architecture documentation is available in [`docs/architecture/`](./docs/architecture/):

- **[Overview](./docs/architecture/overview.md)** - High-level system architecture and design principles
- **[Data Models](./docs/architecture/data-models.md)** - Detailed specifications for Medication, Schedule, DoseHistory, and TimezoneEvent
- **[Timezone Strategy](./docs/architecture/timezone-strategy.md)** - Comprehensive timezone handling approach
- **[Data Schema](./docs/architecture/data-schema.md)** - Complete database schema reference

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

- ✅ Phase 2.3: TimezoneManager Service
- 🔜 Phase 2.4: Medication Schedule Management
- 🔜 Phase 2.5: Data Persistence
- 🔜 Phase 3.1: Notification Service
- 🔜 Phase 3.2: User Interface

## Contributing

This is an open-source project and contributions are welcome! Please read the [Architecture Documentation](./docs/architecture/) to understand the system design before contributing.

## License

TBD

## Contact

Issues and discussions: [GitHub Issues](https://github.com/your-org/open-medtracker/issues)
