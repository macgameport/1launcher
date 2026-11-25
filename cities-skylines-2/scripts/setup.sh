#!/bin/bash
# setup.sh — install the launcher, apply the patches, and build the double-clickable app.
#
# Run this AFTER you have the Wine 11 + DXMT wrapper, Steam inside it and the game (INSTALL.md), or run
# scripts/install.sh, which does all of it and then runs this.
#
#   bash scripts/setup.sh              # check, install, patch, build shortcut
#   bash scripts/setup.sh --check      # preflight only, change nothing
#   bash scripts/setup.sh --hide-mod-badges   # opt in to the mod badge patch (INSTALL.md)
#   bash scripts/setup.sh --show-mod-badges   # opt out again
#   bash scripts/setup.sh --yes        # do not stop to ask when this Mac is outside what has been tested
#   bash scripts/setup.sh --desktop    # also put a 14unch3r shortcut on the Desktop, without asking
#   bash scripts/setup.sh --mac-only   # check this Mac only (Apple Silicon, Rosetta, macOS), then stop
#
# Read from the environment by scripts/install.sh's runs: CS2_VIA_INSTALLER=1 (the caution question was
# asked already; two lines speak of the installer) and L1_FETCHED_REF=<ref> (the checkout is a temporary copy),
# with L1_FETCHED_COMMIT beside it; and L1_UPDATE=1, set by an update: the Desktop question is not asked.
#
# What it does:
#   1. verifies the wrapper, Steam and the game are where they should be
#   2. moves an install made before the folders moved out of the home folder (scripts/move-install.sh), gives
#      the Wine wrappers their new names (common/move-wrappers.sh; L1_KEEP_WRAPPER_NAMES=1 declines), then
#      copies the launcher + repatch.sh + patches/ into the runtime folder, which `bash common/paths.sh`
#      prints (macOS TCC blocks .app bundles from executing scripts inside ~/Documents, so they cannot live
#      in the repo). Exit 3: a launcher or an install is running, and nothing was moved or copied
#   3. applies the binary patches (idempotent; each refuses to write if the pattern moved). When the only
#      shortfall is a fix not out yet for this build of the game, setup finishes, says so, and exits 5
#   4. builds "Cities Skylines II.app" in ~/Applications with the game's own icon, then 14unch3r.app,
#      the window that lists every game set up on this Mac (common/make-launcher-app.sh)
#   5. records which version this was (docs/plans/built-in-update.md, 3.1 and 3.3): common/updates.sh is copied
#      into the folder `bash common/paths.sh` prints as L1_UPDATE_DIR, a file update-dir beside the launcher names
#      that folder, and at the end, for exit 0 and exit 5, one line is written to its installed/949230. A run
#      that only checks, or that is given a folder to install into, touches nothing of that folder
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RETIRED="The Wine 10 + D3DMetal stack was retired on 2026-11-09. Its last version is commit fefc1e0."
CHECK_ONLY=0
ASSUME_YES=0
DESKTOP=0
MAC_ONLY=0
BADGES=""
DEST=""   # --dest; otherwise common/paths.sh says where, below

# a path as printed: the home folder as ~, so that output pasted into an issue does not carry the user's name
tilde() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
need_value() {   # <option> [<value> ...]: an option that takes a value must be given a non-empty one
  if [ $# -lt 2 ] || [ -z "$2" ]; then echo "$1 needs a value"; exit 2; fi
}
while [ $# -gt 0 ]; do
  case "$1" in
    --check)   CHECK_ONLY=1; shift ;;
    --yes)     ASSUME_YES=1; shift ;;
    --desktop) DESKTOP=1; shift ;;
    --mac-only) MAC_ONLY=1; shift ;;
    --stack)   need_value "$@"            # there is one stack now; its names are still accepted
               case "$2" in
                 dxmt11|wine11) ;;
                 d3dmetal|wine10) echo "$RETIRED"; exit 2 ;;
                 *) echo "unknown --stack '$2' (there is one stack now: leave the option out)"; exit 2 ;;
               esac; shift 2 ;;
    --dest)    need_value "$@"; DEST="$2"; shift 2 ;;
    --hide-mod-badges|--show-mod-badges)
      _b="${1#--}"; _b="${_b%-mod-badges}"
      [ -z "$BADGES" ] || [ "$BADGES" = "$_b" ] || { echo "--hide-mod-badges and --show-mod-badges cannot both be given"; exit 2; }
      BADGES="$_b"; shift ;;
    -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)"; exit 2 ;;
  esac
done
# the record of which version this game was set up from (docs/plans/built-in-update.md, 3.1 and 3.3): a run with
# --check, --mac-only or --dest touches nothing of it
RECORD=1
if [ "$CHECK_ONLY" = 1 ] || [ "$MAC_ONLY" = 1 ] || [ -n "$DEST" ]; then RECORD=0; fi

# --- setup's own files (docs/plans/local-files-layout.md, 3.1): the rule for where the files go, and the script
#     that moves an older install. A --mac-only run needs neither and is outside the check: scripts/install.sh
#     reads that run's exit 1 as "Rosetta is missing".
PATHS="$REPO/../common/paths.sh"; MOVER="$REPO/scripts/move-install.sh"
RESOLVER="$REPO/../common/wrappers.sh"; WMOVER="$REPO/../common/move-wrappers.sh"   # docs/plans/wrapper-names.md
UPDATES="$REPO/../common/updates.sh"; GAMES="$REPO/../common/games.tsv"               # docs/plans/built-in-update.md, 3.3
if [ "$MAC_ONLY" = 0 ]; then
  for f in "$PATHS" "$MOVER" "$RESOLVER" "$WMOVER"; do
    [ -f "$f" ] || { echo "  !! setup's own files are missing ($(tilde "$f")). Open the installer again, or run setup from a whole checkout."; exit 1; }
  done
  for f in "$UPDATES" "$GAMES"; do   # a loop of its own: the one above is as older tests know it
    [ -f "$f" ] || { echo "  !! setup's own files are missing ($(tilde "$f")). Open the installer again, or run setup from a whole checkout."; exit 1; }
  done
fi

LAUNCHER_SRC="$REPO/launchers/launch-cs2-dxmt11.sh"

ok=0; bad=0; cautions=0; problems=0
say()  { printf "  %-52s %s\n" "$1" "$2"; }
good() { say "$1" "OK";   ok=$((ok+1)); }
fail() { say "$1" "MISSING"; echo "      -> $2"; bad=$((bad+1)); }
# a CAUTION is not a failure: this Mac is outside what has been tested, and the player may go on
caution() { say "$1" "CAUTION"; echo "      -> $2"; cautions=$((cautions+1)); }
caution_note() {
  echo
  echo "$cautions caution(s): this Mac is outside what this project has been tested on (README.md, \"Compatibility\")."
  echo "Setup can go on from here. It changes only what INSTALL.md names, and INSTALL.md's Uninstall section undoes it."
  echo "The game may still not start on this Mac. Either way, a note in the project's Discussions helps the next person."
}
caution_ask() {   # asked once per install: scripts/install.sh asks it through --mac-only and sets CS2_VIA_INSTALLER
  if [ "$cautions" -gt 0 ] && [ "$ASSUME_YES" = 0 ] && [ "$CHECK_ONLY" = 0 ] && [ "${CS2_VIA_INSTALLER:-0}" != 1 ] && [ -t 0 ]; then
    printf 'Press Return to continue, or Control-C to stop. (--yes skips this question.) '
    read -r _ || true
  fi
}
GUIDE="$(tilde "$REPO/INSTALL.md")"
[ -n "${L1_FETCHED_REF:-}" ] && GUIDE="https://github.com/macgameport/1launcher/blob/main/cities-skylines-2/INSTALL.md"


# --- the wrapper, found once: the move's lock is in it (below), and the preflight reads the same answer. The
#     rule is common/wrappers.sh's (docs/plans/wrapper-names.md, 3.2): $CS2_WRAPPER when a person set it, else the
#     wrapper that carries the game's marker, else an old name, else the app that holds the game; and setup wants
#     a prefix in it. A --mac-only run needs no wrapper.
#     Under the installer, which exports CS2_WRAPPER itself, the variable says nothing about the player:
#     L1_WRAPPER_GIVEN does, and when it is 0 the variable is dropped, so that it means one thing from here on.
[ "${CS2_VIA_INSTALLER:-0}" = 1 ] && [ "${L1_WRAPPER_GIVEN:-}" = 0 ] && unset CS2_WRAPPER
WRAPPER=""
find_wrapper() {   # sets WRAPPER; exits 1 when two wrappers carry the game's marker, before anything is changed
  local w rc=0
  w="$(l1w_find game 949230)" || rc=$?
  if [ "$rc" = 2 ]; then
    echo "  !! Setup stops here, before it changes anything: two wrappers carry the game's marker (the lines above)."
    exit 1
  fi
  WRAPPER=""; [ "$rc" = 0 ] && [ -d "$w/Contents/SharedSupport/prefix" ] && WRAPPER="$w"
  return 0
}
if [ "$MAC_ONLY" = 0 ]; then . "$RESOLVER"; find_wrapper; fi

# --- where the files go (docs/plans/local-files-layout.md, 3.3). The rule is common/paths.sh's.
OLD_INSTALL="$HOME/cs2-patch"
DECLINE_VAR='CS2_PATCH_DIR=~/cs2-patch'
NAMED=0
if [ "$MAC_ONLY" = 0 ]; then
  . "$PATHS"
  RUNTIME="$L1_DATA_ROOT/cities-skylines-2"
  # a folder is "named" when --dest is given, CS2_PATCH_DIR names another folder than the default runtime
  # folder, or a root is set away from its default. A named folder is installed into as it is, and nothing
  # is moved.
  [ -n "$DEST" ] && NAMED=1
  [ -n "${CS2_PATCH_DIR:-}" ] && [ "$CS2_PATCH_DIR" != "$RUNTIME" ] && NAMED=1
  [ "$L1_ROOTS_SET" = 1 ] && NAMED=1
  [ -n "$DEST" ] || DEST="$CS2_DATA"
  [ "$RECORD" = 1 ] && . "$UPDATES"   # the l1u_* functions; L1_UPDATE_DIR is paths.sh's
fi
# three voices, as the other route-dependent lines below
WDECLINE_VAR='L1_KEEP_WRAPPER_NAMES=1'
if [ -n "${L1_FETCHED_REF:-}" ]; then
  AGAIN="open the installer again"
  DECLINE="put $DECLINE_VAR and a space in front of the line you pasted (the whole line: $GUIDE)"
  WDECLINE="put $WDECLINE_VAR and a space in front of the line you pasted"
elif [ "${CS2_VIA_INSTALLER:-0}" = 1 ]; then
  AGAIN="open the installer again"; DECLINE="$DECLINE_VAR bash scripts/install.sh"; WDECLINE="$WDECLINE_VAR bash scripts/install.sh"
else
  AGAIN="run setup again"; DECLINE="$DECLINE_VAR bash scripts/setup.sh"; WDECLINE="$WDECLINE_VAR bash scripts/setup.sh"
fi
# the wrapper mover (common/move-wrappers.sh): under the installer its own hold on the lock is let through, and a
# holder of the wrapper's files is a skip, so that an install is never failed by a rename
wmover() {   # [--dry-run] game|steam
  local a=()
  [ "${CS2_VIA_INSTALLER:-0}" = 1 ] && a+=(--holders-skip --held-by "$PPID")
  if [ "${*: -1}" = game ]; then bash "$WMOVER" ${a[@]+"${a[@]}"} "${@:1:$#-1}" game 949230
  else bash "$WMOVER" ${a[@]+"${a[@]}"} "$@"; fi
}
WM_GAME_OUT=""; WM_GAME_RC=0
wrapper_line() {   # the header's wrapper: lines, from the dry runs; WM_GAME_* keep the game's, for the stop below
  local role out rc st any=0
  for role in game steam; do
    rc=0; out="$(wmover --dry-run "$role" 2>&1)" || rc=$?
    st="$(mv_state "$out")"
    [ "$role" = game ] && { WM_GAME_OUT="$out"; WM_GAME_RC=$rc; WM_GAME_STATE="$st"; }
    case "$st" in
      none) ;;
      old|part-way)
        any=1
        if printf '%s\n' "$out" | grep -q '^  would '; then printf '%s\n' "$out" | sed -n 's/^  \(would .*\)$/wrapper: \1/p'
        else
          if [ "$role" = game ]; then echo "wrapper: the game's wrapper cannot be renamed now"; else echo "wrapper: the Windows Steam's wrapper cannot be renamed now"; fi
          # the reasons: every one under --check; in a run, a stop (setup ends below) and not a skip, which the
          # rename step prints when it meets it
          if [ "$CHECK_ONLY" = 1 ]; then printf '%s\n' "$out" | grep -E '^  (stop|skip): '; else printf '%s\n' "$out" | grep '^  stop: '; fi
        fi ;;
      *) any=1; echo "wrapper: the wrapper mover gave no answer:"; printf '%s\n' "$out" ;;
    esac
  done
  [ "$any" = 1 ] || echo "wrapper: nothing to rename"
  return 0
}
mover() {   # [--dry-run]: the move script, with this wrapper's launch lock; the installer's own hold is let through
  local a
  a=("$@")
  [ -n "$WRAPPER" ] && a+=(--lock "$WRAPPER/Contents/SharedSupport/prefix/.launcher.lock")
  [ "${CS2_VIA_INSTALLER:-0}" = 1 ] && a+=(--held-by "$PPID")
  bash "$MOVER" ${a[@]+"${a[@]}"}
}
# what setup reads of the move script's output: its first line, and the rest without the line that says to run setup
mv_state() { printf '%s\n' "$1" | sed -n '1s/^state: //p'; }
mv_relay() { printf '%s\n' "$1" | sed '1d' | grep -v '^Now run: '; return 0; }
paths_lines() { echo "data: $(tilde "$DEST")"; echo "work: $(tilde "$CS2_WORK")"; }
move_line() {
  local out rc=0 shim
  if [ "$NAMED" = 1 ]; then
    if [ "${CS2_PATCH_DIR:-}" = "$OLD_INSTALL" ] && [ ! -e "$OLD_INSTALL" ] && [ ! -L "$OLD_INSTALL" ] && [ -d "$RUNTIME" ]; then
      echo "  !! This install has already moved to $(tilde "$RUNTIME"). Leave $DECLINE_VAR out."
      exit 1
    fi
    if [ -e "$OLD_INSTALL" ] || [ -L "$OLD_INSTALL" ]; then echo "move: $(tilde "$OLD_INSTALL") stays where it is: a folder was named"; fi
    return 0
  fi
  if { [ -e "$OLD_INSTALL" ] || [ -L "$OLD_INSTALL" ]; } && [ -e "$RUNTIME" ]; then
    shim="$(sed -n 's/^SCRIPT="\(.*\)"$/\1/p' "$HOME/Applications/Cities Skylines II.app/Contents/MacOS/launch" 2>/dev/null | head -1)"
    echo "move: WARNING: $(tilde "$OLD_INSTALL") and $(tilde "$RUNTIME") both exist. The app starts: $(tilde "${shim:-nothing yet}")"
    echo "      Setup uses $(tilde "$RUNTIME"). Remove $(tilde "$OLD_INSTALL") only when it holds nothing but deployed copies."
    return 0
  fi
  out="$(mover --dry-run 2>&1)" || rc=$?
  case "$(mv_state "$out")" in
    none) [ -e "$RUNTIME" ] || echo "move: a new install" ;;
    old)
      if [ "$rc" = 0 ]; then echo "move: $(tilde "$OLD_INSTALL") will be moved"; else echo "move: $(tilde "$OLD_INSTALL") cannot be moved now"; fi
      mv_relay "$out"
      [ -L "$OLD_INSTALL" ] && echo "  Setup will install into $(tilde "$RUNTIME"), and leave the link and what it names alone."
      ;;
    part-way)
      if [ "$rc" = 0 ]; then echo "move: an earlier move stopped part-way; this run finishes it"
      else echo "move: an earlier move stopped part-way and cannot be finished now"; fi
      mv_relay "$out" ;;
    *) echo "move: the move script gave no answer:"; printf '%s\n' "$out" ;;
  esac
  return 0
}

echo "=== Cities: Skylines II on macOS — setup ==="
if [ -n "${L1_FETCHED_REF:-}" ]; then echo "repo: a temporary copy of macgameport/1launcher at $L1_FETCHED_REF"
else echo "repo: $(tilde "$REPO")"; fi
if [ "$MAC_ONLY" = 0 ]; then paths_lines; move_line; wrapper_line; fi
echo
echo "Preflight:"

# --- this Mac, against what has been tested (the root README.md, "Compatibility")
[ "$(uname -s)" = "Darwin" ] || { echo "  This only runs on macOS."; exit 1; }
# sysctl, not uname -m: in a shell that itself runs under Rosetta, uname says x86_64 on Apple Silicon
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ]; then
  good "Apple Silicon"
  if arch -x86_64 /usr/bin/true 2>/dev/null; then good "Rosetta 2"
  else fail "Rosetta 2" "nothing here runs without it. Install it:  softwareupdate --install-rosetta --agree-to-license"; fi
else
  caution "Apple Silicon" "an Intel Mac. Not supported: nothing here has been run on one."
fi
OSV="$(sw_vers -productVersion 2>/dev/null)"; OSMAJ="${OSV%%.*}"
case "$OSMAJ" in
  26|27) say "macOS $OSV" "OK (tested)"; ok=$((ok+1)) ;;
  ''|*[!0-9]*) caution "macOS version" "it could not be read, so this Mac cannot be compared with what has been tested." ;;
  *) if [ "$OSMAJ" -ge 28 ]; then
       caution "macOS $OSV" "newer than anything this has been run on. Apple has said macOS 27 is the last release with general Rosetta support."
     elif [ "$OSMAJ" -ge 14 ]; then
       caution "macOS $OSV" "older than anything this has been run on. The engine's graphics library is built for macOS 26 and may not load."
     else
       caution "macOS $OSV" "below the minimum of DXMT, the graphics layer (macOS 14)."
     fi ;;
esac
if [ "$MAC_ONLY" = 1 ]; then   # scripts/install.sh, stage 1: this Mac alone
  echo
  if [ "$bad" -gt 0 ]; then
    echo "$bad prerequisite(s) missing — fix the ones marked above, then re-run."
    exit 1
  fi
  [ "$cautions" -gt 0 ] && caution_note
  caution_ask
  exit 0
fi

# --- the wrapper (found above the header, by find_wrapper)
if [ -n "$WRAPPER" ]; then good "Wine wrapper ($(basename "$WRAPPER"))"
else fail "Wine wrapper" "INSTALL.md step 1 — install the Porting Kit Wine 11 + DXMT wrapper, or set CS2_WRAPPER=/path/to/Wrapper.app, or run bash scripts/install.sh, which does this for you"; fi

PREFIX="${WRAPPER:-}/Contents/SharedSupport/prefix"
GDIR="$PREFIX/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"

# --- wine binary
if [ -n "$WRAPPER" ] && [ -x "$WRAPPER/Contents/SharedSupport/wine/bin/wine64" ]; then
  good "wine64 in the wrapper ($("$WRAPPER/Contents/SharedSupport/wine/bin/wine64" --version 2>/dev/null))"
else fail "wine64 in the wrapper" "the wrapper looks incomplete — reinstall the engine"; fi

# --- steam + game
if [ -n "$WRAPPER" ] && [ -f "$PREFIX/drive_c/Program Files (x86)/Steam/steam.exe" ]; then good "Steam inside the wrapper"
else fail "Steam inside the wrapper" "INSTALL.md step 2 — install Steam into the wrapper's prefix, or run bash scripts/install.sh, which does this for you"; fi
if [ -n "$WRAPPER" ] && [ -f "$GDIR/Cities2.exe" ]; then good "Cities: Skylines II installed"
else fail "Cities: Skylines II installed" "INSTALL.md step 3 — install the game via Steam inside the wrapper, or run bash scripts/install.sh, which does this for you"; fi

# --- python3 that really runs (Apple's stub answers to the name before the Command Line Tools are installed)
if python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 8))' >/dev/null 2>&1; then
  good "python3 (patches + icon extraction)"
else fail "python3, version 3.8 or newer" "install Apple's Command Line Tools:  xcode-select --install"; fi

echo
if [ "$bad" -gt 0 ]; then
  echo "$bad prerequisite(s) missing — fix the ones marked above, then re-run."
  echo "Full walkthrough: $GUIDE"
  exit 1
fi
echo "All $ok checks passed."
[ "$cautions" -gt 0 ] && caution_note
[ "$CHECK_ONLY" = 1 ] && { echo "(--check: stopping before making changes)"; exit 0; }
caution_ask

# ---------------------------------------------------------------- a wrapper that cannot be renamed now
# Before anything is changed, and before the folder move: a stop after the folder had moved and before the app was
# rebuilt would leave an app that names a launcher that is gone. Looked for only when there is something to rename.
if [ "$WM_GAME_RC" = 3 ] && { [ "${WM_GAME_STATE:-}" = old ] || [ "${WM_GAME_STATE:-}" = part-way ]; }; then
  echo; echo "  !! Setup stops here, before it moves or copies anything: the wrapper: lines above say why."
  echo "     Going on would rename a wrapper that is in use. When it has finished, $AGAIN."
  exit 3
fi

# ---------------------------------------------------------------- an install made before the folders moved
MOVED=0; SKIPPED=0; BESIDE_LINK=0; BOTH=0
if [ "$NAMED" = 0 ]; then
  MV_RC=0; MV_OUT="$(mover 2>&1)" || MV_RC=$?
  case "$MV_RC" in
    0) if printf '%s\n' "$MV_OUT" | grep -q '^  moved: '; then
         MOVED=1; echo; echo "Moving the install folder out of the home folder:"; mv_relay "$MV_OUT"
       fi
       . "$PATHS"; DEST="$CS2_DATA"
       [ "$MOVED" = 1 ] && paths_lines ;;
    1) SKIPPED=1; echo
       if [ "$(mv_state "$MV_OUT")" = part-way ]; then echo "The earlier move was not finished:"; else echo "The install folder was not moved:"; fi
       mv_relay "$MV_OUT"
       if [ -e "$RUNTIME" ] || [ -L "$RUNTIME" ]; then BOTH=1; elif [ -L "$OLD_INSTALL" ]; then BESIDE_LINK=1; fi
       . "$PATHS"; DEST="$CS2_DATA"
       echo "Setup goes on in $(tilde "$DEST")." ;;
    3) echo; echo "  !! Setup stops here, before it copies anything:"; mv_relay "$MV_OUT"
       echo "     Going on could copy over a script that is running. When it has finished, $AGAIN."
       exit 3 ;;
    *) echo; echo "  !! Setup stops here, before it copies anything:"; mv_relay "$MV_OUT"
       echo "     Or $AGAIN: that finishes the move too."
       exit 1 ;;
  esac
fi
# the runtime folder is the user's own (as surviving-mars-relaunched/scripts/setup.sh has it). A named folder,
# and an old folder that a skip leaves in use, are treated as before.
own_folder() {   # <folder>: 0 when it is a real folder of this user's that group and others cannot write to
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -f %u "$1")" = "$(id -u)" ] || return 1
  case "$(stat -f %Lp "$1")" in *[2367]?|*[2367]) return 1 ;; esac
  return 0
}
# the record's folder, the one that holds it, and installed/ in it are each the user's own too, tested here, before
# any folder is made: a folder that fails stops setup before anything of the record is written
# (docs/plans/built-in-update.md, 3.3 item 2)
if [ "$RECORD" = 1 ]; then
  for d in "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
    if [ -e "$d" ] || [ -L "$d" ]; then
      own_folder "$d" || { echo "  !! $(tilde "$d") is not a folder of your own that only you can write to; setup will not keep its record of versions there."; exit 1; }
    fi
  done
fi
case "$DEST/" in "$L1_DATA_ROOT"/*)
  for d in "$L1_DATA_ROOT" "$DEST" "$DEST/patches"; do
    if [ -e "$d" ] || [ -L "$d" ]; then
      own_folder "$d" || { echo "  !! $(tilde "$d") is not a folder of your own that only you can write to; setup will not put the launcher there."; exit 1; }
    fi
  done
  for d in "$L1_DATA_ROOT" "$DEST" "$DEST/patches"; do
    [ -d "$d" ] || { mkdir -p "$d" && chmod go-w "$d"; } || { echo "  !! $(tilde "$d") could not be made."; exit 1; }
  done ;;
esac
# the record's folders are made after the runtime folder's (docs/plans/built-in-update.md, 3.3 item 2)
if [ "$RECORD" = 1 ]; then
  for d in "$(dirname "$L1_UPDATE_DIR")" "$L1_UPDATE_DIR" "$L1_UPDATE_DIR/installed"; do
    [ -d "$d" ] || { mkdir -p "$d" && chmod go-w "$d"; } || { echo "  !! $(tilde "$d") could not be made."; exit 1; }
  done
fi
# the record's two copies are written beside their place and renamed over it, never written in place (as
# surviving-mars-relaunched/scripts/setup.sh writes every copy): a launcher may be reading the tool
put() {   # <from> <to>
  local tmp="$2.new.$$"
  if cp "$1" "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$2"; then return 0; fi
  rm -f "$tmp"; echo "  !! $(tilde "$2") could not be written."; exit 1
}
put_line() {   # <one line> <to>
  local tmp="$2.new.$$"
  if printf '%s\n' "$1" > "$tmp" && chmod 644 "$tmp" && mv -f "$tmp" "$2"; then return 0; fi
  rm -f "$tmp"; echo "  !! $(tilde "$2") could not be written."; exit 1
}
# the stamp (docs/plans/built-in-update.md, 3.3 item 5): called when the work is done, after the exit for problems,
# so for exit 0 and exit 5 and for no other. A stamp that cannot be written is said, and changes no exit code.
stamp_step() {
  [ "$RECORD" = 1 ] || return 0
  l1u_stamp 949230 "$REPO/.." && return 0
  echo "  !! This version could not be recorded ($(tilde "$L1_UPDATE_DIR/installed/949230")). 14unch3r will not offer updates for this game."
  return 0
}

# ---------------------------------------------------------------- install
echo
echo "Installing launcher + patches into $(tilde "$DEST")"
mkdir -p "$DEST"
_lname="$(basename "$LAUNCHER_SRC")"
if [ -f "$DEST/$_lname" ] && ! cmp -s "$LAUNCHER_SRC" "$DEST/$_lname"; then
  cp "$DEST/$_lname" "$DEST/$_lname.bak" && echo "  backed up existing launcher -> $_lname.bak"
fi
cp "$LAUNCHER_SRC" "$DEST/" && echo "  launcher:  $_lname"
cp "$REPO/repatch.sh" "$DEST/" && echo "  repatch.sh"
cp "$REPO/scripts/cs2-display-profile.sh" "$DEST/" 2>/dev/null && echo "  cs2-display-profile.sh (home/mobile display profiles)"
mkdir -p "$DEST/patches" && cp "$REPO"/patches/*.py "$DEST/patches/" 2>/dev/null && \
  echo "  patches:   $(ls "$DEST/patches"/*.py 2>/dev/null | wc -l | tr -d ' ') scripts"
# the two Python libraries the patch scripts use ship with them (patches/_vendor/README.md). Remove, then copy:
# cp -R onto an existing folder merges, and would keep a file a newer version no longer has.
rm -rf "$DEST/patches/_vendor" && cp -R "$REPO/patches/_vendor" "$DEST/patches/_vendor" \
  && echo "  patches/_vendor (dnfile and pefile, which the patch scripts use)"
cp "$RESOLVER" "$DEST/" && echo "  wrappers.sh (how the launcher finds the game's wrapper)"
# the record's tool, and beside the launcher the line that names its folder: here, before the window is built, so
# that a first setup already gives a window that finds the tool (docs/plans/built-in-update.md, 3.3 items 3 and 4)
if [ "$RECORD" = 1 ]; then
  put "$UPDATES" "$L1_UPDATE_DIR/updates.sh"
  put_line "$L1_UPDATE_DIR" "$DEST/update-dir"
fi

# ---------------------------------------------------------------- the wrappers' names (docs/plans/wrapper-names.md, 3.4)
# After the copies, so that a wrapper renamed here is found by the launcher just deployed even if setup fails later.
# A stop that appears only now (something started since the header) is a skip: setup goes on under the old name.
RENAMED=""; WM_SKIPPED=0
echo
echo "The Wine wrappers' names:"
for _role in game steam; do
  _rc=0; _out="$(wmover "$_role" 2>&1)" || _rc=$?
  case "$_rc" in
    0) [ "$(mv_state "$_out")" = none ] || printf '%s\n' "$_out" | sed '1d'
       RENAMED="$RENAMED$(printf '%s\n' "$_out" | sed -n 's/^  moved: //p')
" ;;
    1|3) WM_SKIPPED=1; printf '%s\n' "$_out" | sed '1d' | sed 's/^  stop: /  skip: /' ;;
    *) problems=$((problems+1)); printf '%s\n' "$_out" | sed '1d'
       echo "  !! the rename stopped part-way: the wrapper is marked and keeps its old name until the next run, and the game still starts" ;;
  esac
done
RENAMED="$(printf '%s' "$RENAMED" | sed '/^$/d')"
[ -n "$RENAMED" ] || [ "$WM_SKIPPED" = 1 ] || echo "  nothing to rename"
find_wrapper   # resolved again: the wrapper may have a new name now
PREFIX="${WRAPPER:-}/Contents/SharedSupport/prefix"
GDIR="$PREFIX/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"

# --- the mod badge patch is opt-in. It edits the game's Game.dll to hide a keybinding badge, which is a
#     preference and not a compatibility fix (INSTALL.md, "Mod keybinding badges"). The launcher applies it
#     wherever the installed copy exists, so the installed copy is the switch; the marker records that the
#     player asked, and sits inside patches/ so that it travels with that folder.
BADGE_SRC="$REPO/scripts/patch-modconflict-badge.py"
BADGE_DST="$DEST/patch-modconflict-badge.py"
BADGE_MARK="$DEST/patches/.mod-badges-on"
# the script edits the Game.dll of the wrapper setup found: the launcher gives it the game folder
BADGE_DLL_DIR="$GDIR/Cities2_Data/Managed"
badge_has_run() { ls "$BADGE_DLL_DIR"/Game.dll.bak-modconflict-* >/dev/null 2>&1; }
badge_install() { cp "$BADGE_SRC" "$BADGE_DST" && : > "$BADGE_MARK"; }
case "$BADGES" in
  hide)
    badge_install && echo "  mod badge patch: on. It takes effect at the next launch; --show-mod-badges turns it off"
    ;;
  show)
    rm -f "$BADGE_DST" "$BADGE_MARK"
    echo "  mod badge patch: off. If it has already edited Game.dll, put the file back with Steam: right-click the"
    echo "     game, Properties, Installed Files, Verify integrity of game files. A Game.dll.bak-modconflict-* file"
    echo "     beside Game.dll is the right one only if it was made on the game build that is installed now."
    ;;
  *)
    if [ -f "$BADGE_MARK" ]; then
      badge_install && echo "  mod badge patch: on (--show-mod-badges turns it off)"
    elif [ -f "$BADGE_DST" ] && badge_has_run; then      # it ran here before the patch became opt-in
      badge_install && echo "  mod badge patch: on, as before (--show-mod-badges turns it off)"
    elif [ -f "$BADGE_DST" ]; then                        # copied by an older setup, never ran
      rm -f "$BADGE_DST"
      echo "  mod badge patch: off (it has never run here); --hide-mod-badges turns it on"
    fi
    ;;
esac
chmod +x "$DEST"/*.sh 2>/dev/null

# repatch.sh's exit 3: every script that ran either finished or is not for this build of the game, and at least
# one is not (docs/plans/patch-outcomes.md, 2.4). Not a problem: the rest of setup runs, and it exits 5 (PD1).
# repatch.sh's output is not captured, so this names nothing and points up at its NO FIX YET lines.
nofix_block() {
  local build route
  build="$(sed -n 's/^[[:space:]]*"buildid"[[:space:]]*"\([^"]*\)".*/\1/p' "$GDIR/../../appmanifest_949230.acf" 2>/dev/null | head -1)"
  if [ -n "${L1_FETCHED_REF:-}" ]; then
    route="Open the installer again later: it fetches the newest fixes. Until the fix is out it says this again."
  elif [ "${CS2_VIA_INSTALLER:-0}" = 1 ]; then
    route="Update your copy (git pull in its folder), then open the installer again. If it says this again, the fix is not out yet."
  else
    route="Update this checkout (git pull) and run setup again. If it says this again, the fix is not out yet."
  fi
  echo "  >> Not every Mac fix works with this build of the game${build:+ (build $build)}. The NO FIX YET lines"
  echo "     above name each one and say what you may see without it. The other fixes are in place."
  echo "     The usual cause: Steam has updated the game, and the Mac fix for the new build is not out yet."
  echo "     You can try the game. It may run well, or show what those lines name."
  echo "     $route"
  echo "     More, and where a fix in progress is listed: \"When a fix is not out yet\" in the guide: $GUIDE"
}
echo
echo "Applying binary patches (idempotent — safe to re-run after every game update):"
NOFIX=0
RP_RC=0
CS2_GAME_DIR="$GDIR" bash "$DEST/repatch.sh" dxmt11 || RP_RC=$?
if [ "$RP_RC" = 0 ]; then
  echo "  every patch script finished without error."
elif [ "$RP_RC" = 3 ]; then
  NOFIX=1; nofix_block
else
  problems=$((problems+1))
  echo "  !! not every patch is in place: the FAILED line above names the ones that are not. They refuse to write"
  if [ -n "${L1_FETCHED_REF:-}" ]; then
    echo "     rather than corrupt a file. If the game has just updated, a pattern may have moved: open the installer"
    echo "     again, which fetches the current scripts, and see INSTALL.md, 'After a game update'."
  else
    echo "     rather than corrupt a file. If the game has just updated, a pattern may have moved: update this"
    echo "     checkout (git pull), run setup again, and see INSTALL.md, 'After a game update'."
  fi
  echo "     A NO FIX YET line above, if there is one, names fixes that do not work with this build of the game."
fi

echo
echo "Building the double-clickable app:"
if ! bash "$REPO/scripts/make-shortcut.sh" --launcher "$DEST/$(basename "$LAUNCHER_SRC")" \
  --game "$GDIR/Cities2.exe"; then
  problems=$((problems+1))
  echo "  !! the app was not built: the lines above say why."
else
  # 14unch3r (docs/plans/launcher-window.md, 2.3). Only after the game's app was built, and never counted as a
  # problem: the game's own app does not need it. Its builder exits 3 when it skipped the build and says why.
  echo
  echo "Building 14unch3r, the window that lists the games:"
  WINDOW_BUILDER="$REPO/../common/make-launcher-app.sh"
  if [ ! -f "$WINDOW_BUILDER" ]; then
    echo "  window: not built (common/make-launcher-app.sh is not in this checkout)"
  elif bash "$WINDOW_BUILDER"; then
    WINDOW_BUILT=1
  else
    echo "  window: not built (see the line above)"
  fi
fi
# S734M.app, the Windows Steam, names its wrapper's path: rebuilt when it is there, so that it follows a rename. Only
# the builder's own bundle is rebuilt (the builder refuses any other), and --no-clone makes no store wrapper that was
# not there. Never counted as a problem: the game does not need it.
if [ -e "$HOME/Applications/S734M.app" ] && [ -f "$REPO/scripts/make-steam-shortcut.sh" ]; then
  echo
  echo "Rebuilding S734M, the Windows Steam:"
  bash "$REPO/scripts/make-steam-shortcut.sh" --no-clone 2>&1 | sed 's/^/  /' || true
fi

# 14unch3r's shortcut on the Desktop (docs/plans/launcher-window-look.md, 2.9): one alias, made only on a yes, and
# never in place of anything already there; the window program says what is at the path. Run after the problems
# exit, so a setup that ends with problems never reaches it. Without --desktop, a run that is not at a terminal, or
# that has --yes, does not look at the Desktop: a look could bring a question from macOS that nobody is there to see.
DESKTOP_LINE=""
desktop_step() {
  WINDOW_APP="$HOME/Applications/14unch3r.app"
  WINDOW_PROG="$WINDOW_APP/Contents/MacOS/launcher-window"
  [ "${WINDOW_BUILT:-0}" = 1 ] || return 0
  [ -x "$WINDOW_PROG" ] || return 0
  [ -d "$HOME/Desktop" ] || return 0
  _look=0; _ask=0
  if [ "$DESKTOP" = 1 ]; then _look=1
  elif [ "$ASSUME_YES" = 0 ] && [ -t 0 ]; then _look=1; _ask=1
  fi
  [ "${L1_UPDATE:-}" = 1 ] && [ "$_ask" = 1 ] && { _look=0; _ask=0; }   # an update: nobody is watching for this question
  _state=unlooked
  if [ "$_look" = 1 ]; then _state=$("$WINDOW_PROG" --alias "$WINDOW_APP" "$HOME/Desktop/14unch3r" 2>/dev/null); fi
  if [ "$_state" = none ]; then
    _want=$DESKTOP
    if [ "$_ask" = 1 ]; then
      printf 'Put a 14unch3r shortcut on the Desktop? [y/N] '
      read -r _a || _a=""
      case "$_a" in y|Y) _want=1 ;; esac
    fi
    if [ "$_want" = 1 ]; then _state=$("$WINDOW_PROG" --alias "$WINDOW_APP" "$HOME/Desktop/14unch3r" make 2>/dev/null); fi
  fi
  case "$_state" in
    made)          DESKTOP_LINE="Desktop:   14unch3r shortcut added" ;;
    have)          DESKTOP_LINE="Desktop:   the 14unch3r shortcut is already there" ;;
    other)         DESKTOP_LINE="Desktop:   something else named 14unch3r is there; it was left as it is" ;;
    none|unlooked) DESKTOP_LINE="Desktop:   no shortcut made. $ADD_ONE" ;;
    failed*)       DESKTOP_LINE="Desktop:   the shortcut could not be made: $(printf '%s' "$_state" | cut -s -f2)" ;;
  esac
  return 0
}

# what a rename of the wrappers, or one that was skipped, leaves the owner to know (docs/plans/wrapper-names.md, 3.8)
rename_blocks() {
  local l first=1
  if [ -n "$RENAMED" ]; then
    echo
    while IFS= read -r l; do
      if [ "$first" = 1 ]; then echo "Renamed:   $l"; first=0; else echo "           $l"; fi
    done <<< "$RENAMED"
    echo "           The game's app and 14unch3r find a wrapper by a mark inside it, whatever its name. Anything of yours"
    echo "           that names an old path (a Dock item made from a wrapper, an alias, a saved command, a Porting Kit"
    echo "           entry) must be pointed at the new one. To keep the old names on a Mac not renamed yet: $WDECLINE"
  fi
  if [ "$WM_SKIPPED" = 1 ]; then
    echo
    echo "Not renamed: a wrapper kept its name, for the reason given above. Every start of the game still works."
    echo "           The next run tries again: $AGAIN."
  fi
  return 0
}

# what a move, or a move that was skipped, leaves the owner to know. Printed at every end a run reaches after its
# first copy: a run that moved the folder and then met a failed patch pass must still say where the folder went.
move_blocks() {
  if [ "$MOVED" = 1 ]; then
    echo
    echo "Moved:     what the game runs is now in $(tilde "$DEST")"
    [ -d "$CS2_WORK" ] && echo "           everything else that was in ~/cs2-patch is in $(tilde "$CS2_WORK")"
    echo "           Anything of yours that names ~/cs2-patch (a copied .command, an alias, a second app made with"
    echo "           make-shortcut.sh --name) must be pointed at the first of those folders."
    for _n in launch-cs2.sh revenv; do
      [ -e "$DEST/$_n" ] && echo "           No longer used, and safe to delete: $(tilde "$DEST/$_n")"
    done
    echo "           To keep an install in ~/cs2-patch instead: $DECLINE"
    echo "           Putting a folder back: \"If your install was made before the folders moved\" in the guide: $GUIDE"
  fi
  if [ "$SKIPPED" = 1 ]; then
    echo
    if [ "$BOTH" = 1 ]; then
      echo "Not moved: ~/cs2-patch and $(tilde "$DEST") both exist, and setup used the second: the app starts the"
      echo "           launcher there. Remove ~/cs2-patch only when it holds nothing but deployed copies."
    elif [ "$BESIDE_LINK" = 1 ]; then
      echo "Not moved: ~/cs2-patch is a symlink, so it was left alone, and so was what it names. A new install was made"
      echo "           beside it, in $(tilde "$DEST"), and the app starts that one."
    else
      echo "Not moved: the install folder was left where it is, for the reason given above. The install keeps working"
      echo "           in $(tilde "$DEST"). The next run tries again: $AGAIN."
    fi
  fi
  return 0
}

# the closing words of the record (docs/plans/built-in-update.md, 3.3 item 6):
# every other game that is set up on this Mac (a wrapper with the game's program in it, looked for with the game's
# wrapper variable unset: one left in the environment must not decide what is set up) and has no stamp
unrecorded_games() {
  local id w title
  [ "$RECORD" = 1 ] || return 0
  for id in $(l1w_games); do
    [ "$id" = 949230 ] && continue
    l1w_row game "$id" || continue
    w="$( [ -z "$L1W_VAR" ] || unset "$L1W_VAR"; l1w_find game "$id" 2>/dev/null )" || continue
    l1w_program "$w" "$L1W_PROGRAM" || continue
    l1u_stamp_of "$id" > /dev/null && continue
    title="$(awk -F'\t' -v id="$id" '$1 == id { print $3; exit }' "$GAMES" 2>/dev/null)"
    [ -n "$title" ] || continue
    echo
    echo "$title was set up by an older version. Paste its installer line once, so that it gets updates too."
  done
  return 0
}

ADD_ONE="To add one:  bash scripts/setup.sh --desktop"
AFTER_UPDATE="re-run  bash scripts/setup.sh  (updates reset the patched DLLs)."
if [ "${CS2_VIA_INSTALLER:-0}" = 1 ]; then
  ADD_ONE="To add one, open the installer again and answer y."
  AFTER_UPDATE="open the installer again (updates reset the patched DLLs)."
fi
if [ "$problems" -gt 0 ]; then
  move_blocks; rename_blocks
  echo
  echo "=== setup finished with $problems problem(s): see the lines marked !! above ==="
  exit 1
fi
stamp_step
desktop_step

echo
if [ "$NOFIX" = 0 ]; then echo "=== setup complete ==="; echo; fi
cat << DONE
Play:      double-click  ~/Applications/Cities Skylines II.app$([ "${WINDOW_BUILT:-0}" = 1 ] && printf '\n           or open 14unch3r, which lists every game set up on this Mac')$([ -n "$DESKTOP_LINE" ] && printf '\n%s' "$DESKTOP_LINE")
Log:       ~/Library/Logs/cs2-launcher.log

First run: Steam signs in inside the wrapper, waits ~15s for the licence to sync, then the game
           starts. That wait only happens when Steam was not already running.

In-game:   Options -> Graphics -> Display Mode -> FULLSCREEN WINDOW.
           Exclusive Fullscreen has an alt-tab presentation bug on this stack (dxmt#206) —
           borderless looks identical and is immune.

After a game update: $AFTER_UPDATE
Troubleshooting: INSTALL.md, then GOTCHAS.md.
DONE
move_blocks; rename_blocks
unrecorded_games
if [ "$NOFIX" = 1 ]; then
  echo
  echo "=== setup finished, but not every Mac fix is out yet for this build of the game: see the lines marked >> above ==="
  exit 5
fi
