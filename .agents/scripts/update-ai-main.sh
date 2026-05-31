#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"
UPSTREAM_HTTPS_URL="${UPSTREAM_HTTPS_URL:-https://github.com/jellyfin/Swiftfin.git}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
AI_BRANCH="${AI_BRANCH:-ai/main}"

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

require_clean_worktree() {
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "Refusing to update branches with a dirty worktree." >&2
        git status --short >&2
        exit 1
    fi
}

fetch_upstream_main() {
    echo "Fetching ${UPSTREAM_REMOTE}/${MAIN_BRANCH}..."
    if git fetch "$UPSTREAM_REMOTE" "$MAIN_BRANCH"; then
        return 0
    fi

    echo "Configured upstream fetch failed; falling back to ${UPSTREAM_HTTPS_URL} ${MAIN_BRANCH}." >&2
    git fetch "$UPSTREAM_HTTPS_URL" "$MAIN_BRANCH"
}

require_clean_worktree
fetch_upstream_main

echo "Updating local ${MAIN_BRANCH}..."
git switch "$MAIN_BRANCH"
git merge --ff-only FETCH_HEAD

echo "Pushing ${ORIGIN_REMOTE}/${MAIN_BRANCH}..."
git push "$ORIGIN_REMOTE" "$MAIN_BRANCH"

if git show-ref --verify --quiet "refs/heads/${AI_BRANCH}"; then
    echo "Switching to existing ${AI_BRANCH}..."
    git switch "$AI_BRANCH"
else
    echo "Creating ${AI_BRANCH} from ${MAIN_BRANCH}..."
    git switch -c "$AI_BRANCH" "$MAIN_BRANCH"
fi

echo "Merging updated ${MAIN_BRANCH} into ${AI_BRANCH}..."
git merge --no-edit "$MAIN_BRANCH"

echo "Pushing ${ORIGIN_REMOTE}/${AI_BRANCH}..."
git push -u "$ORIGIN_REMOTE" "$AI_BRANCH"

echo "Done. ${AI_BRANCH} is updated."

