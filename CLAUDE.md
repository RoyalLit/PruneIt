# PruneIt

PruneIt is a macOS app in Swift and SwiftUI. It finds caches and junk and moves them to the Trash. PruneIt deletes files, so **deletion safety comes before every other goal**.

PruneIt is a fork of [purge-app](https://github.com/jithin-sabu/purge-app) by Jithin Sabu (MIT License). See [UPSTREAM.md](UPSTREAM.md) for the upstream commit hash.

## Where things live

- `purge/` is the app. `purge/Services/` holds the scanners, the safety policy, and `FileDeleter`. `purge/Models/` and `purge/Views/` hold the rest.
- `purge/Resources/explanations.json` holds the explanation and safety level for each item.
- `purge/PrivilegedHelper/` and `PurgeHelper/` are the root helper the uninstaller uses.
- `PurgeTests/` holds the unit tests. They use Swift Testing (`@Test`, `#expect`), not XCTest. Shared test helpers are in `PurgeTests/Support/`.
- `docs/safety-notes.md` logs every time PruneIt removed, or could have removed, something it should not have.
- `docs/design-system.md` describes the colours, type, and spacing tokens.
- `docs/ARCHITECTURE.md` is the full architecture walkthrough.
- `UPSTREAM.md` records the upstream commit hash from purge-app.

## Commands

| Check | Command | Runs on Linux |
| --- | --- | --- |
| Unit tests | `xcodebuild -project purge.xcodeproj -scheme purge -destination 'platform=macOS' test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` | No |
| Design tokens | `node scripts/lint-design-tokens.mjs` | Yes |
| Translations | `python3 scripts/check-localization.py` | Yes |
| Release DMG | `bash scripts/make-dmg.sh` | No |

Cloud sessions run on Linux, so they can build no Swift code. Run the two Linux checks on every change.

## How a change gets made

- Open an issue first for anything bigger than a small fix.
- Make one fix or one feature per PR, on a branch off `main`. PRs are squash-merged.
- Write the PR title as a Conventional Commit with the issue number, for example `feat: warn when Large Files items sync to iCloud (#25)`.
- Types in use: feat, fix, docs, test, ci, refactor, release.
- Write commit bodies and PR descriptions in plain, short sentences; give real numbers when you measured something.
- For UI changes, add before and after screenshots in dark mode to `docs/screenshots/`. Cover every scenario.
- Match the style of the file you edit.

## App rules

- **Text.** Wrap every user-facing string in `String(localized:)`.
- **Design.** Take colours, fonts, radii, and spacing from the tokens in `docs/design-system.md`. The design lint fails the build on a raw value.
- **Tests and real files.** The tests run inside a hosted copy of the app that shares the real user's defaults and files. Use `ThrowawayDefaults` and `FakeScans` from `PurgeTests/Support/`, never real user folders.
- **Enums.** When you switch over `SafetyLevel`, `DeletionSafetyDecision`, or another enum of ours, list every case and leave out `default:`.

## Deletion safety

- `SafetyLevel` in `purge/Models/SafetyInfo.swift` has three cases.
  - `.safe` is "Safe to Clean". Clean Safe Items and scheduled cleans take these items without asking.
  - `.medium` is "Check First".
  - `.unknown` is "Not Sure".
- Mark a path `.safe` only when it holds nothing but data its app rebuilds by itself.
- Every cache and Dev Tools removal goes through `DeletionSafetyPolicy.evaluate(_:)`. Never add a delete path that skips it.
- Files go to the Trash. Simulators, simulator runtimes, Time Machine snapshots, the Apple Intelligence models, and tools a package manager removes are removed for good, and the UI and docs must say so.
- Run the `deletion-safety-check` skill before you open a PR that touches any of:
  - `purge/Services/DeletionSafetyPolicy.swift`, `SafetyTierList.swift`, `SafetyAllowlistSummary.swift`, `FileDeleter.swift`
  - any `purge/Services/*ScanPolicy.swift` or `*Scanner.swift`
  - `purge/Resources/explanations.json` or `purge/Models/ProjectArtifactCatalog.swift`
  - simulator runtimes, scheduled cleaning, the root helper, Apple Intelligence models, or command-line tools
- After a real incident, add an entry to `docs/safety-notes.md`.

## Sparkle updates (Phase 4 — TODO)

Automatic update checks are **disabled**. To re-enable:
1. Generate your own EdDSA key pair with Sparkle's `generate_keys` tool.
2. Set `SUFeedURL` in `purge/Info.plist` to your own hosted `appcast.xml`.
3. Set `SUPublicEDKey` to your public key.
4. Set `SUEnableAutomaticChecks` to `true`.
5. Sign each release with `bin/sign_update` from the Sparkle package.
