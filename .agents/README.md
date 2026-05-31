# Swiftfin Agent Workspace

This directory is fork-only agent context for AI-assisted Swiftfin development. It is intended to live on the `ai/main` branch in the `anhar/Swiftfin` fork and must not be included in upstream Jellyfin Swiftfin pull requests.

## Policy Summary

Swiftfin follows Jellyfin's LLM/AI Development Policy:

- AI assistance is allowed, but the contributor owns the final work.
- Every line submitted upstream must be reviewed by hand.
- The contributor must understand the code, docs, behavior, risks, and test coverage before opening a PR.
- PR descriptions, issue comments, feature requests, and community messages must be written by the contributor, not pasted from an AI response.
- Generated or agent-only files such as `.agents/`, `AGENTS.md`, `.codex/`, `.claude/`, and similar metadata must be removed before upstream PR preparation.
- Removing agent-only files is repository hygiene, not concealment. If AI materially assisted the work, disclose that in the contributor's own words and state that the submitted diff was manually reviewed and understood.

Swiftfin `Documentation/` files are treated like source files. They can be drafted with AI assistance during development, but they need the same manual review and curation as Swift code before submission upstream.

## Branch Model

- `main`: clean mirror of upstream Swiftfin `main`, pushed to the fork as `origin/main`.
- `ai/main`: fork-only base branch for AI-assisted development. It tracks this `.agents/` directory.
- Feature branches: branch from `ai/main` during AI-assisted exploration and development.
- Upstream PR branches: create from `origin/main`, then apply only manually curated source/docs changes. Do not include `.agents/` history or agent-only files in upstream PR branches.

## Scripts

- `.agents/scripts/update-ai-main.sh`: update `main` from upstream, push `origin/main`, merge the updated `main` into `ai/main`, and push `origin/ai/main`.
- `.agents/scripts/sanitize-for-upstream.sh`: remove fork-only agent artifacts from a branch before upstream PR review, then show the remaining diff.

Run scripts from anywhere inside the Swiftfin repo:

```bash
bash .agents/scripts/update-ai-main.sh
bash .agents/scripts/sanitize-for-upstream.sh
```
