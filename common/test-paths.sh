#!/bin/bash
# test-paths.sh -- common/paths.sh, the .command wrapper's inline copy of its rule, and every other spelling of
# a root (docs/plans/local-files-layout.md, LT1, LT2, LT14 and the first half of LT15). No game, no Wine; scratch
# homes only.
#   bash common/test-paths.sh    exit 0 = every case passed
#   MUTANT=1 ...  the old-install test inverted; must exit 1
#   MUTANT=2 ...  any set root counts as set, its own default too; must exit 1
#   MUTANT=3 ...  the folder's name changed in the .command wrapper; must exit 1
#   MUTANT=4 ...  L1_ROOTS_SET is among the printed lines; must exit 1
# LT14's two mutants and LT15's change a tracked file (one inline spelling; a root spelled in one more script;
# one script's evidence folder joined to $CS2_DATA), so they are applied by hand and not here.
set -u
REPO="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
T="$(mktemp -d /tmp/test-paths.XXXXXX)"; trap 'rm -rf "$T"' EXIT
# the two files under test, as scratch copies, so that a mutant never touches the checkout
P="$T/paths.sh"; cp "$REPO/common/paths.sh" "$P"
C="$T/wrapper.command"; cp "$REPO/cities-skylines-2/launchers/Cities Skylines II (DXMT Wine 11).command" "$C"
mutate() { perl -0pi -e "$1" "$3"; grep -q -- "$2" "$3" || { echo "REFUSED: mutant did not apply"; exit 2; }; }
case "${MUTANT:-0}" in
  1) mutate 's/ && \[ -d "\$_l1_old" \] && / \&\& [ ! -d "\$_l1_old" ] \&\& /' ' && \[ ! -d "\$_l1_old" \] && ' "$P" ;;
  2) mutate 's/\nL1_DATA_ROOT="\$\{L1_DATA_ROOT:-\$_l1_data_default\}"\n/\n_l1_any="\${L1_DATA_ROOT+x}\${L1_WORK_ROOT+x}"\nL1_DATA_ROOT="\${L1_DATA_ROOT:-\$_l1_data_default}"\n/; s/\nL1_ROOTS_SET=0\n[^\n]*\n/\nL1_ROOTS_SET=0\n[ -n "\$_l1_any" ] \&\& L1_ROOTS_SET=1\n/' '^\[ -n "\$_l1_any" \] && L1_ROOTS_SET=1$' "$P" ;;
  3) mutate 's/1launcher\/cities-skylines-2"/1launcher\/cities-skylines-two"/' 'cities-skylines-two"' "$C" ;;
  4) mutate 's/for _k in L1_DATA_ROOT /for _k in L1_ROOTS_SET L1_DATA_ROOT /' 'for _k in L1_ROOTS_SET ' "$P" ;;
esac
pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1"; echo "   got:  $2"; echo "   want: $3"; fi; }
CLEAN="env -u L1_DATA_ROOT -u L1_WORK_ROOT -u CS2_PATCH_DIR -u CS2_WORK_DIR -u SM_STATE -u SM_WORK -u CS2_DATA -u CS2_WORK -u L1_ROOTS_SET -u L1_UPDATE_DIR"
AS="Library/Application Support/1launcher"; DV="Library/Developer/1launcher"
get() { h="$1"; k="$2"; shift 2; $CLEAN HOME="$h" "$@" bash "$P" 2>/dev/null | sed -n "s/^$k=//p"; }
state() {   # <home> [env...]: CS2_DATA|CS2_WORK with the home as ~
  h="$1"; shift; d="$(get "$h" CS2_DATA "$@")"; w="$(get "$h" CS2_WORK "$@")"
  printf '%s|%s' "~${d#"$h"}" "~${w#"$h"}"
}
NEW="~/$AS/cities-skylines-2|~/$DV/cities-skylines-2"; OLD="~/cs2-patch|~/cs2-patch"
# --- LT1
h="$T/h1"; mkdir -p "$h";                                  check "neither folder: new" "$(state "$h" env)" "$NEW"
h="$T/h2"; mkdir -p "$h/cs2-patch";                        check "only the old folder: old" "$(state "$h" env)" "$OLD"
h="$T/h3"; mkdir -p "$h/$AS/cities-skylines-2";            check "only the new runtime folder: new" "$(state "$h" env)" "$NEW"
h="$T/h4"; mkdir -p "$h/$AS/cities-skylines-2" "$h/cs2-patch"; check "both: new" "$(state "$h" env)" "$NEW"
h="$T/h5"; mkdir -p "$h/$AS/surviving-mars-relaunched" "$h/$DV/surviving-mars-relaunched" "$h/cs2-patch"
check "both roots present with another game's folder, and the old folder: old" "$(state "$h" env)" "$OLD"
h="$T/h6"; mkdir -p "$h/elsewhere"; ln -s "$h/elsewhere" "$h/cs2-patch"; check "the old folder a symlink: new" "$(state "$h" env)" "$NEW"
h="$T/h2"
check "CS2_PATCH_DIR wins for CS2_DATA only" "$(state "$h" env CS2_PATCH_DIR="$h/x y")" "~/x y|~/cs2-patch"
check "CS2_WORK_DIR wins for CS2_WORK only" "$(state "$h" env CS2_WORK_DIR="$h/w")" "~/cs2-patch|~/w"
check "a root set elsewhere turns the old-install rule off" "$(state "$h" env L1_DATA_ROOT="$h/d")" "~/d/cities-skylines-2|~/$DV/cities-skylines-2"
check "the work root set elsewhere does too" "$(state "$h" env L1_WORK_ROOT="$h/w")" "~/$AS/cities-skylines-2|~/w/cities-skylines-2"
check "a root set to its own default does not" "$(state "$h" env L1_DATA_ROOT="$h/$AS")" "$OLD"
check "a root set empty does not" "$(state "$h" env L1_WORK_ROOT=)" "$OLD"
set_() { h="$1"; shift; $CLEAN HOME="$h" "$@" bash -c 'set -eu; . "$1"; echo "$L1_ROOTS_SET"' _ "$P" 2>&1; }
check "L1_ROOTS_SET: 1 for a root set elsewhere, 0 for none, for its own default and for an empty one" \
  "$(set_ "$h" env L1_DATA_ROOT="$h/d")$(set_ "$h" env L1_WORK_ROOT="$h/w")$(set_ "$h" env)$(set_ "$h" env L1_DATA_ROOT="$h/$AS")$(set_ "$h" env L1_WORK_ROOT=)" "11000"
check "L1_ROOTS_SET is never among the printed lines" "$($CLEAN HOME="$h" L1_DATA_ROOT="$h/d" bash "$P" | grep -c 'ROOTS_SET')" 0
for hh in h1 h2; do   # sourced twice in one shell, and again in a child that inherited the values, under set -eu
  out="$($CLEAN HOME="$T/$hh" bash -c 'set -eu; . "$1"; a="$CS2_DATA|$CS2_WORK|$SM_STATE|$SM_WORK"; . "$1"; b="$CS2_DATA|$CS2_WORK|$SM_STATE|$SM_WORK"
     export L1_DATA_ROOT L1_WORK_ROOT CS2_DATA CS2_WORK SM_STATE SM_WORK
     c="$(bash -c "set -eu; . \"\$1\"; echo \"\$CS2_DATA|\$CS2_WORK|\$SM_STATE|\$SM_WORK\"" _ "$1")"
     [ "$a" = "$b" ] && [ "$a" = "$c" ] && [ "$L1_ROOTS_SET" = 0 ] && echo same || { echo "a=$a"; echo "b=$b"; echo "c=$c"; }' _ "$P" 2>&1)"
  check "sourced twice and in a child, under set -eu ($hh)" "$out" same
done
check "sourcing prints nothing and exports nothing" "$($CLEAN HOME="$T/h1" bash -c '. "$1"; env | grep -c "^CS2_DATA=\|^L1_DATA_ROOT="' _ "$P" 2>&1)" "0"
check "run, it prints seven KEY=value lines" "$($CLEAN HOME="$T/h1" bash "$P" | grep -c '^[A-Z0-9_]*=/')" 7
w="$(get "$T/h1" CS2_WORK env)"; s="$(get "$T/h1" SM_WORK env)"
sp=none; case "$w$s" in *" "*) sp=space ;; esac
check "the default CS2_WORK and SM_WORK have no space" "$sp" none
check "a workspace with a space is warned about on stderr" "$($CLEAN HOME="$T/h1" CS2_WORK_DIR="/tmp/a b" bash "$P" 2>&1 >/dev/null | grep -c WARNING)" 1
check "  ...with the home folder as ~" "$($CLEAN HOME="$T/h1" CS2_WORK_DIR="$T/h1/a b" bash "$P" 2>&1 >/dev/null)" "paths.sh: WARNING: the workspace path has a space in it: ~/a b"
h="$T/h1"
check "SM_STATE and SM_WORK at their defaults" "$(get "$h" SM_STATE env)|$(get "$h" SM_WORK env)" "$h/$AS/surviving-mars-relaunched|$h/$DV/surviving-mars-relaunched"
check "SM_STATE and SM_WORK overridden" "$(get "$h" SM_STATE env SM_STATE=/tmp/s)|$(get "$h" SM_WORK env SM_WORK=/tmp/w)" "/tmp/s|/tmp/w"
check "SM_* are outside the old-install rule" "$(get "$T/h2" SM_STATE env)" "$T/h2/$AS/surviving-mars-relaunched"
check "both roots set to scratch folders, in a home with an old install: all seven follow" "$($CLEAN HOME="$T/h2" L1_DATA_ROOT="$T/D" L1_WORK_ROOT="$T/W" bash "$P" | tr '\n' ' ')" \
  "L1_DATA_ROOT=$T/D L1_WORK_ROOT=$T/W CS2_DATA=$T/D/cities-skylines-2 CS2_WORK=$T/W/cities-skylines-2 SM_STATE=$T/D/surviving-mars-relaunched SM_WORK=$T/W/surviving-mars-relaunched L1_UPDATE_DIR=$T/D/_update "
check "L1_UPDATE_DIR at its default, and overridden (docs/plans/built-in-update.md, 3.1)" "$(get "$h" L1_UPDATE_DIR env)|$(get "$h" L1_UPDATE_DIR env L1_UPDATE_DIR=/tmp/u)" "$h/$AS/_update|/tmp/u"

# --- LT2: the .command wrapper, which carries the rule inline
stub() { mkdir -p "$1"; printf '#!/bin/bash\necho "$0"\n' > "$1/launch-cs2-dxmt11.sh"; }
wrap() { h="$1"; shift; $CLEAN HOME="$h" "$@" bash "$C" 2>&1; }
h="$T/c1"; stub "$h/$AS/cities-skylines-2";                          check "wrapper, only the runtime folder: new" "$(wrap "$h" env)" "$h/$AS/cities-skylines-2/launch-cs2-dxmt11.sh"
h="$T/c2"; stub "$h/cs2-patch"; mkdir -p "$h/$AS/surviving-mars-relaunched"; check "wrapper, only the old folder: old" "$(wrap "$h" env)" "$h/cs2-patch/launch-cs2-dxmt11.sh"
h="$T/c3"; stub "$h/cs2-patch"; stub "$h/$AS/cities-skylines-2";      check "wrapper, both: new" "$(wrap "$h" env)" "$h/$AS/cities-skylines-2/launch-cs2-dxmt11.sh"
stub "$T/named";                                                     check "wrapper, CS2_PATCH_DIR set: the named folder" "$(wrap "$T/c2" env CS2_PATCH_DIR="$T/named")" "$T/named/launch-cs2-dxmt11.sh"

# --- LT14: every spelling of a root, in tracked code, is one that paths.sh prints for a home with no install
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  mkdir -p "$T/empty"
  printed="$($CLEAN HOME="$T/empty" bash "$REPO/common/paths.sh" | sed "s#^[A-Z0-9_]*=$T/empty/##")"
  spelled="$(git -C "$REPO" grep -n -e 'Application Support/1launcher' -e 'Developer/1launcher' -- '*.sh' '*.py' '*.command' '*.c' '*.swift' \
    | grep -Ev '^[^:]*:[0-9]+:[[:space:]]*(#|//|\*|/\*)')"
  bad="$(printf '%s\n' "$spelled" | while IFS= read -r line; do
      printf '%s\n' "$line" | grep -Eo 'Library/(Application Support|Developer)/1launcher(/[A-Za-z0-9-]+)?' | while IFS= read -r f; do
        printf '%s\n' "$printed" | grep -qxF "$f" || echo "${line%%:*}: $f"
      done
    done)"
  check "every spelled folder equals a printed value" "$bad" ""
  files="$(printf '%s\n' "$spelled" | sed 's/:[0-9][0-9]*:.*//' | sort -u)"
  cat > "$T/want" <<LIST
cities-skylines-2/launchers/Cities Skylines II (DXMT Wine 11).command
common/mac-inventory.sh
common/paths.sh
common/test-paths.sh
common/test-updates.sh
common/updates.sh
surviving-mars-relaunched/launch-relaunched.sh
surviving-mars-relaunched/patch-window-origin.py
surviving-mars-relaunched/scripts/setup.sh
surviving-mars-relaunched/tools/inject-ab.sh
surviving-mars-relaunched/tools/licence-wait-probe.sh
surviving-mars-relaunched/tools/load-probe.sh
surviving-mars-relaunched/tools/make-engine.sh
surviving-mars-relaunched/tools/split-wrapper.sh
surviving-mars-relaunched/tools/steam-judge.sh
surviving-mars-relaunched/tools/test-mod-notes.sh
LIST
  check "the files that spell a root are the listed sixteen" "$files" "$(cat "$T/want")"
  [ "$files" = "$(cat "$T/want")" ] || printf '%s\n' "$spelled" | cut -c1-160

  # --- LT15: the two folders are not swapped. In tracked shell and Python files, a name joined to $CS2_DATA is
  # a runtime name (the plan's section 2), and a name joined to $CS2_WORK is not. Shell spellings only.
  joins="$(git -C "$REPO" grep -ohE '\$\{?CS2_(DATA|WORK)\}?/[A-Za-z0-9_.-]+' -- '*.sh' '*.command' '*.py' | tr -d '{}' | sort -u)"
  swapped="$(printf '%s\n' "$joins" | while IFS=/ read -r v n; do
      [ -n "$v" ] || continue
      case "$n" in (launch-cs2-dxmt11.sh|launch-cs2.sh|repatch.sh|cs2-display-profile.sh|patch-modconflict-badge.py|wrappers.sh|patches|revenv|launch-cs2*.sh.bak) k='$CS2_DATA' ;; (*) k='$CS2_WORK' ;; esac
      [ "$v" = "$k" ] || echo "$v/$n"
    done)"
  check "no name is joined to the wrong one of CS2_DATA and CS2_WORK" "$swapped" ""
  echo "LT15: $(printf '%s\n' "$joins" | grep -c .) different joins read"
fi
echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
