#!/bin/bash
# test-updates.sh -- common/updates.sh (docs/plans/built-in-update.md, 3.1 and 3.2; tests UT3 and UT4), with
# its folder at a scratch place, L1_UPDATE_NOW as the clock and L1_CURL a stub that honours -o and -w as curl
# does: the body goes to the file and the answer's code to standard output. For --open (3.4), L1_OPEN is a
# stub that records its arguments and TMPDIR a scratch folder; what the written file does when it is run is
# common/test-update-games.sh's. No network, nothing of Wine, no Terminal.
#   bash common/test-updates.sh            exit 0 = every case passed
#   MUTANT=1 ...  versions compared as text; must exit 1
#   MUTANT=2 ...  ready when the offer is different, not when it is newer; must exit 1
#   MUTANT=3 ...  the highest installed version taken, not the lowest; must exit 1
#   MUTANT=4 ...  the manual rule dropped; must exit 1
#   MUTANT=5 ...  "unknown" asked before "manual"; must exit 1
#   MUTANT=6 ...  the match before the comparison dropped; must exit 1
#   MUTANT=7 ...  `tried` not written; must exit 1
#   MUTANT=8 ...  the script's own size check dropped; must exit 1
#   MUTANT=9 ...  a `tried` after now counted as recent; must exit 1
#   MUTANT=10 ..  the state not asked before the fetch; must exit 1
#   MUTANT=11 ..  installed/ not tested for being the player's own; must exit 1
#   MUTANT=12 ..  one fixed name for the fetched file; must exit 1
#   MUTANT=13 ..  --noted not writing `noted`; must exit 1
#   MUTANT=14 ..  a failed fetch made to exit 1; must exit 1
#   MUTANT=15 ..  -q dropped from curl's options; must exit 1
#   MUTANT=16 ..  the address made the short `release` form; must exit 1
#   MUTANT=17 ..  the PATH of the functions that run programs left as the caller's; must exit 1
#   MUTANT=18 ..  the offer lowered by an older answer; must exit 1
#   MUTANT=19 ..  the second read of a file dropped; must exit 1
#   MUTANT=20 ..  a commit left in the environment recorded for a checkout; must exit 1
#   MUTANT=21 ..  --open not asking the state first (a file written and opened when no update waits); must exit 1
#   MUTANT=22 ..  `opened` said when Terminal could not be opened; must exit 1
#   MUTANT=23 ..  L1_CURL written into the update's file unmatched; must exit 1
# (24 and 25: docs/plans/launcher-first-install.md, 3.5; LFT3, the stamp.)
#   MUTANT=24 ..  the launcher's stamp left out of the state; must exit 1
#   MUTANT=25 ..  the launcher's stamp read without its match; must exit 1
# (26 to 29: the same plan, 3.8; LFT13, the lock's rule in shell, and --open during an install.)
#   MUTANT=26 ..  the start's rule dropped (a link older than the Mac's last start read as live); must exit 1
#   MUTANT=27 ..  the read-back after a take dropped; must exit 1
#   MUTANT=28 ..  a game file left by another holder not removed at a take; must exit 1
#   MUTANT=29 ..  --open's refusal during an install dropped; must exit 1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d /tmp/updates-test.XXXX)"
trap 'rm -rf "$T"' EXIT
S="$T/updates.sh"; cp "$HERE/updates.sh" "$S"
mutate() {  # <sed expression> <grep that proves it applied>
  sed -i '' "$1" "$S"; grep -q -- "$2" "$S" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  0) ;;
  1) mutate 's#^    \[ "\$((10\#\$a))" -gt "\$((10\#\$b))" \] && return 0$#    [[ "$a" > "$b" ]] \&\& return 0#' '^    \[\[ "\$a" > "\$b" \]\] && return 0$'
     mutate 's#^    \[ "\$((10\#\$a))" -lt "\$((10\#\$b))" \] && return 1$#    [[ "$a" < "$b" ]] \&\& return 1#' '^    \[\[ "\$a" < "\$b" \]\] && return 1$' ;;
  2) mutate 's#^  if l1u_newer "\$L1U_OFFERED" "\$low"; then L1U_WORD=ready; else L1U_WORD=current; fi$#  if [ "$L1U_OFFERED" != "$low" ]; then L1U_WORD=ready; else L1U_WORD=current; fi#' '^  if \[ "\$L1U_OFFERED" != "\$low" \]; then L1U_WORD=ready' ;;
  3) mutate 's#^    if \[ -z "\$low" \] || l1u_newer "\$low" "\$ver"; then low="\$ver"; fi$#    if [ -z "$low" ] || l1u_newer "$ver" "$low"; then low="$ver"; fi#' 'l1u_newer "\$ver" "\$low"; then low=' ;;
  4) mutate 's#^    \[ -z "\$manual" \] && \[ "\$line" != release \] && manual="\$line"$#    :#' '^    :$' ;;
  5) mutate 's#^  if \[ -n "\$manual" \]; then L1U_WORD=manual; L1U_DETAIL="\$manual"; return 0; fi$#  if [ "$L1U_OFFERED" = - ]; then L1U_WORD=unknown; return 0; fi; if [ -n "$manual" ]; then L1U_WORD=manual; L1U_DETAIL="$manual"; return 0; fi#' '^  if \[ "\$L1U_OFFERED" = - \]; then L1U_WORD=unknown; return 0; fi; if ' ;;
  6) mutate 's#^  _l1u_is_version "\$x" && _l1u_is_version "\$y" || return 1$#  :#' '^  :$' ;;
  7) mutate 's#^  _l1u_put "\$L1_UPDATE_DIR/tried" "\$now" || return 0$#  :#' '^  :$' ;;
  8) mutate 's#^  if \[ "\$rc" = 0 \] && \[ "\$code" = 200 \] && \[\[ "\$size" =~ \$_L1U_SIZE \]\] && \[ "\$size" -le 1048576 \] \\$#  if [ "$rc" = 0 ] \&\& [ "$code" = 200 ] \\#' '^  if \[ "\$rc" = 0 \] && \[ "\$code" = 200 \] \\$' ;;
  9) mutate 's#^    if \[ "\$t" -le "\$now" \] && \[ "\$((now - t))" -lt 86400 \]; then return 0; fi$#    if [ "$((now - t))" -lt 86400 ]; then return 0; fi#' '^    if \[ "\$((now - t))" -lt 86400 \]; then return 0; fi$' ;;
  10) mutate 's#^  case "\$L1U_WORD" in off|none|manual) return 0 ;; esac$#  :#' '^  :$' ;;
  11) mutate 's#^  _l1u_own1 "\$L1_UPDATE_DIR" && _l1u_own1 "\$L1_UPDATE_DIR/installed"$#  _l1u_own1 "$L1_UPDATE_DIR"#' '^  _l1u_own1 "\$L1_UPDATE_DIR"$' ;;
  12) mutate 's#^  tmp="\$(mktemp "\$L1_UPDATE_DIR/.fetch.XXXXXX" 2>/dev/null)" || return 0$#  tmp="$L1_UPDATE_DIR/.fetch.one"#' '^  tmp="\$L1_UPDATE_DIR/.fetch.one"$' ;;
  13) mutate 's#^  _l1u_put "\$L1_UPDATE_DIR/noted" .*#  :#' '^  :$' ;;
  14) mutate 's#^      l1u_refresh "\${2:-}"; _l1u_state$#      l1u_refresh "${2:-}"; [ "$L1U_FETCH" = failed ] \&\& exit 1; _l1u_state#' 'L1U_FETCH" = failed \] && exit 1; _l1u_state$' ;;
  15) mutate 's#"\$curl" -q --proto#"$curl" --proto#' '"\$curl" --proto' ;;
  16) mutate 's#1launcher/refs/heads/release/CHANGELOG.md#1launcher/release/CHANGELOG.md#' "1launcher/release/CHANGELOG.md'" ;;
  17) sed -i '' 's#local PATH=/usr/bin:/bin:/usr/sbin:/sbin#local _unused=#' "$S"; grep -q 'local PATH=' "$S" && { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  18) mutate 's#^    if l1u_newer "\$have" "\$ver"; then$#    if false; then#' '^    if false; then$' ;;
  19) mutate 's#IFS= read -r more || r2=1; }#r2=1; }#' 'rest || true; r2=1; }' ;;
  20) mutate 's#^  \[ "\$line" != checkout \] && \[\[ "\${L1_FETCHED_COMMIT:-}"#  [[ "${L1_FETCHED_COMMIT:-}"#' '^  \[\[ "\${L1_FETCHED_COMMIT:-}" =~ \$_L1U_COMMIT \]\] && commit=' ;;
  21) mutate 's#^  if \[ "\$L1U_WORD" != ready \]; then printf .failed.t%s.n. "No update is waiting\."; return 0; fi$#  :#' '^  :$' ;;
  22) mutate 's#^  if ! "\${L1_OPEN:-/usr/bin/open}" -a Terminal "\$f" > /dev/null 2>&1; then$#  "${L1_OPEN:-/usr/bin/open}" -a Terminal "$f" > /dev/null 2>\&1; if false; then#' '-a Terminal "\$f" > /dev/null 2>&1; if false; then$' ;;
  23) mutate 's#^  \[\[ "\${L1_CURL:-}" =~ \$_L1U_PROG \]\] && curl="\$L1_CURL"$#  [ -n "${L1_CURL:-}" ] \&\& curl="$L1_CURL"#' '^  \[ -n "\${L1_CURL:-}" \] && curl="\$L1_CURL"$' ;;
  24) mutate 's#^  if _l1u_stamp_ok "\$L1_UPDATE_DIR/launcher"; then printf .*#  :#' '^  :$' ;;
  25) mutate 's#^  if _l1u_stamp_ok "\$L1_UPDATE_DIR/launcher"; then printf #  if _l1u_read "$L1_UPDATE_DIR/launcher" 4; then printf #' '^  if _l1u_read "\$L1_UPDATE_DIR/launcher" 4; then printf ' ;;
  26) mutate 's#^    \[ "\$((10\#\$t))" -ge "\$boot" \] || return 1$#    :#' '^    :$' ;;
  27) mutate 's#^  if \[ ! -L "\$f" \] || \[ "\$(readlink "\$f" 2>/dev/null)" != "\$\$" \]; then$#  if false; then#' '^  if false; then$' ;;
  28) mutate 's#^  \[ "\$1" = installing \] \&\& rm -f "\$L1_UPDATE_DIR/installing-game" 2>/dev/null$#  : not removed#' '^  : not removed$'
      grep -c '^  : not removed$' "$S" | grep -qx 2 || { echo "REFUSED: mutant did not apply"; exit 2; }
      perl -0pi -e 's/(l1u_lock_release\(\) \{.*?)  : not removed\n/$1  [ "\$1" = installing ] \&\& rm -f "\$L1_UPDATE_DIR\/installing-game" 2>\/dev\/null\n/s' "$S"
      grep -c '^  : not removed$' "$S" | grep -qx 1 || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  29) mutate 's#^  if l1u_lock_live installing; then printf .failed.t%s.n. "An install is running in Terminal\. .*#  : no refusal#' '^  : no refusal$' ;;
  *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
esac
bash -n "$S" || { echo "REFUSED: the mutant does not parse"; exit 2; }

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
TAB=$'\t'
U="$T/u"; CALLS="$T/calls"; export CALLS
mkdir -p "$T/bin"
cat > "$T/bin/curl" << 'C'
#!/bin/bash
echo "CURL $*" >> "$CALLS"
out=""; w=0; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2 ;; -w) w=1; shift 2 ;; *) shift ;; esac; done
code="${STUB_CODE:-200}"
if [ "$code" = 200 ] && [ -n "$out" ]; then
  if [ -n "${STUB_SLOW:-}" ]; then
    half=$(( $(wc -c < "$STUB_BODY") / 2 ))
    head -c "$half" "$STUB_BODY" > "$out"; /bin/sleep "$STUB_SLOW"; tail -c +"$((half + 1))" "$STUB_BODY" >> "$out"
  else cat "$STUB_BODY" > "$out"; fi
elif [ "$code" != 000 ] && [ -n "$out" ]; then echo "$code: an error page" > "$out"; fi
[ "$w" = 1 ] && printf '%s' "$code"
exit "${STUB_EXIT:-0}"
C
chmod +x "$T/bin/curl"
NOW=1800000000
fresh() { rm -rf "$U"; mkdir -p "$U/installed"; chmod 700 "$U" "$U/installed"; : > "$CALLS"; }
stamp() { printf '%s\t%s\t%s\t%s\n' "$2" "$3" "${4:--}" "${5:-100}" > "$U/installed/$1"; }   # <id> <line> <version> [commit] [time]
offer() { printf '%s\t%s\n' "$1" "${2:-200}" > "$U/offer"; }
tool() { env L1_UPDATE_DIR="$U" L1_CURL="$T/bin/curl" L1_UPDATE_NOW="${NOWAT:-$NOW}" STUB_BODY="${BODY:-$T/body.md}" bash "$S" "$@"; }
fn() { ( L1_UPDATE_DIR="$U"; . "$S"; "$@" ); }   # a function of the file, in a subshell
calls() { grep -c '^CURL' "$CALLS"; }
sum() { [ -e "$1" ] && shasum "$1" | cut -c1-12 || echo none; }
fetchleft() { ls -A "$U" | grep -c '^\.fetch\.\|^\.put\.'; }
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.3.0 (2026-11-24)' '' 'Three.' '' '## v0.2.0 (2026-11-17)' '' 'Two.' > "$T/body.md"

# --- UT3: the version of a file
check "the first version heading under Unreleased" "$(fn l1u_version_of "$T/body.md")" v0.3.0
printf '%s\n' '# Changelog' '## Unreleased' 'words' > "$T/none.md"
check "no version heading: nothing, and 1" "$(fn l1u_version_of "$T/none.md"; echo ":$?")" ":1"
check "a file that is not there: 1" "$(fn l1u_version_of "$T/nope.md"; echo ":$?")" ":1"
for bad in '## v0.03.0 (2026-01-01)' '## v1.2.3.4 (2026-01-01)' '## v1.2.3' '### v1.2.3 (2026-01-01)' '## v1.2.1234567 (2026-01-01)' ' ## v1.2.3 (2026-01-01)'; do
  printf '%s\n' "$bad" > "$T/bad.md"
  check "not a version heading: $bad" "$(fn l1u_version_of "$T/bad.md"; echo ":$?")" ":1"
  printf '%s\n' "$bad" '## v0.1.0 (2026-01-01)' > "$T/bad.md"
  check "  ...and the next real one is taken" "$(fn l1u_version_of "$T/bad.md")" v0.1.0
done
{ head -c 1048576 /dev/zero | tr '\0' 'x'; printf '\n## v9.9.9 (2026-01-01)\n'; } > "$T/far.md"
check "a heading after the first 1 MiB is not read" "$(fn l1u_version_of "$T/far.md"; echo ":$?")" ":1"
printf '## v0.4.0 (2026-01-01)' > "$T/nonl.md"
check "a heading on a last line with no newline is read" "$(fn l1u_version_of "$T/nonl.md")" v0.4.0

# --- UT3: newer
nw() { fn l1u_newer "$1" "$2"; echo $?; }
check "v0.10.0 is newer than v0.9.9" "$(nw v0.10.0 v0.9.9)" 0
check "v0.9.9 is not newer than v0.10.0" "$(nw v0.9.9 v0.10.0)" 1
check "v1.0.0 is newer than v0.99.99" "$(nw v1.0.0 v0.99.99)" 0
check "equal is not newer" "$(nw v0.3.0 v0.3.0)" 1
check "a version is newer than -" "$(nw v0.0.1 -)" 0
check "- is not newer than a version, nor than -" "$(nw - v0.0.1):$(nw - -)" "1:1"
check "a seven-digit number is not a version" "$(nw v1.0.1234567 v1.0.0)" 1
check "a value that would run a command in an arithmetic place is not a version, and runs nothing" \
  "$(nw 'v1.0.a[$(touch '"$T"'/ran1)]' v1.0.0):$(nw v1.0.0 'a[$(touch '"$T"'/ran1)]'):$([ -e "$T/ran1" ] && echo ran || echo none)" "1:1:none"

# --- UT3: the state line, each word in 3.2's order
fresh; offer v0.3.0
check "no stamp, with an offer: none" "$(tool)" "none$TAB-${TAB}v0.3.0$TAB-"
fresh; stamp 949230 checkout v0.3.0
check "a checkout stamp and no offer: manual, with the detail checkout" "$(tool)" "manual${TAB}v0.3.0$TAB-${TAB}checkout"
fresh; stamp 949230 release v0.3.0; stamp 3215050 v0.2.0 v0.2.0; offer v0.4.0
check "one stamp on a named version beside a release one: manual, the lowest installed, the detail that line" "$(tool)" "manual${TAB}v0.2.0${TAB}v0.4.0${TAB}v0.2.0"
fresh; stamp 949230 release v0.3.0
check "a release stamp and no offer: unknown" "$(tool)" "unknown${TAB}v0.3.0$TAB-$TAB-"
fresh; stamp 949230 release v0.3.0; stamp 3215050 release v0.2.0; offer v0.3.0
check "two release stamps at different versions: the lower is the installed one, and the offer is ready" "$(tool)" "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-"
fresh; stamp 949230 release v0.3.0; offer v0.3.0
check "the offer equal to the installed version: current" "$(tool)" "current${TAB}v0.3.0${TAB}v0.3.0$TAB-"
fresh; stamp 949230 release v0.3.0; offer v0.2.0
check "an offer older than the installed version: current" "$(tool)" "current${TAB}v0.3.0${TAB}v0.2.0$TAB-"
fresh; stamp 949230 release -; offer v0.1.0
check "a stamp with no version is lower than every version: ready" "$(tool)" "ready$TAB-${TAB}v0.1.0$TAB-"
fresh; stamp 949230 release v0.2.0; offer v0.3.0; : > "$U/off"
check "the file off: off, whatever else is there" "$(tool)" "off$TAB-${TAB}v0.3.0$TAB-"
fresh; stamp 30 release v0.3.0; stamp 4 v0.1.0 v0.1.0; stamp 200 other v0.2.0
check "manual's detail is the first such stamp in the order of the IDs as numbers" "$(tool | cut -f1,4)" "manual${TAB}v0.1.0"

# --- UT3: what is passed over in installed/, and values that fail their match
fresh; offer v0.3.0
stamp 949230 release v0.2.0; mv "$U/installed/949230" "$T/real-stamp"; ln -s "$T/real-stamp" "$U/installed/949230"
mkdir "$U/installed/111"
printf 'release\tv0.2.0\t-\t100\nrelease\tv0.2.0\t-\t100\n' > "$U/installed/222"
printf 'release\tv0.2.0\t-\t100\textra\n' > "$U/installed/333"
{ printf 'release\tv0.2.0\t-\t100\n'; head -c 5000 /dev/zero | tr '\0' ' '; } > "$U/installed/444"
printf 'release\tv0.2.0\t-\t100\n' > "$U/installed/notanid"
printf 'release\tv0.2.0\t-\t100\n\n' > "$U/installed/555"
printf 'release\tv0.2.0\tnot-a-commit\t100\n' > "$U/installed/666"
check "a link, a folder, two lines, five fields, 5,000 bytes, a name that is no ID, an empty second line, a bad commit: all passed over" "$(tool)" "none$TAB-${TAB}v0.3.0$TAB-"
for v in 'a[$(touch '"$T"'/ran2)]' v0.08.1 v1.2.3x 123456789012345678901234567890; do
  fresh; printf 'release\t%s\t-\t100\n' "$v" > "$U/installed/949230"; printf '%s\t200\n' "$v" > "$U/offer"
  check "a stamp and an offer whose version is $v: passed over and absent" "$(tool):$([ -e "$T/ran2" ] && echo ran || echo none)" "none$TAB-$TAB-$TAB-:none"
done
fresh; printf 'release\tv0.2.0\t-\ta[$(touch %s/ran3)]\n' "$T" > "$U/installed/949230"
check "a stamp whose time would run a command: passed over, nothing run" "$(tool | cut -f1):$([ -e "$T/ran3" ] && echo ran || echo none)" "none:none"
fresh; printf 'release\tv0.2.0\t-\t100' > "$U/installed/949230"
check "a stamp with no final newline counts" "$(tool | cut -f1,2)" "unknown${TAB}v0.2.0"

# --- the stamp, written by a setup (plan 3.1), and what is read back of it
HEX=0123456789abcdef0123456789abcdef01234567
mkdir -p "$T/tree" "$T/bare"; cp "$T/body.md" "$T/tree/CHANGELOG.md"
st() { ( export L1_UPDATE_DIR="$U" L1_UPDATE_NOW="$NOW"; "$@"; . "$S"; l1u_stamp 949230 "${TREE:-$T/tree}"; echo "rc=$?" ); }
fresh
check "a stamp from a checkout: the line checkout, the tree's version, no commit, the time" "$(st true):$(cat "$U/installed/949230")" "rc=0:checkout${TAB}v0.3.0$TAB-$TAB$NOW"
check "  ...and nothing is left beside it" "$(ls -A "$U/installed" | tr '\n' ' ')" "949230 "
fresh
check "a stamp from a fetch: the ref and the commit" "$(st export L1_FETCHED_REF=release L1_FETCHED_COMMIT=$HEX):$(cat "$U/installed/949230")" "rc=0:release${TAB}v0.3.0$TAB$HEX$TAB$NOW"
fresh
check "a commit left in the environment says nothing about a checkout" "$(st export L1_FETCHED_COMMIT=$HEX):$(cut -f1,3 "$U/installed/949230")" "rc=0:checkout$TAB-"
fresh
check "a fetched ref with a commit that is not 40 hex digits: recorded with no commit" "$(st export L1_FETCHED_REF=v0.2.0 L1_FETCHED_COMMIT=xyz):$(cut -f1,3 "$U/installed/949230")" "rc=0:v0.2.0$TAB-"
fresh
check "a ref that is not a line: 1, nothing written" "$(st export 'L1_FETCHED_REF=a b'):$(ls -A "$U/installed" | wc -l | tr -d ' ')" "rc=1:0"
fresh
check "a tree with no changelog: the version is -" "$(TREE="$T/bare" st true):$(cut -f2 "$U/installed/949230")" "rc=0:-"
fresh; chmod 770 "$U/installed"
check "an installed/ the group can write: 1, nothing written" "$(st true):$(ls -A "$U/installed" | wc -l | tr -d ' ')" "rc=1:0"
fresh; stamp 949230 release v0.2.0; stamp 3215050 checkout v0.3.0
check "l1u_stamp_of: the line and the version of a game's stamp; 1 for a game with none, and for a name that is no ID" \
  "$(fn l1u_stamp_of 949230):$(fn l1u_stamp_of 3215050):$(fn l1u_stamp_of 777; echo "rc=$?"):$(fn l1u_stamp_of '../x'; echo "rc=$?")" "release${TAB}v0.2.0:checkout${TAB}v0.3.0:rc=1:rc=1"

# --- LFT3 (docs/plans/launcher-first-install.md, 3.5): 14unch3r's own stamp, the file `launcher`, counts in the
# state as a game's does, is read by the same match, and has a writer and a reader of its own
lstamp() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "${3:--}" "${4:-100}" > "$U/launcher"; }   # <line> <version> [commit] [time]
fresh; lstamp release v0.2.0
check "LFT3 the launcher's stamp alone, on release, with no offer: unknown" "$(tool)" "unknown${TAB}v0.2.0$TAB-$TAB-"
check "LFT3 ...and a refresh calls curl, once" "$(tool --refresh | cut -f1,5):$(calls)" "ready${TAB}fetched:1"
fresh; lstamp release v0.2.0; offer v0.3.0
check "LFT3 ...with a newer offer: ready" "$(tool)" "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-"
fresh; lstamp release v0.3.0; offer v0.3.0
check "LFT3 ...with the offer at its version: current" "$(tool)" "current${TAB}v0.3.0${TAB}v0.3.0$TAB-"
fresh; lstamp checkout v0.3.0; offer v0.4.0
check "LFT3 ...on checkout: manual, with the detail checkout, and nothing is fetched" "$(tool):$(tool --refresh --now | cut -f5):$(calls)" "manual${TAB}v0.3.0${TAB}v0.4.0${TAB}checkout:skipped:0"
fresh; lstamp release v0.2.0; stamp 949230 release v0.3.0; stamp 3215050 release v0.4.0; offer v0.3.0
check "LFT3 beside game stamps at a higher version: the installed version is the launcher's, and the offer is ready" "$(tool)" "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-"
fresh; lstamp release v0.4.0; stamp 949230 release v0.3.0; offer v0.3.0
check "LFT3 ...beside a game at a lower version: the game's, and current" "$(tool)" "current${TAB}v0.3.0${TAB}v0.3.0$TAB-"
fresh; lstamp checkout v0.3.0; stamp 949230 release v0.3.0; offer v0.4.0
check "LFT3 a launcher built from a checkout beside a game on release: manual" "$(tool)" "manual${TAB}v0.3.0${TAB}v0.4.0${TAB}checkout"
fresh; stamp 4 v0.1.0 v0.1.0; lstamp other v0.2.0
check "LFT3 manual's detail is a game's line before the launcher's: its row comes after the games'" "$(tool | cut -f1,4)" "manual${TAB}v0.1.0"
fresh; lstamp release v0.2.0; offer v0.3.0; : > "$U/off"
check "LFT3 the file off: off, with the launcher's stamp there too" "$(tool)" "off$TAB-${TAB}v0.3.0$TAB-"
fresh; lstamp release v0.2.0 "$HEX" 55; stamp 949230 checkout v0.3.0
check "LFT3 l1u_stamp_of_launcher: its line and its version, whatever the games' stamps say" "$(fn l1u_stamp_of_launcher; echo "rc=$?")" "release${TAB}v0.2.0
rc=0"
check "LFT3 ...and l1u_stamp_of still takes an app ID and nothing else" "$(fn l1u_stamp_of launcher; echo "rc=$?")" "rc=1"
fresh
check "LFT3 ...with no such file: nothing, and 1" "$(fn l1u_stamp_of_launcher; echo "rc=$?")" "rc=1"
passed() {   # <name>: the launcher file as the caller left it counts for nothing, to the state and to the reader
  check "LFT3 a launcher file that $1: passed over, the state is none, the reader says 1, nothing ran" \
    "$(tool):$(fn l1u_stamp_of_launcher; echo "rc=$?"):$([ -e "$T/ran8" ] && echo ran || echo none)" "none$TAB-${TAB}v0.3.0$TAB-:rc=1:none"
}
fresh; offer v0.3.0; printf 'release\tv0.2.0\t-\t100\n' > "$T/real-launcher"; ln -s "$T/real-launcher" "$U/launcher"; passed "is a link"
fresh; offer v0.3.0; printf 'release\tv0.2.0\t-\t100\nrelease\tv0.2.0\t-\t100\n' > "$U/launcher"; passed "has two lines"
fresh; offer v0.3.0; printf 'release\tv0.2.0\t-\t100\textra\n' > "$U/launcher"; passed "has five fields"
fresh; offer v0.3.0; printf 'release\ta[$(touch %s/ran8)]\t-\t100\n' "$T" > "$U/launcher"; passed "has a version that would run a command"
fresh; offer v0.3.0; printf 'release\tv0.2.0\tnot-a-commit\t100\n' > "$U/launcher"; passed "has a commit that is no commit"
fresh; offer v0.3.0; printf 'release\tv0.2.0\t-\ta[$(touch %s/ran8)]\n' "$T" > "$U/launcher"; passed "has a time that would run a command"
fresh; offer v0.3.0; mkdir "$U/launcher"; passed "is a folder"
# the writer
stl() { ( export L1_UPDATE_DIR="$U" L1_UPDATE_NOW="$NOW"; "$@"; . "$S"; l1u_stamp_launcher "$T/tree"; echo "rc=$?" ); }
fresh
check "LFT3 l1u_stamp_launcher from a checkout: the line checkout, the tree's version, no commit, the time" "$(stl true):$(cat "$U/launcher")" "rc=0:checkout${TAB}v0.3.0$TAB-$TAB$NOW"
check "LFT3 ...in the record's folder itself, nothing in installed/, nothing left beside it" "$(ls -A "$U" | tr '\n' ' '):$(ls -A "$U/installed" | wc -l | tr -d ' ')" "installed launcher :0"
check "LFT3 ...and the state is then manual" "$(tool)" "manual${TAB}v0.3.0$TAB-${TAB}checkout"
fresh
check "LFT3 ...from a fetch: the ref and the commit" "$(stl export L1_FETCHED_REF=release L1_FETCHED_COMMIT=$HEX):$(cat "$U/launcher")" "rc=0:release${TAB}v0.3.0$TAB$HEX$TAB$NOW"
check "LFT3 ...what it wrote is read back: unknown at that version" "$(tool):$(fn l1u_stamp_of_launcher)" "unknown${TAB}v0.3.0$TAB-$TAB-:release${TAB}v0.3.0"
fresh
check "LFT3 ...a ref that is not a line: 1, nothing written" "$(stl export 'L1_FETCHED_REF=a b'):$(ls -A "$U" | tr '\n' ' ')" "rc=1:installed "
fresh; chmod 770 "$U"
check "LFT3 ...an _update the group can write: 1, nothing written" "$(stl true):$(ls -A "$U" | tr '\n' ' ')" "rc=1:installed "

# --- UT4: the refresh: when curl is called, and with what
OPTS="CURL -q --proto =https --tlsv1.2 -sS --max-time 10 --max-filesize 1048576 -o $U/.fetch.[A-Za-z0-9]* -w %{http_code} https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/CHANGELOG.md"
fresh; stamp 949230 release v0.2.0
check "the first refresh: fetched, the offer and the notes written, tried written, nothing left over" \
  "$(tool --refresh):$(cat "$U/offer"):$(cmp -s "$U/notes.md" "$T/body.md" && echo same):$(cat "$U/tried"):$(fetchleft)" "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-${TAB}fetched:v0.3.0$TAB$NOW:same:$NOW:0"
check "  ...curl called once, with exactly these options, -q first" "$(calls):$(grep -c "^$OPTS\$" "$CALLS")" "1:1"
: > "$CALLS"
check "within a day of tried: skipped, curl not called" "$(NOWAT=$((NOW + 86399)) tool --refresh | cut -f5):$(calls)" "skipped:0"
check "at exactly 86,400 s: called" "$(NOWAT=$((NOW + 86400)) tool --refresh | cut -f5):$(calls)" "fetched:1"
: > "$CALLS"
check "--now inside the day: called" "$(NOWAT=$((NOW + 86400 + 5)) tool --refresh --now | cut -f5):$(calls)" "fetched:1"
: > "$CALLS"; echo $((NOW + 500)) > "$U/tried"
check "a tried after now: called" "$(tool --refresh | cut -f5):$(calls)" "fetched:1"

# --- UT4: failures leave everything as it was, and are not tried again for a day
printf '%s\n' '# Changelog' 'no heading here' > "$T/nohead.md"
{ cat "$T/body.md"; head -c 2097152 /dev/zero | tr '\0' 'x'; } > "$T/big.md"
failcase() {   # <name> <VAR=value ...>
  local name="$1"; shift
  fresh; stamp 949230 release v0.2.0; offer v0.2.0; echo "old notes" > "$U/notes.md"
  local o n; o="$(sum "$U/offer")"; n="$(sum "$U/notes.md")"
  check "$name: failed, exit 0, the offer and the notes byte for byte as they were, nothing left over" \
    "$(env L1_UPDATE_DIR="$U" L1_CURL="$T/bin/curl" L1_UPDATE_NOW="$NOW" STUB_BODY="$T/body.md" "$@" bash "$S" --refresh > "$T/fail.out"; rc=$?; cut -f5 "$T/fail.out"; echo "rc=$rc"):$([ "$(sum "$U/offer")" = "$o" ] && echo same):$([ "$(sum "$U/notes.md")" = "$n" ] && echo same):$(fetchleft)" "failed
rc=0:same:same:0"
  : > "$CALLS"
  check "  ...and it is not tried again within the day" "$(NOWAT=$((NOW + 3600)) tool --refresh | cut -f5):$(calls)" "skipped:0"
}
failcase "curl exit 56 with a 404 page" STUB_CODE=404 STUB_EXIT=56
failcase "curl exit 63 (the answer too large)" STUB_CODE=200 STUB_EXIT=63
failcase "a 404 with exit 0" STUB_CODE=404
failcase "no answer" STUB_CODE=000 STUB_EXIT=6
failcase "a 2 MiB file served with exit 0" STUB_BODY="$T/big.md"
failcase "a file with no version heading" STUB_BODY="$T/nohead.md"

# --- UT4: states in which nothing is ever fetched, and folders that are not the player's own
for st in off none manual; do
  fresh; offer v0.2.0
  case "$st" in off) stamp 949230 release v0.2.0; : > "$U/off" ;; manual) stamp 949230 checkout v0.2.0 ;; esac
  check "the state $st: skipped, curl never called, with --now too, and no tried written" \
    "$(tool --refresh | cut -f1,5):$(tool --refresh --now | cut -f5):$(calls):$([ -e "$U/tried" ] && echo tried || echo none)" "$st${TAB}skipped:skipped:0:none"
done
rm -rf "$U"; mkdir -p "$U"; chmod 700 "$U"; : > "$CALLS"; before="$(ls -A "$U" | wc -l | tr -d ' ')"
check "no installed/ folder: none, nothing fetched, nothing written" "$(tool --refresh | cut -f1,5):$(calls):$(ls -A "$U" | wc -l | tr -d ' ')" "none${TAB}skipped:0:$before"
fresh; stamp 949230 release v0.2.0; chmod 770 "$U"
check "an _update the group can write: failed, curl not called, nothing written" "$(tool --refresh | cut -f5):$(calls):$(ls -A "$U" | tr '\n' ' ')" "failed:0:installed "
fresh; stamp 949230 release v0.2.0; chmod 770 "$U/installed"
check "an installed/ the group can write: failed, curl not called, nothing written" "$(tool --refresh | cut -f5):$(calls):$(ls -A "$U" | tr '\n' ' ')" "failed:0:installed "

# --- UT4: an older answer does not lower the offer; two refreshes at once leave a whole file
fresh; stamp 949230 release v0.2.0; offer v0.4.0; echo "notes of 0.4.0" > "$U/notes.md"; o="$(sum "$U/offer")"; n="$(sum "$U/notes.md")"
check "an answer older than the offer: fetched, the offer and the notes as they were, nothing left over" \
  "$(tool --refresh | cut -f3,5):$([ "$(sum "$U/offer")" = "$o" ] && echo same):$([ "$(sum "$U/notes.md")" = "$n" ] && echo same):$(fetchleft)" "v0.4.0${TAB}fetched:same:same:0"
fresh; stamp 949230 release v0.2.0
{ cat "$T/body.md"; i=0; while [ $i -lt 400 ]; do echo "a line of the notes, number $i, long enough to matter"; i=$((i + 1)); done; } > "$T/long.md"
{ cat "$T/body.md"; i=0; while [ $i -lt 400 ]; do echo "another answer altogether, line $i of it, as long as the other"; i=$((i + 1)); done; } > "$T/long2.md"
# The first writes half its answer and waits; the second starts inside that wait, writes half of another
# answer and waits longer. With one file name for both, the first would finish the second's file.
( BODY="$T/long.md" STUB_SLOW=1 tool --refresh > "$T/slow.out" 2>&1 ) & sp=$!
/bin/sleep 0.3; BODY="$T/long2.md" STUB_SLOW=1.5 tool --refresh --now > "$T/slow2.out" 2>&1; wait "$sp"
whole() { if cmp -s "$U/notes.md" "$T/long.md" || cmp -s "$U/notes.md" "$T/long2.md"; then echo whole; else echo mixed; fi; }
check "two refreshes at once, each slow: notes.md is one whole answer, both say fetched, nothing is left over" \
  "$(whole):$(cut -f5 "$T/slow.out"):$(cut -f5 "$T/slow2.out"):$(fetchleft)" "whole:fetched:fetched:0"

# --- UT4: --notes
fresh; stamp 949230 release v0.2.0
cp "$T/body.md" "$U/notes.md"
check "--notes: the sections newer than the installed version only, the heading without its marks" "$(tool --notes | tr '\n' '|')" "v0.3.0 (2026-11-24)||Three.||"
printf '%s\n' '## Unreleased' 'not shown' '## v0.5.0 (2026-01-03)' 'five' '## v0.4.0 (2026-01-02)' 'four' '## v0.3.0 (2026-01-01)' 'three' > "$U/notes.md"; stamp 949230 release v0.3.0
check "  ...newest first, Unreleased and the installed version left out" "$(tool --notes | tr '\n' '|')" "v0.5.0 (2026-01-03)|five||v0.4.0 (2026-01-02)|four|"
stamp 949230 release v0.2.0
printf '%s\n' '## v0.3.0 (2026-01-01)' 'one line' 'and its second' '' 'a new paragraph' '- an item' '  that goes on' '- a second item' '1. a numbered one' 'still that one' > "$U/notes.md"
check "  ...rule 2: a paragraph's lines joined, ending at an empty line, an item or a number; an item's lines join it" \
  "$(tool --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|one line and its second||a new paragraph|- an item that goes on|- a second item|1. a numbered one still that one|"
printf '%s\n' '## v0.3.0 (2026-01-01)' 'before' '```bash' 'sec() { a;' '  b; }' '```' 'after' > "$U/notes.md"
check "  ...rule 3: the fence lines dropped, the lines between them as they are" "$(tool --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|before|sec() { a;|  b; }|after|"
printf '%s\n' '## v0.3.0 (2026-01-01)' '**Bold** and `code` and a * alone' > "$U/notes.md"
check "  ...rule 4: ** and backticks removed" "$(tool --notes | tail -n 1)" "Bold and code and a * alone"
printf '## v0.3.0 (2026-01-01)\nred \033[31mtext\007 and a\ttab\r\n' > "$U/notes.md"
check "  ...rule 5: control characters removed, the tab kept" "$(tool --notes | tail -n 1)" "red [31mtext and a${TAB}tab"
{ echo '## v0.3.0 (2026-01-01)'; i=0; while [ $i -lt 300 ]; do echo "- item $i"; i=$((i + 1)); done; } > "$U/notes.md"
check "  ...cut before the 201st line, with the closing line" "$(tool --notes | wc -l | tr -d ' '):$(tool --notes | sed -n 200p):$(tool --notes | tail -n 1)" "201:- item 198:More: https://github.com/macgameport/1launcher/blob/release/CHANGELOG.md"
{ echo '## v0.3.0 (2026-01-01)'; i=0; while [ $i -lt 150 ]; do printf -- '- %0100d\n' "$i"; i=$((i + 1)); done; } > "$U/notes.md"
check "  ...cut before the line that would pass 12,000 bytes" "$(tool --notes | sed '$d' | wc -c | tr -d ' '):$(tool --notes | tail -n 1 | cut -c1-5)" "11968:More:"
rm "$U/notes.md"
check "  ...no notes: nothing, exit 0" "$(tool --notes; echo "rc=$?")" "rc=0"

# --- UT4: --noted, for a launcher
fresh; stamp 949230 release v0.2.0; offer v0.3.0
check "--noted: the version at the first two calls, then nothing" "$(tool --noted):$(tool --noted):$(tool --noted):$(cat "$U/noted")" "v0.3.0:v0.3.0::v0.3.0${TAB}2"
offer v0.4.0
check "  ...and again for a newer version" "$(tool --noted):$(cat "$U/noted")" "v0.4.0:v0.4.0${TAB}1"
fresh; stamp 949230 release v0.3.0; offer v0.3.0
check "  ...not ready: nothing printed, nothing written" "$(tool --noted):$([ -e "$U/noted" ] && echo written || echo none)" ":none"
fresh; stamp 949230 release v0.2.0; offer v0.3.0; printf 'v0.3.0\ta[$(touch %s/ran4)]\n' "$T" > "$U/noted"
check "  ...a noted whose count would run a command: taken as absent, nothing run" "$(tool --noted):$([ -e "$T/ran4" ] && echo ran || echo none)" "v0.3.0:none"

# --- UT4: --open (plan 3.4): it refuses unless the state is ready; ready, it writes one file and hands it to Terminal
printf '#!/bin/bash\n{ printf "OPEN"; for a in "$@"; do printf "|%%s" "$a"; done; echo; } >> "$CALLS"\nexit "${STUB_OPEN_EXIT:-0}"\n' > "$T/bin/open"; chmod +x "$T/bin/open"
TM="$T/tmp"
opn() {   # [VAR=value ...]: --open with the stubs; TMPDIR is a fresh scratch folder; the call log is emptied first
  rm -rf "$TM"; mkdir -p "$TM"; : > "$CALLS"
  env L1_UPDATE_DIR="$U" L1_CURL="$T/bin/curl" L1_OPEN="$T/bin/open" L1_UPDATE_NOW="$NOW" TMPDIR="$TM" "$@" bash "$S" --open; echo "rc=$?"
}
opens() { grep -c '^OPEN' "$CALLS"; }
tmleft() { ls -A "$TM" | wc -l | tr -d ' '; }
for st in current unknown none manual off; do
  fresh
  case "$st" in
    current) stamp 949230 release v0.3.0; offer v0.3.0 ;;
    unknown) stamp 949230 release v0.2.0 ;;
    none) offer v0.3.0 ;;
    manual) stamp 949230 checkout v0.2.0; offer v0.3.0 ;;
    off) stamp 949230 release v0.2.0; offer v0.3.0; : > "$U/off" ;;
  esac
  before="$(ls -A "$U" | tr '\n' ' ')"
  check "--open in the state $st: failed and the sentence, exit 0, nothing written, L1_OPEN not called" \
    "$(opn | tr '\n' ':')$([ "$(ls -A "$U" | tr '\n' ' ')" = "$before" ] && echo same):$(tmleft):$(opens)" "failed${TAB}No update is waiting.:rc=0:same:0:0"
done
fresh; stamp 949230 release v0.2.0; offer v0.3.0; before="$(ls -A "$U" | tr '\n' ' ')"
check "--open when ready: opened, exit 0, nothing written into the record's folder" "$(opn | tr '\n' ':')$([ "$(ls -A "$U" | tr '\n' ' ')" = "$before" ] && echo same)" "opened:rc=0:same"
CMD="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"
check "  ...L1_OPEN called once, with -a, Terminal and one file: Update 1launcher.command, mode 755, alone in a new folder of TMPDIR" \
  "$(opens):$(grep -c "^OPEN|-a|Terminal|$TM/1launcher-update\.[A-Za-z0-9]*/Update 1launcher\.command\$" "$CALLS"):$(stat -f %Lp "$CMD" 2>/dev/null):$(tmleft):$(ls -A "$(dirname "$CMD")" | wc -l | tr -d ' ')" "1:1:755:1:1"
check "  ...the file names the curl it was given, and fetches the root install.sh of release by the branch's full name" \
  "$(sed -n 2p "$CMD"):$(grep -c 'https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/install\.sh)"; rc=\$?$' "$CMD"):$(grep -c 'raw\.githubusercontent' "$CMD")" "CURL='$T/bin/curl':1:1"
check "  ...curl is not called by --open itself" "$(calls)" 0
for bad in "x'; touch $T/ran7; '" '/tmp/$(touch '"$T"'/ran7)' 'curl' "$T/bin/cu rl"; do
  check "L1_CURL holding [$bad]: the file names /usr/bin/curl, and nothing ran" "$(opn L1_CURL="$bad" | tr '\n' ':')$(sed -n 2p "$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"):$([ -e "$T/ran7" ] && echo ran || echo none)" "opened:rc=0:CURL='/usr/bin/curl':none"
done
check "Terminal could not be opened: failed and a sentence, exit 0, and the file and its folder are removed again" \
  "$(opn STUB_OPEN_EXIT=1 | tr '\n' ':')$(opens):$(tmleft)" "failed${TAB}Terminal could not be opened for the update.:rc=0:1:0"
# with a TMPDIR that cannot be used, the folder is made in /tmp, as the installer app's is; what this run made is removed
check "a TMPDIR that is no folder: opened all the same, the file in a new folder of /tmp" \
  "$(opn TMPDIR="$T/no-such-folder" | tr '\n' ':')$(grep -c '^OPEN|-a|Terminal|/tmp/1launcher-update\.[A-Za-z0-9]*/Update 1launcher\.command$' "$CALLS")" "opened:rc=0:1"
CMD="$(sed -n 's/^OPEN|-a|Terminal|//p' "$CALLS")"
case "$CMD" in /tmp/1launcher-update.*/"Update 1launcher.command") rm -f "$CMD"; rmdir "$(dirname "$CMD")" 2>/dev/null ;; esac

# --- LFT13 (docs/plans/launcher-first-install.md, 3.8): the lock's rule in shell, for the names installing and
# updating. L1_SYSCTL names a stub that gives the Mac's last start; a link's own time is set with touch -h.
BOOT=1700000000
printf '#!/bin/bash\n[ "$*" = "-n kern.boottime" ] || exit 1\n[ -n "${STUB_BOOT_FAIL:-}" ] && exit 1\necho "{ sec = %s, usec = 84350 } Tue Nov 14 22:13:20 2023"\n' "$BOOT" > "$T/bin/sysctl"; chmod +x "$T/bin/sysctl"
lk() {   # [VAR=value ...] -- <commands>: the tool's functions in a new bash, whose process number is the taker's
  local e=()
  while [ "$1" != -- ]; do e+=("$1"); shift; done; shift
  env L1_UPDATE_DIR="$U" L1_SYSCTL="$T/bin/sysctl" ${e[@]+"${e[@]}"} /bin/bash -c '. "$1"; '"$*" lock-test "$S"
}
live() { lk "$@" -- 'l1u_lock_live "$NAME"; echo "$?:$L1U_HOLDER"'; }   # NAME=<lock> [VAR=value ...]
/bin/sleep 300 & LIVE=$!
( exit 0 ) & DEAD=$!; wait "$DEAD"
trap 'kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null; rm -rf "$T"' EXIT
for name in installing updating; do
  fresh; ln -s "$LIVE" "$U/$name"
  check "LFT13 $name: a link to a live process is live, and its holder is that process" "$(live NAME=$name)" "0:$LIVE"
  fresh; ln -s "$DEAD" "$U/$name"
  check "LFT13 $name: a link to a process that is gone is not" "$(live NAME=$name)" "1:"
  fresh; ln -s not-a-number "$U/$name"
  check "LFT13 $name: a link to no number is not" "$(live NAME=$name)" "1:"
  fresh; echo "$LIVE" > "$U/$name"
  check "LFT13 $name: a plain file that holds a live process's number is not" "$(live NAME=$name)" "1:"
  fresh
  check "LFT13 $name: with no lock at all: not" "$(live NAME=$name)" "1:"
  fresh; ln -s "$LIVE" "$U/$name"; touch -h -t 202001010000 "$U/$name"
  check "LFT13 $name: a link to a live process whose own time is before the Mac's last start is not" "$(live NAME=$name)" "1:"
  check "LFT13 $name: ...with the start's time unreadable the first two parts decide: live" "$(live NAME=$name STUB_BOOT_FAIL=1)" "0:$LIVE"
done
fresh; ln -s "$LIVE" "$U/other"
check "LFT13 another name than the two is no lock: not live, not taken, and left as it is" "$(live NAME=other):$(lk -- 'l1u_lock_take other; echo $?'):$(readlink "$U/other")" "1::1:$LIVE"
fresh
check "LFT13 a take: 0, and the link's target is the taker's own process number" \
  "$(lk -- 'l1u_lock_take installing; echo "$?:$([ "$(readlink "$L1_UPDATE_DIR/installing")" = "$$" ] && echo mine)"')" "0:mine"
fresh; ln -s "$LIVE" "$U/installing"
check "LFT13 a take while another live process holds it: refused, and the lock is still the other's" "$(lk -- 'l1u_lock_take installing; echo $?'):$(readlink "$U/installing")" "1:$LIVE"
check "LFT13 ...a release by one who does not hold it leaves it" "$(lk -- 'l1u_lock_release installing; echo $?'):$(readlink "$U/installing")" "0:$LIVE"
fresh
check "LFT13 take, then release: the link is gone; and a second take by the holder itself is refused" \
  "$(lk -- 'l1u_lock_take updating; l1u_lock_take updating; echo "$?"; l1u_lock_release updating; ls -A "$L1_UPDATE_DIR" | tr "\n" " "')" "1
installed "
for t in "$DEAD" 0 not-a-number; do
  fresh; ln -s -- "$t" "$U/installing"
  check "LFT13 a dead lock (target $t) is taken over" "$(lk -- 'l1u_lock_take installing; echo "$?:$([ "$(readlink "$L1_UPDATE_DIR/installing")" = "$$" ] && echo mine)"')" "0:mine"
done
fresh; ln -s "$LIVE" "$U/installing"; touch -h -t 202001010000 "$U/installing"
check "LFT13 a lock older than the Mac's last start, its target a live process, is taken over" "$(lk -- 'l1u_lock_take installing; echo "$?:$([ "$(readlink "$L1_UPDATE_DIR/installing")" = "$$" ] && echo mine)"')" "0:mine"
fresh; mkdir "$U/installing"
check "LFT13 a folder at the lock's name: the take refuses, and nothing is left inside the folder" "$(lk -- 'l1u_lock_take installing; echo $?'):$(ls -A "$U/installing" | wc -l | tr -d ' ')" "1:0"
fresh; echo 949230 > "$U/installing-game"
check "LFT13 a take of installing removes an installing-game another holder left; a take of updating does not touch it" \
  "$(echo 1 > "$U/installing-game"; lk -- 'l1u_lock_take updating; l1u_lock_release updating'; [ -e "$U/installing-game" ] && echo kept):$(lk -- 'l1u_lock_take installing; echo $?'):$([ -e "$U/installing-game" ] && echo kept || echo removed)" "kept:0:removed"
fresh
check "LFT13 a release of installing removes the game's file with the link" \
  "$(lk -- 'l1u_lock_take installing; echo 949230 > "$L1_UPDATE_DIR/installing-game"; l1u_lock_release installing; ls -A "$L1_UPDATE_DIR" | tr "\n" " "')" "installed "
mkdir -p "$T/pathbin2"; for p in readlink stat ln rm; do printf '#!/bin/bash\necho "%s" >> "%s/pathcalls2"\nexec /usr/bin/false\n' "$p" "$T" > "$T/pathbin2/$p"; chmod +x "$T/pathbin2/$p"; done
fresh; : > "$T/pathcalls2"
check "LFT13 stubs named readlink, stat, ln and rm first on PATH: take, live and release still work, and none was called" \
  "$(lk PATH="$T/pathbin2:$PATH" -- 'l1u_lock_take installing; l1u_lock_live installing; echo "$?"; l1u_lock_release installing; ls -A "$L1_UPDATE_DIR" | tr "\n" " "'):$(wc -l < "$T/pathcalls2" | tr -d ' ')" "0
installed :0"
# --open while an install runs (the update's side of "they keep out of each other's way")
fresh; stamp 949230 release v0.2.0; offer v0.3.0; ln -s "$LIVE" "$U/installing"; before="$(ls -A "$U" | tr '\n' ' ')"
check "LFT13 --open when ready, with a live installing: failed and its sentence, nothing written, L1_OPEN not called" \
  "$(opn L1_SYSCTL="$T/bin/sysctl" | tr '\n' ':')$([ "$(ls -A "$U" | tr '\n' ' ')" = "$before" ] && echo same):$(tmleft):$(opens)" "failed${TAB}An install is running in Terminal. Wait for it to finish, then update.:rc=0:same:0:0"
fresh; stamp 949230 release v0.2.0; offer v0.3.0; ln -s "$DEAD" "$U/installing"
check "LFT13 ...with a dead installing: opened" "$(opn L1_SYSCTL="$T/bin/sysctl" | tr '\n' ':')$(opens)" "opened:rc=0:1"
fresh; stamp 949230 release v0.3.0; offer v0.3.0; ln -s "$LIVE" "$U/installing"
check "LFT13 ...not ready, with a live installing: the state's sentence comes first" "$(opn L1_SYSCTL="$T/bin/sysctl" | sed -n 1p)" "failed${TAB}No update is waiting."

# --- UT4: --version-of, and values that would run a command
fresh
check "--version-of: a file's version, and nothing for a file without one, exit 0 both times" "$(tool --version-of "$T/body.md"; echo "rc=$?"):$(tool --version-of "$T/none.md"; echo "rc=$?")" "v0.3.0
rc=0:rc=0"
fresh; stamp 949230 release v0.2.0; printf 'a[$(touch %s/ran5)]\n' "$T" > "$U/tried"
check "a tried that would run a command: taken as absent (the fetch is made), nothing run" "$(tool --refresh | cut -f5):$([ -e "$T/ran5" ] && echo ran || echo none)" "fetched:none"
fresh; stamp 949230 release v0.2.0
check "L1_UPDATE_NOW that would run a command: the clock is used instead, nothing run" \
  "$(NOWAT='a[$(touch '"$T"'/ran6)]' tool --refresh | cut -f5):$(grep -c '^[0-9]\{9,12\}$' "$U/tried"):$([ -e "$T/ran6" ] && echo ran || echo none)" "fetched:1:none"

# --- the programs the tool runs are the system's, whatever comes first on PATH
mkdir -p "$T/pathbin"
for p in mktemp stat date mv; do printf '#!/bin/bash\necho "%s" >> "%s/pathcalls"\nexec /usr/bin/false\n' "$p" "$T" > "$T/pathbin/$p"; chmod +x "$T/pathbin/$p"; done
fresh; stamp 949230 release v0.2.0; : > "$T/pathcalls"
check "stubs named mktemp, stat, date and mv first on PATH: the refresh still works, and none was called" \
  "$(PATH="$T/pathbin:$PATH" NOWAT=notatime tool --refresh | cut -f1,5):$(wc -l < "$T/pathcalls" | tr -d ' ')" "ready${TAB}fetched:0"
check "  ...--noted too" "$(PATH="$T/pathbin:$PATH" tool --noted):$(wc -l < "$T/pathcalls" | tr -d ' ')" "v0.3.0:0"

echo "$fails failure(s)"
[ "$fails" = 0 ]
