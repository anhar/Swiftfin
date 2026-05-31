# Swiftfin Agent Context

This glossary defines fork-only language for AI-assisted Swiftfin development. It is not Swiftfin product documentation and must not be submitted upstream.

## Language

**AI-Assisted Development**: Work where an AI agent helps with research, planning, editing, or verification, while the human contributor remains responsible for every submitted line and explanation.
_Avoid_: AI DLC, generated work

**Fork-Only Agent Context**: Files that help agents operate in this fork but are not intended for upstream Swiftfin. This includes `.agents/` guidance, ADRs, skills, scripts, and handoff notes.
_Avoid_: Project documentation, upstream docs

**ai/main**: The fork-only base branch for AI-assisted development. It tracks `.agents/` so future agents inherit local workflow context.
_Avoid_: main, upstream main

**Upstream PR Branch**: A branch created from `origin/main` for a manually curated Swiftfin contribution. It must exclude fork-only agent context.
_Avoid_: ai/main branch, agent branch

**Testing Foundation**: The smallest upstream-acceptable unit-test baseline for Swiftfin, centered on deterministic direct-code tests before broader integration, UI, or offline playback tests.
_Avoid_: Full test suite, E2E foundation

**Agent ADR**: A fork-only architecture decision record stored under `.agents/adr/` when a workflow decision is hard to reverse, non-obvious, and tradeoff-driven.
_Avoid_: Scratch note, implementation plan

**Agent Research**: A fork-only research document stored under `.agents/research/` for source, API, product, or ecosystem findings that have not been curated into upstream project documentation.
_Avoid_: Implementation plan, project documentation

**Agent Plan**: A fork-only planning document stored under `.agents/plans/` for agent-authored implementation plans, research-to-plan transitions, or feature strategy drafts that are not curated upstream documentation.
_Avoid_: ADR, project documentation

**Client-Managed Offline Bridge**: A practical Swiftfin-owned offline playback implementation built on existing Jellyfin primitives while the server lacks a first-class offline API.
_Avoid_: Final offline architecture, Swiftfin-only offline standard

**Shared Offline Contract**: The ideal future Jellyfin backend/client API contract for offline jobs, manifests, download profiles, support assets, and progress sync that can serve multiple clients consistently.
_Avoid_: Swiftfin-only contract, local workaround
