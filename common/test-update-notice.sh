#!/bin/bash
# test-update-notice.sh -- what the update-notice block of each launcher does (docs/plans/built-in-update.md,
# 3.6): at a start it asks the update tool whether a new version of 1launcher is out, says so with one note, and
# starts the daily look at GitHub in the background without waiting for it. From each launcher it takes the
# block alone, puts it between `set -u`, a note that records, and two lines that show what the block left
# behind, and runs that extract with /bin/bash (3.2.57 on macOS, as the launchers are) from a folder whose path
# has a space, with `update-dir` beside it. The update tool is a stand-in that records how it was called;
# programs named cat, dirname and bash that record and fail come first on PATH, as a Wine engine's bin does in
# a launcher. HOME and TMPDIR are scratch folders and L1_UPDATE_DIR is unset, as at a start. In the last cases
# the tool is the real common/updates.sh on a scratch folder, with a curl that records. No launcher is run:
# no game, no Steam, no Wine, no network.
# That the two copies of the block are equal, and where each lies, is common/test-launcher-parity.sh, rule 11.
#   bash common/test-update-notice.sh            exit 0 = every case passed; exit 2 = a launcher or its block is missing
#   MUTANT=1 ...   the `&` dropped: the look at GitHub is waited for; must exit 1
#   MUTANT=2 ...   the note made unconditional; must exit 1
#   MUTANT=3 ...   the test of the path dropped: a relative path in update-dir is taken; must exit 1
#   MUTANT=4 ...   the match of the answer made `[ -n ]`: any text reaches note; must exit 1
#   MUTANT=5 ...   /bin/cat made cat; must exit 1
#   MUTANT=6 ...   /usr/bin/dirname made dirname; must exit 1
#   MUTANT=7 ...   /bin/bash made bash in the call of --noted; must exit 1
#   MUTANT=8 ...   the test for a link dropped: a tool that is a link is run; must exit 1
#   MUTANT=9 ...   the look's output no longer sent to /dev/null; must exit 1
#   MUTANT=10 ...  the unset line dropped: the three variables stay behind; must exit 1
# Every mutant is applied to the copies of both launchers, never to a launcher itself.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/update-notice-test.XXXX)"
trap 'rm -rf "$T"' EXIT
R="$T/Application Support"   # the deployed launchers and the update folder lie under a path with a space
GAMES=("cities-skylines-2/launchers/launch-cs2-dxmt11.sh" "surviving-mars-relaunched/launch-relaunched.sh")
mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
mutate() {   # <file> <sed expression> <fixed text that proves it applied>
  sed -i '' "$2" "$1"; grep -qF -- "$3" "$1" || mutated
}
drop() {   # <file> <the line, whole>: the line is there once, and then it is gone
  [ "$(grep -cxF -- "$2" "$1")" = 1 ] || mutated
  grep -vxF -- "$2" "$1" > "$1.new" && mv "$1.new" "$1"
  grep -qxF -- "$2" "$1" && mutated
}
un() { sed -n '/^# >>> update-notice (/,/^# <<< update-notice$/p' "$1"; }
n=0
for f in "${GAMES[@]}"; do
  n=$((n + 1))
  [ -f "$HERE/$f" ] || { echo "REFUSED: $f not found under $HERE"; exit 2; }
  L="$T/launcher.$n.sh"; cp "$HERE/$f" "$L"
  un "$L" | grep -q '^# <<< update-notice$' || { echo "REFUSED: no update-notice block in $f"; exit 2; }
  case "${MUTANT:-0}" in
    0) ;;
    1) mutate "$L" 's/ --refresh < \/dev\/null > \/dev\/null 2>&1 & )$/ --refresh < \/dev\/null > \/dev\/null 2>\&1 )/' ' --refresh < /dev/null > /dev/null 2>&1 )' ;;
    2) mutate "$L" 's/^  \[\[ "\$_l1v" =~ \$_l1p \]\] && note "1launcher /  note "1launcher /' '  note "1launcher $_l1v is out.' ;;
    3) drop "$L" 'case "$_l1u" in /*) ;; *) _l1u="" ;; esac' ;;
    4) mutate "$L" 's/^  \[\[ "\$_l1v" =~ \$_l1p \]\] && note "1launcher /  [ -n "$_l1v" ] \&\& note "1launcher /' '  [ -n "$_l1v" ] && note "1launcher $_l1v is out.' ;;
    5) mutate "$L" 's/^_l1u="\$(\/bin\/cat "/_l1u="$(cat "/' '_l1u="$(cat "$(CDPATH= cd -- ' ;;
    6) mutate "$L" '/^_l1u="\$(\/bin\/cat "/s/"\$(\/usr\/bin\/dirname -- /"$(dirname -- /' '_l1u="$(/bin/cat "$(CDPATH= cd -- "$(dirname -- ' ;;
    7) mutate "$L" 's/^  _l1v="\$(\/bin\/bash "/  _l1v="$(bash "/' '  _l1v="$(bash "$_l1u/updates.sh" --noted ' ;;
    8) mutate "$L" 's/^if \[ -n "\$_l1u" \] && \[ -f "\$_l1u\/updates\.sh" \] && \[ ! -L "\$_l1u\/updates\.sh" \]; then$/if [ -n "$_l1u" ] \&\& [ -f "$_l1u\/updates.sh" ]; then/' 'if [ -n "$_l1u" ] && [ -f "$_l1u/updates.sh" ]; then' ;;
    9) mutate "$L" 's/ --refresh < \/dev\/null > \/dev\/null 2>&1 & )$/ --refresh < \/dev\/null \& )/' ' --refresh < /dev/null & )' ;;
    10) drop "$L" 'unset _l1u _l1v _l1p' ;;
    *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
  esac
  mkdir -p "$R/game.$n"
  {
    printf '%s\n' 'set -u' 'note() { printf "NOTE %s\n" "$1"; }'
    un "$L"
    printf '%s\n' 'echo "after: ${_l1u-unset} ${_l1v-unset} ${_l1p-unset}"' 'IFS= read -r _in; echo "input: $_in"'
  } > "$R/game.$n/extract.sh"
done

# the stand-in for updates.sh: a line per call in the case's `calls`, with the label of the copy that was run
mktool() {   # <folder> <label>
  mkdir -p "$1"
  cat > "$1/updates.sh" <<EOF
#!/bin/bash
printf '%s\n' "$2 \$*" >> "\$CASE/calls"
case "\${1:-}" in
  --noted) echo "noted-stderr" >&2; [ -n "\${TOOL_SAYS:-}" ] && printf '%s\n' "\$TOOL_SAYS"; exit "\${TOOL_RC:-0}" ;;
  --refresh)
    echo "refresh-stdout"; echo "refresh-stderr" >&2
    IFS= read -r line; echo "\$?:\$line" > "\$CASE/stdin"
    if [ -n "\${TOOL_SLEEP:-}" ]; then echo \$\$ > "\$CASE/pid"; exec /bin/sleep "\$TOOL_SLEEP"; fi
    echo done > "\$CASE/done" ;;
esac
exit 0
EOF
}
mkdir -p "$T/bin" "$T/home" "$T/tmp" "$T/cwd" "$R/none" "$R/linked"
mktool "$R/_update" tool                 # the one update-dir names
mktool "$T/cwd/rel/_update" relative     # where a relative path would lead from the folder the extract is run in
mktool "$T/cwd" cwd
mktool "$R/game.1" beside; mktool "$R/game.2" beside
ln -s "$R/_update/updates.sh" "$R/linked/updates.sh"
for p in cat dirname bash; do printf '#!/bin/sh\necho "%s $*" >> "$CASE/stray"\nexit 1\n' "$p" > "$T/bin/$p"; chmod +x "$T/bin/$p"; done
printf '#!/bin/sh\necho "curl $*" >> "$CURL_CALLS"\nexit 7\n' > "$T/bin/curl-stub"; chmod +x "$T/bin/curl-stub"
echo typed > "$T/input"

k=0; C=""; EL=0
settle() {   # the look of the last run has finished, or is asleep (up to 10 s)
  local i=0
  while [ "$i" -lt 100 ]; do { [ -e "$C/done" ] || [ -s "$C/pid" ]; } && return 0; /bin/sleep 0.1; i=$((i + 1)); done
  return 1
}
drive() {   # <game number> [NAME=value ...]: runs the extract; what it printed is in $C/out and $C/err, the tool's calls in $C/calls
  local g="$1" t0; shift
  k=$((k + 1)); C="$T/case.$k"; mkdir -p "$C"; : > "$C/calls"; : > "$C/stray"
  t0=$SECONDS
  ( cd "$T/cwd" && env -u L1_UPDATE_DIR -u L1_UPDATE_NOW -u L1_CURL -u TOOL_SAYS -u TOOL_RC -u TOOL_SLEEP "$@" \
      HOME="$T/home" TMPDIR="$T/tmp" PATH="$T/bin:$PATH" CASE="$C" \
      /bin/bash "$R/game.$g/extract.sh" > "$C/out" 2> "$C/err" < "$T/input" )
  EL=$((SECONDS - t0))
  [ -s "$C/calls" ] && settle
  return 0
}
point() { printf '%s\n' "$2" > "$R/game.$1/update-dir"; }   # <game number> <what update-dir holds>
out() { tr '\n' '|' < "$C/out"; }
calls() { tr '\n' '|' < "$C/calls"; }
stray() { tr '\n' '|' < "$C/stray"; }
errs() { wc -c < "$C/err" | tr -d ' '; }
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
SENT='NOTE 1launcher v0.4.0 is out. Open the 14unch3r app to update.'
AFTER='after: unset unset unset|input: typed|'   # the start goes on, the three variables are unset, its input is untouched
ASKED='tool --noted|tool --refresh|'

n=0
for f in "${GAMES[@]}"; do
  n=$((n + 1)); tag="${f##*/}:"

  # --- the tool prints a version
  point "$n" "$R/_update"
  drive "$n" TOOL_SAYS=v0.4.0
  check "$tag the tool prints a version: exactly one note, 3.6's sentence to the letter" "$(grep -c '^NOTE ' "$C/out"):$(grep -cxF -- "$SENT" "$C/out")" "1:1"
  check "$tag   ...the tool update-dir names was asked --noted and then --refresh, once each, and no other" "$(calls)" "$ASKED"
  check "$tag   ...nothing else is printed, the start goes on, and the three variables are unset" "$(out)" "$SENT|$AFTER"
  check "$tag   ...the look's output goes nowhere, and nothing reaches standard error" "$(cat "$C/out" "$C/err" | grep -c -e refresh-std -e noted-stderr):$(errs)" "0:0"
  check "$tag   ...the look reads nothing of the start's input" "$(cat "$C/stdin" 2>/dev/null)" "1:"
  check "$tag   ...with cat, dirname and bash that fail first on PATH: none of them was called" "$(stray)" ""
  drive "$n" TOOL_SAYS=v10.0.123456
  check "$tag a version of several digits: one note with it" "$(out)" "NOTE 1launcher v10.0.123456 is out. Open the 14unch3r app to update.|$AFTER"

  # --- the tool prints nothing, or something that is not one version and nothing else
  quiet() {   # <name> [NAME=value ...]
    local name="$1"; shift
    drive "$n" "$@"
    check "$tag the tool $name: no note, the look is still started, no error" "$(grep -c NOTE "$C/out"):$(calls):$(out):$(errs)" "0:$ASKED:$AFTER:0"
  }
  quiet "prints nothing"
  quiet "fails and prints nothing" TOOL_RC=1
  quiet "prints v0.04.0" TOOL_SAYS=v0.04.0
  quiet "prints a version with words after it" "TOOL_SAYS=v0.4.0 is out"
  quiet "prints two lines, each a version" "TOOL_SAYS=$(printf 'v0.4.0\nv0.4.1')"
  quiet "prints a word that is not a version" TOOL_SAYS=ready

  # --- the look is never waited for. A guard ends the sleeping tool after 5 s, so that a block that waits
  #     costs this test seconds and not half a minute.
  NEXT="$T/case.$((k + 1))"
  ( /bin/sleep 5; [ -s "$NEXT/pid" ] && kill "$(cat "$NEXT/pid")" ) > /dev/null 2>&1 < /dev/null &
  guard=$!
  drive "$n" TOOL_SAYS=v0.4.0 TOOL_SLEEP=30
  alive=no; [ -s "$C/pid" ] && kill -0 "$(cat "$C/pid")" 2>/dev/null && alive=yes
  check "$tag a tool that sleeps 30 s on --refresh: the block returns within 2 s, the tool still asleep, the note said" \
    "$([ "$EL" -le 2 ] && echo yes || echo "no, $EL s"):$alive:$(out)" "yes:yes:$SENT|$AFTER"
  [ -s "$C/pid" ] && kill "$(cat "$C/pid")" 2>/dev/null
  kill "$guard" 2>/dev/null; wait "$guard" 2>/dev/null

  # --- nothing to run: other copies of the tool lie beside the extract, in the folder it is run in, and where
  #     a relative path would lead, and none of them is taken
  idle() {   # <name>
    drive "$n" TOOL_SAYS=v0.4.0
    check "$tag $1: nothing is run, no note, no error, and the start goes on" "$(calls):$(out):$(errs):$(stray)" ":$AFTER:0:"
  }
  rm -f "$R/game.$n/update-dir";      idle "no update-dir"
  : > "$R/game.$n/update-dir";        idle "an empty update-dir"
  point "$n" "rel/_update";           idle "a relative path in update-dir"
  point "$n" "$R/none";               idle "a folder with no updates.sh"
  point "$n" "$R/absent";             idle "a folder that does not exist"
  point "$n" "$R/linked";             idle "a tool that is a link"
done

# --- the parts joined: the real common/updates.sh, two games set up from v0.3.0 and v0.3.1 on offer. The notice
#     is said at the first two starts, whichever games they are, and not at the third. `tried` is a moment ago,
#     so the look fetches nothing; were it to, curl is a stand-in that records.
[ -f "$HERE/common/updates.sh" ] || { echo "REFUSED: common/updates.sh not found under $HERE"; exit 2; }
U="$R/real/_update"; mkdir -p "$U/installed"; chmod 700 "$U" "$U/installed"
cp "$HERE/common/updates.sh" "$U/updates.sh"
printf 'release\tv0.3.0\t-\t1000\n' > "$U/installed/949230"
printf 'release\tv0.3.0\t-\t1000\n' > "$U/installed/3215050"
printf 'v0.3.1\t1000\n' > "$U/offer"; echo 1000 > "$U/tried"
: > "$T/curl-calls"
REAL=""
for g in 1 2 1; do
  point "$g" "$U"
  drive "$g" L1_UPDATE_NOW=2000 L1_CURL="$T/bin/curl-stub" CURL_CALLS="$T/curl-calls"
  REAL="$REAL$(out)$(errs)/"
done
i=0; while [ "$i" -lt 100 ] && pgrep -f "$U/updates.sh" > /dev/null 2>&1; do /bin/sleep 0.1; i=$((i + 1)); done
JOINED='NOTE 1launcher v0.3.1 is out. Open the 14unch3r app to update.|'"$AFTER"0/
check "the real tool, a newer version on offer: a note at the first start, at the second (the other game), and none at the third" \
  "$REAL" "$JOINED$JOINED${AFTER}0/"
check "  ...the tool recorded the two notices, and the look fetched nothing within a day of the last" \
  "$(cat "$U/noted" 2>/dev/null | tr '\t' ' '):$(wc -l < "$T/curl-calls" | tr -d ' '):$(cat "$U/tried")" "v0.3.1 2:0:1000"

echo "$fails failure(s)"
[ "$fails" = 0 ]
