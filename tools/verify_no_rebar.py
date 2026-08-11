#!/usr/bin/env python3
from pathlib import Path
import hashlib, lzma, struct, sys, uuid

EXPECTED_BIOS_SHA = "529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e"
REBAR_GUID = uuid.UUID("57eb9738-37ba-5389-a90c-f7e504b16d59")
# UEFI GUID encoding: first three fields little-endian, last 8 bytes as-is.
guid_bytes = REBAR_GUID.bytes_le
needles = {
    "V5 ReBAR FFS GUID": guid_bytes,
    "H61RbState ASCII": b"H61RbState",
    "H61RbState UTF-16LE": "H61RbState".encode("utf-16le"),
    "ReBarState ASCII": b"ReBarState",
    "ReBarState UTF-16LE": "ReBarState".encode("utf-16le"),
}

if len(sys.argv) != 2:
    raise SystemExit(f"usage: {sys.argv[0]} BIOS_REGION.bin")
p = Path(sys.argv[1])
bios = p.read_bytes()
if len(bios) != 0x280000:
    raise SystemExit(f"FAIL: unexpected BIOS-region size {len(bios)}")
sha = hashlib.sha256(bios).hexdigest()
print("bios sha256:", sha)
if sha != EXPECTED_BIOS_SHA:
    raise SystemExit("FAIL: BIOS SHA-256 is not the authenticated V4 image")

# Search both compressed image and decompressed outer DXE.
search_blobs = [("BIOS region", bios)]
OUTER_COMP_SECTION_OFF = 0x1C0918 - 0x180000
sec_size = int.from_bytes(bios[OUTER_COMP_SECTION_OFF:OUTER_COMP_SECTION_OFF+3], "little")
if bios[OUTER_COMP_SECTION_OFF+3] != 0x01:
    raise SystemExit("FAIL: expected outer EFI compression section not found")
payload = bios[OUTER_COMP_SECTION_OFF+9:OUTER_COMP_SECTION_OFF+sec_size]
dxe = lzma.decompress(payload, format=lzma.FORMAT_ALONE)
search_blobs.append(("decompressed DXE", dxe))

found = []
for blob_name, blob in search_blobs:
    for label, needle in needles.items():
        pos = blob.find(needle)
        if pos >= 0:
            found.append((blob_name, label, pos))

if found:
    for blob_name, label, pos in found:
        print(f"FOUND: {label} in {blob_name} at 0x{pos:X}")
    raise SystemExit("FAIL: V5/ReBAR identifier found")

insert = dxe[0x5453B0:0x5453D0]
print("DXE 0x5453B0 prefix:", insert.hex())
if any(x != 0xFF for x in insert):
    print("NOTE: insert-area prefix is not fully erased; SHA-256 still authenticates V4 exactly.")
print("PASS: authenticated V4; no V5/ReBAR identifiers found")
