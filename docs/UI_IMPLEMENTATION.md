# UI Implementation Guide (Phase 1.5)

## Overview

This document describes the SwiftUI view implementation for OpenMedTracker, including the view hierarchy, navigation flow, and usage guidelines.

## Architecture

The UI follows the **MVVM (Model-View-ViewModel)** pattern:

- **Views**: SwiftUI views for presentation and user interaction
- **ViewModels**: Observable objects that manage state and business logic
- **Services**: Data access layer connecting to Core Data

### Directory Structure

```
OpenMedTracker/Views/
├── App/
│   ├── OpenMedTrackerApp.swift      # Main app entry point
│   └── ContentView.swift             # Root TabView container
├── Medication/
│   ├── MedicationListView.swift      # List of all medications
│   ├── MedicationDetailView.swift    # Individual medication details
│   └── MedicationFormView.swift      # Add/edit medication form
├── Schedule/
│   ├── ScheduleView.swift            # Daily dose schedule
│   └── ScheduleFormView.swift        # Add/edit schedule form
├── DoseHistory/
│   └── DoseHistoryView.swift         # Dose history with statistics
├── Components/
│   ├── MedicationRowView.swift       # Reusable medication row
│   ├── ScheduleRowView.swift         # Reusable schedule row
│   ├── DoseHistoryRowView.swift      # Reusable dose history row
│   ├── StatusBadgeView.swift         # Status badge component
│   ├── EmptyStateView.swift          # Empty state placeholder
│   ├── LoadingView.swift             # Loading indicator
│   └── ErrorView.swift               # Error display with retry
└── ViewModels/
    ├── MedicationListViewModel.swift
    ├── MedicationDetailViewModel.swift
    ├── ScheduleViewModel.swift
    └── DoseHistoryViewModel.swift
```

## Main App Structure

### OpenMedTrackerApp.swift

The main entry point for the application:

```swift
@main
struct OpenMedTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

### ContentView.swift

Root view with TabView containing three main tabs:

1. **Medications Tab** - List of all medications
2. **Schedule Tab** - Today's doses and upcoming schedules
3. **History Tab** - Complete dose history with statistics

## View Details

### 1. Medication Views

#### MedicationListView

**Purpose**: Display all medications with search and filter capabilities

**Features**:
- List of medications with name, dosage, and next dose time
- Search by medication name (debounced)
- Filter by active/inactive status
- Swipe actions: Delete, Activate/Deactivate
- Pull-to-refresh
- Empty state handling
- Navigation to detail view

**ViewModel**: `MedicationListViewModel`
- `medications`: Array of medications
- `searchText`: Search query
- `showActiveOnly`: Filter toggle
- `loadMedications()`: Fetch medications
- `searchMedications()`: Search with debounce
- `deleteMedication()`: Delete a medication
- `toggleActive()`: Toggle active status

#### MedicationDetailView

**Purpose**: Show detailed information about a single medication

**Features**:
- Display all medication details (name, dosage, prescriber, dates, instructions)
- List of associated schedules
- Add new schedule
- Edit medication
- Delete medication with confirmation
- Enable/disable individual schedules

**ViewModel**: `MedicationDetailViewModel`
- `medication`: Current medication
- `schedules`: List of schedules for this medication
- `loadSchedules()`: Refresh schedules
- `updateMedication()`: Save changes
- `deleteSchedule()`: Remove a schedule
- `toggleSchedule()`: Enable/disable schedule

#### MedicationFormView

**Purpose**: Form for adding or editing medications

**Features**:
- Text fields: Name, dosage amount, dosage unit, prescriber, instructions
- Date pickers: Start date, optional end date
- Validation: Required fields, valid dosage, date logic
- Picker for common dosage units (mg, g, mL, tablets, etc.)
- Cancel/Save actions

**Modes**:
- `.add`: Create new medication
- `.edit(Medication)`: Update existing medication

### 2. Schedule Views

#### ScheduleView

**Purpose**: Display today's (or selected date's) doses

**Features**:
- Date navigation (previous/next day)
- Calendar picker for date selection
- List of doses for selected date
- Status badges (pending, taken, missed, skipped)
- Quick actions: Mark as taken, skip
- Jump to today button
- Empty state for days with no doses

**ViewModel**: `ScheduleViewModel`
- `todayDoses`: Doses for selected date
- `selectedDate`: Currently viewing date
- `loadScheduleData()`: Fetch doses
- `markDoseAsTaken()`: Mark dose as taken
- `markDoseAsSkipped()`: Skip dose
- `markDoseAsMissed()`: Mark as missed
- `selectDate()`: Change date

#### ScheduleFormView

**Purpose**: Form for adding or editing schedules

**Features**:
- Time picker (hour and minute)
- Frequency selector: daily, weekly, as needed
- Days of week selector (for weekly)
- Enable/disable toggle
- Validation: At least one day selected for weekly
- Preview text showing schedule description

**Modes**:
- `.add`: Create new schedule
- `.edit(Schedule)`: Update existing schedule

### 3. Dose History View

#### DoseHistoryView

**Purpose**: Display complete dose history with statistics

**Features**:
- **Statistics Section**:
  - Adherence rate (percentage)
  - Circular progress indicator
  - Count cards: Taken, Missed, Skipped, Pending
- **History List**:
  - Chronological list of all doses
  - Status badges with color coding
  - Medication name and scheduled time
  - Actual time (if taken)
  - Time difference (early/late)
  - Timezone information
- **Filters**:
  - Date range (7/30/90 days presets)
  - Status filter (all, taken, missed, skipped, pending)
  - Medication filter (future enhancement)
- Pull-to-refresh
- Empty state handling

**ViewModel**: `DoseHistoryViewModel`
- `doseHistory`: Array of dose records
- `adherenceRate`: Calculated adherence percentage
- `takenCount`, `missedCount`, `skippedCount`, `pendingCount`: Statistics
- `startDate`, `endDate`: Date range filter
- `selectedStatus`: Status filter
- `loadDoseHistory()`: Fetch with filters
- `setDateRange()`: Update date filter
- `setStatusFilter()`: Update status filter
- `clearFilters()`: Reset all filters

## Reusable Components

### MedicationRowView

Displays medication information in a list row:
- Name and active/inactive badge
- Dosage amount and unit
- Instructions (truncated)
- Next dose time

### ScheduleRowView

Displays schedule information:
- Medication name
- Time and frequency
- Days of week (if not daily)
- Enabled/disabled indicator

### DoseHistoryRowView

Displays dose history record:
- Status badge
- Medication name
- Scheduled and actual times
- Time difference
- Timezone information
- Notes

### StatusBadgeView

Color-coded badge for dose status:
- **Taken**: Green with checkmark
- **Missed**: Red with X
- **Skipped**: Orange with minus
- **Pending**: Blue with clock

### EmptyStateView

Generic empty state component:
- Icon (SF Symbol)
- Title
- Message
- Optional action button

### LoadingView

Loading indicator with message

### ErrorView

Error display with:
- Error icon
- Error message
- Optional retry button

## ViewModels

All ViewModels are marked `@MainActor` to ensure UI updates happen on the main thread.

### Common Patterns

1. **Published Properties**: Use `@Published` for properties that trigger UI updates
2. **Error Handling**: Store errors in `@Published var error: Error?`
3. **Loading States**: Use `@Published var isLoading: Bool`
4. **Service Injection**: Accept services in initializer with default values
5. **Context Management**: Accept `NSManagedObjectContext` for Core Data operations

### Example ViewModel Structure

```swift
@MainActor
class SomeViewModel: ObservableObject {
    @Published var data: [Model] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let service: SomeService
    private let context: NSManagedObjectContext

    init(service: SomeService = SomeService(), context: NSManagedObjectContext) {
        self.service = service
        self.context = context
    }

    func loadData() {
        isLoading = true
        error = nil

        do {
            data = try service.fetchData(in: context)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}
```

## Navigation Flow

```
ContentView (TabView)
├── Tab 1: MedicationListView
│   ├── Tap Row → MedicationDetailView (Sheet)
│   │   ├── Edit → MedicationFormView (.edit mode)
│   │   └── Add Schedule → ScheduleFormView (.add mode)
│   └── Add Button → MedicationFormView (.add mode)
│
├── Tab 2: ScheduleView
│   ├── Date Picker → DatePickerSheet
│   └── Dose Actions → Mark as taken/skipped (inline)
│
└── Tab 3: DoseHistoryView
    └── Filters Button → DoseHistoryFiltersView (Sheet)
```

## SwiftUI Previews

All views include `#Preview` macros for:
- Design-time preview in Xcode
- Using `PersistenceController.preview` for sample data
- Testing different states (empty, loaded, error)

Example:

```swift
#Preview {
    MedicationListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
```

## Core Data Integration

### Environment Setup

The `@Environment(\.managedObjectContext)` is injected at the app level and flows down through the view hierarchy.

### Passing Context to ViewModels

ViewModels receive the managed object context during initialization:

```swift
init() {
    let context = PersistenceController.shared.container.viewContext
    _viewModel = StateObject(wrappedValue: SomeViewModel(context: context))
}
```

### Service Usage

ViewModels use service classes (MedicationService, ScheduleService, etc.) to perform CRUD operations, keeping business logic separate from views.

## Form Validation

Forms include validation for:
- Required fields (name, dosage)
- Data types (numeric dosage)
- Date logic (end date after start date)
- Business rules (at least one day for weekly schedules)

Validation errors are displayed using alerts with clear messages.

## State Management

### Local State (`@State`)
Used for temporary view-specific state:
- Form field values
- Sheet presentation flags
- Selection states

### Published State (`@Published`)
Used in ViewModels for data that affects the UI:
- Fetched data arrays
- Loading/error states
- Filter/search values

### Environment Values
Used for dependency injection:
- `@Environment(\.managedObjectContext)`: Core Data context
- `@Environment(\.dismiss)`: Dismiss presented views

## Accessibility

All views follow iOS accessibility best practices:
- Semantic labels for buttons and images
- Proper navigation hierarchy
- Support for Dynamic Type
- VoiceOver compatibility through SwiftUI defaults

## Error Handling

Three-tier error handling:
1. **Service Level**: Services throw specific errors
2. **ViewModel Level**: ViewModels catch and store errors
3. **View Level**: Views display errors using `ErrorView` component

## Performance Considerations

1. **Lazy Loading**: Use `LazyVStack` for long lists
2. **Debouncing**: Search has 300ms debounce to reduce queries
3. **Background Context**: Services support background contexts for heavy operations
4. **Pagination**: Ready for pagination implementation (not yet implemented)

## Future Enhancements

Opportunities for Phase 2:

1. **Medication Interaction Checking**: Add warnings for drug interactions
2. **Photo Support**: Attach photos of pills
3. **Barcode Scanning**: Scan medication barcodes
4. **Export**: Export dose history as PDF/CSV
5. **Widgets**: iOS widgets for next dose
6. **Watch App**: Apple Watch companion app
7. **Siri Shortcuts**: Voice commands for logging doses
8. **HealthKit Integration**: Sync with Apple Health
9. **Localization**: Multi-language support
10. **Dark Mode Optimization**: Enhanced dark mode colors

## Testing Strategy

### Unit Tests
- Test ViewModels in isolation
- Mock services and contexts
- Verify state changes
- Test error handling

### UI Tests
- Test navigation flows
- Verify form validation
- Test data entry and submission
- Verify list interactions (swipe actions, etc.)

### Manual Testing Checklist

- [ ] Add a new medication
- [ ] Edit medication details
- [ ] Delete medication
- [ ] Add schedule to medication
- [ ] Edit schedule
- [ ] Delete schedule
- [ ] Mark dose as taken
- [ ] Skip a dose
- [ ] View dose history
- [ ] Apply history filters
- [ ] Search medications
- [ ] Toggle active/inactive status
- [ ] Navigate between tabs
- [ ] Test empty states
- [ ] Test error states
- [ ] Test on different device sizes (iPhone SE, iPhone 14 Pro Max, iPad)

## Known Limitations

1. **No CloudKit Sync**: Local-only storage (Phase 2 feature)
2. **No Notifications**: Reminder notifications not yet implemented (Phase 1.6)
3. **No Timezone Adjustment UI**: Manual timezone changes not exposed to user (future)
4. **Limited Medication Search**: Basic name search only
5. **No Dose Editing**: Can't edit dose history after recording (by design for audit trail)

## Code Statistics

- **Total Views**: 11 Swift files
- **Total ViewModels**: 4 Swift files
- **Reusable Components**: 7 Swift files
- **Lines of Code**: ~2,500+ lines
- **Preview Implementations**: 15 previews

## Integration with Existing Phases

This UI implementation integrates with:

- **Phase 2.1 (Core Data)**: Uses all models and services
- **Phase 2.3 (TimezoneManager)**: Ready for timezone change notifications (not yet wired)
- **Future Phase 1.6 (Notifications)**: UI ready to display notification status

## Getting Started

### Running the App

1. Open the project in Xcode
2. Select a simulator or device
3. Build and run (Cmd+R)
4. The app will launch with the TabView

### Testing in Simulator

The preview PersistenceController provides sample data for testing:
- Use previews in Xcode for quick iteration
- Run on simulator for full navigation testing
- Test on multiple device sizes

### Adding Sample Data

Sample data can be added through the UI or by extending `PersistenceController.preview` to include more test data.

## Support and Contribution

For issues or enhancements:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include screenshots for UI issues
4. Reference this documentation

---

**Last Updated**: 2026-02-01
**Phase**: 1.5 - UI Implementation
**Status**: Complete ✅
**Next Phase**: 1.6 - Notification System
