# Daybook

A personal daily companion for iPhone and iPad. It greets you differently every day based on the time and the day of the week, and keeps the small daily stuff in one place.

## What's inside

- **Today**: a greeting that changes with the hour and the weekday (and birthdays and holidays), today's date, a day-progress ruler, weather with sunrise and sunset, today's tasks, habit check-ins, water, mood, a quote, a daily challenge, a fun fact, upcoming countdowns and "on this day" memories.
- **Tasks**: today, tomorrow or a later date. Unfinished tasks carry over automatically.
- **Habits**: streaks, best runs and a tappable week strip to fill in a missed day.
- **Journal**: a daily prompt, mood, one line and notes, a two-week mood chart and past entries.
- **More**: focus timer (with a notification when it ends), box breathing, countdowns, the year so far, and settings.
- **Morning greeting** notification and a **home screen widget** (small and medium).
- Three looks: **Paper** (warm paper and ink), **Bold** (black and signal orange) and **Retro** (amber CRT terminal).

Everything is stored on the device. Weather comes from [Open-Meteo](https://open-meteo.com), which needs no account or key.

## Getting the .ipa

Every push to `main` runs the **Build** workflow, which makes an unsigned `Daybook.ipa` and attaches it to the **latest** release. Download it and import it into eSign to sign and install.

The same workflow builds for the simulator and uploads screenshots of every screen in each theme on iPhone and iPad.

## Building locally

```sh
brew install xcodegen
xcodegen generate
open Daybook.xcodeproj
```

Launch arguments for testing: `-theme paper|bold|retro`, `-startTab 0-4`, `-demoData YES` (in-memory sample data).
