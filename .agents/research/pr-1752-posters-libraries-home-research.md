# Swiftfin PR 1752 Research

## Executive Summary

[`jellyfin/Swiftfin#1752`](https://github.com/jellyfin/Swiftfin/pull/1752), titled "Posters, Libraries, Home", is an open draft pull request from `LePips:poster-library-home` into `jellyfin:main`. The work is not a narrow visual update. It is a broad iOS and tvOS refactor that appears to unify poster rendering, library browsing, home/search/program surfaces, item detail composition, navigation/tab behavior, and related customization settings.

The active work signal is mostly "large WIP integration branch". The PR is still marked draft, has no reviewers, no assignees, and no completed review record. The latest branch activity found during this pass was on 2026-05-07 UTC: a commit named "WIP before merging main" followed by "Merge main into poster-library-home". GitHub reported the pull request as open but dirty against `main`, with skipped GitHub Actions checks and a failing CodeFactor status.

The current blocker profile is therefore integration and stabilization, not final review. The branch has 444 changed files, 11,576 additions, and 16,366 deletions. It touches enough central shared components and platform-specific views that merge conflicts, build health, reviewability, and functional regression testing are likely the dominant remaining work.

## Summary

This document captures a lightweight research pass on what work is actively being done in Swiftfin PR #1752. It is research only, not a merge recommendation or implementation plan.

Research basis:

- Provenance date: 2026-06-06, local environment timezone `Europe/Stockholm`.
- Pull request inspected:
  - [`jellyfin/Swiftfin#1752` Posters, Libraries, Home](https://github.com/jellyfin/Swiftfin/pull/1752)
  - Base branch: `jellyfin/Swiftfin:main`
  - Head branch: `LePips/SwiftFin:poster-library-home`
  - Author: `LePips`
- GitHub CLI metadata query:
  - PR state: open
  - Draft: true
  - Commits: 58
  - Changed files: 444
  - Additions: 11,576
  - Deletions: 16,366
  - Merge state: `DIRTY`
  - Reviews: none
  - Review requests: none
  - Assignees: none
- Status checks observed:
  - `Build` GitHub Actions check: skipped
  - `Validate PR` GitHub Actions check: skipped
  - `CodeFactor`: failure

## Active Work Areas

### Poster System

The PR appears to substantially rework poster display and interaction.

Notable file patterns include:

- New or moved shared poster components:
  - `Shared/Components/PosterButton.swift`
  - `Shared/Components/PosterHStack.swift`
  - `Shared/Components/PosterHStackLibrarySection.swift`
  - `Shared/Components/PosterImage.swift`
- Poster indicators and overlays:
  - `Shared/Components/PosterIndicators/PosterIndicatorsOverlay.swift`
  - `Shared/Components/PosterIndicators/PosterProgressIndicator.swift`
  - `Shared/Components/PosterIndicators/PlayedIndicator.swift`
  - `Shared/Components/PosterIndicators/UnplayedIndicator.swift`
- Poster configuration and type plumbing:
  - `Shared/Objects/Poster/Poster.swift`
  - `Shared/Objects/Poster/AnyPoster.swift`
  - `Shared/Objects/PosterDisplayConfiguration.swift`
  - `Shared/Objects/PosterDisplayType.swift`
  - `Shared/Objects/PosterIndicator.swift`
  - `Shared/Extensions/ViewExtensions/PosterStyleRegistry.swift`

Interpretation: the branch is moving poster rendering toward shared, configurable primitives that can serve both iOS and tvOS instead of maintaining separate platform-specific poster stacks.

### Library And Paging Architecture

The PR adds a broad set of shared library abstractions and removes older view model classes.

Notable additions include:

- `Shared/Objects/Libraries/ItemLibrary.swift`
- `Shared/Objects/Libraries/MediaLibrary.swift`
- `Shared/Objects/Libraries/LatestInLibrary.swift`
- `Shared/Objects/Libraries/NextUpLibrary.swift`
- `Shared/Objects/Libraries/ResumeItemsLibrary.swift`
- `Shared/Objects/Libraries/SeasonLibrary.swift`
- `Shared/Objects/Libraries/ProgramsLibrary.swift`
- `Shared/Objects/PagingLibrary/PagingLibrary.swift`
- `Shared/Objects/PagingLibrary/PagingLibraryViewModel.swift`
- `Shared/Objects/PagingLibrary/PagingLibraryView/PagingLibraryView.swift`

Notable removals include older library view models:

- `Shared/ViewModels/LibraryViewModel/ItemLibraryViewModel.swift`
- `Shared/ViewModels/LibraryViewModel/PagingLibraryViewModel.swift`
- `Shared/ViewModels/LibraryViewModel/LatestInLibraryViewModel.swift`
- `Shared/ViewModels/LibraryViewModel/NextUpLibraryViewModel.swift`
- `Shared/ViewModels/LibraryViewModel/RecentlyAddedViewModel.swift`

Interpretation: the PR is replacing several special-purpose view models with reusable library and paging objects. This likely supports the "Libraries" and "Home" parts of the PR title.

### Home, Search, And Programs

The branch removes several platform-specific home/search/program views while introducing shared equivalents.

Examples of removed platform-specific files include:

- `Swiftfin/Views/HomeView/HomeView.swift`
- `Swiftfin/Views/HomeView/Components/ContinueWatchingView.swift`
- `Swiftfin/Views/HomeView/Components/LatestInLibraryView.swift`
- `Swiftfin/Views/HomeView/Components/NextUpView.swift`
- `Swiftfin/Views/HomeView/Components/RecentlyAddedView.swift`
- `Swiftfin/Views/SearchView.swift`
- `Swiftfin/Views/ProgramsView/ProgramsView.swift`
- tvOS equivalents under `Swiftfin tvOS/Views/HomeView`, `Swiftfin tvOS/Views/SearchView.swift`, and `Swiftfin tvOS/Views/ProgramsView`

Notable shared additions include:

- `Shared/Views/SearchView.swift`
- `Shared/Views/ContentGroupView.swift`
- `Shared/ViewModels/ContentGroupViewModel/ContentGroupViewModel.swift`
- `Shared/ViewModels/ContentGroupViewModel/DefaultContentGroupProvider.swift`
- `Shared/ViewModels/ContentGroupViewModel/ItemTypeContentGroupProvider.swift`
- `Shared/ViewModels/ContentGroupViewModel/LiveTVGroupProvider.swift`
- `Shared/ViewModels/ContentGroupViewModel/SearchContentGroupProvider.swift`

Interpretation: the active direction is a shared content grouping model for home, search, live TV, and item-type surfaces.

### Item View Composition

The branch removes many older item-detail components and introduces shared item content group structures.

Notable additions include:

- `Shared/ViewModels/ItemViewModel.swift`
- `Shared/Views/ItemContentGroupView/ItemContentGroupView.swift`
- `Shared/Views/ItemContentGroupView/ItemGroupProvider.swift`
- `Shared/Views/ItemContentGroupView/AboutItemGroup.swift`
- `Shared/Views/ItemContentGroupView/LabeledContentGroup.swift`
- `Shared/Views/ItemContentGroupView/EnhancedItemViewHeader/EnhancedItemViewHeader.swift`
- `Shared/Views/ItemContentGroupView/PortraitItemViewHeader.swift`
- `Shared/Views/ItemContentGroupView/SimpleItemViewHeader.swift`

Notable removals include older iOS and tvOS item views and subcomponents:

- `Swiftfin/Views/ItemView/ItemView.swift`
- `Swiftfin/Views/ItemView/MovieItemContentView.swift`
- `Swiftfin/Views/ItemView/SeriesItemContentView.swift`
- `Swiftfin/Views/ItemView/Components/AboutView/...`
- `Swiftfin/Views/ItemView/Components/ActionButtonHStack/...`
- tvOS equivalents under `Swiftfin tvOS/Views/ItemView/...`

Interpretation: item pages are likely being rebuilt around shared content groups and shared headers instead of separate iOS/tvOS trees.

### Navigation, Tabs, And Customization

The PR touches navigation routing, tab coordination, and customization settings.

Representative files:

- `Shared/Coordinators/Tabs/MainTabView.swift`
- `Shared/Coordinators/Tabs/TabCoordinator.swift`
- `Shared/Coordinators/Tabs/TabItem.swift`
- `Shared/Coordinators/Navigation/Router.swift`
- `Shared/Coordinators/Navigation/NavigationRoute/NavigationRoute+Library.swift`
- `Shared/Views/SettingsView/CustomizeViewsSettings/CustomizeViewsSettings.swift`
- `Shared/Views/SettingsView/CustomizeViewsSettings/Components/HomeSection.swift`
- `Shared/Views/SettingsView/CustomizeViewsSettings/Components/ItemSection.swift`
- `Shared/Views/SettingsView/CustomizeViewsSettings/Components/LibrarySection.swift`
- `Shared/Views/SettingsView/CustomizeViewsSettings/Components/PosterSection.swift`

Interpretation: the branch is not only replacing display code. It also adjusts how the app routes to these surfaces and how users configure the resulting views.

## Issues And Feature Areas Claimed By The PR

The PR body lists these closing references:

- [`#1910`](https://github.com/jellyfin/Swiftfin/issues/1910) Poster layout customization settings are not reflected when switching users without an app restart.
- [`#1890`](https://github.com/jellyfin/Swiftfin/issues/1890) Collections do not display more than 20 records.
- [`#1896`](https://github.com/jellyfin/Swiftfin/issues/1896) Use folder view for Home Videos and Photos libraries.
- [`#1339`](https://github.com/jellyfin/Swiftfin/issues/1339) Move from `OrderedSet` to `IdentifiedArrayOf`.
- [`#1808`](https://github.com/jellyfin/Swiftfin/issues/1808) Replace `UIScreen.main.bounds` usages.
- [`#1693`](https://github.com/jellyfin/Swiftfin/issues/1693) tvOS landscape images overlap on home.
- [`#1261`](https://github.com/jellyfin/Swiftfin/issues/1261) Blank home screen.
- [`#1031`](https://github.com/jellyfin/Swiftfin/issues/1031) Finalize poster sizing design.
- [`#1205`](https://github.com/jellyfin/Swiftfin/issues/1205) iOS/tvOS new folders not displaying content.
- [`#1615`](https://github.com/jellyfin/Swiftfin/issues/1615) HomeView rework.
- [`#1705`](https://github.com/jellyfin/Swiftfin/issues/1705) Library environment.
- [`#433`](https://github.com/jellyfin/Swiftfin/issues/433) Ability to show only favorited live TV channels.

GitHub's development sidebar also showed additional may-close links, including:

- [`#1707`](https://github.com/jellyfin/Swiftfin/issues/1707) Remove `MediaSources` field from listings.
- [`#1747`](https://github.com/jellyfin/Swiftfin/issues/1747) Custom tabs: ability to pin/unpin tabs to the tab bar.

Interpretation: the PR has become a hub for several adjacent user-facing and developer-facing cleanups. This explains its size, but it also increases review and merge risk.

## Recent Activity

The latest commits visible in the PR metadata were:

- `2026-01-02T23:12:50Z` - `wip` - `719acc0b08c1d0c4b74a673ffdde69ce2d19290f`
- `2026-01-04T00:22:06Z` - `wip` - `ff656bfbf24309da7168ab6d26fb68bca45a0f93`
- `2026-01-10T22:10:38Z` - `wip` - `c8425a778f4d83175f949941256eba8ee40055f1`
- `2026-01-13T01:12:55Z` - `wip` - `51fa5dce77cfeb447793db3635081ed1e668e54d`
- `2026-01-15T02:40:11Z` - `wip` - `f105500786b73ffe2ba6fc54fd3b558c686e8b5c`
- `2026-01-17T20:46:16Z` - `wip` - `f465963433b4bf98ca3765d56dca3681a76cd17e`
- `2026-02-07T19:55:49Z` - `wip` - `24718cda081b6365db973fa37a55ed75e9f3a253`
- `2026-02-28T17:39:12Z` - `Merge branch 'main' into poster-library-home` - `8527269f13da7266bd37bf20be8744f98fd63cd0`
- `2026-02-28T17:42:40Z` - `wip` - `141b3f6ea2873e0e6a4acea3708c048fbdec04f2`
- `2026-02-28T19:35:59Z` - `wip` - `3643a5847833a4c479fef25412850f9a160dedca`
- `2026-05-07T23:19:29Z` - `WIP before merging main` - `839cf21ba21c5bdb37137052f15aac9091e8ba6e`
- `2026-05-07T23:56:36Z` - `Merge main into poster-library-home` - `e7bae1d216677aa3915b12846333e574a3948278`

Interpretation: the most recent activity was not a finalization pass. It was a local WIP checkpoint followed by syncing `main` into the feature branch.

## Current Readiness Signals

Signals suggesting the branch is still actively under construction:

- PR is marked draft.
- PR body begins with `wip`.
- Most commits are named `wip`.
- Latest branch work includes a WIP checkpoint and a merge from `main`.
- No reviewers or review requests are present.
- No reviews are recorded.

Signals suggesting merge risk:

- GitHub reports merge state `DIRTY`.
- The diff is very large: 444 files.
- GitHub's normal PR diff endpoint exceeded the maximum file threshold.
- GitHub Actions checks were skipped.
- CodeFactor reported failure.
- The branch includes many central shared components and removes many platform-specific views.

## Open Questions

- What exact conflicts make the PR `DIRTY` against current `main`?
- Are the skipped GitHub Actions expected for draft PRs, or are they skipped because of branch/workflow configuration?
- What are the CodeFactor failures?
- Which of the many issue-closing claims are fully implemented versus incidentally affected?
- Should the branch be split into reviewable slices, for example poster primitives, library/paging architecture, shared item view composition, home/search/program migration, and customization settings?
- Are there current screenshots or TestFlight notes showing the intended iOS and tvOS behavior?
- How much of the branch overlaps newer merged PRs that were referenced in the timeline, such as LetterPicker, FilterView, ContentUnavailableView, and cleanup work?

## Source Links

- Pull request: [`jellyfin/Swiftfin#1752`](https://github.com/jellyfin/Swiftfin/pull/1752)
- Commits: [`jellyfin/Swiftfin#1752 commits`](https://github.com/jellyfin/Swiftfin/pull/1752/commits)
- Files changed: [`jellyfin/Swiftfin#1752 files`](https://github.com/jellyfin/Swiftfin/pull/1752/files)
- Head branch: [`LePips/SwiftFin:poster-library-home`](https://github.com/LePips/SwiftFin/tree/poster-library-home)

