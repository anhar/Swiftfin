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
- `Problem Statement`: what problem the upstream work is trying to solve, in project/user terms.
- `Options Evaluated`: approaches visible in the PR, prior work, comments, or code history; label inferred options as inference.
- `How This Work Addresses It`: what the PR or research subject changes, and whether that appears complete, partial, or unverified.
- `Active Work Areas` or `Relationship To Tracker`: the actual problem decomposition.
- `Current Readiness Signals`: what suggests the work is ready, blocked, risky, or still WIP.
- `Evidence-Backed Concerns`: concerns grounded in source, PR text, issue comments, checks, or local refs.
- `Candidate Hypotheses / Future-Agent Validation`: bounded hypotheses future sessions can verify to strengthen or falsify the paper trail.
- `Open Questions`: unresolved decisions that future sessions or humans should validate.
- `Source Links`: primary issues, pull requests, discussions, commits, branches, docs, or local refs.

Prefer primary-source facts over interpretation. When including interpretation, label it clearly as interpretation.

Keep upstream source links and identifiers inside the research artifact only: the `.agents/research/` filename and/or the research-document body. When opening or commenting on fork-only PRs that add these research files, do not put upstream PR/issue numbers, direct upstream PR/issue links, or GitHub autolink syntax in the fork PR title, body, comments, commit messages, or other visible PR metadata.

## Upstream PR Research

When documenting an upstream PR, the goal is context and memory building. The research should help a future agent understand what the PR is trying to accomplish, what has been observed, what remains uncertain, and where the proof lives. It is not an implementation plan unless the user explicitly asks for one.

Use a paper-trail style:

- `Evidence`: cite the PR body, issue links, comments, checks, commits, changed files, or exact code paths.
- `Inference`: state what the evidence appears to imply, using words like "appears", "may", or "likely" when runtime behavior has not been tested.
- `Open question`: capture what would need to be verified before treating the inference as fact.
- `Validation target`: name reproducible scenarios future agents can check, without prescribing code changes.

When a PR critique would benefit from possible next investigations, use the exact section header `Candidate Hypotheses / Future-Agent Validation`. Each item in that section should include:

- `Evidence`: source, code, comment, check, or artifact that triggered the hypothesis.
- `Inference`: what may be true, clearly labeled as unverified when appropriate.
- `Validation`: how to prove or disprove it.
- `Confidence`: `low`, `medium`, or `high`.
- `Do not treat as`: usually "an endorsed fix or maintainer decision."

Avoid turning observations into patch instructions. For example, prefer "the playback item appears to consult an empty `DeviceProfile`; verify whether another profile source exists" over "pass the built `DeviceProfile` into `MediaPlayerItem`." Prefer "encoded subtitle disable flow is unverified" over "reorder the rebuild logic."

Separate these concepts clearly:

- What the PR claims.
- What the code currently does.
- What the investigation directly verified.
- What the investigation infers.
- What remains unknown.

If the user asks for a critique, retrospective, or concern list in this research context, keep it at the documentation level unless they explicitly ask for implementation work.

## Provenance Expectations

Record enough context for the document to remain useful after branches move:

- Local date and timezone.
- Current local branch and commit.
- Upstream base ref and inspected head refs.
- GitHub issue or PR metadata that matters to the conclusion.
- Whether external reviews, comments, or third-party artifacts were used, and how much weight they should carry.

For pull-request research, capture at least the PR state, draft state, merge state, changed-file count, commit count, check status, and the current head SHA when inspected.
