# USSoccerDad — Architecture Overview

## 1. Layer Structure

The app follows a layered architecture with clear separation between data, business logic, state management, and presentation.

```
┌──────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                   │
│  Views (SwiftUI) — no business logic                  │
│  RootView · MainTeamView · GameView · ActiveGameView  │
│  PreGameView · SubstitutionOverlayView · PostGameView │
│  PeriodBreakView · AvailabilityView · RosterView      │
├──────────────────────────────────────────────────────┤
│              STATE / VIEW-MODEL LAYER                 │
│  GameViewModel · GameSession · ThemeManager           │
├──────────────────────────────────────────────────────┤
│               BUSINESS LOGIC LAYER                   │
│  SubstitutionEngine (stateless, pure functions)       │
│  GamePhase state machine                              │
├──────────────────────────────────────────────────────┤
│               PERSISTENCE LAYER                      │
│  TeamStore · GameStore · InMemoryPlayerRepository    │
│  Backend: @AppStorage (UserDefaults JSON)             │
├──────────────────────────────────────────────────────┤
│                   MODEL LAYER                        │
│  Player · Game · GameConfig · GamePhase              │
│  SubstitutionPlan · PlayerGameStats                  │
│  SubstitutionIntensity · TeamSettings · AgeGroup     │
│  CompletedGameRecord · ForcedSubProposal             │
└──────────────────────────────────────────────────────┘

DESIGN SYSTEM (cross-cutting)
  Theme.swift — AppColors, AppTypography, AppSpacing,
  AppCornerRadius, AppShadow, AppAnimations, AppIcons
  AppButton_Themed · AppCard · PlayerRow
```

---

## 2. Key Classes and Types

### Models

| Type | Kind | Responsibility |
|------|------|----------------|
| `Player` | struct | Player identity, jersey number, position flags, cumulative `totalMinutesPlayed` |
| `Game` | struct | Opponent, date, format (periods/minutes/players), per-player availability, scores |
| `GameConfig` | struct | Runtime game parameters derived from `Game` + `TeamSettings` (period seconds, players on field, break durations) |
| `TeamSettings` | struct | Per-team defaults calculated from `AgeGroup` (U5–U17) |
| `AgeGroup` | enum | Age-appropriate game format constants (U5–U17) |
| `GamePhase` | enum | State machine: `.preGame`, `.running`, `.pendingSubstitution(plan)`, `.periodBreak(n, secs)`, `.postGame` |
| `SubstitutionPlan` | struct | Scheduled swap — players in, players out, time, completion flag |
| `SubstitutionIntensity` | enum | Frequency setting (frequent / balanced / infrequent) + substitution-time generation |
| `PlayerGameStats` | struct | Per-player runtime state: seconds played, continuous time, on-field flag, arrival/departure |
| `CompletedGameRecord` | struct | Immutable post-game snapshot; factory method converts `GameSession` → record |
| `ForcedSubProposal` | struct | Coach-initiated mid-game sub: player out, proposed player in, optional countdown |

### State / ViewModel

| Type | Kind | Responsibility |
|------|------|----------------|
| `GameSession` | `ObservableObject` class | All live game state — `playerStats`, `phase`, `periodElapsedSeconds`, `substitutionPlans`, scores. Computed groups: `playersOnField`, `playersOffField`, `availablePlayers`, `playersLeftEarly` |
| `GameViewModel` | `@MainActor ObservableObject` | Orchestrates game lifecycle. Owns the 1-second timer, phase transitions, substitution execution, forced sub proposal state, background/foreground recovery, and game completion |
| `ThemeManager` | `ObservableObject` | Manages the active theme, persists selection to UserDefaults, exposes `colors` to every view via `@EnvironmentObject` |

### Business Logic

| Type | Kind | Responsibility |
|------|------|----------------|
| `SubstitutionEngine` | stateless struct | All substitution calculations: starter selection, optimal sub count (1–5), who goes in/out, next-period lineup, substitution time generation |

### Persistence

| Type | Kind | Responsibility |
|------|------|----------------|
| `TeamStore` | `@MainActor ObservableObject` | Single active `TeamSettings`; persisted as JSON in `@AppStorage` |
| `GameStore` | `@MainActor ObservableObject` | `[Game]` array CRUD; persisted as JSON in `@AppStorage` |
| `InMemoryPlayerRepository` | `@MainActor` class | Implements `PlayerRepository` protocol; `[UUID: Player]` dictionary in `@AppStorage` |
| `PlayerRepository` | protocol | Abstraction over player storage (list, upsert, delete) — decouples ViewModel from storage backend |

---

## 3. Data Flow

### 3.1 App Startup

```
USSoccerDadApp
  ├── injects @StateObject TeamStore, GameStore, ThemeManager
  └── RootView
       ├── TeamStore.activeTeam == nil  →  SetupTeamView (first-launch onboarding)
       └── TeamStore.activeTeam exists  →  MainTeamView
```

### 3.2 Game Creation

```
MainTeamView → GameListView
  └── AddEditGameView
       └── gameStore.upsert(game)  →  @AppStorage (persisted)
```

### 3.3 Game Startup

```
GameDetailView → AvailabilityView
  ├── loads players from InMemoryPlayerRepository
  ├── coach toggles availability per player
  ├── coach selects SubstitutionIntensity
  └── "Start Game"
       ├── gameStore.updateAvailability(availableIds)
       ├── builds GameConfig from game + TeamSettings
       └── navigates to GameView
            └── viewModel.startGame()
                 ├── creates GameSession
                 ├── SubstitutionEngine.calculateStarters()    // least season minutes start
                 └── phase = .preGame

PreGameView — coach confirms lineup
  └── "Blow Whistle"
       └── viewModel.startGameClock()
            ├── SubstitutionEngine.generateSubstitutionTimes()
            ├── phase = .running
            └── timer starts
```

### 3.4 Active Game (1-second Timer Loop)

```
Timer → GameViewModel.tick()

phase = .running → handleRunningTick()
  ├── periodElapsedSeconds += speedMultiplier
  ├── for each on-field player:
  │    secondsPlayed += speedMultiplier
  │    continuousSecondsPlayed += speedMultiplier
  ├── updateAbsentPlayerTimes()           // expected-time formula
  ├── tickForcedSubCountdown()            // auto-complete countdown
  ├── checkForUpcomingSubstitution()      // 60-second lookahead
  │    └── if sub within 60s:
  │         SubstitutionEngine.calculateSubstitution()
  │         phase = .pendingSubstitution(plan)
  └── if periodElapsedSeconds >= periodSeconds → handlePeriodEnd()

phase = .pendingSubstitution(plan) → handleSubstitutionCountdownTick()
  ├── same time/stat increments
  ├── if scheduledTime reached:
  │    autoCompleteSubstitutions ON  →  executeSubstitution(plan)
  │    autoCompleteSubstitutions OFF →  wait for coach button
  └── if period ends during countdown → handlePeriodEnd()

phase = .periodBreak → handleBreakTick()
  ├── breakElapsedSeconds += speedMultiplier
  └── if break complete:
       autoStartAfterBreak ON  →  startPeriod()   // recalculates lineup
       autoStartAfterBreak OFF →  timer stops, coach resumes

executeSubstitution(plan)
  ├── players in plan.playersOut: isOnField = false, continuousSecondsPlayed = 0
  ├── players in plan.playersIn:  isOnField = true
  ├── plan.isCompleted = true
  └── phase = .running
```

### 3.5 Forced Substitution (Coach Override)

```
ActiveGameView — coach presses X on a field player
  └── viewModel.forcedSubOut(playerId)
       ├── playerStats[out].isOnField = false
       ├── continuousSecondsPlayed = 0
       ├── find bench player with least secondsPlayed
       └── forcedSubProposal = ForcedSubProposal(out, in, countdown)

Banner appears in ActiveGameView
  ├── "Sub In" button  →  confirmForcedSub()
  │    └── proposed player: isOnField = true; proposal cleared
  ├── "Skip" button    →  dismissForcedSub(); player stays on bench
  └── autoComplete ON: tickForcedSubCountdown() fires every tick
       └── at 0 seconds → confirmForcedSub() automatically

Coach presses X on a bench player
  └── viewModel.markBenchPlayerAbsent(playerId)
       ├── playerStats[i].wasPresent = false       // moves to Absent section
       └── if this player was the pending proposal → proposal dismissed
```

### 3.6 Player Availability Changes (Mid-Game)

```
Absent player arrives:
  absentCard "Arrived" → viewModel.markPlayerPresent(playerId)
    └── GameSession.markPlayerPresent()
         ├── wasPresent = true
         ├── if secondsPlayed == 0 (true late arrival):
         │    arrivedLate = true
         │    secondsPlayed = (totalGameTime × playersOnField) / totalPresent
         └── if secondsPlayed > 0 (was benched, then absent): restore only

Player leaves early:
  viewModel.markPlayerLeftEarly(playerId)
    └── isOnField = false, leftEarly = true, departureTime recorded
        wasPresent stays true (stats preserved)
```

### 3.7 Period Transition

```
handlePeriodEnd()
  ├── stopTimer()
  ├── forcedSubProposal = nil          // clear any pending forced sub
  ├── reset all continuousSecondsPlayed
  ├── if currentPeriod < config.periods:
  │    currentPeriod += 1
  │    phase = .periodBreak(n, breakSeconds)
  └── else: handleGameEnd() → phase = .postGame

startPeriod() (after break)
  ├── SubstitutionEngine.calculateNextPeriodLineup()   // full rotation by game time
  ├── update isOnField for all players
  ├── reset continuousSecondsPlayed
  ├── generateSubstitutionPlans() for new period
  ├── phase = .running
  └── timer restarts
```

### 3.8 Game Completion

```
PostGameView — coach taps "Save & Exit"
  └── viewModel.completeGame(game, gameStore)
       ├── CompletedGameRecord.from(session, game)   // immutable snapshot
       ├── for each playerStat:
       │    additionalMinutes = (secondsPlayed + 30) / 60   // round to nearest
       │    player.totalMinutesPlayed += additionalMinutes
       │    playerRepo.upsert(player)                       // persisted
       ├── gameStore.updateScore(ourScore, opponentScore)   // persisted
       ├── gameStore.markCompleted(gameId)                  // locked from restart
       └── session = nil                                    // clears all live state
```

---

## 4. Substitution Fairness Algorithm

The `SubstitutionEngine` enforces equal playing time across a full season.

### Starter Selection
Players with the **least cumulative season minutes** start. This ensures the player who has played the least overall gets field time first.

### Optimal Substitution Count (1–5 players)
At each substitution window, the engine pairs the most-fatigued on-field players against the most-rested bench players and counts pairs where the time gap exceeds **90 seconds**. This avoids churning players unnecessarily when the lineup is already balanced.

```
sortedOut = on-field sorted by secondsPlayed DESC  (most played first)
sortedIn  = bench sorted by secondsPlayed ASC      (least played first)

count = number of pairs where (sortedOut[i].secondsPlayed − sortedIn[i].secondsPlayed) > 90s
result = clamp(max(1, count), 1, 5)
```

### Who Goes Out
Sort on-field by: `continuousSecondsPlayed DESC` → `secondsPlayed DESC` → `seasonSeconds DESC`
Continuous time is the primary key — the most fatigued player comes off first.

### Who Goes In
Sort bench by: `secondsPlayed ASC` → `seasonSeconds ASC`
The player who has played the least (this game, then this season) gets priority.

### Period Lineup Rotation
Between periods, `calculateNextPeriodLineup()` selects the N players with the least total game time from the full available pool — effectively a complete rotation rather than incremental swaps.

---

## 5. State Machine

`GamePhase` is the single source of truth for game state. Each phase drives a different UI screen and timer behavior.

```
         startGameClock()
.preGame ──────────────────► .running
                                │
             sub within 60s     │         period ends
                 ▼              │              ▼
   .pendingSubstitution(plan) ──┤      .periodBreak(n, secs)
          │ executeSubstitution │              │
          └───────────────────►─┘   startPeriod() / auto-start
                                              │
                              final period ends
                                              ▼
                                        .postGame
```

The forced substitution proposal (`ForcedSubProposal`) sits **outside** the phase machine — it is a parallel `@Published` property on `GameViewModel` so that the game clock continues uninterrupted while the banner is visible.

---

## 6. Persistence

All data is stored in **UserDefaults via `@AppStorage`** using JSON encoding. There is no remote backend or Core Data.

| Store | Key | Type |
|-------|-----|------|
| `TeamStore` | `active_team` | `TeamSettings?` |
| `GameStore` | `games` | `[Game]` |
| `InMemoryPlayerRepository` | `players` | `[UUID: Player]` |
| `ThemeManager` | `selectedTheme` | `String` (theme name) |

The `PlayerRepository` protocol decouples `GameViewModel` from the storage implementation. Swapping to CloudKit or a REST backend requires only a new conforming type.

---

## 7. Background / Foreground Handling

`GameViewModel` subscribes to `UIApplication.didEnterBackgroundNotification` and `willEnterForegroundNotification`.

- **Background**: records `backgroundedAt = Date()`, stops timer.
- **Foreground**: computes `missedSeconds = now − backgroundedAt`, applies them to game time and player stats as if the clock ran normally. If the period would have ended during the background interval, `handlePeriodEnd()` fires immediately on return.

---

## 8. Design System

All visual constants live in `Theme.swift` and are accessed through named types — no magic numbers in view code.

| Constant Type | Examples |
|--------------|---------|
| `AppColors` | `.soccerGreen`, `.fieldLight`, `.alertRed` |
| `AppTypography` | `.display`, `.heading`, `.body`, `.label` |
| `AppSpacing` | `.xs (4)`, `.sm (8)`, `.md (16)`, `.lg (24)`, `.xl (32)`, `.xxl (48)` |
| `AppCornerRadius` | `.sm`, `.md`, `.lg`, `.pill` |
| `AppShadow` | `.none`, `.low`, `.medium`, `.high`, `.extraHigh` |
| `AppIcons` | SF Symbol name strings |

`ThemeManager` exposes a `ThemeColors` wrapper that maps semantic roles (`.primary`, `.success`, `.error`, `.warning`, `.surface`) to the active theme's concrete colors. All six bundled themes implement the `Theme` protocol with both light and dark variants.

---

## 9. File Map

```
USSoccerDad/
├── App Entry
│   └── USSoccerDadApp.swift          @main, injects global stores
│
├── Models
│   ├── Player.swift                  Player struct + PlayerRepository protocol
│   ├── Game.swift                    Game record + availability
│   ├── TeamModels.swift              AgeGroup, TeamSettings
│   ├── GameConfig.swift              Runtime game parameters
│   ├── GamePhase.swift               Phase state machine enum
│   ├── SubstitutionIntensity.swift   Frequency enum + time generator
│   ├── SubstitutionPlan.swift        Scheduled swap record
│   ├── PlayerGameStats.swift         Per-player live stats
│   └── CompletedGameRecord.swift     Post-game immutable snapshot
│
├── State
│   ├── GameSession.swift             Live game ObservableObject
│   └── GameViewModel.swift           @MainActor orchestrator + ForcedSubProposal
│
├── Business Logic
│   └── SubstitutionEngine.swift      Pure static calculation functions
│
├── Persistence
│   ├── TeamStore.swift               @AppStorage singleton
│   ├── GameStore.swift               @AppStorage singleton
│   └── InMemoryPlayerRepository.swift  PlayerRepository implementation
│
├── Views — Navigation
│   ├── RootView.swift
│   ├── MainTeamView.swift
│   └── GameView.swift                Phase router (PreGame/Active/Break/Post)
│
├── Views — Game Flow
│   ├── PreGameView.swift
│   ├── ActiveGameView.swift
│   ├── SubstitutionOverlayView.swift
│   ├── PeriodBreakView.swift
│   └── PostGameView.swift
│
├── Views — Team Management
│   ├── SetupTeamView.swift
│   ├── EditTeamView.swift
│   ├── RosterView.swift
│   ├── AddEditPlayerView.swift
│   ├── GameListView.swift
│   ├── GameDetailView.swift
│   ├── AddEditGameView.swift
│   ├── AvailabilityView.swift
│   └── EventEditView.swift           EventKit calendar integration
│
├── Design System
│   ├── ThemeManager.swift
│   ├── ThemePicker.swift
│   └── CAppDesignSystem/
│       ├── Theme/Theme.swift          AppColors, AppTypography, AppSpacing, …
│       └── Components/
│           ├── AppButton_Themed.swift
│           ├── AppCard.swift
│           └── PlayerRow.swift
│
└── Statistics
    └── Statistics.swift
```
