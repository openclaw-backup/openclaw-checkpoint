#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-/Users/demo/.openclaw/workspace}"
ref="${2:-}"
target_dir="${3:-}"

if [[ -z "$ref" ]]; then
  echo "Usage: $0 [repo-dir] <ref> [target-dir]" >&2
  exit 1
fi

cd "$repo_dir"
git rev-parse --is-inside-work-tree >/dev/null
git fetch --tags origin

if [[ -n "$target_dir" ]]; then
  git worktree add "$target_dir" "$ref"
else
  git switch --detach "$ref"
fi
