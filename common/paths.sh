#!/bin/bash
# paths.sh: the one place that holds the rule for where this project keeps its files outside the repo
# (docs/plans/local-files-layout.md, 3.1 and 3.3).
#
#   . common/paths.sh       sets L1_DATA_ROOT L1_WORK_ROOT CS2_DATA CS2_WORK SM_STATE SM_WORK L1_UPDATE_DIR, and
#                           L1_ROOTS_SET (exports nothing; safe under set -eu, and to source twice)
#   bash common/paths.sh    prints the seven folders as KEY=value lines (not L1_ROOTS_SET)
#
# Overrides: L1_DATA_ROOT, L1_WORK_ROOT (the two roots), CS2_PATCH_DIR (CS2_DATA), CS2_WORK_DIR (CS2_WORK),
# SM_STATE, SM_WORK, L1_UPDATE_DIR (the record of which version each game was set up from and which is on
# offer: <data root>/_update, docs/plans/built-in-update.md 3.1; its name starts with _, which no game's
# folder can). An install made before the move keeps working where it is: while the new runtime folder
# does not exist, the old folder is a real folder, and neither root is set to something other than its default,
# CS2_DATA and CS2_WORK are both the old folder. L1_ROOTS_SET is 1 when a root is set away from its default
# (setup.sh and move-install.sh read it, so that neither spells a default itself).
_l1_data_default="$HOME/Library/Application Support/1launcher"
_l1_work_default="$HOME/Library/Developer/1launcher"
_l1_old="$HOME/cs2-patch"
L1_DATA_ROOT="${L1_DATA_ROOT:-$_l1_data_default}"
L1_WORK_ROOT="${L1_WORK_ROOT:-$_l1_work_default}"
L1_ROOTS_SET=0
if [ "$L1_DATA_ROOT" != "$_l1_data_default" ] || [ "$L1_WORK_ROOT" != "$_l1_work_default" ]; then L1_ROOTS_SET=1; fi
_l1_cs2_data="$L1_DATA_ROOT/cities-skylines-2"
_l1_cs2_work="$L1_WORK_ROOT/cities-skylines-2"
if [ ! -e "$_l1_cs2_data" ] && [ -d "$_l1_old" ] && [ ! -L "$_l1_old" ] && [ "$L1_ROOTS_SET" = 0 ]; then
  _l1_cs2_data="$_l1_old"; _l1_cs2_work="$_l1_old"
fi
CS2_DATA="${CS2_PATCH_DIR:-$_l1_cs2_data}"
CS2_WORK="${CS2_WORK_DIR:-$_l1_cs2_work}"
SM_STATE="${SM_STATE:-$L1_DATA_ROOT/surviving-mars-relaunched}"
SM_WORK="${SM_WORK:-$L1_WORK_ROOT/surviving-mars-relaunched}"
L1_UPDATE_DIR="${L1_UPDATE_DIR:-$L1_DATA_ROOT/_update}"
case "$CS2_WORK" in *" "*) _l1_t='~'; echo "paths.sh: WARNING: the workspace path has a space in it: ${CS2_WORK/#$HOME/$_l1_t}" >&2; unset _l1_t ;; esac
unset _l1_data_default _l1_work_default _l1_old _l1_cs2_data _l1_cs2_work
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  for _k in L1_DATA_ROOT L1_WORK_ROOT CS2_DATA CS2_WORK SM_STATE SM_WORK L1_UPDATE_DIR; do printf '%s=%s\n' "$_k" "${!_k}"; done
fi
