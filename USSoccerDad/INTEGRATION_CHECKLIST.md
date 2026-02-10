# Integration Checklist

## Step-by-Step Implementation Guide

### Phase 1: Add Core Files (Required)

#### 1.1 Add Model Files
Drag these files into your Xcode project under a "Models" or "Game" folder:

- ✅ `SubstitutionIntensity.swift`
- ✅ `GameConfig.swift`
- ✅ `GamePhase.swift`
- ✅ `PlayerGameStats.swift`
- ✅ `SubstitutionPlan.swift`
- ✅ `GameSession.swift`
- ✅ `CompletedGameRecord.swift`

**Verify:** Project builds without errors

#### 1.2 Add Engine Files
Drag these into "Engine" or "Services" folder:

- ✅ `SubstitutionEngine.swift`
- ✅ `GameViewModel.swift`

**Verify:** Project still builds

### Phase 2: Add View Files (Required)

#### 2.1 Add Game Views
Drag these into your "Views" folder:

- ✅ `GameView.swift`
- ✅ `PreGameView.swift`
- ✅ `ActiveGameView.swift`
- ✅ `SubstitutionOverlayView.swift`
- ✅ `PeriodBreakView.swift`
- ✅ `PostGameView.swift`

**Verify:** Project builds (views reference models/view models)

### Phase 3: Update Existing Files

#### 3.1 Replace AvailabilityView
1. ✅ Backup your current `AvailabilityView.swift`
2. ✅ Replace contents with `AvailabilityView_Updated.swift`
3. ✅ Rename file back to `AvailabilityView.swift`

**Verify:** 
- Availability screen compiles
- Can navigate to availability
- Picker shows Frequent/Balanced/Infrequent

#### 3.2 Remove Old Files (If Present)
Delete these if they exist:
- ❌ `U7GameView.swift`
- ❌ `U7GameViewModel.swift`
- ❌ Old game-related views

**Verify:** No build errors from missing references

### Phase 4: Test Basic Flow

#### 4.1 Test Game Creation
1. ✅ Create a new game
2. ✅ Navigate to availability screen
3. ✅ Verify intensity picker appears
4. ✅ Mark some players available
5. ✅ Tap "Start Game"

**Expected:** Navigation to PreGameView

#### 4.2 Test Pre-Game
1. ✅ Verify starters list shows
2. ✅ Verify bench list shows
3. ✅ Tap "Blow Whistle"

**Expected:** Navigation to ActiveGameView with running clock

#### 4.3 Test Game Clock
1. ✅ Watch clock increment
2. ✅ Verify player stats update
3. ✅ Wait for substitution countdown (~150 sec for U7 Frequent)

**Expected:** Overlay appears at 60 seconds before sub

#### 4.4 Test Substitution
1. ✅ Verify countdown shows correct players
2. ✅ Watch colors change (green→orange→red)
3. ✅ Let auto-complete execute OR tap "Sub Complete"

**Expected:** Players swap, continuous time resets for subbed-out players

#### 4.5 Test Period End
1. ✅ Let period run to completion
2. ✅ Verify continuous times reset to 0
3. ✅ Verify break countdown appears

**Expected:** PeriodBreakView shows with countdown

#### 4.6 Test Period Break
1. ✅ Verify next lineup preview shows
2. ✅ Let break count down OR tap "Start Period"

**Expected:** New period begins with new lineup

#### 4.7 Test Game End
1. ✅ Complete all periods
2. ✅ Verify PostGameView appears
3. ✅ Check player statistics
4. ✅ Tap "Share" button

**Expected:** Share sheet appears with formatted stats

#### 4.8 Test Save
1. ✅ Tap "Save & Exit"
2. ✅ Verify navigation back to game list
3. ✅ Check player season totals increased

**Expected:** Player.totalMinutesPlayed updated correctly

### Phase 5: Advanced Testing

#### 5.1 Test Different Age Groups
- ✅ U5 game (4 periods × 10 min)
- ✅ U7 game (4 periods × 10 min)
- ✅ U9 game (2 periods × 25 min)
- ✅ U11 game (2 periods × 30 min)

**Verify:** 
- Correct number of subs per period
- Correct break durations
- Proper timing calculations

#### 5.2 Test Substitution Intensities
For each age group, test:
- ✅ Frequent
- ✅ Balanced  
- ✅ Infrequent

**Verify:** 
- Correct number of subs
- Subs at expected times
- No subs within 90 seconds of period end

#### 5.3 Test Settings
- ✅ Auto-complete substitutions ON
- ✅ Auto-complete substitutions OFF
- ✅ Auto-start after break ON
- ✅ Auto-start after break OFF
- ✅ Skip break countdown ON
- ✅ Skip break countdown OFF

**Verify:** Each setting behaves as expected

#### 5.4 Test Edge Cases
- ✅ Very few players (less than playersOnField)
- ✅ Exactly playersOnField players
- ✅ Many players (10+ for U7)
- ✅ All players marked unavailable
- ✅ Mark player present mid-game (late arrival)

**Verify:** 
- Graceful handling
- Correct time credits for late players
- Proper error messages

### Phase 6: Optional Enhancements

#### 6.1 Add Completed Game Storage
Update `GameStore.swift` to store `CompletedGameRecord`:

```swift
@Published private(set) var completedGames: [CompletedGameRecord] = []
@AppStorage("completedGamesJSON") private var completedGamesJSON: String = ""

func saveCompletedGame(_ record: CompletedGameRecord) {
    completedGames.append(record)
    persistCompletedGames()
}
```

#### 6.2 Add Game History View
Create view to browse past games and statistics

#### 6.3 Add Export Improvements
- Email integration using MessageUI
- CSV export for spreadsheet analysis
- PDF generation for printing

#### 6.4 Add Coach Preferences
- Default substitution intensity per team
- Default auto-complete settings
- Custom break durations

### Troubleshooting Common Issues

#### Build Errors

**"Cannot find type 'SubstitutionIntensity'"**
- ✅ Ensure `SubstitutionIntensity.swift` is added to target
- ✅ Check file is in correct directory
- ✅ Clean build folder (Cmd+Shift+K)

**"Cannot find 'GameViewModel' in scope"**
- ✅ Verify `GameViewModel.swift` is added to target
- ✅ Check all imports are correct
- ✅ Rebuild project

**"Value of type 'Game' has no member 'ageGroup'"**
- ✅ GameConfig needs ageGroup, get it from TeamSettings
- ✅ See AvailabilityView_Updated for correct usage

#### Runtime Issues

**Clock not starting**
- ✅ Check GameViewModel.startGameClock() is called
- ✅ Verify timer is started correctly
- ✅ Ensure phase transitions to .running

**Substitutions not appearing**
- ✅ Verify substitution times calculated correctly
- ✅ Check SubstitutionEngine logic
- ✅ Ensure enough players available

**Stats not updating**
- ✅ Verify tick() function is called every second
- ✅ Check playerStats array is being modified
- ✅ Ensure @Published properties trigger updates

**Save not working**
- ✅ Check PlayerRepository.upsert() is implemented
- ✅ Verify completeGame() is called
- ✅ Ensure Player.totalMinutesPlayed updates

### Performance Optimization

#### For Large Rosters (20+ players)
- Consider lazy loading player lists
- Optimize substitution calculations
- Cache computed properties

#### For Long Games
- Periodically save state (not just at end)
- Consider checkpoint system for recovery
- Add pause/resume functionality

### Deployment Checklist

#### Before Release
- ✅ Test on physical devices (not just simulator)
- ✅ Test on multiple iOS versions (if supporting older)
- ✅ Test with maximum roster size
- ✅ Verify all age groups work correctly
- ✅ Test complete game flow start-to-finish
- ✅ Verify statistics export works
- ✅ Check memory usage during long games
- ✅ Test background/foreground transitions

#### Documentation
- ✅ Provide coach quick reference (COACH_GUIDE.md)
- ✅ Include in-app help/tutorial
- ✅ Add tooltips for settings
- ✅ Create demo video

### Success Criteria

Your implementation is successful when:

1. ✅ Coach can create game and mark availability
2. ✅ Starters are calculated by least season time
3. ✅ Substitutions happen automatically at correct times
4. ✅ Countdown shows with correct colors
5. ✅ Period transitions work smoothly
6. ✅ Final statistics are accurate
7. ✅ Season totals update correctly
8. ✅ All age groups and intensities work
9. ✅ Late arrivals can be added mid-game
10. ✅ Stats can be exported/shared

### Getting Help

#### Review These Files
1. **README.md** - Complete technical documentation
2. **COACH_GUIDE.md** - User-facing instructions
3. **GameViewModel.swift** - Comments explain game flow logic
4. **SubstitutionEngine.swift** - Comments explain selection logic

#### Common Questions

**Q: How do I customize substitution logic?**  
A: Modify `SubstitutionEngine.calculateSubstitution()` method

**Q: Can I change the number of players who sub?**  
A: Yes, modify `numberOfSubs` calculation in SubstitutionEngine

**Q: How do I add position-based selection?**  
A: Enhance Player model with positions, update SubstitutionEngine logic

**Q: Can I add manual substitutions?**  
A: Yes, add button in ActiveGameView that calls custom sub method

---

**Completion**: When all checkboxes are ✅, your implementation is complete!

**Estimated Time**: 2-4 hours for basic integration, 1-2 days for full testing
