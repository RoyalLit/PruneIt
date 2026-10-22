# Contributing to PruneIt

Thank you for your interest in contributing!

## Before you start

- Open an issue first for anything bigger than a small fix.
- Make one fix or one feature per PR, on a branch off `main`. PRs are squash-merged.
- Write the PR title as a Conventional Commit with the issue number, e.g.:
  `feat: warn when Large Files items sync to iCloud (#25)`
  Types in use: `feat`, `fix`, `docs`, `test`, `ci`, `refactor`, `release`.
- Write commit bodies and PR descriptions in plain, short sentences. Include real numbers when you measured something.
- For UI changes, add before/after screenshots in dark mode to `docs/screenshots/`.

## Safety-critical code

**Do not modify the following without also running the full test suite and adding a note to `docs/safety-notes.md`:**

- `purge/Services/DeletionSafetyPolicy.swift`
- `purge/Services/SafetyTierList.swift`
- `purge/Services/FileDeleter.swift`
- Any `purge/Services/*ScanPolicy.swift` or `*Scanner.swift`
- `purge/Models/SimulatorRuntime.swift`
- `PurgeAssetWorker/`
- `PurgeHelper/` and `purge/PrivilegedHelper/`

These are the safety core. A bug here can delete files that cannot be recovered from Trash.

## App rules

- **Strings.** Wrap every user-facing string in `String(localized:)`.
- **Design.** Use tokens from `docs/design-system.md`. The design lint fails the build on raw values.
- **Tests.** Tests run inside the real app. Use `ThrowawayDefaults` and `FakeScans` from `PurgeTests/Support/`. Never use real user folders.
- **Enums.** When you switch over `SafetyLevel` or `DeletionSafetyDecision`, list every case — no `default:`.

## Running checks

| Check | Command |
|---|---|
| Unit tests | `xcodebuild -project purge.xcodeproj -scheme purge -destination 'platform=macOS' test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` |
| Design tokens lint | `node scripts/lint-design-tokens.mjs` |
| Localization check | `python3 scripts/check-localization.py` |

## Acknowledgements

PruneIt is forked from [purge-app](https://github.com/jithin-sabu/purge-app) by Jithin Sabu (MIT License).
