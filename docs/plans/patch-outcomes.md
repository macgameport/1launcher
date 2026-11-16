# A game update with no fix yet: what the patch scripts report, and what the player is told

> **Status:** Triple-checked 2026-11-15 — build-ready-with-fixes (pass 1: six lenses, three blockers and
> the other corrections folded into the sections they concern and listed in "Review corrections"; pass
> 1b: a fitted re-check of that fold, two blockers in the tests and the live step, folded too). Drafted
> 2026-11-15. PD1 to PD4 and PD6 were taken as recommended on 2026-11-15 (section 8), and P0 was
> recorded the same day (section 5). Nothing else is built yet. Tracking: issue #22. This is the plan that slice F of `docs/plans/first-run-findings.md`
> (2.4) and the row SF7 of `docs/plans/shared-installer.md` (section 9) wait for; decision FD1 of the
> first comes here as PD1. Every `file:line` is as of `main` at `324c92d`; the game's files were read,
> never written, on the Studio at build 26404411 (1.6.4f1), and every experiment ran on copies. A path
> is relative to the repository's root.

## 1. What is true today

Cities: Skylines II needs ten patch scripts (`cities-skylines-2/repatch.sh:67-70`, `:101-128`); six more
run only with `CS2_ERRNO_PATCHES=1` (`:80-90`). The ten change five files: the cohtml plugin,
`Colossal.IO.dll`, `Colossal.IO.AssetDatabase.dll`, `mscorlib.dll` and `PDX.SDK.dll`. When Steam updates
the game, the compiler may move the code a script changes. The script then finds nothing to change, and
the player is told the install stopped.

**Seen (SL2, 2026-11-12).** The game was at build 26404411, one build newer than the patches.
`patch_cohtml.py` found no pattern; nine of ten scripts finished; both apps were built; and the window
ended "=== setup finished with 1 problem(s): see the lines marked !! above ===" and "The install
stopped. The lines above say why. Open the installer again to carry on from that step." Opening it again
gave the same, and would have until a new pattern was published (it was, the same day: `e14bbae`). Two
days before, the launcher had said "some fixes did not apply" at the update itself, and nobody read it
(`cities-skylines-2/GOTCHAS.md:3158-3175`).

**Why nothing can say "no fix yet" today.** All sixteen scripts were read whole (2026-11-15; section
2.2 is the result):

- No script's exit code tells "the code I change is not in this file" from any other failure. The codes
  in use are 0, 1 and 2. "Not in this file" is exit 1 in fourteen scripts, shared with a missing file, a
  traceback, an ambiguous match and a failed verification.
- Only the text differs, in five forms: `WARNING: ... pattern not found` (`patch_cohtml.py:125`,
  `patch_longfile.py:75-78`); `UNEXPECTED ...` (the six fixed-offset scripts); `WARN next byte not ret`
  (`patch_delrec.py:15`); `ERROR: FileStream.Init guard not found` on stderr (`patch_fshandle.py:108`);
  and `UNEXPECTED: <msg> — refusing to patch (game updated? re-derive)` in the five `PDX.SDK.dll`
  scripts, where the same sentence also wraps failures that are not a moved pattern
  (`patch_lockbypass.py:27-29` is the function, with a copy in each of the five).
- **Two scripts end with exit 0 when their pattern is gone.** `patch_asset_database.py:92-94` and
  `patch_colossal_io.py:94-96` print "No ... patterns found. DLL may already be patched." and return:
  neither looks for its own patched bytes. `repatch.sh:138` says so in a comment.
- `patch_colossal_io.py` expects two sites. With one, or three, it prints a warning (`:98-102`), writes
  what it found (`:129-130`) and says "Success!" (`:167`), exit 0.
- **Both of those scripts copy the live file over the `.bak` before they decide anything**, whenever
  one original site is found (`patch_colossal_io.py:153-156`, `patch_asset_database.py:143-146`). Run on
  a copy with one site patched and one original, today's script replaced a pristine `.bak` with the
  half-patched file and said "Success!".
- `repatch.sh`'s `run` counts exit 0 as done and anything else as failed (`:55-58`), prints
  `<n> of <expected> patch scripts finished without error` and `FAILED:<names>` (`:139-141`), and exits 1.
- `setup.sh` treats any failure of `repatch.sh` as a problem (`cities-skylines-2/scripts/setup.sh:224-236`)
  and ends with exit 1 (`:301-305`); the core then adds "The install stopped..." (`common/install-core.sh:77`).
- The launcher says "Some patches could not be applied. Update and run setup: INSTALL.md, After a game
  update." at its start, and "WARNING: some fixes did not apply to the new game build" after it has
  updated the game (`cities-skylines-2/launchers/launch-cs2-dxmt11.sh:245`, `:377`), for every failure alike.
- **A `.bak` is not always this build's file.** On the Studio, `PDX.SDK.dll.bak` is 1,651,712 bytes
  dated 2026-10-10 beside a live file of 1,676,288 bytes dated 2026-11-10: the mscorlib and
  `PDX.SDK.dll` scripts make a `.bak` only when there is none, so an update leaves the old build's.

## 2. Design

### 2.1 The contract: one outcome per plain run of a patch script

| Exit | Meaning | What was written |
|---|---|---|
| 0 | The fix is in place in this file: written now, or found already there | the patch, and a `.bak` where 2.2 says one is made |
| 3 | **Not for this build.** Nothing of this script's patch is in the file, and the script cannot put it there because of what the file holds: the code is absent, changed, there more or fewer times than expected, or leaves no room | nothing: not the file, not a `.bak` |
| any other | Something else: a missing file, a wrong argument, a file that holds part of this script's patch in a way that does not add up, a file that cannot be read as what it should be, a failed check of the script's own edit, a traceback | nothing |

- 3 is free: no script, nothing in `patches/_vendor` and no line of `repatch.sh` uses it, and Python
  does not give it by itself (an uncaught exception and `sys.exit("text")` are 1; a missing script is 2).
- A missing file stays exit 1. If it were 3, a broken install would be told "no fix yet".
- The contract is for a plain run, as `repatch.sh` makes it. With `--dry-run` or `--revert`
  (`patch_fshandle.py`, `patch_lockleak.py`) a script keeps its own endings, and an exit 3 from inside
  is made 1 (2.2).
- Each script keeps its own words, but for the new lines 2.2 gives. Only the code is the contract.

Exit 3 does not say the game was updated. It says the file is not one the script can patch. A game
update is the usual cause; a file changed or damaged by something else is the other. 2.4's words name
both, and send the second to Steam's verify.

### 2.2 The sixteen scripts

**The three byte-search scripts with a "not found" ending already.**

| Script | Becomes exit 3 | Is exit 1 |
|---|---|---|
| `patch_cohtml.py` | `notfound` (`:124-127`), and `ambiguous` (`:129-134`) when no site among the matches is a patched one. They share one `sys.exit(1)` at `:185`: that line is split | a missing file (`:158-160`); `ambiguous` with a patched site among the matches (`:103` counts both kinds) |
| `patch_longfile.py` | "GetFileHandle throw pattern not found" (`:75-78`); more than one original site and none patched (today "patching all", `:79-80`) | a missing file (`:63-65`); one site patched and another original (today "Already patched", exit 0: `is_patched` at `:70-72` returns on the first patched hit) |
| `patch_fshandle.py` | "FileStream.Init guard not found" (`:108-109`); more than one candidate (`:110-112`) | `--revert` with no `.bak` (`:89-90`); a missing file |

**The five `PDX.SDK.dll` scripts** (`patch_mkparent.py`, `patch_lockbypass.py`, `patch_longdelete.py`,
`patch_createfile.py`, `patch_lockleak.py`). Four hold one pasted block byte for byte, and
`patch_mkparent.py` holds the same block with one function more (`ensure_text_vsize`). Every refusal
goes through `die` (exit 1), except a missing file and a missing argument (`patch_lockbypass.py:39`;
`patch_mkparent.py:366` is exit 2) and the two refusals of `patch_lockleak.py --revert` (`:447`,
`:451`), which use `sys.exit` and are not changed. The block gains a second function,
`moved(msg)`: the same line, exit 3. Every call of `die` becomes `moved` or stays, by 2.1's rule:

| Where | Calls | Class |
|---|---|---|
| the block, in all five | type or method not found by name, or found more than once (`patch_lockbypass.py:183`, `:185`); no MemberRef (`:191`); the four refusals of `text_slack` (`:252`, `:255`, `:256`, `:270`: no `.text`, no room, the room not empty, the room referenced) | `moved` |
| the block, in all five | "IL does not decode cleanly" (`:106`) | `die` |
| `patch_mkparent.py` | `:359`, `:372`, `:386`, `:388`; the two of `ensure_text_vsize` (`:297`, `:299`) | `moved` |
| `patch_mkparent.py` | "new body no longer fits a tiny header" (`:394`); "post-write verification failed" (`:404`) | `die` |
| `patch_lockbypass.py` | `:326`, `:328`, `:330`, `:333` | `moved` |
| `patch_longdelete.py` | `:325`, `:327`, `:330`, `:332`, `:337` | `moved` |
| `patch_createfile.py` | `:344`, `:345`, `:368`, `:373`, `:375`, `:377` | `moved` |
| `patch_createfile.py` | "post-write verification failed" (`:385`) | `die` |
| `patch_lockleak.py` | `:386`, `:388`, `:396`, `:404`, `:407`, `:411`, `:417` | `moved` |

- "No room in `.text`" is `moved`: the room is the linker's padding, which differs from build to build
  (88 bytes in the older build's file, at least 413 in this one, where the patch needs about 52), so a
  new build can give it first, and nothing the player does changes it.
- "IL does not decode" stays `die`. The decoder knows every opcode, so a new build decodes; a file that
  does not is damaged, and a failure is the true reading. The same holds for a file that is not a .NET
  program at all, which is a traceback today and stays one (measured: `pefile.PEFormatError` on zeros
  and on text, `AttributeError` on `Cities2.exe`, exit 1, nothing written).
- **Where an exit 3 from inside is caught and made exit 1:**
  - with `--dry-run` or `--revert`, in `patch_fshandle.py` and `patch_lockleak.py` (the second runs
    `locate` on the file at `:437` and on the `.bak` at `:449`);
  - where a script has already found part of its own patch in the file: the first method of
    `patch_longdelete.py` or `patch_createfile.py` already patched (`:334`, `:370`) and the second
    refused; `patch_mkparent.py`'s call of `ensure_text_vsize` on a file already relocated (`:379`);
  - where `patch_mkparent.py` resolves the method again in its own edited image (`:401`).
- `patch_longdelete.py` and `patch_createfile.py` each change two methods and write once, after both
  are checked (`:341-344`, `:379-387`); one moved method writes nothing. That is kept.
- **No `.bak` is made from a file that already holds the patch.** Today `patch_mkparent.py`'s "already
  relocated" branch writes (`:377-380`) and would make one if none exists; that write keeps no backup.
- Measured on copies, with today's scripts: another .NET file of the game under the name
  `PDX.SDK.dll` ends all five at "type ... matched 0 types", file unchanged, no `.bak`. That is the
  call 2.2 makes `moved`.

**The three byte-search scripts that learn to count** (`patch_colossal_io.py`, `E` = 2;
`patch_asset_database.py`, `E` = 1; `patch_longfile.py`, `E` = 1). With `o` known original sites and `p`
patched sites:

| Found | Outcome |
|---|---|
| `o = E`, `p = 0` | the `.bak` by the script's own rule (refreshed by `patch_colossal_io.py` and `patch_asset_database.py`, made only when there is none by `patch_longfile.py`), patch, exit 0 |
| `o + p = E`, `o > 0`, `p > 0` | patch the `o` sites; an existing `.bak` is left as it is and none is made; exit 0 |
| `p = E`, `o = 0` | already in place; nothing written; exit 0 |
| `p = 0`, `o` not `E` (none, fewer, more) | exit 3 |
| `p > 0` and `o + p` not `E` | exit 1: "part of this fix is in the file and the sites do not add up" |

Every row but the first two writes nothing. **The script classifies first**: the count and every check
of a site come before any byte is written to the file or to a `.bak`, which is the reverse of today
(`patch_colossal_io.py:153-156`, `patch_asset_database.py:143-146`). `patch_longfile.py` keeps its rule
of making a `.bak` only when there is none (`:82-86`). The fourth and fifth rows need new words, since
today's "DLL may already be patched", "No changes needed" and "patching all" would be untrue. Fourth
row: `WARNING: nothing of this fix is in the file and the code it changes is not as expected (<o> of
<E> sites). No change made.` (`patch_longfile.py` with no site keeps its own "pattern not found"
line, which a test reads.) Fifth row: `ERROR: part of this fix is in the file and the sites do not add
up (<o> original, <p> patched, <E> expected). No change made.`

What the two new searches look for, measured on the Studio's files at build 26404411 (patched file
against its `.bak`, read only, by three of the lenses independently):

- `patch_colossal_io.py`. The two sites are 24 and 27 bytes (`0x84c6`, `0x87f8`), and in both the
  `beq.s` target is the byte after the `throw`. Patched, a site is `2B nn` followed by exactly `nn`
  bytes of `00` and then a byte that is not zero (`2b 16` and 22 zeros; `2b 19` and 25 zeros; the next
  byte is `02` at both).
  - **A known original site** is a match of today's search (`:42-84`) whose `beq.s` target is the byte
    after its `throw` and whose length is 18 bytes or more. A match that is not that is not counted, so
    a file whose sites have another shape ends in the fourth row. Today a site with another target is
    patched with a branch the search below would never recognise, and a site whose branch does not fit
    is skipped while the others are written (`:117-119`).
  - **The patched form** is `2B nn` with `nn` from 16 to 42, exactly `nn` zeros, then a byte that is not
    zero. The floor is what keeps false matches away: with a floor of 3 (all the old search allows) the
    form matched ten places in a pristine `mscorlib.dll`, nine of them with `nn` = 3; with 16, none, and
    none in the other four files or their `.bak`s. A false match can still make a wrong sum right, so
    this is unlikely and not impossible.
  - Before the write, the patched-form search is run on the bytes about to be written and must find
    `E`; if not, exit 1 and nothing is written.
- `patch_asset_database.py`. One site (`0x18839`): `28 2c 05 00 0a 39 ...` becomes
  `26 16 00 00 00 39 ...`. The patched form: `26 16 00 00 00` where the original search wants its
  `call`, with the rest of that search unchanged (the `brfalse` five bytes on, `ldloc.s` and `call`
  after it, an `ldstr` 5 to 24 bytes back and a `call` 1 to 9 back, `:37-82`). It finds the one site in
  the patched file and nothing in its `.bak`.
- `patch_longfile.py` has its patched form already (`is_patched`, `:51-55`); it counts with it.

**The six fixed-offset scripts** (`patch_dirdel.py`, `patch_delchild.py`, `patch_delfile.py`,
`patch_delrec.py`, `patch_dirrec_nx.py`, `patch_dirhandle.py`; off by default). Their "UNEXPECTED" and
"WARN" endings become exit 3 (`patch_dirdel.py:13-14`, `patch_delchild.py:13`, `patch_delfile.py:13`,
`patch_delrec.py:14-15`, `patch_dirrec_nx.py:15`, `patch_dirhandle.py:80-82`). A file too short to hold
the offset is exit 3 in all six (today an `IndexError` in four). `patch_dirhandle.py` makes its `.bak`
before any check (`:67-68`) and writes on every run that ends well (`:87`): nothing is
written when the file already holds the patch and none of its two older edits needs undoing
(`:71-74`), and a `.bak` is made only just before a write to a file whose fix is not yet in. A
missing argument or file stays exit 1 or 2 as it is.

### 2.3 `repatch.sh`

- `run` keeps three lists: finished (exit 0), not for this build (exit 3), failed (anything else). It
  tests the code itself, not the `if` it has today (`:57`).
- The closing lines, in this order:
  1. `<n> of <expected> patch scripts finished without error`
  2. when any script was not for this build, `NO FIX YET FOR THIS BUILD: <names>`, and under it one
     line for each different consequence, `  without <names>: <what the player may see>`, from 2.4's
     table. Scripts with the same consequence share a line.
  3. `FAILED:<names>` as today, and today's line for lists that do not add up (`:141`).
  4. the JetBrains stub and its line. If it cannot be written, the line is `FAILED: the JetBrains
     Toolbox stub could not be written` and the run counts as failed.
  5. `== Finished ==`, in place of `== Done. Patched: <game folder> ...` (`:137`), which is printed
     today whatever happened. The folder is already on the run's first lines (`:45`), and leaving it
     out here keeps the home folder's path out of what a player pastes (2.7).
- Exit, after the last line: 1 when anything failed, or when the three lists do not add up to the
  expected number; else 3 when any script was not for this build; else 0.
- Today the stub (`:134-135`) runs under `set -e` before the summary, so a failure there ends the
  script with no summary. Above, the summary is printed first and the stub is still written on every
  run, as it is now.
- Two comments stop being true and are rewritten: "Every one writes a .bak on first run" (`:6-7`) and
  "two of the scripts cannot tell an applied patch from a moved pattern" (`:138`). The comment that
  teaches `cp <dll>.bak <dll>` (`:34-37`) gains: only when that `.bak` is this build's.

### 2.4 `setup.sh`, and PD1

`repatch.sh` exit 3 is a third case beside "every patch script finished" and "a problem". Setup does
not capture `repatch.sh`'s output (`:224`): its own block names nothing and points up, as the `!!` block
does today (`:228`).

```
  >> Not every Mac fix works with this build of the game (build 26404411). The NO FIX YET lines
     above name each one and say what you may see without it. The other fixes are in place.
     The usual cause: Steam has updated the game, and the Mac fix for the new build is not out yet.
     You can try the game. It may run well, or show what those lines name.
     <one line by the way setup was started>
     More, and where a fix in progress is listed: "When a fix is not out yet" in the guide: <the guide>
```

- The fifth line, by how setup was started, which it already knows (`L1_FETCHED_REF`, `:85`, `:229`;
  `CS2_VIA_INSTALLER`, `:297-300`):
  - from the pasted line or the installer app: `Open the installer again later: it fetches the newest
    fixes. Until the fix is out it says this again.`
  - from the installer in a clone: `Update your copy (git pull in its folder), then open the installer
    again. If it says this again, the fix is not out yet.`
  - plain setup: `Update this checkout (git pull) and run setup again. If it says this again, the fix
    is not out yet.`
- "The guide" is `$GUIDE` (`:84-85`): the file in a checkout, the web address on the fetched route,
  where there is no file. It is the one address the block prints (PD2).
- The build is `buildid` of `steamapps/appmanifest_949230.acf`, two folders above the game's, read with
  the launcher's `sed` form (`launch-cs2-dxmt11.sh:302-304`); when it cannot be read the parenthesis is
  left out.
- The block has no count and no name, so it has no plural and is the same with sixteen scripts.
- It is not counted in `problems`. The apps are built as on a clean run, and the Desktop question is
  asked (today it is skipped when there are problems, `:301-306`).
- Setup then prints the block it ends a clean run with (`:308-324`), every line of it but its heading
  `=== setup complete ===`, which leaves the heredoc so that it can be left out, and last of all
  `=== setup finished, but not every Mac fix is out yet for this build of the game: see the lines
  marked >> above ===`. By PD1 it exits **5**.
- When something else went wrong as well, the `!!` ending and exit 1 win, whether the other problem is
  a failed script (`repatch.sh` exit 1, where the `!!` block gains "A NO FIX YET line above, if there
  is one, names fixes that do not work with this build of the game") or a later step.

| Script | What the player may see without it | From |
|---|---|---|
| `patch_cohtml.py` | the game's menus may not appear, or the game may crash as they start | `cities-skylines-2/docs/patch-inventory.md:58`; `cities-skylines-2/INSTALL.md:410` |
| `patch_colossal_io.py` | the game can crash as it starts | `patch-inventory.md:59` |
| `patch_longfile.py` | error boxes when settings are read or saved | `:51` |
| `patch_asset_database.py` | the game can misread its list of assets; what that looks like in play is not known | `:60` |
| `patch_fshandle.py` | an error box at every start, and settings can go back to their defaults | `:52` |
| `patch_mkparent.py`, `patch_lockbypass.py`, `patch_longdelete.py`, `patch_createfile.py`, `patch_lockleak.py` | mods may not download (stuck at "Preparing") | `:73-77`; `INSTALL.md:411` |
| the six errno scripts | deleting files and folders can fail, which stops mod downloads on some versions of Wine | `patch-inventory.md:40-45`; `repatch.sh:73` |

The lines say "can" and "may". Whether build 1.6.4f1 on DXMT needs `patch_cohtml.py` at all is not
measured: the ledger's C72 is `PARTIAL`, and records that 1.6.2f1 on DXMT reached the main menu once
without it (`cities-skylines-2/EXPERIMENTS.md:1043`). The table lives in `repatch.sh` beside the calls,
and a test holds it complete (PT4).

### 2.5 The core's closing line

The core names no game and no step: each word comes from a setting (`common/install-core.sh:5-8`). It
gains one, `WORDS_NOFIX`, and `on_exit` (`:73-78`) a case: on 5, when the game's file set
`WORDS_NOFIX`, that sentence is the closing line; when it did not, 5 is any other code, as today.
Cities: Skylines II sets:

```
The install is finished, but not every Mac fix is out yet for this build of the game: the lines
marked >> above say more. You can try the game from Applications: <WORDS_DONE>.
```

It is printed as one line, and `on_exit` reads `${WORDS_NOFIX:-}`, since the installers run with
`set -u`. "Done. Start the game" is not said, and neither is "The install stopped". The installer's header
(`cities-skylines-2/scripts/install.sh:14-17`) gains: `5 = finished, but a Mac fix is not out yet for
this build of the game (setup's exit 5)`. Surviving Mars sets no `WORDS_NOFIX` and its setup has no
exit 5. Every layer above passes the code through and adds no words (`install.sh:119-120`; the root
`install.sh:88-89`, `:123-124`; the installer app's `.command` ignores it).

### 2.6 The launcher

`ensure_patches` returns what `repatch.sh` returned (`launch-cs2-dxmt11.sh:224-243`), and its log line
takes the `NO FIX YET FOR THIS BUILD:` line as it takes `FAILED:` today (`:230`), so the log names
every script. Its two callers become `ensure_patches || patches_note $? start` (`:245`) and
`... || patches_note $? update` (`:377`): one new function, with four fixed sentences.

| Code | At the start | After the launcher updated the game |
|---|---|---|
| 3 | `Not every Mac fix is out yet for this build of the game. It may still run. See INSTALL.md, After a game update.` | `The game is updated. Not every Mac fix is out yet for the new build; it may still run. See INSTALL.md, After a game update.` |
| other | today's sentence (`:245`) | today's sentence (`:377`) |

- No sentence holds a count or a patch script's name: a note is a notification of two lines for a few seconds,
  today's two are 89 and 95 characters, and these are 111 and 123.
- By PD6, when the launcher was started from the app (`QUIET=1`), the sentence after an update is
  shown as an alert that waits (`_alert`, `:56`, as `:83-84` uses it) in place of the notification,
  since this message was once a notification and not read. From a terminal it is a printed line, as
  every note is. At later starts it is a note.
- `test-launcher-notes.sh` takes the one line that begins `ensure_patches` (`:24`), which the new call
  still is; the second caller is inside the `update-check` block (`:297-379`), which
  `test-update-check.sh` drives with a stub of `ensure_patches` that always succeeds (`:101`, `:203`,
  `:232`). `patches_note` is defined outside that block; that test takes the function from the launcher, as
  `test-launcher-notes.sh:23` takes `ensure_patches`, stubs `_alert` to a recorded line, and gains a
  stub of `ensure_patches` that returns 3 and 1.
- `common/test-launcher-parity.sh` holds the first call (`:142`) and both of today's sentences word for
  word (`:162`, `:166`): they change with the launcher.

### 2.7 The guide, and where the news is (PD2)

`cities-skylines-2/INSTALL.md`, "After a game update" (`:367`), gains this section:

> **When a fix is not out yet.** After a game update, setup or the launcher may say that not every Mac
> fix is out yet for this build of the game. The lines beginning `NO FIX YET` name the patch scripts
> that do not work with the new build and say what you may see without each. The other fixes are in
> place, and you can try the game.
>
> A fix is out when the installer fetches it. Fixes in progress are listed at [the address of PD2]:
> look there first, and open an issue only if none is there for your build. When the fix is out, open
> the installer again (or, in a clone, `git pull` and run it again).
>
> If the game has not updated lately (the launcher's log says "Game updated to build ..." when it has),
> a file may be damaged. In the Steam inside the wrapper, right-click the game, Properties, Installed
> Files, Verify integrity of game files; then open the installer again. Verify puts every patched file
> back, and can bring a game update with it. After an update, never copy a `.bak` file back by hand: it
> may be the previous build's.
>
> If you ask for help, paste the lines from `NO FIX YET` down. The lines above them hold your home
> folder's path.

- "If one reports a miss, please open an issue" (`:396-397`) becomes a pointer to that section.
- The two rows of the troubleshooting table that answer "re-run setup" (`:410`, `:411`) gain "or see
  When a fix is not out yet", and `:410`'s symptom and 2.4's line for `patch_cohtml.py` say the same.
- `cities-skylines-2/patches/README.md`'s "If a game update breaks them" names exit 3, and says which
  six scripts are held to a weaker test (2.8). `cities-skylines-2/CLAUDE.md:15`, the row for
  `repatch.sh`, says what it prints. `cities-skylines-2/docs/patch-inventory.md:7`
  and `cities-skylines-2/scripts/README.md:32-37` are brought in line (and `setup.sh:22`, at P3).

### 2.8 What this plan does not do

- **The six fixed-offset scripts get no better test of what they change.** Each reads one to seven
  bytes at a fixed offset, so on an `mscorlib.dll` whose code moved a script can say "already patched"
  or write into unrelated code. A sturdier test (the method found by name) is work of its own. An issue
  is opened for it at P1.
- **`patch_fshandle.py`'s "already patched" test is looser than its search** (`:104-107`). It is clean
  on this build (no hit in the pristine file, one in the patched). It goes in the same issue.
- **No write becomes atomic.** Every script opens the live file with `'wb'`.
- **A `.bak` is not a way back after a game update.** The mscorlib and `PDX.SDK.dll` scripts keep the
  first `.bak` they made. `Colossal.IO.dll.bak` can hold `patch_longfile.py`'s change: when
  `patch_colossal_io.py` is not for a build and `patch_longfile.py` is, and the fix then arrives,
  `patch_colossal_io.py` refreshes the `.bak` from a file `patch_longfile.py` has patched. The guide
  says to verify instead (2.7).
- **No list of known builds.** 2.4's words cover both causes without one.
- **The launcher's notes go on naming `INSTALL.md`**, a file that a player who used the pasted line
  does not have. Both of today's notes do (`:245`, `:377`).
- **Surviving Mars** has no patch scripts.

## 3. Steps

Every path here is under `cities-skylines-2/` unless it begins with `common/` or `docs/`.

| Step | What | Files |
|---|---|---|
| P0 | Before anything is changed: PL1's reference hashes (section 5), from the scripts as they are at `main` | none in the repository |
| P1 | The contract in the sixteen scripts (2.1, 2.2), with PT1 to PT3; the issue of 2.8 | `patches/patch_*.py`, `patches/README.md`, `scripts/test-vendor.sh` (its three "exit 1" cases at `:85`, `:87` and `:109-110` become 3, and its mutant 4 is anchored again), a new `scripts/test-patch-outcomes.sh`, `scripts/README.md` |
| P2 | `repatch.sh` (2.3), with the table of 2.4; PT4 | `repatch.sh`, `scripts/test-repatch.sh` (its mutant 1 anchored again) |
| P3 | `setup.sh` (2.4); PT5 | `scripts/setup.sh`, `scripts/test-setup.sh` |
| P4 | The core's setting and the installer's header (2.5); PT6 | `common/install-core.sh`, `scripts/install.sh`, `scripts/test-install.sh` (its mutant 27 uses exit 5 as a wrong code: 6), `scripts/test-install.golden`, `surviving-mars-relaunched/scripts/test-install.sh` (`:315-316` uses 5 the same way: 6), and a copy of the installer without its `WORDS_NOFIX` line for PT6's second case |
| P5 | The launcher (2.6); PT7 | `launchers/launch-cs2-dxmt11.sh`, `scripts/test-launcher-notes.sh` (its mutants 1 and 3 anchored again), `scripts/test-update-check.sh`, `common/test-launcher-parity.sh` |
| P6 | The guide and the other documents (2.7); SF7's row and slice F's section say where it was built; the root `CLAUDE.md` names the new test file; the label `game-update` is made in the repository | `INSTALL.md`, `patches/README.md`, `CLAUDE.md`, `docs/patch-inventory.md`, `scripts/README.md`, the root `CLAUDE.md`, `docs/plans/shared-installer.md`, `docs/plans/first-run-findings.md` |
| P7 | The live step PL1 (section 5), on James's word | none |

- P1 can come first and alone: until `repatch.sh` changes, exit 3 is a failure to each of its three
  callers, as exit 1 is now (`repatch.sh:57`, the launcher's `:227-230`, `setup.sh:224-227`). Nothing
  else runs a patch script.
- P1 waits for PD3 and PD4, P3 for PD1, P5 for PD6, and P3 and P6 for PD2: the block and the guide
  cannot be written without the address.
- All of it is built on a branch. Between P2 and P5 the branch says odd things (after P3 and before P4
  the core answers 5 with "The install stopped"), so setup is not run on a real install from a commit
  between them, and nothing is merged before PL1.
- The deployed copies in `~/cs2-patch` change only when setup is run: it copies the launcher,
  `repatch.sh` and the scripts together (`setup.sh:171-184`), and the launcher never refreshes them.

## 4. Tests

Each is run with `HOME` at a scratch folder, except PT3, and starts nothing of Wine. A mutant is
applied to the source and must be seen red (exit 1, not REFUSED).

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| PT1 | `scripts/test-vendor.sh`, with the real bytes below in a file of zeros | For `patch_cohtml.py`, `patch_longfile.py`, `patch_fshandle.py`, `patch_colossal_io.py`, `patch_asset_database.py`: a file with neither form is exit 3, the file byte for byte as it was, no `.bak` made; no file there is exit 1; the original form is patched, exit 0; a second run is exit 0 and changes nothing; more original sites than expected and none patched is exit 3, nothing written. For `patch_cohtml.py`, one patched and one original form in a file is exit 1, nothing written. For the three that count: a fully original file beside an older `.bak` ends exit 0 with the `.bak` refreshed (`patch_colossal_io.py`, `patch_asset_database.py`) or kept (`patch_longfile.py`); one original and one patched site with a pristine `.bak` beside them ends exit 0 with both patched and the `.bak` byte for byte as it was (`patch_colossal_io.py`); a patched site beside sites that do not add up is exit 1, file and `.bak` unchanged; for `patch_colossal_io.py` one original site alone is exit 3, a site whose `beq.s` target is two bytes further is exit 3 and not written, and `2b 16`, 23 zeros and a non-zero byte is not a patched site | exit 3 made 1 in each of the five; exit 3 made 0 in the two that return 0 today; the count's rule dropped (one site of two says Success); the patched-form search dropped (a second run is exit 3); the `.bak` copied before the count again; the floor of `nn` put back to 3; a missing file made exit 3; `patch_longfile.py` "patching all" again |
| PT2 | the same file | The six fixed-offset scripts on a file of `ff` of 0x16cd00 bytes: exit 3 each, file unchanged, no `.bak`; on 4,096 zeros: exit 3 each; `7a` at `patch_delrec.py`'s offset with a next byte that is not `2a`: exit 3; with the expected bytes at the offset: exit 0, and again exit 0 with nothing written and, for `patch_dirhandle.py`, no `.bak` made by the second run; no file there: exit 1 | `patch_dirhandle.py`'s `.bak` back before the check; one script's exit 3 made 1; `patch_dirhandle.py` writing on an already patched file again |
| PT3 | the source gate in `scripts/test-vendor.sh`; the rest in a new `scripts/test-patch-outcomes.sh`, which finds the game by `CS2_GAME_DIR` or the default wrapper under the real home, clones what it reads into a scratch folder, and says `SKIPPED: no game here` with exit 0 elsewhere | **The source gate, with no game needed:** in each of the five, every call of `moved` and of `die` is the class 2.2's table gives it, matched on a fixed phrase of each message, taken from the lines the table names at `324c92d`, and not on line numbers (`matched`, `no MemberRef`, `.text`, `first section` are `moved`; `does not decode`, `no longer fits`, `verification failed` are `die`); the block has one sha256 in the four scripts that share it. **With the game:** each of the five on a clone of the installed, patched `PDX.SDK.dll` is exit 0 and changes nothing; each on another of the game's .NET files under that name is exit 3 with nothing written and no `.bak`; each on a file of zeros and on `Cities2.exe` is exit 1; each on a clone of an unpatched `PDX.SDK.dll` (the `.bak`, whose build the test prints) with one opcode of the method's IL replaced by `00` (a one-byte opcode, so the body still decodes; `28` or `fe` there gives "does not decode", exit 1) is exit 3 with nothing written; for `patch_longdelete.py` and `patch_createfile.py` the second method's opcode replaced is exit 3 with the first not written, and with the first method already patched it is exit 1; `patch_lockleak.py --revert` beside a `.bak` that is another of the game's .NET files is exit 1 (the catch), and beside the older build's `.bak` it is exit 1 (`:451`) | one `moved` made `die` in each script; `moved`'s exit made 1; the catch at `patch_lockleak.py --revert` dropped (it gives 3) |
| PT4 | `scripts/test-repatch.sh`, whose stub gains `STUB_NOFIX` | One script exits 3: exit 3, `9 of 10`, the `NO FIX YET` line with its name, its `without` line, no `FAILED`, the stub file still written, the lines in 2.3's order, no line beginning `== Done`; one 3 and one failure: exit 1, both lines; all ten 3: exit 3, ten names, and one `without` line for each of the six rows of 2.4's table that hold one of the ten (five scripts sharing one); with `CS2_ERRNO_PATCHES=1` all sixteen 3: every script named in a `without` line; one of the six: `15 of 16`, exit 3; one `run` line removed and one script 3: exit 1; the stub's folder cannot be made after ten successes: the summary, the `FAILED:` line for the stub, exit 1 | 3 counted as finished; 3 counted as failed; exit 0 with a `NO FIX YET` line; the summary back under the stub; a row of the table removed; the lists' sum not checked |
| PT5 | `scripts/test-setup.sh`, whose stub patchers gain `STUB_NOFIX` | `repatch.sh` exit 3: the `>>` block, with the build read from a manifest placed two folders above the game and without the parenthesis when there is none; the app built and the window builder called; the Desktop step reached and its line shown; `=== setup complete ===` not said; the closing line last; exit 5; no `!!`. The fifth line in each of its three forms (`L1_FETCHED_REF` set; `CS2_VIA_INSTALLER=1` alone; neither), anchored on that line, and the guide's address by the same test. `repatch.sh` exit 1 with a `NO FIX YET` line: exit 1, the `!!` block with its added sentence, no `>>` block. `repatch.sh` exit 3 and the app's builder failing: exit 1 and both blocks | exit 5 made 0; exit 5 made 1; the `>>` block counted in `problems`; the app not built on 3; the Desktop step skipped on 5; the fifth line's middle form dropped |
| PT6 | `scripts/test-install.sh`, with its transcript recorded again on purpose and the difference read line by line | Setup's stub exits 5: `WORDS_NOFIX`'s sentence, exit 5, neither "Done." nor "The install stopped"; in a copy of the installer with the `WORDS_NOFIX` line taken out, 5 gives "The install stopped" | the case for 5 dropped; 5 mapped to "Done."; the test of `WORDS_NOFIX` dropped |
| PT7 | `scripts/test-launcher-notes.sh` for the start, `scripts/test-update-check.sh` for after an update, `common/test-launcher-parity.sh` for the lists | `repatch.sh` exit 3 at the start: exactly one notice, 2.6's sentence, and the log line holds the `NO FIX YET` line with every name; exit 1: today's sentence; after an update with a stub returning 3 and `QUIET=1`: 2.6's second sentence, in the recorded `_alert` line and in no notification; without `QUIET`: the printed line; returning 1: today's; the badge step still runs after a 3 | 3 treated as 1 at each caller; the log line taking `FAILED:` only; the alert made a note |
| PT8 | the gates | links; identifiers at the residual of 9; the experiments ledger; `bash -n`; each of the sixteen compiled with `python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")'`, which writes nothing (`py_compile` leaves a `__pycache__` that fails `test-vendor.sh`, even with `-B`); no `__pycache__` in `patches/`; every other test file of the repository; every older mutant of the eight test files touched is exit 1 and none says REFUSED | none |

**The bytes of PT1** (build 26404411, from the `.bak`s; each in a file of zeros):

- `Colossal.IO.dll` site 1, 24 bytes, and the 4 after: `282700000a0d091f122e0d091472f802007028400000067a` `0228f301`
- site 2, 27 bytes, and the 4 after: `282700000a130511051f122e0e11051472f802007028400000067a` `0228fc01`
- `Colossal.IO.AssetDatabase.dll`, 26 bytes before the site, the site's `call`, and 12 after:
  `6f2a05000addb4020000110472b554007028cf00000a13071107` `282c05000a` `39980000001107282d05000a`
- `patch_longfile.py` and `patch_fshandle.py`: the test builds each form from the script's own
  constants (`PATTERN`; `ORIG` and `FINGERPRINT`, `patch_fshandle.py:47-50`).

**Not tested, and said so:** the catch at `patch_mkparent.py:401` (a failed re-resolve cannot be
provoked from outside) and at `:379`; "no room in `.text`" on a real file; the guide's
words beyond the links gate; the installer header's list of codes.

## 5. The live step

- **P0, before P1.** On the Studio, with the scripts as they are at `main`. A scratch game folder
  holds APFS clones of `Cities2.exe` and of the five files and their `.bak`s. Recorded outside the
  repository, beside the run's other files: each `.bak`'s size against its live file's, and, for a
  scratch folder restored from the `.bak`s, the sha256 of each of the five files after `repatch.sh`.
  The steam manifest is cloned for PL1's step 5; it holds an account's id and stays out of the
  repository.
  *Recorded 2026-11-15 in `~/cs2-patch/patch-outcomes-p0/` (`p0.txt`, with the script that made it), from
  the scripts at `207a10f`, game build 26404411. Four `.bak` files have their live file's size;
  `PDX.SDK.dll.bak` is 1,651,712 bytes against 1,676,288. Restored from the `.bak`s, `repatch.sh` gives
  `10 of 10` twice, and four of the five files then equal the installed ones; `PDX.SDK.dll` becomes
  `75fc59119adf...` (the older build patched), against the installed `c962431ae0af...`. On clones of
  the installed files it gives `10 of 10` twice and changes nothing.*
- **PL1, on the Studio, on James's word. Nothing of Wine or Steam is started, the game is closed, and
  the real game folder is read only.** A scratch copy of `repatch.sh` and of the whole `patches/`
  folder runs on the scratch game folder, restored from the `.bak`s as at P0.
  1. With `patch_cohtml.py`'s `fn-rbx` form taken out of the scratch copy (the state of SL2): exit 3,
     `9 of 10`, `NO FIX YET FOR THIS BUILD: patch_cohtml.py` and its `without` line, the plugin's file
     byte for byte as it was, and the other four files patched.
  2. The scripts whole: `10 of 10`, exit 0, and each of the five files has the sha256 P0 recorded for
     it. That is the claim of section 7. (`PDX.SDK.dll.bak` is the older build's file, so that one is
     the older build patched; today's scripts and this plan's must give the same bytes for it.)
  3. Again: `10 of 10`, exit 0, nothing changed.
  4. The scripts whole on clones of the five installed, patched files: `10 of 10`, exit 0, nothing
     changed, and no `.bak` made or changed.
  5. `setup.sh` run from a scratch copy of the branch's `cities-skylines-2/` and `common/` in which
     `patch_cohtml.py`'s `fn-rbx` form is taken out as in step 1 (setup installs the scripts of the copy
     it is run from, `setup.sh:27`, `:177-184`), with `HOME` at a scratch folder holding a stand-in
     wrapper as `test-setup.sh:102-108` makes one, the scratch game folder cloned to the path setup
     derives from the wrapper (`setup.sh:139`), and the manifest at
     `steamapps/appmanifest_949230.acf`: the `>>` block with build 26404411, the closing line, exit 5.
     Its output is what James reads for PD5.
  6. `PT3`, not skipped.
  Pass: all six. The real install is then brought to the new scripts by setup, with the game closed,
  and `boot-verify.sh` is run once, detached, with its log.

## 6. Exit criteria

- P0 is recorded; P1 to P6 are committed; PT1 to PT8 pass; every listed mutant was applied and seen
  red, with the count in the as-built header; every older mutant of the eight test files touched is
  exit 1, those whose anchors moved among them: at least `test-vendor.sh` 4, `test-repatch.sh` 1 and
  `test-launcher-notes.sh` 1 and 3, measured on a build of the plan before its fold, and whichever of
  `test-setup.sh`'s PT8 then finds.
- PT3 was run where the game is installed, and its output, with the build of the file it took as
  unpatched, is recorded.
- PL1 passed in all six steps, step 5's output is kept, and `boot-verify.sh` gave `VERDICT: PASS` on
  the real install with the new scripts.
- SF7's row and slice F's section name this plan and its commits; the issue of 2.8 is open and linked.
- PD1 to PD4 and PD6 are decided, and the words (PD5) read by James in step 5's output and in the
  guide's section.

## 7. Rollback

The work is on a branch, merged with `--no-ff` on James's word and not before PL1, so
`git revert -m 1 <the merge>` takes the scripts and documents back. An install already brought to the
new scripts goes back by running setup from the reverted checkout. No game file needs restoring:
wherever the scripts write a game file at all, they write the same bytes before and after this plan
(PL1's step 2 is the measurement). `.bak` files are not the same before and after: this plan makes
fewer of them. Nothing published reads these files until the install plan's NL3 has made `release`.

## 8. Decisions

| | Decision | Recommended | Why |
|---|---|---|---|
| PD1 | A run in which the only shortfall is a fix not yet out: which exit code (FD1 of the findings plan) | **5, a code of its own** | 0 would let "Done. Start the game" stand, and a script that reads the code would take a short install for a whole one. 1 says "stopped, open it again to carry on", which is untrue: there is nothing to carry on with |
| PD2 | Where the message sends a player for news | **The guide's section, which links the repository's issues under a new label, `game-update`** | One fixed address in words that are copied into `~/cs2-patch`, so a renamed label breaks nothing installed. It commits the project to opening an issue when an update breaks a fix, and to calling a fix "out" only once the branch the installer fetches holds it (`release`, once it exists) |
| PD3 | The six fixed-offset scripts | **The exit code and the backup's place only, and an issue for a sturdier test** | They are off by default and no engine in use needs them |
| PD4 | A file whose sites do not add up | **Nothing written: exit 3 when none of the fix is in the file, exit 1 when part of it is** | "Success!" over half a fix is the untruth this plan removes elsewhere; and a file with part of a fix is not a new build, so "no fix yet" would be untrue of it |
| PD5 | The words of 2.3 to 2.7 | as drafted here, after the check | They are the player's, so James reads them in PL1's step 5 and in the guide before the merge |
| PD6 | After the launcher has updated the game and a fix does not work with the new build: a notification, or an alert that waits | **An alert that waits, then a notification at later starts** | This message was a notification on 2026-11-10 and was not read. The alert comes once, at the moment the cause happens, and needs no record of what was shown |

**Taken 2026-11-15**, on James's "Yes, as recommended": PD1 to PD4 and PD6 as recommended. PD5 is taken
when he reads the words, at PL1's step 5 and in the guide.

## Review corrections (triple-check 2026-11-15)

Pass 1: six lenses on Fable 5.2, each against the source at `324c92d` and none editing the repository:
architecture and rollout, safety of the game's files, correctness, the test plan, words and platform
facts, and a builder who built P1 to P5 in a scratch clone with every test file run and 29 new mutants
seen red. All six said build-ready-with-fixes. Three blockers, each read against the source or the
Studio's files before it was accepted:

| | Finding | Lenses | Folded into |
|---|---|---|---|
| R1 | **Blocker.** The two scripts that count copy the live file over the `.bak` before they decide, so the rule "patch the sites still original" replaced a pristine `.bak` with a half-patched file (reproduced on a copy with today's script), and every new refusal still wrote a `.bak` | safety, architecture, test plan, builder | 1; 2.2 (classify first, the counting table); PT1 and its mutant |
| R2 | **Blocker.** PL1 could not pass: the ten scripts change five files, not four, and `PDX.SDK.dll.bak` on the Studio is the older build's file, so "restored to pristine" gave a mixed folder and the sha256 test failed for it | test plan, safety, builder, correctness | 1; section 5 (P0's reference hashes, the five files, step 4); PT3; section 6 |
| R3 | **Blocker.** PT1's fixtures for the two scripts could not work: a patched site in a file of zeros has no non-zero byte after it, and the plan held six bytes of one site and none of the others | test plan, safety, builder | the bytes under section 4 |
| R4 | "A false match makes the total wrong, never 0" was untrue: the patched form with `nn` from 3 matched ten places in a pristine `mscorlib.dll`, and a false match can complete a sum | safety | 2.2 (the floor of 16, the sentence) |
| R5 | The patched form is not what the script writes when a site's `beq.s` target is not the byte after its `throw`: one run exit 0, every later run exit 3 on a patched file | safety, correctness, builder | 2.2 (a known site; the check before the write); PT1 |
| R6 | Nineteen `die` calls of the pasted block were in neither column; two cited refusals are `sys.exit`, not `die`; the block is identical in four scripts, not five | correctness, test plan, builder | 2.2 (the table by message, the block classed once); PT3's gate |
| R7 | The rule for `moved` did not say what "no room in `.text`", "another body in its slot" and "more than one match" are. All are what the file holds and none can be changed by the player | safety, correctness, builder | 2.1 (the rule); 2.2 (the tables); PD4 |
| R8 | A re-resolve after the script's own edit, and `--revert` on a `.bak`, would have exited 3 | correctness, safety, builder | 2.2 (the list of catches); PT3 |
| R9 | A `.bak` could be made from an already patched file (`patch_mkparent.py`, `patch_dirhandle.py`) | safety, architecture, correctness | 2.2 |
| R10 | `patch_longfile.py` says "Already patched" with one site patched and one original | safety, correctness, builder | 2.2 (it counts too) |
| R11 | P1 could not land with the files it named: `test-vendor.sh` asserts exit 1 today and its mutant 4 is anchored on a line P1 rewrites; four older mutants in all end REFUSED once the plan is built | architecture, correctness, test plan, builder | section 3; PT8; section 6 |
| R12 | The after-update note had no harness, and the parity test reads the lines | architecture, correctness, test plan | 2.6; P5; PT7 |
| R13 | Setup does not capture `repatch.sh`'s output, so the count, the names and the `without` lines had no source, and a capture through `tee` loses the exit code | architecture, correctness, words, builder | 2.4 (the block names nothing and points up) |
| R14 | The exit-5 ending did not say whether the closing block is printed, and the Desktop answer is shown only there | architecture, correctness, words, builder | 2.4 |
| R15 | The summary's move left the exit and the stub's failure unsaid | architecture, correctness, test plan, builder | 2.3; PT4 |
| R16 | The words chose the wrong sentence for the installer run from a clone, the only route that works today; "a fix" did not say whose; "in a few days" promised what nothing backs; no plural was drafted; "Everything else is in place" came before the apps were built | words, safety, builder | 2.4, 2.5, 2.6 |
| R17 | The launcher's drafts were longer than any note today, named a file, and used the channel that failed for this message on 2026-11-10 | words, safety | 2.6; PD6 |
| R18 | The core would have held a game's words | architecture, words | 2.5 (`WORDS_NOFIX`) |
| R19 | The guide's words were not drafted; `INSTALL.md:396-397` asks every player to open an issue; `:410` and 2.4 named different symptoms; verify's effects and the stale `.bak` were unsaid; a pasted window holds the home folder's path | words, safety | 2.7; 2.8 |
| R20 | Rollback named a merge commit this repository did not make last time; "the same bytes" is true of game files and not of `.bak`s | architecture | section 7 |
| R21 | Cites: the evidence for "reached the menu without it" is the ledger's C72, not the GOTCHAS entry of 2026-11-02; the `repatch.sh` row is in the game's `CLAUDE.md`; test paths lacked their folder; several ranges were off by a line or more | correctness, architecture | 2.4; 2.7; section 3 |
| R22 | `py_compile` leaves the folder the gate forbids; a missing file had no test; `test-setup.sh` needs the stub switch too | test plan, builder | PT8; PT1, PT2; PT5 |

Measured by the lenses and kept as the plan's facts: the two patched-form searches find exactly the
real sites; `patch_longfile.py` and `patch_colossal_io.py` classify correctly in either order and end
at the installed file's sha256; today's scripts on the five `.bak`s give `10 of 10`, with four files
equal to the installed ones; exit 5 passes every layer above setup, and no layer adds words; a partly
patched set was not found to be worse than none (`repatch.sh:47-49`; SL2 ran nine of ten).

### Second-pass re-check (pass 1b, 2026-11-15)

One agent on Fable 5.2, not editing, read the fold against the source and against itself, with two
experiments on copies. Every cite of the fold held, the block's claim and the counting table's cover
were confirmed, and no leftover of the earlier design was found. Two blockers, both in the tests and
the live step, and the other corrections, folded:

| | Finding | Folded into |
|---|---|---|
| S1 | **Blocker.** PL1's step 5 could not show the `>>` block: setup installs the scripts of the copy it is run from, so from the branch it would have installed the whole `patch_cohtml.py` and ended `10 of 10` | section 5, step 5 |
| S2 | **Blocker.** The mutant "the catch at `--revert` dropped" could not be red with an older build's `.bak`: `locate` succeeds on it and the refusal is the `sys.exit` at `:451` (measured) | PT3 |
| S3 | 2.2 sent four cases with part of the patch in the file to exit 3, against 2.1 and PD4 | 2.2 (the first table's `patch_cohtml.py` row; the list of catches); PT1, PT3 |
| S4 | 2.1 said no refusal of `--dry-run` or `--revert` is exit 3 while 2.2 caught one call only | 2.1; 2.2 |
| S5 | "One byte of the IL changed" is exit 3 or exit 1 by the byte's value: two scripts decode the whole body first (measured) | PT3 |
| S6 | `test-update-check.sh` sources only the marked block, so it could not reach `patches_note` or `_alert`; whether the alert replaces the note was unsaid | 2.6; PT7 |
| S7 | PT6's second case had no harness | PT6; P4 |
| S8 | A third case of `test-vendor.sh` asserts exit 1 today | P1 |
| S9 | The guide told the player to paste from `NO FIX YET` down, and the line under it held the game folder | 2.3 (`== Finished ==`) |
| S10 | The block named the guide only for a game that had not updated | 2.4 (the sixth line) |
| S11 | Smaller: which words `patch_longfile.py` prints; "make or refresh the `.bak`" was not that script's rule; a header; "17 after" is 12; one catch, not two; "a file name"; one call in the parity test; eight test files; the heredoc's heading; six of the seven rows; the gate's wording; which decision each step waits for; the stub's failure line begins `FAILED:`; `patch_dirhandle.py`'s older edits; a case for the refreshed `.bak`; `WORDS_NOFIX` on one line | the sections they concern |

Not accepted, in either pass: "split 0 matches from more than one" for the by-name lookups. Both are what the file
holds, and the player can do the same about each, so both are exit 3 (R7).

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-15 | 1 | architecture and rollout, safety, correctness, test plan, words and platform facts, builder simulation | six agents, none editing the repository; experiments on copies of the game's files; the builder in a scratch clone with the tests run; each blocker read against the source inline | Fable 5.2 | `main` at `324c92d` | build-ready-with-fixes, folded |
| 2026-11-15 | 1b | the fold of pass 1 | one agent, not editing; two experiments on copies (`--revert` beside the older `.bak`; one byte of a method's IL changed) | Fable 5.2 | the same | build-ready-with-fixes, folded |

Key paths: `cities-skylines-2/patches/`, `cities-skylines-2/repatch.sh`,
`cities-skylines-2/scripts/setup.sh`, `cities-skylines-2/scripts/install.sh`,
`cities-skylines-2/launchers/launch-cs2-dxmt11.sh`, `common/install-core.sh`,
`cities-skylines-2/scripts/` (`test-vendor.sh`, `test-repatch.sh`, `test-setup.sh`, `test-install.sh` and
`test-install.golden`, `test-launcher-notes.sh`, `test-update-check.sh`),
`common/test-launcher-parity.sh`, `surviving-mars-relaunched/scripts/test-install.sh`, `cities-skylines-2/INSTALL.md`,
`cities-skylines-2/docs/patch-inventory.md`.
