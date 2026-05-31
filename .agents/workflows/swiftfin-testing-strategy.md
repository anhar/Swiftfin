# Swiftfin Testing Strategy

## Status

This is fork-only agent context on `ai/main`. Do not submit this file upstream.

Decision date: 2026-05-31.

Current decision: pause test-target and CI implementation work. Document the strategy on `ai/main`, wait for the upstream testing foundation PR to be reviewed and merged, then update `ai/main` from upstream before adding fork-only quality automation.

## Why This Is Paused

Adding a test target is not just a local project-file change. If CI runs simulator tests for every pull request, it can increase macOS runner time and cost for the Swiftfin project. Swiftfin already builds both iOS and tvOS in CI, so a new test job should be proposed carefully and with maintainers' CI budget in mind.

There is also a drift risk between two tracks:

- An upstream branch that introduces the real Swift Testing target and any accepted CI behavior.
- A fork-only `ai/main` branch that carries AI workflow scripts and notes.

If both tracks independently define test commands, target names, simulator selection, or CI assumptions, future agents may optimize against the fork instead of the upstream project. That is exactly the drift we want to avoid.

## Track 1: Upstream Testing Foundation

Goal: get a minimal, maintainable unit-test baseline accepted upstream.

Preferred shape for the first upstream PR:

- Add an iOS-hosted unit-test bundle named `SwiftfinTests`.
- Use Swift Testing with `import Testing`.
- Avoid XCTest in direct-code unit tests.
- Do not add integration tests, E2E tests, snapshot tests, offline playback tests, fixtures, or Xcode test plans in the first PR.
- Start with deterministic shared-logic tests only:
  - `DurationTests` for Jellyfin tick conversion, seconds/minutes/hours conversion, and negative duration `abs`.
  - `ArrayExtensionTests` for append/prepend helpers, conditional append/prepend, safe remove, and toggle.
  - `DirectionTests` for horizontal, vertical, all, and empty option-set behavior.

CI should be proposed explicitly, not assumed. Reasonable upstream options to discuss:

- No CI test job in the first PR: lowest budget impact, but tests rely on local/manual execution.
- Manual `workflow_dispatch` test job: useful for maintainers without running on every PR.
- PR test job with path filters or maintainer labels: better regression coverage with lower default cost.
- Always-on PR test job: best automated protection, highest macOS simulator cost.

The upstream PR should explain the tradeoff and let maintainers choose the CI posture they want.

## Track 2: Fork Quality Scaffolding

Goal: help AI-assisted development run repeatable checks locally without creating upstream drift.

Do not add fork-only test commands or quality scripts that assume a test target exists until the upstream test foundation has merged and `ai/main` has been updated from upstream.

After upstream accepts the test target, add fork-only automation under `.agents/`, likely:

- `.agents/scripts/swiftfin-quality.sh --quick`
  - SwiftFormat lint.
  - SwiftLint strict lint.
  - unused string check.
  - upstream-accepted unit-test command.
- `.agents/scripts/swiftfin-quality.sh --full`
  - quick checks.
  - existing iOS and tvOS build lanes.
  - manual real-device validation notes for playback, storage, networking, and offline workflows.

The fork script must call upstream project commands as they exist after the PR merges. It should not invent a parallel test definition.

## Drift Controls

Future agents should follow these guardrails:

- Treat `origin/main` or `upstream/main` as the source of truth for project structure, test targets, and CI.
- Keep `.agents/` limited to fork-only guidance and helper scripts.
- Do not implement the same test harness twice: once upstream and once in `.agents/`.
- Do not submit upstream PRs directly from `ai/main`.
- Before adding fork quality tooling, run `.agents/scripts/update-ai-main.sh` so `ai/main` contains the merged upstream testing foundation.
- Link any future `.agents/` quality script to the upstream-accepted commands instead of hard-coding speculative alternatives.

## Offline Playback Implication

Offline playback will need tests, but not before the baseline test target exists upstream.

Good next tests after the foundation lands:

- Pure policy tests for download quality defaults and storage-budget decisions.
- Manifest/state tests for local availability and sync eligibility.
- Resume/playstate sync tests using injectable clocks and fake reachability.

Those tests should be written around extracted pure logic, not around live Jellyfin servers, player engines, or device storage APIs in the first pass.
