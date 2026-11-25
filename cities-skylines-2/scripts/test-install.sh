#!/bin/bash
# test-install.sh -- scripts/install.sh with HOME at a scratch folder (docs/plans/simple-install.md, NT3). The
# script runs from a scratch copy of the repository whose setup.sh and make-wrapper.sh are recording stubs.
# Every outside program it calls is a recording stub on PATH: curl, softwareupdate, xcode-select, python3,
# caffeinate, id, df, pgrep, ps, lsof, route and sleep. The fixture wrapper's wine64 and wineserver are stubs too.
# Processes are files in a state folder: wine64 makes them as each start of Steam's plan says (STUB_STARTS),
# wineserver -k and -shutdown remove them, and the stub sleep moves the world on one poll at a time (the
# download, a blip in Steam's process, Apple's tools arriving). No network, no Wine, no real process is
# signalled (the stray sweep's kill is recorded through L1_KILL). A start that ends in "Steam needs to be
# online" writes what a real one logged: fixtures/bootstrap-ml2-failed-start.txt holds the 37 "Add pending
# download:" lines of the failed start of 2026-11-12, without the carriage return that ends every line of
# Steam's log (the repository stores none); the stub puts them back.
#   bash scripts/test-install.sh            exit 0 = every case passed
#   MUTANT=1  ...  Rosetta installed on Return; must exit 1
#   MUTANT=2  ...  setup run when the game is absent; must exit 1
#   MUTANT=3  ...  the wrapper made when one exists; must exit 1
#   MUTANT=4  ...  Steam's installer run when Steam is present; must exit 1
#   MUTANT=5  ...  the fatal line not acted on; must exit 1
#   MUTANT=6  ...  a one-poll gap restarts Steam; must exit 1
#   MUTANT=7  ...  -shutdown left out; must exit 1
#   MUTANT=8  ...  exit 0 when Steam is gone; must exit 1
#   MUTANT=9  ...  --check starts Steam; must exit 1
#   MUTANT=10 ...  the MZ test left out; must exit 1
#   MUTANT=11 ...  the lock not taken; must exit 1
#   MUTANT=12 ...  the running-game test left out; must exit 1
#   MUTANT=13 ...  the update-waiting state treated as not installed; must exit 1
#   MUTANT=14 ...  BytesToDownload 0 divides; must exit 1
#   MUTANT=15 ...  CS2_VIA_INSTALLER not passed to setup; must exit 1
#   MUTANT=16 ...  winemenubuilder.exe=d dropped; must exit 1
#   MUTANT=17 ...  the .crash left; must exit 1
#   MUTANT=18 ...  the start limit raised to six; must exit 1
#   MUTANT=19 ...  a copied function changed in install.sh alone; must exit 1
#   MUTANT=20 ...  the update state matched on any value other than 4; must exit 1
#   MUTANT=21 ...  a client already up started again; must exit 1
#   MUTANT=22 ...  the ten-minute limit removed; must exit 1
#   MUTANT=23 ...  a copied function run with an empty WINEPREFIX; must exit 1
#   MUTANT=24 ...  a broken python3 sent to xcode-select --install; must exit 1
#   MUTANT=25 ...  a signal ends in the EXIT trap alone (which then says Done.); must exit 1
#   MUTANT=26 ...  one word of one line changed ("is open." made "is opened."); must exit 1, by the transcript
#   MUTANT=27 ...  one exit code changed (Apple's tools not there yet: 6, not 4); must exit 1
#   MUTANT=28 ...  a stage's skip test turned round (Apple's tools); must exit 1
#   MUTANT=29 ...  a game's name put into a line of the shared part; must exit 1
#   MUTANT=30 ...  the shared part not checking that the game set its settings; must exit 1
#   MUTANT=31 ...  the look for another wrapper's Steam left out; must exit 1
#   MUTANT=32 ...  any line naming steam.exe taken for a Steam, a Wine program or not; must exit 1
#   MUTANT=33 ...  --desktop taken by a game whose setup has none; must exit 1
# Steam's own update cut (docs/plans/first-run-findings.md, 2.1, FT1); each must exit 1:
#   34 the transfer skipped and Steam started again     35 a start made before the transfer
#   36 the first address used                           37 the largest chosen before the pattern is applied
#   38 the count of starts begun again after the transfer (six starts)
#   39 an address from before this start                40 the carriage return left on
#   41 an address outside the pattern passed to curl    42 --max-time removed
#   43 -f removed                                       44 the VPN sentence with no tunnel
#   45 the VPN sentence when the transfer worked        46 exit 0 with 5 MB counted as working
#   47 28 with 19,999,999 bytes counted as working      48 no restart when the transfer works
#   49 the restart removed for "download location"      50 the transfer made before any failure
#   51 the log's lines printed in these forms           52 exit 1
#   53 the closing line for 4 printed                   54 the path with the home folder
#   55 Steam left running at exit 4                     60 the transfer's result not written to the trace
# curl's own words for Steam's installer (2.2, FT2); each must exit 1:
#   56 curl's words printed when the second address works    57 nothing printed when both fail
# The lines before Steam's start (2.10, FT3c); each must exit 1:
#   58 the old two lines (by its own case, and by the transcript)   59 a size in the lines
# Setup's exit 5, a fix not out yet for this build (docs/plans/patch-outcomes.md, 2.5, PT6); each must exit 1:
#   61 the case for 5 dropped    62 5 mapped to "Done."    63 the test of WORDS_NOFIX dropped
# Wrapper names (docs/plans/wrapper-names.md, WT10, WT11); each must exit 1:
#   64 the marking option dropped in the core (WT10 (b))    65 L1_WRAPPER_GIVEN not exported by core_begin (WT11 (a))
#   66 game_wrapper not asking the resolver's incomplete (WT11 (f))
#   67 setup's unset of CS2_WRAPPER removed (WT11 (b))      68 an unset L1_WRAPPER_GIVEN read as "not given" (WT11 (d))
#   69 --holders-skip not passed by setup (WT11 (g))        70 core_after_setup removed at this installer's call (WT11 (c))
# Setup's record of versions (docs/plans/built-in-update.md, 3.3; UT5, also); must exit 1:
#   74 the own-files loop for common/updates.sh and common/games.tsv dropped
# The update, its parts joined (docs/plans/built-in-update.md, 3.4; UT7b); each must exit 1:
#   75 l1u_stamp not called by setup    76 the driver's test of a stamp's line turned round
# The transcript (docs/plans/shared-installer.md, ST1): every case's name, result and whole output, with the
# scratch folder's name and process numbers replaced, is compared with test-install.golden, which holds what
# the installer printed when it was last recorded on purpose: on the branch first-run-findings, after the
# slices of docs/plans/first-run-findings.md that change its words. It was first recorded at 6a66416, before
# the installer was divided into a shared part and a game's part. A changed line of that file is a changed
# word of the installer. Carriage returns (a case run at a terminal has them) are dropped: the repository
# stores text with plain line ends, so a file holding them would not survive a checkout.
#   GOLDEN=record bash scripts/test-install.sh   write test-install.golden from this run: a deliberate act,
#                                                 refused under a mutant and from a run with a failure
# The transcript is compared under mutants 26, 27, 28 and 58 only: every other one must be caught by its own case.
set -u
unset L1_UPDATE_DIR L1_UPDATE L1_UPDATE_NOW L1_FETCHED_COMMIT   # the record of versions is the cases' own
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LAUNCHER="$REPO/cities-skylines-2/launchers/launch-cs2-dxmt11.sh"
T="$(mktemp -d /tmp/install-test.XXXX)"
trap 'rm -rf "$T"' EXIT
R="$T/repo"; mkdir -p "$R/cities-skylines-2/scripts" "$R/cities-skylines-2/patches" "$R/common"
S="$R/cities-skylines-2/scripts/install.sh"; cp "$HERE/install.sh" "$S"
C="$R/common/install-core.sh"; cp "$REPO/common/install-core.sh" "$C"   # the shared stages: mutants apply in either file
: > "$R/cities-skylines-2/repatch.sh"; : > "$R/common/make-launcher-app.sh"
: > "$R/common/paths.sh"; : > "$R/cities-skylines-2/scripts/move-install.sh"   # setup's own files (docs/plans/local-files-layout.md, 3.4)
cp "$REPO/common/wrappers.sh" "$R/common/wrappers.sh"; : > "$R/common/move-wrappers.sh"   # the resolver, real; the mover, setup's (docs/plans/wrapper-names.md)
: > "$R/common/updates.sh"; : > "$R/common/games.tsv"   # setup's record of versions (docs/plans/built-in-update.md, 3.3)
mutate() {  # <sed expression> <grep that proves it applied>
  sed -i '' "$1" "$S" "$C"; cat "$S" "$C" | grep -q -- "$2" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
first() {   # <perl search> <replacement> <grep that proves it applied>: the first occurrence only, the core first
  cp "$C" "$T/c0"; perl -0pi -e "s/$1/$2/" "$C"; cmp -s "$C" "$T/c0" && perl -0pi -e "s/$1/$2/" "$S"
  cat "$S" "$C" | grep -q -- "$3" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  1) mutate 's#^      y|Y) softwareupdate#      y|Y|"") softwareupdate#' 'y|Y|"") softwareupdate' ;;
  2) mutate 's#|| { echo absent; return; }#|| { echo installed; return; }#' 'echo installed; return; }$' ;;
  3) mutate 's#^if \[ -d "\$W" \]; then say "OK: #if false; then say "OK: #' '^if false; then say "OK: ' ;;
  4) first 'if \[ -f "\$STEAMDIR\/steam.exe" \] \|\| \[ -f "\$STEAMDIR\/Steam.exe" \]; then say "OK"' 'if false; then say "OK"' '^if false; then say "OK"' ;;
  5) mutate "s#^FATAL=.*#FATAL='no such line'#" "^FATAL='no such line'" ;;
  6) mutate 's#^GONE_POLLS=3 #GONE_POLLS=1 #' '^GONE_POLLS=1 ' ;;
  7) mutate 's#^    "\$WINE" "\$(steam_exe)" -shutdown.*#    :#' '^    :$' ;;
  8) mutate 's#{ say "Steam closed before the game finished downloading."; exit 4; }#{ say "Steam closed before the game finished downloading."; exit 0; }#' 'downloading."; exit 0; }' ;;
  9) mutate 's#if \[ "\$CHECK" = 1 \]; then say "not installed: would start#if false; then say "not installed: would start#' 'if false; then say "not installed' ;;
  10) mutate 's# || \[ "\$(head -c 2 "\$D/SteamSetup.exe")" != MZ \]##' 'le 1048576 \] || ! grep' ;;
  11) mutate 's#^  acquire_lock 1 ||#  true ||#' '^  true ||' ;;
  12) first 'if prefix_known && game_running; then say "!! The game is running.[^\n]*\n' '' 'x' ; cat "$S" "$C" | grep -c 'prefix_known && game_running' | grep -qx 1 || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  13) mutate 's#^  elif \[ \$((f \& 4)) -ne 0 \]; then echo update$#  elif false; then echo update#' 'elif false; then echo update' ;;
  14) mutate 's#^        if \[ "\$to" = 0 \]; then$#        if false; then#' '^        if false; then$' ;;
  15) mutate 's#^CS2_VIA_INSTALLER=1 bash "\$SETUP" "\$@"#bash "$SETUP" "$@"#' '^bash "\$SETUP" "\$@"' ;;
  16) mutate 's#^  export WINEDLLOVERRIDES="winemenubuilder.exe=d"#  export WINEDLLOVERRIDES=""#' 'WINEDLLOVERRIDES=""' ;;
  17) mutate 's#^    rm -f "\$STEAMDIR/.crash"#    :#' '^    :$' ;;
  18) mutate 's#^MAX_STARTS=5#MAX_STARTS=6#' '^MAX_STARTS=6' ;;
  19) mutate 's#^_owns() { lsof -p "\$1" 2>/dev/null | grep -q "\$WINEPREFIX"; }#_owns() { lsof -p "$1" 2>/dev/null | grep -qF "$WINEPREFIX"; }#' 'grep -qF "\$WINEPREFIX"' ;;
  20) mutate 's#^  elif \[ \$((f \& 4)) -ne 0 \]; then echo update$#  elif true; then echo update#' 'elif true; then echo update' ;;
  21) mutate 's#^    if \[ "\$up" = 0 \]; then$#    if true; then#' '^    if true; then$' ;;
  22) mutate 's#^    while \[ "\$i" -lt "\$START_POLLS" \]; do$#    while :; do#' '^    while :; do$' ;;
  23) first 'if prefix_known && game_running' 'if game_running' '^if game_running' ;;
  25) mutate "s#^trap 'on_signal 143' TERM\$#: no trap#" '^: no trap$' ;;
  26) mutate 's#Steam for Windows is open\.#Steam for Windows is opened.#' 'Steam for Windows is opened\.' ;;
  27) mutate 's#are not installed yet\."; exit 4; }#are not installed yet."; exit 6; }#' 'installed yet\."; exit 6; }' ;;
  28) mutate 's#^if xcode-select -p > /dev/null 2>&1; then #if ! xcode-select -p > /dev/null 2>\&1; then #' '^if ! xcode-select -p' ;;
  29) mutate 's#^stage "\$1" "The game"$#stage "$1" "Cities: Skylines II"#' '^stage "\$1" "Cities: Skylines II"$' ;;
  30) mutate 's#^  \[ -n "\${!_v:-}" \] || {#  true || {#' '^  true || { echo "install-core.sh: the game' ;;
  31) mutate 's#^    other="\$(other_steam)"$#    other=""#' '^    other=""$' ;;
  32) mutate 's#^    case "\$o" in \*drive_c\*) ;; \*) continue ;; esac.*#    :#' '^    :$' ;;
  33) mutate 's#^    --desktop) \[ "\${TAKES_DESKTOP:-0}" = 1 \] || {.*#    --desktop)#' '^    --desktop)$' ;;
  24) mutate 's#^if xcode-select -p > /dev/null 2>&1; then #if xcode-select -p > /dev/null 2>\&1 \&\& py_ok; then #' '2>&1 && py_ok; then' ;;
  34) mutate 's#grep -q "\$FATAL_ONLINE" \&\& return 2$#grep -q "$FATAL_ONLINE" \&\& continue 2#' 'FATAL_ONLINE" && continue 2$' ;;
  35) mutate 's#^        update_probe$#        start_steam; update_probe#' '^        start_steam; update_probe$' ;;
  36) mutate 's#^    | awk -F_ .*#    | head -n 1)"#' '^    | head -n 1)"$' ;;
  37) perl -0pi -e 's/(    \| )(grep -E [^\n]*) \\\n    \| (awk -F_ [^\n]*)\)"\n/$1$3 \\\n    | $2)"\n/' "$C"
      grep -q '^    | grep -E .*steamstatic.*)"$' "$C" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  38) mutate 's#^        start_until_up || { end_steam; update_words#        STARTS=0; start_until_up || { end_steam; update_words#' '^        STARTS=0; start_until_up ||' ;;
  39) mutate 's#^  url="\$(tail -n +"\$((LOG_FROM + 1))" #  url="$(tail -n +1 #' '^  url="\$(tail -n +1 ' ;;
  40) mutate "s#^\\(  url=.*\\) | tr -d '.r' | sed#\\1 | sed#" '^  url=.*BOOTLOG" 2>/dev/null | sed -n' ;;
  41) mutate 's#^    | grep -E .*steamstatic.*#    | cat \\#' '^    | cat \\$' ;;
  42) mutate 's# -fsSL --max-time "\$PROBE_SECS" \\$# -fsSL \\#' ' --globoff -fsSL \\$' ;;
  43) mutate 's# --globoff -fsSL --max-time # --globoff -sSL --max-time #' ' --globoff -sSL --max-time ' ;;
  44) mutate 's#^         if on_tunnel; then$#         if true; then#' '^         if true; then$' ;;
  45) mutate 's#^    cut) say "!! Steam could not#    cut|working) say "!! Steam could not#' '^    cut|working) say ' ;;
  46) mutate 's#^    0|28) \[ "\$size" -ge "\$PROBE_BYTES" \] \&\& PROBE=working ;;$#    0) PROBE=working ;; 28) [ "$size" -ge "$PROBE_BYTES" ] \&\& PROBE=working ;;#' '^    0) PROBE=working ;; 28) ' ;;
  47) mutate 's#^PROBE_BYTES=20000000 #PROBE_BYTES=19999999 #' '^PROBE_BYTES=19999999 ' ;;
  48) mutate 's#^        case "\$PROBE" in cut|none) update_words#        case "$PROBE" in cut|none|working) update_words#' 'in cut|none|working) update_words' ;;
  49) mutate 's#^        continue 2$#        return 1#' '^        return 1$' ;;
  50) mutate 's#^      start_until_up; rc=\$?$#      LOG_FROM=0; update_probe; PROBED=0; start_until_up; rc=$?#' '^      LOG_FROM=0; update_probe; PROBED=0; start_until_up; rc=\$?$' ;;
  51) mutate 's#^  END=quiet   \# the closing line for 4 would.*#  tail -n 20 "$BOOTLOG" | sed "s/^/     /"; END=quiet#' '^  tail -n 20 "\$BOOTLOG" | sed "s/^/     /"; END=quiet$' ;;
  52) mutate 's#in cut|none) update_words "\$PROBE"; exit 4 ;; esac$#in cut|none) update_words "$PROBE"; exit 1 ;; esac#' 'update_words "\$PROBE"; exit 1 ;; esac$' ;;
  53) mutate 's#^  END=quiet   \# the closing line for 4 would.*#  :#' '^  :$' ;;
  54) mutate 's#if you ask for help: \$(tilde "\$BOOTLOG")"$#if you ask for help: $BOOTLOG"#' 'if you ask for help: \$BOOTLOG"$' ;;
  56) mutate 's# "\$u" 2> "\$D/curl-\$try.err" \&\& { got=1; break; }$# "$u" \&\& { got=1; break; }#' ' "\$u" && { got=1; break; }$' ;;
  57) mutate 's#^    cat "\$D"/curl-\*\.err 2>/dev/null | sed .*#    :#' '^    :$' ;;
  58) perl -0pi -e 's/      say "Steam for Windows is starting\. The first time,[^\n]*\n[^\n]*\n[^\n]*\n/      say "Steam for Windows is starting. A small box headed \\"Steam - Fatal Error\\" can appear once or twice"\n      say "and close again. That is expected: Steam is updating itself. Click nothing in it."\n/' "$C"
      grep -q '^      say "and close again\. That is expected: Steam is updating itself\. Click nothing in it\."$' "$C" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  59) mutate 's#^      say "Steam downloading its own update: leave it,#      say "Steam downloading its own update (about 330 MB): leave it,#' 'its own update (about 330 MB): leave it,' ;;
  60) mutate 's#^  probe_trace "exit=\$rc bytes=\$size"$#  :#' '^  :$' ;;
  55) first '\n        end_steam\n        \[ "\$PROBED" = 0 \]' '\n        :\n        [ "\$PROBED" = 0 ]' '^        :$' ;;
  61) sed -i '' '/^         5:set) echo "\$WORDS_NOFIX" ;;$/d' "$C"; grep -q '^         5:set) ' "$C" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  62) mutate 's#^         0:\*) echo "Done\. #         0:*|5:*) echo "Done. #' '^         0:\*|5:\*) echo "Done\. ' ;;
  63) mutate 's#^         5:set) echo #         5:*) echo #' '^         5:\*) echo "\$WORDS_NOFIX" ;;$' ;;
  64) sed -i '' 's# --mark game "\$GAME_APPID"##g' "$C"; grep -q -- '--mark game' "$C" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  65) mutate 's#^export L1_WRAPPER_GIVEN$#: no export#' '^: no export$' ;;
  66) mutate 's#^W="\$(l1w_incomplete game "\$GAME_APPID")" || W=#W=#' '^W="\$HOME/Applications/\$(l1w_name' ;;
  67|68|69|75|76) ;;   # applied below, to the real setup.sh of the WT11 copy (76: to the driver beside it)
  70) mutate 's#^core_after_setup \$?$#(exit $?)   \# no core_after_setup: the code kept, the lock not followed#' '^(exit \$?)   # no core_after_setup' ;;
  # UT2 (docs/plans/built-in-update.md, U0): 71 silent for a finished install only; 72 silent for a stopped download too; 73 the wrapper not asked for first
  71) mutate 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#if prefix_known; then case "$(game_state)" in installed) return 0 ;; esac; fi#' '^if prefix_known; then case "\$(game_state)" in installed) return 0 ;; esac; fi$' ;;
  72) mutate 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#if prefix_known; then case "$(game_state)" in installed|update|partial) return 0 ;; esac; fi#' '^if prefix_known; then case "\$(game_state)" in installed|update|partial) return 0' ;;
  73) mutate 's#^if prefix_known; then case "\$(game_state)" in installed|update) return 0 ;; esac; fi$#case "$(game_state)" in installed|update) return 0 ;; esac#' '^case "\$(game_state)" in installed|update) return 0 ;; esac$' ;;
  74) mutate 's#^for f in "\$GAME_ROOT/../common/updates.sh" "\$GAME_ROOT/../common/games.tsv"; do .*#for f in; do#' '^for f in; do$' ;;
esac

fails=0
check() {  # <name> <got> <want>; the case also goes to the transcript, with the output of the run it judged
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
  { echo "== $1 :: $2"; cat "${H:-/nonexistent}.out" 2>/dev/null; } | tr -d '\r' \
    | sed -e "s#/private$T#T#g" -e "s#$T#T#g" -e 's/process [0-9][0-9]*/process N/g' >> "$T/transcript"
}

# --- the source: copies held identical to the launcher's, and what no line may hold
ALL="$T/all.sh"; cat "$S" "$C" > "$ALL"
fn() {   # one function, as common/test-launch-lock.sh cuts it
  awk -v f="$1" 'index($0, f "() {") == 1 { print; if ($0 ~ /; }[[:space:]]*$/) exit; p = 1; next }
                 p { print; if ($0 ~ /^}/) exit }' "$2"
}
for f in _owns webhelper_up steam_family game_running acf_field; do
  check "the copy of $f equals the launcher's" "$( [ -n "$(fn "$f" "$ALL")" ] && [ "$(fn "$f" "$ALL")" = "$(fn "$f" "$LAUNCHER")" ] && echo same )" same
done
check "the python3 test equals setup.sh's" "$(grep -cxF "$(grep -m1 '^if python3 -c' "$HERE/setup.sh")" "$ALL")" 1
check "the library path is exported with the launcher's own line" "$(grep -cxF "  $(grep -m1 '^export DYLD_FALLBACK_LIBRARY_PATH=' "$LAUNCHER")" "$ALL")" 1
check "no nohup, env, setsid or kill -9 outside comments" \
  "$(grep -v '^[[:space:]]*#' "$ALL" | grep -cE '(^|[^-[:alnum:]_])(nohup|setsid)([^[:alnum:]_]|$)|(^|[^[:alnum:]_-])env |kill -9')" 0

# --- stubs
B="$T/bin"; mkdir -p "$B" "$T/fixbin"
export ST="$T/state" CALLS="$T/calls"
cat > "$R/cities-skylines-2/scripts/setup.sh" << 'X'
#!/bin/bash
echo "SETUP $* via=${CS2_VIA_INSTALLER:-} wrapper=${CS2_WRAPPER:-} given=${L1_WRAPPER_GIVEN-unset}" >> "$CALLS"
printf '%s\n' "${CS2_PATCH_DIR:-}" > "$CALLS.patchdir"
case " $* " in *" --mac-only "*)
  if [ -n "${STUB_NO_ROSETTA:-}" ] && [ ! -f "$ST/rosetta" ]; then echo "  Rosetta 2   MISSING"; exit 1; fi
  exit 0 ;;
esac
exit "${STUB_SETUP_EXIT:-0}"
X
cat > "$R/common/make-wrapper.sh" << 'X'
#!/bin/bash
echo "MAKEWRAPPER $*" >> "$CALLS"
case " $* " in *" --check "*) exit 0 ;; esac
[ -n "${STUB_MW_EXIT:-}" ] && exit "$STUB_MW_EXIT"
all=" $* "
while [ "$1" != --wrapper ]; do shift; done
case "$all" in *" --mark game 949230 "*) bash "$MKW" "$2" mark ;; *) bash "$MKW" "$2" ;; esac
X
cat > "$T/mkw.sh" << 'X'
#!/bin/bash
# mkw.sh <wrapper> [mark] [steam] [game <StateFlags>|game-nomanifest]: a fixture wrapper; mark writes the marker
# of common/wrappers.sh, as common/make-wrapper.sh --mark game 949230 does
S="$1/Contents/SharedSupport"; P="$S/prefix/drive_c/Program Files (x86)/Steam"
mkdir -p "$S/wine/bin" "$P/logs"; cp "$FIXBIN/wine64" "$FIXBIN/wineserver" "$S/wine/bin/"
printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>' > "$1/Contents/Info.plist"
chmod 755 "$1"
shift
while [ $# -gt 0 ]; do
  case "$1" in
    mark) plutil -replace L1Role -string game-wrapper "$S/../Info.plist"; plutil -replace L1SteamAppID -integer 949230 "$S/../Info.plist" ;;
    steam) : > "$P/Steam.exe" ;;
    game) mkdir -p "$P/steamapps/common/Cities Skylines II"; : > "$P/steamapps/common/Cities Skylines II/Cities2.exe"
          printf '"AppState"\n{\n\t"StateFlags"\t\t"%s"\n\t"BytesToDownload"\t\t"0"\n\t"BytesDownloaded"\t\t"0"\n}\n' "$2" > "$P/steamapps/appmanifest_949230.acf"; shift ;;
    game-nomanifest) mkdir -p "$P/steamapps/common/Cities Skylines II"; : > "$P/steamapps/common/Cities Skylines II/Cities2.exe" ;;
  esac
  shift
done
X
export MKW="$T/mkw.sh" FIXBIN="$T/fixbin" FIX_BOOT="$HERE/fixtures/bootstrap-ml2-failed-start.txt"
cat > "$T/fixbin/wine64" << 'X'
#!/bin/bash
echo "WINE $* dll=${WINEDLLOVERRIDES:-}" >> "$CALLS"
P="$WINEPREFIX/drive_c/Program Files (x86)/Steam"
case "$*" in
  *SteamSetup.exe*/S*) [ -n "${STUB_SETUP_NOEXE:-}" ] || { mkdir -p "$P/logs"; : > "$P/Steam.exe"; }; exit "${STUB_SETUP_RC:-0}" ;;
  *-shutdown*) [ -n "${STUB_SHUTDOWN_STUCK:-}" ] || rm -f "$ST/steam" "$ST/helper"; exit 0 ;;
  *-no-cef-sandbox*)
    n=$(( $(cat "$ST/starts" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$ST/starts"
    echo "start $n at tick $(wc -l < "$ST/ticks" | tr -d ' ') crash=$([ -e "$P/.crash" ] && echo yes || echo no)" >> "$ST/startlog"
    kind="$(echo "${STUB_STARTS:-ok}" | awk -v n="$n" '{ print $n }')"; kind="${kind:-ok}"
    BL="$P/logs/bootstrap_log.txt"; mkdir -p "$P/logs"
    # fatal-o and fatal-both write what ML2's failed start logged: its "Add pending download:" lines (the
    # fixture, or the file STUB_ADDS names) and then the fatal line, each ending in a carriage return as every
    # line of Steam's log does
    cr() { sed "s/\$/$(printf '\r')/"; }
    online="[2026-11-12 17:58:47] Error: Steam needs to be online to update. Please confirm your network connection and try again."
    case "$kind" in
      ok) : > "$ST/steam"; : > "$ST/helper-next" ;;
      fatal-u) : > "$ST/steam"; echo "[2026-11-10 20:40:49] Error: Failed to determine download location for universe 1" >> "$BL" ;;
      fatal-o) : > "$ST/steam"; { cat "${STUB_ADDS:-$FIX_BOOT}"; echo "$online"; } | cr >> "$BL" ;;
      fatal-both) : > "$ST/steam"; { cat "$FIX_BOOT"; echo "[2026-11-12 17:58:40] Error: Failed to determine download location for universe 1"; echo "$online"; } | cr >> "$BL" ;;
      blip) : > "$ST/steam"; echo 2 > "$ST/blip" ;;
      slow) : > "$ST/steam" ;;
      gone) ;;
    esac ;;
esac
exit 0
X
cat > "$T/fixbin/wineserver" << 'X'
#!/bin/bash
echo "WINESERVER $* prefix=${WINEPREFIX:-}" >> "$CALLS"
case "$1" in -k) if [ -n "${STUB_WS_STUCK:-}" ]; then rm -f "$ST/steam"; else rm -f "$ST/steam" "$ST/helper"; fi ;; esac
exit 0
X
cat > "$B/sleep" << 'X'
#!/bin/bash
/bin/sleep 0.15
echo "$1 lock=$([ -L "${WINEPREFIX:-/nowhere}/.launcher.lock" ] && echo yes || echo no)" >> "$ST/ticks"
[ "$(wc -l < "$ST/ticks")" -gt 400 ] && { echo "RUNAWAY" >> "$ST/../runaway"; kill -TERM "$PPID"; exit 0; }
[ -f "$ST/tools-pending" ] && [ -z "${STUB_TOOLS_NEVER:-}" ] && { rm "$ST/tools-pending"; : > "$ST/tools"; }
if [ -f "$ST/blip" ]; then
  if [ "$(cat "$ST/blip")" = 2 ]; then rm -f "$ST/steam"; echo 1 > "$ST/blip"; else : > "$ST/steam"; : > "$ST/helper"; rm "$ST/blip"; fi
  exit 0
fi
P="$WINEPREFIX/drive_c/Program Files (x86)/Steam"; M="$P/steamapps/appmanifest_949230.acf"
man() { mkdir -p "$P/steamapps"; printf '"AppState"\n{\n\t"StateFlags"\t\t"%s"\n\t"BytesToDownload"\t\t"%s"\n\t"BytesDownloaded"\t\t"%s"\n}\n' "$1" "$2" "$3" > "$M"; }
if [ -f "$ST/helper" ] && [ -s "$ST/dl" ]; then
  item="$(head -n 1 "$ST/dl")"; sed -i '' 1d "$ST/dl"
  case "$item" in
    41) man 1026 100000000000 41000000000 ;;
    zero) man 1026 0 0 ;;
    installed|installed+game) mkdir -p "$P/steamapps/common/Cities Skylines II"; : > "$P/steamapps/common/Cities Skylines II/Cities2.exe"; man 4 0 0
              [ "$item" = installed+game ] && : > "$ST/game" ;;
    quit) rm -f "$ST/steam" "$ST/helper" ;;
  esac
fi
[ -f "$ST/helper-next" ] && { rm "$ST/helper-next"; : > "$ST/helper"; }
exit 0
X
cat > "$B/pgrep" << 'X'
#!/bin/bash
case "$2" in
  *Cities2*) [ -f "$ST/game" ] && echo 99901 ;;
  steamwebhelper.exe) [ -f "$ST/helper" ] && echo 99903 ;;
  '[Ss]team\.exe') [ -f "$ST/steam" ] && echo 99902; [ -f "$ST/foreign" ] && echo 99904; [ -f "$ST/lookalike" ] && echo 99905 ;;
  steam) [ -f "$ST/steam" ] && echo 99902; [ -f "$ST/helper" ] && echo 99903; [ -f "$ST/foreign" ] && echo 99904 ;;
esac
exit 0
X
cat > "$B/ps" << 'X'
#!/bin/bash
case "$*" in *99903*) echo 'C:\Program Files (x86)\Steam\bin\cef\cef.win7x64\steamwebhelper.exe' ;; *) echo 'C:\Program Files (x86)\Steam\steam.exe' ;; esac
X
cat > "$B/lsof" << 'X'
#!/bin/bash
case "$*" in
  *99901*) echo "wine64 ${STUB_GAME_OTHER:-${WINEPREFIX:-}}/drive_c/x" ;;
  *99904*) echo "wine64 $HOME/Applications/Other Game.app/Contents/SharedSupport/prefix/drive_c/x" ;;   # another wrapper's Steam
  *99905*) echo "grep /usr/bin/grep" ;;                                                                  # a line that names steam.exe
  *) echo "wine64 ${WINEPREFIX:-}/drive_c/x" ;;
esac
X
cat > "$B/curl" << 'X'
#!/bin/bash
echo "CURL $*" >> "$CALLS"
case " $* " in *" -w "*)   # the installer's own transfer: the exit code and the byte count it prints are settings
  echo "XFER starts=$(cat "$ST/starts" 2>/dev/null || echo 0) steam=$([ -f "$ST/steam" ] && echo up || echo down)" >> "$CALLS"
  echo "curl: (${STUB_XFER_RC:-0}) the transfer's own words" >&2
  printf '%s' "${STUB_XFER_BYTES:-0}"; exit "${STUB_XFER_RC:-0}" ;;
esac
out=""; url=""; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2 ;; *) url="$1"; shift ;; esac; done
host="${url#https://}"; host="${host%%/*}"
fail() { [ -z "${STUB_CURL_WORDS:-}" ] || echo "curl: ($1) $2" >&2; exit "$1"; }   # curl's own words only when a case asks for them
case "$url" in *fastly*) [ -n "${STUB_CURL_FIRST_FAIL:-}" ] && fail 18 "Transferred a partial file" ;; esac
[ -n "${STUB_CURL_FAIL:-}" ] && fail 6 "Could not resolve host: $host"
cp "$FIXBIN/SteamSetup.${STUB_STEAMFILE:-good}" "$out"
X
cat > "$B/softwareupdate" << 'X'
#!/bin/bash
echo "SOFTWAREUPDATE $*" >> "$CALLS"; [ -n "${STUB_ROSETTA_STAYS_MISSING:-}" ] || : > "$ST/rosetta"
X
cat > "$B/xcode-select" << 'X'
#!/bin/bash
case "$1" in
  -p) if [ -n "${STUB_NO_TOOLS:-}" ] && [ ! -f "$ST/tools" ]; then echo "XS -p fail" >> "$CALLS"; exit 2; fi
      echo "XS -p ok" >> "$CALLS"; echo /Library/Developer/CommandLineTools ;;
  --install) echo "XS --install" >> "$CALLS"; : > "$ST/tools-pending" ;;
esac
X
printf '#!/bin/bash\necho "PY" >> "$CALLS"; exit "${STUB_PY_EXIT:-0}"\n' > "$B/python3"
printf '#!/bin/bash\necho "ROUTE $*" >> "$CALLS"; [ -n "${STUB_ROUTE_FAIL:-}" ] && exit 1\necho "   route to: default"; echo "  interface: ${STUB_IFACE:-en0}"\n' > "$B/route"
printf '#!/bin/bash\necho "CAFF $*" >> "$CALLS"\n' > "$B/caffeinate"
printf '#!/bin/bash\necho "KILL $*" >> "$CALLS"; rm -f "$ST/steam" "$ST/helper"\n' > "$B/killrec"
printf '#!/bin/bash\nif [ "$1" = -u ] && [ -n "${STUB_ROOT:-}" ]; then echo 0; else exec /usr/bin/id "$@"; fi\n' > "$B/id"
printf '#!/bin/bash\necho "Filesystem 1024-blocks Used Available Capacity Mounted"\necho "/dev/x 999999999 1 ${STUB_DF_KB:-999999999} 1%% /"\n' > "$B/df"
chmod +x "$B"/* "$T/fixbin"/* "$R/cities-skylines-2/scripts"/*.sh "$R/common"/*.sh
{ printf 'MZ'; head -c 2100000 /dev/zero; printf 'Valve Corp.'; } > "$T/fixbin/SteamSetup.good"
{ printf 'XX'; head -c 2100000 /dev/zero; printf 'Valve Corp.'; } > "$T/fixbin/SteamSetup.nomz"
{ printf 'MZ'; head -c 2100000 /dev/zero; } > "$T/fixbin/SteamSetup.novalve"
{ printf 'MZ'; head -c 1000 /dev/zero; printf 'Valve Corp.'; } > "$T/fixbin/SteamSetup.small"

# --- scenarios
n=0
newh() {   # a fresh HOME, state and call log
  n=$((n + 1)); H="$T/h$n"; mkdir -p "$H/Applications"; rm -rf "$ST"; mkdir -p "$ST"; : > "$ST/ticks"; : > "$CALLS"; : > "$ST/dl"
  WR="$H/Applications/$NEWNAME"; PFX="$WR/Contents/SharedSupport/prefix"; SD="$PFX/drive_c/Program Files (x86)/Steam"
}
NEWNAME="$(bash "$REPO/common/wrappers.sh" name game 949230)"   # what a wrapper the installer makes is named
OLDNAME=CS2dxmt11.app                                         # the old name, a fixture (common/test-wrappers.sh, WT12)
done_all() { bash "$MKW" "$WR" mark steam game 4; }     # every step done, in a wrapper the installer made
dl() { printf '%s\n' "$@" > "$ST/dl"; }               # what the download does, one item per poll once Steam's client is up
run() {    # [install.sh arguments]: HOME=$H; output in $H.out; echoes the exit code, or "timeout"
  local p i=0
  env -u CS2_WRAPPER -u L1_TRACE -u CS2_VIA_INSTALLER HOME="$H" PATH="$B:$PATH" L1_KILL="$B/killrec" \
    bash "$S" "$@" > "$H.out" 2>&1 < /dev/null & p=$!
  while kill -0 "$p" 2>/dev/null; do i=$((i + 1)); [ "$i" -gt 900 ] && { kill "$p"; wait "$p" 2>/dev/null; echo timeout; return; }; /bin/sleep 0.1; done
  wait "$p"; echo $?
}
ptya() {   # <typed line> [install.sh arguments]: at a terminal, with <typed line> typed
  local typed="$1"; shift
  { /bin/sleep 1; printf '%s\n' "$typed"; /bin/sleep 5; } | env -u CS2_WRAPPER -u L1_TRACE -u CS2_VIA_INSTALLER HOME="$H" PATH="$B:$PATH" \
    L1_KILL="$B/killrec" script -q /dev/null bash "$S" "$@" > "$H.out" 2>&1; echo $?
}
said() { grep -c -- "$1" "$H.out"; }
calls() { grep -c -- "$1" "$CALLS"; }
starts() { cat "$ST/starts" 2>/dev/null || echo 0; }

# --- which wrapper: install.sh's choice equals the launcher's once the wrapper exists
chosen() {   # the wrapper install.sh used under --check, resolved
  local m; m="$(sed -n 's/^MAKEWRAPPER .*--wrapper \(.*\) --mark game 949230 --check$/\1/p' "$CALLS")"
  [ -n "$m" ] || m="$(sed -n 's/^  OK: \(.*\)$/\1/p' "$H.out" | sed "s#^~#$H#")"
  [ -d "$m" ] || bash "$MKW" "$m" mark   # as make-wrapper.sh --mark would have made it
  (cd "$m" && pwd -P)
}
launchers_choice() {   # the launcher's choice: common/wrappers.sh, which it reads (docs/plans/wrapper-names.md, 3.2)
  env -u CS2_WRAPPER HOME="$H" ${1:+CS2_WRAPPER="$1"} bash -c '. "$1"; w="$(l1w_find game 949230)"; cd "$w" && pwd -P' _ "$REPO/common/wrappers.sh"
}
newh; run --check > /dev/null; check "wrapper rule: an empty home" "$(chosen)" "$(launchers_choice)"
check "  ...the wrapper to be made has the resolver's name, and is marked" "$(grep -c -- "--wrapper $H/Applications/$NEWNAME --mark game 949230 --check\$" "$CALLS")" 1
newh; done_all; run --check > /dev/null; check "wrapper rule: the installer's own wrapper, found by its marker" "$(chosen)" "$(launchers_choice)"
newh; bash "$MKW" "$H/Applications/$OLDNAME" steam game 4; run --check > /dev/null; check "wrapper rule: an old-named wrapper" "$(chosen)" "$(launchers_choice)"
check "  ...used, and nothing said of it" "$(chosen | sed 's#.*/##'):$(said 'which holds the game')" "$OLDNAME:0"
newh; bash "$MKW" "$H/Applications/CS2.app" steam game 4; run --check > /dev/null
check "wrapper rule: CS2.app with the game" "$(chosen)" "$(launchers_choice)"
check "  ...named, with ~" "$(said 'Using ~/Applications/CS2.app, which holds the game.')" 1
newh; bash "$MKW" "$H/Applications/CS2.app"; run --check > /dev/null
check "wrapper rule: CS2.app without the game: the installer uses it, and no wrapper is made" "$(chosen)" "$(launchers_choice)"
check "  ...which is CS2.app, and the maker is not called" "$(chosen | sed 's#.*/##'):$(calls MAKEWRAPPER)" "CS2.app:0"
newh; mkdir -p "$H/Applications/CS2.app/Contents"; run --check > /dev/null
check "wrapper rule: CS2.app with no prefix and no other wrapper: the maker called with the new name, as it was with the old" \
  "$(grep -c -- "--wrapper $H/Applications/$NEWNAME --mark game 949230 --check\$" "$CALLS")" 1
newh; mkdir -p "$H/Applications/$OLDNAME/Contents"
check "an old-named app with no prefix and no other wrapper: exit 1, the looks-incomplete line, the maker not called" \
  "$(run):$(said "~/Applications/$OLDNAME looks incomplete"):$(calls MAKEWRAPPER)" "1:1:0"
newh; bash "$MKW" "$H/Applications/a.app" mark steam game 4; bash "$MKW" "$H/Applications/b.app" mark steam game 4
check "two wrappers marked alike: exit 1 before anything, the duplicates line, setup not run (WT4b)" \
  "$(run):$(said 'Move one to the Trash, or name the one to use in CS2_WRAPPER.'):$(calls SETUP):$(calls MAKEWRAPPER)" "1:1:0:0"
newh; bash "$MKW" "$H/Applications/Other.app" steam game 4; run --check > /dev/null
check "wrapper rule: the game under another name" "$(chosen)" "$(launchers_choice)"
newh; bash "$MKW" "$H/Applications/A.app" steam game 4; bash "$MKW" "$H/Applications/B.app" steam game 4; run --check > /dev/null
check "wrapper rule: two holding the game" "$(chosen)" "$(launchers_choice)"
newh; mkdir -p "$T/my w$n"; rc="$(env -u L1_TRACE CS2_WRAPPER="$T/my w$n/X.app" HOME="$H" PATH="$B:$PATH" bash "$S" --check > "$H.out" 2>&1; echo $?)"
check "wrapper rule: CS2_WRAPPER with a space, to be made" "$rc:$(chosen)" "0:$(launchers_choice "$T/my w$n/X.app")"
newh; check "a relative CS2_WRAPPER: exit 2" "$(env CS2_WRAPPER=Applications/X.app HOME="$H" PATH="$B:$PATH" bash "$S" > "$H.out" 2>&1; echo $?)" 2
newh; bash "$MKW" "$WR"; rm "$WR/Contents/SharedSupport/wine/bin/wine64"
check "a wrapper without wine64: exit 1, nothing deleted" "$(run):$([ -d "$PFX" ] && echo kept)" "1:kept"
newh; WR="$H/Applications/$OLDNAME"; bash "$MKW" "$WR"; rm -rf "$WR/Contents/SharedSupport/prefix"
check "a wrapper without a prefix folder: exit 1, nothing deleted" "$(run):$([ -d "$WR/Contents/SharedSupport/wine" ] && echo kept)" "1:kept"

# --- all done: only setup runs
newh; done_all
check "all done: exit 0" "$(run)" 0
check "  ...setup run once, with CS2_VIA_INSTALLER=1 and the wrapper, and told no wrapper was given" "$(grep -c "^SETUP  via=1 wrapper=$(cd "$WR" && pwd -P) given=0\$" "$CALLS")" 1
check "  ...nothing else changed: no Steam start, no wrapper made, no download, no Rosetta, no Apple box" \
  "$(calls '^WINE '):$(calls MAKEWRAPPER):$(calls CURL):$(calls SOFTWAREUPDATE):$(calls 'XS --install')" "0:0:0:0:0"
# the installer starts caffeinate in the background, so its stub may write its line after the installer has
# exited: wait up to 3 s for it (seen 2026-11-13: the check read 0 in 1 run of 5 on a busy Mac)
_i=0; while [ "$_i" -lt 30 ] && ! grep -qE '^CAFF -i -w [0-9]+$' "$CALLS"; do /bin/sleep 0.1; _i=$((_i + 1)); done
check "  ...the Mac kept awake while it runs" "$(grep -cE '^CAFF -i -w [0-9]+$' "$CALLS")" 1
check "  ...the closing line for exit 0" "$(said '^Done. Start the game from Applications')" 1
check "  ...the lock released" "$([ -L "$PFX/.launcher.lock" ] && echo held || echo free)" free
check "  ...the home folder nowhere in the output" "$(grep -c "$H" "$H.out")" 0
newh; done_all; rc="$(STUB_SETUP_EXIT=1 run)"
check "setup fails: its exit code, and the stopped line" "$rc:$(said '^The install stopped.')" "1:1"
NOFIX_LINE="The install is finished, but not every Mac fix is out yet for this build of the game: the lines marked >> above say more. You can try the game from Applications: Cities Skylines II, or 14unch3r."
newh; done_all; rc="$(STUB_SETUP_EXIT=5 run)"
check "setup exits 5 (a fix not out yet): exit 5, WORDS_NOFIX's sentence last, neither Done. nor The install stopped" \
  "$rc:$(tail -n 1 "$H.out"):$(said '^Done\.'):$(said '^The install stopped')" "5:$NOFIX_LINE:0:0"
S2="$R/cities-skylines-2/scripts/install-nowords.sh"; sed '/^WORDS_NOFIX=/d' "$S" > "$S2"
newh; done_all; rc="$(S="$S2" STUB_SETUP_EXIT=5 run)"
check "  ...a game that sets no WORDS_NOFIX: 5 is any other code, the stopped line" \
  "$rc:$(grep -c '^WORDS_NOFIX=' "$S2"):$(said '^The install stopped\. The lines above say why\. Open the installer again to carry on from that step\.$'):$(said 'not every Mac fix')" "5:0:1:0"
newh; done_all; run --yes --desktop > /dev/null
check "--yes and --desktop reach setup" "$(grep -c '^SETUP --yes --desktop via=1' "$CALLS")" 1
newh; done_all
check "--no-setup: exit 0, its own line, setup not run" "$(run --no-setup):$(said 'Stopped before step 6, as asked.'):$(grep -c '^SETUP  via' "$CALLS"):$(said '^Done.')" "0:1:0:0"

# --- guards
newh; done_all; : > "$ST/game"
check "the game running: exit 3, before step 1" "$(run):$(said 'Step 1'):$(calls '^SETUP')" "3:0:0"
newh; done_all; ln -s $$ "$PFX/.launcher.lock"
check "a live lock holder: exit 3, nothing done" "$(run):$(calls '^SETUP')" "3:0"
rm -f "$PFX/.launcher.lock"
newh; done_all
check "run as root: exit 1" "$(STUB_ROOT=1 run):$(calls '^SETUP')" "1:0"
check "a wrong option: exit 2" "$(env HOME="$H" PATH="$B:$PATH" bash "$S" --nope > /dev/null 2>&1; echo $?)" 2

# --- step 1: Rosetta
newh; done_all; rc="$(STUB_NO_ROSETTA=1 run)"
check "Rosetta missing, no terminal: exit 3, the command, softwareupdate not run" "$rc:$(said 'softwareupdate --install-rosetta --agree-to-license'):$(calls SOFTWAREUPDATE)" "3:1:0"
rc="$(STUB_NO_ROSETTA=1 ptya n)"; check "  ...n at a terminal: exit 3, not run" "$rc:$(calls SOFTWAREUPDATE)" "3:0"
: > "$CALLS"; rc="$(STUB_NO_ROSETTA=1 ptya '')"; check "  ...Return at a terminal: exit 3, not run" "$rc:$(calls SOFTWAREUPDATE)" "3:0"
: > "$CALLS"; rm -f "$ST/rosetta"; rc="$(STUB_NO_ROSETTA=1 ptya y)"
check "  ...y: softwareupdate with exactly the two options, then on to setup" "$rc:$(grep -cx 'SOFTWAREUPDATE --install-rosetta --agree-to-license' "$CALLS"):$(grep -c '^SETUP  via=1' "$CALLS")" "0:1:1"
: > "$CALLS"; rm -f "$ST/rosetta"; rc="$(STUB_NO_ROSETTA=1 run --yes)"
check "  ...--yes: installed without asking" "$rc:$(calls SOFTWAREUPDATE)" "0:1"
: > "$CALLS"; rm -f "$ST/rosetta"; rc="$(STUB_NO_ROSETTA=1 STUB_ROSETTA_STAYS_MISSING=1 run --yes)"
check "  ...still missing afterwards: exit 1" "$rc" 1

# --- step 2: Apple's Command Line Tools
newh; done_all; rc="$(STUB_NO_TOOLS=1 run)"
check "tools missing: Apple asked once, then on when they arrive" "$rc:$(calls 'XS --install'):$(grep -c '^SETUP  via=1' "$CALLS")" "0:1:1"
check "  ...python3 not run before xcode-select -p succeeds" "$(awk '/^XS -p ok/ { ok = 1 } /^PY$/ && !ok { bad = 1 } END { print bad ? "early" : "after" }' "$CALLS")" after
newh; done_all; sed -i '' 's/^TOOLS_POLLS=720 /TOOLS_POLLS=3 /' "$C"; rc="$(STUB_NO_TOOLS=1 STUB_TOOLS_NEVER=1 run)"
check "  ...they never arrive: exit 4" "$rc" 4
sed -i '' 's/^TOOLS_POLLS=3 /TOOLS_POLLS=720 /' "$C"
newh; done_all; rc="$(STUB_PY_EXIT=1 run)"
check "tools there, python3 broken: exit 1, Apple not asked" "$rc:$(calls 'XS --install')" "1:0"

# --- step 3: the wrapper
# UT2 (docs/plans/built-in-update.md, U0): the free-space caution is for an install that still has to download
newh; done_all
check "low space on a finished install: no CAUTION, and on" "$(STUB_DF_KB=50000000 run):$(said 'CAUTION: ')" "0:0"
newh; bash "$MKW" "$WR" steam game 6
check "low space with a game update waiting: no CAUTION" "$(STUB_DF_KB=50000000 run):$(said 'CAUTION: ')" "0:0"
newh; bash "$MKW" "$WR" steam game 1026; dl installed
check "low space with a download that stopped: the CAUTION, and on" "$(STUB_DF_KB=50000000 run):$(said 'CAUTION: 47 GB free')" "0:1"
newh; rc="$(STUB_DF_KB=50000000 STUB_MW_EXIT=1 run)"
check "low space and no wrapper yet: the CAUTION, and no unbound variable" "$rc:$(said 'CAUTION: 47 GB free'):$(said 'unbound variable')" "1:1:0"
newh; rc="$(STUB_MW_EXIT=1 run)"; check "make-wrapper fails: exit 1" "$rc" 1
newh; rc="$(STUB_MW_EXIT=3 run)"; check "make-wrapper finds another build at work: exit 3" "$rc" 3
newh; : > "$ST/game"; STUB_GAME_OTHER="$T/elsewhere"; export STUB_GAME_OTHER; dl installed
rc="$(run)"; unset STUB_GAME_OTHER
check "a wrapper to be made, with a game running in another wrapper: made, not taken for ours" "$rc:$(grep -c "^MAKEWRAPPER --engine-url https://github.com/vitor251093/porting-kit-engines/releases/download/wineskin/WS12Wine11.0_DXMT-v0.80.tar.7z --engine-bytes 180784324 --engine-sha afdaab97e84ec7064b8fddf47192c95b18b8bbb9cc3aa4d81060a57d7b4dced0 --wrapper $H/Applications/$NEWNAME --mark game 949230\$" "$CALLS")" "0:1"
# (with no prefix yet, set -u stops the copied function inside its own pipeline, so the game is not taken for
# ours either way; what the guard saves is the shell's error line in the player's Terminal)
check "  ...and no copied function was run before there was a prefix" "$(said 'unbound variable')" 0

# --- step 4: Steam
newh; bash "$MKW" "$WR"; dl installed; rc="$(run)"
check "no Steam: fetched over https from Valve, installed with /S, then on" "$rc:$(grep -c 'CURL --proto =https --tlsv1.2 -fsSL --retry 2 -o .* https://cdn.fastly.steamstatic.com/client/installer/SteamSetup.exe$' "$CALLS"):$(grep -c '^WINE .*SteamSetup.exe /S dll=winemenubuilder.exe=d$' "$CALLS")" "0:1:1"
check "  ...an unknown sha256: a CAUTION line" "$(said 'CAUTION: this is a newer installer')" 1
check "  ...wineserver waited for in this prefix" "$(grep -c "^WINESERVER -w prefix=$(cd "$PFX" && pwd -P)\$" "$CALLS")" 2
newh; bash "$MKW" "$WR"; dl installed; rc="$(STUB_CURL_FIRST_FAIL=1 run)"
check "the first address fails: the second is tried" "$rc:$(grep -c 'cdn.akamai.steamstatic.com' "$CALLS")" "0:1"
# curl's own words (docs/plans/first-run-findings.md, 2.2, FT2): shown only when every address has failed
newh; bash "$MKW" "$WR"; dl installed; rc="$(STUB_CURL_FIRST_FAIL=1 STUB_CURL_WORDS=1 run)"
check "the first address fails with curl's words and the second works: none of them on screen" \
  "$rc:$(grep -c 'cdn.akamai.steamstatic.com' "$CALLS"):$(said 'curl:'):$(said 'partial file')" "0:1:0:0"
newh; bash "$MKW" "$WR"; mkdir "$T/tmp$n"; rc="$(STUB_CURL_FAIL=1 STUB_CURL_WORDS=1 TMPDIR="$T/tmp$n" run)"
check "both addresses fail: exit 1, the installer's sentence, then both tries' words indented under it" \
  "$rc:$(grep -A 2 "^  !! Steam's installer could not be downloaded from Valve\. Check the network, then open the installer again\.\$" "$H.out" | sed 1d | tr '\n' '|')" \
  "1:     curl: (6) Could not resolve host: cdn.fastly.steamstatic.com|     curl: (6) Could not resolve host: cdn.akamai.steamstatic.com|"
check "  ...Steam's installer not run, and nothing left in the temporary folder" "$(calls 'SteamSetup.exe /S'):$(ls -A "$T/tmp$n" | wc -l | tr -d ' ')" "0:0"
for k in nomz novalve small; do
  newh; bash "$MKW" "$WR"; rc="$(STUB_STEAMFILE=$k run)"
  check "a downloaded file that fails one test ($k): exit 1, not run" "$rc:$(calls 'SteamSetup.exe /S')" "1:0"
done
newh; bash "$MKW" "$WR"; check "Steam's installer exits 1: exit 1" "$(STUB_SETUP_RC=1 run)" 1
newh; bash "$MKW" "$WR"; check "no steam.exe afterwards: exit 1" "$(STUB_SETUP_NOEXE=1 run)" 1
newh; bash "$MKW" "$WR" steam game 4; check "Steam.exe alone counts as Steam" "$(run):$(calls CURL)" "0:0"

# --- step 5: the game
newh; bash "$MKW" "$WR" steam game 6
check "an update waiting (6): its line, on to setup, Steam not started" "$(run):$(said 'Steam has a game update waiting'):$(starts):$(grep -c '^SETUP  via=1' "$CALLS")" "0:1:0:1"
newh; bash "$MKW" "$WR" steam game-nomanifest; dl installed
check "the game present with no manifest: Steam started" "$(run):$(starts)" "0:1"
newh; bash "$MKW" "$WR" steam game 1026; dl installed
check "the game present with 1026 (a download that stopped): Steam started" "$(run):$(starts)" "0:1"
newh; bash "$MKW" "$WR" steam; dl - installed; : > "$SD/.crash"
rc="$(run)"
check "a fresh start: the stale .crash gone before it, the words, -shutdown before setup" \
  "$rc:$(sed -n 1p "$ST/startlog" | sed 's/.*crash=//'):$(said 'Do not press it'):$(awk '/-shutdown/ { s = NR } /^SETUP  via=1/ { u = NR } END { print (s && u && s < u) ? "ordered" : "not" }' "$CALLS")" "0:no:1:ordered"
check "  ...no wineserver call without the prefix" "$(grep '^WINESERVER' "$CALLS" | grep -c 'prefix=$')" 0
# docs/plans/first-run-findings.md, 2.10, FT3c: Steam's updater cannot be kept off screen, so it is named
check "  ...before Steam's start: the updater's window and its Cancel are named, and the error box, with no size or time in them" \
  "$(grep -A 3 '^Step 5 of 6: The game$' "$H.out" | sed 1d | tr '\n' '|'):$(grep -A 3 '^Step 5 of 6: The game$' "$H.out" | sed 1d | grep -c '[0-9]'):$(said 'That is expected: Steam is updating itself')" \
  '  Steam for Windows is starting. The first time, a small window that says "Updating Steam..." shows|  Steam downloading its own update: leave it, and do not press its Cancel. A box headed|  "Steam - Fatal Error" can also appear once or twice and close again: click nothing in it.|:0:0'
check "  ...the lock held while it waited" "$(grep -c 'lock=yes' "$ST/ticks" | awk '{ print ($1 > 0) ? "held" : "never" }')" held
check "  ...the home folder nowhere in the output" "$(grep -c "$H" "$H.out")" 0
newh; bash "$MKW" "$WR" steam; dl - installed
rc="$(STUB_STARTS="fatal-u ok" STUB_IFACE=utun4 run)"
check "a first start that ends in its fatal line (fatal-u): ended in this prefix, started again at once" \
  "$rc:$(starts):$(grep -c "^WINESERVER -k prefix=$(cd "$PFX" && pwd -P)\$" "$CALLS" | awk '{ print ($1 > 0) }'):$(sed -n 2p "$ST/startlog" | awk '{ print ($5 <= 3) ? "soon" : "late" }')" "0:2:1:soon"
check "  ...with no transfer of the installer's own, no look at the route and no word of a VPN" "$(calls '^XFER'):$(calls '^ROUTE'):$(grep -ci vpn "$H.out")" "0:0:0"

# --- Steam's own update is cut (docs/plans/first-run-findings.md, 2.1, FT1). "Steam needs to be online" ends
# --- that Steam and starts no other until one transfer of the installer's own has said what the path does.
BIG="https://cdn.steamstatic.com/client/bins_cef_win32_win7-64.zip.vz.cd0b352c7e651dd695c51a894a3973eb2efbee4b_105972111"
XFER="CURL -q --proto =https --proto-redir =https --tlsv1.2 --globoff -fsSL --max-time 20 -o /dev/null -w %{size_download} --"
O7='fatal-o fatal-o fatal-o fatal-o fatal-o fatal-o fatal-o'   # more than the limit: a start too many fails too, and is counted
# No start of these cases waits past its first look. The limit of one start is shortened for them, so that a
# mutant under which the fatal line is not seen ends each case in seconds, not at the runaway guard.
sed -i '' 's/^START_POLLS=120 /START_POLLS=4 /' "$C"
seed() { sed "s/\$/$(printf '\r')/" >> "$SD/logs/bootstrap_log.txt"; }   # lines of an earlier run in Steam's log
form() {   # the form of 2.1 the output ends in, whole lines with nothing after them: vpn later none reach plain, or other
  local c="  !! Steam could not download its own update: the connection to Valve's server keeps being cut."
  local w="     Open the installer again in a few minutes. It carries on from this step."
  local l="     Steam's own log, if you ask for help: ~/Applications/$NEWNAME/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/logs/bootstrap_log.txt"
  local nl=$'\n'
  case "$(tail -n 4 "$H.out")" in
    "$c$nl     This Mac is using a VPN, which may be the cause. Change the VPN's server or pause it,$nl     then open the installer again. It carries on from this step.$nl$l") echo vpn; return ;;
  esac
  case "$(tail -n 3 "$H.out")" in
    "$c$nl$w$nl$l") echo later ;;
    "  !! Steam could not download its own update: this Mac cannot reach Valve's server.$nl     Check the network, then open the installer again. It carries on from this step.$nl$l") echo none ;;
    "  !! Steam could not download its own update, although this Mac reaches Valve's server.$nl$w$nl$l") echo reach ;;
    "  !! Steam could not download its own update.$nl$w$nl$l") echo plain ;;
    *) echo other ;;
  esac
}
# what no such run may hold: a line of Steam's log, today's words, the core's closing line for 4, curl's own
# words, the home folder's path; and setup is not run
leaks() { echo $(( $(said 'Error:') + $(said 'Add pending') + $(said 'did not start') + $(said '^Open the installer again: it carries on from here') + $(said 'curl:') + $(grep -c "$H" "$H.out") + $(grep -c '^SETUP  via' "$CALLS") )); }
stopped() {   # <name> <form> <starts> <transfers> <looks at the route>: a run that ended in one of the forms
  check "$1: exit 4, the $2 form, $3 start(s), Steam not left running" \
    "$rc:$(form):$(starts):$([ -f "$ST/steam" ] && echo up || echo down):$(calls '^XFER'):$(calls '^ROUTE'):$(grep -ci vpn "$H.out"):$(leaks)" \
    "4:$2:$3:down:$4:$5:$([ "$2" = vpn ] && echo 1 || echo 0):0"
}
came_up() {   # <name> <starts> <transfers>: a run in which Steam came up after all: no word of any of it
  check "$1: exit 0, $2 start(s), no words" \
    "$rc:$(starts):$(calls '^XFER'):$(calls '^ROUTE'):$(said 'could not download'):$(grep -ci vpn "$H.out")" "0:$2:$3:0:0:0"
}
newh; bash "$MKW" "$WR" steam
echo "[2026-11-09 10:00:00] Add pending download: https://cdn.steamstatic.com/client/from_an_earlier_start.zip.vz.0000_999999999" | seed
rc="$(STUB_STARTS="$O7" STUB_XFER_RC=18 STUB_IFACE=utun4 run)"
stopped "needs to be online, the transfer cut (18), a tunnel" vpn 1 1 1
check "  ...that Steam was ended and no other started before the transfer" "$(grep '^XFER' "$CALLS")" "XFER starts=1 steam=down"
check "  ...one transfer, with the options of 2.1, of the largest file asked for since that start, no carriage return on it" \
  "$(calls '^CURL -q'):$(grep -cxF "$XFER $BIG" "$CALLS")" "1:1"
for c in 56 92; do
  newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=$c STUB_IFACE=utun4 run)"; stopped "the transfer cut ($c), a tunnel" vpn 1 1 1
done
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=18 run)"; stopped "the transfer cut (18), no tunnel" later 1 1 1
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=18 STUB_IFACE=utun4 STUB_ROUTE_FAIL=1 run)"; stopped "the transfer cut (18), the route not told" later 1 1 1
for c in 6 7; do
  newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=$c STUB_IFACE=utun4 run)"; stopped "no network ($c), a tunnel" none 1 1 0
done
for c in 0 28; do
  newh; bash "$MKW" "$WR" steam; dl - installed
  rc="$(STUB_STARTS="fatal-o ok" STUB_XFER_RC=$c STUB_XFER_BYTES=20000000 STUB_IFACE=utun4 run)"; came_up "the transfer working ($c with 20,000,000 bytes), a tunnel, and the next start comes up" 2 1
  newh; bash "$MKW" "$WR" steam
  rc="$(STUB_STARTS="$O7" STUB_XFER_RC=$c STUB_XFER_BYTES=20000000 STUB_IFACE=utun4 run)"; stopped "  ...and the four starts that are left all end in a fatal line" reach 5 1 0
done
newh; bash "$MKW" "$WR" steam; dl - installed
rc="$(STUB_STARTS="fatal-o ok" STUB_XFER_RC=28 STUB_XFER_BYTES=19999999 STUB_IFACE=utun4 run)"; came_up "not known (28 with 19,999,999 bytes): another start, which comes up" 2 1
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=28 STUB_XFER_BYTES=19999999 STUB_IFACE=utun4 run)"; stopped "not known (28 with 19,999,999 bytes), a tunnel, the starts used up" plain 5 1 0
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_XFER_RC=0 STUB_XFER_BYTES=5572671 STUB_IFACE=utun4 run)"; stopped "not known (0 with 5 MB), a tunnel, the starts used up" plain 5 1 0
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS='fatal-o fatal-u fatal-u fatal-u fatal-u fatal-u' STUB_XFER_RC=22 STUB_XFER_BYTES=20000000 run)"
stopped "not known (22), then four starts that end in the other fatal line" plain 5 1 0
newh; bash "$MKW" "$WR" steam
echo "[2026-11-09 10:00:00] Add pending download: https://cdn.steamstatic.com/client/from_an_earlier_start.zip.vz.0000_999999999" | seed
rc="$(STUB_STARTS="$O7" STUB_ADDS=/dev/null STUB_XFER_RC=18 STUB_IFACE=utun4 run)"; stopped "no address in the log since that start: curl is not run, not known" plain 5 0 0
cat > "$T/adds.odd" << 'X'
[2026-11-12 17:57:24] Add pending download: http://cdn.steamstatic.com/client/plain_http.zip.vz.0000_900000001
[2026-11-12 17:57:24] Add pending download: https://cdn.steamstatic.com.example.net/client/another_host.zip.vz.0000_900000002
[2026-11-12 17:57:24] Add pending download: https://steamstatic.com/client/no_host_before_it.zip.vz.0000_900000003
[2026-11-12 17:57:24] Add pending download: https://name@cdn.steamstatic.com/client/a_name_before_the_host.zip.vz.0000_900000004
[2026-11-12 17:57:24] Add pending download: https://cdn.steamstatic.com/client/deeper/a_folder_more.zip.vz.0000_900000005
[2026-11-12 17:57:24] Add pending download: https://cdn.steamstatic.com/client/a_question_mark.zip?vz=0000_900000006
[2026-11-12 17:57:24] Add pending download: https://cdn.steamstatic.com/client/a space.zip.vz.0000_900000007
[2026-11-12 17:57:24] Add pending download: https://cdn.steamstatic.com/client/no_number_at_its_end.zip.f556f4b9c7e087e07c0fef2da2b1d9f27f734cff
X
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_ADDS="$T/adds.odd" STUB_XFER_RC=18 STUB_IFACE=utun4 run)"
stopped "only addresses outside the pattern: curl is not run, not known" plain 5 0 0
{ cat "$T/adds.odd"
  echo "[2026-11-12 17:57:25] Add pending download: https://cdn.steamstatic.com/client/inside_and_smaller.zip.vz.0000_6000000"
  echo "[2026-11-12 17:57:25] Add pending download: https://client-update.steamstatic.com/inside_with_no_client_folder.zip.vz.0000_7000000"; } > "$T/adds.mixed"
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="$O7" STUB_ADDS="$T/adds.mixed" STUB_XFER_RC=18 run)"
stopped "larger addresses outside the pattern beside smaller ones inside it" later 1 1 1
check "  ...the largest inside the pattern is used" "$(grep -cxF "$XFER https://client-update.steamstatic.com/inside_with_no_client_folder.zip.vz.0000_7000000" "$CALLS")" 1
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS='fatal-both fatal-u fatal-u fatal-u fatal-u fatal-u' STUB_XFER_RC=18 run)"
stopped "both fatal lines new in one look: needs to be online is the one acted on" later 1 1 1
newh; bash "$MKW" "$WR" steam; rc="$(STUB_STARTS="fatal-u $O7" STUB_XFER_RC=7 run)"
stopped "download location, then needs to be online: the first restarts, the second does not" none 2 1 0
newh; bash "$MKW" "$WR" steam; dl - installed
{ cat "$FIX_BOOT"; echo "[2026-11-12 17:58:47] Error: Steam needs to be online to update. Please confirm your network connection and try again."; } | seed
rc="$(STUB_IFACE=utun4 run)"; came_up "an earlier run's needs to be online and its addresses in the log, a tunnel, and a start that comes up" 1 0
newh; bash "$MKW" "$WR" steam; dl - installed
rc="$(STUB_STARTS="fatal-o ok" STUB_XFER_RC=0 STUB_XFER_BYTES=20000000 env -u CS2_WRAPPER HOME="$H" PATH="$B:$PATH" L1_KILL="$B/killrec" L1_TRACE="$T/trace$n" bash "$S" > "$H.out" 2>&1 < /dev/null; echo $?)"
check "L1_TRACE: the transfer's result is one line of the trace, and the screen shows nothing of it" \
  "$rc:$(grep -cE '^[0-9]{2}:[0-9]{2}:[0-9]{2} transfer=working exit=0 bytes=20000000$' "$T/trace$n"):$(grep -c 'transfer=' "$T/trace$n"):$(grep -c 'transfer' "$H.out")" "0:1:1:0"
newh; bash "$MKW" "$WR" steam
rc="$(STUB_STARTS="$O7" STUB_ADDS=/dev/null STUB_XFER_RC=18 env -u CS2_WRAPPER HOME="$H" PATH="$B:$PATH" L1_KILL="$B/killrec" L1_TRACE="$T/trace$n" bash "$S" > "$H.out" 2>&1 < /dev/null; echo $?)"
check "  ...and with no address to try, the line says so" "$rc:$(grep -cE '^[0-9]{2}:[0-9]{2}:[0-9]{2} transfer=unknown no address$' "$T/trace$n"):$(grep -c 'transfer=' "$T/trace$n")" "4:1:1"
sed -i '' 's/^START_POLLS=4 /START_POLLS=120 /' "$C"
newh; bash "$MKW" "$WR" steam; dl - installed
check "a one-poll gap in Steam's process: not started again" "$(STUB_STARTS=blip run):$(starts)" "0:1"
newh; bash "$MKW" "$WR" steam; dl - installed
check "a three-poll gap: started again" "$(STUB_STARTS='gone ok' run):$(starts)" "0:2"
newh; bash "$MKW" "$WR" steam
rc="$(STUB_STARTS='fatal-u fatal-u fatal-u fatal-u fatal-u ok' run)"
check "five fatal starts: exit 1, five starts, Steam ended, its log shown, no setup" \
  "$rc:$(starts):$(said 'did not start after 5 tries'):$(said 'Failed to determine download location' | awk '{ print ($1 > 0) }'):$(grep -c '^SETUP  via' "$CALLS")" "1:5:1:1:0"
check "  ...with no transfer: download location alone never asks for one" "$(calls '^XFER'):$(said 'could not download')" "0:0"
newh; bash "$MKW" "$WR" steam; : > "$ST/steam"; dl - installed; sed -i '' 's/^STUCK_POLLS=12 /STUCK_POLLS=2 /' "$C"
rc="$(run)"; sed -i '' 's/^STUCK_POLLS=2 /STUCK_POLLS=12 /' "$C"
check "a Steam already there with no client: ended, then started" "$rc:$(calls '^WINESERVER -k'):$(starts)" "0:1:1"
newh; bash "$MKW" "$WR" steam; dl - installed; sed -i '' 's/^START_POLLS=120 /START_POLLS=3 /' "$C"
rc="$(STUB_STARTS='slow ok' run)"; sed -i '' 's/^START_POLLS=3 /START_POLLS=120 /' "$C"
check "no client within the limit: ended and started again" "$rc:$(starts):$(calls '^WINESERVER -k' | awk '{ print ($1 > 0) }')" "0:2:1"
newh; bash "$MKW" "$WR" steam; : > "$ST/steam"; : > "$ST/helper"; dl installed
check "a client already up: not started again, straight to the words, and not said to be starting" "$(run):$(starts):$(said 'Do not press it'):$(said 'is starting'):$(said 'Steam for Windows is open.')" "0:0:1:0:1"
newh; bash "$MKW" "$WR" steam; dl - - - installed
check "no manifest yet: the choose-Install line once" "$(run):$(said '^  Waiting for you to choose Install in Steam$')" "0:1"
newh; bash "$MKW" "$WR" steam; dl - zero zero installed
check "BytesToDownload 0: the getting-ready line once, and it waits on" "$(run):$(said '^  Steam is getting the download ready$'):$(starts)" "0:1:1"
newh; bash "$MKW" "$WR" steam; dl - 41 41 installed
check "41 percent: one line for it" "$(run):$(said '41.0 of 100.0 GB (41%)')" "0:1"
newh; bash "$MKW" "$WR" steam; dl - quit
check "Steam closed during the download: exit 4, setup not run, the line for 4" "$(run):$(grep -c '^SETUP  via' "$CALLS"):$(said '^Open the installer again: it carries on from here.')" "4:0:1"
newh; bash "$MKW" "$WR" steam; dl - installed
check "-shutdown not enough: wineserver -k after it" "$(STUB_SHUTDOWN_STUCK=1 run):$(awk '/-shutdown/ { s = 1 } /^WINESERVER -k/ && s { k = 1 } END { print k ? "after" : "none" }' "$CALLS")" "0:after"
newh; bash "$MKW" "$WR" steam; dl - installed
check "a stray left after that: a plain kill, never -9" "$(STUB_SHUTDOWN_STUCK=1 STUB_WS_STUCK=1 run):$(grep -c '^KILL 99903$' "$CALLS"):$(grep -c 'KILL -9' "$CALLS")" "0:1:0"
newh; bash "$MKW" "$WR" steam; dl - installed
rc="$(env -u CS2_WRAPPER HOME="$H" PATH="$B:$PATH" L1_KILL="$B/killrec" L1_TRACE="$T/trace$n" bash "$S" > "$H.out" 2>&1 < /dev/null; echo $?)"
check "L1_TRACE: a line per poll" "$rc:$(grep -cE '^[0-9]{2}:[0-9]{2}:[0-9]{2} steam=[0-9]+ proc=(yes|no) client=' "$T/trace$n" | awk '{ print ($1 >= 2) ? "lines" : "few" }')" "0:lines"

# --- stopped by a signal while it waits (Control-C sends INT; a background job cannot be sent INT, so TERM and HUP)
for sig in TERM HUP; do
  newh; bash "$MKW" "$WR" steam; : > "$ST/steam"; : > "$ST/helper"
  env -u CS2_WRAPPER -u L1_TRACE HOME="$H" PATH="$B:$PATH" L1_KILL="$B/killrec" bash "$S" > "$H.out" 2>&1 < /dev/null & ip=$!
  i=0; until grep -q 'Waiting for you to choose Install' "$H.out" 2>/dev/null || [ "$i" -gt 100 ]; do /bin/sleep 0.1; i=$((i + 1)); done
  kill -"$sig" "$ip"; wait "$ip"; rc=$?
  check "stopped by $sig while it waits: its own line, not Done, the lock released, Steam left running" \
    "$(said '^Stopped. Open the installer again'):$(said '^Done.'):$([ -L "$PFX/.launcher.lock" ] && echo held || echo free):$([ -f "$ST/steam" ] && echo up):$(calls '^WINESERVER -k')" "1:0:free:up:0"
  check "  ...and a signal's exit code" "$rc" "$([ "$sig" = TERM ] && echo 143 || echo 129)"
done

# --- step 6
newh; bash "$MKW" "$WR" steam; dl - installed+game
check "the game started during the wait: exit 3 at step 6, setup not run" "$(run):$(grep -c '^SETUP  via' "$CALLS")" "3:0"
newh; done_all; mv "$R/cities-skylines-2/repatch.sh" "$T/repatch.away"
check "the checkout's files gone: exit 4, setup not run" "$(run):$(grep -c '^SETUP  via' "$CALLS")" "4:0"
mv "$T/repatch.away" "$R/cities-skylines-2/repatch.sh"
# docs/plans/local-files-layout.md, LT22 and LT23
newh; done_all; mv "$R/common/paths.sh" "$T/paths.away"
check "common/paths.sh gone: exit 4, setup not run, and no Rosetta offer made of it" "$(run):$(grep -c '^SETUP  via' "$CALLS"):$(said 'softwareupdate --install-rosetta'):$(calls SOFTWAREUPDATE):$(said "The installer's own files are gone")" "4:0:0:0:1"
mv "$T/paths.away" "$R/common/paths.sh"
# UT5, also (docs/plans/built-in-update.md, 3.3): the files of setup's record of versions are the installer's own too
for gone in updates.sh games.tsv; do
  newh; done_all; mv "$R/common/$gone" "$T/$gone.away"
  check "common/$gone gone: exit 4 in the own-files words, setup not run" "$(run):$(grep -c '^SETUP  via' "$CALLS"):$(said "The installer's own files are gone")" "4:0:1"
  mv "$T/$gone.away" "$R/common/$gone"
done
newh; done_all; mv "$R/cities-skylines-2/scripts/move-install.sh" "$T/mover.away"
check "scripts/move-install.sh gone: exit 4, setup not run" "$(run):$(grep -c '^SETUP  via' "$CALLS")" "4:0"
mv "$T/mover.away" "$R/cities-skylines-2/scripts/move-install.sh"
newh; done_all
check "CS2_PATCH_DIR put in front of the installer reaches setup" "$(CS2_PATCH_DIR=/x/named-folder run):$(cat "$CALLS.patchdir")" "0:/x/named-folder"

# --- --check
newh; done_all
check "--check: exit 0, no closing line, nothing changed" \
  "$(run --check):$(said '^Done.'):$(calls '^WINE'):$(calls '^WINESERVER'):$(calls CURL):$(calls SOFTWAREUPDATE):$(calls CAFF):$(calls 'XS --install')" "0:0:0:0:0:0:0:0"
check "  ...setup only as --mac-only --check" "$(calls '^SETUP'):$(calls '^SETUP --mac-only --check')" "1:1"
newh; bash "$MKW" "$WR" steam
check "--check with the game not installed: Steam not started" "$(run --check):$(calls '^WINE'):$(said 'would start Steam')" "0:0:1"
newh; done_all
check "--check with the tools missing: python3 not run" "$(STUB_NO_TOOLS=1 run --check):$(calls '^PY$'):$(said 'would ask Apple')" "0:0:1"
newh; done_all
check "--check with Rosetta missing: reported, exit 0" "$(STUB_NO_ROSETTA=1 run --check):$(said 'would offer to install it'):$(calls SOFTWAREUPDATE)" "0:1:0"
newh
check "--check on an empty home: make-wrapper asked only to check" "$(run --check):$(grep -c '^MAKEWRAPPER' "$CALLS"):$(grep -c '^MAKEWRAPPER --engine-url .* --wrapper .* --check$' "$CALLS")" "0:1:1"
check "--help prints the usage" "$(bash "$S" --help | grep -c 'exit 0 = done')" 1

# --- the shared part (docs/plans/shared-installer.md, 2.1): added after the installer was divided, so these
# --- cases are in test-install.golden from their first run, after the 96 recorded at 6a66416
check "no line of the shared part that is not a comment names a game or a size" \
  "$(grep -v '^[[:space:]]*#' "$C" | sed 's/[[:space:]]#.*//' | grep -cE 'Cities|Skylines|Surviving|Mars|949230|3215050|CS2_|SM_|CS2dxmt11|[0-9] ?(GB|MB)')" 0
check "  ...and the step a line sends the player on to is worked out, not written in" "$(grep -cE 'to step [0-9]|before step [0-9]' "$C")" 0
newh
check "the engine's pin reaches the wrapper script as its three options" \
  "$(run --check > /dev/null; grep -c '^MAKEWRAPPER --engine-url https://github.com/vitor251093/porting-kit-engines/releases/download/wineskin/WS12Wine11.0_DXMT-v0.80.tar.7z --engine-bytes 180784324 --engine-sha afdaab97e84ec7064b8fddf47192c95b18b8bbb9cc3aa4d81060a57d7b4dced0 --wrapper ' "$CALLS")" 1
newh; done_all; cp "$S" "$T/s.keep"; sed -i '' '/^GAME_TITLE=/d' "$S"; rc="$(run)"; cp "$T/s.keep" "$S"
check "a game that sets no title is refused by the shared part, by the setting's name" "$rc:$(said 'did not set GAME_TITLE')" "1:1"
newh; done_all; sed -i '' '/^TAKES_DESKTOP=/d' "$S"; rc="$(run --desktop)"; cp "$T/s.keep" "$S"
check "--desktop is a wrong option for a game whose setup has none: exit 2, nothing done" "$rc:$(said 'unknown option: --desktop'):$(grep -c '^SETUP' "$CALLS")" "2:1:0"
newh; bash "$MKW" "$WR" steam; : > "$ST/foreign"; rc="$(run)"
check "another wrapper's Steam is open: exit 3, the wrapper named, Steam not started here" \
  "$rc:$(said 'Steam is open in Other Game.app. Quit it'):$(starts):$(grep -c '^SETUP  via' "$CALLS")" "3:1:0:0"
newh; bash "$MKW" "$WR" steam; : > "$ST/foreign"
check "  ...with --check: said, and the report goes on" "$(run --check):$(said 'Steam is open in Other Game.app: the installer would stop here'):$(said 'would run setup.sh')" "0:1:1"
newh; done_all; : > "$ST/foreign"
check "  ...with the game installed Steam is not needed, so it is not looked for" "$(run):$(said 'Steam is open in'):$(grep -c '^SETUP  via=1' "$CALLS")" "0:0:1"
newh; bash "$MKW" "$WR" steam; : > "$ST/lookalike"; dl installed
check "a line that only names steam.exe is not a Steam: the install goes on" "$(run):$(said 'Steam is open in'):$(starts)" "0:0:1"

# --- WT11 (docs/plans/wrapper-names.md): the installer's route through the real setup.sh, wrappers.sh and
#     move-wrappers.sh, in a second scratch copy. Its patch scripts are empty files run by the python3 stub; its
#     window builder a stub; xcrun a stub, so that the app builder compiles nothing; the mover's probe a stub.
R2="$T/repo2"; G2="$R2/cities-skylines-2"; mkdir -p "$R2/common" "$G2/patches/_vendor" "$T/wt11bin"
cp -R "$REPO/cities-skylines-2/scripts" "$REPO/cities-skylines-2/launchers" "$REPO/cities-skylines-2/repatch.sh" "$G2/"
for f in "$REPO"/cities-skylines-2/patches/patch_*.py; do : > "$G2/patches/$(basename "$f")"; done
cp "$S" "$G2/scripts/install.sh"; cp "$C" "$R2/common/install-core.sh"   # the copies under test: a mutant of either applies here too
cp "$REPO/common/paths.sh" "$REPO/common/wrappers.sh" "$REPO/common/move-wrappers.sh" "$R/common/make-wrapper.sh" "$R2/common/"
cp "$REPO/common/updates.sh" "$REPO/common/games.tsv" "$R2/common/"   # the real setup keeps its record of versions (docs/plans/built-in-update.md, 3.3)
printf '#!/bin/bash\nexit 0\n' > "$R2/common/make-launcher-app.sh"; printf '#!/bin/bash\nexit 1\n' > "$T/wt11bin/xcrun"
printf '#!/bin/bash\n[ -n "${STUB_WHOLDERS:-}" ] && echo "$STUB_WHOLDERS"\nexit 0\n' > "$T/wt11bin/wprobe"
# this Mac, the same on any Mac, so that the transcript does not depend on the one it runs on (as scripts/test-setup.sh has it)
printf '#!/bin/bash\n[ "$1" = -productVersion ] && echo 27.2\n' > "$T/wt11bin/sw_vers"
printf '#!/bin/bash\n[ "$*" = "-n hw.optional.arm64" ] && { echo 1; exit 0; }\nexec /usr/sbin/sysctl "$@"\n' > "$T/wt11bin/sysctl"
printf '#!/bin/bash\n[ "$1" = -x86_64 ] && exit 0\nexec /usr/bin/arch "$@"\n' > "$T/wt11bin/arch"
chmod +x "$T/wt11bin"/*
S2="$G2/scripts/setup.sh"
case "${MUTANT:-0}" in
  67) sed -i '' 's#^\[ "\${CS2_VIA_INSTALLER:-0}" = 1 \] \&\& \[ "\${L1_WRAPPER_GIVEN:-}" = 0 \] \&\& unset CS2_WRAPPER$#: no unset#' "$S2"; grep -q '^: no unset$' "$S2" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  68) sed -i '' 's#\[ "\${L1_WRAPPER_GIVEN:-}" = 0 \] \&\& unset CS2_WRAPPER#[ "${L1_WRAPPER_GIVEN:-0}" = 0 ] \&\& unset CS2_WRAPPER#' "$S2"; grep -q 'L1_WRAPPER_GIVEN:-0' "$S2" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  69) sed -i '' 's#a+=(--holders-skip --held-by "\$PPID")#a+=(--held-by "$PPID")#' "$S2"; grep -q -- '--holders-skip --held-by' "$S2" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  75) sed -i '' 's#^  l1u_stamp 949230 "\$REPO/\.\." \&\& return 0$#  return 0   \# no stamp#' "$S2"; grep -q '^  return 0   # no stamp$' "$S2" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
esac
run2() {   # [VAR=value ...] -- [install.sh arguments]: the WT11 copy; output in $H.out; echoes the exit code
  local envs=(); while [ "$1" != -- ]; do envs+=("$1"); shift; done; shift
  env -u CS2_WRAPPER -u L1_TRACE -u CS2_VIA_INSTALLER -u L1_WRAPPER_GIVEN HOME="$H" PATH="$T/wt11bin:$B:$PATH" L1_KILL="$B/killrec" \
    L1_WMOVE_PROBE="$T/wt11bin/wprobe" ${envs[@]+"${envs[@]}"} bash "$G2/scripts/install.sh" "$@" > "$H.out" 2>&1 < /dev/null
  echo $?
}
NW="$H/Applications/$NEWNAME"
oldw() { newh; WR="$H/Applications/$OLDNAME"; bash "$MKW" "$WR" steam game 4; NW="$H/Applications/$NEWNAME"; }
l1p() { plutil -extract L1Prefix raw -o - "$H/Applications/Cities Skylines II.app/Contents/Info.plist" 2>/dev/null; }
oldw
check "WT11 through the real setup: an old-named wrapper, no variable given: renamed and marked, exit 0" \
  "$(run2 --):$([ -d "$NW" ] && echo renamed):$(plutil -extract L1Role raw -o - "$NW/Contents/Info.plist" 2>/dev/null)" "0:renamed:game-wrapper"
check "  ...the app's L1Prefix names the renamed wrapper, and no .launcher.lock is left in it" \
  "$(l1p):$([ -L "$NW/Contents/SharedSupport/prefix/.launcher.lock" ] && echo left || echo none)" "$NW/Contents/SharedSupport/prefix:none"
oldw
check "WT11 the variable given by the caller: nothing renamed, and the line says a wrapper was named" \
  "$(run2 CS2_WRAPPER="$WR" --):$([ -d "$WR" ] && echo kept):$(said 'CS2_WRAPPER names a wrapper')" "0:kept:1"
oldw
rc="$(env -u L1_WRAPPER_GIVEN HOME="$H" PATH="$T/wt11bin:$B:$PATH" L1_WMOVE_PROBE="$T/wt11bin/wprobe" CS2_VIA_INSTALLER=1 CS2_WRAPPER="$WR" bash "$S2" > "$H.out" 2>&1 < /dev/null; echo $?)"
check "WT11 setup alone with CS2_VIA_INSTALLER=1, the variable set and L1_WRAPPER_GIVEN not set: nothing renamed" "$rc:$([ -d "$WR" ] && echo kept)" "0:kept"
# what the root install.sh exports reaches the real setup through the installer: its stamp (docs/plans/built-in-update.md, 3.1)
TAB="$(printf '\t')"
oldw
check "UT5 through the installer and the real setup: the stamp holds the line, no version (this tree has no changelog), the commit and the time" \
  "$(run2 L1_FETCHED_REF=release L1_FETCHED_COMMIT=0123456789abcdef0123456789abcdef01234567 L1_UPDATE_NOW=1800000000 --):$(cat "$(HOME="$H" bash "$R2/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')/installed/949230" 2>/dev/null)" "0:release${TAB}-${TAB}0123456789abcdef0123456789abcdef01234567${TAB}1800000000"
oldw
check "WT11 a holder reported by the probe: the installer exits 0, one skip line, nothing renamed" \
  "$(run2 STUB_WHOLDERS=4242 --):$(said '^  skip: something of the wrapper.s Wine is still running'):$([ -d "$WR" ] && echo kept)" "0:1:kept"

# --- UT7b (docs/plans/built-in-update.md, 3.4 and section 6): the parts joined. The root install.sh, pasted with
#     the word update, fetches an archive of the WT11 copy (a stub curl serves it) and goes through the real
#     driver, this installer and the real setup. The table's other game has a stub installer that keeps no
#     record. The name of the fetch's temporary folder is replaced in what is compared with the transcript.
HWT="$H"   # the last case's home: put back below, so that the closing case's part of the transcript stays as it was
cp "$REPO/common/update-games.sh" "$R2/common/"; printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.1.0 (2026-01-01)' '' 'One.' > "$R2/CHANGELOG.md"
if [ "${MUTANT:-0}" = 76 ]; then
  sed -i '' 's#^  if \[ "\$line" != "\$L1_FETCHED_REF" \]; then$#  if [ "$line" = "$L1_FETCHED_REF" ]; then#' "$R2/common/update-games.sh"
  grep -q '^  if \[ "\$line" = "\$L1_FETCHED_REF" \]; then$' "$R2/common/update-games.sh" || { echo "REFUSED: mutant did not apply"; exit 2; }
fi
OTHER="$(awk -F'\t' '$1 == 3215050 { print $2 }' "$R2/common/games.tsv")"; mkdir -p "$R2/$OTHER/scripts" "$T/ut7bbin" "$T/ut7btmp"
printf '#!/bin/bash\necho "SECOND args=$* update=${L1_UPDATE:-}" >> "$CALLS"\necho "  the other game.s installer (a stub) stops here"\nexit "${STUB_SECOND_EXIT:-0}"\n' > "$R2/$OTHER/scripts/install.sh"
( cd "$T" && tar -czf "$T/ut7b.tar.gz" repo2 )
cat > "$T/ut7bbin/curl" << X
#!/bin/bash
case " \$* " in *"/archive/"*) ;; *) exec "$B/curl" "\$@" ;; esac   # the archive of the repository; anything else is the installer's own
echo "ARCHIVE \$*" >> "\$CALLS"
out=""; while [ \$# -gt 0 ]; do case "\$1" in -o) out="\$2"; shift 2 ;; *) shift ;; esac; done
cp "$T/ut7b.tar.gz" "\$out"; printf 200
X
chmod +x "$T/ut7bbin/curl"
upd() {   # [VAR=value ...]: install.sh update, pasted; HOME=$H; output in $H.out; echoes the exit code
  local rc
  env -u CS2_WRAPPER -u L1_TRACE -u CS2_VIA_INSTALLER -u L1_WRAPPER_GIVEN HOME="$H" TMPDIR="$T/ut7btmp" PATH="$T/ut7bbin:$T/wt11bin:$B:$PATH" \
    L1_KILL="$B/killrec" L1_WMOVE_PROBE="$T/wt11bin/wprobe" L1_UPDATE_NOW=1800000000 "$@" \
    /bin/bash -c "$(cat "$REPO/install.sh")" 1launcher-install update > "$H.raw" 2>&1 < /dev/null; rc=$?
  sed 's#1launcher-fetch\.[A-Za-z0-9]*#1launcher-fetch.X#g' "$H.raw" > "$H.out"; echo "$rc"
}
recorded() {   # a finished install whose record says release at v0.0.9, with the tree's version on offer
  newh; done_all; UD="$(HOME="$H" bash "$R2/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"; mkdir -p "$UD/installed"
  printf 'release\tv0.0.9\t-\t100\n' > "$UD/installed/949230"; printf 'v0.1.0\t200\n' > "$UD/offer"
}
state() { env HOME="$H" L1_UPDATE_DIR="$UD" bash "$R2/common/updates.sh" | cut -f1-3; }   # the tree's tool on this home's record
recorded
check "UT7b a finished install recorded at v0.0.9, v0.1.0 on offer: the state is ready" "$(state)" "ready${TAB}v0.0.9${TAB}v0.1.0"
rc="$(upd)"
check "UT7b install.sh update through the real driver, installer and setup: exit 0, the stamp holds the tree's version, and the deployed tool says current" \
  "$rc:$(calls '^ARCHIVE .*/archive/refs/heads/release\.tar\.gz$'):$(cat "$UD/installed/949230" 2>/dev/null):$(env HOME="$H" bash "$UD/updates.sh" 2>/dev/null | cut -f1-3):$(ls -A "$T/ut7btmp" | wc -l | tr -d ' ')" \
  "0:1:release${TAB}v0.1.0${TAB}-${TAB}1800000000:current${TAB}v0.1.0${TAB}v0.1.0:0"
recorded; W2="$H/Applications/$(bash "$REPO/common/wrappers.sh" name game 3215050)"; bash "$MKW" "$W2"
plutil -replace L1Role -string game-wrapper "$W2/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 3215050 "$W2/Contents/Info.plist"
mkdir -p "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"; : > "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"
printf 'release\tv0.0.9\t-\t100\n' > "$UD/installed/3215050"
rc="$(upd STUB_SECOND_EXIT=3)"
check "UT7b with the second game's installer made to stop: exit 3, this game's stamp is new, the other's is old, and the state stays ready" \
  "$rc:$(calls '^SECOND args= update=1$'):$(cut -f2 "$UD/installed/949230" 2>/dev/null):$(cut -f2 "$UD/installed/3215050" 2>/dev/null):$(state)" \
  "3:1:v0.1.0:v0.0.9:ready${TAB}v0.0.9${TAB}v0.1.0"
H="$HWT"
check "no run reached the runaway guard" "$(cat "$T/runaway" 2>/dev/null | wc -l | tr -d ' ')" 0
# --- the transcript: what the installer printed in every case above, against what it printed when last recorded
GOLD="$HERE/test-install.golden"
if [ "${GOLDEN:-}" = record ]; then
  [ "${MUTANT:-0}" = 0 ] || { echo "REFUSED: the transcript is not recorded under a mutant"; exit 2; }
  [ "$fails" = 0 ] || { echo "REFUSED: the transcript is not recorded from a run with a failure"; exit 2; }
  cp "$T/transcript" "$GOLD" && echo "RECORDED  $(grep -c '^== ' "$GOLD") cases in $(basename "$GOLD")"
else
  case "${MUTANT:-0}" in
    0|26|27|28|58)
      if cmp -s "$T/transcript" "$GOLD"; then echo "PASS  the transcript equals $(basename "$GOLD") ($(grep -c '^== ' "$GOLD") cases)"
      else
        echo "FAIL  the transcript differs from $(basename "$GOLD"):"
        diff "$GOLD" "$T/transcript" 2>&1 | head -n 12 | sed 's/^/        /'
        fails=$((fails + 1))
      fi ;;
    *) echo "SKIP  the transcript is not compared under mutant ${MUTANT}: its own case must catch it" ;;
  esac
fi
echo "$fails failure(s)"
[ "$fails" = 0 ]
