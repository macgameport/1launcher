#!/bin/bash
# test-move-wrappers.sh -- common/move-wrappers.sh, the rename of a wrapper (docs/plans/wrapper-names.md,
# section 6: WT7 to WT9c). No game, no Wine; scratch homes only.
#   bash common/test-move-wrappers.sh    exit 0 = every case passed
#   MUTANT=1  the marker not written                                         WT7 (a)
#   MUTANT=2  the stored-name rewrite removed                                WT7 (b)
#   MUTANT=3  the part-way branch removed                                    WT7b (a)
#   MUTANT=4  part-way renaming whatever the name is                         WT7b (b)
#   MUTANT=5  L1RenamePending not written with the marker                    WT7c
#   MUTANT=6  the marker written after the rename, below the stop test       WT7d
#   MUTANT=7  the probe given every wrapper's files                          WT8 (a)
#   MUTANT=8  the Windows Steam's holder left a stop                         WT8 (b)
#   MUTANT=9  --held-by ignored                                              WT8 (c)
#   MUTANT=10 the probe's call replaced by a scan by user                    WT8 (d)
#   MUTANT=11 --holders-skip widened to the lock                             WT8 (e)
#   MUTANT=12 part-way read from "marked and old-named", without the key     WT9 (a)
#   MUTANT=13 candidates taken from step 2 as well                           WT9 (b)
#   MUTANT=14 the keep-names test dropped                                    WT9 (c)
#   MUTANT=15 the lock and the probe read before the skips                   WT9 (d)
#   MUTANT=16 the named-by-the-player reason applied to the Steam role       WT9 (e)
#   MUTANT=17 the store's "not the game's wrapper" test removed              WT9b
#   MUTANT=18 the marker written in a dry run                                WT9c
# Each must exit 1.
set -u
REPO="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
T="$(mktemp -d /tmp/test-move-wrappers.XXXXXX)"
LIVE=""
trap 'for p in $LIVE; do kill "$p" 2>/dev/null; done; rm -rf "$T"' EXIT
mkdir -p "$T/common"; M="$T/common/move-wrappers.sh"; W="$T/common/wrappers.sh"
cp "$REPO/common/move-wrappers.sh" "$M"; cp "$REPO/common/wrappers.sh" "$W"
mutate() { perl -0pi -e "$1" "$3"; grep -q -- "$2" "$3" || { echo "REFUSED: mutant did not apply"; exit 2; }; }
case "${MUTANT:-0}" in
  1) mutate 's/e="\$\(l1w_mark "\$WR" "\$ROLE" "\$MID" 1 "\$OB" "\$NB" 2>&1\)"/e="\$(true MUTANT-1)"/; s/if ! e="\$\(l1w_mark "\$NEW" "\$ROLE" "\$MID" 0 "\$OB" "\$NB" 2>&1\)"/if ! e="\$(true)"/' 'MUTANT-1' "$M" ;;
  2) perl -pi -e 's/("\$MID" [01]) "\$OB" "\$NB"/$1/g' "$M"; ! grep -q '"$OB" "$NB"' "$M" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  3) mutate 's/WR="\$L1W_HITS"; l1w_pending "\$WR" && STATE=part-way/WR="\$L1W_HITS"; : MUTANT-3/' 'MUTANT-3' "$M" ;;
  4) mutate 's/RENAME=0; \[ -n "\$WR" \] && is_old "\$WR" && RENAME=1/RENAME=0; [ -n "\$WR" ] \&\& RENAME=1 # MUTANT-4/' 'MUTANT-4' "$M" ;;
  5) perl -pi -e 's/"\$MID" 1 "\$OB" "\$NB"/"\$MID" 0 "\$OB" "\$NB"/' "$M"; ! grep -q '"$MID" 1 ' "$M" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  6) mutate 's/\nif \[ "\$STATE" = old \]; then\n[^\n]*\nfi\n/\n# MUTANT-6\n/; s/(\[ "\$\{L1_WMOVE_STOP_AFTER:-\}" = rename \] && exit 2\n)/$1\[ "\$STATE" = old \] \&\& l1w_mark "\$NEW" "\$ROLE" "\$MID" 1 "\$OB" "\$NB"\n/' 'MUTANT-6' "$M" ;;
  7) mutate 's/for f in wineserver wine64 wine wine64-preloader wine-preloader; do \[ -f "\$b\/\$f" \] && files\+=\("\$b\/\$f"\); done/for f in "\$APPS"\/*.app\/Contents\/SharedSupport\/wine\/bin\/*; do [ -f "\$f" ] \&\& files+=("\$f"); done # MUTANT-7/' 'MUTANT-7' "$M" ;;
  8) mutate 's/  if \[ "\$ROLE" = steam \]; then\n    reason skip "Steam is open/  if false; then # MUTANT-8\n    reason skip "Steam is open/' 'MUTANT-8' "$M" ;;
  9) mutate 's/kill -0 "\$h" 2>\/dev\/null && \[ "\$h" != "\$HELD" \]; then/kill -0 "\$h" 2>\/dev\/null; then # MUTANT-9/' 'MUTANT-9' "$M" ;;
  10) mutate 's/lsof -t -- "\$\{files\[@\]\}"/lsof -t -u "\$(id -u)" # MUTANT-10/' 'MUTANT-10' "$M" ;;
  11) mutate 's/(  reason stop "a launch or an install is using \$WHAT[^\n]*\n)/  [ "\$HSKIP" = 1 ] \&\& { reason skip "lock MUTANT-11"; echo "Nothing was renamed."; exit 1; }\n$1/' 'MUTANT-11' "$M" ;;
  12) mutate 's/WR="\$L1W_HITS"; l1w_pending "\$WR" && STATE=part-way/WR="\$L1W_HITS"; { l1w_pending "\$WR" || is_old "\$WR"; } \&\& STATE=part-way # MUTANT-12/' 'MUTANT-12' "$M" ;;
  13) mutate 's/WR="\$L1W_HITS"; l1w_pending "\$WR" && STATE=part-way/WR="\$L1W_HITS"; STATE=old # MUTANT-13/; s/RENAME=0; \[ -n "\$WR" \] && is_old "\$WR" && RENAME=1/RENAME=0; [ -n "\$WR" ] \&\& RENAME=1/' 'MUTANT-13' "$M" ;;
  14) mutate 's/if \[ "\$\{L1_KEEP_WRAPPER_NAMES:-\}" = 1 \]; then/if false; then # MUTANT-14/' 'MUTANT-14' "$M" ;;
  15) mutate 's/(# --- reasons not to rename that come from no probe[^\n]*\n)(.*?)(# --- the lock, then the open-files probe\n.*?\n)(# --- the rename)/# MUTANT-15\n$3$1$2$4/s' 'MUTANT-15' "$M" ;;
  16) mutate 's/if \[ "\$ROLE" = game \] && \[ -n "\$\{!L1W_VAR:-\}" \]; then/if { [ "\$ROLE" = game ] \&\& [ -n "\${!L1W_VAR:-}" ]; } || { [ "\$ROLE" = steam ] \&\& [ -n "\${CS2_WRAPPER:-}" ]; }; then # MUTANT-16/' 'MUTANT-16' "$M" ;;
  17) mutate 's/      \[ -n "\$gp" \] && \[ "\$gp" = "\$wp" \] && reason skip/      false MUTANT-17 \&\& reason skip/' 'MUTANT-17' "$M" ;;
  18) mutate 's/(if \[ "\$DRY" = 1 \]; then echo "  would move:)/[ "\$DRY" = 1 ] \&\& l1w_mark "\$WR" "\$ROLE" "\$MID" 1 "\$OB" "\$NB" # MUTANT-18\n$1/' 'MUTANT-18' "$M" ;;
esac
pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1"; echo "   got:  $2"; echo "   want: $3"; fi; }
ALLOUT="$T/all-output"; : > "$ALLOUT"

CS2P="drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II/Cities2.exe"
STP="drive_c/Program Files (x86)/Steam/steam.exe"
n=0
newhome() { n=$((n + 1)); H="$T/h$n"; A="$H/Applications"; mkdir -p "$A" "$H/SystemApplications"; }
mkw() {   # <path> <bare|cs2|steam> [<role> [<app ID>]]
  local a="$1"
  mkdir -p "$a/Contents/SharedSupport/prefix" "$a/Contents/SharedSupport/wine/bin"
  printf '#!/bin/sh\nexit 0\n' > "$a/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$a/Contents/SharedSupport/wine/bin/wine64"
  cat > "$a/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>CFBundleIdentifier</key><string>com.example123.wineskin</string></dict></plist>
EOF
  chmod 666 "$a/Contents/Info.plist"
  case "$2" in
    cs2) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$CS2P")"; : > "$a/Contents/SharedSupport/prefix/$CS2P" ;;
    steam) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$STP")"; : > "$a/Contents/SharedSupport/prefix/$STP" ;;
  esac
  [ -n "${3:-}" ] && plutil -replace L1Role -string "$3" "$a/Contents/Info.plist"
  [ -n "${4:-}" ] && plutil -replace L1SteamAppID -integer "$4" "$a/Contents/Info.plist"
  chmod 755 "$a"
}
pend() { plutil -replace L1RenamePending -bool true "$1/Contents/Info.plist"; }
key() { plutil -extract "$2" raw -o - "$1/Contents/Info.plist" 2>/dev/null || echo none; }
STUBS="$T/stubs"; mkdir -p "$STUBS"
NOPROBE="$STUBS/noprobe"; printf '#!/bin/sh\nexit 0\n' > "$NOPROBE"; chmod +x "$NOPROBE"
HOLDER="$STUBS/holder"; printf '#!/bin/sh\necho 4242\n' > "$HOLDER"; chmod +x "$HOLDER"
R() { env -u CS2_WRAPPER -u SM_WRAPPER -u L1_KEEP_WRAPPER_NAMES -u L1_WMOVE_STOP_AFTER HOME="$H" L1_SYSTEM_APPS="$H/SystemApplications" L1_WMOVE_PROBE="$NOPROBE" "$@"; }
run() {   # [env...] -- <mover args>: the output with the home as ~, then rc=<code>; every output kept for the Spotlight check
  local envs=() out rc
  while [ "$1" != -- ]; do envs+=("$1"); shift; done; shift
  out="$(R "${envs[@]+"${envs[@]}"}" bash "$M" "$@" 2>&1)"; rc=$?
  printf '%s\n' "$out" >> "$ALLOUT"
  printf '%s\nrc=%s\n' "$out" "$rc"
}
has() { printf '%s\n' "$1" | grep -c -- "$2"; }
rcof() { printf '%s\n' "$1" | sed -n 's/^rc=//p'; }
live() {   # <path of a program to make and run>: a bash script that sleeps, started; its pid in LIVEPID
  mkdir -p "$(dirname "$1")"; printf '#!/bin/bash\nwhile :; do sleep 1; done\n' > "$1"; chmod 755 "$1"
  LIVEPID="$( ("$1" > /dev/null 2>&1 & echo $!) )"; LIVE="$LIVE $LIVEPID"; sleep 0.3
}

# --- WT7: the move
newhome; mkw "$A/CS2dxmt11.app" bare; plutil -replace CFBundleName -string CS2dxmt11 "$A/CS2dxmt11.app/Contents/Info.plist"
o="$(run -- game 949230)"
check "WT7 state old, one moved line, exit 0" "$(has "$o" '^state: old$')|$(has "$o" '^  moved: ~/Applications/CS2dxmt11.app -> ~/Applications/wrapper-949230.app$')|$(rcof "$o")" "1|1|0"
N="$A/wrapper-949230.app"
check "WT7 it carries the marker and no L1RenamePending" "$(key "$N" L1Role)|$(key "$N" L1SteamAppID)|$(key "$N" L1RenamePending)" "game-wrapper|949230|none"
check "WT7 Info.plist lints and keeps its mode" "$(plutil -lint -s "$N/Contents/Info.plist" >/dev/null && echo ok)|$(stat -f %Lp "$N/Contents/Info.plist")" "ok|666"
check "WT7 CFBundleName equal to the old name becomes the new name; the identifier is unchanged" "$(key "$N" CFBundleName)|$(key "$N" CFBundleIdentifier)" "wrapper-949230|com.example123.wineskin"
check "WT7 the resolver finds it by its marker" "$(R bash "$W" find game 949230)" "$N"
o="$(run -- game 949230)"; check "WT7 a second run is state none, exit 0" "$o" "state: none
rc=0"
newhome; mkw "$A/CS2dxmt11-pk110.app" steam
o="$(run -- steam)"; N="$A/wrapper-0.app"
check "WT7 the Windows Steam's: moved, marked steam-wrapper with no app ID, Steambuild Metal kept" \
  "$(has "$o" '^  moved: ~/Applications/CS2dxmt11-pk110.app -> ~/Applications/wrapper-0.app$')|$(rcof "$o")|$(key "$N" L1Role)|$(key "$N" L1SteamAppID)|$(key "$N" CFBundleName)" \
  "1|0|steam-wrapper|none|Steambuild Metal"
newhome; mkw "$A/SurvivingMars.app" bare
o="$(run -- game 3215050)"
check "WT7 Surviving Mars's: moved to wrapper-3215050.app" "$(has "$o" '-> ~/Applications/wrapper-3215050.app$')|$(rcof "$o")|$(key "$A/wrapper-3215050.app" L1SteamAppID)" "1|0|3215050"

# --- WT7b: part-way is finished
newhome; mkw "$A/CS2dxmt11.app" bare game-wrapper 949230; pend "$A/CS2dxmt11.app"
o="$(run -- game 949230)"
check "WT7b under an old name with the key: part-way, one moved, exit 0, the key gone" \
  "$(has "$o" '^state: part-way$')|$(has "$o" '^  moved: ')|$(rcof "$o")|$(key "$A/wrapper-949230.app" L1RenamePending)" "1|1|0|none"
newhome; mkw "$A/mine.app" bare game-wrapper 949230; pend "$A/mine.app"
o="$(run -- game 949230)"
check "WT7b under a name of the tester's own: part-way, no moved line, exit 0, the key gone, the name kept" \
  "$(has "$o" '^state: part-way$')|$(has "$o" 'moved: ')|$(rcof "$o")|$(key "$A/mine.app" L1RenamePending)|$(ls "$A")" "1|0|0|none|mine.app"

# --- WT7c: a failed rename
newhome; mkw "$A/CS2dxmt11.app" bare
mkdir -p "$STUBS/failmv"; printf '#!/bin/sh\ncase "$2" in *.app) echo "mv: rename refused" >&2; exit 1 ;; esac\nexec /bin/mv "$@"\n' > "$STUBS/failmv/mv"; chmod +x "$STUBS/failmv/mv"
o="$(run PATH="$STUBS/failmv:$PATH" -- game 949230)"
check "WT7c with mv made to fail: not moved, exit 2" "$(has "$o" '^  not moved: ~/Applications/CS2dxmt11.app -> ~/Applications/wrapper-949230.app')|$(rcof "$o")" "1|2"
check "WT7c ...the marker and L1RenamePending present, the name unchanged" "$(key "$A/CS2dxmt11.app" L1Role)|$(key "$A/CS2dxmt11.app" L1RenamePending)|$(ls "$A")" "game-wrapper|true|CS2dxmt11.app"
check "WT7c ...and the resolver prints the old path" "$(R bash "$W" find game 949230)" "$A/CS2dxmt11.app"
o="$(run -- game 949230)"
check "WT7c a second run with mv working is part-way and finishes" "$(has "$o" '^state: part-way$')|$(has "$o" '^  moved: ')|$(rcof "$o")|$(key "$A/wrapper-949230.app" L1RenamePending)" "1|1|0|none"

# --- WT7d: killed after the rename (a steam fixture: an unmarked one under a new name is found by no step)
newhome; mkw "$A/CS2dxmt11-pk110.app" steam
o="$(run L1_WMOVE_STOP_AFTER=rename -- steam)"
check "WT7d stopped after the rename: under the new name, and found by its marker" "$(ls "$A")|$(R bash "$W" find steam)" "wrapper-0.app|$A/wrapper-0.app"
o="$(run -- steam)"
check "WT7d a second run: part-way, renames nothing, removes L1RenamePending under the new name" \
  "$(has "$o" '^state: part-way$')|$(has "$o" 'moved: ')|$(rcof "$o")|$(key "$A/wrapper-0.app" L1RenamePending)|$(ls "$A")" "1|0|0|none|wrapper-0.app"

# --- WT8: the stops, and the probe
newhome; mkw "$A/CS2dxmt11.app" bare; live "$T/sleeper$n/prog"
ln -s "$LIVEPID" "$A/CS2dxmt11.app/Contents/SharedSupport/prefix/.launcher.lock"
o="$(run -- game 949230)"
check "WT8 a live holder of the launch lock: exit 3, no rename" "$(has "$o" '^  stop: a launch or an install is using')|$(rcof "$o")|$(ls "$A")" "1|3|CS2dxmt11.app"
o="$(run -- --held-by "$LIVEPID" game 949230)"
check "WT8 ...the same holder named in --held-by: renamed" "$(rcof "$o")|$(ls "$A")" "0|wrapper-949230.app"
newhome; mkw "$A/CS2dxmt11.app" bare
o="$(run L1_WMOVE_PROBE="$HOLDER" -- game 949230)"
check "WT8 a holder reported by the probe, game role: exit 3, no rename" "$(has "$o" '^  stop: the game or Steam is using')|$(rcof "$o")|$(ls "$A")" "1|3|CS2dxmt11.app"
newhome; mkw "$A/CS2dxmt11-pk110.app" steam
o="$(run L1_WMOVE_PROBE="$HOLDER" -- steam)"
check "WT8 ...Steam role: exit 1, a skip line, no rename" "$(has "$o" '^  skip: Steam is open in')|$(has "$o" 'stop:')|$(rcof "$o")|$(ls "$A")" "1|0|1|CS2dxmt11-pk110.app"
# the real probe, with a recording lsof on PATH
mkdir -p "$STUBS/reclsof"; REC="$T/lsof-calls"; : > "$REC"
printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "%s"\nexec /usr/sbin/lsof "$@"\n' "$REC" > "$STUBS/reclsof/lsof"; chmod +x "$STUBS/reclsof/lsof"
RP="$STUBS/reclsof:$PATH"
newhome; mkw "$A/CS2dxmt11.app" bare; live "$A/CS2dxmt11.app/Contents/SharedSupport/wine/bin/wineserver"
o="$(run L1_WMOVE_PROBE= PATH="$RP" -- game 949230)"
check "WT8 the real probe: a program running as the wrapper's wineserver: exit 3" "$(has "$o" "^  stop: the game or Steam is using the game's wrapper (process $LIVEPID)")|$(rcof "$o")|$(ls "$A")" "1|3|CS2dxmt11.app"
newhome; mkw "$A/CS2dxmt11.app" bare; mkw "$A/other.app" bare; live "$A/other.app/Contents/SharedSupport/wine/bin/wineserver"
o="$(run L1_WMOVE_PROBE= PATH="$RP" -- game 949230)"
check "WT8 ...the same program running from another wrapper: renamed" "$(rcof "$o")|$(ls "$A" | tr '\n' ' ')" "0|other.app wrapper-949230.app "
bad=0; while IFS= read -r l; do
  case "$l" in "-t -- "*) for f in ${l#-t -- }; do :; done ;; *) bad=$((bad + 1)) ;; esac
done < "$REC"
check "WT8 the recording lsof saw every call as -t -- with file operands ($(wc -l < "$REC" | tr -d ' ') calls)" "$bad|$(grep -c 'wine/bin/w' "$REC")" "0|$(wc -l < "$REC" | tr -d ' ')"
newhome; mkw "$A/CS2dxmt11.app" bare
o="$(run L1_WMOVE_PROBE="$HOLDER" -- --holders-skip game 949230)"
check "WT8 --holders-skip, game role: a probe holder gives exit 1, one skip line, no stop line" "$(rcof "$o")|$(has "$o" '^  skip: ')|$(has "$o" 'stop:')|$(ls "$A")" "1|1|0|CS2dxmt11.app"
live "$T/sleeper$n/prog"; ln -s "$LIVEPID" "$A/CS2dxmt11.app/Contents/SharedSupport/prefix/.launcher.lock"
o1="$(run -- --holders-skip game 949230)"; o2="$(run L1_WMOVE_PROBE="$HOLDER" -- --holders-skip game 949230)"
check "WT8 --holders-skip: a live lock holder not in --held-by still gives exit 3, with and without a probe holder" "$(rcof "$o1")|$(rcof "$o2")|$(ls "$A")" "3|3|CS2dxmt11.app"

# --- WT9: the skips, and names left alone
sk() {   # <label> [env...] -- <args>: exit 1, a skip line, nothing renamed (the home is set up beforehand)
  local label="$1" before; shift; before="$(ls -R "$A" | shasum)"
  o="$(run "$@")"
  check "WT9 skip: $label" "$(rcof "$o")|$(has "$o" '^  skip: ')|$(has "$o" 'stop:')|$(ls -R "$A" | shasum)" "1|$(has "$o" '^  skip: ')|0|$before"
  [ "$(has "$o" '^  skip: ')" -ge 1 ] || check "WT9 skip: $label has a skip line" "$o" "a skip line"
}
newhome; mkw "$A/CS2dxmt11.app" bare; sk "L1_KEEP_WRAPPER_NAMES=1" L1_KEEP_WRAPPER_NAMES=1 -- game 949230
check "WT9 ...its line prints the variable as a literal" "$(has "$o" 'L1_KEEP_WRAPPER_NAMES=1')" 1
newhome; mkw "$A/CS2dxmt11.app" bare; mkw "$H/x.app" bare; sk "a wrapper named by the player" CS2_WRAPPER="$H/x.app" -- game 949230
check "WT9 ...the line says a wrapper was named" "$(has "$o" 'CS2_WRAPPER names a wrapper')" 1
newhome; mkw "$A/CS2dxmt11.app" bare; mkdir "$A/wrapper-949230.app"; sk "the target name taken" -- game 949230
newhome; mkw "$H/real/CS2dxmt11.app" bare; ln -s "$H/real/CS2dxmt11.app" "$A/CS2dxmt11.app"; sk "a symlinked wrapper" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare
mkdir -p "$STUBS/stat$n"; printf '#!/bin/sh\nif [ "$1" = -f ] && [ "$2" = %%u ] && [ "$3" = "%s" ]; then echo 0; exit 0; fi\nexec /usr/bin/stat "$@"\n' "$A/CS2dxmt11.app" > "$STUBS/stat$n/stat"; chmod +x "$STUBS/stat$n/stat"
sk "a wrapper not the user's own" PATH="$STUBS/stat$n:$PATH" -- game 949230
newhome; mkw "$H/SystemApplications/CS2dxmt11.app" bare; A="$H"; sk "one in the system folder" -- game 949230; A="$H/Applications"
newhome; mkw "$A/CS2dxmt11.app" bare; rm "$A/CS2dxmt11.app/Contents/Info.plist"; sk "no Info.plist" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare; printf 'broken' > "$A/CS2dxmt11.app/Contents/Info.plist"; sk "an Info.plist that does not parse" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare; chmod 444 "$A/CS2dxmt11.app/Contents/Info.plist"; sk "an Info.plist that cannot be written" -- game 949230
newhome; mkw "$A/a.app" bare game-wrapper 949230; mkw "$A/b.app" bare game-wrapper 949230; sk "two candidates" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare; live "$T/sleeper$n/prog"; ln -s "$LIVEPID" "$A/CS2dxmt11.app/Contents/SharedSupport/prefix/.launcher.lock"
sk "L1_KEEP_WRAPPER_NAMES=1 beside a live lock holder" L1_KEEP_WRAPPER_NAMES=1 -- game 949230
sk "a wrapper named by the player beside a live lock holder" CS2_WRAPPER="$A/CS2dxmt11.app" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare
sk "L1_KEEP_WRAPPER_NAMES=1 beside a probe holder" L1_KEEP_WRAPPER_NAMES=1 L1_WMOVE_PROBE="$HOLDER" -- game 949230
sk "a wrapper named by the player beside a probe holder" CS2_WRAPPER="$A/CS2dxmt11.app" L1_WMOVE_PROBE="$HOLDER" -- game 949230
newhome; mkw "$A/CS2dxmt11.app" bare game-wrapper 949230
o="$(run -- game 949230)"; check "WT9 a marked wrapper with no L1RenamePending under an old name: state none, kept" "$o|$(ls "$A")" "state: none
rc=0|CS2dxmt11.app"
newhome; mkw "$A/my own name.app" bare game-wrapper 949230
o="$(run -- game 949230)"; check "WT9 ...and one under a name of the tester's own" "$o|$(ls "$A")" "state: none
rc=0|my own name.app"
newhome; mkw "$A/CS2dxmt11-pk110.app" steam; mkw "$A/CS2dxmt11.app" cs2
o="$(run CS2_WRAPPER="$A/CS2dxmt11.app" -- steam)"
check "WT9 Steam role, with CS2_WRAPPER naming another wrapper: the store wrapper is renamed" "$(rcof "$o")|$(ls "$A" | tr '\n' ' ')" "0|CS2dxmt11.app wrapper-0.app "

# --- WT9b: the store candidate
stsk() {   # <label> [env...] -- : a skip, and nothing marked
  local label="$1"; shift
  o="$(run "$@" steam)"
  check "WT9b store skip: $label" "$(rcof "$o")|$([ "$(has "$o" '^  skip: ')" -ge 1 ] && echo skip)|$(key "$A/CS2dxmt11-pk110.app" L1Role)" "1|skip|none"
}
newhome; mkw "$A/CS2dxmt11-pk110.app" steam; mkw "$A/wrapper-949230.app" cs2 game-wrapper 949230
mkdir -p "$A/S734M.app/Contents"
printf '%s' "<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict><key>L1Role</key><string>steam</string><key>L1Prefix</key><string>$A/wrapper-949230.app/Contents/SharedSupport/prefix</string></dict></plist>" > "$A/S734M.app/Contents/Info.plist"
stsk "S734M.app's L1Prefix names the game's wrapper" --
newhome; mkw "$A/CS2dxmt11-pk110.app" steam; mkdir -p "$(dirname "$A/CS2dxmt11-pk110.app/Contents/SharedSupport/prefix/$CS2P")"; : > "$A/CS2dxmt11-pk110.app/Contents/SharedSupport/prefix/$CS2P"
stsk "it holds Cities2.exe" --
newhome; mkw "$A/CS2dxmt11-pk110.app" bare; stsk "it has no steam.exe" --
newhome; mkw "$A/CS2dxmt11-pk110.app" steam; stsk "it is the wrapper CS2_WRAPPER names (the named store)" CS2_WRAPPER="$A/CS2dxmt11-pk110.app" --
newhome; mkw "$A/CS2dxmt11-pk110.app" steam game-wrapper 949230
o="$(run -- steam)"
check "WT9b one that already carries game-wrapper: state none, exit 0, no skip, its marker unchanged" "$o|$(key "$A/CS2dxmt11-pk110.app" L1Role)|$(ls "$A")" "state: none
rc=0|game-wrapper|CS2dxmt11-pk110.app"

# --- WT9c: --dry-run
newhome; mkw "$A/CS2dxmt11.app" bare; sum="$(shasum < "$A/CS2dxmt11.app/Contents/Info.plist")"
o="$(run -- --dry-run game 949230)"
check "WT9c would move, exit 0 as the real run's, the name and the bytes of Info.plist unchanged" \
  "$(has "$o" '^  would move: ~/Applications/CS2dxmt11.app -> ~/Applications/wrapper-949230.app$')|$(rcof "$o")|$(ls "$A")|$(shasum < "$A/CS2dxmt11.app/Contents/Info.plist")" "1|0|CS2dxmt11.app|$sum"
o="$(run L1_WMOVE_PROBE="$HOLDER" -- --dry-run game 949230)"
check "WT9c ...a dry run beside a holder exits as the real run would: 3" "$(rcof "$o")|$(shasum < "$A/CS2dxmt11.app/Contents/Info.plist")" "3|$sum"
newhome; mkw "$A/mine.app" bare game-wrapper 949230; pend "$A/mine.app"; sum="$(shasum < "$A/mine.app/Contents/Info.plist")"
o="$(run -- --dry-run game 949230)"
check "WT9c ...a part-way under another name: would finish, nothing written" "$(has "$o" '^  would finish: ~/Applications/mine.app')|$(rcof "$o")|$(shasum < "$A/mine.app/Contents/Info.plist")" "1|0|$sum"

# --- no line the mover prints holds the word Spotlight (surviving-mars-relaunched/scripts/test-setup.sh counts it)
check "no line of any case holds the word Spotlight" "$(grep -ci spotlight "$ALLOUT")" 0
check "no line of any case holds the home folder's name" "$(grep -c "$T/h" "$ALLOUT")" 0

echo "test-move-wrappers: $pass passed, $fail failed"
[ "$fail" = 0 ]
