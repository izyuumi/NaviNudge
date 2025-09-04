# Suggested Commands (Darwin/macOS)

- Open in Xcode: `xed .`
- Build (simulator): `xcodebuild -scheme NaviNudge -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run tests: `xcodebuild -scheme NaviNudge test`
- Clean build (Xcode): Shift+Cmd+K
- List devices: `xcrun simctl list devices`
- Boot a simulator: `xcrun simctl boot "iPhone 15"`
- Show project settings (text): `grep -n "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription" NaviNudge.xcodeproj/project.pbxproj`

Common utils
- Version control: `git status`, `git add -p`, `git commit` (Conventional Commits preferred)
- Search code: `grep -R "pattern" NaviNudge`