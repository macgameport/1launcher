#!/bin/bash
# load-probe.sh [--attach] [<label>]   how hard does the game work this Mac, and does a frame limit change it?
#
# Two ways to use it:
#   --attach   the game is already running (a colony loaded, by hand): sample it for SECS seconds and leave it
#              running. This is the one that answers a question about heat: run it, change Options > Display >
#              Frame Rate Limit in the game, run it again, compare.
#   (none)     start the game, sample at the main menu, quit it. Measured on the Studio (2026-11-26, five runs):
#              the menu uses about 45 % of one core and leaves the graphics card nearly idle whatever the limit,
#              so this mode shows that the game starts and the limit is accepted, not what a colony costs.
#
# Starts the game through launch-relaunched.sh with Metal's counter on (MTL_HUD_ENABLED=1), waits for the
# main menu, then for SECS seconds (default 60) samples every 5 s: the processor share of the game's
# processes (top, one core = 100) and the graphics card's "Device Utilization %" (ioreg; no password).
# It captures the game's window three times (that window only) so the counter's FPS can be read off, quits
# the game the way licence-wait-probe.sh does (Wine's taskkill without /F), and lets the launcher close Steam.
#
#   MAXFPS=<30|60|120|144|240|Unlimited>   the game's "Frame Rate Limit" for this run
#   VSYNC=<true|false>                     the game's "Vsync" for this run
# Either is written into the Options table of LocalStorage.lua before the start, and the file is put back
# as it was afterwards (sha256-checked). With neither, nothing is written: the run is the Mac as it is.
# The names and the defaults are the game's own, from the source it ships in ModTools/Src:
# CommonLua/OptionsObject.lua (ids "Vsync" and "MaxFps") and Lua/ProjectOptions.lua (Vsync = true,
# MaxFps = "240"). A key that is absent from LocalStorage.lua is at its default.
#
# It refuses while the game or this wrapper's Steam runs, or a launcher lock exists. One Steam on the account
# at a time: close every other one first, on every Mac. A menu is not a colony: this reads the idle load and
# whether the limit takes, not the load of a late game.
# Output: $SM_STATE/runs/load-<label>-<stamp>/ (launcher log, samples.tsv, three PNG captures, summary.txt).
# Captures can show the Steam persona only if Steam's window is up, and it is not: -silent. Keep them out of
# the repository all the same.
set -u
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SM_STATE="${SM_STATE:-$HOME/Library/Application Support/1launcher/surviving-mars-relaunched}"
L="$HERE/launch-relaunched.sh"
ATTACH=0; [ "${1:-}" = --attach ] && { ATTACH=1; shift; }
LABEL="${1:-asis}"; SECS="${SECS:-60}"; MENU_WAIT="${MENU_WAIT:-45}"
# The wrapper as the launcher finds it: by its marker, or SM_WRAPPER (common/wrappers.sh). The launcher's own
# APP= line is set by a function call since wrapper-names, so it cannot be read out of the file.
APP="$(bash "$HERE/../common/wrappers.sh" find game 3215050)" || { echo "REFUSED: no wrapper of the game found"; exit 2; }
SS="$APP/Contents/SharedSupport"
GAME="$SS/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
ENGINE="${SM_ENGINE:-$SS/wine}"
export WINEPREFIX="$SS/prefix" WINEESYNC=1 WINEMSYNC=1 WINEDEBUG=-all
export DYLD_FALLBACK_LIBRARY_PATH="$APP/Contents/Frameworks:$ENGINE/lib:/usr/lib:/usr/local/lib"
WINE="$ENGINE/bin/wine64"
eval "$(grep '^_owns() {' "$L")"
eval "$(sed -n '/^steam_exe_up() {/,/^}/p' "$L")"
eval "$(sed -n '/^game_running() {/,/^}/p' "$L")"
for f in _owns steam_exe_up game_running; do [ "$(type -t $f)" = function ] || { echo "REFUSED: $f not found in the launcher"; exit 2; }; done
ROAM=$(ls -d "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/"Surviving Mars Relaunched" 2>/dev/null | grep -v '/users/\(crossover\|Public\)/' | head -1)
[ -n "$ROAM" ] || ROAM=$(ls -d "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/"Surviving Mars Relaunched" 2>/dev/null | head -1)
GLOGS="$ROAM/logs"; LS="$ROAM/LocalStorage.lua"
[ -d "$GLOGS" ] && [ -f "$LS" ] || { echo "REFUSED: no game data under $WINEPREFIX (start the game once)"; exit 2; }
if [ "$ATTACH" = 1 ]; then
  game_running || { echo "REFUSED: --attach wants the game running: start it, load a colony, then run this"; exit 2; }
  [ -z "${MAXFPS:-}${VSYNC:-}" ] || { echo "REFUSED: with --attach set the limit in the game's Options, not here"; exit 2; }
else
game_running && { echo "REFUSED: the game is running (use --attach to sample it as it is)"; exit 2; }
steam_exe_up && { echo "REFUSED: this wrapper's Steam is running"; exit 2; }
pgrep -x steam_osx >/dev/null && { echo "REFUSED: the macOS Steam is running"; exit 2; }
[ -L "$WINEPREFIX/.launcher.lock" ] && { echo "REFUSED: a launcher lock exists ($(readlink "$WINEPREFIX/.launcher.lock"))"; exit 2; }
fi
case "${MAXFPS:-}" in ""|30|60|120|144|240|Unlimited) ;; *) echo "REFUSED: MAXFPS is one of 30 60 120 144 240 Unlimited"; exit 2 ;; esac
case "${VSYNC:-}" in ""|true|false) ;; *) echo "REFUSED: VSYNC is true or false"; exit 2 ;; esac
# The window lister is built into this account's own temporary folder (mode 700), never /tmp: a program found at
# a path any account can write must not be run. It is used only if it is this account's own plain file.
WLDIR="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"; { [ -d "$WLDIR" ] && [ -O "$WLDIR" ]; } || WLDIR="$SM_STATE/runs"
WL="${WLDIR%/}/1launcher-winlist"
wl_ok() { [ -f "$WL" ] && [ ! -L "$WL" ] && [ -O "$WL" ] && [ -x "$WL" ] && [ "$WL" -nt "$HERE/../cities-skylines-2/scripts/winlist.swift" ]; }
wl_ok || swiftc -O "$HERE/../cities-skylines-2/scripts/winlist.swift" -o "$WL" 2>/dev/null
wl_ok || WL=""
[ -x "$WL" ] || echo "note: no window lister (swiftc missing?): no captures in this run"
OUT="$SM_STATE/runs/load-$LABEL-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"
game_pids() { for _p in $(pgrep -f 'Mars\.exe' 2>/dev/null); do case "$(ps -o command= -p "$_p" 2>/dev/null)" in "$GAME/Mars.exe"*) echo "$_p" ;; esac; done; }
gpu_util() { ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep -oE '"Device Utilization %"=[0-9]+' | head -1 | cut -d= -f2; }
cpu_of() {   # the summed share of the given pids over two seconds (top's second sample), one core = 100
  local args="" p; for p in "$@"; do args="$args -pid $p"; done
  [ -n "$args" ] || { echo 0; return; }
  top -l 2 -s 2 $args -stats pid,cpu 2>/dev/null | awk '/^PID/ { n++; next } n == 2 && $1 ~ /^[0-9]+$/ { s += $2 } END { printf "%.0f\n", s }'
}

cp -p "$LS" "$OUT/LocalStorage.lua.before" || { echo "REFUSED: cannot copy LocalStorage.lua"; exit 2; }
SH0=$(shasum -a 256 "$LS" | cut -c1-64)
restore() {
  for _ in $(seq 1 60); do game_running || steam_exe_up || break; sleep 2; done
  cp -p "$OUT/LocalStorage.lua.before" "$LS"
  [ "$(shasum -a 256 "$LS" | cut -c1-64)" = "$SH0" ] && echo "LocalStorage.lua put back (sha256 as before)" || echo "LocalStorage.lua NOT put back: copy $OUT/LocalStorage.lua.before over it"
}
[ "$ATTACH" = 1 ] || trap restore EXIT
if [ -n "${MAXFPS:-}${VSYNC:-}" ]; then
  /usr/bin/python3 - "$LS" "${MAXFPS:-}" "${VSYNC:-}" <<'PY' || { echo "REFUSED: LocalStorage.lua has no Options table this script knows"; exit 2; }
import sys, io, re
p, maxfps, vsync = sys.argv[1:4]
s = io.open(p, encoding='utf-8', newline='').read()
m = re.search(r'(?m)^\tOptions = \{\r?\n', s)
if not m: raise SystemExit(1)
nl = '\r\n' if m.group(0).endswith('\r\n') else '\n'
add = ''
for key, val in (('MaxFps', '"%s"' % maxfps if maxfps else ''), ('Vsync', vsync)):
    if not val: continue
    s = re.sub(r'(?m)^\t\t%s = [^\n]*\n' % key, '', s)      # one already saved: this run's value replaces it
    add += '\t\t%s = %s,%s' % (key, val, nl)
m = re.search(r'(?m)^\tOptions = \{\r?\n', s)
io.open(p, 'w', encoding='utf-8', newline='').write(s[:m.end()] + add + s[m.end():])
PY
fi
echo "load probe '$LABEL', $(date '+%Y-%m-%d %H:%M'), $(sw_vers -productVersion), MAXFPS=${MAXFPS:-as saved} VSYNC=${VSYNC:-as saved}, output $OUT"
echo "saved before this run: $(grep -E '^\t\t(MaxFps|Vsync|Resolution|Upscaling|VideoPreset|FullscreenMode) = ' "$OUT/LocalStorage.lua.before" | tr -d '\t' | tr '\n' ' ')"
grep -qE '^\t\t(MaxFps|Vsync) = ' "$OUT/LocalStorage.lua.before" || echo "  (no MaxFps and no Vsync saved: the game's defaults, limit 240 and Vsync on)"

# The display is part of the measurement: with the panel asleep the graphics card idles (2 to 4 % against 34 %,
# Studio, 2026-11-26) and a capture fails. Wake it, hold it awake for as long as this script lives, record it.
caffeinate -u -t 5 > /dev/null 2>&1 &
caffeinate -dis -w $$ > /dev/null 2>&1 &
sleep 3
main_awake() { "$WL" --displays 2>/dev/null | grep -q 'main=1 .*asleep=0'; }
AWAKE0=unknown; [ -x "$WL" ] && { AWAKE0=no; main_awake && AWAKE0=yes; }
if [ "$ATTACH" = 1 ]; then
  echo "saved now: $(grep -E '^\t\t(MaxFps|Vsync) = ' "$LS" | tr -d '\t' | tr '\n' ' ')(a key that is absent is at its default: limit 240, Vsync on; the game writes the file when Options are applied)"
  LP=""; glog=$(ls -t "$GLOGS"/Mars.exe-*.log 2>/dev/null | head -1); MENU_WAIT=0
else
prev=$(ls -t "$GLOGS"/Mars.exe-*.log 2>/dev/null | head -1)
MTL_HUD_ENABLED=1 SM_UPDATE=skip L1_SIGNIN_SECS=120 bash "$L" > "$OUT/launcher.log" 2>&1 < /dev/null &
LP=$!
glog=""
for _ in $(seq 1 150); do
  g=$(ls -t "$GLOGS"/Mars.exe-*.log 2>/dev/null | head -1)
  [ -n "$g" ] && [ "$g" != "$prev" ] && { glog="$g"; break; }
  kill -0 "$LP" 2>/dev/null || break
  sleep 2
done
if [ -z "$glog" ]; then
  echo "FAIL: the game did not start: $(grep -m1 'ERROR' "$OUT/launcher.log" | cut -c1-120)"; wait "$LP"; exit 1
fi
echo "game started $(date +%H:%M:%S); waiting $MENU_WAIT s for the menu"
sleep "$MENU_WAIT"
fi
printf 'time\tgame_cpu\tgpu_util\n' > "$OUT/samples.tsv"
n=0; shots=0
while [ $((n * 5)) -lt "$SECS" ] && game_running; do
  n=$((n + 1))
  c=$(cpu_of $(game_pids)); u=$(gpu_util)          # cpu_of takes two seconds
  printf '%s\t%s\t%s\n' "$(date +%H:%M:%S)" "$c" "${u:-?}" >> "$OUT/samples.tsv"
  if [ -x "$WL" ] && [ $((n % 4)) = 2 ] && [ "$shots" -lt 3 ]; then
    wid=$("$WL" 2>/dev/null | grep -E 'owner=wine' | grep -iE 'title=.*Mars' | head -1 | sed -E 's/^id=([0-9]+) .*/\1/')
    [ -n "$wid" ] && screencapture -x -o -l "$wid" "$OUT/window-$n.png" 2>/dev/null && shots=$((shots + 1))
  fi
  sleep 3
done
[ -x "$WL" ] && "$WL" 2>/dev/null | grep -E 'owner=wine' | cut -c1-140 > "$OUT/windows.txt"
AWAKE1=unknown; [ -x "$WL" ] && { AWAKE1=no; main_awake && AWAKE1=yes; }
alive=no; game_running && alive=yes
lrc="-"
if [ "$ATTACH" = 1 ]; then :; elif game_running; then
  "$WINE" taskkill /IM Mars.exe >/dev/null 2>&1
  for _ in $(seq 1 20); do game_running || break; sleep 1; done
  game_running && { echo "  taskkill did not close the game; SIGTERM to $(game_pids | tr '\n' ' ')"; kill $(game_pids) 2>/dev/null; }
fi
[ "$ATTACH" = 1 ] || { wait "$LP"; lrc=$?; cp "$glog" "$OUT/game.log" 2>/dev/null; }
{
  echo "label $LABEL  MAXFPS=${MAXFPS:-as saved}  VSYNC=${VSYNC:-as saved}  samples $n  captures $shots  game alive at the end of sampling: $alive  launcher rc $lrc"
  echo "main display awake: at the start $AWAKE0, at the end $AWAKE1"
  { [ "$AWAKE0" = no ] || [ "$AWAKE1" = no ]; } && echo "VOID as a measurement: the main display was asleep"
  awk -F'\t' 'NR > 1 && $2 ~ /^[0-9]+$/ { c += $2; k++; if ($3 ~ /^[0-9]+$/) { g += $3; j++ } } END { if (k) printf "game processor share: mean %.0f %% of one core (%d samples)\ngraphics card utilisation: mean %.0f %% (%d samples)\n", c / k, k, (j ? g / j : 0), j }' "$OUT/samples.tsv"
  echo "the counter's FPS: read it off window-*.png (top right of the game's window; with --attach it is there only if the game was started with MTL_HUD_ENABLED=1)"
} | tee "$OUT/summary.txt"
