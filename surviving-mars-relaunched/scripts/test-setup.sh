#!/bin/bash
# test-setup.sh -- scripts/setup.sh (docs/plans/surviving-mars-install.md, 2.5, MT6). A copy of the game's
# folder runs in a scratch tree with HOME, the state folder and the app in a scratch folder. sysctl, sw_vers,
# arch, pgrep, ps, xcrun and osascript are stubs first on PATH, so this Mac's own processor, macOS and
# processes are not what is tested, no Swift is compiled and no game is looked for. make-app.sh is the real
# one (its progress window is skipped: the xcrun stub says there is no swiftc); common/make-launcher-app.sh
# is a stub that records how it was called. Nothing is written outside the scratch folder.
#   bash scripts/test-setup.sh            exit 0 = every case passed
#   MUTANT=<n> bash scripts/test-setup.sh   each must exit 1; 2 = the mutant did not apply
#     1 the app is pointed at the checkout's launcher     2 the helper is not copied
#     3 a copy is made only when none is there            4 a copy is written in place
#     5 a file in runs/ is removed                        6 the lock test is removed
#     7 the installer's own lock is refused               8 any live holder is passed
#     9 14unch3r is built in the real folder with SM_APP set
#    10 the test of who may write to the state folder is removed
#    11 the running-game test is removed                 12 --mac-only goes on to copy
#    13 "also in Spotlight and Launchpad" for an app in any folder
#    14 the closing line about mods from Paradox Mods is removed
#    docs/plans/wrapper-names.md: 15 the copy of wrappers.sh removed (WT15 (a))   16 the mover before the state folder's tests and the copies (WT17 (c))
#    17 the early test of the two files removed (WT17 (f))   18 the resolver's exit 2 treated as none (WT4b)
#    docs/plans/built-in-update.md, 3.3 (UT5 and "UT5, also"):
#    19 the stamp written before the app is built           20 the stamp written when the app's builder fails
#    21 the stamp written in place, not beside its place and renamed (common/updates.sh)
#    22 updates.sh not deployed                              23 update-dir not written
#    24 the record's folders not tested for being the user's own
#    25 the own-files loop for paths.sh, updates.sh and games.tsv dropped
#    26 updates.sh deployed after 14unch3r is built          27 the closing words about a game set up by an older version dropped
set -u
unset L1_UPDATE_DIR L1_UPDATE_NOW L1_FETCHED_REF L1_FETCHED_COMMIT L1_DATA_ROOT CS2_WRAPPER   # the record's variables are the cases' own
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
T="$(mktemp -d /tmp/sm-setup-test.XXXX)"
OTHER=""
trap '[ -n "$OTHER" ] && kill "$OTHER" 2>/dev/null; rm -rf "$T"' EXIT
M="${MUTANT:-0}"
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

# --- the scratch tree: the game's folder as it is, and a recording stand-in for the 14unch3r builder
G="$T/repo/surviving-mars-relaunched"
mkdir -p "$G/scripts" "$G/tools" "$T/repo/common" "$T/bin" "$T/home/Applications"
cp "$HERE/scripts/setup.sh" "$G/scripts/"; cp "$HERE/launch-relaunched.sh" "$HERE/make-app.sh" "$G/"
cp "$HERE/tools/frame-fix.exe" "$G/tools/"
cp "$REPO/common/wrappers.sh" "$REPO/common/move-wrappers.sh" "$T/repo/common/"   # docs/plans/wrapper-names.md
# the record of versions (docs/plans/built-in-update.md, 3.3): where it is, its tool and the table of games are
# setup's own files too, and the scratch tree has a changelog whose first version heading is the tree's version
cp "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$REPO/common/games.tsv" "$T/repo/common/"
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.4.2 (2026-11-24)' '' 'Words.' '' '## v0.4.1 (2026-11-20)' > "$T/repo/CHANGELOG.md"
# the stand-in for the 14unch3r builder also records whether the record's tool was deployed when it was called
printf '#!/bin/bash\necho "make-launcher-app $*" >> "%s/calls"\n( . "$(dirname "$0")/paths.sh"; [ -f "$L1_UPDATE_DIR/updates.sh" ] && echo there || echo missing ) > "%s/calls.tool"\nexit "${WINDOW_RC:-0}"\n' "$T" "$T" > "$T/repo/common/make-launcher-app.sh"
S="$G/scripts/setup.sh"
py() { python3 -I - "$@"; }
case "$M" in
  0) ;;
  1) sed -i '' 's|^if ! SM_SCRIPT="\$STATE/launch-relaunched.sh" SM_GAME_EXE=|if ! SM_SCRIPT="$GAME_ROOT/launch-relaunched.sh" SM_GAME_EXE=|' "$S" ;;
  2) sed -i '' '/^put "\$GAME_ROOT\/tools\/frame-fix.exe" /d' "$S" ;;
  3) sed -i '' 's|^  local tmp="\$2.new.\$\$"$|  local tmp="$2.new.$$"; [ -e "$2" ] \&\& return 0|' "$S" ;;
  4) sed -i '' 's|^  if cp "\$1" "\$tmp" \&\& chmod 755 "\$tmp" \&\& mv -f "\$tmp" "\$2"; then return 0; fi$|  if cp "$1" "$2" \&\& chmod 755 "$2"; then return 0; fi|' "$S" ;;
  5) sed -i '' 's|^put "\$GAME_ROOT/launch-relaunched.sh" |rm -f "$STATE/runs/kept.log"; put "$GAME_ROOT/launch-relaunched.sh" |' "$S" ;;
  6) sed -i '' 's|^if \[ -n "\$h" \] \&\& kill -0 "\$h" 2>/dev/null; then$|if false; then|' "$S" ;;
  7) sed -i '' 's/^  if \[ "\${SM_VIA_INSTALLER:-0}" != 1 \] || \[ "\$h" != "\$PPID" \]; then$/  if true; then/' "$S" ;;
  8) sed -i '' 's/^  if \[ "\${SM_VIA_INSTALLER:-0}" != 1 \] || \[ "\$h" != "\$PPID" \]; then$/  if [ "${SM_VIA_INSTALLER:-0}" != 1 ]; then/' "$S" ;;
  9) sed -i '' 's|^if \[ -n "\${SM_APP:-}" \]; then bash "\$REPO/common/make-launcher-app.sh" --dest "\$(dirname "\$APP")" |if [ -n "${SM_APP:-}" ]; then bash "$REPO/common/make-launcher-app.sh" |' "$S" ;;
  10) sed -i '' 's/^    own_folder "\$d" || /    true || /' "$S" ;;
  11) sed -i '' '/^if game_running; then /d' "$S" ;;
  12) sed -i '' '/^  \[ "\$ROSETTA" = 1 \] || exit 1$/{N;s/.*/  :/;}' "$S" ;;
  13) sed -i '' 's/^  case "\$(dirname "\$1")" in "\$HOME\/Applications"|\/Applications) return 0 ;; esac$/  return 0/' "$S" ;;
  14) sed -i '' '/^  If you use mods from Paradox Mods: /d' "$S" ;;
  15) sed -i '' '/^put "\$REPO\/common\/wrappers.sh" "\$STATE\/wrappers.sh"$/d' "$S" ;;
  16) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
i = s.index("# --- the wrapper's name, after the copies"); j = s.index("find_wrapper   # resolved again")
blk = s[i:j]; s = s[:i] + s[j:]
k = s.index("# --- the state folder:"); s = s[:k] + blk + s[k:]
open(p, "w").write(s)
PY
     ;;
  17) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'for f in "$REPO/common/wrappers.sh" "$REPO/common/move-wrappers.sh"; do\n'
i = s.index(a); j = s.index("done\n", i) + 5
s = s[:i] + s[j:]
open(p, "w").write(s)
PY
     ;;
  18) sed -i '' 's/^  if \[ "\$rc" = 2 \]; then echo "  !! Setup stops here/  if false; then echo "  !! Setup stops here/' "$S" ;;
  19) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = "# --- the game's app, built to run that copy\n"
assert s.count("\nstamp_step\n") == 1 and s.count(a) == 1
s = s.replace("\nstamp_step\n", "\n").replace(a, "stamp_step\n" + a)
open(p, "w").write(s)
PY
     ;;
  20) sed -i '' 's|^  echo "  !! The game.s app was not built\. The lines above say why\."$|  stamp_step; echo "  !! The app was not built."|' "$S" ;;
  21) perl -pi -e 's/^  if printf \x27%s\\n\x27 "\$2" > "\$t" 2>\/dev\/null && mv -f "\$t" "\$1" 2>\/dev\/null; then return 0; fi$/  if printf \x27%s\\n\x27 "\$2" > "\$1" 2>\/dev\/null; then : > "\$t"; return 0; fi/' "$T/repo/common/updates.sh" ;;
  22) sed -i '' '/^put "\$REPO\/common\/updates.sh" "\$L1_UPDATE_DIR\/updates.sh"$/d' "$S" ;;
  23) sed -i '' '/^put_line "\$L1_UPDATE_DIR" "\$STATE\/update-dir"$/d' "$S" ;;
  24) sed -i '' 's/^    own_folder "\$d" || { echo "  !! \$(tilde "\$d") is not a folder of your own that only you can write to; setup will not keep its record /    true || { echo "  !! $(tilde "$d") is not a folder of your own that only you can write to; setup will not keep its record /' "$S" ;;
  25) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'for f in "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$REPO/common/games.tsv"; do\n'
i = s.index(a); j = s.index("done\n", i) + 5
s = s[:i] + s[j:]
open(p, "w").write(s)
PY
     ;;
  26) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'put "$REPO/common/updates.sh" "$L1_UPDATE_DIR/updates.sh"\n'; b = '\nrm -f "$OUT"\n'
assert s.count(a) == 1 and s.count(b) == 1
s = s.replace(a, "").replace(b, b + a)
open(p, "w").write(s)
PY
     ;;
  27) sed -i '' '/^unrecorded_games$/d' "$S" ;;
  *) echo "REFUSED: no mutant $M"; exit 2 ;;
esac
if [ "$M" != 0 ]; then
  case "$M" in
    21) cmp -s "$REPO/common/updates.sh" "$T/repo/common/updates.sh" && { echo "REFUSED: mutant $M did not apply"; exit 2; }
        bash -n "$T/repo/common/updates.sh" || { echo "REFUSED: mutant $M does not parse"; exit 2; } ;;
    *) cmp -s "$HERE/scripts/setup.sh" "$S" && { echo "REFUSED: mutant $M did not apply"; exit 2; } ;;
  esac
  bash -n "$S" || { echo "REFUSED: mutant $M does not parse"; exit 2; }
fi

# --- the stubs
stub() { printf '#!/bin/bash\n%s\n' "$2" > "$T/bin/$1"; chmod +x "$T/bin/$1"; }
stub sysctl '[ "$*" = "-n hw.optional.arm64" ] && { echo "${STUB_ARM:-1}"; exit 0; }; exec /usr/sbin/sysctl "$@"'
stub sw_vers 'echo "${STUB_OS:-27.2.1}"'
stub arch 'exit "${STUB_ROSETTA_RC:-0}"'
stub pgrep 'case "$*" in "-f Mars\\.exe") [ "${STUB_GAME:-0}" = 1 ] && { echo 4242; exit 0; } ;; esac; exit 1'
stub ps 'case "$*" in *4242*) echo "${STUB_GAME_CMD:-}"; exit 0 ;; esac; exec /bin/ps "$@"'
stub xcrun 'exit 1'
stub osascript 'exit 0'

H="$T/home"; STATE="$T/state"; APP="$T/apps/Surviving Mars Relaunched.app"
W="$H/Applications/SurvivingMars.app"; PFX="$W/Contents/SharedSupport/prefix"
GAMEDIR="$PFX/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
mkdir -p "$GAMEDIR" "$T/apps" "$W/Contents/SharedSupport/wine/bin"
printf '#!/bin/sh\nexit 0\n' > "$W/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$W/Contents/SharedSupport/wine/bin/wine64"
# the game's marker (docs/plans/wrapper-names.md, 3.1): a case about something else meets a wrapper setup leaves under its name
printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>L1Role</key><string>game-wrapper</string><key>L1SteamAppID</key><integer>3215050</integer></dict></plist>' > "$W/Contents/Info.plist"
stub wprobe '[ -n "${STUB_WHOLDERS:-}" ] && echo "$STUB_WHOLDERS"; exit 0'   # the wrapper mover's open-files probe
export L1_WMOVE_PROBE="$T/bin/wprobe"
run() {   # <args...>: setup's exit code; its output in $T/out. The caller sets STUB_* and SM_VIA_INSTALLER
  : > "$T/calls"
  (cd "$T" && PATH="$T/bin:$PATH" HOME="$H" SM_STATE="$STATE" SM_APP="$APP" SM_GAME_EXE="$GAMEDIR/Mars.exe" /bin/bash "$S" "$@") > "$T/out" 2>&1 < /dev/null
  echo $?
}
copies() { ls -A "$STATE" 2>/dev/null | grep -c -E '^launch-relaunched\.sh$|^tools$'; }
ino() { stat -f %i "$1" 2>/dev/null; }

# --- this Mac alone
check "--mac-only on a ready Mac: exit 0" "$(run --mac-only):$(grep -c 'OK (tested)' "$T/out")" "0:1"
check "  ...--yes and --check are taken" "$(run --mac-only --yes --check)" 0
check "  ...without Rosetta: exit 1" "$(STUB_ROSETTA_RC=1 run --mac-only):$(grep -c 'Rosetta 2  *MISSING' "$T/out")" "1:1"
check "  ...on an Intel Mac: exit 3, its own words" "$(STUB_ARM=0 run --mac-only):$(grep -c 'Intel processor' "$T/out")" "3:1"
check "  ...below macOS 14: exit 3, its own words" "$(STUB_OS=13.6.1 run --mac-only):$(grep -c 'does not load below macOS 14' "$T/out")" "3:1"
check "  ...on a macOS not tested: a caution, and exit 0" "$(STUB_OS=15.2 run --mac-only):$(grep -c 'CAUTION' "$T/out")" "0:1"
check "  ...and nothing was copied or built by any of them" "$(copies):$([ -e "$APP" ] && echo app || echo none):$(wc -l < "$T/calls" | tr -d ' ')" "0:none:0"
check "an unknown option is exit 2" "$(run --desktop)" 2
check "--check says what it would do and changes nothing" "$(run --check):$(grep -c 'would copy the launcher' "$T/out"):$(copies):$([ -e "$APP" ] && echo app || echo none)" "0:1:0:none"

# --- the whole of it
mkdir -p "$STATE/runs" "$STATE/backup"; echo "a run" > "$STATE/runs/kept.log"; echo "a save" > "$STATE/backup/kept.sav"
before="$(cd "$STATE" && find runs backup -type f -exec shasum {} + | shasum | cut -c1-12)"
rc=$(run)
check "setup on a ready Mac: exit 0" "$rc:$(grep -c '^=== setup complete ===$' "$T/out")" "0:1"
check "  ...the launcher is in the state folder, the same bytes" "$(cmp -s "$HERE/launch-relaunched.sh" "$STATE/launch-relaunched.sh" && echo same)" same
check "  ...and so is the helper, under tools/, where the launcher looks for it" "$(cmp -s "$HERE/tools/frame-fix.exe" "$STATE/tools/frame-fix.exe" && echo same):$(grep -c '^HELPER="\$HERE/tools/frame-fix.exe"$' "$STATE/launch-relaunched.sh")" "same:1"
check "  ...the app's program names that copy" "$(grep -c "^SCRIPT=\"$STATE/launch-relaunched.sh\"\$" "$APP/Contents/MacOS/launch" 2>/dev/null)" 1
check "  ...and no line of it names the folder setup ran from" "$(grep -c "$T/repo" "$APP/Contents/MacOS/launch" 2>/dev/null)" 0
check "  ...runs/ and backup/ are untouched, their files included" "$(cd "$STATE" && find runs backup -type f -exec shasum {} + | shasum | cut -c1-12)" "$before"
check "  ...the 14unch3r builder was called, to build beside the app" "$(cat "$T/calls")" "make-launcher-app --dest $T/apps"
check "  ...and nothing was built in the real place" "$(ls -A "$H/Applications" | tr '\n' ' ')" "SurvivingMars.app "
check "  ...no temporary copy is left in the state folder" "$(find "$STATE" -name '*.new.*' | wc -l | tr -d ' ')" 0
check "  ...the closing line names the app, and for an app in a scratch folder says no more" "$(grep -c "^The game:   $APP\$" "$T/out"):$(grep -c 'Spotlight' "$T/out")" "1:0"
check "  ...the line about mods from Paradox Mods closes the block" "$(tail -n 1 "$T/out")" "  If you use mods from Paradox Mods: at the first start, open the game's Mod Manager before you load a save."
check "  ...the lines that say how to update speak of a checkout" "$(grep -c '^To update:  after  git pull , run  bash surviving-mars-relaunched/scripts/setup.sh  again\.$' "$T/out")" 1

# --- an older copy is replaced, by a rename and not in place
echo "an older launcher" > "$STATE/launch-relaunched.sh"; echo "an older helper" > "$STATE/tools/frame-fix.exe"
i1="$(ino "$STATE/launch-relaunched.sh")"; i2="$(ino "$STATE/tools/frame-fix.exe")"
rc=$(run)
check "an older copy of each is replaced" "$rc:$(cmp -s "$HERE/launch-relaunched.sh" "$STATE/launch-relaunched.sh" && echo same):$(cmp -s "$HERE/tools/frame-fix.exe" "$STATE/tools/frame-fix.exe" && echo same)" "0:same:same"
check "  ...by a rename: neither file is the one that was there" "$([ "$(ino "$STATE/launch-relaunched.sh")" != "$i1" ] && echo new):$([ "$(ino "$STATE/tools/frame-fix.exe")" != "$i2" ] && echo new)" "new:new"
check "14unch3r not built is not a problem" "$(WINDOW_RC=3 run):$(grep -c '14unch3r  *not built' "$T/out")" "0:1"

# --- what stops it, with nothing copied
refused() {   # <name> <want rc> <words>: after a run the caller made, the copies are still the older ones
  check "$1" "$rc:$(grep -c -- "$3" "$T/out"):$(cat "$STATE/launch-relaunched.sh")" "$2:1:an older launcher"
}
echo "an older launcher" > "$STATE/launch-relaunched.sh"
rc=$(STUB_GAME=1 STUB_GAME_CMD="$GAMEDIR/Mars.exe -x" run); refused "the game running stops it with exit 3" 3 "The game is running"
rc=$(STUB_GAME=1 STUB_GAME_CMD="/usr/bin/vim notes-about-Mars.exe" run)
check "  ...a process that only mentions Mars.exe does not" "$rc" 0
echo "an older launcher" > "$STATE/launch-relaunched.sh"
sleep 300 & OTHER=$!
ln -s "$OTHER" "$PFX/.launcher.lock"
rc=$(run); refused "a lock held by a live process stops it with exit 3" 3 "is using the game's wrapper (process $OTHER)"
rc=$(SM_VIA_INSTALLER=1 run); refused "  ...and so does that lock with SM_VIA_INSTALLER=1: it is not the parent's" 3 "is using the game's wrapper"
rm -f "$PFX/.launcher.lock"
# the installer's own lock: a parent process that holds the lock and runs setup as its child
parent() {   # <SM_VIA_INSTALLER value or "">: setup run by a shell whose own process number is in the lock
  : > "$T/calls"
  (cd "$T" && PATH="$T/bin:$PATH" HOME="$H" SM_STATE="$STATE" SM_APP="$APP" SM_GAME_EXE="$GAMEDIR/Mars.exe" VIA="$1" LOCKF="$PFX/.launcher.lock" S="$S" \
     /bin/bash -c 'ln -s "$$" "$LOCKF"; if [ -n "$VIA" ]; then SM_VIA_INSTALLER="$VIA" /bin/bash "$S"; else /bin/bash "$S"; fi; rc=$?; rm -f "$LOCKF"; exit $rc') > "$T/out" 2>&1 < /dev/null
  echo $?
}
rc=$(parent ""); refused "the parent's lock without SM_VIA_INSTALLER stops it with exit 3" 3 "is using the game's wrapper"
rc=$(parent 1)
check "run by the installer, its parent holding the lock: it goes on" "$rc:$(cmp -s "$HERE/launch-relaunched.sh" "$STATE/launch-relaunched.sh" && echo same)" "0:same"
check "  ...and the lines that say how to update speak of the installer" "$(grep -c '^To update:  open the installer again\.$' "$T/out")" 1
( : ) & dead=$!; wait "$dead" 2>/dev/null
ln -s "$dead" "$PFX/.launcher.lock"
check "a lock left by a process that is gone does not stop it" "$(run)" 0
rm -f "$PFX/.launcher.lock"; kill "$OTHER" 2>/dev/null; wait "$OTHER" 2>/dev/null; OTHER=""

echo "an older launcher" > "$STATE/launch-relaunched.sh"
chmod 777 "$STATE"
rc=$(run); refused "a state folder others can write to is refused" 1 "is not a folder of your own that only you can write to"
chmod 755 "$STATE"; chmod 775 "$STATE/tools"
rc=$(run); refused "  ...and so is a tools folder the group can write to" 1 "is not a folder of your own that only you can write to"
chmod 755 "$STATE/tools"
mkdir -p "$T/rootbin"; printf '#!/bin/sh\n[ "$1" = -u ] && { echo 0; exit 0; }\nexec /usr/bin/id "$@"\n' > "$T/rootbin/id"; chmod +x "$T/rootbin/id"
(cd "$T" && PATH="$T/rootbin:$T/bin:$PATH" HOME="$H" SM_STATE="$STATE" SM_APP="$APP" /bin/bash "$S") > "$T/out" 2>&1 < /dev/null; rc=$?
refused "root is refused" 1 "as root"
rm -f "$G/tools/frame-fix.exe"
rc=$(run); refused "with the helper gone from setup's own files it stops, and copies nothing" 1 "setup's own files are missing"
cp "$HERE/tools/frame-fix.exe" "$G/tools/"

# --- a state folder that is not there yet is made, for this user alone to write to
rm -rf "$STATE"
rc=$(run)
check "a state folder that is not there is made, and only its owner can write to it" "$rc:$(stat -f %Lp "$STATE"):$(stat -f %Lp "$STATE/tools")" "0:755:755"

# --- "also in Spotlight and Launchpad" only where that is true (docs/plans/first-run-findings.md, 2.8)
rc=$( : > "$T/calls"; (cd "$T" && PATH="$T/bin:$PATH" HOME="$H" SM_STATE="$STATE" SM_APP="$H/Applications/Surviving Mars Relaunched.app" SM_GAME_EXE="$GAMEDIR/Mars.exe" /bin/bash "$S") > "$T/out" 2>&1 < /dev/null; echo $?)
check "an app in ~/Applications: the closing line says it is also in Spotlight and Launchpad" "$rc:$(grep -c '^The game:   ~/Applications/Surviving Mars Relaunched\.app, also in Spotlight and Launchpad$' "$T/out")" "0:1"
rm -rf "$H/Applications/Surviving Mars Relaunched.app"
spot() { ( HOME="$H"; eval "$(awk '/^in_spotlight\(\) \{/ { p = 1 } p { print } p && /^\}$/ { exit }' "$S")"; in_spotlight "$1" && echo yes || echo no ); }
check "  ...the function that decides it: /Applications yes, ~/Applications yes" "$(spot "/Applications/A Game.app"):$(spot "$H/Applications/A Game.app")" "yes:yes"
check "  ...a folder inside one of them, a scratch folder, the home folder: no" "$(spot "/Applications/Games/A Game.app"):$(spot "$T/apps/A Game.app"):$(spot "$H/A Game.app")" "no:no:no"

# --- game_running is the launcher's own, word for word
fn() { awk '/^game_running\(\) \{$/ { p = 1 } p { print } p && /^\}$/ { exit }' "$1"; }
check "game_running equals the launcher's" "$(fn "$S" | shasum | cut -c1-12):$(fn "$S" | wc -l | tr -d ' ')" "$(fn "$HERE/launch-relaunched.sh" | shasum | cut -c1-12):8"

# --- docs/plans/wrapper-names.md: WT4b, WT15, WT17. A second home, whose wrapper is under its old name, unmarked.
H1="$H"; A1="$APP"
H="$T/home2"; W2="$H/Applications/SurvivingMars.app"; NW2="$H/Applications/wrapper-3215050.app"
mkw2() {   # an unmarked Surviving Mars wrapper under its old name, with the game in it
  rm -rf "$H"; mkdir -p "$W2/Contents/SharedSupport/wine/bin" "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
  printf '#!/bin/sh\nexit 0\n' > "$W2/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$W2/Contents/SharedSupport/wine/bin/wine64"
  : > "$W2/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>' > "$W2/Contents/Info.plist"
  rm -rf "$STATE"
}
snaph() { (cd "$H" && find . | LC_ALL=C sort | shasum | cut -c1-12); }
mkw2; before="$(snaph)"
check "WT17 --check: one wrapper: line, would move, both names, exit 0, nothing changed" \
  "$(run --check):$(grep -c '^wrapper: would move: ~/Applications/SurvivingMars.app -> ~/Applications/wrapper-3215050.app$' "$T/out"):$(snaph)" "0:1:$before"
rc=$(run)
check "WT17 a run renames the wrapper, marks it, and the app finds it" \
  "$rc:$([ -d "$NW2" ] && echo renamed):$(plutil -extract L1Role raw -o - "$NW2/Contents/Info.plist" 2>/dev/null)" "0:renamed:game-wrapper"
check "  ...it says what it renamed, both names, and how to decline" \
  "$(grep -c '^Renamed:    ~/Applications/SurvivingMars.app -> ~/Applications/wrapper-3215050.app$' "$T/out"):$(grep -c 'L1_KEEP_WRAPPER_NAMES=1' "$T/out")" "1:1"
check "WT15 the deployed wrappers.sh is there, the same bytes as the repo's" "$(cmp -s "$REPO/common/wrappers.sh" "$STATE/wrappers.sh" && echo same)" same
check "  ...and the launcher in the state folder finds the renamed wrapper with it" "$(HOME="$H" bash "$STATE/wrappers.sh" find game 3215050)" "$NW2"
check "WT17 --check on a home already moved: nothing to rename" "$(run --check):$(grep -c '^wrapper: nothing to rename$' "$T/out")" "0:1"
mkw2; mv "$G/tools/frame-fix.exe" "$T/ff.aside"
check "WT17 an own file missing: exit 1, and the wrapper keeps its name" "$(run):$([ -d "$W2" ] && echo kept)" "1:kept"
mv "$T/ff.aside" "$G/tools/frame-fix.exe"
mkw2; APP="$T/apps/Foreign.app"; mkdir -p "$APP/Contents/SharedSupport"
rc=$(run)
check "WT17 the app builder failing: exit 1, the wrapper renamed, the launcher and wrappers.sh deployed, and it finds the wrapper" \
  "$rc:$([ -d "$NW2" ] && echo renamed):$([ -f "$STATE/launch-relaunched.sh" ] && [ -f "$STATE/wrappers.sh" ] && echo deployed):$(HOME="$H" bash "$STATE/wrappers.sh" find game 3215050 2>/dev/null)" "1:renamed:deployed:$NW2"
APP="$A1"; rm -rf "$T/apps/Foreign.app"
mkw2; mv "$T/repo/common/wrappers.sh" "$T/wr.aside"
check "WT17 wrappers.sh missing: exit 1 in the own-files words, before any call of the resolver" \
  "$(run):$(grep -c "^  !! setup's own files are missing (.*common/wrappers.sh)" "$T/out"):$(grep -c 'command not found' "$T/out")" "1:1:0"
mv "$T/wr.aside" "$T/repo/common/wrappers.sh"
mkw2; cp -R "$W2" "$H/Applications/twin.app"
plutil -replace L1Role -string game-wrapper "$W2/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 3215050 "$W2/Contents/Info.plist"
plutil -replace L1Role -string game-wrapper "$H/Applications/twin.app/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 3215050 "$H/Applications/twin.app/Contents/Info.plist"
check "WT4b two wrappers marked alike: exit 1, setup's line, nothing copied" \
  "$(run):$(grep -c "^  !! Setup stops here, before it changes anything: two wrappers carry the game's marker" "$T/out"):$(copies)" "1:1:0"
H="$H1"

# --- the record of which version this game was set up from (docs/plans/built-in-update.md, 3.1 and 3.3; UT5 and
# "UT5, also"). The clock is L1_UPDATE_NOW; the tree's version is the first version heading of its CHANGELOG.md.
# Each case has a home, a state folder and an app folder of its own.
TAB="$(printf '\t')"
NOW=1800000000; NOW2=1800000777; VER=v0.4.2; HEX=0123456789abcdef0123456789abcdef01234567
PLIST1='<?xml version="1.0" encoding="UTF-8"?>'
mk3() {   # <name>: sets H, STATE, APP, UPD and UPDT; the home holds a marked wrapper with the game in it
  H="$T/home-$1"; STATE="$T/state-$1"; APP="$T/apps-$1/Surviving Mars Relaunched.app"; mkdir -p "$T/apps-$1"
  local w="$H/Applications/wrapper-3215050.app"
  mkdir -p "$w/Contents/SharedSupport/wine/bin" "$w/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
  printf '#!/bin/sh\nexit 0\n' > "$w/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$w/Contents/SharedSupport/wine/bin/wine64"
  : > "$w/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"
  printf '%s\n' "$PLIST1" '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>L1Role</key><string>game-wrapper</string><key>L1SteamAppID</key><integer>3215050</integer></dict></plist>' > "$w/Contents/Info.plist"
  UPD="$(HOME="$H" bash "$T/repo/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"
  UPDT="~${UPD#"$H"}"   # as setup prints it
}
other() {   # [noprogram]: in $H, a Cities: Skylines II wrapper under its new name, marked, with the game's program in it
  local a="$H/Applications/wrapper-949230.app"; local g="$a/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"
  mkdir -p "$a/Contents/SharedSupport/wine/bin" "$g"
  printf '#!/bin/sh\nexit 0\n' > "$a/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$a/Contents/SharedSupport/wine/bin/wine64"
  [ "${1:-}" = noprogram ] || : > "$g/Cities2.exe"
  printf '%s\n' "$PLIST1" '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>L1Role</key><string>game-wrapper</string><key>L1SteamAppID</key><integer>949230</integer></dict></plist>' > "$a/Contents/Info.plist"
}
stampof() { cat "$UPD/installed/3215050" 2>/dev/null; }
stateof() { HOME="$H" bash "$UPD/updates.sh"; }   # the deployed tool, asked as a launcher or the window asks it
snapu() { if [ -d "$UPD" ]; then (cd "$UPD" && { find . | LC_ALL=C sort; find . -type f -exec shasum {} +; } | shasum | cut -c1-12); else echo none; fi; }
has() { if [ -e "$1" ]; then echo yes; else echo no; fi; }
o() { grep -c -- "$1" "$T/out"; }
mk3 u1; : > "$T/calls.tool"
check "UT5 a setup that finishes: exit 0, and the stamp holds checkout, the tree's version, no commit and the time" \
  "$(L1_UPDATE_NOW=$NOW run):$(stampof)" "0:checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "UT5 ...the deployed updates.sh is byte for byte the tree's, and nothing written beside a place is left" \
  "$(cmp -s "$T/repo/common/updates.sh" "$UPD/updates.sh" && echo same):$(find "$UPD" "$STATE" -name '*.new.*' -o -name '.put.*' | wc -l | tr -d ' ')" "same:0"
check "UT5 ...update-dir beside the launcher holds the folder's path, one line" "$(cat "$STATE/update-dir"):$(wc -l < "$STATE/update-dir" | tr -d ' ')" "$UPD:1"
check "UT5 ...the folders setup made are the user's own: no group or other may write" "$(stat -f %Lp "$UPD"):$(stat -f %Lp "$UPD/installed")" "755:755"
check "UT5, also: updates.sh was there when the 14unch3r builder was called" "$(cat "$T/calls.tool")" there
check "UT5 ...a checkout's state is manual, with checkout as its detail" "$(stateof)" "manual${TAB}$VER${TAB}-${TAB}checkout"
check "UT5 ...nothing is said of another game, none being set up here, and the line about mods still closes the block" \
  "$(o 'was set up by an older version'):$(tail -n 1 "$T/out" | cut -c1-36)" "0:  If you use mods from Paradox Mods:"
ln "$UPD/installed/3215050" "$T/keep.stamp"
check "UT5 with L1_FETCHED_REF=release and L1_FETCHED_COMMIT: the stamp holds release and that commit" \
  "$(L1_FETCHED_REF=release L1_FETCHED_COMMIT=$HEX L1_UPDATE_NOW=$NOW2 run):$(stampof)" "0:release${TAB}$VER${TAB}$HEX${TAB}$NOW2"
check "UT5 ...written beside its place and renamed: a second name of the old stamp still holds the old line" "$(cat "$T/keep.stamp")" "checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "UT5 ...with no offer fetched yet the state is unknown" "$(stateof)" "unknown${TAB}$VER${TAB}-${TAB}-"
check "UT5 with L1_FETCHED_REF=v0.2.0: that line in the stamp, and the state is manual with it as the detail" \
  "$(L1_FETCHED_REF=v0.2.0 L1_UPDATE_NOW=$NOW run):$(stampof | cut -f1,4):$(stateof)" "0:v0.2.0${TAB}$NOW:manual${TAB}$VER${TAB}-${TAB}v0.2.0"
# a setup that fails or stops writes no stamp, and leaves an older one as it was
old="$(stampof)"; keep="$APP"; APP="$T/apps-u1/Foreign.app"; mkdir -p "$APP/Contents/SharedSupport"
check "UT5 the app's builder failing: exit 1, the older stamp as it was" "$(L1_UPDATE_NOW=$NOW2 run):$(stampof)" "1:$old"
APP="$keep"
check "UT5 the game running (exit 3): the older stamp as it was" "$(L1_UPDATE_NOW=$NOW2 STUB_GAME=1 STUB_GAME_CMD="$H/Applications/wrapper-3215050.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe -x" run):$(stampof)" "3:$old"
before="$(snapu)"
check "UT5 --check and --mac-only on a home that has a record: every file of it as it was" \
  "$(L1_UPDATE_NOW=$NOW2 run --check):$(L1_UPDATE_NOW=$NOW2 run --mac-only):$(snapu)" "0:0:$before"
mk3 u2; APP="$T/apps-u2/Foreign.app"; mkdir -p "$APP/Contents/SharedSupport"
check "UT5 the app's builder failing on a new install: exit 1, no stamp" "$(run):$(has "$UPD/installed/3215050")" "1:no"
mk3 u3
check "UT5 the game running on a new install (exit 3): nothing of the record is made" \
  "$(STUB_GAME=1 STUB_GAME_CMD="$H/Applications/wrapper-3215050.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe -x" run):$(has "$UPD"):$(has "$STATE/update-dir")" "3:no:no"
check "UT5 --check on a new install: no record folder, no update-dir, nothing copied" "$(run --check):$(has "$UPD"):$(has "$STATE/update-dir"):$(copies)" "0:no:no:0"
check "UT5 --mac-only: the same" "$(run --mac-only):$(has "$UPD"):$(has "$STATE")" "0:no:no"
# the record's folders are the user's own, or setup stops before it copies anything
NOTOWN='is not a folder of your own that only you can write to; setup will not keep its record of versions there\.$'
mk3 u4; mkdir -p "$UPD"; chmod g+w "$UPD"
check "UT5 a record folder the group can write to: exit 1, said, nothing copied and nothing made in it" \
  "$(run):$(o "^  !! $UPDT $NOTOWN"):$(copies):$(ls -A "$UPD" | wc -l | tr -d ' ')" "1:1:0:0"
mk3 u5; mkdir -p "$UPD/installed"; chmod o+w "$UPD/installed"
check "UT5 ...installed/ in it writable by others: the same" "$(run):$(o "^  !! $UPDT/installed $NOTOWN"):$(copies):$(has "$UPD/updates.sh")" "1:1:0:no"
mk3 u6; mkdir -p "$T/rec-u6"; chmod 777 "$T/rec-u6"
check "UT5 ...L1_UPDATE_DIR naming a folder inside one that others can write to: the same, and that folder stays empty" \
  "$(L1_UPDATE_DIR="$T/rec-u6/_update" run):$(o "^  !! $T/rec-u6 $NOTOWN"):$(copies):$(ls -A "$T/rec-u6" | wc -l | tr -d ' ')" "1:1:0:0"
chmod 755 "$T/rec-u6"
check "UT5 ...made the user's own, the record goes there, and update-dir names it" \
  "$(L1_UPDATE_DIR="$T/rec-u6/_update" run):$(has "$T/rec-u6/_update/installed/3215050"):$(cat "$STATE/update-dir"):$(has "$UPD")" "0:yes:$T/rec-u6/_update:no"
# a stamp that cannot be written is said, and changes no exit code
mk3 u10; mkdir -p "$UPD/installed"; chmod 555 "$UPD/installed"
check "UT5 installed/ cannot be written to: the sentence, with the home folder as ~, no stamp, and setup's exit code is kept" \
  "$(run):$(o "^  !! This version could not be recorded ($UPDT/installed/3215050)\. 14unch3r will not offer updates for this game\.\$"):$(has "$UPD/installed/3215050"):$(o '^=== setup complete ===$')" "0:1:no:1"
chmod 755 "$UPD/installed"
# setup's own files: where the record is, its tool and the table of games
mk3 u7
for gone in paths.sh updates.sh games.tsv; do
  mv "$T/repo/common/$gone" "$T/$gone.aside"
  check "UT5 common/$gone missing from the tree: exit 1 in the own-files words, and nothing copied" \
    "$(run):$(o "^  !! setup's own files are missing (.*common/$gone). Open the installer again, or run setup from a whole checkout\.\$"):$(grep -cE 'command not found|No such file' "$T/out"):$(copies):$(has "$UPD")" "1:1:0:0:no"
  check "UT5 ...with --mac-only that run is outside the check: exit 0" "$(run --mac-only):$(o "setup's own files")" "0:0"
  mv "$T/$gone.aside" "$T/repo/common/$gone"
done
# the closing words name every other game that is set up on this Mac and has no stamp
OLDER='was set up by an older version\. Paste its installer line once, so that it gets updates too\.$'
mk3 u8; other
check "UT5 another game set up with no stamp: named in the closing words, by its title in the tree's table, last" \
  "$(run):$(o "^Cities: Skylines II $OLDER"):$(o "$OLDER"):$(tail -n 1 "$T/out" | cut -c1-19)" "0:1:1:Cities: Skylines II"
check "UT5, also: its wrapper variable naming a path that does not exist: still named" "$(CS2_WRAPPER="$T/no-such.app" run):$(o "^Cities: Skylines II $OLDER")" "0:1"
sed -i '' "s/${TAB}Cities: Skylines II${TAB}/${TAB}A Title From The Table${TAB}/" "$T/repo/common/games.tsv"
check "UT5 ...the title is the third field of that ID's row" "$(run):$(o "^A Title From The Table $OLDER")" "0:1"
cp "$REPO/common/games.tsv" "$T/repo/common/games.tsv"
printf 'release\t%s\t-\t100\n' "$VER" > "$UPD/installed/949230"
check "UT5 ...a game that has a stamp is not named" "$(run):$(o "$OLDER")" "0:0"
mk3 u9; other noprogram
check "UT5 ...a wrapper without the game's program is not a game set up: not named" "$(run):$(o "$OLDER")" "0:0"
H="$H1"; APP="$A1"; STATE="$T/state"

echo "$fails failure(s)"
[ "$fails" = 0 ]
