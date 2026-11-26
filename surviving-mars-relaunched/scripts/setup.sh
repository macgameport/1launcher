#!/bin/bash
# setup.sh -- the last step of an install of Surviving Mars: Relaunched, and the way to update one
# (docs/plans/surviving-mars-install.md, 2.5). It puts the launcher and the click helper where the game's
# app keeps them, builds the app, and builds 14unch3r, the window that lists every game.
#
#   bash scripts/setup.sh              # copy the launcher and the helper, build the app and 14unch3r
#   bash scripts/setup.sh --check      # say what it would do, change nothing
#   bash scripts/setup.sh --yes        # do not stop to ask when this Mac is outside what has been tested
#   bash scripts/setup.sh --mac-only   # check this Mac only (Apple Silicon, macOS, Rosetta), then stop
#
#   exit 0 = done (or, with --mac-only, this Mac is ready); 1 = something failed or is missing, said which
#   (with --mac-only: only Rosetta 2 is missing); 2 = a wrong option; 3 = it will not go on: an Intel Mac, a
#   macOS below 14, the game running, or a launch or an install using the wrapper.
#
# The app runs a copy. The launcher and tools/frame-fix.exe are copied into the game's state folder,
# ~/Library/Application Support/1launcher/surviving-mars-relaunched/ (where runs/ and backup/ already are,
# and which setup never touches), and the app is built to run that copy. So an app made by the installer
# does not need the folder it was installed from, and every Mac runs the game the same way. After
# `git pull`, a maintainer runs setup again. A copy is never written over a file in place: it is written
# beside it and renamed over it, because a launcher goes on reading its own file after the game exits.
#
# Setup also keeps the record of which version this was (docs/plans/built-in-update.md, 3.1 and 3.3):
# common/updates.sh is copied into the folder `bash common/paths.sh` prints as L1_UPDATE_DIR, a file update-dir
# beside the launcher names that folder, and before the closing words one line is written to its
# installed/3215050. A run with --check or --mac-only touches nothing of that folder. After a build of 14unch3r
# that worked, the window's own version is recorded there too, in the file `launcher`
# (docs/plans/launcher-first-install.md, 3.5); not with SM_APP set, where the window is built in another folder.
#
# The wrapper is found by common/wrappers.sh, by the marker in its Info.plist, and setup gives an old-named one
# its new name with common/move-wrappers.sh (docs/plans/wrapper-names.md, 3.4). L1_KEEP_WRAPPER_NAMES=1 declines.
#
# Read from the environment: SM_VIA_INSTALLER=1, set by scripts/install.sh, which holds the wrapper's lock
# while it runs setup and has already asked the question about this Mac, and L1_WRAPPER_GIVEN, which says
# whether the player named the wrapper; SM_STATE, SM_APP and SM_WRAPPER, which name another state folder, app
# and wrapper (tests). With SM_APP set, 14unch3r is built in that app's folder.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME_ROOT="$(cd "$HERE/.." && pwd)"
REPO="$(cd "$GAME_ROOT/.." && pwd)"
TESTED=27   # the macOS this has been run on (README.md, "What it assumes")

MAC_ONLY=0; YES=0; CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --mac-only) MAC_ONLY=1; shift ;;
    --yes) YES=1; shift ;;
    --check) CHECK=1; shift ;;
    -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)"; exit 2 ;;
  esac
done
[ "$(id -u)" = 0 ] && { echo "  !! Do not run setup as root (with sudo): it would leave files only root can change in your home folder."; exit 1; }

say() { printf "  %-28s %s\n" "$1" "$2"; }
# a path as printed: the home folder as ~, so that output pasted into an issue does not carry the user's name
tilde() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }

# --- this Mac
[ "$(uname -s)" = Darwin ] || { echo "  !! This only runs on macOS."; exit 3; }
cautions=0
# sysctl, not uname -m: in a shell that itself runs under Rosetta, uname says x86_64 on Apple Silicon
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" != 1 ]; then
  echo "  !! This Mac has an Intel processor. Wine for this game, and Apple's D3DMetal, need an Apple Silicon Mac (M1 or later)."
  exit 3
fi
say "Apple Silicon" "OK"
OSV="$(sw_vers -productVersion 2>/dev/null)"; OSMAJ="${OSV%%.*}"
case "$OSMAJ" in
  ''|*[!0-9]*) say "macOS version" "CAUTION"; echo "      -> it could not be read, so this Mac cannot be compared with what has been tested."; cautions=1 ;;
  *) if [ "$OSMAJ" -lt 14 ]; then
       echo "  !! macOS $OSV: Apple's D3DMetal 3.0 does not load below macOS 14. Update macOS, then try again."
       exit 3
     elif [ "$OSMAJ" = "$TESTED" ]; then say "macOS $OSV" "OK (tested)"
     elif [ "$OSMAJ" -gt "$TESTED" ]; then
       say "macOS $OSV" "CAUTION"; cautions=1
       echo "      -> newer than anything this has been run on. Apple has said macOS $TESTED is the last release with general Rosetta support."
     else
       say "macOS $OSV" "CAUTION"; cautions=1
       echo "      -> older than anything this has been run on (macOS $TESTED). It may work: D3DMetal's own minimum is macOS 14."
     fi ;;
esac
ROSETTA=1; arch -x86_64 /usr/bin/true 2>/dev/null || ROSETTA=0
if [ "$ROSETTA" = 1 ]; then say "Rosetta 2" "OK"; else say "Rosetta 2" "MISSING"; fi
if [ "$cautions" -gt 0 ]; then
  echo "  This Mac is outside what this project has been tested on. Setup can go on; the game may still not start."
  if [ "$YES" = 0 ] && [ "$CHECK" = 0 ] && [ "${SM_VIA_INSTALLER:-0}" != 1 ] && [ -t 0 ]; then
    printf '  Press Return to continue, or Control-C to stop. (--yes skips this question.) '
    read -r _ || true
  fi
fi
if [ "$MAC_ONLY" = 1 ]; then   # scripts/install.sh, step 1: this Mac alone
  [ "$ROSETTA" = 1 ] || exit 1
  exit 0
fi
[ "$ROSETTA" = 1 ] || { echo "      -> the game cannot run without it. Install it:  softwareupdate --install-rosetta --agree-to-license"; exit 1; }

# --- the wrapper, found by common/wrappers.sh. Its two files are looked for first, in the own-files words: without
#     them the first call would fail as a shell error. Under the installer, which exports SM_WRAPPER itself, the
#     variable says nothing about the player: L1_WRAPPER_GIVEN does, and when it is 0 the variable is dropped.
for f in "$REPO/common/wrappers.sh" "$REPO/common/move-wrappers.sh"; do
  [ -f "$f" ] || { echo "  !! setup's own files are missing ($(tilde "$f")). Open the installer again, or run setup from a whole checkout."; exit 1; }
done
# the record's files (docs/plans/built-in-update.md, 3.3), in a loop of their own: the one above is as older tests know it
for f in "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$REPO/common/games.tsv"; do
  [ -f "$f" ] || { echo "  !! setup's own files are missing ($(tilde "$f")). Open the installer again, or run setup from a whole checkout."; exit 1; }
done
. "$REPO/common/wrappers.sh"
[ "${SM_VIA_INSTALLER:-0}" = 1 ] && [ "${L1_WRAPPER_GIVEN:-}" = 0 ] && unset SM_WRAPPER
find_wrapper() {   # sets WRAPPER and GAME; exits 1 when two wrappers carry the game's marker, before anything is changed
  local rc=0
  WRAPPER="$(l1w_find game 3215050)" || rc=$?
  if [ "$rc" = 2 ]; then echo "  !! Setup stops here, before it changes anything: two wrappers carry the game's marker (the lines above)."; exit 1; fi
  [ "$rc" = 0 ] || WRAPPER=""
  GAME="$WRAPPER/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
}
wmover() {   # [--dry-run]: common/move-wrappers.sh for the game's wrapper; under the installer its hold is let through
  local a=()
  [ "${SM_VIA_INSTALLER:-0}" = 1 ] && a+=(--holders-skip --held-by "$PPID")
  bash "$REPO/common/move-wrappers.sh" ${a[@]+"${a[@]}"} "$@" game 3215050
}
find_wrapper

# --- what must not be happening: the game running, or a launch or an install using the wrapper
# --- the launcher's own function (launch-relaunched.sh); scripts/test-setup.sh holds it identical
game_running() {
  for _p in $(pgrep -f 'Mars\.exe' 2>/dev/null); do
    case "$(ps -o command= -p "$_p" 2>/dev/null)" in
      "$GAME/Mars.exe"*|'C:\'*'\Project Spark\Mars.exe'*) return 0 ;;
    esac
  done
  return 1
}
if game_running; then echo "  !! The game is running. Quit it, then run setup again."; exit 3; fi
h="$(readlink "$WRAPPER/Contents/SharedSupport/prefix/.launcher.lock" 2>/dev/null)"
if [ -n "$h" ] && kill -0 "$h" 2>/dev/null; then
  # the installer holds the lock while it runs setup: its lock, and no other, is passed
  if [ "${SM_VIA_INSTALLER:-0}" != 1 ] || [ "$h" != "$PPID" ]; then
    echo "  !! A launch or an install is using the game's wrapper (process $h). Wait for it to finish, then run setup again."
    exit 3
  fi
fi
# what a rename would do, said by --check too; and a rename that cannot be done now stops setup before it changes
# anything. Looked for only when there is something to rename.
WM_RC=0; WM_OUT="$(wmover --dry-run 2>&1)" || WM_RC=$?
WM_STATE="$(printf '%s\n' "$WM_OUT" | sed -n '1s/^state: //p')"
case "$WM_STATE" in
  old|part-way)
    if [ "$WM_RC" = 3 ]; then
      echo "  !! Setup stops here, before it changes anything:"; printf '%s\n' "$WM_OUT" | grep '^  stop: '
      echo "     When it has finished, run setup again."
      exit 3
    fi
    if printf '%s\n' "$WM_OUT" | grep -q '^  would '; then WLINE="$(printf '%s\n' "$WM_OUT" | sed -n 's/^  \(would .*\)$/wrapper: \1/p')"
    else WLINE="wrapper: the game's wrapper cannot be renamed now
$(printf '%s\n' "$WM_OUT" | grep -E '^  (stop|skip): ')"; fi ;;
  none) WLINE="wrapper: nothing to rename" ;;
  *) WLINE="wrapper: the wrapper mover gave no answer:
$WM_OUT" ;;
esac

# --- the state folder: the user's own, and nobody else may write to it
STATE="${SM_STATE:-$HOME/Library/Application Support/1launcher/surviving-mars-relaunched}"
APP="${SM_APP:-$HOME/Applications/Surviving Mars Relaunched.app}"
# the record's folder (docs/plans/built-in-update.md, 3.1): common/paths.sh says where, and only that is taken from
# it: the state folder stays as the line above gives it
L1_UPDATE_DIR="$( . "$REPO/common/paths.sh" 2>/dev/null; printf '%s' "$L1_UPDATE_DIR" )"
own_folder() {   # <folder>: 0 when it is a real folder of this user's that group and others cannot write to
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -f %u "$1")" = "$(id -u)" ] || return 1
  case "$(stat -f %Lp "$1")" in *[2367]?|*[2367]) return 1 ;; esac
  return 0
}
for d in "$STATE" "$STATE/tools"; do
  if [ -e "$d" ] || [ -L "$d" ]; then
    own_folder "$d" || { echo "  !! $(tilde "$d") is not a folder of your own that only you can write to; setup will not put the launcher there."; exit 1; }
  fi
done
for f in "$GAME_ROOT/launch-relaunched.sh" "$GAME_ROOT/tools/frame-fix.exe" "$GAME_ROOT/make-app.sh" "$REPO/common/make-launcher-app.sh"; do
  [ -f "$f" ] || { echo "  !! setup's own files are missing ($(tilde "$f")). Open the installer again, or run setup from a whole checkout."; exit 1; }
done
if [ "$CHECK" = 1 ]; then
  printf '%s\n' "$WLINE"
  echo "  would copy the launcher and the click helper into $(tilde "$STATE")"
  echo "  would build $(tilde "$APP") and 14unch3r beside it"
  echo "(--check: stopping before making changes)"
  exit 0
fi
# the record: its tool is read (the l1u_* functions), and its folder, the one that holds it, and installed/ in it
# are each the user's own too, tested before anything is copied (docs/plans/built-in-update.md, 3.3 items 1 and 2)
. "$REPO/common/updates.sh"
stamp_step() {
  l1u_stamp 3215050 "$REPO" && return 0
  echo "  !! This version could not be recorded ($(tilde "$L1_UPDATE_DIR/installed/3215050")). 14unch3r will not offer updates for this game."
  return 0
}
# 14unch3r's own stamp (docs/plans/launcher-first-install.md, 3.5): written on the line after a build of the window
# that worked into ~/Applications, and by nothing else: that window is then this tree's. Never counted as a problem.
launcher_stamp() {
  [ -z "${SM_APP:-}" ] || return 0
  l1u_stamp_launcher "$REPO" && return 0
  echo "  !! 14unch3r's version could not be recorded ($(tilde "$L1_UPDATE_DIR/launcher")). It may go on offering an update it already has."
  return 0
}
# after the "not built" lines: an older stamp of 14unch3r is left as it is, and when it holds an older version than
# this tree's, that is said: the window there is the old one, and the state goes on counting it
launcher_stays() {
  local old tree
  [ -z "${SM_APP:-}" ] || return 0
  old="$(l1u_stamp_of_launcher)" || return 0
  old="${old#*$'\t'}"; tree="$(l1u_version_of "$REPO/CHANGELOG.md")" || tree=-
  [ "$old" != - ] && l1u_newer "$tree" "$old" || return 0
  echo "      14unch3r stays at $old. It will go on offering this update until it can be built: the line above says why."
  return 0
}
for d in "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
  if [ -e "$d" ] || [ -L "$d" ]; then
    own_folder "$d" || { echo "  !! $(tilde "$d") is not a folder of your own that only you can write to; setup will not keep its record of versions there."; exit 1; }
  fi
done

# --- the copies: each written beside the old one and renamed over it, never written in place
for d in "$STATE" "$STATE/tools" "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
  [ -d "$d" ] || { mkdir -p "$d" && chmod go-w "$d"; } || { echo "  !! $(tilde "$d") could not be made."; exit 1; }
done
put() {   # <from> <to>
  local tmp="$2.new.$$"
  if cp "$1" "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$2"; then return 0; fi
  rm -f "$tmp"; echo "  !! $(tilde "$2") could not be written."; exit 1
}
put "$GAME_ROOT/launch-relaunched.sh" "$STATE/launch-relaunched.sh"
put "$GAME_ROOT/tools/frame-fix.exe" "$STATE/tools/frame-fix.exe"
put "$REPO/common/wrappers.sh" "$STATE/wrappers.sh"
# the record's tool, and beside the launcher the line that names its folder: before 14unch3r is built, so that a
# first setup already gives a window that finds the tool (docs/plans/built-in-update.md, 3.3 items 3 and 4)
put_line() {   # <one line> <to>
  local tmp="$2.new.$$"
  if printf '%s\n' "$1" > "$tmp" && chmod 644 "$tmp" && mv -f "$tmp" "$2"; then return 0; fi
  rm -f "$tmp"; echo "  !! $(tilde "$2") could not be written."; exit 1
}
put "$REPO/common/updates.sh" "$L1_UPDATE_DIR/updates.sh"
put_line "$L1_UPDATE_DIR" "$STATE/update-dir"
say "the launcher and its helper" "in $(tilde "$STATE")"

# --- the wrapper's name, after the copies: the launcher just copied finds a renamed wrapper by its marker even if
#     the app is not built below. A stop that appears only now (something started since) is a skip.
RENAMED=""; WM_SKIPPED=0
WM_RC=0; WM_OUT="$(wmover 2>&1)" || WM_RC=$?
case "$WM_RC" in
  0) RENAMED="$(printf '%s\n' "$WM_OUT" | sed -n 's/^  moved: //p')"
     [ -n "$RENAMED" ] && say "the game's wrapper" "renamed: $RENAMED" ;;
  1|3) WM_SKIPPED=1; say "the game's wrapper" "keeps its name this run:"; printf '%s\n' "$WM_OUT" | sed '1d' | sed 's/^  stop: /  skip: /; s/^/  /' ;;
  *) printf '%s\n' "$WM_OUT" | sed '1d' | sed 's/^/  /'
     echo "  !! The rename stopped part-way. The game still starts; the next run of setup finishes it."
     exit 1 ;;
esac
find_wrapper   # resolved again: it may have a new name now

# --- the game's app, built to run that copy
echo
OUT="$(mktemp /tmp/sm-setup.XXXXXX)" || { echo "  !! no temporary file could be made."; exit 1; }
GEXE="${SM_GAME_EXE:-}"; [ -n "$WRAPPER" ] && GEXE="$GAME/Mars.exe"   # the game in the wrapper resolved again
if ! SM_SCRIPT="$STATE/launch-relaunched.sh" SM_GAME_EXE="$GEXE" bash "$GAME_ROOT/make-app.sh" > "$OUT" 2>&1; then
  sed 's/^/  /' "$OUT"; rm -f "$OUT"
  echo "  !! The game's app was not built. The lines above say why."
  exit 1
fi
grep -v '^14unch3r: ' "$OUT" | sed "s#$HOME#~#g; s/^/  /"

# --- 14unch3r, beside the game's app. Not building it is not a problem: the game's own app does not need it
if [ -n "${SM_APP:-}" ]; then bash "$REPO/common/make-launcher-app.sh" --dest "$(dirname "$APP")" > "$OUT" 2>&1; rc=$?
else bash "$REPO/common/make-launcher-app.sh" > "$OUT" 2>&1; rc=$?; fi
case "$rc" in
  0) say "14unch3r" "built: one window that lists every game"; launcher_stamp ;;
  *) say "14unch3r" "not built (the game's own app does not need it):"; sed "s#$HOME#~#g; s/^/      /" "$OUT"; launcher_stays ;;
esac
rm -f "$OUT"

# --- the record of this version (docs/plans/built-in-update.md, 3.3 item 5): written when the work is done
stamp_step
# every other game that is set up on this Mac (a wrapper with the game's program in it, looked for with the game's
# wrapper variable unset: one left in the environment must not decide what is set up) and has no stamp (item 6)
unrecorded_games() {
  local id w title
  for id in $(l1w_games); do
    [ "$id" = 3215050 ] && continue
    l1w_row game "$id" || continue
    w="$( [ -z "$L1W_VAR" ] || unset "$L1W_VAR"; l1w_find game "$id" 2>/dev/null )" || continue
    l1w_program "$w" "$L1W_PROGRAM" || continue
    l1u_stamp_of "$id" > /dev/null && continue
    title="$(awk -F'\t' -v id="$id" '$1 == id { print $3; exit }' "$REPO/common/games.tsv" 2>/dev/null)"
    [ -n "$title" ] || continue
    echo "$title was set up by an older version. Paste its installer line once, so that it gets updates too."
  done
  return 0
}

if [ "${SM_VIA_INSTALLER:-0}" = 1 ]; then UPDATE="open the installer again."
else UPDATE="after  git pull , run  bash surviving-mars-relaunched/scripts/setup.sh  again."; fi
in_spotlight() {   # <app>: Spotlight and Launchpad list an app in one of these two folders only
  case "$(dirname "$1")" in "$HOME/Applications"|/Applications) return 0 ;; esac
  return 1
}
if in_spotlight "$APP"; then ALSO=", also in Spotlight and Launchpad"; else ALSO=""; fi
if [ "${SM_VIA_INSTALLER:-0}" = 1 ]; then WDECLINE="L1_KEEP_WRAPPER_NAMES=1 bash scripts/install.sh"
else WDECLINE="L1_KEEP_WRAPPER_NAMES=1 bash surviving-mars-relaunched/scripts/setup.sh"; fi
cat << DONE

=== setup complete ===
The game:   $(tilde "$APP")$ALSO
To update:  $UPDATE
  If you use mods from Paradox Mods: at the first start, open the game's Mod Manager before you load a save.
DONE
if [ -n "$RENAMED" ]; then
  echo "Renamed:    $RENAMED"
  echo "  The game's app and 14unch3r find the wrapper by a mark inside it, whatever its name. Anything of yours that"
  echo "  names the old path (a Dock item made from the wrapper, an alias, a saved command) must be pointed at the new one."
  echo "  To keep the old name on a Mac not renamed yet: $WDECLINE"
fi
[ "$WM_SKIPPED" = 1 ] && echo "Not renamed: the game's wrapper kept its name, for the reason given above. The next run tries again."
unrecorded_games
exit 0
