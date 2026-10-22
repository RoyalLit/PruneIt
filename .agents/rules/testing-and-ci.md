# Testing & Verification Rules

Every code change must be verified before opening a pull request or pushing to `main`.

## 1. Test Isolation
- Tests run inside a hosted app sandbox.
- Tests MUST NEVER touch the user’s real files (`~`, `/Library`, `/Applications`).
- Always use `ThrowawayDefaults` for UserDefaults and `FakeScans` with mock directory sandboxes.

## 2. Verification Commands
1. **Design Tokens**: `node scripts/lint-design-tokens.mjs` (must pass with 0 errors).
2. **Localization**: `python3 scripts/check-localization.py` (must pass with 0 missing strings).
3. **Targeted Tests**:
   `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -only-testing:PruneItTests/OverviewPresentationTests`
4. **Full Test Suite**:
   `xcodebuild -project PruneIt.xcodeproj -scheme PruneIt -destination "platform=macOS" test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`
5. **Release DMG Packaging**:
   `bash scripts/make-dmg.sh`
