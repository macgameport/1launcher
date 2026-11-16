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
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${CS2_GAME_DIR:-$HOME/Applications/CS2dxmt11.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II}"
MAN="$GAME/Cities2_Data/Managed"
for f in "$MAN/PDX.SDK.dll" "$MAN/PDX.SDK.dll.bak" "$MAN/Colossal.IO.dll" "$GAME/Cities2.exe"; do
  [ -f "$f" ] || { echo "SKIPPED: no game here (wants PDX.SDK.dll and its .bak, Colossal.IO.dll and Cities2.exe)"; exit 0; }
done
T="$(mktemp -d /tmp/patch-outcomes.XXXX)"
trap 'rm -rf "$T"' EXIT
M="${MUTANT:-0}"
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

check "no __pycache__ left in the scratch copy's patches" "$(find "$C/patches" -name __pycache__ | wc -l | tr -d ' ')" 0
echo "$fails failure(s)"
[ "$fails" = 0 ]
