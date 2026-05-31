# Offline Playback API Research

## Executive Summary

The current evidence supports a client-managed Swiftfin offline playback strategy. Jellyfin already exposes enough backend primitives for a useful offline experience: direct original-file downloads, library metadata queries, playback negotiation, media streaming endpoints, image and subtitle access, and playstate/user-data reporting. Those primitives can support downloaded playback, local metadata and artwork caches, subtitle sidecars, parent/child browsing data, and delayed watch-progress reconciliation once the server is reachable again.

The backend does not currently provide a complete offline product surface. There is no first-class offline job API, no server-side offline queue, no device offline manifest, no quality-profile download API, no storage-budget-aware recommendation system, no conflict-aware offline sync API, and no durable "make me an optimized offline copy" workflow separate from normal playback/transcode machinery. Existing policy fields such as `EnableSyncTranscoding` and `EnableMediaConversion` do not currently appear to back a usable offline sync/conversion controller API.

The live `jellyfin/jellyfin` backlog and repository scan reinforce that conclusion. Open backend issues and PRs contain adjacent work around playlist downloads, HTTP source downloads, progress state, media-source selection, bitrate/transcode behavior, subtitle delivery, image caching, and transcode cache lifecycle, but no open issue, pull request, or in-repo roadmap document was found that proposes a first-class server-owned offline mode. These backend changes may improve the primitives Swiftfin can consume, but they do not move offline playback ownership to Jellyfin Server.

The upstream Swiftfin workstreams make the likely client-side decomposition clearer. The local downloads effort is split across download and metadata storage (#1784), direct vs transcoded download options (#1785), ItemView download controls (#1787), queue resilience and edge cases (#1788), and local Downloads browsing/playback (#1789). Historical branches (#362 and #1065), the current draft PR #2012, and the #1784-linked Braypolk fork branch all demonstrate that the feature is feasible with existing backend primitives, but also show why one large offline-download PR is hard to review and likely to sprawl across storage, playback, UI, and architecture concerns.

The current draft PR #2012 mostly overlaps the #1784 foundation: background original-file downloads, queue state, metadata, image/subtitle sidecars, and experimental UI. It only stubs transcoded downloads, does not implement downloaded-file playback, does not solve progress sync conflicts, and does not provide storage-profile or auto-download policy. The Braypolk fork goes further into background retry, queue services, local browsing, and playback-facing UI, but its size and maintainer feedback make it useful as design evidence rather than an upstream-ready direction.

The practical path is therefore incremental. Start with a narrow, reviewable local download and metadata foundation, then layer in download-quality/profile decisions, state-aware user controls, resilient queue and recovery behavior, and finally a true offline library view that can browse and play saved content while disconnected. Auto-download rules, storage budgets, "latest episodes" behavior, and richer conflict policies remain important, but they should sit on top of those foundations rather than drive the first implementation slice.

## Summary

This document captures what the current Jellyfin backend APIs appear to provide for a future Swiftfin offline playback experience. It is research only, not an implementation plan.

The ideal user experience is broader than the backend currently models: a user should be able to browse saved library content while fully offline, play locally stored media, and sync watch progress back to the server once the client can reach it again. Jellyfin exposes enough primitives for a client-managed version of that workflow, but it does not currently expose a first-class offline viewing, offline sync, or optimized offline download API.

Research basis:

- Provenance timestamps use the local `Europe/Stockholm` timezone.
- Jellyfin backend API/source pass:
  - Provenance normalized at `2026-05-31 13:35:02 CEST (+0200)`.
  - Backend API/source checkout originally inspected at `jellyfin/jellyfin` commit `2a95223c6718bf8892369322b8a30a45e430739f` from 2026-05-29.
  - Backend live backlog and roadmap validation used local backend ref `upstream/master` at commit `99e9b2310f8a2c2a8bc630b31243df63507b1e17`.
  - Current `jellyfin/jellyfin` open issue/PR counts checked through GitHub: 485 open issues and 188 open pull requests.
  - Open backend issues and pull requests were scanned for offline/download/sync/playstate/cache/transcode/manifest/queue terms.
  - Repository docs were scanned for roadmap/offline planning references.
- Official Jellyfin API documentation checked at `https://api.jellyfin.org/`.
- Swiftfin client/workstream pass:
  - Provenance normalized at `2026-05-31 13:35:02 CEST (+0200)`.
  - Baseline refs for `jellyfin/Swiftfin` analysis: `upstream/main` and fork `origin/main`, both at commit `7087d4985141610b34a050814de6aee490140dcc`.
  - Upstream issues inspected through GitHub:
    - [`jellyfin/Swiftfin#57` Local Downloads](https://github.com/jellyfin/Swiftfin/issues/57)
    - [`jellyfin/Swiftfin#1784` DownloadManager and Metadata Storage](https://github.com/jellyfin/Swiftfin/issues/1784)
    - [`jellyfin/Swiftfin#1785` DownloadManager Download Options](https://github.com/jellyfin/Swiftfin/issues/1785)
    - [`jellyfin/Swiftfin#1787` ItemView Download UI & Options](https://github.com/jellyfin/Swiftfin/issues/1787)
    - [`jellyfin/Swiftfin#1788` DownloadManager Advanced Management & Edge Cases](https://github.com/jellyfin/Swiftfin/issues/1788)
    - [`jellyfin/Swiftfin#1789` Downloads ItemView & PagingLibraryView](https://github.com/jellyfin/Swiftfin/issues/1789)
  - Pull request and fork branches inspected as local refs:
    - [`jellyfin/Swiftfin#2012` Download Manager](https://github.com/jellyfin/Swiftfin/pull/2012): local branch `research/pr-2012`, merge base with `upstream/main` `5f5ca24bbeda3013e91f4f6fa695a94b05da242b`, head `e67c213a048eac9a0d5f3ca16f6bf76a9904c594`.
    - [`jellyfin/Swiftfin#1752` Posters, Libraries, Home](https://github.com/jellyfin/Swiftfin/pull/1752): local branch `research/pr-1752`, merge base with `upstream/main` `e8d20178d8164b20e45b138e441af6b2b2a9ed4d`, head `e7bae1d216677aa3915b12846333e574a3948278`.
    - [`jellyfin/Swiftfin#1065` Start work on offline download support](https://github.com/jellyfin/Swiftfin/pull/1065): local branch `research/pr-1065`, merge base with `upstream/main` `5334c57c65853bb4d3184f6de04ad8ca6ba24993`, head `39678f9b95471737d1c73e3f0c61ac1084d86cf8`.
    - [`jellyfin/Swiftfin#362` Pre-Pre-Alpha Downloading Items](https://github.com/jellyfin/Swiftfin/pull/362): local branch `research/pr-362`, merge base with `upstream/main` `a6822aa7394998076796f068348b674154686008`, head `56f20a7eca1b3df94c46a874ad41052c6eceab2e`.
    - Fork branch linked from #1784 comments: `Braypolk/Swiftfin` branch `Feature-DownloadManager-and-Metadata-Storage-#1784`, local branch `research/braypolk-1784`, merge base with `upstream/main` `88dfe6e81484367664c022b2c2af6940b1e60cf0`, head `067e694ddbbe3e9827227e587dc72ea0749371f8`.

## Existing Jellyfin APIs

### Original Media Download

Jellyfin has a direct media download endpoint:

- `GET /Items/{itemId}/Download`
- Implemented in `Jellyfin.Api/Controllers/LibraryController.cs`.
- Requires the `Download` authorization policy.
- The `Download` policy maps to the user permission `EnableContentDownloading`.
- Download support is also reflected on item DTOs through the optional `CanDownload` field.

Important behavior:

- The endpoint returns the original file from the server filesystem.
- The endpoint enables HTTP range processing for local physical files.
- It logs download activity for the authenticated user.
- It does not accept quality, size, codec, container, resolution, or storage-budget options.
- For video items, downloads are limited to file-backed video. DVD and Blu-ray folder media are not downloadable through this path.

Practical implication for Swiftfin:

- Original-file offline downloads are possible where the user has permission and the item supports download.
- This is risky as the only default path for iPad/iPhone storage because source files can be very large, including 4K HDR remuxes.

### Library Metadata And Browsing

Jellyfin exposes enough metadata APIs for a client to cache an offline subset of the library:

- `GET /UserViews`
- `GET /Items`
- `GET /Items/{itemId}`
- `GET /UserItems/Resume`
- `GET /UserItems/{itemId}/UserData`

Useful query and DTO capabilities include:

- `parentId` and `recursive` for browsing.
- `mediaTypes`, `includeItemTypes`, `excludeItemTypes`, and `filters` for narrowing the local catalog.
- `fields` for requesting extra metadata such as `MediaSources`, `MediaStreams`, `Overview`, `Genres`, `ProviderIds`, `ParentId`, `Path`, `CanDownload`, and `Etag`.
- `enableUserData` for including user-specific state.
- `minDateLastSaved` and `minDateLastSavedForUser` for incremental refresh-style queries.
- Image tags on item DTOs for detecting and caching artwork updates.

Practical implication for Swiftfin:

- A client-side offline catalog is feasible.
- The server does not provide an offline catalog manifest, so Swiftfin would need to choose and persist the local data model, cache invalidation strategy, and saved-item membership itself.

### Playback Negotiation

Jellyfin exposes playback negotiation through:

- `GET /Items/{itemId}/PlaybackInfo`
- `POST /Items/{itemId}/PlaybackInfo`

The POST API accepts a device-aware playback request with fields such as:

- `MaxStreamingBitrate`
- `StartTimeTicks`
- `AudioStreamIndex`
- `SubtitleStreamIndex`
- `MaxAudioChannels`
- `MediaSourceId`
- `DeviceProfile`
- `EnableDirectPlay`
- `EnableDirectStream`
- `EnableTranscoding`
- `AllowVideoStreamCopy`
- `AllowAudioStreamCopy`

The response includes:

- `PlaySessionId`
- `MediaSources`
- Playback error information where applicable

Each media source may include stream metadata, bitrate, runtime, supported direct play/direct stream/transcoding flags, transcoding URL details, and stream indexes.

Practical implication for Swiftfin:

- Swiftfin can ask Jellyfin what the server would stream for a particular device profile and bitrate.
- This can inform offline quality choices.
- The API is still playback-oriented, not an offline job contract. It does not reserve, generate, or track a durable offline copy.

### Streaming And Transcoding

Jellyfin exposes online playback streams through endpoints including:

- `GET /Videos/{itemId}/stream`
- `GET /Videos/{itemId}/stream.{container}`
- `GET /Audio/{itemId}/stream`
- `GET /Audio/{itemId}/stream.{container}`
- `GET /Audio/{itemId}/universal`
- `GET /Videos/{itemId}/master.m3u8`
- `GET /Audio/{itemId}/master.m3u8`
- HLS segment endpoints under `Videos/{itemId}/hls...` and `Audio/{itemId}/hls...`

These endpoints support many transcoding parameters, including container, codecs, bitrate, dimensions, max dimensions, stream indexes, subtitle method, and start position.

Practical implication for Swiftfin:

- A client could theoretically save a server-transcoded progressive response or an HLS rendition.
- That would be a client-managed use of online playback machinery, not an official offline download workflow.
- Care is needed around transcode lifecycle, session reporting, cancellation, partial files, HLS segment completeness, and whether saved streams remain playable without server context.

### Images, Subtitles, And Support Assets

Jellyfin exposes item artwork and subtitles separately:

- Item image APIs under `Items/{itemId}/Images/...`.
- User and person/genre/studio image APIs.
- Subtitle stream APIs under `Videos/{itemId}/{mediaSourceId}/Subtitles/...`.
- HLS subtitle playlist support under `Videos/{itemId}/{mediaSourceId}/Subtitles/{index}/subtitles.m3u8`.
- Fallback font listing and font file APIs.

Practical implication for Swiftfin:

- A useful offline experience needs to cache more than media files.
- Swiftfin would need a local asset bundle per saved item or media source, including item metadata, artwork, subtitle streams, selected audio/subtitle preferences, and enough parent hierarchy to browse offline.

### Playback Progress And User Data Sync

Jellyfin exposes session playback reporting:

- `POST /Sessions/Playing`
- `POST /Sessions/Playing/Progress`
- `POST /Sessions/Playing/Stopped`
- `POST /Sessions/Playing/Ping`

It also exposes direct user-data updates:

- `POST /UserItems/{itemId}/UserData`
- Legacy route: `POST /Users/{userId}/Items/{itemId}/UserData`

The user-data update DTO can carry:

- `PlaybackPositionTicks`
- `Played`
- `PlayedPercentage`
- `PlayCount`
- `LastPlayedDate`
- `IsFavorite`
- `Likes`

Practical implication for Swiftfin:

- Offline watch progress can be queued locally and synced once the server is reachable again.
- A future implementation needs conflict rules. For example, if the same item was watched on another device while the iPad was offline, Swiftfin must decide whether the newest timestamp wins, highest progress wins, played state wins, or the server state wins.

## Missing Backend Capabilities

The current Jellyfin backend does not appear to expose first-class APIs for:

- Creating an offline save request for an item, season, series, playlist, or collection.
- Listing what a device has saved offline.
- Persisting per-device offline membership on the server.
- Server-managed offline conversion jobs.
- Download queues, job status, retry state, or completed offline artifacts.
- A quality profile for offline downloads.
- A storage-budget-aware recommendation system.
- A server-generated offline catalog manifest.
- Conflict-aware offline playback sync.
- A durable optimized media file separate from the normal playback transcode cache.

There are user policy fields named `EnableSyncTranscoding` and `EnableMediaConversion`, but no current controller API was found that turns those into a complete offline sync/conversion workflow.

## Backend Project Signal Check

The current `jellyfin/jellyfin` issue and pull request backlog does not appear to contradict the missing-capability analysis above.

No open backend issue or pull request was found that clearly proposes or implements a first-class client offline mode, server-side offline job API, device offline manifest, storage-aware offline profile, server-managed offline queue, or durable optimized offline artifact separate from normal playback/transcode behavior.

Relevant or adjacent open backend issues:

- [`jellyfin/jellyfin#2518` EF Core Migration - Watch Status & Resume Points](https://github.com/jellyfin/jellyfin/issues/2518) tracks media-agnostic watch status and resume point storage. This supports the idea that playstate/user-data sync is a backend concern, but it is not an offline sync conflict-resolution API.
- [`jellyfin/jellyfin#8187` Can't open books if "Allow media downloads" is disabled](https://github.com/jellyfin/jellyfin/issues/8187) confirms that the `Allow media downloads`/download-permission path can affect non-video media access. This reinforces that Swiftfin must treat download permission as a real backend gate, not just a UI hint.
- [`jellyfin/jellyfin#11118` Continue Watching Doesn't Remember the Version Played](https://github.com/jellyfin/jellyfin/issues/11118) is not an offline issue, but it is relevant to future offline correctness for multi-version items. Swiftfin should persist enough media-source/version identity locally to avoid replaying a different version after reconnecting.
- [`jellyfin/jellyfin#16590` Improved Transcoding Cache Retention and Predictive Transcoding](https://github.com/jellyfin/jellyfin/issues/16590) discusses longer-lived transcode cache behavior and predictive transcoding. This is adjacent to optimized offline downloads, but it is session/cache-oriented and not a durable offline-download workflow.
- [`jellyfin/jellyfin#16608` HLS Segment Throttling and Cleanup Timers Never Fire for Fast Remux/DirectStream Transcoding Jobs](https://github.com/jellyfin/jellyfin/issues/16608) highlights lifecycle risk if a client tries to repurpose HLS/transcode endpoints as downloadable artifacts. It reinforces that transcoding endpoints are playback infrastructure, not offline job infrastructure.
- [`jellyfin/jellyfin#15518` Media library manual scan doesnt do anything](https://github.com/jellyfin/jellyfin/issues/15518) mentions a library "offline mode," but that request is about mounted media folders being absent from the server. It is not related to client offline playback and was ignored for this analysis.

Relevant or adjacent open backend pull requests:

- [`jellyfin/jellyfin#13857` Add support for downloading playlists](https://github.com/jellyfin/jellyfin/pull/13857) would extend backend download behavior to playlist ZIP generation. It may help batch original-file downloads, especially music playlists, but it does not provide an offline library manifest, device membership model, quality profile, or progress sync.
- [`jellyfin/jellyfin#15357` Additional http protocol support](https://github.com/jellyfin/jellyfin/pull/15357) proposes download support for HTTP sources, including `.strm` files. This broadens what the existing download path might handle, but it remains an original/remote-source download capability rather than offline mode.
- [`jellyfin/jellyfin#15633` Add ProgressState field for precise EPUB location tracking](https://github.com/jellyfin/jellyfin/pull/15633) would add richer user progress state for books. If merged, it would matter for offline reading sync, but it is not an offline playback/download API.
- [`jellyfin/jellyfin#15971` Add bitrate ladder support for automatic media source selection](https://github.com/jellyfin/jellyfin/pull/15971) and [`jellyfin/jellyfin#15062` Add media source version prioritization](https://github.com/jellyfin/jellyfin/pull/15062) could improve source/version selection when multiple encoded versions already exist. They may help Swiftfin pick a better source before download, but they do not create or manage offline copies.
- [`jellyfin/jellyfin#16161` Playbackinfo - Return API URLs for local external subtitle files on remote media sources](https://github.com/jellyfin/jellyfin/pull/16161), [`jellyfin/jellyfin#16583` Return text subtitles early while extraction continues in background](https://github.com/jellyfin/jellyfin/pull/16583), and [`jellyfin/jellyfin#16839` ImageController: drop Vary: Accept and Content-Disposition: attachment for cacheable image responses](https://github.com/jellyfin/jellyfin/pull/16839) are useful for support assets and cache behavior. They improve online retrieval/caching characteristics, but not offline asset bundling.
- [`jellyfin/jellyfin#16499` add transcode bitrate limit](https://github.com/jellyfin/jellyfin/pull/16499) affects playback transcode bitrate decisions. It may influence future offline-quality heuristics, but it is still playback negotiation/transcoding policy, not a download profile API.

Repository roadmap signal:

- No `ROADMAP.md`, roadmap section, or offline planning document was found in the backend repository.
- The backend README points new ideas to the Jellyfin feature request hub rather than an in-repo roadmap.
- The repository stale workflow exempts issues labeled `roadmap` and `future`, but the currently open roadmap-labeled backend issues found in the scan were broad backend/release tracking items, not offline playback planning.

Validation against this research:

- The main missing-capability list still stands.
- Backend activity may improve individual primitives that Swiftfin can consume, especially batch downloads, media-source selection, subtitle/image retrieval, and user progress data.
- None of the scanned backend signals turn offline playback into a server-owned feature. The complete offline experience remains client-owned unless Jellyfin later adds an explicit offline job/manifest/profile API.

## Swiftfin Upstream Workstreams

The Swiftfin project has several historical and current workstreams around local downloads. These branches are important because they show how contributors have tried to turn Jellyfin's backend primitives into a usable offline experience.

### Umbrella Demand: Local Downloads

[`jellyfin/Swiftfin#57`](https://github.com/jellyfin/Swiftfin/issues/57) is the long-running umbrella issue for offline video downloads, opened in 2021 and still open at the time of inspection. The issue thread confirms that users want more than a single "save file" button:

- Downloaded videos should be playable inside Swiftfin and visibly marked as downloaded.
- Offline mode should filter navigation to downloaded content, similar to Finamp's music offline mode.
- Users want Plex-like automatic downloads of latest TV episodes, raised in [`sbhal`'s comment](https://github.com/jellyfin/Swiftfin/issues/57#issuecomment-1241862495).
- Users want lower-resolution downloads through Jellyfin transcoding to save storage and time, raised in [`kazenshi`'s comment](https://github.com/jellyfin/Swiftfin/issues/57#issuecomment-1490728265).
- Users expect offline watch status to sync back after reconnecting, raised in [`IAmKontrast`'s comment](https://github.com/jellyfin/Swiftfin/issues/57#issuecomment-2942012975).

This maps closely to the ideal experience described in this research, but not to a first-class Jellyfin backend API. The issue thread is product demand; the backend still only provides lower-level pieces.

### Upstream Subissue Breakdown

The upstream project has split #57 into smaller subissues. This split is important because it describes a likely reviewable sequence for a feature that otherwise becomes too large to merge safely.

[`jellyfin/Swiftfin#1784`](https://github.com/jellyfin/Swiftfin/issues/1784) covers the first foundational slice: `DownloadManager`, `DownloadTask`, queueing, download persistence, complete item metadata, parent metadata and images, local file hierarchy, stored images, and enough ItemView button behavior to test queueing. Its acceptance criteria explicitly require completed metadata to support offline views and filtering.

[`jellyfin/Swiftfin#1785`](https://github.com/jellyfin/Swiftfin/issues/1785) covers download options. It separates direct downloads from transcoded downloads, introduces `DownloadOptions`, expects bitrate, `DeviceProfile`, and selected `MediaSource` to be stored with metadata, and requires transcoded downloads to be saved in a format usable by VLCKit. This subissue maps directly to the major backend/API gap in this research: Jellyfin exposes playback/transcode APIs, but not a durable offline transcode job API.

[`jellyfin/Swiftfin#1787`](https://github.com/jellyfin/Swiftfin/issues/1787) covers the ItemView download UI. It asks for an experimental download button/menu with bitrate selection, progress display, and state-aware actions for not downloaded, downloading, paused, failed, and completed items. It depends on #1785 because the UI must pass selected download options into the manager.

[`jellyfin/Swiftfin#1788`](https://github.com/jellyfin/Swiftfin/issues/1788) covers advanced management and edge cases: background downloads, app restart recovery, device reboot recovery, ordered queueing, eventual priority/concurrency controls, low battery/network/storage handling, retry thresholds, logging, missing-file recovery, server-deleted-file cleanup, corrupt-file handling, and public queue controls like pause all, resume all, and recovery.

[`jellyfin/Swiftfin#1789`](https://github.com/jellyfin/Swiftfin/issues/1789) covers downloads browsing and playback. It asks Swiftfin to reuse `PagingLibraryView` and `ItemView` for locally stored content, source data from CoreStore instead of server APIs, use local artwork, disable server-only actions, route users to downloads when offline if saved content exists, and support offline playback through local media paths.

The resulting upstream track decomposition is:

1. Download and metadata foundation (#1784).
2. Direct vs transcoded download options (#1785).
3. ItemView download controls (#1787).
4. Queue resilience, recovery, storage, and background edge cases (#1788).
5. Offline browsing and playback using local data (#1789).

This decomposition reinforces that #2012 should not be interpreted as the full offline playback feature. It mostly overlaps #1784, partially touches #1787 and #1788, stubs #1785, and does not yet complete #1789.

### Current Download Manager Draft

[`jellyfin/Swiftfin#2012`](https://github.com/jellyfin/Swiftfin/pull/2012) is the current open draft for a download manager. It is tied to [`jellyfin/Swiftfin#1784`](https://github.com/jellyfin/Swiftfin/issues/1784), which breaks the local-download feature into a focused `DownloadManager` and metadata-storage task.

Observed branch behavior:

- Adds a `DownloadManager` service using a background `URLSessionDownloadTask`.
- Queues one media download at a time, with pause, resume, retry, delete, progress, and resume-data persistence.
- Persists queue state in `SwiftfinStore` under per-user download keys.
- Creates `DownloadTask` records containing the `BaseItemDto`, download state, parent IDs, byte counts, resume data, timestamps, and completed media/image paths.
- Downloads original media through `Paths.getDownload(itemID:)`, which corresponds to Jellyfin's `GET /Items/{itemId}/Download`.
- Downloads image sidecars and external subtitles after media completion.
- Models series, season, and box-set entries as container tasks, with child media tasks underneath.
- Adds an experimental ItemView download button hidden behind `Experimental -> Enable Downloads`.
- Adds an offline downloads library view model that can page, filter, sort, and display completed or active `DownloadTask` records.
- Performs a simple local disk-space check based on source media size when available.

Important limits in the draft:

- Downloaded-file playback is explicitly not implemented yet. The experimental setting text says playback of downloaded files is not supported.
- Transcoded downloads are only stubbed. The branch builds a device profile, then throws an error that transcoded downloads are not implemented.
- Storage policy is reactive, not profile-based. The branch can reject a download when available space is too low, but it does not recommend a lower quality or manage a user-defined storage budget.
- Server-side offline membership is not used. Saved state remains local to Swiftfin.
- Playback progress sync and conflict handling are not implemented.
- Automatic latest-episode downloads are not implemented.

This branch strongly confirms the research finding that the realistic near-term path is client-managed offline downloads over existing Jellyfin APIs.

### Fork Branch Linked From #1784

The #1784 comments also link a non-upstream branch from `Braypolk/Swiftfin`: [`Feature-DownloadManager-and-Metadata-Storage-#1784`](https://github.com/Braypolk/Swiftfin/tree/Feature-DownloadManager-and-Metadata-Storage-%231784), inspected locally as `research/braypolk-1784` at `067e694ddbbe3e9827227e587dc72ea0749371f8`.

Observed branch shape:

- Roughly 71 changed files compared with its merge base, with about 6,951 insertions and 927 deletions.
- Adds `DownloadItemDto`, `DownloadState`, `BackgroundDownloadSession`, `DownloadFileSystemService`, `DownloadQueueService`, expanded `DownloadManager` and `DownloadTask`, and a `DownloadPagingLibraryViewModel`.
- Uses `Paths.getDownload(itemID:)` for direct original downloads.
- Adds background `URLSession` support, resume data handling, pause/resume, manual retry, automatic retry with exponential backoff, and human-readable download paths.
- Adds local browsing/playback-facing pieces such as `DownloadItemView`, `DownloadPagingLibraryView`, `DownloadQueueView`, `ItemViewModelProtocol`, and generic ItemView changes.

The upstream #1784 discussion around this branch is as important as the code. JPKribs noted that AI-assisted work is acceptable when the contributor can explain, review, own, and revise the code, but also emphasized that a 7,000-line combined branch is too large for the first manager/metadata slice. The maintainer guidance was to trim the work back to just downloading, storage, and metadata, with minimal UI only for testing, and to let #1752 absorb or supersede much of the shared ItemView architecture work.

Practical implication: this branch is useful evidence for design pressure, especially around service separation and background retry, but it is not an upstream PR and should not be treated as accepted direction. It reinforces the need to keep the first upstreamable slice smaller than a full offline UI/playback implementation.

### Library And Item Architecture Dependency

[`jellyfin/Swiftfin#1752`](https://github.com/jellyfin/Swiftfin/pull/1752) is not a downloads implementation, but it is a major dependency for maintainable offline browsing. The branch rewrites poster, library, home, item, and paging structure around shared types such as `PagingLibrary`, `PagingLibraryViewModel`, `LibraryElement`, `PosterButton`, `PosterHStack`, and a simplified `ItemViewModel`.

This matters for offline downloads because an offline catalog needs to present local items through the same browsing surfaces as normal server-backed items. The older attempts duplicated large amounts of ItemView and library UI. The #1752 direction suggests that future offline work should avoid a parallel offline-only UI stack where possible.

Related upstream discussion:

- In [`jellyfin/Swiftfin#2012`](https://github.com/jellyfin/Swiftfin/pull/2012#issuecomment-4437043190), the draft author notes that the branch is expected to remain draft until #1752 is done and that the paging portion is bare bones.
- [`jellyfin/Swiftfin#1810`](https://github.com/jellyfin/Swiftfin/issues/1810) proposed an `ItemViewable` protocol plus `DownloadItemDto`, but it was closed as not planned after LePips noted that #1752 and later work would change how item views are made in [`this comment`](https://github.com/jellyfin/Swiftfin/issues/1810#issuecomment-3525155162).

Practical implication: download-manager work can be reasoned about independently, but offline library and item UI should be designed after #1752 or on top of its abstractions.

### Prior Offline Playback Attempt

[`jellyfin/Swiftfin#1065`](https://github.com/jellyfin/Swiftfin/pull/1065) was a larger 2024 offline-download branch. It attempted a broader experience than #2012:

- Direct downloads for movies and episodes.
- Local metadata and image files.
- Offline coordinators, offline item views, and an offline home/downloads tab.
- Grouping episodes under series and seasons.
- Offline playback from local media URLs.
- Local resume, next-up, and adjacent-episode behavior for downloaded media.

The PR discussion identifies several missing pieces in [`this status comment`](https://github.com/jellyfin/Swiftfin/pull/1065#issuecomment-2133943093):

- Playback-progress syncing was not implemented.
- Batch downloads such as whole seasons were not implemented.
- Proper multi-user support was not implemented.
- Media-source selection was not implemented.
- Much of the UI was copied from existing ItemView code and would need deduplication or a better abstraction.

In a later [`jellyfin/Swiftfin#1065` comment](https://github.com/jellyfin/Swiftfin/pull/1065#issuecomment-3046729221), JPKribs broke the local-download effort into four tracks: downloading content, downloads UI, manage downloads, and download playback. The PR was then closed in favor of a more modular approach and sub-issues under #57 in [`this closing comment`](https://github.com/jellyfin/Swiftfin/pull/1065#issuecomment-3478024466).

Practical implication: #1065 validates that offline playback can be prototyped client-side, but it also demonstrates why upstream wants smaller PRs and why reused library/item architecture matters.

### Earlier Proof Of Concept

[`jellyfin/Swiftfin#362`](https://github.com/jellyfin/Swiftfin/pull/362) was a 2022 pre-alpha proof of concept. It used Alamofire to download original media, save item metadata and playback info JSON, save primary/backdrop images, and provide rough offline home, item, settings, and download-list views.

The branch is useful historically, but it is not an architecture to build on directly. In the closing discussion, LePips said they kept feeling the foundation needed to be redone: [`jellyfin/Swiftfin#362` comment](https://github.com/jellyfin/Swiftfin/pull/362#issuecomment-1072933535). A later Finamp-oriented comment on the same PR also suggested a relational parent/child model for downloads, which aligns with #2012's move toward explicit parent IDs and container/media tasks.

Practical implication: the project has already learned that local downloads need a durable data model for parent/child relationships, deletion behavior, and reusable UI surfaces. A file-only proof of concept is not enough.

### Workstream Fit Against Backend Research

| Capability | Backend API status | Swiftfin workstream evidence | Research conclusion |
| --- | --- | --- | --- |
| Original-file download | Existing `GET /Items/{itemId}/Download` | #362, #1065, #2012, and the Braypolk #1784 branch use direct original downloads | Feasible now, but dangerous as a default for large 4K/HDR files |
| Optimized downloads | Playback/transcode APIs exist, but no offline job contract | #1785 defines `DownloadOptions`; #2012 stubs transcoded downloads; #57 users ask for lower-resolution saves | Needs explicit client strategy or future backend support |
| Offline metadata catalog | Metadata APIs exist, no offline manifest | #1784 requires complete local metadata; #1065, #2012, and Braypolk branch cache item metadata locally | Feasible, client-owned |
| Parent/child browsing | Metadata APIs expose IDs and hierarchy, no saved-device manifest | #1784 requires parent metadata/images; #2012 container/media tasks; #1065 series/season grouping | Needs a local graph model |
| Images and subtitles | Separate image/subtitle APIs exist | #2012 downloads image sidecars and external subtitles | Must be part of saved item bundle |
| Offline playback | Local files can be played by the client | #1789 scopes playback; #1065 attempted playback; #2012 does not yet | Should come after stable download and player architecture |
| Playback progress sync | Session/user-data APIs exist, no offline conflict policy | #1065 stores local progress but does not sync robustly | Needs a queued sync model and conflict rules |
| Auto-download latest episodes | No backend subscription/offline queue API found | Requested in #57; not implemented in inspected PRs or subissues | Future client policy layer |
| Advanced queue recovery | Backend has no offline queue/recovery contract | #1788 scopes local queue intelligence and recovery | Client-owned unless Jellyfin adds a first-class API |
| Server-side offline queue/manifest | Not found | No inspected branch, PR, or subissue uses one | Not currently available |

## Swiftfin Implications

Using today's backend, the most realistic initial architecture is client-managed offline playback:

- Swiftfin chooses which items are saved offline.
- Swiftfin caches a compact metadata graph for those saved items.
- Swiftfin downloads the original media where appropriate, or uses carefully constrained playback/transcode endpoints if optimized copies are required.
- Swiftfin stores local playback state while offline.
- Swiftfin syncs user data and playback state back to Jellyfin when the server is reachable.

This puts the hard product and engineering decisions in Swiftfin:

- How to present download quality choices.
- Whether original-file download is allowed by default.
- Whether optimized downloads are captured from progressive transcodes, HLS, or deferred until Jellyfin has a first-class backend contract.
- How much parent/library metadata to cache for offline browsing.
- How to expire saved content.
- How to model automatic downloads for latest TV episodes if this remains a client-only policy.
- How to stage upstream work so a download manager, browsing UI, management UI, and playback support can be reviewed separately.
- How to handle storage pressure.
- How to handle server URL changes, VPN-only servers, token expiry, deleted items, replaced media files, and user permission changes.

## Follow-Up Questions For An Implementation Plan

- Should v1 support original-file downloads only, or should it include an optimized-download path?
- If optimized downloads are included, should Swiftfin prefer progressive MP4, HLS, or another container strategy?
- What should the default quality profile be for iPhone and iPad?
- Should users be able to set a global offline storage budget?
- Should saved items be per server, per user, and per device?
- Should v1 support movies and episodes only, or also music, photos, playlists, collections, and entire series?
- What metadata depth is required for offline browsing: only saved items, parent folders, full season/series hierarchy, or library home sections?
- What is the conflict policy when offline watch progress disagrees with newer server state?
- How should Swiftfin handle expired authentication while offline?
- Should automatic latest-episode downloads be a first-class v1 scope, or a later policy layer once manual downloads are stable?
- Should Swiftfin build offline browsing on the #1752 library/item abstractions before attempting an upstream UI PR?
- Can the download manager be upstreamed independently of offline playback, as #1784 suggests?
- Should the server ever be told which items a device has saved, or should saved membership remain local-only until Jellyfin defines a first-class contract?
