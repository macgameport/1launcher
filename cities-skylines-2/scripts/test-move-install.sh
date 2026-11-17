#!/bin/bash
# test-move-install.sh -- scripts/move-install.sh with HOME at scratch folders (docs/plans/local-files-layout.md,
# LT16 and LT26). No game, no Wine, no setup. The two lsof probes and the volume read are a stub (L1_MOVE_PROBE)
# except in one case.
#   bash scripts/test-move-install.sh            exit 0 = every case passed
#   MUTANT=1 ...  the game-folder reason removed; must exit 1
#   MUTANT=2 ...  a machine-wide `pgrep -x wineserver` stop put back; must exit 1
#   MUTANT=3 ...  a target tested with -e only; must exit 1
#   MUTANT=4 ...  the closing chmod -R dropped; must exit 1
#   MUTANT=5 ...  a name the runtime folder already holds is lifted over it; must exit 1
#   MUTANT=6 ...  the volume comparison dropped; must exit 1
#   MUTANT=7 ...  with no --lock, the first wrapper on the list is read whether or not it is there; must exit 1
#   MUTANT=8 ...  one path printed raw; must exit 1
#   MUTANT=9 ...  a symlinked root is not looked at; must exit 1
#   MUTANT=10 ... a root the script makes keeps the umask's mode; must exit 1
#   MUTANT=11 ... the closing chmod on the runtime folder and patches/ only, not on the files; must exit 1
#   MUTANT=12 ... the folders' own-folder test dropped on a finishing run; must exit 1
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d /tmp/move-test.XXXX)"; T="$(cd "$T" && pwd -P)"
trap 'kill $(cat "$T"/*.pid 2>/dev/null) 2>/dev/null; chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT
mkdir -p "$T/repo/cities-skylines-2/scripts" "$T/repo/common" "$T/bin"
cp "$REPO/scripts/move-install.sh" "$T/repo/cities-skylines-2/scripts/"; cp "$REPO/../common/paths.sh" "$T/repo/common/"
M="$T/repo/cities-skylines-2/scripts/move-install.sh"
mutate() { perl -0pi -e "$1" "$M"; grep -q -- "$2" "$M" || { echo "REFUSED: mutant did not apply"; exit 2; }; }
case "${MUTANT:-0}" in
  1) mutate 's/reason skip "\$\(tilde "\$d"\) is already there"/: gone/' ': gone' ;;
  2) mutate 's/\nlock_reason\nif \[ ! -L "\$OLD" \]; then\n/\nlock_reason\n[ -n "\$(pgrep -x wineserver)" ] && reason stop "Wine is running"\nif [ ! -L "\$OLD" ]; then\n/' 'pgrep -x wineserver' ;;
  3) mutate 's/  if \[ -e "\$d" \] \|\| \[ -L "\$d" \]; then reason skip "\$\(tilde "\$d"\) is already there"/  if [ -e "\$d" ]; then reason skip "\$(tilde "\$d") is already there"/' 'if \[ -e "\$d" \]; then reason skip' ;;
  4) mutate 's/\nclose_modes\(\) \{[^\n]*\n/\nclose_modes() { return 0; }\n/' 'close_modes() { return 0; }' ;;
  5) mutate 's/\n    if \[ -e "\$2\/\$n" \] \|\| \[ -L "\$2\/\$n" \]; then echo "  left in the workspace: \$n"; continue; fi\n/\n    : lifted over it\n/; s/    elif mv_q "\$1\/\$n" "\$2\/\$n"; then/    elif mv -f "\$1\/\$n" "\$2\/\$n"; then/' 'elif mv -f ' ;;
  6) mutate 's/    \[ "\$\(probe_dev "\$\(parent "\$t"\)"\)" = "\$dv" \] \|\| reason skip/    true || reason skip/' 'true || reason skip' ;;
  7) mutate 's/    else for x in \$WRAPPERS; do \[ -d [^\n]*\n/    else w="\$HOME\/Applications\/\${WRAPPERS%% *}"; fi\n/' 'WRAPPERS%% ' ;;
  8) mutate 's/  echo "  would move: \$\(tilde "\$OLD"\) -> \$\(tilde "\$WORK"\)"/  echo "  would move: \$OLD -> \$(tilde "\$WORK")"/' 'would move: \$OLD -> ' ;;
  9) mutate 's/  if \[ -L "\$d" \]; then reason skip "\$\(tilde "\$d"\) is a symlink"\n  elif \[ -e "\$d" \]; then own_folder/  if [ -e "\$d" ] \&\& [ ! -L "\$d" ]; then own_folder/' 'if \[ -e "\$d" \] && \[ ! -L "\$d" \]; then own_folder' ;;
  10) mutate 's/\nmake_root\(\) \{[^\n]*\n/\nmake_root() { [ -d "\$1" ] || mkdir -p "\$1"; }\n/' 'make_root() { \[ -d "\$1" \] || mkdir -p "\$1"; }' ;;
  11) mutate 's/\nclose_modes\(\) \{[^\n]*\n/\nclose_modes() { chmod go-w "\$DATA" 2>\/dev\/null; [ -d "\$DATA\/patches" ] \&\& chmod go-w "\$DATA\/patches"; return 0; }\n/' 'close_modes() { chmod go-w "\$DATA" 2' ;;
  12) mutate 's/    if \[ -e "\$d" \] \|\| \[ -L "\$d" \]; then own_folder "\$d" \|\| reason skip [^\n]*\n/    :\n/' '^    :$' ;;
esac
# the probe: `open` answers $STUB_OPEN when a file named $STUB_OPEN_FILE is among those it is given; `cwd` answers
# $STUB_CWD; `dev` answers 1, or $STUB_DEV for any folder that is not the old one. Each call is recorded.
cat > "$T/bin/probe" <<'P'
#!/bin/bash
[ -n "${PROBE_CALLS:-}" ] && echo "$1" >> "$PROBE_CALLS"
case "$1" in
  open) shift; for f in "$@"; do [ "$(basename "$f")" = "${STUB_OPEN_FILE:-}" ] && echo "${STUB_OPEN:-777}"; done ;;
  cwd) [ -n "${STUB_CWD:-}" ] && echo "$STUB_CWD" ;;
  dev) case "$2" in */cs2-patch) echo 1 ;; *) echo "${STUB_DEV:-1}" ;; esac ;;
esac
exit 0
P
chmod +x "$T/bin/probe"
eval "$(env -u L1_DATA_ROOT -u L1_WORK_ROOT -u CS2_PATCH_DIR -u CS2_WORK_DIR HOME=/H bash "$T/repo/common/paths.sh" | sed -n 's/^\(L1_[A-Z_]*\)=\/H\/\(.*\)/\1="\2"/p')"
DR="$L1_DATA_ROOT"; WR="$L1_WORK_ROOT"; G=cities-skylines-2          # the roots, relative to a home
fails=0
check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi; }
has() { if [ -e "$1" ] || [ -L "$1" ]; then echo yes; else echo no; fi; }
snap() { (cd "$1" && find . | sort | shasum | cut -c1-12); }
mode() { stat -f %Lp "$1"; }
loose() { find "$1" -perm +022 | wc -l | tr -d ' '; }   # how many names in it group or others can write to
roots() { mkdir -p "$1/$DR/surviving-mars-relaunched" "$1/$WR/surviving-mars-relaunched"; chmod go-w "$1/$DR" "$1/$WR"; }
runtime() {   # <home>: an old folder with only runtime names, the three old kinds among them, and a .DS_Store
  mkdir -p "$1/cs2-patch/patches/_vendor" "$1/cs2-patch/revenv"
  for f in launch-cs2-dxmt11.sh repatch.sh cs2-display-profile.sh launch-cs2.sh launch-cs2-dxmt11.sh.bak patches/patch_a.py patches/.mod-badges-on .DS_Store; do echo "$f" > "$1/cs2-patch/$f"; done
}
full() {      # <home>: the same, and a workspace's things: a nested git repo, a dotfile, a name with a space
  runtime "$1"; mkdir -p "$1/cs2-patch/evidence/cell" "$1/cs2-patch/a name"; echo x > "$1/cs2-patch/.dot"; echo l > "$1/cs2-patch/change-ledger.txt"
  git init -q "$1/cs2-patch/tree" 2>/dev/null; echo s > "$1/cs2-patch/tree/f"
  git -C "$1/cs2-patch/tree" add -A; git -C "$1/cs2-patch/tree" -c user.name=t -c user.email=t@t commit -q -m one; echo dirty >> "$1/cs2-patch/tree/f"
}
finger() { (cd "$1" && { git for-each-ref; git status --porcelain; git config --local --list; wc -l < .git/logs/HEAD; }) | shasum | cut -c1-12; }
: > "$T/raw.hits"; : > "$T/bad.first"
mv_() {       # <home> [arguments]: output in <home>.out; echoes the exit code. Every run's output is held to two rules
  local h="$1" rc; shift
  env -u L1_DATA_ROOT -u L1_WORK_ROOT -u CS2_PATCH_DIR -u CS2_WORK_DIR -u CS2_WRAPPER ${EXTRA:-} HOME="$h" L1_MOVE_PROBE="${PROBE-$T/bin/probe}" \
    bash "${MOVER:-$M}" "$@" > "$h.out" 2>&1 < /dev/null; rc=$?
  grep -F -- "$h" "$h.out" >> "$T/raw.hits"                                             # no line holds the scratch home
  sed -n 1p "$h.out" | grep -qx 'state: \(none\|old\|part-way\)' || echo "$h" >> "$T/bad.first"   # line 1 is the state
  echo $rc
}
said() { grep -c -- "$2" "$1.out"; }
st() { sed -n 1p "$1.out"; }
RT="launch-cs2-dxmt11.sh launch-cs2-dxmt11.sh.bak launch-cs2.sh repatch.sh cs2-display-profile.sh patches revenv"

# --- a full folder
H="$T/h1"; mkdir -p "$H"; roots "$H"; full "$H"; f0="$(finger "$H/cs2-patch/tree")"
ln -s /bin/sleep "$T/bin/wineserver"; "$T/bin/wineserver" 20 & echo $! > "$T/w.pid"       # another game's Wine: not looked at
check "a full folder, with another game's Wine running: exit 0, state: old" "$(mv_ "$H"):$(st "$H")" "0:state: old"
check "  ...(the stub Wine was running)" "$(pgrep -x wineserver | grep -c "^$(cat "$T/w.pid")$")" 1
kill "$(cat "$T/w.pid")" 2>/dev/null; rm -f "$T/w.pid"
check "  ...no old folder; the runtime names are in the runtime folder" "$(has "$H/cs2-patch"):$(for n in $RT; do has "$H/$DR/$G/$n"; done | tr '\n' ' ')" "no:yes yes yes yes yes yes yes "
check "  ...everything else is in the workspace, names unchanged, and no runtime name is" "$(ls -A "$H/$WR/$G" | tr '\n' ' ')" ".DS_Store .dot a name change-ledger.txt evidence tree "
check "  ...the nested repo's fingerprints are equal, and the marker moved with patches/" "$(finger "$H/$WR/$G/tree"):$(has "$H/$DR/$G/patches/.mod-badges-on")" "$f0:yes"
check "  ...the other game's folders are untouched, and the last line says to run setup" "$(has "$H/$DR/surviving-mars-relaunched"):$(has "$H/$WR/surviving-mars-relaunched"):$(tail -1 "$H.out")" "yes:yes:Now run:  bash scripts/setup.sh"
check "  ...every line after the first is a move, but the last" "$(sed '1d;$d' "$H.out" | grep -vc '^  moved: ~/.* -> ~/')" 0

# --- only runtime names
H="$T/h2"; mkdir -p "$H"; roots "$H"; runtime "$H"
check "only runtime names: exit 0, one rename, no workspace made" "$(mv_ "$H"):$(st "$H"):$(grep -c '^  moved: ' "$H.out"):$(has "$H/cs2-patch"):$(has "$H/$WR/$G"):$(has "$H/$DR/$G/revenv"):$(has "$H/$DR/$G/patches/.mod-badges-on")" "0:state: old:1:no:no:yes:yes"

# --- each skip: exit 1 and nothing moved
skipcase() {  # <name> <said> <prepare...>: a full old folder, prepared, then run
  local name="$1" want="$2"; shift 2; n=$((${n:-0} + 1)); H="$T/s$n"; mkdir -p "$H"; roots "$H"; full "$H"
  "$@"; before="$(snap "$H")"
  check "$name: exit 1, its reason, nothing moved" "$(mv_ "$H"):$(st "$H"):$(said "$H" "$want"):$(tail -1 "$H.out"):x$(snap "$H")" "1:state: old:1:Nothing was moved.:x$before"
}
p_data() { mkdir -p "$H/$DR/$G"; }; p_work() { mkdir -p "$H/$WR/$G"; }
skipcase "the runtime folder already there" "^  skip: ~/$DR/$G is already there" p_data
skipcase "the workspace already there" "^  skip: ~/$WR/$G is already there" p_work
EXTRA="STUB_CWD=4242" skipcase "a working directory inside" '^  skip: a process has its working directory inside ~/cs2-patch (process 4242)' true
EXTRA="L1_DATA_ROOT=$T/elsewhere" skipcase "a root set elsewhere" '^  skip: a root is set away from its default' true
EXTRA="STUB_DEV=2" skipcase "the targets on another volume (the probe answers dev with two numbers)" "^  skip: ~/$DR/$G would be on another volume than ~/cs2-patch" true
p_nowrite() { chmod 555 "$H/$WR"; }
skipcase "a first rename that fails (the work root cannot be written to)" '^  skip: ~/cs2-patch could not be renamed' p_nowrite
chmod 755 "$H/$WR"
H="$T/co1"; mkdir -p "$H"; roots "$H"; full "$H"; mkdir -p "$H/cs2-patch/co/cities-skylines-2/scripts" "$H/cs2-patch/co/common"
cp "$M" "$H/cs2-patch/co/cities-skylines-2/scripts/"; cp "$T/repo/common/paths.sh" "$H/cs2-patch/co/common/"; before="$(snap "$H")"
check "the checkout inside the old folder: exit 1, nothing moved" "$(MOVER="$H/cs2-patch/co/cities-skylines-2/scripts/move-install.sh" mv_ "$H"):$(said "$H" '^  skip: this checkout is inside ~/cs2-patch$'):x$(snap "$H")" "1:1:x$before"

# --- each stop: exit 3 and nothing moved
H="$T/t1"; mkdir -p "$H"; roots "$H"; full "$H"; before="$(snap "$H")"
check "the launcher open in a process: exit 3, its process named, nothing moved" "$(EXTRA="STUB_OPEN_FILE=launch-cs2-dxmt11.sh" mv_ "$H"):$(st "$H"):$(said "$H" '^  stop: a script is running from ~/cs2-patch (process 777)'):x$(snap "$H")" "3:state: old:1:x$before"
check "repatch.sh open in a process: the same" "$(EXTRA="STUB_OPEN_FILE=repatch.sh STUB_OPEN=778" mv_ "$H"):$(said "$H" '^  stop: a script is running from ~/cs2-patch (process 778)'):x$(snap "$H")" "3:1:x$before"
check "  ...--dry-run of a stop: exit 3" "$(EXTRA="STUB_OPEN_FILE=repatch.sh" mv_ "$H" --dry-run):x$(snap "$H")" "3:x$before"
sleep 60 & echo $! > "$T/l.pid"; L="$T/lock"; ln -s "$(cat "$T/l.pid")" "$L"
check "a live lock at --lock: exit 3, nothing moved" "$(mv_ "$H" --lock "$L"):$(said "$H" "^  stop: a launch or an install is using the game's wrapper (process $(cat "$T/l.pid"))"):x$(snap "$H")" "3:1:x$before"
check "  ...read from \$CS2_WRAPPER when no --lock is given" "$(mkdir -p "$T/W.app/Contents/SharedSupport/prefix"; ln -s "$(cat "$T/l.pid")" "$T/W.app/Contents/SharedSupport/prefix/.launcher.lock"; EXTRA="CS2_WRAPPER=$T/W.app" mv_ "$H")" 3
H="$T/t3"; mkdir -p "$H/Applications/CS2.app/Contents/SharedSupport/prefix"; roots "$H"; full "$H"
ln -s "$(cat "$T/l.pid")" "$H/Applications/CS2.app/Contents/SharedSupport/prefix/.launcher.lock"; before="$(snap "$H")"
check "no --lock, only CS2.app present and a live lock in it: exit 3, nothing moved" "$(mv_ "$H"):$(said "$H" "^  stop: a launch or an install is using the game's wrapper"):x$(snap "$H")" "3:1:x$before"
check "  ...\$CS2_WRAPPER set to a folder with no prefix: no lock is read, and it moves" "$(EXTRA="CS2_WRAPPER=$T/nowhere.app" mv_ "$H"):$(has "$H/cs2-patch")" "0:no"
H="$T/t1"
check "the same lock with --held-by naming its holder: moved" "$(mv_ "$H" --lock "$L" --held-by "$(cat "$T/l.pid")"):$(has "$H/cs2-patch"):$(has "$H/$DR/$G/repatch.sh")" "0:no:yes"
kill "$(cat "$T/l.pid")"; wait "$(cat "$T/l.pid")" 2>/dev/null; rm -f "$T/l.pid"
H="$T/t2"; mkdir -p "$H"; roots "$H"; full "$H"
check "a dead lock: moved" "$(mv_ "$H" --lock "$L"):$(has "$H/cs2-patch")" "0:no"

# --- no *.sh at the top of the old folder: the open probe is not called
H="$T/ns"; mkdir -p "$H/cs2-patch/patches" "$H/cs2-patch/evidence"; roots "$H"; : > "$T/probe.calls"
check "no script at the top of the old folder: moved, and no open call to the probe" "$(EXTRA="PROBE_CALLS=$T/probe.calls" mv_ "$H"):$(grep -c '^open$' "$T/probe.calls"):$(grep -c '^cwd$' "$T/probe.calls"):$(has "$H/$DR/$G/patches")" "0:0:1:yes"

# --- stopped part-way, then finished
H="$T/p1"; mkdir -p "$H"; roots "$H"; full "$H"
check "stopped after the first rename: exit 2, the command that finishes it" "$(EXTRA="L1_MOVE_STOP_AFTER=rename" mv_ "$H"):$(said "$H" '^Stopped part-way. To finish the move, run:  bash scripts/move-install.sh$'):$(has "$H/cs2-patch"):$(has "$H/$DR/$G"):$(has "$H/$WR/$G/repatch.sh")" "2:1:no:no:yes"
check "  ...--dry-run then says part-way and what it would lift, and moves nothing" "$(mv_ "$H" --dry-run):$(st "$H"):$(grep -c '^  would move: ' "$H.out"):$(has "$H/$DR/$G")" "0:state: part-way:7:no"
check "  ...a second run finishes it" "$(mv_ "$H"):$(st "$H"):$(for n in $RT; do has "$H/$DR/$G/$n"; done | tr '\n' ' '):$(has "$H/$WR/$G/repatch.sh"):$(tail -1 "$H.out")" "0:state: part-way:yes yes yes yes yes yes yes :no:Now run:  bash scripts/setup.sh"
check "  ...and a third run has nothing to move: state: none and no other line" "$(mv_ "$H"):$(cat "$H.out")" "0:state: none"
H="$T/p2"; mkdir -p "$H"; roots "$H"; full "$H"
check "stopped after the first rename, and the runtime folder then holds a repatch.sh of other bytes" "$(EXTRA="L1_MOVE_STOP_AFTER=rename" mv_ "$H"; mkdir -p "$H/$DR/$G"; chmod go-w "$H/$DR/$G"; echo newer > "$H/$DR/$G/repatch.sh")" 2
check "  ...the second run lifts the rest; the workspace's repatch.sh stays and is named, the runtime folder's bytes are unchanged" "$(mv_ "$H"):$(for n in launch-cs2-dxmt11.sh patches revenv; do has "$H/$DR/$G/$n"; done | tr '\n' ' '):$(cat "$H/$DR/$G/repatch.sh"):$(cat "$H/$WR/$G/repatch.sh"):$(said "$H" '^  left in the workspace: repatch.sh$')" "0:yes yes yes :newer:repatch.sh:1"
before="$(snap "$H")"
check "  ...a name both folders hold does not make the state part-way: state: none, nothing moved, no other line" "$(mv_ "$H"):$(cat "$H.out"):x$(snap "$H")" "0:state: none:x$before"
H="$T/p3"; mkdir -p "$H"; roots "$H"; full "$H"; EXTRA="L1_MOVE_STOP_AFTER=rename" mv_ "$H" > /dev/null; chmod g+w "$H/$DR"; before="$(snap "$H")"
check "part-way with a data root writable by group: exit 1, its reason, no name lifted" "$(mv_ "$H"):$(st "$H"):$(said "$H" "^  skip: ~/$DR is not a folder of your own that only you can write to"):x$(snap "$H")" "1:state: part-way:1:x$before"

# --- dry runs
H="$T/d1"; mkdir -p "$H"; roots "$H"; full "$H"; before="$(snap "$H")"
check "--dry-run of a move: exit 0, the moves, nothing moved" "$(mv_ "$H" --dry-run):$(st "$H"):$(grep -c '^  would move: ' "$H.out"):$(said "$H" "^  would move: ~/cs2-patch -> ~/$WR/$G\$"):x$(snap "$H")" "0:state: old:8:1:x$before"
check "--dry-run of a skip: exit 1, nothing moved" "$(EXTRA="STUB_CWD=1" mv_ "$H" --dry-run):x$(snap "$H")" "1:x$before"

# --- no old folder at all: no probe is called
H="$T/n1"; mkdir -p "$H"; roots "$H"; mkdir -p "$H/$DR/$G" "$H/$WR/$G/evidence"; : > "$T/probe.calls"
check "no old folder: exit 0, state: none and no other line, and no probe called" "$(EXTRA="PROBE_CALLS=$T/probe.calls" mv_ "$H"):$(cat "$H.out"):$(wc -l < "$T/probe.calls" | tr -d ' ')" "0:state: none:0"

# --- once with the real probes
H="$T/r1"; mkdir -p "$H"; roots "$H"; full "$H"; ( cd "$H/cs2-patch" && exec sleep 60 ) & echo $! > "$T/i.pid"; sleep 0.5; before="$(snap "$H")"
check "the real probes find an idle process in the folder: exit 1, nothing moved" "$(PROBE= mv_ "$H"):$(said "$H" "working directory inside ~/cs2-patch (process $(cat "$T/i.pid"))"):x$(snap "$H")" "1:1:x$before"
( exec sleep 60 < "$H/cs2-patch/repatch.sh" ) & echo $! > "$T/o.pid"; sleep 0.5
check "  ...and a process that has one of several top-level scripts open: exit 3, that process named" "$(PROBE= mv_ "$H"):$(said "$H" "^  stop: a script is running from ~/cs2-patch (process $(cat "$T/o.pid"))")" "3:1"
kill "$(cat "$T/i.pid")" "$(cat "$T/o.pid")" 2>/dev/null; rm -f "$T/i.pid" "$T/o.pid"

# --- LT26: symlinks and modes
p_oldlink() { mv "$H/cs2-patch" "$H/real"; ln -s "$H/real" "$H/cs2-patch"; }
p_rootlink() { mv "$H/$DR" "$H/dr"; ln -s "$H/dr" "$H/$DR"; }
p_dangling() { ln -s "$H/nowhere" "$H/$DR/$G"; }
p_patchlink() { mv "$H/cs2-patch/patches" "$H/pp"; ln -s "$H/pp" "$H/cs2-patch/patches"; }
p_groupw() { chmod g+w "$H/$DR"; }
skipcase "the old folder a symlink" '^  skip: ~/cs2-patch is a symlink' p_oldlink
skipcase "the data root a symlink" "^  skip: ~/$DR is a symlink" p_rootlink
skipcase "the runtime folder a dangling symlink" "^  skip: ~/$DR/$G is already there" p_dangling
skipcase "patches a symlink in the old folder" '^  skip: ~/cs2-patch/patches is a symlink' p_patchlink
skipcase "the data root writable by group" "^  skip: ~/$DR is not a folder of your own that only you can write to" p_groupw
H="$T/m1"; mkdir -p "$H"; full "$H"
check "a fresh home with no roots, moved under umask 000: the roots made are not writable by group or others" "$( (umask 000; mv_ "$H") ):$(mode "$H/$DR"):$(mode "$H/$WR")" "0:755:755"
H="$T/m2"; mkdir -p "$H"; roots "$H"; runtime "$H"; chmod 777 "$H/cs2-patch" "$H/cs2-patch/patches"; chmod 666 "$H/cs2-patch/launch-cs2-dxmt11.sh" "$H/cs2-patch/patches/patch_a.py"
check "an old folder of mode 777 whose launcher is mode 666, moved: no folder and no file in the runtime folder is writable by group or others" "$(mv_ "$H"):$(mode "$H/$DR/$G"):$(mode "$H/$DR/$G/patches"):$(mode "$H/$DR/$G/launch-cs2-dxmt11.sh"):$(loose "$H/$DR/$G")" "0:755:755:644:0"
H="$T/m3"; mkdir -p "$H"; roots "$H"; full "$H"; chmod 777 "$H/cs2-patch" "$H/cs2-patch/patches"; chmod 666 "$H/cs2-patch/launch-cs2-dxmt11.sh"
check "  ...the same for a folder that is renamed and lifted" "$(mv_ "$H"):$(mode "$H/$DR/$G/launch-cs2-dxmt11.sh"):$(loose "$H/$DR/$G")" "0:644:0"

# --- the two rules every run above was held to
check "line 1 of every run's output is its state: line" "$(wc -l < "$T/bad.first" | tr -d ' ')" 0
check "no line of any run's output holds the scratch home" "$(wc -l < "$T/raw.hits" | tr -d ' ')" 0

echo "$fails failure(s)"
[ "$fails" = 0 ]
