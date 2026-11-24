#!/bin/bash
# move-install.sh: move an install made before the folders moved out of the home folder
# (docs/plans/local-files-layout.md, 3.4). setup.sh runs it; it can be run alone.
#
#   bash scripts/move-install.sh [--dry-run] [--lock <path> [--held-by <pid>]]
#
#   --dry-run     print the reasons and the moves, change nothing, and exit as the real run would: 0, 1 or 3
#   --lock        the launch lock to read (default: the lock of the wrapper setup would choose, by
#                 common/wrappers.sh, when it has a prefix)
#   --held-by     a process whose hold on that lock is let through (the installer that called setup)
#
# Its output is an interface: setup.sh relays it and reads it. Line 1 is "state: none" (nothing to move; no
# other line follows), "state: old" (the old folder is there, real or a symlink) or "state: part-way" (an
# earlier move stopped between its two steps). Then lines indented by two spaces: "stop: ..." or "skip: ..."
# per reason, "would move: A -> B" (dry run) or "moved: A -> B" per move ("not moved: A" for one that failed),
# and "left in the workspace: <name>" for a runtime name both folders hold. Then closing lines that are not indented. Every path is printed with
# the home folder as ~.
#
# Exit: 0 moved, finished an earlier move, or nothing to move · 1 skipped: nothing moved, every reason printed ·
# 2 stopped part-way · 3 stop: nothing moved, and setup must not go on (a script of the old folder is running,
# or a launch or an install is using the wrapper).
# For its tests: L1_MOVE_PROBE=<program> replaces the two lsof calls and the volume read (`<program> open
# <files...>` and `<program> cwd <folder>` print one process per line; `<program> dev <folder>` prints the
# folder's volume), and L1_MOVE_STOP_AFTER=rename stops it after the first rename.
set -u
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
PATHS="$HERE/../../common/paths.sh"
[ -f "$PATHS" ] || { echo "move-install.sh: common/paths.sh is not in this checkout"; exit 1; }
. "$PATHS"
DRY=0; LOCK=""; HELD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --lock) LOCK="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
    --held-by) HELD="${2:-}"; shift; [ $# -gt 0 ] && shift ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
done
OLD="$HOME/cs2-patch"
DATA="$L1_DATA_ROOT/cities-skylines-2"
WORK="$L1_WORK_ROOT/cities-skylines-2"
tilde() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
is_runtime() {
  case "$1" in launch-cs2-dxmt11.sh|launch-cs2.sh|repatch.sh|cs2-display-profile.sh|patch-modconflict-badge.py|wrappers.sh|patches|revenv|launch-cs2*.sh.bak) return 0 ;; esac
  return 1
}
own_folder() {   # as surviving-mars-relaunched/scripts/setup.sh has it
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -f %u "$1")" = "$(id -u)" ] || return 1
  case "$(stat -f %Lp "$1")" in *[2367]?|*[2367]) return 1 ;; esac
  return 0
}
# lsof exits 1 when any of several files is not open, so its output is read and not its exit code
probe_open() { if [ -n "${L1_MOVE_PROBE:-}" ]; then "$L1_MOVE_PROBE" open "$@"; else lsof -t -- "$@" 2>/dev/null; fi; }
probe_cwd() {
  if [ -n "${L1_MOVE_PROBE:-}" ]; then "$L1_MOVE_PROBE" cwd "$1"
  else lsof -a -d cwd -u "$(id -u)" -Fpn 2>/dev/null | awk -v d="$1" '/^p/ { p = substr($0, 2) } /^n/ { n = substr($0, 2); if (n == d || index(n, d "/") == 1) print p }'; fi
}
probe_dev() { if [ -n "${L1_MOVE_PROBE:-}" ]; then "$L1_MOVE_PROBE" dev "$1"; else stat -f %d "$1"; fi; }
names() { ls -A "$1" 2>/dev/null; }
mv_q() {   # <from> <to>: mv, its own words kept in MV_ERR with the home folder as ~
  local e t='~'
  MV_ERR=""; e="$(mv "$1" "$2" 2>&1)" && return 0
  MV_ERR="${e//$HOME/$t}"; return 1
}
not_renamed() { echo "  skip: $(tilde "$OLD") could not be renamed${MV_ERR:+ ($MV_ERR)}"; echo "Nothing was moved."; exit 1; }
make_root() { [ -d "$1" ] || { mkdir -p "$1" && chmod go-w "$1"; }; }
# setup copies in place, and cp over a file that exists keeps that file's mode: no file of the runtime folder
# stays writable by group or others (macOS's chmod -R follows no symlink)
close_modes() { chmod -R go-w "$DATA" 2>/dev/null; return 0; }
lift() {   # <from> <to>: move the runtime names; one already in <to> is left in <from> and named
  local n rc=0
  if [ "$DRY" = 0 ]; then make_root "$L1_DATA_ROOT" && { [ -d "$2" ] || { mkdir "$2" && chmod go-w "$2"; }; } || return 1; fi
  while IFS= read -r n; do
    [ -n "$n" ] && is_runtime "$n" || continue
    if [ -e "$2/$n" ] || [ -L "$2/$n" ]; then echo "  left in the workspace: $n"; continue; fi
    if [ "$DRY" = 1 ]; then echo "  would move: $(tilde "$1/$n") -> $(tilde "$2/$n")"
    elif mv_q "$1/$n" "$2/$n"; then echo "  moved: $(tilde "$1/$n") -> $(tilde "$2/$n")"
    else echo "  not moved: $(tilde "$1/$n")${MV_ERR:+ ($MV_ERR)}"; rc=1; fi
  done <<LIST
$(names "$1")
LIST
  return $rc
}
finish_line() { echo "Stopped part-way. To finish the move, run:  bash scripts/move-install.sh"; }
last_line() { [ "$DRY" = 1 ] || echo "Now run:  bash scripts/setup.sh"; }
stop=0; skip=0
reason() { echo "  $1: $2"; if [ "$1" = stop ]; then stop=1; else skip=1; fi; }
lock_reason() {
  local l="$LOCK" h w="" x
  if [ -z "$l" ]; then   # run by hand: the wrapper setup would choose, or none
    x="$HERE/../../common/wrappers.sh"
    [ -f "$x" ] && w="$(bash "$x" find game 949230 2>/dev/null)" && [ -d "$w/Contents/SharedSupport/prefix" ] || w=""
    [ -n "$w" ] || return 0
    l="$w/Contents/SharedSupport/prefix/.launcher.lock"
  fi
  h="$(readlink "$l" 2>/dev/null)"
  if [ -n "$h" ] && kill -0 "$h" 2>/dev/null && [ "$h" != "$HELD" ]; then
    reason stop "a launch or an install is using the game's wrapper (process $h). Wait for it to finish."
  fi
}
verdict() {   # exits 3 or 1 when a reason was printed
  if [ "$stop" = 1 ]; then echo "Nothing was moved."; exit 3; fi
  if [ "$skip" = 1 ]; then echo "Nothing was moved."; exit 1; fi
}

if [ ! -e "$OLD" ] && [ ! -L "$OLD" ]; then
  # part-way: no old folder, the workspace a real folder, and in it a runtime name that the runtime folder lacks
  part=0
  if [ -d "$WORK" ] && [ ! -L "$WORK" ]; then while IFS= read -r n; do
    [ -n "$n" ] && is_runtime "$n" && [ ! -e "$DATA/$n" ] && [ ! -L "$DATA/$n" ] && part=1
  done <<LIST
$(names "$WORK")
LIST
  fi
  if [ "$part" = 0 ]; then echo "state: none"; exit 0; fi
  echo "state: part-way"
  # a finishing run looks for three things only: a set root, the two folders being the user's own, and the lock
  [ "$L1_ROOTS_SET" = 1 ] && reason skip "a root is set away from its default"
  for d in "$L1_DATA_ROOT" "$DATA"; do
    if [ -e "$d" ] || [ -L "$d" ]; then own_folder "$d" || reason skip "$(tilde "$d") is not a folder of your own that only you can write to"; fi
  done
  lock_reason; verdict
  lift "$WORK" "$DATA" || { finish_line; exit 2; }
  [ "$DRY" = 1 ] || close_modes
  last_line; exit 0
fi
echo "state: old"

# --- reasons not to move; nothing is moved while looking
if [ -L "$OLD" ]; then reason skip "$(tilde "$OLD") is a symlink"
else
  # a script running from the top of the old folder (a launcher, a repatch.sh run by hand): setup would copy
  # over a file that bash is still reading. With no *.sh there, the probe is not called.
  shs=()
  for f in "$OLD"/*.sh; do [ -f "$f" ] && [ ! -L "$f" ] && shs+=("$f"); done
  if [ "${#shs[@]}" -gt 0 ]; then
    o="$(probe_open "${shs[@]}")"
    [ -n "$o" ] && reason stop "a script is running from $(tilde "$OLD") (process $(echo $o)): the game's launcher, or repatch.sh. Quit the game and Steam, or wait for it to finish."
  fi
fi
lock_reason
if [ ! -L "$OLD" ]; then
  OLDP="$(CDPATH= cd -- "$OLD" && pwd -P)"
  c="$(probe_cwd "$OLDP")"
  [ -n "$c" ] && reason skip "a process has its working directory inside $(tilde "$OLD") (process $(echo $c)). Close it, or cd out of the folder."
fi
for d in "$DATA" "$WORK"; do
  if [ -e "$d" ] || [ -L "$d" ]; then reason skip "$(tilde "$d") is already there"; fi
done
for d in "$L1_DATA_ROOT" "$L1_WORK_ROOT"; do
  if [ -L "$d" ]; then reason skip "$(tilde "$d") is a symlink"
  elif [ -e "$d" ]; then own_folder "$d" || reason skip "$(tilde "$d") is not a folder of your own that only you can write to"; fi
done
if [ ! -L "$OLD" ]; then
  while IFS= read -r n; do
    [ -n "$n" ] && is_runtime "$n" && [ -L "$OLD/$n" ] && reason skip "$(tilde "$OLD/$n") is a symlink"
  done <<LIST
$(names "$OLD")
LIST
  parent() { local p="$1"; while [ ! -d "$p" ]; do p="$(dirname "$p")"; done; printf '%s' "$p"; }
  dv="$(probe_dev "$OLD")"
  for t in "$DATA" "$WORK"; do
    [ "$(probe_dev "$(parent "$t")")" = "$dv" ] || reason skip "$(tilde "$t") would be on another volume than $(tilde "$OLD")"
  done
  case "$HERE/" in "$OLDP"/*) reason skip "this checkout is inside $(tilde "$OLD")" ;; esac
fi
[ "$L1_ROOTS_SET" = 1 ] && reason skip "a root is set away from its default"
verdict

# --- the move
other=0
while IFS= read -r n; do [ -z "$n" ] || [ "$n" = .DS_Store ] || is_runtime "$n" || other=1; done <<LIST
$(names "$OLD")
LIST
if [ "$other" = 0 ]; then   # nothing but runtime names: one rename, and no workspace
  if [ "$DRY" = 1 ]; then echo "  would move: $(tilde "$OLD") -> $(tilde "$DATA")"; exit 0; fi
  MV_ERR=""; make_root "$L1_DATA_ROOT" && mv_q "$OLD" "$DATA" || not_renamed
  echo "  moved: $(tilde "$OLD") -> $(tilde "$DATA")"
  close_modes; last_line; exit 0
fi
if [ "$DRY" = 1 ]; then
  echo "  would move: $(tilde "$OLD") -> $(tilde "$WORK")"
  lift "$OLD" "$DATA"; exit 0
fi
MV_ERR=""; make_root "$L1_DATA_ROOT" && make_root "$L1_WORK_ROOT" && mv_q "$OLD" "$WORK" || not_renamed
echo "  moved: $(tilde "$OLD") -> $(tilde "$WORK")"
[ "${L1_MOVE_STOP_AFTER:-}" = rename ] && { finish_line; exit 2; }
lift "$WORK" "$DATA" || { finish_line; exit 2; }
close_modes
last_line; exit 0
