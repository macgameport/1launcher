#!/bin/bash
# test-launch-feedback.sh -- what each launcher tells the player, and how: step, note, licence_wait, signin_wait, _alert
# and die. From each launcher it takes the `QUIET=` line, the launch-feedback-config lines, the launch-feedback
# block and die, and runs them in a fresh bash under `set -u`, driven by the settings the app's shim passes
# (CS2_QUIET and CS2_PANEL, SM_QUIET and SM_PANEL). A recording osascript and a recording sleep come first on
# PATH, so nothing is shown and nothing waits. osacompile, which compiles and shows nothing, checks that the
# AppleScript each call would run is valid. No game, no Steam, no Wine.
#   bash common/test-launch-feedback.sh            exit 0 = every case passed; exit 2 = a launcher or a piece is missing
#   MUTANT=1 ...   step ignores PANEL (the window and a notification for the same milestone); must exit 1
#   MUTANT=2 ...   note is silenced by PANEL (a warning nobody sees); must exit 1
#   MUTANT=3 ...   the PANEL= line is deleted (under set -u the app's launch dies at its first step); must exit 1
#   MUTANT=4 ...   the Cities: Skylines II launcher reads SM_PANEL; must exit 1
#   MUTANT=5 ...   the notification's text is pasted into the AppleScript source again; must exit 1
#   MUTANT=6 ...   licence_wait ignores the setting; must exit 1
#   MUTANT=7 ...   licence_wait drops the remainder below 15 s; must exit 1
#   MUTANT=8 ...   licence_wait takes the setting as it is, with no validation; must exit 1
#   MUTANT=9 ...   the alert's text is pasted into the AppleScript source again; must exit 1
#   MUTANT=10 ...  signin_wait says nothing while it waits (the hint dropped); must exit 1
#   MUTANT=11 ...  signin_wait prints the hint at every poll from 45 s on; must exit 1
#   MUTANT=12 ...  signin_wait's limit put back to 120 s; must exit 1
#   MUTANT=13 ...  the hint's step number written out in the block, not the caller's; must exit 1
#   MUTANT=14 ...  signin_wait counts Steam as gone before it was ever seen; must exit 1
#   MUTANT=15 ...  signin_wait never ends early for a Steam that is gone; must exit 1
#   MUTANT=16 ...  signin_wait does not start its count again when Steam is back; must exit 1
#   MUTANT=17 ...  signin_wait takes a limit of four digits or more as it is; must exit 1
#   MUTANT=18 ...  signin_wait returns the test's own code after the limit; must exit 1
#   MUTANT=19 ...  signin_wait starts again a Steam that was seen for less than 60 s; must exit 1
#   MUTANT=20 ...  signin_wait starts Steam again without counting (a third restart); must exit 1
#   MUTANT=21 ...  signin_wait starts Steam again with less than 60 s of the wait left; must exit 1
#   MUTANT=22 ...  signin_wait forgets at a restart that Steam was seen (waits on for one that never comes); must exit 1
#   MUTANT=23 ...  signin_wait does not start its count of the time Steam was seen again at a restart; must exit 1
#   MUTANT=24 ...  signin_wait goes on when the start word fails; must exit 1
#   MUTANT=25 ...  signin_wait says nothing at a restart; must exit 1
#   MUTANT=26 ...  signin_wait starts Steam again when it was given no start word; must exit 1
#   MUTANT=27 ...  signin_wait takes a limit with a leading zero as it stands (090 is an error in arithmetic); must exit 1
#   MUTANT=28 ...  signin_wait does not start its count of the time Steam is gone again at a restart; must exit 1
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/launch-feedback-test.XXXX)"
trap 'rm -rf "$T"' EXIT
# launcher | the prefix of its settings | the title its pop-ups carry
GAMES=("cities-skylines-2/launchers/launch-cs2-dxmt11.sh|CS2|Cities: Skylines II"
       "surviving-mars-relaunched/launch-relaunched.sh|SM|Surviving Mars: Relaunched")
mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
mutate() {   # <file> <sed expression> <fixed text that proves it applied>
  sed -i '' "$2" "$1"; grep -qF -- "$3" "$1" || mutated
}
n=0
for g in "${GAMES[@]}"; do
  n=$((n + 1)); f="${g%%|*}"
  [ -f "$HERE/$f" ] || { echo "REFUSED: $f not found under $HERE"; exit 2; }
  L="$T/launcher.$n.sh"; cp "$HERE/$f" "$L"
  case "${MUTANT:-0}" in
    0) ;;
    1) mutate "$L" 's/^  \[ "\$QUIET" = 1 \] && \[ "\$PANEL" != 1 \] && _notify "\$2"$/  [ "$QUIET" = 1 ] \&\& _notify "$2"/' '  [ "$QUIET" = 1 ] && _notify "$2"' ;;
    2) mutate "$L" 's/^  \[ "\$QUIET" = 1 \] && _notify "\$1"$/  [ "$QUIET" = 1 ] \&\& [ "$PANEL" != 1 ] \&\& _notify "$1"/' '  [ "$QUIET" = 1 ] && [ "$PANEL" != 1 ] && _notify "$1"' ;;
    3) sed -i '' '/^PANEL=/d' "$L"; grep -q '^PANEL=' "$L" && mutated ;;
    4) [ "$n" = 1 ] && mutate "$L" 's/^PANEL="\${CS2_PANEL:-0}"$/PANEL="${SM_PANEL:-0}"/' 'PANEL="${SM_PANEL:-0}"' ;;
    5) mutate "$L" 's/^_notify() { .*/_notify() { osascript -e "display notification \\"$1\\" with title \\"$TITLE\\"" >\/dev\/null 2>\&1; }/' '_notify() { osascript -e "display notification \"$1\" with title \"$TITLE\"" >/dev/null 2>&1; }' ;;
    6) mutate "$L" 's/\*) w=\$((10#\$2)) ;; esac$/*) w=$3 ;; esac/' "''|*[!0-9]*|????*) w=\$3 ;; *) w=\$3 ;; esac" ;;
    7) mutate "$L" 's/else sleep "\$w"; w=0; fi$/else w=0; fi/' 'sleep 15; w=$((w - 15)); else w=0; fi' ;;
    8) mutate "$L" 's/^  case "\$2" in .*) w=\$((10#\$2)) ;; esac$/  w=${2:-$3}/' '  w=${2:-$3}' ;;
    9) mutate "$L" 's/^  else osascript .* as critical. .*; fi$/  else osascript -e "display alert \\"$TITLE\\" message \\"$1\\" as critical" >\/dev\/null 2>\&1; fi/' '  else osascript -e "display alert \"$TITLE\" message \"$1\" as critical" >/dev/null 2>&1; fi' ;;
    10) sed -i '' '/^    if \[ "\$hinted" = 0 \] .* step "\$1" "Still signing in\./d' "$L"; grep -q 'Still signing in' "$L" && mutated ;;
    11) mutate "$L" 's/^    if \[ "\$hinted" = 0 \] && \[ "\$t" -ge 45 \]; then /    if [ "$t" -ge 45 ]; then /' '    if [ "$t" -ge 45 ]; then hinted=1; step "$1" "Still signing in.' ;;
    12) mutate "$L" 's/^  local limit="\${L1_SIGNIN_SECS:-600}" t=0 /  local limit="${L1_SIGNIN_SECS:-120}" t=0 /' '  local limit="${L1_SIGNIN_SECS:-120}" t=0 ' ;;
    13) mutate "$L" 's/; step "\$1" "Still signing in\./; step 2 "Still signing in./' '; step 2 "Still signing in.' ;;
    14) sed -i '' 's/^      elif \[ "\$seen" = 1 \]; then$/      else/' "$L"; grep -q '^      elif \[ "\$seen" = 1 \]; then$' "$L" && mutated ;;
    15) mutate "$L" 's/^        if \[ "\$gone" -ge 15 \]; then$/        if false; then/' '        if false; then' ;;
    16) mutate "$L" 's/^      if "\$3"; then seen=1; gone=0; lived=/      if "$3"; then seen=1; lived=/' '      if "$3"; then seen=1; lived=$((lived + 3))' ;;
    17) mutate "$L" "s/^  case \"\$limit\" in ''|\*\[!0-9\]\*|????\*) limit=600 ;; esac$/  case \"\$limit\" in ''|*[!0-9]*) limit=600 ;; esac/" "  case \"\$limit\" in ''|*[!0-9]*) limit=600 ;; esac" ;;
    18) awk '/^  "\$2" && return 0$/ { print "  \"$2\""; getline; next } { print }' "$L" > "$L.new" && mv "$L.new" "$L"; grep -q '^  "\$2"$' "$L" || mutated ;;
    19) mutate "$L" 's/^          \[ -n "\${4:-}" \] && \[ "\$lived" -ge 60 \] && /          [ -n "${4:-}" ] \&\& /' '          [ -n "${4:-}" ] && [ "$again" -lt 2 ] && ' ;;
    20) mutate "$L" 's/ && \[ "\$lived" -ge 60 \] && \[ "\$again" -lt 2 \] && / \&\& [ "$lived" -ge 60 ] \&\& /' ' && [ "$lived" -ge 60 ] && [ $((limit - t)) -ge 60 ] || return 1' ;;
    21) mutate "$L" 's/ && \[ "\$again" -lt 2 \] && \[ \$((limit - t)) -ge 60 \] || return 1$/ \&\& [ "$again" -lt 2 ] || return 1/' ' && [ "$again" -lt 2 ] || return 1' ;;
    22) mutate "$L" 's/^          again=\$((again + 1)); gone=0; lived=0$/          again=$((again + 1)); gone=0; lived=0; seen=0/' '          again=$((again + 1)); gone=0; lived=0; seen=0' ;;
    23) sed -i '' 's/^          again=\$((again + 1)); gone=0; lived=0$/          again=$((again + 1)); gone=0/' "$L"; grep -q '^          again=\$((again + 1)); gone=0$' "$L" || mutated ;;
    24) sed -i '' 's/^          "\$4" || return 1$/          "$4"/' "$L"; grep -q '^          "\$4"$' "$L" || mutated ;;
    25) sed -i '' '/^          step "\$1" "Starting Steam again\./d' "$L"; grep -q 'Starting Steam again' "$L" && mutated ;;
    26) mutate "$L" 's/^          \[ -n "\${4:-}" \] && \[ "\$lived" -ge 60 \] && /          [ "$lived" -ge 60 ] \&\& /' '          [ "$lived" -ge 60 ] && [ "$again" -lt 2 ] && ' ;;
    27) mutate "$L" 's/^  limit=\$((10#\$limit))$/  limit=$((limit))/' '  limit=$((limit))' ;;
    28) sed -i '' 's/^          again=\$((again + 1)); gone=0; lived=0$/          again=$((again + 1)); lived=0/' "$L"; grep -q '^          again=\$((again + 1)); lived=0$' "$L" || mutated ;;
    *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
  esac
  {
    grep '^QUIET=' "$L"
    sed -n '/^# >>> launch-feedback-config/,/^# <<< launch-feedback-config/p' "$L"
    sed -n '/^# >>> launch-feedback (/,/^# <<< launch-feedback$/p' "$L"
    sed -n '/^die() {/,/^}/p' "$L"
  } > "$T/pieces.$n.sh"
  [ "$(grep -c '^QUIET=' "$T/pieces.$n.sh")" = 1 ] && grep -q '^# <<< launch-feedback-config' "$T/pieces.$n.sh" \
    && grep -q '^# <<< launch-feedback$' "$T/pieces.$n.sh" && grep -q '^die() {' "$T/pieces.$n.sh" \
    || { echo "REFUSED: could not find the QUIET= line, the config, the block and die in $f"; exit 2; }
done

mkdir -p "$T/bin"
printf '#!/bin/bash\n{ echo "CALL $#"; printf "%%s\\n" "$@"; } >> "$OSA_CALLS"\n' > "$T/bin/osascript"
printf '#!/bin/bash\necho "$1" >> "$SLEEP_CALLS"\n' > "$T/bin/sleep"
chmod +x "$T/bin/osascript" "$T/bin/sleep"
printf 'set -u\n. "$1"\neval "$2"\n' > "$T/harness.sh"
drive() {   # <pieces> <shell text> [NAME=value ...]: the text runs after the pieces; output in $T/out, calls in $T/osa and $T/sleeps
  local pc="$1" code="$2"; shift 2
  : > "$T/osa"; : > "$T/sleeps"
  env -u CS2_QUIET -u CS2_PANEL -u SM_QUIET -u SM_PANEL -u L1_SIGNIN_SECS "$@" PATH="$T/bin:$PATH" OSA_CALLS="$T/osa" SLEEP_CALLS="$T/sleeps" \
    /bin/bash "$T/harness.sh" "$pc" "$code" > "$T/out" 2> "$T/err" < /dev/null
}
posts() { grep -c '^CALL ' "$T/osa"; }
out() { tr '\n' '|' < "$T/out"; }
sources() { awk 'p { print; p = 0 } $0 == "-e" { p = 1 }' "$T/osa"; }   # the AppleScript lines of the recorded calls
compiles() { sources > "$T/src.applescript"; osacompile -o "$T/src.scpt" "$T/src.applescript" > "$T/osacompile.out" 2>&1 && echo yes || echo "no: $(head -1 "$T/osacompile.out")"; }
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
STEP='step 2 "two…"; echo "rc:$?"'; NOTE='note "a warning"; echo "rc:$?"'
TXT='He said "no" and C:\temp\x'

n=0
for g in "${GAMES[@]}"; do
  n=$((n + 1)); f="${g%%|*}"; r="${g#*|}"; P="${r%%|*}"; TITLE="${r#*|}"; B="$T/pieces.$n.sh"; tag="${f##*/}:"

  # --- step and note, as the shim's settings drive them
  drive "$B" "$STEP" "${P}_QUIET=1" "${P}_PANEL=1"; a=$(posts); o=$(out)
  drive "$B" "$NOTE" "${P}_QUIET=1" "${P}_PANEL=1"
  check "$tag quiet with the window up: step posts 0, note posts 1" "$a:$(posts)" "0:1"
  check "$tag   ...the step line reads [n/N] text, the note is plain, both return 0" "$o$(out)" "[2/5] two…|rc:0|a warning|rc:0|"
  check "$tag   ...the note's pop-up carries the text and this game's title, each as one argument" "$(grep -cxF 'a warning' "$T/osa"):$(grep -cxF "$TITLE" "$T/osa")" "1:1"
  drive "$B" "$STEP" "${P}_QUIET=1"; a=$(posts); o=$(out)
  check "$tag   ...and the step's does, when it posts" "$(grep -cxF 'two…' "$T/osa"):$(grep -cxF "$TITLE" "$T/osa")" "1:1"
  drive "$B" "$NOTE" "${P}_QUIET=1"
  check "$tag quiet with no window: step posts 1, note posts 1" "$a:$(posts)" "1:1"
  check "$tag   ...and the log lines are the same as with the window" "$o$(out)" "[2/5] two…|rc:0|a warning|rc:0|"
  drive "$B" "$STEP" "${P}_QUIET=1" "${P}_PANEL=0"
  check "$tag quiet with the window said to be down: step posts 1" "$(posts)" 1
  drive "$B" "$STEP"; a=$(posts); o=$(out)
  drive "$B" "$NOTE"
  check "$tag not quiet: step posts 0, note posts 0, the lines are printed" "$a:$(posts):$o$(out)" "0:0:[2/5] two…|rc:0|a warning|rc:0|"
  drive "$B" "$STEP" "${P}_PANEL=1"; a=$(posts)
  drive "$B" "$NOTE" "${P}_PANEL=1"
  check "$tag not quiet, the window setting given by hand: still nothing posted" "$a:$(posts)" "0:0"

  # --- the text is an argument, never AppleScript source, and the source compiles
  drive "$B" 'note "$TXT"' "${P}_QUIET=1" "TXT=$TXT"
  check "$tag a note holding \" and \\ arrives as one unchanged argument" "$(posts):$(grep -cxF -- "$TXT" "$T/osa"):$(sources | grep -cF 'He said')" "1:1:0"
  check "$tag   ...and the notification's AppleScript compiles" "$(compiles)" yes
  drive "$B" '_alert "$TXT"' "TXT=$TXT"
  check "$tag an alert holding \" and \\ arrives as one unchanged argument, with the title, as critical" "$(posts):$(grep -cxF -- "$TXT" "$T/osa"):$(grep -cxF "$TITLE" "$T/osa"):$(sources | grep -cF 'He said'):$(sources | grep -c ' as critical$')" "1:1:1:0:1"
  check "$tag   ...and the alert's AppleScript compiles" "$(compiles)" yes
  drive "$B" '_alert "$TXT" warning' "TXT=$TXT"
  check "$tag a warning alert: the same, as warning" "$(posts):$(grep -cxF -- "$TXT" "$T/osa"):$(grep -cxF "$TITLE" "$T/osa"):$(sources | grep -cF 'He said'):$(sources | grep -c ' as warning$')" "1:1:1:0:1"
  check "$tag   ...and it compiles" "$(compiles)" yes

  # --- die: ERROR: in the log, one alert when quiet, exit 1
  drive "$B" 'die "$TXT"; echo "not reached"' "${P}_QUIET=1" "${P}_PANEL=1" "TXT=$TXT"; rc=$?
  check "$tag die when quiet: exit 1, the ERROR: line first, one critical alert holding the text unchanged" "$rc:$(head -1 "$T/out"):$(posts):$(grep -cxF -- "$TXT" "$T/osa"):$(sources | grep -c ' as critical$')" "1:ERROR: $TXT:1:1:1"
  drive "$B" 'die "$TXT"; echo "not reached"' "TXT=$TXT"; rc=$?
  check "$tag die when not quiet: exit 1, the ERROR: line first, no alert" "$rc:$(head -1 "$T/out"):$(posts):$(grep -c 'not reached' "$T/out")" "1:ERROR: $TXT:0:0"

  # --- the licence wait: <step> <the setting as given> <default>
  waitcase() {   # <name> <setting> <sleeps wanted> <seconds in the step lines wanted> <seconds in the plain line wanted>
    drive "$B" 'licence_wait 3 "$V" 45; echo "rc:$?"' "V=$2"
    check "$tag licence wait, $1" \
      "sleeps: $(tr '\n' ' ' < "$T/sleeps")| steps: $(sed -n 's/^\[3\/5\] Steam is confirming the game licence, about \([0-9]*\) seconds left…$/\1/p' "$T/out" | tr '\n' ' ')| $(grep '^Licence wait: ' "$T/out" | tr '\n' '|') $(tail -1 "$T/out") stderr: $(wc -c < "$T/err" | tr -d ' ')" \
      "sleeps: $3| steps: $4| Licence wait: $5 s| rc:0 stderr: 0"
  }
  waitcase "nothing set: the default, in three parts" ""      "15 15 15 " "45 30 15 " 45
  waitcase "20: 15 then the remainder"                20      "15 5 "     "20 5 "     20
  waitcase "15: one part"                             15      "15 "       "15 "       15
  waitcase "0: the plain line, no step, no sleep"     0       ""          ""          0
  waitcase "08 is 8, not an octal error"              08      "8 "        "8 "        8
  waitcase "100: three digits are taken"              100     "15 15 15 15 15 15 10 " "100 85 70 55 40 25 10 " 100
  waitcase "abc: the default"                         abc     "15 15 15 " "45 30 15 " 45
  waitcase "-5: the default"                          -5      "15 15 15 " "45 30 15 " 45
  waitcase "9999: the default"                        9999    "15 15 15 " "45 30 15 " 45
  waitcase "99999: the default"                       99999   "15 15 15 " "45 30 15 " 45
  drive "$B" 'licence_wait 3 "" 45' "${P}_QUIET=1"; a=$(posts)
  drive "$B" 'licence_wait 3 "" 45' "${P}_QUIET=1" "${P}_PANEL=1"
  check "$tag licence wait: its countdown lines are steps (3 pop-ups with no window, 0 with it)" "$a:$(posts)" "3:0"
  # --- the sign-in wait: <step> <test>. The test given here fails N times and then succeeds, and prints a line
  #     at each poll; a poll follows every 3 s of sleep, so the polls before the hint say when it came. The step
  #     number, 4, is neither launcher's own.
  SW='c=0; polled() { c=$((c + 1)); echo "poll $c"; [ "$c" -gt "$N" ]; }; signin_wait 4 polled; echo "rc:$? polls:$c"'
  HINT='[4/5] Still signing in. If macOS asks a question, answer it…'
  signcase() {   # <name> <polls that fail first> <rc> <polls> <seconds slept> <hint lines> <seconds before the hint, - for none> [NAME=value ...]
    local name="$1" nfail="$2" want="rc:$3 polls:$4 slept:$5 each:$([ "$5" = 0 ] || echo 3) hints:$6 at:$7 other:0 stderr:0"; shift 7
    drive "$B" "$SW" "N=$nfail" "$@"
    check "$tag sign-in wait, $name" \
      "$(tail -1 "$T/out") slept:$(awk '{ s += $1 } END { print s + 0 }' "$T/sleeps") each:$(sort -u "$T/sleeps" | tr '\n' ' ' | sed 's/ $//') hints:$(grep -cxF -- "$HINT" "$T/out") at:$(awk -v h="$HINT" '$0 == h { print (p - 1) * 3; f = 1; exit } /^poll / { p = $2 } END { if (!f) print "-" }' "$T/out") other:$(grep -v -e '^poll ' -e '^rc:' "$T/out" | grep -vcxF -- "$HINT") stderr:$(wc -c < "$T/err" | tr -d ' ')" \
      "$want"
  }
  signcase "signed in at the first look: no wait, no line"            0      0 1   0   0 -
  signcase "signed in after 30 s: no hint"                            10     0 11  30  0 -
  signcase "signed in after 42 s: no hint"                            14     0 15  42  0 -
  signcase "signed in after 60 s: the hint once, at 45 s, as step 4"  20     0 21  60  1 45
  signcase "never, nothing set: 1 after 600 s, the hint once"         100000 1 201 600 1 45
  signcase "never, L1_SIGNIN_SECS=9: 1 after 9 s"                     100000 1 4   9   0 - L1_SIGNIN_SECS=9
  signcase "never, L1_SIGNIN_SECS=abc: counts as 600"                 100000 1 201 600 1 45 L1_SIGNIN_SECS=abc
  signcase "never, L1_SIGNIN_SECS empty: counts as 600"               100000 1 201 600 1 45 L1_SIGNIN_SECS=
  signcase "L1_SIGNIN_SECS=0: one look, no wait"                      100000 1 1   0   0 - L1_SIGNIN_SECS=0
  drive "$B" "$SW" N=20 "${P}_QUIET=1"; a=$(posts)
  drive "$B" "$SW" N=20 "${P}_QUIET=1" "${P}_PANEL=1"
  check "$tag sign-in wait: its hint is a step (1 pop-up with no window, 0 with it)" "$a:$(posts)" "1:0"
  # (300 failing polls here, not 100000: a limit of twenty digits taken as it stands is a wait without end)
  signcase "never, L1_SIGNIN_SECS of twenty digits: counts as 600"     300    1 201 600 1 45 L1_SIGNIN_SECS=99999999999999999999
  signcase "never, L1_SIGNIN_SECS=090: 1 after 90 s, not an octal error" 100000 1 31  90  1 45 L1_SIGNIN_SECS=090
  drive "$B" 'bad() { return 2; }; signin_wait 4 bad; echo "rc:$?"' L1_SIGNIN_SECS=6
  check "$tag sign-in wait: a test that returns 2 gives 1 after the limit" "$(tail -1 "$T/out")" "rc:1"
  # --- the third word: is Steam there? GONE lists the looks at which it is not.
  SA='c=0; polled() { c=$((c + 1)); [ "$c" -gt "$N" ]; }; up() { case " $GONE " in *" $c "*) return 1 ;; esac; return 0; }; signin_wait 4 polled up; echo "rc:$? polls:$c"'
  alivecase() {   # <name> <polls that fail first> <looks at which Steam is gone> <rc> <polls> <seconds slept> [NAME=value ...]
    local name="$1" nfail="$2" gone="$3" want="rc:$4 polls:$5 slept:$6 stderr:0"; shift 6
    drive "$B" "$SA" "N=$nfail" "GONE=$gone" "$@"
    check "$tag sign-in wait, $name" "$(tail -1 "$T/out") slept:$(awk '{ s += $1 } END { print s + 0 }' "$T/sleeps") stderr:$(wc -c < "$T/err" | tr -d ' ')" "$want"
  }
  alivecase "Steam seen, then gone for 15 s: 1 at once"                 100000 "5 6 7 8 9"                 1 9  24
  alivecase "Steam never seen: waited for until the limit"             100000 "1 2 3 4 5 6 7 8 9 10 11"   1 11 30 L1_SIGNIN_SECS=30
  alivecase "Steam gone 9 s, back, gone 6 s: waited for until the limit" 100000 "3 4 5 8 9"               1 11 30 L1_SIGNIN_SECS=30
  alivecase "Steam gone 6 s, back, then signed in: 0"                   6      "3 4"                       0 7  18
  alivecase "Steam seen 60 s, then gone for 15 s, no fourth word: 1 at once" 100000 "21 22 23 24 25"       1 25 72
  check "$tag   ...and no restart line" "$(grep -c 'Starting Steam again' "$T/out")" 0
  # --- the fourth word: how to start Steam again (docs/plans/signin-restart.md, 4.1). The word given here counts
  #     its calls, prints the look at which each came, and returns SRC. A look is one poll, every 3 s.
  SR='c=0; s=0; polled() { c=$((c + 1)); [ "$c" -gt "$N" ]; }; up() { case " $GONE " in *" $c "*) return 1 ;; esac; return 0; }; again() { s=$((s + 1)); echo "start at look $c"; return "${SRC:-0}"; }; signin_wait 4 polled up again; echo "rc:$? polls:$c starts:$s"'
  AGAIN='[4/5] Starting Steam again. If macOS asks a question, answer it…'
  looks() { seq "$1" "$2" | tr '\n' ' '; }   # <first> <last>: those looks, as a list
  startcase() {   # <name> <polls that fail first> <looks at which Steam is gone> <rc> <polls> <starts> <the looks of the starts, - for none> <restart lines> <seconds slept> [NAME=value ...]
    local name="$1" nfail="$2" gone="$3" want="rc:$4 polls:$5 starts:$6 at:$7 lines:$8 slept:$9 other:0 stderr:0"; shift 9
    drive "$B" "$SR" "N=$nfail" "GONE=$gone" "$@"
    check "$tag sign-in wait, $name" \
      "$(tail -1 "$T/out") at:$(awk '/^start at look / { a = a (a == "" ? "" : ",") $4 } END { print (a == "" ? "-" : a) }' "$T/out") lines:$(grep -cxF -- "$AGAIN" "$T/out") slept:$(awk '{ s += $1 } END { print s + 0 }' "$T/sleeps") other:$(grep -v -e '^start at look ' -e '^rc:' "$T/out" | grep -vxF -e "$HINT" -e "$AGAIN" | wc -l | tr -d ' ') stderr:$(wc -c < "$T/err" | tr -d ' ')" \
      "$want"
  }
  startcase "seen 20 looks, gone 5: started again once at that look, as step 4, then signed in: 0" \
    30 "$(looks 21 25)" 0 31 1 25 1 90
  check "$tag   ...and the restart line comes before the start word is called" "$(grep -n -e '^start at look ' -e 'Starting Steam again' "$T/out" | sed 's/^[0-9]*://; s/ .*//' | tr '\n' ' ')" "[4/5] start "
  startcase "seen 19 looks, gone 5: 1 at once, not started again" \
    100000 "$(looks 20 24)" 1 24 0 - 0 69
  startcase "three departures of a Steam seen 20 looks each: started again twice, 1 at the third" \
    100000 "$(looks 21 25)$(looks 46 50)$(looks 71 75)" 1 75 2 25,50 2 222
  startcase "57 s of the wait left: 1 at once, not started again" \
    100000 "$(looks 21 25)" 1 25 0 - 0 72 L1_SIGNIN_SECS=129
  startcase "60 s of the wait left: started again, and waited for until the limit" \
    100000 "$(looks 21 25)" 1 45 1 25 1 132 L1_SIGNIN_SECS=132
  startcase "started again and never seen for 5 looks: 1, one start" \
    100000 "$(looks 21 400)" 1 30 1 25 1 87
  startcase "started again, seen 10 looks and gone: 1, no second start" \
    100000 "$(looks 21 25)$(looks 36 400)" 1 40 1 25 1 117
  startcase "the start word returns 1: 1 at once, after its one line" \
    100000 "$(looks 21 25)" 1 25 1 25 1 72 SRC=1
  startcase "started again, first seen at the fourth look after it: the wait goes on, then signed in: 0, one start" \
    40 "$(looks 21 25)$(looks 26 28)" 0 41 1 25 1 120
  startcase "L1_SIGNIN_SECS=090 with the third and fourth words, Steam up and never signed in: 1 after 90 s" \
    100000 "" 1 31 0 - 0 90 L1_SIGNIN_SECS=090
  startcase "L1_SIGNIN_SECS=090, Steam seen 20 looks and gone 5: 18 s are left, 1 at once, not started again" \
    100000 "$(looks 21 25)" 1 25 0 - 0 72 L1_SIGNIN_SECS=090
  tot=""
  for k in $(seq 1 40); do
    drive "$B" "$SR" N=100000 "GONE=$(looks $((k + 1)) 400)" L1_SIGNIN_SECS=120
    tot="$tot$(sed -n 's/^rc:\([0-9]*\) polls:[0-9]* starts:\([0-9]*\)$/\1\2/p' "$T/out")$(grep -c 'Starting Steam again' "$T/out")$(wc -c < "$T/err" | tr -d ' ') "
  done
  check "$tag sign-in wait, L1_SIGNIN_SECS=120, Steam leaving after each of 1 to 40 looks: 1, never started again" "$tot" "$(printf '1000 %.0s' $(seq 1 40))"
  drive "$B" "$SR" N=30 "GONE=$(looks 21 25)" "${P}_QUIET=1"; a=$(grep -cxF 'Starting Steam again. If macOS asks a question, answer it…' "$T/osa")
  drive "$B" "$SR" N=30 "GONE=$(looks 21 25)" "${P}_QUIET=1" "${P}_PANEL=1"
  check "$tag sign-in wait: its restart line is a step (1 pop-up with no window, 0 with it)" "$a:$(grep -cxF 'Starting Steam again. If macOS asks a question, answer it…' "$T/osa"):$(posts)" "1:0:0"
done

echo "$fails failure(s)"
[ "$fails" = 0 ]
