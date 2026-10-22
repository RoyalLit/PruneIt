# PruneIt

**PruneIt** is a native macOS app that finds developer caches, build artifacts, orphaned app leftovers, large files, simulator runtimes, and Apple Intelligence models — and moves them to the Trash (or removes them permanently where the system requires it). It runs entirely on-device with no subscriptions and no telemetry.

> **Status:** Early release. Built on the [purge-app](https://github.com/jithin-sabu/purge-app) open-source core (MIT Licensed). See [Acknowledgements](#acknowledgements).

---

## Features

- **Cache Cleaner** — dev caches (`node_modules`, `DerivedData`, `.gradle`, etc.) with a three-tier safety allowlist
- **App Uninstaller** — removes app bundles and their leftover support files, even without Full Disk Access
- **Large Files** — scans for files above a configurable threshold, with thumbnail preview
- **Dev Tools** — removes Simulator runtimes, Apple Intelligence models, command-line tools managed by Homebrew/npm/pipx/uv/cargo
- **Everything Else** — treemap view of large folders
- **Scheduled Cleaning** — one-click or scheduled automatic cleanup of `.safe`-tier caches
- **Menu Bar Mode** — optional status-bar icon with a mini-panel

---

## Installing PruneIt

> **Note:** PruneIt is distributed as an unsigned `.dmg` via GitHub Releases for now.
> macOS Gatekeeper will warn you the first time.

### Steps

1. Download the latest `.dmg` from [Releases](https://github.com/YOUR_GITHUB/pruneit/releases).
2. Open the `.dmg` and drag **PruneIt.app** to your **Applications** folder.
3. Try to open PruneIt. macOS will say **"PruneIt" cannot be opened because it is from an unidentified developer**.
4. Go to **System Settings → Privacy & Security** and click **Open Anyway** next to the PruneIt warning.
5. Open PruneIt again and click **Open** in the confirmation dialog.

### Granting Full Disk Access (required for full scan coverage)

PruneIt will guide you through this on first launch. Or go manually:

**System Settings → Privacy & Security → Full Disk Access → enable PruneIt**

### "PruneIt is damaged and can't be opened" fix

If you get a "damaged app" message, run this once in Terminal:

```sh
xattr -cr /Applications/PruneIt.app
```

Then try opening it again.

### Verifying the download (SHA-256)

Each release includes a `.sha256` file next to the `.dmg`. Verify with:

```sh
shasum -a 256 -c PruneIt-<version>.dmg.sha256
```

---

## Building from source

### Requirements

- macOS 13 or later
- Xcode 16 or later

### Build (Debug)

```sh
xcodebuild build \
  -project purge.xcodeproj \
  -scheme purge \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### Build (Release DMG)

```sh
bash scripts/make-dmg.sh
```

The `.dmg` and a `.sha256` checksum file will be written to `build/`.

### Run tests

```sh
xcodebuild test \
  -project purge.xcodeproj \
  -scheme purge \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

---

## Project structure

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for a full walkthrough.

| Path | Purpose |
|---|---|
| `purge/` | Main SwiftUI app target |
| `purge/Services/` | Scanners, safety policy, deletion engine |
| `purge/Models/` | Data models |
| `purge/Views/` | SwiftUI views |
| `PurgeHelper/` | Privileged XPC helper (root-owned uninstall) |
| `PurgeWatch/` | Background LaunchAgent that monitors deleted apps |
| `PurgeAssetWorker/` | XPC worker for Apple Intelligence model release calls |
| `PurgeTests/` | Unit tests (Swift Testing framework) |
| `docs/` | Architecture notes, safety log, design system |
| `scripts/` | Build, lint, and localization tools |

---

## Safety

Deletion safety is the top priority. Every path goes through `DeletionSafetyPolicy.evaluate(_:)` before any file is touched. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#deletion-and-trash-handling) for details, and [`docs/safety-notes.md`](docs/safety-notes.md) for the incident log.

**Never modify the safety allowlist, scanner logic, or `FileDeleter` without running the full test suite.**

---

## Acknowledgements

PruneIt is built on **[purge-app](https://github.com/jithin-sabu/purge-app)** by [Jithin Sabu](https://github.com/jithin-sabu), used under the [MIT License](LICENSE). The scanning engine, deletion safety system, UI architecture, and all core logic originate from that project. We are grateful for the excellent open-source work.

---

## License

MIT — see [LICENSE](LICENSE).
