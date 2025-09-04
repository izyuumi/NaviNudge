# Repository Guidelines

> **Note for Claude Code users:** See [`CLAUDE.md`](CLAUDE.md) for development commands, architecture details, and code style requirements.

## Commit & Pull Request Guidelines
- Commits: small, focused, Conventional Commits preferred (e.g., `feat: add biking deeplink`, `fix: clamp angle calc`)
- PRs: include summary, linked issue, simulator/device used, screenshots or short video of UI, and test notes
- Keep diffs minimal; update docs (`README.md`, this file) when behavior or setup changes

## Testing & Validation
- Test location permission flows on both simulator and physical device
- Validate Apple Maps deeplinks work correctly across different iOS versions
- Include screenshots or short video demos in PRs showing UI changes
- Test with various destination configurations (empty, single, multiple destinations)
