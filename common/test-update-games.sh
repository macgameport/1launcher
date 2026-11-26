#!/bin/bash
# test-update-games.sh -- common/update-games.sh, the update's driver, and the file `updates.sh --open` writes
# (docs/plans/built-in-update.md, 3.4; tests UT7 and "UT7, also"). The driver runs from a scratch tree whose
# games' installers are stubs that record their arguments and read one line of their input; the driver is given
# a file as its input. Wrappers are the "bare" fixture of docs/plans/wrapper-names.md, section 6, in a scratch
# ~/Applications, with or without the game's program. HOME, TMPDIR and L1_UPDATE_DIR are scratch folders;
# L1_CURL and L1_OPEN name stubs; the stub curl honours -o and -w as curl does. No network, no Wine, no Terminal.
#   bash common/test-update-games.sh            exit 0 = every case passed
# The driver; each must exit 1:
#   MUTANT=1 ...  the stamps as the list (the look at wrappers dropped)
#   MUTANT=2 ...  the list read by a loop on standard input
#   MUTANT=3 ...  the driver stopping at the first failure
#   MUTANT=4 ...  the resolver's exit 2 (two wrappers marked alike) treated as "none"
#   MUTANT=5 ...  the game's wrapper variable not unset for the look
#   MUTANT=6 ...  --yes added to an installer's call
#   MUTANT=7 ...  a stamp on another line run anyway
#   MUTANT=8 ...  an installer's exit 5 counted as failed
#   MUTANT=9 ...  a row's folder taken without the pattern
#   MUTANT=10 ..  the test of the offer against the fetched version dropped (step 3)
#   MUTANT=11 ..  the lock dropped
#   MUTANT=13 ..  the lock not removed at exit
#   MUTANT=14 ..  the test for the game's program dropped
#   MUTANT=15 ..  the per-game test of the stamp's version dropped (apart from step 3's)
#   MUTANT=17 ..  the test of the record's folder dropped (step 2)
#   MUTANT=18 ..  the match of the lock's target dropped
#   MUTANT=19 ..  "No game is set up" said beside a failure
# 14unch3r's own step (docs/plans/launcher-first-install.md, 3.5; LFT4); each must exit 1:
#   MUTANT=20 ..  the launcher's installer run every time (at the fetched version too)
#   MUTANT=21 ..  a launcher on another line run anyway
#   MUTANT=22 ..  "No game is set up" said after the launcher was updated
#   MUTANT=23 ..  the launcher's failure not counted
#   MUTANT=24 ..  the launcher's stamp kept when the app is gone and no game is set up
#   MUTANT=25 ..  a current launcher with no game made exit 3
#   MUTANT=26 ..  the app's test made true for an absent app
# The install's lock (the same plan, 3.8; LFT4's cases "with LF4a"); each must exit 1:
#   MUTANT=27 ..  the look at `installing` dropped
#   MUTANT=28 ..  the look at `installing` made before the take of `updating`
#   MUTANT=29 ..  the line that removes a stale `updating` dropped
# The file `updates.sh --install <ID>` writes (the same plan, 3.8; LFT3); each must exit 1:
#   MUTANT=30 ..  `release` made `main` in the address it fetches
#   MUTANT=31 ..  a second word passed to the installer
#   MUTANT=32 ..  the installer run after a fetch that failed
# (Mutants 12 and 16 change the same lines in both written files, the update's and the install's.)
# (Mutant 18 drops the match of a lock's target in the driver's take and, since LF4a, in the one rule of
# common/updates.sh too: the line that removes a stale `updating` asks that rule first.)
# The file `updates.sh --open` writes; each must exit 1:
#   MUTANT=12 ..  `release` made `main` in the address it fetches
#   MUTANT=16 ..  the fetched file run whatever the answer's code
set -u
unset L1_UPDATE_DIR L1_UPDATE L1_UPDATE_NOW L1_FETCHED_REF L1_FETCHED_COMMIT L1_DATA_ROOT L1_CURL L1_OPEN CS2_WRAPPER SM_WRAPPER
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d /tmp/update-games-test.XXXX)"
LIVE=""
trap '[ -n "$LIVE" ] && { kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null; }; rm -rf "$T"' EXIT
TREE="$T/tree"; mkdir -p "$TREE/common" "$T/bin" "$T/tmp" "$T/exits"
D="$TREE/common/update-games.sh"; U="$TREE/common/updates.sh"
cp "$HERE/update-games.sh" "$D"; cp "$HERE/updates.sh" "$U"
cp "$HERE/paths.sh" "$HERE/wrappers.sh" "$TREE/common/"
mutate() {  # <sed expression> <grep that proves it applied>: in the driver or in updates.sh
  sed -i '' "$1" "$D" "$U"; cat "$D" "$U" | grep -q -- "$2" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
inst() {   # <fixed text> <new text>: its first occurrence in the install's written file (updates.sh, after --install's marker)
  OLD="$1" NEW="$2" python3 -I - "$U" << 'PY' || { echo "REFUSED: mutant did not apply"; exit 2; }
import os, sys
p = sys.argv[1]; s = open(p).read()
i = s.index("# Written by 1launcher (updates.sh --install)"); j = s.index(os.environ["OLD"], i)
open(p, "w").write(s[:j] + os.environ["NEW"] + s[j + len(os.environ["OLD"]):])
PY
}
case "${MUTANT:-0}" in
  0) ;;
  1) mutate 's#^  set_up "\$id"; su=\$?$#  l1u_stamp_of "$id" > /dev/null; su=$?#' '^  l1u_stamp_of "\$id" > /dev/null; su=\$?$' ;;
  2) mutate 's#^while IFS=\$.\\t. read -r id folder title <&3; do$#while IFS=$'"'"'\\t'"'"' read -r id folder title; do#' 'read -r id folder title; do$'
     mutate 's#^done 3<< EOF$#done << EOF#' '^done << EOF$' ;;
  3) mutate 's#^  one_game "\$id" "\$folder" "\$title"$#  one_game "$id" "$folder" "$title"; [ "$FAILED" -gt 0 ] \&\& break#' '"\$title"; \[ "\$FAILED" -gt 0 \] && break$' ;;
  4) mutate 's#^  \[ "\$rc" = 2 \] && return 2$#  :#' '^  :$' ;;
  5) mutate 's#^  w="\$( \[ -z "\$L1W_VAR" \] || unset "\$L1W_VAR"; l1w_find game "\$1" 2>/dev/null )"; rc=\$?$#  w="$( l1w_find game "$1" 2>/dev/null )"; rc=$?#' '^  w="\$( l1w_find game "\$1" 2>/dev/null )"; rc=\$?$' ;;
  6) mutate 's#^  bash "\$ROOT/\$folder/scripts/install.sh" 3<&-; rc=\$?#  bash "$ROOT/$folder/scripts/install.sh" --yes 3<\&-; rc=$?#' 'scripts/install.sh" --yes 3<&-; rc=\$?' ;;
  7) mutate 's#^  if \[ "\$line" != "\$L1_FETCHED_REF" \]; then$#  if false; then#' '^  if false; then$' ;;
  8) sed -i '' '/^    5) closing /d' "$D"; grep -q '^    5) closing ' "$D" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  9) mutate 's#length(\$1) <= 10 && \$2 ~ /^\[a-z0-9\]\[a-z0-9-\]\*\$/ && !seen#length($1) <= 10 \&\& !seen#' 'length(\$1) <= 10 && !seen' ;;
  10) mutate 's#^if l1u_newer "\$OFFERED" "\$T"; then$#if false; then#' '^if false; then$' ;;
  11) mutate 's#^if ! take_lock; then$#if false; then#' '^if false; then$' ;;
  12) mutate 's#1launcher/refs/heads/release/install\.sh)"; rc=\$?$#1launcher/refs/heads/main/install.sh)"; rc=$?#' '1launcher/refs/heads/main/install\.sh)"; rc=\$?$' ;;
  13) mutate 's#^trap release_lock EXIT$#:#' '^:$' ;;
  14) mutate 's#^  l1w_program "\$w" "\$L1W_PROGRAM" || return 1$#  :#' '^  :$' ;;
  15) mutate 's#^  if l1u_newer "\$ver" "\$T"; then$#  if false; then#' '^  if false; then$' ;;
  16) mutate 's#^if \[ "\$rc" = 0 \] && \[ "\$code" = 200 \]; then$#if true; then#' '^if true; then$' ;;
  17) mutate 's#^if ! l1u_own; then$#if false; then#' '^if false; then$' ;;
  18) mutate 's#^  if ! \[\[ "\$h" =~ \$PIDFORM \]\] || ! kill -0 "\$h" 2>/dev/null; then$#  if ! kill -0 "$h" 2>/dev/null; then#' '^  if ! kill -0 "\$h" 2>/dev/null; then$'
      mutate 's#^  \[\[ "\$h" =~ \$_L1U_ID \]\] || return 1$#  : no match of the target#' '^  : no match of the target$' ;;
  19) mutate 's#^elif \[ "\$SETUP" = 0 \] && \[ "\$FAILED" = 0 \]; then$#elif [ "$SETUP" = 0 ]; then#' '^elif \[ "\$SETUP" = 0 \]; then$' ;;
  20) mutate 's#^  if \[ "\$ver" = "\$T" \]; then CURRENT=1; return 0; fi .*#  : run every time#' '^  : run every time$' ;;
  21) mutate 's#^  if \[ "\$line" != "\$L1_FETCHED_REF" \]; then   \# 14unch3r follows another line$#  if false; then   \# 14unch3r#' '^  if false; then   # 14unch3r$' ;;
  22) mutate 's#^  SETUP=\$((SETUP + 1))   \# from here on .*#  : not counted as set up#' '^  : not counted as set up$'
      mutate 's#^  RAN=\$((RAN + 1))   \# 14unch3r.s installer ran$#  : not counted as run#' '^  : not counted as run$' ;;
  23) mutate 's#^    \*) closing "!! 14unch3r: not rebuilt (exit \$rc)\. Its lines above say why\."; FAILED=\$((FAILED + 1)) ;;$#    *) closing "!! 14unch3r: not rebuilt (exit $rc). Its lines above say why." ;;#' '^    \*) closing "!! 14unch3r: not rebuilt (exit \$rc)\. Its lines above say why\." ;;$' ;;
  24) mutate 's#^    rm -f "\$L1_UPDATE_DIR/launcher"; return 0$#    return 0#' '^    return 0$' ;;
  25) mutate 's#^  SETUP=\$((SETUP + 1))   \# from here on .*#  : not counted as set up#' '^  : not counted as set up$' ;;
  26) mutate 's#^  \[ -d "\$a" \] \&\& \[ ! -L "\$a" \] || return 1$#  [ -e "$a" ] || [ -L "$a" ] || return 0#' '^  \[ -e "\$a" \] || \[ -L "\$a" \] || return 0$' ;;
  27) mutate 's#^if l1u_lock_live installing; then$#if false; then#' '^if false; then$' ;;
  28) python3 -I - "$D" << 'PY' || { echo "REFUSED: mutant did not apply"; exit 2; }
import sys
p = sys.argv[1]; s = open(p).read()
a = "if l1u_lock_live installing; then\n"; b = "l1u_lock_live updating || rm -f"
assert s.count(a) == 1 and s.count(b) == 1
i = s.index(a); j = s.index("fi\n", i) + 3; blk = s[i:j]; s = s[:i] + s[j:]
k = s.index(b); s = s[:k] + blk + s[k:]
open(p, "w").write(s)
PY
      ;;
  29) mutate 's#^l1u_lock_live updating || rm -f "\$LOCK" 2>/dev/null .*#: a stale lock is left#' '^: a stale lock is left$' ;;
  30) inst '1launcher/refs/heads/release/install.sh)"; rc=$?' '1launcher/refs/heads/main/install.sh)"; rc=$?' ;;
  31) inst '/bin/bash -c "$S" 1launcher-install "$ID"; rc=$?' '/bin/bash -c "$S" 1launcher-install "$ID" release; rc=$?' ;;
  32) inst 'if [ "$rc" = 0 ] && [ "$code" = 200 ]; then' 'if true; then' ;;
  *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
esac
bash -n "$D" && bash -n "$U" || { echo "REFUSED: the mutant does not parse"; exit 2; }

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
TAB=$'\t'
export CALLS="$T/calls" EXITS="$T/exits"
NOW=1800000000

# --- the tree: its version, its table (not in the order of the IDs), and a stub installer per game
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.3.0 (2026-11-24)' '' 'Three.' > "$TREE/CHANGELOG.md"
table() {   # [the first game's folder]: 3215050 comes first in the file, and as text it sorts first too
  {
    printf '3215050\tsecond-game\tSecond Game\thttps://example.invalid/second\n'
    printf '949230\t%s\tFirst Game\thttps://example.invalid/first\n' "${1:-first-game}"
    printf '12345\tunknown-game\tA Game The Rule Does Not Know\thttps://example.invalid/unknown\n'
    printf 'x7\tbad-id\tA Row With No ID\thttps://example.invalid/bad\n'
  } > "$TREE/common/games.tsv"
}
table
REC='#!/bin/bash
game="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
IFS= read -r line
echo "INSTALLER $game args=$* argc=$# update=${L1_UPDATE:-} ref=${L1_FETCHED_REF:-} cs2w=${CS2_WRAPPER-unset} input=$line" >> "$CALLS"
echo "the installer of $game ran"
# a game whose setup rebuilt the window writes the launcher stamp at the tree version, as the real setups do
[ -f "$EXITS/$game.lstamp" ] && printf "release\\tv0.3.0\\t-\\t100\\n" > "$L1_UPDATE_DIR/launcher"
exit "$(cat "$EXITS/$game" 2>/dev/null || echo 0)"'
# the tree's installer of the launcher: a recorder (docs/plans/launcher-first-install.md, 3.5; LFT4)
LREC='#!/bin/bash
echo "LAUNCHER args=$* argc=$# update=${L1_UPDATE:-} ref=${L1_FETCHED_REF:-}" >> "$CALLS"
echo "the installer of the launcher ran"
exit "$(cat "$EXITS/launcher" 2>/dev/null || echo 0)"'
printf '%s\n' "$LREC" > "$TREE/common/install-launcher.sh"
for g in first-game second-game unknown-game bad-id; do
  mkdir -p "$TREE/$g/scripts"; printf '%s\n' "$REC" > "$TREE/$g/scripts/install.sh"
done
mkdir -p "$T/x/scripts"; printf '%s\n' "$REC" > "$T/x/scripts/install.sh"   # outside the tree: <tree>/../x
printf '%s\n' 'line one' 'line two' 'line three' > "$T/input"

# --- fixtures: a scratch home with its record, and wrappers (as common/test-wrappers.sh makes them)
CS2P="drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II/Cities2.exe"
SMP="drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"
n=0
newh() {   # a fresh home, an empty record, nothing recorded, every installer exiting 0
  n=$((n + 1)); H="$T/h$n"; UD="$H/u"; mkdir -p "$H/Applications" "$H/SystemApplications" "$UD/installed"
  chmod 700 "$UD" "$UD/installed"; : > "$CALLS"; rm -f "$EXITS"/*
}
mkw() {   # <name in ~/Applications> <bare|cs2|sm> [<app ID of its marker>]
  local a="$H/Applications/$1" k="$2"
  mkdir -p "$a/Contents/SharedSupport/prefix" "$a/Contents/SharedSupport/wine/bin"
  printf '#!/bin/sh\nexit 0\n' > "$a/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$a/Contents/SharedSupport/wine/bin/wine64"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>' > "$a/Contents/Info.plist"
  case "$k" in
    cs2) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$CS2P")"; : > "$a/Contents/SharedSupport/prefix/$CS2P" ;;
    sm) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$SMP")"; : > "$a/Contents/SharedSupport/prefix/$SMP" ;;
  esac
  if [ -n "${3:-}" ]; then
    plutil -replace L1Role -string game-wrapper "$a/Contents/Info.plist"; plutil -replace L1SteamAppID -integer "$3" "$a/Contents/Info.plist"
  fi
  chmod 755 "$a"
}
first() { mkw wrapper-949230.app cs2 949230; }     # the first game, set up
second() { mkw wrapper-3215050.app sm 3215050; }   # the second game, set up
stamp() { printf '%s\t%s\t-\t100\n' "${2:-release}" "${3:-v0.2.0}" > "$UD/installed/$1"; }   # <id> [line] [version]
offer() { printf '%s\t200\n' "$1" > "$UD/offer"; }
exits() { local e; for e in "$@"; do echo "${e#*=}" > "$EXITS/${e%%=*}"; done; }   # <game>=<code> ...
drv() {    # [VAR=value ...]: the driver, its input a file; output in $T/out; echoes its exit code
  : > "$CALLS"
  env HOME="$H" TMPDIR="$T/tmp" L1_SYSTEM_APPS="$H/SystemApplications" L1_UPDATE_DIR="$UD" L1_UPDATE_NOW="$NOW" L1_FETCHED_REF=release "$@" \
    bash "$D" < "$T/input" > "$T/out" 2>&1
  echo $?
}
said() { grep -c -- "$1" "$T/out"; }
saidF() { grep -cF -- "$1" "$T/out"; }
ran() { sed -n 's/^INSTALLER \([^ ]*\) .*/\1/p' "$CALLS" | tr '\n' ' '; }   # the installers that ran, in their order
lock() { [ -e "$UD/updating" ] || [ -L "$UD/updating" ] && echo left || echo none; }
UPTODATE='^Everything is up to date: 1launcher v0\.3\.0\.$'
NOTALL='^Not everything was updated\. Do what the lines above say\.$'
NOGAME='^No game is set up on this Mac\.$'

# --- UT7: two games set up and recorded on the line that was fetched
newh; first; second; stamp 949230; stamp 3215050
rc="$(drv)"
check "two set-up games stamped release: both installers run, in the order of the IDs as numbers; exit 0" "$rc:$(ran)" "0:first-game second-game "
check "  ...each with no argument, under L1_UPDATE=1, and each reading the driver's own input" \
  "$(grep -c '^INSTALLER first-game args= argc=0 update=1 ref=release cs2w=unset input=line one$' "$CALLS"):$(grep -c '^INSTALLER second-game args= argc=0 update=1 ref=release cs2w=unset input=line two$' "$CALLS")" "1:1"
check "  ...no recorded argument holds --yes" "$(grep -c -- '--yes' "$CALLS")" 0
check "  ...a heading with each title before its installer's lines, and the closing lines" \
  "$(grep -n -e '^=== First Game ===$' -e '^the installer of first-game ran$' -e '^=== Second Game ===$' -e '^the installer of second-game ran$' -e '^First Game: updated\.$' -e '^Second Game: updated\.$' -e "$UPTODATE" "$T/out" | cut -d: -f2- | tr '\n' '|')" \
  "=== First Game ===|the installer of first-game ran|=== Second Game ===|the installer of second-game ran|First Game: updated.|Second Game: updated.|Everything is up to date: 1launcher v0.3.0.|"
check "  ...the stamps are left to the installers, and no lock is left" "$(cut -f1,2 "$UD/installed/949230"):$(lock)" "release${TAB}v0.2.0:none"
check "  ...a row whose ID the rule for wrappers does not know, and a row with no ID, are not looked at" "$(said 'Does Not Know'):$(said 'No ID')" "0:0"
newh; first; second; stamp 949230; stamp 3215050; exits first-game=1
check "a failing installer first: the second still runs, exit 1, and the closing line says not everything" \
  "$(drv):$(ran):$(said '^!! First Game: its installer did not finish (exit 1)'):$(said '^Second Game: updated\.$'):$(said "$NOTALL"):$(said "$UPTODATE"):$(lock)" "1:first-game second-game :1:1:1:0:none"
newh; first; second; stamp 949230; stamp 3215050; exits first-game=3
check "3 then 0: exit 3, the stop named" "$(drv):$(ran):$(said '^First Game: its installer stopped\.'):$(said "$NOTALL"):$(said "$UPTODATE")" "3:first-game second-game :1:1:0"
newh; first; second; stamp 949230; stamp 3215050; exits first-game=1 second-game=3
check "1 then 3: exit 1" "$(drv):$(ran)" "1:first-game second-game "
newh; first; second; stamp 949230; stamp 3215050; exits second-game=4
check "an installer's exit 4: failed, exit 1" "$(drv):$(said '^!! Second Game: its installer did not finish (exit 4)'):$(said "$NOTALL")" "1:1:1"
newh; first; second; stamp 949230; stamp 3215050; exits first-game=143
check "an installer ended by a signal (143): failed, exit 1, the next still runs" "$(drv):$(ran)" "1:first-game second-game "
newh; first; second; stamp 949230; stamp 3215050; exits first-game=5
check "an installer's exit 5: done; exit 0, everything up to date" "$(drv):$(said '^First Game: updated\. A Mac fix is not out yet'):$(said "$UPTODATE"):$(said "$NOTALL")" "0:1:1:0"

# --- UT7: what is left as it is
newh; first; second; stamp 949230
rc="$(drv)"
check "a set-up game with no stamp beside a stamped one: not run, the other is; exit 3; the closing line is not \"up to date\"" \
  "$rc:$(ran):$(said "$UPTODATE"):$(said "$NOTALL")" "3:first-game :0:1"
check "  ...it is named with its pasted line, the game's ID at its end" \
  "$(saidF "Second Game: set up by a version that keeps no record. Paste its installer line once: /bin/bash -c \"\$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)\" 1launcher-install 3215050")" 1
newh; first; stamp 949230 checkout v0.3.0
check "a stamp on checkout: not run, the line says so, exit 3" "$(drv):$(ran):$(said '^First Game: set up from checkout, so it is left as it is\.$'):$(said "$NOTALL")" "3::1:1"
newh; first; second; stamp 949230 v0.2.0; stamp 3215050 v0.2.0
check "the line that was fetched is the test, not the word release: with v0.2.0 fetched, stamps on v0.2.0 are run" "$(drv L1_FETCHED_REF=v0.2.0):$(ran)" "0:first-game second-game "
newh; first; stamp 949230 release v0.9.0
check "a stamp newer than the tree: left, not run, exit 3" "$(drv):$(ran):$(said '^First Game is at v0\.9\.0, newer than what GitHub sent (v0\.3\.0)\. Left as it is\.$')" "3::1"
newh; first; stamp 949230 release v0.3.0
check "a stamp equal to the tree's version: run (an update run again is the installer run again)" "$(drv):$(ran)" "0:first-game "
newh; first; stamp 949230; rm -rf "$TREE/first-game.off"; mv "$TREE/first-game" "$TREE/first-game.off"
check "a set-up game this version has no installer for: said, exit 1" "$(drv):$(ran):$(said '^!! First Game: this version has no installer for it\.$'):$(said "$NOTALL")" "1::1:1"
mv "$TREE/first-game.off" "$TREE/first-game"

# --- UT7: the games set up on this Mac are the list, not the stamps
newh; stamp 949230
check "a stamp whose wrapper is gone: the stamp removed, no installer run, said; no game is set up, exit 3" \
  "$(drv):$(ran):$([ -e "$UD/installed/949230" ] && echo kept || echo removed):$(said '^First Game: no longer set up on this Mac\. Skipped\.$'):$(said "$NOGAME")" "3::removed:1:1"
newh; mkw wrapper-949230.app bare 949230; stamp 949230
check "a wrapper kept with the game's program gone: the stamp removed, no installer run" \
  "$(drv):$(ran):$([ -e "$UD/installed/949230" ] && echo kept || echo removed):$(said '^First Game: no longer set up on this Mac\. Skipped\.$')" "3::removed:1"
newh; second; stamp 949230; stamp 3215050
check "  ...beside a game that is set up: that one is updated, exit 0" "$(drv):$(ran):$([ -e "$UD/installed/949230" ] && echo kept || echo removed):$(said "$UPTODATE")" "0:second-game :removed:1"
newh; mkw wrapper-949230.app bare 949230
check "a game not set up and with no stamp: nothing is said of it" "$(drv):$(said 'First Game')" "3:0"
newh; mkw a.app cs2 949230; mkw b.app cs2 949230; second; stamp 949230; stamp 3215050
check "two wrappers marked alike: that game not run, its stamp kept, exit 1; the other game still runs" \
  "$(drv):$(ran):$([ -e "$UD/installed/949230" ] && echo kept || echo removed):$(said '^First Game: two wrappers carry its marker\. Left as it is\.$')" "1:second-game :kept:1"
newh; mkw a.app cs2 949230; mkw b.app cs2 949230; stamp 949230
check "the only game with two wrappers: not \"No game is set up\", exit 1" "$(drv):$(ran):$(said "$NOGAME"):$(said "$NOTALL")" "1::0:1"
newh; first; stamp 949230
check "the game's wrapper variable set to a path that does not exist: the set-up game is still found, and its installer gets the variable as it came" \
  "$(drv CS2_WRAPPER=/nonexistent/x.app):$(ran):$(grep -c ' cs2w=/nonexistent/x.app ' "$CALLS"):$([ -e "$UD/installed/949230" ] && echo kept)" "0:first-game :1:kept"
newh; first; stamp 949230; table ../x
check "the row of a set-up game given the folder ../x: nothing run outside the tree, the row not looked at" \
  "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$([ -e "$UD/installed/949230" ] && echo kept)" "3:0:kept"
table
newh
check "no game set up: its sentence, exit 3, nothing run" "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said "$NOGAME"):$(said "$NOTALL")" "3:0:1:0"

# --- LFT4 (docs/plans/launcher-first-install.md, 3.5): 14unch3r itself, after the games. Its stamp is the file
# `launcher` of the record's folder; its app is ~/Applications/14unch3r.app with the builder's identifier.
lstamp() { printf '%s\t%s\t-\t100\n' "${1:-release}" "${2:-v0.2.0}" > "$UD/launcher"; }   # [line] [version]
app() {   # [link|wrapper|foreign]: 14unch3r.app in the scratch home's Applications, or something else at its path
  local a="$H/Applications/14unch3r.app" id=local.1launcher.window
  [ "${1:-}" = foreign ] && id=com.example.other
  if [ "${1:-}" = link ]; then mkdir -p "$H/elsewhere.app/Contents"; a="$H/elsewhere.app"; fi
  mkdir -p "$a/Contents/MacOS"
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>%s</string></dict></plist>\n' "$id" > "$a/Contents/Info.plist"
  [ "${1:-}" = wrapper ] && mkdir -p "$a/Contents/SharedSupport"
  [ "${1:-}" = link ] && ln -s "$a" "$H/Applications/14unch3r.app"
  return 0
}
lran() { grep -c '^LAUNCHER' "$CALLS"; }
lkept() { [ -e "$UD/launcher" ] && echo kept || echo removed; }
newh; app; lstamp release v0.0.9
rc="$(drv)"
check "LFT4 the launcher's stamp on release at an older version, its app, and no game: its installer is run once, with no argument, under L1_UPDATE=1; exit 0" \
  "$rc:$(lran):$(grep -c '^LAUNCHER args= argc=0 update=1 ref=release$' "$CALLS"):$(ran)" "0:1:1:"
check "LFT4 ...a heading before its lines, its closing line, and everything is up to date" \
  "$(grep -n -e '^=== 14unch3r ===$' -e '^the installer of the launcher ran$' -e '^14unch3r: updated\.$' -e "$UPTODATE" "$T/out" | cut -d: -f2- | tr '\n' '|'):$(said "$NOGAME"):$(lock)" \
  "=== 14unch3r ===|the installer of the launcher ran|14unch3r: updated.|Everything is up to date: 1launcher v0.3.0.|:0:none"
newh; app; lstamp release v0.3.0
check "LFT4 the same with the stamp at the tree's version: the installer is not run, nothing is said of 14unch3r, the same closing line, exit 0" \
  "$(drv):$(lran):$(said '14unch3r'):$(said "$UPTODATE"):$(said "$NOGAME")" "0:0:0:1:0"
newh; app; first; stamp 949230; lstamp release v0.2.0; : > "$EXITS/first-game.lstamp"
check "LFT4 a game's setup stamped the launcher at the tree's version: the game's installer ran and the launcher's did not; exit 0" \
  "$(drv):$(ran):$(lran):$(cut -f2 "$UD/launcher"):$(said "$UPTODATE")" "0:first-game :0:v0.3.0:1"
newh; app; first; stamp 949230; lstamp release v0.2.0
check "LFT4 a game updated and the launcher's stamp still older: the launcher's installer runs after the game's" \
  "$(drv):$(grep -oE '^(INSTALLER [^ ]*|LAUNCHER)' "$CALLS" | tr '\n' '|'):$(said "$UPTODATE")" "0:INSTALLER first-game|LAUNCHER|:1"
newh; app; lstamp release v0.9.0
check "LFT4 a launcher's stamp newer than the tree: left, its sentence, exit 3" \
  "$(drv):$(lran):$(said '^14unch3r is at v0\.9\.0, newer than what GitHub sent (v0\.3\.0)\. Left as it is\.$'):$(said "$NOTALL"):$(lkept)" "3:0:1:1:kept"
newh; app; lstamp checkout v0.2.0
check "LFT4 a launcher's stamp on checkout: left, its sentence, exit 3" \
  "$(drv):$(lran):$(said '^14unch3r: set up from checkout, so it is left as it is\.$'):$(said "$NOTALL"):$(lkept)" "3:0:1:1:kept"
newh; app; first; stamp 949230 checkout v0.2.0
check "LFT4 the app there and no launcher's stamp, its game left (a Mac from before this version): nothing is said of the launcher, and its installer is not run" \
  "$(drv):$(lran):$(said '14unch3r'):$(said '^First Game: set up from checkout'):$(lkept)" "3:0:0:1:removed"
newh; lstamp release v0.0.9
check "LFT4 a launcher's stamp, no app and no game: the stamp removed, nothing run, no game is set up, exit 3" \
  "$(drv):$(lran):$(lkept):$(said "$NOGAME"):$(said '14unch3r')" "3:0:removed:1:0"
for kind in link wrapper foreign; do
  newh; app "$kind"; lstamp release v0.0.9
  check "LFT4 the app's test: at the app's path a $kind counts as no app: the stamp removed, the installer not run" \
    "$(drv):$(lran):$(lkept):$(said "$NOGAME")" "3:0:removed:1"
done
newh; first; stamp 949230; lstamp release v0.2.0
check "LFT4 a launcher's stamp with no app beside a game that is set up: not removed, and its installer runs" \
  "$(drv):$(ran):$(lran):$(lkept)" "0:first-game :1:kept"
newh; app; first; stamp 949230; lstamp release v0.2.0; exits launcher=1
check "LFT4 the launcher's installer failing: exit 1, the closing block names 14unch3r as not rebuilt, and the game before it was still run" \
  "$(drv):$(ran):$(lran):$(said '^!! 14unch3r: not rebuilt (exit 1)\. Its lines above say why\.$'):$(said '^First Game: updated\.$'):$(said "$NOTALL"):$(said "$UPTODATE"):$(lock)" "1:first-game :1:1:1:1:0:none"
newh; app; lstamp release v0.0.9; exits launcher=3
check "LFT4 the launcher's installer stopping (exit 3): left, said, exit 3" \
  "$(drv):$(lran):$(said '^14unch3r: its installer stopped\. Its lines above say why\.$'):$(said "$NOTALL")" "3:1:1:1"
check "LFT4 a source gate: the identifier the driver tests for is the builder's ID=" \
  "$(sed -n 's/^WINDOW_ID="\(.*\)"$/\1/p' "$HERE/update-games.sh")" "$(sed -n 's/^ID="\(.*\)"$/\1/p' "$HERE/make-launcher-app.sh")"

# --- UT7: what stops the whole run before any installer
newh; first; stamp 949230; offer v0.4.0
check "an offer newer than the tree: the \"not yet\" sentence, nothing run, exit 3, no lock left" \
  "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said '^GitHub sent v0\.3\.0, not yet v0\.4\.0\. Try again in a few minutes\.$'):$(lock)" "3:0:1:none"
newh; first; stamp 949230; offer v0.3.0
check "an offer equal to the tree's version: run" "$(drv):$(ran)" "0:first-game "
newh; first; stamp 949230; ln -s "$$" "$UD/updating"
check "a live updating lock: the sentence, exit 3, nothing run, the lock still the other process's" \
  "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said '^An update is already running in another Terminal window\.$'):$(readlink "$UD/updating")" "3:0:1:$$"
rm -f "$UD/updating"; ( exit 0 ) & dead=$!; wait "$dead"; ln -s "$dead" "$UD/updating"
check "a dead one: taken over, the update runs, and no lock is left" "$(drv):$(ran):$(lock)" "0:first-game :none"
for t in 0 not-a-number -1; do
  newh; first; stamp 949230; ln -s -- "$t" "$UD/updating"
  check "a lock whose target is $t: taken over" "$(drv):$(ran):$(lock)" "0:first-game :none"
done
newh; first; stamp 949230; exits first-game=1
check "no lock is left after a run that failed" "$(drv):$(lock)" "1:none"
newh; first; stamp 949230
check "L1_FETCHED_REF unset: exit 2, nothing run" "$(: > "$CALLS"; env -u L1_FETCHED_REF HOME="$H" TMPDIR="$T/tmp" L1_UPDATE_DIR="$UD" bash "$D" < "$T/input" > "$T/out" 2>&1; echo $?):$(grep -c '^INSTALLER' "$CALLS"):$(lock)" "2:0:none"
check "an argument: exit 2, nothing run" "$(: > "$CALLS"; env HOME="$H" TMPDIR="$T/tmp" L1_UPDATE_DIR="$UD" L1_FETCHED_REF=release bash "$D" --yes < "$T/input" > "$T/out" 2>&1; echo $?):$(grep -c '^INSTALLER' "$CALLS")" "2:0"
NOREC='^This Mac keeps no record of what is installed\. Paste each game.s installer line once; after that it can update\.$'
newh; first; rm -rf "$UD"
check "no _update folder: the sentence of step 2, exit 3, nothing run, nothing made" "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said "$NOREC"):$([ -e "$UD" ] && echo made || echo none)" "3:0:1:none"
newh; first; stamp 949230; chmod 770 "$UD"
check "an _update the group can write: the same, nothing run, no lock written" "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said "$NOREC"):$(lock)" "3:0:1:none"
newh; first; stamp 949230; chmod 770 "$UD/installed"
check "an installed/ the group can write: the same" "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said "$NOREC")" "3:0:1"

# --- LFT4, with LF4a (docs/plans/launcher-first-install.md, 3.8): an update stops while an install runs, and a
# lock left by a restart does not stop it
/bin/sleep 300 & LIVE=$!
newh; first; stamp 949230; ln -s "$LIVE" "$UD/installing"
check "LFT4 a live installing: exit 3 with its sentence and the process, no installer run, updating gone afterwards, the install's lock untouched" \
  "$(drv):$(grep -c '^INSTALLER' "$CALLS"):$(said "^An install is running in another Terminal window (process $LIVE)\. Wait for it to finish, then update again\.\$"):$(lock):$(readlink "$UD/installing")" "3:0:1:none:$LIVE"
newh; first; stamp 949230; ln -s "$dead" "$UD/installing"
check "LFT4 a dead installing does not stop the update" "$(drv):$(ran):$(lock)" "0:first-game :none"
newh; first; stamp 949230; ln -s "$LIVE" "$UD/installing"; touch -h -t 202001010000 "$UD/installing"
check "LFT4 ...nor one older than the Mac's last start, its target a live process" "$(drv):$(ran)" "0:first-game "
newh; first; stamp 949230; ln -s "$LIVE" "$UD/updating"; touch -h -t 202001010000 "$UD/updating"
check "LFT4 an updating older than the Mac's last start, its target a live process: removed, the update runs, and no lock is left" "$(drv):$(ran):$(lock)" "0:first-game :none"
check "LFT4 a source gate: the take of updating stands before the look at installing" \
  "$(awk '/^if ! take_lock; then$/ { t = NR } /^if l1u_lock_live installing; then$/ { l = NR } END { print (t > 0 && l > t) ? "take first" : t ":" l }' "$D")" "take first"

# --- UT7: the file `updates.sh --open` writes
cat > "$T/bin/curl" << 'C'
#!/bin/bash
echo "CURL $*" >> "$CALLS"
out=""; w=0; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2 ;; -w) w=1; shift 2 ;; *) shift ;; esac; done
code="${STUB_CODE:-200}"
[ "$code" != 000 ] && [ -n "$out" ] && cp "$SERVED" "$out"   # whatever the code, the body is a script that would record its run
[ "$w" = 1 ] && printf '%s' "$code"
exit "${STUB_EXIT:-0}"
C
printf '#!/bin/bash\n{ printf "OPEN"; for a in "$@"; do printf "|%%s" "$a"; done; echo; } >> "$CALLS"\nexit "${STUB_OPEN_EXIT:-0}"\n' > "$T/bin/open"
chmod +x "$T/bin/curl" "$T/bin/open"
export SERVED="$T/served.sh"
printf '%s\n' 'echo "BOOT zero=$0 one=${1-} argc=$#" >> "$CALLS"' 'printf "%s" "$BASH_EXECUTION_STRING" > "$CALLS.text"' 'echo "a line of the update"' '[ -z "${STUB_SERVED_SLEEP:-}" ] || /bin/sleep "$STUB_SERVED_SLEEP"' 'exit "${STUB_UPDATE_EXIT:-0}"' > "$SERVED"
ADDR='https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/install.sh'
opened() {   # [VAR=value ...]: --open in the state ready; its answer in $T/open.out, the file's path in CMD
  newh; stamp 949230; offer v0.3.0; rm -rf "$T/tmp"; mkdir -p "$T/tmp"
  env HOME="$H" TMPDIR="$T/tmp" L1_UPDATE_DIR="$UD" L1_UPDATE_NOW="$NOW" L1_CURL="$T/bin/curl" L1_OPEN="$T/bin/open" "$@" bash "$U" --open > "$T/open.out" 2>&1
  CMD="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"
}
cmd() {   # [VAR=value ...]: the written file, run as Terminal would run it; output in $T/cmd.out; echoes its exit code
  : > "$CALLS"; rm -f "$CALLS.text"
  env HOME="$H" TMPDIR="$T/tmp" "$@" "$CMD" > "$T/cmd.out" 2>&1 < /dev/null; echo $?
}
csaid() { grep -c -- "$1" "$T/cmd.out"; }
inplace() { case "$CMD" in "$T/tmp/1launcher-update."??????"/Update 1launcher.command") echo there ;; esac; }   # the file's place
STEP6='^Updated\.\|^Not everything was updated\|^The update did not finish'
opened
check "--open when ready: opened, and L1_OPEN got -a Terminal and the path of one file in a new folder of TMPDIR" \
  "$(cat "$T/open.out"):$(grep -c '^OPEN|-a|Terminal|' "$CALLS"):$(inplace):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "opened:1:there:1"
check "  ...the file is mode 755, a bash script, and clear comes before its first line of words" \
  "$(stat -f %Lp "$CMD"):$(head -n 1 "$CMD"):$([ "$(grep -n '^clear$' "$CMD" | head -n 1 | cut -d: -f1)" -lt "$(grep -n '^ *echo ' "$CMD" | head -n 1 | cut -d: -f1)" ] && echo first)" "755:#!/bin/bash:first"
check "  ...it names the curl it was given, a plain absolute path" "$(sed -n 2p "$CMD")" "CURL='$T/bin/curl'"
rc="$(cmd)"
check "the file, run: curl called once with exactly these options, the body into a file beside it" \
  "$(grep -c '^CURL' "$CALLS"):$(grep -c "^CURL -q --proto =https --tlsv1.2 -sSL -o $(dirname "$CMD")/.1launcher-fetch.[0-9]* -w %{http_code} $ADDR\$" "$CALLS")" "1:1"
check "  ...what it fetched is run with \$0 1launcher-install and the one word update" "$(grep -c '^BOOT zero=1launcher-install one=update argc=1$' "$CALLS")" 1
check "  ...and is byte for byte what was served, with no line after it" "$(cat "$CALLS.text" 2>/dev/null)" "$(cat "$SERVED")"
check "  ...exit 0, the sentence for it after the update's lines, and the file and its folder are gone" \
  "$rc:$(grep -n -e '^a line of the update$' -e '^Updated\. You can close this window\.$' "$T/cmd.out" | cut -d: -f2- | tr '\n' '|'):$([ -e "$CMD" ] && echo left || echo gone):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" \
  "0:a line of the update|Updated. You can close this window.|:gone:0"
opened; rc="$(cmd STUB_UPDATE_EXIT=3)"
check "the update's exit 3: the file exits 3 and says not everything was updated" "$rc:$(csaid '^Not everything was updated: see the lines above\. You can close this window\.$'):$(csaid '^Updated\.')" "3:1:0"
for x in 1 2 130; do
  opened; rc="$(cmd STUB_UPDATE_EXIT=$x)"
  check "the update's exit $x: the file exits $x and says the update did not finish" "$rc:$(csaid '^The update did not finish: see the lines above\. You can close this window\.$'):$([ -e "$CMD" ] && echo left || echo gone)" "$x:1:gone"
done
opened; rc="$(cmd STUB_CODE=404)"
check "a 404: its sentence, nothing run, exit 1, no line of step 6, and the file and its folder are gone" \
  "$rc:$(csaid '^This version of 1launcher cannot update an install\. Paste the installer line from the guide instead\.$'):$(grep -c '^BOOT' "$CALLS"):$(csaid "$STEP6"):$(csaid '^You can close this window\.$'):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "1:1:0:0:1:0"
opened; rc="$(cmd STUB_CODE=404 STUB_EXIT=56)"
check "  ...whatever curl's exit (56)" "$rc:$(csaid '^This version of 1launcher cannot update an install\.'):$(grep -c '^BOOT' "$CALLS")" "1:1:0"
opened; rc="$(cmd STUB_CODE=000 STUB_EXIT=6)"
check "no answer (000): the other sentence, nothing run, exit 1, no line of step 6" \
  "$rc:$(csaid '^GitHub could not be reached\. Check the network, then try the update again\.$'):$(grep -c '^BOOT' "$CALLS"):$(csaid "$STEP6"):$(csaid '^You can close this window\.$')" "1:1:0:0:1"
opened; rc="$(cmd STUB_CODE=500)"
check "a 500: could not be reached, nothing run, exit 1" "$rc:$(csaid '^GitHub could not be reached\.'):$(grep -c '^BOOT' "$CALLS")" "1:1:0"
opened; rc="$(cmd STUB_CODE=200 STUB_EXIT=18)"
check "a 200 with curl's exit 18 (cut short): could not be reached, nothing run, exit 1" "$rc:$(csaid '^GitHub could not be reached\.'):$(grep -c '^BOOT' "$CALLS")" "1:1:0"
mkdir -p "$T/desk"; echo precious > "$T/desk/other.txt"; opened; cp "$CMD" "$T/desk/x.command"; CMD="$T/desk/x.command"; rc="$(cmd)"
check "copied beside another file and run: only itself is removed" "$rc:$(cat "$T/desk/other.txt" 2>/dev/null):$([ -e "$T/desk/x.command" ] && echo left || echo gone)" "0:precious:gone"
for bad in "/tmp/a'b" '/tmp/a$b' 'bin/curl' '/tmp/a b' ''; do
  opened L1_CURL="$bad"
  check "L1_CURL holding [$bad]: the file names /usr/bin/curl" "$(cat "$T/open.out"):$(sed -n 2p "$CMD")" "opened:CURL='/usr/bin/curl'"
done
opened STUB_OPEN_EXIT=1
check "Terminal could not be opened: failed and a sentence, exit 0 all the same, nothing left in TMPDIR" \
  "$(cut -f1 "$T/open.out"):$(cut -f2 "$T/open.out" | grep -c .):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "failed:1:0"

# --- LFT3 (docs/plans/launcher-first-install.md, 3.8): the file `updates.sh --install <ID>` writes, run as Terminal
# would run it. The record is at the default place under the scratch home: anywhere else the tool refuses.
asked() {   # [VAR=value ...]: --install 949230 with the launcher's stamp alone on release; its answer in $T/open.out, the file's path in CMD
  newh; IUD="$H/Library/Application Support/1launcher/_update"; mkdir -p "$IUD/installed"; chmod 700 "$IUD" "$IUD/installed"
  printf 'release\tv0.3.0\t-\t100\n' > "$IUD/launcher"; rm -rf "$T/tmp"; mkdir -p "$T/tmp"
  env HOME="$H" TMPDIR="$T/tmp" L1_UPDATE_DIR="$IUD" L1_UPDATE_NOW="$NOW" L1_CURL="$T/bin/curl" L1_OPEN="$T/bin/open" "$@" bash "$U" --install 949230 > "$T/open.out" 2>&1
  CMD="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"
}
iplace() { case "$CMD" in "$T/tmp/1launcher-install."??????"/Install with 1launcher.command") echo there ;; esac; }
gone() { if [ -e "$CMD" ]; then echo left; else echo gone; fi; }
CLOSE0='^Installed\. Open 14unch3r to play\. You can close this window\.$'
CLOSE5='^A Mac fix is not out yet for this build of the game: the lines above say more\.$'
CLOSE3='^Not finished\. To carry on, open 14unch3r and click the game again\. You can close this window\.$'
CLOSE1='^The install did not finish: the lines above say why\. To try again, open 14unch3r and click the game\.$'
NOREACH='^GitHub could not be reached\. Check the network, then open 14unch3r and click the game again\.$'
asked
check "LFT3 --install: opened, and L1_OPEN got -a Terminal and the path of one file in a new folder of TMPDIR" \
  "$(cat "$T/open.out"):$(grep -c '^OPEN|-a|Terminal|' "$CALLS"):$(iplace):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "opened:1:there:1"
rc="$(cmd)"
check "LFT3 the file, run: curl called once with exactly these options, the body into a file beside it" \
  "$(grep -c '^CURL' "$CALLS"):$(grep -c "^CURL -q --proto =https --tlsv1.2 -sSL -o $(dirname "$CMD")/.1launcher-fetch.[0-9]* -w %{http_code} $ADDR\$" "$CALLS")" "1:1"
check "LFT3 ...what it fetched is run with \$0 1launcher-install and the ID, one word and nothing after it" "$(grep -c '^BOOT zero=1launcher-install one=949230 argc=1$' "$CALLS")" 1
check "LFT3 ...and is byte for byte what was served" "$(cat "$CALLS.text" 2>/dev/null)" "$(cat "$SERVED")"
check "LFT3 ...exit 0, the closing line after the installer's lines, and the file and its folder are gone" \
  "$rc:$(grep -n -e '^a line of the update$' -e "$CLOSE0" "$T/cmd.out" | cut -d: -f2- | tr '\n' '|'):$(gone):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" \
  "0:a line of the update|Installed. Open 14unch3r to play. You can close this window.|:gone:0"
asked; rc="$(cmd STUB_UPDATE_EXIT=5)"
check "LFT3 the installer's exit 5: the file exits 5, says a Mac fix is not out yet, and then that it is installed" \
  "$rc:$(grep -n -e "$CLOSE5" -e "$CLOSE0" "$T/cmd.out" | cut -d: -f2- | cut -c1-9 | tr '\n' '|'):$(gone)" "5:A Mac fix|Installed|:gone"
for x in 3 4 129 130 143; do
  asked; rc="$(cmd STUB_UPDATE_EXIT=$x)"
  check "LFT3 the installer's exit $x: the file exits $x and says it is not finished and how to carry on" "$rc:$(csaid "$CLOSE3"):$(csaid "$CLOSE0"):$(csaid "$CLOSE1"):$(gone)" "$x:1:0:0:gone"
done
for x in 1 2; do
  asked; rc="$(cmd STUB_UPDATE_EXIT=$x)"
  check "LFT3 the installer's exit $x: the file exits $x and says the install did not finish" "$rc:$(csaid "$CLOSE1"):$(csaid "$CLOSE3"):$(csaid "$CLOSE0"):$(gone)" "$x:1:0:0:gone"
done
for answer in "000 6" "404 0" "404 56" "500 0" "200 18"; do
  asked; rc="$(cmd STUB_CODE="${answer% *}" STUB_EXIT="${answer#* }")"
  check "LFT3 the fetch answering ${answer% *} with curl's exit ${answer#* }: the installer is not run, its one sentence, exit 1, the file and its folder gone" \
    "$rc:$(csaid "$NOREACH"):$(grep -c '^BOOT' "$CALLS"):$(csaid "$CLOSE0"):$(gone):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "1:1:0:0:gone:0"
done
asked; : > "$CALLS"
env HOME="$H" TMPDIR="$T/tmp" STUB_SERVED_SLEEP=1 "$CMD" > "$T/cmd.out" 2>&1 < /dev/null & hp=$!
i=0; until grep -q '^BOOT' "$CALLS" 2>/dev/null || [ "$i" -gt 100 ]; do /bin/sleep 0.1; i=$((i + 1)); done
kill -HUP "$hp" 2>/dev/null; wait "$hp" 2>/dev/null; rc=$?
check "LFT3 a hangup while the installer runs: exit 129, no closing line, and the file and its folder are gone" "$rc:$(csaid "$CLOSE0"):$(gone):$(ls -A "$T/tmp" | wc -l | tr -d ' ')" "129:0:gone:0"
ODD="$T/an odd's \$(touch $T/ranX) place"; mkdir -p "$ODD/home/Library/Application Support/1launcher/_update/installed" "$ODD/tmp" "$ODD/home/Applications"
chmod 700 "$ODD/home/Library/Application Support/1launcher/_update" "$ODD/home/Library/Application Support/1launcher/_update/installed"
printf 'release\tv0.3.0\t-\t100\n' > "$ODD/home/Library/Application Support/1launcher/_update/launcher"; : > "$CALLS"
check "LFT3 with HOME and TMPDIR under a folder whose name holds a space, a quote and \$(touch X): it opens" \
  "$(env HOME="$ODD/home" TMPDIR="$ODD/tmp" L1_UPDATE_DIR="$ODD/home/Library/Application Support/1launcher/_update" L1_CURL="$T/bin/curl" L1_OPEN="$T/bin/open" bash "$U" --install 949230 2>&1)" opened
CMD="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"; : > "$CALLS"
rc="$(env HOME="$ODD/home" TMPDIR="$ODD/tmp" "$CMD" > "$T/cmd.out" 2>&1 < /dev/null; echo $?)"
check "LFT3 ...and runs: the installer got the ID, the closing line is said, the file and its folder are gone, and nothing named X was made" \
  "$rc:$(grep -c '^BOOT zero=1launcher-install one=949230 argc=1$' "$CALLS"):$(csaid "$CLOSE0"):$(gone):$(ls -A "$ODD/tmp" | wc -l | tr -d ' '):$([ -e "$T/ranX" ] && echo ran || echo none)" "0:1:1:gone:0:none"
mkdir -p "$T/desk2"; echo precious > "$T/desk2/other.txt"; asked; cp "$CMD" "$T/desk2/x.command"; CMD="$T/desk2/x.command"; rc="$(cmd)"
check "LFT3 copied beside another file and run: only itself is removed" "$rc:$(cat "$T/desk2/other.txt" 2>/dev/null):$(gone)" "0:precious:gone"

echo "$fails failure(s)"
[ "$fails" = 0 ]
