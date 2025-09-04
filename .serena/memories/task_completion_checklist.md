# Task Completion Checklist

- Build: app compiles via Xcode or `xcodebuild` for a recent simulator (e.g., iPhone 15)
- Tests: all tests pass (if/when tests exist)
- Style: code follows 2‑space indentation and naming conventions; views/managers named appropriately; add `// MARK:` sections
- Permissions: location permission flow validated; reason string matches UX (`NSLocationWhenInUseUsageDescription` present)
- Manual QA: run app in simulator/device; verify destination management, haptic feedback, and Apple Maps routing
- Docs: update `README.md` and guidelines if behavior/setup changes
- PR hygiene: small, focused diffs; include summary, linked issue, screenshots/video of UI, and test notes