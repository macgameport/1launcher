#!/bin/bash
# test-setup.sh -- scripts/setup.sh end to end with HOME at a scratch folder: a fake wrapper (a stub wine64,
# empty steam.exe and Cities2.exe), a scratch copy of scripts/, launchers/ and repatch.sh beside stub
# patchers, a stub xcrun so the app builder compiles nothing, and stubs for sw_vers, sysctl and arch so that
# any Mac can be played (and so that no Intel program is started). No game, no Wine, no network, no real
# patcher; nothing outside the scratch folder is read as an install or written.
#   bash scripts/test-setup.sh            exit 0 = every case passed
#   MUTANT=1 bash scripts/test-setup.sh   the badge patch is kept wherever a copy exists; must exit 1
#   MUTANT=2 bash scripts/test-setup.sh   --show-mod-badges leaves the marker behind; must exit 1
#   MUTANT=3 bash scripts/test-setup.sh   "setup complete" whatever failed; must exit 1
#   MUTANT=4 bash scripts/test-setup.sh   --dest takes no care of a missing value (it loops); must exit 1
#   MUTANT=5 bash scripts/test-setup.sh   macOS 15 counts as tested; must exit 1
#   MUTANT=6 bash scripts/test-setup.sh   the window builder (14unch3r) is never run; must exit 1
#   MUTANT=7 bash scripts/test-setup.sh   a failed window build counts as a setup problem; must exit 1
#   MUTANT=8 bash scripts/test-setup.sh   the window builder runs when the game's app was not built; must exit 1
#   MUTANT=9  ...  Return counted as yes at the Desktop question; must exit 1
#   MUTANT=10 ...  --yes counted as yes; must exit 1
#   MUTANT=11 ...  the Desktop looked at without a terminal; must exit 1
#   MUTANT=12 ...  make passed when the state is other; must exit 1
#   MUTANT=13 ...  asked when the state is have; must exit 1
#   MUTANT=14 ...  the alias step run when the window was not built; must exit 1
#   MUTANT=15 ...  the step run before the problems exit; must exit 1
#   MUTANT=16 ...  the Desktop folder not tested; must exit 1
#   MUTANT=17 ...  --mac-only goes on to the wrapper checks; must exit 1
#   MUTANT=18 ...  CS2_VIA_INSTALLER is ignored; must exit 1
#   MUTANT=19 ...  --mac-only exits 0 with Rosetta missing; must exit 1
#   MUTANT=20 ...  L1_FETCHED_REF is ignored; must exit 1
#   MUTANT=21 ...  the path helper returns its argument unchanged; must exit 1
# (17 to 21: docs/plans/simple-install.md, NT2.)
#   MUTANT=22 ...  exit 5 made 0; must exit 1
#   MUTANT=23 ...  exit 5 made 1; must exit 1
#   MUTANT=24 ...  the >> block counted in problems; must exit 1
#   MUTANT=25 ...  the app not built when repatch.sh exits 3; must exit 1
#   MUTANT=26 ...  the Desktop step skipped when setup will exit 5; must exit 1
#   MUTANT=27 ...  the >> block's middle form of its fifth line dropped (the installer in a clone); must exit 1
# (22 to 27: docs/plans/patch-outcomes.md, 2.4 and PT5. A stub patcher exits 3 when STUB_NOFIX names it.)
#   MUTANT=28 ...  no folder ever counts as named; must exit 1
#   MUTANT=29 ...  the folder is not resolved again after the move; must exit 1
#   MUTANT=30 ...  setup goes on after the move script's exit 3; must exit 1
#   MUTANT=31 ...  --held-by is never passed; must exit 1
#   MUTANT=32 ...  --held-by is passed whatever CS2_VIA_INSTALLER says; must exit 1
#   MUTANT=33 ...  setup's default folder is ~/cs2-patch again; must exit 1
#   MUTANT=34 ...  the move lifts patches/*.py file by file and not the folder; must exit 1
#   MUTANT=35 ...  the runtime folder's owner and mode are not looked at; must exit 1
#   (MUTANT=36 retired 2026-11-21: the list it patched is gone; common/test-wrappers.sh MUTANT=4 holds the case)
# (44 to 52: docs/plans/wrapper-names.md, WT4b, WT14, WT15, WT17.)
#   MUTANT=44 ...  setup treats the resolver's exit 2 as none (WT4b: red by the line alone); must exit 1
#   MUTANT=45 ...  WRAPPER not resolved again after the rename (WT17 (a)); must exit 1
#   MUTANT=46 ...  the dry run's stop looked for after the folder move (WT17 (b)); must exit 1
#   MUTANT=47 ...  the dry run dropped from the header: no wrapper: line (WT17 (d)); must exit 1
#   MUTANT=48 ...  the MAC_ONLY=0 guard taken off the resolver's call (WT17 (e)); must exit 1
#   MUTANT=49 ...  setup's copy of wrappers.sh removed (WT15 (a)); must exit 1
#   MUTANT=50 ...  --no-clone dropped from setup's call of the Steam app builder (WT14 (a)); must exit 1
#   MUTANT=51 ...  S734M.app not rebuilt (WT14 (b)); must exit 1
#   MUTANT=52 ...  check-deploy.sh's line for wrappers.sh removed (WT15 (c)); must exit 1
#   MUTANT=37 ...  setup checks for common/paths.sh only, not for the move script; must exit 1
#   MUTANT=38 ...  the check for setup's own files is made for a --mac-only run too; must exit 1
#   MUTANT=39 ...  a CS2_WRAPPER with no prefix taken as the wrapper; must exit 1
#   MUTANT=40 ...  the "already moved" stop is not made under --check; must exit 1
#   MUTANT=41 ...  the closing blocks about the move are not printed before the problems exit; must exit 1
#   MUTANT=42 ...  the move script does not test the folders' owner and mode on a finishing run; must exit 1
#   MUTANT=43 ...  the move script's closing chmod reaches the runtime folder and patches/ only; must exit 1
# (28 to 43: docs/plans/local-files-layout.md, LT17, LT18, LT22 to LT24, LT26, LT27.)
# (53 to 62: docs/plans/built-in-update.md, 3.3; UT5 and "UT5, also".)
#   MUTANT=53 ...  the stamp written before the app is built; must exit 1
#   MUTANT=54 ...  the stamp written when setup ends with problems; must exit 1
#   MUTANT=55 ...  the stamp written in place, not beside its place and renamed (common/updates.sh); must exit 1
#   MUTANT=56 ...  updates.sh not deployed; must exit 1
#   MUTANT=57 ...  update-dir not written; must exit 1
#   MUTANT=58 ...  the record's folders not tested for being the user's own; must exit 1
#   MUTANT=59 ...  the Desktop question asked under L1_UPDATE=1; must exit 1
#   MUTANT=60 ...  the own-files loop for common/updates.sh and common/games.tsv dropped; must exit 1
#   MUTANT=61 ...  updates.sh deployed after the window is built; must exit 1
#   MUTANT=62 ...  the closing words about a game set up by an older version dropped; must exit 1
# (63 to 66: docs/plans/launcher-first-install.md, 3.5; LFT5.)
#   MUTANT=63 ...  the launcher's stamp written when the window's builder skipped the build; must exit 1
#   MUTANT=64 ...  the launcher's stamp written for another destination (--dest); must exit 1
#   MUTANT=65 ...  the "14unch3r stays at" line said with no older stamp; must exit 1
#   MUTANT=66 ...  the "14unch3r stays at" line said for a stamp at this tree's own version; must exit 1
# The window builder is a recording stub beside the scratch repo, at $T/common, where setup.sh looks for it.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/setup-test.XXXX)"
trap 'rm -rf "$T"' EXIT
R="$T/repo"; mkdir -p "$R/patches" "$T/bin"
cp -R "$REPO/scripts" "$REPO/launchers" "$REPO/repatch.sh" "$R/"
S="$R/scripts/setup.sh"
mutate() {  # <sed expression> <grep that proves it applied>
  sed -i '' "$1" "$S"; grep -q "$2" "$S" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  1) mutate 's#^    elif \[ -f "\$BADGE_DST" \] \&\& badge_has_run; then .*#    elif [ -f "$BADGE_DST" ]; then#' '^    elif \[ -f "\$BADGE_DST" \]; then$' ;;
  2) mutate 's#^    rm -f "\$BADGE_DST" "\$BADGE_MARK"$#    rm -f "$BADGE_DST"#' '^    rm -f "\$BADGE_DST"$' ;;
  3) mutate 's#^if \[ "\$problems" -gt 0 \]; then$#if false; then#' '^if false; then$' ;;
  4) mutate 's#^    --dest) .*#    --dest)    DEST="${2:-}"; shift 2 ;;#' '^    --dest)    DEST="${2:-}"; shift 2 ;;$' ;;
  5) mutate 's#^  26|27) say #  15|26|27) say #' '^  15|26|27) say ' ;;
  6) mutate 's#^  elif bash "\$WINDOW_BUILDER"; then$#  elif true; then#' '^  elif true; then$' ;;
  7) mutate 's#^    echo "  window: not built (see the line above)"$#    problems=$((problems+1)); echo "  window: not built (see the line above)"#' '^    problems=\$((problems+1)); echo "  window: not built' ;;
  9) mutate 's#^      case "\$_a" in y|Y) _want=1 ;; esac$#      case "$_a" in y|Y|"") _want=1 ;; esac#' 'y|Y|"")' ;;
  10) mutate 's#^  if \[ "\$DESKTOP" = 1 \]; then _look=1$#  if [ "$DESKTOP" = 1 ] || [ "$ASSUME_YES" = 1 ]; then _look=1; DESKTOP=1#' 'then _look=1; DESKTOP=1$' ;;
  11) mutate 's#^  elif \[ "\$ASSUME_YES" = 0 \] \&\& \[ -t 0 \]; then _look=1; _ask=1$#  elif [ "$ASSUME_YES" = 0 ]; then _look=1; _ask=1#' '^  elif \[ "\$ASSUME_YES" = 0 \]; then _look=1' ;;
  12) mutate 's#^  if \[ "\$_state" = none \]; then$#  if [ "$_state" = none ] || [ "$_state" = other ]; then#' '\[ "\$_state" = other \]; then$' ;;
  13) mutate 's#^  if \[ "\$_state" = none \]; then$#  if [ "$_state" = none ] || [ "$_state" = have ]; then#' '\[ "\$_state" = have \]; then$' ;;
  14) mutate 's#^  \[ "\${WINDOW_BUILT:-0}" = 1 \] || return 0$#  true#' '^  true$' ;;
  15) mutate 's#^if \[ "\$problems" -gt 0 \]; then$#desktop_step; if [ "$problems" -gt 0 ]; then#' '^desktop_step; if' ;;
  16) mutate 's#^  \[ -d "\$HOME/Desktop" \] || return 0$#  true#' '^  true$' ;;
  17) mutate 's#^if \[ "\$MAC_ONLY" = 1 \]; then .*#if false; then#' '^if false; then$' ;;
  18) mutate 's#\[ "\${CS2_VIA_INSTALLER:-0}" != 1 \] \&\& ##' 'ASSUME_YES" = 0 \] && \[ "\$CHECK_ONLY" = 0 \] && \[ -t 0 \]'
      mutate 's#^if \[ "\${CS2_VIA_INSTALLER:-0}" = 1 \]; then$#if false; then#' '^if false; then$' ;;
  19) perl -0pi -e 's/(    echo "\$bad prerequisite\(s\) missing[^\n]*\n)    exit 1/$1    exit 0/' "$S"
      grep -q '^    exit 0$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  20) mutate 's#\[ -n "\${L1_FETCHED_REF:-}" \]#false#g' 'false && GUIDE=' ;;
  21) mutate "s#^tilde() { case .*#tilde() { printf '%s' \"\$1\"; }#" "^tilde() { printf '%s' \"\$1\"; }$" ;;
  8) perl -0pi -e 's/\nelse\n  # 14unch3r/\nfi\nif true; then\n  # 14unch3r/' "$S"; grep -q '^if true; then$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  22) sed -i '' 's#^  exit 5$#  exit 0#' "$S"; grep -q '^  exit 5$' "$S" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  23) sed -i '' 's#^  exit 5$#  exit 1#' "$S"; grep -q '^  exit 5$' "$S" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  24) mutate 's#^  NOFIX=1; nofix_block$#  NOFIX=1; nofix_block; problems=$((problems+1))#' '^  NOFIX=1; nofix_block; problems=' ;;
  25) mutate 's#^if ! bash "\$REPO/scripts/make-shortcut.sh" #if [ "$NOFIX" = 1 ] || ! bash "$REPO/scripts/make-shortcut.sh" #' '^if \[ "\$NOFIX" = 1 \] || ! bash' ;;
  26) mutate 's#^desktop_step$#[ "$NOFIX" = 1 ] || desktop_step#' '^\[ "\$NOFIX" = 1 \] || desktop_step$' ;;
  27) mutate 's#^  elif \[ "\${CS2_VIA_INSTALLER:-0}" = 1 \]; then$#  elif false; then#' '^  elif false; then$' ;;
  28) mutate 's#^  \[ -n "\${CS2_PATCH_DIR:-}" \] \&\& \[ "\$CS2_PATCH_DIR" != "\$RUNTIME" \] \&\& NAMED=1$#  : never named#' '^  : never named$' ;;
  29) perl -0pi -e 's/       \. "\$PATHS"; DEST="\$CS2_DATA"\n       \[ "\$MOVED" = 1 \]/       : not resolved again\n       [ "\$MOVED" = 1 ]/' "$S"
      grep -q '^       : not resolved again$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  30) mutate 's#^       exit 3 ;;$#       ;;#' '^       ;;$' ;;
  31) mutate 's#^  \[ "\${CS2_VIA_INSTALLER:-0}" = 1 \] \&\& a+=(--held-by "\$PPID")$#  : no held-by#' '^  : no held-by$' ;;
  32) mutate 's#^  \[ "\${CS2_VIA_INSTALLER:-0}" = 1 \] \&\& a+=(--held-by "\$PPID")$#  a+=(--held-by "$PPID")#' '^  a+=(--held-by "\$PPID")$' ;;
  33) mutate 's#^  \[ -n "\$DEST" \] || DEST="\$CS2_DATA"$#  [ -n "$DEST" ] || DEST="$HOME/cs2-patch"#' '|| DEST="\$HOME/cs2-patch"$' ;;
  34) perl -0pi -e 's/    elif mv_q "\$1\/\$n" "\$2\/\$n"; then/    elif if [ "\$n" = patches ]; then mkdir "\$2\/patches" && mv "\$1\/patches"\/*.py "\$2\/patches\/"; else mv "\$1\/\$n" "\$2\/\$n"; fi; then/' "$R/scripts/move-install.sh"
      grep -q 'if \[ "\$n" = patches \]; then mkdir' "$R/scripts/move-install.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  35) mutate 's#^      own_folder "\$d" || { echo .*#      true#' '^      true$' ;;
  36) echo "REFUSED: mutant 36 is retired (the header says where its case went)"; exit 2 ;;
  37) mutate 's#^  for f in "\$PATHS" "\$MOVER" "\$RESOLVER" "\$WMOVER"; do$#  for f in "$PATHS" "$RESOLVER" "$WMOVER"; do#' '^  for f in "\$PATHS" "\$RESOLVER" "\$WMOVER"; do$' ;;
  38) perl -0pi -e 's/\nif \[ "\$MAC_ONLY" = 0 \]; then\n  for f in "\$PATHS" "\$MOVER" "\$RESOLVER" "\$WMOVER"; do\n/\nif true; then\n  for f in "\$PATHS" "\$MOVER" "\$RESOLVER" "\$WMOVER"; do\n/' "$S"
      grep -q '^if true; then$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  39) mutate 's#^  WRAPPER=""; \[ "\$rc" = 0 \] \&\& \[ -d "\$w/Contents/SharedSupport/prefix" \] \&\& WRAPPER="\$w"$#  WRAPPER=""; [ "$rc" = 0 ] \&\& WRAPPER="$w"#' '^  WRAPPER=""; \[ "\$rc" = 0 \] && WRAPPER="\$w"$' ;;
  40) mutate 's#^    if \[ "\${CS2_PATCH_DIR:-}" = "\$OLD_INSTALL" \] \&\& #    if [ "$CHECK_ONLY" = 0 ] \&\& [ "${CS2_PATCH_DIR:-}" = "$OLD_INSTALL" ] \&\& #' '^    if \[ "\$CHECK_ONLY" = 0 \] && \[ "\${CS2_PATCH_DIR:-}" = ' ;;
  41) mutate 's#^  move_blocks; rename_blocks$#  : no blocks here; rename_blocks#' '^  : no blocks here; rename_blocks$' ;;
  42) perl -0pi -e 's/    if \[ -e "\$d" \] \|\| \[ -L "\$d" \]; then own_folder "\$d" \|\| reason skip [^\n]*\n/    :\n/' "$R/scripts/move-install.sh"
      grep -q '^    :$' "$R/scripts/move-install.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  44) mutate 's#^  if \[ "\$rc" = 2 \]; then$#  if false; then#' '^  if false; then$' ;;
  45) perl -0pi -e 's/\nfind_wrapper   # resolved again[^\n]*\n/\n: not resolved again\n/' "$S"; grep -q '^: not resolved again$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  46) perl -0pi -e 's/(# -{20,} a wrapper that cannot be renamed now\n.*?\nfi\n)(.*?)(# -{20,} install\n)/$2$1$3/s' "$S"
      [ "$(grep -n '^# -* a wrapper that cannot be renamed now$' "$S" | cut -d: -f1)" -gt "$(grep -n '^# -* an install made before the folders moved$' "$S" | cut -d: -f1)" ] || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  47) mutate 's#^if \[ "\$MAC_ONLY" = 0 \]; then paths_lines; move_line; wrapper_line; fi$#if [ "$MAC_ONLY" = 0 ]; then paths_lines; move_line; fi#' '^if \[ "\$MAC_ONLY" = 0 \]; then paths_lines; move_line; fi$' ;;
  48) mutate 's#^if \[ "\$MAC_ONLY" = 0 \]; then \. "\$RESOLVER"; find_wrapper; fi$#. "$RESOLVER"; find_wrapper#' '^\. "\$RESOLVER"; find_wrapper$' ;;
  49) mutate 's#^cp "\$RESOLVER" "\$DEST/" \&\& echo .*#: no copy#' '^: no copy$' ;;
  50) mutate 's#bash "\$REPO/scripts/make-steam-shortcut.sh" --no-clone#bash "$REPO/scripts/make-steam-shortcut.sh"#' 'make-steam-shortcut.sh" 2>&1' ;;
  51) mutate 's#^if \[ -e "\$HOME/Applications/S734M.app" \] \&\& \[ -f "\$REPO/scripts/make-steam-shortcut.sh" \]; then$#if false; then#' '^if false; then$' ;;
  52) CD_MUT=1 ;;
  53) mutate 's#^echo "Building the double-clickable app:"$#stamp_step; echo "Building the double-clickable app:"#' '^stamp_step; echo "Building the double-clickable app:"$'
      sed -i '' '/^stamp_step$/d' "$S"; grep -q '^stamp_step$' "$S" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  54) mutate 's#^if \[ "\$problems" -gt 0 \]; then$#stamp_step; if [ "$problems" -gt 0 ]; then#' '^stamp_step; if \[ "\$problems" -gt 0 \]; then$' ;;
  55) U_MUT=1 ;;
  56) mutate 's#^  put "\$UPDATES" "\$L1_UPDATE_DIR/updates.sh"$#  : not deployed#' '^  : not deployed$' ;;
  57) mutate 's#^  put_line "\$L1_UPDATE_DIR" "\$DEST/update-dir"$#  : not written#' '^  : not written$' ;;
  58) mutate 's#^      own_folder "\$d" || { echo "  !! \$(tilde "\$d") is not a folder of your own that only you can write to; setup will not keep its record .*#      : not tested#' '^      : not tested$' ;;
  59) mutate 's#^  \[ "\${L1_UPDATE:-}" = 1 \] \&\& \[ "\$_ask" = 1 \] \&\& .*#  : asked under an update too#' '^  : asked under an update too$' ;;
  60) mutate 's#^  for f in "\$UPDATES" "\$GAMES"; do .*#  for f in; do#' '^  for f in; do$' ;;
  61) mutate 's#^  put "\$UPDATES" "\$L1_UPDATE_DIR/updates.sh"$#  : deployed later#' '^  : deployed later$'
      mutate 's|^\# S734M.app, the Windows Steam, names its wrapper.s path: rebuilt when it is there, .*|[ "$RECORD" = 1 ] \&\& put "$UPDATES" "$L1_UPDATE_DIR/updates.sh"|' '^\[ "\$RECORD" = 1 \] && put "\$UPDATES" "\$L1_UPDATE_DIR/updates.sh"$' ;;
  62) mutate 's#^unrecorded_games$#: no closing words#' '^: no closing words$' ;;
  63) mutate 's#^    echo "  window: not built (see the line above)"$#    launcher_stamp; echo "  window: not built (see the line above)"#' '^    launcher_stamp; echo "  window: not built (see the line above)"$' ;;
  64) perl -0pi -e 's/\nlauncher_stamp\(\) \{\n  \[ "\$RECORD" = 1 \] \|\| return 0\n/\nlauncher_stamp() {\n  [ "\$RECORD" = 1 ] || . "\$UPDATES"\n/' "$S"
      grep -q '^  \[ "\$RECORD" = 1 \] || \. "\$UPDATES"$' "$S" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  65) mutate 's#^  old="\$(l1u_stamp_of_launcher)" || return 0$#  old="$(l1u_stamp_of_launcher)" || old=v0.0.0#' '^  old="\$(l1u_stamp_of_launcher)" || old=v0\.0\.0$' ;;
  66) mutate 's#^  \[ "\$old" != - \] \&\& l1u_newer "\$tree" "\$old" || return 0$#  [ "$old" != - ] || return 0#' '^  \[ "\$old" != - \] || return 0$' ;;
  43) perl -0pi -e 's/\nclose_modes\(\) \{[^\n]*\n/\nclose_modes() { chmod go-w "\$DATA" 2>\/dev\/null; [ -d "\$DATA\/patches" ] \&\& chmod go-w "\$DATA\/patches"; return 0; }\n/' "$R/scripts/move-install.sh"
      grep -q '^close_modes() { chmod go-w "\$DATA" 2' "$R/scripts/move-install.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
esac
for f in "$REPO"/patches/patch_*.py; do
  echo 'import os, sys; n = os.path.basename(sys.argv[0]); sys.exit(1 if os.environ.get("STUB_FAIL") == n else 3 if os.environ.get("STUB_NOFIX") == n else 0)' > "$R/patches/$(basename "$f")"
done
NPATCH=$(ls "$R/patches" | wc -l | tr -d ' ')
mkdir -p "$R/patches/_vendor/lib"; echo vendored > "$R/patches/_vendor/lib/file.py"
printf '#!/bin/bash\nexit 1\n' > "$T/bin/xcrun"      # no swiftc: make-shortcut.sh skips the progress panel
# this Mac, as the case wants it: STUB_OSV (default 27.2), STUB_ARM64 (default 1), STUB_ROSETTA (exit code, default 0)
printf '#!/bin/bash\n[ "$1" = -productVersion ] && echo "${STUB_OSV-27.2}"\n' > "$T/bin/sw_vers"
printf '#!/bin/bash\n[ "$*" = "-n hw.optional.arm64" ] && { echo "${STUB_ARM64:-1}"; exit 0; }\nexec /usr/sbin/sysctl "$@"\n' > "$T/bin/sysctl"
printf '#!/bin/bash\n[ "$1" = -x86_64 ] && exit "${STUB_ROSETTA:-0}"\nexec /usr/bin/arch "$@"\n' > "$T/bin/arch"
chmod +x "$T/bin"/*
mkdir -p "$T/badpy"; printf '#!/bin/bash\nexit 1\n' > "$T/badpy/python3"; chmod +x "$T/badpy/python3"
# the window builder: a stub that records each call, and whether the game's app was there when it ran
export WINDOW_CALLS="$T/window.calls"; : > "$WINDOW_CALLS"
mkdir -p "$T/common"; cp "$REPO/../common/paths.sh" "$REPO/../common/wrappers.sh" "$REPO/../common/move-wrappers.sh" "$T/common/"
# the record of versions (docs/plans/built-in-update.md, 3.3): its tool and the table of games are setup's own files
# too, and the scratch tree, whose root is $T, has a changelog whose first version heading is the tree's version
cp "$REPO/../common/updates.sh" "$REPO/../common/games.tsv" "$T/common/"
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.4.2 (2026-11-24)' '' 'Words.' '' '## v0.4.1 (2026-11-20)' > "$T/CHANGELOG.md"
if [ "${U_MUT:-0}" = 1 ]; then   # MUTANT=55, in the tree's copy of the tool
  perl -pi -e 's/^  if printf \x27%s\\n\x27 "\$2" > "\$t" 2>\/dev\/null && mv -f "\$t" "\$1" 2>\/dev\/null; then return 0; fi$/  if printf \x27%s\\n\x27 "\$2" > "\$1" 2>\/dev\/null; then : > "\$t"; return 0; fi/' "$T/common/updates.sh"
  grep -q '> "\$1" 2>/dev/null; then : > "\$t"; return 0; fi$' "$T/common/updates.sh" || { echo "REFUSED: mutant did not apply"; exit 2; }
fi
# the wrapper mover's open-files probe (docs/plans/wrapper-names.md, 3.4): a stub that reports $STUB_WHOLDERS, so that no run
# reaches the real lsof
printf '#!/bin/bash\n[ -n "${STUB_WHOLDERS:-}" ] && echo "$STUB_WHOLDERS"\nexit 0\n' > "$T/bin/wprobe"; chmod +x "$T/bin/wprobe"
export L1_WMOVE_PROBE="$T/bin/wprobe"
# the move script's probes: a stub that answers $STUB_OPEN and $STUB_CWD, one volume for every folder, and records each call
export PROBE_CALLS="$T/probe.calls"; : > "$PROBE_CALLS"
printf '#!/bin/bash\necho "$1" >> "$PROBE_CALLS"\ncase "$1" in open) [ -n "${STUB_OPEN:-}" ] && echo "$STUB_OPEN" ;; cwd) [ -n "${STUB_CWD:-}" ] && echo "$STUB_CWD" ;; dev) echo 1 ;; esac\nexit 0\n' > "$T/bin/probe"; chmod +x "$T/bin/probe"
export L1_MOVE_PROBE="$T/bin/probe"
cat > "$T/common/make-launcher-app.sh" << 'STUB'
#!/bin/bash
printf 'CALL args=%s app=%s\n' "$#" "$([ -f "$HOME/Applications/Cities Skylines II.app/Contents/MacOS/launch" ] && echo there || echo missing)" >> "$WINDOW_CALLS"
echo "stub: window builder"
( . "$(dirname "$0")/paths.sh"; [ -f "$L1_UPDATE_DIR/updates.sh" ] && echo there || echo missing ) > "$WINDOW_CALLS.tool"
# a recording launcher-window in the scratch HOME's 14unch3r.app: it answers --alias with $STUB_ALIAS
mkdir -p "$HOME/Applications/14unch3r.app/Contents/MacOS"
cat > "$HOME/Applications/14unch3r.app/Contents/MacOS/launcher-window" << 'PROG'
#!/bin/bash
printf 'ALIAS %s\n' "$*" >> "$ALIAS_CALLS"
[ "${4:-}" = make ] && [ "${STUB_ALIAS:-none}" = none ] && { echo made; exit 0; }
echo "${STUB_ALIAS:-none}"
PROG
chmod +x "$HOME/Applications/14unch3r.app/Contents/MacOS/launcher-window"
exit "${STUB_WINDOW_RC:-0}"
STUB
export ALIAS_CALLS="$T/alias.calls"; : > "$ALIAS_CALLS"
cp -R "$R" "$T/repo2"; printf '#!/bin/bash\necho "stub: no app"; exit 1\n' > "$T/repo2/scripts/make-shortcut.sh"
# the folders, relative to a home, as common/paths.sh gives them for a home with no install
CLEAN="env -u CS2_PATCH_DIR -u CS2_WORK_DIR -u L1_DATA_ROOT -u L1_WORK_ROOT -u CS2_WRAPPER -u CS2_GAME_DIR -u CS2_ERRNO_PATCHES -u L1_UPDATE_DIR -u L1_UPDATE -u L1_UPDATE_NOW -u L1_FETCHED_COMMIT -u SM_WRAPPER"
INST="$($CLEAN HOME=/H bash "$T/common/paths.sh" | sed -n 's#^CS2_DATA=/H/##p')"
WORKSP="$($CLEAN HOME=/H bash "$T/common/paths.sh" | sed -n 's#^CS2_WORK=/H/##p')"
UPD="$($CLEAN HOME=/H bash "$T/common/paths.sh" | sed -n 's#^L1_UPDATE_DIR=/H/##p')"   # the record of versions
BADGE="$INST/patch-modconflict-badge.py"
MARK="$INST/patches/.mod-badges-on"
GAME="Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II"

home() {   # <dir> [wrapper name] [unmarked]: a HOME holding a fake wrapper with Steam and the game in it. It carries the
  # game's marker (docs/plans/wrapper-names.md, 3.1), so that a case about something else meets a wrapper setup leaves
  # under its name; "unmarked" makes one under an old name that setup renames, as a Mac not moved yet has
  local a="$1/Applications/${2:-CS2dxmt11.app}"; local p="$a/Contents/SharedSupport"
  mkdir -p "$p/wine/bin" "$a/$GAME/Cities2_Data/Managed"
  printf '#!/bin/bash\necho wine-11.0\n' > "$p/wine/bin/wine64"; chmod +x "$p/wine/bin/wine64"
  : > "$p/prefix/drive_c/Program Files (x86)/Steam/steam.exe"
  : > "$a/$GAME/Cities2.exe"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>' > "$a/Contents/Info.plist"
  if [ "${3:-}" != unmarked ]; then
    plutil -replace L1Role -string game-wrapper "$a/Contents/Info.plist"; plutil -replace L1SteamAppID -integer 949230 "$a/Contents/Info.plist"
  fi
}
ran_here() { : > "$1/Applications/CS2dxmt11.app/$GAME/Cities2_Data/Managed/Game.dll.bak-modconflict-20260827-164900"; }
run() {    # <home> [setup.sh arguments]: output in <home>.out; echoes the exit code, or "timeout" after 20 s
  local h="$1" p i=0; shift
  $CLEAN ${RUN_ENV:-} HOME="$h" PATH="${EXTRA_PATH:+$EXTRA_PATH:}$T/bin:$PATH" \
    bash "${SETUP_REPO:-$R}/scripts/setup.sh" "$@" > "$h.out" 2>&1 < /dev/null & p=$!
  while kill -0 $p 2>/dev/null; do
    i=$((i + 1)); [ $i -gt 200 ] && { kill -9 $p 2>/dev/null; wait $p 2>/dev/null; echo timeout; return; }
    sleep 0.1
  done
  wait $p; echo $?
}
snap() { (cd "$1" && find . | sort | shasum | cut -c1-12); }
said() { grep -c -- "$2" "$1.out"; }
has()  { if [ -e "$1" ]; then echo yes; else echo no; fi; }
lines() { wc -l < "$1" | tr -d ' '; }
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

# --- the clean run
H="$T/h1"; home "$H"
check "clean run exits 0" "$(run "$H")" 0
check "  ...says setup complete, and that all ten patch scripts finished" "$(said "$H" '^=== setup complete ===$'):$(said "$H" '^10 of 10 patch scripts finished without error$')" "1:1"
check "  ...on a tested Mac: no caution, and the three lines about the Mac" "$(said "$H" 'CAUTION\|caution'):$(said "$H" 'Apple Silicon  *OK$'):$(said "$H" 'Rosetta 2  *OK$'):$(said "$H" 'macOS 27.2  *OK (tested)$')" "0:1:1:1"
check "  ...the libraries the patch scripts use are installed with them" "$(cat "$H/$INST/patches/_vendor/lib/file.py" 2>/dev/null)" vendored
check "  ...launcher, repatch.sh and every patch script are in the install folder" "$(has "$H/$INST/launch-cs2-dxmt11.sh"):$(has "$H/$INST/repatch.sh"):$(ls "$H/$INST/patches"/*.py | wc -l | tr -d ' ')" "yes:yes:$NPATCH"
check "  ...the app is in Applications and starts the installed launcher" "$(grep -c "^SCRIPT=\"$H/$INST/launch-cs2-dxmt11.sh\"$" "$H/Applications/Cities Skylines II.app/Contents/MacOS/launch" 2>/dev/null)" 1
check "  ...no badge file, no marker, and nothing said about the badge patch" "$(has "$H/$BADGE"):$(has "$H/$MARK"):$(said "$H" 'mod badge patch')" "no:no:0"

# --- the badge patch is opt-in
check "--hide-mod-badges exits 0" "$(run "$H" --hide-mod-badges)" 0
check "  ...installs the badge file and the marker, and says when it takes effect" "$(has "$H/$BADGE"):$(has "$H/$MARK"):$(said "$H" 'mod badge patch: on. It takes effect at the next launch')" "yes:yes:1"
echo stale > "$H/$BADGE"
check "a plain run before any launch exits 0" "$(run "$H")" 0
check "  ...keeps the badge file and refreshes it (it was asked for)" "$(cmp -s "$R/scripts/patch-modconflict-badge.py" "$H/$BADGE" && echo same || echo differs)" same
check "--show-mod-badges exits 0" "$(run "$H" --show-mod-badges)" 0
check "  ...removes the file and the marker and says how to put Game.dll back" "$(has "$H/$BADGE"):$(has "$H/$MARK"):$(said "$H" 'Verify integrity of game files'):$(said "$H" 'Game.dll.bak-modconflict-')" "no:no:1:1"
ran_here "$H"
check "after --show-mod-badges a plain run exits 0, even where the patch once ran" "$(run "$H")" 0
check "  ...and it stays off" "$(has "$H/$BADGE"):$(has "$H/$MARK")" "no:no"
check "both badge flags at once: exit 2" "$(run "$H" --hide-mod-badges --show-mod-badges):$(said "$H" 'cannot both be given')" "2:1"

# --- installs made before the patch became opt-in: every one of them holds a copy
H="$T/h2"; home "$H"; mkdir -p "$H/$INST"; echo old > "$H/$BADGE"
check "an old copy that never ran: exit 0" "$(run "$H")" 0
check "  ...it is removed, and setup says so" "$(has "$H/$BADGE"):$(has "$H/$MARK"):$(said "$H" 'mod badge patch: off (it has never run here); --hide-mod-badges turns it on')" "no:no:1"
H="$T/h3"; home "$H"; mkdir -p "$H/$INST"; echo old > "$H/$BADGE"; ran_here "$H"
check "an old copy where the patch has run: exit 0" "$(run "$H")" 0
check "  ...it is kept, refreshed, and the choice recorded" "$(cmp -s "$R/scripts/patch-modconflict-badge.py" "$H/$BADGE" && echo same || echo differs):$(has "$H/$MARK"):$(said "$H" 'mod badge patch: on, as before')" "same:yes:1"
rm "$H/Applications/CS2dxmt11.app/$GAME/Cities2_Data/Managed"/Game.dll.bak-modconflict-*
check "  ...and a later run keeps it after the backups are deleted" "$(run "$H"):$(has "$H/$BADGE")" "0:yes"

# --- the badge step uses the wrapper setup found, whatever its name (docs/plans/wrapper-names.md)
H="$T/h4"; home "$H" CS2.app
check "--hide-mod-badges with another wrapper: exit 0, on, and no warning about the wrapper" "$(run "$H" --hide-mod-badges):$(said "$H" 'mod badge patch: on'):$(said "$H" 'only knows')" "0:1:0"
H="$T/h4b"; home "$H" "Some Name.app"; mkdir -p "$H/$INST"; echo old > "$H/$BADGE"
: > "$H/Applications/Some Name.app/$GAME/Cities2_Data/Managed/Game.dll.bak-modconflict-20260827-164900"
check "  ...an old copy where the patch has run in that wrapper: kept, as before" "$(run "$H"):$(said "$H" 'mod badge patch: on, as before')" "0:1"
H="$T/h4"

# --- --check writes nothing, whatever else is asked
H="$T/h5"; home "$H"; before=$(snap "$H")
check "--check --hide-mod-badges exits 0" "$(run "$H" --check --hide-mod-badges)" 0
check "  ...and wrote nothing" "x$(snap "$H")" "x$before"

# --- a stale file in the installed library folder does not survive a run
H="$T/h6"; home "$H"; mkdir -p "$H/$INST/patches/_vendor"; echo old > "$H/$INST/patches/_vendor/stale.py"
check "a run replaces the installed library folder" "$(run "$H"):$(has "$H/$INST/patches/_vendor/stale.py"):$(has "$H/$INST/patches/_vendor/lib/file.py")" "0:no:yes"

# --- a Mac outside what has been tested: a caution, and setup goes on
H="$T/h7"; home "$H"
check "macOS 15: exit 0, setup complete" "$(STUB_OSV=15.5 run "$H"):$(said "$H" '^=== setup complete ===$')" "0:1"
check "  ...one CAUTION line with its reason, the paragraph, and no question (nobody is at a terminal)" "$(said "$H" 'macOS 15.5  *CAUTION$'):$(said "$H" 'older than anything this has been run on'):$(said "$H" '^1 caution(s): this Mac is outside'):$(said "$H" 'Press Return')" "1:1:1:0"
check "  ...a caution is not counted as a check" "$(said "$H" '^All 7 checks passed\.$')" 1
H="$T/h8"; home "$H"
check "macOS 28: a caution about Rosetta's end" "$(STUB_OSV=28.0 run "$H"):$(said "$H" 'macOS 28.0  *CAUTION$'):$(said "$H" 'last release with general Rosetta support')" "0:1:1"
check "macOS 13: a caution about the graphics layer's minimum" "$(STUB_OSV=13.6.1 run "$H"):$(said "$H" 'below the minimum of DXMT')" "0:1"
check "a version that cannot be read: a caution" "$(STUB_OSV= run "$H"):$(said "$H" 'macOS version  *CAUTION$')" "0:1"
check "an Intel Mac: a caution, and no Rosetta line" "$(STUB_ARM64=0 run "$H"):$(said "$H" 'Apple Silicon  *CAUTION$'):$(said "$H" 'Rosetta 2')" "0:1:0"
H="$T/h9"; home "$H"; before=$(snap "$H")
check "--check on macOS 15: the caution, exit 0" "$(STUB_OSV=15.5 run "$H" --check):$(said "$H" 'CAUTION$'):$(said "$H" '^(--check: stopping before making changes)$')" "0:1:1"
check "  ...and wrote nothing" "x$(snap "$H")" "x$before"

# --- what cannot work stops setup before anything is copied
check "no Rosetta: exit 1, the command to install it" "$(STUB_ROSETTA=1 run "$H"):$(said "$H" 'Rosetta 2  *MISSING$'):$(said "$H" 'softwareupdate --install-rosetta --agree-to-license')" "1:1:1"
check "  ...and wrote nothing" "x$(snap "$H")" "x$before"
check "a python3 that does not run: exit 1, the command to install it" "$(EXTRA_PATH="$T/badpy" run "$H"):$(said "$H" 'python3, version 3.8 or newer  *MISSING$'):$(said "$H" 'xcode-select --install')" "1:1:1"
check "  ...and wrote nothing" "x$(snap "$H")" "x$before"

# --- at a terminal, a caution asks before going on, and --yes answers it
pty() {   # <home> [setup.sh arguments]: setup with a terminal for stdin and one Return typed; output in <home>.out
  local h="$1"; shift
  printf '\n' | env -u CS2_PATCH_DIR -u CS2_WRAPPER -u CS2_GAME_DIR -u CS2_ERRNO_PATCHES -u L1_UPDATE_DIR HOME="$h" PATH="$T/bin:$PATH" STUB_OSV=15.5 \
    script -q /dev/null bash "$S" "$@" > "$h.out" 2>&1; echo $?
}
H="$T/h10"; home "$H"
check "macOS 15 at a terminal: the question is asked, and Return goes on" "$(pty "$H"):$(said "$H" 'Press Return to continue, or Control-C to stop'):$(said "$H" '=== setup complete ===')" "0:1:1"
check "  ...with --yes it is not asked" "$(pty "$H" --yes):$(said "$H" 'Press Return'):$(said "$H" '=== setup complete ===')" "0:0:1"

# --- failures are counted, said, and never end in "setup complete"
H="$T/h11"; home "$H"
check "a failing patch script: exit 1" "$(STUB_FAIL=patch_mkparent.py run "$H")" 1
check "  ...1 problem, no setup complete, the patch named" "$(said "$H" '^=== setup finished with 1 problem(s): see the lines marked !! above ===$'):$(said "$H" 'setup complete'):$(said "$H" '^FAILED: patch_mkparent.py$')" "1:0:1"
check "  ...and no closing instructions to play" "$(said "$H" '^Play:')" 0
H="$T/h12"; home "$H"
check "a failing app builder: exit 1" "$(SETUP_REPO="$T/repo2" run "$H")" 1
check "  ...1 problem, no setup complete" "$(said "$H" '^=== setup finished with 1 problem(s)'):$(said "$H" 'setup complete')" "1:0"
check "a failing patch script and a failing app builder: 2 problems" "$(SETUP_REPO="$T/repo2" STUB_FAIL=patch_cohtml.py run "$H"):$(said "$H" '^=== setup finished with 2 problem(s)')" "1:1"

# --- options
H="$T/h13"; home "$H"; before=$(snap "$H")
check "--dest with no value: exit 2 at once" "$(run "$H" --dest):$(said "$H" '^--dest needs a value$')" "2:1"
check "--dest with an empty value: exit 2 at once" "$(run "$H" --dest ''):$(said "$H" '^--dest needs a value$')" "2:1"
check "--stack with no value: exit 2 at once" "$(run "$H" --stack):$(said "$H" '^--stack needs a value$')" "2:1"
check "  ...none of those wrote anything" "x$(snap "$H")" "x$before"
check "--stack d3dmetal: exit 2 and the retirement sentence, nothing written" "$(run "$H" --stack d3dmetal):$(said "$H" '^The Wine 10 + D3DMetal stack was retired on 2026-11-09\. Its last version is commit [0-9a-f]\{7,40\}\.$'):x$(snap "$H")" "2:1:x$before"
check "--stack wine10: the same" "$(run "$H" --stack wine10):$(said "$H" 'stack was retired on 2026-11-09')" "2:1"
check "--stack with an unknown name: exit 2" "$(run "$H" --stack vulkan):$(said "$H" "unknown --stack")" "2:1"
check "--stack dxmt11 is still accepted" "$(run "$H" --stack dxmt11):$(said "$H" '^=== setup complete ===$')" "0:1"
check "--help prints the usage and stops before the code" "$(run "$H" --help):$(said "$H" 'bash scripts/setup.sh --check'):$(said "$H" '^set -u$')" "0:1:0"

# --- 14unch3r, the window's builder (docs/plans/launcher-window.md, 2.3; W10)
H="$T/hw"; home "$H"; : > "$WINDOW_CALLS"
check "14unch3r: setup runs the window builder once, with no arguments, after the game's app" "$(run "$H"):$(cat "$WINDOW_CALLS")" "0:CALL args=0 app=there"
check "  ...setup completes, and its closing lines name the window" "$(said "$H" '^=== setup complete ===$'):$(said "$H" 'or open 14unch3r')" "1:1"
for rc in 1 3; do
  : > "$WINDOW_CALLS"
  check "the window builder exits $rc: setup exits 0, says so once, counts no problem, marks nothing !!" \
    "$(STUB_WINDOW_RC=$rc run "$H"):$(said "$H" '^  window: not built (see the line above)$'):$(said "$H" '^=== setup complete ===$'):$(said "$H" 'setup finished with'):$(said "$H" '!!.*window'):$(said "$H" 'or open 14unch3r')" "0:1:1:0:0:0"
done
mkdir -p "$T/nocommon/common"; cp -R "$R" "$T/nocommon/repo"; cp "$T/common/paths.sh" "$T/common/wrappers.sh" "$T/common/move-wrappers.sh" "$T/common/updates.sh" "$T/common/games.tsv" "$T/nocommon/common/"; : > "$WINDOW_CALLS"
check "a common/ with paths.sh and no window builder: setup exits 0 and says the builder is not in this checkout" \
  "$(SETUP_REPO="$T/nocommon/repo" run "$H"):$(said "$H" '^  window: not built (common/make-launcher-app.sh is not in this checkout)$'):$(said "$H" '^=== setup complete ===$'):$(lines "$WINDOW_CALLS")" "0:1:1:0"
mkdir -p "$T/bare"; cp -R "$R" "$T/bare/repo"; HB="$T/hbare"; home "$HB"; before=$(snap "$HB")
check "no common/ at all: setup stops at once, exit 1, with the words for its own files, and writes nothing" \
  "$(SETUP_REPO="$T/bare/repo" run "$HB"):$(said "$HB" "^  !! setup's own files are missing (.*common/paths.sh). Open the installer again, or run setup from a whole checkout.\$"):$(said "$HB" 'Preflight\|^==='):x$(snap "$HB")" "1:1:0:x$before"
check "  ...with --mac-only that run is outside the check: exit 0, and the Mac is looked at" \
  "$(SETUP_REPO="$T/bare/repo" run "$HB" --mac-only):$(said "$HB" "setup's own files"):$(said "$HB" 'Rosetta 2  *OK$'):x$(snap "$HB")" "0:0:1:x$before"
mkdir -p "$T/nomover/common"; cp -R "$R" "$T/nomover/repo"; cp "$T/common/paths.sh" "$T/common/make-launcher-app.sh" "$T/common/wrappers.sh" "$T/common/move-wrappers.sh" "$T/common/updates.sh" "$T/common/games.tsv" "$T/nomover/common/"; rm "$T/nomover/repo/scripts/move-install.sh"
check "no scripts/move-install.sh: the same stop, before the header and the preflight, and nothing written" \
  "$(SETUP_REPO="$T/nomover/repo" run "$HB"):$(said "$HB" "^  !! setup's own files are missing (.*scripts/move-install.sh). Open the installer again, or run setup from a whole checkout.\$"):$(said "$HB" 'Preflight\|^==='):x$(snap "$HB")" "1:1:0:x$before"
check "  ...and with --mac-only: exit 0" \
  "$(SETUP_REPO="$T/nomover/repo" run "$HB" --mac-only):$(said "$HB" "setup's own files"):$(said "$HB" 'Rosetta 2  *OK$'):x$(snap "$HB")" "0:0:1:x$before"
: > "$WINDOW_CALLS"
check "the game's app was not built: the window builder is not run" "$(SETUP_REPO="$T/repo2" run "$H"):$(lines "$WINDOW_CALLS")" "1:0"

# --- the Desktop shortcut (docs/plans/launcher-window-look.md, 2.9; W18). The stub program answers --alias with
# $STUB_ALIAS and records every call. ptya types its answer into a pipe held open, so that the read sees it and not
# an end of file (measured: printf 'y\n' | script ... gives the read an end of file and an empty answer), on a Mac
# inside the tested range, so that the caution question does not take it first.
ptya() {  # <typed line> <home> [setup.sh arguments]: setup at a terminal, with <typed line> typed
  local typed="$1" h="$2"; shift 2
  { sleep 1; printf '%s\n' "$typed"; sleep 6; } | env -u CS2_PATCH_DIR -u CS2_WRAPPER -u CS2_GAME_DIR -u CS2_ERRNO_PATCHES -u STUB_OSV -u L1_UPDATE_DIR \
    HOME="$h" PATH="$T/bin:$PATH" script -q /dev/null bash "$S" "$@" > "$h.out" 2>&1; echo $?
}
Q='Put a 14unch3r shortcut on the Desktop? \[y/N\]'
TAB="$(printf '\t')"
makes() { grep -c ' make$' "$ALIAS_CALLS"; }
desk() {  # <home>: asked : calls : make calls : which Desktop line : setup complete
  echo "$(said "$1" "$Q"):$(lines "$ALIAS_CALLS"):$(makes):$(sed -n 's/^Desktop:   //p' "$1.out" | tr -d '\r' | cut -c1-14):$(said "$1" '^=== setup complete ===')"
}
H="$T/hd"; home "$H"; mkdir -p "$H/Desktop"
: > "$ALIAS_CALLS"; check "desktop: y at a terminal: asked once, one call and one with make, the added line" "$(ptya y "$H"):$(desk "$H")" "0:1:2:1:14unch3r short:1"
: > "$ALIAS_CALLS"; check "desktop: an empty line: asked, no make, the no-shortcut line" "$(ptya '' "$H"):$(desk "$H")" "0:1:1:0:no shortcut ma:1"
: > "$ALIAS_CALLS"; check "desktop: n: asked, no make, the no-shortcut line" "$(ptya n "$H"):$(desk "$H")" "0:1:1:0:no shortcut ma:1"
: > "$ALIAS_CALLS"; check "desktop: --yes at a terminal: not asked, no call at all, the no-shortcut line" "$(ptya y "$H" --yes):$(desk "$H")" "0:0:0:0:no shortcut ma:1"
: > "$ALIAS_CALLS"; check "desktop: --desktop with no terminal: not asked, make once" "$(run "$H" --desktop):$(desk "$H")" "0:0:2:1:14unch3r short:1"
: > "$ALIAS_CALLS"; check "desktop: no terminal and no flag: no call at all, the no-shortcut line" "$(run "$H"):$(desk "$H")" "0:0:0:0:no shortcut ma:1"
: > "$ALIAS_CALLS"; check "desktop: have at a terminal: not asked, no make, already there" "$(STUB_ALIAS=have ptya y "$H"):$(desk "$H")" "0:0:1:0:the 14unch3r s:1"
: > "$ALIAS_CALLS"; check "desktop: have with --desktop at none: not asked, no make, already there" "$(STUB_ALIAS=have run "$H" --desktop):$(desk "$H")" "0:0:1:0:the 14unch3r s:1"
: > "$ALIAS_CALLS"; check "desktop: other at a terminal: not asked, no make, left as it is" "$(STUB_ALIAS=other ptya y "$H"):$(desk "$H")" "0:0:1:0:something else:1"
: > "$ALIAS_CALLS"; check "desktop: other with --desktop at none: not asked, no make, left as it is" "$(STUB_ALIAS=other run "$H" --desktop):$(desk "$H")" "0:0:1:0:something else:1"
: > "$ALIAS_CALLS"
check "desktop: failed with a sentence: the could-not-be-made line with that sentence" \
  "$(STUB_ALIAS="failed${TAB}the disk is full" run "$H" --desktop):$(sed -n 's/^Desktop:   //p' "$H.out")" "0:the shortcut could not be made: the disk is full"
: > "$ALIAS_CALLS"; before=$(snap "$H")
check "desktop: --check --desktop: no call at all and nothing written" "$(run "$H" --check --desktop):$(lines "$ALIAS_CALLS"):x$(snap "$H")" "0:0:x$before"
: > "$ALIAS_CALLS"
check "desktop: the window builder exits 1: no call, no Desktop line" "$(STUB_WINDOW_RC=1 run "$H" --desktop):$(lines "$ALIAS_CALLS"):$(said "$H" '^Desktop:'):$(said "$H" '^=== setup complete ===$')" "0:0:0:1"
H2="$T/hd2"; home "$H2"; : > "$ALIAS_CALLS"
check "desktop: a home with no Desktop folder: no call, no line" "$(run "$H2" --desktop):$(lines "$ALIAS_CALLS"):$(said "$H2" '^Desktop:')" "0:0:0"
: > "$ALIAS_CALLS"
check "desktop: a failing patch with --desktop: exit 1 as before, not asked, no call" \
  "$(STUB_FAIL=patch_mkparent.py run "$H" --desktop):$(said "$H" "$Q"):$(lines "$ALIAS_CALLS"):$(said "$H" '^=== setup finished with 1 problem')" "1:0:0:1"
check "desktop: --help names --desktop" "$(bash "$S" --help | grep -c -- '--desktop')" 1

# --- for scripts/install.sh (docs/plans/simple-install.md, 2.6 and NT2)
H="$T/hm"; mkdir -p "$H"
check "--mac-only on a tested Mac with nothing installed: exit 0, before any wrapper line" \
  "$(run "$H" --mac-only):$(said "$H" 'Rosetta 2  *OK$'):$(said "$H" 'Wine wrapper')" "0:1:0"
check "--mac-only with Rosetta missing: exit 1, the missing line" \
  "$(STUB_ROSETTA=1 run "$H" --mac-only):$(said "$H" 'prerequisite(s) missing'):$(said "$H" 'Wine wrapper')" "1:1:0"
check "--mac-only on macOS 15 at a terminal: the paragraph and the question, exit 0" \
  "$(pty "$H" --mac-only):$(said "$H" '^1 caution(s)'):$(said "$H" 'Press Return to continue'):$(said "$H" 'Wine wrapper')" "0:1:1:0"
check "  ...with --yes it is not asked" "$(pty "$H" --mac-only --yes):$(said "$H" 'Press Return')" "0:0"
check "  ...with --check it is not asked" "$(pty "$H" --mac-only --check):$(said "$H" 'Press Return')" "0:0"
check "--help names --mac-only" "$(bash "$S" --help | grep -c -- '--mac-only')" 1
H="$T/hv"; home "$H"
check "CS2_VIA_INSTALLER=1 on macOS 15 at a terminal: not asked again, setup complete" \
  "$(CS2_VIA_INSTALLER=1 pty "$H"):$(said "$H" 'Press Return'):$(said "$H" '^1 caution(s)'):$(said "$H" '=== setup complete ===')" "0:0:1:1"
check "  ...the closing line says to open the installer again after a game update" \
  "$(said "$H" '^After a game update: open the installer again'):$(said "$H" 'bash scripts/setup.sh  (updates')" "1:0"
check "without it: asked, and today's closing line" "$(pty "$H"):$(said "$H" 'Press Return'):$(said "$H" '^After a game update: re-run  bash scripts/setup.sh')" "0:1:1"
mkdir -p "$H/Desktop"
check "CS2_VIA_INSTALLER=1, no shortcut made: the line says to open the installer again" \
  "$(CS2_VIA_INSTALLER=1 run "$H"):$(said "$H" '^Desktop:   no shortcut made. To add one, open the installer again and answer y.$')" "0:1"
check "  ...without it, today's line" "$(run "$H"):$(said "$H" '^Desktop:   no shortcut made. To add one:  bash scripts/setup.sh --desktop$')" "0:1"
H="$T/hf"; home "$H"
check "L1_FETCHED_REF=release: the repo line names the temporary copy" \
  "$(L1_FETCHED_REF=release run "$H"):$(said "$H" '^repo: a temporary copy of macgameport/1launcher at release$')" "0:1"
check "  ...a failing patch says to open the installer again, not git pull" \
  "$(L1_FETCHED_REF=release STUB_FAIL=patch_mkparent.py run "$H"):$(said "$H" 'open the installer'):$(said "$H" 'git pull')" "1:1:0"
check "  ...without it, the checkout and git pull" "$(STUB_FAIL=patch_mkparent.py run "$H"):$(said "$H" 'git pull')" "1:1"
check "  ...a missing prerequisite points at the guide's address" \
  "$(L1_FETCHED_REF=release STUB_ROSETTA=1 run "$H"):$(said "$H" '^Full walkthrough: https://github.com/macgameport/1launcher/blob/main/cities-skylines-2/INSTALL.md$')" "1:1"
H="$T/hp"; home "$H" CS2.app unmarked
check "the lines setup itself prints give the home folder as ~" \
  "$(run "$H" --hide-mod-badges):$(said "$H" "^Installing launcher + patches into ~/$INST\$"):$(said "$H" '^Renamed:   ~/Applications/CS2.app -> ~/Applications/wrapper-949230.app$')" "0:1:1"
check "  ...and none of them holds the home folder whole" \
  "$(grep -E '^(repo:|wrapper:|Installing launcher|  moved:|Renamed:|Full walkthrough)' "$H.out" | grep -c "$H")" 0

# --- a fix not out yet for this build: repatch.sh exits 3 (docs/plans/patch-outcomes.md, 2.4; PT5)
manifest() {   # <home> [buildid]: the game's Steam manifest, two folders above the game's, with that build
  printf '"AppState"\n{\n\t"appid"\t\t"949230"\n\t"buildid"\t\t"%s"\n}\n' "${2:-26404411}" \
    > "$1/Applications/CS2dxmt11.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_949230.acf"
}
CLOSE5='=== setup finished, but not every Mac fix is out yet for this build of the game: see the lines marked >> above ==='
L1='  >> Not every Mac fix works with this build of the game (build 26404411). The NO FIX YET lines'
R_FETCHED='     Open the installer again later: it fetches the newest fixes. Until the fix is out it says this again.'
R_CLONE='     Update your copy (git pull in its folder), then open the installer again. If it says this again, the fix is not out yet.'
R_PLAIN='     Update this checkout (git pull) and run setup again. If it says this again, the fix is not out yet.'
G_LOCAL="     More, and where a fix in progress is listed: \"When a fix is not out yet\" in the guide: $R/INSTALL.md"
G_WEB='     More, and where a fix in progress is listed: "When a fix is not out yet" in the guide: https://github.com/macgameport/1launcher/blob/main/cities-skylines-2/INSTALL.md'
block5() {   # <home>: the >> block, from its first line to the guide's, as printed
  sed -n '/^  >> /,/^     More, and where a fix in progress is listed: /p' "$1.out"
}
H="$T/hn"; home "$H"; manifest "$H"; mkdir -p "$H/Desktop"; : > "$WINDOW_CALLS"
check "no fix yet: exit 5" "$(STUB_NOFIX=patch_cohtml.py run "$H")" 5
check "  ...repatch.sh's NO FIX YET line above, then the >> block with the build from the manifest, six lines" \
  "$(said "$H" '^NO FIX YET FOR THIS BUILD: patch_cohtml.py$'):$(grep -cxF "$L1" "$H.out"):$(block5 "$H" | wc -l | tr -d ' ')" "1:1:6"
cat > "$T/block5.want" << WANT
$L1
     above name each one and say what you may see without it. The other fixes are in place.
     The usual cause: Steam has updated the game, and the Mac fix for the new build is not out yet.
     You can try the game. It may run well, or show what those lines name.
$R_PLAIN
$G_LOCAL
WANT
check "  ...the block word for word, for a plain setup" "$(block5 "$H" | diff - "$T/block5.want" > /dev/null && echo same || echo differs)" same
check "  ...the app built, and the window builder called once" "$(has "$H/Applications/Cities Skylines II.app/Contents/MacOS/launch"):$(lines "$WINDOW_CALLS")" "yes:1"
check "  ...the Desktop step reached and its line shown, with the lines a clean run ends with" "$(said "$H" '^Desktop:   no shortcut made\.'):$(said "$H" '^Play:'):$(said "$H" '^After a game update: ')" "1:1:1"
check "  ...no setup complete, no !!, no problem count, and the closing line last" \
  "$(said "$H" 'setup complete'):$(said "$H" '!!'):$(said "$H" 'problem(s)'):$(tail -n 1 "$H.out")" "0:0:0:$CLOSE5"
rm "$H/Applications/CS2dxmt11.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_949230.acf"
check "no manifest: exit 5, the first line without the parenthesis" \
  "$(STUB_NOFIX=patch_cohtml.py run "$H"):$(said "$H" '^  >> Not every Mac fix works with this build of the game\. The NO FIX YET lines$'):$(said "$H" '(build ')" "5:1:0"
manifest "$H"
check "the installer from a clone (CS2_VIA_INSTALLER=1): its fifth line, and the guide in the checkout" \
  "$(CS2_VIA_INSTALLER=1 STUB_NOFIX=patch_cohtml.py run "$H"):$(block5 "$H" | sed -n 5p):$(block5 "$H" | sed -n 6p)" "5:$R_CLONE:$G_LOCAL"
check "the fetched route (L1_FETCHED_REF): its fifth line, and the guide's web address" \
  "$(L1_FETCHED_REF=release CS2_VIA_INSTALLER=1 STUB_NOFIX=patch_cohtml.py run "$H"):$(block5 "$H" | sed -n 5p):$(block5 "$H" | sed -n 6p)" "5:$R_FETCHED:$G_WEB"
check "a plain setup: its fifth line" "$(STUB_NOFIX=patch_cohtml.py run "$H"):$(block5 "$H" | sed -n 5p)" "5:$R_PLAIN"
check "repatch.sh exits 1 with a NO FIX YET line: exit 1, the !! block with its added sentence, no >> block" \
  "$(STUB_FAIL=patch_mkparent.py STUB_NOFIX=patch_cohtml.py run "$H"):$(said "$H" '^NO FIX YET FOR THIS BUILD: patch_cohtml.py$'):$(said "$H" '^  !! not every patch is in place'):$(said "$H" '^     A NO FIX YET line above, if there is one, names fixes that do not work with this build of the game\.$'):$(said "$H" '^  >> ')" "1:1:1:1:0"
check "  ...and the !! ending last" "$(tail -n 1 "$H.out")" '=== setup finished with 1 problem(s): see the lines marked !! above ==='
check "repatch.sh exits 3 and the app's builder fails: exit 1, both blocks, the !! ending" \
  "$(SETUP_REPO="$T/repo2" STUB_NOFIX=patch_cohtml.py run "$H"):$(said "$H" '^  >> Not every Mac fix'):$(said "$H" '^  !! the app was not built'):$(tail -n 1 "$H.out")" "1:1:1:=== setup finished with 1 problem(s): see the lines marked !! above ==="

# --- an install made before the folders moved (docs/plans/local-files-layout.md, 3.3 and 3.4; LT17, LT18, LT22 to
# LT24, LT26, LT27). The move script's two lsof probes are the stub above.
old() {    # <home> [full]: a fake old install in ~/cs2-patch; with "full", a workspace's things beside it
  mkdir -p "$1/cs2-patch/patches/_vendor"
  echo "old launcher" > "$1/cs2-patch/launch-cs2-dxmt11.sh"; echo old > "$1/cs2-patch/repatch.sh"; echo old > "$1/cs2-patch/patches/patch_old.py"
  if [ "${2:-}" = full ]; then mkdir -p "$1/cs2-patch/evidence/cell" "$1/cs2-patch/revenv"; echo l > "$1/cs2-patch/change-ledger.txt"; echo r > "$1/cs2-patch/launch-cs2.sh"; fi
}
LOCKP="Applications/CS2dxmt11.app/Contents/SharedSupport/prefix/.launcher.lock"
shim() { sed -n 's/^SCRIPT="\(.*\)"$/\1/p' "$1/Applications/Cities Skylines II.app/Contents/MacOS/launch" 2>/dev/null; }
moveline() { sed -n 's/^move: //p' "$1.out"; }
installed() {  # <home> <folder under it>: launcher identical to the repo's : repatch.sh : patch scripts
  echo "$(cmp -s "$R/launchers/launch-cs2-dxmt11.sh" "$1/$2/launch-cs2-dxmt11.sh" && echo same || echo differs):$(has "$1/$2/repatch.sh"):$(ls "$1/$2/patches"/patch_*.py 2>/dev/null | grep -vc patch_old)"
}
DV='CS2_PATCH_DIR=~/cs2-patch'

# LT17: --check says what a run would do, and moves and makes nothing
H="$T/m1"; home "$H"; before=$(snap "$H")
check "LT17 no install: a new install, the data and work lines" "$(run "$H" --check):$(moveline "$H"):$(said "$H" "^data: ~/$INST\$"):$(said "$H" "^work: ~/$WORKSP\$"):x$(snap "$H")" "0:a new install:1:1:x$before"
H="$T/m2"; home "$H"; old "$H" full; before=$(snap "$H")
check "LT17 an old install: will be moved, with the moves" "$(run "$H" --check):$(moveline "$H"):$(said "$H" "^  would move: ~/cs2-patch -> ~/$WORKSP\$"):$(said "$H" "^  would move: ~/cs2-patch/repatch.sh -> ~/$INST/repatch.sh\$"):$(said "$H" '^data: ~/cs2-patch$'):x$(snap "$H")" "0:~/cs2-patch will be moved:1:1:1:x$before"
check "LT17 ...with a skip reason: cannot be moved now, with the reason" "$(STUB_CWD=4242 run "$H" --check):$(moveline "$H"):$(said "$H" '^  skip: a process has its working directory inside ~/cs2-patch'):x$(snap "$H")" "0:~/cs2-patch cannot be moved now:1:x$before"
check "LT17 ...with a stop reason: the same" "$(STUB_OPEN=777 run "$H" --check):$(moveline "$H"):$(said "$H" '^  stop: a script is running from ~/cs2-patch (process 777)'):x$(snap "$H")" "0:~/cs2-patch cannot be moved now:1:x$before"
check "LT17 CS2_PATCH_DIR naming the old folder: stays, named" "$(RUN_ENV="CS2_PATCH_DIR=$H/cs2-patch" run "$H" --check):$(moveline "$H"):x$(snap "$H")" "0:~/cs2-patch stays where it is: a folder was named:x$before"
check "LT17 CS2_PATCH_DIR empty: will be moved" "$(RUN_ENV="CS2_PATCH_DIR=" run "$H" --check):$(moveline "$H")" "0:~/cs2-patch will be moved"
check "LT17 --dest naming another folder: stays, named" "$(run "$H" --check --dest "$H/other"):$(moveline "$H"):$(said "$H" '^data: ~/other$'):x$(snap "$H")" "0:~/cs2-patch stays where it is: a folder was named:1:x$before"
check "LT17 and LT14, a root set elsewhere: stays, and the lines print the scratch roots" "$(RUN_ENV="L1_DATA_ROOT=$T/D L1_WORK_ROOT=$T/W" run "$H" --check):$(moveline "$H"):$(said "$H" "^data: $T/D/cities-skylines-2\$"):$(said "$H" "^work: $T/W/cities-skylines-2\$"):x$(snap "$H")" "0:~/cs2-patch stays where it is: a folder was named:1:1:x$before"
H="$T/m3"; home "$H"; mkdir -p "$H/$INST"; before=$(snap "$H")
check "LT17 an install already moved: no move line" "$(run "$H" --check):$(said "$H" '^move:'):$(said "$H" "^data: ~/$INST\$"):x$(snap "$H")" "0:0:1:x$before"
old "$H"; before=$(snap "$H")
check "LT17 both folders: the warning" "$(run "$H" --check):$(said "$H" "^move: WARNING: ~/cs2-patch and ~/$INST both exist. The app starts: nothing yet\$"):x$(snap "$H")" "0:1:x$before"
H="$T/m4"; home "$H" CS2.app; old "$H" full; sleep 60 & lk=$!; ln -s "$lk" "$H/Applications/CS2.app/Contents/SharedSupport/prefix/.launcher.lock"; before=$(snap "$H")
check "LT17 only CS2.app present and a live lock in it: cannot be moved now, naming the lock" "$(run "$H" --check):$(moveline "$H"):$(said "$H" "^  stop: a launch or an install is using the game's wrapper (process $lk)"):x$(snap "$H")" "0:~/cs2-patch cannot be moved now:1:x$before"
kill "$lk" 2>/dev/null; wait "$lk" 2>/dev/null
H="$T/m5"; home "$H"; old "$H" full; mv "$H/cs2-patch" "$H/real"; ln -s "$H/real" "$H/cs2-patch"; before=$(snap "$H")
check "LT17 ~/cs2-patch a symlink: cannot be moved now, the symlink, and that setup installs beside it" "$(run "$H" --check):$(moveline "$H"):$(said "$H" '^  skip: ~/cs2-patch is a symlink$'):$(said "$H" "^  Setup will install into ~/$INST, and leave the link and what it names alone\.\$"):$(said "$H" "^data: ~/$INST\$"):x$(snap "$H")" "0:~/cs2-patch cannot be moved now:1:1:1:x$before"
H="$T/m6"; home "$H"; old "$H" full; mkdir -p "$T/noprefix.app"; before=$(snap "$H")
check "LT17 CS2_WRAPPER at a folder with no prefix, beside a wrapper of the list that has one: no wrapper is named, exit 1, nothing moved or made" "$(RUN_ENV="CS2_WRAPPER=$T/noprefix.app" run "$H" --check):$(said "$H" 'Wine wrapper  *MISSING$'):$(said "$H" 'Wine wrapper (CS2dxmt11.app)'):x$(snap "$H")" "1:1:0:x$before"
H="$T/m7"; home "$H"; mkdir -p "$H/$INST"; before=$(snap "$H")
check "LT17 CS2_PATCH_DIR naming ~/cs2-patch on an install already moved: exit 1 under --check too, nothing made" "$(RUN_ENV="CS2_PATCH_DIR=$H/cs2-patch" run "$H" --check):$(said "$H" "^  !! This install has already moved to ~/$INST\. Leave $DV out\.\$"):$(said "$H" 'Preflight'):x$(snap "$H")" "1:1:0:x$before"
H="$T/m3"
check "LT17 --mac-only: no data, work or move line" "$(run "$H" --mac-only):$(said "$H" '^data:\|^work:\|^move:')" "0:0"

# LT18: setup whole on a fake old install, in each voice
lt18() {   # <name> <closing line wanted> [environment]: nothing in the way
  local name="$1" want="$2"; shift 2; k=$((${k:-0} + 1)); H="$T/v$k"; home "$H"; old "$H" full
  check "LT18 $name: exit 0, no old folder, the files in the runtime folder, the shim there, the workspace made" \
    "$(RUN_ENV="$*" run "$H"):$(has "$H/cs2-patch"):$(installed "$H" "$INST"):$(shim "$H"):$(has "$H/$WORKSP/evidence/cell"):$(has "$H/$WORKSP/repatch.sh")" "0:no:same:yes:$NPATCH:$H/$INST/launch-cs2-dxmt11.sh:yes:no"
  check "LT18 $name: the closing block has this voice's line that declines, and names what came along" \
    "$(grep -cF -- "$want" "$H.out"):$(said "$H" "^Moved:     what the game runs is now in ~/$INST\$"):$(said "$H" "No longer used, and safe to delete: ~/$INST/launch-cs2.sh\$"):$(said "$H" "safe to delete: ~/$INST/revenv\$")" "1:1:1:1"
}
lt18 "a checkout" "To keep an install in ~/cs2-patch instead: $DV bash scripts/setup.sh"
lt18 "the installer from a clone" "To keep an install in ~/cs2-patch instead: $DV bash scripts/install.sh" CS2_VIA_INSTALLER=1
lt18 "a fetched copy" "To keep an install in ~/cs2-patch instead: put $DV and a space in front of the line you pasted (the whole line: https://github.com/macgameport/1launcher/blob/main/cities-skylines-2/INSTALL.md)" CS2_VIA_INSTALLER=1 L1_FETCHED_REF=release
check "LT20a's literal is in setup once, as one string" "$(grep -c "^DECLINE_VAR='CS2_PATCH_DIR=~/cs2-patch'\$" "$S")" 1
check "LT18 run twice: the second run moves nothing, and has no move line" "$(run "$H"):$(said "$H" 'Moving the install folder'):$(said "$H" '^move:'):$(has "$H/cs2-patch")" "0:0:0:no"
H="$T/k1"; home "$H"; old "$H" full
check "LT18 a skip: exit 0, said, the old folder used and no runtime folder made" "$(STUB_CWD=4242 run "$H"):$(said "$H" '^The install folder was not moved:$'):$(said "$H" '^Setup goes on in ~/cs2-patch\.$'):$(installed "$H" cs2-patch):$(has "$H/$INST"):$(shim "$H"):$(said "$H" '^Not moved: the install folder was left where it is'):$(said "$H" 'in ~/cs2-patch. The next run tries again: run setup again\.$')" "0:1:1:same:yes:$NPATCH:no:$H/cs2-patch/launch-cs2-dxmt11.sh:1:1"
H="$T/k2"; home "$H"; old "$H" full; before=$(snap "$H")
check "LT18 a stop: exit 3, nothing copied, the old launcher's bytes unchanged" "$(STUB_OPEN=777 run "$H"):$(cat "$H/cs2-patch/launch-cs2-dxmt11.sh"):$(said "$H" 'Installing launcher'):x$(snap "$H")" "3:old launcher:0:x$before"
H="$T/k3"; home "$H"; old "$H" full
check "LT18 stopped part-way: exit 1, nothing copied" "$(L1_MOVE_STOP_AFTER=rename run "$H"):$(said "$H" 'To finish the move'):$(said "$H" 'Installing launcher'):$(has "$H/$INST"):$(has "$H/cs2-patch")" "1:1:0:no:no"
check "LT18 ...--check then says this run finishes it" "$(run "$H" --check):$(moveline "$H")" "0:an earlier move stopped part-way; this run finishes it"
check "LT18 ...and the next run ends as a clean move does" "$(run "$H"):$(has "$H/cs2-patch"):$(installed "$H" "$INST"):$(shim "$H"):$(has "$H/$WORKSP/repatch.sh")" "0:no:same:yes:$NPATCH:$H/$INST/launch-cs2-dxmt11.sh:no"
old "$H"
check "LT18 both folders present: it goes on in the runtime folder and warns" "$(run "$H"):$(said "$H" '^move: WARNING: ~/cs2-patch and'):$(said "$H" "^Setup goes on in ~/$INST\.\$"):$(cat "$H/cs2-patch/launch-cs2-dxmt11.sh"):$(shim "$H"):$(said "$H" "^Not moved: ~/cs2-patch and ~/$INST both exist, and setup used the second"):$(said "$H" 'The next run tries again')" "0:1:1:old launcher:$H/$INST/launch-cs2-dxmt11.sh:1:0"
H="$T/k4"; home "$H"; mkdir -p "$H/$INST"; before=$(snap "$H")
check "LT18 the decline line typed on a moved Mac: exit 1, already moved, nothing written" "$(RUN_ENV="CS2_PATCH_DIR=$H/cs2-patch" run "$H"):$(said "$H" "^  !! This install has already moved to ~/$INST\. Leave $DV out\.\$"):x$(snap "$H")" "1:1:x$before"
H="$T/k5"; home "$H"; old "$H" full; mv "$H/cs2-patch" "$H/real"; ln -s "$H/real" "$H/cs2-patch"; before=$(snap "$H/real")
check "LT18 ~/cs2-patch a symlink: a new install in the runtime folder, the link and what it names untouched, and the closing text says so" \
  "$(run "$H"):$(installed "$H" "$INST"):$(shim "$H"):$([ -L "$H/cs2-patch" ] && echo link):x$(snap "$H/real"):$(said "$H" '^Not moved: ~/cs2-patch is a symlink'):$(said "$H" "beside it, in ~/$INST, and the app starts that one")" "0:same:yes:$NPATCH:$H/$INST/launch-cs2-dxmt11.sh:link:x$before:1:1"
H="$T/k6"; home "$H"; old "$H" full
check "LT18 a move followed by a patch pass that fails: exit 1, and the closing block that says where the folder went" \
  "$(STUB_FAIL=patch_mkparent.py run "$H"):$(said "$H" "^Moved:     what the game runs is now in ~/$INST\$"):$(grep -cF -- "To keep an install in ~/cs2-patch instead: $DV bash scripts/setup.sh" "$H.out"):$(has "$H/cs2-patch"):$(tail -n 1 "$H.out")" "1:1:1:no:=== setup finished with 1 problem(s): see the lines marked !! above ==="
H="$T/k7"; home "$H"; old "$H" full
check "LT18 part-way, and the data root then writable by group: the first run stops" "$(L1_MOVE_STOP_AFTER=rename run "$H")" 1
chmod g+w "$(dirname "$H/$INST")"; before=$(snap "$H")
check "LT18 ...--check says it cannot be finished now, with the reason" "$(run "$H" --check):$(moveline "$H"):$(said "$H" '^  skip: .* is not a folder of your own that only you can write to$')" "0:an earlier move stopped part-way and cannot be finished now:1"
check "LT18 ...and the run exits 1: nothing copied, no name lifted" "$(run "$H"):$(said "$H" 'Installing launcher'):$(has "$H/$INST"):x$(snap "$H")" "1:0:no:x$before"

# LT22: the installer holds the wrapper's launch lock while it runs setup. The lock is a symlink to the holder's
# PID, as common/install-core.sh makes it; a holder that has ended leaves a dead lock, which is let through.
held() {   # <home> [environment]: a process takes the lock and runs setup as its own child
  local h="$1"; shift
  $CLEAN "$@" HOME="$h" PATH="$T/bin:$PATH" bash -c 'ln -s $$ "$1" || exit 99; bash "$2" > "$3.out" 2>&1 < /dev/null; exit $?' _ "$h/$LOCKP" "$R/scripts/setup.sh" "$h"; echo $?
}
H="$T/i1"; home "$H"; old "$H"
check "LT22 the lock's holder runs setup with CS2_VIA_INSTALLER=1: moved, exit 0, the installer's words" "$(held "$H" CS2_VIA_INSTALLER=1):$(has "$H/cs2-patch"):$(installed "$H" "$INST"):$(grep -cF "instead: $DV bash scripts/install.sh" "$H.out")" "0:no:same:yes:$NPATCH:1"
H="$T/i2"; home "$H"; old "$H"; before=$(snap "$H")
check "LT22 the same without the variable: exit 3, nothing moved or copied" "$(held "$H"):$(said "$H" "^  !! Setup stops here, before it copies anything:\$"):$(cat "$H/cs2-patch/launch-cs2-dxmt11.sh"):$(has "$H/$INST")" "3:1:old launcher:no"
H="$T/i3"; home "$H"; old "$H"; sleep 60 & third=$!; ln -s "$third" "$H/$LOCKP"; before=$(snap "$H")
check "LT22 with the variable while a third live process holds the lock: exit 3" "$(CS2_VIA_INSTALLER=1 run "$H"):x$(snap "$H")" "3:x$before"
kill "$third" 2>/dev/null; wait "$third" 2>/dev/null

# LT23: the decline reaches setup, and setup stays
H="$T/j1"; home "$H"; old "$H"
check "LT23 CS2_PATCH_DIR naming the old folder, in the fetched voice: stays, moves nothing, named" "$(RUN_ENV="CS2_PATCH_DIR=$H/cs2-patch" L1_FETCHED_REF=release CS2_VIA_INSTALLER=1 run "$H"):$(moveline "$H"):$(installed "$H" cs2-patch):$(has "$H/$INST"):$(said "$H" 'Moving the install folder')" "0:~/cs2-patch stays where it is: a folder was named:same:yes:$NPATCH:no:0"

# LT24: a Mac already moved
H="$T/a1"; home "$H"; mkdir -p "$H/$INST"; : > "$PROBE_CALLS"
check "LT24 only the runtime folder, the fetched voice: exit 0, no move line, no old folder made, no probe called" "$(L1_FETCHED_REF=release CS2_VIA_INSTALLER=1 run "$H"):$(said "$H" '^move:'):$(has "$H/cs2-patch"):$(shim "$H"):$(lines "$PROBE_CALLS")" "0:0:no:$H/$INST/launch-cs2-dxmt11.sh:0"
check "LT24 ...and the installer's voice" "$(CS2_VIA_INSTALLER=1 run "$H"):$(said "$H" '^move:'):$(has "$H/cs2-patch"):$(shim "$H"):$(lines "$PROBE_CALLS")" "0:0:no:$H/$INST/launch-cs2-dxmt11.sh:0"

# LT26: the runtime folder is the user's own
H="$T/o1"; home "$H"; mkdir -p "$H/$INST"; chmod o+w "$H/$INST"
check "LT26 a runtime folder others can write to: exit 1 before copying" "$(run "$H"):$(said "$H" "^  !! ~/$INST is not a folder of your own that only you can write to"):$(has "$H/$INST/launch-cs2-dxmt11.sh")" "1:1:no"
H="$T/o2"; home "$H"
check "LT26 a new install under umask 000: the folders setup makes are not writable by group or others" "$( (umask 000; run "$H") ):$(stat -f %Lp "$H/$INST"):$(stat -f %Lp "$H/$INST/patches"):$(stat -f %Lp "$(dirname "$H/$INST")")" "0:755:755:755"
H="$T/o3"; home "$H"; old "$H"; chmod 777 "$H/cs2-patch" "$H/cs2-patch/patches"; chmod 666 "$H/cs2-patch/launch-cs2-dxmt11.sh" "$H/cs2-patch/repatch.sh"
check "LT26 an old folder of mode 777 whose launcher is mode 666, moved, and then setup: nothing in the runtime folder is writable by group or others" \
  "$(run "$H"):$(has "$H/cs2-patch"):$(find "$H/$INST" -perm +022 | wc -l | tr -d ' '):$(stat -f %Lp "$H/$INST/launch-cs2-dxmt11.sh")" "0:no:0:755"

# LT27: the markers survive, and an opted-in badge stays on
H="$T/b1"; home "$H"; old "$H" full; echo badge > "$H/cs2-patch/patch-modconflict-badge.py"; : > "$H/cs2-patch/patches/.mod-badges-on"; : > "$H/cs2-patch/patches/.compat-noted-28"
check "LT27 both markers and the badge script are in the runtime folder, and the badge patch is on" "$(run "$H"):$(has "$H/$INST/patches/.mod-badges-on"):$(has "$H/$INST/patches/.compat-noted-28"):$(cmp -s "$R/scripts/patch-modconflict-badge.py" "$H/$INST/patch-modconflict-badge.py" && echo same || echo differs):$(said "$H" 'mod badge patch: on (--show-mod-badges turns it off)')" "0:yes:yes:same:1"

# --- docs/plans/wrapper-names.md: WT4b, WT15, WT17, WT14
NEWW="Applications/wrapper-949230.app"
l1p() { plutil -extract L1Prefix raw -o - "$1/Applications/Cities Skylines II.app/Contents/Info.plist" 2>/dev/null; }
wline() { sed -n 's/^wrapper: //p' "$1.out"; }
# WT4b
H="$T/wn1"; home "$H" a.app; home "$H" b.app
check "WT4b two wrappers marked alike: exit 1, the resolver's duplicates line and setup's own, nothing copied" \
  "$(run "$H"):$(said "$H" 'Move one to the Trash, or name the one to use in CS2_WRAPPER.'):$(said "$H" "^  !! Setup stops here, before it changes anything: two wrappers carry the game's marker"):$(has "$H/$INST/launch-cs2-dxmt11.sh")" "1:1:1:no"
# WT15: the deployed copy, and check-deploy.sh counting it (a copy laid out as in the repo, so that its mutant edits a copy)
H="$T/wn2"; home "$H"
check "WT15 after a run the deployed wrappers.sh is there, the same bytes as the repo's" \
  "$(run "$H"):$(cmp -s "$REPO/../common/wrappers.sh" "$H/$INST/wrappers.sh" && echo same)" "0:same"
CDT="$T/cd"; mkdir -p "$CDT/common"; ln -s "$REPO" "$CDT/cities-skylines-2"
cp "$REPO/../common/check-deploy.sh" "$REPO/../common/paths.sh" "$REPO/../common/wrappers.sh" "$REPO/../common/updates.sh" "$CDT/common/"
[ "${CD_MUT:-0}" = 1 ] && { sed -i '' '/^one "\$TOP\/common\/wrappers.sh" wrappers.sh$/d' "$CDT/common/check-deploy.sh"; grep -q 'wrappers.sh wrappers.sh' "$CDT/common/check-deploy.sh" && { echo "REFUSED: mutant did not apply"; exit 2; }; }
rm "$H/$INST/wrappers.sh"
check "WT15 ...check-deploy.sh counts it: a run without it says absent" "$($CLEAN HOME="$H" bash "$CDT/common/check-deploy.sh" 2>/dev/null | grep -c '^  absent:  wrappers.sh$')" 1
# WT17: both moves in one run, from the v0.1.0 layout (an unmarked wrapper under its old name, ~/cs2-patch)
H="$T/wn3"; home "$H" CS2dxmt11.app unmarked; old "$H"
echo old > "$H/cs2-patch/patch-modconflict-badge.py"; : > "$H/Applications/CS2dxmt11.app/$GAME/Cities2_Data/Managed/Game.dll.bak-modconflict-20260827-164900"
before=$(snap "$H")
check "WT17 --check: one wrapper: line with would move and both names, exit 0, nothing changed" \
  "$(run "$H" --check):$(wline "$H"):x$(snap "$H")" "0:would move: ~/Applications/CS2dxmt11.app -> ~/Applications/wrapper-949230.app:x$before"
check "WT17 both moves in one run: the folder moved, the wrapper renamed and marked" \
  "$(run "$H"):$(has "$H/cs2-patch"):$(has "$H/$INST/launch-cs2-dxmt11.sh"):$(has "$H/Applications/CS2dxmt11.app"):$(plutil -extract L1Role raw -o - "$H/$NEWW/Contents/Info.plist" 2>/dev/null)" "0:no:yes:no:game-wrapper"
check "  ...the app's launch file names the runtime folder, its L1Prefix the renamed wrapper" "$(shim "$H")|$(l1p "$H")" "$H/$INST/launch-cs2-dxmt11.sh|$H/$NEWW/Contents/SharedSupport/prefix"
check "  ...the badge step looked in the renamed wrapper" "$(said "$H" 'mod badge patch: on, as before')" 1
check "  ...setup said what it renamed, both names, and how to decline" \
  "$(said "$H" '^Renamed:   ~/Applications/CS2dxmt11.app -> ~/Applications/wrapper-949230.app$'):$(said "$H" 'L1_KEEP_WRAPPER_NAMES=1 bash scripts/setup.sh')" "1:1"
check "  ...--check on the home now moved: nothing to rename" "$(run "$H" --check):$(wline "$H")" "0:nothing to rename"
H="$T/wn4"; home "$H" CS2dxmt11.app unmarked; old "$H"; before=$(snap "$H")
check "WT17 a stop comes first: a holder of the wrapper's files: exit 3, the folder not moved, nothing copied" \
  "$(RUN_ENV="STUB_WHOLDERS=4242" run "$H"):$(said "$H" '^  stop: the game or Steam is using'):$(has "$H/cs2-patch"):$(has "$H/$INST"):x$(snap "$H")" "3:1:yes:no:x$before"
H="$T/wn5"; home "$H" a.app; home "$H" b.app
mkdir -p "$T/nowr/common"; cp -R "$R" "$T/nowr/repo"; cp "$T/common/paths.sh" "$T/common/updates.sh" "$T/common/games.tsv" "$T/nowr/common/"
check "WT17 --mac-only with two marked alike and no wrappers.sh in common/: as today" "$(SETUP_REPO="$T/nowr/repo" run "$H" --mac-only)" 0
check "WT17 --mac-only with two marked alike: the resolver is not asked, exit 0" "$(run "$H" --mac-only):$(said "$H" 'two wrappers carry')" "0:0"
# WT14: S734M.app rebuilt after a move, never made where it was not, a foreign one left alone
H="$T/wn6"; home "$H" CS2dxmt11.app unmarked
SW="$H/Applications/CS2dxmt11-pk110.app"; mkdir -p "$SW/Contents/SharedSupport/wine/bin" "$SW/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam"
printf '#!/bin/bash\necho wine-11.0\n' > "$SW/Contents/SharedSupport/wine/bin/wine64"; chmod +x "$SW/Contents/SharedSupport/wine/bin/wine64"
: > "$SW/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steam.exe"
printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string></dict></plist>' > "$SW/Contents/Info.plist"
$CLEAN HOME="$H" PATH="$T/bin:$PATH" bash "$R/scripts/make-steam-shortcut.sh" --wrapper "$SW" > /dev/null 2>&1
stw() { sed -n 's/^WRAPPER=//p' "$1/Applications/S734M.app/Contents/MacOS/launch" 2>/dev/null; }
check "WT14 (the fixture) S734M.app built for the store wrapper under its old name" "$(stw "$H")" "$SW"
check "WT14 after a move the rebuilt S734M.app's launch file names the renamed store wrapper" \
  "$(run "$H"):$(stw "$H"):$(has "$SW")" "0:$H/Applications/wrapper-0.app:no"
H="$T/wn7"; home "$H"
check "WT14 no store wrapper and no S734M.app before: none after, and no wrapper cloned" \
  "$(run "$H"):$(has "$H/Applications/S734M.app"):$(ls "$H/Applications" | grep -c 'wrapper-0\|pk110')" "0:no:0"
H="$T/wn8"; home "$H"; SW="$H/Applications/store.app"; cp -R "$T/wn6/Applications/wrapper-0.app" "$SW"
$CLEAN HOME="$H" PATH="$T/bin:$PATH" bash "$R/scripts/make-steam-shortcut.sh" --wrapper "$SW" > /dev/null 2>&1; rm -rf "$SW"
check "WT14 S734M.app there and its store wrapper gone: no wrapper cloned, and it says so" \
  "$(run "$H"):$(ls -d "$H"/Applications/*.app/Contents/SharedSupport | wc -l | tr -d ' '):$(said "$H" 'not built: there is no storefront wrapper')" "0:1:1"
H="$T/wn9"; home "$H"; mkdir -p "$H/Applications/S734M.app/Contents"; echo mine > "$H/Applications/S734M.app/Contents/x"
check "WT14 a foreign S734M.app is not touched" "$(run "$H"):$(cat "$H/Applications/S734M.app/Contents/x")" "0:mine"

# --- the record of which version this game was set up from (docs/plans/built-in-update.md, 3.1 and 3.3; UT5 and
# "UT5, also"). The clock is L1_UPDATE_NOW; the tree's version is the first version heading of $T/CHANGELOG.md.
NOW=1800000000; NOW2=1800000777; VER=v0.4.2; HEX=0123456789abcdef0123456789abcdef01234567
STAMP="$UPD/installed/949230"
stampof() { cat "$1/$STAMP" 2>/dev/null; }
stateof() { $CLEAN HOME="$1" bash "$1/$UPD/updates.sh"; }   # the deployed tool, asked as a launcher or the window asks it
snapu() { if [ -d "$1/$UPD" ]; then (cd "$1/$UPD" && { find . | LC_ALL=C sort; find . -type f -exec shasum {} +; } | shasum | cut -c1-12); else echo none; fi; }
H="$T/u1"; home "$H"; : > "$WINDOW_CALLS.tool"
check "UT5 a setup that finishes: exit 0, and the stamp holds checkout, the tree's version, no commit and the time" \
  "$(RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H"):$(stampof "$H")" "0:checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "UT5 ...the deployed updates.sh is byte for byte the tree's, and nothing written beside a place is left" \
  "$(cmp -s "$T/common/updates.sh" "$H/$UPD/updates.sh" && echo same):$(find "$H/$UPD" "$H/$INST" -name '*.new.*' -o -name '.put.*' | wc -l | tr -d ' ')" "same:0"
check "UT5 ...update-dir beside the launcher holds the folder's path, one line" "$(cat "$H/$INST/update-dir"):$(lines "$H/$INST/update-dir")" "$H/$UPD:1"
check "UT5 ...the folders setup made are the user's own: no group or other may write" "$(stat -f %Lp "$H/$UPD"):$(stat -f %Lp "$H/$UPD/installed")" "755:755"
check "UT5, also: updates.sh was there when the window's builder was called" "$(cat "$WINDOW_CALLS.tool")" there
check "UT5 ...a checkout's state is manual, with checkout as its detail" "$(stateof "$H")" "manual${TAB}$VER${TAB}-${TAB}checkout"
check "UT5 ...and nothing is said of another game: none is set up here" "$(said "$H" 'was set up by an older version')" 0
ln "$H/$STAMP" "$T/keep.stamp"
check "UT5 with L1_FETCHED_REF=release and L1_FETCHED_COMMIT: the stamp holds release and that commit" \
  "$(L1_FETCHED_REF=release RUN_ENV="L1_UPDATE_NOW=$NOW2 L1_FETCHED_COMMIT=$HEX" run "$H"):$(stampof "$H")" "0:release${TAB}$VER${TAB}$HEX${TAB}$NOW2"
check "UT5 ...written beside its place and renamed: a second name of the old stamp still holds the old line" "$(cat "$T/keep.stamp")" "checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "UT5 ...with no offer fetched yet the state is unknown" "$(stateof "$H")" "unknown${TAB}$VER${TAB}-${TAB}-"
check "UT5 with L1_FETCHED_REF=v0.2.0: that line in the stamp, and the state is manual with it as the detail" \
  "$(L1_FETCHED_REF=v0.2.0 RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H"):$(stampof "$H" | cut -f1,4):$(stateof "$H")" "0:v0.2.0${TAB}$NOW:manual${TAB}$VER${TAB}-${TAB}v0.2.0"
# a setup that fails or stops writes no stamp, and leaves an older one as it was
old="$(stampof "$H")"
check "UT5 a failing patch script: exit 1, the older stamp as it was" "$(RUN_ENV="L1_UPDATE_NOW=$NOW2" STUB_FAIL=patch_mkparent.py run "$H"):$(stampof "$H")" "1:$old"
check "UT5 a failing app builder: exit 1, the older stamp as it was" "$(RUN_ENV="L1_UPDATE_NOW=$NOW2" SETUP_REPO="$T/repo2" run "$H"):$(stampof "$H")" "1:$old"
H="$T/u2"; home "$H"
check "UT5 a failing patch script on a new install: exit 1, no stamp" "$(STUB_FAIL=patch_mkparent.py run "$H"):$(has "$H/$STAMP")" "1:no"
H="$T/u3"; home "$H"
check "UT5 a failing app builder on a new install: exit 1, no stamp" "$(SETUP_REPO="$T/repo2" run "$H"):$(has "$H/$STAMP")" "1:no"
H="$T/u4"; home "$H"; old "$H" full
check "UT5 a setup that stops (exit 3, a script running from the old folder): nothing of the record is made" "$(STUB_OPEN=777 run "$H"):$(has "$H/$UPD"):$(has "$H/cs2-patch/update-dir")" "3:no:no"
# --check, --mac-only and --dest touch nothing of the record
H="$T/u5"; home "$H"
check "UT5 --check on a new install: no record folder, no update-dir" "$(run "$H" --check):$(has "$H/$UPD"):$(has "$H/$INST/update-dir")" "0:no:no"
check "UT5 --mac-only: the same" "$(run "$H" --mac-only):$(has "$H/$UPD")" "0:no"
check "UT5 --dest: exit 0, installed there, and nothing of the record: no folder, no update-dir beside that launcher" \
  "$(run "$H" --dest "$H/other"):$(has "$H/other/launch-cs2-dxmt11.sh"):$(has "$H/$UPD"):$(has "$H/other/update-dir")" "0:yes:no:no"
H="$T/u1"; before="$(snapu "$H")"
check "UT5 --check, --mac-only and --dest on a home that has a record: every file of it as it was" \
  "$(RUN_ENV="L1_UPDATE_NOW=$NOW2" run "$H" --check):$(RUN_ENV="L1_UPDATE_NOW=$NOW2" run "$H" --mac-only):$(RUN_ENV="L1_UPDATE_NOW=$NOW2" run "$H" --dest "$H/other"):$(snapu "$H")" "0:0:0:$before"
# exit 5 is a finished setup: it writes a stamp
H="$T/u6"; home "$H"; manifest "$H"
check "UT5 a fix not out yet (exit 5): the stamp is written" "$(RUN_ENV="L1_UPDATE_NOW=$NOW" STUB_NOFIX=patch_cohtml.py run "$H"):$(stampof "$H")" "5:checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "UT5 ...and the closing line for exit 5 is still the last" "$(tail -n 1 "$H.out")" "$CLOSE5"
# the record's folders are the user's own, or setup stops before it writes anything
NOTOWN='is not a folder of your own that only you can write to; setup will not keep its record of versions there\.$'
H="$T/u7"; home "$H"; mkdir -p "$H/$UPD"; chmod g+w "$H/$UPD"; before=$(snap "$H")
check "UT5 a record folder the group can write to: exit 1, said, and nothing written" "$(run "$H"):$(said "$H" "^  !! ~/$UPD $NOTOWN"):x$(snap "$H")" "1:1:x$before"
H="$T/u8"; home "$H"; mkdir -p "$H/$UPD/installed"; chmod o+w "$H/$UPD/installed"; before=$(snap "$H")
check "UT5 ...installed/ in it writable by others: the same" "$(run "$H"):$(said "$H" "^  !! ~/$UPD/installed $NOTOWN"):x$(snap "$H")" "1:1:x$before"
H="$T/u9"; home "$H"; mkdir -p "$T/rec9"; chmod 777 "$T/rec9"; before=$(snap "$H")
check "UT5 ...L1_UPDATE_DIR naming a folder inside one that others can write to: the same, and that folder stays empty" \
  "$(RUN_ENV="L1_UPDATE_DIR=$T/rec9/_update" run "$H"):$(said "$H" "^  !! $T/rec9 $NOTOWN"):x$(snap "$H"):$(ls -A "$T/rec9" | wc -l | tr -d ' ')" "1:1:x$before:0"
chmod 755 "$T/rec9"
check "UT5 ...made the user's own, the record goes there, and update-dir names it" "$(RUN_ENV="L1_UPDATE_DIR=$T/rec9/_update" run "$H"):$(has "$T/rec9/_update/installed/949230"):$(cat "$H/$INST/update-dir"):$(has "$H/$UPD")" "0:yes:$T/rec9/_update:no"
# a stamp that cannot be written is said, and changes no exit code
H="$T/u14"; home "$H"; mkdir -p "$H/$UPD/installed"; chmod 555 "$H/$UPD/installed"
check "UT5 installed/ cannot be written to: the sentence, with the home folder as ~, no stamp, and setup's exit code is kept" \
  "$(run "$H"):$(said "$H" "^  !! This version could not be recorded (~/$STAMP)\. 14unch3r will not offer updates for this game\.\$"):$(has "$H/$STAMP"):$(said "$H" '^=== setup complete ===$')" "0:1:no:1"
chmod 755 "$H/$UPD/installed"
# setup's own files: the tool and the table of games
OWNF="Open the installer again, or run setup from a whole checkout\.\$"
for gone in updates.sh games.tsv; do
  mkdir -p "$T/gone-$gone/common"; cp -R "$R" "$T/gone-$gone/repo"
  for f in "$T/common"/*; do [ "$(basename "$f")" = "$gone" ] || cp "$f" "$T/gone-$gone/common/"; done
  HB="$T/hgone-$gone"; home "$HB"; before=$(snap "$HB")
  check "UT5 common/$gone missing from the tree: exit 1 in the own-files words, before the header, and nothing written" \
    "$(SETUP_REPO="$T/gone-$gone/repo" run "$HB"):$(said "$HB" "^  !! setup's own files are missing (.*common/$gone). $OWNF"):$(grep -cE 'Preflight|^===|No such file' "$HB.out"):x$(snap "$HB")" "1:1:0:x$before"
  check "UT5 ...with --mac-only that run is outside the check: exit 0" "$(SETUP_REPO="$T/gone-$gone/repo" run "$HB" --mac-only):$(said "$HB" "setup's own files")" "0:0"
done
# the closing words name every other game that is set up on this Mac and has no stamp
other() {   # <home> [noprogram]: a Surviving Mars wrapper under its new name, marked, with the game's program in it
  local a="$1/Applications/wrapper-3215050.app"; local g="$a/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark"
  mkdir -p "$a/Contents/SharedSupport/wine/bin" "$g"
  printf '#!/bin/bash\necho wine-10.0\n' > "$a/Contents/SharedSupport/wine/bin/wine64"; chmod +x "$a/Contents/SharedSupport/wine/bin/wine64"
  [ "${2:-}" = noprogram ] || : > "$g/Mars.exe"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>L1Role</key><string>game-wrapper</string><key>L1SteamAppID</key><integer>3215050</integer></dict></plist>' > "$a/Contents/Info.plist"
}
OLDER='was set up by an older version\. Paste its installer line once, so that it gets updates too\.$'
H="$T/u10"; home "$H"; other "$H"
check "UT5 another game set up with no stamp: named in the closing words, by its title in the tree's table" "$(run "$H"):$(said "$H" "^Surviving Mars: Relaunched $OLDER"):$(said "$H" "$OLDER")" "0:1:1"
check "UT5, also: its wrapper variable naming a path that does not exist: still named" "$(RUN_ENV="SM_WRAPPER=$T/no-such.app" run "$H"):$(said "$H" "^Surviving Mars: Relaunched $OLDER")" "0:1"
check "UT5 ...and with exit 5 too, above the closing line" "$(STUB_NOFIX=patch_cohtml.py run "$H"):$(said "$H" "^Surviving Mars: Relaunched $OLDER"):$(tail -n 1 "$H.out")" "5:1:$CLOSE5"
sed -i '' "s/${TAB}Surviving Mars: Relaunched${TAB}/${TAB}A Title From The Table${TAB}/" "$T/common/games.tsv"
check "UT5 ...the title is the third field of that ID's row" "$(run "$H"):$(said "$H" "^A Title From The Table $OLDER")" "0:1"
cp "$REPO/../common/games.tsv" "$T/common/games.tsv"
check "UT5 ...--dest writes no record, so it names no game" "$(run "$H" --dest "$H/other"):$(said "$H" "$OLDER")" "0:0"
printf 'release\t%s\t-\t100\n' "$VER" > "$H/$UPD/installed/3215050"
check "UT5 ...a game that has a stamp is not named" "$(run "$H"):$(said "$H" "$OLDER")" "0:0"
H="$T/u11"; home "$H"; other "$H" noprogram
check "UT5 ...a wrapper without the game's program is not a game set up: not named" "$(run "$H"):$(said "$H" "$OLDER")" "0:0"
# under an update nobody is watching for the Desktop question: it is neither looked at nor asked
H="$T/u12"; home "$H"; mkdir -p "$H/Desktop"
: > "$ALIAS_CALLS"; check "UT5 L1_UPDATE=1 at a terminal: the Desktop question is not asked, no call at all, the no-shortcut line" "$(L1_UPDATE=1 ptya y "$H"):$(desk "$H")" "0:0:0:0:no shortcut ma:1"
: > "$ALIAS_CALLS"; check "UT5 ...without it, on the same home: asked" "$(ptya n "$H"):$(desk "$H")" "0:1:1:0:no shortcut ma:1"
# check-deploy.sh counts the record's tool and update-dir (the copy laid out as in the repo, above)
H="$T/u13"; home "$H"
check "UT5 check-deploy.sh after a run: the tool and update-dir are found and identical" "$(run "$H"):$($CLEAN HOME="$H" bash "$CDT/common/check-deploy.sh" 2>/dev/null | grep -cE '_update/updates\.sh|update-dir')" "0:0"
mv "$H/$UPD/updates.sh" "$T/tool.aside"; echo elsewhere > "$H/$INST/update-dir"
check "UT5 ...without the tool, and with update-dir naming another folder: absent, and differs" \
  "$($CLEAN HOME="$H" bash "$CDT/common/check-deploy.sh" 2>/dev/null | grep -cE '^  (absent:  _update/updates\.sh|differs: update-dir)$')" 2

# --- 14unch3r's own stamp (docs/plans/launcher-first-install.md, 3.5; LFT5): the file `launcher` of the record's
# folder, written on the line after a build of the window that worked, and by nothing else
LSTAMP="$UPD/launcher"
lstampof() { cat "$1/$LSTAMP" 2>/dev/null; }
lsum() { if [ -e "$1/$LSTAMP" ]; then shasum < "$1/$LSTAMP" | cut -c1-12; else echo none; fi; }
older() { mkdir -p "$1/$UPD/installed"; printf 'release\t%s\t%s\t100\n' "$2" "$HEX" > "$1/$LSTAMP"; }   # <home> <version>
STAYS='^  14unch3r stays at v0\.0\.9\. It will go on offering this update until it can be built: the line above says why\.$'
NOLSTAMP="^  !! 14unch3r's version could not be recorded (~/$LSTAMP)\. It may go on offering an update it already has\.\$"
H="$T/l1"; home "$H"
check "LFT5 a setup whose window builder exits 0: the launcher's stamp holds checkout, the tree's version, no commit and the time" \
  "$(RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H"):$(lstampof "$H")" "0:checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "LFT5 ...nothing is said of a version that stays or of a stamp not written, and nothing written beside a place is left" \
  "$(said "$H" '14unch3r stays at'):$(said "$H" 'could not be recorded'):$(find "$H/$UPD" -name '.put.*' | wc -l | tr -d ' ')" "0:0:0"
check "LFT5 with L1_FETCHED_REF=release and L1_FETCHED_COMMIT: it holds release and that commit, and the state is unknown at the tree's version" \
  "$(L1_FETCHED_REF=release RUN_ENV="L1_UPDATE_NOW=$NOW2 L1_FETCHED_COMMIT=$HEX" run "$H"):$(lstampof "$H"):$(stateof "$H")" "0:release${TAB}$VER${TAB}$HEX${TAB}$NOW2:unknown${TAB}$VER${TAB}-${TAB}-"
# --check, --mac-only and --dest write nothing of it (the window's builder is still run under --dest, and exits 0)
before="$(snapu "$H")"; : > "$WINDOW_CALLS"
check "LFT5 --check, --mac-only and --dest on that home: the launcher's stamp and every other file of the record as they were" \
  "$(RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H" --check):$(RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H" --mac-only):$(RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H" --dest "$H/other"):$(snapu "$H"):$(lstampof "$H" | cut -f4)" "0:0:0:$before:$NOW2"
check "LFT5 ...the builder was run by the --dest run, and nothing is said of the launcher's version" "$(lines "$WINDOW_CALLS"):$(said "$H" 'could not be recorded'):$(said "$H" 'command not found')" "1:0:0"
H="$T/l1b"; home "$H"
check "LFT5 --dest on a new install: the builder exits 0 and no launcher's stamp is written" "$(run "$H" --dest "$H/other"):$(has "$H/$UPD"):$(said "$H" 'could not be recorded')" "0:no:0"
# a build that failed leaves an older stamp as it is, and says so; the setup's exit code and the game's own stamp are as ever
for rc in 3 1; do
  H="$T/l2-$rc"; home "$H"; older "$H" v0.0.9; old="$(lsum "$H")"
  check "LFT5 the window builder exits $rc with an older launcher stamp there: exit 0, that stamp byte for byte, the game's own stamp written" \
    "$(L1_FETCHED_REF=release RUN_ENV="L1_UPDATE_NOW=$NOW STUB_WINDOW_RC=$rc" run "$H"):$([ "$(lsum "$H")" = "$old" ] && echo same):$(stampof "$H" | cut -f1,2,4)" "0:same:release${TAB}$VER${TAB}$NOW"
  check "LFT5 ...the line that 14unch3r stays at its version is said once, right after the not-built line, and setup completes" \
    "$(said "$H" "$STAYS"):$(grep -A1 '^  window: not built (see the line above)$' "$H.out" | tail -n 1 | grep -c "$STAYS"):$(said "$H" '^=== setup complete ===$'):$(said "$H" 'setup finished with')" "1:1:1:0"
  check "LFT5 ...and the installed version stays the launcher's older one" "$(stateof "$H")" "unknown${TAB}v0.0.9${TAB}-${TAB}-"
done
H="$T/l3"; home "$H"
check "LFT5 the same with no older stamp: no launcher's stamp, no such line, the game's own stamp written" \
  "$(RUN_ENV="L1_UPDATE_NOW=$NOW STUB_WINDOW_RC=3" run "$H"):$(has "$H/$LSTAMP"):$(said "$H" '14unch3r stays at'):$(stampof "$H" | cut -f2,4)" "0:no:0:$VER${TAB}$NOW"
H="$T/l4"; home "$H"; older "$H" "$VER"; old="$(lsum "$H")"
check "LFT5 a stamp at this tree's own version and a build that failed: the stamp as it was, and no such line (no update is held back)" \
  "$(STUB_WINDOW_RC=3 run "$H"):$([ "$(lsum "$H")" = "$old" ] && echo same):$(said "$H" '14unch3r stays at')" "0:same:0"
H="$T/l5"; home "$H"; older "$H" v0.0.9; old="$(lsum "$H")"; cp "$T/CHANGELOG.md" "$T/nocommon/"   # that tree has a version too
check "LFT5 no window builder in the checkout, with an older stamp there: the stamp as it was, and the line said once" \
  "$(SETUP_REPO="$T/nocommon/repo" run "$H"):$([ "$(lsum "$H")" = "$old" ] && echo same):$(said "$H" "$STAYS")" "0:same:1"
H="$T/l6"; home "$H"; older "$H" v0.0.9; old="$(lsum "$H")"
check "LFT5 a build that worked replaces an older stamp, and says nothing of staying" \
  "$(L1_FETCHED_REF=release RUN_ENV="L1_UPDATE_NOW=$NOW" run "$H"):$(lstampof "$H" | cut -f1,2,4):$(said "$H" '14unch3r stays at')" "0:release${TAB}$VER${TAB}$NOW:0"
H="$T/l7"; home "$H"
check "LFT5 a launcher's stamp that cannot be written (a fetched ref that is no line): said once, no stamp, and setup's exit code is kept" \
  "$(L1_FETCHED_REF='a b' run "$H"):$(said "$H" "$NOLSTAMP"):$(has "$H/$LSTAMP"):$(said "$H" '^=== setup complete ===$')" "0:1:no:1"

echo "$fails failure(s)"
[ "$fails" = 0 ]
