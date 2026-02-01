# Architecture Documentation

This directory contains comprehensive architecture documentation for the Open MedTracker project.

## Documents

### [Overview](./overview.md)
High-level system architecture, design principles, component architecture, and development roadmap.

**Read this first** for an understanding of the overall system design.

### [Data Models](./data-models.md)
Detailed specifications for all core data models:
- Medication
- Schedule
- DoseHistory
- TimezoneEvent

Includes properties, relationships, validation rules, and design principles.

### [Timezone Strategy](./timezone-strategy.md)
Comprehensive timezone handling approach for international travel support:
- UTC storage with reference timezone
- Multiple adjustment strategies
- Edge case handling (DST, International Date Line, etc.)
- Implementation details and best practices

**Critical reading** for understanding the app's unique value proposition.

### [Data Schema](./data-schema.md)
Complete database schema reference:
- Table definitions with all fields and constraints
- Indexes for performance optimization
- Migration scripts
- Security and performance considerations

**Essential for implementation** of the data layer.

## Architecture at a Glance

### Core Principles

1. **Timezone Safety First**: UTC storage, explicit timezone context, user-confirmed transitions
2. **Data Integrity**: Immutable history, complete audit trail, soft deletes
3. **User Control**: Explicit consent, multiple adjustment strategies, privacy by design
4. **Offline-First**: Local Core Data storage, no internet required
5. **Focused Scope**: Medication tracking with timezone support, no feature creep

### Technology Stack

- **Platform**: iOS 17+
- **UI**: SwiftUI
- **Data**: Core Data
- **Language**: Swift 5.9+
- **Architecture**: MVVM + Repository Pattern

### Key Components

```
UI Layer (SwiftUI)
    ↓
Business Logic Layer
    ├─ MedicationManager
    ├─ ScheduleManager
    ├─ TimezoneManager
    ├─ DoseHistoryManager
    └─ NotificationManager
    ↓
Data Layer (Core Data)
    ├─ MedicationRepository
    ├─ ScheduleRepository
    ├─ DoseHistoryRepository
    └─ TimezoneEventRepository
```

## Data Model Relationships

```
User
 ├─ Medication (1:N)
 │   ├─ Schedule (1:N)
 │   │   └─ DoseHistory (1:N)
 │   └─ DoseHistory (1:N, for as-needed)
 │
 └─ TimezoneEvent (1:N)
     └─ ScheduleAdjustment (1:N)
         └─ Schedule (references)
```

## Development Phases

### Phase 1: Core Functionality (Current)
- ✅ Phase 1.1: Project setup
- ✅ Phase 1.2: Architecture design (these docs)
- ⏳ Phase 1.3: Data layer implementation
- ⏳ Phase 1.4: Business logic
- ⏳ Phase 1.5: UI implementation
- ⏳ Phase 1.6: Notifications
- ⏳ Phase 1.7: Testing

### Phase 2: Polish & Beta
- UI/UX refinement
- Edge case handling
- Performance optimization
- Beta testing

### Phase 3: Release
- App Store submission
- Marketing
- Launch

## Getting Started

### For Developers

1. Read [Overview](./overview.md) for system understanding
2. Review [Data Models](./data-models.md) for data structure
3. Study [Timezone Strategy](./timezone-strategy.md) for the core differentiator
4. Reference [Data Schema](./data-schema.md) during implementation

### For Contributors

Before contributing code:
1. Understand the architecture principles in [Overview](./overview.md)
2. Ensure changes align with timezone safety requirements
3. Follow the data model specifications
4. Add tests for timezone edge cases

### For Reviewers

When reviewing PRs:
1. Verify timezone handling follows the documented strategy
2. Check that data models match specifications
3. Ensure indexes are used for database queries
4. Validate that dose history remains immutable

## Future Enhancements

Potential features documented in [Overview](./overview.md):
- CloudKit sync for multi-device support
- Apple Watch app
- Health app integration
- Medication interaction checking
- Advanced analytics

## Questions or Feedback

- **Issues**: [GitHub Issues](https://github.com/your-org/open-medtracker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/open-medtracker/discussions)
- **Architecture Questions**: Tag with `architecture` label

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-01 | Initial architecture documentation |

---

**Note**: This architecture is designed to be implemented incrementally. Start with core data models and basic medication tracking, then add timezone features, then polish and optimize.
