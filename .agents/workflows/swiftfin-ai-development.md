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
