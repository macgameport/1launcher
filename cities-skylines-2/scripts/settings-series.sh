#!/bin/bash
# settings-series.sh [DRY=1] [CAPTURE=1] [WINDOW=<w>x<h>] <cell> [<cell> ...]
# A series of built-in benchmark runs, one graphics setting changed per run. Each cell is one cycle of
# scripts/perf-bench.sh with Settings.coc made for the cell from the copy taken at the start, and that copy
# is put back at the end (sha256-checked). Runbook: docs/settings-series-runbook.md. First used on the Mac
# Studio on 2026-11-25 (game 1.6.4f1), from the workspace, as s164-series.sh: docs/perf-pass-results.md.
#
# The BASE is made from the Settings.coc found, with these keys set and everything else left as found:
#   anti-aliasing TAA (SMAA quality High) | shadows on, Medium (2048, terrain shadows, culling 1.5) |
#   Level of Detail 0.25 | upscaler None | fog, volumetrics, ambient occlusion, reflections and both
#   cloud kinds on | vsync off (so a run is not capped at the display's rate).
# Dynamic Resolution, the display mode and every other key are left as found, and are printed at the start.
#
# Cells (the BASE with the named keys changed; join several with "+", as in sh-low+clouds-off):
#   base
#   sh-low sh-high sh-off                       shadows Low / High / off
#   aa-none aa-fxaa aa-smaa-low aa-smaa-high    anti-aliasing (the BASE is TAA)
#   fsr3 fsr3-uq fsr3-bal fsr3-perf             FSR 3 at Quality / Ultra Quality / Balanced / Performance
#   fsr4 xess3                                  the other two upscalers the game lists
#   lod-035 lod-050 lod-100                     Level of Detail
#   fog-off vol-off ssao-off ssr-off clouds-off one effect group off (clouds-off is both cloud kinds;
#   vclouds-off dclouds-off                     the volumetric ones alone, the distant ones alone)
#   drs-off drs-050                             Dynamic Resolution off / on at a fixed 0.5 (the laptop profile's)
# Every cycle: CS2_UPDATE=skip, CS2_PROFILE=off, Use Native=1 in the registry, Player.log's window size
# required to be the same in every cycle (WINDOW names it; without WINDOW the first cycle's is taken), the
# cell's keys read back from Settings.coc after the game closed (the game rewrites the file: a value it did
# not keep is a VOID cycle), a graceful exit wanted. Two VOID cycles in a row stop the series.
# DRY=1: make each cell's Settings.coc in a scratch folder, print its diff against the file found, start nothing.
#   DRY_FROM=<file> reads that Settings.coc in place of the wrapper's; DRY_KEEP=<folder> keeps the files made.
# CAPTURE=1: also capture the game's window (that window only) at fixed seconds after the benchmark's scene
#   is loaded (CAPTURE_AT, default "10 30 50 70"), into the series folder, for scripts/edge-probe.swift.
#   Measured on the Studio: captures did not move the frame rate (39.53 with, 39.55 without).
# ALWAYS at the end: waits for the game to be gone and puts Settings.coc back.
# NEVER edit this file while a series runs: bash reads a script as it goes.
set -u
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/../common/paths.sh"
RUNDIR="${CS2_PERF_DIR:-$CS2_WORK/perf-runs}"
[ $# -ge 1 ] || { echo "usage: [DRY=1] [CAPTURE=1] [WINDOW=<w>x<h>] $0 <cell> ..."; exit 2; }
W="$(bash "$REPO/../common/wrappers.sh" find game 949230)" || { echo "STOP: no game wrapper"; exit 1; }
SS="$W/Contents/SharedSupport"
C="$SS/prefix/drive_c/users/Wineskin/AppData/LocalLow/Colossal Order/Cities Skylines II"; S="$C/Settings.coc"
TS=$(date +%Y%m%d-%H%M%S); LOGD="$RUNDIR/settings-$TS"
die() { echo "STOP: $*"; exit 1; }
game_gone() { ! pgrep -qf '/Cities2\.exe'; }
wine_gone() { ! ps -axo comm | grep -qiE 'wineserver|wine64|wine-preloader'; }
wait_gone() { local i; for i in $(seq 1 120); do game_gone && wine_gone && return 0; sleep 2; done; return 1; }
locked() { ioreg -n Root -d1 -a 2>/dev/null | grep -q CGSSessionScreenIsLocked; }
[ "${DRY:-0}" = 1 ] && [ -n "${DRY_FROM:-}" ] && S="$DRY_FROM"   # a dry run of another Settings.coc (a copy from another Mac)
[ -f "$S" ] || die "no Settings.coc at the game's wrapper: start the game once and close it"

# make_cell <cell> <src> <dst>: the cell's Settings.coc; prints the strings it must hold after the run, one a line.
# With <cell> "describe": prints what the file found holds for the keys the BASE leaves alone, writes nothing.
make_cell() {
  /usr/bin/python3 - "$1" "$2" "$3" <<'PY'
import sys, re, io
cell, src, dst = sys.argv[1:4]
s = io.open(src, encoding='utf-8', newline='').read()   # newline='': the file's own line ends are kept
T = 'Game.Settings.%sQualitySettings'
def block(kind):
    """the text of one quality block, found by its @type; none of them holds a nested brace"""
    t = 'Game.Settings.DynamicResolutionScaleSettings' if kind == 'DynamicResolutionScale' else T % kind
    m = re.search(r'\{[^{}]*"@type": "%s"[^{}]*\}' % re.escape(t), s)
    if not m: raise SystemExit("Settings.coc has no %s block: this script does not know this file" % kind)
    return m
def setk(kind, key, val):
    """set "key": val inside one block; val is the text to stand after the colon"""
    global s
    m = block(kind); b = m.group(0)
    b2, n = re.subn(r'("%s": )("[^"]*"|[-0-9.eE]+|true|false)' % re.escape(key), lambda x: x.group(1) + val, b)
    if n != 1: raise SystemExit("%s block: key %s found %d times" % (kind, key, n))
    s = s[:m.start()] + b2 + s[m.end():]
def top(key, val, after=None):
    """set a top-level key of Graphics Settings (4 spaces deep); put it in after another key if it is absent"""
    global s
    pat = r'(?m)^(    "%s": )("[^"]*"|[-0-9.eE]+|true|false)(,?)\r?$' % re.escape(key)
    if re.search(pat, s):
        s, n = re.subn(pat, lambda x: x.group(1) + val + x.group(3), s)
        if n != 1: raise SystemExit("key %s found %d times" % (key, n))
    elif after:
        m = re.search(r'(?m)^(    "%s": [^\n]*,)(\r?\n)' % re.escape(after), s)
        if not m: raise SystemExit("cannot place %s: no %s line" % (key, after))
        s = s[:m.end()] + '    "%s": %s,' % (key, val) + m.group(2) + s[m.end():]
    else: raise SystemExit("no key " + key)
def drop(key):
    global s
    s = re.sub(r'(?m)^    "%s": [^\n]*\n' % re.escape(key), '', s)
def get(kind, key):
    m = re.search(r'"%s": ("[^"]*"|[-0-9.eE]+|true|false)' % re.escape(key), block(kind).group(0))
    return m.group(1) if m else '(absent)'
if cell == 'describe':
    dm = re.search(r'"displayMode": "([A-Za-z]*)"', s); rs = re.search(r'"width": (\d+),\s*"height": (\d+)', s)
    up = re.search(r'(?m)^    "upscaler": "([A-Za-z0-9]*)"', s)
    print("display mode %s, stored resolution %s, upscaler as found %s, Dynamic Resolution enabled %s (minScale %s, adaptive %s)" % (
        dm.group(1) if dm else '?', '%sx%s' % rs.groups() if rs else '?', up.group(1) if up else '(no key: the game default)',
        get('DynamicResolutionScale', 'enabled'), get('DynamicResolutionScale', 'minScale'), get('DynamicResolutionScale', 'isAdaptive')))
    raise SystemExit(0)
want = []   # strings the game's rewritten file must still hold
def shadows(on, r, t, c):
    setk('Shadows', 'enabled', on)
    setk('Shadows', 'directionalShadowResolution', str(r)); setk('Shadows', 'terrainCastShadows', t)
    setk('Shadows', 'shadowCullingThresholdHeight', c); setk('Shadows', 'shadowCullingThresholdVolume', c)
def aa(m, q='High'):
    setk('AntiAliasing', 'antiAliasingMethod', '"%s"' % m); setk('AntiAliasing', 'smaaQuality', '"%s"' % q)
def up(name, quality=None):
    top('upscaler', '"%s"' % name, after='vSync'); drop('upscalerQuality')
    if quality: top('upscalerQuality', '"%s"' % quality, after='upscaler')
def clouds(v):
    setk('Clouds', 'volumetricCloudsEnabled', v); setk('Clouds', 'distanceCloudsEnabled', v)
def lod(v): setk('LevelOfDetail', 'levelOfDetail', v)
# --- the BASE
aa('TAA'); shadows('true', 2048, 'true', '1.5'); lod('0.25'); up('None'); clouds('true')
for g in ('Fog', 'Volumetrics', 'SSAO', 'SSR'): setk(g, 'enabled', 'true')
top('vSync', 'false')
def w(x): want.append(x)
ATOMS = {
  'sh-low': lambda: (shadows('true', 1024, 'false', '2'), w('"directionalShadowResolution": 1024')),
  'sh-high': lambda: (shadows('true', 4096, 'true', '1'), w('"directionalShadowResolution": 4096')),
  'sh-off': lambda: setk('Shadows', 'enabled', 'false'),
  'aa-none': lambda: (aa('None'), w('"antiAliasingMethod": "None"')),
  'aa-fxaa': lambda: (aa('FXAA'), w('"antiAliasingMethod": "FXAA"')),
  'aa-smaa-high': lambda: (aa('SMAA'), w('"antiAliasingMethod": "SMAA"')),
  'aa-smaa-low': lambda: (aa('SMAA', 'Low'), w('"antiAliasingMethod": "SMAA"'), w('"smaaQuality": "Low"')),
  # at its default (FSR 3 at Quality) the game wrote no upscaler key (seen 2026-11-25): no read-back for these
  'fsr3': lambda: up('FSR3'), 'fsr3-uq': lambda: up('FSR3', 'UltraQuality'), 'fsr3-bal': lambda: up('FSR3', 'Balanced'),
  'fsr3-perf': lambda: up('FSR3', 'Performance'), 'fsr4': lambda: up('FSR4'), 'xess3': lambda: up('XeSS3'),
  'lod-035': lambda: (lod('0.35'), w('"levelOfDetail": 0.35')), 'lod-050': lambda: (lod('0.5'), w('"levelOfDetail": 0.5')),
  'lod-100': lambda: (lod('1'), w('"levelOfDetail": 1')),
  'fog-off': lambda: setk('Fog', 'enabled', 'false'), 'vol-off': lambda: setk('Volumetrics', 'enabled', 'false'),
  'ssao-off': lambda: setk('SSAO', 'enabled', 'false'), 'ssr-off': lambda: setk('SSR', 'enabled', 'false'),
  'clouds-off': lambda: clouds('false'),
  'vclouds-off': lambda: setk('Clouds', 'volumetricCloudsEnabled', 'false'),
  'dclouds-off': lambda: setk('Clouds', 'distanceCloudsEnabled', 'false'),
  'drs-off': lambda: setk('DynamicResolutionScale', 'enabled', 'false'),
  'drs-050': lambda: (setk('DynamicResolutionScale', 'enabled', 'true'), setk('DynamicResolutionScale', 'isAdaptive', 'false'),
                      setk('DynamicResolutionScale', 'minScale', '0.5'),
                      setk('DynamicResolutionScale', 'upscaleFilter', '"ContrastAdaptiveSharpen"')),
}
atoms = [] if cell == 'base' else cell.split('+')
for a in atoms:
    if a not in ATOMS: raise SystemExit("unknown cell or atom: " + a)
    ATOMS[a]()
if not any(a.startswith(('aa-',)) for a in atoms): w('"antiAliasingMethod": "TAA"')
if not any(a in ('sh-low', 'sh-high') for a in atoms): w('"directionalShadowResolution": 2048')
if not any(a.startswith('lod-') for a in atoms): w('"levelOfDetail": 0.25')
if not any(a.startswith(('fsr', 'xess')) for a in atoms): w('"upscaler": "None"')
io.open(dst, 'w', encoding='utf-8', newline='').write(s)
print('\n'.join(want))
PY
}

if [ "${DRY:-0}" = 1 ]; then
  D="$(mktemp -d /tmp/settings-dry.XXXXXX)"
  echo "found: $(make_cell describe "$S" /dev/null)"
  for cell in "$@"; do
    echo "=== $cell"; make_cell "$cell" "$S" "$D/$cell.coc" > "$D/$cell.want" || { echo "  make_cell FAILED"; continue; }
    diff "$S" "$D/$cell.coc" | grep '^[<>]' | sed 's/^/  /'; echo "  want after: $(tr '\n' '|' < "$D/$cell.want")"
  done
  [ -n "${DRY_KEEP:-}" ] && { rm -rf "$DRY_KEEP"; mv "$D" "$DRY_KEEP"; } || rm -rf "$D"
  exit 0
fi

# --- preconditions
game_gone && wine_gone || die "the game or something of Wine is running"
pgrep -x steam_osx >/dev/null && die "the macOS Steam is running"
locked && die "the screen is locked"
[ -f "$CS2_WORK/win-resize-driver.exe" ] || die "no win-resize-driver.exe in the workspace (its build line is in scripts/win-resize-driver.c)"
mkdir -p "$LOGD"
BAK="$LOGD/Settings.coc.before"; cp -p "$S" "$BAK" || die "the copy of Settings.coc failed"
SH0=$(shasum -a 256 "$BAK" | cut -c1-64)
for cell in "$@"; do make_cell "$cell" "$BAK" "$LOGD/check.coc" >/dev/null || die "cell $cell cannot be made from this Settings.coc"; done; rm -f "$LOGD/check.coc"
echo "series settings TS $TS, $# cycles, Settings.coc sha $(echo "$SH0" | cut -c1-16), folder $(basename "$LOGD")"
echo "found: $(make_cell describe "$BAK" /dev/null)"

cleanup() {
  wait_gone || echo "  WARNING: the game or Wine still up after 240 s: restoring anyway"
  cp -p "$BAK" "$S"
  [ "$(shasum -a 256 "$S" | cut -c1-64)" = "$SH0" ] && echo "Settings.coc RESTORED (sha256 == before)" || echo "Settings.coc RESTORE FAILED: copy $BAK over it"
  echo "DONE $(date +%H:%M:%S)"
}
trap cleanup EXIT

UN='Screenmanager Resolution Use Native_h1405027254'
native() {
  WINEPREFIX="$SS/prefix" WINEDEBUG=-all "$SS/wine/bin/wine64" reg add 'HKCU\Software\Colossal Order\Cities Skylines II' \
    /v "$UN" /t REG_DWORD /d 1 /f >/dev/null 2>&1
  WINEPREFIX="$SS/prefix" "$SS/wine/bin/wineserver" -w
  grep -q "\"$UN\"=dword:00000001" "$SS/prefix/user.reg" || die "registry: Use Native NOT set"
}

# capture_loop <cell> <t0>: the game's window, at fixed seconds after the scene is loaded
capture_loop() {
  local cell="$1" t0="$2" i t wid n=0 L="$C/Logs/SceneFlow.log" loaded=""
  for i in $(seq 1 150); do
    # the second "Loading completed" of a fresh log is the benchmark's scene (the first comes about 17 s earlier)
    if [ "$(stat -f %m "$L" 2>/dev/null || echo 0)" -gt "$t0" ] && [ "$(grep -c 'Loading completed' "$L")" -ge 2 ]; then loaded=$(date +%s); break; fi
    sleep 2
  done
  [ -n "$loaded" ] || { echo "  capture: no 'Loading completed' seen"; return; }
  for t in ${CAPTURE_AT:-10 30 50 70}; do
    while [ $(( $(date +%s) - loaded )) -lt "$t" ]; do sleep 0.2; done
    wid=$(/tmp/winlist 2>/dev/null | grep -i 'title=Cities' | head -1 | sed -E 's/^id=([0-9]+) .*/\1/')
    [ -n "$wid" ] || { echo "  capture: no game window at +$t s"; continue; }
    screencapture -x -o -l "$wid" "$LOGD/$cell-t$t.png" 2>/dev/null && n=$((n + 1))
  done
  echo "  capture: $n file(s), scene loaded at $(date -r "$loaded" +%H:%M:%S)"
}

FAILS=0; N=0; WIN="${WINDOW:-}"
cycle() {   # <cell>
  local cell="$1" name P Wl ok=1 t0 k miss="" row
  N=$((N + 1)); name="set-$(printf '%02d' "$N")-$cell-$TS"
  echo "=== $name $(date +%H:%M:%S)"
  locked && die "the screen is locked"
  pgrep -x steam_osx >/dev/null && die "the macOS Steam is running"
  wait_gone || die "the game or Wine is still up before $cell"
  native
  make_cell "$cell" "$BAK" "$S" > "$LOGD/$name.want" || die "make_cell failed for $cell"
  cp -p "$S" "$LOGD/$name.Settings.made.coc"
  t0=$(date +%s)
  [ "${CAPTURE:-0}" = 1 ] && { capture_loop "$name" "$t0" & }
  CS2_UPDATE=skip CS2_PROFILE=off bash "$REPO/scripts/perf-bench.sh" "$name" > "$LOGD/$name.log" 2>&1 || ok=0
  wait
  wait_gone || die "the game or Wine is still up after $cell"
  cp -p "$S" "$LOGD/$name.Settings.after.coc" 2>/dev/null
  P=$(ls -t "$RUNDIR/$name"-*Player.log 2>/dev/null | head -1)
  Wl=$(grep -m1 "Window resolution" "$P" 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -1)
  [ -n "$WIN" ] || { WIN="$Wl"; echo "  window of this series: ${WIN:-not found}"; }
  if [ -z "$Wl" ] || [ "$Wl" != "$WIN" ]; then ok=0; echo "  VOID: the window is ${Wl:-not in Player.log}, the series wants ${WIN:-one}"; fi
  while IFS= read -r k; do [ -n "$k" ] && { grep -qF -- "$k" "$S" || miss="$miss [$k]"; }; done < "$LOGD/$name.want"
  [ -z "$miss" ] || { ok=0; echo "  VOID: after the run Settings.coc lacks$miss"; }
  cmp -s "$LOGD/$name.Settings.made.coc" "$S" && echo "  note: the game did not rewrite Settings.coc (the read-back proves nothing)" || echo "  the game rewrote Settings.coc; upscaler now: $(grep -oE '"upscaler(Quality)?": "[A-Za-z0-9]*"' "$S" | tr '\n' ' ' || echo none)"
  grep -q 'graceful=yes' "$LOGD/$name.log" || echo "  note: the exit was not graceful"
  grep -q 'display awake at start: yes' "$LOGD/$name.log" || { ok=0; echo "  VOID: the display was not awake"; }
  grep -q 'screen sharing: yes' "$LOGD/$name.log" && echo "  note: a Screen Sharing viewer was connected: it costs frames (docs/perf-pass-results.md)"
  row=$(grep -F "\"$name\"" "$RUNDIR/results.jsonl" 2>/dev/null | tail -1)
  if [ "$ok" = 1 ] && [ -n "$row" ]; then
    FAILS=0
    printf '%s' "$row" | /usr/bin/python3 -c "import json,sys; r=json.loads(sys.stdin.read()); print('  OK   fps %.2f  gpuMs avg %.2f p95 %.2f  cpuMs avg %.2f  gpuBound %.0f%%  frames %s  graceful %s  %s' % (r['averageFps'], r['gpuMs']['average'], r['gpuMs']['p95'], r['cpuMs']['average'], r['gpuBoundPercent'], r['framesRendered'], r['graceful'], r['gameVersion'].split()[0]))"
  else
    FAILS=$((FAILS + 1)); echo "  VOID cycle ($FAILS in a row)"
    [ "$FAILS" -ge 2 ] && die "two cycles in a row failed: the series stops"
  fi
}

for cell in "$@"; do cycle "$cell"; done
# Each run beside the base runs nearest to it in the series (a line between the one before and the one after):
# the base drifts when something else on the Mac changes, and a setting is read against its neighbours.
echo "=== rows of this series (vs base: against the base runs before and after, when the series has them)"
grep -F -- "-$TS\"" "$RUNDIR/results.jsonl" | /usr/bin/python3 -c "
import json, sys, re
rows = []
for l in sys.stdin:
    r = json.loads(l); m = re.match(r'set-(\d+)-(.+)-\d{8}-\d{6}$', r['cell'])
    if m: rows.append((int(m.group(1)), m.group(2), r))
rows.sort(key=lambda x: x[0])
base = [(n, r['averageFps']) for n, c, r in rows if c == 'base']
def ref(n):
    lo = [b for b in base if b[0] <= n]; hi = [b for b in base if b[0] >= n]
    if not lo and not hi: return None
    if not lo: return hi[0][1]
    if not hi: return lo[-1][1]
    lo, hi = lo[-1], hi[0]
    return lo[1] if lo[0] == hi[0] else lo[1] + (hi[1] - lo[1]) * (n - lo[0]) / (hi[0] - lo[0])
for n, c, r in rows:
    b = ref(n)
    print('%02d %-34s %6.2f fps  gpu %5.2f ms  cpu %5.2f ms  %s' % (n, c, r['averageFps'], r['gpuMs']['average'], r['cpuMs']['average'], '' if b is None else 'vs base %+5.1f%%' % ((r['averageFps'] / b - 1) * 100)))"
