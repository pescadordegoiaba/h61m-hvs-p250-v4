#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"; TEMPLATE="$HERE/H61M-HVS_PERSONAL_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin"; CHIP="${1:-W25Q64BV/W25Q64CV/W25Q64FV}"
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo "ERRO: execute com sudo/root."; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
flashrom -p internal -c "$CHIP" --ifd -i "bios:$TMP/current.bin" -r >/dev/null
python3 - "$TMP/current.bin" "$TEMPLATE" <<'PY2'
from pathlib import Path
import hashlib,sys
for label,p in [('current',Path(sys.argv[1])),('template',Path(sys.argv[2]))]:
 b=p.read_bytes(); print(label,'full sha256:',hashlib.sha256(b).hexdigest()); print(label,'code-tail sha256:',hashlib.sha256(b[0x20000:]).hexdigest())
PY2
