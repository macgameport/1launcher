#!/bin/bash
# wrappers.sh: the one place that holds the rule for finding a game's Wine wrapper and for naming one
# (docs/plans/wrapper-names.md, 3.1 to 3.3). A wrapper is found by a marker in its Contents/Info.plist:
# L1Role (game-wrapper or steam-wrapper), L1SteamAppID (a game-wrapper's Steam app ID) and, only while a
# rename is under way, L1RenamePending. Its file name is a label.
#
#   . wrappers.sh            defines the l1w_* functions (exports nothing; safe under set -eu, and to source twice)
#   bash wrappers.sh find game <app ID>        the path of that game's wrapper
#   bash wrappers.sh find steam                the Windows Steam's wrapper
#   bash wrappers.sh name game <app ID>        the file name a new wrapper of that game is given
#   bash wrappers.sh name steam                the same, for the Windows Steam's
#   bash wrappers.sh list                      every marked wrapper: role, app ID, path with ~
#   bash wrappers.sh incomplete game <app ID>  the app at the game's first old name, when it has no prefix
#
# find exits 0 with one path, 1 with none, and 2 when two wrappers carry the same marker (both named on
# standard error, nothing on standard output). Every caller treats 2 as a stop of its own, never as "none".
# Test variable: L1_SYSTEM_APPS, the system's Applications folder (default /Applications).
#
# This file is the only place in the code that spells a wrapper's old name (common/test-wrappers.sh, WT12).

L1W_PROGRAM_CS2="drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II/Cities2.exe"
L1W_PROGRAM_SM="drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"

# The table: one row per game, and one for the Windows Steam. Sets L1W_VAR (the game's variable, empty for
# the Windows Steam), L1W_OLD (the old names in today's order, one per line, each a path) and L1W_PROGRAM
# (the game's program under the prefix, empty for the Windows Steam). Returns 1 for a game it does not know.
l1w_row() {   # <role> [<app ID>]
  local sys="${L1_SYSTEM_APPS:-/Applications}"
  L1W_VAR=""; L1W_OLD=""; L1W_PROGRAM=""
  case "$1:${2:-}" in
    game:949230)
      L1W_VAR=CS2_WRAPPER
      L1W_OLD="$HOME/Applications/CS2dxmt11.app
$HOME/Applications/CS2.app
$sys/CS2dxmt11.app"
      L1W_PROGRAM="$L1W_PROGRAM_CS2" ;;
    game:3215050)
      L1W_VAR=SM_WRAPPER
      L1W_OLD="$HOME/Applications/SurvivingMars.app"
      L1W_PROGRAM="$L1W_PROGRAM_SM" ;;
    steam:)
      L1W_OLD="$HOME/Applications/CS2dxmt11-pk110.app" ;;
    *) return 1 ;;
  esac
  return 0
}
l1w_games() { echo 949230; echo 3215050; }   # the app IDs of the table's games
l1w_tilde() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
l1w_key() { plutil -extract "$2" raw -o - "$1/Contents/Info.plist" 2>/dev/null; }   # <app> <key>
l1w_role() {   # <role>: the marker's value for a role
  case "$1" in game) echo game-wrapper ;; steam) echo steam-wrapper ;; *) return 1 ;; esac
}
l1w_marked() {   # <app> <role> [<app ID>]: 0 when the app carries the marker of that role and app ID
  [ "$(l1w_key "$1" L1Role)" = "$(l1w_role "$2")" ] || return 1
  [ "$2" = steam ] && return 0
  [ "$(l1w_key "$1" L1SteamAppID)" = "${3:-}" ]
}
l1w_pending() { local v; v="$(l1w_key "$1" L1RenamePending)" || return 1; [ "$v" != false ]; }   # <app>: the key is there
l1w_program() { [ -n "${2:-}" ] && [ -f "$1/Contents/SharedSupport/prefix/$2" ]; }   # <app> <program>

# The tests of a candidate (3.2), all but the marker. They judge the bundle folder itself and nothing inside
# it: an installer-made wrapper has Contents and its prefix writable by all, and is still a candidate.
# Prints the first test the app fails and returns 1; prints nothing and returns 0 when it passes.
l1w_fails() {   # <app>
  local a="$1" m
  if [ -L "$a" ]; then echo "a symlink"; return 1; fi
  if [ ! -d "$a" ]; then echo "not a folder"; return 1; fi
  case "$a" in *.app) ;; *) echo "not named *.app"; return 1 ;; esac
  if [ "$(dirname "$a")" != "$HOME/Applications" ]; then echo "not a direct child of ~/Applications"; return 1; fi
  if [ "$(stat -f %u "$a")" != "$(id -u)" ]; then echo "not yours"; return 1; fi
  m="$(stat -f %Lp "$a")"
  case "$m" in *[2367]?|*[2367]) echo "writable by group or others"; return 1 ;; esac
  if [ ! -d "$a/Contents/SharedSupport/prefix" ]; then echo "no prefix"; return 1; fi
  if [ ! -x "$a/Contents/SharedSupport/wine/bin/wine64" ]; then echo "no wine64"; return 1; fi
  if xattr -p com.apple.quarantine "$a" >/dev/null 2>&1; then echo "quarantined"; return 1; fi
  return 0
}

# Step 2: the direct children of ~/Applications that carry the marker and pass every test. Sets L1W_HITS
# (one path per line) and L1W_COUNT.
l1w_by_marker() {   # <role> [<app ID>]
  local a
  L1W_HITS=""; L1W_COUNT=0
  for a in "$HOME/Applications"/*.app; do
    [ -e "$a" ] || [ -L "$a" ] || continue
    l1w_marked "$a" "$1" "${2:-}" || continue
    l1w_fails "$a" >/dev/null || continue
    L1W_HITS="${L1W_HITS:+$L1W_HITS
}$a"; L1W_COUNT=$((L1W_COUNT + 1))
  done
}
l1w_dup() {   # <role> [<app ID>]: the duplicates lines, on standard error
  local what="the Windows Steam" a
  [ "$1" = game ] && what="game $2"
  echo "Two wrappers carry the marker of $what:" >&2
  while IFS= read -r a; do echo "  $(l1w_tilde "$a")" >&2; done <<< "$L1W_HITS"
  if [ -n "$L1W_VAR" ]; then echo "Move one to the Trash, or name the one to use in $L1W_VAR." >&2
  else echo "Move one to the Trash." >&2; fi
}

l1w_find() {   # <role> [<app ID>]: prints the wrapper's path; 0 found, 1 none, 2 two marked alike
  local role="$1" id="${2:-}" v a
  l1w_role "$role" >/dev/null || { echo "wrappers.sh: unknown role: $role" >&2; return 1; }
  l1w_row "$role" "$id" || { L1W_VAR=""; L1W_OLD=""; L1W_PROGRAM=""; }
  # 1. a wrapper named by the player, taken as it is
  if [ -n "$L1W_VAR" ]; then
    v="${!L1W_VAR:-}"
    if [ -n "$v" ]; then printf '%s\n' "${v%/}"; return 0; fi
  fi
  # 2. the marker
  l1w_by_marker "$role" "$id"
  if [ "$L1W_COUNT" = 1 ]; then printf '%s\n' "$L1W_HITS"; return 0; fi
  if [ "$L1W_COUNT" -gt 1 ]; then l1w_dup "$role" "$id"; return 2; fi
  # 3. no marked wrapper: the old names, in today's order, each wanted with a prefix. An app that carries a
  #    marker of another role or app ID is not this one.
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    [ -d "$a/Contents/SharedSupport/prefix" ] || continue
    if [ -n "$(l1w_key "$a" L1Role)" ] && ! l1w_marked "$a" "$role" "$id"; then continue; fi
    printf '%s\n' "$a"; return 0
  done <<< "$L1W_OLD"
  # 4. a game only: the app in ~/Applications that holds the game's program, with every test of a candidate
  #    but the marker. An app that carries any marker is passed over: one of this game's own was judged at
  #    step 2, and one of another role or app ID is not this game's (a store wrapper cloned by hand).
  if [ "$role" = game ] && [ -n "$L1W_PROGRAM" ]; then
    for a in "$HOME/Applications"/*.app; do
      l1w_program "$a" "$L1W_PROGRAM" || continue
      l1w_fails "$a" >/dev/null || continue
      [ -z "$(l1w_key "$a" L1Role)" ] || continue
      printf '%s\n' "$a"; return 0
    done
  fi
  return 1
}

l1w_name() {   # <role> [<app ID>]: the file name a new wrapper is given (3.3)
  case "$1" in
    game) case "${2:-}" in ''|*[!0-9]*) echo "wrappers.sh: name game needs a Steam app ID" >&2; return 1 ;; esac
          echo "wrapper-$2.app" ;;
    steam) echo "wrapper-0.app" ;;
    *) echo "wrappers.sh: unknown role: $1" >&2; return 1 ;;
  esac
}

l1w_incomplete() {   # game <app ID>: the game's first old name in ~/Applications, when a folder with no prefix
  local first
  [ "$1" = game ] && l1w_row game "${2:-}" || return 1
  first="$(printf '%s\n' "$L1W_OLD" | head -n 1)"
  case "$first" in "$HOME/Applications/"*) ;; *) return 1 ;; esac
  if [ -d "$first" ] && [ ! -d "$first/Contents/SharedSupport/prefix" ]; then printf '%s\n' "$first"; return 0; fi
  return 1
}

l1w_list() {   # every marked wrapper: role, app ID, path with ~; one that is passed over names the test it failed
  local a role id why note
  for a in "$HOME/Applications"/*.app "$HOME/Applications"/*/*.app; do
    [ -e "$a" ] || [ -L "$a" ] || continue
    case "$(dirname "$a")" in *.app) continue ;; esac   # inside another bundle
    role="$(l1w_key "$a" L1Role)"
    if [ -z "$role" ]; then
      [ -f "$a/Contents/Info.plist" ] && ! plutil -lint -s "$a/Contents/Info.plist" >/dev/null 2>&1 \
        && grep -q 'L1Role' "$a/Contents/Info.plist" 2>/dev/null \
        && echo "? - $(l1w_tilde "$a")  (passed over: its Info.plist does not parse)"
      continue
    fi
    case "$role" in
      game-wrapper|steam-wrapper) ;;
      *) [ -d "$a/Contents/SharedSupport/prefix" ] || continue   # an app meant to be clicked, not a wrapper
         echo "$role - $(l1w_tilde "$a")  (passed over: L1Role $role is not a wrapper's)"; continue ;;
    esac
    id="-"; [ "$role" = game-wrapper ] && id="$(l1w_key "$a" L1SteamAppID)"
    note=""
    if [ "$role" = game-wrapper ] && case "$id" in ''|*[!0-9]*) true ;; *) false ;; esac; then
      note="  (passed over: no Steam app ID)"; id="-"
    elif why="$(l1w_fails "$a")"; then :
    else note="  (passed over: $why)"
    fi
    l1w_pending "$a" && note="$note  (rename pending)"
    echo "$role $id $(l1w_tilde "$a")$note"
  done
  return 0
}

# One write of the marker (3.1): the keys are put into a copy of Info.plist in the same folder, the copy takes
# the original's mode, is linted, and is renamed over the original. When <old base> and <new base> are given
# and CFBundleName equals the old base, it becomes the new base in that same write. CFBundleIdentifier is never
# touched. Returns 1, with one line on standard error, when Info.plist is missing, does not parse or cannot be
# written.
l1w_mark() {   # <app> <role> <app ID or -> <pending: 1 or 0> [<old base> <new base>]
  local app="$1" role id="$3" pend="$4" p tmp
  role="$(l1w_role "$2")" || { echo "wrappers.sh: unknown role: $2" >&2; return 1; }
  p="$app/Contents/Info.plist"
  [ -f "$p" ] || { echo "$(l1w_tilde "$app") has no Info.plist" >&2; return 1; }
  plutil -lint -s "$p" >/dev/null 2>&1 || { echo "$(l1w_tilde "$app")'s Info.plist does not parse" >&2; return 1; }
  tmp="$app/Contents/.Info.plist.l1w.$$"
  cp -p "$p" "$tmp" 2>/dev/null || { echo "$(l1w_tilde "$app")'s Info.plist cannot be written" >&2; rm -f "$tmp"; return 1; }
  if plutil -replace L1Role -string "$role" "$tmp" 2>/dev/null \
     && { if [ "$2" = game ]; then plutil -replace L1SteamAppID -integer "$id" "$tmp"
          else plutil -remove L1SteamAppID "$tmp" >/dev/null 2>&1 || true; fi; } \
     && { if [ "$pend" = 1 ]; then plutil -replace L1RenamePending -bool true "$tmp"
          else plutil -remove L1RenamePending "$tmp" >/dev/null 2>&1 || true; fi; } \
     && { [ -z "${5:-}" ] || [ "$(plutil -extract CFBundleName raw -o - "$tmp" 2>/dev/null)" != "$5" ] \
          || plutil -replace CFBundleName -string "$6" "$tmp"; } \
     && plutil -lint -s "$tmp" >/dev/null 2>&1 \
     && chmod "$(stat -f %Lp "$p")" "$tmp" \
     && mv -f "$tmp" "$p" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp"
  echo "$(l1w_tilde "$app")'s Info.plist cannot be written" >&2
  return 1
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  case "${1:-}" in
    find) shift; l1w_find "$@"; exit $? ;;
    name) shift; l1w_name "$@"; exit $? ;;
    list) l1w_list; exit $? ;;
    incomplete) shift; l1w_incomplete "$@"; exit $? ;;
    *) echo "usage: bash wrappers.sh find|name game <app ID> | find|name steam | list | incomplete game <app ID>" >&2; exit 2 ;;
  esac
fi
