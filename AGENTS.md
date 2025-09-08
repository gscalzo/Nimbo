# Repository Guidelines

## Project Structure & Module Organization
- SwiftPM layout:
  - `Package.swift` (deps, products), `Sources/NimboCLI/main.swift` (CLI entry), `Tests/` (XCTest when added), `.github/` (CI), `scripts/` (helpers).
- Keep names concise; group shared helpers under `Sources/Shared/` if needed.

## Build, Test, and Development Commands
- `swift build` – build the package in debug mode.
- `swift run nimbo` – run the CLI locally.
- `swift test` – run tests (XCTest) when present.
- Future deps: SwiftOpenAI and swift-subprocess. Avoid others unless justified.

## Coding Style & Naming Conventions
- Use Swift guidelines: 4-space indentation; types `PascalCase`, methods/properties `camelCase`, constants `camelCase` with `static let`.
- Keep files small and focused. Prefer free functions only for simple utilities; otherwise create types.
- Optional: adopt `swift-format` locally; commit formatted code only.

## Testing Guidelines
- XCTest with mirrors of `Sources/` under `Tests/` (e.g., `Tests/NimboCLITests`).
- Name tests descriptively: `test_<behavior>_...` and cover edge cases.
- Target: meaningful coverage on changed code; add regression tests for fixes.

## Commit & Pull Request Guidelines
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- Keep PRs focused; include description, linked issues, and CLI screenshots/recordings when output changes.
- CI must pass (build, lint/format, tests) before merge.

## Security & Configuration Tips
- Never commit secrets. Provide `/.env.example` and load via process env.
- Scope tokens minimally; rotate on suspicion of leak.

## Roadmap Notes (Agent-Specific)
- v0: echo run loop in `main.swift`.
- v1: wire OpenAI client; v2: add subprocess tool use.
- Make minimal, surgical changes; document new commands and folders.
