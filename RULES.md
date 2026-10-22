# PruneIt — Engineering & Design Rules (RULES.md)

This document specifies the strict design, code quality, safety, and git rules that must be followed by all contributors and AI agents working on **PruneIt**.

---

## 1. Visual Design & Taste Rules (Anti-Slop Standard)

PruneIt uses the **Framed Sheet / Precision Developer Workbench** design aesthetic inspired by modern, high-craft developer tools.

### 1.1 Color Budget (3–5% Max)
- **Neutral Core (95%)**: Backgrounds, surfaces, cards, and text use monochromatic architectural slate and zinc tones.
  - Primary Background: `AppColors.background`
  - Card/Workbench Surface: `AppColors.cardBackground`
  - Hairline Border: `AppColors.borderHairline` (1px opacity-adjusted border)
- **Brand Accent (Spruce)**: Used sparingly for high-intent actions and active states.
  - Light mode: `#1B6C80`
  - Dark mode: `#2EA3BE`
  - Subtle background fill: `AppColors.accentPruneSubtle`
  - Accent border: `AppColors.accentPruneBorder`
- **Semantic Safety Tints**: Never use bright neon candy badges.
  - Safe to Clean: Subtle Spruce tint (`AppColors.Safety.safeBackground`), foreground `AppColors.Safety.safeForeground`.
  - Check First (Medium): Soft Amber tint (`AppColors.Safety.mediumBackground`), foreground `AppColors.Safety.mediumForeground`.
  - Not Sure / System Danger: Subdued Crimson/Red tint (`AppColors.Safety.unknownBackground`).

### 1.2 Elevation & Surfaces
- **No Heavy Drop Shadows**: Avoid large blurred shadows that make macOS apps feel like ungrounded web popups.
- **Hairline Framing**: Use crisp 1px borders (`AppColors.borderHairline` or `.overlay(RoundedRectangle(...).stroke(AppColors.borderHairline, lineWidth: 1))`).
- **Corner Radii**: Standardize on `AppDimensions.cardCornerRadius` (10pt) for cards, and `AppDimensions.buttonCornerRadius` (6pt) for buttons/badges.

### 1.3 Typography & Tabular Numerals
- **No raw `.system(size:)`**: All text must use the design system tokens defined in `AppStyle.Typography`:
  - `pageTitle`: Large screen headers
  - `sectionTitle`: Group headers
  - `rowTitle`: Primary row labels
  - `caption`: Explanatory descriptions and secondary info
  - `micro`: Badges, status chips, path scopes (10pt semibold)
- **Tabular Figures**: Every byte size, item count, percentage, and timestamp **must** specify `.monospacedDigit()`. Numbers must not jitter or shift when values update.
- **Monospaced Paths**: Directory paths and shell locations must use monospaced fonts (e.g. `Font.system(size: 11, design: .monospaced)` or badge components) to reinforce the developer-tool feel.

---

## 2. SwiftUI & Swift Code Standards

### 2.1 Enums & Pattern Matching
- **No Wildcard `default:` on Safety Enums**: When switching over `SafetyLevel`, `DeletionSafetyDecision`, or `ScanCategory`, **every case must be listed explicitly**. Using `default:` is prohibited because new cases added in the future must force a compiler failure until reviewed.

### 2.2 Localization
- **All User-Facing Strings Must Be Localized**:
  ```swift
  // Correct
  Text(String(localized: "Safe to Clean"))
  
  // Incorrect
  Text("Safe to Clean")
  ```
- Run `python3 scripts/check-localization.py` to verify localization coverage.

### 2.3 State Management & Performance
- Avoid placing heavy computational logic in SwiftUI view bodies.
- Scanners must run asynchronously in background tasks and publish snapshots to the main thread via `@MainActor`.
- Keep view bodies small and composable; extract subcomponents for rows, chips, and headers.

---

## 3. Deletion Safety Invariants

PruneIt deletes user files; a single bug can delete user source code or irrecoverable OS state.

1. **Gatekeeper Enforcement**: Every deletion **must** be evaluated by `DeletionSafetyPolicy.evaluate(_:)`. No direct invocation of `FileManager` deletion is permitted outside `FileDeleter.swift`.
2. **Move to Trash**: Regular caches and developer build artifacts are moved to the Trash (`FileManager.default.trashItem`) so users can recover them if needed.
3. **Explicit Warnings for Permanent Deletions**:
   - Xcode Simulator runtimes, Time Machine local snapshots, and Homebrew tools cannot be trashed; they are permanently deleted via their respective CLI tools (`simctl`, `tmutil`).
   - The UI must explicitly warn the user before executing these actions.
4. **Safety Level Semantics**:
   - `.safe`: Artifacts that can be automatically regenerated on next build/run without human intervention (e.g., Xcode DerivedData, build logs, SPM caches).
   - `.medium`: Items that require developer context (e.g., archived apps, old simulators, tool caches that take significant time to re-download).
   - `.unknown`: Items not fully recognized or that could contain user-modified assets. Requires manual user review.

---

## 4. Testing & CI Standards

1. **Swift Testing Framework**: All new tests should use the modern Swift Testing framework (`@Test`, `#expect`) rather than legacy XCTest where applicable.
2. **Sandbox Safety**: Tests must **never** read or write to actual user directories (`~`, `/Library`, `/Applications`). Always use:
   - `ThrowawayDefaults` for UserDefaults isolation.
   - `FakeScans` and mock directories in temporary sandboxes.
3. **Targeted Testing for Rapid Iteration**:
   - To test changes to presentation views:
     `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -only-testing:PruneItTests/OverviewPresentationTests`

---

## 5. Git & Commit Guidelines

1. **Conventional Commits**: Commit messages must follow the Conventional Commits specification:
   - `feat:` New features or UI overhauls
   - `fix:` Bug fixes or corrections
   - `docs:` Documentation or guideline updates
   - `refactor:` Code restructuring without behavioral changes
   - `test:` Adding or updating unit tests
   - `ci:` Workflow or script modifications
2. **Commit Message Format**:
   ```
   feat(views): modernize scan result row with workbench styling

   - Add 1px hairline container with subtle hover feedback
   - Display inline monospaced path badges for scan items
   - Apply restrained spruce/amber safety chips
   - Enforce monospaced digits on byte metrics
   ```
3. **No Unrelated Scope Creep**: Keep commits focused and atomic. Never mix UI refactoring with safety policy changes.
