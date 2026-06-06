# Swiftfin PR 1882 Index And Track Fixes Research

## Executive Summary

[`jellyfin/Swiftfin#1882`](https://github.com/jellyfin/Swiftfin/pull/1882), titled "Index/Track Fixes", is a dense playback correctness PR focused on audio and subtitle track selection. It attempts to resolve a long-running mismatch between Jellyfin's server-side stream indexes and the indexes exposed by VLC/VLCKit after the actual media file and sidecar subtitle files load.

The core direction looks sound: keep Jellyfin stream indexes and local player indexes separate, introduce an `indexMap` between them, and route track changes through `MediaPlayerManager` so Swiftfin can either switch locally or request a new server stream when transcoding is needed. This is a stronger model than rewriting stream indexes up front because it preserves both truths: the index Jellyfin expects in playback requests and the index VLC expects for local selection.

The current implementation should be treated as partially solving the problem, not merge-clean complete. CI is green and the branch is mergeable, but review is still required and this investigation found central subtitle regressions: enabling subtitles from `None` can be rejected, disabling an encoded subtitle may not rebuild the stream, and rebuild decisions currently consult an empty `DeviceProfile`, so local-vs-server capability decisions are unreliable.

## Summary

This document captures a research pass on Swiftfin PR #1882 and the track-selection problem it is trying to solve. It is fork-only agent research under `.agents/`, following the accepted `ai/main` workflow: this is not upstream-facing project documentation unless a human rewrites and promotes it later.

Research basis:

- Provenance date: 2026-06-06, local environment timezone `Europe/Stockholm`.
- Local fork branch when researched: `docs/pr-1902-tvos-media-player-research` at `5290f41af3b7aebb9faa007bf1d32c91ecb27e35`.
- Local upstream ref after fetch: `upstream/main` at `43a33d9255e3766c914b3db0a3f5744a8e848977`.
- Pull request inspected:
  - [`jellyfin/Swiftfin#1882` Index/Track Fixes](https://github.com/jellyfin/Swiftfin/pull/1882)
  - Base branch: `jellyfin/Swiftfin:main`
  - Head branch: `JPKribs/Swiftfin:transcodeFix`
  - Local research ref: `upstream/pr-1882`
  - Merge base with current `upstream/main`: `5f5ca24bbeda3013e91f4f6fa695a94b05da242b`
  - Current PR head: `65579decd1d52bf1eceb75b4e2542b6f57f486f4`
- GitHub API metadata query:
  - PR state: open
  - Draft: false
  - Author: `JPKribs`
  - Commits: 77
  - Changed files: 11
  - Additions: 429
  - Deletions: 124
  - Mergeable: `MERGEABLE`
  - Merge state: `BLOCKED`
  - Review decision: `REVIEW_REQUIRED`
  - Updated at: 2026-05-21T04:03:10Z
- Status checks observed for current head `65579decd1d52bf1eceb75b4e2542b6f57f486f4`:
  - `Build (Swiftfin tvOS)`: pass.
  - `Build (Swiftfin)`: pass.
  - `Validate PR`: pass.
  - `CodeFactor`: pass.
- Local inspection method:
  - Fetched `upstream/main` and PR ref `upstream/pr-1882`.
  - Created a detached temporary worktree at `/private/tmp/Swiftfin-pr1882` for exact line inspection.
  - Reviewed the merge-base diff, changed files, PR body, comments, review records, and checks.
  - Did not run a local Xcode build or media playback test.

## Problem Statement

Swiftfin has been mixing two different track-index models:

- Jellyfin exposes media streams as a single global server list. The PR author describes this order as external audio, external subtitles, video, audio, subtitles.
- VLC/VLCKit selects tracks from the actual loaded media. The PR author describes this order as file track order, then external audio, then external subtitles.

The mismatch is easy to hide for simple files, but it breaks down when playback has any of these traits:

- External subtitles or audio tracks.
- Library settings that hide text subtitles, image subtitles, or all internal subtitles from Jellyfin's `MediaSource`.
- Tracks that still exist in the physical media file even though Jellyfin does not expose them to Swiftfin.
- Transcoding, where embedded subtitles can become external sidecar tracks or be dropped.
- Audio tracks where the default track can direct play, but a later user-selected track requires transcoding.
- External image subtitles such as `.sup` or PGS that VLC cannot use as a sidecar and Jellyfin must encode into the video.

The user-visible failures are wrong track selections, missing subtitle selections, audio switching that appears to "not transcode", and subtitle indexes becoming incorrect after a transcode.

## Options Evaluated

### Keep Rewriting Track Indexes Up Front

This was the old direction, represented by the earlier `adjustedTrackIndexes` approach and related work such as PR #1445. It adjusted streams into a player-like order before playback started.

Strength:

- Simple model for the UI because streams appear to have one index.

Weakness:

- It destroys the distinction between Jellyfin's server index and the player index.
- It guesses before VLC reports sidecar track positions.
- It cannot reliably account for tracks hidden by Jellyfin library settings but still present in the file.
- It becomes fragile under transcode behavior where subtitle delivery methods can change.

### Switch Every Track Locally

This is the simplest runtime behavior: keep the currently loaded media and tell the player to switch to another local audio or subtitle track.

Strength:

- Smooth for tracks that the current media actually contains and the local player can handle.
- Preserves playback without a server round trip.

Weakness:

- Fails when the newly selected audio track requires transcoding.
- Fails for external image subtitles that must be encoded into the video.
- Does not work for AVPlayer-style HLS cases where the current stream only exposes one audio rendition to the local player.

### Rebuild The Server Stream For Every Track Change

This asks Jellyfin for a new playback stream whenever the user changes audio or subtitles.

Strength:

- Makes Jellyfin choose the correct stream/transcode for unsupported audio.
- Can support AVPlayer track switching by re-requesting HLS with the selected track.
- Avoids relying on local file track availability.

Weakness:

- Heavier and more disruptive than a local switch.
- Risks breaking downloaded/offline playback if not guarded.
- Unnecessary for direct-play-compatible audio and text subtitles that VLC can switch locally.

### Hybrid Index Map With Conditional Rebuilds

This is the PR's chosen direction.

Strength:

- Maintains both server and local indexes.
- Allows local switches when safe.
- Allows server rebuilds when the selected track needs Jellyfin involvement.
- Handles sidecar subtitle index finalization after VLC exposes real track info.

Weakness:

- More stateful and easier to get edge cases wrong.
- Requires accurate capability checks.
- Needs explicit handling for sentinel indexes such as subtitle `None`.
- Needs tests because most of the important behavior is deterministic but branchy.

## How PR #1882 Solves The Problem

The PR replaces the older adjusted-index approach with an index map:

- `Shared/Extensions/JellyfinAPI/MediaStream.swift`
  - Adds `sidecarSubtitles`.
  - Adds `buildIndexMap(for:selectedAudioStreamIndex:)`.
  - Adds `resolveIndexMap(into:playbackChildren:subtitleTracks:isTranscoding:)`.
- `Shared/Objects/MediaPlayerManager/MediaPlayerItem/MediaPlayerItem.swift`
  - Stores `indexMap` on `MediaPlayerItem`.
  - Keeps original `audioStreams`, `subtitleStreams`, and `videoStreams` filtered for UI display.
  - Adds `isRebuildRequired(type:from:to:)`.
  - Adds `switchTrack(type:index:)`.
  - Updates the map after VLC reports subtitle tracks via `getSubtitleIndexes`.
- `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift`
  - Adds `setTrack(type:from:to:)`.
  - Adds `updateMediaPlayerItem(...)` to stop the current proxy, request a new playback item, and preserve playback position.
- `Shared/Objects/MediaPlayerManager/MediaPlayerProxy/MediaPlayerProxy+VLC.swift`
  - Uses `indexMap` when configuring initial audio and subtitle tracks.
  - Passes VLC-reported subtitle tracks back to the item so external subtitle mapping can be finalized.
- `Shared/Objects/VideoPlayerType/VideoPlayerType+Swiftfin.swift`
  - Removes image subtitle formats from external delivery and moves them to encode delivery.
- `Shared/Extensions/JellyfinAPI/DeviceProfile.swift`
  - Adds helper capability checks used by the rebuild decision.

The intended runtime flow is:

1. Build playback info from Jellyfin with the selected server indexes.
2. Build an initial `indexMap` from Jellyfin media stream metadata.
3. Start playback with VLC using local player indexes from `indexMap`.
4. When VLC reports actual subtitle tracks, revise sidecar subtitle entries in `indexMap`.
5. On track change, decide whether to switch locally or rebuild the stream.
6. If rebuilding, preserve playback position by setting `playbackPositionTicks` before requesting the new item.

This partially solves both halves of the problem:

- It keeps Jellyfin stream indexes available for playback info requests.
- It keeps player-local indexes available for VLC local selection.

It also moves track selection toward a manager-owned decision, which is a better fit for future AVPlayer parity because AVPlayer cannot depend on VLC-style local track switching.

## Current Readiness Signals

Signals suggesting the PR is mature enough for serious final review:

- The PR is open and not draft.
- GitHub reports it as mergeable.
- Current head checks pass for iOS build, tvOS build, PR validation, and CodeFactor.
- The diff is relatively contained: 11 files, 429 additions, 124 deletions.
- The PR author provided substantial scenario testing notes, test attachments, and videos.
- The PR author later tested the same direction with AVPlayer in a side branch and reported it enabling subtitle and track selection there too.

Signals suggesting the PR is not merge-clean yet:

- GitHub review decision is still `REVIEW_REQUIRED`.
- Merge state is `BLOCKED`.
- The author explicitly said they felt unsure about whether the manager/proxy layering was integrated correctly.
- The author called out downloaded playback as a likely breakage point for the HLS rebuild route.
- External audio remains explicitly unsupported and hidden from `audioStreams`.
- No local unit tests were found for `buildIndexMap`, `resolveIndexMap`, or `isRebuildRequired`.
- This investigation found subtitle edge-case concerns in code paths central to the PR's claims. These are recorded as questions for future validation, not as implementation instructions.

## Evidence-Backed Concerns

### Concern: None To Subtitle Enable Flow

`MediaStream.none` uses `index: -1`, and both iOS and tvOS subtitle menus prepend it to the subtitle list. When the user changes from `None` to a real subtitle, `MediaPlayerItem.selectedSubtitleStreamIndex` calls `manager?.setTrack(type: .subtitle, from: oldValue, to: selectedSubtitleStreamIndex)`.

`MediaPlayerManager._setTrack` then validates the old subtitle index with:

```swift
guard playbackItem.subtitleStreams.contains(where: { $0.index == oldIndex }) else {
    logger.warning("MediaPlayerManager.SetTrack call with an invalid subtitle track index")
    return
}
```

Inference: because `-1` is not in `subtitleStreams`, this path appears to return before local switching or rebuilding. This should be verified against runtime behavior before being treated as a confirmed defect.

Evidence trail at PR head:

- `Shared/Extensions/JellyfinAPI/MediaStream.swift`
- `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift`
- `Swiftfin/Views/VideoPlayerContainerView/PlaybackControls/Components/NavigationBar/ActionButtons/SubtitleActionButton.swift`
- `Swiftfin tvOS/Views/VideoPlayerContainerState/PlaybackControls/Components/ActionButtons/SubtitleActionButton.swift`

Open question: how does the current PR behave when playback starts with subtitles off and the user selects an embedded or sidecar subtitle?

### Concern: Encoded Subtitle To None Flow

`MediaPlayerItem.isRebuildRequired` returns false immediately when the new index is `nil` or `-1`:

```swift
guard let newIndex, newIndex != -1 else { return false }
```

That early return runs before the subtitle branch checks whether the old subtitle had `deliveryMethod == .encode`.

Inference: if an image/external subtitle was burned into the video, selecting `None` may require a new server stream without that burned subtitle. The current code appears to classify disable as local-only first, but this should be validated with an encoded subtitle scenario before being treated as proven runtime behavior.

Evidence trail at PR head:

- `Shared/Objects/MediaPlayerManager/MediaPlayerItem/MediaPlayerItem.swift`

Open question: when the selected subtitle has `deliveryMethod == .encode`, does changing to `None` actually request playback info again, or does it only issue a local subtitle disable?

### Concern: Rebuild Decisions And DeviceProfile Provenance

`MediaPlayerItem` defines:

```swift
let deviceProfile: DeviceProfile = .init()
```

The real profile is built in `MediaPlayerItem.build` and sent to Jellyfin in `playbackInfo.deviceProfile`, but it is not passed into the returned `MediaPlayerItem`. As a result, `isRebuildRequired` consults an empty profile when checking `canPlay(...)`.

Inference:

- Audio capability checks appear likely to return false unless the empty profile has been populated elsewhere, which this investigation did not find.
- External text subtitles that the PR describes as local-switchable may be classified as needing a rebuild.
- Embedded subtitles that the PR describes as local-switchable may be classified as needing a rebuild.
- The PR's intended hybrid behavior may differ from the author's description unless there is another profile source not found in this pass.

Evidence trail at PR head:

- `Shared/Objects/MediaPlayerManager/MediaPlayerItem/MediaPlayerItem.swift`
- `Shared/Objects/MediaPlayerManager/MediaPlayerItem/MediaPlayerItem+Build.swift`
- `Shared/Extensions/JellyfinAPI/DeviceProfile.swift`

Open question: is `MediaPlayerItem.deviceProfile` intentionally empty, or is the playback-info `DeviceProfile` meant to be retained for later local-vs-rebuild decisions?

## Problem Coverage Assessment

Likely improved by the PR:

- Initial direct-play mapping with external tracks ahead of internal tracks.
- Transcode mapping for the selected audio track.
- Late correction of sidecar subtitle local indexes after VLC reports real subtitle tracks.
- Audio track changes that need a transcode, as long as compatibility mode allows one.
- External image subtitle behavior in non-direct-play modes.
- Avoiding unusable external image subtitle options in forced direct-play mode.

Still incomplete, risky, or unverified:

- Subtitle `None` to subtitle enable flow.
- Encoded subtitle to `None` disable flow.
- Local-vs-rebuild decision accuracy given the observed empty `DeviceProfile` on `MediaPlayerItem`.
- Downloaded/offline playback behavior when a track change wants to rebuild HLS.
- External audio playback, explicitly left as TODO.
- Tests for hidden track types and transcode delivery-method transitions.

## Candidate Hypotheses / Future-Agent Validation

These are not implementation recommendations. They are bounded hypotheses and scenarios where future agents can strengthen or falsify the paper trail.

### Hypothesis: Direct Play Index Mapping Handles External Tracks Before Internal Tracks

- Evidence: `buildIndexMap(for: .directPlay, ...)` subtracts the count of external streams from internal Jellyfin indexes, matching the PR author's description that Jellyfin lists external tracks before file tracks while VLC indexes file tracks first.
- Inference: direct-play files with external subtitles before internal streams may now select the intended VLC-local track.
- Validation: test a direct-play file with external subtitles and internal subtitles, then compare the selected Jellyfin stream index against VLC's selected local track.
- Confidence: medium.
- Do not treat as: an endorsed fix or maintainer decision.

### Hypothesis: Sidecar Subtitle Mapping Is Only Final After VLC Reports Tracks

- Evidence: `MediaPlayerItem.getSubtitleIndexes` calls `resolveIndexMap` after VLC's `.playing` state reports `info.subtitleTracks`; the PR body describes a first pass from Jellyfin metadata and a second pass after sidecar information loads.
- Inference: early playback selection and post-load subtitle selection may differ until VLC has reported actual subtitle track indexes.
- Validation: test startup with default sidecar subtitles and inspect whether the selected subtitle remains correct before and after VLC reports tracks.
- Confidence: medium.
- Do not treat as: an endorsed fix or maintainer decision.

### Hypothesis: Subtitle None Transitions Need Runtime Verification

- Evidence: `MediaStream.none` uses `index: -1`; subtitle menus prepend `.none`; `_setTrack` validates the old subtitle index against `subtitleStreams`; `isRebuildRequired` returns local-only for new `nil` or `-1`.
- Inference: enabling subtitles from `None` and disabling encoded subtitles to `None` may not follow the intended local/rebuild path.
- Validation: test `None` to embedded subtitle, `None` to external text subtitle, and encoded/image subtitle to `None` while observing playback-info requests and VLC selected track.
- Confidence: high for code-path concern, medium for runtime behavior until tested.
- Do not treat as: an endorsed fix or maintainer decision.

### Hypothesis: Local-Vs-Rebuild Decisions May Use A Different Capability Source Than Playback Info

- Evidence: `MediaPlayerItem` stores `let deviceProfile: DeviceProfile = .init()`, while `MediaPlayerItem.build` creates a populated `DeviceProfile` and assigns it only to `playbackInfo.deviceProfile`.
- Inference: `isRebuildRequired` may classify tracks differently from the profile used to request playback info.
- Validation: inspect runtime `MediaPlayerItem.deviceProfile` state and test direct-play-compatible audio/subtitle switches that should remain local according to the PR description.
- Confidence: high for source discrepancy, medium for behavior until runtime state is inspected.
- Do not treat as: an endorsed fix or maintainer decision.

### Hypothesis: Rebuild-Based Track Changes Are An Online-Playback Assumption

- Evidence: the PR author explicitly noted in a comment that calling a new HLS stream will break downloaded playback and they were unsure how to approach that.
- Inference: downloaded/offline playback may need separate behavior or may remain outside this PR's solved scope.
- Validation: inspect downloaded playback code paths and test track changes without network/server playback-info access.
- Confidence: medium.
- Do not treat as: an endorsed fix or maintainer decision.

### Hypothesis: The Nuke Package Resolution Change Is Unrelated To The Track Work

- Evidence: `Package.resolved` changes Nuke from `13.0.2` to `13.0.4`, while the PR topic and code changes are playback track mapping.
- Inference: the dependency bump may be incidental from package resolution rather than part of the playback fix.
- Validation: check PR comments/commits for intentional dependency updates or compare whether current upstream already carries the same resolution.
- Confidence: low.
- Do not treat as: an endorsed fix or maintainer decision.

## Open Questions

- Should `MediaPlayerManager` validate the old track index at all, or only validate the requested new track and let `isRebuildRequired` inspect old state opportunistically?
- Should subtitle `None` be represented as `nil` consistently instead of `-1`, or is the sentinel needed because VLC expects `-1`?
- Should `DeviceProfile.canPlay` consider custom playback profiles exactly as the playback-info request does, including bitrate changes?
- Should the manager own all stream rebuild decisions, or should proxies expose a capability object so VLC, AVPlayer, and downloaded playback can differ?
- Does the PR need to solve external audio now, or is hiding it acceptable as a separate known limitation?
- How should this interact with PR #1902 and the tvOS media-player work, which also includes a stream and track selection risk cluster?

## Source Links

- Pull request: [`jellyfin/Swiftfin#1882`](https://github.com/jellyfin/Swiftfin/pull/1882)
- Current PR head commit: [`65579decd1d52bf1eceb75b4e2542b6f57f486f4`](https://github.com/jellyfin/Swiftfin/pull/1882/commits/65579decd1d52bf1eceb75b4e2542b6f57f486f4)
- Related prior index work: [`jellyfin/Swiftfin#1445`](https://github.com/jellyfin/Swiftfin/pull/1445)
- Related AVPlayer track-switching PR mentioned by author: [`jellyfin/Swiftfin#1562`](https://github.com/jellyfin/Swiftfin/pull/1562)
- SDK/transcode URL issue mentioned by author: [`jellyfin/Swiftfin#2030`](https://github.com/jellyfin/Swiftfin/issues/2030)
- Claimed resolved issues:
  - [`jellyfin/Swiftfin#676`](https://github.com/jellyfin/Swiftfin/issues/676)
  - [`jellyfin/Swiftfin#900`](https://github.com/jellyfin/Swiftfin/issues/900)
  - [`jellyfin/Swiftfin#926`](https://github.com/jellyfin/Swiftfin/issues/926)
  - [`jellyfin/Swiftfin#1531`](https://github.com/jellyfin/Swiftfin/issues/1531)
  - [`jellyfin/Swiftfin#1554`](https://github.com/jellyfin/Swiftfin/issues/1554)
  - [`jellyfin/Swiftfin#1728`](https://github.com/jellyfin/Swiftfin/issues/1728)
  - [`jellyfin/Swiftfin#1854`](https://github.com/jellyfin/Swiftfin/issues/1854)
  - [`jellyfin/Swiftfin#1889`](https://github.com/jellyfin/Swiftfin/issues/1889)
  - [`jellyfin/Swiftfin#1904`](https://github.com/jellyfin/Swiftfin/issues/1904)
