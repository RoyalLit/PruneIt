# PruneIt — Roadmap & Task Tracker (TASKS.md)

This living document tracks the execution phases, active tasks, backlog, and verification requirements for **PruneIt**. All AI agents and developers should update the status checkboxes and notes as work progresses.

**Current Milestone**: `v1.12.0 — Precision Workbench Redesign`  
**Current Active Phase**: **Phase 2: Modernize Detail Screens (Dev Tools & App Caches)**

---

## Progress Overview

| Phase | Description | Status | Completion |
|---|---|---|---|
| **Phase 1** | Brand Separation, Repo Setup & Overview Redesign | ✅ COMPLETED | 100% |
| **Phase 2** | Detail Screens Modernization (Dev Tools & App Caches) | 🔄 IN PROGRESS | 0% |
| **Phase 3** | Specialized Workbenches (AI Models, Time Machine, Uninstaller) | ⏳ QUEUED | 0% |
| **Phase 4** | Quick-Prune Menu Bar Extra | ⏳ QUEUED | 0% |
| **Phase 5** | Release Packaging, Distribution & Homebrew | ⏳ QUEUED | 0% |

---

## Phase 1: Brand Separation & Overview Redesign (COMPLETED)

- [x] **1.1 Identity & Brand Scrubbing**:
  - [x] Renamed all references from `purge-app` to `PruneIt` across source files, plists, asset catalogs, and build scripts.
  - [x] Renamed root project, target schemes, tests, and worker helpers.
  - [x] Created clean git history and pushed to [RoyalLit/PruneIt](https://github.com/RoyalLit/PruneIt).
- [x] **1.2 Overview Dashboard Overhaul (`OverviewView.swift`)**:
  - [x] Replaced generic 7-color rainbow bar with **Storage Strata (The Prune Horizon)**: 3 functional architectural zones (`Living System`, `Prunable Debris`, `Available Capacity`).
  - [x] Built **Reclaimable Yield Horizon Deck** with tabular monospaced lead figures and instant clean/scan primary actions (`OverviewCleanSafeButton`, `OverviewScanButton`).
  - [x] Replaced squircle cards with **Pruning Ledger** rows featuring directory scope badges (`~/Library/Developer`, `~/Library/Caches`), live status chips, and drilldown chevrons.
  - [x] Merged fragmented cards into **Guarded System Allocations** for Time Machine snapshots and AI models.
  - [x] Modernized `AppColors.Chart` tokens with Spruce anchor (`#1B6C80` / `#2EA3BE`).
- [x] **1.3 Quality & Release Verification**:
  - [x] `node scripts/lint-design-tokens.mjs` passing with 0 warnings.
  - [x] `OverviewPresentationTests` and `OverviewBreakdownTests` passing.
  - [x] Production DMG built and verified (`build/PruneIt-1.12.0.dmg`).
  - [x] Full Disk Access permission loop verified and resolved.

---

## Phase 2: Modernize Detail Screens (ACTIVE FOCUS)

The goal of Phase 2 is to carry the Framed Sheet / Precision Workbench aesthetic into the detail inspection screens: **Developer Tools** and **App Caches**.

- [ ] **Task 2.1: Modernize `ScanResultRow.swift` (Inspected Workbench Row)**:
  - [ ] Replace bulky card containers with 1px hairline-bordered workbench rows (`AppColors.borderHairline`).
  - [ ] Add subtle hover state (`AppColors.cardBackground` to hover highlight) with smooth transition.
  - [ ] Design inline monospaced directory path badges (e.g. `DerivedData`, `iOS DeviceSupport`, `node_modules`).
  - [ ] Modernize safety level tags with restrained chips:
    - Safe: Spruce subtle background + hairline border (`AppColors.Safety.safeBackground`).
    - Review / Medium: Soft Amber subtle background (`AppColors.Safety.mediumBackground`).
  - [ ] Display file sizes and item counts with monospaced tabular figures (`.monospacedDigit()`).
  - [ ] Hairline checkbox styling aligned with workbench grid.
- [ ] **Task 2.2: Redesign `SafetyFilterBar.swift` (Precision Filter Track)**:
  - [ ] Replace bubbly toggle buttons with a precision segmented track.
  - [ ] Subtle Spruce indicator for active filter state.
  - [ ] Compact badges showing item counts per safety category.
- [ ] **Task 2.3: Modernize `DevModeView.swift` (Developer Tools Workbench)**:
  - [ ] Group headers with engineering context (e.g. last build age, total artifact count, rebuild explanation).
  - [ ] Batch actions header (Select All, Deselect All, Reclaimable Total in tabular mono font).
  - [ ] Clean table structure without distracting drop shadows.
- [ ] **Task 2.4: Modernize `GeneralModeView.swift` (App Caches Workbench)**:
  - [ ] High-density workbench table for application and system caches.
  - [ ] Grouping by domain (Browsers, System Caches, Developer Logs).
  - [ ] Inline explanation affordance showing rebuild behavior and safety notes.
- [ ] **Task 2.5: Design Verification & Targeted Tests**:
  - [ ] Run `node scripts/lint-design-tokens.mjs`.
  - [ ] Run targeted unit tests (`DevToolsPresentationTests`, `AppCachesPresentationTests`).
  - [ ] Verify dark and light mode contrast.

---

## Phase 3: Specialized Workbenches (QUEUED)

- [ ] **Task 3.1: AI Models Workbench (`AIModelsView.swift` / `EverythingElseView.swift`)**:
  - [ ] Dedicated runtime view for Ollama, LM Studio, Hugging Face checkpoints.
  - [ ] Display parameters, quantization levels (e.g. `Q4_K_M`), context lengths, and VRAM/disk footprints.
  - [ ] Clear safety distinction: warn users that deleted models must be re-downloaded.
- [ ] **Task 3.2: Time Machine & System Snapshots**:
  - [ ] Monospaced list of APFS local snapshots with creation timestamps and size deltas.
  - [ ] Explicit permanent deletion confirmation modal for snapshot pruning.
- [ ] **Task 3.3: App Uninstaller Detail View**:
  - [ ] Modernize residual leftover file discovery view (`Application Support`, `LaunchAgents`, `Preferences`).
  - [ ] Root helper privilege status indicator.

---

## Phase 4: Quick-Prune Menu Bar Extra (QUEUED)

- [ ] **Task 4.1: Status Bar Applet**:
  - [ ] Lightweight `NSStatusItem` / `MenuBarExtra` companion.
  - [ ] 1-click prune for Xcode DerivedData, build logs, and stale simulator caches.
  - [ ] Live reclaimable badge counter in menu bar.

---

## Phase 5: Release Packaging, Distribution & Homebrew (QUEUED)

- [ ] **Task 5.1: GitHub Release v1.12.0**:
  - [ ] Draft release notes highlighting the Precision Workbench redesign.
  - [ ] Attach notarized production DMG with SHA-256 checksum.
- [ ] **Task 5.2: Homebrew Cask Formula**:
  - [ ] Create `homebrew-tap` formula for `brew install --cask pruneit`.
- [ ] **Task 5.3: Sparkle Automatic Updates**:
  - [ ] Configure Sparkle public EdDSA key and host `appcast.xml`.

---

## Verification Checklist for Every PR

Before committing or pushing any changes:
1. [ ] `node scripts/lint-design-tokens.mjs` exits with 0 problems.
2. [ ] `python3 scripts/check-localization.py` exits with 0 missing strings.
3. [ ] Targeted unit tests succeed via `xcodebuild`.
4. [ ] No modifications made to `FileDeleter.swift` or `DeletionSafetyPolicy.swift`.
5. [ ] Commit message conforms to Conventional Commits format.
