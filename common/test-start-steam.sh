#!/bin/bash
# test-start-steam.sh -- start_steam of common/install-core.sh prints nothing of bash's own
# (docs/plans/first-run-findings.md, 2.9, FT4b). The function is cut from the core and tested in two parts,
# which are not the same kind:
#   the gate   a source test: the three lines stand in braces whose error output is sent away, and the
#              child's own line is as it was. Its mutants turn it red every time.
#   the watch  STARTS starts (30,000; about 25 s) of that function with a stub program and input and output
#              redirected print nothing. A line printed fails the file. It is not a gate: under mutant 1 bash's
#              "child setpgid" line came in 4 of 3,200 starts, in 1 of 3,000 and in 0 of 9,000, as the Mac's
#              load moved, so a green watch under a mutant shows nothing.
# The stub program is /usr/bin/true. No Wine, no Steam, and no process but the test's own is read or signalled.
#   bash common/test-start-steam.sh        exit 0 = both parts passed
#   STARTS=<n> ...   another number of starts for the watch
#   MUTANT=1 ...   the braces' redirection removed; must exit 1, by the gate
#   MUTANT=2 ...   the redirection moved onto the child's line; must exit 1, by the gate
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d /tmp/start-steam-test.XXXX)"
trap 'rm -rf "$T"' EXIT
C="$T/install-core.sh"; cp "$HERE/install-core.sh" "$C"
mutate() {  # <sed expression> <grep that proves it applied>
  sed -i '' "$1" "$C"; grep -q -- "$2" "$C" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  0) ;;
  1) mutate 's#^    set +m; } 2> /dev/null$#    set +m; }#' '^    set +m; }$' ;;
  2) mutate 's#^\(    ( trap .* < /dev/null > /dev/null 2>&1\) & disown$#\1 2> /dev/null \& disown#; s#^    set +m; } 2> /dev/null$#    set +m; }#' ' 2>&1 2> /dev/null & disown$' ;;
  *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
esac
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
F="$T/start_steam.sh"
awk '/^start_steam\(\) \{/ { p = 1 } p { print } p && /^\}$/ { exit }' "$C" > "$F"
body() { grep -v '^[[:space:]]*#' "$F"; }   # the function without its comment lines
check "the gate: start_steam is found, and parses by itself" "$(grep -c '^start_steam() {' "$F"):$(bash -n "$F" 2>&1 | wc -l | tr -d ' ')" "1:0"
check "the gate: its lines are the three, in braces whose error output is sent away" \
  "$(body | sed -n 2p):$(body | sed -n 4,5p | tr '\n' '|'):$(body | wc -l | tr -d ' ')" "  { set -m:    set +m; } 2> /dev/null|}|:5"
check "the gate: the child's own line is as it was" \
  "$(body | sed -n 3p)" "    ( trap '' HUP; exec \"\$WINE\" \"\$(steam_exe)\" \$STEAM_ARGS ) < /dev/null > /dev/null 2>&1 & disown"

N="${STARTS:-30000}"
cat > "$T/watch.sh" << X2
set -u
. "$F"
steam_exe() { echo steam.exe; }
WINE=/usr/bin/true; STEAM_ARGS="-no-cef-sandbox"
i=0; while [ "\$i" -lt $N ]; do start_steam; i=\$((i + 1)); done
X2
bash "$T/watch.sh" < /dev/null > "$T/out" 2>&1; rc=$?
check "the watch: $N starts with a stub program print nothing" "$rc:$(wc -c < "$T/out" | tr -d ' ')" "0:0"
[ -s "$T/out" ] && { echo "      printed ($(wc -l < "$T/out" | tr -d ' ') lines), the first two:"; head -n 2 "$T/out" | sed 's/^/        /'; }
echo "$fails failure(s)"
[ "$fails" = 0 ]
