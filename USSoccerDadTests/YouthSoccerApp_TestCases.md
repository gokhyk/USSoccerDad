# Youth Soccer Game Management System - Test Cases

## Test Plan Overview
**App Type**: Youth Soccer Game Management (U5-U17)  
**Testing Scope**: Manual + Automated Test Cases  
**iOS Target**: iOS 15.0+  
**Last Updated**: February 10, 2026

---

## 1. GAME SETUP & CONFIGURATION

### TC-001: Create New Game
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Navigate to game creation screen
2. Select age group (U5, U7, U9, U11, U13, U15, U17)
3. Configure game settings (periods, duration, players on field)
4. Save game configuration

**Expected Results**:
- Game created with correct GameConfig for selected age group
- Appropriate number of periods displayed (4 for U5-U7, 2 for U8+)
- Correct period duration applied
- Break times match age group specifications

**Test Data**:
- U7: 4 periods × 10 min, breaks: 2-5-2 min
- U9: 2 periods × 25 min, break: 10 min
- U11: 2 periods × 30 min, break: 12 min

---

### TC-002: Age-Aware Substitution Intensity Configuration
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Create game for U7 (10-min periods)
2. Navigate to AvailabilityView
3. Select "Frequent" intensity
4. Verify substitution times calculated
5. Repeat for U9 (25-min periods) with same intensity

**Expected Results**:
- U7 Frequent: 3 subs at 150s, 300s, 450s
- U9 Frequent: 4 subs at 300s, 600s, 900s, 1200s
- Balanced and Infrequent options calculate correctly
- Last substitution never occurs within 90 seconds of period end

**Automation Notes**:
```swift
func testSubstitutionTimingU7Frequent() {
    let intensity = SubstitutionIntensity.frequent
    let periodDuration = 600 // 10 minutes
    let ageGroup = AgeGroup.u7
    
    let times = intensity.calculateSubstitutionTimes(
        periodDuration: periodDuration, 
        ageGroup: ageGroup
    )
    
    XCTAssertEqual(times.count, 3)
    XCTAssertEqual(times, [150, 300, 450])
    XCTAssertTrue(times.allSatisfy { $0 <= periodDuration - 90 })
}
```

---

### TC-003: Player Availability Marking
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Open AvailabilityView for created game
2. Mark 8 players as "Present"
3. Leave 2 players as "Absent"
4. Select substitution intensity (Balanced)
5. Tap "Start Game"

**Expected Results**:
- Only present players included in starting lineup calculation
- Absent players receive credited time: `(elapsed_time × players_on_field) / players_present`
- GameSession initialized with correct player counts
- SubstitutionEngine receives only available players

**Edge Cases to Test**:
- Fewer present players than players_on_field (should show warning)
- All players marked absent (should prevent game start)
- Exactly players_on_field present (no bench, should handle gracefully)

---

## 2. PRE-GAME PHASE

### TC-004: Starting Lineup Calculation
**Priority**: Critical  
**Type**: Functional + Algorithm

**Steps**:
1. Set up game with 10 present players, 7 on field
2. Assign varying season times: P1=100min, P2=50min, P3=200min, etc.
3. Navigate to PreGameView
4. Review calculated starters

**Expected Results**:
- 7 players with LOWEST cumulative season time selected as starters
- Displayed in order from least to most season time
- Remaining 3 players shown as bench
- "Blow Whistle" button enabled

**Test Data**:
```
Player 1: 100 min season → Starter
Player 2: 50 min season → Starter (lowest)
Player 3: 200 min season → Bench
Player 4: 75 min season → Starter
Player 5: 300 min season → Bench
Player 6: 60 min season → Starter
Player 7: 80 min season → Starter
Player 8: 90 min season → Starter
Player 9: 250 min season → Bench
Player 10: 70 min season → Starter
```

**Expected Starters (by season time)**: P2, P6, P10, P4, P7, P8, P1

---

### TC-005: Blow Whistle - Game Start
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Review starters in PreGameView
2. Tap "Blow Whistle" button
3. Observe phase transition

**Expected Results**:
- GamePhase changes from `.preGame` to `.running`
- ActiveGameView displayed
- Timer starts counting from 00:00
- Current lineup matches PreGameView starters
- All starters' `continuousTimeInGame` starts incrementing
- First substitution time scheduled correctly

---

## 3. LIVE GAME MANAGEMENT

### TC-006: Game Clock Functionality
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Start game and observe clock
2. Let clock run for 30 seconds
3. Pause game (if pause implemented)
4. Resume game
5. Verify time accuracy

**Expected Results**:
- Clock displays MM:SS format
- Updates every second
- Pause/resume works correctly (if implemented)
- Time tracked accurately in PlayerGameStats
- `continuousTimeInGame` increments for on-field players only

**Performance Test**:
- Timer should not drift over 30-minute period
- UI updates should remain smooth (60 fps)

---

### TC-007: Substitution Overlay - Countdown Display
**Priority**: High  
**Type**: UI/UX

**Steps**:
1. Start U9 game with Frequent intensity (first sub at 300s = 5:00)
2. Fast-forward to 4:00 (240 seconds)
3. Observe overlay appearance at 60-second warning
4. Watch countdown color changes

**Expected Results**:
- Overlay appears at exactly 4:00 mark (60 sec before sub)
- Countdown starts at 60 and decrements
- Colors change: Green (60-21s) → Orange (20-11s) → Red (10-0s)
- Displays players IN and OUT
- "Sub Complete" button visible if auto-complete disabled

**Visual Validation**:
- Overlay doesn't block critical game info
- Colors are accessible (WCAG AA compliant)
- Font size readable from typical viewing distance

---

### TC-008: Substitution Logic - Players OUT
**Priority**: Critical  
**Type**: Algorithm

**Steps**:
1. Set up game with 7 on field, 3 bench
2. Simulate 5 minutes of play with starters
3. Trigger first substitution
4. Record which players are subbed out

**Expected Results - Priority Order**:
1. **Highest continuous time** in game (most tired)
2. If tied, **highest total time** in current game
3. If still tied, **highest cumulative season time**

**Test Scenario**:
```
Starting lineup (all have 300s continuous, 300s game time):
P1: 100 min season
P2: 150 min season  
P3: 80 min season
P4: 200 min season (HIGHEST season time)
P5: 120 min season
P6: 90 min season
P7: 110 min season

Bench:
P8: 50 min season
P9: 60 min season
P10: 70 min season
```

**Expected**: P4, P2, P5 subbed out (3 highest season times among starters)

**Automation**:
```swift
func testSubstitutionPriorityPlayersOut() {
    let engine = SubstitutionEngine()
    // Setup players with varying stats
    let (playersOut, playersIn) = engine.calculateNextSubstitution(
        currentLineup: starters,
        bench: benchPlayers,
        playersOnField: 7,
        substitutionsNeeded: 3
    )
    
    XCTAssertEqual(playersOut.count, 3)
    XCTAssertTrue(playersOut.contains(player4)) // highest season time
}
```

---

### TC-009: Substitution Logic - Players IN
**Priority**: Critical  
**Type**: Algorithm

**Steps**:
1. Continue from TC-008 with bench players
2. Verify which bench players are selected to come IN

**Expected Results - Priority Order**:
1. **Lowest time in current game** (fresh legs)
2. If tied, **lowest cumulative season time** (fairness)

**Test Scenario** (continuing TC-008):
```
Bench players (all have 0s game time):
P8: 50 min season → Should be selected #1
P9: 60 min season → Should be selected #2
P10: 70 min season → Should be selected #3
```

**Expected**: P8, P9, P10 come IN (in that order)

---

### TC-010: Automatic Substitution Execution
**Priority**: High  
**Type**: Functional

**Steps**:
1. Enable "Auto-complete subs" in settings
2. Start game with substitution at 5:00
3. Let countdown reach 0:00
4. Observe automatic substitution

**Expected Results**:
- At countdown 0:00, substitution executes automatically
- Overlay dismisses
- Current lineup updates immediately
- Players OUT stop accumulating time
- Players IN start accumulating time
- `continuousTimeInGame` resets to 0 for subbed-out players
- Next substitution time scheduled

---

### TC-011: Manual Substitution Confirmation
**Priority**: High  
**Type**: Functional

**Steps**:
1. Disable "Auto-complete subs" in settings
2. Start game with substitution at 5:00
3. Let countdown reach 0:00
4. Tap "Sub Complete" button

**Expected Results**:
- Countdown stays at 0:00 until button tapped
- Allows coach to time substitution with game flow
- Same lineup updates as TC-010 after confirmation
- No penalty for delaying substitution

---

### TC-012: Skip Substitution Within 90 Seconds of Period End
**Priority**: High  
**Type**: Edge Case

**Steps**:
1. Create U7 game (10-min periods = 600s)
2. Set Infrequent intensity (1 sub per period)
3. Calculated sub time would be at 300s (5:00)
4. Start game and observe at 8:30 (510s = 90s before end)

**Expected Results**:
- Substitution at 5:00 occurs normally
- No additional substitutions scheduled after 8:30 mark
- Period ends without late-game disruption
- Next period calculates fresh substitutions

---

### TC-013: Period End Transition
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Run game until period 1 ends (10:00 for U7)
2. Observe phase transition

**Expected Results**:
- GamePhase changes from `.running` to `.periodBreak`
- PeriodBreakView displays
- Break countdown starts (120s for U7 break 1)
- All player times freeze (no accumulation during break)
- Next period lineup calculated and displayed

---

## 4. PERIOD BREAKS

### TC-014: Break Countdown and Color Change
**Priority**: Medium  
**Type**: UI/UX

**Steps**:
1. Enter period break (U7, 120-second break)
2. Observe countdown
3. Watch for color change at 15 seconds

**Expected Results**:
- Countdown displays MM:SS format
- Changes color at 0:15 mark (implementation-dependent styling)
- Reaches 0:00 smoothly
- Next period lineup visible throughout

---

### TC-015: Auto-Start After Break
**Priority**: High  
**Type**: Functional

**Steps**:
1. Enable "Auto-start after break" in settings
2. Complete period 1
3. Let break countdown reach 0:00

**Expected Results**:
- At 0:00, GamePhase automatically changes to `.running`
- Period 2 starts immediately
- Timer resets to 00:00 and begins counting
- Next period lineup becomes active lineup
- Substitution times recalculated for period 2

---

### TC-016: Manual Start After Break
**Priority**: High  
**Type**: Functional

**Steps**:
1. Disable "Auto-start after break" in settings
2. Complete period 1
3. Let break countdown reach 0:00
4. Tap "Start Period" button

**Expected Results**:
- Countdown stops at 0:00
- "Start Period" button becomes prominent
- Period 2 only starts when button tapped
- Allows coach flexibility for team talk/logistics

---

### TC-017: Skip Break Countdown
**Priority**: Medium  
**Type**: Functional

**Steps**:
1. Enable "Skip break countdown" in settings
2. Complete period 1

**Expected Results**:
- PeriodBreakView displays without countdown
- Shows next period lineup immediately
- "Start Period" button available
- Coach manually controls when to start period 2

---

### TC-018: Half-Time vs Regular Break
**Priority**: Medium  
**Type**: Functional

**Steps**:
1. Run U7 game through periods 1 and 2
2. Observe break durations
3. Complete period 3

**Expected Results**:
- Break 1 (after period 1): 120 seconds
- Break 2/Half-Time (after period 2): 300 seconds (5 minutes)
- Break 3 (after period 3): 120 seconds
- Correct durations pulled from GameConfig

---

## 5. PLAYING TIME TRACKING

### TC-019: Continuous Time Tracking
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Start game with Player 1 in starting lineup
2. Run for 5:00 (300 seconds)
3. Substitute Player 1 out
4. Run for 3:00 (180 seconds)
5. Substitute Player 1 back in
6. Run for 2:00 (120 seconds)

**Expected Results**:
- After first stint: `continuousTimeInGame = 300s`, `timeInGame = 300s`
- While on bench: `continuousTimeInGame = 0s`, `timeInGame = 300s`
- After second stint: `continuousTimeInGame = 120s`, `timeInGame = 420s`
- Continuous time resets on each substitution OUT

---

### TC-020: Total Game Time Accumulation
**Priority**: Critical  
**Type**: Functional

**Steps**:
1. Track Player 1 through full U9 game (2 × 25-min periods)
2. Player plays first 15 minutes, sits 10 minutes, plays last 25 minutes

**Expected Results**:
- Period 1: 15 min (900s) on field, 10 min (600s) on bench = 900s game time
- Period 2: 25 min (1500s) on field = 1500s game time
- Total `timeInGame`: 2400 seconds (40 minutes)
- Percentage: (2400 / 3000) × 100 = 80% of game played

---

### TC-021: Absent Player Credited Time
**Priority**: High  
**Type**: Algorithm

**Steps**:
1. Mark Player 1 as Absent in AvailabilityView
2. Start game with 9 present players, 7 on field
3. Run for 10 minutes (600 seconds)
4. Calculate credited time for Player 1

**Expected Results**:
- Formula: `(elapsed_time × players_on_field) / players_present`
- Calculation: `(600 × 7) / 9 = 466.67 seconds`
- Player 1 receives ~467 seconds credited time
- Season time updated accordingly
- Ensures absent players aren't penalized for future games

**Automation**:
```swift
func testAbsentPlayerCreditedTime() {
    let elapsedTime: TimeInterval = 600
    let playersOnField = 7
    let playersPresent = 9
    
    let creditedTime = (elapsedTime * Double(playersOnField)) / Double(playersPresent)
    
    XCTAssertEqual(creditedTime, 466.67, accuracy: 0.01)
}
```

---

### TC-022: Late Arrival - Retroactive Credit
**Priority**: High  
**Type**: Edge Case

**Steps**:
1. Start game with Player 1 marked Absent
2. Play for 10 minutes
3. Player 1 arrives late
4. Mark Player 1 as Present
5. Add to bench

**Expected Results**:
- Player 1 receives credited time for first 10 minutes
- Available for substitution in current game
- Can be subbed in immediately
- Total season time reflects both credited and actual playing time

---

### TC-023: Season Time Accumulation Across Games
**Priority**: High  
**Type**: Integration

**Steps**:
1. Complete Game 1: Player 1 plays 30 minutes
2. Verify Player 1's season time: 30 minutes (1800s)
3. Create Game 2
4. Complete Game 2: Player 1 plays 25 minutes
5. Verify updated season time

**Expected Results**:
- After Game 1: 1800 seconds season time
- After Game 2: 3300 seconds season time (1800 + 1500)
- Season time persists across app launches
- Used correctly in future games for fair lineup selection

---

## 6. POST-GAME STATISTICS

### TC-024: Post-Game Stats Display
**Priority**: High  
**Type**: Functional

**Steps**:
1. Complete full game
2. Observe PostGameView

**Expected Results**:
- All players listed with final statistics
- Columns: Name, Time Played, % of Game
- Accurate time calculations
- Percentages add up logically
- Present players: actual playing time
- Absent players: credited time shown

---

### TC-025: Playing Time Percentage Calculation
**Priority**: Medium  
**Type**: Algorithm

**Steps**:
1. Complete U11 game (2 × 30-min periods = 3600s total)
2. Player 1 played 2700 seconds
3. Verify percentage display

**Expected Results**:
- Percentage: (2700 / 3600) × 100 = 75%
- Displayed as "75%" or "75.0%"
- Rounding handled appropriately

**Test Cases**:
- Full game: 3600s / 3600s = 100%
- Half game: 1800s / 3600s = 50%
- No play: 0s / 3600s = 0%
- Partial: 1234s / 3600s = 34.3%

---

### TC-026: Export/Share Functionality
**Priority**: Medium  
**Type**: Functional

**Steps**:
1. Complete game
2. Tap "Share" or "Export" button in PostGameView
3. Attempt to share via Messages, Email, Notes

**Expected Results**:
- iOS share sheet appears
- Game summary formatted readably
- Includes: date, opponent, final stats per player
- Can be shared to multiple destinations
- Text format preserves structure

---

### TC-027: Save & Exit Game
**Priority**: Critical  
**Type**: Data Persistence

**Steps**:
1. Complete game
2. Tap "Save & Exit" button
3. Verify CompletedGameRecord created
4. Return to games list
5. Restart app
6. Verify game still saved

**Expected Results**:
- CompletedGameRecord saved to persistent storage
- Contains all player statistics
- Season times updated for all players
- Game marked as completed
- Data survives app termination
- Can be retrieved for historical viewing

---

## 7. SETTINGS & PREFERENCES

### TC-028: Toggle Auto-Complete Substitutions
**Priority**: Medium  
**Type**: Functional

**Steps**:
1. Open settings during active game
2. Toggle "Auto-complete subs" ON and OFF
3. Observe substitution behavior changes

**Expected Results**:
- Setting persists during game session
- Changes behavior immediately
- Does not affect already-scheduled substitutions
- Saved to UserDefaults for future games

---

### TC-029: Toggle Auto-Start After Break
**Priority**: Medium  
**Type**: Functional

**Steps**:
1. Complete period 1
2. During break, toggle "Auto-start after break"
3. Observe break ending behavior

**Expected Results**:
- Setting change takes effect for current break
- Doesn't retroactively affect already-started breaks
- Persists for future periods

---

### TC-030: Toggle Skip Break Countdown
**Priority**: Low  
**Type**: Functional

**Steps**:
1. Start game with setting OFF
2. Complete period, observe countdown
3. Change setting to ON
4. Complete next period, observe no countdown

**Expected Results**:
- First break shows countdown
- Second break skips countdown
- Consistent behavior within each break

---

## 8. EDGE CASES & ERROR HANDLING

### TC-031: Insufficient Players to Start Game
**Priority**: High  
**Type**: Error Handling

**Steps**:
1. Create game requiring 7 on field
2. Mark only 5 players as Present
3. Attempt to start game

**Expected Results**:
- Error message displayed: "Not enough players present"
- Game start prevented
- Suggested action: "Mark more players as available"
- No crash or undefined behavior

---

### TC-032: All Players Marked Absent
**Priority**: Medium  
**Type**: Error Handling

**Steps**:
1. Leave all players unchecked in AvailabilityView
2. Attempt to start game

**Expected Results**:
- Error message: "No players available"
- Start button disabled
- Graceful handling, no crash

---

### TC-033: Exactly Players-On-Field Present (No Bench)
**Priority**: High  
**Type**: Edge Case

**Steps**:
1. Game requires 7 on field
2. Mark exactly 7 players Present
3. Start game with any intensity

**Expected Results**:
- Game allows start (warning optional)
- All 7 players start
- No substitutions occur (empty bench)
- Game completes normally
- All players play 100% of game time

---

### TC-034: Single Bench Player, Multiple Substitutions
**Priority**: Medium  
**Type**: Edge Case

**Steps**:
1. Game requires 7 on field
2. Mark 8 players Present (only 1 bench player)
3. Select Frequent intensity (4 subs per period)

**Expected Results**:
- First sub: swaps 1 bench player with 1 starter
- Second sub: swaps back (rotation between same 2 players)
- Continues rotating
- No crash or logic errors
- Playing time balanced as much as possible with limited bench

---

### TC-035: Mid-Game Player Injury/Absence
**Priority**: Medium  
**Type**: Edge Case

**Steps**:
1. Game in progress, player on field injured
2. Coach needs to remove player without substitution credit

**Expected Results**:
- Mechanism to mark player as injured/unavailable
- Player removed from field
- Playing time frozen at current state
- Lineup adjusts if fewer than required on field
- (Note: May need feature implementation)

---

### TC-036: Rapid Period Changes (Fast-Forward Testing)
**Priority**: Low  
**Type**: Stress Test

**Steps**:
1. Use simulator to fast-forward through game
2. Complete all periods rapidly
3. Observe state transitions

**Expected Results**:
- All phase transitions occur correctly
- No timing race conditions
- Statistics calculate accurately
- Memory stable (no leaks)
- UI remains responsive

---

### TC-037: App Backgrounding During Active Game
**Priority**: High  
**Type**: State Management

**Steps**:
1. Start game, let run for 5 minutes
2. Background app (home button / swipe up)
3. Wait 2 minutes in background
4. Return to app

**Expected Results**:
- Timer continues running in background OR pauses intelligently
- Time tracked accurately upon return
- No crash on foreground
- Game state preserved
- If timer paused, coach can resume manually

---

### TC-038: Force Quit During Active Game
**Priority**: High  
**Type**: Data Persistence

**Steps**:
1. Start game, play for 10 minutes
2. Force quit app (swipe up from multitasking)
3. Relaunch app

**Expected Results**:
- Game state saved periodically (auto-save)
- Option to "Resume Game" or "Abandon Game"
- If resumed, statistics accurate up to last save point
- If abandoned, no corrupted data

---

### TC-039: Device Rotation Handling
**Priority**: Medium  
**Type**: UI/UX

**Steps**:
1. Start game in portrait
2. Rotate to landscape
3. Rotate back to portrait
4. Verify during different phases (pre-game, active, break, post-game)

**Expected Results**:
- Layout adapts gracefully
- No UI elements cut off or overlapping
- Timer remains visible
- Substitution overlay readable in both orientations
- (Or lock to portrait if intentional design choice)

---

### TC-040: Low Battery Warning During Game
**Priority**: Low  
**Type**: Edge Case

**Steps**:
1. Play game while battery drops below 20%
2. Observe iOS low battery alert

**Expected Results**:
- App continues functioning
- Timer not interrupted
- Statistics continue tracking
- Game completable on low battery

---

## 9. PERFORMANCE & OPTIMIZATION

### TC-041: Timer Accuracy Over Long Game
**Priority**: High  
**Type**: Performance

**Steps**:
1. Run U17 game (2 × 45-min periods = 90 minutes total)
2. Use stopwatch to track actual elapsed time
3. Compare app timer to stopwatch

**Expected Results**:
- Timer drift < 2 seconds over 90 minutes
- Consistent 1-second tick rate
- No cumulative error
- CPU usage remains low

---

### TC-042: Memory Usage During Game
**Priority**: Medium  
**Type**: Performance

**Steps**:
1. Monitor memory using Xcode Instruments
2. Run full game from start to finish
3. Check for memory leaks

**Expected Results**:
- Memory usage stable throughout game
- No memory leaks detected
- Memory released after game completion
- App memory footprint < 100 MB during active game

---

### TC-043: UI Responsiveness During Substitutions
**Priority**: Medium  
**Type**: Performance

**Steps**:
1. Play game with maximum players (e.g., 18 players)
2. Trigger substitution with complex calculations
3. Measure UI lag

**Expected Results**:
- Substitution calculation completes in < 100ms
- No visible UI lag
- Animations smooth (60 fps)
- Overlay appears instantly

---

## 10. ACCESSIBILITY

### TC-044: VoiceOver Support
**Priority**: High  
**Type**: Accessibility

**Steps**:
1. Enable VoiceOver in iOS settings
2. Navigate through all screens
3. Attempt to start and manage game

**Expected Results**:
- All buttons have appropriate labels
- Timer announces time changes
- Substitution overlay readable
- Player names spoken correctly
- All interactions possible without sight

---

### TC-045: Dynamic Type Support
**Priority**: Medium  
**Type**: Accessibility

**Steps**:
1. Set iOS text size to largest
2. Navigate through app
3. Set to smallest, repeat

**Expected Results**:
- Text scales appropriately
- No text cut off at large sizes
- Layouts adapt to prevent overlap
- Timer remains readable at all sizes

---

### TC-046: Color Contrast (WCAG Compliance)
**Priority**: Medium  
**Type**: Accessibility

**Steps**:
1. Review traffic light colors (green, orange, red)
2. Test with color blindness simulators
3. Verify contrast ratios

**Expected Results**:
- Green/Orange/Red distinguishable with color blindness
- Text contrast meets WCAG AA standards (4.5:1)
- Timer readable in bright sunlight
- Alternative indicators beyond color (icons, text labels)

---

## 11. INTEGRATION TESTING

### TC-047: Complete Game Flow - Happy Path
**Priority**: Critical  
**Type**: End-to-End

**Steps**:
1. Create U9 game (2 × 25 min periods)
2. Mark 10 players present, select Balanced intensity
3. Start game
4. Review starters, blow whistle
5. Play through period 1 with all substitutions
6. Complete break
7. Play through period 2
8. Review post-game stats
9. Share results
10. Save & exit

**Expected Results**:
- Entire flow completes without errors
- All statistics accurate
- Season times updated
- Game saved to history
- No crashes or hangs

---

### TC-048: Multiple Games Same Day
**Priority**: Medium  
**Type**: Integration

**Steps**:
1. Complete Game 1 (morning)
2. Save and exit
3. Create Game 2 (afternoon, same players)
4. Start Game 2

**Expected Results**:
- Season times from Game 1 reflected in Game 2
- Starter selection considers Game 1 playing time
- Both games stored separately
- No data corruption between games

---

### TC-049: Season Statistics Report
**Priority**: Low  
**Type**: Integration

**Steps**:
1. Complete 5 games with same roster
2. View season statistics (if feature exists)
3. Verify cumulative totals

**Expected Results**:
- Total minutes per player accurate
- Average playing time calculated correctly
- Historical trends visible
- Export season report possible

---

## 12. LOCALIZATION & INTERNATIONALIZATION

### TC-050: Non-English Language Support
**Priority**: Low  
**Type**: Localization

**Steps**:
1. Change iOS language to Spanish/French/German
2. Navigate through app

**Expected Results**:
- If localized: all strings translated
- If not localized: English displayed consistently
- No hardcoded strings visible
- Time format adapts to locale (24h vs 12h)

---

## 13. SECURITY & PRIVACY

### TC-051: Data Privacy - No External Transmission
**Priority**: High  
**Type**: Security

**Steps**:
1. Use network monitoring tool (Charles Proxy)
2. Play complete game
3. Monitor network traffic

**Expected Results**:
- No unexpected network requests
- Player data not transmitted externally
- All data stored locally
- Complies with youth privacy regulations (COPPA)

---

## 14. REGRESSION TESTING

### TC-052: Core Functionality After Update
**Priority**: Critical  
**Type**: Regression

**Steps**:
1. After any code change, run critical test cases:
   - TC-001 (Create game)
   - TC-004 (Starting lineup)
   - TC-006 (Game clock)
   - TC-008 (Substitution logic OUT)
   - TC-009 (Substitution logic IN)
   - TC-027 (Save & exit)

**Expected Results**:
- All core features still function
- No regressions introduced
- Existing games still load correctly

---

## Test Execution Summary

### Priority Levels
- **Critical**: Must pass before release
- **High**: Should pass before release
- **Medium**: Fix before next minor version
- **Low**: Address as time permits

### Test Coverage Matrix

| Feature Area | Manual | Automated | Total Cases |
|---|---|---|---|
| Game Setup | 3 | 1 | 3 |
| Pre-Game | 2 | 1 | 2 |
| Live Game | 8 | 3 | 8 |
| Period Breaks | 5 | 0 | 5 |
| Time Tracking | 5 | 2 | 5 |
| Post-Game | 4 | 1 | 4 |
| Settings | 3 | 0 | 3 |
| Edge Cases | 10 | 2 | 10 |
| Performance | 3 | 0 | 3 |
| Accessibility | 3 | 0 | 3 |
| Integration | 3 | 0 | 3 |
| Other | 3 | 0 | 5 |
| **Total** | **52** | **10** | **54** |

### Recommended Test Automation

**XCTest Unit Tests** (10 priority cases):
- TC-002: Substitution timing calculations
- TC-004: Starting lineup algorithm
- TC-008: Substitution OUT priority
- TC-009: Substitution IN priority
- TC-021: Absent player credited time
- TC-025: Playing time percentage
- TC-041: Timer accuracy
- TC-043: Substitution calculation performance

**XCTest UI Tests** (5 priority flows):
- TC-047: Complete game happy path
- TC-010: Automatic substitution execution
- TC-013: Period end transition
- TC-037: App backgrounding

### Bug Severity Definitions

**S1 - Critical**: App crash, data loss, game unplayable  
**S2 - Major**: Feature broken, incorrect statistics, substitution logic wrong  
**S3 - Minor**: UI glitch, poor UX, non-critical bug  
**S4 - Cosmetic**: Typos, minor visual issues

---

## Test Environment Setup

### Required Devices
- iPhone SE (small screen testing)
- iPhone 14 Pro (notch handling)
- iPhone 15 Pro Max (large screen)
- iPad (if supported)

### iOS Versions
- iOS 15.0 (minimum supported)
- iOS 16.x (current stable)
- iOS 17.x (latest)

### Test Data Requirements
- Roster with 15+ players with varying season times
- Multiple age groups (U7, U9, U11, U13, U17)
- Games at different completion states (pre-game, in-progress, completed)

---

## Automated Test Example (XCTest)

```swift
import XCTest
@testable import YouthSoccerApp

final class SubstitutionEngineTests: XCTestCase {
    
    var engine: SubstitutionEngine!
    
    override func setUp() {
        super.setUp()
        engine = SubstitutionEngine()
    }
    
    func testStartingLineupSelectionByLowestSeasonTime() {
        // Given
        let players = createTestPlayers(count: 10)
        players[0].cumulativeSeasonTime = 100 * 60 // 100 min
        players[1].cumulativeSeasonTime = 50 * 60  // 50 min (lowest)
        players[2].cumulativeSeasonTime = 200 * 60
        players[3].cumulativeSeasonTime = 75 * 60
        players[4].cumulativeSeasonTime = 300 * 60
        players[5].cumulativeSeasonTime = 60 * 60
        players[6].cumulativeSeasonTime = 80 * 60
        players[7].cumulativeSeasonTime = 90 * 60
        players[8].cumulativeSeasonTime = 250 * 60
        players[9].cumulativeSeasonTime = 70 * 60
        
        let playersOnField = 7
        
        // When
        let starters = engine.selectStarters(
            from: players, 
            playersOnField: playersOnField
        )
        
        // Then
        XCTAssertEqual(starters.count, 7)
        XCTAssertTrue(starters.contains(players[1])) // 50 min
        XCTAssertTrue(starters.contains(players[5])) // 60 min
        XCTAssertTrue(starters.contains(players[9])) // 70 min
        XCTAssertTrue(starters.contains(players[3])) // 75 min
        XCTAssertTrue(starters.contains(players[6])) // 80 min
        XCTAssertTrue(starters.contains(players[7])) // 90 min
        XCTAssertTrue(starters.contains(players[0])) // 100 min
        
        XCTAssertFalse(starters.contains(players[2])) // 200 min - bench
        XCTAssertFalse(starters.contains(players[8])) // 250 min - bench
        XCTAssertFalse(starters.contains(players[4])) // 300 min - bench
    }
    
    func testSubstitutionTimingU7Frequent() {
        let intensity = SubstitutionIntensity.frequent
        let periodDuration: TimeInterval = 600 // 10 minutes
        let ageGroup = AgeGroup.u7
        
        let times = intensity.calculateSubstitutionTimes(
            periodDuration: periodDuration,
            ageGroup: ageGroup
        )
        
        XCTAssertEqual(times.count, 3)
        XCTAssertEqual(times, [150, 300, 450])
        
        // Verify no sub within 90 seconds of period end
        XCTAssertTrue(times.allSatisfy { $0 <= periodDuration - 90 })
    }
    
    func testAbsentPlayerCreditedTime() {
        let elapsedTime: TimeInterval = 600 // 10 minutes
        let playersOnField = 7
        let playersPresent = 9
        
        let creditedTime = engine.calculateCreditedTime(
            elapsedTime: elapsedTime,
            playersOnField: playersOnField,
            playersPresent: playersPresent
        )
        
        XCTAssertEqual(creditedTime, 466.67, accuracy: 0.01)
    }
    
    func testPlayerOutPriority_HighestContinuousTime() {
        // Given: All starters with different continuous times
        let lineup = createTestPlayers(count: 7)
        lineup[0].continuousTimeInGame = 300 // HIGHEST - should be out
        lineup[1].continuousTimeInGame = 250
        lineup[2].continuousTimeInGame = 280
        lineup[3].continuousTimeInGame = 200
        lineup[4].continuousTimeInGame = 150
        lineup[5].continuousTimeInGame = 100
        lineup[6].continuousTimeInGame = 180
        
        let bench = createTestPlayers(count: 3)
        
        // When
        let (playersOut, _) = engine.calculateNextSubstitution(
            currentLineup: lineup,
            bench: bench,
            playersOnField: 7,
            substitutionsNeeded: 1
        )
        
        // Then
        XCTAssertEqual(playersOut.count, 1)
        XCTAssertEqual(playersOut[0].id, lineup[0].id) // Highest continuous time
    }
    
    func testPlayerInPriority_LowestGameTime() {
        // Given
        let lineup = createTestPlayers(count: 7)
        let bench = createTestPlayers(count: 3)
        bench[0].timeInGame = 100
        bench[1].timeInGame = 0 // LOWEST - should come in
        bench[2].timeInGame = 50
        
        // When
        let (_, playersIn) = engine.calculateNextSubstitution(
            currentLineup: lineup,
            bench: bench,
            playersOnField: 7,
            substitutionsNeeded: 1
        )
        
        // Then
        XCTAssertEqual(playersIn.count, 1)
        XCTAssertEqual(playersIn[0].id, bench[1].id) // Lowest game time
    }
    
    private func createTestPlayers(count: Int) -> [Player] {
        return (0..<count).map { index in
            Player(
                id: UUID(),
                name: "Player \(index + 1)",
                jerseyNumber: index + 1
            )
        }
    }
}
```

---

## Notes for QA Team

1. **Test Data Preparation**: Before testing, create a consistent test roster with known season times to verify algorithm accuracy

2. **Timing Tests**: Use stopwatch alongside app to verify timer accuracy in long-running tests

3. **Real-World Scenarios**: Simulate actual coaching conditions (distractions, rapid decisions, field chaos)

4. **Device Variety**: Test on oldest supported device (iOS 15 hardware) to catch performance issues

5. **Edge Case Focus**: Youth sports have many unpredictable scenarios - test liberally beyond happy path

6. **Accessibility Priority**: Many coaches use apps during games in bright sunlight with gloves - test readability

7. **Battery Impact**: Games are long - monitor battery drain during full 90-minute U17 game

8. **Feedback Loop**: Document any UX friction points where coach might make mistakes under pressure

---

## Version History

| Version | Date | Changes | Tester |
|---|---|---|---|
| 1.0 | 2026-02-10 | Initial test plan | QA Team |

---

**End of Test Plan**
