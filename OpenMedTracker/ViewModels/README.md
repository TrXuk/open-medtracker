# View Models

This directory contains the business logic layer for OpenMedTracker, implementing the MVVM (Model-View-ViewModel) pattern. All view models follow SwiftUI best practices with `@Published` properties, Combine publishers, and proper error handling.

## Architecture

```
ViewModels/
├── ViewModelError.swift          # Error types with user-friendly messages
├── Medication/
│   ├── MedicationListViewModel.swift   # List of medications
│   └── MedicationDetailViewModel.swift # Single medication view/edit
├── Schedule/
│   └── ScheduleViewModel.swift         # Schedule management
└── DoseHistory/
    └── DoseHistoryViewModel.swift      # Dose tracking and adherence
```

## Design Principles

### 1. Reactive Programming with Combine

All view models use Combine publishers to automatically update derived state:

```swift
Publishers.CombineLatest($searchText, $showActiveOnly)
    .map { searchText, showActiveOnly in
        // Automatically filter medications
    }
    .assign(to: &$filteredMedications)
```

### 2. Error Handling

Consistent error handling using `ViewModelError`:

```swift
public func save() async -> Medication? {
    do {
        return try medicationService.create(...)
    } catch {
        self.error = ViewModelError.from(persistenceError: error)
        return nil
    }
}
```

### 3. Validation

Real-time validation with debouncing:

```swift
Publishers.CombineLatest4($name, $dosageAmount, $dosageUnit, $hasEndDate)
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.validate()
    }
```

### 4. SwiftUI Preview Support

All view models include preview helpers:

```swift
extension MedicationListViewModel {
    public static func preview() -> MedicationListViewModel {
        MedicationListViewModel(
            medicationService: MedicationService(persistenceController: .preview)
        )
    }
}
```

## View Models

### ViewModelError

Provides user-friendly error messages and recovery suggestions.

**Features:**
- Maps PersistenceError to user-friendly messages
- Includes recovery suggestions
- Implements LocalizedError protocol

**Usage:**
```swift
if let error = viewModel.error {
    Text(error.errorDescription ?? "Unknown error")
    if let suggestion = error.recoverySuggestion {
        Text(suggestion)
            .font(.caption)
    }
}
```

### MedicationListViewModel

Manages a list of medications with search and filtering.

**Published Properties:**
- `medications: [Medication]` - All medications
- `filteredMedications: [Medication]` - Filtered by search/active status
- `searchText: String` - Search query
- `showActiveOnly: Bool` - Filter toggle
- `isLoading: Bool` - Loading state
- `error: ViewModelError?` - Current error

**Key Methods:**
- `loadMedications()` - Load all medications
- `search(_ query: String)` - Filter by name
- `delete(_ medication: Medication)` - Delete medication
- `deactivate/reactivate(_ medication: Medication)` - Toggle active status
- `toggleActiveFilter()` - Toggle active/inactive filter

**Usage:**
```swift
@StateObject private var viewModel = MedicationListViewModel()

var body: some View {
    List(viewModel.filteredMedications) { medication in
        MedicationRow(medication: medication)
    }
    .searchable(text: $viewModel.searchText)
    .onAppear {
        viewModel.loadMedications()
    }
}
```

### MedicationDetailViewModel

Manages viewing and editing a single medication.

**Initialization:**
- `init()` - Create new medication
- `init(medication:)` - Edit existing medication

**Published Properties:**
- `name: String` - Medication name
- `dosageAmount: String` - Amount per dose
- `dosageUnit: String` - Unit (mg, ml, etc.)
- `instructions: String` - Instructions
- `prescribedBy: String` - Prescriber name
- `startDate: Date` - Start date
- `endDate: Date?` - Optional end date
- `hasEndDate: Bool` - Whether end date is set
- `isValid: Bool` - Form validation state
- `validationErrors: [String: String]` - Field-specific errors
- `isSaving: Bool` - Saving state
- `error: ViewModelError?` - Current error

**Key Methods:**
- `save() async -> Medication?` - Save changes
- `delete() async -> Bool` - Delete medication
- `deactivate()` / `reactivate()` - Toggle active status
- `validationError(for field: String)` - Get field error
- `hasError(for field: String)` - Check field has error

**Validation Rules:**
- Name: Required, max 100 characters
- Dosage amount: Required, must be > 0, valid number
- Dosage unit: Required, max 20 characters
- End date: Must be after start date (if set)

**Usage:**
```swift
@StateObject private var viewModel = MedicationDetailViewModel(medication: medication)

var body: some View {
    Form {
        TextField("Name", text: $viewModel.name)
            .foregroundColor(viewModel.hasError(for: "name") ? .red : .primary)

        if let error = viewModel.validationError(for: "name") {
            Text(error).foregroundColor(.red).font(.caption)
        }
    }
    .toolbar {
        Button("Save") {
            Task {
                if await viewModel.save() != nil {
                    dismiss()
                }
            }
        }
        .disabled(!viewModel.isValid || viewModel.isSaving)
    }
}
```

### ScheduleViewModel

Manages medication schedules with time and day selection.

**Initialization:**
- `init(medication:)` - Create new schedule for medication
- `init(schedule:)` - Edit existing schedule

**Published Properties:**
- `medication: Medication?` - Associated medication
- `timeOfDay: Date` - Scheduled time
- `frequency: String` - Frequency description
- `selectedDays: Set<Schedule.DayOfWeek>` - Selected days
- `isEnabled: Bool` - Whether schedule is active
- `nextScheduledTime: Date?` - Next occurrence
- `isValid: Bool` - Form validation state
- `isSaving: Bool` - Saving state
- `error: ViewModelError?` - Current error

**Computed Properties:**
- `isEveryday: Bool` - All 7 days selected
- `isWeekdaysOnly: Bool` - Monday-Friday only
- `isWeekendsOnly: Bool` - Saturday-Sunday only
- `formattedNextScheduledTime: String?` - Formatted next time

**Key Methods:**
- `save() async -> Schedule?` - Save changes
- `delete() async -> Bool` - Delete schedule
- `toggleDay(_ day: DayOfWeek)` - Toggle specific day
- `selectAllDays()` - Select all 7 days
- `selectWeekdays()` - Select Monday-Friday
- `selectWeekends()` - Select Saturday-Sunday
- `clearDays()` - Deselect all days
- `enable()` / `disable()` / `toggleEnabled()` - Control enabled state

**Validation Rules:**
- Medication: Required
- Days of week: At least one day must be selected

**Usage:**
```swift
@StateObject private var viewModel = ScheduleViewModel(medication: medication)

var body: some View {
    Form {
        DatePicker("Time", selection: $viewModel.timeOfDay, displayedComponents: .hourAndMinute)

        Section("Days") {
            ForEach(Schedule.DayOfWeek.allCases, id: \.self) { day in
                Toggle(day.name, isOn: Binding(
                    get: { viewModel.selectedDays.contains(day) },
                    set: { _ in viewModel.toggleDay(day) }
                ))
            }
        }

        Section {
            Button("Every Day") { viewModel.selectAllDays() }
            Button("Weekdays") { viewModel.selectWeekdays() }
            Button("Weekends") { viewModel.selectWeekends() }
        }
    }
    .toolbar {
        Button("Save") {
            Task {
                if await viewModel.save() != nil {
                    dismiss()
                }
            }
        }
        .disabled(!viewModel.isValid)
    }
}
```

### DoseHistoryViewModel

Manages dose tracking, adherence statistics, and history.

**Published Properties:**
- `doseHistory: [DoseHistory]` - All dose records
- `filteredDoseHistory: [DoseHistory]` - Filtered records
- `startDate: Date` - Filter start date
- `endDate: Date` - Filter end date
- `selectedStatus: DoseHistory.Status?` - Status filter
- `selectedMedication: Medication?` - Medication filter
- `adherenceRate: Double` - Adherence (0.0-1.0)
- `statusCounts: [Status: Int]` - Counts by status
- `overdueDoses: [DoseHistory]` - Overdue doses
- `isLoading: Bool` - Loading state
- `error: ViewModelError?` - Current error

**Computed Properties:**
- `adherencePercentage: String` - Formatted percentage
- `totalDoses: Int` - Total count
- `takenCount: Int` - Taken count
- `missedCount: Int` - Missed count
- `skippedCount: Int` - Skipped count
- `pendingCount: Int` - Pending count
- `overdueCount: Int` - Overdue count

**Key Methods:**
- `loadDoseHistory()` - Load doses for date range
- `refresh()` - Reload data
- `markAsTaken/Missed/Skipped(_ dose:notes:)` - Update dose status
- `resetToPending(_ dose:)` - Reset dose
- `setLast7Days()` / `setLast30Days()` - Quick date filters
- `setCurrentMonth()` / `setLastMonth()` - Month filters
- `filterByStatus(_ status:)` - Filter by status
- `filterByMedication(_ medication:)` - Filter by medication
- `clearFilters()` - Clear all filters
- `dosesByDate()` - Group doses by date
- `doses(for medication:)` - Get doses for medication
- `adherenceRate(for medication:)` - Get adherence for medication

**Usage:**
```swift
@StateObject private var viewModel = DoseHistoryViewModel()

var body: some View {
    List {
        Section("Adherence") {
            Text("Rate: \(viewModel.adherencePercentage)")
            Text("Taken: \(viewModel.takenCount)/\(viewModel.totalDoses)")
        }

        Section("Overdue") {
            ForEach(viewModel.overdueDoses) { dose in
                DoseRow(dose: dose)
                    .swipeActions {
                        Button("Take") {
                            viewModel.markAsTaken(dose)
                        }
                        .tint(.green)
                    }
            }
        }

        Section("History") {
            Picker("Status", selection: $viewModel.selectedStatus) {
                Text("All").tag(nil as DoseHistory.Status?)
                ForEach(DoseHistory.Status.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status as DoseHistory.Status?)
                }
            }

            ForEach(viewModel.filteredDoseHistory) { dose in
                DoseRow(dose: dose)
            }
        }
    }
    .toolbar {
        Menu("Range") {
            Button("Last 7 Days") { viewModel.setLast7Days() }
            Button("Last 30 Days") { viewModel.setLast30Days() }
            Button("This Month") { viewModel.setCurrentMonth() }
            Button("Last Month") { viewModel.setLastMonth() }
        }
    }
    .onAppear {
        viewModel.loadDoseHistory()
    }
}
```

## Testing

While unit tests are not yet implemented, all view models are designed to be testable:

1. **Dependency Injection**: Services can be injected for mocking
2. **In-Memory Core Data**: Use `.preview` persistence controller for tests
3. **Published Properties**: Easy to observe changes in tests
4. **Async/Await**: Modern async testing support

Example test structure:

```swift
@MainActor
final class MedicationListViewModelTests: XCTestCase {
    var viewModel: MedicationListViewModel!
    var mockService: MedicationService!

    override func setUp() {
        mockService = MedicationService(persistenceController: .preview)
        viewModel = MedicationListViewModel(medicationService: mockService)
    }

    func testLoadMedications() {
        viewModel.loadMedications()
        XCTAssertFalse(viewModel.medications.isEmpty)
    }

    func testSearch() {
        viewModel.searchText = "Aspirin"
        // Wait for debounce
        XCTAssertTrue(viewModel.filteredMedications.allSatisfy {
            $0.name.contains("Aspirin")
        })
    }
}
```

## Best Practices

### 1. Always Use @MainActor

All view models are marked `@MainActor` to ensure UI updates happen on the main thread:

```swift
@MainActor
public final class MedicationListViewModel: ObservableObject {
    // ...
}
```

### 2. Debounce User Input

Use debouncing for search and validation to avoid excessive updates:

```swift
$searchText
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] text in
        self?.performSearch(text)
    }
```

### 3. Handle Errors Gracefully

Always provide user-friendly error messages:

```swift
do {
    try performOperation()
} catch {
    self.error = ViewModelError.from(persistenceError: error)
}
```

### 4. Clear Errors Appropriately

Clear errors when user starts a new operation:

```swift
public func save() async {
    error = nil  // Clear previous errors
    // ... perform save
}
```

### 5. Use Async/Await for Long Operations

Mark save/delete operations as async to support loading indicators:

```swift
Button("Save") {
    Task {
        if await viewModel.save() != nil {
            dismiss()
        }
    }
}
```

## Integration with Services

View models interact with services from the service layer:

```
UI Layer (SwiftUI Views)
    ↓
View Model Layer (This package)
    ↓
Service Layer (MedicationService, ScheduleService, etc.)
    ↓
Data Layer (Core Data)
```

View models should:
- Never directly access Core Data contexts
- Use services for all CRUD operations
- Map PersistenceError to ViewModelError
- Maintain UI state separate from model state

## Future Enhancements

Potential improvements for future iterations:

1. **Unit Tests**: Comprehensive test coverage
2. **Undo/Redo**: Support undo for destructive operations
3. **Batch Operations**: Support for bulk updates
4. **Caching**: In-memory caching for better performance
5. **Offline Queue**: Queue operations when offline
6. **Analytics**: Track usage patterns
7. **Accessibility**: Enhanced accessibility support
8. **Localization**: Full localization support

## Contributing

When adding new view models:

1. Follow the established pattern (ObservableObject, @Published, Combine)
2. Include error handling with ViewModelError
3. Add validation where appropriate
4. Implement preview helpers
5. Document public API with doc comments
6. Use @MainActor annotation
7. Support dependency injection for testing

---

**Last Updated**: 2026-02-01
**Phase**: 1.4 - Business Logic Layer
🤖 Generated with [Claude Code](https://claude.com/claude-code)
