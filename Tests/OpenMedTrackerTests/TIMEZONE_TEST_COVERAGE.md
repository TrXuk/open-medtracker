# Timezone Edge Case Test Coverage

This document describes the comprehensive test suite for timezone edge cases in OpenMedTracker.

## Test File
`TimezoneEdgeCaseTests.swift`

## Overview
The test suite contains **40+ test cases** covering critical timezone scenarios that users may encounter while traveling with medication schedules.

## Test Categories

### 1. Eastward Travel Tests (3 tests)
Tests medication time handling when traveling east (timezone offset increases).

- **testEastwardTravel_NewYorkToLondon**: Validates conversion from UTC-5 to UTC+0
- **testEastwardTravel_LosAngelesToTokyo**: Tests large eastward jump (UTC-8 to UTC+9) with date change
- **testEastwardTravel_MedicationScheduleConsistency**: Ensures medication intervals remain consistent across eastward timezone changes

**Key Validation**: Medication times correctly adjust forward, maintaining proper intervals between doses.

### 2. Westward Travel Tests (3 tests)
Tests medication time handling when traveling west (timezone offset decreases).

- **testWestwardTravel_TokyoToLosAngeles**: Validates conversion from UTC+9 to UTC-8 with date rollback
- **testWestwardTravel_LondonToNewYork**: Tests westward jump from UTC+0 to UTC-5
- **testWestwardTravel_GainExtraDayScenario**: Verifies date handling when gaining time

**Key Validation**: Medication times correctly adjust backward, preventing duplicate doses.

### 3. International Date Line Crossing Tests (4 tests)
Tests the complex scenario of crossing the International Date Line.

- **testDateLineCrossing_EastwardSamoaToHawaii**: Crossing eastward (date goes backward)
- **testDateLineCrossing_WestwardHawaiiToKiribati**: Crossing westward (date goes forward)
- **testDateLineCrossing_MedicationScheduleIntegrity**: Ensures medication schedule integrity across date line
- **testDateLineCrossing_MidnightBoundary**: Tests date line crossing at midnight

**Key Validation**: Date changes are handled correctly, preventing confusion about which day's medication to take.

### 4. Daylight Saving Time (DST) Transition Tests (5 tests)
Tests medication scheduling during DST transitions.

- **testDSTTransition_SpringForward**: Tests "spring forward" when 2:00 AM becomes 3:00 AM (lost hour)
- **testDSTTransition_FallBack**: Tests "fall back" when 2:00 AM becomes 1:00 AM (repeated hour)
- **testDSTTransition_MedicationScheduleDuringSpringForward**: Validates handling of medication scheduled during the lost hour
- **testDSTTransition_MedicationScheduleDuringFallBack**: Validates handling of medication scheduled during the repeated hour
- **testDSTTransition_CrossTimezone_WithDSTChanges**: Tests traveling between DST-observing and non-DST timezones

**Key Validation**: Medications scheduled during DST transitions are adjusted appropriately, and no doses are lost or duplicated.

### 5. Rapid Timezone Change Tests (4 tests)
Tests scenarios with multiple timezone changes in a short period (connecting flights, layovers).

- **testRapidTimezoneChanges_MultipleTransitionsInDay**: Simulates multiple timezone changes in one day (NYC → Paris → Dubai → Tokyo)
- **testRapidTimezoneChanges_ConsecutiveEastWestTravel**: Tests east then west travel in quick succession
- **testRapidTimezoneChanges_SameDayMultipleCrossings**: Multiple International Date Line crossings
- **testRapidTimezoneChanges_OffsetAccumulation**: Verifies that rapid changes don't accumulate rounding errors

**Key Validation**: Multiple timezone changes don't corrupt medication times or introduce drift errors.

### 6. Midnight Boundary Tests (5 tests)
Tests edge cases around midnight transitions.

- **testMidnightBoundary_MedicationAtMidnight**: Medication scheduled exactly at 00:00
- **testMidnightBoundary_CrossTimezoneAtMidnight**: Viewing midnight medication in different timezones
- **testMidnightBoundary_23_59_To_00_01**: Tests day boundary transition
- **testMidnightBoundary_DateLineAndMidnight**: Combines midnight with date line crossing
- **testMidnightBoundary_MedicationScheduleAroundMidnight**: Multiple medications scheduled around midnight

**Key Validation**: Midnight transitions don't cause date confusion or medication scheduling errors.

### 7. Medication Time Consistency Tests (6 tests)
Tests that medication schedules remain consistent across timezone changes.

- **testMedicationConsistency_UTCReferencePreservation**: Verifies UTC times are preserved when viewing in different timezones
- **testMedicationConsistency_DailyScheduleIntegrity**: Tests that daily medication intervals remain correct
- **testMedicationConsistency_WeeklyScheduleAcrossTimezones**: Tests weekly medication schedules
- **testMedicationConsistency_TimezoneChangeDoesNotAffectAbsoluteTime**: Ensures absolute time is unchanged by timezone conversions
- **testMedicationConsistency_MultipleTimezoneChangesInSameDay**: Tests multiple changes preserve schedule
- **testMedicationConsistency_LeapYearAndTimezones**: Tests leap year day (Feb 29) with timezone changes

**Key Validation**: Medication times stored in UTC remain absolutely consistent regardless of timezone changes.

### 8. Edge Case Combination Tests (3 tests)
Tests complex combinations of edge cases.

- **testCombination_DateLineCrossingAndDST**: Combines date line crossing with DST transition
- **testCombination_MidnightDSTAndDateLine**: Midnight during DST change while crossing date line
- **testCombination_RapidChangesWithDST**: Rapid timezone changes during DST transition period

**Key Validation**: Complex real-world scenarios are handled correctly.

## Test Scenarios Coverage

### Timezone Pairs Tested
- **Americas**: New York, Los Angeles, Phoenix, Chicago, Denver
- **Europe**: London, Paris
- **Asia**: Tokyo, Dubai, Singapore
- **Pacific**: Hawaii, Samoa, Fiji, Kiribati, Auckland, New Zealand

### Special Cases
- ✅ International Date Line crossings (both directions)
- ✅ DST transitions (spring forward and fall back)
- ✅ Non-DST timezones (Arizona, Hawaii, Japan)
- ✅ Large timezone offsets (24+ hour differences)
- ✅ Midnight boundary conditions
- ✅ Leap year handling (Feb 29)
- ✅ Same-day date changes
- ✅ Rapid consecutive changes
- ✅ UTC preservation through conversions

## Critical Validations

### 1. Absolute Time Preservation
All tests verify that the absolute time (Date object) remains unchanged when viewed in different timezones.

### 2. Interval Consistency
Tests verify that intervals between medication doses remain consistent regardless of timezone representation.

### 3. No Time Drift
Multiple conversions don't introduce rounding errors or drift.

### 4. Date Boundary Handling
Proper handling of situations where timezone conversion causes date changes.

### 5. DST Awareness
Medication times adjust appropriately during DST transitions, with special handling for the "lost hour" and "repeated hour".

## Running the Tests

### macOS with Xcode
```bash
swift test --filter TimezoneEdgeCaseTests
```

Or in Xcode:
1. Open the project
2. Press Cmd+U to run all tests
3. Or select specific tests from the Test Navigator

### CI/CD
The tests are designed to run in any timezone and will pass regardless of the machine's local timezone setting.

## Expected Behavior

### All Tests Should Pass When:
- System timezone is set to any valid timezone
- Tests are run on any platform (iOS Simulator, macOS)
- Tests are run at any time of day
- Tests are run during or outside DST periods

### Tests Are Timezone-Independent
All tests create specific timezone instances rather than relying on `TimeZone.current`, ensuring consistent behavior across different testing environments.

## Future Enhancements

Potential areas for expansion:
1. Tests for half-hour offset timezones (India, Iran, Afghanistan)
2. Tests for 15-minute offset timezones (Nepal, Chatham Islands)
3. Integration tests with Core Data medication schedules
4. Performance tests for large numbers of timezone conversions
5. Tests for historical timezone data and offset changes

## Related Files
- `TimezoneManager.swift` - Core timezone management logic
- `TimezoneManagerTests.swift` - Basic timezone manager tests
- `TimezoneEvent+CoreDataProperties.swift` - Timezone event data model
- `DoseHistory+CoreDataProperties.swift` - Dose history with timezone tracking
