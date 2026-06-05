# Agent Research

Store fork-only source, API, product, and ecosystem research here.

Use this directory for findings that should survive across sessions but are not yet manually curated into Swiftfin `Documentation/`. If research becomes upstream-facing project documentation, rewrite and review it by hand before moving it into `Documentation/`.

## File Naming

Use descriptive, stable filenames that identify the subject being researched:

- `pr-<number>-<topic>-research.md` for pull-request investigations.
- `<feature-or-domain>-research.md` for broader source, API, or product research.

## Suggested Structure

Research files do not need a rigid template, but they should usually include:

- `Executive Summary`: the current read in a few paragraphs.
- `Summary`: scope, provenance, inspected refs, dates, API queries, and local branches.
- `Active Work Areas` or `Relationship To Tracker`: the actual problem decomposition.
- `Current Readiness Signals`: what suggests the work is ready, blocked, risky, or still WIP.
- `Open Questions`: unresolved decisions that future sessions or humans should validate.
- `Source Links`: primary issues, pull requests, discussions, commits, branches, docs, or local refs.

Prefer primary-source facts over interpretation. When including interpretation, label it clearly as interpretation.

## Provenance Expectations

Record enough context for the document to remain useful after branches move:

- Local date and timezone.
- Current local branch and commit.
- Upstream base ref and inspected head refs.
- GitHub issue or PR metadata that matters to the conclusion.
- Whether external reviews, comments, or third-party artifacts were used, and how much weight they should carry.

For pull-request research, capture at least the PR state, draft state, merge state, changed-file count, commit count, check status, and the current head SHA when inspected.
