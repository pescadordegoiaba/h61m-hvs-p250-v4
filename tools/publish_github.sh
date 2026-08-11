#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v git >/dev/null || { echo 'git not found'; exit 2; }
command -v gh >/dev/null || { echo 'gh not found'; exit 2; }
REPO_NAME="${REPO_NAME:-h61m-hvs-p250-v4}"
VISIBILITY="${VISIBILITY:-private}"
case "$VISIBILITY" in public|private|internal) ;; *) echo 'VISIBILITY must be public/private/internal'; exit 2;; esac
./tools/verify_release.sh
if [[ ! -d .git ]]; then git init; fi
git add -A
if ! git diff --cached --quiet; then
  git commit -m "H61M-HVS P2.50 Final Backend Unlock V4 dual-chip release"
fi
if git remote get-url origin >/dev/null 2>&1; then
  echo "origin already exists: $(git remote get-url origin)"
  git push -u origin HEAD
else
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
fi
