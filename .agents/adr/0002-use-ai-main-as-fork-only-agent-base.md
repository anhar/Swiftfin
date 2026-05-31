# Use ai/main As Fork-Only Agent Base

Status: accepted

We will keep `main` as a clean mirror of upstream Swiftfin and use `ai/main` as the fork-only base branch for AI-assisted development. This preserves upstream alignment while giving agents a durable place for `.agents/` guidance, scripts, skills, ADRs, and handoff context.

## Considered Options

- Work directly on `main`: simple, but risks mixing fork scaffolding into a branch that should mirror upstream.
- Create unrelated feature branches from `main`: cleaner per feature, but future agents lose shared workflow context.
- Use `ai/main`: keeps shared agent context while preserving `main` as an upstream mirror.

## Consequences

Feature exploration can branch from `ai/main`, but upstream PR prep still starts from `origin/main` and receives only manually curated project changes.
