#!/usr/bin/env python3
"""patch_delfile.py — make mscorlib System.IO.FileSystem.DeleteFile tolerant of Wine's garbage
GetLastError. UnityDeleteFile fails on Wine with a garbage errno (not 2/FILE_NOT_FOUND), so File.Delete
throws spuriously (the delete really succeeded or the file was already gone) and aborts the mod download
before the content .zip is fetched. Change the throw (IL 0x1a, 0x7a) to pop (0x26); it then falls to the
ret after it (IL 0x1b) -> delete failure treated as done. Same graceful class as patch_dirhandle.

The method is found by name and its whole IL is matched (the sha256 of its by-name form,
docs/plans/errno-by-name.md 2.2) before anything is written; no file offset is read. Site: DeleteFile
IL 0x1a, as on build 26404411. Exit 0 = the fix is in place, 3 = not for this build (nothing written, no .bak).
`--form <path>` prints the by-name form of the method in that file and writes nothing; compare it with
patches/errno-forms/df.txt. Idempotent; makes a .bak when it first patches and none is there.
Usage: patch_delfile.py [--form] <path-to-mscorlib.dll | game-dir>"""
# ---- shared by-name resolver + strict IL checker (identical in all five PDX patchers) ----
import sys, os, re, shutil, struct

sys.dont_write_bytecode = True  # dnfile ships beside this script, in _vendor: leave no __pycache__ in it
sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), "_vendor"))
import dnfile


def die(msg):
    print(f"UNEXPECTED: {msg} — refusing to patch (game updated? re-derive)")
    sys.exit(1)


def moved(msg):
    """The same line, exit 3: nothing of this patch is in the file, and what the file holds (a name, a body,
    the room for one) is not what this script can patch. Not for this build; nothing is written."""
    print(f"UNEXPECTED: {msg} — refusing to patch (game updated? re-derive)")
    sys.exit(3)


def find_dll(arg):
    if os.path.isdir(arg):
        for c in (os.path.join(arg, "Cities2_Data", "Managed", "PDX.SDK.dll"), os.path.join(arg, "PDX.SDK.dll")):
            if os.path.isfile(c):
                return c
    if os.path.isfile(arg):
        return arg
    sys.exit(f"PDX.SDK.dll not found: {arg}")


def backup_and_write(p, data):
    if not os.path.exists(p + ".bak"):
        shutil.copy2(p, p + ".bak")
    with open(p, "wb") as f:
        f.write(bytes(data))


# operand sizes per ECMA-335 III; 'S' = switch. Anything absent is an unknown opcode.
_OP1 = {}
for _o in list(range(0x00, 0x0e)) + [0x14, 0x15] + list(range(0x16, 0x1f)) + [0x25, 0x26, 0x2a] + \
        list(range(0x46, 0x6f)) + [0x76, 0x7a, 0x8e] + list(range(0x82, 0x8c)) + list(range(0x90, 0xa3)) + \
        list(range(0xb3, 0xbb)) + [0xc3] + list(range(0xd1, 0xdd)) + [0xdf, 0xe0]:
    _OP1[_o] = 0
for _o in (0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x1f, 0xde):
    _OP1[_o] = 1
for _o in list(range(0x2b, 0x38)):
    _OP1[_o] = 1
for _o in [0x20, 0x22, 0x27, 0x28, 0x29, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x79, 0x7b, 0x7c, 0x7d, 0x7e,
           0x7f, 0x80, 0x81, 0x8c, 0x8d, 0x8f, 0xa3, 0xa4, 0xa5, 0xc2, 0xc6, 0xd0, 0xdd] + list(range(0x38, 0x45)):
    _OP1[_o] = 4
_OP1[0x21] = 8; _OP1[0x23] = 8; _OP1[0x45] = "S"
_OP2 = {0x00: 0, 0x01: 0, 0x02: 0, 0x03: 0, 0x04: 0, 0x05: 0, 0x06: 4, 0x07: 4, 0x09: 2, 0x0a: 2, 0x0b: 2, 0x0c: 2,
        0x0d: 2, 0x0e: 2, 0x0f: 0, 0x11: 0, 0x12: 1, 0x13: 0, 0x14: 0, 0x15: 4, 0x16: 4, 0x17: 0, 0x18: 0, 0x19: 1,
        0x1a: 0, 0x1c: 4, 0x1d: 0, 0x1e: 0}
_BR1 = set(range(0x2b, 0x38)) | {0xde}
_BR4 = set(range(0x38, 0x45)) | {0xdd}
_TERM1 = {0x2a, 0x7a, 0x2b, 0x38, 0xdd, 0xde, 0xdc, 0x27}
_TERM2 = {0x1a, 0x11}


def decode(il):
    """Strict linear decode. -> list of (off, opcode, operand, next_off, branch_targets). Raises ValueError."""
    out, i = [], 0
    while i < len(il):
        off = i; op = il[i]; i += 1
        if op == 0xFE:
            if i >= len(il): raise ValueError(f"truncated 0xfe at IL {off:#x}")
            op2 = il[i]; i += 1
            if op2 not in _OP2: raise ValueError(f"unknown opcode fe {op2:02x} at IL {off:#x}")
            n = _OP2[op2]; opc = 0xFE00 | op2
        else:
            if op not in _OP1: raise ValueError(f"unknown opcode {op:02x} at IL {off:#x}")
            n = _OP1[op]; opc = op
        tg = []
        if n == "S":
            if i + 4 > len(il): raise ValueError(f"switch runs off body at IL {off:#x}")
            cnt = struct.unpack_from("<I", il, i)[0]; i += 4
            if i + 4 * cnt > len(il): raise ValueError(f"switch table runs off body at IL {off:#x}")
            rel = struct.unpack_from(f"<{cnt}i", il, i); i += 4 * cnt
            tg = [i + r for r in rel]; operand = cnt
        else:
            if i + n > len(il): raise ValueError(f"operand runs off body at IL {off:#x}")
            raw = bytes(il[i:i + n]); i += n
            operand = int.from_bytes(raw, "little") if n else None
            if op in _BR1 and opc == op: tg = [i + struct.unpack("<b", raw)[0]]
            if op in _BR4 and opc == op: tg = [i + struct.unpack("<i", raw)[0]]
        out.append((off, opc, operand, i, tg))
    return out


def check_body(il, eh):
    try:
        return _check_body(il, eh)
    except ValueError as e:
        die(f"IL does not decode cleanly: {e}")


def _check_body(il, eh):
    """Mono-style linear validity: every byte decodes, ends exactly at the body end on a terminator,
    every branch target and EH boundary lands on an instruction boundary."""
    ins = decode(il)
    bounds = {o for o, *_ in ins} | {len(il)}
    last = ins[-1][1]
    if not (last in _TERM1 or (last >> 8 == 0xFE and last & 0xFF in _TERM2)):
        raise ValueError(f"last instruction {last:#x} is not a terminator")
    for o, opc, _, _, tg in ins:
        for t in tg:
            if t not in bounds or t == len(il): raise ValueError(f"branch at IL {o:#x} -> {t:#x} not an instruction")
    for (flags, toff, tlen, hoff, hlen, _x) in eh:
        for b in (toff, toff + tlen, hoff, hoff + hlen):
            if b not in bounds: raise ValueError(f"EH boundary {b:#x} not on an instruction")
    return ins


class PDX:
    def __init__(self, data):
        self.data = data
        self.pe = dnfile.dnPE(data=bytes(data))
        self.md = self.pe.net.mdtables
        self.nested = {}
        if self.md.NestedClass:
            for n in self.md.NestedClass.rows:
                self.nested[n.NestedClass.row_index] = n.EnclosingClass.row_index
        self.mparent = {}
        for ti, ty in enumerate(self.md.TypeDef.rows):
            try:
                for m in ty.MethodList: self.mparent[m.row_index] = ti + 1
            except Exception:
                pass

    # -- names --
    def tdname(self, ti):
        ty = self.md.TypeDef.rows[ti - 1]; enc = self.nested.get(ti)
        if enc: return self.tdname(enc) + "/" + str(ty.TypeName)
        ns = str(ty.TypeNamespace or "")
        return (ns + "." if ns else "") + str(ty.TypeName)

    def trname(self, row):
        ns = str(getattr(row, "TypeNamespace", "") or "")
        return (ns + "." if ns else "") + str(getattr(row, "TypeName", "?"))

    def tokname(self, tok):
        tbl, rid = tok >> 24, tok & 0xFFFFFF
        try:
            if tbl == 0x06 and 1 <= rid <= len(self.md.MethodDef.rows):
                return self.tdname(self.mparent[rid]) + "::" + str(self.md.MethodDef.rows[rid - 1].Name)
            if tbl == 0x0A and 1 <= rid <= len(self.md.MemberRef.rows):
                r = self.md.MemberRef.rows[rid - 1]
                return self.trname(r.Class.row) + "::" + str(r.Name)
            if tbl == 0x04 and 1 <= rid <= len(self.md.Field.rows):
                return "field " + str(self.md.Field.rows[rid - 1].Name)
            if tbl == 0x70:
                return '"' + str(self.pe.net.user_strings.get(rid).value) + '"'
            if tbl == 0x2B and 1 <= rid <= len(self.md.MethodSpec.rows):
                m = self.md.MethodSpec.rows[rid - 1].Method.row
                return "spec " + str(getattr(m, "Name", "?"))
        except Exception:
            pass
        return f"<{tok:#010x}>"

    def sig(self, row):
        s = row.Signature
        return bytes(s.value if hasattr(s, "value") else s)

    # -- lookups --
    def types(self, pattern):
        rx = re.compile(pattern)
        return [ti + 1 for ti in range(len(self.md.TypeDef.rows)) if rx.fullmatch(self.tdname(ti + 1))]

    def method(self, type_pattern, name):
        tis = self.types(type_pattern)
        if len(tis) != 1: moved(f"type /{type_pattern}/ matched {len(tis)} types")
        rids = [m.row_index for m in self.md.TypeDef.rows[tis[0] - 1].MethodList if str(m.row.Name) == name]
        if len(rids) != 1: moved(f"{self.tdname(tis[0])}::{name} matched {len(rids)} methods")
        return rids[0]

    def memberref(self, cls, name, sig):
        hits = [i + 1 for i, r in enumerate(self.md.MemberRef.rows)
                if str(r.Name) == name and self.trname(r.Class.row) == cls and self.sig(r) == sig]
        if not hits: moved(f"no MemberRef {cls}::{name} with sig {sig.hex()}")
        return 0x0A000000 | hits[0]

    # -- PE / bodies (Mono maps an RVA against each section's RAW size) --
    def rva2off(self, rva):
        for s in self.pe.sections:
            if s.VirtualAddress <= rva < s.VirtualAddress + s.SizeOfRawData:
                return rva - s.VirtualAddress + s.PointerToRawData
        return None

    def off2rva(self, off):
        for s in self.pe.sections:
            if s.PointerToRawData <= off < s.PointerToRawData + s.SizeOfRawData:
                return off - s.PointerToRawData + s.VirtualAddress
        return None

    def rva_field_off(self, rid):
        t = self.md.MethodDef
        return t.file_offset + t.row_size * (rid - 1)  # RVA is column 0

    def rva_of(self, rid, data=None):
        return struct.unpack_from("<I", data if data is not None else self.data, self.rva_field_off(rid))[0]


def body_at(data, off):
    """Parse a method body at file offset. -> dict(hdr, fat, il, size, end, eh, flags, maxstack, lvsig)."""
    b0 = data[off]
    if b0 & 3 == 2:
        return dict(hdr=off, fat=False, il=off + 1, size=b0 >> 2, end=off + 1 + (b0 >> 2), eh=[], flags=2,
                    maxstack=8, lvsig=0)
    if b0 & 3 != 3: raise ValueError(f"no method header at {off:#x}")
    flags, ms, size, lv = struct.unpack_from("<HHII", data, off)
    il = off + (flags >> 12) * 4; end = il + size; eh = []
    if flags & 8:
        p = (end + 3) & ~3
        while True:
            kind = data[p]
            if kind & 0x40:
                n = struct.unpack_from("<I", data, p)[0] >> 8
                for k in range((n - 4) // 24): eh.append(struct.unpack_from("<IIIIII", data, p + 4 + 24 * k))
            else:
                n = data[p + 1]
                for k in range((n - 4) // 12): eh.append(struct.unpack_from("<HHBHBI", data, p + 4 + 12 * k))
            end = p + n
            if not kind & 0x80: break
            p = (end + 3) & ~3
    return dict(hdr=off, fat=True, il=il, size=size, end=end, eh=eh, flags=flags, maxstack=ms, lvsig=lv)


def tok(t):
    return struct.pack("<I", t)


def il_of(data, b):
    return bytes(data[b["il"]:b["il"] + b["size"]])


def text_slack(px, nbytes, data):
    """First 4-aligned run of `nbytes` zero bytes past .text's VirtualSize (linker file-alignment padding),
    verified unreferenced: no MethodDef/FieldRVA/PE-or-CLI data directory/debug data points into it."""
    s = px.pe.sections[0]
    if not bytes(s.Name).startswith(b".text"): moved("first section is not .text")
    start = (s.PointerToRawData + s.Misc_VirtualSize + 3) & ~3
    end = s.PointerToRawData + s.SizeOfRawData
    if start + nbytes > end: moved(f".text tail slack is {end - start} B, need {nbytes}")
    if any(data[start:start + nbytes]): moved(f".text tail slack at {start:#x} is not zero")
    lo, hi = px.off2rva(start), px.off2rva(start) + nbytes
    refs = [r.Rva for r in px.md.MethodDef.rows if r.Rva]
    if px.md.FieldRva: refs += [r.Rva for r in px.md.FieldRva.rows]
    for dd in px.pe.OPTIONAL_HEADER.DATA_DIRECTORY:
        if dd.VirtualAddress: refs += [dd.VirtualAddress, dd.VirtualAddress + max(dd.Size, 1) - 1]
    cli = px.pe.net.struct
    for f in ("MetaDataRva", "ResourcesRva", "StrongNameSignatureRva", "VTableFixupsRva"):
        v = getattr(cli, f, 0)
        if v: refs += [v, v + max(getattr(cli, f.replace("Rva", "Size"), 1), 1) - 1]
    for d in getattr(px.pe, "DIRECTORY_ENTRY_DEBUG", []) or []:
        if d.struct.AddressOfRawData: refs += [d.struct.AddressOfRawData, d.struct.AddressOfRawData + d.struct.SizeOfData - 1]
    text_end = s.VirtualAddress + s.SizeOfRawData
    bad = [hex(r) for r in refs if lo <= r < text_end]
    if bad: moved(f".text slack RVA {lo:#x}.. is referenced or followed by referenced data ({bad})")
    return start, lo
def match(px, il, pos, template):
    """template items: bytes (literal) | (name,) a 4-byte token that must resolve to `name` |
    (name, key) same, captured into the result dict. -> (dict | None, reason)"""
    got = {}
    for it in template:
        if isinstance(it, (bytes, bytearray)):
            if il[pos:pos + len(it)] != it: return None, f"IL {pos:#x}: want {bytes(it).hex()} got {il[pos:pos + len(it)].hex()}"
            pos += len(it)
        else:
            if pos + 4 > len(il): return None, f"IL {pos:#x}: token runs off body"
            t = struct.unpack_from("<I", il, pos)[0]; nm = px.tokname(t)
            if nm != it[0]: return None, f"IL {pos:#x}: token {t:#010x} is {nm}, want {it[0]}"
            if len(it) > 1:
                if it[1] in got and got[it[1]] != t: return None, f"IL {pos:#x}: {it[1]} token differs"
                got[it[1]] = t
            pos += 4
    return got, pos
def sig_types(px, sig):
    """Minimal ECMA-335 II.23.2 method-sig reader -> (callconv, [ret, param...]) as readable names."""
    p = [0]
    def cu():
        x = sig[p[0]]
        if x & 0x80 == 0: p[0] += 1; return x
        if x & 0xC0 == 0x80: p[0] += 2; return ((x & 0x3F) << 8) | sig[p[0] - 1]
        p[0] += 4; return ((x & 0x1F) << 24) | (sig[p[0] - 3] << 16) | (sig[p[0] - 2] << 8) | sig[p[0] - 1]
    def ty():
        e = sig[p[0]]; p[0] += 1
        if e in (0x11, 0x12):
            c = cu(); tag, rid = c & 3, c >> 2
            kw = "class " if e == 0x12 else "valuetype "
            if tag == 1: return kw + px.trname(px.md.TypeRef.rows[rid - 1])
            if tag == 0: return kw + px.tdname(rid)
            return kw + "<typespec>"
        return {0x01: "void", 0x02: "bool", 0x08: "int32", 0x0E: "string", 0x18: "native int", 0x1C: "object"}.get(e, f"<et {e:#x}>")
    cc = sig[0]; p[0] = 1; n = cu()
    out = [ty() for _ in range(n + 1)]
    if p[0] != len(sig): return cc, out + ["<trailing bytes>"]
    return cc, out
# ---- end shared block ----
# ---- errno sites (identical in the six errno patchers) ----
import hashlib

# opcodes whose 4-byte operand is a metadata token
TOKEN_OPS = {0x27, 0x28, 0x29, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x79, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80,
             0x81, 0x8c, 0x8d, 0x8f, 0xa3, 0xa4, 0xa5, 0xc2, 0xc6, 0xd0, 0xFE06, 0xFE07, 0xFE15, 0xFE16, 0xFE1C}
# key: (type pattern, method, IL size, sha256 of the method's by-name form on build 26404411); the form's text
# is patches/errno-forms/<key>.txt, less its final newline
METHODS = {
    "rdr": (r"System\.IO\.FileSystem", "RemoveDirectoryRecursive", 377,
            "adbdd7f2bbc85487b5cb2f9ab47eae8fc7ea6d8c5c07088132248554a13b04ed"),
    "rdi": (r"System\.IO\.FileSystem", "RemoveDirectoryInternal", 84,
            "76168eda1185ead91b1515e31ef2a1a556d2cd67846c631273466483a24de810"),
    "df": (r"System\.IO\.FileSystem", "DeleteFile", 28,
           "950c3878fe13738fecb8d4320af973d24ad0fa08792183f8f13db7d6d05dc7af"),
    "cdh": (r"System\.IO\.Enumeration\.FileSystemEnumerator`1", "CreateDirectoryHandle", 80,
            "9b0db6be5eb495dea89ecc32aeb98bc28530ae26629fb2f1d9333879530f73b2"),
}
GELW = ("System.IO.Win32Marshal::GetExceptionForLastWin32Error",)
SITES = [  # id (part of the form's text: never renamed), method, IL offset, original (a match template), patched
    ("dirrec_nx", "rdr", 0x26, [b"\x02\x28", GELW, b"\x7a"], bytes.fromhex("38390100000000")),
    ("delchild", "rdr", 0x14d, [b"\x7a"], b"\x26"),
    ("dirdel", "rdr", 0x163, [b"\x7a"], b"\x00"),
    ("delrec", "rdi", 0x52, [b"\x7a"], b"\x26"),
    ("delfile", "df", 0x1a, [b"\x7a"], b"\x26"),
    ("dirhandle", "cdh", 0x38, [b"\x2c\x06"], b"\x26\x00"),
    ("exp-handle0", "cdh", 0x1a, [b"\x2d\x0e"], b"\x26\x00"),
    ("exp-errno0", "cdh", 0x40, [bytes.fromhex("07183302190b")], bytes.fromhex("072cf7000000")),
]
PUT_BACK = {"dirhandle": ("exp-handle0", "exp-errno0")}  # the sites a script returns to their original bytes


def find_mscorlib(arg):
    p = os.path.join(arg, "Cities2_Data", "Managed", "mscorlib.dll") if os.path.isdir(arg) else arg
    if not os.path.isfile(p):
        print(f"mscorlib.dll not found at {p}"); sys.exit(1)
    return p


def name_of(px, t):
    tbl, rid = t >> 24, t & 0xFFFFFF
    if tbl == 0x02 and 1 <= rid <= len(px.md.TypeDef.rows): return px.tdname(rid)
    if tbl == 0x01 and px.md.TypeRef and 1 <= rid <= len(px.md.TypeRef.rows): return px.trname(px.md.TypeRef.rows[rid - 1])
    return px.tokname(t)


def il_lines(px, il, a, z):
    """IL a..z decoded strictly, one line an instruction: a token operand as its name, anything else as bytes."""
    return [f"{opc:x} {name_of(px, operand)}" if opc in TOKEN_OPS else il[a + o:a + nxt].hex()
            for (o, opc, operand, nxt, _tg) in decode(il[a:z])]


def eh_lines(px, eh):
    return ["eh " + " ".join(str(x) for x in c[:5]) + " " + (name_of(px, c[5]) if c[0] == 0 else str(c[5]))
            for c in eh]


def form(px, il, eh, key):
    """The by-name form of a method's body (docs/plans/errno-by-name.md 2.2): one line per instruction outside
    the sites, one per site, one per EH clause. -> (text, {site id: "original" | "patched"}). Raises ValueError."""
    out, states, pos = [], {}, 0
    for sid, _key, off, orig, new in sorted((s for s in SITES if s[1] == key), key=lambda s: s[2]):
        if off < pos or off + len(new) > len(il): raise ValueError(f"site {sid} at IL {off:#x} is outside the body")
        out += il_lines(px, il, pos, off)
        if il[off:off + len(new)] == new:
            states[sid] = "patched"
        else:
            got, end = match(px, il, off, orig)
            if got is None or end != off + len(new): raise ValueError(f"site {sid} at IL {off:#x} holds {il[off:off + len(new)].hex()}, neither its original nor its patched form")
            states[sid] = "original"
        out.append(f"<{sid}:{len(new)}>"); pos = off + len(new)
    out += il_lines(px, il, pos, len(il))
    return "\n".join(out + eh_lines(px, eh)), states


def locate(px, d, key, sized=True):
    """The method by name and its body -> (body, il), or `moved`."""
    tpat, name, size, _h = METHODS[key]
    rid = px.method(tpat, name)
    off = px.rva2off(px.rva_of(rid))
    if off is None: moved(f"{name} RVA {px.rva_of(rid):#x} maps to no section")
    try:
        b = body_at(d, off)
    except (ValueError, IndexError, struct.error) as e:
        moved(f"{name} has no body that parses at file {off:#x}: {e}")
    if not b["fat"]: moved(f"{name} body at file {off:#x} has a tiny header (want the fat one)")
    if sized and b["size"] != size: moved(f"{name} IL is {b['size']} bytes (want {size})")
    return b, il_of(d, b)


def show_form(px, il, eh, key):
    """--form: print the form, or a `#` line with the reason and the body decoded as one piece. -> the exit code:
    0 when the IL has the recorded size and the form the recorded sha256, 3 otherwise. Prints nothing else."""
    try:
        text, _states = form(px, il, eh, key)
    except (ValueError, IndexError, struct.error) as e:
        print(f"# no form can be made: {e}")
        try:
            print("\n".join(il_lines(px, il, 0, len(il)) + eh_lines(px, eh)))
        except (ValueError, IndexError, struct.error):
            pass
        return 3
    print(text)
    return 0 if len(il) == METHODS[key][2] and hashlib.sha256(text.encode()).hexdigest() == METHODS[key][3] else 3


def run(sid):
    args = [a for a in sys.argv[1:] if a != "--form"]; show = len(args) != len(sys.argv) - 1
    if len(args) != 1:
        print(f"usage: {os.path.basename(sys.argv[0])} [--form] <path-to-mscorlib.dll | game-dir>"); sys.exit(2)
    p = find_mscorlib(args[0])
    d = bytearray(open(p, "rb").read())
    px = PDX(d)  # a file dnfile cannot read ends here in its traceback, exit 1: not caught, as in the five
    _sid, key, soff, orig, new = next(s for s in SITES if s[0] == sid)
    name = METHODS[key][1]
    b, il = locate(px, d, key, sized=not show)
    if show:
        code = show_form(px, il, b["eh"], key)
        sys.exit(code)
    try:
        text, states = form(px, il, b["eh"], key)
    except (ValueError, IndexError, struct.error) as e:
        moved(f"{name} is not the method this script was written for: {e}")
    h = hashlib.sha256(text.encode()).hexdigest()
    if h != METHODS[key][3]:
        moved(f"{name} is not the method this script was written for: its by-name form has sha256 {h}")
    back = [s for s in SITES if s[0] in PUT_BACK.get(sid, ()) and states[s[0]] == "patched"]
    O = b["il"] + soff
    if states[sid] == "patched" and not back:
        print(f"already patched (file {O:#x}: {name} IL {soff:#x})"); return
    new_il = bytearray(il)
    for bid, _key, boff, borig, bnew in back:
        new_il[boff:boff + len(bnew)] = b"".join(borig)
        print(f"put back {b['il'] + boff:#x}: {bnew.hex()} -> {b''.join(borig).hex()} ({bid}: {name} IL {boff:#x})")
    new_il[soff:soff + len(new)] = new
    check_body(bytes(new_il), b["eh"])
    if states[sid] == "original" and not os.path.exists(p + ".bak"):
        shutil.copy2(p, p + ".bak")
    d[b["il"]:b["il"] + b["size"]] = new_il
    with open(p, "wb") as f:
        f.write(bytes(d))
    if states[sid] == "original":
        print(f"patched {O:#x}: {il[soff:soff + len(new)].hex()} -> {new.hex()} ({sid}: {name} IL {soff:#x})")
# ---- end errno block ----

if __name__ == "__main__": run("delfile")
