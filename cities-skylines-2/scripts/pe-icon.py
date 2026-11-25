#!/usr/bin/env python3
# pe-icon.py — pull the largest image of a PE binary's first icon and write it beside <out-base>.
# Shared by make-shortcut.sh (Cities2.exe) and make-steam-shortcut.sh (steam.exe).
# Usage: python3 pe-icon.py <exe> <out-base>   -> writes <out-base>.png or <out-base>.ico,
# prints "png"/"ico" on success, exits non-zero with a message on stderr otherwise.
# Pure stdlib: no pefile, no icoutils.
import struct, sys
if len(sys.argv) != 3: sys.exit('usage: pe-icon.py <exe> <out-base>')
src, out = sys.argv[1], sys.argv[2]
d = open(src, 'rb').read()

pe = struct.unpack_from('<I', d, 0x3c)[0]
if d[pe:pe+4] != b'PE\0\0': sys.exit('not a PE')
nsec, optsz = struct.unpack_from('<HH', d, pe + 6), None
nsec = struct.unpack_from('<H', d, pe + 6)[0]
optsz = struct.unpack_from('<H', d, pe + 20)[0]
opt = pe + 24
magic = struct.unpack_from('<H', d, opt)[0]
ddoff = opt + (112 if magic == 0x20b else 96)          # PE32+ vs PE32
res_rva, res_size = struct.unpack_from('<II', d, ddoff + 2 * 8)   # DataDirectory[2] = resources
if not res_rva: sys.exit('no resource directory')

sections = []
sh = opt + optsz
for i in range(nsec):
    o = sh + i * 40
    # section header: Name[8] VirtualSize@8 VirtualAddress@12 SizeOfRawData@16 PointerToRawData@20
    vsz = struct.unpack_from('<I', d, o + 8)[0]
    va, rawsz, rawptr = struct.unpack_from('<III', d, o + 12)
    sections.append((va, max(vsz, rawsz), rawptr))

def to_off(rva):
    for va, sz, ptr in sections:
        if va <= rva < va + sz:
            return ptr + (rva - va)
    return None

base = to_off(res_rva)

def entries(off):
    nnamed, nid = struct.unpack_from('<HH', d, off + 12)
    for i in range(nnamed + nid):
        eid, child = struct.unpack_from('<II', d, off + 16 + i * 8)
        yield eid, child

def leaves(rtype):   # (resource id, data) of every resource of a type, in the directory's own order
    for eid, child in entries(base):                        # level 1: resource type
        if eid != rtype or not (child & 0x80000000):
            continue
        for rid, c2 in entries(base + (child & 0x7fffffff)):  # level 2: resource id
            if not (c2 & 0x80000000):
                continue
            for _, c3 in entries(base + (c2 & 0x7fffffff)):   # level 3: language
                if c3 & 0x80000000:
                    continue
                drva, dsz = struct.unpack_from('<II', d, base + c3)
                o = to_off(drva)
                if o:
                    yield rid, (o, dsz)

# A program may hold several icons, and Windows shows the first group (RT_GROUP_ICON == 14): steam.exe's
# other two are Steam with a dot and with a microphone on it, and the microphone's image is the largest of all.
icons = list(leaves(3))                                     # RT_ICON == 3
group = next((g for _, g in leaves(14)), None)
wanted = set()
if group:
    n = struct.unpack_from('<H', d, group[0] + 4)[0]
    wanted = {struct.unpack_from('<H', d, group[0] + 6 + 14 * i + 12)[0] for i in range(n)}
candidates = [i for rid, i in icons if rid in wanted] or [i for _, i in icons]
best = max(candidates, key=lambda i: i[1], default=None)

if not best: sys.exit('no RT_ICON found')
off, size = best
blob = d[off:off + size]

if blob[:8] == b'\x89PNG\r\n\x1a\n':                   # modern icons embed PNG directly
    open(out + '.png', 'wb').write(blob)
    print('png')
else:                                                   # legacy DIB — wrap as a one-image .ico
    w = struct.unpack_from('<i', blob, 4)[0]
    h = struct.unpack_from('<i', blob, 8)[0] // 2
    hdr = struct.pack('<HHH', 0, 1, 1) + struct.pack('<BBBBHHII',
        w if w < 256 else 0, h if h < 256 else 0, 0, 0, 1, 32, len(blob), 22)
    open(out + '.ico', 'wb').write(hdr + blob)
    print('ico')
