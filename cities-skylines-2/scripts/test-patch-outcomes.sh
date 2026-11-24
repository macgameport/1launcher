#!/bin/bash
# test-patch-outcomes.sh -- PT3 of docs/plans/patch-outcomes.md, the part that needs the game: the five
# PDX.SDK.dll patch scripts (patch_mkparent, patch_lockbypass, patch_longdelete, patch_createfile,
# patch_lockleak) on clones of the game's own files. Exit 0 = the fix is in place, 3 = not for this build
# (nothing written, no .bak), anything else = a failure (nothing written). The source gate of the same test
# (every refusal in its class, one pasted block) needs no game and is in scripts/test-vendor.sh.
# The game is found by CS2_GAME_DIR, else the default wrapper under the real home. What is read is cloned
# into a scratch folder first: no script is ever run on the game's own files. With no game here it says
# "SKIPPED: no game here" and exits 0. No Wine, no Steam, no network.
# The unpatched PDX.SDK.dll is the game's PDX.SDK.dll.bak; the test prints its size and date, since a .bak
# can be an older build's (the scripts make one only when there is none).
#   bash scripts/test-patch-outcomes.sh       exit 0 = every case passed (or SKIPPED)
#   MUTANT=1 ...   `moved` exits 1 instead of 3, in all five; must exit 1
#   MUTANT=2 ...   patch_lockleak.py --revert no longer makes an exit 3 from reading the .bak into 1; must exit 1
#   MUTANT=3 ...   patch_longdelete.py: a refusal beside a method found patched stays 3; must exit 1
#   MUTANT=4 ...   patch_createfile.py: the same; must exit 1
# And ET2 of docs/plans/errno-by-name.md, a section of its own: the six errno scripts (patch_dirdel,
# patch_delchild, patch_dirrec_nx, patch_delrec, patch_delfile, patch_dirhandle) on clones of the game's
# unpatched mscorlib.dll. That is mscorlib.dll.bak when it has the installed file's size and differs from it in
# fewer than 64 bytes (the installed one holds patch_fshandle.py's change); otherwise the installed file, with
# a line "STALE .bak". Its size, date and sha256 are printed. If it is the file the plan's measurements (P0)
# were made on, every case runs; if not, the cases that compare with P0's values are not run and are counted.
# The last line is "<n> case(s) not run", with why when n is not 0.
#   ET2's mutants, each must exit 1; all but 10 are applied to all six (the two blocks are pasted):
#   MUTANT=5 ...   the shared block's `moved` exits 1 instead of 3
#   MUTANT=6 ...   the form's sha256 is no longer compared
#   MUTANT=7 ...   a site in neither state is taken as original
#   MUTANT=8 ...   the .bak is made before the checks
#   MUTANT=9 ...   a site that is not the script's own must be original
#   MUTANT=10 ..   patch_dirhandle.py writes again when the fix is in and nothing is to be put back
#   MUTANT=11 ..   --form goes on to patch
#   MUTANT=12 ..   the method's file offset is taken from a constant (build 26404411's), not from its address
#   MUTANT=13 ..   the .bak is copied over one that is there
#   MUTANT=14 ..   a .bak is made when only putting back
#   MUTANT=15 ..   only exp-handle0 is put back
#   MUTANT=16 ..   the token in dirrec_nx's original form is taken as any token
#   MUTANT=17 ..   the first of several methods of the name is taken
#   A number that is none of these is REFUSED (exit 2).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${CS2_GAME_DIR:-$(bash "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)/common/wrappers.sh" find game 949230 2>/dev/null)/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II}"   # as repatch.sh finds it
MAN="$GAME/Cities2_Data/Managed"
for f in "$MAN/PDX.SDK.dll" "$MAN/PDX.SDK.dll.bak" "$MAN/Colossal.IO.dll" "$GAME/Cities2.exe"; do
  [ -f "$f" ] || { echo "SKIPPED: no game here (wants PDX.SDK.dll and its .bak, Colossal.IO.dll and Cities2.exe)"; exit 0; }
done
T="$(mktemp -d /tmp/patch-outcomes.XXXX)"
trap 'rm -rf "$T"' EXIT
M="${MUTANT:-0}"
SIX="patch_dirdel.py patch_delchild.py patch_dirrec_nx.py patch_delrec.py patch_delfile.py patch_dirhandle.py"
# the scripts under test are always a scratch copy, so that a mutant never touches the checkout
C="$T/c"; mkdir -p "$C"; cp -R "$REPO/patches" "$C/patches"
mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
mut() {  # <script> <sed expression> <a fixed string the mutated file must then hold>
  cp "$C/patches/$1" "$T/before.py"; sed -i '' "$2" "$C/patches/$1"
  { ! cmp -s "$T/before.py" "$C/patches/$1" && grep -qF -- "$3" "$C/patches/$1"; } || mutated
}
case "$M" in
  1) for s in patch_mkparent.py patch_lockbypass.py patch_longdelete.py patch_createfile.py patch_lockleak.py; do
       mut "$s" 's/^    sys.exit(3)$/    sys.exit(1)/' '    sys.exit(1)'
       [ "$(grep -c '^    sys.exit(3)$' "$C/patches/$s")" = 0 ] || mutated
     done ;;
  2) mut patch_lockleak.py 's/ob = own_ending(locate, PDX(orig), orig)/ob = locate(PDX(orig), orig)/' 'ob = locate(PDX(orig), orig)' ;;
  3) mut patch_longdelete.py 's/if refused: sys.exit(1 if seen else 3)/if refused: sys.exit(3)/' 'if refused: sys.exit(3)' ;;
  4) mut patch_createfile.py 's/if refused: sys.exit(1 if seen else 3)/if refused: sys.exit(3)/' 'if refused: sys.exit(3)' ;;
  5) for s in $SIX; do
       mut "$s" 's/^    sys.exit(3)$/    sys.exit(1)/' '    sys.exit(1)'
       [ "$(grep -c '^    sys.exit(3)$' "$C/patches/$s")" = 0 ] || mutated
     done ;;
  6) for s in $SIX; do mut "$s" 's/^    if h != METHODS\[key\]\[3\]:$/    if False:/' '    if False:'; done ;;
  7) for s in $SIX; do mut "$s" 's/if got is None or end != off + len(new): raise ValueError/if False: raise ValueError/' 'if False: raise ValueError'; done ;;
  8) for s in $SIX; do mut "$s" 's/^    d = bytearray(open(p, "rb").read())$/&; os.path.exists(p + ".bak") or shutil.copy2(p, p + ".bak")/' 'read()); os.path.exists'; done ;;
  9) for s in $SIX; do mut "$s" 's/^    back = \[.*$/&; any(v == "patched" for k, v in states.items() if k != sid) and moved("another site is patched")/' 'and moved("another site is patched")'; done ;;
  10) mut patch_dirhandle.py 's/^    if states\[sid\] == "patched" and not back:$/    if False:/' '    if False:' ;;
  11) for s in $SIX; do
        mut "$s" 's/^        sys.exit(code)$/        pass/' '        pass'
        [ "$(grep -c 'sys.exit(code)' "$C/patches/$s")" = 0 ] || mutated
      done ;;
  12) for s in $SIX; do mut "$s" 's/^    off = px.rva2off(px.rva_of(rid))$/    off = {"rdr": 0x1544b0, "rdi": 0x15466c, "df": 0x154078, "cdh": 0x16cc5c}[key]/' '"df": 0x154078'; done ;;
  13) for s in $SIX; do mut "$s" 's/^    if states\[sid\] == "original" and not os.path.exists(p + ".bak"):$/    if states[sid] == "original":/' '    if states[sid] == "original":'; done ;;
  14) for s in $SIX; do mut "$s" 's/^    if states\[sid\] == "original" and not os.path.exists(p + ".bak"):$/    if not os.path.exists(p + ".bak"):/' '    if not os.path.exists(p + ".bak"):'; done ;;
  15) for s in $SIX; do mut "$s" 's/^PUT_BACK = {"dirhandle": ("exp-handle0", "exp-errno0")}/PUT_BACK = {"dirhandle": ("exp-handle0",)}/' '("exp-handle0",)}'; done ;;
  16) for s in $SIX; do mut "$s" 's/^            got, end = match(px, il, off, orig)$/            got, end = match(px, il, off, [x if isinstance(x, bytes) else il[off + 2:off + 6] for x in orig])/' 'else il[off + 2:off + 6] for x in orig])'; done ;;
  17) for s in $SIX; do mut "$s" 's/^        if len(rids) != 1: moved(/        if len(rids) < 1: moved(/' '        if len(rids) < 1: moved('; done ;;
  0) ;;
  *) echo "REFUSED: no mutant $M in this file"; exit 2 ;;
esac
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
clone() { mkdir -p "$(dirname "$2")"; cp -c "$1" "$2" 2>/dev/null || cp "$1" "$2"; }
# snap <file>...: sha256 prefix and mtime in ns of each file, or "none": equal before and after = nothing written
snap() { /usr/bin/python3 -I -c 'import sys, os, hashlib
print(" ".join(hashlib.sha256(open(p, "rb").read()).hexdigest()[:16] + ":" + str(os.stat(p).st_mtime_ns)
               if os.path.exists(p) else "none" for p in sys.argv[1:]))' "$@"; }
run() { (cd "$T" && /usr/bin/python3 -I -B "$C/patches/$1" "${@:2}" >"$T/out" 2>&1); echo $?; }
# ilbyte <script> <dll> <method | lockleak> [tail]: the file offset of a one-byte opcode in that method's IL, found
# with the script's own resolver (the script loaded, its main not run), and the byte there: the IL's first byte,
# the first of its 21-byte tail with `tail`, or the first of the Log run patch_lockleak.py replaces
ilbyte() { (cd "$T" && /usr/bin/python3 -I -B -c 'import sys, importlib.util
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("m", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
d = bytearray(open(sys.argv[2], "rb").read()); px = m.PDX(d)
if sys.argv[3] == "lockleak":
    o = m.locate(px, d)[1]
else:
    b = m.body_at(d, px.rva2off(px.rva_of(px.method(m.TYPE, sys.argv[3]))))
    o = b["il"] + (b["size"] - 21 if sys.argv[4:] == ["tail"] else 0)
print(o, "%02x" % d[o])' "$C/patches/$1" "$2" "$3" "${4:-}"); }
nop() { printf '\000' | dd of="$1" bs=1 seek="$2" conv=notrunc 2>/dev/null; }

# --- what is read: cloned once into the scratch folder
G="$T/game"
clone "$MAN/PDX.SDK.dll" "$G/installed.dll"; clone "$MAN/PDX.SDK.dll.bak" "$G/unpatched.dll"
clone "$MAN/Colossal.IO.dll" "$G/other.dll"; clone "$GAME/Cities2.exe" "$G/Cities2.exe"
head -c 4096 /dev/zero > "$G/zeros.dll"
build="$(sed -n 's/^[[:space:]]*"buildid"[[:space:]]*"\([0-9]*\)".*/\1/p' "$GAME/../../appmanifest_949230.acf" 2>/dev/null | head -1)"
us="$(stat -f %z "$G/unpatched.dll")"; is="$(stat -f %z "$G/installed.dll")"
echo "game: ${build:+build $build, }$GAME"
echo "unpatched PDX.SDK.dll: the .bak, $us bytes, dated $(stat -f %Sm -t %Y-%m-%d "$MAN/PDX.SDK.dll.bak"), sha256 $(shasum -a 256 "$G/unpatched.dll" | cut -c1-16)"
if [ "$us" = "$is" ]; then echo "  (the installed file is the same size: the .bak is likely this build's)"
else echo "  (the installed file is $is bytes: the .bak is another build's, older than the installed one)"; fi

# each case runs on its own copy: <name> <source> -> $T/<name>/PDX.SDK.dll, printed
case_file() { local f="$T/$1/PDX.SDK.dll"; clone "$G/$2" "$f"; echo "$f"; }
for s in patch_mkparent.py patch_lockbypass.py patch_longdelete.py patch_createfile.py patch_lockleak.py; do
  n="${s%.py}"
  F="$(case_file "$n-installed" installed.dll)"; s0="$(snap "$F" "$F.bak")"
  check "$s on the installed, patched file: exit 0, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "0:$s0"
  F="$(case_file "$n-other" other.dll)"; s0="$(snap "$F" "$F.bak")"
  check "$s on another of the game's .NET files under the name: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  for src in zeros.dll Cities2.exe; do
    F="$(case_file "$n-${src%.*}" "$src")"; s0="$(snap "$F" "$F.bak")"
    check "$s on ${src/zeros.dll/a file of zeros} under the name: exit 1, nothing written" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "1:$s0"
  done
  case "$n" in
    patch_mkparent) meth=CreateFileStream; want=02 ;;
    patch_lockbypass) meth=GetError; want=02 ;;
    patch_longdelete) meth="DeleteLongPathFile tail"; want=02 ;;
    patch_createfile) meth=LongPathFileExists; want=02 ;;
    patch_lockleak) meth=lockleak; want=07 ;;
  esac
  F="$(case_file "$n-op" unpatched.dll)"
  read -r off byte <<< "$(ilbyte "$s" "$F" $meth)"
  check "$s: the opcode to replace in the unpatched file (${meth% tail}) is $want" "${byte:-?}" "$want"
  nop "$F" "$off"; s0="$(snap "$F" "$F.bak")"
  check "$s on the unpatched file with that opcode made 00: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
done

# --- the two scripts that change two methods and write once
for s in patch_longdelete.py patch_createfile.py; do
  n="${s%.py}"
  if [ "$n" = patch_longdelete ]; then first="DeleteLongPathFile tail"; second="DeleteLongPathDirectory tail"
  else first=LongPathFileExists; second=LongPathDirectoryExists; fi
  F="$(case_file "$n-second" unpatched.dll)"
  read -r off byte <<< "$(ilbyte "$s" "$F" $second)"
  nop "$F" "$off"; s0="$(snap "$F" "$F.bak")"
  check "$s, the second method's opcode made 00 ($byte at $off): exit 3, the first method not written" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  F="$(case_file "$n-first-patched" installed.dll)"
  read -r off byte <<< "$(ilbyte "$s" "$F" $second)"
  nop "$F" "$off"; s0="$(snap "$F" "$F.bak")"
  check "$s, the first method already patched and the second refused: exit 1, nothing written" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "1:$s0"
  F="$(case_file "$n-second-patched" installed.dll)"
  read -r off byte <<< "$(ilbyte "$s" "$F" $first)"
  nop "$F" "$off"; s0="$(snap "$F" "$F.bak")"
  check "$s, the first method refused and the second already patched: exit 1, nothing written (#24)" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "1:$s0"
done

# --- patch_lockleak.py --revert keeps its own endings: an exit 3 from reading the .bak is made 1
F="$(case_file revert-other installed.dll)"; clone "$G/other.dll" "$F.bak"; s0="$(snap "$F" "$F.bak")"
check "patch_lockleak.py --revert beside a .bak that is another of the game's .NET files: exit 1, nothing written" \
  "$(run patch_lockleak.py "$F" --revert):$(snap "$F" "$F.bak")" "1:$s0"
if [ "$us" != "$is" ]; then
  F="$(case_file revert-older installed.dll)"; clone "$G/unpatched.dll" "$F.bak"; s0="$(snap "$F" "$F.bak")"
  check "patch_lockleak.py --revert beside the older build's .bak: exit 1 (not this build's pristine form), nothing written" \
    "$(run patch_lockleak.py "$F" --revert):$(grep -c 'not the pristine form of this build' "$T/out"):$(snap "$F" "$F.bak")" "1:1:$s0"
else
  echo "NOTE  the .bak is this build's size: the case of --revert beside an older build's .bak is not run here"
fi

# === ET2 (docs/plans/errno-by-name.md section 4): the six errno scripts on clones of the game's unpatched mscorlib.dll
notrun=0; why=""
skip() { notrun=$((notrun + 1)); case "$why" in *"$1"*) ;; *) why="${why:+$why; }$1" ;; esac; }   # <why>: a case not run
P0=952703a7a04ee371          # the unpatched mscorlib.dll of build 26404411, on which P0 ran the fixed-offset scripts
NOTP0="the unpatched mscorlib.dll is not the file P0 measured"
# the test's own table, not read from the scripts. site <script>: the site's IL offset, its patched bytes, how
# many of them differ from the original, the method's key, and P0's fixed file offset of the site
site() {
  case "$1" in
    patch_dirdel.py)    echo "0x163 00 1 rdr 0x15461f" ;;
    patch_delchild.py)  echo "0x14d 26 1 rdr 0x154609" ;;
    patch_dirrec_nx.py) echo "0x26 38390100000000 6 rdr 0x1544e2" ;;
    patch_delrec.py)    echo "0x52 26 1 rdi 0x1546ca" ;;
    patch_delfile.py)   echo "0x1a 26 1 df 0x15409e" ;;
    patch_dirhandle.py) echo "0x38 2600 2 cdh 0x16cca0" ;;
  esac
}
# others <script>: the other known sites of its method, each "<id>:<IL offset>:<patched bytes>"
others() {
  case "$1" in
    patch_dirdel.py)    echo "dirrec_nx:0x26:38390100000000 delchild:0x14d:26" ;;
    patch_delchild.py)  echo "dirrec_nx:0x26:38390100000000 dirdel:0x163:00" ;;
    patch_dirrec_nx.py) echo "delchild:0x14d:26 dirdel:0x163:00" ;;
    patch_dirhandle.py) echo "exp-handle0:0x1a:2600 exp-errno0:0x40:072cf7000000" ;;
  esac
}
formsha() {                  # section 2.2's four sha256, as literals
  case "$1" in
    rdr) echo adbdd7f2bbc85487b5cb2f9ab47eae8fc7ea6d8c5c07088132248554a13b04ed ;;
    rdi) echo 76168eda1185ead91b1515e31ef2a1a556d2cd67846c631273466483a24de810 ;;
    df)  echo 950c3878fe13738fecb8d4320af973d24ad0fa08792183f8f13db7d6d05dc7af ;;
    cdh) echo 9b0db6be5eb495dea89ecc32aeb98bc28530ae26629fb2f1d9333879530f73b2 ;;
  esac
}
ref() {                      # what the fixed-offset script made of P0's file (the plan's section 4)
  case "$1" in
    patch_dirdel.py) echo 6f9d78c05a6ef357 ;; patch_delchild.py) echo 987aeb81ca033bf0 ;;
    patch_dirrec_nx.py) echo 8cc872288742f56a ;; patch_delrec.py) echo 236775e81db8a7f7 ;;
    patch_delfile.py) echo 3aef88cab7ec6079 ;; patch_dirhandle.py) echo cba53a210dfaa85c ;;
    all) echo a11ba27335a2b805 ;;
  esac
}
p0check() { if [ "$p0" = 1 ]; then check "$@"; else skip "$NOTP0"; fi; }   # a case that compares with P0's values
sha() { shasum -a 256 "$1" | cut -c1-16; }
peek() { xxd -s "$2" -l "$3" -p "$1" | tr -d '\n'; }                                               # <file> <offset> <length>
poke() { printf '%s' "$3" | xxd -r -p | dd of="$1" bs=1 seek="$2" conv=notrunc 2>/dev/null; }      # <file> <offset> <hex>
# differ <a> <b> <offset> <length>: "inside:<n>" when the two files differ in n bytes, all in those; else "elsewhere"
differ() { /usr/bin/python3 -I -c 'import sys
a = open(sys.argv[1], "rb").read(); b = open(sys.argv[2], "rb").read(); o, n = int(sys.argv[3]), int(sys.argv[4])
ok = len(a) == len(b) and a[:o] == b[:o] and a[o + n:] == b[o + n:]
print("inside:%d" % sum(x != y for x, y in zip(a[o:o + n], b[o:o + n])) if ok else "elsewhere")' "$@" 2>/dev/null; }
# printed <file>: the sha256 of what a --form run printed, less its final newline; "no-newline" if it does not end in one
printed() { /usr/bin/python3 -I -c 'import sys, hashlib
t = open(sys.argv[1], "rb").read()
print(hashlib.sha256(t[:-1]).hexdigest() if t.endswith(b"\n") and not t.endswith(b"\n\n") else "no-newline")' "$1"; }
# em <script> <dll> il | move | dupname: the script loaded (its run not run); the method found with the shared
# block and the method table, not with the errno block's own locate.
#   il:      the file offset of the IL of the script's method
#   move:    the method's body copied into the tail of .text and its address pointed at the copy, the old bytes
#            left in place; "<old body's file offset> <its length> <the copy's IL file offset>"
#   dupname: RemoveDirectoryInternal's Name in the method table made DeleteFile's; prints how many methods of
#            System.IO.FileSystem are then called DeleteFile and how many RemoveDirectoryInternal
em() { (cd "$T" && /usr/bin/python3 -I -B -c 'import sys, struct, importlib.util
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("m", sys.argv[1]); m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
own = sys.argv[1].rsplit("/", 1)[1][6:-3]; key = next(x for x in m.SITES if x[0] == own)[1]
d = bytearray(open(sys.argv[2], "rb").read()); px = m.PDX(d)
rid = px.method(*m.METHODS[key][:2]); b = m.body_at(d, px.rva2off(px.rva_of(rid)))
if sys.argv[3] == "il":
    print(b["il"])
elif sys.argv[3] == "move":
    n = b["end"] - b["hdr"]; start, rva = m.text_slack(px, n, d)
    d[start:start + n] = d[b["hdr"]:b["end"]]
    struct.pack_into("<I", d, px.rva_field_off(rid), rva)
    open(sys.argv[2], "wb").write(d); print(b["hdr"], n, start + b["il"] - b["hdr"])
else:
    t = m.METHODS["df"][0]; src = px.rva_field_off(px.method(t, "DeleteFile")) + 8
    dst = px.rva_field_off(px.method(t, "RemoveDirectoryInternal")) + 8
    d[dst:dst + 4] = d[src:src + 4]; open(sys.argv[2], "wb").write(d)
    names = [str(x.row.Name) for x in m.PDX(d).md.TypeDef.rows[px.types(t)[0] - 1].MethodList]
    print(names.count("DeleteFile"), names.count("RemoveDirectoryInternal"))' "$C/patches/$1" "$2" "$3" 2>/dev/null); }

# --- the section's own preconditions: which file is the unpatched one
U=ms-unpatched.dll; MSI="$MAN/mscorlib.dll"
if [ ! -f "$MSI" ]; then
  echo "NOTE  the game has no mscorlib.dll: ET2 is not run"; skip "the game has no mscorlib.dll"
  echo "$fails failure(s)"; echo "$notrun case(s) not run: $why"; [ "$fails" = 0 ]; exit $?
fi
if [ -f "$MSI.bak" ] && [ "$(stat -f %z "$MSI.bak")" = "$(stat -f %z "$MSI")" ] && [ "$(cmp -l "$MSI.bak" "$MSI" | wc -l | tr -d ' ')" -lt 64 ]; then
  clone "$MSI.bak" "$G/$U"; usrc="the .bak"; udate="$(stat -f %Sm -t %Y-%m-%d "$MSI.bak")"
else
  echo "STALE .bak: mscorlib.dll.bak is not there, or is not the installed file's size, or differs from it in 64 bytes or more; the installed file is taken as the unpatched one"
  clone "$MSI" "$G/$U"; usrc="the installed file"; udate="$(stat -f %Sm -t %Y-%m-%d "$MSI")"
fi
msha="$(sha "$G/$U")"
echo "unpatched mscorlib.dll: $usrc, $(stat -f %z "$G/$U") bytes, dated $udate, sha256 $msha"
if [ "$msha" = "$P0" ]; then p0=1; echo "  (the file P0 measured: every case runs)"
else p0=0; echo "NOTE  not the file P0 measured ($P0): the cases that compare with P0's values are not run"; fi
head -c 1000000 "$G/$U" > "$G/cut.dll"
# the order: read from repatch.sh, the scripts it runs under CS2_ERRNO_PATCHES=1
ORDER="$(awk '/^if \[ "\$ERRNO_PATCHES" = 1 \]; then$/ {f = 1} /^else/ {f = 0} f && /^run patch_/ {print $2}' "$REPO/repatch.sh" | tr '\n' ' ')"
check "repatch.sh runs the six, and only them, under CS2_ERRNO_PATCHES=1" \
  "$(for s in $ORDER; do echo "$s"; done | LC_ALL=C sort | tr '\n' ' ')" "$(for s in $SIX; do echo "$s"; done | LC_ALL=C sort | tr '\n' ' ')"
ms_file() { local f="$T/$1/mscorlib.dll"; clone "$G/$2" "$f"; echo "$f"; }   # <name> <source> -> $T/<name>/mscorlib.dll

for s in $SIX; do
  n="${s%.py}"; read -r soff shex sdiff key fixed <<< "$(site "$s")"; slen=$(( ${#shex} / 2 ))
  ilo="$(em "$s" "$G/$U" il)"; off=$(( ${ilo:-0} + soff ))
  p0check "$s: its site is at the fixed-offset script's file offset (P0)" "$off" "$(( fixed ))"
  # on the unpatched file, with no .bak beside it
  F="$(ms_file "$n-alone" $U)"
  check "$s on the unpatched file: exit 0, its site holds the patched bytes, nothing differs outside it, a .bak of the file as it was" \
    "$(run "$s" "$F"):$(peek "$F" "$off" "$slen"):$(differ "$G/$U" "$F" "$off" "$slen"):$(sha "$F.bak")" "0:$shex:inside:$sdiff:$msha"
  alone="$(sha "$F")"
  p0check "$s: that file is the one the fixed-offset script gave (P0)" "$alone" "$(ref "$s")"
  rm -f "$F.bak"; s0="$(snap "$F" "$F.bak")"
  check "$s, a second run with the .bak removed: exit 0, nothing written, no .bak made" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "0:$s0"
  # beside a .bak that is already there
  F="$(ms_file "$n-oldbak" $U)"; head -c 100 /dev/zero > "$F.bak"; b0="$(snap "$F.bak")"
  check "$s beside a .bak that is already there: exit 0, patched, the .bak as it was" "$(run "$s" "$F"):$(sha "$F"):$(snap "$F.bak")" "0:$alone:$b0"
  # the folder as the argument
  D="$T/$n-folder"; F="$D/Cities2_Data/Managed/mscorlib.dll"; clone "$G/$U" "$F"
  check "$s with the game's folder as the argument: exit 0, the same file as with the file" "$(run "$s" "$D"):$(sha "$F")" "0:$alone"
  # --form
  F="$(ms_file "$n-form" $U)"; s0="$(snap "$F" "$F.bak")"; rc="$(run "$s" --form "$F")"
  check "$s --form on the unpatched file: exit 0, nothing written, the sha256 of what it prints is the plan's ($key)" \
    "$rc:$(snap "$F" "$F.bak"):$(printed "$T/out")" "0:$s0:$(formsha "$key")"
  F="$(ms_file "$n-form-first" $U)"; poke "$F" "$ilo" 00; s0="$(snap "$F" "$F.bak")"; rc="$(run "$s" --form "$F")"
  check "$s --form, the method's first IL byte made 00 (a form can be made): exit 3, the first line is 00, as many lines as the committed text, nothing written" \
    "$rc:$(head -1 "$T/out"):$(wc -l < "$T/out" | tr -d ' '):$(snap "$F" "$F.bak")" "3:00:$(wc -l < "$C/patches/errno-forms/$key.txt" | tr -d ' '):$s0"
  F="$(ms_file "$n-form-own" $U)"; poke "$F" "$off" 2a; s0="$(snap "$F" "$F.bak")"; rc="$(run "$s" --form "$F")"
  check "$s --form, its own site made 2a (no form can be made): exit 3, the first line begins with #, no site line, nothing written" \
    "$rc:$(head -1 "$T/out" | cut -c1):$(grep -c '^<' "$T/out"):$(grep -c UNEXPECTED "$T/out"):$(snap "$F" "$F.bak")" "3:#:0:0:$s0"
  # refusals: exit 3, nothing written, no .bak
  F="$(ms_file "$n-other" other.dll)"; s0="$(snap "$F" "$F.bak")"
  check "$s on Colossal.IO.dll under the name: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  F="$(ms_file "$n-first" $U)"; poke "$F" "$ilo" 00; s0="$(snap "$F" "$F.bak")"
  check "$s, the method's first IL byte made 00: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  F="$(ms_file "$n-own" $U)"; poke "$F" "$off" 2a; s0="$(snap "$F" "$F.bak")"
  check "$s, its own site made 2a: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  for o in $(others "$s"); do
    IFS=: read -r oid oil ohex <<< "$o"; ooff=$(( ${ilo:-0} + oil ))
    F="$(ms_file "$n-$oid" $U)"; poke "$F" "$ooff" 2a; s0="$(snap "$F" "$F.bak")"
    check "$s, another site of its method ($oid) made 2a: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
    F="$(ms_file "$n-own-$oid" $U)"; poke "$F" "$off" "$shex"; poke "$F" "$ooff" 2a; s0="$(snap "$F" "$F.bak")"
    check "$s, its own site patched and another site ($oid) made 2a: exit 3, not \"already patched\", nothing written" \
      "$(run "$s" "$F"):$(grep -c 'already patched' "$T/out"):$(snap "$F" "$F.bak")" "3:0:$s0"
  done
  if [ "$key" = rdr ]; then
    F="$(ms_file "$n-token" $U)"; poke "$F" $(( ${ilo:-0} + 0x26 + 2 )) d5660006; s0="$(snap "$F" "$F.bak")"
    check "$s, dirrec_nx's call made to name another method (token 0x060066d5): exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  fi
  if [ "$s" = patch_delfile.py ] || [ "$s" = patch_delrec.py ]; then
    F="$(ms_file "$n-dupname" $U)"
    check "$s: RemoveDirectoryInternal's name made DeleteFile's in the method table (two DeleteFile, no RemoveDirectoryInternal)" "$(em "$s" "$F" dupname)" "2 0"
    s0="$(snap "$F" "$F.bak")"
    check "$s on that file: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  fi
  # not a .NET file: exit 1
  for src in zeros.dll Cities2.exe cut.dll; do
    F="$(ms_file "$n-${src%.*}" "$src")"; s0="$(snap "$F" "$F.bak")"
    case "$src" in zeros.dll) what="a file of zeros" ;; cut.dll) what="the unpatched file's first 1,000,000 bytes" ;; *) what="$src" ;; esac
    check "$s on $what under the name: exit 1, nothing written" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "1:$s0"
  done
done
# the four files on which a fixed-offset script said "already patched" (P0, item 3)
for pair in patch_dirdel.py:System.Data.dll patch_dirdel.py:Unity.RenderPipelines.HighDefinition.Runtime.dll \
            patch_dirdel.py:UnityEngine.UIElementsModule.dll patch_delfile.py:System.Xml.dll; do
  s="${pair%%:*}"; o="${pair#*:}"
  if [ -f "$MAN/$o" ]; then
    F="$T/p0-$o/mscorlib.dll"; clone "$MAN/$o" "$F"; s0="$(snap "$F" "$F.bak")"
    check "$s on $o under the name: exit 3, nothing written, no .bak" "$(run "$s" "$F"):$(snap "$F" "$F.bak")" "3:$s0"
  else echo "NOTE  the game has no $o: $s on it is not run"; skip "the game has no $o"; fi
done
# all six on one clone, in repatch.sh's order and in reverse
REV="$(for s in $ORDER; do echo "$s"; done | tail -r | tr '\n' ' ')"
F="$(ms_file all-order $U)"; rcs=""; for s in $ORDER; do rcs="$rcs$(run "$s" "$F")"; done
check "all six on one clone, in repatch.sh's order: exit 0 each" "$rcs" 000000
F2="$(ms_file all-reverse $U)"; rcs=""; for s in $REV; do rcs="$rcs$(run "$s" "$F2")"; done
check "all six on one clone, in reverse: exit 0 each" "$rcs" 000000
check "all six: one file for both orders, and not the unpatched one" "$(sha "$F"):$([ "$(sha "$F")" != "$msha" ] && echo changed)" "$(sha "$F2"):changed"
p0check "all six: that file is the one the fixed-offset scripts gave (P0)" "$(sha "$F")" "$(ref all)"
rm -f "$F.bak"
for s in $SIX; do
  read -r soff shex sdiff key fixed <<< "$(site "$s")"; s0="$(snap "$F" "$F.bak")"; rc="$(run "$s" --form "$F")"
  check "$s --form on the file with all six: exit 0, nothing written, the same sha256 ($key)" \
    "$rc:$(snap "$F" "$F.bak"):$(printed "$T/out")" "0:$s0:$(formsha "$key")"
done
# a moved body: the three whose body fits the tail of .text
for s in patch_delfile.py patch_delrec.py patch_dirhandle.py; do
  n="${s%.py}"; read -r soff shex sdiff key fixed <<< "$(site "$s")"; slen=$(( ${#shex} / 2 ))
  F="$(ms_file "$n-moved" $U)"
  read -r ohdr blen nil <<< "$(em "$s" "$F" move)"; old0="$(peek "$F" "${ohdr:-0}" "${blen:-1}")"
  check "$s, the method's body moved to the tail of .text: exit 0, the site patched in the copy, the old place as it was" \
    "$(run "$s" "$F"):$(peek "$F" $(( ${nil:-0} + soff )) "$slen"):$(peek "$F" "${ohdr:-0}" "${blen:-1}")" "0:$shex:$old0"
done
# patch_dirhandle.py and the experiment's two edits
s=patch_dirhandle.py; alone="$(sha "$T/patch_dirhandle-alone/mscorlib.dll")"; ilo="$(em "$s" "$G/$U" il)"
place_exp() { for o in $(others patch_dirhandle.py); do IFS=: read -r oid oil ohex <<< "$o"; poke "$1" $(( ${ilo:-0} + oil )) "$ohex"; done; }
F="$(ms_file dirhandle-exp $U)"; place_exp "$F"; h0="$(sha "$F")"
check "$s, the experiment's two edits placed: 7 bytes differ from the unpatched file" "$(cmp -l "$G/$U" "$F" | wc -l | tr -d ' ')" 7
check "$s, with the two edits: exit 0, both back and the fix in (the file $s alone gives), a .bak of the file as it was" \
  "$(run "$s" "$F"):$(grep -c '^put back ' "$T/out"):$(sha "$F"):$(sha "$F.bak")" "0:2:$alone:$h0"
p0check "$s, with the two edits: that file is the one the fixed-offset script gave (P0)" "$(sha "$F")" "$(ref "$s")"
F="$(ms_file dirhandle-exp-fixed $U)"; run "$s" "$F" >/dev/null; rm -f "$F.bak"; place_exp "$F"
check "$s, the fix in and the two edits placed: exit 0, the edits put back, no .bak made" \
  "$(run "$s" "$F"):$(grep -c '^put back ' "$T/out"):$(sha "$F"):$([ -e "$F.bak" ] && echo bak || echo none)" "0:2:$alone:none"

check "no __pycache__ left in the scratch copy's patches" "$(find "$C/patches" -name __pycache__ | wc -l | tr -d ' ')" 0
echo "$fails failure(s)"
echo "$notrun case(s) not run${why:+: $why}"
[ "$fails" = 0 ]
