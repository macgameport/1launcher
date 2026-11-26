#!/bin/bash
# update-games.sh -- the update's driver (docs/plans/built-in-update.md, 3.4). Run only by the root install.sh
# (install.sh update), from the tree it fetched, so the code that drives an update is always the newest. It
# runs the installer of every game that is set up on this Mac and follows the line that was fetched, each with
# no option: no answer is ever given for the player, and each installer reads the Terminal as this script does.
#
#   bash common/update-games.sh     (no argument; L1_FETCHED_REF is set by the root install.sh)
#
# The games it looks at are the games set up on this Mac, not the record: for each row of this tree's
# common/games.tsv whose folder is a plain name, in the order of the app IDs as numbers, it asks
# common/wrappers.sh for the game's wrapper, with the game's wrapper variable unset for that look only. A game
# with no wrapper, or a wrapper without a prefix or without the game's program, is not set up here.
# After the games, 14unch3r itself (docs/plans/launcher-first-install.md, 3.5): when it has a stamp of its own on
# the line that was fetched and at an older version, common/install-launcher.sh of this tree is run, with no
# argument, and counted like a game's installer. A stamp already at the fetched version (a game's setup wrote
# it in this run, or nothing is newer) means the window is that version's: nothing is run, and it counts as up
# to date. A stamp with neither the app nor a game set up is removed, as a game's is.
#   exit 0 = every game set up here was updated
#        1 = something failed: an installer (any exit but 0, 3 and 5; the launcher's: any but 0 and 3), a game
#            with two wrappers marked alike, or a game this version has no installer for
#        2 = not run by the root install.sh (L1_FETCHED_REF is not set), or an argument given
#        3 = something was left as it is: a game with no record, a game or 14unch3r on another line or newer
#            than what was fetched; an installer that stopped at a question; neither a game nor 14unch3r set up;
#            no record on this Mac; another update running; or GitHub sent an older version than the one
#            already offered
# It exports L1_UPDATE=1, under which a setup asks nothing about the Desktop. Its lock is the link `updating`
# in the record's folder, in the launchers' lock form: its target is this process's number. While an install's
# lock, `installing`, is live it stops, exit 3 (docs/plans/launcher-first-install.md, 3.8).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
LINE="https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh"
PIDFORM='^[1-9][0-9]{0,9}$'

# 1. only from the root install.sh; the rules come from this tree
if [ -z "${L1_FETCHED_REF:-}" ] || [ $# -gt 0 ]; then
  echo "update-games.sh is run by the root install.sh, with no argument: install.sh update"
  exit 2
fi
for f in paths.sh updates.sh wrappers.sh games.tsv; do
  [ -f "$HERE/$f" ] || { echo "The update's own files are gone (macOS clears old temporary files). Try the update again."; exit 1; }
done
L1_UPDATE_DIR="$( . "$HERE/paths.sh" 2>/dev/null; printf '%s' "$L1_UPDATE_DIR" )"   # that one folder, and nothing else of paths.sh
. "$HERE/updates.sh"
. "$HERE/wrappers.sh"
export L1_UPDATE=1

# 2. the record's folder must be the player's own, and one update runs at a time
if ! l1u_own; then
  echo "This Mac keeps no record of what is installed. Paste each game's installer line once; after that it can update."
  exit 3
fi
LOCK="$L1_UPDATE_DIR/updating"
lock_holder() { readlink "$LOCK" 2>/dev/null; }
take_lock() {   # 0 = this process holds the lock. A target that is no process number, or names one that is gone, is taken over
  local h
  ln -s "$$" "$LOCK" 2>/dev/null && return 0
  h="$(lock_holder)"
  if ! [[ "$h" =~ $PIDFORM ]] || ! kill -0 "$h" 2>/dev/null; then
    [ "$(lock_holder)" = "$h" ] && rm -f "$LOCK"
    ln -s "$$" "$LOCK" 2>/dev/null && return 0
  fi
  return 1
}
release_lock() { [ "$(lock_holder)" = "$$" ] && rm -f "$LOCK"; return 0; }
l1u_lock_live updating || rm -f "$LOCK" 2>/dev/null   # a lock that is not live by the one rule, the Mac's last start among it, is removed first
if ! take_lock; then
  echo "An update is already running in another Terminal window."
  exit 3
fi
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
# an install and an update keep out of each other's way (docs/plans/launcher-first-install.md, 3.8): this lock is
# taken first, and only then is the install's looked at, so of two that start together at least one stops
if l1u_lock_live installing; then
  echo "An install is running in another Terminal window (process $L1U_HOLDER). Wait for it to finish, then update again."
  exit 3
fi

# 3. what was fetched must not be older than what this Mac was already offered
T="$(l1u_version_of "$ROOT/CHANGELOG.md")" || T=-
IFS=$'\t' read -r _word _installed OFFERED _detail << EOF
$(l1u_state)
EOF
if l1u_newer "$OFFERED" "$T"; then
  echo "GitHub sent $T, not yet $OFFERED. Try again in a few minutes."
  exit 3
fi

# 4. the games set up on this Mac, one after the other
SETUP=0; RAN=0; LEFT=0; FAILED=0; CLOSING=""
closing() { CLOSING="$CLOSING$1
"; }
set_up() {   # <app ID>: 0 = set up on this Mac; 1 = not; 2 = two wrappers carry its marker
  local w rc
  l1w_row game "$1" || return 1   # a game this tree's rule for wrappers does not know
  w="$( [ -z "$L1W_VAR" ] || unset "$L1W_VAR"; l1w_find game "$1" 2>/dev/null )"; rc=$?
  [ "$rc" = 2 ] && return 2
  [ "$rc" = 0 ] || return 1
  [ -d "$w/Contents/SharedSupport/prefix" ] || return 1
  l1w_program "$w" "$L1W_PROGRAM" || return 1
  return 0
}
one_game() {   # <app ID> <folder> <title>
  local id="$1" folder="$2" title="$3" su stamp line ver rc
  set_up "$id"; su=$?
  if [ "$su" = 2 ]; then
    closing "$title: two wrappers carry its marker. Left as it is."; FAILED=$((FAILED + 1)); return 0
  fi
  if [ "$su" != 0 ]; then   # not set up here: an update must not start a new install of a game the player removed
    if l1u_stamp_of "$id" > /dev/null; then
      rm -f "$L1_UPDATE_DIR/installed/$id"
      closing "$title: no longer set up on this Mac. Skipped."
    fi
    return 0
  fi
  SETUP=$((SETUP + 1))
  if ! stamp="$(l1u_stamp_of "$id")"; then   # its files may come from a checkout
    closing "$title: set up by a version that keeps no record. Paste its installer line once: /bin/bash -c \"\$(curl --proto '=https' --tlsv1.2 -fsSL $LINE)\" 1launcher-install $id"
    LEFT=$((LEFT + 1)); return 0
  fi
  line="${stamp%%$'\t'*}"; ver="${stamp#*$'\t'}"
  if [ "$line" != "$L1_FETCHED_REF" ]; then
    closing "$title: set up from $line, so it is left as it is."; LEFT=$((LEFT + 1)); return 0
  fi
  if l1u_newer "$ver" "$T"; then
    closing "$title is at $ver, newer than what GitHub sent ($T). Left as it is."; LEFT=$((LEFT + 1)); return 0
  fi
  if [ ! -f "$ROOT/$folder/scripts/install.sh" ]; then
    closing "!! $title: this version has no installer for it."; FAILED=$((FAILED + 1)); return 0
  fi
  echo
  echo "=== $title ==="
  bash "$ROOT/$folder/scripts/install.sh" 3<&-; rc=$?   # no option; its standard input is this script's own
  RAN=$((RAN + 1))
  case "$rc" in
    0) closing "$title: updated." ;;
    5) closing "$title: updated. A Mac fix is not out yet for this build of the game: its lines above say more." ;;
    3) closing "$title: its installer stopped. Its lines above say why."; LEFT=$((LEFT + 1)) ;;
    *) closing "!! $title: its installer did not finish (exit $rc). Its lines above say why."; FAILED=$((FAILED + 1)) ;;
  esac
  return 0
}
# The rows that count: four fields, an app ID, a folder that passes the root install.sh's pattern; the first row
# of an ID, in the order of the IDs as numbers. The list is read on descriptor 3, so that each installer's
# standard input is this script's own, the Terminal.
ROWS="$(awk -F'\t' 'NF == 4 && $1 ~ /^[1-9][0-9]*$/ && length($1) <= 10 && $2 ~ /^[a-z0-9][a-z0-9-]*$/ && !seen[$1]++ { print $1 "\t" $2 "\t" $3 }' "$HERE/games.tsv" 2>/dev/null | sort -n)"
while IFS=$'\t' read -r id folder title <&3; do
  [ -n "$id" ] || continue
  one_game "$id" "$folder" "$title"
done 3<< EOF
$ROWS
EOF

# 4b. 14unch3r itself, after the games (docs/plans/launcher-first-install.md, 3.5). The test that the launcher is
# there is this script's own: the builder's (own_app, common/make-launcher-app.sh) returns 0 for an app that is
# absent, and the builder cannot be read with `.`. The identifier is the builder's ID= line; the test of this
# script holds the two equal. The test decides one thing: whether a stamp with no app and no game is removed.
WINDOW_ID="local.1launcher.window"
launcher_app() {   # 0 when ~/Applications/14unch3r.app is a real folder, no Wine wrapper, and the builder's own app
  local a="$HOME/Applications/14unch3r.app" id
  [ -d "$a" ] && [ ! -L "$a" ] || return 1
  { [ ! -e "$a/Contents/SharedSupport" ] && [ ! -L "$a/Contents/SharedSupport" ]; } || return 1
  id="$(plutil -extract CFBundleIdentifier raw "$a/Contents/Info.plist" 2>/dev/null)" || return 1
  [ "$id" = "$WINDOW_ID" ]
}
CURRENT=0   # 1 when 14unch3r is here with its stamp at the fetched version, and so needs nothing
the_launcher() {
  local stamp line ver rc
  stamp="$(l1u_stamp_of_launcher)" || return 0   # no stamp: a Mac whose games' setups write it at this update
  if [ "$SETUP" = 0 ] && ! launcher_app; then    # an update does not bring back what the player removed
    rm -f "$L1_UPDATE_DIR/launcher"; return 0
  fi
  SETUP=$((SETUP + 1))   # from here on SETUP counts 14unch3r with the games: something of this project is set up
  line="${stamp%%$'\t'*}"; ver="${stamp#*$'\t'}"
  if [ "$line" != "$L1_FETCHED_REF" ]; then   # 14unch3r follows another line
    closing "14unch3r: set up from $line, so it is left as it is."; LEFT=$((LEFT + 1)); return 0
  fi
  if l1u_newer "$ver" "$T"; then   # 14unch3r is newer than the fetch
    closing "14unch3r is at $ver, newer than what GitHub sent ($T). Left as it is."; LEFT=$((LEFT + 1)); return 0
  fi
  if [ "$ver" = "$T" ]; then CURRENT=1; return 0; fi   # the window is that version's already
  echo
  echo "=== 14unch3r ==="
  bash "$HERE/install-launcher.sh" 3<&-; rc=$?   # no argument; its standard input is this script's own
  RAN=$((RAN + 1))   # 14unch3r's installer ran
  case "$rc" in
    0) closing "14unch3r: updated." ;;
    3) closing "14unch3r: its installer stopped. Its lines above say why."; LEFT=$((LEFT + 1)) ;;
    *) closing "!! 14unch3r: not rebuilt (exit $rc). Its lines above say why."; FAILED=$((FAILED + 1)) ;;
  esac
  return 0
}
the_launcher

# 5. the closing block: one line per game with what happened, then one line for the whole
echo
echo "=== The update ==="
printf '%s' "$CLOSING"
if { [ "$RAN" -gt 0 ] || [ "$CURRENT" = 1 ]; } && [ "$LEFT" = 0 ] && [ "$FAILED" = 0 ]; then
  echo "Everything is up to date: 1launcher $T."
elif [ "$SETUP" = 0 ] && [ "$FAILED" = 0 ]; then
  echo "No game is set up on this Mac."
else
  echo "Not everything was updated. Do what the lines above say."
fi

# 6. the exit code
[ "$FAILED" -gt 0 ] && exit 1
if [ "$LEFT" -gt 0 ] || [ "$SETUP" = 0 ]; then exit 3; fi
exit 0
