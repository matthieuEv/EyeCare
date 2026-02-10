# EyeCare

[![CI](https://github.com/matthieuEv/EyeRest/actions/workflows/ci.yml/badge.svg)](https://github.com/matthieuEv/EyeRest/actions/workflows/ci.yml)

EyeCare is a macOS menu bar app that reminds you to rest your eyes using a fullscreen-safe border cue across all displays.

## Why

The app is built around the 20-20-20 principle: every 20 minutes, look at something far away for about 20 seconds.

## Features

- Menu bar app (`LSUIElement`) with no Dock icon
- Enable/disable reminders in one click
- Live countdown in the menu
- Adjustable reminder interval (`1` to `240` minutes)
- Adjustable cue duration (`1` to `30` seconds)
- Accent color selector for reminder border
- Optional office-hours mode (including overnight ranges)
- Multi-display support (one border overlay per screen)
- Settings persisted locally via `UserDefaults`

## Install on macOS (from Releases)

1. Open the [Releases](https://github.com/matthieuEv/EyeRest/releases) page.
2. Download the latest `EyeCare-<version>.dmg` asset.
3. Open the DMG.
4. Drag `EyeCare.app` to `/Applications`.
5. Launch `EyeCare.app`.
6. If macOS blocks first launch (unsigned app), right-click the app, choose `Open`, then confirm.

## Requirements (development from source)

- macOS `13` or newer
- Xcode Command Line Tools (`xcode-select --install`)
- Swift `6.0+` toolchain (tested with Xcode `16.2`)

## Quick Start

```bash
git clone git@github.com:matthieuEv/EyeRest.git
cd EyeRest
swift test
./scripts/package-app.sh
./scripts/reinstall-app.sh --user
```

The app bundle is generated at `dist/EyeCare.app`.

## Development Commands

### Build (debug)

```bash
swift build
```

### Run tests

```bash
swift test
```

### Build a release `.app` bundle

```bash
./scripts/package-app.sh
```

### Reinstall quickly during local development

```bash
./scripts/reinstall-app.sh --user
```

Useful flags:
- `--user`: install in `~/Applications` (no admin rights)
- `--skip-build`: reuse current `dist/EyeCare.app`
- `--no-open`: do not launch app after install

## CI

GitHub Actions is split into two workflows:

- Code checks (`.github/workflows/ci.yml`)
  - Trigger: every `push` and `pull_request`
  - Runs `swift build` + `swift test` on `macos-14` and `macos-15`
- Release (`.github/workflows/release.yml`)
  - Trigger: tag push only
  - Builds `dist/EyeCare.app`, archives it, and publishes a GitHub Release

For tagged releases, app version fields in `Info.plist` are injected from the tag:
- `CFBundleShortVersionString`: from tag (example `v1.2.3` -> `1.2.3`)
- `CFBundleVersion`: GitHub Actions run number

## Contributing

1. Fork the repository.
2. Create a branch from `main`.
3. Run `swift test` locally.
4. Open a pull request with a clear change description.

## Notes

- The packaged app is unsigned by default.
- Reminder settings are stored locally on your machine.
