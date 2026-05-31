# Record Fork Workflow Decisions With Agent ADRs

Status: accepted

We will record hard-to-reverse, non-obvious, tradeoff-driven AI workflow decisions as fork-only Agent ADRs under `.agents/adr/`. This keeps historical reasoning available to future agents without turning Swiftfin `Documentation/` into generated agent workspace material.

## Considered Options

- Keep decisions only in chat history: low ceremony, but fragile across compaction, new threads, and future agents.
- Put decisions in Swiftfin `Documentation/`: durable, but inappropriate for generated fork-only workflow scaffolding.
- Store ADRs under `.agents/adr/`: durable for this fork while remaining excluded from upstream PRs.

## Consequences

Future agents should scan `.agents/adr/` before changing workflow, branch, CI, or test strategy. Upstream-facing project decisions still need manual curation before they move into Swiftfin `Documentation/`.
