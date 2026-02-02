# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for the OpenMedTracker project.

## Workflows

### `ci.yml` - Continuous Integration

Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**

1. **SwiftLint** (`swiftlint`)
   - Runs SwiftLint to enforce code quality standards
   - Uses the `.swiftlint.yml` configuration file
   - Reports issues in GitHub Actions annotations

2. **Test and Coverage** (`test`)
   - Runs the test suite on multiple iOS simulators (iPhone 15 Pro, iPhone 15)
   - Generates code coverage reports using `llvm-cov`
   - Uploads coverage reports as artifacts (30-day retention)
   - Checks coverage threshold (currently set to 0%, can be increased)
   - Tests must pass for the build to succeed

3. **Build Verification** (`build`)
   - Builds the project in both Debug and Release configurations
   - Verifies iOS 16+ compatibility requirement in Package.swift
   - Ensures the project compiles correctly

4. **Integration Check** (`integration`)
   - Final job that verifies all previous jobs passed
   - Generates a summary report in GitHub Actions
   - Build fails if any job fails

## Features

✅ **Automated Testing**: Tests run automatically on every push/PR
✅ **Code Coverage**: Generates and uploads coverage reports
✅ **Code Quality**: SwiftLint enforces Swift best practices
✅ **Build Verification**: Ensures project builds for iOS 16+
✅ **Test Reporting**: Uploads test results as artifacts
✅ **Fail on Errors**: Build fails if tests fail or code quality issues exist

## Configuration

### iOS Version Requirement

The workflow verifies that `Package.swift` specifies iOS 16+ as the minimum platform:

```swift
platforms: [
    .iOS(.v16)
]
```

### SwiftLint

SwiftLint configuration is in `.swiftlint.yml` at the project root. Customize rules as needed for your coding standards.

### Coverage Threshold

The coverage threshold is currently set to 0% in the workflow. To enforce a minimum coverage percentage, update this line in `ci.yml`:

```yaml
THRESHOLD=0  # Change to desired percentage (e.g., 80)
```

## Artifacts

The following artifacts are uploaded for each run:

- **Coverage Report** (`coverage-report`): LCOV and text coverage reports
- **Test Results** (`test-results-*`): XCTest result bundles

Artifacts are retained for 30 days.

## Local Development

### Running Tests Locally

```bash
swift test
```

### Running Tests with Coverage

```bash
swift test --enable-code-coverage
```

### Running SwiftLint

```bash
# Install SwiftLint (macOS only)
brew install swiftlint

# Run SwiftLint
swiftlint

# Auto-fix violations
swiftlint --fix
```

### Building the Project

```bash
# Debug build
swift build

# Release build
swift build -c release
```

## Troubleshooting

### SwiftLint Failures

If SwiftLint fails, review the annotations in the GitHub Actions log. You can:
- Fix violations manually
- Run `swiftlint --fix` locally to auto-fix some issues
- Update `.swiftlint.yml` to adjust rules if needed

### Test Failures

If tests fail:
1. Check the test results artifact for detailed failure information
2. Run tests locally to reproduce: `swift test`
3. Review the GitHub Actions log for error messages

### Coverage Issues

If coverage generation fails:
1. Ensure tests run successfully first
2. Check that the test binary path matches the expected location
3. Review the coverage report artifact for details

## Requirements

- **Xcode**: 15.2 (specified in workflow)
- **Swift**: 5.9+
- **macOS Runner**: macos-14
- **iOS**: 16.0+

## CI Best Practices

1. **Keep tests fast**: Slow tests delay feedback
2. **Maintain high coverage**: Aim for 80%+ code coverage
3. **Fix SwiftLint issues**: Don't ignore code quality warnings
4. **Review failing builds**: Address CI failures promptly
5. **Update dependencies**: Keep Xcode and Swift versions current

## Future Enhancements

Consider adding:
- [ ] Codecov integration for coverage visualization
- [ ] Danger for automated PR reviews
- [ ] Fastlane for more advanced build automation
- [ ] Beta distribution workflow (TestFlight)
- [ ] Release automation
- [ ] Dependency scanning
- [ ] Security scanning
