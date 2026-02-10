# Youth Soccer Game Management System - Implementation Guide

## Overview

This implementation provides a complete game management system for youth soccer coaches (U5-U17). It handles pre-game setup, live game management with automatic substitutions, and post-game statistics.

## File Structure

### Core Models
1. **SubstitutionIntensity.swift** - Defines substitution frequency (Frequent/Balanced/Infrequent) with age-aware timing
2. **GameConfig.swift** - Game configuration (periods, duration, players on field, break times)
3. **GamePhase.swift** - Enum tracking current game state (PreGame, Running, PendingSubstitution, PeriodBreak, PostGame)
4. **PlayerGameStats.swift** - Individual player statistics during active game
5. **SubstitutionPlan.swift** - Model for planned substitutions
6. **GameSession.swift** - Active game session state (observable object)
7. **CompletedGameRecord.swift** - Persistent record of finished games

### Game Engine
8. **SubstitutionEngine.swift** - Core logic for calculating optimal substitutions based on playing time
9. **GameViewModel.swift** - Main view model orchestrating game flow (timer, phases, substitutions)

### Views
10. **GameView.swift** - Main coordinator view that switches between game phases
11. **PreGameView.swift** - Shows calculated starters, "Blow Whistle" button
12. **ActiveGameView.swift** - Live game clock and current lineup
13. **SubstitutionOverlayView.swift** - 60-second countdown with traffic light colors (green→orange→red)
14. **PeriodBreakView.swift** - Break countdown with next period lineup preview
15. **PostGameView.swift** - Final statistics, share/export functionality
16. **AvailabilityView_Updated.swift** - Enhanced availability view with intensity picker

## Key Features Implemented

### 1. Age-Aware Substitution Timing
- **U5-U7**: Frequent=3 subs, Balanced=2 subs, Infrequent=1 sub per period
- **U8+**: Frequent=4 subs, Balanced=3 subs, Infrequent=2 subs per period
- Automatically skips substitutions within 90 seconds of period end

### 2. Smart Substitution Logic
**Players OUT (prioritized by):**
1. Highest continuous time in game (most tired)
2. Highest total time in game
3. Highest cumulative season time

**Players IN (prioritized by):**
1. Lowest time in current game
2. Lowest cumulative season time

### 3. Fair Playing Time
- Starters selected by lowest cumulative season time
- Absent players credited with expected time: `(elapsed_time × players_on_field) / players_present`
- Late arrivals can be marked present and credited retroactively

### 4. Automatic Time Tracking
- **Time in Game**: Total seconds played in current game
- **Continuous Time**: Seconds in current stint (resets on sub)
- **Season Time**: Cumulative minutes across all games
- All tracked in seconds for precision

### 5. Game Flow Controls
- Traffic light countdown (Green→Orange→Red) for substitutions
- Period break countdown with color change at 15 seconds
- Between-period lineup calculation
- Settings for:
  - Auto-complete substitutions
  - Auto-start after break
  - Skip break countdown

### 6. Post-Game Features
- Detailed playing time statistics
- Percentage of game played per player
- Export/share functionality
- Automatic update of season totals

## Integration Steps

### 1. Add New Files to Xcode Project
Copy all `.swift` files to your Xcode project:
- Core Models (7 files)
- Game Engine (2 files)
- Views (6 files)

### 2. Replace AvailabilityView
Replace your existing `AvailabilityView.swift` with `AvailabilityView_Updated.swift`

### 3. Remove Old U7 Files (if present)
- Remove `U7GameView.swift`
- Remove `U7GameViewModel.swift`

### 4. Update GameStore (Optional Enhancement)
Add support for storing completed game records:

```swift
@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var completedGames: [CompletedGameRecord] = []
    
    @AppStorage("gamesJSON") private var gamesJSON: String = ""
    @AppStorage("completedGamesJSON") private var completedGamesJSON: String = ""
    
    // Add methods to save/load completed games
    func saveCompletedGame(_ record: CompletedGameRecord) {
        completedGames.append(record)
        persistCompletedGames()
    }
    
    private func persistCompletedGames() {
        do {
            let data = try JSONEncoder().encode(completedGames)
            if let json = String(data: data, encoding: .utf8) {
                completedGamesJSON = json
            }
        } catch {
            print("Failed to encode completed games: \(error)")
        }
    }
}
```

### 5. Add InMemoryPlayerRepository (if not exists)
Make sure you have a player repository implementation:

```swift
class InMemoryPlayerRepository: PlayerRepository {
    // Your implementation here
}
```

## Usage Flow

### Coach Workflow
1. **Setup Game** → Coach creates game in GameStore
2. **Mark Availability** → Navigate to AvailabilityView, mark present players, select intensity
3. **Start Game** → Tap "Start Game" button
4. **Pre-Game** → Review calculated starters, tap "Blow Whistle"
5. **During Game**:
   - Clock runs automatically
   - 60 seconds before sub: overlay appears with countdown
   - At sub time: either auto-executes or waits for "Sub Complete" button
   - Period ends → automatic break countdown
   - Break ends → shows next period lineup, tap "Start Period"
6. **Post-Game** → View statistics, share results, save & exit

### Settings Menu (gear icon in toolbar)
- **Auto-complete subs**: Substitutions happen automatically at scheduled time
- **Auto-start after break**: Next period starts automatically when break ends
- **Skip break countdown**: No countdown during breaks, manual start only

## Substitution Timing Examples

### U7 (10-minute periods = 600 seconds)
- **Frequent**: 150s, 300s, 450s (every 2.5 min)
- **Balanced**: 200s, 400s (every 3.33 min)
- **Infrequent**: 300s (at 5 min)

### U9 (25-minute periods = 1500 seconds)
- **Frequent**: 300s, 600s, 900s, 1200s (every 5 min)
- **Balanced**: 375s, 750s, 1125s (every 6.25 min)
- **Infrequent**: 500s, 1000s (every 8.33 min)

### U11 (30-minute periods = 1800 seconds)
- **Frequent**: 360s, 720s, 1080s, 1440s (every 6 min)
- **Balanced**: 450s, 900s, 1350s (every 7.5 min)
- **Infrequent**: 600s, 1200s (every 10 min)

## Break Durations by Age Group

### U5-U7 (4 periods)
- Break 1: 120 seconds (2 min)
- Half Time: 300 seconds (5 min)
- Break 3: 120 seconds (2 min)

### U8-U9 (2 periods)
- Half Time: 600 seconds (10 min)

### U10-U11 (2 periods)
- Half Time: 720 seconds (12 min)

### U12+ (2 periods)
- Half Time: 720 seconds (12 min)

## Technical Notes

### Time Precision
- All internal calculations use **seconds** for accuracy
- Display formats show MM:SS
- Season totals stored as **minutes** (rounded) in Player model

### Data Persistence
- Active game: In-memory only (GameSession)
- Completed games: JSON via AppStorage (CompletedGameRecord)
- Player season stats: Updated immediately on game completion

### Thread Safety
- GameViewModel is @MainActor
- Timer runs on main thread
- All UI updates are synchronous

### Future Enhancements
- Position-based starter selection
- Goalkeeper rotation logic
- Multiple games per day support
- Detailed stint history
- Custom substitution patterns
- Email integration for stats sharing

## Testing Checklist

- [ ] Create game with different age groups
- [ ] Mark players available/unavailable
- [ ] Verify correct number of starters
- [ ] Confirm substitution times match intensity
- [ ] Test traffic light countdown colors
- [ ] Verify continuous time resets on sub
- [ ] Check period break countdown
- [ ] Test late player arrival
- [ ] Confirm absent player time calculation
- [ ] Verify season totals update correctly
- [ ] Test export/share functionality
- [ ] Check all settings (auto-complete, auto-start, skip break)

## Support

For questions or issues, refer to the inline code comments or review the game flow logic in GameViewModel.swift.

---

**Version**: 1.0  
**Created**: February 9, 2026  
**Compatible with**: iOS 15+
