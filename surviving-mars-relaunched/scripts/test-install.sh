#!/bin/bash
# test-install.sh -- scripts/install.sh on the shared core (docs/plans/surviving-mars-install.md, 2.4, MT3).
# The installer and common/install-core.sh run from a scratch copy of the repository with HOME and TMPDIR at
# a scratch folder. setup.sh, common/make-wrapper.sh, tools/fetch-d3dmetal.sh and tools/make-engine.sh are
# stubs there that write to one record of calls; curl, xcode-select, nm, caffeinate, softwareupdate, pgrep,
# ps, lsof, sleep, sysctl, sw_vers and arch are stubs on PATH; a fixture wrapper's wine64 and wineserver are
# stubs too. Processes are lines in a file the pgrep, ps and lsof stubs read, and the stub sleep moves the
# world on. No network, no Wine, no Steam, nothing outside the scratch folder.
# The fixture maker makes a wrapper whose framework reads 2.1, 3.0, another version, or is absent.
#   bash scripts/test-install.sh            exit 0 = every case passed
#   MUTANT=<n> bash scripts/test-install.sh   each must exit 1; 2 = the mutant did not apply
#     1 step 4 skipped at 2.1                    2 step 4 after Steam
#     3 the comparison after the swap removed    4 the question's refusal removed
#     5 the question asked when both steps are done   6 the lock taken after step 4
#     7 a swap stopped part way left as it is    8 the other game's manifest accepted
#     9 --check fetching                        10 setup run with the game absent
#    11 the stop before step 7 not comparing (setup run with another wrapper given)
#                                               12 WINEMSYNC dropped from the exports
#    13 the version pattern made 3.0             14 SM_VIA_INSTALLER not passed to setup
#    15 --rebuild never passed                   16 the wait for Wine to let go removed
#    17 game_cleanup's removal taken out         18 game_cleanup not called by the core
#    19 an EXIT trap of the game's own           20 L1_WRAPPER_GIVEN decided after the core's export
#    21 WINE left out of game_env                22 ENGINE taken from SM_ENGINE
#    23 GAME taken from the resolved path        24 the swap finished under --check
#    25 the lock's holder not looked at before the finish
#    26 the finish made only when wine64 is gone 27 a refused finish passed on to the core's test
#    28 the closing line put back after a Mac check that exits 3 (docs/plans/first-run-findings.md, 2.8, FT5)
#    29 the closing line dropped after the refusal of Rosetta too
#    30 the stop before step 7 put back to "whenever SM_WRAPPER is given" (docs/plans/wrapper-names.md, WT11 (e))
#    31 game_wrapper not asking the resolver's incomplete (WT11 (f))
#    32 the marking option dropped in the core (WT10 (b))
#    33 core_after_setup removed at this installer's call, setup's exit code kept (WT11 (c))
#    34 setup's unset of SM_WRAPPER removed (WT11 (b))       35 --holders-skip not passed by setup (WT11 (g))
#    (36 to 38: docs/plans/built-in-update.md, U0, UT2: the free-space caution.)
#    39 the own-files loop for common/paths.sh, updates.sh and games.tsv dropped (built-in-update 3.3; UT5, also)
#    The update, its parts joined (built-in-update 3.4; UT7b):
#    40 l1u_stamp not called by setup            41 the driver's test of a stamp's line turned round
#    The install's lock, taken by the core (docs/plans/launcher-first-install.md, 3.8; LFT13):
#    42 the lock not taken                       43 the game file not written
#    An install from 14unch3r, its parts joined (the same plan, 3.8; LFT8):
#    44 the written file made to run update      45 the lock left behind (in the fetched tree's core)
#    46 the setup's launcher stamp dropped
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
LAUNCHER="$HERE/launch-relaunched.sh"
T="$(mktemp -d /tmp/sm-install-test.XXXX)"; T="$(cd "$T" && pwd -P)"   # resolved: the core resolves the wrapper's path
HOLD=""
trap '[ -n "$HOLD" ] && kill "$HOLD" 2>/dev/null; rm -rf "$T"' EXIT
M="${MUTANT:-0}"
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

R="$T/repo"; G="$R/surviving-mars-relaunched"
mkdir -p "$R/common" "$G/scripts" "$G/tools" "$T/bin" "$T/st" "$T/home/Applications" "$T/tmp"
S="$G/scripts/install.sh"; CORE="$R/common/install-core.sh"
cp "$HERE/scripts/install.sh" "$S"; cp "$REPO/common/install-core.sh" "$CORE"
: > "$G/launch-relaunched.sh"; : > "$G/make-app.sh"; : > "$G/tools/frame-fix.exe"; : > "$R/common/make-launcher-app.sh"
cp "$REPO/common/wrappers.sh" "$R/common/wrappers.sh"; : > "$R/common/move-wrappers.sh"   # the resolver, real; the mover, setup's
cp "$REPO/common/tools.sh" "$R/common/tools.sh"   # the ask and the wait for Apple's tools, real: the core reads it (docs/plans/launcher-first-install.md, 3.2)
cp "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$R/common/"; : > "$R/common/games.tsv"   # setup's record of versions (docs/plans/built-in-update.md, 3.3); the two are real: the core reads the record's folder and the lock's rule from them (docs/plans/launcher-first-install.md, 3.8)

py() { python3 -I - "$@"; }
case "$M" in
  0) ;;
  1) sed -i '' 's|^if d3dm_ok "\$SS/wine"; then say "OK: D3DMetal \$D3DM_VER"$|if d3dm_ver "$SS/wine"; then say "OK: D3DMetal $D3DM_VER"|' "$S" ;;
  2) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
assert s.count("\ncore_steam 5\n") == 1 and s.count("\ncore_lock\n") == 1
s = s.replace("\ncore_steam 5\n", "\n").replace("\ncore_lock\n", "\ncore_lock\ncore_steam 5\n")
open(p, "w").write(s)
PY
     ;;
  3) sed -i '' 's|^    cmp -s "\$SM_TMP/pieces/lib/\$f" "\$SS/wine/lib/\$f" \|\| |    true \|\| |' "$S" ;;
  4) sed -i '' 's|^      \*) say "Nothing of Apple'"'"'s was fetched\. To go on later, open the installer again\."; exit 3 ;;$|      *) ;;|' "$S" ;;
  5) sed -i '' 's|^if \[ ! -d "\$W" \] \|\| ! d3dm_ok "\$W/Contents/SharedSupport/wine"; then$|if true; then|' "$S" ;;
  6) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
assert s.count("\ncore_lock\n") == 1 and s.count("\ncore_steam 5\n") == 1
s = s.replace("\ncore_lock\n", "\n").replace("\ncore_steam 5\n", "\ncore_lock\ncore_steam 5\n")
open(p, "w").write(s)
PY
     ;;
  7) sed -i '' 's|^swap_waiting "\$W" \|\| return 0$|return 0|' "$S" ;;
  8) sed -i '' 's|^GAME_APPID=3215050$|GAME_APPID=949230|' "$S" ;;
  9) sed -i '' 's|^elif \[ "\$CHECK" = 1 \]; then say "D3DMetal \$D3DM_VER: version 3\.0 would be fetched|elif false; then say "D3DMetal $D3DM_VER: version 3.0 would be fetched|' "$S" ;;
  10) sed -i '' 's|^core_game 6$|: core_game 6|' "$S" ;;
  11) sed -i '' 's|^  if \[ "\$_app_w" != "\$W" \]; then$|  if false; then|' "$S" ;;
  12) sed -i '' 's|^export WINEESYNC=1 WINEMSYNC=1 D3DMETAL=1 |export WINEESYNC=1 D3DMETAL=1 |' "$S" ;;
  13) sed -i '' 's|^  \[3-9\]\.\*) ;;$|  3.0) ;;|' "$S" ;;
  14) sed -i '' 's|^SM_VIA_INSTALLER=1 bash "\$SETUP" "\$@"$|bash "$SETUP" "$@"|' "$S" ;;
  15) sed -i '' '/^  \[ -e "\$SS\/wine\.d3dm21-BAK" \] && set -- "\$@" --rebuild$/d' "$S" ;;
  16) sed -i '' 's|^    \[ -z "\$held" \] \&\& break$|    break|' "$S" ;;
  17) sed -i '' 's|^game_cleanup() { \[ -n "\${SM_TMP:-}" \] \&\& rm -rf "\$SM_TMP"; return 0; }|game_cleanup() { return 0; }|' "$S" ;;
  18) sed -i '' '/^  declare -F game_cleanup > \/dev\/null && game_cleanup$/d' "$CORE" ;;
  19) sed -i '' 's|^core_begin$|trap '"'"'rm -rf "$SM_TMP"'"'"' EXIT; core_begin|' "$S" ;;
  20) py "$CORE" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'if [ -n "${!WRAPPER_VAR:-}" ]; then L1_WRAPPER_GIVEN=1; else L1_WRAPPER_GIVEN=0; fi\nexport L1_WRAPPER_GIVEN\n'
b = '  use_wrapper "$W"\n  LOCK="$WINEPREFIX/.launcher.lock"\n'
assert s.count(a) == 1 and s.count(b) == 1
s = s.replace(a, "").replace(b, b + a)
open(p, "w").write(s)
PY
     ;;
  21) sed -i '' '/^WINE="\$ENGINE\/bin\/wine64"$/d' "$S" ;;
  22) sed -i '' 's|^  ENGINE="\$SS/wine"$|  ENGINE="${SM_ENGINE:-$SS/wine}"|' "$S" ;;
  23) sed -i '' 's|^  GAME="\$SPELLED/Contents/SharedSupport/prefix/|  GAME="$APP/Contents/SharedSupport/prefix/|' "$S" ;;
  24) sed -i '' 's|^if \[ "\$CHECK" = 1 \]; then$|if false; then|' "$S" ;;
  25) sed -i '' 's|^if \[ -n "\$_h" \] \&\& \[ "\$_h" != "\$\$" \] \&\& kill -0 "\$_h" 2>/dev/null; then$|if false; then|' "$S" ;;
  26) sed -i '' 's|^swap_waiting "\$W" \|\| return 0$|{ swap_waiting "$W" \&\& ! wine_whole "$W"; } \|\| return 0|' "$S" ;;
  27) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'Quit whatever uses this wrapper, then open the installer again."\n  exit 3\n'
assert s.count(a) == 1
open(p, "w").write(s.replace(a, a.replace("  exit 3\n", "  return 0\n")))
PY
     ;;
  28) sed -i '' '/^  \[ "\$rc" = 3 \] && END=quiet /d' "$CORE" ;;
  29) sed -i '' 's|softwareupdate --install-rosetta --agree-to-license"; exit 3 ;;$|softwareupdate --install-rosetta --agree-to-license"; END=quiet; exit 3 ;;|' "$CORE" ;;
  30) sed -i '' 's|^  if \[ "\$_app_w" != "\$W" \]; then$|  if true; then|' "$S" ;;
  31) sed -i '' 's|W="\$(l1w_incomplete game "\$GAME_APPID")" \|\| W=|W=|' "$S" ;;
  32) sed -i '' 's| --mark game "\$GAME_APPID"||g' "$CORE" ;;
  33) sed -i '' 's|^core_after_setup \$?$|(exit $?)|' "$S" ;;
  34|35|40|41|44|45|46) ;;   # applied below, to the real setup.sh of the WT11 copy (41: to the driver beside it; 44 to 46: to that copy's files, for LFT8)
  # UT2 (docs/plans/built-in-update.md, U0): 36 silent for a finished install only; 37 silent for a game that is
  # only partly there too; 38 the wrapper not asked for first
  36) sed -i '' 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#if prefix_known; then case "$(game_state)" in installed) return 0 ;; esac; fi#' "$CORE" ;;
  37) sed -i '' 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#if prefix_known; then case "$(game_state)" in installed|update|partial) return 0 ;; esac; fi#' "$CORE" ;;
  38) sed -i '' 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#case "$(game_state)" in installed|update) return 0 ;; esac#' "$CORE" ;;
  39) sed -i '' 's|^for f in "\$GAME_ROOT/\.\./common/paths\.sh" "\$GAME_ROOT/\.\./common/updates\.sh" .*|for f in; do|' "$S" ;;
  42) sed -i '' 's|^\[ "\$CHECK" = 0 \] \&\& install_lock .*|: no lock|' "$CORE" ;;
  43) py "$CORE" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = "  printf '%s\\n' \"$GAME_APPID\" > "
assert s.count(a) == 1
i = s.index(a); j = s.index("\n", s.index("\n", i) + 1) + 1
s = s[:i] + "  : the game file is not written\n" + s[j:]
open(p, "w").write(s)
PY
     ;;
  *) echo "REFUSED: no mutant $M"; exit 2 ;;
esac
if [ "$M" != 0 ]; then
  case "$M" in 34|35|40|41|44|45|46) ;; *) cmp -s "$HERE/scripts/install.sh" "$S" && cmp -s "$REPO/common/install-core.sh" "$CORE" && { echo "REFUSED: mutant $M did not apply"; exit 2; } ;; esac
  bash -n "$S" && bash -n "$CORE" || { echo "REFUSED: mutant $M does not parse"; exit 2; }
fi

# --- the fixture maker
export ST="$T/st" CALLS="$T/calls" HOME="$T/home" TMPDIR="$T/tmp"
unset L1_UPDATE_DIR L1_UPDATE_NOW L1_FETCHED_REF L1_FETCHED_COMMIT L1_DATA_ROOT   # the record of versions is the cases' own
plist() {   # <wine folder> <version>
  mkdir -p "$1/lib/external/D3DMetal.framework/Versions/A/Resources"
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>CFBundleShortVersionString</key><string>%s</string></dict></plist>\n' "$2" \
    > "$1/lib/external/D3DMetal.framework/Versions/A/Resources/Info.plist"
}
mkwine() {   # <wine folder> <version, or none> [<tag for its wine64's record>]
  mkdir -p "$1/bin" "$1/lib/external" "$1/lib/wine/x86_64-windows"
  cat > "$1/bin/wine64" << X
#!/bin/sh
echo "${3:-WINE64} \$*" >> "\$CALLS"
case "\$*" in *SteamSetup.exe*) d="\$WINEPREFIX/drive_c/Program Files (x86)/Steam"; mkdir -p "\$d"; : > "\$d/steam.exe" ;; esac
exit 0
X
  printf '#!/bin/sh\necho "WINESERVER $*" >> "$CALLS"\n' > "$1/bin/wineserver"
  chmod +x "$1/bin/wine64" "$1/bin/wineserver"
  [ "$2" = none ] || plist "$1" "$2"
  for f in external/libd3dshared.dylib wine/x86_64-windows/atidxx64.dll wine/x86_64-windows/d3d11.dll \
           wine/x86_64-windows/d3d12.dll wine/x86_64-windows/dxgi.dll; do echo "v$2 $f" > "$1/lib/$f"; done
}
mkwrap() {   # <wrapper> <version, or none> [steam] [game] [othergame] [mark]: mark writes common/wrappers.sh's marker
  local s="$1/Contents/SharedSupport" sd
  mkdir -p "$s/prefix/drive_c" "$1/Contents/Frameworks"; mkwine "$s/wine" "$2"
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>\n' > "$1/Contents/Info.plist"
  case " $* " in *" mark "*) plutil -replace L1Role -string game-wrapper "$1/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 3215050 "$1/Contents/Info.plist" ;; esac
  chmod 755 "$1"
  sd="$s/prefix/drive_c/Program Files (x86)/Steam"
  case " $* " in *" steam "*) mkdir -p "$sd"; : > "$sd/steam.exe" ;; esac
  case " $* " in *" game "*) mkdir -p "$sd/steamapps/common/Project Spark"; : > "$sd/steamapps/common/Project Spark/Mars.exe"
    printf '"AppState"\n{\n\t"appid"\t\t"3215050"\n\t"StateFlags"\t\t"4"\n}\n' > "$sd/steamapps/appmanifest_3215050.acf" ;; esac
  case " $* " in *" othergame "*) mkdir -p "$sd/steamapps/common/Project Spark"; : > "$sd/steamapps/common/Project Spark/Mars.exe"
    printf '"AppState"\n{\n\t"appid"\t\t"949230"\n\t"StateFlags"\t\t"4"\n}\n' > "$sd/steamapps/appmanifest_949230.acf" ;; esac
}
export -f plist mkwine mkwrap
lockof() { readlink "$1/Contents/SharedSupport/prefix/.launcher.lock" 2>/dev/null; }
ver() { plutil -extract CFBundleShortVersionString raw "$1/lib/external/D3DMetal.framework/Versions/A/Resources/Info.plist" 2>/dev/null || echo none; }

# --- the stubs in the repository copy
cat > "$G/scripts/setup.sh" << 'X'
#!/bin/bash
case " $* " in *" --mac-only "*) [ -n "${STUB_MAC_WORDS:-}" ] && echo "  $STUB_MAC_WORDS"; exit "${STUB_MAC_RC:-0}" ;; esac
w="${SM_WRAPPER:-/none}"
echo "SETUP $* via=${SM_VIA_INSTALLER:-} lock=$(readlink "$w/Contents/SharedSupport/prefix/.launcher.lock" 2>/dev/null) ppid=$PPID given=${L1_WRAPPER_GIVEN-unset}" >> "$CALLS"
# the install's lock as this stand-in finds it (LFT13): the installer is its parent process
_u="$(bash "$(dirname "$0")/../../common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"; _h="$(readlink "$_u/installing" 2>/dev/null)"; [ "$_h" = "$PPID" ] && _h=mine
echo "LOCKATSETUP ${_h:-none} $(cat "$_u/installing-game" 2>/dev/null || echo none)" >> "$CALLS"
exit "${STUB_SETUP_RC:-0}"
X
cat > "$R/common/make-wrapper.sh" << 'X'
#!/bin/bash
echo "MAKE-WRAPPER $*" >> "$CALLS"
case " $* " in *" --check "*) echo "  would make the wrapper (stub)"; exit 0 ;; esac
m=""; case " $* " in *" --mark game 3215050 "*) m=mark ;; esac
while [ $# -gt 0 ]; do [ "$1" = --wrapper ] && W="$2"; shift; done
mkwrap "$W" 2.1 ${STUB_NEW_WRAPPER-steam game} $m
X
cat > "$G/tools/fetch-d3dmetal.sh" << 'X'
#!/bin/bash
echo "FETCH $* lock=$(readlink "${SM_WRAPPER:-/none}/Contents/SharedSupport/prefix/.launcher.lock" 2>/dev/null) ppid=$PPID" >> "$CALLS"
mkdir -p "$2"; mkwine "$2/x" 3.0; mv "$2/x/lib" "$2/lib"; rm -rf "$2/x"; echo "  fetched (stub)"; echo "$2/lib"
X
cat > "$G/tools/make-engine.sh" << 'X'
#!/bin/bash
s="$2/Contents/SharedSupport"
echo "MAKE-ENGINE $* CX_GPTK=${CX_GPTK-unset} lock=$(readlink "$s/prefix/.launcher.lock" 2>/dev/null) ppid=$PPID" >> "$CALLS"
if [ -d "$s/wine.new" ] && [ -e "$s/wine.d3dm21-BAK" ]; then   # a swap stopped part way
  [ -n "${STUB_FINISH_REFUSED:-}" ] && { echo "ERROR: a Wine process (pid 77) is using $2; quit it first"; exit 1; }
  rm -rf "$s/wine"; mv "$s/wine.new" "$s/wine"; echo "finished    : $s/wine (an engine swap that was stopped part way)"
  [ "${3:-}" = --rebuild ] || exit 0
fi
echo "source Wine : $s/wine (stub)"; echo "D3DMetal    : $CX_GPTK (3.0)"; echo "some other line"
[ -n "${STUB_ENGINE_FAILS:-}" ] && { echo "ERROR: stub failure"; exit 1; }
if [ -e "$s/wine.d3dm21-BAK" ]; then rm -rf "$s/wine"; else mv "$s/wine" "$s/wine.d3dm21-BAK"; fi
mkwine "$s/wine" 3.0
[ -n "${STUB_ENGINE_WRONG:-}" ] && echo tampered > "$s/wine/lib/wine/x86_64-windows/d3d12.dll"
exit 0
X
# --- the stubs on PATH
stub() { printf '#!/bin/bash\n%s\n' "$2" > "$T/bin/$1"; chmod +x "$T/bin/$1"; }
stub curl 'echo "CURL $*" >> "$CALLS"; [ -n "${STUB_CURL_FILE:-}" ] || exit 7; while [ $# -gt 0 ]; do [ "$1" = -o ] && out="$2"; shift; done; cp "$STUB_CURL_FILE" "$out"'
stub softwareupdate 'echo "SOFTWAREUPDATE $*" >> "$CALLS"'
stub xcode-select 'echo "XCODE-SELECT $*" >> "$CALLS"; exit 0'
stub caffeinate 'exit 0'
stub nm 'echo "NM $*" >> "$CALLS"; exit 0'
stub osascript 'exit 0'
# the stub sleep moves the world on: after STUB_RELEASE_AT sleeps, whatever held the wrapper is gone
stub sleep 'n=$(cat "$ST/sleeps" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$ST/sleeps"; [ -n "${STUB_RELEASE_AT:-}" ] && [ "$n" -ge "$STUB_RELEASE_AT" ] && rm -f "$ST/procs" "$ST"/lsof.*; exit 0'
# pgrep -f [-i] <pattern>: the process numbers of the lines the pattern matches, as the real one would
stub pgrep 'i=""; pat=""; for a in "$@"; do [ "$a" = -i ] && i=-i; pat="$a"; done; grep -E $i -- "$pat" "$ST/procs" 2>/dev/null | cut -d" " -f1; exit 0'
stub ps 'p=""; for a in "$@"; do p="$a"; done; sed -n "s/^$p //p" "$ST/procs" 2>/dev/null'
stub lsof 'p=""; for a in "$@"; do p="$a"; done; cat "$ST/lsof.$p" 2>/dev/null'
stub sysctl 'echo 1'
stub sw_vers 'echo 27.2.1'
stub df 'echo "Filesystem 1024-blocks Used Available Capacity Mounted"; echo "/dev/x 999999999 1 ${STUB_DF_KB:-999999999} 1% /"'
stub arch 'exit 0'
export PATH="$T/bin:$PATH"

run() {   # [VAR=value ...] -- <args>: the installer's exit code; its output in $T/out, the record in $CALLS
  local envs=()
  while [ "$1" != -- ]; do envs+=("$1"); shift; done; shift
  : > "$CALLS"; rm -f "$ST/sleeps"
  env ${envs[@]+"${envs[@]}"} /bin/bash "$S" "$@" < /dev/null > "$T/out" 2>&1
  echo $?
}
world() { rm -f "$ST/procs" "$ST"/lsof.*; }   # no process holds anything
c() { grep -c -- "$1" "$CALLS"; }
o() { grep -c -- "$1" "$T/out"; }
snap() { (cd "$HOME" && find . | LC_ALL=C sort | shasum | cut -c1-12); }
tmpleft() { ls -A "$TMPDIR" | wc -l | tr -d ' '; }
D="$HOME/Applications/$(bash "$REPO/common/wrappers.sh" name game 3215050)"; DS="$D/Contents/SharedSupport"   # the name the installer gives
fresh() { rm -rf "$D"; world; mkwrap "$D" "$@" mark; }   # the installer's own wrapper anew, marked as make-wrapper.sh --mark marks it

# --- nothing there: --check, nobody to ask, the whole install
before=$(snap); rc=$(run -- --check)
check "--check with no wrapper: exit 0, steps 4 to 7 named" "$rc:$(grep -c '^Step [4567] of 7' "$T/out")" "0:4"
check "  ...it says it would ask, and asks nothing" "$(o 'would ask before fetching'):$(o 'type y')" "1:0"
check "  ...it fetches and changes nothing" "$(c '^FETCH'):$(c '^MAKE-ENGINE'):$(c '^MAKE-WRAPPER .*--check'):$([ "$(snap)" = "$before" ] && echo same)" "0:0:1:same"
# UT2 (docs/plans/built-in-update.md, U0): the free-space caution is for an install that still has to download
rc=$(run STUB_DF_KB=5000000 -- --check)
check "low space and no wrapper yet: the CAUTION, and no unbound variable" "$rc:$(o 'CAUTION: 4 GB free'):$(o 'unbound variable')" "0:1:0"
rc=$(run --)
check "nobody to ask: exit 3, and nothing is made or fetched" "$rc:$(o "Nothing of Apple's was fetched"):$(c '^MAKE-WRAPPER'):$(c '^FETCH')" "3:1:0:0"
rc=$(run -- --yes)
check "--yes from nothing: exit 0" "$rc" 0
check "  ...the question's words were shown: Apple's D3DMetal, both versions, where the licence is" "$(o "Apple's D3DMetal, a part of Apple's Game Porting Toolkit"):$(o 'https://github.com/Gcenx/game-porting-toolkit/releases/tag/Game-Porting-Toolkit-3.0-3')" "1:1"
check "  ...the order: Apple's tools, the wrapper, the fetch, the engine, setup" "$(grep -oE '^(NM|MAKE-WRAPPER|FETCH|MAKE-ENGINE|SETUP)' "$CALLS" | tr '\n' ' ')" "NM MAKE-WRAPPER FETCH MAKE-ENGINE SETUP "
check "  ...the wrapper is made with this game's engine pin" "$(c '^MAKE-WRAPPER --engine-url https://github.com/vitor251093/porting-kit-engines/releases/download/wineskin/WS12WineSikarugir10.0_2_D3DMetal-v2.1.tar.7z --engine-bytes 183963888 --engine-sha a2f9322f3e6160453d9b31891e91d17a7c1f0b752c1804416880792c37d125d2 --wrapper ')" 1
check "  ...the lock is held at the fetch, by the installer" "$(grep -c '^FETCH.* lock=\([0-9][0-9]*\) ppid=\1$' "$CALLS")" 1
check "  ...and at the engine swap" "$(grep -c '^MAKE-ENGINE.* lock=\([0-9][0-9]*\) ppid=\1$' "$CALLS")" 1
check "  ...the engine is given the temporary folder's pieces, and no --rebuild" "$(grep -c "^MAKE-ENGINE --install $D CX_GPTK=$TMPDIR/1launcher-d3dmetal\.[A-Za-z0-9]*/pieces/lib " "$CALLS")" 1
check "  ...setup is run by the installer, which holds the lock, with SM_VIA_INSTALLER=1, told no wrapper was given" "$(grep -c '^SETUP --yes via=1 lock=\([0-9][0-9]*\) ppid=\1 given=0$' "$CALLS")" 1
check "  ...the wrapper was made with the resolver's name, and marked" "$(c "^MAKE-WRAPPER .* --wrapper $D --mark game 3215050\$")" 1
check "  ...the engine script's two lines are shown, naming the temporary folder, and no other line of it" "$(o '^  source Wine :'):$(grep -c "^  D3DMetal    : $TMPDIR/1launcher-d3dmetal\.[A-Za-z0-9]*/pieces/lib " "$T/out"):$(o 'some other line')" "1:1:0"
check "  ...the temporary folder is gone, and the lock released" "$(tmpleft):$(lockof "$D")" "0:"
check "  ...it ends with the core's closing line" "$(o '^Done\. Start the game from Applications: Surviving Mars Relaunched, or 14unch3r\.$')" 1
check "  ...no line names the other game" "$(grep -c -i -E 'cities|skylines|949230|CS2' "$T/out")" 0
rc=$(run --)
check "everything done, nobody to ask: exit 0, no question, nothing fetched, setup run" "$rc:$(o "Apple's Game Porting Toolkit"):$(c '^FETCH'):$(c '^SETUP')" "0:0:0:1"
rc=$(run -- --yes)
check "  ...--yes reaches setup" "$(c '^SETUP --yes via=1')" 1
# LFT13 (docs/plans/launcher-first-install.md, 3.8): this game's installer takes the one install lock through the core
UD="$(bash "$REPO/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"   # asked of common/paths.sh, never spelled here (common/test-paths.sh, LT14)
ilock() { if [ -e "$UD/installing" ] || [ -L "$UD/installing" ] || [ -e "$UD/installing-game" ]; then echo left; else echo none; fi; }
rc=$(run --)
check "LFT13 the install's lock is this installer's when setup runs, with this game's ID beside it; both are gone afterwards" \
  "$rc:$(grep '^LOCKATSETUP' "$CALLS"):$(ilock)" "0:LOCKATSETUP mine 3215050:none"
/bin/sleep 300 & HOLD=$!
ln -s "$HOLD" "$UD/installing"; rc=$(run --)
check "LFT13 an install of another process running: exit 3 with its sentence and that process, nothing fetched, setup not run" \
  "$rc:$(o "^  !! Another install is running in another Terminal window (process $HOLD)\\. Wait for it to finish, then open the installer again\\.\$"):$(c '^FETCH'):$(c '^SETUP'):$(readlink "$UD/installing")" "3:1:0:0:$HOLD"
rm -f "$UD/installing"; kill "$HOLD" 2>/dev/null; wait "$HOLD" 2>/dev/null; HOLD=""
rc=$(run -- --check)
check "LFT13 under --check no lock is taken" "$rc:$(c '^LOCKATSETUP mine'):$(ilock)" "0:0:none"
ACF="$DS/prefix/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_3215050.acf"
rc=$(run STUB_DF_KB=5000000 -- --check)
check "low space on a finished install: no CAUTION" "$rc:$(o 'CAUTION: ')" "0:0"
sed -i '' 's/"StateFlags"\t\t"4"/"StateFlags"\t\t"6"/' "$ACF"; rc=$(run STUB_DF_KB=5000000 -- --check)
check "low space with a game update waiting (6): no CAUTION" "$rc:$(grep -c '"6"' "$ACF"):$(o 'CAUTION: ')" "0:1:0"
sed -i '' 's/"StateFlags"\t\t"6"/"StateFlags"\t\t"1026"/' "$ACF"; rc=$(run STUB_DF_KB=5000000 -- --check)
check "low space with a download that stopped (1026): the CAUTION" "$rc:$(grep -c '"1026"' "$ACF"):$(o 'CAUTION: 4 GB free')" "0:1:1"
sed -i '' 's/"StateFlags"\t\t"1026"/"StateFlags"\t\t"4"/' "$ACF"
check "  ...the fixture is a finished install again" "$(grep -c '"StateFlags".*"4"' "$ACF")" 1

# --- step 4: skipped at 3 or later, run at 2.1 and with no framework, --rebuild with a BAK
fresh 3.1 steam game
rc=$(run --); check "a framework that reads 3.1: step 4 is skipped" "$rc:$(c '^FETCH'):$(o '^  OK: D3DMetal 3.1$')" "0:0:1"
fresh 2.1 steam game; before=$(snap)
rc=$(run -- --check)
check "--check at 2.1: exit 0, step 4 says what it would do, nothing fetched or changed, no lock" "$rc:$(o 'D3DMetal 2.1: version 3.0 would be fetched'):$(c '^FETCH'):$([ "$(snap)" = "$before" ] && echo same):$(lockof "$D")" "0:1:0:same:"
rc=$(run -- --yes); check "at 2.1: fetched and swapped" "$rc:$(c '^FETCH'):$(ver "$DS/wine")" "0:1:3.0"
fresh none steam game
rc=$(run -- --yes); check "with no framework: fetched and swapped" "$rc:$(c '^FETCH'):$(ver "$DS/wine")" "0:1:3.0"
fresh 2.1 steam game; mkwine "$DS/wine.d3dm21-BAK" 2.1
rc=$(run -- --yes); check "a BAK and a wine/ at 2.1: --rebuild is passed" "$rc:$(c '^MAKE-ENGINE --install .* --rebuild CX_GPTK=')" "0:1"

# --- step 4 failing: the comparison, the engine script; what is left afterwards
fresh 2.1 steam game
rc=$(run STUB_ENGINE_WRONG=1 -- --yes)
check "a piece that differs from the fetched one after the swap stops it" "$rc:$(o 'd3d12.dll in the wrapper is not the fetched file'):$(c '^SETUP')" "1:1:0"
check "  ...the closing line is the core's, the lock is released, the temporary folder is gone" "$(o '^The install stopped\. The lines above say why\.'):$(lockof "$D"):$(tmpleft)" "1::0"
fresh 2.1 steam game
rc=$(run STUB_ENGINE_FAILS=1 -- --yes)
check "the engine script failing: exit 1, its last lines shown, the temporary folder gone" "$rc:$(o 'ERROR: stub failure'):$(tmpleft)" "1:1:0"

# --- step 4 waits for Wine to let go of the wrapper, and stops for Steam
hold() {   # <command line>: process 4242 holds a file of the default wrapper
  echo "4242 $1" > "$ST/procs"; echo "wine64 4242 x cwd $DS/prefix/drive_c" > "$ST/lsof.4242"
}
fresh 2.1 steam game; hold "C:\\windows\\system32\\services.exe"
rc=$(run STUB_RELEASE_AT=3 -- --yes)
check "something of Wine that lets go within the wait: step 4 goes on" "$rc:$(c '^FETCH'):$(cat "$ST/sleeps")" "0:1:3"
fresh 2.1 steam game; hold "C:\\windows\\system32\\services.exe"
rc=$(run -- --yes)
check "something of Wine that does not let go: exit 3 after ten waits, nothing fetched" "$rc:$(o 'Something of Wine is still using this wrapper (process 4242)'):$(c '^FETCH'):$(cat "$ST/sleeps")" "3:1:0:10"
fresh 2.1 steam game; hold "C:\\Program Files (x86)\\Steam\\steam.exe -no-cef-sandbox"
rc=$(run -- --yes)
check "Steam open in the wrapper stops step 4: exit 3, nothing fetched" "$rc:$(o 'Steam is open in this wrapper'):$(c '^FETCH')" "3:1:0"
world

# --- the order against Steam's installer, and the game
fresh 2.1
rc=$(run -- --yes)
check "step 4 comes before Steam's installer, by the record" "$(grep -oE '^(FETCH|MAKE-ENGINE|CURL)' "$CALLS" | uniq | tr '\n' ' ')" "FETCH MAKE-ENGINE CURL "
{ printf 'MZ'; head -c 1100000 /dev/zero; printf 'Valve Corp'; } > "$T/SteamSetup.exe"
fresh 3.0
rc=$(run STUB_CURL_FILE="$T/SteamSetup.exe" SM_ENGINE="$T/elsewhere" -- --yes)
check "Steam's installer is run with the wrapper's own wine64, SM_ENGINE not followed" "$(grep -c '^WINE64 .*/SteamSetup\.exe /S$' "$CALLS")" 1
check "  ...the game absent: setup is not run" "$(c '^SETUP')" 0
mkwine "$T/elsewhere" 3.0 OTHERWINE
fresh 3.0
rc=$(run STUB_CURL_FILE="$T/SteamSetup.exe" SM_ENGINE="$T/elsewhere" -- --yes)
check "  ...and with a Wine at SM_ENGINE, still the wrapper's own" "$(c '^OTHERWINE'):$(grep -c '^WINE64 .*/SteamSetup\.exe /S$' "$CALLS")" "0:1"
fresh 3.0 steam game
rc=$(run -- --check); check "the game is found by Project Spark/Mars.exe and manifest 3215050 at StateFlags 4" "$rc:$(grep -A1 '^Step 6 of 7' "$T/out" | grep -c '^  OK$')" "0:1"
fresh 3.0 steam othergame
rc=$(run -- --check); check "  ...the other game's manifest is not this game's" "$rc:$(o 'not installed: would start Steam')" "0:1"

# --- SM_WRAPPER, the options, the installer's own files, the Mac check
world; mkwrap "$T/other.app" 3.0 steam game
rc=$(run SM_WRAPPER="$T/other.app" --)
check "SM_WRAPPER given: it stops before step 7 with exit 0, runs no setup, and has no closing line" "$rc:$(o 'Stopped before step 7: SM_WRAPPER names another wrapper'):$(c '^SETUP'):$(o '^Done')" "0:1:0:0"
fresh 3.0 steam game
rc=$(run SM_WRAPPER="$D" --)
check "SM_WRAPPER naming the wrapper the game's app starts: setup runs, told a wrapper was given (WT11)" "$rc:$(o 'Stopped before step 7'):$(grep -c '^SETUP .* given=1$' "$CALLS")" "0:0:1"
[ "$rc" = 0 ] || sed 's/^/   | /' "$T/out"
mv "$D" "$T/aside.app"; mkdir -p "$HOME/Applications/SurvivingMars.app/Contents"
rc=$(run --)
check "an old-named app with no prefix and no other wrapper: exit 1, the looks-incomplete line, nothing made (WT11)" \
  "$rc:$(o 'SurvivingMars.app looks incomplete'):$(c '^MAKE-WRAPPER')" "1:1:0"
rm -rf "$HOME/Applications/SurvivingMars.app"; mv "$T/aside.app" "$D"
mkwrap "$HOME/Applications/twin.app" 3.0 steam game mark
rc=$(run --)
check "two wrappers marked alike: exit 1, the duplicates line, no setup (WT4b)" "$rc:$(o 'Move one to the Trash, or name the one to use in SM_WRAPPER.'):$(c '^SETUP')" "1:1:0"
rm -rf "$HOME/Applications/twin.app"
check "a relative SM_WRAPPER is exit 2, by that name" "$(run SM_WRAPPER=other.app --):$(o '^SM_WRAPPER must be an absolute path: other.app$')" "2:1"
check "--desktop is exit 2 for this game" "$(run -- --desktop):$(o 'unknown option: --desktop')" "2:1"
fresh 3.0 steam game
check "--no-setup stops before step 7" "$(run -- --no-setup):$(o 'Stopped before step 7, as asked'):$(c '^SETUP')" "0:1:0"
rm "$G/tools/frame-fix.exe"
check "the installer's own files gone: exit 4" "$(run --):$(c '^SETUP')" "4:0"
: > "$G/tools/frame-fix.exe"
# UT5, also (docs/plans/built-in-update.md, 3.3): the files of setup's record of versions are the installer's own too
for gone in paths.sh updates.sh games.tsv; do
  mv "$R/common/$gone" "$T/$gone.aside"
  check "common/$gone gone: exit 4 in the own-files words, before setup runs" "$(run --):$(o "The installer's own files are gone"):$(c '^SETUP')" "4:1:0"
  mv "$T/$gone.aside" "$R/common/$gone"
done
check "  ...with all three back: setup runs" "$(run --):$(c '^SETUP')" "0:1"
rc=$(run STUB_MAC_RC=3 STUB_MAC_WORDS="!! This Mac has an Intel processor." --)
check "a Mac check that exits 3 stops the install, setup's words above the core's" "$rc:$(grep -n -E 'Intel processor|the check of this Mac failed \(exit 3\)' "$T/out" | cut -d: -f2 | cut -c1-14 | tr '\n' '|')" "1:  !! This Mac |  !! the check|"
# the core's closing line sends the player to the installer again, which cannot help on such a Mac
# (docs/plans/first-run-findings.md, 2.8, FT5): after setup's exit 3, and that code only, it is not said
check "  ...and the core's closing line is not said: no \"Open the installer again\", and its own line is the last" "$(o 'Open the installer again'):$(o '^The install stopped'):$(tail -n 1 "$T/out")" "0:0:  !! the check of this Mac failed (exit 3)"
rc=$(run STUB_MAC_RC=6 STUB_MAC_WORDS="!! something else." --)
check "a Mac check that fails with another code keeps the closing line" "$rc:$(o 'the check of this Mac failed (exit 6)'):$(o '^The install stopped\. The lines above say why\. Open the installer again to carry on from that step\.$')" "1:1:1"
rc=$(run STUB_MAC_RC=1 --)
check "the refusal of Rosetta keeps the closing line: there, opening the installer again does help" "$rc:$(o 'softwareupdate --install-rosetta --agree-to-license$'):$(c '^SOFTWAREUPDATE'):$(o '^The install stopped\. The lines above say why\. Open the installer again to carry on from that step\.$')" "3:1:0:1"

# --- a swap stopped part way: a finished wine.new beside the BAK
part() {   # <what is left of wine/: gone | noserver | whole21 | whole30>: the default wrapper in that state
  fresh 2.1 steam game; mkwine "$DS/wine.d3dm21-BAK" 2.1; mkwine "$DS/wine.new" 3.0
  case "$1" in
    gone) rm -rf "$DS/wine" ;;
    noserver) rm -f "$DS/wine/bin/wineserver" ;;
    whole30) plist "$DS/wine" 3.0 ;;
  esac
}
finished() {   # <name>: after a run, the swap was finished by one call, nothing fetched, no question
  check "$1: finished by one call of the engine script, no --rebuild, no CX_GPTK" "$rc:$(c '^MAKE-ENGINE'):$(c "^MAKE-ENGINE --install $D CX_GPTK=unset ")" "0:1:1"
  check "  ...nothing fetched, no question, not called incomplete, step 4 skipped, setup run" "$(c '^FETCH'):$(o "Apple's Game Porting Toolkit"):$(o 'looks incomplete'):$(o '^  OK: D3DMetal 3.0$'):$(c '^SETUP')" "0:0:0:1:1"
  check "  ...wine.new is now wine/" "$([ -e "$DS/wine.new" ] && echo left || echo none):$(ver "$DS/wine")" "none:3.0"
}
part gone; rc=$(run --); finished "wine/ gone"
part noserver; rc=$(run --); finished "wine/ without its wineserver"
part whole21; rc=$(run --); finished "wine/ whole at 2.1"
part whole30; rc=$(run --); finished "wine/ whole at 3.0"
part gone; before=$(snap); rc=$(run -- --check)
check "wine/ gone, --check: said, exit 0 at once, nothing changed, not called incomplete" "$rc:$(o 'an engine swap was stopped part way\. The installer would finish it'):$(o '^Step'):$(o 'looks incomplete'):$(c '^MAKE-ENGINE'):$([ "$(snap)" = "$before" ] && echo same)" "0:1:0:0:0:same"
part whole21; before=$(snap); rc=$(run -- --check)
check "wine/ whole, --check: said, and the report goes on; nothing changed" "$rc:$(o 'The installer would finish it'):$(grep -c '^Step [1-7] of 7' "$T/out"):$(c '^MAKE-ENGINE'):$([ "$(snap)" = "$before" ] && echo same)" "0:1:7:0:same"
part gone; /bin/sleep 300 & HOLD=$!
ln -s "$HOLD" "$DS/prefix/.launcher.lock"; before=$(snap); rc=$(run --)
check "a live holder of the lock: exit 3 with the core's words, not called incomplete" "$rc:$(o "Another launch or install is using this wrapper (process $HOLD)"):$(o 'looks incomplete')" "3:1:0"
check "  ...and the swap is left as it was: wine.new there, no call of the engine script" "$([ -d "$DS/wine.new" ] && echo there):$(c '^MAKE-ENGINE'):$([ "$(snap)" = "$before" ] && echo same)" "there:0:same"
rm -f "$DS/prefix/.launcher.lock"; kill "$HOLD" 2>/dev/null; wait "$HOLD" 2>/dev/null; HOLD=""
part gone; rc=$(run STUB_FINISH_REFUSED=1 --)
check "the engine script refusing the finish: exit 3 under its own line, not passed on to the core's test" "$rc:$(o 'ERROR: a Wine process (pid 77) is using'):$(o 'could not be finished'):$(o 'looks incomplete'):$([ -d "$DS/wine.new" ] && echo there)" "3:1:1:0:there"
fresh 2.1 steam game; mkwine "$DS/wine.new" 3.0
rc=$(run -- --yes)
check "a wine.new with no BAK is not a finished swap: step 4 runs as for any 2.1" "$rc:$(c '^MAKE-ENGINE --install .* CX_GPTK=unset'):$(c '^FETCH')" "0:0:1"

# --- the game running, seen under the path the launcher was given
ln -s "$T/home" "$T/homelink"
fresh 3.0 steam game
echo "4343 $T/homelink/Applications/$(basename "$D")/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe" > "$ST/procs"
rc=$(run HOME="$T/homelink" --)
check "the game running, started under a home folder that resolves to another: exit 3" "$rc:$(o 'The game is running'):$(c '^SETUP')" "3:1:0"
world

# --- the launcher's own lines, word for word
blk() { awk -v a="$2" -v b="$3" 'index($0, a) == 1 { p = 1 } p { print } p && index($0, b) == 1 { exit }' "$1"; }
fn() { awk -v h="$2" '$0 == h { p = 1 } p { print } p && /^\}$/ { exit }' "$1"; }
same() {   # <first line starts with> <last line starts with> <lines>: that block of the installer is the launcher's
  echo "$(blk "$S" "$1" "$2" | shasum | cut -c1-12):$(blk "$S" "$1" "$2" | wc -l | tr -d ' ')"
}
want() { echo "$(blk "$LAUNCHER" "$1" "$2" | shasum | cut -c1-12):$3"; }
check "the exports equal the launcher's, comment lines included" "$(same 'export WINEPREFIX=' 'export SteamAppId=')" "$(want 'export WINEPREFIX=' 'export SteamAppId=' 8)"
check "WINE is the launcher's line" "$(grep -c -x -F 'WINE="$ENGINE/bin/wine64"' "$S"):$(grep -c -x -F 'WINE="$ENGINE/bin/wine64"' "$LAUNCHER")" "1:1"
check "the version expression equals the launcher's" "$(same 'D3DM_VER=$(plutil' '  || plutil')" "$(want 'D3DM_VER=$(plutil' '  || plutil' 2)"
check "the version pattern equals the launcher's" "$(same 'case "$D3DM_VER" in' '  [3-9]')" "$(want 'case "$D3DM_VER" in' '  [3-9]' 2)"
check "game_running equals the launcher's" "$(fn "$S" 'game_running() {' | shasum | cut -c1-12):$(fn "$S" 'game_running() {' | wc -l | tr -d ' ')" "$(fn "$LAUNCHER" 'game_running() {' | shasum | cut -c1-12):8"
check "no line of the installer names the other game" "$(grep -c -i -E 'cities|skylines|949230|CS2' "$HERE/scripts/install.sh")" 0

# --- WT11 (docs/plans/wrapper-names.md): the installer's route through the real setup.sh, wrappers.sh and
#     move-wrappers.sh, in a second scratch copy; its app builder is the real one with xcrun a stub, its window
#     builder a stub, the mover's probe a stub
R2="$T/repo2"; G2="$R2/surviving-mars-relaunched"; mkdir -p "$R2/common" "$G2/scripts" "$G2/tools"
cp "$S" "$G2/scripts/install.sh"; cp "$CORE" "$R2/common/install-core.sh"   # the copies under test: their mutants apply here too
cp "$HERE/scripts/setup.sh" "$G2/scripts/"; cp "$HERE/launch-relaunched.sh" "$HERE/make-app.sh" "$G2/"; cp "$HERE/tools/frame-fix.exe" "$G2/tools/"
cp "$G/tools/fetch-d3dmetal.sh" "$G/tools/make-engine.sh" "$G2/tools/"
cp "$REPO/common/wrappers.sh" "$REPO/common/move-wrappers.sh" "$R/common/make-wrapper.sh" "$R/common/tools.sh" "$R2/common/"
cp "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$REPO/common/games.tsv" "$R2/common/"   # the real setup keeps its record of versions
printf '#!/bin/bash\nexit 0\n' > "$R2/common/make-launcher-app.sh"
S2="$G2/scripts/setup.sh"
case "$M" in
  34) sed -i '' 's|^\[ "\${SM_VIA_INSTALLER:-0}" = 1 \] \&\& \[ "\${L1_WRAPPER_GIVEN:-}" = 0 \] \&\& unset SM_WRAPPER$|: no unset|' "$S2"
      grep -q '^: no unset$' "$S2" || { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
  35) sed -i '' 's|a+=(--holders-skip --held-by "\$PPID")|a+=(--held-by "$PPID")|' "$S2"
      grep -q -- '--holders-skip --held-by' "$S2" && { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
  40) sed -i '' 's|^  l1u_stamp 3215050 "\$REPO" \&\& return 0$|  return 0   # no stamp|' "$S2"
      grep -q '^  return 0   # no stamp$' "$S2" || { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
esac
stub xcrun 'exit 1'
stub wprobe '[ -n "${STUB_WHOLDERS:-}" ] && echo "$STUB_WHOLDERS"; exit 0'
# a pgrep that, as the real one, exits 1 when nothing matches: the app builder refuses while its app's program runs
mkdir -p "$T/bin2"; printf '#!/bin/bash\ni=""; pat=""; for a in "$@"; do [ "$a" = -i ] && i=-i; pat="$a"; done\ngrep -E $i -- "$pat" "$ST/procs" 2>/dev/null | cut -d" " -f1 | grep .\n' > "$T/bin2/pgrep"; chmod +x "$T/bin2/pgrep"
OLDW="$HOME/Applications/SurvivingMars.app"; NEWW="$HOME/Applications/$(bash "$REPO/common/wrappers.sh" name game 3215050)"
oldw() { rm -rf "$HOME/Applications"/*.app "$HOME/Library"; world; mkwrap "$OLDW" 3.0 steam game; }
run2() { : > "$CALLS"; env -u SM_WRAPPER -u L1_WRAPPER_GIVEN PATH="$T/bin2:$PATH" L1_WMOVE_PROBE="$T/bin/wprobe" "$@" /bin/bash "$G2/scripts/install.sh" < /dev/null > "$T/out" 2>&1; echo $?; }
oldw; rc=$(run2)
check "WT11 through the real setup: an old-named wrapper, no variable given: renamed and marked, exit 0" \
  "$rc:$([ -d "$NEWW" ] && echo renamed):$(plutil -extract L1Role raw -o - "$NEWW/Contents/Info.plist" 2>/dev/null)" "0:renamed:game-wrapper"
check "  ...the app's L1Prefix names the renamed wrapper, and no .launcher.lock is left in it" \
  "$(plutil -extract L1Prefix raw -o - "$HOME/Applications/Surviving Mars Relaunched.app/Contents/Info.plist" 2>/dev/null):$(lockof "$NEWW")" "$NEWW/Contents/SharedSupport/prefix:"
# what the root install.sh exports reaches the real setup through the installer: its stamp (docs/plans/built-in-update.md, 3.1)
TAB="$(printf '\t')"
oldw; rc=$(run2 L1_FETCHED_REF=release L1_FETCHED_COMMIT=0123456789abcdef0123456789abcdef01234567 L1_UPDATE_NOW=1800000000)
check "UT5 through the installer and the real setup: the stamp holds the line, no version (this tree has no changelog), the commit and the time" \
  "$rc:$(cat "$(HOME="$HOME" bash "$R2/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')/installed/3215050" 2>/dev/null)" "0:release${TAB}-${TAB}0123456789abcdef0123456789abcdef01234567${TAB}1800000000"
oldw; rc=$(run2 STUB_WHOLDERS=4242)
check "WT11 a holder reported by the probe: exit 0, one skip line, nothing renamed" "$rc:$(o 'skip: something of the wrapper'):$([ -d "$OLDW" ] && echo kept)" "0:1:kept"
rm -rf "$HOME/Applications"/*.app "$HOME/Library"

# --- UT7b (docs/plans/built-in-update.md, 3.4 and section 6): the parts joined. The root install.sh, pasted with
#     the word update, fetches an archive of the WT11 copy (a stub curl serves it) and goes through the real
#     driver, this installer and the real setup. The table's other game has a stub installer that keeps no record.
cp "$REPO/common/update-games.sh" "$R2/common/"; printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.1.0 (2026-01-01)' '' 'One.' > "$R2/CHANGELOG.md"
if [ "$M" = 41 ]; then
  sed -i '' 's|^  if \[ "\$line" != "\$L1_FETCHED_REF" \]; then$|  if [ "$line" = "$L1_FETCHED_REF" ]; then|' "$R2/common/update-games.sh"
  grep -q '^  if \[ "\$line" = "\$L1_FETCHED_REF" \]; then$' "$R2/common/update-games.sh" || { echo "REFUSED: mutant $M did not apply"; exit 2; }
fi
OTHER="$(awk -F'\t' '$1 == 949230 { print $2 }' "$R2/common/games.tsv")"; mkdir -p "$R2/$OTHER/scripts" "$T/bin3"
printf '#!/bin/bash\necho "SECOND args=$* update=${L1_UPDATE:-}" >> "$CALLS"\necho "  the other game.s installer (a stub) stops here"\nexit "${STUB_SECOND_EXIT:-0}"\n' > "$R2/$OTHER/scripts/install.sh"
( cd "$T" && tar -czf "$T/ut7b.tar.gz" repo2 )
# a curl that serves that archive as curl would (the body to the file, the answer's code to standard output)
printf '#!/bin/bash\necho "ARCHIVE $*" >> "$CALLS"\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && out="$2"; shift; done\ncp "%s" "$out"; printf 200\n' "$T/ut7b.tar.gz" > "$T/bin3/curl"; chmod +x "$T/bin3/curl"
UD="$(bash "$R2/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"   # the record's folder under the scratch home
recorded() {   # a finished install whose record says release at v0.0.9, with the tree's version on offer
  rm -rf "$HOME/Applications"/*.app "$HOME/Library"; world; mkwrap "$NEWW" 3.0 steam game mark
  mkdir -p "$UD/installed"; printf 'release\tv0.0.9\t-\t100\n' > "$UD/installed/3215050"; printf 'v0.1.0\t200\n' > "$UD/offer"
}
state() { L1_UPDATE_DIR="$UD" bash "$R2/common/updates.sh" | cut -f1-3; }   # the tree's tool on this home's record
upd() {   # [VAR=value ...]: install.sh update, pasted; output in $T/out; echoes the exit code
  : > "$CALLS"
  env -u SM_WRAPPER -u L1_WRAPPER_GIVEN PATH="$T/bin3:$T/bin2:$PATH" L1_WMOVE_PROBE="$T/bin/wprobe" L1_UPDATE_NOW=1800000000 "$@" \
    /bin/bash -c "$(cat "$REPO/install.sh")" 1launcher-install update < /dev/null > "$T/out" 2>&1; echo $?
}
recorded
check "UT7b a finished install recorded at v0.0.9, v0.1.0 on offer: the state is ready" "$(state)" "ready${TAB}v0.0.9${TAB}v0.1.0"
rc=$(upd)
check "UT7b install.sh update through the real driver, installer and setup: exit 0, the stamp holds the tree's version, and the deployed tool says current" \
  "$rc:$(c '^ARCHIVE .*/archive/refs/heads/release\.tar\.gz$'):$(cat "$UD/installed/3215050" 2>/dev/null):$(bash "$UD/updates.sh" 2>/dev/null | cut -f1-3):$(tmpleft)" \
  "0:1:release${TAB}v0.1.0${TAB}-${TAB}1800000000:current${TAB}v0.1.0${TAB}v0.1.0:0"
check "  ...the driver's heading and closing lines are there" "$(o '^=== Surviving Mars: Relaunched ===$'):$(o '^Surviving Mars: Relaunched: updated\.$'):$(o '^Everything is up to date: 1launcher v0\.1\.0\.$')" "1:1:1"
recorded; W2="$HOME/Applications/$(bash "$REPO/common/wrappers.sh" name game 949230)"; mkwrap "$W2" 2.1
plutil -replace L1Role -string game-wrapper "$W2/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 949230 "$W2/Contents/Info.plist"
mkdir -p "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"; : > "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II/Cities2.exe"
printf 'release\tv0.0.9\t-\t100\n' > "$UD/installed/949230"
rc=$(upd STUB_SECOND_EXIT=3)
check "UT7b with the second game's installer made to stop: exit 3, this game's stamp is new, the other's is old, and the state stays ready" \
  "$rc:$(c '^SECOND args= update=1$'):$(cut -f2 "$UD/installed/3215050" 2>/dev/null):$(cut -f2 "$UD/installed/949230" 2>/dev/null):$(state)" \
  "3:1:v0.1.0:v0.0.9:ready${TAB}v0.0.9${TAB}v0.1.0"
rm -rf "$HOME/Applications"/*.app "$HOME/Library"

# --- LFT8 (docs/plans/launcher-first-install.md, 3.8 and section 6): an install from 14unch3r, the parts joined.
#     The fixture: the record at the default place under the scratch home, a marked wrapper of the game with no
#     app (a begun install), the launcher's stamp alone on release at v0.0.9, and the offer at v0.0.9, so the
#     state is current and the tool opens. The offer is then raised to the tree's version, as a daily check
#     would have found it, and the written file is run: through the root install.sh (a stub curl serves it, and
#     the archive of the WT11 copy), this installer and the real setup.
case "$M" in
  44) sed -i '' 's#^  /bin/bash -c "\$S" 1launcher-install "\$ID"; rc=\$?$#  /bin/bash -c "$S" 1launcher-install update; rc=$?#' "$R2/common/updates.sh"
      grep -q '^  /bin/bash -c "\$S" 1launcher-install update; rc=\$?$' "$R2/common/updates.sh" || { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
  45) sed -i '' 's#^  \[ "\${INSTALL_LOCK:-0}" = 1 \] && l1u_lock_release installing .*#  : not released#' "$R2/common/install-core.sh"
      grep -q '^  : not released$' "$R2/common/install-core.sh" || { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
  46) sed -i '' 's#"built: one window that lists every game"; launcher_stamp ;;$#"built: one window that lists every game" ;;#' "$G2/scripts/setup.sh"
      grep -q 'launcher_stamp ;;$' "$G2/scripts/setup.sh" && { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
esac
mkdir -p "$T/bin4"; ( cd "$T" && tar -czf "$T/lft8.tar.gz" repo2 )
cat > "$T/bin4/curl" << X
#!/bin/bash
case " \$* " in
  *"/refs/heads/release/install.sh "*) echo "ROOTSCRIPT \$*" >> "\$CALLS"; src="$REPO/install.sh" ;;
  *) echo "ARCHIVE \$*" >> "\$CALLS"; src="$T/lft8.tar.gz" ;;
esac
out=""; while [ \$# -gt 0 ]; do case "\$1" in -o) out="\$2"; shift 2 ;; *) shift ;; esac; done
cp "\$src" "\$out"; printf 200
X
printf '#!/bin/bash\n{ printf "OPEN"; for a in "$@"; do printf "|%%s" "$a"; done; echo; } >> "$CALLS"\n' > "$T/bin4/open"
chmod +x "$T/bin4/curl" "$T/bin4/open"
world; mkwrap "$NEWW" 3.0 steam game mark
mkdir -p "$UD/installed"; printf 'release\tv0.0.9\t-\t100\n' > "$UD/launcher"; printf 'v0.0.9\t200\n' > "$UD/offer"; cp "$R2/common/updates.sh" "$UD/updates.sh"
check "LFT8 the fixture: a begun install (a marked wrapper, no app), the launcher's stamp alone on release at v0.0.9, that version on offer: the state is current" \
  "$(state):$([ -e "$HOME/Applications/Surviving Mars Relaunched.app" ] && echo app || echo no-app)" "current${TAB}v0.0.9${TAB}v0.0.9:no-app"
: > "$CALLS"
ans="$(env L1_UPDATE_DIR="$UD" L1_CURL="$T/bin4/curl" L1_OPEN="$T/bin4/open" bash "$UD/updates.sh" --install 3215050 2>&1)"
CMD8="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"
check "LFT8 the deployed tool, asked to install the game: opened, and Terminal was handed one file" "$ans:$(grep -c '^OPEN|-a|Terminal|' "$CALLS"):$([ -x "$CMD8" ] && echo file)" "opened:1:file"
printf 'v0.1.0\t300\n' > "$UD/offer"   # as a daily check would have found it since
env -u SM_WRAPPER -u L1_WRAPPER_GIVEN PATH="$T/bin4:$T/bin2:$PATH" L1_WMOVE_PROBE="$T/bin/wprobe" L1_UPDATE_NOW=1800000000 TERM=xterm "$CMD8" < /dev/null > "$T/out" 2>&1; rc=$?
check "LFT8 the written file, run: the root install.sh is fetched, then the archive of release, and the game's line runs this installer and the real setup; exit 0, its closing line last" \
  "$rc:$(c '^ROOTSCRIPT .*/refs/heads/release/install\.sh$'):$(c '^ARCHIVE .*/archive/refs/heads/release\.tar\.gz$'):$(tail -n 1 "$T/out")" "0:1:1:Installed. Open 14unch3r to play. You can close this window."
check "LFT8 ...the game's stamp and the launcher's stamp both hold release and the tree's version, and the state is current (with the launcher's stamp left at v0.0.9 it would be ready)" \
  "$(cut -f1,2 "$UD/installed/3215050" 2>/dev/null):$(cut -f1,2 "$UD/launcher" 2>/dev/null):$(state)" "release${TAB}v0.1.0:release${TAB}v0.1.0:current${TAB}v0.1.0${TAB}v0.1.0"
check "LFT8 ...no lock is left, no file names a game, the game's app is there, and no temporary folder is left" \
  "$([ -e "$UD/installing" ] || [ -L "$UD/installing" ] && echo left || echo none):$([ -e "$UD/installing-game" ] && echo left || echo none):$([ -e "$HOME/Applications/Surviving Mars Relaunched.app" ] && echo app):$(tmpleft)" "none:none:app:0"
rm -rf "$HOME/Applications"/*.app "$HOME/Library"

echo "$fails failure(s)"
[ "$fails" = 0 ]
