# Code Style & Conventions

- Language: Swift (SwiftUI)
- Indentation: 2 spaces; keep lines < 120 chars
- Naming: Types UpperCamelCase; vars/functions lowerCamelCase
- File names: one primary type per file; views end with `View`; managers end with `Manager`
- SwiftUI: prefer value types in models; `@StateObject` for long‑lived managers; `@EnvironmentObject` for app‑wide state
- Organization: group with `// MARK:` sections
- Tests: XCTest with files named `ThingTests.swift` and methods `test_…()`; place under `NaviNudgeTests/` if/when added
- Lint/format: no explicit tools configured in repo; follow Swift API Design Guidelines