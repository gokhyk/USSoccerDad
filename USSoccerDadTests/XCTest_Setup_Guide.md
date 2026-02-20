# XCTest Setup and Usage Guide

## 🚀 How to Add Tests to Your Project

### Step 1: Create Test Target (If Not Already Present)

1. In Xcode, go to **File → New → Target**
2. Select **iOS → Unit Testing Bundle**
3. Name it `USSoccerDadTests`
4. Click **Finish**

### Step 2: Add the Test File

1. Right-click on `USSoccerDadTests` folder in Xcode
2. Select **New File → Swift File**
3. Name it `GameManagementTests.swift`
4. Copy the contents of the test file I created
5. Make sure it's added to the **USSoccerDadTests** target (not the main app target)

### Step 3: Configure Test Target

In your test target's **Build Settings**, ensure:
- **Enable Testability** is set to `Yes` for Debug configuration
- The test target can import the main app module

### Step 4: Update Main App Target

In your main app target's **Build Settings**:
1. Search for "Enable Testability"
2. Set it to **Yes** for Debug builds
3. Keep it **No** for Release builds

---

## ▶️ How to Run Tests

### Run All Tests
- **Keyboard**: `Cmd + U`
- **Menu**: Product → Test
- **Test Navigator**: Click the ▶️ button next to "USSoccerDadTests"

### Run Individual Test
1. Open `GameManagementTests.swift`
2. Click the diamond icon (◇) next to the test function name
3. It will turn into a ▶️ when you hover over it

### Run Specific Test Class
- Click the ◇ next to `class GameManagementTests`

---

## ✅ Tests Included

### 1. Substitution Timing Tests
- `testSubstitutionIntensityFrequent()` - Tests 3 subs for U7 Frequent
- `testSubstitutionIntensityBalanced()` - Tests 3 subs for U9 Balanced  
- `testSubstitutionIntensityInfrequent()` - Tests 2 subs for U11 Infrequent

### 2. Age Group Configuration Tests
- `testAgeGroupDefaults()` - Verifies U7, U9, U11 defaults

### 3. Time Calculation Tests
- `testAbsentPlayerCreditedTime()` - Verifies credited time formula
- `testPlayingTimePercentage()` - Tests percentage calculations
- `testTimeFormatting()` - Tests time display formatting

### 4. Player Stats Tests
- `testPlayerGameStatsInitialization()` - Tests initial stat values

### 5. Team Settings Tests
- `testTeamSettingsCustomization()` - Tests custom team settings

### 6. Player Repository Tests
- `testPlayerCreation()` - Tests player object creation

### 7. Game Config Tests
- `testGameConfigFromTeamSettings()` - Tests config creation

### 8. Edge Case Tests
- `testMinimumPlayers()` - Tests insufficient players
- `testExactPlayersOnField()` - Tests no bench scenario
- `testSingleBenchPlayer()` - Tests single bench player

### 9. Performance Tests
- `testSubstitutionCalculationPerformance()` - Measures calculation speed

### 10. Data Validation Tests
- `testPeriodDurationValidation()` - Tests valid period durations
- `testPlayersOnFieldValidation()` - Tests valid player counts

---

## 📊 Understanding Test Results

### ✅ Green Checkmark
Test passed successfully

### ❌ Red X
Test failed - click to see assertion that failed

### ◇ Gray Diamond
Test not run yet

### ⏱ Performance Tests
Shows execution time - faster is better

---

## 🔧 Common Issues and Fixes

### Issue: "Cannot find type in scope"

**Fix**: Make sure your types are public or have `@testable import`

```swift
@testable import USSoccerDad  // This line should be at the top
```

### Issue: "Enable Testability" error

**Fix**: 
1. Select your main app target
2. Build Settings → Search "Enable Testability"
3. Set to **Yes** for Debug

### Issue: Tests don't appear in Test Navigator

**Fix**:
1. Make sure the test file is in `USSoccerDadTests` target
2. Check that functions start with `test` (e.g., `testSomething()`)
3. Clean build folder: Cmd + Shift + K, then rebuild

### Issue: "Module 'USSoccerDad' has no member 'SubstitutionIntensity'"

**Fix**: This means you need to implement the missing types. The tests are written for the types described in your implementation guide. You'll need:

- `SubstitutionIntensity` enum with `calculateSubstitutionTimes()` method
- `AgeGroup` enum
- `TeamSettings` struct
- `Player` struct
- `PlayerGameStats` struct
- `GameConfig` struct

---

## 🎯 How Tests Help You

### 1. Catch Bugs Early
Tests will fail if you accidentally break existing functionality

### 2. Document Behavior
Tests show how your code is supposed to work

### 3. Refactor Safely
Change code confidently knowing tests will catch issues

### 4. Prevent Regressions
If a test passed before and fails now, you broke something

---

## 📝 Writing Your Own Tests

### Basic Test Template

```swift
func testSomething() {
    // Given: Set up test data
    let input = 5
    
    // When: Execute the code being tested
    let result = input * 2
    
    // Then: Verify the result
    XCTAssertEqual(result, 10, "5 * 2 should equal 10")
}
```

### Common Assertions

```swift
XCTAssertEqual(a, b)              // a must equal b
XCTAssertNotEqual(a, b)           // a must not equal b
XCTAssertTrue(condition)          // condition must be true
XCTAssertFalse(condition)         // condition must be false
XCTAssertNil(value)               // value must be nil
XCTAssertNotNil(value)            // value must not be nil
XCTAssertGreaterThan(a, b)        // a > b
XCTAssertLessThan(a, b)           // a < b
XCTAssertEqual(a, b, accuracy: 0.01)  // For floating point
```

### Test Async Code

```swift
func testAsyncOperation() async throws {
    // Given
    let repo = MockPlayerRepository()
    
    // When
    let players = try await repo.listPlayers(teamId: UUID(), search: "")
    
    // Then
    XCTAssertEqual(players.count, 0)
}
```

---

## 🏃‍♂️ Quick Start Checklist

- [ ] Add test target to project (if needed)
- [ ] Add `GameManagementTests.swift` file
- [ ] Enable testability in Build Settings
- [ ] Run tests with `Cmd + U`
- [ ] All tests should pass ✅
- [ ] Add custom tests for your specific features

---

## 💡 Pro Tips

1. **Run tests frequently** - After every significant code change
2. **Write tests first** - Test-Driven Development (TDD)
3. **Keep tests focused** - One test, one behavior
4. **Name tests clearly** - Name should describe what's being tested
5. **Use test coverage** - Enable code coverage in scheme settings

---

## 📚 Next Steps

1. Run the provided tests to verify core functionality
2. Add tests for your view models
3. Add UI tests for critical user flows
4. Set up continuous integration to run tests automatically

---

## 🆘 Getting Help

If tests still don't work:

1. **Check console output** - Error messages are usually helpful
2. **Verify imports** - Make sure `@testable import USSoccerDad` is present
3. **Check target membership** - File should be in test target only
4. **Clean and rebuild** - Cmd + Shift + K, then Cmd + B
5. **Restart Xcode** - Sometimes Xcode needs a fresh start

---

Good luck with testing! 🎯
