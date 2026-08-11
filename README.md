# ASRock H61M-HVS P2.50 — Final Backend Unlock V4

Firmware mod experimental para a **ASRock H61M-HVS**, baseado na UEFI oficial **P2.50 / AMI Aptio IV**, com desbloqueio de menus ocultos, controles avançados de CPU, memória, System Agent, PCH, PCIe, SATA, Intel ICC, thermal/power e opções específicas da ASRock.

O repositório contém **uma única imagem V4 de BIOS-region**, acompanhada por dois perfis de flash Linux/flashrom:

- **W25Q64 / 8 MiB** — perfil usado com a família Winbond original;
- **W25Q32 / 4 MiB** — perfil usado com o chip de recuperação detectado como JEDEC `EF 40 16`.

> [!IMPORTANT]
> As duas pastas usam **exatamente o mesmo firmware V4**. O `.bin` é byte-for-byte idêntico. O que muda é somente a definição de chip passada ao `flashrom` pelos scripts.

> [!CAUTION]
> Este é firmware de placa-mãe modificado. Um erro pode impedir POST/vídeo/boot. Tenha um método real de recuperação antes de gravar, como outro chip funcional, programador SPI externo ou uma forma comprovada de reflashear o dispositivo.

---

## Índice

- [Estado do projeto](#estado-do-projeto)
- [ReBAR: não incluído nesta versão](#rebar-não-incluído-nesta-versão)
- [Hardware e firmware alvo](#hardware-e-firmware-alvo)
- [Layout Intel SPI](#layout-intel-spi)
- [Perfis de chip suportados](#perfis-de-chip-suportados)
- [Identidade criptográfica da V4](#identidade-criptográfica-da-v4)
- [Resumo do mod](#resumo-do-mod)
- [CPU / OC Tweaker](#cpu--oc-tweaker)
- [Tecnologias de CPU](#tecnologias-de-cpu)
- [Memória / MRC / XMP](#memória--mrc--xmp)
- [System Agent / PEG / iGPU](#system-agent--peg--igpu)
- [Intel ICC / clocking](#intel-icc--clocking)
- [PCH / PCIe / SATA](#pch--pcie--sata)
- [Thermal / power / security](#thermal--power--security)
- [Evidência de backend](#evidência-de-backend)
- [Setup VarStore e offsets conhecidos](#setup-varstore-e-offsets-conhecidos)
- [O que foi comprovado fisicamente](#o-que-foi-comprovado-fisicamente)
- [Limitações conhecidas](#limitações-conhecidas)
- [Pré-requisitos para flash via Linux](#pré-requisitos-para-flash-via-linux)
- [Verificação antes do flash](#verificação-antes-do-flash)
- [Flash — W25Q64](#flash--w25q64)
- [Flash — W25Q32](#flash--w25q32)
- [Como o script de flash funciona](#como-o-script-de-flash-funciona)
- [NVRAM e preservação do Setup](#nvram-e-preservação-do-setup)
- [Recuperação](#recuperação)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Validação automatizada](#validação-automatizada)
- [Publicação via GitHub CLI](#publicação-via-github-cli)
- [GitHub Releases](#github-releases)
- [Documentação adicional](#documentação-adicional)
- [Aviso legal](#aviso-legal)

---

# Estado do projeto

**Versão recomendada neste repositório:** `Final Backend Unlock V4`

Estado resumido:

| Item | Estado |
|---|---|
| ASRock H61M-HVS P2.50 | alvo confirmado |
| AMI Aptio IV x86-64 | confirmado |
| Flash interno via Linux/flashrom | funcional no ambiente testado |
| Região BIOS via Intel IFD | read/write |
| Intel ME | mantida intacta |
| Flash Descriptor | mantido intacto |
| NVRAM ao vivo | preservada pelos scripts |
| W25Q64 | perfil disponível |
| W25Q32 | perfil disponível |
| Menus ocultos | extensivamente desbloqueados |
| Per-core ratio | interface/backend de Setup comprovados |
| No-K OC | toggle real exposto; unlock físico não comprovado |
| ReBAR | **não incluído** |
| Above 4G automático | **não incluído** |

A V4 deve ser tratada como a última base do projeto **sem o experimento ReBAR da V5**.

---

# ReBAR: não incluído nesta versão

Este ponto é intencionalmente destacado porque uma versão posterior de laboratório, chamada internamente de **V5**, inseriu um driver DXE de Resizable BAR e alterações HII adicionais.

No teste físico dessa V5, a placa passou a apresentar **black screen / ausência de vídeo logo após o flash**, inclusive quando a opção de ReBAR deveria estar desativada no Setup.

Por esse motivo:

- a V5 é considerada inválida para esta placa/configuração;
- o driver ReBAR da V5 **não está presente** na V4;
- a variável customizada `H61RbState` **não está presente**;
- a opção transplantada `Resizable BAR` da V5 **não está presente**;
- a opção `ReBAR MMIO/TOLUD` da V5 **não está presente**;
- o hook de `PciHostBridgeResourceAllocationProtocol` da V5 **não está presente**;
- Above 4G não é habilitado automaticamente.

O GUID FFS usado pelo experimento ReBAR da V5 era:

```text
57EB9738-37BA-5389-A90C-F7E504B16D59
```

A ferramenta:

```bash
./tools/verify_release.sh
```

verifica a imagem V4 e aborta se os identificadores conhecidos dessa implementação ReBAR forem encontrados.

---

# Hardware e firmware alvo

## Placa-mãe

- **Fabricante:** ASRock
- **Modelo:** H61M-HVS
- **Chipset:** Intel H61
- **Firmware base:** P2.50
- **Família:** AMI Aptio IV
- **Arquitetura DXE principal:** x86-64

## Firmware original autenticado

Imagem vendor original utilizada durante a engenharia reversa:

```text
H61MHVS2.50
```

Tamanho:

```text
4 MiB
```

SHA-256:

```text
da10fc7a80469cbbdf34bffea5d96cfdc9ae1aef7bec99ed1175b852167f94ca
```

SHA-256 do DXE principal descomprimido da base:

```text
24b4bfa2ac3168bd1d9d06f35456b3bfd6cc891cb266b698f3e515b8dd437396
```

Versão de Intel ME encontrada na base analisada:

```text
8.1.0.1248
```

---

# Layout Intel SPI

O Intel Flash Descriptor da imagem base define:

| Região | Endereço | Tamanho aproximado | Acesso interno observado |
|---|---:|---:|---|
| Flash Descriptor | `0x000000–0x000FFF` | 4 KiB | read-only |
| Intel ME | `0x001000–0x17FFFF` | ~1.5 MiB | locked |
| BIOS | `0x180000–0x3FFFFF` | 2.5 MiB | read-write |

Tamanho exato da BIOS-region:

```text
0x280000
2621440 bytes
```

Nos testes com `flashrom`, os Protected Ranges `PR0..PR4` apareceram como não utilizados.

Os scripts deste repositório trabalham **somente com a região `bios` do IFD**. Eles não tentam full-flash interno do chip.

---

# Perfis de chip suportados

## W25Q64 — 8 MiB

Perfil para a família Winbond usada originalmente durante os primeiros testes.

JEDEC observado anteriormente:

```text
EF 40 17
```

Definições aceitas pelo script:

```text
W25Q64BV/W25Q64CV/W25Q64FV
W25Q64JV-.Q
```

Padrão:

```text
W25Q64BV/W25Q64CV/W25Q64FV
```

Mesmo sendo um dispositivo físico de 8 MiB, o Intel Flash Descriptor usado pela placa descreve o layout de firmware de 4 MiB indicado acima, e o script grava apenas a BIOS-region de 2.5 MiB.

## W25Q32 — 4 MiB

O chip de recuperação foi detectado com:

```text
JEDEC RDID: EF 40 16
Capacidade: 4096 kB
```

O `flashrom 1.7.0` encontrou três definições compatíveis:

```text
W25Q32BV/W25Q32CV/W25Q32DV
W25Q32FV
W25Q32JV
```

As três foram utilizadas em operações de leitura da BIOS-region. Os dumps resultantes tinham exatamente:

```text
2621440 bytes
```

E todos produziram o mesmo SHA-256:

```text
35f9633e16ddb40868e76b30f31c4e650f339894139a2c8117ec940e1f43a5db
```

Também passaram em comparação byte-for-byte com `cmp`.

Padrão utilizado pelo script W25Q32:

```text
W25Q32BV/W25Q32CV/W25Q32DV
```

### Aviso `UNTESTED for operations: WP`

Durante os probes do W25Q32, o flashrom mostrou:

```text
This flash part has status UNTESTED for operations: WP
```

Isso se refere à cobertura/teste das operações de **Write Protect** para aquela definição de chip. As leituras da BIOS-region utilizadas para validar as três definições concluíram normalmente.

---

# Identidade criptográfica da V4

Os dois diretórios:

```text
firmware/w25q64/
firmware/w25q32/
```

contêm a mesma imagem:

```text
H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
```

Tamanho:

```text
2621440 bytes
```

SHA-256:

```text
529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e
```

SHA-256 do code-tail, ignorando os primeiros `0x20000` bytes reservados para a NVRAM ao vivo durante o merge:

```text
2fae3d8891ffb3b140c7f54ee954d6a327d88e892f6877b29af18dff0092e36f
```

SHA-256 do DXE descomprimido da V4:

```text
10e7bbe27bfb380204dcc244033a6b3f6565502d4dbf4b39605bc656a772c30a
```

Backup stock BIOS-region incluído como referência:

```text
aca1d8d089633394453ae2603982cbe6799a650f6ab23999b2a168e39a48f955
```

Para confirmar que W25Q32 e W25Q64 usam exatamente o mesmo firmware:

```bash
cmp -s \
  firmware/w25q64/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin \
  firmware/w25q32/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin \
  && echo "V4 W25Q64/W25Q32: byte-for-byte identical"
```

---

# Resumo do mod

A V4 evoluiu sobre as versões de pesquisa anteriores e concentra os seguintes grupos:

- desbloqueio de navegação/menu avançado;
- desbloqueio específico de controles de OC de CPU;
- exposição de `No-K OC` como toggle real;
- remoção de clamps de interface encontrados no callback do Setup;
- exposição de tecnologias de CPU/PPM/TXT;
- Intel ICC / clock generator;
- PCH PCIe;
- SATA/PCH Storage;
- System Agent;
- PEG/PCIe Gen3;
- GT/iGPU;
- XMP/MRC/memória;
- thermal/power;
- locks e segurança PCH;
- controles ASRock ocultos dentro do OC Tweaker.

Na auditoria V4 foram neutralizados adicionalmente:

```text
230 blocos condicionais
279 checks de capability/equality
```

Foram mantidas **26 expressões condicionais complexas** sem flatten cego quando usavam combinações como `NOT`, `OR`, `AND` e comparações question-to-question e não havia evidência suficiente para removê-las de forma segura.

---

# CPU / OC Tweaker

## No-K OC

Existe uma variável real no Setup:

```text
Setup[0x42]
```

Valores:

```text
0 = Disabled
1 = Enabled
```

Na V4 ela permanece exposta como uma opção explícita de OC Tweaker.

**Importante:** a existência do toggle e o armazenamento do valor não provam que um processador Intel locked aceite multiplicadores fisicamente acima dos limites permitidos pelo silício/microcode.

## CPU Ratio / All Core / Per-Core

Offsets conhecidos:

```text
CPU Ratio          Setup[0x3F]
All Core           Setup[0x40]
1-Core Ratio       Setup[0x34]
2-Core Ratio       Setup[0x35]
3-Core Ratio       Setup[0x36]
4-Core Ratio       Setup[0x37]
```

A análise do `Setup.efi` mostrou que o firmware continha callbacks que regravavam/normalizavam valores de ratio durante a edição.

Na V3/V4 foram removidos dois clamps identificados no callback do Setup que forçavam:

- `All Core` de volta ao máximo detectado da CPU;
- `1-Core Ratio` de volta ao máximo detectado da CPU.

A regra de ordenamento dos bins per-core foi preservada:

```text
1-Core >= 2-Core >= 3-Core >= 4-Core
```

Isso evita criar uma configuração logicamente inconsistente para o formato de Turbo Ratio Limits.

## Power/current/voltage

Controles presentes/expostos incluem, quando suportados pelo backend da plataforma:

- Additional Turbo Voltage;
- Long Duration Power Limit;
- Short Duration Power Limit;
- Long Duration Maintained;
- Primary Plane Current Limit;
- Secondary Plane Current Limit;
- CPU Core Voltage Offset;
- iGPU Voltage Offset;
- CPU PLL Voltage;
- VCCSA Voltage;
- VTT Voltage;
- PCH Voltage;
- Internal PLL Overvoltage;
- CPU Thermal Throttling.

## Controles ASRock adicionais

A V4 recolocou dois controles ASRock reais dentro do OC Tweaker usando slots redundantes de interface.

### Advanced Turbo 50

```text
Setup offset : 0x2AA
Question ID  : 0x4C6
Source IFR   : 0x43066
Destination  : 0x43661
```

### ASRock Vdroop Control

```text
Setup offset : 0x2B5
Question ID  : 0x245
Source IFR   : 0x43310
Destination  : 0x436D5
```

O primeiro `Load Optimized GPU OC Setting` original foi preservado; foram reutilizadas entradas redundantes.

---

# Tecnologias de CPU

Foram encontrados menus/controles nativos para várias tecnologias Intel e PPM.

Entre as famílias expostas estão:

- Intel Hyper-Threading Technology;
- Active Processor Cores;
- Enhanced Halt State / C1E;
- CPU C3 State;
- CPU C6 State;
- CPU C7 State;
- Package C State;
- Intel SpeedStep / EIST;
- Intel Turbo Boost Technology;
- CPU Thermal Throttling;
- Hardware Prefetcher;
- Adjacent Cache Line Prefetch;
- No-Execute / XD;
- Intel Virtualization Technology / VT-x;
- VT-d;
- Configurable TDP;
- Config TDP Lock;
- ACPI T-State;
- CPU PPM Configuration;
- Intel TXT.

## AVX

Nenhum toggle nativo de AVX com backend comprovado foi encontrado no HII/IFR analisado da P2.50.

Por isso a V4 **não inventa** opções artificiais como:

```text
AVX Enable
AVX Disable
AVX Ratio Offset
```

Um botão sem caminho real de backend seria apenas placebo e não faz parte do objetivo desta build.

---

# Memória / MRC / XMP

O firmware contém controles relacionados ao caminho MRC/memória, incluindo famílias como:

- XMP;
- DRAM Frequency;
- Command Rate;
- tCL;
- tRCD;
- tRP;
- tRAS;
- tWR;
- tRFC;
- tRRD;
- tWTR;
- tRTP;
- tFAW;
- DRAM Voltage;
- Memory Scrambler;
- MRC Fast Boot;
- Power Down;
- Memory Remap;
- channel/lane controls;
- memory thermal controls;
- Max TOLUD;
- DMI-related controls.

Nem todo parâmetro genérico presente num reference code Intel é necessariamente útil no H61M-HVS. A V4 prioriza tornar visíveis caminhos existentes sem afirmar suporte elétrico/físico onde isso não foi demonstrado.

---

# System Agent / PEG / iGPU

Famílias encontradas no System Agent e componentes gráficos incluem:

- GT OverClocking Support;
- GT OverClocking Frequency;
- GT OverClocking Voltage;
- iGPU Aperture Size;
- DVMT/GTT-related settings;
- Render Standby;
- Deep Render Standby;
- GOP-related options;
- PEG link controls;
- Fast PEG Init;
- PCIe Gen3 Equalization;
- equalization presets;
- dwell/margins;
- de-emphasis;
- transmitter swing;
- sampler calibration;
- DMI-related controls.

Backend associado foi correlacionado com módulos do System Agent/GOP, incluindo:

```text
SaInitDxe
SaLateInitSmm
IntelSaGopDriver
IntelIvbGopDriver
```

---

# Intel ICC / clocking

Um dos grupos mais interessantes encontrados na engenharia reversa foi o painel Intel ICC real.

Há evidência de controles para:

- nova frequência em unidades de `10 kHz`;
- SSC Mode;
- percentual de spread spectrum;
- ICC Profile;
- watchdog de ICC;
- clock gating de clocks não utilizados;
- ICC register lock;
- aplicação imediata;
- aplicação permanente após reboot.

Módulos relacionados encontrados:

```text
IccPlatform
IccOverClocking
WdtDxe
WdtAppDxe
```

Esses controles são de baixo nível. Alterações agressivas podem impedir POST/boot e devem ser tratadas como experimentais.

---

# PCH / PCIe / SATA

## PCH PCIe

Famílias expostas incluem:

- root-port enable/disable;
- ASPM;
- AER;
- Hot Plug;
- link speed;
- clock gating;
- recursos/reservas dos root ports;
- opções de treinamento/compatibilidade do PCIe presentes no firmware.

Módulos correlacionados:

```text
PchInitDxe
PchPcieSmm
PciExpressDxe
PciHotPlug
```

## SATA / Storage

Controles encontrados incluem:

- SATA controller speed;
- ALPM;
- controles por porta;
- Hot Plug;
- External SATA;
- Spin-Up;
- Device Type;
- masks/opções Intel de armazenamento presentes no firmware;
- outros parâmetros PCH-IO relacionados.

Módulos associados:

```text
SataController
PchInitDxe
```

---

# Thermal / power / security

Famílias de controles ocultos relacionadas a power/thermal/security incluem:

- CPU thermal;
- platform thermal reporting;
- C-state/power policy;
- current/power limits;
- PCH power controls;
- SMI Lock;
- BIOS Lock;
- BIOS Interface Lock;
- RTC RAM Lock;
- controles relacionados à segurança PCH;
- Intel TXT.

Módulos correlacionados incluem:

```text
PchSpiWrap
Runtime
PchInitDxe
TxtDxe
TxtOneTouchDxe
TXTWrapperDxe
```

> [!WARNING]
> Controles de lock/security podem tornar futuras alterações ou recuperações mais difíceis. Não altere valores desconhecidos sem um caminho de recuperação externa.

---

# Evidência de backend

O objetivo da V4 não foi simplesmente revelar strings escondidas. A auditoria procurou correlação com módulos que implementam o recurso.

Resumo:

| Família | Módulos/backend correlacionados |
|---|---|
| CPU policy / power | `CpuPolicyDxe`, `CpuInitDxe`, `CpuDxe` |
| Intel ICC | `IccPlatform`, `IccOverClocking`, `WdtDxe`, `WdtAppDxe` |
| PCH PCIe | `PchInitDxe`, `PchPcieSmm`, `PciExpressDxe`, `PciHotPlug` |
| SATA | `SataController`, `PchInitDxe` |
| System Agent / PEG | `SaInitDxe`, `SaLateInitSmm` |
| iGPU / GOP | `IntelSaGopDriver`, `IntelIvbGopDriver` |
| Flash/security | `PchSpiWrap`, `Runtime`, `PchInitDxe` |
| TXT | `TxtDxe`, `TxtOneTouchDxe`, `TXTWrapperDxe` |
| Memory | MRC/platform memory path, `UpdateMemoryRecord`, `SmBiosMemory` |

A presença do backend aumenta a confiança de que o controle não é apenas texto órfão, mas **não garante** que todo valor seja aceito pelo chipset, CPU ou componentes físicos da placa.

---

# Setup VarStore e offsets conhecidos

VarStore principal:

```text
Name : Setup
GUID : EC87D643-EBA4-4BB5-A1E5-3F3E36B20DA9
Size : 695 bytes
```

Principais offsets mapeados:

| Offset | Função |
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
| `0x042` | No-K OC |
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

Esses offsets são específicos do `Setup` VarStore identificado nessa P2.50 analisada. Não devem ser transportados automaticamente para outra BIOS/revisão sem nova validação.

---

# O que foi comprovado fisicamente

É importante separar **interface exposta**, **backend identificado** e **comportamento físico comprovado**.

## Flash Linux

Foi comprovado que a H61M-HVS permite leitura/escrita da região BIOS via `flashrom` interno quando o ambiente está configurado corretamente.

O estado observado do IFD foi:

```text
Descriptor : read-only
BIOS       : read-write
ME         : locked
```

## Per-core

A configuração per-core demonstrou caminho funcional na interface/Setup.

Também foi comprovado que o firmware aplicava normalização própria dos valores, o que levou à análise dos callbacks e remoção dos clamps encontrados para `All Core` e `1-Core`.

## No-K OC

O toggle existe e aponta para a variável real `Setup[0x42]`.

Entretanto, nos testes com processador locked, isso **não demonstrou** capacidade de ultrapassar os limites físicos/fused/microcode do multiplicador.

## Above 4G

Ativar Above 4G no ambiente testado resultou em ausência de vídeo/preboot com a configuração gráfica usada.

Por isso a V4 não força essa opção.

## ReBAR V5

A V5 experimental resultou em black screen/no-video mesmo quando o menu ReBAR deveria estar desativado.

Isso é um dos motivos pelos quais este repositório volta deliberadamente à V4 e contém verificações explícitas contra os artefatos da V5.

---

# Limitações conhecidas

1. **Menu visível não significa recurso fisicamente suportado.**

   Um reference code Intel pode conter opções para múltiplos chipsets/CPUs/placas.

2. **No-K não equivale a transformar um CPU locked em K.**

   O firmware pode armazenar valores que o CPU simplesmente ignora ou limita posteriormente.

3. **Algumas opções avançadas podem impedir POST.**

   Especialmente ICC, PEG training, memória, locks e certos parâmetros PCH.

4. **AVX não possui toggle nativo comprovado nessa imagem.**

   Nenhum controle falso foi criado.

5. **ReBAR está excluído.**

   Não use a V5 como base para misturar recursos nesta V4 sem uma nova investigação isolada.

6. **Above 4G não é forçado.**

   O teste físico anterior apresentou black screen.

7. **A BIOS-region não é uma imagem para full-chip interno.**

   Ela tem `2621440` bytes e deve ser usada pelo fluxo IFD `bios` fornecido.

---

# Pré-requisitos para flash via Linux

Os scripts verificam:

- execução como `root`/`sudo`;
- `flashrom` instalado;
- `python3` instalado;
- presença do `.bin` esperado;
- `iomem=relaxed` presente em `/proc/cmdline`;
- tamanho correto da BIOS-region;
- code-tail atual pertencente a uma base autenticada do projeto.

Ambiente de referência usado nos testes mais recentes do chip de recuperação:

```text
flashrom 1.7.0
Linux 7.0.9-zen1-1-zen x86_64
Intel H61
```

## Verificando `iomem=relaxed`

```bash
cat /proc/cmdline
```

Deve aparecer:

```text
iomem=relaxed
```

Se não aparecer, o script abortará antes de gravar.

---

# Verificação antes do flash

Antes de qualquer escrita, execute na raiz do repositório:

```bash
./tools/verify_release.sh
```

O verificador confirma:

1. SHA-256 dos dois `.bin`;
2. identidade byte-for-byte W25Q64/W25Q32;
3. sintaxe dos scripts shell com `bash -n`;
4. ausência dos identificadores ReBAR conhecidos da V5;
5. integridade dos ZIPs de release.

Resultado esperado:

```text
ALL CHECKS PASSED
```

Também é possível usar o script `VERIFY_ONLY.sh` dentro do perfil do chip para fazer verificações sem iniciar escrita.

---

# Flash — W25Q64

Entre na pasta:

```bash
cd firmware/w25q64
```

Execute:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Definição padrão:

```text
W25Q64BV/W25Q64CV/W25Q64FV
```

Para selecionar explicitamente a outra definição aceita:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q64JV-.Q'
```

Antes da escrita será exigida a frase:

```text
FLASH_FINAL_V4
```

Qualquer outra entrada cancela o processo.

---

# Flash — W25Q32

Entre na pasta:

```bash
cd firmware/w25q32
```

Execute:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh
```

Definição padrão:

```text
W25Q32BV/W25Q32CV/W25Q32DV
```

Outras definições que produziram leitura idêntica no chip testado:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q32FV'
```

ou:

```bash
sudo ./FLASH_LINUX_BIOS_REGION.sh 'W25Q32JV'
```

Antes da escrita será exigida a frase:

```text
FLASH_FINAL_V4_W25Q32
```

---

# Como o script de flash funciona

O fluxo foi desenhado para evitar uma gravação cega do template.

## 1. Leitura da BIOS atual

O script executa uma leitura usando o layout IFD:

```text
--ifd -i bios:<arquivo>
```

Somente a região BIOS é lida.

## 2. Autenticação da base atual

É calculado SHA-256 do code-tail:

```text
BIOS[0x20000:]
```

O valor atual precisa corresponder a uma das bases autenticadas do histórico do projeto, incluindo stock e estágios anteriores.

Se não corresponder, o script aborta.

## 3. Preservação da NVRAM

O script cria a imagem de flash assim:

```text
imagem final = current[0x00000:0x20000] + V4[0x20000:]
```

Ou seja:

- primeiros `0x20000` bytes: leitura feita imediatamente antes do flash;
- restante: code-tail V4 autenticado.

## 4. Backup

O dump imediatamente anterior à escrita fica numa pasta:

```text
preflash_YYYYMMDD_HHMMSS/
```

junto com logs e hashes.

## 5. Confirmação manual

O script exige uma frase literal antes de executar `-w`.

## 6. Escrita somente da região BIOS

É utilizado:

```text
--ifd -i bios:<imagem>
```

A escrita não solicita Descriptor nem ME.

## 7. Readback independente

Depois da escrita, a BIOS-region é lida novamente para outro arquivo.

## 8. Comparação byte-for-byte

O script compara:

```text
imagem solicitada == leitura pós-flash
```

Se houver qualquer diferença, é emitido erro crítico.

---

# NVRAM e preservação do Setup

O projeto identificou o `Setup` principal com 695 bytes e evidência de armazenamento na área NVRAM da BIOS-region.

Por segurança, os scripts preservam a NVRAM atual ao invés de sobrescrevê-la com uma cópia estática da imagem template.

Isso tem uma consequência importante:

> alterar o **default** de uma variável dentro da ROM não significa necessariamente alterar um valor já existente na NVRAM viva.

Esse comportamento já foi observado durante testes anteriores do `No-K OC`.

Se for necessário testar defaults novos, pode ser necessário limpar/carregar defaults de Setup de forma consciente, mas isso deve ser tratado como uma ação separada do flash.

---

# Recuperação

Antes de testar qualquer firmware modificado, tenha um caminho de recuperação.

Possibilidades:

- outro chip SPI funcional;
- programador externo;
- hot-swap somente se você dominar o procedimento e aceitar o risco elétrico;
- backup integral conhecido e validado;
- chip socketed/substituível.

## Depois de uma configuração ruim

Dependendo da opção alterada, um Clear CMOS pode recuperar uma configuração inválida de NVRAM.

Entretanto, Clear CMOS **não corrige código DXE/PEI defeituoso gravado no chip**. Nesse caso é necessário reflashear firmware funcional por um método que ainda consiga acessar o SPI.

## Black screen da V5

A recuperação do incidente V5 demonstrou por que é importante ter outro chip disponível. A V4 deste repositório existe justamente como baseline anterior ao ReBAR experimental.

---

# Estrutura do repositório

```text
.
├── README.md
├── resume.md
├── NOTICE.md
├── SHA256SUMS.txt
├── .gitignore
├── .gitattributes
│
├── docs/
│   ├── BACKEND_AUDIT.md
│   ├── BUILD_REPORT.json
│   └── VALIDATION.json
│
├── firmware/
│   ├── w25q64/
│   │   ├── H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
│   │   ├── H61M-HVS_PERSONAL_STOCK_BIOS_REGION_BACKUP.bin
│   │   ├── FLASH_LINUX_BIOS_REGION.sh
│   │   ├── VERIFY_ONLY.sh
│   │   └── SHA256SUMS.txt
│   │
│   └── w25q32/
│       ├── H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
│       ├── H61M-HVS_PERSONAL_STOCK_BIOS_REGION_BACKUP.bin
│       ├── FLASH_LINUX_BIOS_REGION.sh
│       ├── VERIFY_ONLY.sh
│       └── SHA256SUMS.txt
│
├── release-assets/
│   ├── H61M-HVS_V4_W25Q64.zip
│   └── H61M-HVS_V4_W25Q32.zip
│
└── tools/
    ├── verify_no_rebar.py
    ├── verify_release.sh
    ├── publish_github.sh
    └── publish_release.sh
```

---

# Validação automatizada

Execute:

```bash
./tools/verify_release.sh
```

O script espera o SHA-256 canônico:

```text
529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e
```

para ambos os firmwares.

Depois executa:

```text
cmp W25Q64 W25Q32
```

para provar que os dois `.bin` são idênticos.

Também executa:

```bash
bash -n
```

nos scripts shell e:

```bash
python3 tools/verify_no_rebar.py <V4.bin>
```

para checar os marcadores ReBAR proibidos da V5.

Por fim, os ZIPs dentro de `release-assets/` passam por teste de integridade com `unzip -tq`.

---

# Publicação via GitHub CLI

O ZIP distribuído não contém histórico `.git` pré-criado.

Depois de extrair e revisar:

```bash
cd H61M-HVS_FINAL_V4_DUAL_CHIP_GITHUB_20260811
```

Certifique-se de que `git` e `gh` estão instalados/autenticados.

Verifique:

```bash
gh auth status
```

## Criar repositório privado

```bash
REPO_NAME=h61m-hvs-p250-v4 \
./tools/publish_github.sh
```

O script:

1. executa `verify_release.sh`;
2. executa `git init` se necessário;
3. adiciona os arquivos;
4. cria commit se houver alterações staged;
5. cria o repositório com `gh repo create` se `origin` ainda não existir;
6. faz push.

Por padrão:

```text
VISIBILITY=private
```

## Criar repositório público

```bash
REPO_NAME=h61m-hvs-p250-v4 \
VISIBILITY=public \
./tools/publish_github.sh
```

Antes de publicar firmware derivado de vendor em repositório público, leia `NOTICE.md`.

---

# GitHub Releases

Depois que o repositório já existir e estiver publicado, os dois pacotes independentes podem ser enviados como release assets.

Exemplo:

```bash
TAG=v4.0-final \
./tools/publish_release.sh
```

Assets preparados:

```text
release-assets/H61M-HVS_V4_W25Q64.zip
release-assets/H61M-HVS_V4_W25Q32.zip
```

Esses ZIPs são convenientes para usuários que precisam apenas do perfil de chip correspondente, sem clonar todo o repositório.

---

# Documentação adicional

## `resume.md`

Documento técnico extenso contendo:

- histórico da engenharia reversa;
- offsets;
- resultados de testes;
- backend modules;
- decisões de implementação;
- diferenças W25Q64/W25Q32;
- histórico Above 4G/ReBAR;
- fluxo de flash.

## `docs/BACKEND_AUDIT.md`

Auditoria dos módulos relacionados às opções desbloqueadas.

## `docs/BUILD_REPORT.json`

Metadados do processo de construção da V4.

## `docs/VALIDATION.json`

Resultados de validação estrutural do firmware.

## `NOTICE.md`

Informações importantes sobre origem do firmware e distribuição de binários derivados.

---

# Histórico resumido do desenvolvimento

## Stock P2.50

Baseline oficial usada para mapear SPI, DXE, Setup, VarStores e IFR.

## Full Menus / PCI Advanced

Primeiro estágio de desbloqueio de navegação e páginas escondidas.

## No-K OC

Identificação de `Setup[0x42]` e tentativa inicial de expor/defaultar a função.

## CPU Full Unlock V2

Remoção direcionada de `SuppressIf`/`GrayOutIf` nos controles reais de CPU.

## CPU Tech Unlock V3

Expansão para tecnologias de CPU/PPM/TXT e remoção dos clamps identificados no callback de ratio do Setup.

## Final Backend Unlock V4

Auditoria mais ampla de backend e exposição de controles ICC, PCH, PCIe, SATA, SA, PEG, GT, memória, thermal/security e controles ASRock adicionais.

## ReBAR V5 — descartada

Experimento com DXE/HII ReBAR que resultou em black screen/no-video e, por isso, **não faz parte deste repositório**.

---

# Princípios desta build

A V4 segue algumas regras importantes:

1. **não inventar opções sem backend comprovado;**
2. **não gravar Intel ME pelo fluxo interno;**
3. **não gravar Flash Descriptor;**
4. **preservar NVRAM ao vivo;**
5. **autenticar o code-tail antes de escrever;**
6. **fazer readback independente após a gravação;**
7. **manter W25Q64 e W25Q32 com o mesmo binário;**
8. **manter ReBAR/V5 fora da baseline;**
9. **não forçar Above 4G;**
10. **diferenciar recurso exposto de recurso fisicamente comprovado.**

---

# Aviso legal

Este projeto contém uma imagem de firmware derivada/modificada de software de firmware proprietário originalmente distribuído por terceiros, incluindo componentes associados à ASRock, AMI e Intel.

Consulte:

```text
NOTICE.md
```

antes de redistribuir publicamente binários ou derivados.

Este projeto não é afiliado, endossado ou suportado oficialmente pela ASRock, AMI ou Intel.

O uso de firmware modificado pode causar:

- perda de boot;
- ausência de vídeo;
- corrupção de NVRAM;
- necessidade de reprogramação SPI externa;
- perda de configurações;
- comportamento elétrico/térmico fora dos padrões do fabricante.

Use apenas se você entende e aceita esses riscos.

---

# Hash principal para conferência rápida

Se você quiser conferir uma única coisa antes de começar, os dois arquivos abaixo devem ter exatamente:

```text
SHA-256
529da4c46c234db67c7c91ddfce425c7d71bf6a57ff7c8fe870063db261ae84e
```

Arquivos:

```text
firmware/w25q64/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
firmware/w25q32/H61M-HVS_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin
```

E:

```bash
./tools/verify_release.sh
```

deve terminar com:

```text
ALL CHECKS PASSED
```

---

**Projeto:** ASRock H61M-HVS P2.50 Final Backend Unlock V4  
**Baseline recomendada:** V4 sem ReBAR  
**Perfis de flash:** W25Q64 / W25Q32  
**Método de escrita:** Linux + flashrom + Intel IFD BIOS-region only
