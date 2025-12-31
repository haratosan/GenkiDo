# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenkiDo (元気道) is an iOS app for food and fitness tracking. It combines meal photo capture with daily exercise tracking, inspired by martial arts discipline.

## Technology Stack

- **Platform:** iOS 26+ (Swift 6.0 / SwiftUI)
- **Persistence:** SwiftData with CloudKit sync
- **Project Generation:** XcodeGen (project.yml)
- **AI:** Vision Framework / Core ML (planned for meal analysis)

## Build Commands

```bash
# Regenerate Xcode project after modifying project.yml
xcodegen generate

# Build the project
xcodebuild -scheme GenkiDo -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test -scheme GenkiDo -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

MVVM architecture with SwiftData for persistence:

- **Models/** - SwiftData `@Model` classes and enums
  - `Exercise.swift` - Enum with 4 exercise types (50 reps goal each)
  - `ExerciseRecord.swift` - Daily exercise completion tracking
  - `Meal.swift` - Meal with photo data and timestamp
  - `DayRecord.swift` - Computed daily status aggregation

- **Views/** - SwiftUI views organized by feature
  - `Food/` - Meal tracking with photo capture
  - `Fitness/` - Exercise counters with progress rings
  - `Components/` - Reusable UI components

- **ViewModels/** - `@Observable` view models
- **Services/** - CloudKit service for sync status

## Business Logic

- **Fasting cutoff:** 18:00 - meals after this time are flagged
- **Daily goal:** 50 repetitions per exercise (4 exercises total)
- **Day completion:** All 4 exercises done AND no meal after 18:00

## Development Notes

- German is the primary UI language
- Photo data uses `@Attribute(.externalStorage)` for efficient storage
- SwiftData with `cloudKitDatabase: .automatic` handles iCloud sync
