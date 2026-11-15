# A game update with no fix yet: what the patch scripts report, and what the player is told

> **Status:** drafted 2026-11-15. Not checked: `check it` comes before any build, and nothing here is
> built. Tracking: issue #22. This is the plan that slice F of `docs/plans/first-run-findings.md` (2.4)
> and the row SF7 of `docs/plans/shared-installer.md` (section 9) wait for; decision FD1 of the first
> comes here as PD1. Every `file:line` is as of `main` at `fd92a1b`, read on 2026-11-15; the game's files
> were read, not written, on the Studio at build 26404411 (1.6.4f1). A path is relative to the
> repository's root.

## 1. What is true today

Cities: Skylines II needs ten patch scripts (`cities-skylines-2/repatch.sh:67-70`, `:101-128`); six more
run only with `CS2_ERRNO_PATCHES=1` (`:80-90`). When Steam updates the game, the compiler may move the
code a script changes. The script then finds nothing to change, and the player is told the install
stopped.

**Seen (SL2, 2026-11-12).** The game was at build 26404411, one build newer than the patches.
`patch_cohtml.py` found no pattern; nine of ten scripts finished; both apps were built; and the window
ended "=== setup finished with 1 problem(s): see the lines marked !! above ===" and "The install
stopped. The lines above say why. Open the installer again to carry on from that step." Opening it again
gave the same, and would have until a new pattern was published (it was, the same day: `e14bbae`). Two
days before, the launcher had said "some fixes did not apply" at the update itself, and nobody read it
(`cities-skylines-2/GOTCHAS.md`, 2026-11-12).

**Why nothing can say "no fix yet" today.** An inventory of all sixteen scripts (2026-11-15, each read
whole; section 2.2 is its result) found:

- No script's exit code tells "the code I change is not in this file" from any other failure. The codes
  in use are 0, 1 and 2. "Not in this file" is exit 1 in fourteen scripts, shared with a missing file, a
  traceback, an ambiguous match and a failed verification.
- Only the text differs, in four forms: `WARNING: ... pattern not found` (`patch_cohtml.py:125`,
  `patch_longfile.py:75-78`); `UNEXPECTED ...` (the six fixed-offset scripts); `ERROR: FileStream.Init
  guard not found` on stderr (`patch_fshandle.py:108`); and `UNEXPECTED: <msg> — refusing to patch (game
  updated? re-derive)` in the five `PDX.SDK.dll` scripts, where the same sentence also wraps failures
  that are not a moved pattern (`patch_lockbypass.py:27-29` is the function).
- **Two scripts end with exit 0 when their pattern is gone.** `patch_asset_database.py:92-94` and
  `patch_colossal_io.py:94-96` print "No ... patterns found. DLL may already be patched." and return:
  neither looks for its own patched bytes, so "already patched" is only the absence of the original.
  `repatch.sh:138` says so in a comment.
- `patch_colossal_io.py` expects two sites. With one, or three, it prints a warning, writes what it
  found and says "Success!" (`:98-102`), exit 0.
- `repatch.sh`'s `run` counts exit 0 as done and anything else as failed (`:55-58`), prints
  `<n> of <expected> patch scripts finished without error` and `FAILED:<names>` (`:139-141`), and exits 1.
- `setup.sh` treats any failure of `repatch.sh` as a problem (`cities-skylines-2/scripts/setup.sh:224-236`)
  and ends with exit 1 (`:301-305`); the core then adds "The install stopped..." (`common/install-core.sh:77`).
- The launcher says "Some patches could not be applied. Update and run setup: INSTALL.md, After a game
  update." at its start, and "WARNING: some fixes did not apply to the new game build" after it has
  updated the game (`cities-skylines-2/launchers/launch-cs2-dxmt11.sh:245`, `:377`), for every failure alike.

## 2. Design

### 2.1 The contract: one outcome per run of a patch script

| Exit | Meaning | What was written |
|---|---|---|
| 0 | The fix is in place in this file: written now, or found already there | the patch, and a `.bak` where the script makes one |
| 3 | **Not for this build.** The code this script changes was not found, and its own patch is not there either | nothing: not the file, not a `.bak` |
| any other | Something else went wrong: a missing file, a wrong argument, an ambiguous match, no room, a failed verification, a traceback | nothing, where the script can help it (2.2) |

3 is free in every script and in `repatch.sh` (which uses 0, 1 and 2), and Python gives it for nothing
by itself. Each script keeps its own words; only the code is the contract. "Exit 0 means the fix is in
place" must be true of every script, which is why 2.2 changes more than exit codes in two of them.

Exit 3 does not say the game was updated. It says the file is not one the script knows. A game update
is the usual cause; a file changed by something else is the other. 2.4's words name both.

### 2.2 The sixteen scripts, each read whole

**Three with a clean "not found" ending already: the code changes, nothing else.**

| Script | Ending that becomes exit 3 | Stays exit 1 |
|---|---|---|
| `patch_cohtml.py` | `notfound` (`:124-127`, exit at `:185`) | `ambiguous`, more than one site (`:129-131`); a missing file (`:158-160`) |
| `patch_longfile.py` | "GetFileHandle throw pattern not found" (`:75-78`) | a missing file (`:63-65`) |
| `patch_fshandle.py` | "FileStream.Init guard not found" (`:108-109`) | more than one candidate (`:110-112`); `--revert` with no `.bak` (`:89-90`); a missing file |

**The five `PDX.SDK.dll` scripts** (`patch_mkparent.py`, `patch_lockbypass.py`, `patch_longdelete.py`,
`patch_createfile.py`, `patch_lockleak.py`). Each holds a pasted copy of one shared block, and each
calls `die` for everything. The block gains a second function, `moved(msg)`: the same line, exit 3.
Each call of `die` is then either left as it is or made `moved`, by this rule: **`moved` when the
method, its body or the bytes it must hold are not as the script expects; `die` when the script found
what it expects and cannot finish.** By the inventory:

| Script | `moved` (exit 3) | `die` (exit 1) |
|---|---|---|
| `patch_mkparent.py` | type or method not found by name (`:196`, `:198`); RVA maps to no section (`:372`); body fat or of another size (`:385-386`); original IL differs (`:387-388`); a needed MemberRef absent (`:204`, `:359`) | IL does not decode (`:119`); new body no longer fits (`:394`); no room in `.text` (`:265`, `:268`, `:269`, `:283`); VirtualSize (`:297`, `:299`); verification (`:403-404`) |
| `patch_lockbypass.py` | not found by name (`:183`, `:185`); RVA (`:326`); body shape (`:328`); IL differs (`:330`); the two bytes (`:333`) | IL does not decode (`:106`) |
| `patch_longdelete.py` | per method: not found by name (`:181`, `:183`); RVA (`:325`); body too short (`:327`); tail not an instruction boundary (`:330`); an EH clause in the tail (`:332`); the byte (`:337`) | IL does not decode (`:104`) |
| `patch_createfile.py` | not found by name (`:198`, `:200`); `CreateFile` signature (`:344`); it has an IL body (`:345`); no `get_IsInvalid` MemberRef (`:206`); per method: RVA (`:368`), body shape (`:372-373`), IL differs (`:375`), another body in its slot (`:377`) | verification (`:385`); IL does not decode (`:121`) |
| `patch_lockleak.py` | everything in `locate` (`:234`, `:236`, `:386`, `:388`, `:396`, `:404`, `:407`, `:411`, `:417`) | IL does not decode (`:157`); the two `--revert` refusals (`:447`, `:451`) |

"IL does not decode" stays `die`: on a new build it would be a sign of the same thing, but it is also
what a damaged file gives, and a failure is the safe reading. A file that is not a .NET program at all
is a traceback today (what `dnfile` raises was not determined); it stays exit 1. `patch_longdelete.py`
and `patch_createfile.py` each change two methods and already write once, after both are checked, so
one moved method writes nothing; that is kept.

**The two that cannot tell "already patched" from "gone".** Each gains a search for its own patched
bytes, and a rule on the sum. Measured on the Studio's files at build 26404411, patched file against
its `.bak` (read only):

- `patch_colossal_io.py`. The two sites are 24 and 27 bytes (`0x84c6`, `0x87f8`), and in both the
  `beq.s` target is the byte after the `throw`. Patched, a site is `2B nn` followed by exactly `nn`
  bytes of `00` (`2b 16` and 22 zeros; `2b 19` and 25 zeros). The patched form to search for: `2B nn`
  with `nn` from 3 to 42 (what the original search's two windows allow, `:53`, `:63`), then exactly
  `nn` zero bytes, then a byte that is not zero. Run read-only on the real files, that search finds
  the two sites and nothing else in the patched file, and nothing in its `.bak`.
- `patch_asset_database.py`. One site (`0x18839`): `28 2c 05 00 0a 39 ...` becomes
  `26 16 00 00 00 39 ...`. The patched form: `26 16 00 00 00` where the original search wants its
  `call`, with the rest of that search unchanged (the `brfalse` five bytes on, `ldloc.s` and `call`
  after it, an `ldstr` 5 to 25 bytes back and a `call` 1 to 10 back, `:39-71`). Run read-only on the
  real files, it finds the one site in the patched file and nothing in its `.bak`.

The rule, for both, with `o` original sites, `p` patched sites and `E` the expected number (2 and 1):

| Found | Outcome |
|---|---|
| `o + p = E`, `o > 0` | patch the `o` sites; exit 0 |
| `p = E`, `o = 0` | already in place; exit 0 |
| `o = 0`, `p = 0` | exit 3 |
| anything else | exit 1, nothing written: "sites do not add up; refusing" |

This ends three things that exit 0 today: the moved pattern, one site of two patched with "Success!",
and more sites than expected patched with a warning. A site whose branch does not fit (`:117-119`)
becomes exit 1 with nothing written, where today the others are written. The patched forms are loose
(a run of zeros can be data), and they were measured on one build only. The sum guards that: a false
match makes the total wrong, and the wrong total is exit 1 with the script named, never 0.

`patch_longfile.py` patches every match when it finds more than one (`:79-80`); that becomes exit 1,
nothing written, as `patch_cohtml.py` and `patch_fshandle.py` already do.

**The six fixed-offset scripts** (`patch_dirdel.py`, `patch_delchild.py`, `patch_delfile.py`,
`patch_delrec.py`, `patch_dirrec_nx.py`, `patch_dirhandle.py`; off by default). Their "UNEXPECTED"
endings become exit 3 (`patch_dirdel.py:13-14`, `patch_delchild.py:13`, `patch_delfile.py:13`,
`patch_delrec.py:14-15`, `patch_dirrec_nx.py:15`, `patch_dirhandle.py:80-82`). `patch_dirhandle.py`
makes its `.bak` before any check (`:67-68`); the copy moves to just before the write, so exit 3 leaves
nothing. A missing argument or file is a traceback in five of them and stays exit 1.

Not changed here, and said so (2.8): each of the six reads one to seven bytes at a fixed offset, so on
an `mscorlib.dll` whose code moved the byte there is arbitrary, and a script can say "already patched"
or write into unrelated code. The contract is as sound for them as that test is.

### 2.3 `repatch.sh`

- `run` keeps three lists: finished (exit 0), not for this build (exit 3), failed (anything else).
- The closing lines, in this order: `<n> of <expected> patch scripts finished without error`; then
  `NO FIX YET FOR THIS BUILD: <names>` when that list is not empty; then `FAILED:<names>` as today.
- Exit: 1 when anything failed, or when the three lists do not add up to the expected number; else 3
  when any script was not for this build; else 0.
- The JetBrains stub (`:134-135`) runs under `set -e` before the summary, so a failure there ends the
  script with no summary at all. The summary moves above it.
- `== Done. Patched: ...` (`:137`) is printed whatever happened. It becomes `== Finished: ...`.

### 2.4 `setup.sh`, and PD1

`repatch.sh` exit 3 is a third case beside "every patch script finished" and "a problem":

```
  >> 1 of the 10 fixes does not fit this build of the game (build 26404411): patch_cohtml.py
     Without it: the game can crash while its menus are drawn.
     This is what a game update looks like until the fix for it is out. Everything else is in place,
     and the game may still start.
     Open the installer again in a few days: it fetches the current fixes. News: <address, PD2>
     If the game has not updated lately, have Steam verify the game's files, then open the installer
     again (INSTALL.md, "After a game update").
```

- From a checkout the fifth line is "Update this checkout (git pull) and run setup again. If it says
  the same, the fix is not out yet. News: ...", by the test `setup.sh` already makes (`L1_FETCHED_REF`,
  `:229`).
- The build is `buildid` of `steamapps/appmanifest_949230.acf`, two folders above the game's; when it
  cannot be read the parenthesis is left out.
- "Without it" is one line a script, from the table below; with several scripts, one line each.
- It is not counted in `problems`. The apps are built as on a clean run, and the Desktop question is
  asked (today it is skipped when there are problems, `:301-306`).
- Setup then ends `=== setup finished; 1 fix is not out yet for this build of the game: see the lines
  marked >> above ===` and, by PD1, **exit 5**. With a problem as well, the `!!` ending and exit 1 win,
  and both blocks are on screen.

| Script | Without it (the player's line) | From `cities-skylines-2/docs/patch-inventory.md` |
|---|---|---|
| `patch_cohtml.py` | the game can crash while its menus are drawn | row 1 |
| `patch_colossal_io.py` | the game can crash as it starts | row 2 |
| `patch_longfile.py` | error boxes when settings are read or saved | row 3 |
| `patch_asset_database.py` | the game can read a wrong file while it lists its assets | row 4 |
| `patch_fshandle.py` | settings go back to their defaults at every start | row 12 |
| `patch_mkparent.py`, `patch_lockbypass.py`, `patch_longdelete.py`, `patch_createfile.py`, `patch_lockleak.py` | mods may not download | rows 13 to 17 |
| the six errno scripts | deleting files and folders can fail, which breaks mod downloads on some Wine builds | rows 6 to 11 |

The lines say "can" and "may": whether build 1.6.4f1 on DXMT needs `patch_cohtml.py` at all is not
measured (the ledger's C72 is `PARTIAL`), and an earlier build reached the main menu without it
(GOTCHAS, 2026-11-02). The table lives in `repatch.sh` beside the calls, and `repatch.sh` prints the
line under `NO FIX YET FOR THIS BUILD`, so the launcher has it too.

### 2.5 The core's closing line

`common/install-core.sh`'s `on_exit` gains a case for 5 (`:73-78`):

```
The install is finished, except for a fix that is not out yet for this build of the game: the lines
marked >> above say which. The game's app is in Applications: <WORDS_DONE>.
```

"Done. Start the game" is not said, and neither is "The install stopped". The installer's header lists
5 with its other codes (`cities-skylines-2/scripts/install.sh:14-17`). The core does not know what a
fix is: 5 is "the game's setup finished short of a fix", and Surviving Mars's setup never gives it.

### 2.6 The launcher

`ensure_patches` returns what `repatch.sh` returned (`launch-cs2-dxmt11.sh:224-243`), and its two
callers say, for 3:

- at the start (`:245`): "A fix does not fit this build of the game yet (patch_cohtml.py). The game may
  still start. What to do: INSTALL.md, After a game update."
- after it updated the game (`:377`): "The update is in. A fix for the new build is not out yet
  (patch_cohtml.py); the game may still start. INSTALL.md, After a game update."

For any other failure the two lines of today stay. A note is two lines in a notification, so the names
are cut after the second with "and N more". The launcher's own line in its log names every script, from
`NO FIX YET FOR THIS BUILD`, as it takes `FAILED:` today (`:230`).

### 2.7 The guide, and where the news is (PD2)

`cities-skylines-2/INSTALL.md`, "After a game update", gains "When a fix is not out yet": what the
message means; that the game may start and what may be wrong until then, by the table of 2.4; that
opening the installer again (or `git pull` and setup) picks the fix up when it is out; that Steam's
"verify" is the answer when the game did not update; and where to look. `patches/README.md`'s "If a
game update breaks them" names exit 3. The root `CLAUDE.md` row for `repatch.sh` says what it prints.

### 2.8 What this plan does not do

- **The six fixed-offset scripts get no better test of what they change.** A sturdier one (the method
  found by name, as the `PDX.SDK.dll` scripts do since 1.6.2f1) is work of its own. An issue is opened
  for it at P1, and `patches/README.md` says which six are held to a weaker test.
- **No write becomes atomic.** Every script opens the live file with `'wb'`. A crash mid-write is not
  this plan's subject.
- **A `.bak` from an older build stays where it is.** The mscorlib and `PDX.SDK.dll` scripts make a
  `.bak` only when there is none, so after an update it is the old build's.
- **No list of known builds.** With one, exit 3 on a build in the list could be called damage and not
  an update. It would have to be kept in step with every re-derivation, and 2.4's words cover both
  causes without it.
- **Surviving Mars** has no patch scripts.

## 3. Steps

| Step | What | Files |
|---|---|---|
| P1 | The contract in the sixteen scripts (2.1, 2.2); the issue of 2.8 | `cities-skylines-2/patches/patch_*.py`, `patches/README.md` |
| P2 | `repatch.sh` (2.3), with the "without it" table (2.4) | `cities-skylines-2/repatch.sh`, `scripts/test-repatch.sh` |
| P3 | `setup.sh` (2.4) | `cities-skylines-2/scripts/setup.sh`, `scripts/test-setup.sh` |
| P4 | The core's closing line and the installer's header (2.5) | `common/install-core.sh`, `cities-skylines-2/scripts/install.sh`, `scripts/test-install.sh` and its transcript |
| P5 | The launcher's two notes (2.6) | `cities-skylines-2/launchers/launch-cs2-dxmt11.sh`, `scripts/test-launcher-notes.sh`, `common/test-launcher-parity.sh` if it reads those lines |
| P6 | The guide and the other documents (2.7); SF7's row and slice F's section say where it was built | `cities-skylines-2/INSTALL.md`, `patches/README.md`, `CLAUDE.md`, `docs/plans/shared-installer.md`, `docs/plans/first-run-findings.md` |
| P7 | The live step PL1 (section 5), on James's word | none |

P1 comes first and alone: until every script keeps the contract, `repatch.sh` must go on treating 3 as
a failure, which it does today. P2 to P5 can follow in that order, each with its tests. Between P1 and
P2 a script's exit 3 is a failure to every caller, as exit 1 is now, so no order of deployment says
"done" over a missing fix. The deployed copies in `~/cs2-patch` change only when setup is run.

## 4. Tests

Each is run with `HOME` at a scratch folder and starts nothing of Wine. A mutant is applied to the
source and must be seen red.

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| PT1 | `scripts/test-vendor.sh`, on files of zeros and on the real byte forms it already holds | For the byte-search scripts (`patch_cohtml.py`, `patch_longfile.py`, `patch_fshandle.py`, `patch_colossal_io.py`, `patch_asset_database.py`): a file with neither form is exit 3, the file is byte for byte as it was and no `.bak` is made; the original form is patched, exit 0; a second run is exit 0 and changes nothing; two sites where one is expected is exit 1 and nothing written. For `patch_colossal_io.py`: one original and one patched site is exit 0 with both patched after; one site alone is exit 1; a site whose branch does not fit is exit 1. The fixtures for these two are the measured bytes of 2.2 in a file of zeros | exit 3 made 1 in each; exit 3 made 0 in the two that return 0 today; the sum's rule dropped (one site of two says Success); the patched-form search dropped (a second run is exit 3) |
| PT2 | the same file | The six fixed-offset scripts on a file of `ff` long enough to hold every offset: exit 3 each, file unchanged, no `.bak` (`patch_dirhandle.py` among them); with the expected bytes at the offset: exit 0, and again exit 0 | `patch_dirhandle.py`'s `.bak` back before the check; one script's exit 3 made 1 |
| PT3 | a new `scripts/test-patch-outcomes.sh`, **only where the game is installed**: it says `SKIPPED: no game here` and exits 0 elsewhere, and the exit criteria ask for a run where it is not skipped | On clones of the real `PDX.SDK.dll` and its `.bak` in a scratch folder: each of the five scripts on the pristine file is exit 0 and on the patched one exit 0 with nothing changed; each on another of the game's .NET files under the name `PDX.SDK.dll` (the type is not found by name) is exit 3 with nothing written; each on a file that is not a .NET program is exit 1. And the source gate: in each of the five, the calls of `moved` and of `die` are those of 2.2's table, by line count | one `moved` made `die` in each script; `moved`'s exit made 1 |
| PT4 | `scripts/test-repatch.sh`, whose stub gains `STUB_NOFIX` | One script exits 3: exit 3, `9 of 10`, the `NO FIX YET` line with its name and its "without it" line, no `FAILED`; one 3 and one failure: exit 1, both lines; all ten 3: exit 3; the summary is printed when the stub folder cannot be made | 3 counted as finished; 3 counted as failed; exit 0 with a `NO FIX YET` line; the summary back under the stub |
| PT5 | `scripts/test-setup.sh` | `repatch.sh` exit 3: the `>>` block with the build read from a manifest in the scratch prefix, and without the parenthesis when there is none; the app built; the Desktop step reached; the closing line; exit 5; no `!!`. With `L1_FETCHED_REF` the installer's sentence, without it the checkout's. With a problem too: exit 1 and both blocks | exit 5 made 0; exit 5 made 1; the `>>` block counted in `problems`; the app not built on 3 |
| PT6 | `scripts/test-install.sh`, with its transcript recorded again on purpose | Setup's stub exits 5: the core's closing lines of 2.5, exit 5, neither "Done." nor "The install stopped" | the case for 5 dropped (it says "The install stopped"); 5 mapped to "Done." |
| PT7 | `scripts/test-launcher-notes.sh` | `repatch.sh` exit 3 at the start: exactly one notice, 2.6's first; after an update: the second; exit 1: today's two lines unchanged; three names: two and "and 1 more" | 3 treated as 1; the names not cut |
| PT8 | the gates | links; identifiers at the residual of 9; the experiments ledger; `bash -n`; `python3 -m py_compile` of the sixteen with no `__pycache__` left; every other test file of the repository | none |

## 5. The live step

- **PL1, on the Studio, on James's word. Nothing of Wine or Steam is started, and the real game folder
  is read only.** A scratch game folder is made of APFS clones of `Cities2.exe`, the four files the ten
  scripts change and their `.bak` files, restored to pristine from the `.bak`s.
  1. The patches as built, with `patch_cohtml.py`'s `fn-rbx` form taken out of a scratch copy of the
     script (the state of SL2): `repatch.sh` on the scratch folder gives exit 3, `9 of 10`, `NO FIX YET
     FOR THIS BUILD: patch_cohtml.py`, the plugin's file byte for byte as it was, and the other three
     files patched.
  2. The patches as built, whole: `10 of 10`, exit 0, and each of the four files has the sha256 of the
     real install's patched file.
  3. Again: `10 of 10`, exit 0, nothing changed.
  4. `PT3`, not skipped.
  Pass: all four. The real install is then brought to the new scripts by setup, and `boot-verify.sh`
  is run once, detached, with its log (the launcher and `repatch.sh` are on the boot path).

## 6. Exit criteria

- P1 to P6 are committed; PT1 to PT8 pass; every listed mutant was applied and seen red, with the count
  in the as-built header; the older mutants of the five test files touched are still red.
- PT3 was run where the game is installed, and its output is recorded.
- PL1 passed, and `boot-verify.sh` gave `VERDICT: PASS` on the real install with the new scripts.
- SF7's row and slice F's section name this plan and its commits; the issue of 2.8 is open and linked.
- PD1 and PD2 are decided and the words read by James.

## 7. Rollback

Each step is a commit on a branch, merged on James's word and never before PL1; a `git revert` of the
merge takes the scripts back. An install already brought to the new scripts goes back by running setup
from the reverted checkout: the scripts write the same bytes before and after this plan wherever they
write at all, so no game file needs restoring. Nothing published reads these files until the install
plan's NL3 has made `release`.

## 8. Decisions

| | Decision | Recommended | Why |
|---|---|---|---|
| PD1 | A run in which the only shortfall is a fix not yet out: which exit code (FD1 of the findings plan) | **5, a code of its own** | 0 would let "Done. Start the game" stand, and a script that reads the code would take a short install for a whole one. 1 says "stopped, open it again to carry on", which is untrue: there is nothing to carry on with |
| PD2 | Where the message sends a player for news | **The repository's issues, by a label for game updates** | The fix is announced where it is made. It commits the project to opening an issue when an update breaks a fix. The other choice is the guide alone, with no address that changes |
| PD3 | The six fixed-offset scripts | **The exit code only, and an issue for a sturdier test** | They are off by default and no engine in use needs them |
| PD4 | `patch_colossal_io.py` with one site of two, or with more than expected | **Refuse, exit 1, nothing written** | "Success!" over half a fix is the same untruth this plan removes elsewhere |
| PD5 | The words of 2.4, 2.5 and 2.6 | as drafted | They are the player's, so James reads them before they are built |

## Review log

No pass yet.

Key paths: `cities-skylines-2/patches/`, `cities-skylines-2/repatch.sh`,
`cities-skylines-2/scripts/setup.sh`, `cities-skylines-2/scripts/install.sh`,
`cities-skylines-2/launchers/launch-cs2-dxmt11.sh`, `common/install-core.sh`,
`cities-skylines-2/scripts/` (`test-vendor.sh`, `test-repatch.sh`, `test-setup.sh`, `test-install.sh` and
its transcript, `test-launcher-notes.sh`), `cities-skylines-2/INSTALL.md`,
`cities-skylines-2/docs/patch-inventory.md`.
