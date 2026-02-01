# OpenMedTracker SwiftUI View Tests

Comprehensive SwiftUI view tests using ViewInspector for testing view structure, state, and user interactions.

## Overview

This test suite uses [ViewInspector](https://github.com/nalexn/ViewInspector) to test SwiftUI views without requiring XCUITest or a simulator. These tests run on any platform including Linux, making them ideal for CI/CD pipelines.

## Test Files

### Medication Views
- **MedicationListViewTests.swift** - Tests for medication list view
  - View structure and navigation
  - Empty state handling
  - List rendering with medications
  - Search and filter functionality
  - Toolbar buttons (add, filter)

- **MedicationFormViewTests.swift** - Tests for add/edit medication form
  - Add vs Edit mode behaviors
  - Form field validation
  - Prepopulation in edit mode
  - Toolbar actions (cancel, save)
  - Dosage unit picker
  - Date picker functionality

### Schedule Views
- **ScheduleViewTests.swift** - Tests for schedule display and dose logging
  - Daily dose display
  - Date navigation (previous/next day)
  - DoseCard component testing
  - Status badges (pending, taken, missed, skipped)
  - Action buttons (take, skip)
  - DatePickerSheet component
  - Empty state handling

- **ScheduleFormViewTests.swift** - Tests for schedule creation/editing
  - Time picker functionality
  - Frequency selection (daily, weekly, as needed)
  - Days of week selection
  - Enable/disable toggle
  - Prepopulation in edit mode
  - Form validation

### Dose History Views
- **DoseHistoryViewTests.swift** - Tests for dose history and statistics
  - History list display
  - Statistics section (adherence rate, status counts)
  - StatCard component testing
  - CircularProgressView component testing
  - DoseHistoryFiltersView component
  - Filter functionality
  - Empty state handling
  - Color coding based on adherence (green/orange/red)

## Test Coverage

### What These Tests Cover

1. **View Structure**
   - Presence of navigation stacks
   - Navigation titles
   - Toolbar buttons and items
   - Form fields and pickers

2. **Component Rendering**
   - Individual reusable components (cards, badges, etc.)
   - Component states (empty, loading, error, data)
   - Conditional rendering based on state

3. **View Modes**
   - Add vs Edit modes
   - Different data states
   - Multiple configurations

4. **Data Integration**
   - Views rendering with Core Data entities
   - In-memory persistence for isolation
   - Multiple entities and relationships

### What These Tests Don't Cover

- **User Interactions**: ViewInspector has limited support for simulating taps, swipes, and gestures
- **Navigation Flow**: Multi-screen navigation flows are not fully testable
- **Animations**: Animation behavior is not tested
- **Accessibility**: VoiceOver and accessibility features require XCUITest
- **Visual Appearance**: Color, layout, and visual design require snapshot testing or manual verification

## Running the Tests

### Using Swift Package Manager (Any Platform)
```bash
swift test --filter OpenMedTrackerViewTests
```

### Using Xcode (macOS)
1. Open the project in Xcode
2. Select the test navigator (⌘6)
3. Run OpenMedTrackerViewTests
4. Or use keyboard shortcut: ⌘U to run all tests

### CI/CD Integration
These tests run on Linux and can be integrated into CI pipelines:
```bash
# In GitHub Actions, GitLab CI, etc.
swift test --filter OpenMedTrackerViewTests
```

## Test Structure

Each test file follows this pattern:

```swift
@MainActor
final class ViewTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        // Create in-memory Core Data stack
    }

    override func tearDown() async throws {
        // Clean up
    }

    // MARK: - View Structure Tests
    func testViewExists() throws { }

    // MARK: - Component Tests
    func testComponentRendering() throws { }

    // MARK: - Integration Tests
    func testViewWithData() throws { }
}
```

## ViewInspector Extensions

All tested views include the `Inspectable` protocol extension:

```swift
extension MyView: Inspectable { }
```

This allows ViewInspector to traverse the view hierarchy and inspect elements.

## Testing Philosophy

### Focus on Structure, Not Implementation
These tests verify that views have the correct structure and components, not specific implementation details. This allows refactoring without breaking tests.

### Test with Real Data
Tests use in-memory Core Data with real entities, ensuring views work with actual data models.

### Isolation
Each test runs in isolation with its own Core Data stack, preventing test pollution.

## Known Limitations

### ViewInspector Limitations
1. **Async operations**: ViewModel state changes are asynchronous and may not be immediately reflected
2. **Environment objects**: Some environment-based behaviors are difficult to test
3. **Navigation**: Navigation actions and sheet presentations have limited testability
4. **SwiftUI internals**: Some SwiftUI view modifiers are not directly inspectable

### Workarounds
- Focus on structural tests rather than behavioral tests
- Use integration tests for complex flows
- Consider adding XCUITests for critical user flows (requires macOS)

## Future Enhancements

Potential improvements to the test suite:

1. **Snapshot Testing**: Add snapshot tests for visual regression testing
2. **Accessibility Testing**: Verify accessibility labels and hints
3. **Performance Testing**: Measure view rendering performance with large datasets
4. **XCUITests**: Add UI tests for critical user flows (requires macOS/Xcode)
5. **Mock ViewModels**: Create mock view models for more controlled testing
6. **User Interaction Tests**: Expand coverage of button taps and user actions

## Test Statistics

- **Total Test Files**: 5
- **Test Methods**: ~170+ tests
- **Coverage Areas**:
  - Medication views: ~50 tests
  - Schedule views: ~60 tests
  - Dose history views: ~60 tests
- **Platforms**: iOS, macOS, Linux (via ViewInspector)

## Contributing

When adding new SwiftUI views:

1. Create a corresponding test file in `Tests/OpenMedTrackerViewTests/`
2. Add the `Inspectable` extension to your view
3. Write tests for:
   - Basic structure (navigation, sections)
   - Components and subviews
   - Different modes/states
   - Integration with data
4. Run tests locally before committing
5. Ensure tests pass in CI

## Resources

- [ViewInspector Documentation](https://github.com/nalexn/ViewInspector)
- [SwiftUI Testing Best Practices](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/9-testing-swiftui-views-with-viewinspector)
- [OpenMedTracker Architecture Docs](../../docs/architecture/)

---

**Note**: These tests complement but do not replace unit tests (Models, Services, ViewModels) and integration tests. For comprehensive coverage, use all three testing strategies.
