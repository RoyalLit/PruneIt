# PruneIt — Agent Guidelines & Instructions (AGENTS.md)

Welcome to **PruneIt**. This document defines the operating contract, architectural boundaries, design taste standards, and engineering rules for all autonomous and pair-programming AI agents (Antigravity, Claude Code, Cursor, Copilot, Codex, etc.).

All agents working on this repository **MUST** read, understand, and adhere to this document.

---

## 1. Project Overview & Philosophy

**PruneIt** is a native macOS storage workbench built with Swift and SwiftUI. It discovers developer build artifacts, application caches, AI models, simulator runtimes, and system debris, safely moving them to the Trash or removing them through verified system tools.

PruneIt was forked from `purge-app` by Jithin Sabu (MIT License) and is maintained at [RoyalLit/PruneIt](https://github.com/RoyalLit/PruneIt).

### Core Values
1. **Deletion Safety is Sacred**: PruneIt deletes user files. Deletion safety takes priority over aesthetics, speed, and all other goals. Under no circumstances should safety checks be bypassed.
2. **Anti-Slop Design Taste**: We build a **Precision Developer Workbench** (Framed Sheet aesthetic). No bubbly cartoon cards, no 7-color rainbow bars, no heavy drop shadows. We maintain a restrained 3–5% color budget on data only, hairline 1px borders, and tabular monospaced digits.
3. **Fact-Grounded Engineering**: Inspect real code before making changes. Avoid speculative abstractions. Maintain minimal viable diffs. Run design linting and unit tests on every change.

---

## 2. Repository Layout & Architecture

```
PruneIt/
├── PruneIt/                     # Main SwiftUI Application
│   ├── Views/                   # UI views and component hierarchy
│   │   ├── OverviewView.swift   # Dashboard (Storage Strata, Horizon Deck, Ledger)
│   │   ├── DevModeView.swift    # Developer Tools workbench
│   │   ├── GeneralModeView.swift# App Caches workbench
│   │   ├── ScanResultRow.swift  # Inspected workbench row component
│   │   ├── SafetyFilterBar.swift# Segmented safety filter bar
│   │   └── EverythingElseView.swift # System, models, snapshots
│   ├── Services/                # Scanners, Policies, and Deletion Engine
│   │   ├── FileDeleter.swift    # Core deletion mechanism (moves to Trash)
│   │   ├── DeletionSafetyPolicy.swift # Critical safety gatekeeper
│   │   ├── SafetyTierList.swift # Safety tiers and category rules
│   │   └── *Scanner.swift       # Artifact and cache scanners
│   ├── Models/                  # Data structures and catalogs
│   │   ├── SafetyInfo.swift     # SafetyLevel enum (.safe, .medium, .unknown)
│   │   └── ProjectArtifactCatalog.swift # Known artifact locations
│   ├── Theme/                   # Design Tokens
│   │   ├── AppColors.swift      # Semantic colors, Spruce accent, Chart palette
│   │   ├── AppStyle.swift       # Typography styles and layout metrics
│   │   └── AppDimensions.swift  # Spacing, padding, corner radii
│   └── Resources/
│       └── explanations.json    # Human-readable path explanations and rebuild info
├── PruneItTests/                # Swift Testing suite (@Test, #expect)
│   └── Support/                 # ThrowawayDefaults, FakeScans test helpers
├── scripts/
│   ├── lint-design-tokens.mjs   # Strict design token linter (enforces AppStyle)
│   ├── check-localization.py    # Verifies String(localized:) keys
│   └── make-dmg.sh              # Production DMG packaging script
├── docs/
│   ├── design-system.md         # Detailed design token documentation
│   ├── taste-skill.md           # Anti-slop frontend taste guidelines
│   ├── safety-notes.md          # Historical safety incident log
│   └── ARCHITECTURE.md          # In-depth architectural design
├── AGENTS.md                    # This document (Agent instruction master)
├── RULES.md                     # Strict engineering and styling rules
└── TASKS.md                     # Roadmap and living task backlog
```

---

## 3. Invariants & Safety Guardrails (CRITICAL)

### Invariant 1: Deletion Safety Engine is Immutable
- **NEVER** edit `PruneIt/Services/FileDeleter.swift` or `PruneIt/Services/DeletionSafetyPolicy.swift` as part of a UI or feature PR.
- Every cache and developer debris removal **must** pass through `DeletionSafetyPolicy.evaluate(_:)`.
- Deletions move files to the macOS Trash (`FileManager.default.trashItem(at:resultingItemURL:)`).
- Simulators, simulator runtimes, Time Machine snapshots, and package manager tools are removed permanently via system tools (`xcrun simctl`, `tmutil`, `brew`) and **must** be clearly surfaced as permanent in the UI.

### Invariant 2: Design Token Enforcement
- Every text element must use `AppStyle.Typography` (e.g. `AppStyle.Typography.rowTitle`, `AppStyle.Typography.micro`).
- Raw `.system(size:)` is strictly prohibited and fails `node scripts/lint-design-tokens.mjs`.
- All byte quantities, counts, and dates must append `.monospacedDigit()`.
- Maximum 3–5% color budget on data only (Spruce `#1B6C80` / `#2EA3BE` as primary brand accent).

### Invariant 3: Localization & Accessibility
- Wrap every user-visible string in `String(localized:)`.
- Provide meaningful accessibility labels or hide decorative elements (`.accessibilityHidden(true)`).

### Invariant 4: Test Isolation
- **NEVER** write or delete from real user directories during tests.
- Always use `ThrowawayDefaults` and `FakeScans` from `PruneItTests/Support/`.

---

## 4. Verification & Testing Matrix

Before finishing any task or opening a pull request, run the following verification checks:

| Check | Command | Environment |
|---|---|---|
| **Design Token Linter** | `node scripts/lint-design-tokens.mjs` | Node.js (All platforms) |
| **Localization Check** | `python3 scripts/check-localization.py` | Python 3 (All platforms) |
| **Build App** | `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` | macOS with Xcode |
| **Targeted Unit Tests** | `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -only-testing:PruneItTests/OverviewPresentationTests` | macOS with Xcode |
| **Full Unit Tests** | `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` | macOS with Xcode |
| **Build DMG** | `bash scripts/make-dmg.sh` | macOS |

---

## 5. Agent Workflow & Lifecycle

1. **Orientation**:
   - Check `TASKS.md` for current phase, active task, and priorities.
   - Review `RULES.md` for coding, styling, and git rules.
2. **Investigation**:
   - Trace the exact code path before proposing edits.
   - Check existing design tokens in `AppColors.swift` and `AppStyle.swift`.
3. **Implementation**:
   - Write clean, modular, minimal diffs.
   - Respect the Framed Sheet / Precision Workbench visual standard.
4. **Validation**:
   - Run `node scripts/lint-design-tokens.mjs`.
   - Run targeted tests for the modified views or models.
5. **Documentation & Handoff**:
   - Update `TASKS.md` with status of completed items.
   - Commit with Conventional Commit formatting (e.g. `feat: modernize scan result row with workbench styling`).
