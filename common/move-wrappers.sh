#!/bin/bash
# move-wrappers.sh: give a game's Wine wrapper, or the Windows Steam's, its new name (docs/plans/wrapper-names.md,
# 3.4). A rename in ~/Applications and nothing else: nothing is copied. Each setup runs it; it can be run alone.
#
#   bash common/move-wrappers.sh [--dry-run] [--held-by <pid>] [--holders-skip] game <app ID>
#   bash common/move-wrappers.sh [--dry-run] [--held-by <pid>] [--holders-skip] steam
#
#   --dry-run       print the reasons and the rename, change nothing, and exit as the real run would
#   --held-by       a process whose hold on the wrapper's launch lock is let through (the installer that called setup)
#   --holders-skip  a process holding one of a game's wrapper's own files is a skip and not a stop (setup passes it
#                   only under an installer)
#
# Its output is an interface: setup relays it and reads it. Line 1 is "state: none" (nothing to rename; no other
# line follows), "state: old" (an unmarked wrapper under an old name) or "state: part-way" (an earlier rename
# stopped between its steps). Then lines indented by two spaces: "stop: ..." or "skip: ..." per reason, and
# "would move: A -> B", "moved: A -> B" or "not moved: A -> B" for the rename ("would finish:" or "finished:"
# when an earlier rename only needs its marker tidied). Then closing lines that are not indented. Every path is
# printed with the home folder as ~.
#
# Exit: 0 renamed, finished an earlier rename, or nothing to do · 1 skipped: nothing renamed, every reason
# printed · 2 the rename failed after the marker was written: the next run finishes it · 3 stop: nothing renamed,
# and setup must not go on (a launch, an install or the game is using the game's wrapper).
# To decline for one run: L1_KEEP_WRAPPER_NAMES=1.
# For its tests: L1_WMOVE_PROBE=<program> replaces the open-files probe (`<program> holders <wrapper>` prints one
# process per line), and L1_WMOVE_STOP_AFTER=rename ends it straight after its rename.
set -u
HERE="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$HERE/wrappers.sh" ] || { echo "move-wrappers.sh: wrappers.sh is not beside it"; exit 3; }
. "$HERE/wrappers.sh"
DRY=0; HELD=""; HSKIP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --held-by) HELD="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
    --holders-skip) HSKIP=1; shift ;;
    -*) echo "move-wrappers.sh: unknown option: $1"; exit 3 ;;
    *) break ;;
  esac
done
ROLE="${1:-}"; ID="${2:-}"
case "$ROLE" in
  game) l1w_row game "$ID" || { echo "move-wrappers.sh: no game with the Steam app ID '$ID'"; exit 3; } ;;
  steam) ID=""; l1w_row steam ;;
  *) echo "usage: bash common/move-wrappers.sh [--dry-run] [--held-by <pid>] [--holders-skip] game <app ID> | steam"; exit 3 ;;
esac
APPS="$HOME/Applications"
NEW="$APPS/$(l1w_name "$ROLE" "$ID")"
WHAT="the game's wrapper"; [ "$ROLE" = steam ] && WHAT="the Windows Steam's wrapper"
t() { l1w_tilde "$1"; }
stop=0; skip=0
reason() { echo "  $1: $2"; if [ "$1" = stop ]; then stop=1; else skip=1; fi; }
none() { echo "state: none"; exit 0; }
is_old() {   # <path>: one of this role's old names in ~/Applications
  local o
  while IFS= read -r o; do [ -n "$o" ] && [ "$o" = "$1" ] && case "$o" in "$APPS"/*) return 0 ;; esac; done <<< "$L1W_OLD"
  return 1
}
probe() {   # the processes that hold one of the wrapper's own named files; lsof's output is read, not its exit code
  local b="$1/Contents/SharedSupport/wine/bin" f files=()
  if [ -n "${L1_WMOVE_PROBE:-}" ]; then "$L1_WMOVE_PROBE" holders "$1"; return 0; fi
  for f in wineserver wine64 wine wine64-preloader wine-preloader; do [ -f "$b/$f" ] && files+=("$b/$f"); done
  [ "${#files[@]}" -gt 0 ] || return 0
  lsof -t -- "${files[@]}" 2>/dev/null
  return 0
}
mv_q() {   # <from> <to>: mv, its own words kept in MV_ERR with the home folder as ~
  local e tl='~'
  MV_ERR=""; e="$(mv "$1" "$2" 2>&1)" && return 0
  MV_ERR="${e//$HOME/$tl}"; return 1
}

# --- what is there
WR=""; STATE=none; DUP=0
l1w_by_marker "$ROLE" "$ID"
if [ "$L1W_COUNT" -gt 1 ]; then
  DUP=1
  while IFS= read -r a; do l1w_pending "$a" && STATE=part-way; done <<< "$L1W_HITS"
elif [ "$L1W_COUNT" = 1 ]; then
  WR="$L1W_HITS"; l1w_pending "$WR" && STATE=part-way
else
  # no marked wrapper: the app that step 3 of the resolver returns
  while IFS= read -r a; do
    [ -n "$a" ] && [ -d "$a/Contents/SharedSupport/prefix" ] || continue
    if [ -n "$(l1w_key "$a" L1Role)" ]; then
      l1w_marked "$a" "$ROLE" "$ID" || continue   # another role or app ID: not this one
      l1w_pending "$a" && { WR="$a"; STATE=part-way; }
      break                                       # marked and not pending: someone's own name, left alone
    fi
    WR="$a"; STATE=old; break
  done <<< "$L1W_OLD"
fi
[ "$STATE" = none ] && [ "$DUP" = 0 ] && none
echo "state: $STATE"
RENAME=0; [ -n "$WR" ] && is_old "$WR" && RENAME=1

# --- reasons not to rename that come from no probe; nothing is changed while looking
if [ "${L1_KEEP_WRAPPER_NAMES:-}" = 1 ]; then
  reason skip "L1_KEEP_WRAPPER_NAMES=1 is set: $WHAT keeps its name this run"
fi
if [ "$ROLE" = game ] && [ -n "${!L1W_VAR:-}" ]; then
  reason skip "$L1W_VAR names a wrapper ($(t "${!L1W_VAR}")): it is used as it is and keeps its name"
fi
if [ "$DUP" = 1 ]; then
  reason skip "two wrappers carry the marker of $WHAT: move one to the Trash"
fi
if [ -n "$WR" ]; then
  wskip=0
  if [ -L "$APPS" ]; then reason skip "$(t "$APPS") is a symlink"; wskip=1
  elif [ "$(stat -f %u "$APPS")" != "$(id -u)" ]; then reason skip "$(t "$APPS") is not a folder of your own"; wskip=1; fi
  if [ "$(dirname "$WR")" != "$APPS" ]; then
    reason skip "$(t "$WR") is outside ~/Applications: it is found under its name there and never renamed"; wskip=1
  elif [ -L "$WR" ]; then
    reason skip "$(t "$WR") is a symlink: it stays under its old name, where a search still finds it"; wskip=1
  elif [ "$(stat -f %u "$WR")" != "$(id -u)" ]; then
    reason skip "$(t "$WR") is not your own"; wskip=1
  fi
  if [ "$RENAME" = 1 ] && { [ -e "$NEW" ] || [ -L "$NEW" ]; }; then reason skip "$(t "$NEW") is already there"; fi
  P="$WR/Contents/Info.plist"
  if [ ! -f "$P" ]; then reason skip "$(t "$WR") has no Info.plist"
  elif ! plutil -lint -s "$P" >/dev/null 2>&1; then reason skip "$(t "$WR")'s Info.plist does not parse"
  elif [ ! -w "$WR/Contents" ] || [ ! -w "$P" ]; then reason skip "$(t "$WR")'s Info.plist cannot be written"; fi
  if [ "$wskip" = 0 ] && why="$(l1w_fails "$WR")"; then :
  elif [ "$wskip" = 0 ]; then reason skip "$(t "$WR") is not a wrapper this can rename: $why"; fi
  if [ "$ROLE" = steam ] && [ "$STATE" = old ]; then
    [ -f "$WR/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steam.exe" ] \
      || [ -f "$WR/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/Steam.exe" ] \
      || reason skip "$(t "$WR") holds no steam.exe"
    wp="$(CDPATH= cd -- "$WR" 2>/dev/null && pwd -P)"
    for g in $(l1w_games); do
      l1w_row game "$g"
      if l1w_program "$WR" "$L1W_PROGRAM"; then reason skip "$(t "$WR") holds a game ($g): it is not the Windows Steam's wrapper"; fi
      gw="$(l1w_find game "$g" 2>/dev/null)" || continue
      gp="$(CDPATH= cd -- "$gw" 2>/dev/null && pwd -P)"
      [ -n "$gp" ] && [ "$gp" = "$wp" ] && reason skip "$(t "$WR") is the wrapper of game $g: it is not the Windows Steam's"
    done
    l1w_row steam
    S="$APPS/S734M.app"
    if [ -d "$S" ] && [ "$(l1w_key "$S" L1Role)" = steam ]; then
      sp="$(l1w_key "$S" L1Prefix)"
      if [ -n "$sp" ] && [ "$sp" != "$WR/Contents/SharedSupport/prefix" ]; then
        reason skip "$(t "$S") names another wrapper ($(t "$sp")) than $(t "$WR"): neither is renamed"
      fi
    fi
  fi
fi
if [ "$skip" = 1 ]; then echo "Nothing was renamed."; exit 1; fi

# --- the lock, then the open-files probe
LOCKF="$WR/Contents/SharedSupport/prefix/.launcher.lock"
h="$(readlink "$LOCKF" 2>/dev/null)"
if [ -n "$h" ] && kill -0 "$h" 2>/dev/null && [ "$h" != "$HELD" ]; then
  reason stop "a launch or an install is using $WHAT (process $h). Wait for it to finish."
  echo "Nothing was renamed."; exit 3
fi
o="$(probe "$WR")"
if [ -n "$o" ]; then
  o="$(echo $o)"
  if [ "$ROLE" = steam ]; then
    reason skip "Steam is open in $WHAT (process $o): it keeps its old name this run, and the next setup run renames it"
  elif [ "$HSKIP" = 1 ]; then
    reason skip "something of the wrapper's Wine is still running (process $o): it keeps its old name this run, and the next setup run renames it. If that is your own Steam, quit it and open the installer again"
  else
    reason stop "the game or Steam is using $WHAT (process $o). Quit the game and Steam, or wait for them to finish."
    echo "Nothing was renamed."; exit 3
  fi
  echo "Nothing was renamed."; exit 1
fi

# --- the rename: the marker first, with L1RenamePending, so that no moment has a wrapper under a new name unmarked
OB="$(basename "$WR" .app)"; NB="$(basename "$NEW" .app)"; MID="${ID:--}"
if [ "$RENAME" = 0 ]; then   # part-way under a name that is not an old one: tidy the marker, keep the name
  if [ "$DRY" = 1 ]; then echo "  would finish: $(t "$WR") (its name is kept)"; exit 0; fi
  l1w_mark "$WR" "$ROLE" "$MID" 0 2>&1 | sed 's/^/  not finished: /'
  l1w_pending "$WR" && { echo "The next setup run finishes it."; exit 2; }
  echo "  finished: $(t "$WR") (its name is kept)"; exit 0
fi
if [ "$DRY" = 1 ]; then echo "  would move: $(t "$WR") -> $(t "$NEW")"; exit 0; fi
if [ "$STATE" = old ]; then
  e="$(l1w_mark "$WR" "$ROLE" "$MID" 1 "$OB" "$NB" 2>&1)" || { reason skip "$e"; echo "Nothing was renamed."; exit 1; }
fi
mv_q "$WR" "$NEW" || {
  echo "  not moved: $(t "$WR") -> $(t "$NEW")${MV_ERR:+ ($MV_ERR)}"
  echo "It is marked under its old name, and every script finds it there. The next setup run renames it."; exit 2; }
[ "${L1_WMOVE_STOP_AFTER:-}" = rename ] && exit 2
if ! e="$(l1w_mark "$NEW" "$ROLE" "$MID" 0 "$OB" "$NB" 2>&1)"; then
  echo "  moved: $(t "$WR") -> $(t "$NEW")"
  echo "  not finished: $e"; echo "The next setup run finishes it."; exit 2
fi
echo "  moved: $(t "$WR") -> $(t "$NEW")"
exit 0
