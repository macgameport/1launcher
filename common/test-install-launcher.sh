#!/bin/bash
# test-install-launcher.sh -- common/install-launcher.sh, the launcher's own installer
# (docs/plans/launcher-first-install.md, 3.4; LFT2 and LFT11). A copy of it runs in a scratch tree beside the
# real common/paths.sh, common/updates.sh, common/tools.sh and common/games.tsv, with HOME at a scratch folder.
# xcode-select, xcrun, sw_vers, sysctl, open, sleep and id are stubs first on PATH that write to one record of
# calls, so this Mac's own tools, macOS and processor are not what is tested and nothing waits; the window's
# builder is a stand-in that records its call and what existed when it was called. Nothing is compiled, no
# network, nothing of Wine, and nothing is written outside the scratch folder.
#   bash common/test-install-launcher.sh            exit 0 = every case passed
#   MUTANT=<n> bash common/test-install-launcher.sh   each must exit 1; 2 = the mutant did not apply
#     1 the stamp written before the build              2 the stamp written when the build was skipped
#     3 updates.sh deployed after the builder           4 the wait for the tools dropped
#     5 the build begun before the wait ends            6 open called after a failure
#     7 the own-folder test dropped                     8 the request moved before the macOS test
#     9 the compiler check dropped                     10 the versions compared as decimals
#    11 macOS 14.0 refused                             12 the caution below macOS 26 dropped
#    13 a folder that is there with a broken part asked about
#   The install's lock (3.8; LFT2's cases "with LF4a"):
#    14 the lock not released on a signal (the trap on EXIT dropped)
#    15 the lock still held when the window is opened
#    16 L1_UPDATE=1 believed with no live `updating`
set -u
unset L1_UPDATE_DIR L1_UPDATE L1_UPDATE_NOW L1_FETCHED_REF L1_FETCHED_COMMIT L1_DATA_ROOT L1_WORK_ROOT   # the cases' own
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/install-launcher-test.XXXX)"
BG=""; LIVE=""
trap '[ -n "$BG" ] && kill "$BG" 2>/dev/null; [ -n "$LIVE" ] && { kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null; }; rm -rf "$T"' EXIT
M="${MUTANT:-0}"
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

# --- the scratch tree: the installer under test, the real files it reads, and a stand-in for the builder
R="$T/repo"; mkdir -p "$R/common" "$T/bin"
S="$R/common/install-launcher.sh"; cp "$REPO/common/install-launcher.sh" "$S"
cp "$REPO/common/paths.sh" "$REPO/common/updates.sh" "$REPO/common/tools.sh" "$REPO/common/games.tsv" "$REPO/common/launcher-window.swift" "$R/common/"
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.4.2 (2026-11-24)' '' 'Words.' '' '## v0.4.1 (2026-11-20)' > "$R/CHANGELOG.md"
cat > "$R/common/make-launcher-app.sh" << 'STUB'
#!/bin/bash
# the stand-in: its call, and what existed then (the deployed tool, the launcher's stamp, Apple's tools)
tool=missing; [ -f "$UPD/updates.sh" ] && cmp -s "$UPD/updates.sh" "$(dirname "$0")/updates.sh" && tool=same
stamp=none; [ -e "$UPD/launcher" ] && stamp="$(cut -f2 "$UPD/launcher")"
tools=there; [ -n "${STUB_NO_TOOLS:-}" ] && [ ! -f "$ST/tools" ] && tools=absent
echo "BUILDER args=$# tool=$tool stamp=$stamp tools=$tools" >> "$CALLS"
# the install's lock at that moment: the installer is this stand-in's parent process
held="$(readlink "$UPD/installing" 2>/dev/null)"; [ "$held" = "$PPID" ] && held=mine
echo "LOCKATBUILD lock=${held:-none} game=$([ -e "$UPD/installing-game" ] && echo there || echo none)" >> "$CALLS"
echo "stub: the window's builder"
[ -n "${STUB_BUILD_SLEEP:-}" ] && /bin/sleep "$STUB_BUILD_SLEEP"
[ "${STUB_BUILD_RC:-0}" = 0 ] || echo "    window: skipped (the compile failed: a stub's error); nothing was changed"
exit "${STUB_BUILD_RC:-0}"
STUB
py() { python3 -I - "$@"; }
move() {   # <from marker> <to marker> <before marker>: the lines from the first marker up to the second, put before the third
  py "$S" "$1" "$2" "$3" << 'PY'
import sys
p, a, b, c = sys.argv[1:5]; s = open(p).read()
assert s.count(a) == 1 and s.count(b) == 1 and s.count(c) == 1
i = s.index(a); j = s.index(b); assert i < j
blk = s[i:j]; s = s[:i] + s[j:]
k = s.index(c); s = s[:k] + blk + s[k:]
open(p, "w").write(s)
PY
}
case "$M" in
  0) ;;
  1) move "# --- 7. the launcher's own stamp" "# --- 8. the close" "# --- 6. the build." ;;
  2) sed -i '' 's|^if ! bash "\$HERE/make-launcher-app.sh"; then$|if ! bash "$HERE/make-launcher-app.sh"; then l1u_stamp_launcher "$HERE/.."|' "$S" ;;
  3) move 'TOOL="$L1_UPDATE_DIR/updates.sh"' "# --- 4. the wait for Apple's tools" "# --- 7. the launcher's own stamp" ;;
  4) sed -i '' 's|^  _tw=0; tools_wait swift_ok \|\| _tw=\$?$|  _tw=0|' "$S" ;;
  5) move "# --- 4. the wait for Apple's tools" "# --- 5. the compiler check" "# --- 7. the launcher's own stamp" ;;
  6) py "$S" << 'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'the guide lists them, at $FRONT"\n  exit 1\n'
assert s.count(a) == 1
s = s.replace(a, 'the guide lists them, at $FRONT"\n  open "$HOME/Applications/14unch3r.app"\n  exit 1\n')
open(p, "w").write(s)
PY
     ;;
  7) sed -i '' 's|^    own_folder "\$d" \|\| { say .*|    :|' "$S" ;;
  8) move "# --- 2. Apple's Command Line Tools" "# --- 3. the record's folders" "# this Mac (LFD12)" ;;
  9) sed -i '' 's|^  if \[ "\$_a" -lt 5 \] \|\| { .*|  if false; then|' "$S" ;;
  10) sed -i '' 's|^  if \[ "\$_a" -lt 5 \] \|\| { .*|  if awk "BEGIN { exit !($_a.$_b < 5.9) }"; then|' "$S" ;;
  11) sed -i '' 's|^  \*) if \[ "\$((10#\$OSMAJ))" -lt 14 \]; then$|  *) if [ "$((10#$OSMAJ))" -le 14 ]; then|' "$S" ;;
  12) sed -i '' 's|^     elif \[ "\$((10#\$OSMAJ))" -lt 26 \]; then$|     elif false; then|' "$S" ;;
  13) sed -i '' 's|^  swift_ok \|\| { say "\$STALE"; exit 1; }$|  swift_ok \|\| { tools_ask; ASKED=1; }|' "$S" ;;
  14) sed -i '' '/^trap .\[ "\$HELD" = 1 \] && l1u_lock_release installing. EXIT$/d' "$S" ;;
  15) sed -i '' '/^\[ "\$HELD" = 1 \] && { l1u_lock_release installing; HELD=0; }$/d' "$S" ;;
  16) sed -i '' 's|^\[ "\${L1_UPDATE:-}" = 1 \] && l1u_lock_live updating && UNDER_UPDATE=1$|[ "${L1_UPDATE:-}" = 1 ] \&\& UNDER_UPDATE=1|' "$S" ;;
  *) echo "REFUSED: no mutant $M"; exit 2 ;;
esac
if [ "$M" != 0 ]; then
  cmp -s "$REPO/common/install-launcher.sh" "$S" && { echo "REFUSED: mutant $M did not apply"; exit 2; }
  bash -n "$S" || { echo "REFUSED: mutant $M does not parse"; exit 2; }
fi

# --- the stubs: one record of calls, in the order they were made
stub() { printf '#!/bin/bash\n%s\n' "$2" > "$T/bin/$1"; chmod +x "$T/bin/$1"; }
absent='[ -n "${STUB_NO_TOOLS:-}" ] && [ ! -f "$ST/tools" ]'
stub sw_vers 'echo "SWVERS" >> "$CALLS"; echo "${STUB_OS-27.2.1}"'
stub sysctl '[ "$*" = "-n hw.optional.arm64" ] && { echo "${STUB_ARM:-1}"; exit 0; }; exec /usr/sbin/sysctl "$@"'
stub open 'echo "OPEN $*" >> "$CALLS"; echo "LOCKATOPEN lock=$(readlink "$UPD/installing" 2>/dev/null || echo none)" >> "$CALLS"'
stub id 'if [ "$1" = -u ] && [ -n "${STUB_ROOT:-}" ]; then echo 0; else exec /usr/bin/id "$@"; fi'
# xcode-select: -p fails while the tools are absent; --install records whether a record folder was there yet
stub xcode-select 'case "$1" in
  -p) if '"$absent"'; then echo "XS -p fail" >> "$CALLS"; exit 2; fi
      echo "XS -p ok" >> "$CALLS"; echo /Library/Developer/CommandLineTools ;;
  --install) echo "XS --install folders=$([ -e "$(dirname "$UPD")" ] && echo there || echo none)" >> "$CALLS"; : > "$ST/tools-pending"; exit "${STUB_XS_INSTALL_EXIT:-0}" ;;
esac'
# sleep: no time passes; the tools arrive at the poll STUB_ARRIVE_AFTER names, unless they never do
stub sleep 'echo "SLEEP" >> "$CALLS"
n=$(( $(cat "$ST/sleeps" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$ST/sleeps"
[ -f "$ST/tools-pending" ] && [ -z "${STUB_TOOLS_NEVER:-}" ] && [ "$n" -ge "${STUB_ARRIVE_AFTER:-1}" ] && { rm -f "$ST/tools-pending"; : > "$ST/tools"; }
exit 0'
# xcrun: called while the tools are absent it would open Apple'"'"'s box itself, so that is recorded as EARLY
stub xcrun 'if '"$absent"'; then echo "XCRUN-EARLY $*" >> "$CALLS"; exit 1; fi
echo "XCRUN $*" >> "$CALLS"
case "$*" in
  "-f swiftc") [ -n "${STUB_SWIFT_BROKEN:-}" ] && exit 1
     n=$(( $(cat "$ST/finds" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$ST/finds"
     [ "$n" -le "${STUB_SWIFT_FAILS:-0}" ] && exit 1
     echo /Library/Developer/CommandLineTools/usr/bin/swiftc ;;
  "--show-sdk-path") [ -n "${STUB_SDK_FAIL:-}" ] && exit 1
     if [ -n "${STUB_SDK_GONE:-}" ]; then echo "$ST/no-such-sdk"; else mkdir -p "$ST/sdk"; echo "$ST/sdk"; fi ;;
  "swiftc --version") echo "${STUB_SWIFT_LINE-Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.0.1.2)}"; echo "Target: arm64-apple-macosx27.0" ;;
esac'

NOW=1800000000; VER=v0.4.2; HEX=0123456789abcdef0123456789abcdef01234567
TAB="$(printf '\t')"
n=0
newh() {   # a fresh home, state and record of calls
  n=$((n + 1)); H="$T/h$n"; ST="$T/st$n"; CALLS="$T/calls$n"; mkdir -p "$H" "$ST"; : > "$CALLS"
  UPD="$(HOME="$H" bash "$REPO/common/paths.sh" | sed -n 's/^L1_UPDATE_DIR=//p')"   # asked of common/paths.sh, never spelled here (common/test-paths.sh, LT14)
  export CALLS ST UPD
}
run() {   # [VAR=value ...] [-- arguments]: the installer's exit code; its output in $H.out
  local e=()
  while [ $# -gt 0 ] && [ "$1" != -- ]; do e+=("$1"); shift; done
  [ $# -gt 0 ] && shift
  ( cd "$T" && env HOME="$H" PATH="$T/bin:$PATH" L1_UPDATE_NOW="$NOW" ${e[@]+"${e[@]}"} /bin/bash "$S" "$@" ) > "$H.out" 2>&1 < /dev/null
  echo $?
}
said() { grep -c -- "$1" "$H.out"; }
calls() { grep -c -- "$1" "$CALLS"; }
has() { if [ -e "$1" ]; then echo yes; else echo no; fi; }
stampof() { cat "$UPD/launcher" 2>/dev/null; }
lsum() { if [ -e "$UPD/launcher" ]; then shasum < "$UPD/launcher" | cut -c1-12; else echo none; fi; }
older() { mkdir -p "$UPD/installed"; printf 'release\tv0.0.9\t%s\t100\n' "$HEX" > "$UPD/launcher"; }
lineno() { grep -n -- "$1" "$CALLS" | tail -n 1 | cut -d: -f1; }   # the last such call's place in the record
snaph() { (cd "$H" && find . | LC_ALL=C sort | shasum | cut -c1-12); }
DONE='^Done\. 14unch3r is in Applications: open it and choose a game\. You can close this window\.$'
STALE="^Apple's Command Line Tools are installed, but their swiftc does not run\. Update them in Software Update, then paste the line again\.\$"
NOBUILD='^14unch3r could not be built on this Mac\. Each game can still be installed by its own line: the guide lists them, at https://github\.com/macgameport/1launcher$'
BOX1='^A box from Apple has opened; it may be behind this window\. Press Install, then Agree\.$'
BOX2='^The download comes from Apple and can take 10 minutes or more\. This window goes on by itself when it is done\.$'
NOBOX="^Apple's box could not be opened from here\. It may be open already; if no box is showing, run xcode-select --install in Terminal at the Mac itself\. This window goes on by itself when the tools are there\.\$"

# --- with the tools
newh; rc="$(run)"
check "with the tools: exit 0, the closing line is the last, with its words about the window" "$rc:$(tail -n 1 "$H.out" | grep -c "$DONE")" "0:1"
check "  ...the three folders are there, none writable by group or others" \
  "$(stat -f %Lp "$(dirname "$UPD")"):$(stat -f %Lp "$UPD"):$(stat -f %Lp "$UPD/installed")" "755:755:755"
check "  ...the deployed updates.sh is byte for byte the tree's, mode 755, and nothing written beside a place is left" \
  "$(cmp -s "$R/common/updates.sh" "$UPD/updates.sh" && echo same):$(stat -f %Lp "$UPD/updates.sh"):$(find "$UPD" -name '*.new.*' -o -name '.put.*' | wc -l | tr -d ' ')" "same:755:0"
check "  ...the builder was called once, with no option, the tool there by then and no stamp yet" "$(calls '^BUILDER'):$(grep '^BUILDER' "$CALLS")" "1:BUILDER args=0 tool=same stamp=none tools=there"
check "  ...it said first that the build prints nothing meanwhile" "$(said '^Building 14unch3r\. This can take a minute; nothing is printed meanwhile\.$')" 1
check "  ...the launcher's stamp holds checkout, the tree's version, no commit and the time" "$(stampof)" "checkout${TAB}$VER${TAB}-${TAB}$NOW"
check "  ...open was called once, with the app's path, after the builder" "$(calls '^OPEN'):$(grep '^OPEN' "$CALLS"):$([ "$(lineno '^OPEN')" -gt "$(lineno '^BUILDER')" ] && echo after)" "1:OPEN $H/Applications/14unch3r.app:after"
check "  ...Apple was not asked, nothing waited, and no caution was said" "$(calls 'XS --install'):$(calls '^SLEEP'):$(said CAUTION)" "0:0:0"
check "  ...the macOS test came before any call of xcode-select" "$([ "$(grep -n '^SWVERS' "$CALLS" | head -n 1 | cut -d: -f1)" -lt "$(grep -n '^XS ' "$CALLS" | head -n 1 | cut -d: -f1)" ] && echo before)" before
newh; rc="$(run L1_FETCHED_REF=release L1_FETCHED_COMMIT=$HEX)"
check "with L1_FETCHED_REF=release and L1_FETCHED_COMMIT: the stamp holds that line and the commit, and the state is unknown" \
  "$rc:$(stampof):$(HOME="$H" bash "$UPD/updates.sh")" "0:release${TAB}$VER${TAB}$HEX${TAB}$NOW:unknown${TAB}$VER${TAB}-${TAB}-"
newh; rc="$(run L1_UPDATE=1)"
check "with L1_UPDATE=1: no open, the line that 14unch3r is rebuilt, no word about the Terminal window, the stamp written" \
  "$rc:$(calls '^OPEN'):$(tail -n 1 "$H.out"):$(said 'close this window'):$(stampof | cut -f2)" "0:0:Done. 14unch3r is rebuilt.:0:$VER"
newh; ( umask 000; mkdir -p "$H" ); rc="$( umask 000; run )"
check "under a umask of 000 the three folders are still made for the player alone to write to, the parent first" \
  "$rc:$(stat -f %Lp "$(dirname "$UPD")"):$(stat -f %Lp "$UPD"):$(stat -f %Lp "$UPD/installed")" "0:755:755:755"
newh; older; rc="$(run L1_FETCHED_REF=release)"
check "an older stamp is replaced by a build that worked, and the builder was called while it still held the older version" \
  "$rc:$(stampof | cut -f1,2,4):$(grep '^BUILDER' "$CALLS")" "0:release${TAB}$VER${TAB}$NOW:BUILDER args=0 tool=same stamp=v0.0.9 tools=there"

# --- without the tools: asked for right after the refusals, before anything is made; then the wait
newh; rc="$(run STUB_NO_TOOLS=1 STUB_ARRIVE_AFTER=3)"
check "tools missing: Apple asked once, before the first folder was made, and the two lines said" \
  "$rc:$(calls 'XS --install'):$(grep 'XS --install' "$CALLS"):$(said "$BOX1"):$(said "$BOX2"):$(said "$NOBOX")" "0:1:XS --install folders=none:1:1:0"
check "  ...they arrive at the third poll: three waits, then the build, the stamp and the window" \
  "$(calls '^SLEEP'):$(grep '^BUILDER' "$CALLS"):$(stampof | cut -f2):$(calls '^OPEN')" "3:BUILDER args=0 tool=same stamp=none tools=there:$VER:1"
check "  ...no tool of Apple's was run before the tools were there" "$(calls '^XCRUN-EARLY')" 0
check "  ...the wait's last poll, then the compiler's version, then the builder" \
  "$([ "$(lineno '^XS -p')" -lt "$(lineno '^XCRUN swiftc --version')" ] && [ "$(lineno '^XCRUN swiftc --version')" -lt "$(lineno '^BUILDER')" ] && echo ordered)" ordered
newh; rc="$(run STUB_NO_TOOLS=1 STUB_XS_INSTALL_EXIT=1)"
check "the request answering 1: the other words are said and not the first, the wait still runs, and the build follows" \
  "$rc:$(said "$NOBOX"):$(said "$BOX1"):$(calls '^SLEEP'):$(calls '^BUILDER')" "0:1:0:1:1"
newh; sed -i '' 's/^TOOLS_POLLS=720 /TOOLS_POLLS=3 /' "$S"; rc="$(run STUB_NO_TOOLS=1 STUB_TOOLS_NEVER=1)"
check "they never arrive: exit 4 with its two sentences, the builder not called, no stamp, nothing opened" \
  "$rc:$(said "^Apple's Command Line Tools are not installed yet\.\$"):$(tail -n 1 "$H.out"):$(calls '^BUILDER'):$(has "$UPD/launcher"):$(calls '^OPEN')" "4:1:Paste the line again: it carries on from here.:0:no:0"
check "  ...after three polls, with the update tool deployed meanwhile" "$(calls '^SLEEP'):$(has "$UPD/updates.sh")" "3:yes"
sed -i '' 's/^TOOLS_POLLS=3 /TOOLS_POLLS=720 /' "$S"
newh; rc="$(run STUB_NO_TOOLS=1 STUB_SWIFT_FAILS=2)"
check "they arrive with swiftc not running at two polls and running at the third: the build" "$rc:$(calls '^BUILDER'):$(calls '^SLEEP'):$(said "$STALE")" "0:1:3:0"
newh; sed -i '' 's/^TOOLS_PART_POLLS=24 /TOOLS_PART_POLLS=3 /' "$S"; rc="$(run STUB_NO_TOOLS=1 STUB_SWIFT_BROKEN=1)"
check "they arrive with swiftc never running: after the settle exit 1 with the Software Update sentence, the builder not called" \
  "$rc:$(said "$STALE"):$(calls '^BUILDER'):$(calls '^SLEEP'):$(has "$UPD/launcher")" "1:1:0:4:no"
sed -i '' 's/^TOOLS_PART_POLLS=3 /TOOLS_PART_POLLS=24 /' "$S"
check "the settle is two minutes: 24 polls of 5 seconds stand in the installer" "$(grep -c '^POLL=5 ' "$S"):$(grep -c '^TOOLS_PART_POLLS=24 ' "$S"):$(grep -c '^TOOLS_POLLS=720 ' "$S")" "1:1:1"

# --- the tools' folder there at the start with a swiftc that does not run: at once, and Apple is not asked
stale() {   # <name> <VAR=value>
  newh; rc="$(run "$2")"
  check "tools there at the start, $1: exit 1 at once with the Software Update sentence, Apple not asked, no poll slept, the builder not called, nothing made" \
    "$rc:$(said "$STALE"):$(calls 'XS --install'):$(calls '^SLEEP'):$(calls '^BUILDER'):$(has "$H/Library")" "1:1:0:0:0:no"
}
stale "swiftc not found" STUB_SWIFT_BROKEN=1
stale "xcrun --show-sdk-path failing" STUB_SDK_FAIL=1
stale "the SDK's path naming no folder" STUB_SDK_GONE=1

# --- the compiler: below Swift 5.9 it stops; the two numbers are compared as numbers, in both forms of the line
swift() {   # <version> <want: stops|goes>
  local form line
  for form in plain driver; do
    line="Apple Swift version $1 (swiftlang-$1.0.1 clang-1500.0.1)"
    [ "$form" = driver ] && line="swift-driver version: 1.87.3 $line"
    newh; rc="$(run "STUB_SWIFT_LINE=$line")"
    if [ "$2" = stops ]; then
      check "Swift $1 ($form form): exit 3 with its sentence, the builder not called" \
        "$rc:$(said "^Apple's Command Line Tools on this Mac are older than 14unch3r needs (Swift $1, and it needs 5\.9)\. Update them in Software Update, then paste the line again\.\$"):$(calls '^BUILDER')" "3:1:0"
    else
      check "Swift $1 ($form form): goes on to the build" "$rc:$(calls '^BUILDER'):$(said 'older than 14unch3r needs')" "0:1:0"
    fi
  done
}
swift 5.8 stops; swift 4.2 stops; swift 5.9 goes; swift 5.10 goes; swift 6.4 goes
newh; rc="$(run "STUB_SWIFT_LINE=some words and no version")"
check "a version that cannot be read does not stop it: the build decides" "$rc:$(calls '^BUILDER')" "0:1"

# --- this Mac
newh; rc="$(run STUB_OS=13.6)"
check "macOS 13.6: exit 3, its sentence with the version in it, xcode-select never called, nothing made" \
  "$rc:$(said '^This Mac has macOS 13\.6\. 14unch3r needs macOS 14 or later, and so does every game it lists\. Update macOS, then paste the line again\.$'):$(calls '^XS '):$(has "$H/Library"):$(calls '^BUILDER')" "3:1:0:no:0"
OLDOS='is older than anything this project has been run on (macOS 26 and 27)\. 14unch3r may work; each game checks this Mac for itself when it is installed\.$'
for v in 14.0 25.9; do
  newh; rc="$(run STUB_OS=$v)"
  check "macOS $v: the caution for an older macOS, and exit 0" "$rc:$(said "^CAUTION: macOS $v $OLDOS"):$(said CAUTION):$(calls '^BUILDER')" "0:1:1:1"
done
newh; rc="$(run STUB_OS=26.0)"
check "macOS 26.0: no caution" "$rc:$(said CAUTION)" "0:0"
newh; rc="$(run STUB_OS=)"
check "a macOS version that cannot be read: its caution, and exit 0" \
  "$rc:$(said '^CAUTION: the macOS version could not be read, so this Mac cannot be compared with what has been tested\.$'):$(said CAUTION):$(calls '^BUILDER')" "0:1:1:1"
newh; rc="$(run STUB_ARM=0)"
check "an Intel processor: its caution, and exit 0" \
  "$rc:$(said '^CAUTION: this Mac has an Intel processor\. Nothing of this project has been run on one\. 14unch3r may work; each game checks this Mac for itself when it is installed\.$'):$(said CAUTION):$(calls '^BUILDER')" "0:1:1:1"

# --- the build failing: exit 1, no stamp, an older stamp as it was, nothing opened
for brc in 3 1; do
  newh; rc="$(run STUB_BUILD_RC=$brc)"
  check "the builder exits $brc: exit 1, the sentence that names each game's own line and the guide's address last, its own line above, no stamp, open not called" \
    "$rc:$(tail -n 1 "$H.out" | grep -c "$NOBUILD"):$(said 'window: skipped (the compile failed'):$(has "$UPD/launcher"):$(calls '^OPEN')" "1:1:1:no:0"
  newh; older; old="$(lsum)"; rc="$(run STUB_BUILD_RC=$brc L1_FETCHED_REF=release)"
  check "  ...with an older stamp there: that stamp byte for byte" "$rc:$([ "$(lsum)" = "$old" ] && echo same):$(calls '^OPEN')" "1:same:0"
done

# --- TERM while the builder runs: the trap runs when the builder has returned, and nothing after it is done
term() {   # the installer in the background with a builder that takes a second; TERM once the builder is running
  ( cd "$T" && exec env HOME="$H" PATH="$T/bin:$PATH" L1_UPDATE_NOW="$NOW" STUB_BUILD_SLEEP=1 /bin/bash "$S" ) > "$H.out" 2>&1 < /dev/null & BG=$!
  local i=0
  until grep -q '^BUILDER' "$CALLS" 2>/dev/null; do i=$((i + 1)); [ "$i" -gt 100 ] && break; /bin/sleep 0.1; done
  kill -TERM "$BG" 2>/dev/null; wait "$BG" 2>/dev/null; echo $?; BG=""
}
newh; rc="$(term)"
check "TERM while the builder runs: exit 143, the Stopped line, no stamp, nothing opened" \
  "$rc:$(said '^Stopped\. Paste the line again: it carries on from here\.$'):$(has "$UPD/launcher"):$(calls '^OPEN'):$(said '^Done')" "143:1:no:0:0"
newh; older; old="$(lsum)"; rc="$(term)"
check "  ...with an older stamp there: that stamp byte for byte" "$rc:$([ "$(lsum)" = "$old" ] && echo same):$(calls '^OPEN')" "143:same:0"

# --- refused before anything is asked or made
newh; rc="$(run STUB_ROOT=1)"
check "as root: exit 1 with the installer's sentence, nothing asked, nothing made" "$rc:$(said '^Do not run the installer as root (with sudo)'):$(calls '^XS '):$(has "$H/Library")" "1:1:0:no"
for which in parent _update installed; do
  newh; mkdir -p "$UPD/installed"
  case "$which" in parent) bad="$(dirname "$UPD")" ;; _update) bad="$UPD" ;; installed) bad="$UPD/installed" ;; esac
  chmod o+w "$bad"; before="$(snaph)"; rc="$(run)"
  check "the record's folder others can write ($which): exit 1 with the chmod sentence, the folder in full and in quotes in the command, xcode-select never called, nothing written" \
    "$rc:$(grep -cxF "$bad is not a folder of your own that only you can write to. In Terminal: chmod go-w \"$bad\", then try again." "$H.out"):$(calls '^XS '):$(snaph)" "1:1:0:$before"
done
newh; mkdir -p "$(dirname "$UPD")"; ln -s "$T" "$UPD"; rc="$(run)"
check "the record's folder a link: the same sentence, and nothing made through it" "$rc:$(said 'is not a folder of your own that only you can write to'):$(calls '^XS '):$(has "$T/installed")" "1:1:0:no"
for gone in paths.sh updates.sh tools.sh make-launcher-app.sh launcher-window.swift games.tsv; do
  newh; mv "$R/common/$gone" "$T/$gone.aside"; rc="$(run)"
  check "common/$gone missing from the tree: exit 4 in the own-files words, nothing asked, nothing made" \
    "$rc:$(said "^The installer's own files are gone (macOS clears old temporary files)\.\$"):$(grep -cE 'command not found|No such file' "$H.out"):$(calls '^XS '):$(has "$H/Library")" "4:1:0:0:no"
  mv "$T/$gone.aside" "$R/common/$gone"
done
for a in --check --yes release; do
  newh; rc="$(run -- "$a")"
  check "the argument $a: exit 2, said, nothing asked, nothing made" "$rc:$(said "^install-launcher.sh takes no argument: $a "):$(calls '^XS '):$(has "$H/Library")" "2:1:0:no"
done

# --- the install's lock (docs/plans/launcher-first-install.md, 3.4 and 3.8; LFT2's cases "with LF4a"): held from
# the moment the record's folders are there until just before the window is opened, and gone after every exit
/bin/sleep 300 & LIVE=$!
( exit 0 ) & DEAD=$!; wait "$DEAD"
lock() { if [ -e "$UPD/installing" ] || [ -L "$UPD/installing" ]; then echo left; else echo none; fi; }
newh; rc="$(run)"
check "the lock: held when the builder is called, its target this installer's process, and no file names a game" "$rc:$(grep '^LOCKATBUILD' "$CALLS")" "0:LOCKATBUILD lock=mine game=none"
check "  ...gone when the window is opened, and gone afterwards" "$(grep '^LOCKATOPEN' "$CALLS"):$(lock)" "LOCKATOPEN lock=none:none"
newh; mkdir -p "$UPD/installed"; ln -s "$DEAD" "$UPD/installing"; echo 949230 > "$UPD/installing-game"; rc="$(run)"
check "a dead holder's lock and its installing-game: taken over, the file gone by the build and none written" \
  "$rc:$(grep '^LOCKATBUILD' "$CALLS"):$(has "$UPD/installing-game"):$(lock)" "0:LOCKATBUILD lock=mine game=none:no:none"
for other in installing updating; do
  newh; mkdir -p "$UPD/installed"; ln -s "$LIVE" "$UPD/$other"; rc="$(run)"
  case "$other" in installing) words="An install is running" ;; updating) words="An update of 1launcher is running" ;; esac
  check "a live $other of another process: exit 3, the process in its sentence, xcode-select never called, the builder not called, the lock left as it was" \
    "$rc:$(said "^$words in another Terminal window (process $LIVE)\. Wait for it to finish, then paste the line again\.\$"):$(calls '^XS '):$(calls '^BUILDER '):$(readlink "$UPD/$other")" "3:1:0:0:$LIVE"
done
newh; mkdir -p "$UPD/installed"; ln -s "$LIVE" "$UPD/updating"; rc="$(run L1_UPDATE=1)"
check "in an update (L1_UPDATE=1 and a live updating): no lock is taken, and that updating does not stop it" \
  "$rc:$(grep '^LOCKATBUILD' "$CALLS"):$(tail -n 1 "$H.out"):$(readlink "$UPD/updating"):$(lock)" "0:LOCKATBUILD lock=none game=none:Done. 14unch3r is rebuilt.:$LIVE:none"
newh; rc="$(run L1_UPDATE=1)"
check "with L1_UPDATE=1 and no live updating the lock is taken as in any run" "$rc:$(grep '^LOCKATBUILD' "$CALLS"):$(lock)" "0:LOCKATBUILD lock=mine game=none:none"
newh; mkdir -p "$UPD/installed"; ln -s "$LIVE" "$UPD/installing"; rc="$(run L1_UPDATE=1)"
check "  ...and a live installing of another process stops it then too" "$rc:$(calls '^BUILDER ')" "3:0"
newh; rc="$(run STUB_BUILD_RC=3)"
check "the lock is gone after a build that failed (exit 1)" "$rc:$(grep '^LOCKATBUILD' "$CALLS" | cut -d' ' -f2):$(lock)" "1:lock=mine:none"
newh; rc="$(run "STUB_SWIFT_LINE=Apple Swift version 5.8 (swiftlang-5.8.0.1)")"
check "  ...after the compiler check stopped it (exit 3)" "$rc:$(lock)" "3:none"
newh; sed -i '' 's/^TOOLS_POLLS=720 /TOOLS_POLLS=3 /' "$S"; rc="$(run STUB_NO_TOOLS=1 STUB_TOOLS_NEVER=1)"
check "  ...after the tools never arrived (exit 4), the lock having been held through the wait" "$rc:$(lock):$(has "$UPD/updates.sh")" "4:none:yes"
sed -i '' 's/^TOOLS_POLLS=3 /TOOLS_POLLS=720 /' "$S"
newh; rc="$(term)"
check "  ...and after TERM while the builder ran" "$rc:$(grep '^LOCKATBUILD' "$CALLS" | cut -d' ' -f2):$(lock)" "143:lock=mine:none"

echo "$fails failure(s)"
[ "$fails" = 0 ]
