# Deletion Safety Rules

PruneIt deletes files on the user’s Mac. Consequently, **deletion safety precedes all other considerations**, including aesthetics, user convenience, and feature velocity.

## 1. Safety Invariants
1. **Gatekeeper Enforcement**: Every deletion of caches, developer debris, orphan files, or logs MUST pass through `DeletionSafetyPolicy.evaluate(_:)`. Never invoke `FileManager.default.removeItem` or `trashItem` directly from a view or scanner.
2. **Always Move to Trash**: All regular file and directory deletions must move items to the macOS Trash via `FileManager.default.trashItem(at:resultingItemURL:)` in `FileDeleter.swift`. This ensures user recoverability.
3. **Irreversible Removals**:
   - Xcode Simulator runtimes (`xcrun simctl runtime delete`), Time Machine APFS snapshots (`tmutil deletelocalsnapshots`), and CLI packages (`brew uninstall`) permanently remove assets.
   - The UI and confirmation dialogs MUST clearly indicate to the user that these operations cannot be undone from the Trash.
4. **Safety Level Semantics (`SafetyLevel`)**:
   - `.safe`: Automatically regenerable files (Xcode DerivedData, build logs, package caches). Can be pruned in batch or via scheduled clean.
   - `.medium` ("Check First"): Artifacts that take significant time to re-download or recreate (old simulators, archived packages). Requires explicit selection.
   - `.unknown` ("Not Sure"): Non-whitelisted or ambiguous locations. Must require individual manual review.

## 2. Protected Code
Never modify the following files without a dedicated safety review, running full unit tests, and documenting in `docs/safety-notes.md`:
- `PruneIt/Services/DeletionSafetyPolicy.swift`
- `PruneIt/Services/SafetyTierList.swift`
- `PruneIt/Services/FileDeleter.swift`
- `PruneIt/Resources/explanations.json`
