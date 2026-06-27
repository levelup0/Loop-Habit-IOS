# LoopHabits iOS

iOS port of [Loop Habit Tracker](https://loophabits.org/) — built with SwiftUI + SwiftData.

**Requires:** Xcode 15+, iOS 17+

## MVP Features

- Create habits with name, colour, days of week
- Check off today's habits from the main list
- Streak counter per habit
- 13-week calendar history grid (tap any past day to toggle)
- 90-day completion rate
- Persistent storage via SwiftData (no account needed)

## Setup

```bash
git clone git@github.com:levelup0/Loop-Habit-IOS.git
open LoopHabits.xcodeproj
```

Select a simulator or device → Run (⌘R).

## Structure

```
LoopHabits/
├── LoopHabitsApp.swift        # entry point + SwiftData container
├── Models/
│   └── Habit.swift            # Habit + HabitEntry SwiftData models
├── Extensions/
│   └── Color+Hex.swift        # Color init from hex string
└── Views/
    ├── HabitListView.swift    # main list with today's checkboxes
    ├── HabitRowView.swift     # single habit row
    ├── AddHabitView.swift     # create habit sheet
    └── HabitDetailView.swift  # stats + 13-week calendar grid
```

## Roadmap

- [ ] Local notifications / reminders
- [ ] Numeric habits (e.g. "8 glasses of water")
- [ ] Widget (WidgetKit)
- [ ] CSV export
- [ ] Dark / AMOLED theme tweaks
