---
name: grill-with-docs
description: Stress-test plans against Swiftfin's existing language, documented decisions, and codebase before implementation. Use when a plan has architectural, workflow, or domain consequences that should be captured in glossary terms or ADRs.
---

# Grill With Docs

This is a vendored third-party skill adapted for the Swiftfin agent workspace.

- Original library: https://github.com/mattpocock/skills
- Original skill: https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md
- Original license: https://github.com/mattpocock/skills/blob/main/LICENSE
- Copyright: 2026 Matt Pocock

## Purpose

Use this skill to challenge a plan before it hardens into implementation. The goal is to sharpen terms, compare claims against the codebase and existing docs, and capture decisions while the reasoning is still fresh.

## Swiftfin Agent Workspace Adaptation

For fork-only AI-assisted Swiftfin work, use:

- `.agents/CONTEXT.md` for agent-workflow glossary terms.
- `.agents/adr/` for fork-only agent workflow ADRs.
- `Documentation/` only for manually curated upstream project documentation.

Do not put generated or agent-only ADRs into Swiftfin `Documentation/`. If a decision belongs upstream, curate it by hand on a branch from `origin/main`.

## Session Rules

- Ask one sharp question at a time when the decision cannot be resolved from the codebase or existing docs.
- If the answer can be found locally, inspect the repo instead of asking.
- Challenge vague or overloaded terms and propose one canonical term.
- Cross-reference user claims with code or documentation when possible.
- Capture resolved terms in `.agents/CONTEXT.md` immediately.
- Create ADRs sparingly, only when the decision is hard to reverse, surprising without context, and the result of a real tradeoff.

## ADR Criteria

Create an ADR only when all three are true:

1. The decision is meaningful to reverse later.
2. A future agent or maintainer would wonder why this path was chosen.
3. Real alternatives existed and were rejected for specific reasons.

If any condition is missing, do not write an ADR. Let small reversible choices stay in normal notes or commits.

## Supporting Formats

- ADR format: `.agents/vendor/skills/grill-with-docs/ADR-FORMAT.md`
- Context format: `.agents/vendor/skills/grill-with-docs/CONTEXT-FORMAT.md`
