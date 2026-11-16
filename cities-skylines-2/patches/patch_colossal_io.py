#!/usr/bin/env python3
"""
Automated patcher for Colossal.IO.dll (Cities: Skylines II macOS/Wine fix)

Removes the Win32 error check after FindNextFile in the
EnumerateFileSystemIterator and EnumerateFileSystemIteratorRecursive methods.

Under Wine on macOS, Marshal.GetLastWin32Error() returns random values after
FindNextFile, causing a crash on startup. This patch replaces the error check
with a branch directly to the normal "no more files" code path.

The IL pattern patched (in both methods):
    call Marshal::GetLastWin32Error()   // 28 xx xx xx xx
    stloc[.s] <var>                     // 0D or 11 xx
    ldloc[.s] <var>                     // 09 or 11 xx
    ldc.i4.s 18                         // 1F 12
    beq.s <target>                      // 2E xx
    ldloc[.s] <var>                     // 09 or 11 xx
    ldnull                              // 14
    ldstr "path"                        // 72 xx xx xx xx
    call GetExceptionFromWin32Error     // 28 xx xx xx xx
    throw                               // 7A

Replaced with:
    br.s <target>                       // 2B xx  (branch to same target as beq.s)
    nop * (remaining bytes)             // 00 ...
"""

import sys
import os
import shutil
import hashlib

EXPECTED_MATCHES = 2  # One per iterator method


def file_hash(path):
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


def find_error_check_patterns(data):
    """Find all instances of the GetLastWin32Error + throw pattern."""
    matches = []

    for i in range(len(data) - 3):
        # Look for: ldc.i4.s 18; beq.s
        if data[i] != 0x1F or data[i + 1] != 0x12 or data[i + 2] != 0x2E:
            continue

        # Look backward for 'call' opcode (0x28) within 15 bytes
        call_start = None
        for back in range(1, 15):
            if i - back >= 0 and data[i - back] == 0x28:
                call_start = i - back
                break

        if call_start is None:
            continue

        # Look forward for 'throw' opcode (0x7A) within 30 bytes
        throw_pos = None
        for fwd in range(3, 30):
            if i + fwd < len(data) and data[i + fwd] == 0x7A:
                throw_pos = i + fwd
                break

        if throw_pos is None:
            continue

        # beq.s target offset is relative to the next instruction
        beq_s_pos = i + 2  # position of beq.s opcode
        beq_s_operand = data[beq_s_pos + 1]  # signed offset

        matches.append({
            'call_start': call_start,
            'throw_pos': throw_pos,
            'beq_s_pos': beq_s_pos,
            'beq_s_target_offset': beq_s_operand,
            'length': throw_pos - call_start + 1,
            'original': bytes(data[call_start:throw_pos + 1]),
        })

    return matches


# A site this script knows how to patch: the beq.s lands on the byte after the throw (so br.s over nops lands
# where the beq.s did), and the site is long enough for the patched form below to recognise it again.
MIN_SITE = 18
# The patched form: br.s nn, exactly nn nops, then a byte that is not a nop. The floor keeps false matches
# away: from 3 up the form matched ten places in a pristine mscorlib.dll, from 16 none in any patched file.
PATCHED_MIN, PATCHED_MAX = 16, 42


def known_sites(data):
    """The matches of find_error_check_patterns that this script can patch and recognise afterwards."""
    sites = []
    for m in find_error_check_patterns(data):
        beq_target_absolute = m['beq_s_pos'] + 2 + m['beq_s_target_offset']
        if beq_target_absolute == m['throw_pos'] + 1 and m['length'] >= MIN_SITE:
            sites.append(m)
    return sites


def patched_sites(data):
    """File offsets of every br.s nn followed by exactly nn nops and a byte that is not a nop."""
    hits = []
    i = data.find(b"\x2b")
    while i != -1 and i + 2 < len(data):
        nn = data[i + 1]
        if PATCHED_MIN <= nn <= PATCHED_MAX and i + 2 + nn < len(data) \
                and not any(data[i + 2:i + 2 + nn]) and data[i + 2 + nn] != 0:
            hits.append(i)
        i = data.find(b"\x2b", i + 1)
    return hits


def patch_sites(data, sites):
    """Replace each site with br.s to the beq.s target, then nops."""
    for idx, match in enumerate(sites):
        start = match['call_start']
        end = match['throw_pos'] + 1
        # br.s at 'start' must reach the beq.s target, which known_sites put at 'end'
        br_s_offset = end - (start + 2)
        print(f"  Patching pattern {idx+1} at file offset 0x{start:X} ({match['length']} bytes)")
        data[start] = 0x2B  # br.s
        data[start + 1] = br_s_offset & 0xFF
        for i in range(start + 2, end):
            data[i] = 0x00  # nop


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    game_root = os.path.dirname(script_dir)

    if len(sys.argv) > 1:
        game_root = sys.argv[1]

    dll_path = os.path.join(game_root, "Cities2_Data", "Managed", "Colossal.IO.dll")
    backup_path = dll_path + ".bak"

    if not os.path.exists(dll_path):
        print(f"ERROR: Cannot find {dll_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Patching: {dll_path}")

    # Classify first: count the original sites and the patched ones before any byte is written to the DLL
    # or to its .bak. Copying the live file over the .bak before this once replaced a pristine .bak with a
    # half-patched file.
    data = bytearray(open(dll_path, 'rb').read())
    sites = known_sites(data)
    o, p = len(sites), len(patched_sites(data))

    if p == EXPECTED_MATCHES and o == 0:
        print("  Already patched: both error checks are branches over nops.")
        print("\nNo changes needed.")
        return
    if p == 0 and o != EXPECTED_MATCHES:
        print(f"  WARNING: nothing of this fix is in the file and the code it changes is not as expected"
              f" ({o} of {EXPECTED_MATCHES} sites). No change made.")
        sys.exit(3)
    if o + p != EXPECTED_MATCHES:
        print(f"  ERROR: part of this fix is in the file and the sites do not add up ({o} original, {p} patched,"
              f" {EXPECTED_MATCHES} expected). No change made.")
        sys.exit(1)

    print(f"  Found {o} error check pattern(s) to patch" + (f", {p} already patched." if p else "."))
    patch_sites(data, sites)
    if len(patched_sites(data)) != EXPECTED_MATCHES:
        print("  ERROR: the patched file would not show the patched form at every site. No change made.")
        sys.exit(1)

    # With every site original, refresh the backup so it matches the current game version. With part of the
    # fix already in the file, the live file is not pristine: an existing .bak is left as it is, none is made.
    if p == 0:
        had_backup = os.path.exists(backup_path)
        shutil.copy2(dll_path, backup_path)
        print(f"Backup {'refreshed' if had_backup else 'created'}: {backup_path}")
    elif os.path.exists(backup_path):
        print(f"Backup exists: {backup_path}")
    else:
        print(f"  (no backup made — DLL already partly patched)")

    with open(dll_path, 'wb') as f:
        f.write(data)
    print("\nSuccess! Colossal.IO.dll has been patched.")


if __name__ == '__main__':
    main()
