# Document Upstream PR Research As Evidence, Not Patch Plans

Status: accepted

When documenting upstream PRs for fork-only agent memory, we will capture the problem statement, observed evidence, labeled inference, open questions, and bounded `Candidate Hypotheses / Future-Agent Validation` rather than turning concerns into implementation instructions. Hypothesis items must include evidence, inference, validation, confidence, and a "do not treat as" disclaimer. This keeps `.agents/research/` useful as a context-building paper trail for future agents while avoiding accidental ownership of upstream fixes that have not been requested.

## Considered Options

- Write PR research like a code-review patch plan: immediately actionable, but it can blur documentation with implementation direction and overstate unverified inferences.
- Keep only raw links and metadata: safe, but too thin for future agents to recover the reasoning.
- Use evidence/inference/open-question research notes with a bounded hypothesis section: preserves reasoning and uncertainty while staying out of implementation mode.

## Consequences

Future upstream PR research should distinguish what the PR claims, what the code shows, what was directly verified, what is inferred, and what remains unknown. Candidate hypotheses can be recorded, but they are not endorsed fixes or maintainer decisions. If a user explicitly asks for fixes or implementation planning, that work can happen separately from the research note.
