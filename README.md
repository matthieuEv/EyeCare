# EyeCare

macOS menu bar app that shows a red break cue on all screens at regular intervals to remind you to rest your eyes.

## Features

- Background app (menu bar icon)
- Quick enable/disable from the menu
- Countdown to the next break directly in the menu
- Interval setting (minutes) directly from the menu
- Break cue duration setting (seconds) directly from the menu
- Break cue shown above windows and full-screen apps
- Multi-display support (one break cue per screen)

## Run tests

```bash
swift test
```

## Debug build

```bash
swift build
```

## Build `.app` bundle

```bash
./scripts/package-app.sh
```

The bundle is created at `dist/EyeCare.app`.
The Finder icon is loaded from `resources/AppIcon.icns` and copied into the app bundle during packaging.

## Fast uninstall + reinstall loop

```bash
./scripts/reinstall-app.sh
```

Useful options:

- `--user` to install in `~/Applications` (no admin rights needed)
- `--skip-build` to reuse the bundle already generated in `dist/`
- `--no-open` to avoid opening the app right after installation
