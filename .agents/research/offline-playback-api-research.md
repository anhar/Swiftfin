# Offline Playback API Research

## Summary

This document captures what the current Jellyfin backend APIs appear to provide for a future Swiftfin offline playback experience. It is research only, not an implementation plan.

The ideal user experience is broader than the backend currently models: a user should be able to browse saved library content while fully offline, play locally stored media, and sync watch progress back to the server once the client can reach it again. Jellyfin exposes enough primitives for a client-managed version of that workflow, but it does not currently expose a first-class offline viewing, offline sync, or optimized offline download API.

Research basis:

- Jellyfin backend source inspected in a sibling checkout at commit `2a95223c6718bf8892369322b8a30a45e430739f` from 2026-05-29.
- Official Jellyfin API documentation checked at `https://api.jellyfin.org/`.
- Swiftfin checkout used for this document: `origin/main` as the branch base.

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
- Should the server ever be told which items a device has saved, or should saved membership remain local-only until Jellyfin defines a first-class contract?
