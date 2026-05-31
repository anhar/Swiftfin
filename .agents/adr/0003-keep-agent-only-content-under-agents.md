# Keep Agent-Only Content Under .agents

Status: accepted

We will store generated agent context, workflow notes, skills, ADRs, and helper scripts under `.agents/`. Swiftfin `Documentation/` is reserved for manually curated project documentation that should be reviewed like source before any upstream PR.

## Considered Options

- Use root `AGENTS.md` files: common for agents, but these can scatter through the repo and must be sanitized before upstream PRs.
- Use Swiftfin `Documentation/`: durable, but blurs the line between generated agent context and project documentation.
- Use `.agents/`: centralizes fork-only scaffolding and makes sanitation straightforward.

## Consequences

The sanitizer must continue removing `.agents/` and related agent files from upstream PR branches. If an agent note becomes useful upstream documentation, it must be rewritten and reviewed by hand before moving.
