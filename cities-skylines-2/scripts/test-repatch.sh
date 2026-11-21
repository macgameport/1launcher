#!/bin/bash
# test-repatch.sh -- repatch.sh as a scratch copy beside a patches/ folder of stub patchers that record how
# they were run (name, target). No game, no Wine, no real patcher; HOME is a scratch folder too, so a default
# target can never be a real game folder.
#   bash scripts/test-repatch.sh            exit 0 = every case passed
#   MUTANT=1 bash scripts/test-repatch.sh   run() ignores a patch script's exit status; must exit 1
#   MUTANT=2 bash scripts/test-repatch.sh   one patch script is no longer run; must exit 1
# A run with no fix yet for the build (docs/plans/patch-outcomes.md, 2.3 and PT4); each must exit 1:
#   MUTANT=3  exit 3 counted as finished          MUTANT=4  exit 3 counted as failed
#   MUTANT=5  exit 0 with a NO FIX YET line        MUTANT=6  the summary back under the stub (set -e ends it unsummed)
#   MUTANT=7  a row of the table removed           MUTANT=8  the three lists' sum not checked
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/repatch-test.XXXX)"
trap 'rm -rf "$T"' EXIT
I="$T/inst"; mkdir -p "$I/patches" "$T/home"
cp "$REPO/repatch.sh" "$I/repatch.sh"; cp "$REPO/../common/wrappers.sh" "$I/wrappers.sh"   # as setup deploys them
case "${MUTANT:-0}" in
  1) sed -i '' 's#^  python3 "\$HERE/\$p" "\$@" || rc=\$?$#  python3 "$HERE/$p" "$@" || true#' "$I/repatch.sh"
     grep -q '^  python3 "\$HERE/\$p" "\$@" || true$' "$I/repatch.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  2) sed -i '' '/^run patch_longdelete\.py /d' "$I/repatch.sh"
     grep -q '^run patch_longdelete\.py ' "$I/repatch.sh" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  3) sed -i '' 's#^    0) RAN_OK=#    0|3) RAN_OK=#' "$I/repatch.sh"
     grep -q '^    0|3) RAN_OK=' "$I/repatch.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  4) sed -i '' '/^    3) NOFIX=/d' "$I/repatch.sh"
     grep -q '^    3) NOFIX=' "$I/repatch.sh" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  5) sed -i '' 's#^if \[ -n "\$NOFIX" \]; then exit 3; fi$#if [ -n "$NOFIX" ]; then exit 0; fi#' "$I/repatch.sh"
     grep -q '^if \[ -n "\$NOFIX" \]; then exit 0; fi$' "$I/repatch.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  6) sed -i '' "s#^if mkdir -p \"\\\$TB\" .*#mkdir -p \"\$TB\"; printf '{}' > \"\$TB/.settings.json\"; STUB_OK=1#" "$I/repatch.sh"
     grep -q '^mkdir -p "\$TB"; printf' "$I/repatch.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  7) sed -i '' '/^    patch_cohtml\.py) echo /d' "$I/repatch.sh"
     grep -q '^    patch_cohtml\.py) echo ' "$I/repatch.sh" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  8) sed -i '' '/^if \[ "\$RAN" != "\$EXPECTED" \]; then /d' "$I/repatch.sh"
     grep -q '^if \[ "\$RAN" != "\$EXPECTED" \]; then ' "$I/repatch.sh" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
esac

# a stub patcher: one line per run in $STUB_LOG (name, target); fails when STUB_FAIL lists it, and exits 3
# (not for this build) when STUB_NOFIX lists it
STUB='import os, sys
name = os.path.basename(sys.argv[0])
with open(os.environ["STUB_LOG"], "a") as f:
    f.write("%s\t%s\n" % (name, sys.argv[1]))
sys.exit(1 if name in os.environ.get("STUB_FAIL", "").split() else 3 if name in os.environ.get("STUB_NOFIX", "").split() else 0)'
for f in "$REPO"/patches/patch_*.py; do echo "$STUB" > "$I/patches/$(basename "$f")"; done
# the same repatch.sh with one run line taken out, beside its own stubs: the three lists then fall one short
I2="$T/inst2"; cp -R "$I" "$I2"; sed -i '' '/^run patch_longdelete\.py /d' "$I2/repatch.sh"
ST="Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"
G="$T/A.app/$ST"; G2="$T/B.app/$ST"; mkdir -p "$G" "$G2"; : > "$G/Cities2.exe"; : > "$G2/Cities2.exe"
SENTENCE='^The Wine 10 + D3DMetal stack was retired on 2026-11-09\. Its last version is commit [0-9a-f]\{7,40\}\.$'
TEN="cohtml colossal_io longfile asset_database fshandle mkparent lockbypass longdelete createfile lockleak "
SIXTEEN="cohtml colossal_io longfile asset_database dirdel dirhandle delfile delrec dirrec_nx delchild fshandle mkparent lockbypass longdelete createfile lockleak "

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
run() {    # [VAR=value ...] bash <repatch.sh> [args]: fresh log, output in $T/out; echoes the exit code
  : > "$T/log"
  ( cd "$T" && env -u CS2_GAME_DIR -u CS2_ERRNO_PATCHES -u STUB_FAIL -u STUB_NOFIX HOME="$T/home" STUB_LOG="$T/log" "$@" > "$T/out" 2>&1 ); echo $?
}
names() { cut -f1 "$T/log" | sed 's/^patch_//; s/\.py$//' | tr '\n' ' '; }
said()  { grep -c -- "$1" "$T/out"; }

# --- the default set: ten, in order
check "all succeed: exit 0" "$(run CS2_GAME_DIR="$G" bash "$I/repatch.sh" dxmt11)" 0
check "  ...ten, in the order that keeps Colossal.IO.dll's backup pristine" "$(names)" "$TEN"
check "  ...it says 10 of 10" "$(said '^10 of 10 patch scripts finished without error$')" 1
check "  ...and names no failure" "$(said '^FAILED')" 0
check "  ...targets: the game folder x4, mscorlib.dll, PDX.SDK.dll x5" "$(cut -f2 "$T/log" | sed 's|.*/||' | uniq -c | awk '{printf "%s:%s ", $1, $NF}')" "4:II 1:mscorlib.dll 5:PDX.SDK.dll "
check "CS2_ERRNO_PATCHES=1: exit 0" "$(run CS2_GAME_DIR="$G" CS2_ERRNO_PATCHES=1 bash "$I/repatch.sh" dxmt11)" 0
check "  ...sixteen, the six errno ones after the first four" "$(names)" "$SIXTEEN"
check "  ...it says 16 of 16" "$(said '^16 of 16 patch scripts finished without error$')" 1

# --- a failure is named, and does not stop the others
check "patch_mkparent fails: exit 1" "$(run CS2_GAME_DIR="$G" STUB_FAIL=patch_mkparent.py bash "$I/repatch.sh" dxmt11)" 1
check "  ...the other nine still ran, in order" "$(names)" "$TEN"
check "  ...it says 9 of 10 and names the one" "$(said '^9 of 10 patch scripts finished without error$'):$(said '^FAILED: patch_mkparent.py$')" "1:1"
check "two fail: exit 1" "$(run CS2_GAME_DIR="$G" STUB_FAIL="patch_cohtml.py patch_lockleak.py" bash "$I/repatch.sh" dxmt11)" 1
check "  ...8 of 10, both named, in the order they ran" "$(said '^8 of 10 patch scripts finished without error$'):$(said '^FAILED: patch_cohtml.py patch_lockleak.py$')" "1:1"

# --- not for this build: a script's exit 3 (docs/plans/patch-outcomes.md, 2.3 and 2.4; PT4)
ALL10="patch_cohtml.py patch_colossal_io.py patch_longfile.py patch_asset_database.py patch_fshandle.py patch_mkparent.py patch_lockbypass.py patch_longdelete.py patch_createfile.py patch_lockleak.py"
ERRNO6="patch_dirdel.py patch_dirhandle.py patch_delfile.py patch_delrec.py patch_dirrec_nx.py patch_delchild.py"
W_COHTML="  without patch_cohtml.py: the game's menus may not appear, or the game may crash as they start"
TBSTUB="$T/A.app/Contents/SharedSupport/prefix/drive_c/users/crossover/AppData/Local/JetBrains/Toolbox/.settings.json"
at() { grep -n -m1 -- "$1" "$T/out" | cut -d: -f1; }   # the first line that matches, by number
rm -f "$TBSTUB"
check "patch_cohtml exits 3: exit 3" "$(run CS2_GAME_DIR="$G" STUB_NOFIX=patch_cohtml.py bash "$I/repatch.sh" dxmt11)" 3
check "  ...all ten still ran, in order" "$(names)" "$TEN"
check "  ...9 of 10, the NO FIX YET line naming it, its without line, no FAILED" \
  "$(said '^9 of 10 patch scripts finished without error$'):$(said '^NO FIX YET FOR THIS BUILD: patch_cohtml.py$'):$(grep -cxF "$W_COHTML" "$T/out"):$(said '^FAILED')" "1:1:1:0"
check "  ...the JetBrains stub still written, and its line" "$([ -f "$TBSTUB" ] && echo written):$(said '^JetBrains Toolbox stub: written$')" "written:1"
check "  ...the lines in 2.3's order: count, NO FIX YET, without, stub, Finished, and Finished last" \
  "$(at '^9 of 10') $(at '^NO FIX YET') $(at '^  without ') $(at '^JetBrains Toolbox stub') $(at '^== Finished ==$')/$(tail -n 1 "$T/out")" \
  "$(for i in 0 1 2 3 4; do echo $(( $(at '^9 of 10') + i )); done | tr '\n' ' ' | sed 's/ $//')/== Finished =="
check "  ...and no line begins == Done, nor names the game folder after the count" "$(said '^== Done'):$(sed -n "$(at '^9 of 10'),\$p" "$T/out" | grep -c "$T")" "0:0"
check "one exits 3 and one fails: exit 1" "$(run CS2_GAME_DIR="$G" STUB_NOFIX=patch_cohtml.py STUB_FAIL=patch_lockleak.py bash "$I/repatch.sh" dxmt11)" 1
check "  ...8 of 10, the NO FIX YET line and the FAILED line" "$(said '^8 of 10 patch scripts'):$(said '^NO FIX YET FOR THIS BUILD: patch_cohtml.py$'):$(said '^FAILED: patch_lockleak.py$')" "1:1:1"
check "all ten exit 3: exit 3" "$(run CS2_GAME_DIR="$G" STUB_NOFIX="$ALL10" bash "$I/repatch.sh" dxmt11)" 3
check "  ...0 of 10, the ten named in order, no FAILED" "$(said '^0 of 10 patch scripts'):$(said "^NO FIX YET FOR THIS BUILD: $ALL10\$"):$(said '^FAILED')" "1:1:0"
check "  ...one without line per row of the table that holds one of the ten: six, the five PDX.SDK.dll scripts on one" \
  "$(said '^  without '):$(said '^  without patch_mkparent.py patch_lockbypass.py patch_longdelete.py patch_createfile.py patch_lockleak.py: mods may not download (stuck at "Preparing")$')" "6:1"
check "CS2_ERRNO_PATCHES=1, all sixteen exit 3: exit 3, 0 of 16" "$(run CS2_GAME_DIR="$G" CS2_ERRNO_PATCHES=1 STUB_NOFIX="$ALL10 $ERRNO6" bash "$I/repatch.sh" dxmt11):$(said '^0 of 16 patch scripts')" "3:1"
cat > "$T/want" << 'WANT'
  without patch_cohtml.py: the game's menus may not appear, or the game may crash as they start
  without patch_colossal_io.py: the game can crash as it starts
  without patch_longfile.py: error boxes when settings are read or saved
  without patch_asset_database.py: the game can misread its list of assets; what that looks like in play is not known
  without patch_dirdel.py patch_dirhandle.py patch_delfile.py patch_delrec.py patch_dirrec_nx.py patch_delchild.py: deleting files and folders can fail, which stops mod downloads on some versions of Wine
  without patch_fshandle.py: an error box at every start, and settings can go back to their defaults
  without patch_mkparent.py patch_lockbypass.py patch_longdelete.py patch_createfile.py patch_lockleak.py: mods may not download (stuck at "Preparing")
WANT
check "  ...every script named in a without line, each with its row of the table, in the order they ran" "$(grep '^  without ' "$T/out" | diff - "$T/want" > /dev/null && echo same || echo differs)" same
check "CS2_ERRNO_PATCHES=1, one of the six exits 3: exit 3, 15 of 16" \
  "$(run CS2_GAME_DIR="$G" CS2_ERRNO_PATCHES=1 STUB_NOFIX=patch_delrec.py bash "$I/repatch.sh" dxmt11):$(said '^15 of 16 patch scripts'):$(said '^NO FIX YET FOR THIS BUILD: patch_delrec.py$')" "3:1:1"
check "one run line removed and one script exits 3: exit 1, the lists' sum named" \
  "$(run CS2_GAME_DIR="$G" STUB_NOFIX=patch_cohtml.py bash "$I2/repatch.sh" dxmt11):$(said '^FAILED: 9 patch scripts ran where 10 were expected$')" "1:1"
G3="$T/C.app/$ST"; mkdir -p "$G3" "$T/C.app/Contents/SharedSupport/prefix/drive_c/users"; : > "$G3/Cities2.exe"
: > "$T/C.app/Contents/SharedSupport/prefix/drive_c/users/crossover"   # a file where the stub's folder must go
check "the stub's folder cannot be made after ten successes: exit 1" "$(run CS2_GAME_DIR="$G3" bash "$I/repatch.sh" dxmt11)" 1
check "  ...the summary still printed, the stub's FAILED line, and Finished last" \
  "$(said '^10 of 10 patch scripts finished without error$'):$(said '^FAILED: the JetBrains Toolbox stub could not be written$'):$(tail -n 1 "$T/out")" "1:1:== Finished =="

# --- no game there: nothing is run
check "no Cities2.exe under the target: exit 1" "$(run CS2_GAME_DIR="$T/nowhere" bash "$I/repatch.sh" dxmt11)" 1
check "  ...it says so, and no patch script ran" "$(said '^ERROR: no Cities2.exe under: '):$(wc -l < "$T/log" | tr -d ' ')" "1:0"

# --- targets: one stack. The retired names say so and run nothing; a folder is that folder, with the ten
for w in free FREE d3dmetal wine10; do
  check "$w: exit 2, the retirement sentence, no patch script run" "$(run CS2_GAME_DIR="$G" bash "$I/repatch.sh" $w):$(said "$SENTENCE"):$(wc -l < "$T/log" | tr -d ' ')" "2:1:0"
done
check "a folder as the argument: exit 0" "$(run bash "$I/repatch.sh" "$G2")" 0
check "  ...ten, all in that folder, and a line about the errno six" "$(names)/$(cut -f2 "$T/log" | grep -c "^$T/B.app/")/$(said 'needs CS2_ERRNO_PATCHES=1')" "$TEN/10/1"
check "  ...and CS2_ERRNO_PATCHES=1 makes it sixteen there" "$(run CS2_ERRNO_PATCHES=1 bash "$I/repatch.sh" "$G2"):$(names)" "0:$SIXTEEN"
check "no argument, CS2_GAME_DIR set: ten, in that folder" "$(run CS2_GAME_DIR="$G" bash "$I/repatch.sh"):$(names)/$(cut -f2 "$T/log" | grep -c "^$T/A.app/")" "0:$TEN/10"
check "no argument and no wrapper: exit 1, one plain line, nothing run" "$(run bash "$I/repatch.sh"):$(said '^repatch.sh: no wrapper of the game was found. Name the game folder in CS2_GAME_DIR.$'):$(wc -l < "$T/log" | tr -d ' ')" "1:1:0"
# --- the wrapper found by its marker (docs/plans/wrapper-names.md, WT15, WT4b), with wrappers.sh beside repatch.sh
mkw() {   # <app>: a wrapper carrying the game's marker, with the game in it
  mkdir -p "$1/$ST" "$1/Contents/SharedSupport/wine/bin"; : > "$1/$ST/Cities2.exe"
  printf '#!/bin/sh\nexit 0\n' > "$1/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$1/Contents/SharedSupport/wine/bin/wine64"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>L1Role</key><string>game-wrapper</string><key>L1SteamAppID</key><integer>949230</integer></dict></plist>' > "$1/Contents/Info.plist"
}
mkw "$T/home/Applications/any name.app"
check "run by hand with a marked wrapper of any name: ten, in its game folder" "$(run bash "$I/repatch.sh"):$(names)/$(cut -f2 "$T/log" | grep -c "^$T/home/Applications/any name.app/")" "0:$TEN/10"
mkw "$T/home/Applications/another.app"
check "two wrappers marked alike: exit 1, the duplicates line, nothing run" "$(run bash "$I/repatch.sh"):$(said 'Move one to the Trash, or name the one to use in CS2_WRAPPER.'):$(wc -l < "$T/log" | tr -d ' ')" "1:1:0"
rm -rf "$T/home/Applications/another.app"; mv "$I/wrappers.sh" "$T/wrappers.sh.aside"
check "wrappers.sh not beside it: exit 1, one plain line, nothing run" "$(run bash "$I/repatch.sh"):$(said '^repatch.sh: wrappers.sh is not beside it'):$(wc -l < "$T/log" | tr -d ' ')" "1:1:0"
check "  ...CS2_GAME_DIR still works without it" "$(run CS2_GAME_DIR="$G" bash "$I/repatch.sh"):$(names)" "0:$TEN"
mv "$T/wrappers.sh.aside" "$I/wrappers.sh"

echo "$fails failure(s)"
[ "$fails" = 0 ]
