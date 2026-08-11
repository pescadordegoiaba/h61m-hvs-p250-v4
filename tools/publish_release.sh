#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v gh >/dev/null || { echo 'gh not found'; exit 2; }
TAG="${TAG:-v4.0-final}"
./tools/verify_release.sh
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" \
    release-assets/H61M-HVS_V4_W25Q64.zip \
    release-assets/H61M-HVS_V4_W25Q32.zip \
    --clobber
else
  gh release create "$TAG" \
    release-assets/H61M-HVS_V4_W25Q64.zip \
    release-assets/H61M-HVS_V4_W25Q32.zip \
    --title "H61M-HVS P2.50 Final Backend Unlock V4" \
    --notes "Dual-chip release: W25Q64 and W25Q32 flashrom profiles. Same authenticated V4 BIOS-region binary. No ReBAR/V5 code included."
fi
