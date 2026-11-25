#!/bin/bash
# test-pe-icon.sh -- pe-icon.py takes the largest image of a program's FIRST icon group, the icon Windows shows.
# (S734M wore Steam's icon with a microphone: steam.exe has three groups, and the largest image of any group was
# taken.) The programs are fixtures written here, with the smallest resource section that holds icons.
#   bash scripts/test-pe-icon.sh      exit 0 = every case passed
#   MUTANT=1 ...   every icon of the program is a candidate, as it was; must exit 1
#   MUTANT=2 ...   the group's first image is taken, not its largest; must exit 1
#   MUTANT=3 ...   the fallback for a program with no group is dropped; must exit 1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d /tmp/pe-icon-test.XXXX)"; trap 'rm -rf "$T"' EXIT
cp "$HERE/pe-icon.py" "$T/pe-icon.py"; P="$T/pe-icon.py"
case "${MUTANT:-0}" in
  0) ;;
  1) sed -i '' 's/ if rid in wanted\]/]/' "$P" ;;
  2) sed -i '' 's/^best = max(.*/best = candidates[0] if candidates else None/' "$P" ;;
  3) sed -i '' 's/ or \[i for _, i in icons\]$//' "$P" ;;
  *) echo "REFUSED: no mutant $MUTANT"; exit 2 ;;
esac
[ "${MUTANT:-0}" = 0 ] || ! cmp -s "$HERE/pe-icon.py" "$P" || { echo "REFUSED: mutant did not apply"; exit 2; }
fails=0
check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi; }

# fixture <out> <icons: id=size,...> <groups: id:icon+icon,...>: image <id> is a PNG signature, then "icon<id>", padded to size
cat > "$T/fixture.py" <<'PY'
import struct, sys
out, icons, groups = sys.argv[1:]
res = {}
for x in filter(None, icons.split(',')):
    i, n = map(int, x.split('='))
    res.setdefault(3, {})[i] = (b'\x89PNG\r\n\x1a\n' + b'icon%d.' % i).ljust(n, b'.')
for x in filter(None, groups.split(',')):
    g, l = x.split(':'); ids = [int(i) for i in l.split('+')]
    res.setdefault(14, {})[int(g)] = struct.pack('<HHH', 0, 1, len(ids)) + b''.join(
        struct.pack('<BBBBHHIH', 0, 0, 0, 0, 1, 32, 0, i) for i in ids)
RVA, RAW = 0x1000, 0x200
blob = bytearray()
def directory(keys):
    at = len(blob)
    blob.extend(struct.pack('<IIHHHH', 0, 0, 0, 0, 0, len(keys)) + b'\0' * 8 * len(keys))
    return at
def put(at, i, key, child): struct.pack_into('<II', blob, at + 16 + 8 * i, key, child)
root = directory(sorted(res)); data = []
for a, t in enumerate(sorted(res)):
    l2 = directory(sorted(res[t])); put(root, a, t, l2 | 0x80000000)
    for b, r in enumerate(sorted(res[t])):
        l3 = directory([1033]); put(l2, b, r, l3 | 0x80000000)
        e = len(blob); blob.extend(b'\0' * 16); put(l3, 0, 1033, e); data.append((e, res[t][r]))
for e, v in data:
    struct.pack_into('<IIII', blob, e, RVA + len(blob), len(v), 0, 0); blob.extend(v)
opt = bytearray(240); struct.pack_into('<H', opt, 0, 0x20b); struct.pack_into('<II', opt, 112 + 16, RVA, len(blob))
f = bytearray(64); f[:2] = b'MZ'; struct.pack_into('<I', f, 0x3c, 64)
f += b'PE\0\0' + struct.pack('<HHIIIHH', 0x8664, 1, 0, 0, 0, len(opt), 0) + opt
f += b'.rsrc\0\0\0' + struct.pack('<IIIIIIHHI', len(blob), RVA, len(blob), RAW, 0, 0, 0, 0, 0)
open(out, 'wb').write(f.ljust(RAW, b'\0') + blob)
PY
pick() {  # <icons> <groups>: which icon is taken, or "none"
  rm -f "$T/o.png"; python3 "$T/fixture.py" "$T/p.exe" "$1" "$2" || { echo fixture; return; }
  python3 "$P" "$T/p.exe" "$T/o" >/dev/null 2>&1 || { echo none; return; }
  LC_ALL=C grep -aoE 'icon[0-9]+' "$T/o.png" | head -1
}
check "three groups: the first, though a later one has the largest image" "$(pick 1=100,2=300,3=100,4=900 101:1+2,102:3+4)" icon2
check "its largest image, whatever the order"                             "$(pick 1=300,2=100 101:1+2)" icon1
check "one group: its largest image"                                      "$(pick 1=100,2=300 101:1+2)" icon2
check "no group: the largest image of all"                                "$(pick 1=100,2=300 '')" icon2
check "a group that names no icon here: the largest image of all"         "$(pick 1=100,2=300 101:9)" icon2
check "no icon: refused"                                                  "$(pick '' 101:9)" none
[ "$fails" = 0 ] && echo "all passed"; [ "$fails" = 0 ]
