# PruneIt - Comprehensive Audit Action Plan

*Generated from multi-agent audit (Security, Performance, UI/UX, Accessibility, Product, Code Quality, Release Engineering)*  
*Date: 2026-10-23 | Commit: 4dba51f | Version: 1.12.0*

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [P0 - Critical Blockers (Must Fix Before Public Release)](#p0---critical-blockers-must-fix-before-public-release)
- [P1 - High Impact (Fix Soon)](#p1---high-impact-fix-soon)
- [P2 - Important Improvements](#p2---important-improvements)
- [P3 - Nice to Have](#p3---nice-to-have)
- [Additional P1 Findings (Security, Performance, UX)](#additional-p1-findings-security-performance-ux)
- [Additional P2 Findings](#additional-p2-findings)
- [Additional P3 Findings](#additional-p3-findings)
- [Appendix A: Quick Reference Commands](#appendix-a-quick-reference-commands)
- [Appendix B: Key Files Reference](#appendix-b-key-files-reference)

---

## Executive Summary

PruneIt is a well-engineered, safety-conscious macOS storage cleaner. The core guardrails (central `DeletionSafetyPolicy`, Trash-by-default, careful privileged helper design, symlink defenses) are solid. However, there are critical gaps in **release/distribution** (unsigned ad-hoc builds, CI red, no notarization), **performance bottlenecks** (store publication/churn causing UI invalidation), and several **UX/accessibility** issues.

**Top 3 Immediate Priorities:**
1. **Release Readiness** - Fix CI (Xcode 26.5 on macos-26), implement Developer ID signing + notarization, protect `main` branch
2. **Deletion Safety Consistency** - Enforce global policy in `deleteUserSelectedFiles()` and reconsider uninstall pre-selection defaults
3. **Performance** - Fix cache-scan flush churn and store-wide `@Published` invalidation (biggest source of UI stutter)

---

## Findings at a Glance

| # | Finding | Severity | Effort |
| --- | --- | --- | --- |
| 1 | Fix CI to Xcode 26.5 + protect main | P0 | S |
| 2 | Developer ID signing + notarization + stapling | P0 | L |
| 3 | Fix privileged helper registration for signed builds | P0 | M |
| 4 | Enforce global policy in `deleteUserSelectedFiles()` | P0 | S |
| 5 | Fix ScanResultRow selection accessibility | P0 | S |
| 6 | Fix DevMode project checkbox labeling | P0 | S |
| 7 | Fix textTertiary contrast (≥4.5:1) | P0 | S/M |
| 8 | Optimize cache-scan flush churn | P1 | M |
| 9 | Fix store-wide invalidation | P1 | L |
| 10 | Fix EverythingElse per-progress invalidation | P1 | S |
| 11 | Reconsider uninstall pre-selection defaults | P1 | S/M |
| 12 | Add scan cancel affordance | P1 | M |
| 13 | Fix "All" safety filter / `.unknown` | P1 | S |
| 14 | Use skeletons during scans | P1 | S |
| 15 | Add Trash recovery UI | P1 | M |
| 16 | Add helper service tests | P1 | M |
| 17 | Complete Phase 2 UI redesign | P2 | M |
| 18 | Optimize LargeFiles/DevMode render passes | P2 | M |
| 19 | Optimize treemap layout | P2 | M |
| 20 | Add Dynamic Type support | P2 | L |
| 21 | Fix localization gaps | P2 | S/M |
| 22 | Homebrew Cask + Sparkle enablement | P2 | M |
| 23 | Export cleanup history | P2 | S |
| 24 | Split large files / reduce duplication | P2 | L |
| 25 | Add `.stringsdict` plurals | P3 | S |
| 26 | Duplicate detection outside Large Files | P3 | M |
| 27 | Docker/browser deep cleanup | P3 | M |
| 28 | Swift 6 + `@Observable` migration | P3 | L |
| 29 | Reject cleartext HTTP in Sparkle | P1 | S |
| 30 | Remove vendored `sign_update` | P1 | M |
| 31 | Authenticate watch-agent notifications | P1 | M |
| 32 | Align helper/app Preferences policy | P1 | S |
| 33 | Symlink resolution in safety policy | P1 | M |
| 34 | Report hidden/refused cleanup entries | P1 | S |
| 35 | Stop Trash 30s `du` polling | P1 | S |
| 36 | Cache `ByteCountFormatter` | P1 | S |
| 37 | Non-blocking `FolderSizing` | P1 | M |
| 38 | Reduce `DevScanner` syscall amplification | P1 | M |
| 39 | Stop re-sorting large files every 25 rows | P1 | S |
| 40 | Memoize `GitStatusChecker` lookup | P1 | S |
| 41 | Fix doc drift / broken links | P2 | S |
| 42 | xcconfig versioning / stale plists | P2 | S |
| 43 | Remove icon build-phase mutation | P2 | S |
| 44 | DMG layout / universal / verification | P2 | M |
| 45 | dSYM retention / crash triage | P2 | S |
| 46 | Add `PrivacyInfo.xcprivacy` | P2 | S |
| 47 | Fix UX copy and empty states | P2 | S |
| 48 | Missing `.monospacedDigit()` | P2 | S |
| 49 | Menu bar a11y + localization | P2 | S |
| 50 | Expand localization checker | P2 | S |
| 51 | `.stringsdict` + locale-aware bytes | P2 | S |
| 52 | Multi-volume / purgeable space | P3 | M |
| 53 | iOS backup + Docker/browser cleanup | P3 | M/L |
| 54 | Swift 6 strict concurrency | P3 | L |

**Effort key:** S = under 1 day, M = 1–5 days, L = 1–2+ weeks.

**How to use this document:** Work top-down within each priority tier. Every item states what is wrong, why it matters, why it is worth fixing, and how to fix it with verification steps. P0 items are release blockers; do not ship a public build until all P0 items are resolved.

---

## P0 - Critical Blockers (Must Fix Before Public Release)

These issues must be resolved before any public distribution. They affect security, Gatekeeper compliance, core functionality, or accessibility compliance.

### 1. Fix CI to use Xcode 26.5 on macos-26 and protect main branch
| Field | Value |
| --- | --- |
| **Category** | Release Engineering / CI |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `.github/workflows/build.yml`, GitHub repo settings |
| **Effort** | S (Small) |

#### What is the issue?
All 10 recent CI runs have failed. The codebase uses macOS 26 APIs like `.safeAreaBar` (wrapped in `@available(macOS 26.0, *)` in `AppChrome.swift:77`), but CI runs on `macos-15` with Xcode 16.4 which doesn't have these symbols. Additionally, `main` branch has no protection rules.

#### Why is it an issue?
- No merge gate exists - broken code can be merged to main
- Cannot verify builds/tests in CI
- Blocks any automated release pipeline
- Gives false confidence in release readiness

#### Why solve it?
CI must be green and enforced before shipping. This is foundational for all other release work.

#### How to solve it?
1. Update `.github/workflows/build.yml` to use `runs-on: macos-26`
2. Add `maxim-lobanov/setup-xcode@v1` with `xcode-version: '26.5'`
3. Add `permissions: { contents: read }`, `concurrency` settings, and `timeout-minutes`
4. Enable branch protection on `main` requiring lint, build, and test checks to pass
5. Update `README.md` to state "Xcode 26 or later" (currently says "Xcode 16 or later")

**Verification:** Push a test PR and confirm all checks pass.

---


### 2. Implement Developer ID signing, hardened runtime, notarization and stapling
| Field | Value |
| --- | --- |
| **Category** | Release Engineering / Security |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt.xcodeproj/project.pbxproj`, `scripts/make-dmg.sh`, all target Info.plists |
| **Effort** | L (Large) |

#### What is the issue?
The built app is ad-hoc/linker-signed (`Signature=adhoc`), `Info.plist` not bound to code directory, `codesign --verify --deep --strict` fails. DMG is unsigned and not notarized. Users must run `xattr -cr` to open it.

#### Why is it an issue?
- Defeats Gatekeeper security model
- Privileged helper cannot register (requires proper code signing with Developer ID)
- PruneItWatch and PruneItAssetWorker cannot function properly
- Unacceptable for distribution of a file-deletion tool
- Users rightfully distrust unsigned apps that delete files

#### Why solve it?
Proper signing and notarization is required for a trustworthy macOS distribution. It's also required for the privileged helper and Sparkle updates to work.

#### How to solve it?
1. **Setup:** Obtain Developer ID Application certificate, create ASC API key for notarytool
2. **Project config:** Create `Config/Signing.xcconfig` and `Config/Version.xcconfig`, update all targets (app, helper, watch, assetworker) to use Developer ID signing with hardened runtime enabled
3. **Build flow:** Switch to `xcodebuild archive` → `xcodebuild -exportArchive` with `ExportOptions.plist` (method: `developer-id`)
4. **Verify signatures:** Script to verify all nested binaries (helper, watch, assetworker, Sparkle) are signed with Developer ID and have runtime flag
5. **Notarize:** Submit app zip to notarytool, wait for approval, staple with `xcrun stapler staple`
6. **DMG:** Rewrite `make-dmg.sh` to create proper layout with background, sign DMG, notarize DMG, staple DMG, verify with `spctl`
7. **Universal binary:** Build for both `arm64` and `x86_64`

**Verification:** `spctl -a -vvv -t exec PruneIt.app` should show "accepted", `codesign --verify --deep --strict` should pass with no errors.

---


### 3. Fix privileged helper registration for signed builds
| Field | Value |
| --- | --- |
| **Category** | Security / Functionality |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt/PrivilegedHelper/PrivilegedHelperManager.swift`, `PruneIt/PrivilegedHelper/PruneItHelperProtocol.swift`, `PruneItHelper/*` |
| **Effort** | M (Medium) |

#### What is the issue?
The helper requires specific code signing (team `BX83ZBV95B`, anchor apple generic, certificate leaf with specific OU). In ad-hoc builds, `clientRequirement` and `helperRequirement` checks fail, so `SMAppService.daemon.register()` fails silently. Protected App Removal and root-owned cleanup don't work.

#### Why is it an issue?
This is a core feature - removing apps that leave root-owned files behind. If it doesn't work, users can't fully uninstall applications. The failure is silent with only NSLog.

#### Why solve it?
Must work in properly signed distribution. Also need graceful handling if helper isn't available.

#### How to solve it?
1. Ensure all signing is consistent (app and helper signed with same team/certificate chain)
2. Add proper error surfacing in UI when helper registration fails
3. Test helper registration flow on clean machine post-signing: `sudo launchctl print system/com.pahul.pruneit.helper`
4. Add verification in settings to show helper status clearly
5. Consider making team ID configurable via build settings instead of hardcoded

**Verification:** In signed build, helper registers successfully, protected app removal works, `launchctl` shows the service loaded.

---


### 4. Enforce global DeletionSafetyPolicy in deleteUserSelectedFiles()
| Field | Value |
| --- | --- |
| **Category** | Security / Safety |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt/Services/FileDeleter.swift:461-545`, `PruneIt/Services/DeletionSafetyPolicy.swift` |
| **Effort** | S (Small) |

#### What is the issue?
`deleteUserSelectedFiles()` uses per-feature eligibility gates (`isEligibleForDeletion`, `isEligibleForUninstallDeletion` etc.) but never calls `DeletionSafetyPolicy.evaluate()`. The global safety policy is bypassed.

#### Why is it an issue?
If any per-feature gate has a logic bug (symlink handling, prefix matching error, etc.), files could be deleted without passing the central safety choke point. The global policy is the ultimate backstop - bypassing it violates defense-in-depth.

#### Why solve it?
The deletion safety engine must be the single source of truth. No code path should bypass it.

#### How to solve it?
In `deleteUserSelectedFiles()`, after determining feature eligibility, add:
```swift
guard case .allow = DeletionSafetyPolicy.evaluate(url) else {
    skippedItems.append(SkippedDeletionItem(path: url.path, displayName: friendlyTitle, reason: "Blocked by global deletion policy", isUserVisible: true))
    continue
}
```
Keep feature gates as "can be offered" but make global policy the final gate.

**Verification:** Add unit test attempting to delete a path blocked by global policy through this path - should be skipped.

---


### 5. Fix ScanResultRow selection accessibility
| Field | Value |
| --- | --- |
| **Category** | Accessibility (WCAG) |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt/Views/ScanResultRow.swift:219-249` |
| **Effort** | S (Small) |

#### What is the issue?
The checkbox toggle has `.labelsHidden()`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`. The row has `accessibilityAction` for toggling but no `accessibilityValue`, no `accessibilityAddTraits(.isSelected)`. VoiceOver users cannot tell if an item is selected.

#### Why is it an issue?
This is the core cleanup flow - users must be able to select items to delete. Blind/low-vision users cannot use the app properly. This is likely a WCAG violation.

#### Why solve it?
Accessibility is required for a professional app and is the right thing to do.

#### How to solve it?
```swift
.accessibilityElement(children: .combine)
.accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
```
Keep the whole-row tap action. Add localized strings "Selected"/"Not selected" to Localizable.strings.

**Verification:** Test with VoiceOver - selecting/deselecting should be announced, selection state should be readable.

---


### 6. Fix DevMode project checkbox labeling
| Field | Value |
| --- | --- |
| **Category** | Accessibility (WCAG) |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt/Views/DevModeView.swift:1112-1120` |
| **Effort** | S (Small) |

#### What is the issue?
`TriStateCheckbox(title: "", state: ...)` has empty title and no accessibility label. Project group "select all" checkboxes are unlabeled for VoiceOver.

#### Why is it an issue?
Users cannot understand what the checkbox controls. Same core flow issue as #5.

#### Why solve it?
Required for accessibility compliance.

#### How to solve it?
Add localized accessibility label: `String(format: String(localized: "Select all items in %@"), group.displayName)`. Add key to Localizable.strings and zh-Hans.

**Verification:** VoiceOver should announce "Select all items in [Project Name]" when focusing the checkbox.

---


### 7. Fix textTertiary contrast to meet WCAG AA (≥4.5:1)
| Field | Value |
| --- | --- |
| **Category** | Accessibility (WCAG) |
| **Severity** | P0 - Critical Blocker |
| **Affected Files** | `PruneIt/Theme/AppColors.swift:20,143-165` |
| **Effort** | S/M (Small/Medium) |

#### What is the issue?
`textTertiary` colors fail contrast requirements:
- Light: `#85827C` on `#F6F5F3` = 3.52:1 (needs ≥4.5:1)
- Worse with opacity: `0.6` gives ~1.99:1, `0.3` gives ~1.38:1
Used for sentence text in Overview, sheets, etc.

#### Why is it an issue?
WCAG AA requires 4.5:1 for normal text. Low vision users cannot read secondary text. Using opacity to dim text compounds the problem.

#### Why solve it?
Accessibility compliance is required.

#### How to solve it?
1. Change light mode `textTertiary` to `#6B6863` (~5.09:1) or darker
2. Adjust dark mode `textTertiary` to meet ≥4.5:1 on all surfaces
3. **Never** use opacity on readable sentence text - use proper color tokens instead
4. Audit all `opacity()` on text and replace with semantic color tokens
5. Add high-contrast mode support where feasible

**Verification:** Use Accessibility Inspector to verify all text meets ≥4.5:1 contrast ratio.

---


## P1 - High Impact (Fix Soon)

These issues significantly impact user experience, safety, or maintainability. Should be addressed after P0 blockers.

### 8. Optimize cache-scan flush (eliminate 6-pass churn every 140ms)
| Field | Value |
| --- | --- |
| **Category** | Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/PruneItStore.swift:4064-4386` |
| **Effort** | M (Medium) |

#### What is the issue?
Every 140ms during cache scan, `flushCacheScanBuffers` does 6 full passes over the entire collection: append, apply sizes, group, dedupe, filter, publish, reconcile. Each pass does `standardizedFileURL.path` lookups (syscalls). With 5000 items and ~215 flushes, that's ~1300 traversals + 10000 realpath calls.

#### Why is it an issue?
Causes main-thread stutter/freeze during scanning. Multiplied by store-wide invalidation.

#### Why solve it?
Major performance improvement for core scanning functionality.

#### How to solve it?
1. Cache normalized path on `CacheLocation` (computed once at creation) instead of recomputing
2. Incremental deduplication - only check new items against index, not full list
3. Skip expensive passes (grouping/dedup/filter) when it's just size updates
4. Maintain `publishedByID: [String: CacheItem]` incrementally instead of rebuilding
5. Only run full pipeline when new items are found

**Verification:** Profile with Instruments Time Profiler during scan - flush time should drop significantly.

---


### 9. Fix store-wide invalidation (split observables or use @Observable)
| Field | Value |
| --- | --- |
| **Category** | Performance / Architecture |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/PruneItStore.swift:205-465` |
| **Effort** | L (Large) |

#### What is the issue?
~40 `@Published` properties on one `ObservableObject`. Any mutation sends `objectWillChange` for the whole object, invalidating every view observing it.

#### Why is it an issue?
Multiplies all performance costs. A cache scan flush re-renders Overview, Dev Tools, Uninstaller, Everything Else, etc. even if their data unchanged.

#### Why solve it?
Foundation for good performance across the app.

#### How to solve it?
**Option A (incremental):** Split into feature stores/coordinators - `ScanCoordinator`, `DeletionCoordinator`, `UninstallCoordinator`, `LargeFileCoordinator`. Keep facade.
**Option B (modern):** Migrate to `@Observable` macro where deployment target allows (macOS 14+). This gives per-property tracking.

Start with Option A incrementally to reduce risk.

**Verification:** SwiftUI instrument should show body counts drop dramatically for unrelated views during scans.

---


### 10. Fix EverythingElse measurement invalidating store per progress chunk
| Field | Value |
| --- | --- |
| **Category** | Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/PruneItStore+EverythingElse.swift:92-101` |
| **Effort** | S (Small) |

#### What is the issue?
`everythingElseMeasurement = measurement` is assigned on every event before checking if it's `.progress`, causing store-wide invalidation for every chunk.

#### Why is it an issue?
Hundreds of invalidations during measurement, each triggering treemap layout work.

#### Why solve it?
Easy fix with big impact on Everything Else tab.

#### How to solve it?
```swift
measurement.apply(event)
if case .progress = event { 
    measurementProgress = measurement.progress // separate published property
    continue 
}
everythingElseMeasurement = measurement
everythingElseMeasurementRevision &+= 1
```
Publish progress separately.

**Verification:** Count store invalidations during measurement - should drop from ~hundreds to ~number of roots.

---


### 11. Reconsider uninstall pre-selection defaults
| Field | Value |
| --- | --- |
| **Category** | Security / UX |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/AppUninstallScanner.swift:232`, `PruneIt/Services/AppUninstallScanPolicy.swift:277-295` |
| **Effort** | S/M (Small/Medium) |

#### What is the issue?
Items matched by `bundleID`/`groupID` are marked `.safe` and pre-selected. This includes Application Support, Preferences, Containers, Group Containers etc. which often contain user data (logins, settings, documents).

#### Why is it an issue?
High blast radius - user can accidentally delete important app data. While Trash allows recovery until emptied, it's easy to miss. Dot-folders are already handled correctly (unticked).

#### Why solve it?
Safer defaults prevent accidents. "Safe to regenerate" vs "user data" distinction is important.

#### How to solve it?
1. Default-select only pure caches: `.caches`, `.httpStorages`, `.logs`
2. Require explicit opt-in for: `.applicationSupport`, `.preferences`, `.containers`, `.groupContainers`, `.savedState`, `.launchAgents`
3. Add category summary before confirmation: "You're about to remove X items (Y caches, Z settings) totaling N"
4. Consider changing defaults to untick everything and let user opt-in
5. Add stronger warnings for categories containing settings/data

**Verification:** Uninstall a test app - only caches should be pre-selected.

---


### 12. Add scan cancel affordance
| Field | Value |
| --- | --- |
| **Category** | UX |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Views/AppChrome.swift:285-319`, `PruneIt/Menu/MenuBarView.swift` |
| **Effort** | M (Medium) |

#### What is the issue?
No way to cancel scans once started (except maybe Overview "Scan Everything" has "Stop"). `scanPhase.cancelling` state exists but UI doesn't use it. Long scans on large drives are frustrating.

#### Why is it an issue?
Users need control over long-running operations. Poor UX.

#### Why solve it?
Important usability improvement.

#### How to solve it?
1. Update `AppScanButton` to show "Stop"/"Cancel" when scanning
2. Wire to scan cancellation API in store
3. Show progress/cancelling state
4. Disable clean actions while cancelling
5. Add cancel to menu bar
6. Ensure cancellation actually stops work (check scanner cancellation)

**Verification:** Start a large scan, click cancel, verify it stops within reasonable time.

---


### 13. Fix "All" safety filter to include/explain .unknown
| Field | Value |
| --- | --- |
| **Category** | UX / Safety |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Views/SafetyFilterBar.swift:24` |
| **Effort** | S (Small) |

#### What is the issue?
`SafetyFilter.matches` silently excludes `.unknown` from every filter including `.all`. The label says "All" which is misleading.

#### Why is it an issue?
Users expect "All" to show everything. Items marked `.unknown` (not fully recognized) are hidden by default and users don't know they exist. This could cause confusion and misses items that need review.

#### Why solve it?
Clarity and safety - unknown items need explicit attention.

#### How to solve it?
**Option A:** Include `.unknown` in "All" filter
**Option B:** Relabel to "Safe + Medium", add explicit "Unknown (review)" filter with warning badge/tooltip explaining these need manual review

Option B is safer - makes unknown items visible but clearly marked as needing review.

**Verification:** Check all filters show correct counts, unknown items appear in their filter.

---


### 14. Use skeletons during scans
| Field | Value |
| --- | --- |
| **Category** | UX / Perceived Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Views/ScanListSkeletonPlaceholder.swift`, `PruneIt/Views/GeneralModeView.swift:415`, `PruneIt/Views/DevModeView.swift:769`, `PruneIt/Views/LargeFilesView.swift:594-599` |
| **Effort** | S (Small) |

#### What is the issue?
During scanning, App Caches and Dev Tools show blank `Color.clear` with just accessibility labels. Skeleton component exists but isn't used.

#### Why is it an issue?
Poor perceived performance - looks broken/frozen even though scanning is happening.

#### Why solve it?
Easy win using existing component. Much better UX.

#### How to solve it?
Replace `Color.clear` placeholders with `ScanListSkeletonPlaceholder()` or create tab-specific skeletons. Large Files has better handling but could also benefit.

**Verification:** Start scan on App Caches tab - should show skeleton rows, not blank space.

---


### 15. Add Trash recovery UI
| Field | Value |
| --- | --- |
| **Category** | Product / Safety |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/TrashStore.swift`, `PruneIt/Views/*` (new view) |
| **Effort** | M (Medium) |

#### What is the issue?
Files go to Trash (good for safety) but there's no way to view/restore them from within PruneIt. Users must open Finder.

#### Why is it an issue?
Reduces confidence in the app. If someone accidentally deletes something, they have to leave the app to recover it. Also makes the Trash integration feel incomplete.

#### Why solve it?
Better safety net and more complete UX.

#### How to solve it?
1. Add "Trash" section/view to browse items in Trash
2. Show items moved by PruneIt (track via TrashStore/CleanupLedger)
3. Allow selecting and restoring items where possible (use `FileManager` or AppleScript/Finder APIs)
4. Show warnings about items emptied by user
5. Add to sidebar or settings

**Verification:** Delete items via PruneIt, open Trash view, restore an item, verify it comes back.

---


### 16. Add tests for PrivilegedHelper/HelperService
| Field | Value |
| --- | --- |
| **Category** | Quality / Security |
| **Severity** | P1 - High |
| **Affected Files** | `PruneItHelper/HelperService.swift`, new test files |
| **Effort** | M (Medium) |

#### What is the issue?
HelperService (runs as root, does privileged file operations) has no tests. This is critical security code.

#### Why is it an issue?
Bugs in helper could cause incorrect permissions, failed operations, or security issues. No regression protection.

#### Why solve it?
Critical for security and reliability.

#### How to solve it?
Create tests for:
1. Admin peer validation
2. Path allowlist checks (uninstall locations, install leftovers)
3. Symlink rejection
4. Chown recursion logic
5. renameatx_np operations
6. Trash validation
7. Error handling

Use fakes/mocks for file system operations where possible.

**Verification:** Tests pass, cover critical security checks.

---


## P2 - Important Improvements

### 17. Complete Phase 2 UI redesign
| Field | Value |
| --- | --- |
| **Category** | UI |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Views/ScanResultRow.swift`, `PruneIt/Views/SafetyFilterBar.swift`, `PruneIt/Views/DevModeView.swift`, `PruneIt/Views/GeneralModeView.swift` |
| **Effort** | M (Medium) |

#### What is the issue?
Phase 2 is in progress but not complete. Items like workbench row styling, precision segmented filter track, improved headers haven't been fully applied.

#### Why is it an issue?
Inconsistent design between Overview (redesigned) and detail screens.

#### Why solve it?
Polish the app to match the "Precision Developer Workbench" vision.

#### How to solve it?
Follow TASKS.md Phase 2.1-2.4:
1. Modernize ScanResultRow with hairline borders, hover states, inline badges, monospaced digits
2. Redesign SafetyFilterBar as precision segmented track
3. Polish DevModeView headers and batch actions
4. Polish GeneralModeView grouping and explanations

**Verification:** Design lint passes, visual consistency across screens.

---


### 18. Optimize LargeFilesView and DevModeView render passes
| Field | Value |
| --- | --- |
| **Category** | Performance / UI |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Views/LargeFilesView.swift`, `PruneIt/Views/DevModeView.swift` |
| **Effort** | M (Medium) |

#### What is the issue?
Both views recompute filters/sorts/counts multiple times per body pass (LargeFilesView does ~10x scans per render).

#### Why is it an issue?
Input lag during search, sluggish UI.

#### Why solve it?
Follow the pattern already used in GeneralModeView (`makeListPlan()`).

#### How to solve it?
Create cached view models/plans computed once per body pass or keyed by dependencies, do all filtering/sorting/counting in single pass.

**Verification:** Search in LargeFilesView should feel responsive with 10k files.

---


### 19. Optimize treemap layout
| Field | Value |
| --- | --- |
| **Category** | Performance / UI |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Models/TreemapLayout.swift`, `PruneIt/Views/EverythingElseView.swift` |
| **Effort** | M (Medium) |

#### What is the issue?
Layout computed in view body with O(n²) squarify algorithm (`row + [item]` creates arrays), deep comparison on every change.

#### Why is it an issue?
Janky resizing, wasted work.

#### Why solve it?
Better performance for Everything Else tab.

#### How to solve it?
1. Compute layout outside body, cache by `(breakdownRevision, size)`
2. Make squarify incremental with running sums (no array concatenation)
3. Use identity comparison instead of deep comparison
4. Avoid rebuilding on every body pass

**Verification:** Resize window smoothly, measure layout time.

---


### 20. Add Dynamic Type support
| Field | Value |
| --- | --- |
| **Category** | Accessibility |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Views/AppStyle.swift`, all views |
| **Effort** | L (Large) |

#### What is the issue?
All typography uses fixed `Font.system(size:)`. No support for system text size preferences.

#### Why is it an issue?
Users with vision impairments can't increase text size. Accessibility requirement.

#### Why solve it?
Important accessibility improvement.

#### How to solve it?
1. Use `@ScaledMetric` for sizes or relative fonts
2. Use `Font.system(.body).weight(...)` with text styles
3. Allow text wrapping, adjust row heights for larger sizes
4. Test at accessibility sizes

**Verification:** Increase text size in System Settings, app should scale appropriately.

---


### 21. Fix localization gaps
| Field | Value |
| --- | --- |
| **Category** | i18n |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/zh-Hans.lproj/Localizable.strings`, `PruneIt/PruneItApp.swift:262`, `PruneIt/Views/OverviewView.swift`, `PruneIt/Models/LargeFile.swift` |
| **Effort** | S/M (Small/Medium) |

#### What is the issue?
Missing keys for new UI, menu uses rawValue (bypasses localization), byte formatting not locale-aware, no .stringsdict for plurals, checker doesn't enforce code→table coverage.

#### Why is it an issue?
Chinese localization is incomplete/broken in places, not properly locale-aware.

#### Why solve it?
Better internationalization support.

#### How to solve it?
1. Add all missing keys to Localizable.strings
2. Fix menu to use `tab.displayName`
3. Use `ByteCountFormatter` in `ByteFormatter`
4. Add `.stringsdict` for common plurals
5. Enhance `check-localization.py` to catch missing keys

**Verification:** Run localization check, test in Chinese locale.

---


### 22. Homebrew Cask and Sparkle enablement
| Field | Value |
| --- | --- |
| **Category** | Distribution |
| **Severity** | P2 - Important |
| **Affected Files** | `appcast.xml`, `PruneIt/Services/PruneItUpdater.swift`, new Homebrew formula |
| **Effort** | M (Medium) |

#### What is the issue?
No releases exist, Sparkle not configured, no Homebrew cask.

#### Why is it an issue?
Distribution friction, no automatic updates.

#### Why solve it?
After signing works, enable professional distribution.

#### How to solve it?
1. Generate Sparkle EdDSA keys, add public key to Info.plist
2. Set up gh-pages for appcast, create release workflow
3. Create Homebrew tap and cask formula
4. Enable updates after first signed release

**Verification:** Install via Homebrew, update flow works.

---


### 23. Export cleanup history/reports
| Field | Value |
| --- | --- |
| **Category** | Product |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Services/CleanupHistoryStore.swift`, `PruneIt/Views/SettingsView.swift` |
| **Effort** | S (Small) |

#### What is the issue?
Cleanup history is stored but can't be exported.

#### Why is it an issue?
Users want accountability/audit trail.

#### Why solve it?
Easy value-add.

#### How to solve it?
Add "Export History" button in Settings > Cleanup History, export as JSON/CSV with timestamps, items, sizes, paths.

**Verification:** Export works, format is valid.

---


### 24. Split large files and reduce duplication
| Field | Value |
| --- | --- |
| **Category** | Architecture / Quality |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneItStore.swift`, `AppChrome.swift`, `LargeFilesView.swift`, `UninstallView.swift`, `DevScanner.swift` |
| **Effort** | L (Large) |

#### What is the issue?
God objects, huge files, duplication across scanners.

#### Why is it an issue?
Hard to maintain, test, review.

#### Why solve it?
Long-term health.

#### How to solve it?
Incremental refactoring as outlined in code quality audit. Do one area at a time with tests passing.

**Verification:** File sizes reduced, tests still pass, no behavior changes.

---


## P3 - Nice to Have

### 25. Add .stringsdict for plurals
| Field | Value |
| --- | --- |
| **Category** | i18n |
| **Severity** | P3 - Low |
| **Affected Files** | New `Localizable.stringsdict` files |
| **Effort** | S (Small) |

#### What is the issue?
Manual plural handling doesn't work for languages with complex plural rules.

#### Why is it an issue?
Better localization for non-English languages.

#### Why solve it?
Polish for international users.

#### How to solve it?
Add .stringsdict for common plurals (items, files, days, etc.).

---


### 26. Duplicate detection outside Large Files
| Field | Value |
| --- | --- |
| **Category** | Product |
| **Severity** | P3 - Low |
| **Affected Files** | New scanner/detector, UI |
| **Effort** | M (Medium) |

#### What is the issue?
Duplicate detection only exists in Large Files tab.

#### Why is it an issue?
Users might have duplicates elsewhere.

#### Why solve it?
Nice feature expansion.

#### How to solve it?
Extend duplicate detection to other areas or add dedicated section.

---


### 27. Docker/Browser deep cleanup improvements
| Field | Value |
| --- | --- |
| **Category** | Product |
| **Severity** | P3 - Low |
| **Affected Files** | `CacheScanner.swift`, `DevScanner.swift`, UI |
| **Effort** | M (Medium) |

#### What is the issue?
Docker and browser caches are scanned but lack specialized cleanup UI/guidance.

#### Why is it an issue?
Common use cases not fully optimized.

#### Why solve it?
Better user experience for common cases.

#### How to solve it?
Add dedicated sections/guidance, better categorization.

---


### 28. Migrate to Swift 6 and @Observable
| Field | Value |
| --- | --- |
| **Category** | Architecture / Future-proofing |
| **Severity** | P3 - Low |
| **Affected Files** | Throughout codebase |
| **Effort** | L (Large) |

#### What is the issue?
Using Swift 5 mode, ObservableObject everywhere, mixed concurrency.

#### Why is it an issue?
Not using latest language features, potential performance benefits missed.

#### Why solve it?
Future-proofing and better performance.

#### How to solve it?
Gradual migration - enable strict concurrency, migrate to @Observable where beneficial, use actors more.

---


---

## Additional P1 Findings (Security, Performance, UX)

### 29. Reject cleartext HTTP in Sparkle feed validation
| Field | Value |
| --- | --- |
| **Category** | Security / Updates |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/PruneItUpdater.swift:71-88` |
| **Effort** | S (Small) |

#### What is the issue?
`hasValidConfiguration` accepts `feedURL.scheme == "https" || feedURL.scheme == "http"`. The updater is currently inert (no feed/key configured), but the code permits an insecure feed.

#### Why is it an issue?
If a future build is configured with an HTTP feed, a network attacker could serve a malicious appcast and update payload. Sparkle's EdDSA signature mitigates this, but defense-in-depth demands HTTPS-only.

#### Why solve it?
Update integrity is a core security property for a tool that deletes files. Never allow downgrade to cleartext.

#### How to solve it?
1. Require `https` only, except explicitly allowlisted localhost development feeds.
2. Require a valid 32-byte base64 `SUPublicEDKey`.
3. Add tests: empty/TODO key, `http://`, non-32-byte key must all be rejected.
4. Keep the current fail-closed guard when unconfigured.

**Verification:** Unit tests assert rejection of HTTP and malformed keys; update settings remain disabled when unconfigured.

---


### 30. Remove or rebuild the vendored `bin/sign_update` binary
| Field | Value |
| --- | --- |
| **Category** | Security / Supply Chain |
| **Severity** | P1 - High |
| **Affected Files** | `bin/sign_update`, future release tooling |
| **Effort** | M (Medium) |

#### What is the issue?
A 1.3 MB universal Mach-O binary is tracked in the repo. It is ad-hoc signed, has no TeamIdentifier, and was imported in the initial commit. It is not referenced by any script or CI workflow.

#### Why is it an issue?
`sign_update` is the tool that receives the Sparkle EdDSA private key. Using a prebuilt, unverifiable binary for update signing creates a supply-chain hole. If compromised, it could exfiltrate the key or sign malicious updates.

#### Why solve it?
Remove unknown-trust binaries from the release path.

#### How to solve it?
1. `git rm bin/sign_update`.
2. Vendor Sparkle's official 2.10.0 release tooling, pinned by SHA-256, or install via a pinned Homebrew/SPM artifact.
3. Document provenance and checksum verification in the release process.
4. Upgrade Sparkle SPM pin from 2.9.4 to an exact 2.10.0.

**Verification:** No unsigned binaries tracked under `bin/`; release workflow downloads/verifies official tooling.

---


### 31. Authenticate the watch-agent notification channel
| Field | Value |
| --- | --- |
| **Category** | Security / IPC |
| **Severity** | P1 - High |
| **Affected Files** | `PruneItWatch/PruneItWatchMain.swift:107-176`, `PruneIt/Services/RemovedAppMonitor.swift:169-173,300-308` |
| **Effort** | M (Medium) |

#### What is the issue?
`PruneItWatch` listens on `DistributedNotificationCenter`, which is unauthenticated. `RemovedAppMonitor` posts owner/ping notifications using a filesystem path as the object.

#### Why is it an issue?
Any local process or user can post the same notification names and influence the agent's lifecycle (exit/behavior). The path object is spoofable.

#### Why solve it?
IPC trust boundaries should be explicit. A background agent that watches app deletions should not be steerable by arbitrary local processes.

#### How to solve it?
1. Validate sender bundle identity and code signature where feasible.
2. Prefer XPC or `NSXPCConnection` with audit-token checks over distributed notifications.
3. If keeping notifications, include a nonce/ownership token that only the owning app knows.
4. Harden the agent's exit logic so a spoofed notification cannot terminate a valid session.

**Verification:** A third-party process posting the notification cannot affect a running watch agent.

---


### 32. Align helper allowlist with app policy for `~/Library/Preferences`
| Field | Value |
| --- | --- |
| **Category** | Security / Defense in Depth |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/PrivilegedHelper/PruneItHelperProtocol.swift:50-60`, `PruneItHelper/HelperService.swift:47-150`, `PruneIt/Services/DeletionSafetyPolicy.swift:226` |
| **Effort** | S (Small) |

#### What is the issue?
The helper permits direct children of `~/Library/Preferences` for uninstall leftovers, while the app's `neverDeletePrefixes` blocks `Preferences` entirely.

#### Why is it an issue?
The helper is the root boundary; it should not accept paths the app would refuse. Today the helper's own checks mitigate it, but the discrepancy weakens defense-in-depth.

#### Why solve it?
Keep the root helper's capability set a subset of the app's policy. Easier to reason about and audit.

#### How to solve it?
1. Add an explicit deny in the helper for `Preferences` direct children unless a narrowly audited exception exists.
2. Document intentional differences.
3. Add tests for both app and helper decisions on the same path corpus.

**Verification:** A path under `Preferences` refused by the app is also refused by the helper.

---


### 33. Add symlink resolution to `DeletionSafetyPolicy.evaluate`
| Field | Value |
| --- | --- |
| **Category** | Security / Defense in Depth |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/DeletionSafetyPolicy.swift:1139-1250` |
| **Effort** | M (Medium) |

#### What is the issue?
`evaluate` normalizes with `standardizedFileURL` and uses lexical prefix checks. It does not always resolve symlinks. Scanners currently skip symlinks and the helper uses `O_NOFOLLOW`, so practical risk is low.

#### Why is it an issue?
Safety-critical policy should not depend on every caller remembering to pre-resolve symlinks. A future scanner bug could open a bypass.

#### Why solve it?
Make the choke point robust regardless of caller behavior.

#### How to solve it?
1. Compute both standardized and `resolvingSymlinksInPath()` paths.
2. Run protected-prefix and allowlist checks against both; deny if either resolves into a protected area.
3. Add tests: symlink from an allowed cache dir to `/etc`, home root, and another user's directory.

**Verification:** Symlink-bypass tests fail closed.

---


### 34. Report hidden/refused entries in contents-only cleanup
| Field | Value |
| --- | --- |
| **Category** | UX / Safety Transparency |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/FileDeleter.swift:257-327` |
| **Effort** | S (Small) |

#### What is the issue?
Contents-only cleanup uses `.skipsHiddenFiles`, and entries refused by `isOfferedForCleanup` are silently dropped rather than added to `skippedItems`.

#### Why is it an issue?
Users may believe a folder was fully cleaned while hidden cache files remain. Silent skips undermine trust and debuggability.

#### Why solve it?
Transparency is essential for a deletion tool.

#### How to solve it?
1. Enumerate hidden entries and evaluate them normally, or document why they are excluded.
2. Append refused entries to `skippedItems` with a visible reason.
3. Mirror the same reporting in the main `deleteItems` loop at line ~233.

**Verification:** A folder containing a hidden file reports either its removal or a skipped-item reason.

---


### 35. Stop `TrashStore` from polling `du` every 30 seconds while frontmost
| Field | Value |
| --- | --- |
| **Category** | Performance / Power |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/TrashStore.swift:92-103,470-507` |
| **Effort** | S (Small) |

#### What is the issue?
While the app is frontmost, Trash is re-measured every 30 seconds via `du`, competing for the global 10-permit sizing limiter and generating continuous I/O.

#### Why is it an issue?
Wasted power/IO for a figure the user may not be looking at; can starve scans and trigger retry loops.

#### Why solve it?
Reduce background work without losing accuracy.

#### How to solve it?
1. Poll only when the Trash view/sidebar figure is visible.
2. Increase interval to 2–5 minutes and skip if a scan is running.
3. Keep watcher events and app-activation refreshes as primary triggers.

**Verification:** `fs_usage` shows no periodic `du` during idle foreground use.

---


### 36. Cache `ByteCountFormatter` instead of allocating per call
| Field | Value |
| --- | --- |
| **Category** | Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Utilities/ByteFormatter.swift:3-12` |
| **Effort** | S (Small) |

#### What is the issue?
`formatBytes` creates a new `ByteCountFormatter` on every call. It is used in row bodies and list subtitles.

#### Why is it an issue?
Formatter initialization is heavyweight and runs per cell per body pass, causing scroll jank.

#### Why solve it?
Cheap, measurable scroll improvement.

#### How to solve it?
Use one configured shared instance (thread-safe for `string(fromByteCount:)`), or a lock-free cache keyed by byte count.

**Verification:** Time Profiler shows no `ByteCountFormatter.init` during scrolling.

---


### 37. Replace blocking `DispatchGroup.wait()` in `FolderSizing`
| Field | Value |
| --- | --- |
| **Category** | Performance / Concurrency |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Utilities/FolderSizing.swift:100-138` |
| **Effort** | M (Medium) |

#### What is the issue?
Chunked `du` work is awaited with `group.wait()`, blocking a Swift cooperative-pool thread. The code comment documents this as a workaround.

#### Why is it an issue?
The cooperative pool has ~one thread per core. Blocking several callers stalls unrelated async work (scanners, UI tasks) and worsens latency.

#### Why solve it?
Keep async concurrency non-blocking.

#### How to solve it?
1. Use `withThrowingTaskGroup` and await chunk completion.
2. Bridge `Process` termination via continuations.
3. Replace the semaphore with an actor-based limiter that suspends rather than blocks.

**Verification:** Thread Performance Checker shows no threads parked in `DispatchGroup.wait`.

---


### 38. Reduce `DevScanner.listTypes` syscall amplification
| Field | Value |
| --- | --- |
| **Category** | Performance / Scanning |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/DevScanner.swift:1141-1192` |
| **Effort** | M (Medium) |

#### What is the issue?
For every visited directory, the scanner probes ~22 marker files with `fileExists`, plus extra directory listings.

#### Why is it an issue?
On 100k directories this is 2M+ stats before sizing, adding seconds to every dev scan. Cold/network volumes are worse.

#### Why solve it?
Scan time is a primary UX metric.

#### How to solve it?
1. Read each directory once with `contentsOfDirectory` and match names against a `Set<String>`.
2. Skip impossible project roots by depth/known workspace heuristics.
3. Cache results per directory for rescan sessions.

**Verification:** `fs_usage` shows a single `getattrlistbulk` per directory instead of many stats.

---


### 39. Stop full re-sorting of `largeFiles` every 25 rows
| Field | Value |
| --- | --- |
| **Category** | Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/PruneItStore.swift:1697-1729` |
| **Effort** | S (Small) |

#### What is the issue?
`publish()` fully sorts `collected` every 25 discovered files and republishes the entire array.

#### Why is it an issue?
O(n² log n) sorting across a scan, plus thousands of full-array `@Published` publications.

#### Why solve it?
Large-file scans are common and large.

#### How to solve it?
1. Sort once at completion.
2. During scan, binary-insert into the sorted prefix or keep top-K heap for live display.
3. Publish at a lower cadence tied to the flush throttle.

**Verification:** Sorting samples disappear from the profile; publication count drops.

---


### 40. Memoize repository lookup in `GitStatusChecker`
| Field | Value |
| --- | --- |
| **Category** | Performance |
| **Severity** | P1 - High |
| **Affected Files** | `PruneIt/Services/GitStatusChecker.swift:4-20` |
| **Effort** | S (Small) |

#### What is the issue?
Every cache item walks up its ancestors and `lstat`s `.git` at each level, with no memoization across items.

#### Why is it an issue?
5k items × depth ~8 = ~40k stats for a few hundred distinct directories.

#### Why solve it?
Cheap scan-time reduction.

#### How to solve it?
Cache `[URL: URL?]` for enclosing repositories per scan, resolve via nearest cached ancestor, cache negative results too.

**Verification:** `fs_usage` shows each distinct directory's `.git` probed once.

---


## Additional P2 Findings

### 41. Fix doc drift and broken repository links
| Field | Value |
| --- | --- |
| **Category** | Documentation / Trust |
| **Severity** | P2 - Important |
| **Affected Files** | `README.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/*`, `appcast.xml`, `.github/FUNDING.yml`, `.gitignore` |
| **Effort** | S (Small) |

#### What is the issue?
AGENTS.md, RULES.md, TASKS.md, GEMINI.md, CLAUDE.md and docs/taste-skill.md are gitignored but linked from README/CONTRIBUTING. `SECURITY.md` has `TODO_YOUR_SECURITY_EMAIL`. Issue templates and appcast point to `pahul/pruneit` instead of `RoyalLit/PruneIt`. `docs/taste-skill.md`, `UPSTREAM.md`, `spikes/` and `SafetyTierListTests.swift` are referenced but missing.

#### Why is it an issue?
Every linked doc 404s on GitHub. Contributors lack the safety rules the repo says are mandatory. Security disclosure is impossible.

#### Why solve it?
Trust and maintainability. Docs must match reality.

#### How to solve it?
1. Decide which agent docs are public; commit them (adjust `.gitignore`) or remove links.
2. Replace the security email with a real address or GitHub private advisories link.
3. Fix owner strings to `RoyalLit/PruneIt`.
4. Remove or fix missing-file references.
5. Keep TASKS.md status aligned with shipped features (menu bar, AI models, snapshots, uninstaller).

**Verification:** A link checker finds zero broken docs; GitHub renders all linked files.

---


### 42. Move versions to xcconfig and fix stale helper/watch/worker versions
| Field | Value |
| --- | --- |
| **Category** | Release Engineering |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt.xcodeproj/project.pbxproj:703-777`, `PruneItHelper/Info.plist`, `PruneItWatch/Info.plist`, `PruneItAssetWorker/Info.plist`, `.gitignore` |
| **Effort** | S (Small) |

#### What is the issue?
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are duplicated across target/config pairs. Helper is `1.0/2`, watch and asset worker are `1.0/1`, while the app is `1.12.0/35`. `.gitignore` ignores `*.xcconfig`.

#### Why is it an issue?
Version drift is guaranteed. Sparkle orders updates by `CFBundleVersion`; stale nested versions confuse crash reports and helper reconciliation.

#### Why solve it?
Single source of truth for release versioning.

#### How to solve it?
1. Create `Config/Version.xcconfig` with the two values.
2. Reference it from every target/config.
3. Make nested plists use `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)`.
4. Stop ignoring `*.xcconfig`.
5. Add a CI check that tag == plist version and build number strictly increases.

**Verification:** `defaults read` on every embedded Info.plist shows the same app version; tag matches.

---


### 43. Remove the source-tree-mutating icon build phase
| Field | Value |
| --- | --- |
| **Category** | Build / Reproducibility |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt.xcodeproj/project.pbxproj:472-489`, `package.json`, `scripts/generate-brand-icons.mjs` |
| **Effort** | S (Small) |

#### What is the issue?
An `alwaysOutOfDate` script phase runs `npm run generate:icons`, writes into `$(SRCROOT)/PruneIt/Resources/BrandIcons`, and swallows failure with `2>/dev/null || echo`. CI logs "brand icon generation skipped". Dependencies use floating semver ranges.

#### Why is it an issue?
- Non-reproducible builds.
- Dirty working trees after builds on dev machines.
- CI silently ships committed PNGs, so the phase is decorative.
- Floating deps can change generated bytes.

#### Why solve it?
Reproducibility and clean builds.

#### How to solve it?
1. Delete the build phase.
2. Add a CI drift job: `npm ci --ignore-scripts && npm run generate:icons && git diff --exit-code -- PruneIt/Resources/BrandIcons`.
3. Pin exact dependency versions.
4. Add a `NOTICE` for third-party brand marks.

**Verification:** Build no longer writes to the source tree; CI fails on icon drift.

---


### 44. Improve DMG layout, architecture, and verification
| Field | Value |
| --- | --- |
| **Category** | Release Engineering |
| **Severity** | P2 - Important |
| **Affected Files** | `scripts/make-dmg.sh`, `Assets/dmg/dmg_bg.png` |
| **Effort** | M (Medium) |

#### What is the issue?
The DMG uses plain `hdiutil -srcfolder` with no background/layout, ignores `dmg_bg.png`, builds arm64-only, and has no sign/notarize/staple/verify steps. Name has no architecture.

#### Why is it an issue?
Intel Macs get a non-launching app despite the documented macOS 13+ support. Gatekeeper friction remains. Poor first impression.

#### Why solve it?
Distribution quality and correctness.

#### How to solve it?
1. Use `create-dmg`/`dmgbuild` with background and icon positions.
2. Build universal (`ARCHS="arm64 x86_64"`, `ONLY_ACTIVE_ARCH=NO`).
3. Sign → notarize → staple → `spctl` verify.
4. Emit SHA-256 and SHA-512.
5. Name `PruneIt-<version>-universal.dmg`.
6. Remove the post-build icon copy or fix the asset catalog.

**Verification:** DMG opens cleanly on Intel + Apple Silicon with no quarantine bypass; `spctl` accepts.

---


### 45. Add dSYM retention and crash triage
| Field | Value |
| --- | --- |
| **Category** | Release Engineering / Observability |
| **Severity** | P2 - Important |
| **Affected Files** | `scripts/make-dmg.sh:26`, `.github/workflows/build.yml`, release workflow |
| **Effort** | S (Small) |

#### What is the issue?
Builds use `xcodebuild clean build`, not `archive`, so no `.xcarchive`/dSYMs are retained.

#### Why is it an issue?
Crash reports from users are unsymbolizable. For a file-deleting app, post-incident forensics is essential (see `docs/safety-notes.md`).

#### Why solve it?
Debuggability and incident response.

#### How to solve it?
1. Switch release builds to `xcodebuild archive`.
2. Upload dSYMs to the GitHub release or object storage.
3. Optionally add opt-in crash reporting (privacy-preserving), or document manual symbolication.

**Verification:** A crash log can be symbolized against the release dSYM.

---


### 46. Add PrivacyInfo.xcprivacy
| Field | Value |
| --- | --- |
| **Category** | Privacy / Compliance |
| **Severity** | P2 - Important |
| **Affected Files** | New `PrivacyInfo.xcprivacy` in app bundle |
| **Effort** | S (Small) |

#### What is the issue?
No privacy manifest exists outside Sparkle. The app reads file timestamps and disk-capacity APIs.

#### Why is it an issue?
Not required for Developer ID notarization, but required for App Store and increasingly expected. Declares required-reason API usage.

#### Why solve it?
Low-cost compliance and transparency, matching the "no telemetry" claim.

#### How to solve it?
Add a manifest declaring `NSPrivacyAccessedAPICategoryFileTimestamp` and `NSPrivacyAccessedAPICategoryDiskSpace` with valid reasons; declare no tracking and no collected data.

**Verification:** `plutil -lint` passes; manifest is embedded in the app bundle.

---


### 47. Fix remaining UX copy and empty states
| Field | Value |
| --- | --- |
| **Category** | UX |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Views/DeletionConfirmSheet.swift:133`, `UninstallReviewSheet.swift:1363`, `OrphanReviewSheet.swift:1439`, `RemovedAppLeftoverSheet.swift:1530`, `GeneralModeView.swift:402-415`, `OverviewView.swift:106-109`, `ContentView.swift:652-659` |
| **Effort** | S (Small) |

#### What is the issue?
- Confirmation sheets say "Freeing X" although items go to Trash.
- Permanent-deletion note says "Xcode deletes these itself", which is inaccurate for snapshots/AI models.
- App Caches empty state has no scan CTA.
- Overview renders duplicate scan/clean buttons in header and strata deck.
- Overview labels are jargon-heavy.

#### Why is it an issue?
Inaccurate language erodes trust; duplicate actions add noise; dead-end empty states frustrate.

#### Why solve it?
Cheap, high-visibility polish.

#### How to solve it?
1. Change to "Moving X to Trash" and add "Space freed after emptying Trash".
2. Replace permanent copy with a generic, explicit "removed permanently via system tools" warning.
3. Add a "Scan now" button to the App Caches empty state.
4. Remove duplicate Overview actions, keep one location.
5. Rename sections to plain language with tooltips for technical detail.

**Verification:** Copy review and visual check of empty states.

---


### 48. Add missing `.monospacedDigit()` and use single-pass subtitles
| Field | Value |
| --- | --- |
| **Category** | Design System / UX |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/ContentView.swift:750-751`, `PruneIt/Views/LargeFilesView.swift:617-621`, `PruneIt/Views/UninstallView.swift:838,932,936,1042`, `PruneIt/Views/DevModeView.swift:634`, `PruneIt/Views/GeneralModeView.swift:163` |
| **Effort** | S (Small) |

#### What is the issue?
Several numeric displays omit `.monospacedDigit()`, and some subtitles compute counts/totals more than once per render.

#### Why is it an issue?
Numbers jitter during updates, breaking the tabular "precision workbench" feel. Duplicate computation adds render cost.

#### Why solve it?
Design consistency and minor performance.

#### How to solve it?
Audit numeric `Text`/`Label` and add `.monospacedDigit()`. Compute count and bytes once in a tuple per body pass.

**Verification:** Design lint extended to catch missing digit monospacing; visual check during updates.

---


### 49. Improve menu bar accessibility and localization
| Field | Value |
| --- | --- |
| **Category** | Accessibility / i18n |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Menu/MenuBarView.swift:9-34`, `PruneIt/PruneItApp.swift:262`, `PruneIt/Services/PruneItStore.swift:108-118` |
| **Effort** | S (Small) |

#### What is the issue?
The bundled menu bar `NSImage` has no accessibility description. Menu items use `Button(tab.rawValue)`, bypassing the localized `displayName`.

#### Why is it an issue?
VoiceOver cannot identify the menu bar icon. Menu labels stay English in Chinese locale.

#### Why solve it?
Accessibility and localization correctness.

#### How to solve it?
Set `image.accessibilityDescription = "PruneIt"`, and use `Text(tab.displayName)`/localized titles in menus.

**Verification:** VoiceOver announces the menu bar item; Chinese locale shows translated tabs.

---


### 50. Expand localization coverage checker
| Field | Value |
| --- | --- |
| **Category** | i18n / Tooling |
| **Severity** | P2 - Important |
| **Affected Files** | `scripts/check-localization.py` |
| **Effort** | S (Small) |

#### What is the issue?
The script validates existing tables but never checks that keys used in code exist in `Localizable.strings`. Recent strings (Overview strata labels, size thresholds) are missing and CI still passes.

#### Why is it an issue?
Silent localization regressions.

#### Why solve it?
Make the guardrail real.

#### How to solve it?
Scan `String(localized:)`, `NSLocalizedString`, `Text("...")`, `Button`, `.help`, `.accessibilityLabel`, alert titles for keys; fail on missing entries; validate format placeholders across languages.

**Verification:** Introducing an untranslated string fails CI.

---


### 51. Add .stringsdict and locale-aware byte formatting
| Field | Value |
| --- | --- |
| **Category** | i18n |
| **Severity** | P2 - Important |
| **Affected Files** | `PruneIt/Utilities/ByteFormatter.swift`, new `*.stringsdict` |
| **Effort** | S (Small) |

#### What is the issue?
Plurals are hand-rolled in ~20 places and `formatStorageBytes`/`formatBytesRoundedDown` hardcode English `TB/GB/MB/KB` and a `.` decimal separator.

#### Why is it an issue?
Incorrect grammar in languages with multiple plural forms; wrong separators/units in localized UI.

#### Why solve it?
Real localization quality.

#### How to solve it?
Use `ByteCountFormatter`/`MeasurementFormatter` for storage units, and `.stringsdict` for high-traffic plurals.

**Verification:** Chinese/German locales display correct units and plural forms.

---


## Additional P3 Findings

### 52. Add multi-volume and purgeable-space awareness
| Field | Value |
| --- | --- |
| **Category** | Product |
| **Severity** | P3 - Low |
| **Affected Files** | `ScanSources.swift`, `VolumeCapacityReader.swift`, `LargeFilesView.swift` |
| **Effort** | M (Medium) |

#### What is the issue?
Scans focus on the home volume; external volumes and purgeable space are not explicitly surfaced.

#### Why is it an issue?
Users with external drives cannot reclaim there; free-space confusion persists.

#### How to solve it?
Add volume selection, show purgeable vs free, and warn when operating on external volumes.

---


### 53. Add iOS backup and Docker/browser deep-clean views
| Field | Value |
| --- | --- |
| **Category** | Product |
| **Severity** | P3 - Low |
| **Affected Files** | `CacheDiscoveryPaths.swift`, `DevScanner.swift`, new views |
| **Effort** | M/L (Medium/Large) |

#### What is the issue?
MobileSync backups are excluded and there is no dedicated Docker or browser profile cleanup UI.

#### Why is it an issue?
Common sources of large reclaimable space are under-served.

#### How to solve it?
Add read-only backup browsing, Docker image/volume/container listing with explicit warnings, and per-browser cache/profile controls.

---


### 54. Migrate to Swift 6 strict concurrency and `@Observable`
| Field | Value |
| --- | --- |
| **Category** | Architecture |
| **Severity** | P3 - Low |
| **Affected Files** | Throughout |
| **Effort** | L (Large) |

#### What is the issue?
Project builds in Swift 5 mode with a MainActor-default isolation setting, 17 `@unchecked Sendable` uses, and zero `@Observable`.

#### Why is it an issue?
Missed compile-time race checking and per-property observation performance.

#### How to solve it?
Enable strict concurrency incrementally, audit `@unchecked Sendable`, and migrate high-churn stores to `@Observable` where deployment targets allow.

---

## Appendix A: Quick Reference Commands

### Development & Testing
```bash
# Build (unsigned, for development)
xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run all tests
xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run specific tests
xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -only-testing:PruneItTests/OverviewPresentationTests

# Lint design tokens
node scripts/lint-design-tokens.mjs

# Check localization
python3 scripts/check-localization.py

# Build DMG
bash scripts/make-dmg.sh
```

### Signing & Verification (Post-Release Setup)
```bash
# Check signature
codesign -dv --verbose=4 /Applications/PruneIt.app

# Verify signature
codesign --verify --deep --strict --verbose=2 /Applications/PruneIt.app

# Check Gatekeeper
spctl -a -vvv -t exec /Applications/PruneIt.app

# Notarize
xcrun notarytool submit PruneIt.zip --key AuthKey.p8 --key-id "$KEY_ID" --issuer "$ISSUER" --wait
xcrun stapler staple PruneIt.app

# Check helper
sudo launchctl print system/com.pahul.pruneit.helper
```

---

## Appendix B: Key Files Reference

| File | Purpose | Notes |
| --- | --- | --- |
| `PruneIt/Services/DeletionSafetyPolicy.swift` | Central safety gatekeeper | **DO NOT MODIFY** - critical invariant |
| `PruneIt/Services/FileDeleter.swift` | Deletion execution engine | **DO NOT MODIFY** - critical invariant |
| `PruneIt/Services/PruneItStore.swift` | App state store (god object) | Needs refactoring, 5266 LOC |
| `PruneIt/Services/DevScanner.swift` | Developer cache scanner | 1581 LOC, needs optimization |
| `PruneIt/Views/AppChrome.swift` | Main app shell | 2083 LOC, needs splitting |
| `PruneIt/Views/ScanResultRow.swift` | Row component | Needs a11y fixes (P0) |
| `PruneIt/Views/SafetyFilterBar.swift` | Filter bar | Needs "All" filter fix (P1) |
| `PruneItHelper/HelperService.swift` | Privileged helper daemon | Untested, security critical |
| `scripts/make-dmg.sh` | DMG packaging | Needs rewrite for signing/notarization |
| `.github/workflows/build.yml` | CI pipeline | Needs Xcode 26.5 fix |
| `docs/ARCHITECTURE.md` | Architecture documentation | Reference |
| `TASKS.md` | Roadmap | Reference for phases |

---

*This document should be treated as a living plan. Update status as items are completed. All P0 items must be resolved before public release.*
