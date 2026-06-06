# Swiftfin Agent Workspace

This directory is fork-only agent context for AI-assisted Swiftfin development. It is intended to live on the `ai/main` branch in the `anhar/Swiftfin` fork and must not be included in upstream Jellyfin Swiftfin pull requests.

## Operating Ethos

We make our own lives harder in `ai/main` when that is the cost of respecting upstream Swiftfin, Jellyfin project rules, and maintainer attention. This is the fork's modus operandi: agent speed and convenience are secondary to keeping upstream workflows clean, human-owned, and reviewable.

Respect means more than following AI disclosure guidance. It means avoiding unnecessary upstream timeline events, notifications, issue churn, review burden, and public breadcrumbs from fork-only agent work. Do not open upstream PRs, create upstream issues, comment upstream, or publish upstream-facing PR text from agent output unless the human has explicitly reviewed the material and instructed that specific action.

See `.agents/adr/0007-respect-upstream-maintainer-attention.md` for the governing decision.

## Policy Summary

Swiftfin follows Jellyfin's LLM/AI Development Policy:

- AI assistance is allowed, but the contributor owns the final work.
- Every line submitted upstream must be reviewed by hand.
- The contributor must understand the code, docs, behavior, risks, and test coverage before opening a PR.
- PR descriptions, issue comments, feature requests, and community messages must be written by the contributor, not pasted from an AI response.
- Generated or agent-only files such as `.agents/`, `AGENTS.md`, `.codex/`, `.claude/`, and similar metadata must be removed before upstream PR preparation.
- Removing agent-only files is repository hygiene, not concealment. If AI materially assisted the work, disclose that in the contributor's own words and state that the submitted diff was manually reviewed and understood.
- Upstream Jellyfin PR/issue identifiers and links belong only in the actual `.agents/research/` artifact: the filename and/or research-document body.
- Fork-only PR titles, descriptions, comments, commit messages, branch names, and other visible PR metadata must not identify upstream Jellyfin PRs/issues by number or link. Avoid syntax such as `#123`, `jellyfin/Swiftfin#123`, plain phrases such as `PR 123`, or direct GitHub PR/issue URLs in fork PR conversation text because GitHub can create irrelevant upstream timeline references and visible fork-work breadcrumbs.

Swiftfin `Documentation/` files are treated like source files. They can be drafted with AI assistance during development, but they need the same manual review and curation as Swift code before submission upstream.

## Branch Model

- `main`: clean mirror of upstream Swiftfin `main`, pushed to the fork as `origin/main`.
- `ai/main`: fork-only base branch for AI-assisted development. It tracks this `.agents/` directory.
- Feature branches: branch from `ai/main` during AI-assisted exploration and development.
- Upstream PR branches: create from `origin/main`, then apply only manually curated source/docs changes. Do not include `.agents/` history or agent-only files in upstream PR branches.

## Discovery And Progressive Disclosure

This fork intentionally keeps agent guidance under `.agents/` instead of root `AGENTS.md`. That compromise reduces the chance that agent-only instructions are submitted upstream, but it also means future agents may not automatically discover this workspace context.

Impact for future agents:

- A fresh agent that only reads root project files may miss the `ai/main` branch model, sanitizer, ADRs, research conventions, and fork-only workflow terms.
- An agent that does inspect hidden workspace folders can progressively disclose context from this file, then `.agents/CONTEXT.md`, `.agents/adr/`, `.agents/research/`, and `.agents/workflows/` as needed.
- Research and ADR memory are only useful if the agent first discovers `.agents/`; otherwise the fork may behave like a clean upstream checkout with hidden local history.

Current recommendation:

- Keep `.agents/README.md` as the durable fork-only entrypoint.
- At the start of agent sessions on `ai/main` or branches derived from it, inspect `.agents/README.md` before making workflow, research, planning, or upstream-PR-prep decisions.
- If future agents repeatedly miss `.agents/` context or violate the branch/sanitizer/research conventions, reconsider adding a minimal root `AGENTS.md` pointer on `ai/main`.

If a root `AGENTS.md` is added later, keep it small and fork-only. It should point agents to `.agents/README.md`, state that `.agents/` and `AGENTS.md` must never be submitted upstream, and rely on `.agents/scripts/sanitize-for-upstream.sh` for cleanup. Do not duplicate detailed workflow policy in root `AGENTS.md`.

## Scripts

- `.agents/scripts/update-ai-main.sh`: update `main` from upstream, push `origin/main`, merge the updated `main` into `ai/main`, and push `origin/ai/main`.
- `.agents/scripts/sanitize-for-upstream.sh`: remove fork-only agent artifacts from a branch before upstream PR review, then show the remaining diff.

Run scripts from anywhere inside the Swiftfin repo:

```bash
bash .agents/scripts/update-ai-main.sh
bash .agents/scripts/sanitize-for-upstream.sh
```

## Agent Working Files

- `.agents/research/`: source, API, and product investigations that are not ready for Swiftfin `Documentation/`.
- `.agents/plans/`: implementation plans, research-to-plan transitions, and other agent-authored planning markdown that is not ready for Swiftfin `Documentation/`.
- `.agents/adr/`: historical decision records for hard-to-reverse, non-obvious, tradeoff-driven workflow decisions.
- `.agents/workflows/`: reusable workflow guidance.

Research and plans are working documents. Move them into Swiftfin `Documentation/` only after manual curation and only when they are intended as upstream project documentation.

## Vendored Skills

- `.agents/vendor/skills/grill-with-docs/`: third-party skill adapted from Matt Pocock's `skills` library for ADR and glossary-driven planning.

Vendored skills must keep their upstream source and license references in the vendored folder.
