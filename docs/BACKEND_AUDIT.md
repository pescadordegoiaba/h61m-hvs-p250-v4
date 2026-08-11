# Backend audit — H61M-HVS P2.50 FINAL V4

This build does not merely expose arbitrary strings. The following hidden control families have matching firmware modules and Setup/VarStore plumbing in the analyzed P2.50 image.

## Intel ICC / clocking
Modules: IccPlatform, IccOverClocking, WdtDxe, WdtAppDxe

## PCH PCIe/resources
Modules: PchInitDxe, PchPcieSmm, PciExpressDxe, PciHotPlug

## SATA/storage
Modules: SataController, PchInitDxe

## System Agent / IGD / PEG
Modules: SaInitDxe, SaLateInitSmm, IntelSaGopDriver, IntelIvbGopDriver

## CPU policy/power
Modules: CpuPolicyDxe, CpuInitDxe, CpuDxe

## Security/flash locks
Modules: PchSpiWrap, Runtime, PchInitDxe

## Memory bookkeeping
Modules: UpdateMemoryRecord, SmBiosMemory

## TXT
Modules: TxtDxe, TxtOneTouchDxe, TXTWrapperDxe

## High-value hidden controls surfaced
- Intel ICC: frequency in 10 kHz units, SSC mode/spread, apply immediately, apply permanently, ICC profile, watchdog, unused clock gating, ICC register lock.
- System Agent/IGD: GT overclock support/frequency/voltage, aperture/GTT/DVMT, render standby.
- PEG/PCIe: link generation, ASPM, de-emphasis, swing, Gen3 equalization/preset search, fast PEG init, RxCEM diagnostics.
- Memory/MRC: XMP, DRAM frequency/timings, command rate, scrambler, MRC fast boot, power-down mode, channel controls, memory remap, thermal management.
- PCH PCIe: root-port enable, ASPM, AER error reporting, hot-plug, resource reservation, PCIe clock gating, DMI ASPM/extended sync.
- PCH security: SMI Lock, BIOS Lock, GPIO Lock, BIOS Interface Lock, RTC RAM Lock.
- SATA: controller speed, ALPM, per-port hot plug/external-SATA/device type/spin-up and Intel storage feature mask fields.
- Thermal: ACPI trip points, ME SMBus thermal reporting, PCH thermal device, CPU/PCH/DIMM sensor controls.

## ASRock-only controls inserted into OC Tweaker
- Advanced Turbo 50 — Setup[0x2AA], QID 0x4C6.
- ASRock Vdroop Control — Setup[0x2B5], QID 0x245.

Two redundant `Load Optimized GPU OC Setting` UI instances were used as equal/greater-sized slots; the first GPU preset entry remains untouched.

## Deliberately not fabricated
No fake AVX toggle was added; there is no native AVX setup question in P2.50. No ReBAR code is included. Above 4G stays at the current/default setting.
