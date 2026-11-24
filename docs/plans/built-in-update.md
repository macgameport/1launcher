# A built-in update: 14unch3r says when a new version is out, and one click runs the installer again

**Status: check-it'd 2026-11-24 — build-ready-with-fixes (pass 2, the re-check after the merge, folded).** Pass 1
(2026-11-23) said needs-rework and the plan was reworked the same day; pass 1b, two fitted re-checks of the
rework, said build-ready-with-fixes and is folded; pass 1c verified that fold. `wrapper-names` was merged into
`main` on 2026-11-24 (`35f0eb8`, the commit of `v0.3.0`), `main` was merged into this branch, and pass 2 read
every cite again against that tree: no blocker, ten corrections, folded ("Pass 2" at the foot). **Built through U5 on the branch on 2026-11-24** (as-built header below); the live steps of section 7 have not run, and nothing is merged or released.
The merge changed two things this plan leans on: `common/test-launcher-parity.sh` now has a rule 10 and mutants
up to 24, so this plan's new rule is 11 and its mutants start at 25; and the launchers' shared block gained
`signin_wait`, so its notice block sits in launchers that wait up to ten minutes for Steam's sign-in.
Written 2026-11-23 on the branch `built-in-update`, cut from `wrapper-names` at `efe176b`; every `file:line`
below was read at that commit and again at `35f0eb8`, where the seven that had moved were corrected. Pass 1's findings, and where each went, are at the foot ("Review corrections").
Tracking: issue #34 (opened 2026-11-23); the two defects of step U0 are on record as issue #31. James answered the fifteen decisions of section 9 on
2026-11-23: fourteen as recommended, which is what the design below is built on, and UD9 his own way (the
release that carries this raises the third number).

> **🔧 As-built (2026-11-24): partial — steps U0 to U5 built on the branch `built-in-update` (pushed, not
> merged, not in `release`); step U6 not started: no live step of section 7 has run, UL4 (the first real
> offer) can only come at the first release after the one that carries this, and UD5's rulesets are not set.**
> Commits: `fb0213e` (U0), `f234c3e` and `797b97e` (U1), `146f711` (U2), `0a93b3b` (U3), `df5a5a6` (U4),
> `b9b5bfd` (U5), in the order U0, U1, U2, U4, U5, U3: U3 and U4 were built side by side on separate files,
> and U5's words were written while the window was still being built. U0 and the first part of U1 were built
> by the session; the second part of U1, U2, U3, U4 and the gate of U5 by builder agents from this plan, each
> read by the session and every gate of each run again before its commit (clean runs, and every new mutant
> seen red; the older mutants of the touched files were swept on frozen copies of the commits).
> **The last sweep (2026-11-24):** on a frozen copy of `3aa0832`, every test file and every mutant of every
> test file this plan touched. It found one red file, `common/test-paths.sh`: U3's new cases in
> `common/test-make-launcher-app.sh` spelled the data root, which LT14 allows only in a fixed list of files;
> fixed in `32ee477` (the folder is asked of `paths.sh`). Of 425 mutant runs 424 were red and one refused:
> Cities: Skylines II's `test-setup.sh` 36, retired on 2026-11-21. At `32ee477` all 46 test files exit 0.
> Deviations from the text above:
> - **`common/updates.sh` has one function 3.2 does not list, `l1u_stamp_of <app ID>`** (the line and the
>   version of a game's stamp): both setups' closing words and the driver ask it, so that nothing outside the
>   file reads a stamp. And `l1u_stamp` records `L1_FETCHED_COMMIT` only for a fetched tree: one left in the
>   environment says nothing about a checkout.
> - **The driver's words beyond 3.4.** The sentences of step 4 are printed once, in the closing block under
>   "=== The update ===", not during the walk; a game that ran gets a line of its own ("`<title>`: updated.",
>   and one each for exit 5, exit 3 and a failure); it refuses any argument and tests for its own files
>   first; INT, TERM and HUP release the lock. In the root `install.sh` the word `update` passes the test of
>   the first word as the stand-in `0`, and an option after it gets its own sentence.
> - **The gate's fifth question prints one FAIL line for each part that does not hold**, counts a failed
>   `git ls-remote` as a failure of its own, and writes the changelog to one temporary file, which it
>   removes. Like questions 3 and 4 it reads local tags, so a `v` tag not yet pushed satisfies it.
> - **The window.** Two names beyond 3.5's seam table: `Call` (the four calls with their limits) and
>   `askState`. The menu item is switched off through `validateMenuItem`. `Look`'s new constants: `footGrowX`,
>   `footGrowY`, `footRadius`, `notesW`, `notesH`, `notesInset`, `notesFont`, `foot()`, `footSpoken()`,
>   `out()`, `has()`, `updateText`, `notNow`, `update`, `ok`, `notesLabel`, `notesAddress`, `quitFirst()`,
>   `quitFirstText`, `notOpened`, `noAnswer`, `checkItem`, `checkKey`, `offMessage`, `offText`, `noneMessage`,
>   `noneText`, `manualMessage`, `checkoutText`, `namedText`, `unreadMessage`, `unreadText`, `newest()`,
>   `newestText`. Measured in the text modes: one game with the line is 444 by 196, contrast 9.63.
> - **More mutants than section 6 lists**, each seen red: three for `--open` in `common/test-updates.sh`
>   (21 to 23) and one for the stamp (20), two more in the parity test (27, 28), ten in the new
>   `common/test-update-notice.sh`, one in the gate's test (11), one in `common/test-make-launcher-app.sh` (10).
> - **The guides say "from v0.3.1"** (README, both `INSTALL.md`, both games' READMEs). That is this plan's
>   release only if it is the next one after `v0.3.0`: if the launcher fix of issue #32 is released first, the
>   number in them changes with it.
> - **Not judged by any test, and still to be read off the screen at UL1:** the sheet's focus, Return and
>   Escape; the notes view in light and dark; the window growing when the first answer arrives; the menu item
>   and Command-U; hover, the cursor and VoiceOver on the line. One oddity is known: with a `release` stamp
>   whose tree had no version heading, the menu's row 7 would read "1launcher - is the newest version."
>
> **Verify against:** `common/updates.sh`, `common/update-games.sh`, `common/paths.sh`, `install.sh`,
> `common/install-core.sh` (`core_space`), `common/make-installer-app.sh`, `common/make-launcher-app.sh`,
> `common/launcher-window.swift`, `common/check-release-move.sh`, `common/check-deploy.sh`, both games'
> `scripts/setup.sh` and `scripts/install.sh`, both launchers (the block between `# >>> update-notice` and
> `# <<< update-notice`), and the tests `common/test-updates.sh`, `common/test-update-games.sh`,
> `common/test-update-notice.sh`, `common/test-bootstrap.sh`, `common/test-make-installer-app.sh`,
> `common/test-launcher-window.sh`, `common/test-make-launcher-app.sh`, `common/test-launcher-parity.sh`,
> `common/test-check-release-move.sh`, both games' `scripts/test-setup.sh` and `scripts/test-install.sh`.

James asked on 2026-11-23: "How do we make the app have a built in auto update process? I'd especially like
this for when we add compatibility with additional games."

The short answer this plan builds: **the update is the installer, run again for you.** Both installers already
say of themselves "on a finished install it is the way to update" and skip every step that is done. What is
missing is that an installed Mac does not know which version it has, never asks whether a newer one is out,
and has no button that runs the installer. This plan adds those three things and nothing that updates files
by a second route.

## 1. What is true today (read and measured 2026-11-23)

### 1.1 The installer is already the update

- `cities-skylines-2/scripts/install.sh:2-6` and `surviving-mars-relaunched/scripts/install.sh:2-7`: "each
  skipped when it is already done ... on a finished install it is the way to update (setup runs every time)".
- Measured on the Studio, both games set up, with `--check` (which starts, downloads and changes nothing):
  every step of both installers prints `OK` and the last says "would run setup.sh". Cities: Skylines II took
  1 s to that point and Surviving Mars under 1 s. How long setup itself takes on a finished install was not
  measured (live step UL2 measures it).
- One line of that run is wrong for an update: Cities: Skylines II printed `CAUTION: 80 GB free. The game
  with its DLC takes about 100 GB ...` although the game is installed. `core_space`
  (`common/install-core.sh:346-353`) compares free space with what a new install needs and does not look at
  whether the game is there. Both installers call it right after `core_begin`, `core_mac` and `core_tools`.
- A run at a terminal without `--yes` can ask three things: Rosetta (`common/install-core.sh:310-318`),
  Surviving Mars's question before anything of Apple's is fetched, and Cities: Skylines II's setup's "Put a
  14unch3r shortcut on the Desktop? [y/N]", which is asked at every such run while no shortcut exists
  (`cities-skylines-2/scripts/setup.sh:506-518`).
- The root `install.sh` fetches `https://github.com/macgameport/1launcher/archive/<ref>.tar.gz` (`:95-97`),
  reads the commit from the archive's header (`:106`), prints it (`:121`), exports `L1_FETCHED_REF` (`:122`)
  and runs the game's installer (`:123`). The ref defaults to `release`. A first word that is not a number is
  refused before anything is fetched (`:68-74`). A `git archive` of the tree at `efe176b` is 16.5 MB gzipped.
- The installer app (`common/make-installer-app.sh:5-6`; its program is the heredoc `EOS`, `:90-105`) writes
  a `.command` file into a temporary folder and opens it in Terminal, where it takes the root `install.sh`
  from curl's standard output (`S="$(curl ...)"`, `:95`) and runs it: "opening it again is the update". No
  installer app has been released.

### 1.2 What an installed Mac knows about itself

Nothing. The commit is printed and the temporary folder removed (`install.sh:93`, `:121`). No setup writes a
version, a ref or a commit anywhere: the only version-like values in `common/`, both `scripts/` folders and
`install.sh` are `CFBundleVersion` constants of the app builders. `L1_FETCHED_REF` is read by Cities:
Skylines II's setup for its words only (`cities-skylines-2/scripts/setup.sh:99`, `:139`, `:225`, `:432`,
`:458`).

### 1.3 The window

- 14unch3r lists the apps in `~/Applications` whose `Info.plist` carries `L1Role`
  (`common/launcher-window.swift:1-6`), and after a start it quits (`:1469`).
- It already shows a ported game that is not set up, as an offer: a row of role `offer` (`:31`), made by
  `offerRows` (`:470`) from `games.tsv` for each game with no game row **that Steam's own package cache says
  the account owns** (`askOwned`, `:436`). Its full second line is "Not set up on this Mac. Opens the set-up
  guide." (`:165`), and a click opens the guide in the browser, with no question (`startChosen`, `:1434`).
- The table it reads is the copy inside its own bundle, `Contents/Resources/games.tsv` (`:1292`), which
  `common/make-launcher-app.sh:76` copies at build time. So a game added to the repository shows as an offer
  only after a setup has run again and rebuilt the window.
- Anything that could stall the window is asked of a child process with a time limit. `runChild` (`:390`)
  returns the child's output only when it exited 0 within the limit (`:427-430`), and sends its standard error
  nowhere (`:400`).
- Its one question is an `NSAlert` shown as a sheet, with the safe answer first (`:1441-1448`). The key
  monitor ends a sheet on Escape as the first button and passes Return to it, but only when the delegate's
  `sheet` records that one is up (`:791-798`, `:1315`). The sheets, the launch and the menu live in the app
  delegate, which no text mode builds: the tests reach the question through a pure function behind `--second`
  and drive only the grid with `--act` (`:1172-1220`).
- Its menu holds one item, "Quit 14unch3r" (`:1318-1319`). Its one preference is `lastAppID` (`:1466`).
- Both setups build it: `surviving-mars-relaunched/scripts/setup.sh:215-216` and
  `cities-skylines-2/scripts/setup.sh:479-482`.
- `docs/plans/launcher-window.md` says of it today: "The window sends nothing anywhere."

### 1.4 The launchers

- Each launcher's only update step is the game's own, through Steam (`step 4 "Checking for a game update…"`,
  `surviving-mars-relaunched/launch-relaunched.sh:478`; `cities-skylines-2/launchers/launch-cs2-dxmt11.sh:413`).
- `note` (`launch-relaunched.sh:124`, `launch-cs2-dxmt11.sh:63`) is "something the player should see even
  while the progress window is up": a line in the log and, from the app, a notification. The notification is
  `osascript ... display notification`, with the text passed as an argument.
- A deployed launcher finds `wrappers.sh` beside itself (`launch-relaunched.sh:73-82`), and
  `common/test-launcher-parity.sh` holds the blocks the two launchers share equal byte for byte (rule 9) and
  records every `note` call in two lists that must match exactly (rule 5).
- Both launchers put the Wine engine's `bin` first on `PATH` (`launch-relaunched.sh:89`).

### 1.5 What GitHub, curl and macOS answer (measured from the Studio: `/usr/bin/curl` 8.7.1, bash 3.2.57, macOS 27.2)

| Asked | Answer |
|---|---|
| `https://raw.githubusercontent.com/macgameport/1launcher/release/CHANGELOG.md` | 200, 1,853 bytes, 0.17 to 0.25 s; `cache-control: max-age=300`; `content-length` present on every try |
| the same file at `.../1launcher/refs/heads/release/CHANGELOG.md` | 200, the same bytes. `archive/refs/heads/release.tar.gz` answers too, with the same commit |
| a ref that does not exist, with `-f` | **curl exit 56** over HTTP/2, 22 with `--http1.1` |
| the same without `-f`, body to a file, `-w '%{http_code}'` | exit 0 and `404` on both protocols; with no network, `000` and a non-zero exit |
| `--max-filesize 100` | exit 56 over HTTP/2 and 63 over HTTP/1.1, nothing kept. Before curl 8.4.0 it does not bound an answer of unknown length (`man curl`) |
| `-w '%{http_code}'` on a curl whose standard output is captured as the script | the code becomes the script's last line |
| a tag named `release` beside the branch | none exists; which one the short name would then give is not established |
| the first version heading of `CHANGELOG.md` at each tag | `v0.1.0`: `## v0.1.0 (2026-11-16)`; `v0.2.0`: `## v0.2.0 (2026-11-17)`; `## Unreleased` above both |
| `release` on GitHub | at `ce2fcd0` (the commit `v0.1.0` names); **not protected**; no rulesets. Its `install.sh` answers `update` with "not a Steam app ID: update" and fetches nothing |
| a `.command` written by bash from a program that is not quarantined | no `com.apple.quarantine`; mode 644, so it must be made executable. At NL2 (`docs/plans/simple-install.md`) a `.command` written by a quarantined app ran in Terminal with no further question |
| `mktemp` with a suffix after the X's | the name is not randomised |
| `read -r` on a line with no final newline | the fields are set and the exit code is 1; an empty field shifts the rest |
| a notification from `osascript` | by reports, macOS shows Script Editor as the sender, a click opens Script Editor, and nothing shows until Script Editor may notify. Not measured on a new Mac |
| which curl macOS 14 and 15 ship | not established; the fetch rule of 3.2 does not depend on it |

So one small request to an address family the project already depends on for ever (the pasted line reads
`raw.githubusercontent.com/.../release/install.sh`) says which version `release` holds and what changed in
it. An answer can be up to five minutes old.

### 1.6 Two defects found on the way

1. `install.sh:98` tells "GitHub has no such ref" from "GitHub could not be reached" by curl's exit code 22,
   and so does the installer app's program (`common/make-installer-app.sh:98`). On this Mac curl exits 56 for
   a 404. So a ref that does not exist is reported as "GitHub could not be reached (curl exit 56). Check the
   network", and the installer app's "This installer has been withdrawn or has moved" can never be printed.
   `common/test-bootstrap.sh` serves its fixtures from a stub curl, so it could not see this.
2. The free-space caution on a finished install (1.1).

### 1.7 Conferring with the sibling repositories

`grep -rIlE 'self-update|auto-update|check for updates'` over the siblings' `docs/` and `CLAUDE.md` finds
nothing about an app that updates itself. No precedent to adopt, none declined.

## 2. Target

1. A Mac set up by the pasted line knows which version of 1launcher each game was set up from.
2. By itself, at most once a day, when 14unch3r opens or a game starts, the Mac asks GitHub which version
   `release` holds. If the network is down, nothing is said and the game starts as before.
3. When a newer version is out, 14unch3r shows it, with what changed. One click, and a yes, opens Terminal
   and runs the installer again for every game set up on that Mac. Nothing is ever installed without that yes.
4. A game added to the repository reaches every such Mac with the update: after it, the window offers the
   game to the players whose Steam account owns it, as it offers an unported game today.
5. A Mac where any game was set up from a checkout or from a named version is never offered an update and
   never asks GitHub anything.

## 3. Design

### 3.1 The record

A new folder beside the games' state folders: `<data root>/_update`, where the data root is
`common/paths.sh`'s `L1_DATA_ROOT` (`~/Library/Application Support/1launcher`). `paths.sh` gains
`L1_UPDATE_DIR="${L1_UPDATE_DIR:-$L1_DATA_ROOT/_update}"` and prints it as a seventh line. The name starts
with `_`, which no game folder can (`install.sh:22` and `:29` admit `^[a-z0-9][a-z0-9-]*$` only). It is a new
place outside the repository (UD13).

| File in `_update/` | What | Written by |
|---|---|---|
| `installed/<Steam app ID>` | the stamp: one line, four fields, tab-separated: the line the game follows, the version, the commit, the time (epoch seconds) | that game's setup, at its end |
| `offer` | one line: the version `release` held at the last fetch that worked, and its time | the check |
| `tried` | one line: the time of the last attempt to fetch, whether it worked or not | the check, before it calls curl |
| `notes.md` | `CHANGELOG.md` as last fetched | the check |
| `noted` | one line: the version the launchers last announced, and how often (1 or 2) | the check, for a launcher |
| `off` | if it exists, nothing is ever fetched. Made by hand | the player |
| `updating` | a link to the process number of a running update, in the launchers' lock form | `common/update-games.sh` |
| `updates.sh` | the deployed copy of `common/updates.sh` | each setup |

- **The line a game follows** is `L1_FETCHED_REF` when the root `install.sh` fetched the tree (`release` for
  every player), and the word `checkout` otherwise.
- **The version** is the first line of the tree's `CHANGELOG.md` that matches
  `^## v(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5}) \(`, written `v<a>.<b>.<c>`, or `-`
  when there is none. `CLAUDE.md` § Releases fixes that heading form; nothing checks it today (the release
  commands print a count that a person reads), and 3.7 makes it a check.
- **The commit** is the 40 hex digits the root `install.sh` read from the archive (`:106`), which it now
  exports as `L1_FETCHED_COMMIT` without the `comment=` in front, or `-`.
- **Every value read from `_update` is matched whole before it is used.** A version: the pattern above
  without the `## ` and the ` \(`, or `-`. A time: `^[0-9]{1,12}$`, then used as `$((10#...))`. A line:
  `^[A-Za-z0-9._/-]{1,100}$`. A commit: 40 hex digits or `-`. A count: `1` or `2`. A process number: `^[1-9][0-9]{0,9}$` (`updating` is the
  one link in `_update`: it is read with `readlink`, and its target is matched as a process number). A file that is a link, is
  not a regular file, is over 4,096 bytes, or fails its match is treated as absent; in `installed/` it is
  passed over. A file is read on one descriptor: its first line with `IFS=$'\t' read -r a b c d rest`, counted also when it
  has no final newline, and then a second read, which must find nothing. It counts only when every field is
  non-empty, `rest` is empty and there is no second line. A version is matched with bash's `[[ =~ ]]` and the
  pattern held in a variable (as a quoted literal it matches nothing under bash 3.2, and `grep -x` matches line
  by line, so it would pass a value with a second line). No value reaches `[ -gt ]`, an arithmetic test in `[[ ]]` or `$(( ))` before
  its match, and nothing in `_update` is ever read with `.` or `eval`. (Under bash 3.2 a value such as
  `a[$(cmd)]` in an arithmetic place runs `cmd`.)
- A stamp is written beside its place and renamed over it.
- A setup writes its stamp when it has finished its work: exit 0, and for Cities: Skylines II exit 5 too
  (finished, a fix not out yet for this game build). With `--check`, `--mac-only` or `--dest` a setup
  touches nothing of `_update`: no stamp, no copy, no `update-dir`. A run whose folder is named by
  `CS2_PATCH_DIR`, `SM_STATE` or a root variable is still the install the apps run, so it does write: a choice,
  said here.
- The key is the Steam app ID, the one name of a game that never changes (`CLAUDE.md` § Published addresses).

### 3.2 `common/updates.sh`: the rule for what is installed and what is on offer

One file, in the form of `common/wrappers.sh`: read with `.` it defines functions and exports nothing; run,
it prints. Read with `.`, it needs `L1_UPDATE_DIR` set by the caller (setup, after `paths.sh`). Run, it uses
`L1_UPDATE_DIR` if set and otherwise the folder it lies in, which for the deployed copy is `_update` itself.
It writes only when `l1u_own` (below) says that `_update` and `_update/installed` are folders that belong to
the player and that nobody else can write to. (The setups test the folder that holds `_update` as well, because they may have to make it.)

**Its options and its output lines are a contract between versions on one Mac:** a launcher or a window
built by one version may call the tool of another. A later version may add an option or a field at the end
of a line, and never changes or removes one.

Functions:

- `l1u_own`: 0 when `_update` and `_update/installed` are folders of the player's own that nobody else can
  write to. The tool asks it before every write, and the driver in 3.4 step 2.
- `l1u_version_of <file>`: the version as defined above, read from the first 1 MiB; returns 1 when none.
- `l1u_newer <x> <y>`: 0 when `x` is a later version than `y`, the three numbers compared as numbers. It
  returns 1 unless both are a version or `-`; `-` is lower than every version.
- `l1u_stamp <app ID> <tree root>`: writes `installed/<app ID>` as 3.1 says. Returns 1 when it could not.
- `l1u_state`: prints one line of four fields, `<word><TAB><installed><TAB><offered><TAB><detail>`, with `-`
  for a field that has no value. In this order:
  1. `off`, if `off` exists;
  2. `none`, if `installed/` holds no stamp;
  3. `manual`, if any stamp's line is not `release`. `<detail>` is that line (the first such stamp in the
     order of the app IDs as numbers);
  4. `unknown`, if `offer` is absent;
  5. `ready`, if the offered version is newer than the **lowest** installed version;
  6. `current` otherwise.

  `<installed>` is the lowest installed version (`-` in `off` and `none`); `<offered>` is `offer`'s version.
- `l1u_refresh [--now]`: sets the word `fetched`, `failed` or `skipped`.
  - In the states `off`, `none` and `manual` it fetches nothing: `skipped`.
  - Without `--now` it fetches nothing when `tried` holds a time less than 86,400 s before now and not after
    now: `skipped`. So a failure is not tried again for a day, and "at most once a day" is true of failures
    too.
  - Otherwise it removes files named `.fetch.*` in `_update` that are older than ten minutes, writes `tried`,
    makes a new file with `mktemp "$L1_UPDATE_DIR/.fetch.XXXXXX"` (no suffix after the X's), and runs
    `curl -q --proto '=https' --tlsv1.2 -sS --max-time 10 --max-filesize 1048576 -o <that file>
    -w '%{http_code}' https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/CHANGELOG.md`
    with `-q` first (a player's `~/.curlrc` is not read) and no `-f`.
  - The answer is taken only when curl's exit is 0, the code is `200`, the file is at most 1,048,576 bytes
    (its own check: on a curl before 8.4.0 `--max-filesize` does not bound an answer of unknown length) and
    `l1u_version_of` finds a version in it. Then, if the version found is older than the one `offer` already holds (an answer up to five minutes old
    must not lower it), the file is removed and `offer` and `notes.md` stay as they were; otherwise the file is
    renamed to `notes.md` and `offer` is written beside and renamed. Either way: `fetched`. In every other case the file is removed and `offer` and `notes.md` stay as
    they were: `failed`. No rule reads curl's exit code for more than zero or not.

Run as a program. **Every call exits 0 when it could answer and says the outcome in its output**, because
the window's `runChild` gives back nothing for a child that exits non-zero (1.3):

| Call | Prints |
|---|---|
| `updates.sh` | the state line |
| `updates.sh --refresh [--now]` | the state line with a fifth field, `fetched`, `failed` or `skipped` |
| `updates.sh --notes` | from `notes.md`, every section whose version is newer than the lowest installed one, newest first, cleaned (below); nothing when there is none |
| `updates.sh --noted` | the offered version, when the state is `ready` and `noted` does not yet hold that version with the count 2; it then writes `noted` with the count raised. Otherwise nothing |
| `updates.sh --open` | `opened`, after it wrote the `.command` of 3.4 and handed it to Terminal; or `failed<TAB><one sentence>`. It refuses unless the state is `ready`: "No update is waiting." |
| `updates.sh --version-of <file>` | that file's version, or nothing (for the release gate and the release commands) |

**The notes, cleaned by `--notes`** so that the window shows them as they come: (1) a `## v...` heading
loses its `## `; (2) the lines of one paragraph are joined with one space, a paragraph ending at an empty
line, at a line that starts `- ` or a number and a dot, or at a code fence, and a list item's indented lines
join their item; (3) fence lines are dropped and the lines between them kept as they are; (4) `**` and
backticks are removed; (5) every control character but newline and tab is removed. After 200 lines or
12,000 bytes it stops before the line that would pass the limit and prints one last line:
`More: https://github.com/macgameport/1launcher/blob/release/CHANGELOG.md`.

Test variables, in the form of `L1_KILL` and `L1_OWNED_HELPER`: `L1_UPDATE_DIR`; `L1_UPDATE_NOW`, an epoch
that stands for now (matched as a time); `L1_CURL` (default `/usr/bin/curl`) and `L1_OPEN` (default
`/usr/bin/open`), the two programs a test replaces. Every function that runs a program begins
`local PATH=/usr/bin:/bin:/usr/sbin:/sbin`, because a launcher calls the tool with the Wine engine's `bin`
first on `PATH`.

**Why the version and not the commit.** The version is what the player is shown, and its section is the text
of what changed, so one request serves both. It works only if `release` never holds a commit that is not a
release, which 3.7 makes a gate. **Why "newer" and not "different".** `raw.githubusercontent.com` may answer
with a copy up to five minutes old (1.5). Right after an update the old answer names the version just left,
and "different" would offer it back. Numbers compared as numbers cannot offer an older version.

### 3.3 The setups, the installers and the window's builder

Both `cities-skylines-2/scripts/setup.sh` and `surviving-mars-relaunched/scripts/setup.sh`, unless the run is
`--check`, `--mac-only` or (Cities: Skylines II) `--dest`:

1. read `common/paths.sh` and `common/updates.sh`. Surviving Mars's setup reads `paths.sh` after its own
   line `:151`, which stays as it is, and takes only `L1_UPDATE_DIR` from it (its own state folder stays as `:151` gives it);
2. test, with the `own_folder` they already have, the folder that holds `_update` (the parent of `L1_UPDATE_DIR`; by default
   the data root),
   `_update` and `_update/installed` (made
   with `mkdir` and `chmod go-w` if absent); a folder that fails stops setup with exit 1 before anything of this plan is written;
3. copy `common/updates.sh` to `_update/updates.sh`, written beside and renamed. Cities: Skylines II's setup
   copies with plain `cp` today (`:358-367`); it gains a `put` in Surviving Mars's form (`:179-183`) for the
   files of this plan only. This copy is made before the window is built, so that a first setup already gives
   a window with `L1UpdateDir`;
4. write one line, the absolute path of `_update`, into a file `update-dir` beside the deployed launcher, the
   same way;
5. call `l1u_stamp` when the work is done: in Cities: Skylines II's setup after the exit for problems
   (`:590-595`) and before the Desktop step, so that it is written for exit 0 and exit 5; in Surviving Mars's
   before the closing words. If it fails, setup prints "  !! This version could not be recorded
   (`~/...`). 14unch3r will not offer updates for this game." and keeps its exit code;
6. in the closing words, name every other game of `l1w_games` that has a wrapper with the game in it (looked for with
   its wrapper variable unset, as in 3.4 step 4) and no stamp: "`<title>` was set up by an older version. Paste its installer line once, so that it gets updates
   too." The title is the third field of that ID's row in the tree's `common/games.tsv` (`l1w_row` carries no
   title), so `games.tsv` joins the new own-files loop below, and each hand-made `common/` of UT5 gains it.

**The own-files lists.** A fetched tree can lose files while it is in use (macOS clears old temporary
files), and each script tests for the files it needs before it starts. `common/updates.sh`, and for
Surviving Mars `common/paths.sh`, join them in a **separate loop below the existing one** at
`cities-skylines-2/scripts/setup.sh:72-76`, `surviving-mars-relaunched/scripts/setup.sh:93` and `:164`,
`cities-skylines-2/scripts/install.sh:109-110` and `surviving-mars-relaunched/scripts/install.sh:226-228`.
A separate loop, because three older mutants are anchored on the existing loops' lines (Surviving Mars's
`test-setup.sh` MUTANT 17; Cities: Skylines II's 37 and 38).

**The Desktop question.** `common/update-games.sh` exports `L1_UPDATE=1`. Under it Cities: Skylines II's
setup does not look at the Desktop and does not ask (the look plan's D20: a run nobody is watching for that
question does not look).

**`common/make-launcher-app.sh`** reads `common/paths.sh` beside it (which keeps an `L1_UPDATE_DIR` already
set, as UL1 uses) and writes the path into the window's `Info.plist` as `L1UpdateDir`, with `plutil`, when
`<that folder>/updates.sh` is a regular file. With no such file the key is not written and the window has no
update parts. With no `paths.sh` beside it (the tests' scratch folders) it writes no key either.

Two setups deploy the same file, and the later one wins. Within one update both come from one tree. A game
set up again from an older tag puts an older `updates.sh` back, with any defect since fixed in it, until the
next update replaces it. The contract of 3.2 is what keeps the other callers working meanwhile. Accepted.

### 3.4 The update itself

**The button's file** (`updates.sh --open`). In a folder from
`mktemp -d "${TMPDIR:-/tmp}/1launcher-update.XXXXXX"` (falling back to `/tmp`, as the installer app does) it
writes `Update 1launcher.command`, mode 755, holding constants only but for curl's path (`L1_CURL` when it
matches `^/[A-Za-z0-9._/-]{1,200}$` whole, else `/usr/bin/curl`, so that a test can serve the fetch), and runs `"$L1_OPEN" -a Terminal <file>`.
The file:

1. removes itself and its folder when it exits, and begins with `clear` (Terminal prints the user's name and
   the file's path before a script's first line);
2. says "Fetching the installer from github.com/macgameport/1launcher ...";
3. fetches `https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/install.sh` into a
   file in its own folder: `<curl's path> -q --proto '=https' --tlsv1.2 -sSL -o <file> -w '%{http_code}'`,
   judged by 3.2's rule (exit 0 and `200`). Never from curl's standard output, where the code would become
   the script's last line (1.5);
4. on `200` runs `/bin/bash -c "$(cat <file>)" 1launcher-install update`. A download cut short runs
   nothing, as today (`install.sh` is all functions and calls the last of them on its last line);
5. on `404`: "This version of 1launcher cannot update an install. Paste the installer line from the guide
   instead." On anything else: "GitHub could not be reached. Check the network, then try the update again." On any
   code but `200` nothing is run: after its sentence the file says "You can close this window." and exits 1;
6. after step 4 ran, ends with one line that says what happened, by the update's exit code (0: "Updated. You can close this
   window."; 3: "Not everything was updated: see the lines above. You can close this window."; anything
   else: "The update did not finish: see the lines above. You can close this window."), and exits with that
   code.

**The root `install.sh`** takes `update` as its first word: `install.sh update [<ref>]`.

- It is the one first word that is not a number, and it names no game. Every other such word still gets
  "not a Steam app ID" (UD11: this amends `docs/plans/shared-installer.md` 2.2 and `install.sh`'s header).
- It takes no option and no third word: `install.sh update --yes` is a usage error, exit 2.
- From a checkout it fetches nothing and says: "This is a checkout: update it with git pull, then run each
  game's scripts/setup.sh." Exit 2.
- Fetched, after the checks it makes today, it needs `common/update-games.sh` in what it fetched (else:
  "This version of 1launcher cannot update an install. Paste the installer line from the guide instead.",
  exit 1), exports `L1_FETCHED_REF` and `L1_FETCHED_COMMIT`, and runs `bash <tree>/common/update-games.sh`
  with no argument, returning its exit code.
- Its branch is a new test placed before the existing test of the first word (`:69`, on which mutant 7 of
  `common/test-bootstrap.sh` is anchored) and an early return at its own indent, so that the older mutants
  anchored on the lines for a game (2 and 11 on `:123`, 5 on `:122`, 8 on `:115`) still apply.
- For the ref `release`, on both paths, the archive is fetched as `archive/refs/heads/release.tar.gz`
  (measured: the same commit), so that a tag of that name could not be taken for the
  branch. `L1_FETCHED_REF` stays `release`.
- The game path also exports `L1_FETCHED_COMMIT`.

So the code that drives an update is always the newest (it comes with the fetch), and the only thing an
installed Mac holds is the address of the root `install.sh`, which is already never moved.

**`common/update-games.sh`** (new; run only by the root `install.sh`, from the fetched tree):

1. It refuses unless `L1_FETCHED_REF` is set (exit 2), reads `paths.sh`, `updates.sh` and `wrappers.sh` from
   its own tree, and exports `L1_UPDATE=1`.
2. If `_update` or `_update/installed` is not a folder of the player's own (`l1u_own`, 3.2), nothing is run:
   "This Mac keeps no record of what is installed. Paste each game's installer line once; after that it can
   update." Exit 3. Else it takes the lock `_update/updating` (a link whose target is its process number; a
   target that is not a process number by 3.1's rule, or that names a process that is gone, is taken over). A
   trap removes the lock when the driver exits, only while it still names this process. Held by a live process: "An update is already running in another Terminal
   window." Exit 3.
3. `T` is the fetched tree's version. If `offer` holds a version newer than `T`: "GitHub sent `<T>`, not yet
   `<offered>`. Try again in a few minutes." Nothing is run. Exit 3.
4. **The games it looks at are the games set up on this Mac, not the stamps.** For each row of the fetched
   `games.tsv` whose folder passes `install.sh`'s pattern, in the order of the app IDs as numbers, it asks
   `l1w_find game <ID>` with the game's wrapper variable unset (`l1w_row` names it; a variable left in the environment must not decide what is set up; it is unset
   for this look only, and the installers get the environment as it came):
   - exit 2 (two wrappers carry the marker): "`<title>`: two wrappers carry its marker. Left as it is." The
     stamp stays. Counted as failed;
   - no wrapper, or one without a prefix, or one without the game's program (`l1w_program`, with `l1w_row`'s
     `L1W_PROGRAM`): the game is not set up here. A stamp for it is removed, with "`<title>`: no longer set
     up on this Mac. Skipped."; with no stamp nothing is said. (Without this, an update would start a new
     install of a game the player removed: a download of up to 100 GB nobody asked for.);
   - set up, and no stamp: "`<title>`: set up by a version that keeps no record. Paste its installer line
     once: `<the pasted line with its ID>`". Not run (its files may come from a checkout). Counted as left;
   - set up, and the stamp's line is not `L1_FETCHED_REF`: "`<title>`: set up from `<line>`, so it is left
     as it is." Counted as left;
   - set up, and the stamp's version is newer than `T`: "`<title>` is at `<version>`, newer than what GitHub
     sent (`<T>`). Left as it is." Counted as left;
   - set up, and the folder has no `scripts/install.sh`: "!! `<title>`: this version has no installer for
     it." Counted as failed;
   - else a heading line with the title, and `bash <tree>/<folder>/scripts/install.sh` with no option. The
     list is held in an array (or read on descriptor 3), so that **each installer's standard input is the
     driver's own**, the Terminal. A failing installer does not stop the ones after it.
5. A closing block: one line per game with what happened, then exactly one of
   - "Everything is up to date: 1launcher `<T>`.", when at least one installer ran, every one that ran
     exited 0 or 5, and no game was left or failed;
   - "No game is set up on this Mac.", when step 4 found no game set up and nothing was counted as failed;
   - "Not everything was updated. Do what the lines above say.", otherwise. (It does not say "update again from
     14unch3r": with one game recorded and current, the window shows no line and calls the Mac current.)
6. Exit 1 if anything was counted as failed (an installer's exit other than 0, 3 and 5 is failed: 4 and a
   signal's code among them), else 3 if anything was left or an installer stopped with 3 or step 4 found no
   game, else 0.

**No answer is ever given for the player.** The installers run without `--yes`. In Terminal each can ask what
it asks today (1.1), except the Desktop question. An update that needs a new engine therefore asks first, in
the same words as a new install.

**What an update can do without asking**, so that it is said and not found: everything a second run of the
installer does today, among them the rename of the wrappers (`docs/plans/wrapper-names.md`) and the move of an
old install folder (`docs/plans/local-files-layout.md`). A player who pasted the line with
`L1_KEEP_WRAPPER_NAMES=1` or `CS2_PATCH_DIR=~/cs2-patch` in front must go on updating by that line: the
window's update cannot carry either, and would rename or move. The guides say so (section 5), and UD15 asks
whether an update should instead never start a move or a rename.

**The free-space caution.** `core_space` says nothing when a wrapper exists (`prefix_known`) and `game_state`
is `installed` or `update`, tested in that order: with no wrapper `use_wrapper` has not run, and what
`game_state` reads is unset under `set -u`. In the states `absent` and `partial` the caution stays.

### 3.5 The window

**The sign is one line at the foot of the grid** (UD10; a tile in a group of its own is the alternative, and
it is measured against this in section 9).

- **When.** With `L1UpdateDir` in its `Info.plist` (or `--update-dir <dir>` on the command line), a value
  that starts with `/`, and `<dir>/updates.sh` a regular file that is not a link: the window asks
  `/bin/bash <dir>/updates.sh` through `runChild` with a 5 s limit, **off the main thread**: at open with the offers (`askOffers`, `:1381-1391`) and after each
  `applicationDidBecomeActive`. That call touches no network. `reload()` itself never calls the tool (it runs
  on the main thread, before a start among other places): it draws the foot from the last answer the delegate
  holds. An answer replaces what is held and, only when its word or its offered version differs and no sheet
  is up and no start is under way, shows the list again by a path that asks nothing.
- Then, chained once after the first answer at open and off the main thread, it asks `updates.sh --refresh`
  (15 s), and its answer is taken by the same rule. After an answer of `ready` the same background block asks
  `updates.sh --notes` (5 s) and keeps the result with the state. The window never waits for the network, and
  no child runs between a click on the foot line and its sheet.
- An answer is used only if its word is one of the six and both versions match 3.1's pattern or are `-`. Only
  its first line counts, fields past those this version knows are ignored (3.2's contract), and `ready` needs
  a version, not `-`, as the offered one. Any
  other answer, and no answer from `runChild`, is dropped: with nothing held the window draws no foot line, as
  without the tool. The menu item stays, and row 6 answers it.
- **State `ready`:** the grid draws one more line, `1launcher <offered> is out. Click to see what changed.`
  - Drawn with the look of the label "You also own": `Look.labelFont`, white at `Look.labelAlpha`,
    `Look.labelH` high, one line, centred in the grid's width, no shadow. Measured: 277 points for
    `v0.4.0`, 287 for `v0.10.12` and 388 for the widest text a matched version can give, in the 396 the least
    window gives, so no rule for cutting it is needed. Its rectangle: the width is the text's, rounded up; it
    is centred; `y` is the last row's bottom plus `Look.labelAbove`; the height is `Look.labelH`.
  - Place: `Look.labelAbove` below the last row of tiles, offers included, then `Look.bottom` as today. The
    grid grows by 24 points (measured on a prototype: one game with the line is 444 by 196, the line's
    contrast 9.6, and 7.6 over the hover fill). The line is a subview of the grid, added after the tiles at
    every `show`, and scrolls with it; it is not in `tiles`. Past 600 points it is reached by scrolling (from
    13 tiles, or 9 with an offer row), and with the line a selected tile of the last row is shown down to the
    grid's end. **With no tile at all there is no foot line:** the grid is hidden in the empty state, which
    stays as today, and the menu item is the way to the sheet.
  - Its hit area is the text's rectangle grown by 6 at the sides and 4 above and below. Pointing-hand
    cursor; under the pointer, that rectangle filled white at `Look.hoverFill`, radius 4. A press arms it and
    a release on it with a click count of 1 opens the sheet, with `blocked` asked first: the tiles' rule.
  - It is not in the arrows' order and is never selected, so Return still starts the last game. The keyboard
    reaches it through the menu item.
  - VoiceOver: one element after the tiles, role button, label
    `1launcher <offered> is out, shows what changed`. Its press action is the click.
  - Every new size and string is a constant in `Look`, as `Look.label` and `Look.noGames` are.
- **The sheet for `ready`**, an `NSAlert` as the one question the window has today:
  - message: `1launcher <offered> is out.`
  - text: `This Mac has <installed>. Update opens Terminal and runs the installer again for each game set up
    here. It may ask you a question there.` With `-` for the version, the first sentence is left out.
  - an accessory view: a scroll view of 380 by 180 points, set before the alert is shown, bezel border,
    vertical scroller that hides itself; in it a text view, not editable, selectable (a right-click copies; the app has
    no Edit menu), no link or data detection, the text set as a plain string, `NSFont.systemFont(ofSize: 11)`, `textColor = .labelColor`,
    no background drawn, 4 points of inset, accessibility label `What changed`. It holds the notes
    kept with the state (above). When that is nothing, or there was no answer: the one line
    `What changed: https://github.com/macgameport/1launcher/blob/release/CHANGELOG.md`. No colour comes from
    `Look`: the alert takes the window's dark appearance as the existing sheets do.
  - buttons: "Not Now" first (Return and Escape, as "Don't Start" is today), then "Update". Focus at open is
    "Not Now"; the text view is in the key loop after the buttons. "Update" has no key of its own.
  - If a game row is `busy` (read after a `reload()`), the sheet is instead: message `Quit <title> first.`
    (the first busy row in the list's order), text `The update leaves a running game as it is. Quit it, then
    update.`, one button "OK".
- **"Update"**: which button was pressed is decided by one pure function, `sheetAnswer(button)`, which gives
  `open` only for the second button. Then, with `starting` set as for a start, `updates.sh --open` is asked off
  the main thread (10 s). `opened`: the window quits, as after a
  start. `failed<TAB><sentence>`: a sheet with the message "The update did not open." and that sentence. No
  answer: the same sheet with "The update tool did not answer." On `failed` and on no answer, `starting` is
  cleared before the sheet.
- **The menu** gains "Check for Updates…" with the key Command-U, and a separator, above "Quit 14unch3r". When
  `updateTool` gives none at open, the item and its separator are absent. It does nothing while a sheet is up or a start is under way. When the
  delegate holds the state `ready` (with a foot line or, with no tile, without one), it opens that sheet at once. Otherwise the item is disabled and `updates.sh --refresh --now` is asked (15 s, off
  the main thread); on an answer of `ready` the same block asks `--notes` before the sheet is shown, as at
  open; an answer that arrives while a sheet is up or a start is under way is dropped. Nothing else
  shows while it runs: 0.2 s when GitHub answers, up to 10 s when it does not. The item is enabled again when its
  answer is shown or dropped. The
  answer shown, decided in this order, each an alert with one button "OK":

  | Order | Case | Message | Text |
  |---|---|---|---|
  | 1 | `off` | Checking for updates is switched off on this Mac. | The install guide says how to switch it on. |
  | 2 | `none` | This Mac is not yet set up for updates. | Paste each game's installer line once more. After that, 14unch3r says when a new version is out. |
  | 3 | `manual`, detail `checkout` | No update is offered on this Mac. | Its games were set up from a checkout. Update with git pull, then run each game's setup. |
  | 4 | `manual`, any other detail | No update is offered on this Mac. | A game here was set up from a named version. Paste its installer line from the guide to follow new versions again. |
  | 5 | `ready` | the sheet above | |
  | 6 | the fetch `failed`, or `unknown`, or no usable answer (none, or one that fails the rule above) | The list of versions could not be read from GitHub. | Check the network and try again later. |
  | 7 | `current` | 1launcher `<installed>` is the newest version. | A game set up before updates were recorded is not counted until its line is pasted once. |

- **Every sheet sets the delegate's `sheet`** (the `ready` sheet as a question, the others as a failure is
  today). A sheet shown without it would let Escape quit the app and Return start the selected game under
  the sheet (1.3).
- **The seams, so that all of this is tested with no window.** The delegate builds its alerts and takes its
  decisions only from pure functions, and each has a text mode:

  | Function | Gives | Text mode |
  |---|---|---|
  | `updateState(line)` | the parsed answer, or none | used by all below |
  | `footText(state)` | the line's text, or none | `--grid` prints one `foot` line after the tile lines when there is one; `paint label` covers every label rectangle, this one included |
  | `updateSheet(state, notes, busyTitle)` | message, text, notes and the buttons in order | `--update-sheet` |
  | `menuAnswer(state, fetch)` | message and text, or the word `sheet` | `--update-menu <fetch word>` |
  | `afterOpen(output)` | `quit`, or `failure` and a sentence | `--update-open` |
  | `sheetAnswer(button)` | `open` for the second button; `nothing` for the first and for Escape | `--update-answer` |
  | `updateTool(dir)` | the tool's path, or none: `dir` starts with `/`, and the file is regular and not a link | `--update-tool`, run by `common/test-make-launcher-app.sh` from inside a built app, as `--folders` is, to show that the builder's key and the window's reader agree |
  | `askUpdate(tool, arguments, limit)` | the tool's answer, or none. The one place the tool is run, by the window and by every text mode, with `L1_UPDATE_DIR` set for the child to the folder in use | the calls the stub records |

  The forms:

  ```
  launcher-window [--games <tsv>] [--update-dir <dir>] [<folder>...]
  launcher-window --grid [--games <tsv>] [--update-dir <dir>] <last id or -> <folder>...
  launcher-window --act <step,...> [--games <tsv>] [--update-dir <dir>] <last id or -> <folder>...
  launcher-window --update-sheet --update-dir <dir> <folder>...
  launcher-window --update-menu --update-dir <dir> <fetched|failed|skipped|->
  launcher-window --update-open --update-dir <dir>
  launcher-window --update-answer <first|second|escape>
  launcher-window --update-tool [--update-dir <dir>]

  ```

  What they print, tab-separated:
  - `--grid`: `foot`, then x, y, width, height, the text, the role and the label. A test checks `y`, the
    height, the text and that the line's middle is the grid's middle within 1 point, never an absolute `x` or
    width (they follow the font).
  - `--update-sheet`: a `message` line, a `text` line, one `button` line per button in order, and one `note`
    line per line of notes; `none` when the state is not `ready`.
  - `--update-menu`: `sheet`, or `alert` with the message and the text or `-`. The state comes from the stub's
    call with no argument; the word `-` stands for no answer to the refresh.
  - `--update-open`: `quit`, or `failure` with the message and the sentence. It runs the tool with exactly
    `--open`.
  - `--update-answer`: `open` or `nothing`.
  - `--act`: `press:x:y` in the hit area prints `armed` and `foot`; a `release:x:y` there with one click prints
    `sheet` and `update`; the step `foot` is both, at the rectangle's centre; `axpress:foot` prints the same.
    With no foot line, under `block`, after a release elsewhere, on a second click, or with a `reload` in
    between, each prints `nothing`. None ever prints `start`.

  A text mode looks for a tool only when it is given `--update-dir`; the window and `--update-tool` alone read
  `L1UpdateDir`, and `--update-dir` wins over it. So every recorded output of today is unchanged (confirmed on the prototype:
  without the option, `size`, `window`, `empty` and `paint label` are byte for byte today's). The dispatch
  (`:1231`) and the window's test of its own arguments (`:1289`) both let `--update-dir <dir>` through. The stub `updates.sh`
  writes one line per call to `args.log` and answers from the files `out`, `out.notes` and `out.open` beside it.

  Three source gates, each a count the test file takes from the source: (1) every line holding
  `beginSheetModal(` has, just before it, a line that sets `sheet` to a question or a failure; (2) the string
  `"--open"` occurs once, in one function, and that function is called on exactly two lines: in the
  `--update-open` text mode, and in the delegate on a line that follows a test of `sheetAnswer` for `open`; (3) the
  tool is run nowhere but in `askUpdate`, and the delegate calls `askUpdate` only inside a block sent off the
  main thread. A fourth count: below the window's marker the source holds none of the update's sentences,
  which are constants of `Look`.

### 3.6 The launchers

One block, the same in both launchers, placed after the `acquire_lock` call and before the first `step 1`,
and compared byte for byte by `common/test-launcher-parity.sh` (a new rule 11, in the form of rule 9, which
also checks the place):

```bash
# >>> update-notice (the same in both launchers: common/test-launcher-parity.sh compares the copies)
# docs/plans/built-in-update.md, 3.6. At most two notices per new version of 1launcher, and a look at GitHub
# in the background at most once a day. The look cannot delay or stop a start: it is never waited for. The
# notice is waited for: it reads small local files and touches no network.
_l1u="$(/bin/cat "$(CDPATH= cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)/update-dir" 2>/dev/null)"
case "$_l1u" in /*) ;; *) _l1u="" ;; esac
if [ -n "$_l1u" ] && [ -f "$_l1u/updates.sh" ] && [ ! -L "$_l1u/updates.sh" ]; then
  _l1v="$(/bin/bash "$_l1u/updates.sh" --noted 2>/dev/null)"
  _l1p='^v(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})$'
  [[ "$_l1v" =~ $_l1p ]] && note "1launcher $_l1v is out. Open the 14unch3r app to update."
  ( /bin/bash "$_l1u/updates.sh" --refresh < /dev/null > /dev/null 2>&1 & )
fi
unset _l1u _l1v _l1p
# <<< update-notice
```

- The repository's own launcher has no `update-dir` beside it, so it does nothing there.
- The sentence joins both recorded `note` lists of rule 5 (`common/test-launcher-parity.sh:184-208`), or that
  rule goes red.
- The notice is said at the first two starts after a version comes out, whichever games they are (`noted`).
  Two, because a notification from `osascript` belongs to Script Editor and may not show at all (1.5), and
  what is written to `noted` is written before anything is shown.
- The block names `cat` and `dirname` by their full paths (a launcher's `PATH` begins with the Wine engine's
  `bin`) and matches the tool's answer as a version before it reaches `note`. Run under bash 3.2.57 with
  `set -u` and stray programs named `cat` and `dirname` first on `PATH`: a version gives one note; no answer,
  two lines, a text that is not a version and an absent tool give none; a tool that sleeps on `--refresh` does
  not delay it; the three variables are unset afterwards.
- Measured by the check's builder: with the real `updates.sh` the block takes 30 to 37 ms.

### 3.7 The release gate, and the published addresses

`common/check-release-move.sh` gains a fifth question, asked when `<commit>` **or `origin/release`** holds
`common/updates.sh` (so that it cannot be switched off by a commit that removes the file):

5. a `v` tag's commit (`<tag>^{commit}`, not the tag object) is `<commit>`; the first version heading of
   `<commit>:CHANGELOG.md` is that tag's name; that version is newer than the first version heading of
   `origin/release:CHANGELOG.md` (no file or no heading there counts as `-`); and
   `git ls-remote --tags origin release` prints nothing.

It takes the version rule from `common/updates.sh` beside it. When the question is asked and that file is not
beside the gate, it fails: "FAIL  the version rule (common/updates.sh) is not in this checkout".

Reason: an installed Mac learns of an update only by a version heading that rises. A move of `release` to a
commit between two releases would reach new installs and no installed Mac.

What this changes for James: **every move of `release` is from now on a tagged release.** A fix for a game
update, which `docs/plans/local-files-layout.md` has go to `main` and then to `release`, becomes a release
whose third number rises. A mistyped heading in a tagged commit is found only at the move and costs a
successor release, so the release commands of `CLAUDE.md` § Releases gain one line before the tag is made:
`bash common/updates.sh --version-of CHANGELOG.md` must print the tag about to be made.

`CLAUDE.md` § Published addresses gains: the root `CHANGELOG.md` is never moved, and the form of its version
headings is read by every installed Mac; `install.sh update` is a published word that can never be
withdrawn; `release` moves only to a commit a `v` tag names; no tag is ever named `release`. § Releases
gains: "A section is read inside 14unch3r before a player says yes to an update. Each change opens with one
bold sentence saying what a player will notice or must do; pointers to plans and to code come after it."

### 3.8 Trust, and what this sends

- **What runs.** The update runs code from `release`, as the pasted line does. It trusts nobody new, but it
  widens what that trust reaches: before, whoever moved `release` reached only a Mac whose owner later
  decided, unprompted, to paste the line; after, every installed Mac is told within a day, in words the mover
  chooses, and one click runs their code in Terminal. The notes shown in the sheet inform. They are not
  proof of anything.
- **What stands against that.** Nothing is installed without a yes (UD1). `release` moves only on James's
  word, after the gate and the tests (`CLAUDE.md`). And the rules of UD5 on GitHub: a ruleset on `release`
  that blocks force pushes and deletion, and one on the tags `v*` and `installer-*` that blocks their update
  and deletion, both with an empty bypass list. Those rules stop an accident and a rewind. They do not stop
  anyone who holds an owner's credential, which includes any session on James's Macs that can push; nor
  GitHub itself; nor the third-party downloads the installers make.
- **What is only read.** The check fetches one text file and runs none of it. The file is bounded at 1 MiB,
  its version is taken by one fixed pattern, every value read back from disk is matched again (3.1), and its
  text is shown as plain text.
- **What it sends.** By itself at most one request a day per Mac, and one more each time the player chooses
  "Check for Updates…". The request names curl and its version and nothing else of ours; GitHub's servers
  see the Mac's network address and the time, which is when the window opened or a game started. Nothing
  about the player or the games is sent: no identifier, no installed version, no list of games.
- **Who is never asked.** A Mac whose state is `manual`, `none` or `off` fetches nothing, in every caller.

### 3.9 New games

Adding a game stays what it is today: a folder with its installer, a row in `common/games.tsv`, a row in
`common/wrappers.sh`'s table, its tests, a release. With this plan the release then reaches installed Macs:
the update rebuilds 14unch3r with the new table, and the window offers the game to players whose Steam
account owns it (1.3). The offer still opens the game's set-up guide, which holds the pasted line (UD7).

### 3.10 Statements this plan ends

Each is corrected in its file in step U5, with a pointer here:

- `docs/plans/launcher-window.md`: "The window sends nothing anywhere." From this plan the window runs
  `_update/updates.sh`, which asks GitHub for one file (UD12).
- `docs/plans/shared-installer.md` 2.2 and `install.sh`'s header: a first word that is not digits fetches
  nothing and exits 2. `update` is now the one exception (UD11).
- `docs/plans/local-files-layout.md`: "a fix for a game update goes to `main`, and `release` moves to it".
  Now through a tagged release (3.7).
- `docs/plans/launcher-window-look.md`, sections 2.1, 2.4 and 2.7: extended by 3.5 (the foot line, its place
  in the size table, its contrast line).

## 4. Steps

Each step is one or more commits on `built-in-update`, with its tests in the same commit and every mutant of
section 6 applied and seen red before the step is called done.

- **U0. Two fixes found on the way.** The root `install.sh` and the installer app's program judge a fetch by
  3.2's rule (the installer app's program fetches into a file in its own folder, as 3.4's `.command` does, reads
  it into `S` and removes it at once, so that its trap line and its `/bin/bash -c "$S" 1launcher-install` line,
  on which mutants 5 and 6 of `common/test-make-installer-app.sh` are anchored, keep their text, and the case
  "only itself is removed" still holds); `-L` and `--retry 2` stay on the root `install.sh`'s fetch (the archive
  address redirects), `-f` goes; for every code but `200` and `404` the sentence keeps the words "GitHub could
  not be reached" and "Check the network" and adds the code; `core_space` is silent on a finished install.
  Tests UT1, UT2.
- **U1. The record and the rule.** `common/paths.sh` and its header; `common/updates.sh`;
  `common/test-updates.sh`; the root `install.sh` exports `L1_FETCHED_COMMIT`; both setups, both installers'
  own-files loops and `common/make-launcher-app.sh` (3.3; its key is tested with the window, in UT8); the `CLAUDE.md` line for `_update` and
  `update-dir` (the folder is made in this step, so its line is too). Tests UT3, UT4, UT5.
- **U2. The update.** `install.sh update`, `common/update-games.sh`, `common/test-update-games.sh`,
  `updates.sh --open`, and the `refs/heads` form of the archive for `release`. Tests UT6, UT7, UT7b.
- **U3. The window.** The seams, the foot line, the sheets, the menu item, the text modes. Test UT8.
- **U4. The launchers.** The block, rule 11, the two note lists. Test UT9.
- **U5. The gate and the words.** `common/check-release-move.sh` question 5 and its header (UT10);
  `CLAUDE.md` (published addresses, releases, `common/` in the layout table); the four statements of 3.10;
  the root `README.md`, both `INSTALL.md` files, `cities-skylines-2/README.md` and Surviving Mars's
  `README.md`, with the words of section 5's last block; `CHANGELOG.md` under Unreleased; this plan's
  as-built header, naming `Look`'s new constants.
- **U6. Live steps, merge, release.** Section 7. The branch is merged into `main` with `--no-ff` after
  `wrapper-names` is (that plan's W3b), and **only when James is ready to publish it, or after `release`
  has taken `v0.3.0`**: once `main` holds `common/updates.sh`, `release` cannot take anything from `main`
  without taking this plan (the gate's fifth question then asks for a tagged release of what `main` holds).
  Its release raises the third number (UD9, James's answer): `v0.3.1` if it follows `v0.3.0` directly. The suites of U1, U3 and U4 are run on the
  tagged commit itself before `release` moves, because a release whose check, window or notice is broken
  cannot be repaired by a successor on the Macs that took it (section 10).

## 5. Who notices what

| Who | What they notice |
|---|---|
| A player set up before this version | Nothing, until they paste each game's installer line once more. The release notes of this version say so. With two games, pasting one line stamps one: that setup's closing words name the other, and an update names it too. Until its line is pasted, every update ends "Not everything was updated" and names it, and 14unch3r shows no line once the recorded game is current. |
| A player set up by this version or later | By itself at most one request a day to GitHub. When a version is out: a line at the foot of 14unch3r whenever it is open (reached by scrolling from 13 tiles) until they update, and at most two notifications, at the next two starts of a game. Nothing else changes until they click Update. |
| A player who clicks Update | A Terminal window, the update's own lines and the installer's for each game, and its questions if a step needs one. |
| A player who declined the folder move or the new wrapper names | The window's update runs the installer without their variable, so it moves or renames. To keep their choice they update by the line they pasted, with `CS2_PATCH_DIR=~/cs2-patch` or `L1_KEEP_WRAPPER_NAMES=1` in front. |
| The Studio and the MacBook | No line, no notice, no request: a game there is set up from a checkout, so the state is `manual`. The menu item says why. |
| James, at a release | `release` moves only to a tagged commit, and each section of the changelog is read by players before they say yes. A move of `release` now reaches installed Macs within a day, not only new installs. |

**The words for the guides** (U5; published text no test reads, so it is given here). Beside each "paste the
line again" place:

- "**Updates (from v`<this release>`).** When a new version of 1launcher is out, 14unch3r says so at the foot
  of its window, and the game's app says so in a notification. Click the line, read what changed, and click
  Update: Terminal opens and runs the installer again for every game set up on this Mac. Nothing is installed
  until you click Update. Pasting the installer line again does the same."
- "**What the check sends.** By itself at most once a day, when you open 14unch3r or start a game, this Mac
  asks GitHub for one public file, the list of changes. GitHub sees this Mac's network address and the time,
  as for any page. Nothing about you or your games is sent."
- "**To switch the check off:** `touch ~/Library/Application\ Support/1launcher/_update/off`. Delete that
  file to switch it on again. With it off, update by pasting the installer line."
- "**If you pasted the line with a variable in front** (`CS2_PATCH_DIR=...` or `L1_KEEP_WRAPPER_NAMES=1`): do
  not use Update in 14unch3r. It runs the installer without them, which moves the folder or renames the
  wrappers. Paste your line again instead."
- By hand, for a Mac with no 14unch3r: the pasted line with the word `update` where the app ID stands.
- `CHANGELOG.md`, first lines of this version's section: "**14unch3r says when a new version is out, and one
  click updates.** ... **On a Mac set up before this version, paste each game's installer line once more:**
  nothing can reach it before that."

The guides on `main` are what players read (the rows of `common/games.tsv` point at `blob/main`), so each
sentence starts "from v`<this release>`" and is true before `release` moves.

## 6. Tests

Every test runs with `HOME`, `TMPDIR` and `L1_UPDATE_DIR` at scratch folders, starts nothing of Wine, and
touches no network: `L1_CURL` and `L1_OPEN` name stubs (for `install.sh`, a stub `curl` first on `PATH`, as
today). A stub curl honours `-o` and `-w`: it writes the body to the file and the code to its standard
output, as curl does. A mutant is applied to the source and must be seen red (exit 1, not REFUSED).

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| UT1 | `common/test-bootstrap.sh`, `common/test-make-installer-app.sh` | A 404 gives "GitHub has no ..." whatever curl's exit (0, 22, 56); no answer (`000`, exit 6) gives "could not be reached"; 403 and 500 give "could not be reached" with the code; with 200, what the installer app's program runs is byte for byte what the stub served, with no line after `main "$@"` | the exit code 22 put back as the test; `-w` written into a captured script; every code but 200 read as "no such ref" |
| UT2 | both games' `scripts/test-install.sh`; Surviving Mars's gains a `df` stub | With less free space than `NEED_GB`: a finished install, no `CAUTION`; `game_state` `update`, none; `partial`, the `CAUTION`; no wrapper, the `CAUTION` and no "unbound variable" | silent for `installed` only; silent for `partial` too; the wrapper test dropped |
| UT3 | `common/test-updates.sh` (new) | `l1u_version_of`: the first version heading under `## Unreleased`; none when there is none; a leading zero, a fourth number, no date, `###` are not versions; only the first 1 MiB is read. `l1u_newer`: `v0.10.0` over `v0.9.9`; equal is not newer; `-` is lowest; a seven-digit number is not a version. `l1u_state`: each of the six words in 3.2's order, among them: a `checkout` stamp and **no `offer`** gives `manual` with the detail `checkout`; no stamp and an `offer` gives `none`; two `release` stamps at different versions use the lower; an `offer` older than the installed version gives `current`; in `installed/` a link, a folder, a two-line file, a five-field file and a file of 5,000 bytes are passed over; a stamp or an `offer` whose version is `a[$(touch <file>)]`, `v0.08.1`, `v1.2.3x` or 30 digits is passed over or absent, and `<file>` does not exist; fields that have no value print `-` | `l1u_newer` made a comparison of text; "ready when different"; "lowest" made "highest"; the `manual` rule dropped; rules 3 and 4 swapped; the match before the comparison dropped |
| UT4 | the same file | `l1u_refresh`: within a day of `tried`, curl is not called, **after a failure too**; at exactly 86,400 s and with `--now` it is, with exactly 3.2's options, `-q` first; a `tried` after now: called; curl exit 56, exit 63, a 404, a 2 MiB file served with exit 0, and a file with no heading each leave `offer` and `notes.md` byte for byte as they were, leave no `.fetch.*` behind and print `failed`; in the states `off`, `none` and `manual` curl is never called, with `--now` too; with no `installed/` folder, or a `_update` others can write, nothing is written; two refreshes at once with a slow stub leave a whole `notes.md`; every call exits 0. `--notes`: the newer sections only, newest first, cleaned by each of the five rules (a fixture per rule), cut before the line that passes 200 lines or 12,000 bytes, with the closing line. `--noted`: prints at the first two calls for a version and then nothing; prints again for a newer version; when not `ready`, prints nothing and writes nothing. `--open` when not `ready`: `failed` and the sentence, nothing written, `L1_OPEN` not called | `tried` not written on failure; the script's own size check dropped; the future-time test dropped; the state test before the fetch dropped; the `installed/` test dropped; one fixed name for the new file; `--noted` not writing `noted` |
| UT5 | both games' `scripts/test-setup.sh`; each scratch `common/` gains `paths.sh` and `updates.sh` | After a setup that finishes: `installed/<app ID>` holds `checkout`, the tree's version, `-` and `L1_UPDATE_NOW`; with `L1_FETCHED_REF=release` and `L1_FETCHED_COMMIT`: `release` and that commit; with `L1_FETCHED_REF=v0.2.0`: that line, and the state is `manual`; `_update/updates.sh` is byte for byte `common/updates.sh`; `update-dir` beside the launcher holds the path; a setup that stops or fails writes no stamp and leaves an older one as it was; `--check`, `--mac-only` and `--dest` touch nothing of `_update`; exit 5 writes one; a `_update` writable by the group: exit 1, nothing written; `common/updates.sh` missing from the tree: the own-files sentence; another game set up with no stamp is named in the closing words; with `L1_UPDATE=1` and a terminal, the Desktop question is not asked | the stamp written before the app is built; the stamp written on failure; the stamp written in place; `updates.sh` not deployed; `update-dir` not written; the own-folder test dropped; the `L1_UPDATE` test dropped |
| UT6 | `common/test-bootstrap.sh` | `install.sh update`, fetched: the fixture's `common/update-games.sh` is run with `L1_FETCHED_REF` and `L1_FETCHED_COMMIT` and no argument, and its exit code is returned; `update x --yes` and `update --check`: usage, exit 2, nothing fetched; a fixture without the driver: the sentence, exit 1; from a checkout: the sentence, exit 2, curl not called; `Update`, `updates` and a folder's name are still "not a Steam app ID" | the word accepted in any case; arguments passed on to the driver; the checkout case made to run the driver; the exit code dropped |
| UT7 | `common/test-update-games.sh` (new): stub installers that record their arguments and read one line of their input; the driver is given a file as its input; wrappers are the "bare" fixture of `docs/plans/wrapper-names.md` section 6 in the scratch `~/Applications` | Two set-up games stamped `release`: both installers run, in the order of the IDs as numbers, with no argument, **each reading the driver's own input**; a failing installer first: the second still runs, exit 1; 3 then 0: exit 3; 1 then 3: exit 1; an installer's exit 4: failed; 5: done. **A set-up game with no stamp beside a stamped one: not run, named with its pasted line, the closing line is not "Everything is up to date", exit 3.** A stamp on `checkout`: not run, the line says so, exit 3. A stamp newer than the tree: left. A stamp whose wrapper is gone, or whose wrapper has no game in it: the stamp removed, no installer run. Two wrappers marked alike: nothing run, the stamp kept, exit 1. The game's wrapper variable set to a path that does not exist: the set-up game is still found. The row of a set-up game given the folder `../x`: nothing run outside the tree. `offer` newer than the tree: the "not yet" sentence, nothing run, exit 3. A live `updating` lock: the sentence, exit 3; a dead one: taken over. No game set up: its sentence, exit 3. `L1_FETCHED_REF` unset: exit 2. The stubs' recorded arguments hold no `--yes`. `updates.sh --open`: the written file, run with a stub curl, records `$0` as `1launcher-install` and `$1` as `update`, one word; it is mode 755, begins with `clear`, removes itself, exits with the driver's code and says the sentence for it; `L1_OPEN` got `-a Terminal` and its path | the stamps as the list (the look at wrappers dropped); the list read by a loop on standard input; the driver stopping at the first failure; resolver exit 2 treated as "none"; the wrapper variable not unset; `--yes` added; a stamp on another line run anyway; 5 counted as failed; the folder taken without the pattern; the version test dropped; the lock dropped; `release` made `main` in the `.command`'s address |
| UT7b | each game's `scripts/test-install.sh`, in the case that keeps the real `setup.sh` | **The parts joined.** From a finished-install fixture with a stamp `release` at `v0.0.9` and an `offer` at the tree's version: `updates.sh` says `ready`; `install.sh update` through the real driver, installer and setup; then the stamp holds the tree's version and `updates.sh` says `current`. With the second game's installer made to stop: its stamp is old and the state stays `ready` | `l1u_stamp` not called by setup; the driver's test of the line inverted |
| UT8 | `common/test-launcher-window.sh`, through the modes of 3.5; `common/test-make-launcher-app.sh` | The first call of the tool has no argument, and no text mode calls `--refresh`; with a stub saying `ready`: `--grid` holds the `foot` line with 3.5's text, the grid 24 points higher, the row selected at open unchanged, the contrast line for it at 4.5 or more; `--act foot` prints `sheet update` and never `start`, and the tool was not called with `--open`; `--update-sheet`: message, text, notes, and the buttons in the order "Not Now", "Update"; the text shows the state line's second field; with `-`, the first sentence is absent; with no notes, the one line with the address; with a busy row, the other sheet, naming the first busy row; `--update-open`: `opened` gives `quit`, `failed` and a sentence gives that sentence, no answer gives "The update tool did not answer."; `--update-menu`: each of the seven rows of 3.5's table, among them `current` with a failed fetch giving row 6; under a sheet, `--act` Escape gives `end-sheet` and Return `pass`; every other state, a seventh word, an offered text that is not a version, a tool that hangs past the limit, a tool that is a link, a relative `--update-dir`: no foot line, and the list as without the tool; `--update-dir` with no value: usage; with no tile, no `foot` line and the size as today; `L1UpdateDir` is in the built `Info.plist` only when the tool exists; the three source gates of 3.5 and its fourth count | the first button of the sheet made to give `open`; the test before the one call of `--open` dropped; the first call made `--refresh`; "Update" made the first button; the line that sets `sheet` dropped before one new sheet (the first source gate); the line shown for `current`; the offered text shown unmatched; the limit removed from a call; row 6 placed after row 7 |
| UT9 | `common/test-launcher-parity.sh` (rule 11); behaviour in a new `common/test-update-notice.sh`, on the block taken from each launcher in turn, with `update-dir` beside the extract | The two blocks are equal byte for byte, and in each launcher the block lies after the `acquire_lock` call and before the first `step 1`; the sentence is in both recorded note lists; the tool printing a version: exactly one `note` with 3.6's sentence; printing nothing: none; a tool that sleeps 30 s on `--refresh`: the block returns within 2 s; the refresh's output goes nowhere; no `update-dir`, a relative path in it, a folder with no `updates.sh`, a tool that is a link: nothing is run; the tool printing `v0.04.0`, a version with words after it, or two lines: no `note`; with programs named `cat` and `dirname` that fail first on `PATH`: one `note` still, and neither was called; the three variables are unset afterwards | one byte changed in one copy; the block moved above `acquire_lock` in one launcher; the `&` dropped; the `note` made unconditional; the test of the path dropped; the match made `[ -n ]` in both copies; `/bin/cat` made `cat` in both copies |
| UT10 | `common/test-check-release-move.sh`; the fixture gains `CHANGELOG.md` on the commit and on `origin/release`, and annotated tags | A commit holding `common/updates.sh`: untagged fails; an `installer-1` tag alone fails; tagged `v0.4.0` with the heading `v0.4.1` fails; tagged, heading equal, not newer than `release`'s fails; a tag named `release` on the remote fails; all right passes; `origin/release` with no changelog counts as `-`; a commit without the file, on a `release` without it, is not asked; a commit without the file on a `release` that has it **is** asked | each of the four conditions dropped in turn; the tag compared by its object; the trigger read from the commit alone |
| UT3, UT4, also | `common/test-updates.sh` | A two-line stamp is passed over; `tried`, `noted`, a stamp's time and `L1_UPDATE_NOW` holding `a[$(touch <file>)]` are each taken as absent and `<file>` is not made; an answer whose version is older than `offer`'s leaves `offer` and `notes.md` byte for byte as they were, leaves no `.fetch.*` and prints `fetched`; stubs named `mktemp`, `stat`, `date` and `mv` first on `PATH` record no call; `--version-of` prints a file's version and nothing for a file without one | a failed fetch made to exit 1; `-q` dropped; the address made the short `release` form; the `local PATH` line dropped; `offer` lowered by an older answer; the second read of a stamp dropped |
| UT5, also | both games' `scripts/test-setup.sh`, both `scripts/test-install.sh` | The stand-in for the window's builder records that `_update/updates.sh` existed when it was called; with `common/updates.sh` missing, each installer says its own-files sentence with exit 4 before setup runs; a set-up game whose wrapper variable names a path that does not exist is still named in the closing words | the new own-files loop dropped (setup; installer); the copy made after the window is built; item 6's closing words dropped |
| UT5, also (built at U1) | `common/test-bootstrap.sh` | On the game path the root `install.sh` exports `L1_FETCHED_COMMIT`, on a line of its own, beside `L1_FETCHED_REF`: the fixture installer records it in a side file (as `$CALLS.patchdir` is), not on its one recorded line, which six checks match to its end | the export dropped |
| UT6, also | `common/test-bootstrap.sh` | For the ref `release`, on the game path and the update path, the recorded address is the `refs/heads` form; for any other ref it is as today | the short form put back for `release` |
| UT7, also | `common/test-update-games.sh` | No `_update` folder: the sentence of step 2, exit 3, nothing run; a lock whose target is `0`: taken over; no `updating` left after a run that finished and after one that failed; the only game with two wrappers: not "No game is set up", exit 1; a wrapper kept with the game's program gone: not run; `L1_CURL` holding a quote, a `$` or a relative path: the file names `/usr/bin/curl`. The `.command`: a 404 gives its sentence, nothing run, exit 1, and no line of step 6; `000` gives the other sentence | the lock not removed; the program test dropped; the per-game version test dropped (apart from step 3's); the fetched file run whatever the code; the folder test of step 2 dropped; the match of the lock's target dropped; "No game is set up" said beside a failure |
| UT8, also | `common/test-launcher-window.sh`, `common/test-make-launcher-app.sh` | `--update-answer`: `second` gives `open`; `first` and `escape` give `nothing`. The foot's click: a press on the line and a release on a tile, a second click, a `reload` in between and `block,foot` each print `nothing`; the `foot` line carries the button role and 3.5's label, and `axpress:foot` opens the sheet. With 17 games and the last row selected the line's rectangle ends inside the shown part. `--update-tool` from inside a built app prints the tool when the key was written and `-` when not; a relative path and a link, given with `--update-dir`, give `-`; the key is absent when the tool was absent at the build | the foot's release not compared with what was armed; the foot's press action doing nothing; a relative path taken; a link taken; the key written when the tool is absent; the scroll rule left without the line's height |
| UT10, also | `common/test-check-release-move.sh` | The gate copied alone into a scratch `common/`, on a `release` that holds the file: it fails with the sentence of 3.7 | that case passing |
| UT11 | the gates | `common/check-links.py`, `common/check-identifiers.sh` at its residual of 9, `bash -n` on every changed script, every other test file of the repository, and every older mutant of each test file touched still red and none REFUSED | none |

### 6.1 Existing tests that change, by name

| File | What changes |
|---|---|
| `common/test-paths.sh` | `:62` (six lines become seven), `:72-73` (the exact printed lines); the header of `common/paths.sh` (`:5-7`). Its count of files that spell a root stays, because Surviving Mars's `setup.sh:151` stays |
| `cities-skylines-2/scripts/test-move-install.sh` | `:54` evals every `L1_*=` line `paths.sh` prints: one more |
| `common/test-bootstrap.sh` | the stub curl honours `-w`; the `STUB_CURL_EXIT` cases (`:189-191`) become UT1's, and the stub gains a second variable for the code, printed on standard output when `-w` is given; the recorded archive address for `release` becomes the `refs/heads` form; its header lists mutants to 10 and the file has 11: new ones start at 12 |
| `common/test-make-installer-app.sh` | the stub curl; the recorded curl line (`:143`) and the `STUB_CURL_EXIT=22` case (`:149-153`); its check that every copy of the pasted address agrees gains `updates.sh`'s, compared after `refs/heads/` is taken out; the stub honours `-o` (today it prints the script on standard output); new mutants from 11 |
| `cities-skylines-2/scripts/test-install.sh` and `test-install.golden` | `:489` ("low space: a CAUTION line, and on") runs on a finished install and inverts; the golden transcript loses that line and is recorded again on purpose, the difference read line by line; the cases that run the real setup need `common/updates.sh` in their fixture |
| `surviving-mars-relaunched/scripts/test-install.sh` | the same fixture; a `df` stub for UT2 |
| both games' `scripts/test-setup.sh` | each hand-made `common/` gains `paths.sh` and `updates.sh` (Cities: Skylines II's at four places for setup, `:151`, `:329`, `:337` and `:616`, and the `check-deploy.sh` copy at `:595`); the "writes nothing" snapshots; MUTANTs 17, 37 and 38 stay anchored because the new own-files check is a separate loop |
| `common/test-launcher-parity.sh` | the header's rules (eleven); both recorded note lists; new mutants from 25 |
| `common/test-check-release-move.sh` | the fixture; the gate's header ("asks four things") |
| `common/test-mac-inventory.sh` | `common/mac-inventory.sh` lists what lies under both roots, so `_update` appears: the expected lines |
| `common/check-deploy.sh` | it counts what Cities: Skylines II's setup copies: `_update/updates.sh` and `update-dir` are added to what it compares |
| `common/test-launcher-window.sh` | the header's list of modes; new mutants from 73; the single lines on which mutants 36, 39 to 41, 51 to 54, 57 to 59, 61, 63 and 64 are anchored (`press`, `release`, `show`, `unblocked` among them) stay whole; no existing case changes, because none gives `--update-dir` |
| `common/test-make-launcher-app.sh` | new mutants from 9; its three scratch `common/` folders hold no `paths.sh`, and the builder then writes no key (3.3) |

**Not tested, and said so:** what Terminal shows, and whether macOS asks anything when 14unch3r opens a
`.command` (UL1); the sheet drawn on screen, where its notes stand when it opens (UL1 found them 136 points down, and fixed it), Return and Escape on a sheet that holds a scrolling text view,
and the second showing of the list after the background refresh (UL1, by eye; on macOS 27 only, never on 14
or 15); a real notification, who macOS names as its sender and what a click on it opens (UL1b); GitHub's real
404 (UL1c) and its answer when it limits requests (not provoked: with no version heading in the answer,
nothing is offered); the menu item and the calls of `--refresh` (they live in the app
delegate, which no text mode builds: UL1); the whole chain from a real offer to a real update (UL4).

## 7. Live steps (each on James's word)

- **UL1. The check and the sheet, on the Studio, with nothing real changed.** A scratch `_update` holding one
  hand-written stamp on `release` at `v0.0.9` and the branch's `updates.sh`, and a 14unch3r built into a
  scratch folder with `L1_UPDATE_DIR` at that folder. It is opened with `open -n <app> --args <a scratch folder
  that holds one fixture game app>`, so that no real game is listed and none can be started; afterwards the
  scratch app is deleted and then unregistered with `lsregister -u`, as `common/test-launcher-window.sh` does
  for its own. Pass, each read off the screen or a file: the foot line
  reads `1launcher <the version release holds> is out. Click to see what changed.`; the sheet's notes begin
  with that version's section; `offer` holds it; a second opening within the day leaves `tried` unchanged;
  Return and Escape both close the sheet with nothing run; the menu holds "Check for Updates…" above "Quit
  14unch3r", and choosing it, and Command-U, each open the same sheet. Then press "Update" and let it run: today's
  `release` answers "not a Steam app ID: update" and fetches nothing (1.5), which shows the word arrives.
  Record every dialog macOS shows between the click and that line. Capture the window's region only, with
  the system in light and in dark.
- **UL1b. The notice.** With that scratch folder named by an `update-dir` beside the Studio's deployed
  Surviving Mars launcher, removed afterwards: a notification with 3.6's sentence at the first and the
  second start, none at the third. Record who macOS names as the sender and what a click on it opens.
- **UL1c. The 404.** The branch's root `install.sh` copied outside a checkout and run with a ref that does
  not exist: it prints "GitHub has no ...". Nothing is fetched.
- **UL2. The update, rehearsed from the branch, on the Studio's Surviving Mars** (which is set up from what
  is published). With the branch pushed and `L1_UPDATE_DIR` not set: write by hand, in the real `_update`,
  one stamp for 3215050 on the line `built-in-update` at `v0.0.9`. Fetch **the branch's own** root
  `install.sh` (`.../1launcher/built-in-update/install.sh`; `release`'s has no such word) and run it with
  `update built-in-update`. Pass: the installer's seven steps, setup, the stamp now at the branch's version
  on the line `built-in-update`, Cities: Skylines II named and not run (as set up with no record; or, if a setup from the checkout
  has stamped it by then, as set up from `checkout`), the game
  starts from its app afterwards. Record how long the run took, and compare the commit the installer prints
  with the commit pushed. Afterwards the Studio's state is `manual`, as it should be; its Surviving Mars then
  runs the branch's code until it is set up again from what is published.
- **UL3. The same on the MacBook**, for both games, after its `wrapper-names` step (W3).
- **UL4. The first real offer.** At the first release after the one that carries this plan, on a Mac or a
  macOS user account whose every game is set up by the pasted line (the Studio is `manual`; James names
  which): the foot line within a day, and Update brings it to the new version, after which the line is gone.
  Its record goes into this file's as-built header. Until that release this chain cannot run from end to
  end; UT7b and UL1 with UL2 are its nearest rehearsal, and they overlap at the word `update`.

## 8. Exit criteria

1. Every test of section 6 passes and every mutant listed was applied and seen red.
2. UL1, UL1b, UL1c, UL2 and UL3 passed and are recorded in this file with what was measured.
3. A Mac in the state `manual` makes no request: shown by UT4, and on the Studio after its window has been
   opened and a game started: `_update/offer`, `_update/tried` and `_update/notes.md` do not exist.
4. The guides hold the words of section 5; `CLAUDE.md` names the `_update` folder, the `update-dir` files
   and the new published addresses; the four statements of 3.10 are corrected.
5. Before `release` moves to the version that carries this: the rulesets of UD5 are active, shown by a
   read-only request. If James decides against them, that decision and his reason are written into 3.8, and
   this criterion is met by that record.
6. The as-built header is written at the build, with UL4 named as still to come.

## 9. Decisions for James

| | Question | Recommended |
|---|---|---|
| UD1 | May an update ever install without a yes? | No. Always the sheet, always a click. |
| UD2 | Where does the update run: in Terminal, as the install did, or inside the window with a progress bar? | Terminal, in this plan. It is the installer app's own way, it lets an installer ask its questions, and the player sees every line that runs. A progress view inside the window can follow once this has run on real Macs. |
| UD3 | From now on, does `release` move only to a commit that a `v` tag names (the gate's fifth question)? It makes every fix for a game update a release with its third number raised. | Yes. It is what makes "a newer version is out" a fact an installed Mac can read. |
| UD4 | How often is GitHub asked, and can it be switched off? | By itself at most once a day, failures included; a file `off` in `_update` switches it off; the guides say what is sent. |
| UD5 | Two rulesets on GitHub before this is published: on `release`, block force pushes and deletion; on the tags `v*` and `installer-*`, block update and deletion; both with nobody on the bypass list? | Yes. They are settings of the repository, so they are yours to make or to tell me to make. They stop an accident and a rewind, not someone who holds an owner's credential (3.8). |
| UD6 | Do the games' own launchers say when a version is out, for a player who never opens 14unch3r? | Yes: at most two notifications per version per Mac. They come from Script Editor as every notice of the launchers does, and show only where it may notify. |
| UD7 | Does an offer for a game that is not set up still open its guide, or start the installer from the window? | The guide, in this plan. Starting an install from the window is a plan of its own: it is the installer's first-run path, with the findings that has. |
| UD8 | Fix the two defects of step U0 in this plan? | Yes. The update prints the same words and would carry the same wrong sentence. |
| UD9 | Which number does the release that carries this take? | The second number rises: it asks a player with an install to paste each game's line once more. **(Not taken: see below.)** |
| UD10 | The sign in the window: one line at the foot, or a tile in a third group? Measured by the design lens: a tile adds 174 points to the window (172 becomes 346, and 520 with an offer), arrives up to 15 s after open, falls below the fold from five games with an offer (674 over the 600 limit) and is then never seen, and stays at every open for a player who has not updated. The line adds 24 points. | The line, with the menu item as the keyboard's way and the notification as the one loud sign. Past 600 points the line too is reached only by scrolling (from 13 tiles). A tile is a different design, not a bounded change: besides three texts, a second label, a three-block layout and a rule past 600 points, it needs a new role carried through the window's ranking, drawing, starting and listing, an icon, and a rule for Return on it. If you choose it, that section is written and checked as a pass of its own. |
| UD11 | May `update` be a published word of the root `install.sh`, the one first word that is not an app ID? Once published it can never be withdrawn. | Yes. It keeps one fetch for all games and adds no second address that must never move. |
| UD12 | May the window run a script outside its own bundle (`_update/updates.sh`) and, through it, ask GitHub? It ends "The window sends nothing anywhere." | Yes, with 3.5's limits: a time limit on every call, and nothing fetched is run. |
| UD13 | The new places outside the repository: the folder `<data root>/_update`, and a one-line file `update-dir` beside each deployed launcher. | Yes. `CLAUDE.md` gets its line in step U1, before the folder is made. |
| UD14 | Make the first release after the one that carries this a quiet one, with little or nothing changed for players? | Yes. The first real offer then risks only the mechanism. |
| UD15 | A player who declined the folder move or the new wrapper names by a variable in front of the pasted line: should an update started from the window never start a move or a rename (it would still finish one that was begun)? Or do the guides only tell that player to keep updating by their own line? | The guides only, in this plan (3.4, section 5). The other way changes how both setups decide a move and a rename, which this plan otherwise leaves alone; if you want it, it is added and checked before U1. |

**Answered by James on 2026-11-23**, each by a tap on a question that stood on its own, with the recommended
answer marked as such:

- **UD1 to UD8 and UD10 to UD15: as recommended.** Always a yes before anything installs; the update runs in
  Terminal; `release` moves only to a tagged version; once a day with an off switch; the two rulesets on
  GitHub; at most two notifications per version; an offer still opens its guide; the two faults fixed in step
  U0; the line at the foot of the window; `update` as a published word; the window may run the tool and ask
  GitHub; the new places outside the repository; a quiet first release afterwards; and for a player who
  declined the folder move or the new wrapper names, the guides warn and setup is left as it is.
- **UD5, who makes the rules:** Claude sets the two rulesets with the project's GitHub login, **on James's
  word at that time**, before `release` moves to this version, and shows a read-only check that they are
  active (exit criterion 5).
- **UD9: the third number rises**, against the recommendation. The release that carries this is `v0.3.1` if it
  follows `v0.3.0` directly. `CLAUDE.md` § Releases says the second number rises when a change asks someone
  with an install to do something, and this release asks for one paste per game; it takes the third number by
  James's decision, the rule's text is left as it is, and the release notes still tell a player to paste each
  game's line once. Nothing in the design depends on which number rises: the gate asks only that the version
  be newer than the one `release` holds.

## 10. Rollback

- **Before `release` moves:** nothing has reached a player. Revert the commits on `main`.
- **After, a wrong release:** it gets a successor (`CLAUDE.md` § Releases), and installed Macs are offered it
  within a day. **This holds only while the check, the window and the notice of the wrong release work.** A
  release that breaks one of them cannot be repaired by a successor on the Macs that took it: they need one
  paste of the installer line, and the release notes are the only way to tell them. That is the new blast
  radius of this plan, and why step U6 runs the suites on the tagged commit and UL4 is repeated in spirit at
  each release (a look at one installed Mac after `release` moves).
- **A player going back:** by pasting the line with an older version's tag after the app ID. For a tag from
  this version on, the stamp then names that tag, the state is `manual`, and nothing is offered until the
  plain line is pasted again. An older tag writes no stamp and rebuilds the window without the update parts:
  the old stamp must be removed by hand (`_update/installed/<app ID>`). Going back across `v0.2.0` or
  `v0.3.0` is not a plain paste: those releases moved folders and renamed wrappers.
- **The check alone:** `off` stops it on one Mac. If GitHub's answer ever stops parsing, each Mac keeps the
  state it had (`offer` is left as it was) and asks again once a day: the failure is silence, never a wrong
  offer.
- **Files:** the `_update` folder holds no game data. Moving it to the Trash puts a Mac back to "no record";
  the next setup writes it again.
- **After UL2:** the Studio's Surviving Mars runs the branch's code and its stamp is on the line
  `built-in-update`. Setting it up again from what is published puts both back.

## 11. Not in this plan

- **An install started from the window** (UD7).
- **A progress view inside the window** (UD2).
- **Engine changes**, among them the `ntdll.dll` change of issue #30 and an engine of Wine 11.20 or later.
  They need a plan of their own. What this plan gives them: an installer step that swaps an engine, as
  Surviving Mars's step 4 does for D3DMetal, is run by the update on every installed Mac, and asks first
  where it fetches something new.
- **Silent updates, a schedule, a background agent.** Nothing runs when no app of the project is open.
- **Signing.** Nothing fetched is signed, as nothing is today.
- **"Skip this version".** The line stays until the player updates.
- **Macs set up before this version.** They need one paste per game; nothing reaches them before that.
- **Removing a game.** There is no uninstaller. An update passes over a game whose wrapper is gone and
  removes its stamp (3.4).
- **A dry run of an update.** `install.sh update` takes no option; each installer's own `--check` is the dry
  run.

## Review corrections (check it 2026-11-23, pass 1)

Seven lenses read the first draft (`13966b6`). Two returned needs-rework (the builder: the window's section
and its test; the test plan: sections 6 and 7), five build-ready-with-fixes. Every blocker was read against
the source before it was taken. The plan above is the rework; this table says where each finding went.

| # | Finding | Lens | Where it went |
|---|---|---|---|
| B1 | The update walked the stamps, so a set-up game with no stamp was never updated and the run still said "Everything is up to date" | architecture, correctness | 3.4 step 4 (the games set up, not the stamps) and step 5; 3.3 item 6; section 5; UT7 and its mutant; UT7b |
| B2 | `runChild` gives nothing for a child that exits non-zero, so a failure sentence and the state after a failed fetch could not be read | correctness, builder, security, architecture | 1.3; 3.2 (every call exits 0 and says the outcome); 3.5 ("Update", the menu table); UT4, UT8 |
| B3 | `-w '%{http_code}'` lands inside a script taken from curl's standard output | correctness, security, test plan | 1.5; 3.4 (the body goes to a file); U0; UT1 and its mutant |
| B4 | The window's sheets, menu and button are in the app delegate, which no text mode builds: UT8 could not be written, and "nothing installed without a yes" had no mutant | builder, test plan | 1.3; 3.5 (the seams, their text modes, the source gate); UT8 and its mutants |
| B5 | "It adds no new trust" was wrong about what the trust reaches, and "force pushes and deletion" does not deliver the claim | security, platform | 3.8 rewritten; UD5; exit criterion 5 |
| S1 | "At most once a day" was false after a failed fetch | all but design | 3.1 (`tried`); 3.2; 3.8; UD4; UT4 |
| S2 | Values read back from `_update` reached bash arithmetic unmatched | security, correctness, platform | 3.1 (the matching rule); UT3 and its mutant |
| S3 | The fetch must not read curl's exit code for the kind of failure; no `-q`; a tag named `release` would be ambiguous | platform, security | 1.5; 3.2 (the fetch rule, the `refs/heads` address); 3.7; UT1, UT4 |
| S4 | `l1w_find` exit 2 unhandled; the wrapper variable in the environment decided what is set up; a wrapper with the game removed still ran the installer | security, architecture, correctness, builder | 3.4 step 4; UT7 |
| S5 | The "newer" rule guarded the offer and not the install; two updates at once; a stamp older than the offer after an update | security, platform | 3.4 steps 2 and 3, and the per-game test of the stamp's version; UT7 |
| S6 | The Desktop question at every update; the wrapper-rename decline cannot reach the window's update | architecture, security | 1.1; 3.3 (`L1_UPDATE`); 3.4; section 5; UT5 |
| S7 | The own-folder test and the write-beside-and-rename were claimed for both setups and hold for one; the own-files lists were not named; three older mutants would refuse | security, correctness, builder | 3.3 |
| S8 | `--noted` is waited for; the note must join rule 5's lists; Surviving Mars has no launcher-notes test; the notice can be spent unseen | correctness, architecture, builder, platform | 3.6; UD6; UT9 (`common/test-update-notice.sh`); UL1b |
| S9 | The state line's fields were undefined; the `manual` sentence was wrong for a named version; a failed fetch could say "newest" | correctness, architecture, design | 3.2 (`-`, the detail field); 3.5 (the menu table and its order) |
| S10 | UL2 could not run and contradicted itself; UL1 had no pass condition; UL4 named no Mac | architecture, correctness, test plan, platform | section 7 |
| S11 | A tile is too heavy a carrier; the sheet had no size, font or rule for the notes; eight sheets did not set `sheet`; words untrue in some state | design | UD10; 3.5; 3.2 (`--notes` cleaned); section 5's words |
| S12 | Three recorded statements ended without being named; three decisions missing | architecture | 3.10; UD11 to UD13 |
| S13 | Section 10 overclaimed; after the merge `release` is all-or-nothing; the gate's trigger could switch itself off | architecture | section 10; U6; 3.7 |
| S14 | Existing tests, a recorded transcript and mutants that change were not named | builder, test plan, correctness | 6.1 |
| S15 | "The release commands refuse a tag whose section is not found" was false | correctness | 3.1; 3.7 (`--version-of` in the release commands) |
| M | Wrong line cites (`install.sh:25`, `launcher-window.swift:1270`, the setup header); `mktemp` with a suffix; `read` on a line with no newline; "3.6 makes a gate"; one game or each | several | corrected in place |

**Not taken, with the reason.** "Restrict who may update `release` to James's account" (security): both
owners are James's accounts and every session on his Macs pushes with one of them, so the rule would name
the same credential it is meant to keep out. 3.8 says what the rules do and do not stop. A fresh macOS user
account to measure a first notification (platform): making an account is a system setting and James's; UL1b
records what the Studio shows, and UD6 says the limit.

### Second pass: fitted re-check of the rework (2026-11-23, pass 1b): build-ready-with-fixes, folded

Two agents read the rework (`ba7daad`): one checked every row of the table above against the plan and the
code and ran the plan's own code (the block of 3.6, the read rule of 3.1, the version pattern); one traced
section 3.5 as a builder and measured a 20-line prototype of the foot line in the window's text modes. Both:
build-ready-with-fixes, no design rework. Where each finding went:

| # | Finding | Where it went |
|---|---|---|
| F1 | The folder move has a published decline too (`CS2_PATCH_DIR`); the guide words did not say it | 3.4 ("What an update can do without asking"); section 5; UD15 |
| F2, W-B2 | The mutant "a sheet shown without setting `sheet`" could not go red; which button runs `--open` was outside the seams; the source gate named `launch`, which an update never uses | 3.5 (`sheetAnswer`, the three source gates); UT8 |
| F3 | "Update again from 14unch3r" told the player to do what the window will not offer | 3.4 step 5; section 5 row 1; 3.5 row 7 |
| F4 | The `.command` after a failed fetch had no exit code and no test | 3.4 (file steps 5 and 6); UT7, also |
| F5, W-S1, W-S2 | "Again at every reload" would stall the main thread or loop; the notes call sat between the click and the sheet | 3.5 ("When", the refresh, the notes kept with the state); source gate 3 |
| F6 | The lock: no folder on an older Mac, nobody removed it, its target unmatched | 3.1; 3.4 step 2; UT7, also |
| F7 | The archive was still fetched by the short name | 3.4 (the root `install.sh`); U2; UT6, also; 6.1 |
| F8 | "Never finds a program by `PATH`" was untrue of the tool and of the block | 3.2 (`local PATH`); 3.6 (full paths, run again); UT3, UT4, also |
| F9 | The gate's widened trigger had no rule when the file is gone | 3.7; UT10, also |
| W-B1 | In the empty state the grid is hidden, so nothing could draw the line | 3.5 (no foot line with no tile); UT8 |
| W-S3 | `Checking for a new version…` had no state to live in | dropped: the item is disabled, and 3.5 says what shows |
| W-S4, W-S5 | The VoiceOver element and the click rule were unspecified and untested | 3.5 (a subview, its role and press action; the `--act` words); UT8, also |
| W-S6, W-S7 | `cut()` cannot cut at that width and the case cannot occur; past 600 points the line is below the fold and was cut by 2 points | 3.5 (the measurement, the rectangle, the scroll rule); UD10 |
| W-S8, W-S9, W-S10 | The text modes had no forms or outputs; the call of the tool was not a seam; nothing tested that the window reads the key | 3.5 (the forms, the outputs, `askUpdate`, `updateTool`, `--update-tool`); 3.3 (the copy before the build); UT5 and UT8, also |
| W-S11 | 6.1 had no row for either window test file | 6.1 |
| W-S12 | UL1's app would list and could start the real games | UL1 |
| M | The cite for standard error; a two-line stamp; the vacuous `777` case; cases without mutants; "No game is set up" beside a failure; the own-folder rule said two ways; an unmeasured "seconds per game"; the block passing an unmatched answer to `note`; `offer` lowered by an old answer; which runs write to `_update`; UL2's dependence on the checkout's stamp | corrected in place: 1.3, 3.1, 3.2, 3.3, 3.4, 3.6, section 5, UT7, the "also" rows, UL2 |

### Third pass: the second fold verified (2026-11-23, pass 1c): build-ready-with-fixes, folded

One agent read exactly what the second fold changed (the working tree over `ba7daad`): each row of the table
above against the normative text, new text against the old text left standing, the test table, and every
fact the fold had taken from the re-check agents, read in the source. It ran the block of 3.6 as it stands in
this file. No blocker and no design rework; nine should-fixes and eleven minor points, all words and test
rows, each folded in place:

- source gate 2 could not be green beside the `--update-open` mode (3.5);
- an answer older than `offer` would still have replaced `notes.md` (3.2; UT3 and UT4, also);
- the block's new match and full paths had no clause and no mutant in UT9;
- the driver's folder test cited a function it does not have (`l1u_own`, 3.2 and 3.4 step 2);
- `--update-tool` reads the key, against "only the window reads it" (3.5);
- the menu's way to the sheet: the notes, the no-tile case, "no answer" against "no tool" (3.5, row 6);
- UL1 had no step for the menu item;
- curl's path in the `.command` (3.4); the line "drawn by the grid" beside "a subview" (3.5); clauses
  without mutants; the stub's unused file; smaller points in 3.1, 3.3, section 5 and 6.1.

This last fold was audited inline, both ways, and has not been read by an agent. The plan is checked again
before U1 in any case (the status line says why).

A reference build of U0, U1, U2, U4 and U5 **from the first draft**, with its test logs, is kept in
`<workspace>/built-in-update-p0/` (`builder-first-draft.patch`; the game's `CLAUDE.md` says where the workspace
is). It predates the rework: it shows what breaks and where, and is not the design.

### Pass 2: the re-check after `wrapper-names` merged (2026-11-24): build-ready-with-fixes, folded

One read-only agent on Fable 5.2 against `main` at `35f0eb8`, with this branch's plan beside it. It opened all
79 live cites (72 in files unchanged since `efe176b`, 7 in the two launchers and `common/test-launcher-parity.sh`),
counted the rules and mutants of the parity test, and read the code U0, U1 and U2 touch. No blocker. Two of its
findings (5 and 3) were read again in the source by the session before they were folded.

| # | Finding | Where it went |
|---|---|---|
| 1 | The parity test's rule 10 and mutants 17 to 24 are taken by the sign-in wait | 3.6, U4, UT9 and 6.1: rule 11, mutants from 25 |
| 2 | Seven cites in the launchers and the parity test had moved | 1.4 and 3.6, corrected |
| 3 | 3.3 item 6 names another game by its title, and no setup reads `games.tsv` | 3.3 item 6: the title's source, and `games.tsv` in the own-files loop and in UT5's fixtures |
| 4 | U1 exports `L1_FETCHED_COMMIT`, but its only test was a clause of UT6, built at U2 | a "UT5, also (built at U1)" row with its mutant; the clause removed from UT6 |
| 5 | U0's fetch into a file would unanchor mutants 5 and 6 of `common/test-make-installer-app.sh` | U0: read into `S`, removed at once; the two lines keep their text |
| 6 | 6.1 did not say where that file's new mutants start | 6.1: from 11 |
| 7 | "four places" in Cities: Skylines II's `test-setup.sh` are five | 6.1, with the lines |
| 8 | "wait ten minutes" is not true as a flat statement (issue #32) | the status line: "up to ten minutes". No design consequence: the notice block runs before `step 1` |
| 9, 10 | two loose ranges (`setup.sh:70-74`, `test-bootstrap.sh:189-190`) | 3.3 and 6.1 |

**For the builder, not said elsewhere in the plan** (each read at `35f0eb8`):

- **U0.** Both stub curls exit before they write anything when `STUB_CURL_EXIT` is set
  (`common/test-bootstrap.sh:74-80`, `common/test-make-installer-app.sh:62-67`); UT1's "a 404 with exit 0, 22
  and 56" needs the second variable. `GAME_EXE`, `GDIR` and `MANIFEST` are set only by `use_wrapper`
  (`common/install-core.sh:148-157`), so `core_space` tests `prefix_known` first. The low-space transcript that
  inverts is `test-install.golden:806-817`.
- **U1.** The new own-files loop of Cities: Skylines II's setup sits under `MAC_ONLY = 0`, inside the existing
  `if` after its `done` (mutant 38 then still applies); Surviving Mars's goes below the loop at `:93` (mutant 17
  removes from that `for` to the first `done`). `L1_FETCHED_COMMIT` is exported on a line of its own (mutant 5
  matches the whole `export L1_FETCHED_REF` line), and new locals are appended after `local id="" ref=release `
  (mutant 6). The stamp in Cities: Skylines II's setup goes between `:595` and `desktop_step` at `:596`; exit 5
  is at `:618`.
- **U2.** `install.sh:69` keeps its text and indent (mutant 7), so the `case` at `:68-74` is not wrapped; no
  second line that is six spaces and `return 2 ;;` (mutant 10); the early return for `update` goes after `:114`
  and before `:115`; `update --yes` is caught by `$#` after the word loop (`:45-56`). `l1w_row` returns 1 for
  an app ID it does not know (`common/wrappers.sh:44`): a new row of a fetched `games.tsv` then falls under "not
  set up here".

## UL1 on the Studio (2026-11-24, on James's word: "Sure. I'm on my way home", then "I'm at the Studio"): passed, one defect found and fixed

From the branch at `d4c6a19`, then with the fix below. Staged while the screen was still locked, with no request
made: in the workspace's `built-in-update-ul1/`, a scratch `_update` (mode 700) holding one stamp
`installed/999999` (`release`, `v0.0.9`) and the branch's `updates.sh`; a fixture app "Stand-in Game" (ID
999999) in a folder of its own; and a 14unch3r built into a scratch folder with `L1_UPDATE_DIR` at that
`_update`. Opened with `open -n <app> --args <the fixture's folder>`. The session drove the window through the
accessibility interface, which James allowed for 14unch3r and Terminal; the three key presses were his own.
The window alone was captured, with the system in Dark.

| What | Result |
|---|---|
| The first opening | **Pass.** Before it: state `unknown`, no `offer`, no `tried`. Within the first second the window was 444 by 204, then 444 by 228 (the line's 24 points), and `offer` (`v0.1.0`), `tried` and `notes.md` were there. The foot line reads "1launcher v0.1.0 is out. Click to see what changed." |
| The sheet, by a click on the line | **Pass, after the fix below.** Message "1launcher v0.1.0 is out."; text "This Mac has v0.0.9. Update opens Terminal and runs the installer again for each game set up here. It may ask you a question there."; the buttons "Update" and, as the default, "Not Now". The sheet is 562 by 500 and hangs over the small window. The notes begin "v0.1.0 (2026-11-16)" |
| "Not Now" | **Pass.** The sheet closes; Terminal is not started; no update folder is made |
| The menu | **Pass.** "Check for Updates…" stands above "Quit 14unch3r". Chosen, it opens the same sheet, and `tried` is unchanged (the state held was `ready`, so nothing is asked again, as 3.5 says) |
| A second opening within the day | **Pass.** The window comes up at 444 by 228 with the line; `tried` is unchanged |
| Escape, Command-U, Return (James's keys) | **Pass.** James: "The keys behaved as expected." After the three, the sheet was closed, the window still open, `tried` unchanged, and nothing had been run |
| The system in Light (James switched it) | **Pass.** The window and the sheet were captured alone again: both keep their dark look, as the window's design has it, and every word reads as in Dark. James: "window looked the same in light/dark". In that capture "Not Now" is drawn without its colour: the window was not the active one when it was taken |
| "Update" | **Pass.** At 07:53:11 the click; the window quit; Terminal opened and printed "Fetching the installer from github.com/macgameport/1launcher ...", "not a Steam app ID: update", the usage line, the front page's address, then "The update did not finish: see the lines above. You can close this window."; by 07:53:22 the file and its folder were gone. So the word arrives at today's `release`, which does not know it |
| Dialogs of macOS between the click and that line | **None that held it up:** nobody was at the Studio at that minute and the lines were printed within eleven seconds. The privacy log has no question in that minute; the quarantine resolver was asked once at 07:53:12, with nothing shown |

**The defect, and its fix (`common/launcher-window.swift`, the class `NotesText`).** The notes opened 136 points
down, in the middle of their text. Measured with a copy that wrote the scroll position down: at the sheet's
opening the position is 0, and a tenth of a second later 136, moved by an animated scroll of AppKit's;
136 is (450 - 178) / 2, the view's height less its frame's, halved. The sheet's first responder was the notes
view, not "Not Now": with keyboard navigation off (the default of macOS) no button can hold the keyboard, the
sheet gives it to the next view that can, and AppKit brings that view into sight by its middle. The notes view
now does not accept the keyboard while the sheet opens, and accepts it from the next turn of the run loop on
(Tab, with keyboard navigation on) and at a click, which selecting text needs. With it the position stays 0 and
the notes begin with the version's heading. Two attempts before it did nothing and are not in the code: a scroll
to the top after the sheet is shown (the animation comes later), and refusing a request to show the whole view
(the scroll does not go through the text view). No test sees this: the text modes build no sheet. The window's
test passes on the changed source (245 cases) and all 96 mutants of its two test files are red.

**Seen and not changed, for James to decide:**

1. **The line's accessibility press opens the sheet and answers "failure" to its caller.** `showUpdate` shows
   the list anew before the sheet, so the element that was pressed is gone when the press returns. VoiceOver
   would open the sheet; whether it sounds an error was not heard.
2. **A link in the notes shows as it is written,** `[Install guide](https://...)`: 3.2's five cleaning rules
   have none for links, and `CLAUDE.md` § Releases asks for full addresses in a section.
3. **Terminal's window title** shows the temporary folder's path and the file's name.

**Cleaned up afterwards:** the scratch window quit; the two scratch builds of 14unch3r and the fixture app moved
to the Trash and unregistered with `lsregister -u` (a move into the Trash registers an app again, so the
unregistering is done after the move: a first try before it left both copies registered). `lsregister -dump`
then names one 14unch3r, the installed one. The scratch `_update`, the captures and the build outputs stay in
the workspace's `built-in-update-ul1/`. Exit criterion 2 still wants UL1b, UL2 and UL3.

## UL1c on the Studio (2026-11-24, on James's word: "Yes, run UL1c"): passed

The branch's root `install.sh` (at `574c347`) copied alone into a new folder under `/tmp`, outside any
checkout, and run with the ref `no-such-version-ul1c`, which GitHub does not have. Three forms, each with its
standard input closed:

| Run | Printed | Exit |
|---|---|---|
| as a file, `949230` and the ref | "Fetching 1launcher (no-such-version-ul1c) from github.com/macgameport/1launcher ...", then "GitHub has no \"no-such-version-ul1c\" of 1launcher. The current way in is at:" and the front page's address | 1 |
| the pasted form (`/bin/bash -c "$(cat install.sh)" 1launcher-install 3215050 <ref>`) | the same three lines | 1 |
| `update` and the ref | the same three lines | 1 |

Nothing was fetched beyond GitHub's answer, no installer ran, and no `1launcher-fetch.*` folder was left in the
temporary folder. Asked by hand with the same options, `/usr/bin/curl` 8.7.1 exits 0 with the answer `404` and
a body of 14 bytes: without `-f` the code is all there is to go by, which is what U0 made the script read.
Before U0 this run said "GitHub could not be reached (curl exit 56)" (issue #31).

## UL1b on the Studio (2026-11-24, on James's word: "Yes, run UL1b"): passed: the notice at the first and second start and none at the third; the notification comes as Script Editor's

**What the step needed and the plan did not say.** The Studio's installed Surviving Mars launcher was
`v0.3.0`'s, which has no notice block, so an `update-dir` beside it would have done nothing. For the step the
branch's launcher (at `18b9eb6`) was put in its place, written beside and renamed, with the original kept
beside it; `update-dir` named the scratch `_update` of UL1 (state `ready`: installed `v0.0.9`, offered
`v0.1.0`, `tried` of that morning, no `noted`). James was told before the first start. Afterwards the original
was put back and is byte for byte `main`'s again (sha256 `a73ceab28f5b4888`, as before the step), and the
`update-dir` was taken away.

| Start | Result |
|---|---|
| 1, from the game's app at 08:15:52 | **The notice: as 3.6 has it.** The launcher's log has, as the session's first line, "1launcher v0.1.0 is out. Open the 14unch3r app to update.", before "[1/5] Starting Steam and signing in…"; `noted` then held `v0.1.0` and 1; `tried` was unchanged, so the look in the background asked GitHub nothing (it had been asked that morning). Whether macOS showed the notification, and whom it named as the sender, is James's to say. **Then the start stopped at step 3:** Steam logged on 28 s after the start, and the launcher's own check found a Steam Cloud conflict on `account.dat` and `account.dat.bak`, said so in its alert, shut Steam down, and ended when James answered. No game was started |
| 2, at 08:22:09, after the conflict was cleared (below) and the branch's launcher put in place again | **The notice again.** One line of it in the launcher's log; `noted` then `v0.1.0` and 2; `tried` unchanged. The game ran and was closed 15 s after its window: exit `rc=0`, saves uploaded |
| 3, at 08:23:23 | **No notice.** No such line in the log; `noted` unchanged at 2; `tried` unchanged. The game ran: `rc=0` |
| 4, at 08:34:31, for James's eyes (he had been away from the screen at the first three, and asked for it again): `noted` moved aside, the branch's launcher in place once more | **The notice, and James saw the notification on screen ("I saw it").** One line of it in the log; `noted` then `v0.1.0` and 1. The game reached its menu and was closed there; saves uploaded. The launcher took about four minutes to end after the game's window, longer than at the other starts; why was not looked into. The original launcher was put back afterwards, byte for byte `main`'s |
| 5, at 09:01:07, so that James could read the sender (`noted` was 1, so the notice was due once more) | **The notice; `noted` then 2.** James: "it had the script editor icon with no title". The game reached its menu; saves uploaded; the original launcher put back, byte for byte `main`'s |

**Who macOS names as the sender: Script Editor.** James saw its icon on the notification, and the notification
system's own log has `bundleIdentifier: com.apple.ScriptEditor2` for the notifications of 08:34:31 and of
09:01:07. That is what 1.5 had only from reports: the launchers post through `osascript`, and macOS shows
`osascript`'s notifications as Script Editor's. James saw no title on it, though the launcher passes the game's
name as the title. On this Mac it showed at once, so Script Editor may notify here; what a Mac shows on which
it has never been allowed was not measured. What a click on the notification opens was not tried. **For James
to decide, with the three of UL1:** whether a notice that looks like Script Editor's is good enough, or the
notice should come from one of the project's own apps (not this plan's design).

At starts 4 and 5 the launcher ended about three minutes after the game was closed, where the starts before
them took about one. Not looked into; nothing was lost (both say "saves uploaded").

So the launcher gives the notice at the first two starts and not at the third, and its look in the background
asked GitHub nothing in any of the three (it had been asked that morning). The watcher's own verdict on starts 2
and 3 reads "no menu": it closed the game 15 s after the window, before the menu, which is the watcher's dwell
and not the game's fault (the start after the clearing, with 25 s, reached it). After start 3 the original
launcher was put back again, byte for byte `main`'s.

**The conflict is the session's doing, of the evening before, and not the update's.** On 2026-11-23 at 20:16 a
start made for issue #33 lost its Steam session to the MacBook's Steam and exited offline, so this Mac's
`account.dat` changed and was not uploaded; the MacBook's sessions of that night then uploaded theirs. The
launcher found it at the next start, as `surviving-mars-relaunched/INSTALL.md` § "A Steam Cloud conflict" says
it does, and that section says how to clear it.

**Cleared the same morning, on James's word ("Yes, clear it"), the guide's way.** With nothing of Steam running:
the saves folder and Steam's record folder for the game were copied whole into the game's backup folder
(`backup/conflict-20261124-081934/`, compared: no difference), and `account.dat`, `account.dat.bak` and the
record's `remotecache.vdf` were moved there, not deleted. The next start (08:19:42) said "Steam Cloud: saves up
to date.", the game reached its menu, exited `rc=0`, and "saves uploaded". Afterwards: `account.dat` and its
`.bak` are back, the cloud's; seven of the eight savegames are byte for byte as before; **one, which differed
from the cloud's, was replaced by the cloud's newer copy** (changed on the other Mac that morning), and two
that only the cloud had were added. The copy made before holds the replaced one. This is the case the guide
called not measured, and the guide now says it.

## UL2 on the Studio (2026-11-24, on James's word: "Yes, run UL2"): passed

The branch pushed at `a31d0a3`, `L1_UPDATE_DIR` not set. Before: no `_update` folder on this Mac; the installed
Surviving Mars launcher was `v0.3.0`'s; 14unch3r had no `L1UpdateDir`; nothing of Steam or Wine running. By hand,
in the real `_update` (made with its `installed/`, both mode 700): one stamp `installed/3215050` on the line
`built-in-update` at `v0.0.9`. Then the branch's own root `install.sh` was fetched from
`raw.githubusercontent.com/.../built-in-update/install.sh` and run as
`/bin/bash -c "<it>" 1launcher-install update built-in-update`, with its standard input closed.

| What | Result |
|---|---|
| The fetch | "Fetching 1launcher (built-in-update) ...", then "1launcher at commit `a31d0a357a4c0ea45b9f7439df368fa5201b6565`": the commit pushed |
| Surviving Mars's installer | **Pass.** Its seven steps, every one `OK` (the wrapper, D3DMetal 3.0, Steam and the game as they were), then setup: the launcher and its helper deployed, the game's app, the progress panel and 14unch3r built. No question was asked |
| Setup's closing words | "Cities: Skylines II was set up by an older version. Paste its installer line once, so that it gets updates too." |
| The update's closing block | "Cities: Skylines II: set up by a version that keeps no record. Paste its installer line once: `<the pasted line with 949230>`", then "Surviving Mars: Relaunched: updated.", then "Not everything was updated. Do what the lines above say." Exit 3. Cities: Skylines II's installer was not run |
| How long | 8 s from the start of the update to its exit |
| The stamp | `built-in-update`, `v0.3.0`, the commit above, the time: the branch's version on the line `built-in-update` |
| The state afterwards | `manual`, installed `v0.3.0`, detail `built-in-update`. `_update` holds `installed/` and `updates.sh` (the branch's, byte for byte) and nothing else |
| What setup deployed | the branch's launcher (with the notice block) and `update-dir` beside it, naming `_update`; 14unch3r rebuilt with `L1UpdateDir` at `_update`, and `--update-tool` from inside it prints the tool. The wrapper's own files are untouched (its `ntdll.dll` has the hash it had before) |
| The game from its app afterwards | **Pass.** Started at 16:28:23: logon 28 s and window 44 s after the start, the menu reached, closed there, `rc=0`, "saves uploaded"; no notice in the launcher's log, as the state `manual` has it |
| Exit criterion 3 on this Mac | **Pass.** After that game start, after 14unch3r was opened (three tiles, no line at the foot, 444 by 204) and after "Check for Updates…" was chosen in it: `_update/offer`, `_update/tried` and `_update/notes.md` do not exist. The menu's answer: "No update is offered on this Mac." and "A game here was set up from a named version. Paste its installer line from the guide to follow new versions again." |

**How the Studio stands afterwards.** Its Surviving Mars and its 14unch3r run the branch's code, and stay so
until a setup from another tree is run; its state is `manual`, so it asks GitHub nothing and is offered nothing.
Cities: Skylines II is as it was (`v0.3.0`'s files, no stamp). Exit criterion 2 still wants UL3, the MacBook.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-23 | 1 | architecture and rollout; security and privacy; correctness; builder simulation; test plan; design and words; platform facts | seven agents, none editing the repository; the builder in a scratch clone with U0, U1, U2, U4 and U5 built and the test files run; measurements against GitHub and of curl, bash and `mktemp` on this Mac; each blocker read against the source inline | Fable 5.2 | `built-in-update` at `13966b6` (`wrapper-names` at `efe176b` and the plan) | needs-rework; reworked the same day |
| 2026-11-23 | 1b | the rework: every correction against the plan and the code; section 3.5 with UT8 traced as a build | two agents, none editing the repository; the plan's own code run under bash 3.2.57; a prototype of the foot line built in a scratch folder and measured in the text modes | Fable 5.2 | `built-in-update` at `ba7daad` | build-ready-with-fixes, folded |
| 2026-11-23 | 1c | the fold of pass 1b: each row against the normative text, new text against old, the test table, the facts taken from the re-check agents | one agent, not editing the repository; the cited lines read in the source; the block of 3.6 run under bash 3.2.57 with stubs | Fable 5.2 | the working tree over `ba7daad` | build-ready-with-fixes, folded |
| 2026-11-24 | 2 (fitted re-check after the merge of `wrapper-names`) | every cite at the merged tree; the parity test's numbers; the notice block's place; what U0, U1 and U2 touch | one read-only agent; findings 3 and 5 read again in the source by the session; folded the same night, audited two-sided | Fable 5.2 | `main` at `35f0eb8` | build-ready-with-fixes, folded |

Key paths: `install.sh`, `common/install-core.sh`, `common/paths.sh`, `common/wrappers.sh`,
`common/games.tsv`, `common/launcher-window.swift`, `common/make-launcher-app.sh`,
`common/make-installer-app.sh`, `common/check-release-move.sh`, `common/check-deploy.sh`,
`common/mac-inventory.sh`, `common/test-bootstrap.sh`, `common/test-launcher-parity.sh`,
`common/test-launcher-window.sh`, `common/test-paths.sh`, `cities-skylines-2/scripts/install.sh`,
`cities-skylines-2/scripts/setup.sh`, `cities-skylines-2/launchers/launch-cs2-dxmt11.sh`,
`surviving-mars-relaunched/scripts/install.sh`, `surviving-mars-relaunched/scripts/setup.sh`,
`surviving-mars-relaunched/launch-relaunched.sh`, `CHANGELOG.md`, `CLAUDE.md`.
