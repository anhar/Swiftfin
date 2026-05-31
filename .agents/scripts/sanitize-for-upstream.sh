#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: sanitize-for-upstream.sh [--root PATH]

Remove fork-only agent files from a working tree before preparing an upstream PR.
By default, the script runs from the current git repository root.
EOF
}

root=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            if [[ $# -lt 2 ]]; then
                echo "--root requires a path." >&2
                exit 2
            fi
            root="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$root" ]]; then
    root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

cd "$root"

is_git_repo=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    is_git_repo=true
fi

declare -a targets=()

add_target_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        targets+=("$path")
    fi
}

add_target_if_exists ".agents"
add_target_if_exists ".codex"
add_target_if_exists ".claude"
add_target_if_exists ".aider.conf.yml"
add_target_if_exists ".aider.chat.history.md"
add_target_if_exists ".aider.input.history"
add_target_if_exists ".continue"
add_target_if_exists ".cursor"
add_target_if_exists ".windsurf"

while IFS= read -r -d '' file; do
    targets+=("${file#./}")
done < <(find . -type f \( \
    -name 'AGENTS.md' -o \
    -name 'CLAUDE.md' -o \
    -name 'GEMINI.md' -o \
    -name '.aider*' \
\) -print0)

if [[ ${#targets[@]} -eq 0 ]]; then
    echo "No agent-only artifacts found."
else
    echo "Removing agent-only artifacts:"
    for target in "${targets[@]}"; do
        echo "  ${target}"
        if [[ "$is_git_repo" == true ]]; then
            git rm -r --ignore-unmatch -- "$target" >/dev/null 2>&1 || true
        fi
        rm -rf -- "$target"
    done
fi

echo
if [[ "$is_git_repo" == true ]]; then
    echo "Remaining git status:"
    git status --short
    echo
    echo "Remaining diff summary:"
    git diff --stat
    git diff --cached --stat
    echo
    echo "Review reminder:"
    echo "  This cleanup removes fork-only development scaffolding; it is not a concealment step."
    echo "  If AI materially assisted this work, disclose that in your own words and confirm manual review."
else
    echo "Sanitized non-git directory: ${root}"
fi
