# The six errno patch scripts: the method found by name, its whole IL matched

> **Status:** Drafted 2026-11-16 on Fable 5.2. Not checked: `check it` comes before any build, and nothing
> here is built. Decisions ED1 to ED4 are open (section 8). This is item 1 of
> [#24](https://github.com/macgameport/1launcher/issues/24), the follow-up that
> `docs/plans/patch-outcomes.md` (2.8) left for a plan of its own; items 2 and 3 of that issue are
> fixed. Tracking: issue #24; the repository's tracking issue is #22. Every `file:line` is as of `main`
> at `e259950`; the game's files were read, never written, on the Studio at build 26404411 (1.6.4f1),
> and every experiment ran on copies. A path is relative to the repository's root unless it begins with
> `patches/` or `scripts/`, which are under `cities-skylines-2/`.

## 1. What is true today

**The six scripts.** `patch_dirdel.py`, `patch_delchild.py`, `patch_dirrec_nx.py`, `patch_delrec.py`,
`patch_delfile.py` and `patch_dirhandle.py` each change one place in the game's `mscorlib.dll`. They
are off by default: `repatch.sh:93-111` runs them only with `CS2_ERRNO_PATCHES=1`, for an engine with
the file-error defect that Wine 10 had. No engine in use needs them.

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
`0x16cca8`, when it finds them (`:50-54`, `:70-74`).

**The five `PDX.SDK.dll` scripts decide differently**, since 1.6.2f1: the method is found by name with
`dnfile`, and its whole IL is matched, tokens resolved to names, before anything is written. The code
for that is one block of text pasted into all five (`patches/patch_lockbypass.py:19-317`), and
`scripts/test-vendor.sh:323-354` fails when the five copies differ.

**Measured (P0, 2026-11-16).** Recorded in `~/cs2-patch/errno-by-name-p0/`, with the scripts that made
each file. The unpatched `mscorlib.dll` is the game's `mscorlib.dll.bak` (4,631,552 bytes, sha256
`952703a7a04ee371`); the installed file differs from it in four bytes at `0x1668c4`, which is
`patch_fshandle.py`'s change, so the `.bak` is this build's file.

1. **Every site resolves by name, and is where the script says.** Each of the four methods is the only
   one of its name in the only type of its name. Each fixed offset falls on an instruction boundary of
   the method the script's own comment names:

   | Method | Type | IL at file | IL size | EH clauses | Sites (IL offset) |
   |---|---|---|---|---|---|
   | `RemoveDirectoryRecursive` | `System.IO.FileSystem` | `0x1544bc` | 377 | 2 | `patch_dirrec_nx` `0x26`, `patch_delchild` `0x14d`, `patch_dirdel` `0x163` |
   | `RemoveDirectoryInternal` | `System.IO.FileSystem` | `0x154678` | 84 | 0 | `patch_delrec` `0x52` |
   | `DeleteFile` | `System.IO.FileSystem` | `0x154084` | 28 | 0 | `patch_delfile` `0x1a` |
   | `CreateDirectoryHandle` | ``System.IO.Enumeration.FileSystemEnumerator`1`` | `0x16cc68` | 80 | 0 | `patch_dirhandle` `0x38`; the experiment's `0x1a` and `0x40` |

2. **The shared block reads `mscorlib.dll` as it is.** `dnfile` parses the file in 1.4 s (2.0 s under
   Apple's `python3` 3.9.6): 3,023 types, 27,492 methods. The block's strict decoder accepts all four
   bodies, unpatched and with every patch in, with their EH clauses.
3. **Today's scripts say "already patched" on files that are not theirs.** Each of the game's other
   .NET files large enough for the offsets (8 of 183) was cloned under the name and each script run on
   its own clone: 48 runs. 44 refused with exit 3. **4 said "already patched" and exited 0**:
   `patch_dirdel.py` on `System.Data.dll`, `Unity.RenderPipelines.HighDefinition.Runtime.dll` and
   `UnityEngine.UIElementsModule.dll`, and `patch_delfile.py` on `System.Xml.dll`. None wrote.
4. **On a file whose code moved, today's script writes into dead bytes and says "patched".** On a
   clone, `DeleteFile`'s body was copied into the unused tail of `.text` and the method's address
   pointed at the copy, the old bytes left in place. `patch_delfile.py` printed `patched 0x15409e` and
   exited 0. The one byte it changed is in the old, dead copy; the method the game would run is
   untouched.
5. **A prototype of section 2 gives the right answer in each of those cases.** On the unpatched file,
   the installed file, the file with all six patches, each of the six alone, and the file with the
   experiment's two edits, the four methods have the same by-name form (2.2) and every site reads as
   original or patched as it is. `Colossal.IO.dll` under the name: no such type. The moved
   `DeleteFile`: found at its new place, same form.
6. **Room to move a body, for the test of item 4.** `.text` has 140 unused bytes at its tail. The bodies
   of `DeleteFile` (40 bytes), `RemoveDirectoryInternal` (96) and `CreateDirectoryHandle` (92) fit;
   `RemoveDirectoryRecursive` (444) does not.

**What is tested today.** `scripts/test-vendor.sh:293-321` runs the six on files it makes: 0x16cd00
bytes of `ff`, 4,096 zeros, and the expected bytes placed at each offset. No test runs them on the
game's file. `scripts/test-patch-outcomes.sh` covers the five `PDX.SDK.dll` scripts only.

## 2. Design

### 2.1 What changes, in one paragraph

Each of the six finds its method by name, requires the whole method to be the one it was written for,
and only then looks at its own site. The entry points stay: six files, the same names, the same
arguments, the same order in `repatch.sh`, the same bytes written. The ten scripts that run by default
are not edited.

### 2.2 The by-name form of a method

The whole-IL match is carried as one sha256 per method, of a text made from the method's body (ED1):

- The method's known sites are taken in order of IL offset. The IL before the first site, between two
  sites and after the last is decoded strictly, piece by piece, with the shared block's `decode`.
- Each instruction gives one line. If its operand is a metadata token, the line is the opcode in hex,
  a space and the token's name: `tokname(token)`, or the type's full name when the token is a TypeDef
  or a TypeRef. Otherwise the line is the instruction's bytes in lowercase hex.
- Each site gives one line, `<id:length>`. The site's bytes must be its patched bytes, or match its
  original form (a `match` template, so a token in it is resolved by name); anything else is "not for
  this build".
- Each EH clause gives one line: `eh`, its flags, the try block's offset and length, the handler's
  offset and length, and the caught type's name when the clause is a catch (the stored number
  otherwise).
- Lines are joined with a newline, with none at the end, and hashed as UTF-8.

The opcodes that carry a token: `27 28 29 6f 70 71 72 73 74 75 79 7b 7c 7d 7e 7f 80 81 8c 8d 8f a3 a4
a5 c2 c6 d0`, and `fe06 fe07 fe15 fe16 fe1c`.

The form is the same whether a site is patched or not, and it does not hold a token's number: a
rebuilt `mscorlib.dll` in which only the numbering changed still matches. One name is weak: the call
at IL `0x33` of `CreateDirectoryHandle` resolves to `?::ContinueOnDirectoryError`, since its parent is
the generic type's own TypeSpec, which `tokname` does not name. The method's name is still matched.

The four forms on build 26404411, as the prototype computed them (`p0b.py`, `p0b.txt`):

| Key | Method | Lines | sha256 |
|---|---|---|---|
| `rdr` | `RemoveDirectoryRecursive` | 144 | `adbdd7f2bbc85487b5cb2f9ab47eae8fc7ea6d8c5c07088132248554a13b04ed` |
| `rdi` | `RemoveDirectoryInternal` | 31 | `76168eda1185ead91b1515e31ef2a1a556d2cd67846c631273466483a24de810` |
| `df` | `DeleteFile` | 14 | `950c3878fe13738fecb8d4320af973d24ad0fa08792183f8f13db7d6d05dc7af` |
| `cdh` | `CreateDirectoryHandle` | 32 | `9b0db6be5eb495dea89ecc32aeb98bc28530ae26629fb2f1d9333879530f73b2` |

The built scripts must give these four on the unpatched file. If the build's form differs from the
prototype's in any character, the build records its own four and says so in the as-built header.

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

- Three scripts change `RemoveDirectoryRecursive`. Each accepts the other two's sites in either
  state, which is what the shared table is for: today each is blind to the others only because it
  reads nothing but its own bytes.
- `patch_delrec.py`'s test of the byte after its site (`:16`) is covered by the form.
- `patch_dirrec_nx.py`'s branch lands on IL `0x164`, the instruction after `dirdel`'s site. That
  holds wherever the form matches, since the form fixes the method's layout.

### 2.4 What a script does

Each of the six becomes: its own header, the shared block as the five have it, a second pasted block
(`# ---- errno sites (identical in the six errno patchers) ----`), and one line, `run("<id>")` (ED2).
`run`, in order:

1. One argument, the file or the game's folder, as five of the six take it today. No argument: a usage
   line and exit 2, as `patch_dirhandle.py:59-60` does.
2. No file there: exit 1. A file `dnfile` cannot read (zeros, a truncated file, something that is not
   a .NET file): exit 1, as the five give (`scripts/test-patch-outcomes.sh:89-92`).
3. The method by name: exactly one type and one method, or `moved` (exit 3).
4. The body: its address maps into a section, its header is the fat one, its IL has the recorded
   size, or `moved`.
5. The form (2.2): a decode error, a site in neither state, or another sha256 is `moved`. The line
   printed holds the sha256 found, whole, so that a new build's value can be read off a refusal.
6. Its own site is patched, and nothing is to be put back: "already patched", exit 0, nothing written,
   no `.bak` made.
7. Otherwise the new IL is made (its site patched; for `patch_dirhandle.py`, the experiment's two
   sites back at their original bytes), checked whole with `check_body`, and the file written. A
   `.bak` is made first only when the script's own fix was not yet in the file, as today
   (`patch_dirhandle.py:78-88`).

`<script> --form <file>` prints the by-name form of the script's method and exits 0, writing nothing.
It is how a later build's method is compared with this one's: two forms, one `diff` (ED1).

### 2.5 What changes for whoever runs them

| Case | Today | After |
|---|---|---|
| The game's file at build 26404411, unpatched or patched | patched, or "already patched" | the same, and the same bytes (ET2) |
| Another .NET file, or an `mscorlib.dll` whose method changed | exit 3 in 44 of 48 runs, "already patched" in 4 | exit 3 |
| The method moved and is otherwise the same | "patched", written into dead bytes | the live method patched |
| Not a .NET file: zeros, `ff`, a truncated file | exit 3 | exit 1, so `repatch.sh` lists it under `FAILED:` and not under `NO FIX YET` |
| Time, with `CS2_ERRNO_PATCHES=1` | none to speak of | 1.4 to 2.0 s more per script, six scripts |
| A script copied somewhere without `_vendor` | runs | stops at the import, as the five do |

`setup.sh:180-184` already installs `_vendor` beside the scripts. `repatch.sh` is not changed.

### 2.6 What this plan does not do

- **The ten default scripts are not edited**, the shared block's text among them. What a player runs
  without `CS2_ERRNO_PATCHES=1` is byte for byte what `main` has.
- **`tokname` is not improved** for a call whose parent is a TypeSpec (2.2): that would change the
  shared block in the five.
- **`patch_fshandle.py` stays a byte search.** It is the one default script on `mscorlib.dll`; its
  search and its "already patched" test are one fingerprint since #24's item 2.
- **No write becomes atomic, and a `.bak` is no more a way back than before**
  (`docs/plans/patch-outcomes.md`, 2.8).
- **Nothing here shows that the six fix anything.** They are for a defect of an engine, and no engine
  in use has it. Whether the game starts with all sixteen on this build is ED4.
- **No game-less test of the write path.** A file made of placed bytes is not a .NET file, so the
  cases of `scripts/test-vendor.sh:293-321` that patch such a file go; what replaces them needs the
  game (ET2), as the five's tests do.

## 3. Steps

| Step | What | Files |
|---|---|---|
| E0 | P0's measurements (section 1). Done 2026-11-16 | none in the repository |
| E1 | The six scripts (2.2 to 2.4), with ET1 and ET2 | the six `patches/patch_*.py`; `scripts/test-vendor.sh` (its PT2 cases at `:293-321`, its mutants 22 to 24, the list of scripts that import `dnfile` at `:119-122`, the gate at `:323-354`, its header); `scripts/test-patch-outcomes.sh` (its header, the files it wants at `:21-23`, the new cases and mutants) |
| E2 | The documents | `patches/README.md` (the safety list and the paragraph at `:52-55`, and `--form`); `cities-skylines-2/docs/patch-inventory.md:40-45`; `scripts/README.md` (the rows of the two test files); `docs/plans/patch-outcomes.md` (2.8 gains a pointer here); the root `CLAUDE.md`; this plan's as-built header |
| E3 | The live step EL1 (section 5), on James's word, if ED4 is yes | none |

- All of it is built on a branch, in a worktree, by one model from start to end.
- E1 is one commit: the six scripts share one block and one table, and the gate fails between a first
  script and a sixth.
- The branch is merged with `--no-ff` on James's word. Moving `release` is a separate act, also on
  his word and after every test file passes on that commit: until then no player's installer fetches
  these scripts.
- The deployed copies in `~/cs2-patch` change only when setup is run.

## 4. Tests

A mutant is applied to a scratch copy of the source and must be seen red: exit 1, not REFUSED.

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| ET1 | the source gate of `scripts/test-vendor.sh`, no game needed | The shared block is one text in eleven scripts (in `patch_mkparent.py` apart from its `ensure_text_vsize`, as now). The errno block is one text in the six. Outside the two blocks each of the six holds its header and one `run("<id>")`; the six ids are the six scripts' rows of 2.3, each once. In the errno block every refusal is `moved`, apart from the two classes of 2.4's step 2 and `check_body`'s. Each of the six gets past its import from another directory and from an install layout, under both pythons, leaving no bytecode (the loop at `:119-122` gains them). On a file of zeros, on 0x16cd00 bytes of `ff`, and with no file: exit 1, nothing written, no `.bak` | 22: one script's errno block differs by a character. 23: one `moved` of the errno block made `die`. 24: one script's `run` id made another script's. Each is today's number, pointed at the new code, since what 22 to 24 mutate today is replaced |
| ET2 | `scripts/test-patch-outcomes.sh`, on clones of the game's `mscorlib.dll.bak`; `SKIPPED` with exit 0 where there is no game or no `.bak` | It prints the `.bak`'s size, date and sha256, and whether that is P0's file. **Each of the six, on its own clone of the unpatched file:** exit 0; a `.bak` made; the file differs from the unpatched one in exactly its site's bytes, at the method's IL plus the site's offset as the script's own resolver gives them; a second run is exit 0 with nothing written and no `.bak` made. When the unpatched file is P0's, each result's sha256 is the one today's script gave (below). **All six on one clone, in `repatch.sh`'s order and in reverse:** exit 0 each, one sha256 for both orders, P0's when the file is P0's. **`--form`:** exit 0, nothing written, and the sha256 of what it prints is the script's own constant. **Refusals, each exit 3 with nothing written and no `.bak`:** `Colossal.IO.dll` under the name; the four files of P0's item 3 under the name, each with the script that says "already patched" on it today (skipped by name if the game no longer has the file); the method's first IL byte made `00`; the script's own site made `2a`; another script's site in the same method made `2a`. **A moved body:** for `patch_delfile.py`, `patch_delrec.py` and `patch_dirhandle.py`, the method's body is copied into the tail of `.text` and its address pointed there; the script exits 0, the site is patched in the copy, and the bytes at the old place are as they were. **`patch_dirhandle.py` and the experiment:** with the two edits placed, exit 0, both back at their original bytes and the fix in; with the fix in and the edits placed, the edits put back and no `.bak` made. **Not a .NET file:** zeros and `Cities2.exe` under the name are exit 1 | 5: `moved` exits 1 in the errno block. 6: the form's sha256 no longer compared. 7: a site in neither state taken as original. 8: the `.bak` made before the checks. 9: `delchild`'s row left out of the table (the all-six case must fail). 10: `patch_dirhandle.py` writes again when the fix is in and nothing is to be put back. 11: `--form` goes on to patch. 12: the method's file offset taken from a constant, not from its address (the moved-body case must fail) |
| ET3 | the gates | links; identifiers at the residual of 9; the experiments ledger; `bash -n` on the two test files; each of the six compiled with `python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")'`; no `__pycache__` left; every one of the tracked test files passes with its real exit code, `scripts/test-repatch.sh` and `scripts/test-setup.sh` unchanged | none |

**P0's reference results** (today's scripts, each on its own clone of the file `952703a7a04ee371`;
`p0b.txt`): `patch_dirdel.py` `6f9d78c05a6ef357`, `patch_delchild.py` `987aeb81ca033bf0`,
`patch_dirrec_nx.py` `8cc872288742f56a`, `patch_delrec.py` `236775e81db8a7f7`, `patch_delfile.py`
`3aef88cab7ec6079`, `patch_dirhandle.py` `cba53a210dfaa85c`; all six, `a11ba27335a2b805`.

**Not tested, and said so:** a moved `RemoveDirectoryRecursive` (its body does not fit the tail of
`.text`); a rebuilt `mscorlib.dll` whose tokens are renumbered (there is no second build of the file to
test on; the form's claim for it rests on 2.2's definition); whether any of the six still does on an
engine what its header says.

## 5. The live step

**EL1, on James's word, if ED4 is yes.** On the Studio, with nothing of Wine running, from the branch's
worktree. Run detached with a log, as `boot-verify.sh` asks.

1. Recorded first: the sha256 of the installed `mscorlib.dll` (P0: `863df6c5fd1863a7`) and of its
   `.bak`, and that the two differ only in `patch_fshandle.py`'s four bytes. If they do not, stop:
   the way back in step 4 would not hold.
2. `CS2_ERRNO_PATCHES=1 bash cities-skylines-2/repatch.sh dxmt11` from the worktree. Pass: `16 of 16
   patch scripts finished without error`, exit 0, and the installed file's sha256 is the one ET2's
   all-six case gives with `patch_fshandle.py` run after it on a clone.
3. `scripts/boot-verify.sh`. Its `VERDICT` line is recorded, whichever it is. A `FAIL` is a finding
   about the six on this build and engine, not about this plan (the bytes are today's): it goes into
   `patches/README.md` and #24, and does not hold the merge.
4. Back: the `.bak` copied over `mscorlib.dll`, then `patch_fshandle.py` on it. Pass: the sha256 of
   step 1. No second start of the game: that file is the one already boot-verified.

The run's files go in `~/cs2-patch/errno-by-name-el1/`.

## 6. Exit criteria

- E0 is recorded; E1 and E2 are committed; ET1 to ET3 pass; every listed mutant was applied and seen
  red, with the count in the as-built header; every older mutant of the two test files touched is
  still exit 1.
- ET2 was run where the game is installed, on P0's file, and its output is kept beside P0's.
- The built scripts give section 2.2's four sha256, or the header says why not and gives theirs.
- The diff of the branch against `main` touches none of the ten default scripts.
- ED1 to ED4 are decided. If ED4 is yes, EL1 was run, its verdict recorded and step 4 passed.
- #24 holds a comment naming the merge; with item 1 done it is closed by hand.

## 7. Rollback

The work is on a branch, merged with `--no-ff`, so `git revert -m 1 <the merge>` takes the scripts,
tests and documents back. An install brought to the new scripts goes back by running setup from the
reverted checkout. No game file needs restoring because of this plan: where the six write at all on
this build, they write today's bytes (ET2). EL1 has its own way back (its step 4). Nothing reaches a
player until `release` is moved.

## 8. Decisions

| | Decision | Recommended | Why |
|---|---|---|---|
| ED1 | How the whole-IL match is carried in a script | **One sha256 per method, of the by-name form (2.2), with `--form` to print the form** | The alternative is the five's way: the IL written out as a template in each script. `RemoveDirectoryRecursive` has 43 tokens, so its template is about 87 items, the same in three scripts and not readable either. The sha256 is four constants. What it gives up is a refusal that names the first byte that differs; `--form` on two builds and a `diff` gives that back |
| ED2 | Where the shared code lives | **Pasted, as the five have it: the shared block unchanged, and a second block for the six, each held to one text by the gate** | It is the repository's convention and the gate exists. A module beside the scripts would be shorter, but it is a second convention, it changes the count of files setup installs, and the five would stay as they are |
| ED3 | The experiment's two edits in `patch_dirhandle.py` | **Kept, as two known sites** | They cost two rows. Dropping them would make a file that holds them "not for this build", a change of behaviour nothing asks for. They were only ever on one Mac, in August 2026, which is the case for dropping them |
| ED4 | A start of the game with all sixteen on the real install (EL1) | **Yes, once** | `patches/README.md` tells a player with such an engine to run all sixteen, and its boot-verified claim is for the ten. EL1 is the only measurement of the sixteen on this build; it takes about ten minutes and its way back is checked by sha256. The plan's own claims do not rest on it |

## Review log

No pass yet.

Key paths: `cities-skylines-2/patches/` (the six, and `patch_lockbypass.py` for the shared block),
`cities-skylines-2/repatch.sh`, `cities-skylines-2/scripts/test-vendor.sh`,
`cities-skylines-2/scripts/test-patch-outcomes.sh`, `cities-skylines-2/scripts/setup.sh`,
`cities-skylines-2/patches/README.md`, `cities-skylines-2/docs/patch-inventory.md`.
