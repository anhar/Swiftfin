# Document Upstream PR Research As Evidence, Not Patch Plans

Status: accepted

When documenting upstream PRs for fork-only agent memory, we will capture the problem statement, observed evidence, labeled inference, open questions, and bounded `Candidate Hypotheses / Future-Agent Validation` rather than turning concerns into implementation instructions. Hypothesis items must include evidence, inference, validation, confidence, and a "do not treat as" disclaimer. This keeps `.agents/research/` useful as a context-building paper trail for future agents while avoiding accidental ownership of upstream fixes that have not been requested.

Upstream PR/issue identifiers and direct links belong only inside the actual research artifact: the `.agents/research/` filename and/or the contents of that research document. Fork PR surfaces must not directly link, autolink, or visibly identify upstream PRs/issues. This is a hard rule for fork PR titles, descriptions, comments, commit messages, branch names, and other visible PR metadata because GitHub can publish those references back into the upstream Jellyfin timeline.

This rule is a concrete application of ADR 0007: we accept extra local friction because respecting upstream maintainer attention matters more than fork-agent convenience.

## Considered Options

- Write PR research like a code-review patch plan: immediately actionable, but it can blur documentation with implementation direction and overstate unverified inferences.
- Keep only raw links and metadata: safe, but too thin for future agents to recover the reasoning.
- Use evidence/inference/open-question research notes with a bounded hypothesis section: preserves reasoning and uncertainty while staying out of implementation mode.
- Allow upstream PR/issue identifiers only in the research artifact filename and/or body: preserves an auditable evidence trail while keeping fork PR conversation surfaces isolated from upstream.
- Put upstream PR/issue links in fork PR bodies: rejected. This creates noisy upstream timeline references for fork-only agent work and is not allowed.

## Consequences

Future upstream PR research should distinguish what the PR claims, what the code shows, what was directly verified, what is inferred, and what remains unknown. Candidate hypotheses can be recorded, but they are not endorsed fixes or maintainer decisions. If a user explicitly asks for fixes or implementation planning, that work can happen separately from the research note.

Source links and upstream PR/issue identifiers may remain inside `.agents/research/` filenames and research-document bodies as evidence. They must not appear in fork PR titles, descriptions, comments, commit messages, branch names, or other visible PR metadata. Fork PR surfaces should use topical wording such as `track-index research`, `playback investigation`, or `poster-library research note` instead of `PR 123`, `#123`, `owner/repo#123`, or a direct upstream GitHub URL.
