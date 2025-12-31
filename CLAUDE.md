# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenkiDo (元気道) is an iOS app for food and fitness tracking. It combines meal photo capture with daily exercise tracking, inspired by martial arts discipline.

## Technology Stack

- **Platform:** iOS 26+ (Swift 6.0 / SwiftUI)
- **Persistence:** SwiftData with CloudKit sync via App Group
- **Project Generation:** XcodeGen (project.yml)
- **Widget:** WidgetKit extension for home screen

## Build Commands

```bash
# Regenerate Xcode project after modifying project.yml
xcodegen generate

# Build for device
xcodebuild -scheme GenkiDo -destination 'platform=iOS,id=DEVICE_ID' -allowProvisioningUpdates build

# Install on device
xcrun devicectl device install app --device DEVICE_ID ~/Library/Developer/Xcode/DerivedData/GenkiDo-*/Build/Products/Debug-iphoneos/GenkiDo.app

# Run tests
xcodebuild test -scheme GenkiDo -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

MVVM architecture with SwiftData for persistence:

- **Models/** - SwiftData `@Model` classes and enums
  - `Exercise.swift` - Enum with 5 exercises (4 regular + 1 timed)
  - `ExerciseRecord.swift` - Daily exercise completion tracking
  - `Meal.swift` - Meal with compressed photo data and timestamp
  - `DayRecord.swift` - Computed daily status aggregation

- **Views/** - SwiftUI views organized by feature
  - `Food/` - Meal tracking with camera capture (FAB button)
  - `Fitness/` - Exercise tracking with timer support
  - `History/` - Day-by-day history with streak tracking
  - `Components/` - CameraView, ProgressRing

- **Services/**
  - `CloudKitService.swift` - iCloud sync status
  - `ImageCompressor.swift` - Photo compression (800px, 50% quality)

- **GenkiDoWidget/** - Home screen widget extension

## Exercises

| Exercise | Type | Goal |
|----------|------|------|
| Pushups | Regular | 50 reps |
| SL Deadlifts | Regular | 50 reps |
| Towel Rows | Regular | 50 reps |
| Squats | Regular | 50 reps |
| Planks | Timed | 60 seconds |

Planks has a countdown timer with screen wake lock (`isIdleTimerDisabled`).

## Business Logic

- **Fasting cutoff:** 18:00 - meals after this time are flagged
- **Day completion:** All 5 exercises done AND no meal after 18:00
- **Streaks:** Current streak and longest streak tracked in History view
- **Photo compression:** Max 800px, 50% JPEG quality (~50-150 KB per photo)

## Widget

- Small & Medium sizes supported
- Shows exercise completion (X/5) and fasting status
- Uses App Group (`group.ch.budo-team.GenkiDo`) for shared data
- Updates when app goes to background

## Development Notes

- German is the primary UI language
- Photo data uses `@Attribute(.externalStorage)` for efficient storage
- App Group required for widget data access
- Camera captures directly to app (no photo library access)
