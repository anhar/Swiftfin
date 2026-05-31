# Swiftfin AI-Assisted Development Workflow

## Purpose

Use AI tools for research, planning, and implementation support without leaking agent-only context into upstream Swiftfin pull requests. The key rule is simple: AI can help produce drafts, but the contributor must manually review, understand, and curate everything submitted upstream.

## Keeping The Fork Base Current

Use `ai/main` as the working base for AI-assisted development:

```bash
bash .agents/scripts/update-ai-main.sh
```

The update script:

1. Fetches upstream Swiftfin `main`.
2. Fast-forwards local `main`.
3. Pushes `main` to `origin`.
4. Switches to `ai/main`, creating it from `main` if needed.
5. Merges the updated `main` into `ai/main`.
6. Pushes `ai/main` to `origin`.

If fetching from `upstream` fails, fix the configured remote or SSH credentials instead of falling back to a different URL. If the merge into `ai/main` conflicts, resolve it on `ai/main` and keep `.agents/` as fork-only context.

## Starting AI-Assisted Work

For exploratory or implementation work:

```bash
git switch ai/main
git switch -c feature/my-work
```

Use `.agents/` for agent notes, handoff details, scratch research, and workflow-specific files. Keep source changes and durable project documentation in their normal Swiftfin locations only when they are intended to be reviewed as upstream contribution material.

Use `.agents/research/` for agent-authored source, API, product, or ecosystem research. Use `.agents/plans/` for implementation plans or feature strategy drafts. Use `.agents/adr/` only when a decision is hard to reverse, surprising without context, and tradeoff-driven. Use Swiftfin `Documentation/` only for manually curated upstream project documentation.

## Decision Records

Use the vendored third-party `grill-with-docs` skill for plans that need careful domain, workflow, or architectural scrutiny:

- Skill: `.agents/vendor/skills/grill-with-docs/SKILL.md`
- Original library: https://github.com/mattpocock/skills
- Agent glossary: `.agents/CONTEXT.md`
- Agent ADRs: `.agents/adr/`

Create Agent ADRs only for decisions that are meaningful to reverse, surprising without context, and the result of a real tradeoff. Keep these ADRs fork-only unless a decision is manually curated into upstream-facing Swiftfin documentation.

## Upstream Project Standards

Before changing Swiftfin source, read the relevant project guidance:

- `Documentation/contributing.md`: setup, PR requirements, architecture, design, and feature discussion expectations.
- `Documentation/version.md`: minimum OS policy and SwiftUI-driven OS support tradeoffs.
- `Documentation/players.md`: playback architecture and Swiftfin/VLCKit vs Native/AVPlayer behavior.
- `Documentation/libraries.md`: supported library types and known product scope.
- `.github/workflows/ci.yml` and `.github/workflows/validate-pr.yaml`: current CI build and validation commands.
- `.agents/workflows/swiftfin-testing-strategy.md`: fork-only testing strategy and the current pause on adding test targets or CI until upstream direction is clear.

Follow the repository tooling exactly:

```bash
brew bundle --file Brewfile
swiftformat . --lint --config ".swiftformat"
swiftlint lint --strict --config ".swiftlint.yml"
swift Scripts/Translations/FindUnusedStrings.swift
```

SwiftFormat is configured in `.swiftformat` for Swift 6.2, a 140-column max width, 4-space indentation, no semicolons, the project MPL header, and several enabled/disabled rewrite rules. Let SwiftFormat own formatting decisions instead of hand-formatting around them.

SwiftLint currently enforces the project custom rule against hard-coded display strings. User-facing strings in SwiftUI controls such as `Text`, `Button`, `Label`, `Toggle`, `Picker`, `Section`, and `LabeledContent` should use `L10n`, not string literals. Only add a `swiftlint:disable` directive when there is a narrow, reviewed justification.

SwiftGen reads `Translations/en.lproj` and generates `Shared/Strings/Strings.swift`. Add new non-experimental user-facing strings to `Translations/en.lproj/Localizable.strings`, run `swiftgen`, and review generated output instead of hand-editing `Shared/Strings/Strings.swift`.

The recommended Xcode version is the one pinned in `.github/workflows/ci.yml`; at the time this workflow was written, CI uses Xcode 26.3. Upstream PRs must keep automated iOS and tvOS builds passing, must not attach a developer account, and must satisfy SwiftFormat, SwiftLint, unused-string checks, localization expectations, and applicable labels.

## SwiftUI And UI Code Guardrails

Swiftfin is developed using SwiftUI. The iOS and tvOS clients share backend code under `Shared/`, while each client owns platform-specific views under `Swiftfin/` and `Swiftfin tvOS/`. UI work that touches shared behavior should consider both clients, even when the visible change starts on one platform.

Good SwiftUI in this repo generally means:

- Prefer native SwiftUI/UIKit components and existing Swiftfin components/modifiers before introducing custom UI.
- Keep UI state ownership clear: use `@StateObject` when a view owns a view model, injected/bound state when it does not, and the existing `ViewModel`/`Stateful` action-state pattern for non-trivial async behavior.
- Put networking, playback, persistence, and business logic in shared services, managers, or view models rather than inside `body`.
- Navigate through `@Router` and `NavigationRoute` instead of ad hoc presentation flows.
- Use existing design helpers such as `edgePadding`, poster styles, `ErrorView`, `ContentUnavailableView`, `Form`, `Section`, `ChevronButton`, `@Default(.accentColor)`, and platform helpers like `PlatformView` or `#if os(iOS)/#if os(tvOS)`.
- Respect the Jellyfin/Swiftfin theme and user customization while avoiding one-off colors, spacing, typography, and controls that do not match nearby screens.
- Treat accessibility, localization, loading, empty, error, cancellation, and refresh states as part of the UI implementation, not polish after the fact.

Bad SwiftUI in this repo usually looks like hard-coded display text, view bodies that perform API work directly, duplicated iOS/tvOS UI that should share a model or component, bespoke controls where a native or existing component fits, unlocalized settings labels, storage-heavy work on the main actor, or platform assumptions that break focus, PiP, local network access, or device storage behavior.

For UI/UX changes, `Documentation/contributing.md` says there is no separate formal design guide, but the project aims to use native SwiftUI/UIKit components while adhering to a Jellyfin theme. New UI components can receive upstream feedback or later redesign, and user customization is welcome only when it stays maintainable and preserves Swiftfin's distinct design.

Testing expectations should match risk. Simulator testing is useful, but the project specifically calls out picture-in-picture, device storage, and local network access as areas where real hardware is recommended. Offline playback work should be validated on real devices because it directly involves storage, networking reachability, and playback behavior.

Do not add fork-only test harnesses, CI jobs, or `.agents/` quality scripts that assume a new Swiftfin test target exists until the upstream testing foundation has merged. Keep testing strategy in `.agents/workflows/swiftfin-testing-strategy.md`, then update `ai/main` from upstream before adding local automation around accepted project commands.

## Preparing An Upstream PR

Prepare upstream PRs from `origin/main` so the submitted branch contains only manually curated project changes. Removing `.agents/` is not a concealment step; it keeps fork-only development scaffolding out of upstream. If AI materially assisted the work, disclose that in your own words and state that you manually reviewed and understand the submitted diff.

Recommended PR preparation flow:

```bash
git switch main
git switch -c feature/my-upstream-pr
```

Then apply only the manually curated changes from the AI-assisted branch. Before opening the PR:

```bash
bash .agents/scripts/sanitize-for-upstream.sh
git status --short
git diff --name-only origin/main...HEAD
```

Manually review every remaining file and line. The PR body must be written in the contributor's own words.

### Review Guardrails

Before upstream submission, confirm:

- The branch contains only source, tests, resources, or project documentation intended for upstream.
- All `.agents/`, `AGENTS.md`, `.codex/`, `.claude/`, and similar development scaffolding has been removed.
- AI-assisted changes have been manually reviewed line by line.
- The contributor can explain the behavior, risks, and tests without pasting AI output.
- Any material AI assistance is disclosed in the contributor's own words.
- Tests are proportional to the change: unit tests for logic, UI/manual validation for user-facing flows, and broader end-to-end checks for cross-screen or playback behavior.

## Documentation Rule

Markdown in Swiftfin `Documentation/` is not agent scratch space. It is project documentation and needs the same manual review as Swift source before an upstream PR.

Use `.agents/` for generated or agent-only markdown. Move content into `Documentation/` only after it has been curated into project-facing documentation.
