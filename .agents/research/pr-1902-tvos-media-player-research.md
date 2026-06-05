# Swiftfin PR 1902 tvOS Media Player Research

## Executive Summary

[`jellyfin/Swiftfin#1902`](https://github.com/jellyfin/Swiftfin/pull/1902), titled "[tvOS] Media Player", is the active implementation PR for the tvOS media player work tracked by [`jellyfin/Swiftfin#818`](https://github.com/jellyfin/Swiftfin/issues/818). The PR is not a small polish-only change. It is a broad tvOS player UI and shared video-player consolidation branch that currently claims to resolve #818 and all 22 child issues attached to that parent tracker.

The current readiness signal is best described as late-stage work under maintainer review, not as either abandoned prototype or merge-clean final implementation. The PR is open, not draft, mergeable according to GitHub, and current head checks pass. It has also received positive real-device tester feedback in the PR conversation. At the same time, the current head still contains explicit WIP markers, placeholder playback-rate UI, broad remote-command handling, focus/scrubbing complexity, and unresolved scope ambiguity around Live TV.

The recent commits titled `wip`, including `6e14bf7` and current head `d82171f`, are mostly refactor, relocation, supplement cleanup, style, slider/progress polish, and review/pass work. They do not by themselves prove that the whole PR is unfinished; rather, they show that LePips appears to be reshaping and reviewing an already-functional branch after JPKribs handed off the implementation.

The most important project-management risk is issue-link accuracy. The PR body uses `Resolves:` links for #818 and all child issues, so merging it would auto-close the tracker and the children. JPKribs explicitly noted that if the team determines this is not the final player solution, those links should be removed before merge. That should be read as a real validation point, not just a joke: the PR needs to be accepted as the final tvOS player path before it should close the whole issue cluster.

## Summary

This document captures a research pass on the current state and problem space around Swiftfin PR #1902 and its relationship to tvOS media-player tracker #818. It is research only, not a merge recommendation or implementation plan.

Research basis:

- Provenance date: 2026-06-06, local environment timezone `Europe/Stockholm`.
- Local fork branch when researched: `ai/main` at `e1bd34743c9aa8eb3bb067b6176fae95cea83fae`.
- Local upstream baseline: `upstream/main` at `7087d4985141610b34a050814de6aee490140dcc`.
- Pull request inspected:
  - [`jellyfin/Swiftfin#1902` [tvOS] Media Player](https://github.com/jellyfin/Swiftfin/pull/1902)
  - Base branch: `jellyfin/Swiftfin:main`
  - Head branch: `JPKribs/Swiftfin:tvOSPlayer`
  - Local research ref: `upstream/pr/1902`
  - Merge base with `upstream/main`: `530ba12af8e0fac41e732101828e690e32a39f43`
  - Current PR head: `d82171f6091564b9ba5c21169c6fc4e7f49c70df`
- GitHub API metadata query:
  - PR state: open
  - Draft: false
  - Commits: 244
  - Changed files: 89
  - Additions: 3,059
  - Deletions: 2,321
  - Merge state: `clean`
  - Issue comments: 38
  - Pull request reviews: 1 review record, `COMMENTED`
  - Line-level review comments: 1
- Status checks observed for current head `d82171f6091564b9ba5c21169c6fc4e7f49c70df`:
  - `Validate PR` completed successfully on 2026-05-30.
  - `Build (Swiftfin)` completed successfully on 2026-05-30.
  - `Build (Swiftfin tvOS)` completed successfully on 2026-05-30.
- Tracker inspected:
  - [`jellyfin/Swiftfin#818` [tvOS] Swiftfin Media Player](https://github.com/jellyfin/Swiftfin/issues/818)
  - State: open
  - State reason: reopened
  - Milestone: `tvOS Resync`
  - Type: Feature
  - Labels: `developer`, `playback`, `tvOS`
  - Assignees: `LePips`, `JPKribs`
  - Sub-issues: 22 total, 0 completed
- External review artifact inspected:
  - [`Claude Opus Review of #1902 at commit 1a714fe`](https://gist.github.com/tagatac/69022acca0aecfa5aa771fff9d06e21d)
  - This was treated as an informal checklist only because it targets an older WIP commit and JPKribs asked that this kind of AI review not clutter the PR discussion.

## Relationship To Tracker #818

Issue #818 originally tracked incomplete tvOS overlay work after earlier video-player layer movement from UIKit to SwiftUI. On 2025-10-23, JPKribs reopened it as a parent issue for tvOS media-player issues that should be resolved by the next tvOS player work.

The tracker currently has 22 child issues:

- 20 bugs.
- 2 feature/enhancement items.
- 0 closed/completed child issues.

The child issue set is best understood as a release-readiness bundle for the tvOS media player rather than a single defect. The issues cluster into these themes:

- Audio/subtitle selection and stream-index correctness:
  - #577, #679, #787, #892, #900, #926, #1102, #1378, #1755.
  - The hard problem is mapping Jellyfin stream indexes, local player track indexes, direct play, direct stream, and transcode behavior into a consistent UI state.
- Subtitle display and subtitle-off behavior:
  - #729, #954, #1006, part of #1755.
  - Includes embedded subtitle display, external subtitle behavior, explicit off/none UX, and ASS/font rendering concerns.
- Remote, focus, seeking, and overlay behavior:
  - #697, #703, #906, #914, #1166, #1962.
  - These are tvOS-specific interaction issues around Siri Remote generations, the iOS Remote app, play/pause commands, scrubbing, and control discoverability.
- Playback/session lifecycle:
  - #770 and parts of #1005.
  - Includes Now Playing/state reporting, progress updates, stopping playback, and post-playback behavior.
- Live TV:
  - #503 and #658.
  - These are related to the media-player pipeline but remain the least certain fit. JPKribs said in #818 that the Live TV items were the only attached items they were not positive about.

## PR 1902 Scope

The PR body says it:

- Resolves parent issue #818.
- Resolves all 22 child issues attached to #818.
- Creates a tvOS version of the iOS player UI.
- Attempts to mirror iOS where possible while accounting for tvOS buttons, swipes, focus, and UIKit controller limitations.

The current diff confirms that the branch is not limited to visual polish. It moves and consolidates substantial video-player UI structure:

- Adds a shared `VideoPlayer` entry under `Shared/Views/VideoPlayer/VideoPlayer.swift`.
- Moves player container and supplement container code toward shared paths under `Shared/Views/VideoPlayer/VideoPlayerContainerView/`.
- Adds tvOS-specific player controls under `Swiftfin tvOS/Views/VideoPlayer/PlaybackControls/`.
- Adds tvOS-specific supplement tab view under `Swiftfin tvOS/Views/VideoPlayer/SupplementTabView.swift`.
- Adds and modifies tvOS slider/progress controls under `Swiftfin tvOS/Components/`.
- Replaces the older `Swiftfin tvOS/Views/VideoPlayerContainerState/...` player-control files.
- Updates shared supplement, toolbar, action-button, toast, button-style, and `VideoPlayerContainerState` code.

The active design direction is to keep the playback manager and most player surfaces shared, while preserving tvOS-specific control and focus handling where platform behavior requires it.

## Recent Work Signal

The last 25 commits before current head show an implementation branch moving through manual testing, merges from `main`, then a handoff to LePips for review and changes.

Notable late commits:

- `2026-05-19` - LePips commented that they were starting review and changes.
- `2026-05-21` - Commit `25573a6` was the source of the video linked in the PR body.
- `2026-05-23` - Commit `fd14fea`, titled `wip`.
- `2026-05-25` - Commit `1a714fe`, titled `wip`; this is the commit reviewed by the external Claude gist.
- `2026-05-26` - Commit `6e14bf7`, titled `wip`.
- `2026-05-30` - Commit `d82171f`, titled `wip`; this is current PR head.

The two WIP commits specifically raised in follow-up discussion are mostly final-pass work:

- `6e14bf7`
  - 422 total changed lines.
  - 298 additions, 124 deletions.
  - Modifies button styles, tinted material styling, media supplement display metadata, action-button structure, toolbar paths, tvOS video-player slider/progress behavior, project files, and package resolution.
  - Includes many rename/move-style changes.
- `d82171f`
  - 513 total changed lines.
  - 256 additions, 257 deletions.
  - Removes separate supplement empty/loading placeholder buttons, moves `SupplementPosterButton`, reworks `EpisodeMediaPlayerQueue`, and moves `SupplementTabView` into video-player view folders.

Interpretation: these commits do not add a large new feature surface. They look like cleanup and review iteration over an existing player implementation.

## Conversation Signal

The PR thread contains several useful readiness signals:

- On 2026-05-02, JPKribs said they were done making changes and had three known outstanding items with fixes, but wanted to loop in LePips.
- On 2026-05-03, JPKribs said Live TV would need to be another PR because they did not have Live TV set up and did not have time to test it.
- On 2026-05-06, a tester reported that the branch seemed solid on simulator and Apple TV 4K 3rd generation.
- On 2026-05-09, another tester reported successful playback on Apple TV 4K 1, 2, and simulated 3rd generation after checking the correct build.
- On 2026-05-13, a tester said the updated media player felt closer to native and more natural.
- On 2026-05-19, LePips said they were starting review and changes.
- On 2026-05-19, JPKribs replied that they would not touch it moving forward, cleaned up the main post, and linked the items they believed were resolved by the PR.
- In that same comment, JPKribs said the linked resolving items should be removed before final merge if the team determines this is not the final player solution.
- On 2026-05-25, JPKribs responded to the external Claude review by noting that the reviewed commit was titled WIP, that many issues were already known because it was WIP, and that such reviews add clutter to the development conversation.

Interpretation:

- The branch has meaningful hands-on testing signal.
- The branch is in owner/maintainer review, not raw exploratory development.
- Live TV is a known mismatch between PR close claims and author confidence.
- The issue-closing links remain a final-scope decision, not a purely decorative PR-body detail.

## Current Readiness Signals

Signals suggesting the PR is close enough for serious final review:

- It is open and no longer marked draft.
- GitHub reports the branch as clean/mergeable.
- Current head has successful `Validate PR`, `Build (Swiftfin)`, and `Build (Swiftfin tvOS)` checks.
- JPKribs reported being done with their implementation changes before LePips started review.
- Tester comments report good simulator and real-device behavior.
- The current diff is much smaller and more focused than broader WIP PRs such as #1752.

Signals suggesting the PR is not merge-clean yet:

- The current head commit is still titled `wip`.
- `PlaybackRateMediaPlayerSupplement.swift` still contains `TODO: POC of a "guest" supplement, finish` and renders `Color.orange.opacity(0.5)` for tvOS.
- `VideoPlayerContainerState.swift` still includes comments describing the state as "spaghetti" and asks to verify timer states.
- `Shared/Views/VideoPlayer/VideoPlayer.swift` has TODOs around audio/subtitle offset ownership and scrubbing behavior.
- `VideoPlayerContainerView.swift` contains several TODOs around overlay dismissal, aspect fill, static supplement sizing, center-tap behavior, no-supplements state, item changes during gestures, and bad playback states.
- tvOS playback progress still has TODOs for enabled/disabled state, scrubbing snapping behavior, and chapter title display.
- `MPRemoteCommandCenter.shared().togglePlayPauseCommand.removeTarget(nil)` is used in the tvOS player container. This may be intentional to avoid double-handling, but it is a broad process-wide mutation and should be explicitly validated.
- `PlaybackInfoLabeledContentStyle` uses `@FocusState` inside a `LabeledContentStyle`, which is at least a focus-lifecycle risk worth review.
- The focus and scrubbing model has two-way coordination between local focus state and shared `VideoPlayerContainerState.isProgressBarFocused`; it needs hardware validation.
- The PR body still claims Live TV child issues even though JPKribs said enabling Live TV will need another PR.

## Claude Review Assessment

The external Claude review is useful only as an informal checklist.

Reasons it should not be treated as authoritative:

- It reviewed commit `1a714fe`, not the current head `d82171f`.
- The reviewed commit was explicitly titled `wip`.
- JPKribs stated that many of the issues were already known and asked contributors to avoid adding this kind of AI review clutter to the PR conversation.
- Several critical findings from the review are stale at current head.

Examples of stale or resolved review findings at current head:

- The local `../StatefulMacros` package concern appears resolved. Current `project.pbxproj` uses the remote `https://github.com/LePips/StatefulMacro` package with a version requirement.
- `NativeVideoPlayer` again calls `manager.stop()` when the presentation is dismissed.
- `PRODUCT_BUNDLE_IDENTIFIER` for tvOS is supplied by `XcodeConfig/Shared.xcconfig`, which exists and sets `PRODUCT_BUNDLE_IDENTIFIER = org.jellyfin.swiftfin`.

Examples of review findings that still appear relevant:

- The orange playback-rate placeholder still exists.
- `@FocusState` inside `PlaybackInfoLabeledContentStyle` still exists.
- `removeTarget(nil)` for the toggle play/pause remote command still exists.
- Focus/scrubbing state remains complex and should be validated on hardware.
- The Live TV close-claim ambiguity remains.

Interpretation: use the review to seed a final manual checklist, but do not quote it into upstream discussion or treat it as a substitute for maintainer review.

## Meaning Of "Final Player Solution"

JPKribs' comment about removing linked items if the PR is not the final player solution should be treated as an actual merge-scope decision.

The practical reason is GitHub automation: `Resolves:` links in the PR body will close #818 and the child issues when the PR merges. Therefore, the team should only keep those links if #1902 is accepted as the player implementation that should retire the tracker.

The two laugh reactions on that comment probably reflect the awkward understatement of a large PR potentially not being "the final player solution." They should not be read as making the comment meaningless. The comment protects issue hygiene.

Possible final outcomes:

- If #1902 is accepted as the tvOS media player solution, keep the #818 and child issue links, except possibly Live TV if that work is deferred.
- If #1902 lands as partial groundwork, remove or narrow the closing links before merge.
- If #1902 is mined for parts or replaced by a different player approach, remove the closing links and keep #818 open.

## Risk Areas To Validate Before Merge

### Stream And Track Selection

The largest child-issue cluster concerns audio/subtitle behavior. Final testing should include:

- Multiple audio tracks with direct play.
- Multiple audio tracks with transcode/direct stream.
- Default audio track behavior.
- Manual audio switching.
- Embedded subtitles.
- External subtitles.
- Explicit subtitle `None` or off behavior.
- ASS subtitles and fallback fonts where possible.
- Episode-to-episode carryover and UI state accuracy.

### tvOS Remote And Focus Behavior

The tvOS-specific risk is not just whether controls render. It is whether they behave naturally across input devices:

- Siri Remote 1st generation touchpad behavior.
- Newer Siri Remote clickpad behavior.
- iOS Remote app behavior.
- Play/pause command behavior.
- Menu/back behavior when overlay is visible vs hidden.
- Scrubbing start, cancel, commit, and jump behavior.
- Focus restoration when closing supplements.

### Playback Lifecycle

The session lifecycle should be validated:

- Starting playback.
- Pausing/resuming.
- Dismissing the player from normal UI.
- Dismissing through non-standard tvOS routes.
- Natural video end.
- Next episode autoplay.
- Now Playing / remote state reporting.
- Audio stopping when the player view closes.

### Live TV

Live TV is the weakest close claim:

- #503 and #658 are linked as resolved by the PR body.
- JPKribs later said enabling Live TV would need another PR due to lack of test setup.

Before merge, either Live TV should be tested and the close claims kept, or the Live TV issue links should be removed from the PR body.

## Open Questions

- Does LePips intend to replace the orange playback-rate supplement placeholder before merge, or remove that guest supplement from the visible tvOS UI?
- Is the global `MPRemoteCommandCenter` target removal intentional and scoped enough for Swiftfin's other playback paths?
- Should Live TV issues #503 and #658 remain in the PR's `Resolves:` list?
- Which of #818's 22 child issues are truly fixed by current head versus expected to be closed because the old player path disappears?
- Are the positive tester reports enough coverage for older Siri Remote, iOS Remote app, and all supported Apple TV generations?
- Is the final player expected to remain VLC-backed by default, with AVPlayer/native work deferred, or should AVPlayer parity be part of #1902's acceptance bar?
- Should the PR body distinguish "verified fixed" from "made obsolete by replacement player UI" for child issues?

## Source Links

- Pull request: [`jellyfin/Swiftfin#1902`](https://github.com/jellyfin/Swiftfin/pull/1902)
- Current PR head commit: [`d82171f6091564b9ba5c21169c6fc4e7f49c70df`](https://github.com/jellyfin/Swiftfin/pull/1902/commits/d82171f6091564b9ba5c21169c6fc4e7f49c70df)
- Late WIP commit: [`6e14bf722466173691e363879dd4ebf3d76df332`](https://github.com/jellyfin/Swiftfin/pull/1902/commits/6e14bf722466173691e363879dd4ebf3d76df332)
- Parent tracker: [`jellyfin/Swiftfin#818`](https://github.com/jellyfin/Swiftfin/issues/818)
- tvOS update discussion: [`jellyfin/Swiftfin#1294`](https://github.com/jellyfin/Swiftfin/discussions/1294)
- External review artifact: [`Claude Opus Review of #1902 at 1a714fe`](https://gist.github.com/tagatac/69022acca0aecfa5aa771fff9d06e21d)
