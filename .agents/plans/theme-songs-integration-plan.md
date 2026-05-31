# Swiftfin Theme Songs Integration Plan

## Summary

Swiftfin should support Jellyfin theme music as native theme media, not by integrating directly with the Themerr plugin API.

Themerr's API is an elevated, admin-oriented control surface for plugin operations such as triggering updates, reading progress, replacing themes, and loading dashboard translations. The playback path for Swiftfin should instead use Jellyfin's built-in theme media model. Themerr writes theme audio into media folders, refreshes metadata, and Jellyfin then exposes those files as ordinary `ThemeSong` extras.

The user-facing feature should be named around theme songs or theme music, not around Themerr. Themerr is one server-side provider of those songs, but manually added `theme.mp3` files and `theme-music/` folders should work the same way.

## Server Behavior Validated

Jellyfin already provides the client-facing primitives Swiftfin needs:

- `GET /Items/{itemId}/ThemeSongs`
- `GET /Items/{itemId}/ThemeMedia`
- `GET /Audio/{itemId}/universal`

Theme files are discovered by Jellyfin's native naming rules:

- `theme.mp3` beside a movie or series.
- Files inside a `theme-music/` folder.

Those files are represented as `ExtraType.ThemeSong` items and are deliberately ignored as top-level library items. After Themerr writes a theme file and refreshes item metadata, clients can discover and play it through Jellyfin's normal item and audio streaming APIs.

## Track 1: Fast Swiftfin PR

Goal: ship useful theme song playback in Swiftfin without waiting for Jellyfin server API changes.

This track implements a Swiftfin-local, per-signed-in-user setting. It is intentionally scoped to the Swiftfin client and should not write Swiftfin-specific keys into Jellyfin's server-side preferences.

### Swiftfin changes

1. Add a theme song service that:

- Calls `GET /Items/{itemId}/ThemeSongs`.
- Sends the active user id.
- Uses `inheritFromParent=true` so episodes and seasons can inherit series-level theme songs.
- Uses random sort when supported so repeated visits do not always choose the same song.
- Treats missing, empty, unauthorized, or failed responses as "no theme song" and does not surface a UI error.
- Picks one returned theme song for the first implementation.

2. Build playback URLs through Jellyfin audio streaming:

- Use `GET /Audio/{themeSongItemId}/universal`.
- Prefer direct MP3 playback when possible.
- Allow Jellyfin to transcode when the source is not directly playable by AVPlayer.
- Disable redirection so authenticated Swiftfin networking behavior remains predictable.
- Use AVPlayer-compatible defaults: containers `mp3,aac,m4a,m4b,wav`, codecs `mp3,aac,alac,flac`, and MP3 as the transcode fallback.

3. Add a dedicated ambient audio player:

- Use `AVPlayer` or `AVQueuePlayer`.
- Fade in when playback starts and fade out before stopping.
- Loop the chosen theme song while the item detail screen remains active.
- Avoid Now Playing metadata, remote command handling, progress reporting, queue state, and watched-state behavior.
- Stop immediately when foreground video playback starts.

4. Hook playback into iOS and tvOS item detail views:

- Start after the item detail model has loaded.
- Restart when the visible item id changes.
- Stop on view disappearance.
- Stop when the app resigns active or enters background.
- Stop when regular media playback starts.
- Do nothing when no theme song is available.
- Keep existing special feature filtering unchanged so `ThemeSong` extras do not appear as normal special feature videos.

Primary Swiftfin touchpoints:

- `Shared/ViewModels/ItemViewModel/ItemViewModel.swift`
- `Swiftfin/Views/ItemView/ItemView.swift`
- `Swiftfin tvOS/Views/ItemView/ItemView.swift`
- `Shared/Objects/MediaPlayerManager/MediaPlayerItem/MediaPlayerItem+Build.swift`

5. Add the fast-track Swiftfin setting:

- Add `Defaults.Keys.Customization.Library.enableThemeSongs`.
- Store it in Swiftfin's current user defaults suite, making it per signed-in Swiftfin user on the device.
- Label it `Theme Songs` for consistency with Jellyfin Web.
- Default it to off.
- Place it under customization/library settings.
- When disabled, never request or play theme songs.
- When toggled off while a theme song is playing, stop playback immediately.

### Fast-track tests

- Theme song request includes item id, user id, `inheritFromParent=true`, and random sort.
- Empty, missing, unauthorized, or failed theme song responses produce no playback.
- Universal audio URL builder creates an authenticated Jellyfin audio URL for the returned theme song item id.
- Theme audio player stops when the item view disappears.
- Theme audio player stops when regular video playback starts.
- Disabling the Swiftfin setting prevents requests and stops active playback.

Manual validation:

- Run Jellyfin with a manually added `theme.mp3` and with Themerr-generated `theme.mp3`.
- Open a movie in Swiftfin on iOS and confirm theme music starts only when the setting is enabled.
- Open an episode or season and confirm inherited series theme music works.
- Start actual media playback and confirm theme music stops.
- Repeat on tvOS.

### Fast-track acceptance criteria

- Swiftfin does not call any `/Themerr/*` plugin endpoints.
- Theme music works for media created by Themerr and for manually added Jellyfin theme files.
- iOS and tvOS item detail pages can play theme music when enabled.
- Theme music never appears as a regular special feature video.
- Theme music stops reliably on navigation, app state changes, and full media playback.
- The fast-track setting is local to Swiftfin and does not create a server-side Swiftfin-specific preference.

## Track 2: Full Jellyfin Contract

Goal: replace client-local theme media preferences with an official Jellyfin backend contract and migrate existing Jellyfin Web users safely.

This track should be submitted separately from the Swiftfin fast-track PR because it touches Jellyfin server behavior and likely Jellyfin Web migration code.

### Jellyfin server changes

Add a first-class theme media playback preference with typed semantics. The contract should cover theme songs and theme videos, even if Swiftfin initially consumes only theme songs.

The contract must define:

- Scope: user-wide by default, not per-library or per-item.
- Default: unset for migration purposes, interpreted by clients as disabled unless a legacy client says otherwise.
- Values: explicit enabled, explicit disabled, and unset.
- API shape for reading and writing the preference.
- Backward compatibility behavior for clients that do not know about the setting.
- OpenAPI/SDK generation expectations so Swiftfin and Web can consume typed properties rather than ad hoc keys.

Do not model this as a Swiftfin-specific custom preference. If `DisplayPreferences.CustomPrefs` is used internally, expose a typed Jellyfin API contract above it.

### Jellyfin Web migration

Jellyfin Web currently stores theme media settings in browser localStorage, scoped by user id. The server cannot migrate those values by itself, so migration must happen in Jellyfin Web after a user signs in and the new backend contract is available.

Legacy keys to support:

- Current Web keys: `{userId}-enableThemeSongs` and `{userId}-enableThemeVideos`, with string values such as `true` or `false`.
- Older Web key for theme songs: `enableThemeSongs-{userId}`, with legacy values such as `1`, `0`, or empty string.

Migration rules:

- Read the official server setting first.
- If the server setting is unset and a legacy localStorage value exists, normalize it and write it to the official server setting.
- Normalize `true` and `1` to enabled; normalize `false` and `0` to disabled; treat missing or empty values as unset.
- Mark migration complete per server and user, for example `themeMediaSettingsMigration:{serverId}:{userId}:v1`, so each browser profile only attempts migration once.
- If the server already has an explicit value, the server value wins and Web must not overwrite it with legacy localStorage.
- Leave legacy keys in place for downgrade compatibility during the migration window; stop reading them once migration is complete.
- For older Jellyfin servers without the new contract, Web should keep using the legacy localStorage path until the server is upgraded.

Conflict behavior:

- If the same user has different legacy values across browsers, the first migrated browser wins.
- Later browsers respect the already explicit server value rather than overwriting it.
- Users can still change the setting normally after migration, and that change writes only to the official server contract.

### Swiftfin follow-up after the server contract

Once the Jellyfin contract is available in the Swift SDK:

- Read the official Jellyfin theme song setting before requesting theme songs.
- Write setting changes to the official Jellyfin setting.
- Migrate the fast-track local Swiftfin value only if the server setting is unset.
- Prefer the explicit server value over any local Swiftfin value.
- Keep the local value only as a compatibility fallback for older Jellyfin servers.

### Full-track tests

- Server API distinguishes unset from explicit disabled.
- Server API persists explicit enabled and disabled values per user.
- Generated client models expose typed theme media preference fields.
- Web migration preserves existing localStorage values when the server setting is unset.
- Web migration does not overwrite an explicit server value with stale localStorage.
- Swiftfin migrates its fast-track local setting only when the server setting is unset.
- Older servers continue using the Swiftfin local fallback without breaking playback.

## Shared Assumptions

- The initial Swiftfin playback implementation only needs one theme song at a time.
- Shuffle or multi-song rotation can be added later.
- Theme video playback is out of scope for the fast-track Swiftfin PR.
- AVPlayer is the right playback engine because Jellyfin can provide or transcode to Apple-friendly audio.
- Themerr remains server-side data population only; Swiftfin should never depend on Themerr being installed.
