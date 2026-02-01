# open-medtracker
Open source medicine tracker with international travel support for iPhone

## Overview

OpenMedTracker is an iOS application designed to help users track their medication schedules, with special attention to international travel scenarios where timezone changes can affect medication timing.

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

## Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## Roadmap

- ✅ Phase 2.3: TimezoneManager Service
- 🔜 Phase 2.4: Medication Schedule Management
- 🔜 Phase 2.5: Data Persistence
- 🔜 Phase 3.1: Notification Service
- 🔜 Phase 3.2: User Interface

## License

TBD
