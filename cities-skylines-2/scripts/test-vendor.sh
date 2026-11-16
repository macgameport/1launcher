#!/bin/bash
# test-vendor.sh -- the two Python libraries shipped in patches/_vendor (dnfile, pefile): the folder is what
# its manifest says, git stores every byte unchanged, every script that imports dnfile finds it there under
# Apple's python3 and whatever python3 is first on PATH, from any working directory, through a symlink and
# from an install-folder layout, and running them leaves no bytecode behind. And patch_cohtml.py's three
# forms of the function (one per compiler output seen in a game build): each is found, patched once and
# then recognised as patched, and two forms in one file are refused.
# Also the patch scripts' outcome (docs/plans/patch-outcomes.md 2.1): 0 = the fix is in place, 3 = not for
# this build (nothing written, no .bak), anything else = a failure (nothing written). PT1: the five
# byte-search scripts on the real bytes of build 26404411 in a file of zeros. PT2: the six errno scripts at
# their fixed offsets. PT3's source gate: in the five PDX.SDK.dll scripts every refusal is `moved` (exit 3)
# or `die` (exit 1) as 2.2 classes it, and the pasted block is the same in each. The rest of PT3 needs the
# game: scripts/test-patch-outcomes.sh.
# No game, no Wine, no network. Nothing is written outside a scratch folder.
#   bash scripts/test-vendor.sh            exit 0 = every case passed
#   MUTANT=1 ...   one byte of one vendored file changed (in a scratch copy); must exit 1
#   MUTANT=2 ...   one patcher no longer sets sys.dont_write_bytecode; must exit 1
#   MUTANT=3 ...   one patcher finds _vendor with abspath instead of realpath; must exit 1
#   MUTANT=4 ...   patch_longfile.py returns instead of exit 3 when its pattern is missing; must exit 1
#   MUTANT=5 ...   the .gitattributes line for _vendor is moved to the top; must exit 1
#   MUTANT=6 ...   patch_cohtml.py's form for 1.6.4f1 (fn-rbx) no longer matches; must exit 1
#   PT1, each must exit 1:
#   MUTANT=7..11   exit 3 made 1 in patch_cohtml.py, patch_longfile.py, patch_fshandle.py, patch_colossal_io.py,
#                  patch_asset_database.py (in that order)
#   MUTANT=12, 13  exit 3 made 0 in patch_colossal_io.py, patch_asset_database.py (the two that returned 0)
#   MUTANT=14      patch_colossal_io.py: the count's rule dropped (one site of two goes on to be patched)
#   MUTANT=15, 16  the patched-form search dropped in patch_colossal_io.py, patch_asset_database.py
#   MUTANT=17, 18  the .bak copied before the count again, in patch_colossal_io.py, patch_asset_database.py
#   MUTANT=19      patch_colossal_io.py: the floor of the patched form's nn put back to 3
#   MUTANT=20      patch_cohtml.py: a missing file made exit 3
#   MUTANT=21      patch_longfile.py: "patching all" again when there are more original sites than expected
#   PT2, each must exit 1:
#   MUTANT=22      patch_dirhandle.py makes its .bak before the check again
#   MUTANT=23      patch_delfile.py: exit 3 made 1
#   MUTANT=24      patch_dirhandle.py writes the file again when it already holds the fix
#   PT3's source gate, each must exit 1:
#   MUTANT=25..29  one `moved` made `die` in patch_mkparent.py, patch_lockbypass.py, patch_longdelete.py,
#                  patch_createfile.py, patch_lockleak.py (in that order)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TOP="$(cd "$REPO/.." && pwd)"
T="$(mktemp -d /tmp/vendor-test.XXXX)"
trap 'rm -rf "$T"' EXIT
M="${MUTANT:-0}"
# the scripts under test are always a scratch copy, so that a mutant never touches the checkout
C="$T/c"; mkdir -p "$C"; cp -R "$REPO/patches" "$C/patches"; mkdir -p "$C/scripts"
cp "$REPO/scripts/patch-modconflict-badge.py" "$REPO/scripts/disasm.py" "$REPO/scripts/dump-binding-attrs.py" "$C/scripts/"
cp "$TOP/.gitattributes" "$T/gitattributes"
V="$C/patches/_vendor"
mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
case "$M" in
  1) printf 'x' | dd of="$V/pefile.py" bs=1 seek=100 conv=notrunc 2>/dev/null ;;
  2) sed -i '' '/^sys.dont_write_bytecode = True/d' "$C/patches/patch_mkparent.py"; grep -q '^sys.dont_write_bytecode' "$C/patches/patch_mkparent.py" && mutated ;;
  3) sed -i '' 's/os.path.realpath(__file__)/os.path.abspath(__file__)/' "$C/patches/patch_lockleak.py"; grep -q 'abspath(__file__)' "$C/patches/patch_lockleak.py" || mutated ;;
  4) sed -i '' 's/^        sys.exit(3)  # neither the original bytes.*/        return/' "$C/patches/patch_longfile.py"; grep -q 'neither the original bytes' "$C/patches/patch_longfile.py" && mutated ;;
  5) { grep 'patches/_vendor' "$T/gitattributes"; grep -v 'patches/_vendor' "$T/gitattributes"; } > "$T/ga" && mv "$T/ga" "$T/gitattributes"
     [ "$(head -1 "$T/gitattributes" | grep -c '_vendor')" = 1 ] || mutated ;;
  6) sed -i '' 's/0x48, 0x8B, 0xD9,   /0x48, 0x8B, 0xDA,   /' "$C/patches/patch_cohtml.py"; grep -q '0x48, 0x8B, 0xDA,' "$C/patches/patch_cohtml.py" || mutated ;;
  7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)
     case "$M" in   # <script> <sed expression> <a fixed string the mutated file must then hold>
       7)  set -- patch_cohtml.py 's/^        sys.exit(3)$/        sys.exit(1)/' '        sys.exit(1)$' ;;
       8)  set -- patch_longfile.py 's/^        sys.exit(3)  # neither/        sys.exit(1)  # neither/' 'sys.exit(1)  # neither' ;;
       9)  set -- patch_fshandle.py 's/sys.exit(1 if dry else 3)  # not for this build/sys.exit(1)  # not for this build/' 'sys.exit(1)  # not for this build' ;;
       10) set -- patch_colossal_io.py 's/^        sys.exit(3)$/        sys.exit(1)/' '^        sys.exit(1)$' ;;
       11) set -- patch_asset_database.py 's/^        sys.exit(3)$/        sys.exit(1)/' '^        sys.exit(1)$' ;;
       12) set -- patch_colossal_io.py 's/^        sys.exit(3)$/        return/' '^        return$' ;;
       13) set -- patch_asset_database.py 's/^        sys.exit(3)$/        return/' '^        return$' ;;
       14) set -- patch_colossal_io.py 's/^    if p == 0 and o != EXPECTED_MATCHES:$/    if p == 0 and o == 0:/' 'if p == 0 and o == 0:' ;;
       15) set -- patch_colossal_io.py 's/^    return hits$/    return []/' '^    return \[\]$' ;;
       16) set -- patch_asset_database.py 's/len(find_priority_file_exists_pattern(data, patched=True))$/0/' 'o, p = len(matches), 0$' ;;
       17) set -- patch_colossal_io.py "s/^    data = bytearray(open(dll_path, 'rb').read())\$/&; shutil.copy2(dll_path, backup_path)/" 'read()); shutil.copy2' ;;
       18) set -- patch_asset_database.py "s/^    data = bytearray(open(dll_path, 'rb').read())\$/&; shutil.copy2(dll_path, backup_path)/" 'read()); shutil.copy2' ;;
       19) set -- patch_colossal_io.py 's/^PATCHED_MIN, PATCHED_MAX = 16, 42$/PATCHED_MIN, PATCHED_MAX = 3, 42/' '= 3, 42$' ;;
       20) set -- patch_cohtml.py 's/^        sys.exit(1)$/        sys.exit(3)/' '^        sys.exit(3)$' ;;
       21) set -- patch_longfile.py 's/^    if o != EXPECTED_MATCHES:$/    if False:/' '^    if False:$' ;;
       22) set -- patch_dirhandle.py 's/^    d = bytearray(open(p, "rb").read())$/&; os.path.exists(p + ".bak") or shutil.copy2(p, p + ".bak")/' 'read()); os.path.exists' ;;
       23) set -- patch_delfile.py 's/at 0x{OFF:x}"); sys.exit(3)/at 0x{OFF:x}"); sys.exit(1)/' 'at 0x{OFF:x}"); sys.exit(1)' ;;
       24) set -- patch_dirhandle.py 's/^            return  # nothing to write.*/            pass/' '^            pass$' ;;
       25) set -- patch_mkparent.py 's/moved(f"MethodDef#{rid} body at RVA/die(f"MethodDef#{rid} body at RVA/' 'die(f"MethodDef#{rid} body at RVA' ;;
       26) set -- patch_lockbypass.py 's/moved(f"GetError IL differs/die(f"GetError IL differs/' 'die(f"GetError IL differs' ;;
       27) set -- patch_longdelete.py 's/moved(f"{nm} body only/die(f"{nm} body only/' 'die(f"{nm} body only' ;;
       28) set -- patch_createfile.py 's/moved(f"{nm} original IL differs/die(f"{nm} original IL differs/' 'die(f"{nm} original IL differs' ;;
       29) set -- patch_lockleak.py 's/moved(f"Log run at IL/die(f"Log run at IL/' 'die(f"Log run at IL' ;;
     esac
     cp "$C/patches/$1" "$T/before.py"; sed -i '' "$2" "$C/patches/$1"
     { ! cmp -s "$T/before.py" "$C/patches/$1" && grep -q -- "$3" "$C/patches/$1"; } || mutated ;;
esac
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
PYS="/usr/bin/python3"; P2="$(command -v python3)"; [ "$P2" != /usr/bin/python3 ] && PYS="$PYS $P2"

# --- the folder is what the manifest says
check "the manifest verifies" "$(cd "$V" && shasum -a 256 -c MANIFEST.sha256 >/dev/null 2>&1; echo $?)" 0
check "the manifest lists every file but itself, the README and the two licences" \
  "$(cd "$V" && find . -type f ! -name MANIFEST.sha256 ! -name README.md ! -name 'LICENSE-*' ! -path '*/__pycache__/*' | sed 's#^\./##' | LC_ALL=C sort | tr '\n' ' ')" \
  "$(cd "$V" && awk '{print $2}' MANIFEST.sha256 | LC_ALL=C sort | tr '\n' ' ')"
check "both licence files are there" "$(ls "$V" | grep -c '^LICENSE-')" 2

# --- git stores every byte as it came: the rule must be the last line of .gitattributes to win
G="$T/g"; mkdir -p "$G/cities-skylines-2/patches/_vendor/ordlookup"; cp "$T/gitattributes" "$G/.gitattributes"
cp "$REPO/patches/_vendor/ordlookup/wsock32.py" "$G/cities-skylines-2/patches/_vendor/ordlookup/"
( cd "$G" && git init -q . && git add -A 2>/dev/null )
check "a file with CRLF endings is stored with them, and marked -text" "$(cd "$G" && git ls-files --eol cities-skylines-2/patches/_vendor/ordlookup/wsock32.py | awk '{print $1, $2, $3}')" "i/crlf w/crlf attr/-text"

# --- every script that imports dnfile gets it from _vendor
for py in $PYS; do
  v="$("$py" -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
  check "python $v imports dnfile 0.18.0 from _vendor" \
    "$("$py" -I -B -c "import sys; sys.path.insert(0, '$V'); import dnfile; print(dnfile.__version__, dnfile.__file__.startswith('$V'))" 2>&1)" "0.18.0 True"
  L="$T/layout-$v"; mkdir -p "$L/other" "$L/install/patches"                       # an install-folder layout
  cp -R "$C/patches/." "$L/install/patches/"; cp "$C/scripts/patch-modconflict-badge.py" "$L/install/"
  ln -s "$C/patches/patch_lockleak.py" "$L/link-to-lockleak.py"                    # run through a symlink
  past=0; total=0
  for s in "$C/patches/patch_mkparent.py" "$C/patches/patch_lockbypass.py" "$C/patches/patch_longdelete.py" \
           "$C/patches/patch_createfile.py" "$C/patches/patch_lockleak.py" "$C/patches/dis_pdx.py" \
           "$C/scripts/disasm.py" "$C/scripts/dump-binding-attrs.py" "$C/scripts/patch-modconflict-badge.py" \
           "$L/install/patches/patch_mkparent.py" "$L/install/patch-modconflict-badge.py" "$L/link-to-lockleak.py"; do
    total=$((total + 1))
    out="$(cd "$L/other" && HOME="$T/nohome" "$py" -I -X pycache_prefix="$T/pyc-$v" "$s" "$T/no-such-target" 2>&1)"
    case "$out" in *"No module named"*|*ModuleNotFoundError*|*ImportError*) echo "      import failed: ${s#$T/}" ;; *) past=$((past + 1)) ;; esac
  done
  check "python $v: all $total runs get past the import (another directory, a symlink, an install layout)" "$past" "$total"
  check "python $v: no bytecode for the vendored files, anywhere" \
    "$(find "$T/pyc-$v" "$V" "$L/install/patches/_vendor" -name '*.pyc' 2>/dev/null | grep -c '_vendor')" 0
done
check "no __pycache__ in the checkout's own _vendor" "$(find "$REPO/patches/_vendor" -name __pycache__ | wc -l | tr -d ' ')" 0

# --- a file that holds neither the original bytes nor the patched ones is "not for this build" (exit 3), not
#     "no changes needed", and nothing is written
# snap <file>...: sha256 prefix and mtime in ns of each file, or "none": equal before and after = nothing written
snap() { /usr/bin/python3 -I -c 'import sys, os, hashlib
print(" ".join(hashlib.sha256(open(p, "rb").read()).hexdigest()[:16] + ":" + str(os.stat(p).st_mtime_ns)
               if os.path.exists(p) else "none" for p in sys.argv[1:]))' "$@"; }
R="$T/root"; mkdir -p "$R/Cities2_Data/Plugins/x86_64" "$R/Cities2_Data/Managed"
head -c 8192 /dev/zero > "$R/Cities2_Data/Plugins/x86_64/cohtml_unity3dplugin.dll"
head -c 8192 /dev/zero > "$R/Cities2_Data/Managed/Colossal.IO.dll"
F="$R/Cities2_Data/Plugins/x86_64/cohtml_unity3dplugin.dll"; s0="$(snap "$F" "$F.bak")"
out="$(/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$R" 2>&1)"; rc=$?
check "patch_cohtml.py on a file with neither form: warns, exit 3, nothing written, no .bak" \
  "$rc:$(echo "$out" | grep -c 'WARNING: Pattern not found'):$(snap "$F" "$F.bak")" "3:1:$s0"
F="$R/Cities2_Data/Managed/Colossal.IO.dll"; s0="$(snap "$F" "$F.bak")"
out="$(/usr/bin/python3 -I "$C/patches/patch_longfile.py" "$R" 2>&1)"; rc=$?
check "patch_longfile.py on a file with neither form: warns, exit 3, nothing written, no .bak" \
  "$rc:$(echo "$out" | grep -c 'WARNING: GetFileHandle throw pattern not found'):$(snap "$F" "$F.bak")" "3:1:$s0"

# --- patch_cohtml.py: the function as each game build compiled it. The bytes are the real ones of 1.6.2f1
#     (fn; with the int3 before it, 1.6.0f1's legacy form too) and of 1.6.4f1 (fn-rbx), in a file of zeros.
FN="405648 83EC30 80791000 488BF1 0F84 2E060000 488B8998000000"
RBX="405348 83EC30 80791000 488BD9 0F84 32060000 488B8998000000"
mk() { /usr/bin/python3 -I -c 'import sys; open(sys.argv[1], "wb").write(bytes(4096) + b"".join(bytes.fromhex(h) + bytes(64) for h in sys.argv[2:]) + bytes(4096))' "$@"; }
at() { xxd -s "$2" -l 1 -p "$1"; }
for form in "fn:$FN:4110:fn" "fn-rbx:$RBX:4110:fn-rbx" "legacy:CC $FN:4111:legacy, fn"; do
  IFS=: read -r name hex off found <<<"$form"
  D="$T/cohtml-$name"; F="$D/Cities2_Data/Plugins/x86_64/cohtml_unity3dplugin.dll"; mkdir -p "$(dirname "$F")"
  mk "$F" "$hex"
  out="$(/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$D" 2>&1)"; rc=$?
  check "patch_cohtml.py, $name: found, the je becomes jne, the original kept beside it" \
    "$rc:$(echo "$out" | grep -cF "Pattern found [$found]"):$(at "$F" "$off"):$(at "$F.bak" "$off")" "0:1:85:84"
  out="$(/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$D" 2>&1)"; rc=$?
  check "patch_cohtml.py, $name: a second run sees it patched and writes nothing" \
    "$rc:$(echo "$out" | grep -cF "Already patched (je -> jne) at 0x$(printf '%X' "$off") [$found]"):$(at "$F" "$off")" "0:1:85"
done
D="$T/cohtml-two"; F="$D/Cities2_Data/Plugins/x86_64/cohtml_unity3dplugin.dll"; mkdir -p "$(dirname "$F")"
mk "$F" "$FN" "$RBX"
out="$(/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$D" 2>&1)"; rc=$?
check "patch_cohtml.py, two forms in one file and neither patched: refused, exit 3, nothing written" \
  "$rc:$(echo "$out" | grep -c 'more than one site'):$(at "$F" 4110):$(at "$F" 4200):$([ -e "$F.bak" ] && echo bak || echo none)" "3:1:84:84:none"

FP="$(echo "$FN" | sed 's/0F84/0F85/')"
D="$T/cohtml-half"; F="$D/Cities2_Data/Plugins/x86_64/cohtml_unity3dplugin.dll"; mkdir -p "$(dirname "$F")"
mk "$F" "$FP" "$RBX"; s0="$(snap "$F" "$F.bak")"
/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$D" >/dev/null 2>&1; rc=$?
check "patch_cohtml.py, one patched and one original form: exit 1, nothing written" "$rc:$(snap "$F" "$F.bak")" "1:$s0"
/usr/bin/python3 -I "$C/patches/patch_cohtml.py" "$T/nowhere" >/dev/null 2>&1; rc=$?
check "patch_cohtml.py, no file there: exit 1" "$rc" 1

# --- PT1 (docs/plans/patch-outcomes.md section 4): the byte-search scripts on the real bytes of build 26404411
#     (from the .baks), each in a file of zeros. A case is: exit code, then what the file and its .bak became.
z() { printf '%0*d' $(( $1 * 2 )) 0; }
# const <script> <code>: run the code among the script's own names (the script loaded, its main not run); prints `out`
const() { /usr/bin/python3 -I -B -c 'import sys, importlib.util
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("m", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m); ns = vars(m); exec(sys.argv[2], ns); print(ns["out"])' "$C/patches/$1" "$2"; }
run() { /usr/bin/python3 -I "$C/patches/$1" "${@:2}" >"$T/out" 2>&1; echo $?; }
sha() { shasum -a 256 "$1" | cut -c1-16; }
# place <dir> <path under it> [hex...]: the file, made by mk, and its folder; prints the file's path
place() { local f="$1/$2"; shift 2; mkdir -p "$(dirname "$f")"; mk "$f" "$@"; echo "$f"; }

# patch_colossal_io.py, two sites (E = 2): the 24- and 27-byte sites and the 4 bytes after each
CIO=Cities2_Data/Managed/Colossal.IO.dll
S1=282700000a0d091f122e0d091472f802007028400000067a; A1=0228f301
S2=282700000a130511051f122e0e11051472f802007028400000067a; A2=0228fc01
S1FAR=282700000a0d091f122e0f091472f802007028400000067a   # its beq.s lands two bytes past the throw
P1="2b16$(z 22)"; P2="2b19$(z 25)"                         # the two sites as the script patches them
F="$(place "$T/cio-none" $CIO)"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, neither form: exit 3, nothing written, no .bak" "$(run patch_colossal_io.py "$T/cio-none"):$(snap "$F" "$F.bak")" "3:$s0"
mkdir -p "$T/cio-missing"
check "patch_colossal_io.py, no file there: exit 1" "$(run patch_colossal_io.py "$T/cio-missing")" 1
F="$(place "$T/cio-orig" $CIO "$S1$A1" "$S2$A2")"; h0="$(sha "$F")"
check "patch_colossal_io.py, both sites original: exit 0, both patched, the .bak is the file as it was" \
  "$(run patch_colossal_io.py "$T/cio-orig"):$(xxd -s 4096 -l 2 -p "$F"):$(xxd -s 4188 -l 2 -p "$F"):$(sha "$F.bak")" "0:2b16:2b19:$h0"
s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, a second run: exit 0, nothing written" "$(run patch_colossal_io.py "$T/cio-orig"):$(snap "$F" "$F.bak")" "0:$s0"
F="$(place "$T/cio-three" $CIO "$S1$A1" "$S2$A2" "$S1$A1")"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, three original sites and none patched: exit 3, nothing written" "$(run patch_colossal_io.py "$T/cio-three"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/cio-oldbak" $CIO "$S1$A1" "$S2$A2")"; h0="$(sha "$F")"; head -c 100 /dev/zero > "$F.bak"
check "patch_colossal_io.py, both original beside an older .bak: exit 0, the .bak refreshed" "$(run patch_colossal_io.py "$T/cio-oldbak"):$(sha "$F.bak")" "0:$h0"
F="$(place "$T/cio-half" $CIO "$P1$A1" "$S2$A2")"; mk "$F.bak" "$S1$A1" "$S2$A2"; b0="$(snap "$F.bak")"
check "patch_colossal_io.py, one patched and one original beside a pristine .bak: exit 0, both patched, the .bak as it was" \
  "$(run patch_colossal_io.py "$T/cio-half"):$(xxd -s 4096 -l 2 -p "$F"):$(xxd -s 4188 -l 2 -p "$F"):$(snap "$F.bak")" "0:2b16:2b19:$b0"
check "patch_colossal_io.py, ... and that file then equals the one patched from two original sites" "$(sha "$F")" "$(sha "$T/cio-orig/$CIO")"
F="$(place "$T/cio-sum" $CIO "$P1$A1" "$S2$A2" "$S1$A1")"; mk "$F.bak" "$S1$A1" "$S2$A2"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, a patched site beside sites that do not add up: exit 1, file and .bak unchanged" "$(run patch_colossal_io.py "$T/cio-sum"):$(snap "$F" "$F.bak")" "1:$s0"
F="$(place "$T/cio-one" $CIO "$S2$A2")"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, one original site alone: exit 3, nothing written" "$(run patch_colossal_io.py "$T/cio-one"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/cio-far" $CIO "$S1FAR$A1" "$S2$A2")"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, a site whose beq.s lands two bytes further: exit 3, not written" "$(run patch_colossal_io.py "$T/cio-far"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/cio-loose" $CIO "$S2$A2" "2b16$(z 23)02")"; s0="$(snap "$F" "$F.bak")"
check "patch_colossal_io.py, 2b 16 then 23 zeros then a non-zero byte is not a patched site: exit 3" "$(run patch_colossal_io.py "$T/cio-loose"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/cio-floor" $CIO "$S1$A1" "$S2$A2" "2b05$(z 5)01")"
check "patch_colossal_io.py, a short br.s over 5 nops beside the two sites is not a patched site: exit 0" "$(run patch_colossal_io.py "$T/cio-floor")" 0

# patch_asset_database.py, one site (E = 1): 26 bytes before the site, its call, and 12 after
ADB=Cities2_Data/Managed/Colossal.IO.AssetDatabase.dll
AD=6f2a05000addb4020000110472b554007028cf00000a13071107282c05000a39980000001107282d05000a
ADP="$(echo "$AD" | sed 's/282c05000a39/261600000039/')"
F="$(place "$T/adb-none" $ADB)"; s0="$(snap "$F" "$F.bak")"
check "patch_asset_database.py, neither form: exit 3, nothing written, no .bak" "$(run patch_asset_database.py "$T/adb-none"):$(snap "$F" "$F.bak")" "3:$s0"
mkdir -p "$T/adb-missing"
check "patch_asset_database.py, no file there: exit 1" "$(run patch_asset_database.py "$T/adb-missing")" 1
F="$(place "$T/adb-orig" $ADB "$AD")"; h0="$(sha "$F")"
check "patch_asset_database.py, the site original: exit 0, patched, the .bak is the file as it was" \
  "$(run patch_asset_database.py "$T/adb-orig"):$(xxd -s 4122 -l 5 -p "$F"):$(sha "$F.bak")" "0:2616000000:$h0"
s0="$(snap "$F" "$F.bak")"
check "patch_asset_database.py, a second run: exit 0, nothing written" "$(run patch_asset_database.py "$T/adb-orig"):$(snap "$F" "$F.bak")" "0:$s0"
F="$(place "$T/adb-two" $ADB "$AD" "$AD")"; s0="$(snap "$F" "$F.bak")"
check "patch_asset_database.py, two original sites and none patched: exit 3, nothing written" "$(run patch_asset_database.py "$T/adb-two"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/adb-oldbak" $ADB "$AD")"; h0="$(sha "$F")"; head -c 100 /dev/zero > "$F.bak"
check "patch_asset_database.py, the site original beside an older .bak: exit 0, the .bak refreshed" "$(run patch_asset_database.py "$T/adb-oldbak"):$(sha "$F.bak")" "0:$h0"
F="$(place "$T/adb-sum" $ADB "$ADP" "$AD")"; mk "$F.bak" "$AD"; s0="$(snap "$F" "$F.bak")"
check "patch_asset_database.py, a patched site beside an original one: exit 1, file and .bak unchanged" "$(run patch_asset_database.py "$T/adb-sum"):$(snap "$F" "$F.bak")" "1:$s0"

# patch_longfile.py, one site (E = 1): the forms built from the script's own PATTERN
LO="$(const patch_longfile.py 'out = bytes(1 if b is None else b for b in PATTERN).hex()')"
LP="$(const patch_longfile.py 'out = bytes(0 if NOP_START <= k < NOP_END else 1 if b is None else b for k, b in enumerate(PATTERN)).hex()')"
mkdir -p "$T/lf-missing"
check "patch_longfile.py, no file there: exit 1" "$(run patch_longfile.py "$T/lf-missing")" 1
F="$(place "$T/lf-orig" $CIO "$LO")"; h0="$(sha "$F")"
check "patch_longfile.py, the site original: exit 0, the throw made nops, a .bak of the file as it was" \
  "$(run patch_longfile.py "$T/lf-orig"):$(xxd -s 4096 -l 14 -p "$F"):$(sha "$F.bak")" "0:$LP:$h0"
s0="$(snap "$F" "$F.bak")"
check "patch_longfile.py, a second run: exit 0, nothing written" "$(run patch_longfile.py "$T/lf-orig"):$(snap "$F" "$F.bak")" "0:$s0"
F="$(place "$T/lf-two" $CIO "$LO" "$LO")"; s0="$(snap "$F" "$F.bak")"
check "patch_longfile.py, two original sites and none patched: exit 3, nothing written" "$(run patch_longfile.py "$T/lf-two"):$(snap "$F" "$F.bak")" "3:$s0"
F="$(place "$T/lf-oldbak" $CIO "$LO")"; head -c 100 /dev/zero > "$F.bak"; b0="$(snap "$F.bak")"
check "patch_longfile.py, the site original beside an older .bak: exit 0, the .bak kept" "$(run patch_longfile.py "$T/lf-oldbak"):$(snap "$F.bak")" "0:$b0"
F="$(place "$T/lf-sum" $CIO "$LP" "$LO")"; mk "$F.bak" "$LO"; s0="$(snap "$F" "$F.bak")"
check "patch_longfile.py, a patched site beside an original one: exit 1, file and .bak unchanged" "$(run patch_longfile.py "$T/lf-sum"):$(snap "$F" "$F.bak")" "1:$s0"

# patch_fshandle.py, one guard: built from the script's own ORIG and FINGERPRINT, with the throw at IL 0x20
MSC=Cities2_Data/Managed/mscorlib.dll
FO="$(const patch_fshandle.py 'x = bytearray(0x25); x[:4] = ORIG
for k, v in FINGERPRINT.items(): x[k] = v
x[0x20] = 0x7a; out = x.hex()')"
F="$(place "$T/fs-none" $MSC)"; s0="$(snap "$F" "$F.bak")"
check "patch_fshandle.py, neither form: exit 3, nothing written, no .bak" "$(run patch_fshandle.py "$T/fs-none"):$(snap "$F" "$F.bak")" "3:$s0"
check "patch_fshandle.py, neither form with --dry-run: the dry run's own ending, exit 1" "$(run patch_fshandle.py "$T/fs-none" --dry-run)" 1
mkdir -p "$T/fs-missing"
check "patch_fshandle.py, no file there: exit 1" "$(run patch_fshandle.py "$T/fs-missing")" 1
F="$(place "$T/fs-orig" $MSC "$FO")"; h0="$(sha "$F")"
check "patch_fshandle.py, the guard original: exit 0, it becomes br.s, a .bak of the file as it was" \
  "$(run patch_fshandle.py "$T/fs-orig"):$(xxd -s 4096 -l 4 -p "$F"):$(sha "$F.bak")" "0:2b1f0000:$h0"
s0="$(snap "$F" "$F.bak")"
check "patch_fshandle.py, a second run: exit 0, nothing written" "$(run patch_fshandle.py "$T/fs-orig"):$(snap "$F" "$F.bak")" "0:$s0"
F="$(place "$T/fs-two" $MSC "$FO" "$FO")"; s0="$(snap "$F" "$F.bak")"
check "patch_fshandle.py, two guards and none patched: exit 3, nothing written" "$(run patch_fshandle.py "$T/fs-two"):$(snap "$F" "$F.bak")" "3:$s0"

# --- PT2: the six errno scripts, each at its fixed offset in mscorlib.dll: <script> <offset> <original> <patched>
ERRNO="patch_dirdel.py 0x15461f 7a 00
patch_delchild.py 0x154609 7a 26
patch_delfile.py 0x15409e 7a 26
patch_delrec.py 0x1546ca 7a2a 262a
patch_dirrec_nx.py 0x1544e2 0228d66600067a 38390100000000
patch_dirhandle.py 0x16cca0 2c06 2600"
# ffile <path> [<offset> <hex>]...: 0x16cd00 bytes of ff with the given bytes placed
ffile() { /usr/bin/python3 -I -c 'import sys
d = bytearray(b"\xff" * 0x16cd00); a = sys.argv[2:]
for o, h in zip(a[::2], a[1::2]): b = bytes.fromhex(h); d[int(o, 16):int(o, 16) + len(b)] = b
open(sys.argv[1], "wb").write(d)' "$@"; }
E="$T/errno"; mkdir -p "$E"
ffile "$E/expected.dll" $(echo "$ERRNO" | awk '{print $2, $3}')
ffile "$E/delrec-noret.dll" 0x1546ca 7a
while read -r s off orig patched; do
  n="${s%.py}"; F="$E/$n-ff.dll"; ffile "$F"; s0="$(snap "$F" "$F.bak")"
  check "$s on a file of ff: exit 3, unchanged, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  F="$E/$n-zeros.dll"; head -c 4096 /dev/zero > "$F"; s0="$(snap "$F" "$F.bak")"
  check "$s on 4,096 zeros, too short for its offset: exit 3, unchanged, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  F="$E/$n-ok.dll"; cp "$E/expected.dll" "$F"
  check "$s with its expected bytes at $off: exit 0, patched, a .bak made" \
    "$(run "$s" "$F"):$(xxd -s "$off" -l $(( ${#patched} / 2 )) -p "$F"):$([ -e "$F.bak" ] && echo bak)" "0:$patched:bak"
  rm -f "$F.bak"; s0="$(snap "$F" "$F.bak")"
  check "$s, a second run: exit 0, nothing written, no .bak made" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "0:$s0"
  check "$s, no file there: exit 1" "$(run "$s" "$E/no-such.dll")" 1
done <<< "$ERRNO"
F="$E/delrec-noret.dll"; s0="$(snap "$F" "$F.bak")"
check "patch_delrec.py, 7a at its offset and a next byte that is not 2a: exit 3, unchanged" "$(run patch_delrec.py "$F"):$(snap "$F" "$F.bak")" "3:$s0"

# --- PT3's source gate: in the five PDX.SDK.dll scripts every refusal is `moved` (exit 3: not for this build) or
#     `die` (exit 1) by the class of docs/plans/patch-outcomes.md 2.2, matched on the message, and the pasted block
#     is one text in the four that share it and in patch_mkparent.py apart from its ensure_text_vsize.
gate="$(/usr/bin/python3 -I - "$C/patches" <<'PY'
import re, sys, hashlib
d = sys.argv[1]
DIE = ("does not decode", "no longer fits", "verification failed")
MOVED = ("matched", "no MemberRef", ".text", "first section")
WANT = {"patch_mkparent.py": (13, 3), "patch_lockbypass.py": (11, 1), "patch_longdelete.py": (12, 1),
        "patch_createfile.py": (13, 2), "patch_lockleak.py": (14, 1)}   # (moved calls, die calls)
bad, blocks = [], {}
for f, want in WANT.items():
    src = open(f"{d}/{f}").read()
    n = {"moved": 0, "die": 0}; seen = set()
    for ln in src.splitlines():
        if ln.lstrip().startswith("def "): continue
        for kind, msg in re.findall(r"\b(die|moved)\((.*)", ln):
            n[kind] += 1
            if (kind == "die") != any(p in msg for p in DIE): bad.append(f"{f}: {kind}({msg[:50]}")
            if kind == "moved": seen |= {p for p in MOVED if p in msg}
    if (n["moved"], n["die"]) != want: bad.append(f"{f}: {n['moved']} moved, {n['die']} die, want {want}")
    if seen != set(MOVED): bad.append(f"{f}: no moved call for {set(MOVED) - seen}")
    blk = src[src.index("# ---- shared by-name"):src.index("# ---- end shared block ----")]
    if not re.search(r"def moved\(msg\):\n(    .*\n)*?    sys\.exit\(3\)\n", blk): bad.append(f"{f}: moved does not exit 3")
    if f == "patch_mkparent.py":
        a = blk.index("def ensure_text_vsize"); blk = blk[:a] + blk[blk.index("def match(", a):]
    blocks[f] = hashlib.sha256(blk.encode()).hexdigest()[:16]
if len(set(blocks.values())) != 1: bad.append(f"the block differs: {blocks}")
print("\n".join(bad) if bad else "ok")
PY
)"
check "PT3 source gate: every moved and die call of the five PDX.SDK.dll scripts in its class, one block" "$gate" ok

echo "$fails failure(s)"
[ "$fails" = 0 ]
