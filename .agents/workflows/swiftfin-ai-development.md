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
2. Falls back to `https://github.com/jellyfin/Swiftfin.git` if the configured `upstream` remote cannot be fetched.
3. Fast-forwards local `main`.
4. Pushes `main` to `origin`.
5. Switches to `ai/main`, creating it from `main` if needed.
6. Merges the updated `main` into `ai/main`.
7. Pushes `ai/main` to `origin`.

If the merge into `ai/main` conflicts, resolve it on `ai/main` and keep `.agents/` as fork-only context.

## Starting AI-Assisted Work

For exploratory or implementation work:

```bash
git switch ai/main
git switch -c feature/my-work
```

Use `.agents/` for agent notes, handoff details, scratch research, and workflow-specific files. Keep source changes and durable project documentation in their normal Swiftfin locations only when they are intended to be reviewed as upstream contribution material.

## Preparing An Upstream PR

Do not open upstream PRs directly from `ai/main` or from branches that include `.agents/` history.

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

## Documentation Rule

Markdown in Swiftfin `Documentation/` is not agent scratch space. It is project documentation and needs the same manual review as Swift source before an upstream PR.

Use `.agents/` for generated or agent-only markdown. Move content into `Documentation/` only after it has been curated into project-facing documentation.

