# The six errno patch scripts: the method found by name, its whole IL matched

> **🔧 As-built (2026-11-16):** BUILT through E2, on the branch `errno-by-name`, cut from `main` at
> `9d2d3fc`; not merged, and nothing of it is installed on either Mac. E0 is recorded in
> `~/cs2-patch/errno-by-name-p0/`. Its commits: E1 `b910864` (the six scripts, the four form texts, ET1 and
> ET2) and E2, the commit that carries this header (the documents). E3 is done: the issue of ED4 is
> [#25](https://github.com/macgameport/1launcher/issues/25). Tracking: issue #24 (item 1); the
> repository's tracking issue is #22. Still to come, each on James's word: the merge with `--no-ff`, the
> comment on #24 that names it, and closing #24 by hand. `release` is not moved by this plan.
> **What the built scripts give.** On a copy of the game's `mscorlib.dll.bak` (`952703a7a04ee371`, build
> 26404411): section 2.2's four sha256, character for character, so the four committed form texts are the
> ones `--form` prints (and are byte for byte the reference build's); and section 4's seven reference
> results, each of the six alone and all six in `repatch.sh`'s order and in reverse. The diff of the
> branch against `main` touches none of the ten default scripts.
> **Tests.** Every one of the 38 tracked test files passes on the branch, with real exit codes: among them
> `test-vendor.sh` 99 cases (ET1; 88 before), `test-patch-outcomes.sh` 174 (37 of the five, 137 of ET2),
> run on clones of the Studio's game, on P0's file, ending `0 case(s) not run` (the builder writes
> nothing outside its worktree, so its output and every mutant's are in `/private/tmp/errno-build-logs/`
> until they are copied beside P0's), `test-repatch.sh` 41, `test-setup.sh` 107. ET3's gates: links,
> identifiers at 9, the experiments ledger, `bash -n`, the six compiled under both pythons, no
> `__pycache__`. **New mutants applied and seen red: 18** (`test-vendor.sh` 31 to 35,
> `test-patch-outcomes.sh` 5 to 17). Every older mutant is still exit 1 (`test-vendor.sh` 1 to 21 and 25
> to 30, `test-patch-outcomes.sh` 1 to 4); `test-vendor.sh` 22 to 24 are REFUSED (exit 2), and so is a
> number neither file knows.
> **How it was built.** By one agent on Fable 5.2 in a worktree, from this plan. It started from the
> reference build of section 1's item 7 and then went through 2.2 to 2.4 and section 4 line by line: the
> errno block, the six headers and both test sections were written again.
> **Departures.** (1) Mutants 32 and 34 of ET1 are applied to all six scripts, not to one: the errno
> block then stays one text, and it is the class check and the run that go red, not the block's
> comparison. (2) ET1's gate is written to a file and run from there: bash 3.2 cannot read a
> here-document that holds quotes inside `$( )`. Its "no file offset in the header" is `0x` with five to
> seven hex digits; `patch_dirhandle.py`'s header keeps two eight-digit values, which are error codes
> seen. (3) ET2 holds its own table of the sites (IL offset, patched bytes, how many differ, P0's file
> offset) and finds a method's body with the shared block, not with the errno block's `locate`, so a
> mutant of the scripts' table or of `locate` cannot move the test with it. (4) Cases the plan does not
> list, added because a listed mutant or sentence needed them or they cost one run: that `repatch.sh`
> runs these six and no others under `CS2_ERRNO_PATCHES=1` (the order is read from it); a folder with no
> `mscorlib.dll` in it, exit 1; that a patched own site beside a broken one does not say "already
> patched"; that the experiment's two edits differ from the unpatched file in 7 bytes; the name
> duplicate is checked to be in the file (two `DeleteFile`, no `RemoveDirectoryInternal`) before the
> script runs. (5) The token case of `dirrec_nx` runs for all three `RemoveDirectoryRecursive` scripts.
> (6) With no `mscorlib.dll` in the game at all, ET2's section is one case not run. (7) Mutant 9 is an
> added refusal when a site that is not the script's own is patched, and mutant 16 replaces the token of
> the template by the bytes found: each a change of one line. (8) `--form`'s `#` line reads
> `# no form can be made: <the reason>`. (9) `test-patch-outcomes.sh` takes six to seven minutes on the
> Studio under Apple's `python3` (the plan: three and a half), and so does each of its mutants.
> (10) `patch_dirdel.py`'s header became a docstring, and the script takes the folder too (2.5).
> **Not run:** section 5 (the start with all sixteen: #25); setup on either Mac, `repatch.sh` on the
> real game, `boot-verify.sh`; ET2 on a file that is not P0's, so the `n case(s) not run` path and the
> `STALE .bak` line were read, not seen; a moved `RemoveDirectoryRecursive`, a renumbered `mscorlib.dll`
> and the IL size check by a mutant (section 4, "Not tested").
> **Verify against:** `patches/patch_dirdel.py` and its five siblings (the errno block: `SITES`,
> `METHODS`, `form`, `locate`, `show_form`, `run`), `patches/errno-forms/`, `scripts/test-vendor.sh` (the
> gate, `EWANT`, `ROWS`), `scripts/test-patch-outcomes.sh` (from `=== ET2`: `site`, `others`, `formsha`,
> `ref`, `em`), `patches/README.md` ("If a game update breaks them").

> **Status:** Triple-checked 2026-11-16 — build-ready-with-fixes (pass 1: five lenses, three blockers
> and the other corrections folded into the sections they concern and listed in "Review corrections";
> pass 1b: a fitted re-check of that fold, one blocker in a test case, folded too).
> Drafted 2026-11-16 on Fable 5.2. Built through E2 the same day: the as-built header above. Decisions
> ED1 to ED5 are taken as recommended (section 8). This is item 1 of [#24](https://github.com/macgameport/1launcher/issues/24), the
> follow-up that the root's `docs/plans/patch-outcomes.md` (2.8) left for a plan of its own; items 2 and
> 3 of that issue are fixed. Tracking: issue #24; the repository's tracking issue is #22. Every
> `file:line` is as of `main` at `86bc3f5`; the game's files were read, never written, on the Studio at
> build 26404411 (1.6.4f1), and every experiment ran on copies. A path is relative to
> `cities-skylines-2/`; a file of the repository's root is called the root's.

## 1. What is true today

**The six scripts.** `patch_dirdel.py`, `patch_delchild.py`, `patch_dirrec_nx.py`, `patch_delrec.py`,
`patch_delfile.py` and `patch_dirhandle.py` each change one place in the game's `mscorlib.dll`. They
are off by default: `repatch.sh:93-111` runs them only with `CS2_ERRNO_PATCHES=1`, for an engine with
the file-error defect that Wine 10 had. Nothing in the launcher, setup or the installer sets that
variable, and no engine in use needs them.

**How each decides.** Each reads one to seven bytes at a fixed file offset and nothing else:

| Script | Offset | Reads | Writes | Lines |
|---|---|---|---|---|
| `patch_dirdel.py` | `0x15461f` | `7a` | `00` | `:10`, `:13-16` |
| `patch_delchild.py` | `0x154609` | `7a` | `26` | `:11`, `:13-14` |
| `patch_dirrec_nx.py` | `0x1544e2` | `0228d66600067a` | `38390100000000` | `:12-15` |
| `patch_delrec.py` | `0x1546ca` | `7a`, and `2a` after it | `26` | `:12`, `:14-16` |
| `patch_delfile.py` | `0x15409e` | `7a` | `26` | `:11`, `:13-14` |
| `patch_dirhandle.py` | `0x16cca0` | `2c06` | `2600` | `:55`, `:78-88` |

`patch_dirhandle.py` also puts back two edits of an experiment of August 2026, at `0x16cc82` and
`0x16cca8`, when it finds them (`:50-54`, `:70-74`). Five of the six take the game's folder or the
file; `patch_dirdel.py` takes the file only (`:8`).

**The five `PDX.SDK.dll` scripts decide differently**, since 1.6.2f1: the method is found by name with
`dnfile`, and its whole IL is matched, tokens resolved to names, before anything is written. The code
for that is one block of 299 lines pasted into all five (`patches/patch_lockbypass.py:19-317`), and
`scripts/test-vendor.sh:323-354` fails when the five copies differ.

**Measured (P0, 2026-11-16).** Recorded in `~/cs2-patch/errno-by-name-p0/`, with the scripts that made
each file. The unpatched `mscorlib.dll` is the game's `mscorlib.dll.bak` (4,631,552 bytes, sha256
`952703a7a04ee371`); the installed file (`863df6c5fd1863a7`) differs from it in four bytes at
`0x1668c4`, which is `patch_fshandle.py`'s change, so the `.bak` is this build's file. Items 1 to 6
were measured again, independently, by the lenses of pass 1.

1. **Every site resolves by name, and is where the script says.** Each of the four methods is the only
   one of its name in the only type of its name. Each fixed offset falls on an instruction boundary of
   the method the script's own comment names:

   | Method | Type | IL at file | IL size | EH clauses | Sites (IL offset) |
   |---|---|---|---|---|---|
   | `RemoveDirectoryRecursive` | `System.IO.FileSystem` | `0x1544bc` | 377 | 2 | `patch_dirrec_nx` `0x26`, `patch_delchild` `0x14d`, `patch_dirdel` `0x163` |
   | `RemoveDirectoryInternal` | `System.IO.FileSystem` | `0x154678` | 84 | 0 | `patch_delrec` `0x52` |
   | `DeleteFile` | `System.IO.FileSystem` | `0x154084` | 28 | 0 | `patch_delfile` `0x1a` |
   | `CreateDirectoryHandle` | ``System.IO.Enumeration.FileSystemEnumerator`1`` | `0x16cc68` | 80 | 0 | `patch_dirhandle` `0x38`; the experiment's `0x1a` and `0x40` |

2. **The shared block reads `mscorlib.dll` as it is.** `dnfile` parses the file in 1.4 to 1.6 s under
   the `python3` on PATH (3.14) and 2.0 to 2.4 s under Apple's 3.9.6: 3,023 types, 27,492 methods. The
   block's strict decoder accepts all four bodies with their EH clauses in each of the 20 combinations
   of site states (8 for `RemoveDirectoryRecursive`, 2, 2, and 8 for `CreateDirectoryHandle`).
3. **Today's scripts say "already patched" on files that are not theirs.** Each of the game's other
   .NET files larger than `0x16cca8` bytes (8 of 183) was cloned under the name and each script run on
   its own clone: 48 runs. 44 refused with exit 3. **4 said "already patched" and exited 0**:
   `patch_dirdel.py` on `System.Data.dll`, `Unity.RenderPipelines.HighDefinition.Runtime.dll` and
   `UnityEngine.UIElementsModule.dll`, and `patch_delfile.py` on `System.Xml.dll`. None wrote.
   `patch_dirdel.py` says the same on 5 MB of zeros.
4. **On a file whose code moved, today's script writes into dead bytes and says "patched".** On a
   clone, `DeleteFile`'s body was copied into the unused tail of `.text` and the method's address
   pointed at the copy, the old bytes left in place. `patch_delfile.py` printed `patched 0x15409e` and
   exited 0. The one byte it changed is in the old, dead copy; the method the game would run is
   untouched. The same holds for `patch_delrec.py` and `patch_dirhandle.py` with their methods moved.
5. **A prototype of section 2 gives the right answer in each of those cases.** On the unpatched file,
   the installed file, the file with all six patches, each of the six alone, and the file with the
   experiment's two edits, the four methods have the same by-name form (2.2) and every site reads as
   original or patched as it is. `Colossal.IO.dll` under the name: no such type. The moved bodies:
   found at their new place, same form.
6. **Room to move a body, for the test of item 4.** `.text` has 140 unused bytes at its tail. The bodies
   of `DeleteFile` (40 bytes), `RemoveDirectoryInternal` (96) and `CreateDirectoryHandle` (92) fit, one
   to a clone; `RemoveDirectoryRecursive` (444) does not.
7. **A build of section 2 exists, as a reference.** The builder lens of pass 1 built step E1 in a
   scratch clone. Its six scripts give 2.2's four sha256 and section 4's seven reference results, and
   on the 48 runs of item 3 give exit 3 every time. It is kept as
   `~/cs2-patch/errno-by-name-p0/sim/errno-by-name-sim.bundle` (one commit on `86bc3f5`), with its
   logs and the four form texts it prints. It was built before the fold. It lacks `--form`'s exit
   codes and `#` output, the committed texts, the retired mutant numbers and the fold's new cases and
   mutants, and it catches `dnfile`'s exception with `die`, against 2.4's step 2.

**What is tested today.** `scripts/test-vendor.sh:293-321` runs the six on files it makes: 0x16cd00
bytes of `ff`, 4,096 zeros, and the expected bytes placed at each offset (31 of its 88 cases). No test
runs them on the game's file. `scripts/test-patch-outcomes.sh` covers the five `PDX.SDK.dll` scripts
only.

## 2. Design

### 2.1 What changes, in one paragraph

Each of the six finds its method by name, requires the whole method to be the one it was written for,
and only then looks at its own site. The entry points stay: six files, the same names, the same
order in `repatch.sh`, the same bytes written. The ten scripts that run by default are not edited.

### 2.2 The by-name form of a method

The whole-IL match is carried as one sha256 per method, of a text made from the method's body (ED1):

- The method's known sites are taken in order of IL offset. The IL before the first site, between two
  sites and after the last is decoded strictly, piece by piece, with the shared block's `decode`.
- Each instruction gives one line. If its operand is a metadata token, the line is the opcode in
  lowercase hex without padding (`28`, `fe06`), a space and the token's name: `tokname(token)`, or the
  type's full name when the token is a TypeDef or a TypeRef. Otherwise the line is the instruction's
  bytes in lowercase hex.
- Each site gives one line, `<id:length>`, the length in decimal. The site's bytes must be its patched
  bytes, or match its original form (a `match` template, so a token in it is resolved by name; `match`
  returns an empty dict on success, so the test is `is None` and the end position); anything else is
  "not for this build".
- Each EH clause gives one line: `eh`, then its flags, the try block's offset and length, the handler's
  offset and length, each in decimal with one space between, then the caught type's name when the
  clause is a catch (flags 0) and the stored number in decimal otherwise. On this build:
  `eh 0 180 17 197 10 System.Exception` and `eh 2 30 328 358 10 0`.
- Lines are joined with a newline, with none at the end, and hashed as UTF-8.

The opcodes that carry a token: `27 28 29 6f 70 71 72 73 74 75 79 7b 7c 7d 7e 7f 80 81 8c 8d 8f a3 a4
a5 c2 c6 d0`, and `fe06 fe07 fe15 fe16 fe1c`. That is every opcode with a four-byte operand in the
shared block's tables but `20`, `22`, the branches `38` to `44` and `dd`. A token opcode left out of
the list would only be matched more strictly, as bytes.

**What the form holds and does not.**

- It is the same whether a site is patched or not, and it holds no token's number for the tokens these
  four bodies have (methods, member references, fields, strings, and the catch's type). A TypeSpec or
  a StandAloneSig token would be kept as its number; none is in the four bodies, and this
  `mscorlib.dll` has no TypeRef table.
- **Twelve of the 61 token lines are names that are not unique in the file:** overloads of
  `Path::Join`, `Path::Combine`, `SR::Format`, `IOException::.ctor` and `IntPtr::op_Explicit`; the
  fields `Zero` and `dwFileAttributes`, named without their type; and `?::ContinueOnDirectoryError`,
  whose parent is the generic type's own TypeSpec. A body that differs only in which same-named
  member a token means has the same form. No such body is type-correct, and the five match their
  tokens with the same `tokname`. Making the names sharper is ED5.
- It does not cover the body's header: maxstack, the locals' signature, the init-locals flag. No patch
  here deepens the stack (measured: 3 of 3, 2 of 2, 2 of 2, 5 of 5).
- It depends on the shared block's `decode`, `tokname`, `tdname` and `trname`. A change to those, for
  the five, needs the four sha256 computed again; ET1 and ET2 would go red.
- A site's id is part of the text. An id is never renamed.

The four forms on build 26404411, computed by the prototype and again by the reference build:

| Key | Method | Lines | IL size | sha256 |
|---|---|---|---|---|
| `rdr` | `RemoveDirectoryRecursive` | 144 | 377 | `adbdd7f2bbc85487b5cb2f9ab47eae8fc7ea6d8c5c07088132248554a13b04ed` |
| `rdi` | `RemoveDirectoryInternal` | 31 | 84 | `76168eda1185ead91b1515e31ef2a1a556d2cd67846c631273466483a24de810` |
| `df` | `DeleteFile` | 14 | 28 | `950c3878fe13738fecb8d4320af973d24ad0fa08792183f8f13db7d6d05dc7af` |
| `cdh` | `CreateDirectoryHandle` | 32 | 80 | `9b0db6be5eb495dea89ecc32aeb98bc28530ae26629fb2f1d9333879530f73b2` |

**The four form texts are committed**, as `patches/errno-forms/rdr.txt`, `rdi.txt`, `df.txt` and
`cdh.txt`, each with one newline at its end. Setup does not copy them (`scripts/setup.sh:180` copies
`patches/*.py`); they are for whoever works in a checkout. They are what a later build's method is
compared with (2.4), and they tie the four constants to something a Mac without the game can check
(ET1). The built scripts must give the four sha256 above on the unpatched file; if a build's form
differs from them in any character, the build records its own four and says so in the as-built header.

### 2.3 The sites

One table, the same in all six scripts. The id is part of the form's text.

| Id | Method | IL offset | Original | Patched | Whose |
|---|---|---|---|---|---|
| `dirrec_nx` | `rdr` | `0x26` | `02 28` (`System.IO.Win32Marshal::GetExceptionForLastWin32Error`) `7a` | `38 39 01 00 00 00 00` | `patch_dirrec_nx.py` |
| `delchild` | `rdr` | `0x14d` | `7a` | `26` | `patch_delchild.py` |
| `dirdel` | `rdr` | `0x163` | `7a` | `00` | `patch_dirdel.py` |
| `delrec` | `rdi` | `0x52` | `7a` | `26` | `patch_delrec.py` |
| `delfile` | `df` | `0x1a` | `7a` | `26` | `patch_delfile.py` |
| `dirhandle` | `cdh` | `0x38` | `2c 06` | `26 00` | `patch_dirhandle.py` |
| `exp-handle0` | `cdh` | `0x1a` | `2d 0e` | `26 00` | the experiment; `patch_dirhandle.py` puts it back (ED3) |
| `exp-errno0` | `cdh` | `0x40` | `07 18 33 02 19 0b` | `07 2c f7 00 00 00` | the same |

- A script's id is its file's name without `patch_` and `.py`.
- Three scripts change `RemoveDirectoryRecursive`. Each accepts the other two's sites in either
  state, which is what the shared table is for: today each is blind to the others only because it
  reads nothing but its own bytes.
- `patch_delrec.py`'s test of the byte after its site (`:16`) is covered by the form.
- `patch_dirrec_nx.py`'s branch lands on IL `0x164`, the instruction after `dirdel`'s site. Both ends
  are inside the try of the method's `finally` (`0x1e` to `0x166`) and outside its catch, and that
  holds wherever the form matches, since the form fixes the method's layout.
- Each site is whole instructions in both states, and no branch from outside lands inside one.

### 2.4 What a script does

Each of the six becomes, in this order:

- its own header: what it fixes, the method, the site's IL offset, "build 26404411", and no file
  offset;
- the shared block, pasted unchanged from the five, its first line ("identical in all five PDX
  patchers") and its `find_dll` (which looks for `PDX.SDK.dll`) included (ED2, 2.6);
- a second pasted block, from `# ---- errno sites (identical in the six errno patchers) ----` to
  `# ---- end errno block ----`, holding the token opcodes, the four methods with their IL sizes and
  sha256, the sites table, and `run`;
- one last line: `if __name__ == "__main__": run("<id>")`. The guard is needed: the tests load a
  script without running it.

`run`, in order:

1. Arguments: exactly one path, the file or the game's folder (`<folder>/Cities2_Data/Managed/
   mscorlib.dll`), found by the errno block itself and not by `find_dll`; `--form` may stand anywhere.
   Anything else: a usage line and exit 2, as `patch_dirhandle.py:59-60` does. No file there: one
   line and exit 1.
2. The file is read with `dnfile`. A file it cannot read (zeros, `ff`, a file cut short, a program
   that is not a .NET file) ends in the exception's traceback, exit 1, as in the five: it is not
   caught.
3. The method by name: exactly one type and one method, or `moved` (exit 3).
4. The body: its address maps into a section, a body parses there, its header is the fat one, its IL
   has the recorded size, or `moved`. `body_at`'s `ValueError` is caught and is `moved`.
5. The form (2.2): a piece that does not decode, a site in neither state, or another sha256 is
   `moved`. The line names the site, or holds the sha256 found, whole. Its words do not contain "does
   not decode" (the gate reads that phrase as a `die`). **This is exit 3 also when the script's own
   site reads as patched:** in a body that is not the known one, those bytes are no evidence of the
   fix, which is the finding of section 1's items 3 and 4; the five do the same
   (`patch_lockbypass.py:336-337` come before `:339`).
6. Its own site is patched, and nothing is to be put back: "already patched", exit 0, nothing written,
   no `.bak` made.
7. Otherwise the new IL is made (its site patched; for `patch_dirhandle.py`, the experiment's two
   sites back at their original bytes), checked whole with `check_body` and the EH clauses, and the
   file written by the errno block's own write. A `.bak` is made first only when the script's own fix
   was not yet in the file and no `.bak` is there, as today (`patch_dirhandle.py:78-88`): an existing
   `.bak` is never written over, and putting the experiment's edits back in a file that holds the fix
   makes none.

**What it prints** (one line each, plus the header's explanation staying in the header):
`patched <file offset>: <bytes before> -> <bytes after> (<id>: <Method> IL <offset>)`;
`already patched (file <offset>: <Method> IL <offset>)`;
`put back <file offset>: <bytes before> -> <bytes after> (<id>: <Method> IL <offset>)`.

**`<script> --form <path>`** writes nothing and makes no `.bak`. It does steps 1 to 3 and step 4
without the size.

- When a form can be made, it prints the form and a final newline. Exit 0 if the IL has the recorded
  size and the form the recorded sha256, exit 3 otherwise.
- When none can be made (a site that does not fit the body or is in neither state, or a piece
  between sites that does not decode), its first line begins with `#` and gives the reason; then it
  prints the whole body decoded as one piece, one line an instruction as in 2.2, with no site lines,
  then the EH lines; exit 3. If the whole body does not decode either, the `#` line is all it prints.
- It prints nothing but the form or the `#` output, and ends with its own exit: once the body is
  found it does not call `moved`, whose `UNEXPECTED:` line would spoil a `diff`.

So on the day a game update changes one of these methods, the maintainer runs `--form` on the new
file and compares it with the committed text: `diff patches/errno-forms/rdr.txt <(python3
patches/patch_dirdel.py --form <game>)`. In the `#` output the site lines show as differences beside
the real ones.

### 2.5 What changes for whoever runs them

| Case | Today | After |
|---|---|---|
| The game's file at build 26404411, unpatched or patched | patched, or "already patched" | the same, and the same bytes (ET2) |
| Another .NET file, or an `mscorlib.dll` whose method changed | exit 3 in 44 of 48 runs, "already patched" in 4 | exit 3 |
| The method moved and is otherwise the same | "patched", written into dead bytes | the live method patched |
| Not a .NET file | exit 3 when too short for the offset; `patch_dirdel.py` says "already patched" on zeros long enough | exit 1 where `dnfile` cannot read it, so `repatch.sh` lists it under `FAILED:` and not under `NO FIX YET` |
| The folder as the argument to `patch_dirdel.py` | a traceback | works, as in the other five |
| Time, with `CS2_ERRNO_PATCHES=1` | none to speak of | 1.4 to 2.4 s more per script: 8 to 14 s for the six |
| A script copied somewhere without `_vendor` | runs | stops at the import, as the five do |

`scripts/setup.sh:180-184` already installs `_vendor` beside the scripts. `repatch.sh`'s code is not
changed; its comment at `:40-41` ("the patch scripts take no --check/--dry flag") gains "but `--form`
in the six" (E2).

### 2.6 What this plan does not do

- **The ten default scripts are not edited**, the shared block's text among them. What a player runs
  without `CS2_ERRNO_PATCHES=1` is byte for byte what `main` has. The cost: six scripts for
  `mscorlib.dll` carry a block whose first line says "all five PDX patchers" and whose `find_dll`,
  unused by them, looks for `PDX.SDK.dll`.
- **One module for all eleven scripts** would end the pasting (about 3,300 lines of the shared block
  after this plan, and the errno block of about 125 lines six times). It edits five default scripts
  and so needs a boot-verify: a plan of its own if it is ever wanted. Nothing has gone wrong with the
  paste, and the gate holds it.
- **`tokname` is not improved** (2.2, ED5).
- **What the six write is not changed, `patch_dirdel.py`'s `00` among it.** Its five siblings write
  `26` (`pop`) over a `throw`; it writes `00` (`nop`), which leaves the exception on the stack at IL
  `0x164` when reached by falling through and not when reached by a branch. ECMA-335 asks for the same
  depth on every path; the `leave.s` there empties the stack, so the effect is benign where the
  runtime does not verify, and this is the script that ran on Wine 10. Found by pass 1's safety lens;
  it goes to the issue of ED4.
- **`patch_fshandle.py` stays a byte search.** It is the one default script on `mscorlib.dll`; its
  search and its "already patched" test are one fingerprint since #24's item 2.
- **No write becomes atomic, and a `.bak` is no more a way back than before** (the root's
  `docs/plans/patch-outcomes.md`, 2.8). A `.bak` can hold another script's fix or the experiment's
  edits, as today.
- **A file cut by a few hundred bytes at its end** still parses, matches, and would be patched as it
  is. So it is today.
- **Nothing here shows that the six fix anything**, or that the game starts with all sixteen on this
  build. That is ED4.
- **No game-less test of the write path.** A file made of placed bytes is not a .NET file. Of the 31
  cases of `scripts/test-vendor.sh:293-321`, 13 go (each script's write with its `.bak`, its second
  run, and `patch_delrec.py`'s next-byte case), 12 change from exit 3 to exit 1 (zeros and `ff`), and
  the six "no file there" stay. What replaces the 13 needs the game (ET2), as the five's tests do. No .NET file is
  committed, and writing metadata from a test is more than this is worth.

## 3. Steps

| Step | What | Files |
|---|---|---|
| E0 | P0's measurements (section 1). Done 2026-11-16 | none in the repository |
| E1 | The six scripts and the four form texts (2.2 to 2.4), with ET1 and ET2 | the six `patches/patch_*.py`; a new `patches/errno-forms/` with four files; `scripts/test-vendor.sh` (its PT2 cases at `:293-321`, its mutants 22 to 24 and the table at `:53-90`, the list of scripts that import `dnfile` at `:119-122`, the gate at `:323-354`, its header); `scripts/test-patch-outcomes.sh` (its header, a section of its own for the six with its own preconditions, a last arm for an unknown mutant, the new cases and mutants) |
| E2 | The documents | `patches/README.md` (the safety list, the paragraph at `:52-55`, "Offsets need re-deriving" at `:57`, and `--form` with `errno-forms/`); `patches/_vendor/README.md:3` ("Five of the patch scripts": eleven); `docs/patch-inventory.md:7` and `:40-45`; `scripts/README.md` (the rows of the two test files); `repatch.sh:40-41` (the comment); `GOTCHAS.md` (an entry for section 1's items 3 and 4: what a fixed offset says on a file that is not the one it was measured on); the root's `docs/plans/patch-outcomes.md` (2.8 gains a pointer here); the root's `CLAUDE.md`; this plan's as-built header |
| E3 | The issue of ED4, opened on James's word | none |

- All of it is built on a branch, in a worktree, by one model from start to end. Commits say
  `refs #24`.
- E1 is one commit: the six scripts share one block and one table, and the gate fails between a first
  script and a sixth.
- **The branch is merged only with E1 and E2 both on it**, with `--no-ff`, on James's word: between
  them `patches/README.md:52-55` is false.
- **This plan does not move `release`.** After the merge the scripts reach a player's installer at
  the next move of `release`, which is its own act, on James's word, after every test file passes on
  that commit.
- The deployed copies in `~/cs2-patch` change only when setup is run. Setup is not run on either Mac
  for this plan: the six are off there.

## 4. Tests

A mutant is applied to a scratch copy of the source and must be seen red: exit 1, not 0 and not
REFUSED. Both test files gain a last arm: a mutant number they do not know is REFUSED, exit 2 (today
it runs unmutated and exits 0).

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| ET1 | `scripts/test-vendor.sh`, no game needed | **The gate.** The shared block is one text in eleven scripts (in `patch_mkparent.py` apart from its `ensure_text_vsize`, as now), and the five keep their class check. The errno block, between its two marker lines, is one text in the six. Outside the two blocks each of the six holds its header and the last line `if __name__ == "__main__": run("<id>")`, the id being its file's name; the six ids are the six scripts' rows of 2.3. In the errno block every refusal is `moved`, apart from the usage line (exit 2), the missing file (exit 1), `--form`'s own exit 3 and `check_body`; the gate holds the built block's counts, as `WANT` does for the five. **The form texts:** the sha256 of each `patches/errno-forms/<key>.txt` less its final newline is that key's constant in the errno block. **The imports:** each of the six gets past its import from another directory and from an install layout, under both pythons, leaving no bytecode (the loop at `:119-122` gains them). **Game-less runs of each of the six,** nothing written and no `.bak` each time: no argument, exit 2; no file there, exit 1; 4,096 zeros, 0x16cd00 bytes of `ff`, and the root's `surviving-mars-relaunched/tools/frame-fix.exe` (a program that is not a .NET file) under the name, exit 1 | 22 to 24 are retired: what they mutate is replaced, and the as-built header of the root's `docs/plans/patch-outcomes.md` records "7 to 29" as seen red. Their arm says where the behaviours went and is REFUSED. New: 31, one script's errno block differs by a character. 32, one `moved` of the errno block made `die`. 33, one script's `run` id made another script's. 34, "no file there" made exit 3. 35, one character of one committed form text changed |
| ET2 | `scripts/test-patch-outcomes.sh`, a section of its own, on clones | See "ET2's cases" below | 5 to 17, below |
| ET3 | the gates | links; identifiers at the residual of 9; the experiments ledger; `bash -n` on the two test files; each of the six compiled with `python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")'`; no `__pycache__` left; every one of the tracked test files passes with its real exit code, `scripts/test-repatch.sh` and `scripts/test-setup.sh` unchanged | none |

**ET2's preconditions.** With no game: `SKIPPED`, exit 0, as now. With the game, the five's section
runs on what it wants today (`:21-23`), and the six's section decides for itself:

- The file it takes as unpatched is `mscorlib.dll.bak` when that has the installed file's size and
  differs from it in fewer than 64 bytes; otherwise the installed file, with a line `STALE .bak`.
  It prints the file's size, date and sha256.
- If that file is P0's (`952703a7a04ee371`), every case runs. If not, the cases that compare with
  P0's values are not run, each is counted, and the last line reads `n case(s) not run: <why>`. The
  other cases run, and go red if the six no longer fit this build's file: that is the day to re-derive,
  as it is for the five's cases.
- The exit criteria want this test run on P0's file with `0 case(s) not run`.

**ET2's cases.** Each run is on its own clone, and "nothing written" is the file's sha256 and
modification time before and after, with no `.bak` appearing.

- **Each of the six on the unpatched file,** with no `.bak` beside it: exit 0; a `.bak` made, equal to
  the unpatched file; a byte diff against the unpatched file shows differences only inside the site's
  bytes, which hold the patched bytes (in `patch_dirrec_nx.py`'s seven, six differ). On P0's file the
  site's file offset is the fixed offset of section 1, from a table in the test, and the result's
  sha256 is the reference below. With the `.bak` then removed, a second run: exit 0, nothing written.
- **Beside a `.bak` that is already there** (100 zeros): exit 0, the `.bak` as it was.
- **The folder as the argument,** for each of the six: exit 0 and the same sha256 as with the file.
- **All six on one clone,** in the order read from `repatch.sh` and in reverse: exit 0 each, one
  sha256 for both orders, `a11ba27335a2b805` on P0's file.
- **`--form`** on the unpatched file and on the file with all six: exit 0, nothing written, and the
  sha256 of the output less its final newline is section 2.2's value, held in the test as a literal.
  On a clone whose method has its first IL byte made `00` (a form can still be made): exit 3, the
  first line is `00`, as many lines as the committed text, nothing written. On a clone with the
  script's own site made `2a` (no form can be made): exit 3, the first line begins with `#`, no line
  begins with `<`, nothing written.
- **Refusals, each exit 3 with nothing written:**
  - `Colossal.IO.dll` under the name;
  - the four files of P0's item 3 under the name, each with the script that says "already patched"
    on it today (counted as not run if the game no longer has the file);
  - the method's first IL byte made `00` (it still decodes: only the sha256 refuses);
  - the script's own site made `2a`;
  - for the three `RemoveDirectoryRecursive` scripts and `patch_dirhandle.py`, another site of the
    method made `2a`; and the script's own site patched with another site made `2a`;
  - `dirrec_nx`'s call made to name another method (its token made `0x060066d5`);
  - `RemoveDirectoryInternal`'s name made `DeleteFile`'s in the method table, so that two methods
    have the name: `patch_delfile.py` and `patch_delrec.py`.
- **A moved body,** one to a clone, for `patch_delfile.py`, `patch_delrec.py` and
  `patch_dirhandle.py`: the body is copied into the tail of `.text` and the method's address pointed
  there. Exit 0, the site is patched in the copy, and the bytes at the old place are as they were.
- **`patch_dirhandle.py` and the experiment:** with the two edits placed, exit 0, both back at their
  original bytes and the fix in (`cba53a210dfaa85c` on P0's file); with the fix in and the edits
  placed, the edits put back and no `.bak` made.
- **Not a .NET file:** zeros, `Cities2.exe` and the unpatched file's first 1,000,000 bytes under the
  name are exit 1, nothing written.

**ET2's mutants.** 5: the shared block's `moved` exits 1, in the six. 6: the form's sha256 no longer
compared. 7: a site in neither state taken as original. 8: the `.bak` made before the checks. 9: a
site that is not the script's own must be original (each alone still passes; the all-six cases must
fail). 10: `patch_dirhandle.py` writes again when the fix is in and nothing is to be put back. 11:
`--form` goes on to patch. 12: the method's file offset taken from a constant, not from its address
(the moved-body cases must fail). 13: the `.bak` copied over one that is there. 14: a `.bak` made
when only putting back. 15: only `exp-handle0` put back. 16: the token in `dirrec_nx`'s original
form taken as any token. 17: the first of several methods of the name taken.

**P0's reference results** (today's scripts, each on its own clone of the file `952703a7a04ee371`;
measured three times): `patch_dirdel.py` `6f9d78c05a6ef357`, `patch_delchild.py` `987aeb81ca033bf0`,
`patch_dirrec_nx.py` `8cc872288742f56a`, `patch_delrec.py` `236775e81db8a7f7`, `patch_delfile.py`
`3aef88cab7ec6079`, `patch_dirhandle.py` `cba53a210dfaa85c`; all six, `a11ba27335a2b805`.

**Time.** In the reference build `test-vendor.sh` took 18 s and `test-patch-outcomes.sh` about three
and a half minutes (36 s today); its mutants take about an hour one after another.

**Not tested, and said so:** a moved `RemoveDirectoryRecursive` (its body does not fit the tail of
`.text`); a rebuilt `mscorlib.dll` whose tokens are renumbered (there is no second build of the file to
test on; the form's claim for it rests on 2.2's definition); the IL size check of step 4 by a mutant
(the sha256 refuses the same files); whether any of the six still does on an engine what its header
says.

## 5. A start of the game with all sixteen (the procedure of ED4)

Not a step of this plan unless ED4 says so. On the Studio, with nothing of Wine running, from a
checkout that holds the scripts to be measured. Run detached with a log, as `boot-verify.sh` asks.

1. Recorded first: the sha256 of the installed `mscorlib.dll` (P0: `863df6c5fd1863a7`) and of its
   `.bak`, that the two differ only in `patch_fshandle.py`'s four bytes, and the manifest's build
   (26404411). If they do not, stop: the way back in step 4 would not hold.
2. `env -u CS2_GAME_DIR CS2_ERRNO_PATCHES=1 bash cities-skylines-2/repatch.sh dxmt11` from the
   checkout: it runs the checkout's scripts on the default wrapper's game. Pass: `16 of 16 patch
   scripts finished without error`, exit 0, and the installed file's sha256 is `e9831e12fd829442`
   (measured on a clone with today's scripts: all six, then `patch_fshandle.py`). It also writes the
   stub file it always writes, and leaves no marker: later starts and a later setup run the ten.
3. `scripts/boot-verify.sh`. Its `VERDICT` line is recorded, whichever it is.
4. Back, only if the installed file's sha256 is still step 2's, the manifest's build is still
   26404411, and no process holds a file of the prefix open: the `.bak` copied over `mscorlib.dll`,
   then `patch_fshandle.py` on it (`repatch.sh:35-39` describes it, with the whole `repatch.sh` in
   place of the one script). Pass: the sha256 of step 1. No
   second start of the game: that file is the one already boot-verified.

## 6. Exit criteria

- E0 is recorded; E1 and E2 are committed on the branch; ET1 to ET3 pass; every listed mutant was
  applied and seen red, with the count in the as-built header; every older mutant of the two test
  files is still exit 1, but `test-vendor.sh` 22 to 24, which are REFUSED.
- ET2 was run where the game is installed, on P0's file, with `0 case(s) not run`, and its output is
  kept beside P0's.
- The built scripts give section 2.2's four sha256, or the header says why not and gives theirs; the
  four committed form texts are the ones the built scripts print.
- The diff of the branch against `main` touches none of the ten default scripts.
- ED1 to ED5 are decided. The issue of ED4 is open and linked, or section 5 was run and recorded, as
  ED4 says.
- #24 holds a comment naming the merge; with item 1 done it is closed by hand.

## 7. Rollback

The work is on a branch, merged with `--no-ff`, so `git revert -m 1 <the merge>` takes the scripts,
tests, form texts and documents back. An install brought to the new scripts goes back by running setup
from the reverted checkout: it copies all sixteen over the installed ones and leaves no file behind.
No game file needs restoring because of this plan: where the six write at all on this build, they
write today's bytes (ET2). `release` only ever moves forward: if it has been moved to a commit that
holds this work, the revert is merged into `main` and `release` moved forward to that.

## 8. Decisions

| | Decision | Recommended | Why |
|---|---|---|---|
| ED1 | How the whole-IL match is carried in a script | **One sha256 per method, of the by-name form (2.2); the four form texts committed; `--form` to print a file's** | The alternative is the five's way: the IL written out as a template in each script. `RemoveDirectoryRecursive` has 43 tokens, so its template is about 87 items, the same in three scripts and not readable either. The sha256 is four constants. A refusal then cannot name the first byte that differs; the committed text and `--form` on the new file, with a `diff`, give that back, and the committed text lets a Mac without the game check the constants |
| ED2 | Where the shared code lives | **Pasted, as the five have it: the shared block unchanged, and a second block for the six, each held to one text by the gate** | A module for the six alone would still need the shared block a sixth time, so it adds a third pattern without removing the second; it must be found under `-I`, through a symlink and from an install layout; and a rollback by setup would leave it behind in `~/cs2-patch/patches`. One module for all eleven is the change that would pay, and it is not this plan's (2.6) |
| ED3 | The experiment's two edits in `patch_dirhandle.py` | **Kept, as two known sites** | They cost two rows. Dropping them would make a file that holds them "not for this build", a change of behaviour nothing asks for. They were only ever on one Mac, in August 2026, which is the case for dropping them |
| ED4 | A start of the game with all sixteen on the real install (section 5) | **Not in this plan: an issue of its own, with section 5 as its procedure and `patch_dirdel.py`'s `00` (2.6) in it** | It writes the real install, and since the six write today's bytes it would give the same answer with today's scripts: it tests `patches/README.md`'s advice to run all sixteen, whose boot-verified claim is for the ten, and not this plan. The case for doing it here: it is about ten minutes, and nothing else has measured the sixteen on this build |
| ED5 | Sharper names in the form: a method's parameter count and a field's type, added inside the errno block | **No** | It would close 9 of the 12 names that are not unique (2.2) and change the four sha256. No body that differs only that way is type-correct, the five match with the same names, and the guard is already far above one to seven bytes at an offset |

**Taken 2026-11-16**, on James's "Yes, as recommended": ED1 to ED5 as recommended. So the four form
texts are committed, the code is pasted, the experiment's two sites are kept, the start with all
sixteen goes to an issue of its own (E3, opened the same day as
[#25](https://github.com/macgameport/1launcher/issues/25)), and the names stay as `tokname` gives them. The
verdict is posted on #24.

## Review corrections (triple-check 2026-11-16)

Pass 1, five lenses on Fable 5.2, none editing the repository: correctness, safety with IL and
platform facts, the test plan, a builder that built step E1 in a scratch clone and ran the tests and
every mutant, architecture and rollout. All five: build-ready-with-fixes. Every `file:line` held, and
every number of P0 was measured again and reproduced. Each blocker was read against the source before
it was folded.

| | Finding | Lens | Folded into |
|---|---|---|---|
| R1 | **Blocker.** No case ran a script beside a `.bak` that is already there, which is every real install: a build that wrote over the only unpatched copy stayed green | test plan | ET2's cases; mutant 13 |
| R2 | **Blocker.** A bare `run("<id>")` as the last line runs the patcher when a test loads the script | builder, test plan | 2.4; ET1's gate |
| R3 | **Blocker.** "Differs in exactly its site's bytes" is false for `patch_dirrec_nx.py` (six of seven differ), so the case as written is red on correct code | builder, correctness | ET2's cases |
| R4 | `--form` could not do what ED1 gave it: a changed method has no form, and the old build's form text was kept nowhere | correctness, architecture, test plan, builder | 2.2 (the texts committed); 2.4 (`--form`'s two outputs and exits); ET1; ET2; ED1 |
| R5 | Own site patched, form not matching: not named. Correctness read the contract as exit 1; safety as exit 3 | correctness, safety | 2.4 step 5: exit 3, with the reason; ET2 pins it. Exit 1 was not taken: the five refuse before they look at their site, and the bytes prove nothing in a body that is not the known one |
| R6 | "One name is weak": twelve of 61 are not unique; the form does not cover the header; a TypeSpec token would stay a number | safety, correctness, builder | 2.2; ED5 |
| R7 | The EH line's number base, the opcode's form, `match`'s return and the final newline were not given | builder, correctness | 2.2; ET2 (`--form`) |
| R8 | The shared block's `find_dll` looks for `PDX.SDK.dll`, and its write always makes a `.bak`; the errno block had no end marker; step 2's exception was not said to be uncaught; `body_at`'s `ValueError` was not caught; a decode refusal worded "does not decode" would fail the gate | builder, correctness, safety, architecture | 2.4; 2.6 |
| R9 | The lines a script prints, and what its header holds, were not given | builder, architecture | 2.4 |
| R10 | Mutant 9 was killed by accident, 11 survived unless `--form` ran on an unpatched file, 5 named the wrong block; two assertions were circular; no mutant for the put-back, the token by name, or one method of the name | test plan | ET2's cases and mutants 9, 13 to 17 |
| R11 | Re-using 22 to 24 would falsify the record of "7 to 29"; an unknown mutant number ran unmutated and exited 0 | test plan | ET1: retired, 31 to 35; the last arm |
| R12 | Adding `mscorlib.dll.bak` to the wanted files would skip the five's cases too; a stale `.bak`, and assertions that silently hold less on another build | test plan, builder, architecture | ET2's preconditions; exit criteria |
| R13 | E2 missed `_vendor/README.md:3`, `patch-inventory.md:7`, `patches/README.md:57`, `repatch.sh:40-41`, the six headers, and a `GOTCHAS.md` entry | architecture, correctness | section 3; 2.4; 2.5 |
| R14 | Rollback did not cover a moved `release`; nothing said the merge waits for E2, or whether `release` or the two Macs are touched | architecture | sections 3 and 7 |
| R15 | The live step: `CS2_GAME_DIR` could leak in; step 4 copied the `.bak` back with no re-check; its expected sha256 was not given. And it measures the README's claim, not this plan | safety, architecture | section 5; ED4's recommendation changed to an issue of its own |
| R16 | `patch_dirdel.py` writes `00` where its siblings write `26`, leaving unequal stack depths at IL `0x164` | safety | 2.6; the issue of ED4. Not changed here |
| R17 | 2.5's cells for a file that is not a .NET file were too simple; the time was low for Apple's `python3`; `patch_dirdel.py` gains the folder argument | correctness, builder, safety | 2.5; section 1 |
| R18 | ED2's reasons were weak (a module changes one echoed count, not the installer's transcript); the id in the form's text is a trap if renamed; the plan was in the root's folder though it touches one game | architecture | ED2; 2.2 and 2.3; the plan moved to `cities-skylines-2/docs/plans/` |

One thing about the pass itself: the lenses shared a scratch parent, and one lens's clean-up removed
the builder's clone mid-run. The builder rebuilt and re-ran everything; its numbers are from the
rebuilt clone.

### Second-pass re-check (pass 1b, 2026-11-16)

One lens on Fable 5.2, on the fold only, not editing: R1 to R18 each read in the sections they name;
the fold's new claims tried on a scratch clone of the reference build (`--form`'s two outputs and
exits, the token and name-duplicate refusals, mutants 9 and 13 to 17 each applied as a one-line
change and seen red, section 5's sha256). Verdict: build-ready-with-fixes. Folded:

| | Finding | Folded into |
|---|---|---|
| S1 | **Blocker.** ET2's `--form` case "first IL byte `00`: the first line begins with `#`" contradicted 2.4: that body still decodes, so a form is printed (exit 3, first line `00`). Red on a build that follows 2.4 | ET2's `--form` cases: two cases, one for each output |
| S2 | How `--form` ends with exit 3 was not said: `moved` prints a line that cannot follow the `#` line; ET1's list of endings left it out | 2.4; ET1's gate |
| S3 | "19 of the 31" cases: 13 go, 12 change from exit 3 to exit 1, six stay | 2.6 |
| S4 | "The fold's changes are not in it" was too strong of the reference build; the errno block is about 125 lines; `repatch.sh:35-39`; a site that does not fit the body; where the site lines show in a `diff` | section 1 item 7; 2.6; section 5; 2.4 |
| S5 | The root's `CLAUDE.md` still called the plan drafted, at its old path | the fold's commit |

Measured in this pass and kept as they were: the 64-byte bound of ET2's preconditions (the `.bak` and
the installed file differ in 4 bytes now, 16 with all six, 23 with the experiment's edits too); the
`diff` line in bash and zsh; `0x060066d5` (another method: exit 3); the name duplicate (the Name
column is 4 bytes at the row's offset 8: `patch_delfile.py` finds two methods, `patch_delrec.py`
none; both exit 3). Mutants 5 and 17 change the shared block in the six's copies only, which
`test-patch-outcomes.sh` allows: it does not run the gate.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-16 | 1 | correctness, safety with IL and platform facts, test plan, builder simulation, architecture and rollout | five agents, none editing the repository; experiments on copies of the game's files; the builder in a scratch clone with both test files and every mutant run (kept as a bundle, section 1 item 7); each blocker read against the source inline | Fable 5.2 | `main` at `86bc3f5` | build-ready-with-fixes, folded |
| 2026-11-16 | 1b | the fold of pass 1 | one agent, not editing; the fold's new cases, `--form`'s rules and six mutants tried on a scratch clone of the reference build | Fable 5.2 | the same | build-ready-with-fixes, folded |

Key paths: `cities-skylines-2/patches/` (the six, and `patch_lockbypass.py` for the shared block),
`cities-skylines-2/repatch.sh`, `cities-skylines-2/scripts/test-vendor.sh`,
`cities-skylines-2/scripts/test-patch-outcomes.sh`, `cities-skylines-2/scripts/setup.sh`,
`cities-skylines-2/patches/README.md`, `cities-skylines-2/docs/patch-inventory.md`.
