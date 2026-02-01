# MedTracker iOS Project Structure

This document describes the organization of the MedTracker iOS application.

## Overview

MedTracker is an open-source medicine tracker with international travel support for iPhone, built using SwiftUI and modern iOS development practices.

## Project Structure

```
MedTracker/
├── MedTracker/                 # Main application source code
│   ├── MedTrackerApp.swift    # App entry point (@main)
│   ├── Info.plist             # App configuration and permissions
│   ├── Models/                # Data models and business logic
│   │   └── Medicine.swift     # Medicine data model
│   ├── Views/                 # SwiftUI views and UI components
│   │   └── ContentView.swift  # Main content view
│   ├── Services/              # Business logic and data services
│   │   └── MedicineService.swift  # Medicine data management
│   ├── Utilities/             # Helper functions and extensions
│   │   └── DateFormatter+Extensions.swift  # Date formatting utilities
│   └── Resources/             # Assets, images, and resources
│       └── Assets.xcassets/   # Asset catalog
│           ├── AppIcon.appiconset/  # App icons
│           └── AccentColor.colorset/  # App accent color
├── MedTrackerTests/           # Unit tests
│   └── MedTrackerTests.swift  # Test cases
├── MedTracker.xcodeproj/      # Xcode project configuration
├── Package.swift              # Swift Package Manager configuration
├── .gitignore                 # Git ignore rules for iOS/Xcode
└── README.md                  # Project documentation
```

## Key Directories

### Models
Contains data models and business entities. These are typically Swift structs or classes that conform to `Codable` and `Identifiable` for SwiftUI compatibility.

**Current Models:**
- `Medicine.swift` - Represents a medicine entry with name, dosage, frequency, and notes

### Views
Contains SwiftUI views that make up the user interface. Views should be focused on presentation and delegate business logic to Services.

**Current Views:**
- `ContentView.swift` - The main app view

### Services
Contains business logic, data management, and API communication. Services are typically `ObservableObject` classes that publish state changes to views.

**Current Services:**
- `MedicineService.swift` - Manages medicine data CRUD operations

### Utilities
Contains helper functions, extensions, and utility classes used throughout the app.

**Current Utilities:**
- `DateFormatter+Extensions.swift` - Date formatting helpers

### Resources
Contains non-code assets like images, colors, and asset catalogs.

## Technology Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Dependency Management**: Swift Package Manager
- **Testing**: XCTest

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ Simulator or Device
- macOS for development

### Opening the Project
1. Open `MedTracker.xcodeproj` in Xcode
2. Select a simulator or device target
3. Press Cmd+R to build and run

### Project Configuration
- **Bundle Identifier**: `com.medtracker.app`
- **Deployment Target**: iOS 16.0
- **Swift Version**: 5.0
- **Supported Orientations**:
  - iPhone: Portrait, Landscape Left, Landscape Right
  - iPad: All orientations

## Development Guidelines

### Code Organization
- Keep views focused on presentation
- Move business logic to Services
- Use Models for data structures
- Place reusable utilities in Utilities folder

### Naming Conventions
- Use descriptive names for files and types
- Views should end with "View" (e.g., `ContentView`, `MedicineListView`)
- Services should end with "Service" (e.g., `MedicineService`, `StorageService`)
- Models should use singular nouns (e.g., `Medicine`, not `Medicines`)

### SwiftUI Best Practices
- Keep view bodies simple and readable
- Extract complex views into separate files
- Use `@State` for view-local state
- Use `@ObservedObject` or `@StateObject` for shared state
- Implement `PreviewProvider` for all views

## Next Steps

This is Phase 1.1 of the project setup. Future phases will add:
- Data persistence (Core Data or SwiftData)
- International travel support features
- Medication scheduling and reminders
- Time zone handling
- UI/UX enhancements
- Additional views and navigation

## Contributing

When adding new features:
1. Place files in the appropriate directory
2. Update this document if adding new major components
3. Include unit tests in `MedTrackerTests/`
4. Follow Swift and SwiftUI best practices
5. Keep the architecture clean and maintainable
