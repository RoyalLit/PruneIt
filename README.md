# PruneIt

> *Built with purpose by Pahul.*

**PruneIt** is a native macOS app that finds developer caches, build artifacts, orphaned app leftovers, large files, simulator runtimes, and Apple Intelligence models — and moves them to the Trash (or removes them permanently where the system requires it). It runs entirely on-device with no subscriptions and no telemetry.


## Features

- **Precision Developer Workbench (New)**:
  - **Storage Strata (The Prune Horizon)**: 3-tier architectural capacity breakdown (`Living System`, `Prunable Debris`, `Available Capacity`) replacing generic rainbow bars.
  - **Reclaimable Yield Horizon Deck**: Bold, monospaced tabular metrics with instant clean and scan actions.
  - **Pruning Ledger**: Directory-scoped ledger rows (`~/Library/Developer`, `~/Library/Caches`) with live status chips and drilldown affordances.
  - **Guarded System Allocations**: Dedicated, guarded panels for Time Machine snapshots and local AI foundation models.
- **Cache Cleaner** — Dev caches (`node_modules`, `DerivedData`, `.gradle`, etc.) governed by a strict three-tier safety allowlist (`.safe`, `.medium`, `.unknown`).
- **App Uninstaller** — Removes app bundles and their leftover support files (`Application Support`, `Containers`, `Preferences`), even without Full Disk Access.
- **Large Files** — Scans for disk space hogs above configurable size thresholds with thumbnail previews.
- **Developer Tools** — Safely removes Xcode Simulator runtimes, local AI models (Ollama, LM Studio), and command-line tools.
- **Everything Else** — Treemap visualization of system allocations and personal files.
- **Scheduled Cleaning** — Automatic background or 1-click cleanup of `.safe`-tier caches.
- **Menu Bar Mode** — Lightweight status-bar applet for instant pruning.

---

## Installing PruneIt

> **Note:** PruneIt is distributed as an unsigned `.dmg` via GitHub Releases for now.
> macOS Gatekeeper will warn you the first time.

### Steps

1. Download the latest `.dmg` from [Releases](https://github.com/RoyalLit/PruneIt/releases).
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
  -project PruneIt.xcodeproj \
  -scheme PruneIt \
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
  -project PruneIt.xcodeproj \
  -scheme PruneIt \
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
| `PruneIt/` | Main SwiftUI app target |
| `PruneIt/Services/` | Scanners, safety policy, deletion engine |
| `PruneIt/Models/` | Data models |
| `PruneIt/Views/` | SwiftUI views |
| `PruneItHelper/` | Privileged XPC helper (root-owned uninstall) |
| `PruneItWatch/` | Background LaunchAgent that monitors deleted apps |
| `PruneItAssetWorker/` | XPC worker for Apple Intelligence model release calls |
| `PruneItTests/` | Unit tests (Swift Testing framework) |
| `docs/` | Architecture notes, safety log, design system |
| `scripts/` | Build, lint, and localization tools |

---

## Agent & Developer Documentation

PruneIt provides first-class documentation and operational guardrails for human contributors and autonomous AI agents:

| Guide | Description |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Universal agent operating instructions, invariants, architecture map, and verification matrix. |
| [`RULES.md`](RULES.md) | Engineering standards, design taste rules (anti-slop, 3–5% color budget), and deletion policies. |
| [`TASKS.md`](TASKS.md) | Living project roadmap, active redesign tasks, and verification checklist. |
| [`GEMINI.md`](GEMINI.md) | Fast-bootstrap configuration for Gemini and Google Antigravity agents. |
| [`CLAUDE.md`](CLAUDE.md) | Quick command reference and rules for Claude Code. |
| [`.agents/rules/`](.agents/rules/) | Modular rule definitions discovered by agent customization engines. |
| [`docs/design-system.md`](docs/design-system.md) | Complete design token reference (Spruce palette, typography, button styles, radii). |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | In-depth architectural design, scanning pipelines, and target layout. |
| [`docs/safety-notes.md`](docs/safety-notes.md) | Forensic incident log and historical safety audits. |

---

## Safety

Deletion safety is the top priority. Every path goes through `DeletionSafetyPolicy.evaluate(_:)` before any file is touched. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#deletion-and-trash-handling) for details, and [`docs/safety-notes.md`](docs/safety-notes.md) for the incident log.

**Never modify the safety allowlist, scanner logic, or `FileDeleter` without running the full test suite.**

---


## Author

**Pahul** ([@RoyalLit](https://github.com/RoyalLit))  
*Built with purpose by Pahul for macOS developers.*

---

## License

MIT — see [LICENSE](LICENSE).

