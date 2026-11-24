#!/bin/bash
# check-deploy.sh: cmp of what Cities: Skylines II's setup copies against the runtime folder (CS2_DATA of
# common/paths.sh; docs/plans/local-files-layout.md, LT4). Its list is its own: the launcher, repatch.sh, the
# display-profile helper, wrappers.sh (docs/plans/wrapper-names.md, 3.2), every patches/*.py, the badge script only
# when a copy is installed, and patches/_vendor as a tree; and of the record of versions
# (docs/plans/built-in-update.md, 3.3) the tool in L1_UPDATE_DIR and, beside the launcher, the line update-dir that
# names that folder. Markers and other files in the folder are not counted.
# Prints "<found> found, <identical> identical of <n>"; exit 0 only when the three are equal and _vendor is the same.
set -u
TOP="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"; G="$TOP/cities-skylines-2"
. "$TOP/common/paths.sh"
n=0; found=0; same=0; vendor=same
one() {   # <repo file> <deployed name> [<the deployed file, when it is not in the runtime folder>]
  local d="${3:-$CS2_DATA/$2}"
  n=$((n+1)); [ -f "$d" ] || { echo "  absent:  $2"; return; }
  found=$((found+1)); if cmp -s "$1" "$d"; then same=$((same+1)); else echo "  differs: $2"; fi
}
one "$G/launchers/launch-cs2-dxmt11.sh" launch-cs2-dxmt11.sh
one "$G/repatch.sh" repatch.sh
one "$G/scripts/cs2-display-profile.sh" cs2-display-profile.sh
one "$TOP/common/wrappers.sh" wrappers.sh
one "$TOP/common/updates.sh" _update/updates.sh "$L1_UPDATE_DIR/updates.sh"
one <(printf '%s\n' "$L1_UPDATE_DIR") update-dir
for f in "$G"/patches/*.py; do one "$f" "patches/$(basename "$f")"; done
[ -f "$CS2_DATA/patch-modconflict-badge.py" ] && one "$G/scripts/patch-modconflict-badge.py" patch-modconflict-badge.py
diff -rq "$G/patches/_vendor" "$CS2_DATA/patches/_vendor" >/dev/null 2>&1 || { vendor=differs; echo "  differs: patches/_vendor"; }
echo "$found found, $same identical of $n"
[ "$found" = "$n" ] && [ "$same" = "$n" ] && [ "$vendor" = same ]
