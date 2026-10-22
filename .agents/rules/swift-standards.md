# Swift & SwiftUI Standards

## 1. Pattern Matching & Safety Enums
When switching over safety-critical enums (`SafetyLevel`, `DeletionSafetyDecision`, `ScanCategory`):
- **NEVER** use `default:`.
- Every case must be handled explicitly so compiler errors catch newly added cases.

## 2. Localization
- Every user-visible text string MUST be wrapped in `String(localized:)`:
  ```swift
  Text(String(localized: "DerivedData"))
  ```
- Run `python3 scripts/check-localization.py` to ensure all strings are registered.

## 3. View Composition & Performance
- Keep view bodies small and declarative.
- Extract complex rows, cards, and headers into reusable subcomponents.
- Use `@StateObject` for view lifecycle ownership, `@ObservedObject` for shared stores, and `@Binding` for two-way state.
- Scanners and background work must run on background threads; UI updates must be isolated to `@MainActor`.
