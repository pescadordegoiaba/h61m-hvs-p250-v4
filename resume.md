# RESUME — ASRock H61M-HVS P2.50 Final Backend Unlock V4

## 1. Purpose

This repository packages the final **V4 backend-unlock BIOS mod** for the ASRock H61M-HVS P2.50 firmware, with Linux/flashrom scripts for two physically different Winbond SPI flash families used on the same board during testing/recovery.

The two chip variants do **not** contain different firmware code. They use the same 2.5 MiB BIOS-region template. The only intended difference is which flashrom `-c` chip definition the Linux scripts accept.

This V4 is the last baseline intentionally kept **without ReBAR**. A later V5 experiment added a ReBAR DXE driver and HII changes; the board then booted with a black screen/no video even when the ReBAR menu value was disabled. V5 is therefore treated as invalid for this physical board and is not included here.

---

## 2. Board / firmware identity

- Board: **ASRock H61M-HVS**
- Vendor firmware: **P2.50**
- Firmware family: AMI Aptio IV, x86-64 UEFI
- Chipset: Intel H61
- CPU used for physical OC testing: Intel Core i7-3770
- Original vendor image size: 4 MiB
- Authenticated vendor P2.50 image SHA-256: `da10fc7a80469cbbdf34bffea5d96cfdc9ae1aef7bec99ed1175b852167f94ca`.
- Decompressed main DXE baseline SHA-256: `24b4bfa2ac3168bd1d9d06f35456b3bfd6cc891cb266b698f3e515b8dd437396`

### Intel SPI layout

- Flash Descriptor: `0x000000–0x000FFF`
- Intel ME: `0x001000–0x17FFFF`
- BIOS region: `0x180000–0x3FFFFF`
- BIOS region size: **2,621,440 bytes (0x280000)**

Observed protection state:

- Descriptor: read-only through internal flashrom path
- ME: locked
- BIOS region: read-write
- PR0..PR4: unused in the tested configuration

The flash scripts intentionally operate only on the IFD `bios` region and never request full-chip internal flashing.

---

## 3. Supported physical flash profiles

### 3.1 W25Q64 family — original chip

Original testing used JEDEC `EF 40 17`, corresponding to an 8 MiB Winbond W25Q64-class device.

The W25Q64 script accepts:

- `W25Q64BV/W25Q64CV/W25Q64FV` — default
- `W25Q64JV-.Q`

The board's Intel descriptor still defines only the 4 MiB firmware layout above. The script reads/writes only the 2.5 MiB BIOS region defined by the descriptor.

### 3.2 W25Q32 family — recovery chip

The replacement/recovery chip returned:

- JEDEC RDID: **`EF 40 16`**
- flashrom size: **4096 kB**

flashrom 1.7.0 found three matching definitions:

- `W25Q32BV/W25Q32CV/W25Q32DV`
- `W25Q32FV`
- `W25Q32JV`

All three definitions were used for read-only BIOS-region dumps. Results:

```text
35f9633e16ddb40868e76b30f31c4e650f339894139a2c8117ec940e1f43a5db  bios_bv_cv_dv.bin
35f9633e16ddb40868e76b30f31c4e650f339894139a2c8117ec940e1f43a5db  bios_fv.bin
35f9633e16ddb40868e76b30f31c4e650f339894139a2c8117ec940e1f43a5db  bios_jv.bin
```

All three files were exactly **2,621,440 bytes** and `cmp` reported byte-for-byte equality.

The flashrom warning `UNTESTED for operations: WP` refers to write-protect support/testing for the flash definition; it did not prevent the successful read operations.

---

## 4. Canonical V4 firmware identity

Both chip folders contain an identical BIOS-region binary:

- File: `H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin`
- Size: **2,621,440 bytes**
- SHA-256: **`529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e`**
- Code-tail SHA-256, excluding live FV0/NVRAM `0x00000–0x1FFFF`: **`2fae3d8891ffb3b140c7f54ee954d6a327d88e892f6877b29af18dff0092e36f`**
- Decompressed V4 DXE SHA-256: `10e7bbe27bfb380204dcc244033a6b3f6565502d4dbf4b39605bc656a772c30a`

The stock BIOS-region backup included for reference has SHA-256:

`aca1d8d089633394453ae2603982cbe6799a650f6ab23999b2a168e39a48f955`

### No ReBAR guarantee for this repository image

V4 predates the V5 ReBAR experiment and does not contain that added DXE driver/HII VarStore.

The V5-specific ReBAR FFS GUID was:

`57EB9738-37BA-5389-A90C-F7E504B16D59`

The V5 custom state variable string was:

`H61RbState`

The verification tool in this repository checks the V4 image for these identifiers and fails if they are found.

V4 intentionally has:

- no ReBarDxe insertion
- no `H61RbState` VarStore
- no V5 `Resizable BAR` menu transplant
- no V5 `ReBAR MMIO/TOLUD` menu transplant
- no ReBAR PCI-host-bridge hook

Above 4G is also not automatically enabled.

---

## 5. Setup VarStore facts

Main Setup VarStore:

- Name: `Setup`
- GUID: `EC87D643-EBA4-4BB5-A1E5-3F3E36B20DA9`
- Size: 695 bytes

Important known offsets include:

| Offset | Function |
|---:|---|
| `0x001` | Above 4G Decoding |
| `0x02A` | CPU Core Voltage Offset |
| `0x02B` | iGPU Voltage Offset |
| `0x034` | 1-Core Ratio Limit |
| `0x035` | 2-Core Ratio Limit |
| `0x036` | 3-Core Ratio Limit |
| `0x037` | 4-Core Ratio Limit |
| `0x038` | Primary Plane Current Limit |
| `0x03A` | Secondary Plane Current Limit |
| `0x03E` | Additional Turbo Voltage |
| `0x03F` | CPU Ratio |
| `0x040` | All Core |
| `0x041` | CPU Thermal Throttling |
| `0x042` | No-K OC (`0` Disabled, `1` Enabled) |
| `0x055` | BIOS Interface Lock |
| `0x056` | RTC RAM Lock |
| `0x174` | EC Turbo Control Mode |
| `0x181` | Render Standby |
| `0x183` | GT OverClocking Support |
| `0x184` | GT OverClocking Frequency |
| `0x192` | iGPU Aperture Size |
| `0x1E4` | VT-d |
| `0x1ED` | Primary Graphics |
| `0x1F1` | iGPU Multi-Monitor |
| `0x1FA` | Memory Remap |
| `0x1FE` | Max TOLUD |
| `0x207` | XMP |
| `0x20E` | PCIE1 Link Speed |
| `0x22B` | Internal PLL Overvoltage |
| `0x242` | DRAM Voltage |
| `0x25C` | PCH Voltage |
| `0x25D` | CPU PLL Voltage |
| `0x25E` | VTT Voltage |
| `0x275` | CSM |
| `0x282` | Intel Turbo Boost Technology |
| `0x28F` | Long Duration Power Limit |
| `0x291` | Short Duration Power Limit |
| `0x293` | Long Duration Maintained |
| `0x299` | Secure Boot |
| `0x2AA` | Advanced Turbo 50 |
| `0x2B4` | VCCSA Voltage |
| `0x2B5` | ASRock Vdroop Control |

---

## 6. V4 backend-unlock scope

V4 is based on the preceding CPU Technology Unlock V3 and adds additional backend-backed hidden controls.

### Retained from V3

- Full Menus / PCI Advanced navigation unlock
- No-K OC exposed as a real `Setup[0x42]` toggle
- CPU Ratio / All Core / 1-Core / 2-Core / 3-Core / 4-Core controls
- removal of two Setup callback clamps that forced All-Core and 1-Core values back to the CPU-detected maximum
- CPU technology / PPM / TXT menu visibility work

### Physical result from CPU testing

The per-core UI/backend path was proven to exist because changing per-core values worked at the Setup level. On the i7-3770, attempts to exceed `39x` were originally clamped back to 39 by Setup callback code; V3/V4 remove the two identified UI callback clamps for All-Core/1-Core.

This does **not** prove the locked i7-3770 silicon/microcode will execute ratios above its fused/turbo limits. Firmware visibility/storage and physical MSR acceptance are separate layers.

### V4 additional unlock regions

V4 neutralizes 230 additional conditional blocks and 279 equality/capability checks across these IFR regions:

- PCI Subsystem + PCIe + ACPI advanced
- Platform Thermal + SATA/PCH Storage + Internal GOP
- Intel Rapid Start + TXT/PCH firmware
- Platform Misc + Intel ICC + Network Stack
- PCH-IO core + platform power
- PCH USB/EHCI per-port controls
- Azalia + PCH security/lock controls
- PCH PCIe root-port/resource controls
- System Agent navigation/capability controls
- IGD/GOP + GT power/overclocking controls
- PEG/PCIe Gen3 training/equalization
- Memory/XMP/MRC/timing/channel controls
- Memory thermal + DMI controls

Twenty-six nontrivial conditional expressions were intentionally not blindly neutralized because they used combinations such as NOT/OR/AND/question-to-question comparisons and were not considered safe to flatten without stronger proof.

---

## 7. Backend module evidence

The V4 audit correlated hidden controls with firmware modules rather than exposing arbitrary text-only questions.

### Intel ICC / clocking

Modules:

- `IccPlatform`
- `IccOverClocking`
- `WdtDxe`
- `WdtAppDxe`

Hidden controls include clock frequency in 10 kHz units, SSC mode/spread, apply-immediately/apply-permanently actions, ICC profile/watchdog, unused-clock gating and ICC register lock.

### PCH PCIe/resources

Modules:

- `PchInitDxe`
- `PchPcieSmm`
- `PciExpressDxe`
- `PciHotPlug`

Controls include root-port enable/ASPM/AER/hotplug/resource reservations/clock gating and DMI-related settings.

### SATA/storage

Modules:

- `SataController`
- `PchInitDxe`

Controls include controller speed, ALPM and per-port settings such as hot plug/external SATA/device type/spin-up and Intel storage feature masks.

### System Agent / IGD / PEG

Modules:

- `SaInitDxe`
- `SaLateInitSmm`
- `IntelSaGopDriver`
- `IntelIvbGopDriver`

Controls include GT overclock support/frequency/voltage, aperture/GTT/DVMT/render standby, PEG link/training/equalization/presets/de-emphasis/swing and related graphics/system-agent options.

### CPU policy/power

Modules:

- `CpuPolicyDxe`
- `CpuInitDxe`
- `CpuDxe`

Controls include Turbo, C-states, SpeedStep, thermal/power/current limits, Hyper-Threading, active cores, prefetchers and other CPU policy features present in the firmware.

### Security / flash locks

Modules:

- `PchSpiWrap`
- `Runtime`
- `PchInitDxe`

Controls include SMI Lock, BIOS Lock, BIOS Interface Lock, RTC RAM Lock and related PCH security options.

### Memory

Modules/evidence include `UpdateMemoryRecord`, `SmBiosMemory` and the platform MRC path.

Exposed families include XMP, DRAM frequency/timings, command rate, scrambler, MRC fast boot, power-down, channel controls, memory remap, thermal controls and DMI-related values.

### TXT

Modules:

- `TxtDxe`
- `TxtOneTouchDxe`
- `TXTWrapperDxe`

---

## 8. ASRock-specific OC Tweaker additions

V4 places two real ASRock controls into the OC Tweaker page by reusing redundant UI slots while preserving the original first GPU preset entry:

### Advanced Turbo 50

- Setup offset: `0x2AA`
- Question ID: `0x4C6`
- source IFR relative offset: `0x43066`
- transplanted destination: `0x43661`

### ASRock Vdroop Control

- Setup offset: `0x2B5`
- Question ID: `0x245`
- source IFR relative offset: `0x43310`
- transplanted destination: `0x436D5`

No artificial AVX toggle was added because the analyzed P2.50 HII/IFR did not contain a native AVX setup question with a proven backend.

---

## 9. Important menu families exposed

High-value families include, where present in the original firmware:

- Hyper-Threading
- Active Processor Cores
- C1E / C3 / C6 / C7 / Package C-state
- CPU Thermal Throttling
- XD / No-Execute
- VT-x / VT-d
- Hardware Prefetcher
- Adjacent Cache Line Prefetch
- Intel SpeedStep
- Intel Turbo Boost
- Configurable TDP / TDP Lock
- Long/Short Duration Power Limits
- Primary/Secondary Plane Current Limits
- CPU/iGPU voltage offsets
- CPU PLL / VCCSA / VTT / PCH voltages
- Internal PLL Overvoltage
- XMP and DRAM timing controls
- GT overclocking
- PEG Gen3 training/equalization
- PCH PCIe root-port options
- SATA advanced controls
- Intel ICC clocking
- TXT and several PCH security/lock controls

Visibility does not guarantee every generic Intel reference option is meaningful on H61 hardware.

---

## 10. Above 4G / ReBAR history — critical safety note

### Above 4G physical result

On the tested board, enabling Above 4G caused a black screen/no preboot video with the installed RX 580 configuration. Recovery was required. Therefore V4 does not automatically enable Above 4G.

### V5 ReBAR physical result

A later V5 added a custom ReBAR DXE driver and new PCI Advanced HII controls. The board produced black screen/no video immediately after flashing **even while the ReBAR menu value was intended to be disabled**.

This means the failure could be caused by driver load/relocation/dispatch or other V5 HII/FFS changes rather than only a resized BAR value.

Consequences:

- V5 is excluded from this repository.
- Do not merge V5/ReBAR artifacts into V4 casually.
- The V4 binaries in both chip folders are required to remain SHA-256 `529da4c...e84e`.
- `tools/verify_release.sh` checks for V5 ReBAR identifiers.

---

## 11. Linux flash workflow

Both scripts use the same safety model:

1. require root, `flashrom`, `python3` and kernel parameter `iomem=relaxed`;
2. read only the current IFD `bios` region;
3. verify that the current code-tail belongs to one of the authenticated project baselines;
4. preserve the fresh live first `0x20000` bytes of the BIOS region, which contain FV0/NVRAM state;
5. merge the V4 code-tail with the live NVRAM prefix;
6. create a pre-flash backup and SHA-256 record;
7. require a literal confirmation phrase;
8. write only the IFD `bios` region with `--noverify-all` as required by the locked ME/descriptor layout;
9. read the BIOS region again independently;
10. compare requested write vs readback byte-for-byte.

### Why NVRAM is preserved

The Setup variable is stored in the live firmware NVRAM. Preserving the first `0x20000` avoids blindly replacing board-specific/current NVRAM state with a template copy.

A consequence is that changing a *default* in the ROM does not necessarily overwrite an already-existing live Setup value. This was observed earlier with the No-K OC default experiment.

---

## 12. Flash commands

### Original W25Q64 profile

```bash
cd firmware/w25q64
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Confirmation phrase used by that original script:

`FLASH_FINAL_V4`

Alternative chip definition example:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q64JV-.Q'
```

### Recovery W25Q32 profile

```bash
cd firmware/w25q32
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Confirmation phrase:

`FLASH_FINAL_V4_W25Q32`

Alternative definitions:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q32FV'
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q32JV'
```

---

## 13. Recovery and operational warnings

This is modified motherboard firmware. A successful prior flash does not eliminate brick risk.

Strongly recommended:

- keep a known-good chip/programmer/recovery method available;
- make no unrelated changes while validating a new firmware build;
- change only one family of hidden settings at a time;
- avoid unknown ICC/PEG/memory/security-lock values unless a recovery path is ready;
- retain the automatically created preflash backup directory after every write;
- do not full-flash the 4 MiB logical/reference image internally when the script is designed for BIOS-region-only flashing;
- do not use V5/ReBAR on the tested configuration without a new, isolated engineering approach.

The W25Q32 replacement chip itself became part of the recovery path after the V5 black-screen incident.

---

## 14. Repository layout

```text
.
├── README.md
├── resume.md
├── .gitignore
├── .gitattributes
├── docs/
│   ├── BACKEND_AUDIT.md
│   ├── BUILD_REPORT.json
│   └── VALIDATION.json
├── firmware/
│   ├── w25q64/
│   │   ├── H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
│   │   ├── H61M-HVS_PERSONAL_STOCK_BIOS_REGION_BACKUP.bin
│   │   ├── FLASH_LINUX_BIOS_REGION.sh
│   │   └── VERIFY_ONLY.sh
│   └── w25q32/
│       ├── H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
│       ├── H61M-HVS_PERSONAL_STOCK_BIOS_REGION_BACKUP.bin
│       ├── FLASH_LINUX_BIOS_REGION.sh
│       └── VERIFY_ONLY.sh
├── release-assets/
│   ├── H61M-HVS_V4_W25Q64.zip
│   └── H61M-HVS_V4_W25Q32.zip
└── tools/
    ├── verify_no_rebar.py
    ├── verify_release.sh
    ├── publish_github.sh
    └── publish_release.sh
```

---

## 15. Git/GitHub publishing

No Git history is embedded in the ZIP. Extract it, review the contents, then run:

```bash
REPO_NAME=h61m-hvs-p250-v4 ./tools/publish_github.sh
```

The helper initializes a repository if needed, creates a commit and asks `gh` to create/push the remote repository. Visibility defaults to private unless explicitly overridden.

To create a GitHub Release containing both standalone chip ZIPs:

```bash
TAG=v4.0-final ./tools/publish_release.sh
```

The release helper never rebuilds firmware; it uploads the already-hashed release assets from `release-assets/`.
