#!/bin/bash
# test-mod-notes.sh — exercises launch-relaunched.sh's notes about mods from Paradox Mods in a new
# install (docs/plans/first-run-findings.md, 2.6; rows FT4 and FT4c) without Steam, wine or the game.
# It works on a copy of the launcher: it sources the copy's code between the `>>> mod-notes` and
# `<<< mod-notes` markers and its launch-feedback block (for _alert), reads the copy's own lines for
# where the calls stand, and gives the functions the game's real log lines. `osascript` and `cp` are
# recording stubs; HOME, the prefix and the state folder are scratch folders, the state folder with a
# space in its path as the real one has.
#
# The fixtures in tools/fixtures/mod-notes/ are the marker lines of real logs (ML2, ML3, ML4, P5),
# nothing else of them. The repository stores no carriage return, so a line that ended in one in the
# game's log ends in the four characters <CR> there, and this test puts it back.
#
#   bash tools/test-mod-notes.sh [path/to/launch-relaunched.sh]   exit 0 = every case passed
#   MUTANT=<n> bash tools/test-mod-notes.sh                        must exit 1; 2 = the mutant did not apply
#     1  the note on every start                     2  the note as a notification
#     3  the note before the lock is taken           4  the note after step 1
#     5  the alert before the note is printed        6  "present, but not loaded" not looked for
#     7  "which is not present" not looked for       8  a session with neither line is named
#     9  the title placed in the script's source     10 the newest log read whatever its time
#     11 a missing log stops the launcher            12 a title cut in the middle of a character is kept
#     13 the copy on every start                     14 the copy before the cloud check
#     15 the saves moved instead of copied           16 a saves folder that is a link is followed
#     17 a failed copy stops the launch              18 a failed copy gets the final name
#     19 the home folder's path in the line          20 an existing copy is written over
#     21 backup/ is not made                         22 cp's own words are not sent away
#     23 files are looked for at the top level only  24 the copy only when the cloud says "up to date"
#     25 a line of the launcher reads account.dat
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHER="${1:-$REPO/launch-relaunched.sh}"
FIX="$REPO/tools/fixtures/mod-notes"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
T="$(cd "$T" && pwd -P)"

L="$T/launcher.sh"; cp "$LAUNCHER" "$L"
mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
py() { python3 - "$L" "$@" || mutated; }
case "${MUTANT:-0}" in
  0) ;;
  1) sed -i '' 's/^  \[ -e "\$GAME_DATA\/LocalStorage\.lua" \] || FIRST_START=1$/  FIRST_START=1/' "$L"
     grep -q '^  FIRST_START=1$' "$L" || mutated ;;
  2) sed -i '' 's/^  \[ "\$QUIET" = 1 \] && _alert "\$MOD_NOTE" warning$/  [ "$QUIET" = 1 ] \&\& _notify "$MOD_NOTE"/' "$L"
     grep -q '^  \[ "\$QUIET" = 1 \] && _notify "\$MOD_NOTE"$' "$L" || mutated ;;
  3) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
call = 'first_start_look; first_start_note\n'; lock = 'acquire_lock 90 || die '
assert s.count(call) == 1 and s.count(lock) == 1
s = s.replace(call, ''); s = s.replace(lock, call + lock)
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  4) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
call = 'first_start_look; first_start_note\n'; st = '  step 1 "Starting Steam and signing in…"\n'
assert s.count(call) == 1 and s.count(st) == 1
s = s.replace(call, ''); s = s.replace(st, st + call)
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  5) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  echo "$MOD_NOTE"\n  [ "$QUIET" = 1 ] && _alert "$MOD_NOTE" warning\n'
assert s.count(a) == 1
s = s.replace(a, '  [ "$QUIET" = 1 ] && _alert "$MOD_NOTE" warning\n  echo "$MOD_NOTE"\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  6) sed -i '' '/^    \/\^\\\[mod\\\] This savegame tries to load Mod \.\* \\(id \.\*which is present, but not loaded\/ {$/s/.*/    \/^never matched$\/ {/' "$L"
     grep -q '^    /^never matched\$/ {$' "$L" || mutated ;;
  7) sed -i '' 's/^    \/\^\\\[mod\\\] Savegame references Mod \.\* \\(id \.\*which is not present\/ ||$/    \/^never matched$\/ ||/' "$L"
     grep -q '^    /^never matched\$/ ||$' "$L" || mutated ;;
  8) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '    /^\\[mod\\] Savegame references Mod .* \\(id .*which is not present/ ||\n'
b = '      sub(/^\\[mod\\] (Savegame references|This savegame tries to load) Mod /, "", t)\n'
assert s.count(a) == 1 and s.count(b) == 1
s = s.replace(a, a + '    /^\\[mod\\] Loaded mod def .* \\(id / ||\n')
s = s.replace(b, '      sub(/^\\[mod\\] (Loaded mod def|Savegame references Mod|This savegame tries to load Mod) /, "", t)\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  9) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  [ "$QUIET" = 1 ] && _alert "$MOD_MSG" warning\n'
assert s.count(a) == 1
s = s.replace(a, '  [ "$QUIET" = 1 ] && osascript -e "display alert \\"$TITLE\\" message \\"$MOD_MSG\\" as warning" >/dev/null 2>&1\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  10) sed -i '' '/^    \[ "\$stamp" \\< "\$1" \] && continue  /d' "$L"
      sed -i '' 's/^    f="\$g"; break$/    f="$g"/' "$L"
      grep -q '&& continue  ' "$L" && mutated; grep -q '^    f="\$g"$' "$L" || mutated ;;
  11) sed -i '' 's/^  \[ -n "\$f" \] || return 0$/  [ -n "$f" ] || exit 1/' "$L"
      grep -q '^  \[ -n "\$f" \] || exit 1$' "$L" || mutated ;;
  12) sed -i '' "s/^    }' | iconv -c -f UTF-8 -t UTF-8 2>\/dev\/null\$/    }'/" "$L"
      grep -q "^    }'\$" "$L" || mutated ;;
  13) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  local dest\n  [ "$FIRST_START" = 1 ] || return 0\n'
assert s.count(a) == 1
s = s.replace(a, '  local dest\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  14) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
call = '\nfirst_start_copy\n'; st = '\nstep 3 "Checking saves with Steam Cloud…"\n'
assert s.count(call) == 1 and s.count(st) == 1
s = s.replace(call, '\n'); s = s.replace(st, call + st[1:])
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  15) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '     cp -Rp -- "$SAVES_DIR" "$dest.partial" >/dev/null 2>&1 && mv -- "$dest.partial" "$dest"; then\n'
assert s.count(a) == 1
s = s.replace(a, '     mv -- "$SAVES_DIR" "$dest.partial" >/dev/null 2>&1 && mv -- "$dest.partial" "$dest"; then\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  16) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  [ ! -L "$SAVES_DIR" ] && [ -d "$SAVES_DIR" ] || return 0\n'
b = '  [ -n "$(find "$SAVES_DIR" -type f 2>/dev/null | head -n 1)" ] || return 0'
c = '     cp -Rp -- "$SAVES_DIR" "$dest.partial" '
assert s.count(a) == 1 and s.count(b) == 1 and s.count(c) == 1
s = s.replace(a, '  [ -d "$SAVES_DIR" ] || return 0\n')
s = s.replace(b, '  [ -n "$(find "$SAVES_DIR/" -type f 2>/dev/null | head -n 1)" ] || return 0')
s = s.replace(c, '     cp -Rp -- "$SAVES_DIR/" "$dest.partial" ')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  17) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = 'The game starts all the same."\n'
assert s.count(a) == 1
s = s.replace(a, a + '    die "The saves could not be copied."\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  18) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = ' >/dev/null 2>&1 && mv -- "$dest.partial" "$dest"; then\n'
assert s.count(a) == 1
s = s.replace(a, ' >/dev/null 2>&1; mv -- "$dest.partial" "$dest"; then\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  19) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = 'first start: $(home_tilde "$dest")"\n'
assert s.count(a) == 1
s = s.replace(a, 'first start: $dest"\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  20) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  if [ -e "$dest" ] || [ -e "$dest.partial" ]; then return 0; fi\n'
assert s.count(a) == 1
s = s.replace(a, '')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  21) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  if mkdir -p "$SM_STATE/backup" 2>/dev/null &&\n'
assert s.count(a) == 1
s = s.replace(a, '  if true &&\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  22) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '     cp -Rp -- "$SAVES_DIR" "$dest.partial" >/dev/null 2>&1 && '
assert s.count(a) == 1
s = s.replace(a, '     cp -Rp -- "$SAVES_DIR" "$dest.partial" && ')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  23) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '$(find "$SAVES_DIR" -type f 2>/dev/null | head -n 1)'
assert s.count(a) == 1
s = s.replace(a, '$(find "$SAVES_DIR" -maxdepth 1 -type f 2>/dev/null | head -n 1)')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  24) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
call = '\nesac\nfirst_start_copy\n'; arm = '  current) echo "Steam Cloud: saves up to date." ;;\n'
assert s.count(call) == 1 and s.count(arm) == 1
s = s.replace(call, '\nesac\n'); s = s.replace(arm, '  current) echo "Steam Cloud: saves up to date."; first_start_copy ;;\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  25) py <<'PY'
import io, sys
p = sys.argv[1]; s = io.open(p, encoding='utf-8').read()
a = '  [ "$FIRST_START" = 1 ] || return 0\n  echo "$MOD_NOTE"\n'
assert s.count(a) == 1
s = s.replace(a, '  [ "$FIRST_START" = 1 ] || return 0\n  [ -s "$SAVES_DIR/account.dat" ] || return 0\n  echo "$MOD_NOTE"\n')
io.open(p, 'w', encoding='utf-8').write(s)
PY
     ;;
  *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
esac
bash -n "$L" || { echo "REFUSED: the mutant is not valid bash"; exit 2; }

BLOCK="$T/block.sh"
sed -n '/^# >>> mod-notes/,/^# <<< mod-notes/p' "$L" > "$BLOCK"
[ -s "$BLOCK" ] || { echo "FAIL: no mod-notes block in $LAUNCHER"; exit 1; }
FEED="$T/feedback.sh"
sed -n '/^# >>> launch-feedback (/,/^# <<< launch-feedback$/p' "$L" > "$FEED"
[ -s "$FEED" ] || { echo "FAIL: no launch-feedback block in $LAUNCHER"; exit 1; }
# The lines that give MOD_MSG to the player stand at the launcher's end, outside the block.
GIVE="$T/give.sh"
sed -n '/^if \[ -n "\$MOD_MSG" \]; then$/,/^fi$/p' "$L" > "$GIVE"
[ -s "$GIVE" ] || { echo "FAIL: the launcher never gives MOD_MSG to the player"; exit 1; }

fails=0
ok()   { echo "  ok    $1"; }
bad()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; echo "        wanted: $3"; echo "        got:    $2"; fi; }

# Recording stubs. osascript: one file per call, one line per argument; whether the note was already
# in the caller's output when the alert was asked for is written beside it.
BIN="$T/bin"; mkdir -p "$BIN" "$T/osa"
cat > "$BIN/osascript" <<'EOF'
#!/bin/bash
n=$(ls "$OSA_DIR" | grep -c '^call-')
f="$OSA_DIR/call-$n"
: > "$f"
for a in "$@"; do printf '%s\n' "$a" >> "$f"; done
printf '%s\n' "$#" > "$OSA_DIR/argc-$n"
if [ -n "${OSA_OUT:-}" ] && grep -qF "Before you load or continue a save" "$OSA_OUT" 2>/dev/null; then echo yes; else echo no; fi > "$OSA_DIR/printed-$n"
exit 0
EOF
chmod +x "$BIN/osascript"
export OSA_DIR="$T/osa"
osa_reset() { rm -f "$T/osa"/*; }
osa_calls() { ls "$T/osa" | grep -c '^call-'; }

export HOME="$T/home"
export WINEPREFIX="$T/prefix"
SM_STATE="$HOME/Library/Application Support/1launcher/surviving-mars-relaunched"
mkdir -p "$HOME" "$WINEPREFIX" "$SM_STATE"
TITLE="Surviving Mars: Relaunched"; STEPS=5; PANEL=1; QUIET=0
PATH="$BIN:$PATH"
# shellcheck disable=SC1090
. "$FEED"
# shellcheck disable=SC1090
. "$BLOCK"
DATA="$WINEPREFIX/drive_c/users/Wineskin/AppData/Roaming/Surviving Mars Relaunched"
SAVES="$WINEPREFIX/drive_c/users/Wineskin/Saved Games/Surviving Mars Relaunched"
check "the block reads the game's own folder" "$GAME_DATA" "$DATA"
check "the block reads the saves folder" "$SAVES_DIR" "$SAVES"

NOTE="Before you load or continue a save in this new install: if you use mods from Paradox Mods, they start switched off. Accept the game's two agreements (scroll each to its end), log in to your Paradox account when the game offers it, then open Mod Manager from the main menu."

echo "== the note before the first start"
mkdir -p "$DATA"
osa_reset; QUIET=0
( first_start_look; first_start_note ) > "$T/out" 2>&1
check "no LocalStorage.lua, a terminal: the note is printed, alone" "$(cat "$T/out")" "$NOTE"
check "  and nothing is asked of osascript" "$(osa_calls)" 0
osa_reset; QUIET=1
( export OSA_OUT="$T/out"; first_start_look; first_start_note ) > "$T/out" 2>&1
check "no LocalStorage.lua, the app: the note is printed, alone" "$(cat "$T/out")" "$NOTE"
check "  and osascript is asked once" "$(osa_calls)" 1
check "  for an alert" "$(grep -c 'display alert' "$T/osa/call-0" 2>/dev/null)" 1
check "  not for a notification" "$(grep -c 'display notification' "$T/osa/call-0" 2>/dev/null)" 0
check "  as a warning" "$(grep -c 'as warning' "$T/osa/call-0" 2>/dev/null)" 1
check "  the note is one whole argument" "$(grep -cxF "$NOTE" "$T/osa/call-0" 2>/dev/null)" 1
check "  and it was printed before the alert was asked for" "$(cat "$T/osa/printed-0" 2>/dev/null)" yes
: > "$DATA/LocalStorage.lua"
for q in 0 1; do
  osa_reset; QUIET=$q
  ( first_start_look; first_start_note ) > "$T/out" 2>&1
  check "LocalStorage.lua is there (QUIET=$q): no note" "$(cat "$T/out")" ""
  check "  and nothing is asked of osascript" "$(osa_calls)" 0
done
rm -f "$DATA/LocalStorage.lua"; QUIET=0

ln_of() { grep -n -m 1 -- "$1" "$L" | cut -d: -f1; }
a=$(ln_of '^trap release_lock EXIT$'); b=$(ln_of '^first_start_look; first_start_note$'); c=$(ln_of '^  step 1 "')
check "the launcher makes the look and gives the note in one line" "$(grep -c '^first_start_look; first_start_note$' "$L")" 1
check "  and nowhere else" "$(grep -c 'first_start_note' "$L")" 2
if [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; then ok "  after the lock is taken and before step 1"
else bad "  after the lock is taken and before step 1 (lock ${a:-?}, note ${b:-?}, step 1 ${c:-?})"; fi

echo "== after the game has exited"
put_log() {   # <fixture> <log name> [nocr]: the fixture as the game wrote it, or with no carriage return at all
  mkdir -p "$DATA/logs"
  if [ "${3:-}" = nocr ]; then sed 's/<CR>$//' "$FIX/$1.txt" > "$DATA/logs/$2"
  else python3 - "$FIX/$1.txt" "$DATA/logs/$2" <<'PY'
import io, sys
out = []
for line in io.open(sys.argv[1], encoding='utf-8').read().split('\n')[:-1]:
    out.append(line[:-4] + '\r' if line.endswith('<CR>') else line)
io.open(sys.argv[2], 'w', encoding='utf-8', newline='').write('\n'.join(out) + '\n')
PY
  fi
}
LOGNAME="Mars.exe-20261113-13.24.10-6aba6e65.log"
report() { rm -rf "$DATA/logs"; put_log "$1" "$LOGNAME" "${2:-}"; mod_report 20261113-132400; printf '%s' "$MOD_MSG"; }
ONE="This session loaded a save that uses the mod Relaunched Fix Pack while it was switched off: it ran without it, and anything saved in it was saved without it. Open Mod Manager from the main menu before you load a save again."
for f in ml2-scratch ml4-scratch; do
  check "$f (\"which is not present\"): the mod is named by its title" "$(report $f)" "$ONE"
  check "  the same with no carriage returns" "$(report $f nocr)" "$ONE"
done
for f in ml2-real ml2-scratch-second; do
  check "$f (\"present, but not loaded\"): named" "$(report $f)" "$ONE"
  check "  the same with no carriage returns" "$(report $f nocr)" "$ONE"
done
check "the fixtures hold carriage returns for the test to put back" "$(grep -c '<CR>$' "$FIX/ml2-scratch.txt")" 4
rm -rf "$DATA/logs"; put_log ml2-scratch "$LOGNAME"
check "  and the log the functions read has them" "$(grep -c "$(printf '\r')\$" "$DATA/logs/$LOGNAME")" 4
check "ml4-real (definition, load, items after; neither line): no words" "$(report ml4-real)" ""
check "ml3 (items before the load): no words" "$(report ml3)" ""
check "p5-run1 (no load): no words" "$(report p5-run1)" ""
check "p5-run2 (no load): no words" "$(report p5-run2)" ""
grep -v '^\[mod\]' "$FIX/ml3.txt" > "$T/no-mod.txt"   # ML3's session with its mod's lines cut
nomod() { rm -rf "$DATA/logs"; mkdir -p "$DATA/logs"; sed 's/<CR>$//' "$T/no-mod.txt" > "$DATA/logs/$LOGNAME"; mod_report 20261113-132400; printf '%s' "$MOD_MSG"; }
check "a load with no mod at all: no words" "$(nomod)" ""

custom() {   # the lines on stdin as this session's log -> MOD_MSG
  rm -rf "$DATA/logs"; mkdir -p "$DATA/logs"; cat > "$DATA/logs/$LOGNAME"; mod_report 20261113-132400; printf '%s' "$MOD_MSG"
}
TAB="$(printf '\t')"; CR="$(printf '\r')"; ESC="$(printf '\033')"
two=$(printf '%s\n' "Load Game: " \
  "[mod] Savegame references Mod First One (id A_1, v1) which is not present$CR" \
  "[mod] This savegame tries to load Mod Second One (id B_2, v2), which is present, but not loaded$TAB${TAB}Lua 0:00:15:629" \
  "Load Game: " \
  "[mod] Savegame references Mod First One (id A_1, v1) which is not present$CR" | custom)
check "two mods in the game's lines: both named, each once" "$two" "This session loaded a save that uses the mods First One, Second One while they were switched off: it ran without them, and anything saved in it was saved without them. Open Mod Manager from the main menu before you load a save again."
four=$(for n in One Two Three Four; do echo "[mod] Savegame references Mod $n (id X_$n, v1) which is not present$CR"; done | custom)
check "four: three and \"and 1 more\"" "$four" "This session loaded a save that uses the mods One, Two, Three and 1 more while they were switched off: it ran without them, and anything saved in it was saved without them. Open Mod Manager from the main menu before you load a save again."

HOSTILE='a"b\c$(touch '"$T"'/pwned)`touch '"$T"'/pwned2`'
long="${HOSTILE}${ESC}[31m and a tail that goes on well past the sixtieth character of the title"
printf '%s\n' "[mod] Savegame references Mod $long (id H_1, v1) which is not present$CR" | custom > "$T/hostile.msg"
want60=$(printf '%s' "${HOSTILE}[31m and a tail that goes on well past the sixtieth character of the title" | cut -c1-60)
case "$(cat "$T/hostile.msg")" in
  "This session loaded a save that uses the mod $want60 while it was switched off:"*) ok "a title with quotes, a backslash, \$(...) and an escape character: carried as it is, 60 characters of it" ;;
  *) bad "a title with quotes, a backslash, \$(...) and an escape character: carried as it is, 60 characters of it"; echo "        got: $(cat "$T/hostile.msg")" ;;
esac
check "  the escape character is gone" "$(grep -c "$ESC" "$T/hostile.msg")" 0
give() {   # <MOD_MSG> <QUIET>: the launcher's own closing lines
  ( MOD_MSG="$1"; QUIET="$2"; . "$GIVE" )
}
osa_reset
give "$(cat "$T/hostile.msg")" 0 > "$T/out" 2>&1
check "in a terminal the words are a WARNING: line" "$(cat "$T/out")" "WARNING: $(cat "$T/hostile.msg")"
check "  and nothing is asked of osascript" "$(osa_calls)" 0
osa_reset
give "$(cat "$T/hostile.msg")" 1 > "$T/out" 2>&1
check "from the app: the WARNING: line" "$(cat "$T/out")" "WARNING: $(cat "$T/hostile.msg")"
check "  and one alert" "$(osa_calls)" 1
check "  whose message is one whole argument" "$(grep -cxF "$(cat "$T/hostile.msg")" "$T/osa/call-0" 2>/dev/null)" 1
check "  with no word of the title in the script's source" "$(grep -F 'display alert' "$T/osa/call-0" 2>/dev/null | grep -c 'touch')" 0
check "  and the same number of arguments as any other alert" "$(cat "$T/osa/argc-0" 2>/dev/null)" 9
if [ -e "$T/pwned" ] || [ -e "$T/pwned2" ]; then bad "  nothing in the title was run"; else ok "  nothing in the title was run"; fi
check "no mod, nothing to give: no line and no alert" "$(osa_reset; give "" 1 2>&1; osa_calls)" 0

wide=$(printf 'x'; for _ in $(seq 1 40); do printf 'é'; done)
printf '%s\n' "[mod] Savegame references Mod $wide (id W_1, v1) which is not present$CR" | custom > "$T/wide.msg"
if iconv -f UTF-8 -t UTF-8 < "$T/wide.msg" > /dev/null 2>&1; then ok "a title cut in the middle of a character: what is kept is whole characters"
else bad "a title cut in the middle of a character: what is kept is whole characters"; fi
want29=$(printf 'x'; for _ in $(seq 1 29); do printf 'é'; done)
case "$(cat "$T/wide.msg")" in "This session loaded a save that uses the mod $want29 while"*) ok "  59 bytes of it, the half character dropped" ;; *) bad "  59 bytes of it, the half character dropped"; echo "        got: $(cat "$T/wide.msg")" ;; esac

at() { rm -rf "$DATA/logs"; put_log ml2-scratch "$LOGNAME"; mod_report "$1"; printf '%s' "$MOD_MSG"; }
check "a log named for the second of the launch: read" "$(at 20261113-132410)" "$ONE"
check "a log named one second before the launch: not this session's, no words" "$(at 20261113-132411)" ""
check "a log of the day before: no words" "$(at 20261114-000000)" ""
rm -rf "$DATA/logs"; put_log ml2-scratch "Mars.exe-20261113-13.24.10-6aba6e65.log"; put_log ml3 "Mars.exe-20261113-14.51.30-6aba6e65.log"
mod_report 20261113-145100
check "an older log with the line and this session's without: no words" "$MOD_MSG" ""
rm -rf "$DATA/logs"; put_log ml3 "Mars.exe-20261113-14.51.30-6aba6e65.log"; put_log ml2-scratch "Mars.exe-20261113-15.00.00-6aba6e65.log"
mod_report 20261113-145100
check "two logs since the launch: the first is this session's" "$MOD_MSG" ""
rm -rf "$DATA/logs"
check "no log folder: no words and no failure" "$( (mod_report 20261113-132400; echo "rc=$? msg=[$MOD_MSG] went on") 2>&1)" "rc=0 msg=[] went on"
mkdir -p "$DATA/logs"; : > "$DATA/logs/notes.txt"
check "a log folder with no log: no words and no failure" "$( (mod_report 20261113-132400; echo "rc=$? msg=[$MOD_MSG] went on") 2>&1)" "rc=0 msg=[] went on"
a=$(ln_of '^echo "Game exited (rc='); b=$(ln_of '^mod_report "\$LSTAMP"'); c=$(ln_of '^mkdir -p "\$RUNS"; LSTAMP="\$(date +%Y%m%d-%H%M%S)"; LOG='); d=$(ln_of '^step 5 "')
if [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ -n "$d" ] && [ "$c" -lt "$d" ] && [ "$d" -lt "$a" ] && [ "$a" -lt "$b" ]; then ok "the launcher notes the time before step 5 and reads the log after the game has exited"
else bad "the launcher notes the time before step 5 and reads the log after the game has exited"; fi

echo "== a copy of the saves before the first start"
NUM=11112222   # stands for the numbered folder, whose real name is an account's number
BACKUP="$SM_STATE/backup"
mk_saves() {
  rm -rf "$SAVES" "$T/elsewhere"; mkdir -p "$SAVES/$NUM" "$T/elsewhere"
  echo one > "$SAVES/$NUM/a.savegame.sav"; echo two > "$SAVES/$NUM/b.dat"; echo kept > "$T/elsewhere/file"
  ln -s "$T/elsewhere" "$SAVES/$NUM/shortcut"
}
snap() {   # everything under the scratch folder but the backup folder and this test's own records
  (cd "$T" && find prefix home elsewhere 2>/dev/null | grep -v '/surviving-mars-relaunched/backup' | sort
   find prefix elsewhere -type f -exec shasum {} + 2>/dev/null | sort)
}
fresh() { rm -rf "$BACKUP" "$DATA/LocalStorage.lua"; }
copies() { ls "$BACKUP" 2>/dev/null | tr '\n' ' '; }
copy() { ( first_start_look; first_start_copy; echo "went on rc=$?" ) > "$T/out" 2>&1; }
LINE="A copy of your saves as they were on this Mac before this install's first start: ~/Library/Application Support/1launcher/surviving-mars-relaunched/backup/"
check "the state folder has a space in its path and is under the scratch home" "$SM_STATE" "$HOME/Library/Application Support/1launcher/surviving-mars-relaunched"

fresh; mk_saves; osa_reset; QUIET=1
check "the saves folder's top level holds one folder and no file" "$(find "$SAVES" -maxdepth 1 -type f | wc -l | tr -d ' '):$(ls "$SAVES")" "0:$NUM"
before="$(snap)"; copy; after="$(snap)"
name="$(ls "$BACKUP" 2>/dev/null)"
case "$name" in first-start-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ok "no LocalStorage.lua, no backup folder yet: one copy, named first-start-<stamp>" ;;
  *) bad "no LocalStorage.lua, no backup folder yet: one copy, named first-start-<stamp>"; echo "        backup holds: $(copies)" ;; esac
C="$BACKUP/$name"
check "  its files are the saves', byte for byte" "$(cmp -s "$SAVES/$NUM/a.savegame.sav" "$C/$NUM/a.savegame.sav" && cmp -s "$SAVES/$NUM/b.dat" "$C/$NUM/b.dat" && echo same)" same
check "  a link inside is copied as a link" "$([ -L "$C/$NUM/shortcut" ] && readlink "$C/$NUM/shortcut")" "$T/elsewhere"
check "  the one line, with ~, and the launch goes on" "$(cat "$T/out")" "$LINE$name
went on rc=0"
check "  the home folder's path is not in it" "$(grep -cF "$HOME" "$T/out")" 0
check "  nor the numbered folder's name" "$(grep -cF "$NUM" "$T/out")" 0
check "  nothing else under the scratch folder changed" "$after" "$before"
check "  the saves are still there" "$(cat "$SAVES/$NUM/a.savegame.sav" 2>/dev/null)" one
check "  no alert is asked for" "$(osa_calls)" 0

fresh; mk_saves; : > "$DATA/LocalStorage.lua"; copy
check "LocalStorage.lua is there: no copy, no line" "$(copies)|$(cat "$T/out")" "|went on rc=0"
fresh; rm -rf "$SAVES"; copy
check "no saves folder: no copy, no line" "$(copies)|$(cat "$T/out")" "|went on rc=0"
fresh; mkdir -p "$SAVES/$NUM/empty"; copy
check "a saves folder with folders and no file: no copy, no line" "$(copies)|$(cat "$T/out")" "|went on rc=0"
fresh; rm -rf "$SAVES" "$T/elsewhere"; mkdir -p "$T/elsewhere/$NUM"; echo kept > "$T/elsewhere/$NUM/file"; ln -s "$T/elsewhere" "$SAVES"; copy
check "a saves folder that is a link to a folder holding a file: no copy, no line" "$(copies)|$(cat "$T/out")" "|went on rc=0"
check "  and the link's target is untouched" "$(cat "$T/elsewhere/$NUM/file" 2>/dev/null):$([ -L "$SAVES" ] && echo link)" "kept:link"
rm -f "$SAVES"

# cp and date by their bare names: stubs first on PATH stand in for them
mkdir -p "$T/bin-cp" "$T/bin-date"
cat > "$T/bin-cp/cp" <<'STUB'
#!/bin/bash
for a in "$@"; do t="$a"; done
mkdir -p "$t"
echo "cp: $t/$STUB_NUM/a.savegame.sav: No space left on device" >&2
exit 1
STUB
printf '#!/bin/bash\necho 20261115-010203\n' > "$T/bin-date/date"
chmod +x "$T/bin-cp/cp" "$T/bin-date/date"
WARN="WARNING: The saves could not be copied before this first start (~/Library/Application Support/1launcher/surviving-mars-relaunched/backup/first-start-20261115-010203.partial). The game starts all the same."
fresh; mk_saves; osa_reset; QUIET=1
( export STUB_NUM="$NUM"; PATH="$T/bin-cp:$T/bin-date:$PATH"; first_start_look; first_start_copy; echo "went on rc=$?" ) > "$T/out" 2>&1
check "cp failing: the WARNING: line names the unfinished copy with ~, and the launch goes on" "$(cat "$T/out")" "$WARN
went on rc=0"
check "  what was copied is left under the .partial name, and no finished name" "$(copies)" "first-start-20261115-010203.partial "
check "  no line holds the home folder's path" "$(grep -cF "$HOME" "$T/out")" 0
check "  nor the numbered folder's name" "$(grep -cF "$NUM" "$T/out")" 0
check "  no alert is asked for" "$(osa_calls)" 0
fresh; mk_saves; : > "$BACKUP"
( PATH="$T/bin-date:$PATH"; first_start_look; first_start_copy; echo "went on rc=$?" ) > "$T/out" 2>&1
check "backup cannot be made (a file of that name): the WARNING: line, and the launch goes on" "$(cat "$T/out")" "$WARN
went on rc=0"
rm -f "$BACKUP"
for taken in first-start-20261115-010203 first-start-20261115-010203.partial; do
  fresh; mk_saves; mkdir -p "$BACKUP/$taken"; echo "an earlier copy" > "$BACKUP/$taken/marker"
  ( PATH="$T/bin-date:$PATH"; first_start_look; first_start_copy; echo "went on rc=$?" ) > "$T/out" 2>&1
  check "the name $taken is there already: nothing copied, nothing said" "$(copies)|$(cat "$T/out")" "$taken |went on rc=0"
  check "  and nothing inside it changed" "$(ls "$BACKUP/$taken" | tr '\n' ' '):$(cat "$BACKUP/$taken/marker")" "marker :an earlier copy"
done
fresh; rm -rf "$SAVES" "$T/elsewhere"

e=$(awk '/^case "\$SIGNIN" in$/ { c = 1 } c && /^esac$/ { print NR; exit }' "$L"); b=$(ln_of '^first_start_copy$'); c=$(ln_of '^step 4 "')
check "the launcher asks for the copy in one line of its own" "$(grep -c '^first_start_copy$' "$L")" 1
check "  and nowhere else" "$(grep -c 'first_start_copy' "$L")" 2
if [ -n "$e" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$e" -lt "$b" ] && [ "$b" -lt "$c" ]; then ok "  after the esac of the cloud check, so for every answer that goes on, and before step 4"
else bad "  after the esac of the cloud check, so for every answer that goes on, and before step 4 (esac ${e:-?}, copy ${b:-?}, step 4 ${c:-?})"; fi

echo "== the account's file is left alone"
# Its size was once taken for a sign of which mods are on; it is none (2.6). No line of the launcher, of
# setup, of the installer or of the shared core may name it outside a comment.
named() { grep -v '^[[:space:]]*#' "$1" | grep -c 'account\.dat'; }
check "no line of the launcher names account.dat outside a comment" "$(named "$L")" 0
for f in "$REPO/scripts/setup.sh" "$REPO/scripts/install.sh" "$REPO/../common/install-core.sh"; do
  check "  nor of ${f#"$REPO"/}" "$([ -f "$f" ] && named "$f")" 0
done

echo
if [ "$fails" = 0 ]; then echo "PASS: every case"; exit 0; fi
echo "FAIL: $fails case(s)"; exit 1
