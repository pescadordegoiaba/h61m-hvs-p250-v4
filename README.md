# ASRock H61M-HVS P2.50 — Final Backend Unlock V4

Repository-ready package for the **same V4 firmware image** with two Linux/flashrom chip profiles:

- `firmware/w25q64/` — original 8 MiB Winbond W25Q64 chip family.
- `firmware/w25q32/` — recovery 4 MiB Winbond W25Q32 chip family.

> **Important:** the BIOS-region binary is byte-for-byte identical in both directories. Only the flashrom chip-selection scripts differ.

## ReBAR status

**ReBAR is NOT included in V4.** The later V5 ReBAR experiment caused a no-video/black-screen boot and is intentionally excluded from this repository.

Run the local verification before publishing or flashing:

```bash
./tools/verify_release.sh
```

## Flash

### W25Q64

```bash
cd firmware/w25q64
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Supported script definitions:

- `W25Q64BV/W25Q64CV/W25Q64FV` (default)
- `W25Q64JV-.Q`

### W25Q32

```bash
cd firmware/w25q32
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Supported script definitions:

- `W25Q32BV/W25Q32CV/W25Q32DV` (default)
- `W25Q32FV`
- `W25Q32JV`

The W25Q32 recovery chip was probed as JEDEC `EF 40 16`; all three flashrom definitions produced identical 2,621,440-byte BIOS-region reads.

## GitHub CLI

To initialize and push this folder as a new repository:

```bash
REPO_NAME=h61m-hvs-p250-v4 ./tools/publish_github.sh
```

To publish the two standalone ZIPs as a GitHub Release after the repository exists:

```bash
TAG=v4.0-final ./tools/publish_release.sh
```

Read [`resume.md`](./resume.md) before flashing or publishing.
