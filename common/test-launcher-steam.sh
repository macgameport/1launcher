#!/bin/bash
# test-launcher-steam.sh -- how each launcher starts Steam and how it stops it (docs/plans/signin-restart.md, 4.2
# and 4.4). From each launcher it cuts start_steam and the piece between the stop-steam markers, and runs them in
# a fresh bash under `set -u` with stubs:
#   wine64       records its arguments. Given -shutdown with a stub Steam up, it does what the case says: ends
#                that Steam a moment later and returns (the default); returns at once and Steam stays ("ignores");
#                blocks 40 recorded seconds and ends Steam then ("blocks40"); or blocks for ever on a pipe nobody
#                writes to and records a TERM if one is sent ("forever"). Given -shutdown with no stub Steam up, it
#                becomes a client: it stays on that pipe, and records how it was ended.
#   wineserver   records its arguments, WINEPREFIX and how many sleeps came before it. -k ends the stub Steam and
#                a client that is attributed to the prefix by then, and never the client that is not, so that
#                the TERM to the call's own process is seen by itself.
#   sleep        recorded and cut to 0.05 s: the 60 and the 20 are counted in recorded sleeps, and the call in the
#                background gets to run.
#   pgrep        finds nothing (Cities: Skylines II asks it for a lingering wineserver).
#   steam_exe_up, steam_family   the harness's, in place of the launcher's own (which read pgrep and lsof and are
#                outside the pieces). The stub Steam is a file. A client the case attributes is seen as steam.exe
#                once 4 sleeps are recorded, and is in the family; a client the case does not attribute is never
#                seen and never in the family. The family also holds the stub webhelper, when the case has one.
# Every look, sleep, call and wineserver run goes into one list in order, and the cases read their counts from
# it. A watchdog of 10 s fails any case that does not return, and ends what it left. No Wine, no Steam, no game,
# and no process but the test's own is read or signalled.
#   bash common/test-launcher-steam.sh           exit 0 = every case passed; exit 2 = a launcher or a piece is missing
#   MUTANT=1 ...   the test over the call dropped (the call sent with no Steam up); must exit 1
#   MUTANT=2 ...   the call put in the foreground (the watchdog); must exit 1
#   MUTANT=3 ...   the call's own process no longer waited for (the loop of 60 ends at its first look); must exit 1
#   MUTANT=4 ...   the `wineserver -k` fallback dropped; must exit 1, by race (a)
#   MUTANT=5 ...   the TERM to the call's process dropped; must exit 1, by race (b)
#   MUTANT=6 ...   the sweep of strays dropped; must exit 1
#   MUTANT=7 ...   `rm -f` of the .crash marker dropped from start_steam; must exit 1
#   MUTANT=8 ...   `kill` made `kill -9` in the sweep; must exit 1
#   MUTANT=9 ...   the second look dropped from the test over the call; must exit 1
#   MUTANT=10 ...  the 60 s for the call's process made 20; must exit 1
#   MUTANT=11 ...  `_sd=""` dropped from the head of Cities: Skylines II's piece; must exit 1
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/launcher-steam-test.XXXX)"
endall() {   # end what a case left: only pids this test's own stubs recorded
  local f p
  for f in "$T"/s.*/client.pid "$T"/s.*/call.pid "$T"/s.*/helper.pid "$T"/s.*/harness.pid; do
    [ -f "$f" ] || continue
    p="$(cat "$f")"; case "$p" in ''|*[!0-9]*) continue ;; esac
    kill "$p" 2>/dev/null
  done
}
trap 'endall; rm -rf "$T"' EXIT
# launcher | the variable that holds its wine for Steam | how the stop piece is run
GAMES=("cities-skylines-2/launchers/launch-cs2-dxmt11.sh|WINE|inline"
       "surviving-mars-relaunched/launch-relaunched.sh|STEAM_WINE|stop_steam")
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
    1) sed -i '' 's/^\( *\)if steam_exe_up || { sleep 1; steam_exe_up; }; then   # with no Steam of this prefix up, .*$/\1if true; then/' "$L"
       grep -q '^ *if true; then$' "$L" && ! grep -q 'if steam_exe_up || { sleep 1; steam_exe_up; }; then' "$L" || mutated ;;
    2) sed -i '' 's/ -shutdown >\/dev\/null 2>&1 & _sd=\$!; disown$/ -shutdown >\/dev\/null 2>\&1; _sd=""/' "$L"
       grep -q -- ' -shutdown >/dev/null 2>&1; _sd=""$' "$L" && ! grep -q -- '-shutdown >/dev/null 2>&1 & ' "$L" || mutated ;;
    3) sed -i '' 's/kill -0 "\$_sd" 2>\/dev\/null || { _sd=""; break; }/break/' "$L"
       grep -q 'kill -0 "\$_sd" 2>/dev/null || { _sd=""; break; }' "$L" && mutated ;;
    4) awk '/^# >>> stop-steam$/ { b = 1 } b && !done && /wineserver" -k >\/dev\/null 2>&1$/ { done = 1; next } { print }' "$L" > "$L.new" && mv "$L.new" "$L"
       [ "$(grep -c 'wineserver" -k >/dev/null 2>&1$' "$L")" = "$(( $(grep -c 'wineserver" -k >/dev/null 2>&1$' "$HERE/$f") - 1 ))" ] || mutated ;;
    5) sed -i '' '/^ *\[ -n "\$_sd" \] && kill -0 "\$_sd" 2>\/dev\/null && kill "\$_sd" 2>\/dev\/null /d' "$L"; grep -q '&& kill "\$_sd"' "$L" && mutated ;;
    6) sed -i '' '/^ *\[ -n "\$_strays" \] && kill \$_strays 2>\/dev\/null /d' "$L"; grep -q 'kill \$_strays' "$L" && mutated ;;
    7) sed -i '' '/^  rm -f "\$WINEPREFIX\/drive_c\/Program Files (x86)\/Steam\/\.crash" 2>\/dev\/null$/d' "$L"; grep -q '^ *rm -f .*Steam/\.crash' "$L" && mutated ;;
    8) mutate "$L" 's/\] && kill \$_strays 2>/] \&\& kill -9 $_strays 2>/' '] && kill -9 $_strays 2>' ;;
    9) sed -i '' 's/^\( *\)if steam_exe_up || { sleep 1; steam_exe_up; }; then /\1if steam_exe_up; then /' "$L"
       grep -q '^ *if steam_exe_up; then   # with no Steam' "$L" && ! grep -q '{ sleep 1; steam_exe_up; }' "$L" || mutated ;;
    10) sed -i '' 's/\$(seq 1 60); do/$(seq 1 20); do/' "$L"; grep -q 'seq 1 60' "$L" && mutated ;;
    11) if [ "$n" = 1 ]; then
          awk '/^# >>> stop-steam$/ { print; getline; if ($0 != "_sd=\"\"") bad = 1; else next } { print } END { exit bad }' "$L" > "$L.new" && mv "$L.new" "$L" || mutated
          grep -q '^_sd=""$' "$L" && mutated
        fi ;;
    *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
  esac
  awk '/^start_steam\(\) \{/ { p = 1 } p { print } p && /^\}$/ { exit }' "$L" > "$T/start.$n.sh"
  sed -n '/^# >>> stop-steam$/,/^# <<< stop-steam$/p' "$L" > "$T/stop.$n.sh"
  grep -q '^start_steam() {' "$T/start.$n.sh" && grep -q '^# <<< stop-steam$' "$T/stop.$n.sh" && grep -q -- '-shutdown' "$T/stop.$n.sh" \
    || { echo "REFUSED: could not find start_steam and the stop-steam piece in $f"; exit 2; }
done

BIN="$T/bin"; mkdir -p "$BIN"
cat > "$BIN/wine64" <<'STUB'
#!/bin/bash
# the stub wine64: see the head of common/test-launcher-steam.sh
{ printf '%s' "$#"; printf '|%s' "$@"; echo; } >> "$S/wine.calls"
case " $* " in *" -shutdown "*) ;; *) exit 0 ;; esac
echo call-in >> "$S/events"
if [ -e "$S/steam.up" ]; then
  case "$(cat "$S/call.mode" 2>/dev/null)" in
    ignores) ;;
    blocks40) while [ "$(wc -l < "$S/sleeps" | tr -d ' ')" -lt 40 ]; do /bin/sleep 0.02; done; rm -f "$S/steam.up" ;;
    forever)
      echo "$$" > "$S/call.pid"
      trap 'echo TERM >> "$S/call.signals"; exit 0' TERM
      read -r _ < "$S/pipe" ;;
    *) /bin/sleep 0.15; rm -f "$S/steam.up" ;;
  esac
  echo call-out >> "$S/events"
  exit 0
fi
echo "$$" > "$S/client.pid"
trap 'if [ -e "$S/ended.by.wineserver" ]; then echo WINESERVER >> "$S/client.signals"; else echo TERM >> "$S/client.signals"; fi; exit 0' TERM
read -r _ < "$S/pipe"
echo released >> "$S/client.signals"
exit 0
STUB
cat > "$BIN/wineserver" <<'STUB'
#!/bin/bash
n=$(wc -l < "$S/sleeps" | tr -d ' ')
echo "$* | ${WINEPREFIX:-unset} | after $n sleeps" >> "$S/wineserver.calls"
echo wineserver >> "$S/events"
case " $* " in
  *" -k "*)
    rm -f "$S/steam.up"
    if [ -e "$S/client.attributed" ] && [ -f "$S/client.pid" ] && [ "$n" -ge 4 ]; then
      p="$(cat "$S/client.pid")"; : > "$S/ended.by.wineserver"; kill "$p" 2>/dev/null
      i=0; while kill -0 "$p" 2>/dev/null && [ "$i" -lt 40 ]; do i=$((i + 1)); /bin/sleep 0.05; done
    fi ;;
esac
exit 0
STUB
printf '#!/bin/bash\necho "$1" >> "$S/sleeps"\necho sleep >> "$S/events"\n/bin/sleep 0.05\n' > "$BIN/sleep"
printf '#!/bin/bash\nexit 1\n' > "$BIN/pgrep"
cat > "$BIN/helper" <<'STUB'
#!/bin/bash
# a stub webhelper left over: it stays until it is signalled, and records a TERM (a KILL leaves no record)
trap 'echo TERM >> "$S/helper.signals"; exit 0' TERM
echo "$$" > "$S/helper.pid"
while :; do /bin/sleep 0.05; done
STUB
chmod +x "$BIN/wine64" "$BIN/wineserver" "$BIN/sleep" "$BIN/pgrep" "$BIN/helper"
# the harness: <the launcher's wine variable> <piece> <shell text run after the piece>
cat > "$T/harness.sh" <<'HARNESS'
set -u
echo "$$" > "$S/harness.pid"
WINEPREFIX="$S/prefix"; export WINEPREFIX
STEAM="$S/prefix/drive_c/Program Files (x86)/Steam/steam.exe"; CL="$S/connection_log.txt"
SS="$S/ss"; ENGINE="$S/ss/wine"; APPTAG="no-such-wrapper.app"
eval "$1=\"\$BIN/wine64\""
_client() { [ -f "$S/client.pid" ] && kill -0 "$(cat "$S/client.pid")" 2>/dev/null; }
steam_exe_up() {
  local k; echo look >> "$S/events"; k=$(grep -c '^look$' "$S/events")
  [ -e "$S/first.false" ] && [ "$k" = 1 ] && return 1
  if [ -e "$S/steam.leaves" ] && [ -e "$S/steam.up" ]; then rm -f "$S/steam.up"; return 0; fi   # seen at this look, gone before the next line runs
  [ -e "$S/steam.up" ] && return 0
  [ -e "$S/client.attributed" ] && _client && [ "$(wc -l < "$S/sleeps" | tr -d ' ')" -ge 4 ] && return 0
  return 1
}
steam_family() {
  [ -e "$S/helper.pid" ] && kill -0 "$(cat "$S/helper.pid")" 2>/dev/null && cat "$S/helper.pid"
  [ -e "$S/client.attributed" ] && _client && cat "$S/client.pid"
  return 0
}
. "$2"
eval "$3"
HARNESS
fresh() {   # a new state folder for one case, in S
  S="$(mktemp -d "$T/s.XXXX")"
  mkdir -p "$S/prefix/drive_c/Program Files (x86)/Steam" "$S/ss/wine/bin"
  cp "$BIN/wineserver" "$S/ss/wine/bin/wineserver"
  : > "$S/wine.calls"; : > "$S/wineserver.calls"; : > "$S/sleeps"; : > "$S/events"; mkfifo "$S/pipe"
}
run() {   # <wine variable> <piece> <shell text>: under the watchdog; output in $S/out and $S/err; RET is returned or hung
  local i=0
  env -i HOME="$HOME" PATH="$BIN:/usr/bin:/bin" S="$S" BIN="$BIN" /bin/bash "$T/harness.sh" "$1" "$2" "$3" > "$S/out" 2> "$S/err" < /dev/null &
  local h=$!
  RET=returned
  while kill -0 "$h" 2>/dev/null; do
    i=$((i + 1)); [ "$i" -gt 100 ] && { RET=hung; kill "$h" 2>/dev/null; break; }
    /bin/sleep 0.1
  done
  wait "$h" 2>/dev/null
}
settle() { local i=0; while [ ! -s "$1" ] && [ "$i" -lt 40 ]; do i=$((i + 1)); /bin/sleep 0.05; done; }   # <file>: wait up to 2 s for it to hold something
calls() { grep -c -- '-shutdown' "$S/wine.calls"; }
ks() { grep -c -- '^-k ' "$S/wineserver.calls"; }
kline() { grep -- '^-k ' "$S/wineserver.calls" | head -1; }
slept() { tr '\n' ' ' < "$S/sleeps" | sed 's/ $//'; }
nslept() { wc -l < "$S/sleeps" | tr -d ' '; }
sig() { [ -f "$1" ] && tr '\n' ' ' < "$1" | sed 's/ $//' || echo none; }
alive() { [ -f "$1" ] && kill -0 "$(cat "$1")" 2>/dev/null && echo alive || echo gone; }
up() { [ -e "$S/steam.up" ] && echo yes || echo no; }
errs() { wc -c < "$S/err" | tr -d ' '; }
ev() { awk "$1" "$S/events"; }   # <awk program>: over the list of looks, sleeps, calls and wineserver runs
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
COUNT='  Residual Steam-family processes in this prefix: 0'

n=0
for g in "${GAMES[@]}"; do
  n=$((n + 1)); f="${g%%|*}"; r="${g#*|}"; WV="${r%%|*}"; HOW="${r#*|}"; tag="${f##*/}:"
  START="$T/start.$n.sh"; STOP="$T/stop.$n.sh"
  [ "$HOW" = inline ] && GO=':' || GO="$HOW"
  counted() { [ "$HOW" != inline ] && { echo -; return; }; [ "$(tail -1 "$S/out")" = "$COUNT" ] && echo yes || echo "no: $(tail -1 "$S/out")"; }   # Cities: Skylines II's count line, always its last
  [ "$HOW" = inline ] && CN=yes || CN=-

  # --- start_steam: the first start and a second one
  SHOW='echo "rc:$? BEFORE:$((BEFORE)) marker:$([ -e "$WINEPREFIX/drive_c/Program Files (x86)/Steam/.crash" ] && echo there || echo gone) jobs:$(jobs | wc -l | tr -d " ")"'
  AWAIT='i=0; while [ "$(wc -l < "$S/wine.calls" | tr -d " ")" -lt "$W" ] && [ "$i" -lt 40 ]; do i=$((i + 1)); /bin/sleep 0.05; done'
  fresh; MARK="$S/prefix/drive_c/Program Files (x86)/Steam/.crash"
  printf 'a\nb\nc\n' > "$S/connection_log.txt"; : > "$MARK"
  run "$WV" "$START" "start_steam; $SHOW; W=1; $AWAIT
    printf 'd\ne\n' >> \"\$CL\"; : > \"\$WINEPREFIX/drive_c/Program Files (x86)/Steam/.crash\"
    start_steam; $SHOW; W=2; $AWAIT"
  check "$tag start_steam, first and second call: returns 0, BEFORE is the log's line count then, the marker is gone, no job is left" \
    "$RET|$(tr '\n' '|' < "$S/out")" "returned|rc:0 BEFORE:3 marker:gone jobs:0|rc:0 BEFORE:5 marker:gone jobs:0|"
  check "$tag   ...each started one child, with Steam's path and the two options as three arguments" \
    "$(tr '\n' ';' < "$S/wine.calls")" "3|$S/prefix/drive_c/Program Files (x86)/Steam/steam.exe|-silent|-no-cef-sandbox;3|$S/prefix/drive_c/Program Files (x86)/Steam/steam.exe|-silent|-no-cef-sandbox;"
  check "$tag   ...and bash printed nothing of its own" "$(errs)" 0
  fresh; : > "$S/prefix/drive_c/Program Files (x86)/Steam/.crash"
  run "$WV" "$START" "start_steam 2> \"\$S/err.start\"; $SHOW; W=1; $AWAIT"
  check "$tag start_steam with no connection log yet: returns 0, BEFORE is 0, the marker is gone, one child, no job is left" \
    "$RET|$(cat "$S/out")|$(wc -l < "$S/wine.calls" | tr -d ' ')" "returned|rc:0 BEFORE:0 marker:gone jobs:0|1"
  # bash itself reports the log that is not there (the `<` fails before `2>/dev/null` applies): one line, as at
  # the launcher's first BEFORE= line today, and nothing else
  check "$tag   ...and the only line on stderr is bash's own, that the log is not there" \
    "$(wc -l < "$S/err.start" | tr -d ' '):$(grep -c 'connection_log.txt: No such file or directory$' "$S/err.start"):$(errs)" "1:1:0"

  # --- stopping: no Steam up
  fresh
  run "$WV" "$STOP" "$GO"
  check "$tag stop, no Steam up: returns, no call, no wineserver -k, the only waits are the second look's 1$([ "$HOW" = inline ] || echo ' and the 2')" \
    "$RET calls:$(calls) k:$(ks) slept:$(slept) client:$(alive "$S/client.pid") count:$(counted) stderr:$(errs)" \
    "returned calls:0 k:0 slept:1$([ "$HOW" = inline ] || echo ' 2') client:gone count:$CN stderr:0"
  if [ "$HOW" = inline ]; then
    check "$tag   ...and it says so, and prints its count" "$(tr '\n' '|' < "$S/out")" "  Steam is not running: nothing to shut down.|$COUNT|"
  fi

  # --- stopping: a Steam up that leaves at the call
  fresh; : > "$S/steam.up"
  run "$WV" "$STOP" "$GO"
  check "$tag stop, Steam up: one call with -shutdown, the looks for Steam begin only after the call has returned, no wineserver -k" \
    "$RET calls:$(calls) args:$(head -1 "$S/wine.calls" | cut -d'|' -f1,3) looks before the call returned:$(ev '/^call-out$/ { exit } /^look$/ { n++ } END { print n + 0 }') up:$(up) k:$(ks) waited:$([ "$(nslept)" -lt 20 ] && echo "under 20" || echo "20 or more") count:$(counted) stderr:$(errs)" \
    "returned calls:1 args:2|-shutdown looks before the call returned:1 up:no k:0 waited:under 20 count:$CN stderr:0"
  if [ "$HOW" = inline ]; then
    check "$tag   ...and it prints its count, and no line of a fallback" "$(tr '\n' '|' < "$S/out")" "$COUNT|"
  fi

  # --- stopping: a Steam up that one look misses
  fresh; : > "$S/steam.up"; : > "$S/first.false"
  run "$WV" "$STOP" "$GO"
  check "$tag stop, Steam up and the first look false: a second look 1 s later, and one call all the same" \
    "$RET calls:$(calls) first wait:$(head -1 "$S/sleeps") looks before the call:$(ev '/^call-in$/ { exit } /^look$/ { n++ } END { print n + 0 }') up:$(up) k:$(ks) stderr:$(errs)" \
    "returned calls:1 first wait:1 looks before the call:2 up:no k:0 stderr:0"

  # --- stopping: a Steam up that ignores the call
  fresh; : > "$S/steam.up"; echo ignores > "$S/call.mode"
  run "$WV" "$STOP" "$GO"
  check "$tag stop, Steam ignores the call: one call, wineserver -k once for this prefix after 20 looks a second apart, Steam gone" \
    "$RET calls:$(calls) k:$(ks) $(kline | cut -d'|' -f1,2) seconds between the first look after the call and wineserver:$(ev '/^wineserver$/ { exit } /^look$/ { l++ } l >= 2 && /^sleep$/ { n++ } END { print n + 0 }') up:$(up) count:$(counted) stderr:$(errs)" \
    "returned calls:1 k:1 -k | $S/prefix  seconds between the first look after the call and wineserver:20 up:no count:$CN stderr:0"

  # --- stopping: the call blocks 40 s while Steam needs 40 s
  fresh; : > "$S/steam.up"; echo blocks40 > "$S/call.mode"
  run "$WV" "$STOP" "$GO"
  check "$tag stop, the call blocks 40 recorded seconds while Steam needs 40: waited for, no wineserver -k" \
    "$RET calls:$(calls) k:$(ks) up:$(up) waited:$([ "$(nslept)" -ge 40 ] && [ "$(nslept)" -lt 60 ] && echo "40 to 59" || nslept) looks before the call returned:$(ev '/^call-out$/ { exit } /^look$/ { n++ } END { print n + 0 }') stderr:$(errs)" \
    "returned calls:1 k:0 up:no waited:40 to 59 looks before the call returned:1 stderr:0"

  # --- stopping: the call blocks for ever with Steam up
  fresh; : > "$S/steam.up"; echo forever > "$S/call.mode"
  run "$WV" "$STOP" "$GO"; settle "$S/call.signals"
  check "$tag stop, the call blocks for ever with Steam up: wineserver -k once after 60 recorded seconds, no look meanwhile, and the call's TERM" \
    "$RET calls:$(calls) k:$(ks) $(kline | cut -d'|' -f3) looks before wineserver:$(ev '/^wineserver$/ { exit } /^look$/ { n++ } END { print n + 0 }') up:$(up) call got:$(sig "$S/call.signals") now:$(alive "$S/call.pid") count:$(counted) stderr:$(errs)" \
    "returned calls:1 k:1  after 60 sleeps looks before wineserver:2 up:no call got:TERM now:gone count:$CN stderr:0"

  # --- race (a): Steam leaves between the test and the call; the client the call became is attributed to the prefix
  fresh; : > "$S/steam.up"; : > "$S/steam.leaves"; : > "$S/client.attributed"
  run "$WV" "$STOP" "$GO"; settle "$S/client.signals"
  check "$tag stop, race (a), the client is attributed: returns after 60 recorded seconds, wineserver -k once, and it ends the client" \
    "$RET calls:$(calls) client:$([ -f "$S/client.pid" ] && echo started || echo none) k:$(ks) $(kline | cut -d'|' -f3) client ended by:$(sig "$S/client.signals") now:$(alive "$S/client.pid") count:$(counted) stderr:$(errs)" \
    "returned calls:1 client:started k:1  after 60 sleeps client ended by:WINESERVER now:gone count:$CN stderr:0"

  # --- race (b): the same, and the client is never attributed
  fresh; : > "$S/steam.up"; : > "$S/steam.leaves"
  run "$WV" "$STOP" "$GO"; settle "$S/client.signals"
  check "$tag stop, race (b), the client is never attributed: wineserver -k once after 60 recorded seconds does not end it, the TERM to the call does" \
    "$RET calls:$(calls) client:$([ -f "$S/client.pid" ] && echo started || echo none) k:$(ks) $(kline | cut -d'|' -f3) client ended by:$(sig "$S/client.signals") now:$(alive "$S/client.pid") count:$(counted) stderr:$(errs)" \
    "returned calls:1 client:started k:1  after 60 sleeps client ended by:TERM now:gone count:$CN stderr:0"

  # --- stopping: a webhelper left over after Steam has gone
  fresh; : > "$S/steam.up"
  S="$S" "$BIN/helper" > /dev/null 2>&1 &
  settle "$S/helper.pid"
  run "$WV" "$STOP" "$GO"; settle "$S/helper.signals"
  check "$tag stop, a webhelper left over: it gets a TERM and never a KILL" \
    "$RET calls:$(calls) helper got:$(sig "$S/helper.signals") now:$(alive "$S/helper.pid") stderr:$(errs)" \
    "returned calls:1 helper got:TERM now:gone stderr:0"
  endall
done

echo "$fails failure(s)"
[ "$fails" = 0 ]
