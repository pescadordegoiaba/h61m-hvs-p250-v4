#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
B64="$ROOT/firmware/w25q64/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin"
B32="$ROOT/firmware/w25q32/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin"
EXPECTED="529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e"

echo '[1/5] SHA-256'
for f in "$B64" "$B32"; do
  got="$(sha256sum "$f" | awk '{print $1}')"
  echo "$got  $f"
  [[ "$got" == "$EXPECTED" ]] || { echo 'FAIL: unexpected BIOS hash'; exit 1; }
done

echo '[2/5] Binary identity'
cmp -s "$B64" "$B32"
echo 'PASS: W25Q64 and W25Q32 BIOS-region binaries are byte-for-byte identical.'

echo '[3/5] Shell syntax'
bash -n "$ROOT/firmware/w25q64/FLASH_LINUX_BIOS_REGION.sh"
bash -n "$ROOT/firmware/w25q64/VERIFY_ONLY.sh"
bash -n "$ROOT/firmware/w25q32/FLASH_LINUX_BIOS_REGION.sh"
bash -n "$ROOT/firmware/w25q32/VERIFY_ONLY.sh"
bash -n "$ROOT/tools/publish_github.sh"
bash -n "$ROOT/tools/publish_release.sh"
echo 'PASS: bash -n'

echo '[4/5] No-ReBAR V4 verification'
python3 "$ROOT/tools/verify_no_rebar.py" "$B64"

echo '[5/5] Release assets'
unzip -tq "$ROOT/release-assets/H61M-HVS_V4_W25Q64.zip" >/dev/null
unzip -tq "$ROOT/release-assets/H61M-HVS_V4_W25Q32.zip" >/dev/null
echo 'PASS: nested release ZIP integrity'

echo 'ALL CHECKS PASSED'
