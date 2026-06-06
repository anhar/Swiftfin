# Respect Upstream Maintainer Attention

Status: accepted

We will intentionally make work in `ai/main` more cautious and sometimes less convenient when that protects the upstream Swiftfin repository, Jellyfin project norms, and maintainer attention. Respect for upstream is not limited to AI disclosure rules. It also means avoiding unnecessary notifications, timeline references, issue churn, review burden, and public breadcrumbs from fork-only agent work.

Agents must treat upstream-facing actions as human-owned actions. Do not open upstream PRs, create upstream issues, comment on upstream discussions, or publish upstream-facing PR text from agent output unless the human has explicitly reviewed the material and instructed that specific action. Agents may prepare drafts, evidence trails, and checklists, but the human contributor owns the final upstream communication.

Fork-only research may include upstream identifiers and links only inside the actual `.agents/research/` artifact: the filename and/or research-document body. Fork PR titles, descriptions, comments, commit messages, branch names, and other visible PR metadata must use topical wording instead. This avoids creating irrelevant upstream timeline events and avoids making upstream maintainers spend attention on fork-only agent context.

## Considered Options

- Optimize for agent convenience: easier for agents to link and reference everything directly, but it pushes cleanup cost and notification noise onto upstream maintainers.
- Ban upstream identifiers everywhere in `.agents/`: quiet, but it weakens the evidence trail and makes future research harder to verify.
- Allow identifiers only inside research artifacts and require human review for upstream-facing actions: preserves a citation-backed memory trail while keeping fork-only agent work from leaking into upstream workflows.

## Consequences

Future agents should assume extra local ceremony is intentional. Branch names, commit messages, fork PR bodies, and comments may need less precise topical wording so upstream timelines stay clean. Research files may carry precise citations because they are fork-only memory, but those citations must not be echoed into fork PR metadata.

When there is tension between agent speed and upstream respect, choose upstream respect. The `ai/main` workflow exists to make that tradeoff explicit: use the fork for drafts, research, validation targets, and memory building, then submit upstream only manually reviewed work that the contributor understands and is ready to stand behind.
