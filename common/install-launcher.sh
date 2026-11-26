#!/bin/bash
# install-launcher.sh -- the launcher's own installer (docs/plans/launcher-first-install.md, 3.4): it builds
# 14unch3r, the window that lists the games, on a Mac that may hold nothing of this project, and records which
# version it was built from. Run only by the root install.sh (the word launcher) and by the update's driver,
# from the tree it lies in. Every step is skipped or done again safely, so running it again is the update.
#
#   bash install.sh launcher [<ref>]        the way it is run; this script itself takes no argument
#
# In order: its refusals (root, its own files, this Mac, the record's folders), before anything is asked or
# made; Apple's Command Line Tools, judged, and asked for when absent (common/tools.sh); the record's folders
# and the update tool (common/updates.sh, copied into the folder `bash common/paths.sh` prints as
# L1_UPDATE_DIR); the wait for Apple's tools, only after an ask; the compiler check; the build
# (common/make-launcher-app.sh); the launcher's stamp, only after a build that worked; the close, which opens
# 14unch3r. It downloads nothing itself and does not keep the Mac awake.
#
# Read from the environment: L1_FETCHED_REF and L1_FETCHED_COMMIT, set by the root install.sh after a fetch (the
# stamp records them); L1_UPDATE=1, set by an update: 14unch3r is then not opened, and the closing line is the
# update's. L1_UPDATE_DIR names another folder for the record (tests).
#
#   exit 0 = done; 1 = failed, and said; 2 = an argument; 3 = it will not go on (this Mac, or tools too old);
#   4 = it cannot go on by itself (Apple's tools are not there yet, or its own files are gone).
# The path of this script, its call with no argument and these exit codes are a contract with the root
# install.sh of another version, which runs it from whatever it fetched.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
POLL=5                # seconds between two looks for Apple's tools
TOOLS_POLLS=720       # 60 minutes for Apple's Command Line Tools
TOOLS_PART_POLLS=24   # and two more for their swiftc: Apple's package may still be writing its files
FRONT="https://github.com/macgameport/1launcher"
say() { echo "$*"; }

[ $# -eq 0 ] || { echo "install-launcher.sh takes no argument: $1 (usage: install.sh launcher [<ref>])"; exit 2; }

# Control-C, a closed window, a kill: said, and nothing after the signal is done (the stamp among it)
on_signal() { echo; echo "Stopped. Paste the line again: it carries on from here."; exit "$1"; }
trap 'on_signal 130' INT
trap 'on_signal 143' TERM
trap 'on_signal 129' HUP

# --- 1. refusals, before anything is asked or made
[ "$(id -u)" = 0 ] && { echo "Do not run the installer as root (with sudo): it would leave files only root can change in your home folder."; exit 1; }
for f in paths.sh updates.sh tools.sh make-launcher-app.sh launcher-window.swift games.tsv; do
  [ -f "$HERE/$f" ] || { echo "The installer's own files are gone (macOS clears old temporary files)."; exit 4; }
done
. "$HERE/paths.sh"     # L1_UPDATE_DIR, the record's folder
. "$HERE/updates.sh"   # the l1u_* functions
. "$HERE/tools.sh"     # tools_ask and tools_wait

# this Mac (LFD12): only a macOS below 14 stops it, where no game of the project runs; each game's own check
# decides for that game
OSV="$(sw_vers -productVersion 2>/dev/null)"; OSMAJ="${OSV%%.*}"
case "$OSMAJ" in
  ''|*[!0-9]*) say "CAUTION: the macOS version could not be read, so this Mac cannot be compared with what has been tested." ;;
  *) if [ "$((10#$OSMAJ))" -lt 14 ]; then
       say "This Mac has macOS $OSV. 14unch3r needs macOS 14 or later, and so does every game it lists. Update macOS, then paste the line again."
       exit 3
     elif [ "$((10#$OSMAJ))" -lt 26 ]; then
       say "CAUTION: macOS $OSV is older than anything this project has been run on (macOS 26 and 27). 14unch3r may work; each game checks this Mac for itself when it is installed."
     fi ;;
esac
# sysctl, not uname -m: in a shell that itself runs under Rosetta, uname says x86_64 on Apple Silicon
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" != 1 ]; then
  say "CAUTION: this Mac has an Intel processor. Nothing of this project has been run on one. 14unch3r may work; each game checks this Mac for itself when it is installed."
fi

# the record's folders, looked at and not yet made: each one that is there must be the player's own
own_folder() {   # <folder>: 0 when it is a real folder of this user's that group and others cannot write to
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -f %u "$1")" = "$(id -u)" ] || return 1
  case "$(stat -f %Lp "$1")" in *[2367]?|*[2367]) return 1 ;; esac
  return 0
}
for d in "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
  if [ -e "$d" ] || [ -L "$d" ]; then
    own_folder "$d" || { say "$d is not a folder of your own that only you can write to. In Terminal: chmod go-w \"$d\", then try again."; exit 1; }
  fi
done

# --- 2. Apple's Command Line Tools: judged, and asked for when absent (LFD14). "Present" means "runs": the
#     compiler is found, its SDK is a folder that exists, and it answers. A folder that is there with a swiftc
#     that does not run (left stale by a macOS upgrade) stops here, and Apple is not asked: a request on a Mac
#     that has the folder brings no box.
swift_ok() {
  local sdk
  xcrun -f swiftc > /dev/null 2>&1 || return 1
  sdk="$(xcrun --show-sdk-path 2> /dev/null)" || return 1
  [ -n "$sdk" ] && [ -d "$sdk" ] || return 1
  xcrun swiftc --version > /dev/null 2>&1
}
STALE="Apple's Command Line Tools are installed, but their swiftc does not run. Update them in Software Update, then paste the line again."
ASKED=0
if xcode-select -p > /dev/null 2>&1; then   # first: without the tools, running one of them opens Apple's box itself
  swift_ok || { say "$STALE"; exit 1; }
else
  tools_ask; ASKED=1
fi

# --- 3. the record's folders, made, the parent first; then the update tool, written beside its place and renamed.
#     All of it before the build, so that the first window already finds the tool (L1UpdateDir).
for d in "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
  [ -d "$d" ] || { mkdir -p "$d" && chmod go-w "$d"; } || { say "$d could not be made."; exit 1; }
done
TOOL="$L1_UPDATE_DIR/updates.sh"
if ! { cp "$HERE/updates.sh" "$TOOL.new.$$" && chmod 755 "$TOOL.new.$$" && mv -f "$TOOL.new.$$" "$TOOL"; }; then
  rm -f "$TOOL.new.$$"; say "$TOOL could not be written."; exit 1
fi

# --- 4. the wait for Apple's tools, only after an ask
if [ "$ASKED" = 1 ]; then
  _tw=0; tools_wait swift_ok || _tw=$?
  if [ "$_tw" = 1 ]; then
    say "Apple's Command Line Tools are not installed yet."
    say "Paste the line again: it carries on from here."
    exit 4
  fi
  [ "$_tw" = 0 ] || { say "$STALE"; exit 1; }
fi

# --- 5. the compiler check, for tools left behind by an upgrade: the window's source needs Swift 5.9. The version
#     is taken from the words "Swift version <a>.<b>", wherever they stand in the output, and the two numbers
#     are compared as numbers (5.10 is later than 5.9). A version that cannot be read does not stop it.
SWIFTV="$(xcrun swiftc --version 2>&1)"
if [[ "$SWIFTV" =~ Swift\ version\ ([0-9]{1,4})\.([0-9]{1,4}) ]]; then
  _a="$((10#${BASH_REMATCH[1]}))"; _b="$((10#${BASH_REMATCH[2]}))"
  if [ "$_a" -lt 5 ] || { [ "$_a" = 5 ] && [ "$_b" -lt 9 ]; }; then
    say "Apple's Command Line Tools on this Mac are older than 14unch3r needs (Swift $_a.$_b, and it needs 5.9). Update them in Software Update, then paste the line again."
    exit 3
  fi
fi

# --- 6. the build. The builder's exit 3 (it skipped: swiftc or the source is missing, or the compile failed) is
#     a failure here: for a game's setup the window is an extra, here it is the whole point.
say "Building 14unch3r. This can take a minute; nothing is printed meanwhile."
if ! bash "$HERE/make-launcher-app.sh"; then
  say "14unch3r could not be built on this Mac. Each game can still be installed by its own line: the guide lists them, at $FRONT"
  exit 1
fi

# --- 7. the launcher's own stamp, only after a build that worked
l1u_stamp_launcher "$HERE/.." || say "  !! 14unch3r's version could not be recorded ($L1_UPDATE_DIR/launcher). It may go on offering an update it already has."

# --- 8. the close
if [ "${L1_UPDATE:-}" = 1 ]; then
  say "Done. 14unch3r is rebuilt."
else
  say "Done. 14unch3r is in Applications: open it and choose a game. You can close this window."
  open "$HOME/Applications/14unch3r.app"
fi
exit 0
