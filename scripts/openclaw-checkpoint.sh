#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-/Users/demo/.openclaw/workspace}"
remote_name="${REMOTE_NAME:-origin}"
branch_name="${BRANCH_NAME:-main}"
tag_prefix="${TAG_PREFIX:-checkpoint}"
timestamp="$(date '+%Y%m%d-%H%M%S')"
commit_message="${COMMIT_MESSAGE:-checkpoint: ${timestamp}}"
tag_name="${TAG_NAME:-${tag_prefix}-${timestamp}}"

cd "$repo_dir"

git rev-parse --is-inside-work-tree >/dev/null
git remote get-url "$remote_name" >/dev/null

if git status --porcelain=v1 --untracked-files=all | rg -n '(^|/)(\.env(\..*)?|auth-profiles\.json|device-auth\.json|credentials/|.*\.(key|pem|p12|pfx|crt|cer|der|token|secret))($| )' >/dev/null; then
  echo "Refusing to checkpoint: secret-like files are present in the working tree." >&2
  git status --short --untracked-files=all
  exit 1
fi

git add -A

if git diff --cached --quiet; then
  echo "No changes to checkpoint."
  exit 0
fi

git commit -m "$commit_message"

if git rev-parse "$tag_name" >/dev/null 2>&1; then
  echo "Tag already exists: $tag_name" >&2
  exit 1
fi

git tag -a "$tag_name" -m "$commit_message"
git push "$remote_name" "$branch_name"
git push "$remote_name" "$tag_name"

echo "Checkpoint pushed: $tag_name"
echo "Commit: $(git rev-parse --short HEAD)"
