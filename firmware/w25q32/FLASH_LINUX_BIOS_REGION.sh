#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$HERE/H61M-HVS_PERSONAL_FINAL_BACKEND_UNLOCK_V4_BIOS_REGION.bin"
EXPECTED_SIZE=2621440
STOCK_CODE_SHA="cd863c6756ca1b4e1d9a8e4ce6bf59ceb4eb6c7581f914cb25ab16b07f8d38b7"
STAGE1_CODE_SHA="3a6cb595922172b256baa87da635939366f00000ed81d5398e15f74e11ec87f8"
FULLMENUS_CODE_SHA="d5bb903d45fd34204f4fd7574c1a3b4a4794a88e76cfe2fcf22fc7ff0dc678ca"
NONK_CODE_SHA="e4f5fc8a446775f53ec2670486a7243ed2f0f05678efab2c07eaa3a13c19f055"
ALLHIDDEN_CODE_SHA="22eed556203c8de4fcf73c09ff739114db34b744249d898732505506f7c641f0"
CPU_FULL_V2_CODE_SHA="7522f6780118f22f2fed60e3b7a0b735950c5758fee7159c3a3bbc66b34299a8"
CPU_TECH_V3_CODE_SHA="c2ebfaae5047212845e8f78586f2a8c95a4c8e849052cac327042c84d8cb7565"
FINAL_V4_CODE_SHA="2fae3d8891ffb3b140c7f54ee954d6a327d88e892f6877b29af18dff0092e36f"
DEFAULT_CHIP='W25Q32BV/W25Q32CV/W25Q32DV'
CHIP="${1:-$DEFAULT_CHIP}"
case "$CHIP" in
 'W25Q32BV/W25Q32CV/W25Q32DV'|'W25Q32FV'|'W25Q32JV') ;;
 *) echo "ERRO: definição de chip não suportada: $CHIP"; exit 2;;
esac
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo "ERRO: execute com sudo/root."; exit 2; }
command -v flashrom >/dev/null || { echo "ERRO: flashrom não encontrado."; exit 2; }
command -v python3 >/dev/null || { echo "ERRO: python3 não encontrado."; exit 2; }
[[ -f "$TEMPLATE" ]] || { echo "ERRO: template não encontrado."; exit 2; }
grep -qw 'iomem=relaxed' /proc/cmdline || { echo "ERRO: iomem=relaxed não está presente em /proc/cmdline."; exit 2; }
TS="$(date +%Y%m%d_%H%M%S)"; WORK="$HERE/preflash_${TS}"; mkdir -p "$WORK"
CURRENT="$WORK/current_bios_region.bin"; TOFLASH="$WORK/live_merged_final_backend_v4.bin"; POST="$WORK/postflash_bios_region.bin"
printf '
[1/6] Lendo a região BIOS atual...
'
flashrom -p internal -c "$CHIP" --ifd -i "bios:$CURRENT" -r -o "$WORK/preflash_read.log"
printf '
[2/6] Validando base e preservando a NVRAM AO VIVO...
'
python3 - "$CURRENT" "$TEMPLATE" "$TOFLASH" "$EXPECTED_SIZE" "$STOCK_CODE_SHA" "$STAGE1_CODE_SHA" "$FULLMENUS_CODE_SHA" "$NONK_CODE_SHA" "$ALLHIDDEN_CODE_SHA" "$CPU_FULL_V2_CODE_SHA" "$CPU_TECH_V3_CODE_SHA" "$FINAL_V4_CODE_SHA" <<'PY2'
from pathlib import Path
import hashlib, sys
curp,tmpp,outp=map(Path,sys.argv[1:4]); expected_size=int(sys.argv[4]); allowed=set(sys.argv[5:13])
cur=curp.read_bytes(); tmpl=tmpp.read_bytes()
if len(cur)!=expected_size or len(tmpl)!=expected_size: raise SystemExit(f"ERRO: tamanho inesperado current={len(cur)} template={len(tmpl)}")
cur_code=hashlib.sha256(cur[0x20000:]).hexdigest(); tmpl_code=hashlib.sha256(tmpl[0x20000:]).hexdigest()
print('current code-tail sha256:',cur_code); print('template code-tail sha256:',tmpl_code)
if cur_code not in allowed: raise SystemExit('ERRO: código atual não corresponde a uma base autenticada deste projeto.')
expected=sys.argv[12]
if tmpl_code!=expected: raise SystemExit('ERRO: template FINAL V4 falhou na autenticação local.')
out=cur[:0x20000]+tmpl[0x20000:]; outp.write_bytes(out)
if out[:0x20000]!=cur[:0x20000]: raise SystemExit('ERRO: NVRAM não foi preservada.')
if hashlib.sha256(out[0x20000:]).hexdigest()!=expected: raise SystemExit('ERRO: code-tail inesperado após merge.')
print('NVRAM live preservada: YES'); print('imagem preparada sha256:',hashlib.sha256(out).hexdigest())
PY2
printf '
[3/6] Backup imediatamente anterior ao flash:
  %s
' "$CURRENT"
sha256sum "$CURRENT" "$TOFLASH" | tee "$WORK/preflash_sha256.txt"
cat <<EOX

[4/6] FINAL BACKEND UNLOCK V4 / W25Q32 PRONTO PARA GRAVAR.
Chip:       $CHIP
Descriptor: NÃO será gravado
Intel ME:   NÃO será gravada
NVRAM:      preservada da leitura feita agora
ReBAR:      NÃO incluído
Above 4G:   NÃO é ativado automaticamente

Inclui V3 + ICC/clock, PCH/PCIe/SATA, SA/PEG/GT/memória, thermal/security locks,
Advanced Turbo 50 e ASRock Vdroop Control no OC Tweaker.

Digite exatamente: FLASH_FINAL_V4_W25Q32
EOX
read -r CONFIRM
[[ "$CONFIRM" == "FLASH_FINAL_V4_W25Q32" ]] || { echo "Cancelado."; exit 3; }
printf '
[5/6] Gravando SOMENTE a região BIOS e verificando...
'
flashrom -p internal -c "$CHIP" --ifd -i "bios:$TOFLASH" --noverify-all -w -o "$WORK/write.log"
printf '
[6/6] Leitura independente pós-gravação...
'
flashrom -p internal -c "$CHIP" --ifd -i "bios:$POST" -r -o "$WORK/postflash_read.log"
python3 - "$TOFLASH" "$POST" <<'PY2'
from pathlib import Path
import hashlib,sys
want=Path(sys.argv[1]).read_bytes(); got=Path(sys.argv[2]).read_bytes()
print('wanted sha256:',hashlib.sha256(want).hexdigest()); print('readback sha256:',hashlib.sha256(got).hexdigest())
if want!=got: raise SystemExit('ERRO CRÍTICO: leitura pós-gravação não coincide byte a byte.')
print('READBACK BYTE-FOR-BYTE: PASS')
PY2
echo; echo "FLASH CONCLUÍDO E VERIFICADO. Faça reboot normal."; echo "Backup/logs: $WORK"
