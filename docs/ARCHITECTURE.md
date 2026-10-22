# PruneIt Architecture

This document describes the architecture of **PruneIt**, explaining its target structure, scanning engine, safety invariant model, in-use detection, deletion mechanisms, system integrations, and recommended starting files.

---

## 1. Folder & Target Structure

PruneIt is organized into 5 targets in `PruneIt.xcodeproj`:

| Target | Directory | Role & Description |
|---|---|---|
| **PruneIt** (App) | `PruneIt/` | The primary macOS SwiftUI application. Houses UI views (`Views/`), the centralized reactive state store (`Services/PruneItStore.swift`), high-level orchestrators (`Services/`), utilities, and assets. Handles user interaction, scheduling, and standard deletion. |
| **PruneItHelper** | `PruneItHelper/` | A privileged helper tool designed to run via `SMJobBless` or `SMAppService.daemon`. Invoked via XPC (`HelperService.swift`) when deletion requires root/elevated permissions (e.g. system-level caches or files left behind by uninstalled applications owned by `root`). |
| **PruneItWatch** | `PruneItWatch/` | A lightweight background agent (`SMAppService.agent` or Login Item) that monitors `/Applications` and Trash events via `FSEvents` (`ApplicationsFolderWatcher.swift`, `PruneItWatchMain.swift`). When an app is dragged to Trash, it triggers an orphan leftover scan and alerts the user to clean up leftovers. |
| **PruneItAssetWorker** | `PruneItAssetWorker/` | A specialized auxiliary XPC service (`PruneItAssetWorkerMain.swift`, `UnifiedAssetCalls.swift`) that interacts with system asset management routines and CacheDelete frameworks to safely identify and delete Apple Intelligence assets and system caches out-of-process. |
| **PruneItTests** | `PruneItTests/` | Unit and integration test suite. Contains test cases asserting safety invariant rules (`SafetyTierListTests`, `DeletionSafetyPolicyTests`), simulated file trees (`ThrowawayDefaults`, `FakeScans`), and mock service fixtures. Tests run without touching user directories. |

Additional top-level folders:
- `Assets/`: Graphic assets, icons, and branding.
- `scripts/`: Operational scripts (e.g. `make-dmg.sh`, localization validators, token linters).
- `spikes/`: Standalone proof-of-concept experiments (e.g. Apple Intelligence model access).
- `docs/`: Design system tokens, safety notes, and architecture guides.

---

## 2. Scanning Engine & UI Streaming

Scanning in PruneIt is modular, non-blocking, and streamed to the UI:

### Scanners & Policies
Each scanning domain has a dedicated Scanner and Policy pair living in `PruneIt/Services/`:
- **Developer Caches**: `DevScanner.swift` scans Xcode DerivedData, SPM caches, CocoaPods, Carthage, Gradle, Android build artifacts, Rust `target/`, and package manager caches.
- **Application Caches**: `CacheScanner.swift` scans `~/Library/Caches` with exclusions.
- **Orphan Leftovers**: `OrphanLeftoverScanner.swift` & `OrphanLeftoverScanPolicy.swift` inspect `~/Library/Application Support`, `~/Library/Containers`, and `Preferences` for bundles whose parent app is no longer in `/Applications`.
- **Large Files**: `LargeFileScanner.swift` & `LargeFileScanPolicy.swift` traverse user folders for large files exceeding configurable size thresholds.
- **Command-Line Tools**: `CommandLineToolScanner.swift` & `CommandLineToolScanPolicy.swift` scan Homebrew, MacPorts, and standalone binary paths.
- **Apple Intelligence Models**: `AIModelScanner.swift` & `AppleIntelligenceModelReader.swift` scan system-allocated foundation model storage.

### Asynchronous Streaming to the UI
1. Scanning tasks are coordinated through `PruneItStore+ScanQueue.swift`.
2. The orchestrator executes scanners asynchronously via Swift Concurrency (`Task` / `TaskGroup`).
3. As items are discovered, they are filtered against exclusions and safety policies.
4. Items are committed in batches to `PruneItStore` (`ObservableObject`), updating `@Published` properties (e.g., `devItems`, `cacheItems`, `orphanItems`, `largeFileItems`).
5. SwiftUI views (`OverviewView`, `DevModeView`, `GeneralModeView`, `UninstallView`, `LargeFilesView`) observe `PruneItStore` and re-render progressively with animation and running byte totals without freezing the main thread.

---

## 3. Safety Allowlist & Invariant Protections

Because PruneIt deletes user files, **deletion safety takes precedence over every other goal**:

### Core Safety Definitions
- **`PruneIt/Services/DeletionSafetyPolicy.swift`**: The central rulebook governing whether a path can ever be deleted. Enforces checks against critical operating system directories, user root folders, iCloud synced documents, and key configuration locations.
- **`PruneIt/Services/SafetyTierList.swift`**: Categorizes every cleanable path into safety tiers (e.g., `safe`, `review`, `danger`). Items in `review` or `danger` require explicit user opt-in before selection.
- **`PruneIt/Services/SafetyAllowlistSummary.swift`**: Defines explicit path prefixes and bundle identifiers that are certified safe for cache deletion.
- **`PruneIt/Services/ScanExclusions.swift`**: Explicit list of never-touch directory names, system containers, and user document paths that are pruned immediately during scanning before reaching the UI.

### Invariant Rules
- No scanner or deletion path may use wildcards that resolve to `~`, `/`, `/System`, `/Library`, `/Applications`, or top-level `/Users`.
- All decisions return a strictly-typed `DeletionSafetyDecision` enum. Switch statements over safety levels never use `default:`.

---

## 4. "In-Use" Detection Mechanisms

Before an item can be selected or deleted, PruneIt verifies that it is not actively being read or written by another program:

- **Open File & Process Checks (`OpenFileCheck.swift`)**: Uses kernel-level inspection (`proc_pidinfo` / system process table) and `lsof` lookups to detect if an active application or daemon holds an open descriptor on the target folder or any nested file.
- **Git Activity Checks (`GitStatusChecker.swift`)**: For developer directories and repository caches, checks whether the git repo has uncommitted changes, active merges, rebases, or detached worktrees. Never deletes build artifacts if worktree dirty state indicates active editing.
- **Project Activity Policy (`ProjectActivityPolicy.swift`)**: Examines lock files (`package-lock.json`, `Cargo.lock`, `yarn.lock`, `pnpm-lock.yaml`), editor metadata (`.vscode`, `.idea`), and recent `mtime` modification timestamps to detect active developer sessions.

---

## 5. Deletion & Trash Mechanics

File removal is implemented in `PruneIt/Services/FileDeleter.swift`:

### Standard Deletion (Trash)
- By default, files are **never deleted permanently**.
- They are sent to the macOS user Trash via `NSWorkspace.shared.recycle` or `FileManager.default.trashItem(at:resultingItemURL:)`.
- The user can inspect the Trash and recover items if desired.
- Reported space is split into `bytesMovedToTrash` (pending reclamation upon emptying trash) vs true volume reclaimed delta (`bytesReclaimedOnVolume`).

### Permanent Deletion Exceptions
Certain categories of items cannot be moved to the Trash by macOS and require specialized command-line tools:
1. **Simulator Runtimes & Devices**: Managed by Xcode's CoreSimulator daemon. Handled via `xcrun simctl delete <UDID>` and `xcrun simctl runtime delete <identifier>` (wrapped in `Simctl.swift` with timeouts and verification polling).
2. **Local Time Machine Snapshots**: Handled via `tmutil deletelocalsnapshots <snapshot_date>` in `LocalSnapshotStore.swift`.
3. **Apple Intelligence Models & System Caches**: Handled via out-of-process CacheDelete / asset requests in `PruneItAssetWorker`.

---

## 6. System Integrations (Sparkle, FDA, Login Items)

- **Sparkle Updates (`PruneItUpdater.swift`)**: Integrates Sparkle 2.x via `SPUStandardUpdaterController`. Configured via `Info.plist` keys (`SUFeedURL`, `SUPublicEDKey`, and `SUEnableAutomaticChecks`). In PruneIt, automatic update checks are disabled until independent EdDSA keys and release feeds are established.
- **Full Disk Access (`ScanAccess.swift`)**: Probes readable status of system-protected TCC directories (`~/Library/Safari`, `~/Library/Mail`). If access is denied, surfaces guidance panels directing the user to **System Settings > Privacy & Security > Full Disk Access**.
- **Login Items & Launch Services (`LoginItemRegistrar.swift`, `StartupPreferenceStore.swift`)**: Uses macOS modern Service Management (`SMAppService.mainApp` and `SMAppService.agent`) to configure background execution cleanly without legacy deprecated login item APIs.

---

## 7. The 10 Files You Should Read First

1. **`PruneIt/Services/PruneItStore.swift`**: The brain of the application; manages scan queues, overall UI state, item listings, and clean triggers.
2. **`PruneIt/Services/DeletionSafetyPolicy.swift`**: Safety-critical core defining all deletion barriers and never-delete rules.
3. **`PruneIt/Services/FileDeleter.swift`**: The execution engine that executes Trash transfers, volume delta measurements, and simctl exceptions.
4. **`PruneIt/Services/SafetyTierList.swift`**: Defines safety tiers, risk levels, and UI confirmation requirements for each category.
5. **`PruneIt/Services/DevScanner.swift`**: The most extensive scanner; demonstrates how developer caches and build folders are traversed and categorized.
6. **`PruneIt/Services/OrphanLeftoverScanner.swift`**: Shows how uninstalled application traces are matched against current `/Applications` entries.
7. **`PruneIt/Services/ScanAccess.swift`**: Full Disk Access checking logic and sandbox/permission boundaries.
8. **`PruneIt/Services/OpenFileCheck.swift`**: How active process holding and file locks are validated before cleaning.
9. **`PruneIt/Views/AppRootView.swift`**: Root SwiftUI view showing the visual hierarchy, sidebar modes, and navigation.
10. **`PruneItTests/SafetyTierListTests.swift`**: The primary safety regression tests; shows which safety invariants must never be broken.
