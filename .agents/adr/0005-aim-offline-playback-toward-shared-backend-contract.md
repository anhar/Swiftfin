# Aim Offline Playback Toward A Shared Backend Contract

Status: accepted

Swiftfin offline playback should be treated as a practical client-managed bridge, not the ideal final architecture. Existing Jellyfin APIs are enough for Swiftfin to make incremental progress now, but the long-term ecosystem goal should be a shared Jellyfin backend/client offline contract that can serve Swiftfin, Android clients, and other Jellyfin clients consistently.

## Context

The offline playback research in `.agents/research/offline-playback-api-research.md` found that Jellyfin Server exposes useful primitives: direct downloads, metadata queries, playback negotiation, streaming/transcoding endpoints, image/subtitle endpoints, and playstate/user-data updates. It also found no current first-class backend API for offline jobs, device manifests, storage-aware download profiles, durable optimized offline artifacts, or conflict-aware offline sync.

Swiftfin's upstream issues split local downloads into practical slices: download and metadata storage, download options, ItemView controls, queue resilience, and offline browsing/playback. Historical branches show this is feasible client-side, but also show the risk of large, tangled PRs and duplicated business logic.

## Decision

We will aim for a shared Jellyfin backend/client offline contract as the ideal end state, while allowing Swiftfin to pursue practical client-managed offline work first.

Swiftfin implementation work should clearly separate:

- Tactical client-owned behavior needed because the backend contract does not exist yet.
- Candidate backend contract concepts that should eventually be standardized for all Jellyfin clients.

Future Swiftfin offline code should be structured so that download policy, offline membership, local manifests, quality decisions, progress sync, and support-asset bundling can migrate toward a server-defined contract later.

## Considered Options

- Wait for a Jellyfin Server offline contract before doing Swiftfin work: architecturally clean, but blocks user value indefinitely. No active backend issue, pull request, or roadmap document currently suggests that such a contract is imminent.
- Treat Swiftfin-only client-managed offline playback as the final architecture: fastest for Swiftfin, but likely to create inconsistent behavior across Jellyfin clients, duplicated business rules, fragile dependence on playback/transcode internals, and future breaking changes when server behavior evolves.
- Build a practical Swiftfin client-managed bridge while explicitly aiming for a shared backend contract: gives Swiftfin a path to incremental user value, lets real client work inform future API design, and keeps pressure on the design to remain portable across clients.

We choose the third option.

## Practical State

The practical near-term state is Swiftfin-managed offline playback using existing Jellyfin primitives:

- Download original media through the current download endpoint where permissions allow.
- Cache item, parent, image, subtitle, and selected media-source metadata locally.
- Queue download and playback-progress work on the client.
- Use conservative storage and quality defaults where the backend provides no profile API.
- Sync user progress back through existing playstate/user-data endpoints when the server becomes reachable.
- Keep offline browsing/playback isolated behind local services and view models rather than scattering server assumptions throughout UI code.

This is the path we prioritize first because it is achievable, reviewable in slices, and aligned with the current Swiftfin issue decomposition.

## Ideal State

The ideal end state is a Jellyfin-defined offline contract available to multiple clients. That contract would likely include:

- Server capability discovery for offline support.
- Offline save requests for items, seasons, series, playlists, and collections.
- Download profiles such as original, compatible, storage-saving, max bitrate, max resolution, codec, container, and subtitle preferences.
- Server-managed conversion jobs with durable status, retry, cancellation, expiration, and error reporting.
- A device/user offline manifest describing saved membership and required support assets.
- A defined bundle model for media, metadata, artwork, subtitles, fonts, chapters, and selected media-source identity.
- Conflict-aware progress sync rules for offline playback.
- Permission, revocation, deletion, and media-replacement semantics.
- Optional storage-budget hints while preserving final storage ownership on the client device.

This ideal state should work for Swiftfin and other clients rather than encoding Swiftfin-specific behavior as the only interpretation of offline playback.

## Consequences

Future agents should not present client-managed offline logic as the final architecture. It is a bridge until Jellyfin Server exposes a proper contract.

Implementation plans should call out which decisions are temporary client ownership and which are candidates for a future Jellyfin API proposal.

Swiftfin should avoid hard-coding playback/transcode internals as if they were durable offline-download guarantees. Where existing streaming or transcoding endpoints are reused, the code and documentation should make that assumption explicit.

Upstream PRs should stay small and practical, but the architecture should preserve a path toward a cross-client Jellyfin offline contract.
