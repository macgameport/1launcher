# The launcher first: one pasted line installs 14unch3r, and its window installs the games

**Status: check-it'd 2026-11-26 — needs-rework (pass 1). Draft written 2026-11-25. No build may start from this
file until it is reworked, checked again, and carries a verdict that allows it.** Nothing below is built. What
the pass found is the section "Review corrections" near the foot: **the sections above it are NOT yet corrected**,
so where they disagree with it, it is right. The lenses the check should recruit,
by what this plan touches: architecture, security (a click that runs code from `release`; a file written with a
number in it), correctness, the builder lens, design (the window's tiles, a new sheet, published words),
platform facts (Apple's Command Line Tools, Gatekeeper, Terminal), and the test-plan audit.
Every `file:line` below was read on `main` at `91cfb63` (2026-11-25). A path is relative to the repository
root. Tracking: no issue yet; one is opened when the check is done.

**Decisions: taken by James on 2026-11-26** (section 13, the block under the table). Four are his own: the install
view goes on the roadmap (LFD1), 14unch3r is compiled on the player's Mac until the project is a registered Apple
developer (LFD2), a game that is not set up is drawn in grey scale and ghosted (LFD4), and the wait for Apple's
Command Line Tools is asked for first and overlapped (LFD14, new). The fold of those four is new material and has
not been checked either.

**How to read the marks.** **[read]**: read in the code or a plan at that commit, by the session that wrote
this draft. **[record]**: taken from another plan's record of a measurement, not measured again. **[inferred]**:
follows from what was read, and was not run. **[not known]**: the code and the plans do not answer it; it is a
probe or a decision below. Nothing in this draft was measured: no test, build, app, Wine or network request was
run while it was written.

This plan's steps are LF0 to LF8 (LF8, added with LFD14, may come after LF7), its tests LFT1 to LFT11, its
probes LP1 to LP3, its live steps LFL1 to LFL6 and its decisions LFD1 to LFD14.

## 0. What James asked for (2026-11-25)

> "I think it's worth considering using an agent to unify the installation process, make a plan. The idea being
> that a person would simply install the launcher, and then the launcher would run any subscripts appropriate
> for games, rather than having a separate script for each game that a person has to navigate."

Today a player pastes one line per game, each ending in the game's Steam app ID, and must find the right line
in the right guide. The target: one pasted line that names no game installs 14unch3r; its window lists the
games this project ports; a click on one, and a yes, runs that game's installer. The lines that name a game
keep working as they are.

This is the plan two earlier decisions left for later: `docs/plans/surviving-mars-install.md`, MD8 ("14unch3r's
'Not set up' tile starts the installer": "A later slice, with its own plan", `:889`), and
`docs/plans/built-in-update.md`, UD7 and its section 11 ("An install started from the window").

## 1. What is true today

### 1.1 The root `install.sh` and the table of games

- **With no word it installs nothing [read].** `install.sh:86-92`: an empty first word prints "Say which game:
  the first word is its Steam app ID.", the usage line, and then, from a checkout, the games that have an
  installer, or, pasted, "The games and their IDs are listed at https://github.com/macgameport/1launcher". It
  returns 2. Nothing is fetched: this test comes before the fetch (`:110`). Options alone do the same, because
  the word loop stops at the first option (`:54-65`). `common/test-bootstrap.sh:191-196` holds this, and its
  mutant 10 is "with no game named, the list got by fetching first" (`:20`).
- **One first word is not a number [read].** `update` (`install.sh:78-82`): it takes a ref and nothing else,
  refuses from a checkout, and after the fetch hands over to `common/update-games.sh` of the fetched tree
  (`:138-148`). Every other word that is not digits gets "not a Steam app ID" (`:88`).
- **A game is found by its ID in the fetched table [read].** `game_folder` (`install.sh:30-32`) takes the row
  of `common/games.tsv` whose first field is the ID, only if the row has exactly four fields and its folder
  matches `^[a-z0-9][a-z0-9-]*$`, and the script then runs `<folder>/scripts/install.sh` with the options
  (`:149-159`), after exporting `L1_FETCHED_REF` and `L1_FETCHED_COMMIT` (`:156-157`).
- **The table [read].** `common/games.tsv`: two rows of four tab-separated fields: Steam app ID, folder, title,
  the address of the set-up guide (949230 and 3215050). Three programs read it and each insists on four
  fields: `install.sh:31`, `common/update-games.sh:135`, `common/launcher-window.swift:467`.
- **What is published [read].** `CLAUDE.md` § Published addresses: the root `install.sh` and
  `common/games.tsv` never move; a row's first field never changes; a published thing names a game by its
  Steam app ID; `install.sh update` is a published word; `release` moves only to a commit a `v` tag names. The
  guides hold the pasted line six times, each with an ID (`README.md:32`; `cities-skylines-2/INSTALL.md:23`,
  `:475`, `:538`; `surviving-mars-relaunched/INSTALL.md:26`, `:180`).

### 1.2 The installers

- **One shared core, per-game settings [read].** `common/install-core.sh` is read with `.` by a game's
  `scripts/install.sh` after the game has set eighteen settings and defined five functions (`:8-19`); a
  missing one stops it (`:20-26`). The game calls the stages in order and puts its own between them:
  Cities: Skylines II has six steps (`cities-skylines-2/scripts/install.sh:89-121`), Surviving Mars seven, with
  a question and an engine step of its own (`surviving-mars-relaunched/scripts/install.sh:132-238`).
- **It talks to the player in Terminal [read].** What a run can ask, each only when its input is a terminal
  and `--yes` was not given: Rosetta, "type y and press Return" (`common/install-core.sh:310-319`); Surviving
  Mars's question before anything of Apple's D3DMetal is fetched
  (`surviving-mars-relaunched/scripts/install.sh:138-157`); each setup's "Press Return to continue" on a Mac
  outside what was tested (`cities-skylines-2/scripts/setup.sh:105-110`,
  `surviving-mars-relaunched/scripts/setup.sh:82-88`); and Cities: Skylines II's Desktop shortcut
  (`cities-skylines-2/scripts/setup.sh:574`), which an update does not ask (`:568`). With nobody to ask, the
  answer is "stop", exit 3. Besides the questions it tells the player what to do in other windows: Apple's box
  for the Command Line Tools (`common/install-core.sh:333-335`), Steam's sign-in and its Install button
  (`:466-474`), and it prints the download's progress by percent (`:476-501`).
- **It can be stopped and opened again [read].** Each step is skipped when it is done
  (`cities-skylines-2/scripts/install.sh:2-6`). Control-C, a closed window and a kill end it with "Stopped. Open
  the installer again: it carries on from here." (`common/install-core.sh:76`, `:88-93`), and Steam is not
  reached by any of them: it has its own process group (`:159-166`). The exit codes are 0 done, 1 a step
  failed, 2 a wrong option, 3 stopped at a question or because something else is running, 4 cannot go on by
  itself, 5 finished with a fix not out yet (`cities-skylines-2/scripts/install.sh:14-18`).
- **Every game needs Apple's Command Line Tools at its step 2 [read].** `core_tools`
  (`common/install-core.sh:326-345`) asks Apple for them with `xcode-select --install` and waits up to 60
  minutes (`:34`); its words say the download "can take 10 minutes or more". Cities: Skylines II needs their
  `python3` (`cities-skylines-2/scripts/install.sh:42`), Surviving Mars their `nm`
  (`surviving-mars-relaunched/scripts/install.sh:45`).
- **A second Steam [read].** Before it starts Steam for a game that is not yet downloaded, the core looks for
  a Steam for Windows of another prefix and stops with exit 3: "Steam is open in <wrapper>. Quit it, then open
  the installer again." (`common/install-core.sh:427-435`). Its own comment says what it does not see: "This
  sees a Steam for Windows of another prefix on this Mac, and nothing else." The look comes at the game's
  step, after Wine and Steam for Windows are already in place.
- **A full disk [read].** `core_space` prints a caution when less than the game's `NEED_GB` is free and goes
  on (`common/install-core.sh:346-357`). `common/make-wrapper.sh:84-86` refuses to make a wrapper with under
  6 GB free. Nothing else in the installers looks at free space. **[not known]**: what Steam under Wine does
  when the disk fills during the game's download, and so whether the installer's wait (`:476-501`), which ends
  only when the game is installed or Steam is gone, would then wait for ever.
- **A wrapper is marked when it is made [read].** `core_wine` runs `common/make-wrapper.sh` with `--mark game
  <ID>` (`common/install-core.sh:363`); the marker is written before the finished wrapper is moved into place
  (`common/make-wrapper.sh:11-12`), and a wrapper whose making stopped leaves nothing (`:16-17`).

### 1.3 14unch3r, its builder, and what it shows

- **It is compiled on the player's Mac [read].** `common/make-launcher-app.sh:62` needs `xcrun -f swiftc` and
  otherwise skips with exit 3 ("install the Xcode Command Line Tools"); `:71` compiles
  `common/launcher-window.swift` (1,984 lines) with `swiftc -O`; `:76-77` copies `common/games.tsv` into the
  bundle; `:132-137` writes `L1UpdateDir` into its `Info.plist` only when `_update/updates.sh` is already
  there; `:140-151` swaps the finished app in. Its `LSMinimumSystemVersion` is 13.0 (`:115`).
- **Only a game's setup builds it [read].** Cities: Skylines II's setup builds it after, and only if, the
  game's own app was built (`cities-skylines-2/scripts/setup.sh:526-543`); Surviving Mars's setup builds it at
  `surviving-mars-relaunched/scripts/setup.sh:249-250`. Cities: Skylines II's setup stops unless a wrapper
  with Steam and the game in it is there (`cities-skylines-2/scripts/setup.sh:278-293`, `:303-305`); what
  Surviving Mars's setup does with no wrapper was not read for this draft. Neither setup is offered to a
  player as a way to get the window alone, so today there is no way to have the window before a game.
- **A row is a set-up game [read].** The window lists the apps in `~/Applications` whose `Info.plist` carries
  `L1Role` `game` or `steam`, a game also `L1SteamAppID` (`common/launcher-window.swift:131-151`). Its state
  comes from files alone (`:168-173`): `busy` when the prefix's `.launcher.lock` names a live process, else
  `ready` or `absent` by Steam's manifest for the game.
- **A game that is not set up shows only when Steam's cache says the account owns it [read].** `offerRows`
  (`:483-507`) reads `packageinfo.vdf` of the prefixes of the rows that are there, and returns nothing when
  there is no such file (`:491`). `docs/plans/launcher-window.md`, 2.5, says so in words: "A Mac with no game
  set up has no prefix to read and so shows no offer." With no tile at all the window shows "No games are set
  up on this Mac yet." and the README's address (`:799-800`, `:1743`).
- **A click on an offer opens the guide in the browser [read].** `startChosen` (`:1769`) hands an offer to
  `launch`, which runs `/usr/bin/open <address>` and leaves the window open (`:1799`). The address must start
  `https://github.com/` (`:495`). The words: "Not set up on this Mac. Opens the set-up guide." (`:177`).
- **The table it reads is the copy in its own bundle [read].** `:1611`. So a game added to the repository
  shows only after some setup has run again and rebuilt the window (`docs/plans/built-in-update.md`, 1.3).
- **It already finds a marked wrapper [read].** `markedWrapper` (`:216`) looks in a folder for the one app
  marked `game-wrapper` with a given `L1SteamAppID`; `rows(in:)` uses it after a hand rename (`:238-240`).
- **A built app opens with no question [record].** `docs/plans/launcher-window.md:158-159`: `swiftc -O`
  compiled a 257-line skeleton in 1.3 s on the Studio, "and the bundle it sits in starts through `open` with no
  signing step". **[not known]**: how long the whole file takes to compile, on any Mac; and whether it
  compiles with the Command Line Tools alone, with no Xcode (LP1). Its tests have run on macOS 27 only.

### 1.4 The built-in update

- **What the daily check fetches [read].** One file: `CHANGELOG.md` of `release`
  (`common/updates.sh:50`, `:225`), at most once a day (`:216-219`), bounded at 1 MiB. Its first version
  heading becomes `offer`, and the file `notes.md`. It never fetches the table of games.
- **Who is never asked [read].** In the states `off`, `none` and `manual` nothing is fetched (`:214`). `none`
  is "no stamp": no file in `_update/installed/` that counts (`:196`). A stamp's name must be an app ID,
  `^[1-9][0-9]{0,9}$` (`:48`, `:150-161`), and only a game's setup writes one (`l1u_stamp`, `:132-146`).
  **So a Mac that had the launcher and no game would be in the state `none` and would never learn of a new
  release [inferred].**
- **How the window opens Terminal for an update [read].** The window runs the deployed tool with `--open`
  (`common/launcher-window.swift:765`). `l1u_open` (`common/updates.sh:307-349`) writes `Update
  1launcher.command`, mode 755, into a new temporary folder, holding constants only but for curl's path, and
  runs `open -a Terminal <file>`. The file fetches the root `install.sh` of `release` into a file and runs it
  with the one word `update` (`:322-325`), says one closing line by the exit code (`:327-331`), and removes
  itself. The window quits when the tool answers `opened` (`common/launcher-window.swift:1930-1943`). Before
  the sheet it looks for a game in use and then shows "Quit <title> first." (`:1854`).
- **Measured at UL1 [record]** (`docs/plans/built-in-update.md`, "UL1 on the Studio"): between the click and
  Terminal's first line macOS showed no dialog that held it up, and the lines were printed within eleven
  seconds. One run, on the Studio, with nobody at the screen.
- **The driver passes over a Mac with no game [read].** `common/update-games.sh:149-150` says "No game is set
  up on this Mac." and exits 3 (`:157`). It runs each set-up game's installer with no option (`:122`), and
  each of those setups rebuilds the window.
- **The tool's options and output lines are a contract between versions on one Mac [read].**
  `common/updates.sh:24-26`: "a later version may add an option or a field at the end of a line, and never
  changes or removes one." The window takes only the six state words it knows
  (`common/launcher-window.swift:671-680`).

### 1.5 What macOS does with an installer that is downloaded

- **An installer app was stranded by Gatekeeper [record].** `docs/plans/simple-install.md`, its header's
  record of NL2 (2026-11-12), and `docs/plans/shared-installer.md`, section 9, SF6: an unsigned app downloaded
  by Safari was refused, approved with Open Anyway, and then held by macOS at a Touch ID box whose fallback
  button was pressed; every later open ended in Finder's "not responding" until the process was ended from
  Terminal. One run; the cause is inferred there. James decided on 2026-11-16 (that plan's ND1): only the
  pasted line is published. No installer app has been released (`CLAUDE.md`).
- **Read for that plan, not measured [record]** (`docs/plans/simple-install.md`, 1.5): a file fetched with
  `curl` carries no quarantine attribute, and Gatekeeper acts on quarantined items; an app built on the Mac
  itself opens with no question; a Developer ID with notarization costs 99 USD a year and puts the holder's
  legal name in the signature (declined, K3); macOS 26.4 and later can refuse a pasted Terminal command with
  "Possible malware, paste blocked", which the user can override. That plan's NL4, which measures the pasted
  line on such a Mac, has not been run.

### 1.6 Conferring with the sibling repositories

Not done for this draft: the Mac was running benchmarks and a search over the siblings' `docs/` was left out.
It is one command before the check (`grep -rIlE 'install the launcher|launcher first' ~/github/*/docs`), and
its result, a precedent adopted or a decline with its reason, is written here.

## 2. Target

1. One pasted line that names no game installs 14unch3r on a Mac that has nothing of this project.
2. Its window lists every game this project ports: the ones set up, the ones not set up, and one whose
   install was begun and not finished.
3. A click on a game that is not set up, and a yes, runs that game's installer. Nothing is installed without
   that yes.
4. Every published line keeps working unchanged: each game's line with its ID, and `install.sh update`.
5. A game added in a later release reaches an installed launcher by the built-in update, and is then a tile
   like the others.
6. A new game is written against a contract that a test holds.

## 3. Design

### 3.1 Where a game's install runs: Terminal (LFD1)

The window opens Terminal for a game's install, the way it opens Terminal for an update. What each way costs:

| | Terminal, as the update does | An install view inside the window |
|---|---|---|
| The installer's questions (1.2) | Work as they are: the installer reads the Terminal | Each needs a way in: a pseudo-terminal behind a text view, or a protocol by which the installer names a question and the window shows a sheet. Every game's installer and both setups would speak it, and the contract of 3.6 would carry it |
| A run of hours | Terminal owns the process. The window quits after the click, as after an update | The window must stay alive for the whole download, or the installer must outlive it and be found again. Today the window quits after every start (`common/launcher-window.swift:1804`) |
| The setup at the end rebuilds 14unch3r | Nothing of 14unch3r need be running | The app would replace its own bundle while it shows the install (`common/make-launcher-app.sh:140-151` moves the old app aside and removes it) |
| Stop and carry on | Built and measured: Control-C, a closed window, opening again (1.2) | To be built: a Stop button, a closed window, a quit, a crash of the window |
| What the player sees | A second app with a text window, the same one the pasted line used | One app, a progress bar, sentences in the project's own look |
| What is new to build and to test | One option of the deployed tool, one sheet | A terminal view or a protocol, a process owner, a progress model, and tests for each. The window's sheets live in the app delegate, which no text mode builds today (`docs/plans/built-in-update.md`, 1.3) |

So: Terminal in this plan. It is what UD2 chose for the update, for the same reasons, and it adds no second
way for an installer to talk. An install view is a plan of its own (section 14), and what it would need from
the installers, questions that have names, is worth knowing before a third game's installer is written
(LFD1 asks).

**Decided 2026-11-26 (LFD1): Terminal in this plan, and the install view is on the roadmap** (the root
`README.md`, "Roadmap"; section 11, slice 3).

### 3.2 What must happen before a window can appear: build it there (LFD2)

On a Mac with nothing, in order **[inferred from 1.2, 1.3]**: Terminal and the paste; the fetch of the
repository; Apple's Command Line Tools, if absent (Apple's own box, Install, Agree, a download of ten minutes
or more by the installer's own words); the compile; the app. Not needed for the window: Rosetta, Wine, Steam,
any licence question of a game.

| | Build it on the Mac (today's way) | Ship a built app |
|---|---|---|
| Before the first window | The Command Line Tools, then a compile whose length is not known (LP1) | A download of the app |
| Is that wait extra? | No: every game's step 2 asks for the same tools (1.2), so a player who goes on to any game pays it once either way. It moves to the front | It would save the wait only for a player who installs the launcher and no game |
| Gatekeeper | An app built on the Mac opens with no question (1.3, 1.5) | Fetched by curl inside the pasted line: **[inferred, not measured]** no quarantine, so no question, if the build is signed ad hoc. Downloaded by a browser: refused, Open Anyway, and SF6's stranding (1.5) |
| Signing | None | For a browser download to open cleanly: a Developer ID and notarization, 99 USD a year, a legal name in the signature (declined, K3) |
| What a player can read | The source that is compiled | A binary. The project would have to build it, test it on each macOS it claims, and publish it at an address that can then never move |
| A new published thing | None | The binary's address and its tag, for ever |
| An update of the window | The update compiles the new source, as now | A second download path beside the tree, or both ways kept |

So: build it there. The cost is honest and is said in the guide: the first window comes after Apple's tools.
LP1 measures the compile. Shipping a built app stays possible later without changing this plan's design, and is
not in it (section 14).

**Decided 2026-11-26 (LFD2): compiled on the player's Mac until the project is a registered Apple developer.** A
built app is taken up when a Developer ID exists to sign and notarize it with; until then nothing of this plan
ships a binary.

**Decided 2026-11-26 (LFD14): the wait for Apple's Command Line Tools is asked for first, and overlapped.** Asked
by James on 2026-11-25, the day the first player from outside the project was about to run an installer: this is
the longest step that is not a game's download.

- **What needs the tools today [read].** Cities: Skylines II names `python3`, for its patches
  (`cities-skylines-2/scripts/install.sh:42`); Surviving Mars names `nm`, for its engine swap
  (`surviving-mars-relaunched/scripts/install.sh:45`); and every app this project builds is compiled with
  `swiftc`. So a built app alone would not remove the tools from either game's install.
- **The rule.** An installer asks Apple for the tools as its first act after its refusals
  (`xcode-select --install`, when `xcode-select -p` finds none), says in one line that Apple's box is up and what to
  press, and goes on. It waits for them only at the first stage that runs one of them, with the wait and the words
  the core has today (`common/install-core.sh:326-345`). With the tools there, nothing is asked and nothing waits.
- **In the launcher's installer** (3.4) the stages before the build need no tool, so the ask comes first and the
  wait comes before the build.
- **In a game's installer** the gain is larger and is a change to the shared core: the wait can fall inside the
  wrapper's, Steam's and the game's downloads. **[inferred, not read]** Which of the core's stages run a tool of
  Apple's before the game's setup has not been read; the check's builder lens reads it, and the stage list it
  finds is written here before step LF8 is built. If a stage before the downloads needs a tool, the wait stays
  where that stage is and the gain is smaller.
- **Not chosen:** asking through `softwareupdate` without Apple's box (it needs an administrator's password, which
  the installer has never asked for; not verified on macOS 26 or 27), and needing fewer of the tools (a Python that
  is not Apple's, `nm` replaced, built apps: each a dependency or a published thing the project does not have).

### 3.3 The no-game form of the root `install.sh` (LFD3)

A new first word, `launcher`, beside `update`:

    /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)" 1launcher-install launcher

- It is tested for where `update` is, before the test of the first word (`install.sh:78`), and is an early
  branch of its own, so that the lines for a game and for `update`, on which the older mutants of
  `common/test-bootstrap.sh` are anchored, keep their text.
- It takes a ref and nothing else, as `update` does: `install.sh launcher [<ref>]`. An option after it is a
  usage error, exit 2, nothing fetched.
- Fetched, it needs `common/install-launcher.sh` in what it fetched (else: "This version of 1launcher has no
  installer for the launcher. Paste a game's installer line from the guide instead.", exit 1), exports
  `L1_FETCHED_REF` and `L1_FETCHED_COMMIT`, and runs that script with no argument, returning its exit code.
- From a checkout it fetches nothing and runs the checkout's `common/install-launcher.sh` ("Using this
  checkout of 1launcher (nothing is fetched)."), unlike `update`: a maintainer builds the window this way.
- **What changes for the lines that exist: nothing.** A first word of digits takes the same path as today,
  line for line. `update` takes the same path. With no word the script still fetches nothing and exits 2; its
  words gain one line, after the usage line: "To install the launcher, which lists the games: the word
  launcher." Every other word is still "not a Steam app ID".
- **The alternative, the bare line.** The pasted line with nothing after the closing quote could install the
  launcher. It is the shortest line there can be. It is not recommended: today that line is an error that
  fetches nothing, and a test and a mutant hold it (1.1); a paste cut short before a game's ID would install
  something instead of saying so; the repository's own rule, which `docs/plans/shared-installer.md` 1.2 cites
  for "there is no default game", is that "nobody said which" must not mean "that one"; and once published,
  the meaning of the bare line could never be taken back, while a word leaves it free.
- Once `release` holds it, `launcher` is a published word that can never be withdrawn (section 9).

### 3.4 The launcher's installer: `common/install-launcher.sh` (new)

Run only by the root `install.sh` (the word `launcher`) and by the update's driver (3.5), from the tree it
lies in. Like a game's installer it is steps that are skipped when done, so that running it again is the
update. It takes no option.

1. **Refusals.** As root: the core's sentence (`common/install-core.sh:95`). Its own files (`paths.sh`,
   `updates.sh`, `make-launcher-app.sh`, `launcher-window.swift`, `games.tsv`) missing: "The installer's own
   files are gone (macOS clears old temporary files).", exit 4.
2. **This Mac.** macOS below 13: "14unch3r needs macOS 13 or later.", exit 3 (the builder's own minimum,
   1.3). An Intel processor or a macOS outside what is tested gets one line of caution and no stop: each
   game's own check decides for that game (Cities: Skylines II cautions on Intel, Surviving Mars stops:
   `cities-skylines-2/scripts/setup.sh:248-254`, `surviving-mars-relaunched/scripts/setup.sh:60-63`). LFD12.
3. **Apple's Command Line Tools.** Asked for at once, right after step 1's refusals, and waited for here, before
   the build (LFD14, 3.2): steps 2 and 4 run while Apple's download does. The core's stage (`core_tools`), with
   `swiftc` as the part that must run (`xcrun -f swiftc`). The core cannot be read here as it is: it stops unless a game's settings are set
   (`common/install-core.sh:20-26`). So this script holds a copy of that stage's wait and words, and a test
   holds the two equal, the way `cities-skylines-2/scripts/test-install.sh` holds the core's copies of the
   launcher's functions equal to the launcher (`common/install-core.sh:97-99`). Whether a shared file is
   better than a held copy is for the check's builder lens: the older mutants of both games'
   `test-install.sh` are anchored on the core's lines.
4. **The record's folder.** `_update` and `_update/installed`, made with `mkdir` and `chmod go-w` if absent,
   and tested to be the player's own, as both setups do (`cities-skylines-2/scripts/setup.sh:347-376`); then
   `common/updates.sh` is copied to `_update/updates.sh`, written beside and renamed. Before the build, so
   that the first window already has `L1UpdateDir` (`common/make-launcher-app.sh:132-137`).
5. **The build.** `bash common/make-launcher-app.sh`. Its exit 3 (skipped: the compile failed) is a failure
   here, exit 1, with its line shown: for a game's setup the window is an extra, here it is the whole point.
6. **The stamp.** The launcher's own stamp (3.5), written only after a build that worked.
7. **The close.** "Done. 14unch3r is in Applications: open it and choose a game." and, unless `L1_UPDATE=1`,
   `open ~/Applications/14unch3r.app` (LFD6). On a signal: the core's "Stopped." line with "Paste the line
   again: it carries on from here."

Exit codes as a game's installer: 0 done, 1 failed, 3 will not go on, 4 cannot go on by itself.

### 3.5 The record, the update, and how a new game arrives (LFD5)

**The launcher gets a stamp of its own.** A new file `_update/launcher`, one line in the form of a game's
stamp: the line it follows, the version, the commit, the time (`docs/plans/built-in-update.md`, 3.1), read
and matched by the same rule. It is not in `installed/`, whose names are app IDs. `common/updates.sh` gains:

- `l1u_stamp_launcher <tree root>`, which writes it;
- in `_l1u_stamps`, the launcher's stamp as one more row, so that the state's rules count it: a Mac with the
  launcher and no game is `unknown`, then `current` or `ready`, and is asked once a day like any other; a
  launcher built from a checkout makes the Mac `manual`; the lowest version among the launcher and the games
  is "installed".

Nothing that exists changes its form: no state word is added, no line changes (1.4's contract). An older
`updates.sh`, put back by a setup from an older tag, does not see the file and calls a launcher-only Mac
`none`: nothing is offered there until the next setup. Accepted, and said.

**Who writes it.** `common/install-launcher.sh` (3.4, step 6), and each game's setup on the line after a
build of the window that worked into `~/Applications` (not with `--dest`, `SM_APP`, `--check` or
`--mac-only`): the window that setup just built is that tree's. Without this, a game installed from an older
launcher would leave the launcher's stamp behind and the window would offer an update a minute after an
install.

**The update's driver** (`common/update-games.sh`) gains one step after its walk of the games:

- the launcher is set up here when `~/Applications/14unch3r.app` is the builder's own app
  (`common/make-launcher-app.sh:46-53`'s test) or any game is set up;
- no launcher stamp: nothing is done for it and nothing is said (a Mac from `v0.3.1`, whose games' setups
  write the stamp at this update);
- a stamp, and no app and no game set up: the stamp is removed, as a game's is
  (`common/update-games.sh:98-103`): an update does not bring back what the player removed;
- a stamp on another line than the one fetched: "14unch3r: set up from `<line>`, so it is left as it is.",
  counted as left;
- a stamp already at the fetched version (a game's setup wrote it in this run): nothing more;
- else `bash <tree>/common/install-launcher.sh`, counted like a game's installer.

"No game is set up on this Mac." is then said only when neither a game nor the launcher was there. The
window's sentence for the update (`Look.updateText`, `common/launcher-window.swift:815`) becomes true of a
launcher-only Mac: "Update opens Terminal and runs the installer again for 14unch3r and each game set up
here. It may ask you a question there."

**So a new game arrives like this.** It is released: a folder, a row, a version heading that rises. Within a
day each installed launcher's check reads the heading (1.4) and shows its foot line; the sheet's notes are the
changelog, which names the game. Update rebuilds the window with the new table, and the game is a tile. This
is the chain the update already has (`docs/plans/built-in-update.md`, 3.9); what this plan adds is that it
also runs on a Mac with the launcher alone, and that the tile installs.

**The alternative**, fetching the table of games in the daily check so that a new game shows before any
update: not recommended. It would be a second file read from the network into the window, with titles and
addresses that are then shown and opened; the window an old launcher would show the tile in could be too old
for what the new game needs of it; and an installed Mac would learn of a release by two routes that can
disagree. The update is one route, and the player reads what changed before saying yes.

### 3.6 The contract a game meets

Most of it exists and is only written down here; the last three rows are new. A new test,
`common/test-game-contract.sh` (LFT7), holds what can be held without running anything of Wine.

| # | A game provides | Where it is read today |
|---|---|---|
| 1 | A row in `common/games.tsv`: exactly four tab-separated fields; a Steam app ID of digits that never changes; a folder matching `^[a-z0-9][a-z0-9-]*$`; a title (a label); a guide's address starting `https://github.com/` | `install.sh:30-32`; `common/update-games.sh:135`; `common/launcher-window.swift:467`, `:495` |
| 2 | A row in `common/wrappers.sh`: `l1w_row` (the wrapper variable, the old names, the game's program under the prefix) and its ID in `l1w_games` | `common/wrappers.sh:26-46`; `common/update-games.sh:82-91` |
| 3 | `<folder>/scripts/install.sh`: sets the core's settings and functions, reads `common/install-core.sh`, calls the stages in order; makes its wrapper with the game's marker; every step skipped when done, so that a run with no option is both the install and the update | `common/install-core.sh:8-26`, `:363` |
| 4 | Its options: `--check` (starts, downloads and changes nothing), `--yes`, `--no-setup`. Its exit codes: 0, 1, 2, 3, 4, and 5 only if its setup can finish without every fix | `cities-skylines-2/scripts/install.sh:8-18` |
| 5 | `<folder>/scripts/setup.sh`: `--mac-only`, `--check`, `--yes`; builds the game's app in `~/Applications` with `L1Role` `game`, `L1SteamAppID` and `L1Prefix`; builds 14unch3r; deploys `updates.sh` and `update-dir`; writes the game's stamp; asks nothing optional under `L1_UPDATE=1` | `docs/plans/built-in-update.md`, 3.3; `docs/plans/launcher-window.md`, 2.1 |
| 6 | Its launcher holds the shared blocks | `common/test-launcher-parity.sh` |
| 7 | **What it may ask the player.** Only in Terminal, only when its input is a terminal, each with "stop" as the answer when nobody answers (exit 3), each answered by `--yes`. Never a password, never `sudo` (the core refuses root). The kinds allowed: consent before something of a third party's is fetched under a licence; Rosetta; a Mac outside what was tested. Every question is listed in the installer's header. What the player does in other windows (Steam's sign-in, its Install button) is said in `words_play` and the core's words | new as a rule; true of both installers today (1.2) |
| 8 | **Its needs as plain words.** `WORDS_NEED` and `NEED_GB` are one-line literals with no `$` and no backtick, so that a later slice can show them before a yes (section 11, slice 2) | new as a rule; true today (`cities-skylines-2/scripts/install.sh:32`, `:36`; `surviving-mars-relaunched/scripts/install.sh:36`, `:40`) |
| 9 | **Nothing else is needed for the window to install it.** The window knows a game only by its row; the installer is found by the root `install.sh` from the ID. No list of games is written anywhere else | new as a rule |

Row 2 is a second table keyed by the ID, held in code. It stays as it is: joining it with `games.tsv` would
change the shape of a file that three programs read with "exactly four fields" (1.1), and a root `install.sh`
cached for five minutes at a move of `release` would read the new shape with the old rule.

### 3.7 What the window shows (LFD4)

Three kinds of tile, and where each state comes from:

| Shown as | When | Read from |
|---|---|---|
| A game, as today (`ready`, `absent`, `busy`) | An app with `L1Role` `game` and the ID is in `~/Applications` | The app's `Info.plist`, Steam's manifest and the prefix's lock (1.3). Unchanged |
| **Not set up**: "Not set up. Click to install." | The table has the game, no such app is there, and no wrapper in `~/Applications` carries the game's marker | The bundle's `games.tsv`; `markedWrapper` (1.3) |
| **Begun**: "Install not finished. Click to carry on." | No such app, and a wrapper carries the game's marker | The wrapper's `Info.plist`: `L1Role` `game-wrapper` and `L1SteamAppID` |
| **Installing**: "Installing in Terminal." | The lock of a running install names a live process (3.8), or a begun wrapper's `.launcher.lock` does | `_update/installing-<ID>`; the prefix's lock, by the rule the window has (`common/launcher-window.swift:157-165`) |

- **The wrappers' markers say how far an install got; the app says it is finished; `_update/installed/` says
  which version, and nothing about a tile.** A stamp is written only when a setup has finished, and then the
  app is there too. The one case where they differ, a stamp and a wrapper with the game in it but no app (the
  player deleted the app), shows as "begun", and a click runs the installer, which rebuilds the app.
- **Every game of the table is listed, whether or not Steam says the account owns it.** On a Mac with nothing
  there is no Steam to ask (1.3), so "only what you own" would show an empty window to exactly the player this
  plan is for. Where a cache does say the account owns the game, its second line says so: "You own this. Click
  to install." The group's label becomes "Not set up on this Mac" (today "You also own",
  `common/launcher-window.swift:801`). The installer's first lines already say that a Steam account that owns
  the game is needed (`common/install-core.sh:269`). A game that is set up is never hidden (D7, unchanged).
- **A game that is not on this Mac yet is drawn in grey scale and ghosted (LFD4, decided 2026-11-26).** The three
  new kinds of tile (not set up, begun, installing) are drawn by the rule the window has for a game it cannot
  start: `dim()` (`common/launcher-window.swift:976`), under which the icon is drawn through `greyed()` at
  `Look.dimAlpha`, 0.5 (`:794`, `:1077-1078`) **[read: those lines; the rest of the tile's drawing was not]**. A
  game that is set up is never drawn so. Where the icon of a game with no app comes from is for the design lens:
  the table has no picture, and today's offers were not read for it.
- **A wrapper under an old name with no marker** (a Mac not yet renamed, `docs/plans/wrapper-names.md`) is
  not seen by the window, which reads markers only: such a game shows as "not set up" where "begun" would be
  truer. The click is right either way: the installer finds the wrapper by `common/wrappers.sh`'s rule and
  carries on. Said, and left.
- **With no tile at all** (no table in the bundle) the window says what it says today.

**The click.** A tile that is not set up or begun opens a sheet; nothing runs before its answer.

- Message: "Install `<title>`?" (begun: "Carry on installing `<title>`?").
- Text: "Terminal opens and runs the game's installer. It says first what the game needs, asks before it
  fetches anything under a licence, and waits while you sign in to Steam and the game downloads. You can stop
  it at any point and carry on from here later."
- Buttons, the safe one first and the default, as every sheet of the window has it: "Not Now", "Install"
  ("Carry On"), and "Read the Guide", which opens the row's address as a click on an offer does today.
- With a game in use: the update's other sheet with its own words, "Quit `<title>` first." and "Installing a
  game needs Steam, and only one Steam at a time can use your account." One button.
- With an install running: "An install is running in Terminal." One button.
- On "Install" the window asks the tool to open the install (3.8) and quits when it answers `opened`, as after
  an update. Any other answer: its sentence, and the guide stays one click away.
- **With no tool** (no `L1UpdateDir`, or no `updates.sh` there) a tile that is not set up opens its guide, as
  an offer does today, and its words say so. Nothing is taken away from such a Mac.

The words above are published text. The design lens checks them, the tiles' contrast and the window's height
with three groups (`docs/plans/built-in-update.md`, UD10, measured a tile at 174 points and the limit at 600).

### 3.8 The tool opens the install: `updates.sh --install <Steam app ID>`

A new option of `common/updates.sh`, beside `--open`, and built like it (1.4):

- The ID is matched whole against `^[1-9][0-9]{0,9}$` before anything is written. Anything else: `failed` and a
  sentence, nothing written.
- It refuses, with `failed` and one sentence each: in the state `manual` ("The games on this Mac were set up
  from a checkout or a named version. Install this one the same way: its guide says how.", LFD8); while an
  update's lock or an install's lock names a live process; when the record's folder is not the player's own.
  The state `off` does not stop it: `off` switches off the daily check, and this is the player's own click.
- It writes `Install with 1launcher.command`, mode 755, into a new temporary folder: constants only, but for
  curl's path and the matched number. The file takes the lock `_update/installing-<ID>` (a link whose target is
  its process number, the launchers' lock form; a dead holder is taken over), clears the screen, fetches the
  root `install.sh` of `release` into a file beside itself, judged by the code as `--open`'s file does, and
  runs `/bin/bash -c "$S" 1launcher-install <ID>`: the published line for that game, word for word. So an
  install from the window and an install from the guide are one path from there on.
- Its closing line, by the installer's exit code: 0, "Installed. Open 14unch3r to play. You can close this
  window."; 5, the same with "A Mac fix is not out yet for this build of the game: the lines above say more.";
  3 or 4, or a signal, "Not finished. To carry on, open 14unch3r and click the game again. You can close this
  window."; else "The install did not finish: the lines above say why. To try again, open 14unch3r and click
  the game." It releases the lock and removes itself and its folder.
- It hands the file to Terminal with `open -a Terminal` and prints `opened`, or `failed` and one sentence.

**One install at a time.** Any live `installing-*` lock refuses a second install from the window, whatever the
game: each install starts a Steam, and one Steam at a time can use an account (`cities-skylines-2/CLAUDE.md`).
An install started by a pasted line takes no such lock. The installers' own guards then apply: the wrapper's
lock (`common/install-core.sh:383-388`) and the wrapper maker's refusals (`common/make-wrapper.sh:14-17`).

**An older tool.** A window built by this version, beside an `updates.sh` put back by a setup from an older
tag, gets a usage error for `--install`, which `runChild` reads as no answer. The window then says "This
Mac's update tool is older than this window. Paste the game's installer line from its guide." and offers the
guide.

### 3.9 Failure and resume

| What happens | What the player meets | Where from |
|---|---|---|
| The paste of the launcher line is cut, or the fetch fails | "GitHub could not be reached ..." or nothing run: the script is all functions and calls the last on its last line | `install.sh:28-29`, `:121-128` **[read]** |
| Apple's tools are not installed within 60 minutes | Exit 4, "Paste the line again: it carries on from here." | 3.4, the core's rule (`common/install-core.sh:339`) |
| The compile fails | Exit 1 with the compiler's first error. No app, no stamp; an older 14unch3r stays as it was (`common/make-launcher-app.sh:16-19`) | 3.4 |
| A game's install is stopped: Control-C, the Terminal window closed, the Mac restarted | "Stopped." in Terminal; Steam is left as it is; at the next open the window shows the game as begun, or as not set up if no wrapper was made yet, and a click carries on | 1.2, 3.7, 3.8 |
| The installer stops at a question (exit 3) or cannot go on (exit 4) | Its own lines say why; the closing line says to click the game again | 3.8 |
| A game is running in another wrapper | The window's sheet says to quit it, before Terminal opens | 3.7 |
| A Steam for Windows is open in another wrapper and no game runs (the Steam app, S734M) | The window cannot see it: "A Steam app is never busy: nothing locks the store wrapper" (`common/launcher-window.swift:167`). The installer stops at the game's step, exit 3, and says which wrapper (1.2). Clicking again after quitting it carries on from there | 1.2 **[read]** |
| The macOS Steam app is open | **[not known]** to this draft: the installer does not look for it (1.2), and what then happens to the session was not read. LP3 | 1.2 |
| Less free space than the game needs | The installer's caution, and it goes on (1.2). Under 6 GB: the wrapper is not made, exit 1 | 1.2 **[read]** |
| The disk fills during the game's download | **[not known]** (1.2). LP2 | |
| A second click while an install runs | "An install is running in Terminal." | 3.7, 3.8 |
| The temporary copy of the repository is cleared by macOS during a long run | The installers' own sentence and exit 4; a click fetches again | `cities-skylines-2/scripts/install.sh:109-115` **[read]** |
| The window is opened again while an install runs, and the setup at its end rebuilds 14unch3r under it | **[not known]**: the bundle of a running window is moved aside and removed. The same can happen today with a pasted line. Read off the screen at LFL2 | 1.3 |

## 4. Steps

Each step is one or more commits on a branch `launcher-first-install`, with its tests in the same commit and
every mutant of section 6 applied and seen red before the step is called done.

- **LF0. The probes** (section 7), before any code: LP1 decides whether 3.2 holds as written.
- **LF1. The record.** `common/updates.sh`: the launcher's stamp and its place in the state; both setups
  write it after a build of the window that worked. `CLAUDE.md`'s line for `_update` names the new files
  first (LFD9), before anything writes them. Tests LFT3 (its first half), LFT5.
- **LF2. The launcher's installer and the word.** `common/install-launcher.sh`, which asks for Apple's tools
  first (LFD14); the root `install.sh`'s word `launcher` and the one new line for no word. Tests LFT1, LFT2,
  LFT11 (its launcher half).
- **LF3. The update.** `common/update-games.sh`'s step for the launcher; `Look.updateText`. Test LFT4.
- **LF4. The tool's `--install`** and the lock. Tests LFT3 (its second half), LFT8.
- **LF5. The window.** The three kinds of tile, drawn in grey scale and ghosted (LFD4), the group's label, the
  sheet, the text modes for each, the fallback with no tool. Tests LFT6, LFT10.
- **LF6. The contract and the words.** `common/test-game-contract.sh` (LFT7); `CLAUDE.md` (the layout
  table's rows for `install.sh` and `common/`, § Published addresses); the statements of section 10; the root
  `README.md` and both `INSTALL.md` files, each keeping its game's own line as the second way;
  `CHANGELOG.md` under Unreleased; this plan's as-built header.
- **LF8. The tools asked first in the shared core (LFD14).** Only after the stage list of 3.2 is written from a
  read of the core: `common/install-core.sh` asks at its start and waits at the first stage that runs a tool.
  Both games' installers change with it. Test LFT11 (its games half). It may be released after LF7: slice 1
  does not depend on it.
- **LF7. Live steps, merge, release** (section 7). The guides lead with the launcher's line only from the
  release whose `release` holds the word (LFD10): until then that line answers "not a Steam app ID: launcher".

## 5. Who notices what

| Who | What they notice |
|---|---|
| A new player | One line to paste. Apple's box for its tools, a wait, then a window with the games. A click, a yes, and Terminal runs the game's installer as the guide's line would |
| A player set up before this version | Nothing until they update. Then: a game that is not set up shows as a tile whether or not Steam says they own it; a click on it asks, and installs. Their pasted lines work as before |
| A player with the launcher and no game | By itself at most one request a day to GitHub, as for any installed Mac (`docs/plans/built-in-update.md`, 3.8), and the foot line when a version is out |
| A player whose install stopped | The game's tile says the install is not finished; a click carries on |
| A Mac where a game was set up from a checkout or a named version (the maintainer's two Macs, at times) | The state is `manual`: a tile's click says why it does not install from `release` and offers the guide (LFD8) |
| James, at a release | A new game's release notes are what tells every installed player that the game exists. `launcher` is one more word that can never be withdrawn |

## 6. Tests

Every test runs with `HOME`, `TMPDIR` and `L1_UPDATE_DIR` at scratch folders, starts nothing of Wine, compiles
only where the existing window tests already do, and touches no network: `L1_CURL` and `L1_OPEN` name stubs
(for `install.sh`, a stub `curl` first on `PATH`, as today). A mutant is applied to the source and must be
seen red (exit 1, not REFUSED). New mutants take the numbers after each file's last; by a count of the word in
each file at `91cfb63` those are 19 in `common/test-bootstrap.sh`, 86 in `common/test-launcher-window.sh`, 10
in `common/test-make-launcher-app.sh`, 23 in `common/test-updates.sh`, 19 in `common/test-update-games.sh`: the
check confirms each count against the file's header.

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| LFT1 | `common/test-bootstrap.sh` | `install.sh launcher`, fetched: the fixture's `common/install-launcher.sh` is run with `L1_FETCHED_REF` and `L1_FETCHED_COMMIT` and no argument, and its exit code is returned; `launcher x --yes` and `launcher --check`: usage, exit 2, nothing fetched; a fixture without the script: the sentence, exit 1; from a checkout: the checkout's script is run and curl is not called; `Launcher`, `launchers` and `14unch3r` are still "not a Steam app ID"; **with no word: exit 2, curl not called, "Say which game", the usage line and the new line, and no script run**; every existing case for an app ID and for `update` passes with no expected line changed | the word accepted in any case; no word made to install the launcher; arguments passed on to the script; the script's exit code dropped; the checkout case made to fetch; the ID path reading the new branch's variable |
| LFT2 | `common/test-install-launcher.sh` (new): stubs for `xcode-select`, `xcrun`, `sw_vers`, `open` and `caffeinate`; a stand-in for the window's builder that records its call and what existed then | With the tools: `_update` and `installed/` made and not writable by others; `_update/updates.sh` byte for byte the tree's and there before the builder was called; the builder called once with no option; `_update/launcher` holds `checkout`, the tree's version, `-` and `L1_UPDATE_NOW`, and with `L1_FETCHED_REF=release` that line and the commit; `open` called once with the app's path, and not at all with `L1_UPDATE=1`; the closing line. Without the tools: `xcode-select --install` called once, the wait, and exit 4 with its sentence when they never come. The builder's exit 3 and exit 1: exit 1, no stamp written, an older stamp left byte for byte, `open` not called. macOS 12: exit 3. As root: refused. A `_update` others can write: exit 1, nothing written. An own file missing: exit 4. A signal: the "Stopped." line. Any option: exit 2. The tools stage's words and wait equal the core's (the held copy) | the stamp written before the build; the stamp written when the build was skipped; `updates.sh` deployed after the builder; the wait for the tools dropped; `open` called after a failure; the own-folder test dropped; one byte changed in the held copy |
| LFT3 | `common/test-updates.sh` | **The stamp.** Only `_update/launcher` on `release` with no `offer`: `unknown`, and a refresh calls curl; with a newer `offer`: `ready`; on `checkout`: `manual`; beside game stamps at a higher version: "installed" is the launcher's; a launcher file that is a link, has two lines, five fields or a version `a[$(touch <file>)]`: passed over, the state is `none` and `<file>` does not exist; every existing case passes unchanged. **`--install`.** With a stub curl and a stub open: the written file is mode 755, begins with `clear`, and run, records `$0` as `1launcher-install` and `$1` as the ID, one word and nothing after it; it holds the lock while the installer runs and no lock after; it says the closing line for exit 0, 3, 4, 5 and 1 and exits with that code; `L1_OPEN` got `-a Terminal` and its path. Refused, with `failed`, nothing written and `L1_OPEN` not called: an ID of `0`, `12x`, eleven digits, `a[$(touch <file>)]`; the state `manual`; a live `installing-*` lock of another game; a live `updating` lock; a `_update` others can write. A dead lock is taken over. In the state `off` it opens | the ID written unmatched; the lock not taken; the lock not released; the refusal in `manual` dropped; `release` made `main` in the file's address; the launcher's stamp left out of the state; the launcher's stamp read without its match; a second word passed to the installer |
| LFT4 | `common/test-update-games.sh` | A Mac with the launcher's stamp on `release` at `v0.0.9`, its app, and no game: the fixture's `common/install-launcher.sh` is run with no argument, the closing line is "Everything is up to date", exit 0. With a game whose stand-in setup wrote the launcher's stamp at the tree's version: the launcher's script is not run. The stamp on `checkout`: left, its sentence, exit 3. A stamp, no app, no game: the stamp removed, "No game is set up on this Mac.", exit 3. The launcher's script failing: exit 1, and the games before it were still run. No launcher stamp (a Mac from `v0.3.1`): every existing case passes unchanged | the launcher's script run every time; a launcher on another line run anyway; "No game is set up" said after the launcher was updated; its failure not counted; the stamp kept when the app is gone |
| LFT5 | both games' `scripts/test-setup.sh` | After a setup whose stand-in builder exits 0: `_update/launcher` holds the line and the tree's version. The builder exiting 3: no launcher stamp, an older one left as it was, the game's own stamp still written. With `--dest` (Cities: Skylines II) and `SM_APP` (Surviving Mars), `--check` and `--mac-only`: nothing written | the stamp written when the builder skipped; the stamp written for another destination |
| LFT6 | `common/test-launcher-window.sh`, through text modes; `common/test-make-launcher-app.sh` | `--list --games` with no app at all: one row per game of the table, role `offer`, the new state for "not set up" (today: no row); with a wrapper marked for the game and no app: the state for "begun"; with a live `installing-<ID>` in `--update-dir`: the state for "installing"; a game that is set up has no such row; a row whose address is not on github.com is dropped, as today; a cache that says owned changes the second line and nothing else. `--grid`: the group's label, the three second lines, a contrast line of 4.5 or more for each, the height with three groups. `--act start` on such a tile prints the install sheet's name and never `start`, and the tool was not called. A new mode for the sheet: message, text, the buttons in the order "Not Now", "Install", "Read the Guide"; for a begun game the other words; with a busy row the one-button sheet naming it; with a live install the other one-button sheet. A new mode for the answer: only the second button gives `open`; the third gives `guide`; the first and Escape give `nothing`. A new mode for the opening: a stub tool saying `opened` gives `quit`; `failed` and a sentence gives the sentence; a tool that exits 2 gives the older-tool sentence. With no tool: `--act start` on the tile prints the guide's start, exactly as an offer today | "Install" made the first button; the first button made to give `open`; a set-up game listed as not set up; "begun" shown without a marker; the tool called before the sheet's answer; the ID passed to the tool unmatched; the limit removed from the call; the tiles hidden when ownership is not known; the fallback with no tool dropped |
| LFT7 | `common/test-game-contract.sh` (new), on a tree given as its argument | For every row of `common/games.tsv`: four fields and each one's form; the folder is there; `scripts/install.sh` and `scripts/setup.sh` are there and pass `bash -n`; the installer sets every setting of the core's list, with `GAME_APPID` the row's ID and `GAME_TITLE` the row's title; it reads `common/install-core.sh`; `WORDS_NEED` and `NEED_GB` are one-line literals; `l1w_row game <ID>` returns 0 and `l1w_games` prints the ID; the guide's address names a file of the tree; the installer's header lists the exit codes and every `read` in the installer and its setup stands under a test of the terminal. And the reverse: every ID of `l1w_games` has a row | on a scratch copy of the tree: an ID taken out of `l1w_games`; a `GAME_APPID` that is not the row's; a guide's address with no file; `WORDS_NEED` holding `$(date)`; a `read` with no terminal test; a fifth field in a row |
| LFT8 | each game's `scripts/test-install.sh`, in the case that keeps the real `setup.sh` | **The parts joined.** From a fixture with the launcher's stamp alone (`release`, the tree's version): `updates.sh --install <ID>` with stubs; the written file run; through the root `install.sh`, the installer and the real setup; then the game's stamp and the launcher's stamp hold the tree's version, the state is `current`, and no lock is left | the written file made to run `update`; the lock left behind |
| LFT9 | the gates | `common/check-links.py`, `common/check-identifiers.sh` at its residual, `bash -n` on every changed script, every other test file of the repository, and every older mutant of each test file touched still red and none REFUSED | none |
| LFT10 | `common/test-launcher-window.sh`, through `--grid` | **Ghosted (LFD4).** With one game set up and one not: the tile of the game that is not set up carries `dim` in `--grid`'s line and the set-up game's does not; the same for a begun wrapper and for a running install's lock | A new mutant: `dim()` no longer true for the new states: red. A second: `dim()` true for a set-up game: red |
| LFT11 | `common/test-install-launcher.sh`; both games' `scripts/test-install.sh` (the games half with LF8) | **The tools first (LFD14).** With no tools at the start: `xcode-select --install` is called before any download's stub is called and before the record's folder is made, the one line about Apple's box is printed, and the installer waits at the first stage that runs a tool and not before. With the tools there: no ask, no line, no wait | A new mutant each: the ask moved back to where the wait is: red. The wait dropped: red (a stage runs a stub tool that is not there yet) |

**Existing tests that change, by name** (each to be confirmed by the check's builder lens, which reads the
files): `common/test-launcher-window.sh` (the offer cases that expect no row without an owning cache, the
group's label, the header's list of modes); `common/test-bootstrap.sh` (the no-word case gains one expected
line); `common/test-update-games.sh` (the "No game is set up" case gains a launcher-less fixture by name);
both games' `scripts/test-setup.sh` (the "writes nothing" snapshots list `_update/launcher`);
`common/test-mac-inventory.sh` and `common/check-deploy.sh` (`_update` gains a file).

**Not tested, and said so:** what Terminal shows and whether macOS asks anything when 14unch3r opens the
install's file (LFL2); the sheet on screen, its focus, Return and Escape (LFL2); a compile with Apple's tools
alone and how long it takes (LP1); a Mac that really has nothing (LFL1); a real install from a click, from the
sign-in to the game's start (LFL2); a window left open while its bundle is rebuilt (LFL2); macOS's refusal of
a pasted command (`docs/plans/simple-install.md`, NL4, not yet run).

## 7. Probes and live steps (each on James's word)

**Probes, before the build.**

- **LP1. The compile with Apple's tools alone.** On the Studio, with `DEVELOPER_DIR` at the Command Line
  Tools' folder so that no Xcode is used, compile `common/launcher-window.swift` into a scratch folder with
  the builder's own line; record whether it compiles, the seconds, and the compiler's version. If it does not
  compile without Xcode, 3.2 does not hold and the plan is reworked before anything is built. Not run while
  this draft was written (benchmarks were running).
- **LP2. A full disk during Steam's download.** In a scratch wrapper on a small disk image: what Steam shows,
  what its manifest's fields read, and whether Steam stays up. Decides whether the installer's wait needs a
  rule, as a finding for the installers (it is true of a pasted line today) and not as part of this plan.
- **LP3. The macOS Steam app open during an install.** Read first: `cities-skylines-2/GOTCHAS.md`'s entry of
  the session with the macOS Steam running (commit `a9de979` names it; not read for this draft). Then, if it
  does not answer: one install step with it open.

**Live steps.**

- **LFL1. The launcher from nothing.** On a new macOS user account on the Studio, which James makes (the
  Command Line Tools are the system's, so the account is new to the project and not to Apple's tools): the
  branch's root `install.sh` fetched and run with `launcher launcher-first-install`. Pass, each read off the
  screen or a file: every line Terminal shows; every dialog of macOS; the seconds from the paste to the
  window; the window lists both games as not set up; `_update/launcher` names the branch; the state is
  `manual`; nothing is under `~/Library` of that account but what `CLAUDE.md` names. Capture the window's
  region only.
- **LFL2. A game from the window.** In that account, with every other Steam on the Mac quit: a click on
  Surviving Mars (the smaller download), the sheet read, Return and Escape tried first, then "Install". James
  signs in to Steam. Once during the download: the Terminal window closed, 14unch3r opened (the tile says the
  install is not finished), a click, and the install carries on. Once: 14unch3r left open while the setup at
  the end rebuilds it. Pass: the game starts from its app; the window lists it as set up and Cities: Skylines
  II as not set up; both stamps name the branch; no lock is left. Record every dialog of macOS between the
  click and Terminal's first line.
- **LFL3. The update on that account.** The launcher's stamp and the game's rewritten by hand to `v0.0.9` on
  the branch's line; `install.sh update launcher-first-install`. Pass: the game's installer runs, the window
  is rebuilt once, both stamps hold the branch's version. Then with the game's wrapper and app in the Trash
  and its stamp removed: the launcher alone is updated, "Everything is up to date".
- **LFL4. An install that exists** (the MacBook, or the Studio's own account): the rehearsed update from the
  branch. Pass: both games as before, the launcher's stamp written, no tile that was not there.
- **LFL5. The published line.** After `release` holds the word: the guide's launcher line pasted on a clean
  account; the window; one game installed from it. This is also where macOS's answer to a pasted command is
  read, if `docs/plans/simple-install.md`'s NL4 has not been run by then.
- **LFL6. The third game.** Its first install on a player's Mac is from the window. This is the contract's
  own test, and it belongs to that game's plan.

## 8. Exit criteria

1. Every test of section 6 passes, and every mutant listed was applied and seen red.
2. LP1 passed before LF1 was begun, and its numbers are in this file. LFL1 to LFL4 passed and are recorded
   here with what was measured.
3. The three kinds of line keep working, shown on the tagged commit: each game's line with its ID,
   `install.sh update`, and `install.sh launcher`; and with no word nothing is fetched.
4. `common/test-game-contract.sh` passes for both games, and `CLAUDE.md` names it as what a new game is
   written against.
5. `CLAUDE.md` names the new files of `_update`, the word `launcher` under § Published addresses, and
   `common/install-launcher.sh` in the layout table. The statements of section 10 are corrected in their
   files. The guides hold both ways in.
6. The design audit gate is done for the window's new tiles and sheet: the existing look's constants are
   used, the contrast lines are at 4.5 or more, and `docs/plans/launcher-window-look.md` is extended.
7. The as-built header is written at the build, with LFL5 and LFL6 named as still to come.
8. A game that is not set up, a begun install and a running install are each drawn in grey scale and ghosted,
   shown in a capture of the window in the dark and the light appearance (LFD4); LFT10 passes.
9. On a Mac without Apple's tools the launcher's installer asks for them before anything else it does, and
   LFL1 records the seconds from the paste to Apple's box and from the box's end to the window (LFD14). If LF8
   is built: the same in LFL2 for a game, with the stage at which the installer waited.

## 9. What is published, and can never be withdrawn

- **The word `launcher`** of the root `install.sh`, from the release whose `release` holds it, and the pasted
  line that ends in it. Like `update`, it is a first word that is not a number and names no game.
- **Nothing that is published changes.** The root `install.sh` and `common/games.tsv` do not move; the table
  keeps its four fields; a game is still named by its Steam app ID in every line; `install.sh update` does
  what it does; `release` still moves only to a tagged commit, by the gate.
- **A contract on the player's Mac, not an address:** `updates.sh --install <ID>` and its two answers
  (`opened`, `failed` and a sentence); the file `_update/launcher` and its four fields; the lock
  `_update/installing-<ID>`. By the tool's own rule (1.4) a later version may add to these and never changes
  or removes one.
- **Not published:** `common/install-launcher.sh`. It is run by the root `install.sh` and the driver of the
  same tree, so it may be renamed with them.
- **What this widens.** Today whoever moves `release` reaches an installed Mac by one click on Update
  (`docs/plans/built-in-update.md`, 3.8). After this plan a click on a game's tile runs code from `release`
  too. It trusts nobody new, the yes is still asked, and the rulesets on `release` and the tags stand. The
  list of games the window shows comes from its own bundle, built from the tree a yes installed, never from
  the network.

## 10. Statements this plan ends

Each is corrected in its file in step LF6, with a pointer here:

- `docs/plans/built-in-update.md`, UD7, 3.9 and section 11: "The offer still opens the game's set-up guide";
  "An install started from the window" as not planned.
- `docs/plans/launcher-window.md`, 2.5: "Only `owned` adds a row"; "A Mac with no game set up has no prefix to
  read and so shows no offer."
- `docs/plans/surviving-mars-install.md`, MD8: "A later slice, with its own plan."
- `docs/plans/shared-installer.md`, 2.2: "There is no default game", with `update` as its one exception. There
  is still no default game; there are two words.
- `common/make-launcher-app.sh:6` and `common/launcher-window.swift:3`: who builds the window, and what a row
  is.
- `CLAUDE.md`, the layout table's row for `install.sh` ("given a game's Steam app ID ...").
- The guides' first step, each of which is a game's own line today.

## 11. Phasing

**Slice 1, this plan (LF0 to LF7): useful by itself.** One line installs the launcher; its window lists every
game; a click and a yes run a game's installer in Terminal; a stopped install is seen and carried on; the
update keeps a launcher-only Mac current; a test holds the contract. Inside it, LF1 to LF3 can be released
before LF4 and LF5 if the live steps of the window's part find trouble: the launcher is then installable by
itself and its tiles open the guides, which is less than the idea and breaks nothing.

**What can wait, each a plan or a slice of its own:**

- **Slice 2: what the sheet says before a yes.** The game's needs in its own words (the contract's row 8,
  taken from each installer when the window is built) and this Mac's free space beside them (LFD7, LFD11).
  And the installer's look for another Steam moved to its first step, so that it stops before anything is
  downloaded.
- **Slice 3: an install view inside the window** (3.1), after slice 1 has run on real Macs. On the roadmap since
  2026-11-26 (LFD1).
- **A built and signed 14unch3r, and a double-click form of the launcher's installer**, once the project is a
  registered Apple developer (LFD2; 1.5, ND1 of `docs/plans/simple-install.md`).
- **The third game**, written against 3.6, with LFL6 as its live step.

## 12. Rollback

- **Before `release` moves:** nothing has reached a player. Revert the commits on `main`.
- **After, a wrong release:** a successor, which installed Macs are offered within a day, **while the check,
  the window's update parts and the driver of the wrong release work** (`docs/plans/built-in-update.md`,
  section 10: the same limit, and the same reason to run the suites on the tagged commit). A wrong tile or a
  wrong sheet cannot stop that route: the update's parts are separate.
- **The word:** it cannot be withdrawn. If the launcher's installer must be stopped, the word stays and its
  script says what to paste instead.
- **A player going back:** a game's line with an older tag after the ID, as today. An older setup rebuilds
  the window without the install parts and leaves `_update/launcher` unread.
- **Files:** `_update/launcher` and a stale `installing-*` link hold no game data and can go to the Trash.
  14unch3r goes to the Trash like any app; with no game set up, the next update then removes its stamp (3.5).
- **After LFL1 to LFL3:** the scratch account is deleted by James. Nothing of the Studio's own account was
  touched.

## 13. Decisions for James

| | Question | Recommended, and why |
|---|---|---|
| LFD1 | Does a game's install from the window run in Terminal, as the update does, or in an install view of the window's own? | Terminal, in this plan (3.1). The installers already ask, wait, stop and carry on there, and all of that is built and measured; an install view needs a way for every installer to hand its questions to a window, a process that outlives the window, and tests for both. Worth a plan of its own once this has run on real Macs. If you already know you want the view, say so now: the third game's installer should then name its questions from the start |
| LFD2 | Is 14unch3r still compiled on the player's Mac, or is a built app shipped? | Compiled there (3.2). The wait for Apple's tools is one every game's installer has anyway; a built app needs either a signature in a legal name or the route that stranded an approval at SL2, and a binary's address that could never move. LP1 must pass first |
| LFD3 | The line that names no game: a new word, `launcher`, or the bare line with nothing after the quote? And is `launcher` the word? | The word `launcher` (3.3). The bare line is an error today, on purpose and under test; a paste cut short should say so and not install something; and a word leaves the bare line free for ever. `launcher` reads as what it installs; `14unch3r` is the app's name but hard to say and to type |
| LFD4 | Does the window list every game the project ports, or only those Steam says the account owns? | Every game (3.7). A Mac with nothing has no Steam to ask, so the other rule shows an empty window to the player this is for. Where ownership is known the tile says "You own this" |
| LFD5 | How does an installed launcher learn of a new game: by the built-in update, or by fetching the table of games each day? | By the update (3.5): one route, and the player reads what changed before saying yes. The table from the network would be a second route that can disagree, shown in a window that may be too old for the game |
| LFD6 | After the click on "Install", does the window quit, as after an update? And does the launcher's installer open 14unch3r when it is done? | Yes to both. A window left open would be rebuilt under itself at the end of the install; and after the paste the player's next step is in the window |
| LFD7 | Before a yes, should the sheet say what the game needs (its size, its download) in the game's own words? | Yes, as slice 2 (section 11). Slice 1's sheet says that the installer says it first. It is a small change with its own test, and keeping it out keeps slice 1 to one new option and one new sheet |
| LFD8 | On a Mac in the state `manual` (a game set up from a checkout or a named version): does a tile's click install from `release` anyway? | No: it says why and offers the guide (3.8). Such a Mac asks GitHub nothing today, and mixing lines on one Mac is what `manual` exists to name. It is your two Macs' usual state, so on them the tiles would not install: say if you want the other answer |
| LFD9 | The new files outside the repository: `_update/launcher` and `_update/installing-<ID>`, both inside the folder `CLAUDE.md` already names | Yes. `CLAUDE.md`'s line for `_update` gains them in step LF1, before anything writes them |
| LFD10 | When do the guides lead with the launcher's line, and which number does the release take? | The guides change in the release that carries this, whose notes say that the old lines still work; each game's own line stays in its guide as the second way. The second number rises: a player with an install will notice new tiles. You took the third for `v0.3.1` against the same rule, so this is asked and not assumed |
| LFD11 | When less space is free than the game needs: does the window refuse, or caution? | Caution, in slice 2, as the installer does (1.2): a player may be about to free space or to install without the DLC |
| LFD12 | On an Intel Mac, or a macOS outside what is tested, does the launcher's installer stop? | It says so and goes on; only a macOS below 13, where the window cannot run, stops it. The two games already judge an Intel Mac differently, so the judgment belongs to each game |
| LFD13 | One install at a time from the window, whatever the game? | Yes (3.8): each install starts a Steam, and one Steam at a time can use an account |
| LFD14 | (Added 2026-11-26, from James's request of 2026-11-25.) Is the wait for Apple's Command Line Tools asked for first and overlapped with what needs no tool? | Yes (3.2): in the launcher's installer in slice 1, and in the shared core as step LF8 once its stages are read |

**Decided by James on 2026-11-26**, in answer to the table above laid out in the session, with the question which
he wanted different:

- **LFD1: Terminal, "but put in the roadmap".** The install view is on the roadmap (root `README.md`).
- **LFD2: compiled on the Mac "until we are a registered developer".**
- **LFD4: every game, and "uninstalled games should be gray scale or ghosted".**
- **LFD14: "agree".**
- **LFD3 and LFD5 to LFD13: as recommended.** He named the four above and left these as they stand.

## 14. Not in this plan

- **An install view inside the window**, and questions that have names (3.1; slice 3).
- **A built or signed 14unch3r**, and a double-click installer of the launcher (3.2): until the project is a
  registered Apple developer (LFD2).
- **The table of games fetched from the network** (3.5).
- **Removing a game.** There is no uninstaller; the guides' Uninstall sections stand.
- **Buying a game, or signing in to Steam, from the window.** The installer still sends the player to Steam's
  own window.
- **Installing two games in one go.** One click, one game, one at a time.
- **A change to `common/games.tsv`'s shape**, or joining it with `common/wrappers.sh`'s table (3.6).
- **The installers' own steps.** Nothing in a game's installer changes in slice 1; LP2 and LP3 may find
  things that are theirs to fix. The one change planned to the shared core is step LF8 (LFD14), after slice 1.
- **Macs set up before `v0.3.1`.** They need one paste per game before any update reaches them
  (`docs/plans/built-in-update.md`, section 11).
- **The third game itself.**

## What this draft could not verify

- **Whether 14unch3r compiles with Apple's Command Line Tools alone, and how long the compile takes** (LP1).
  The one number on record is 1.3 s for a 257-line skeleton on the Studio.
- **That a file fetched by curl and a built app with no quarantine open with no question on a new Mac.**
  Read in `docs/plans/simple-install.md`, 1.5, which cites it and did not measure it; the Studio's own builds
  are the only measurement.
- **What macOS shows when 14unch3r hands an install's file to Terminal on a Mac that has never done it.** UL1
  saw no dialog, once, on the Studio.
- **What Steam does on a full disk, and with the macOS Steam app open** (LP2, LP3).
- **Which existing test cases change, and the last mutant number of each test file.** The numbers in section
  6 are a count of one word per file, and the list of cases is from the files' headers and a few lines, not
  from a read of each file. The builder lens reads them.
- **Which older mutants are anchored on the lines this plan touches** in `install.sh`, the two setups,
  `common/update-games.sh` and `common/updates.sh`. `docs/plans/built-in-update.md` names several for its own
  changes; none was looked up for these.
- **Which stages of `common/install-core.sh` run a tool of Apple's, and in what order** (LFD14, LF8). Only the
  two games' named parts (`python3`, `nm`) and the tools stage itself were read.
- **Where the picture of a game with no app comes from** in a ghosted tile (LFD4).
- **The siblings' precedents** (1.6).
- **Line numbers** are of `91cfb63`. Three of the files read are long and were read in parts:
  `common/launcher-window.swift` (its header, `:128-312`, `:440-508`, `:639-836`, `:1606-1984`), and the two
  setups (their headers and the lines cited). A claim about a part not listed here is marked [inferred] or is
  absent.

## Review corrections (check-it 2026-11-26, pass 1): needs-rework

Seven lenses, each an agent on Fable reading the plan against the code at `93868e3`: architecture, security,
correctness, a builder, design, Apple platform facts, and the test plan. Two said needs-rework (architecture, test
plan) and five build-ready-with-fixes. Every blocker below was then read in the code or the plan by the session
that ran the pass, and holds. **Nothing in this section is folded into the sections above yet.** The rework does
that, and a second pass checks the rework.

Correctness counted 127 `file:line` citations: 123 hold, 4 are off by a line or two, none points at the wrong
code; no cited file changed since `91cfb63`. The builder typed in LF1's stamp row and LF2's `launcher` branch in a
scratch tree: the existing tests stayed green and all 42 older mutants of the two files stayed red.

### Decisions James took during the pass (2026-11-26)

- **The picture of a game that is not installed is the game's own icon, greyed** ("a ghosted or greyed out copy of
  the icon noting that it's not installed and can be"). Today such a tile shows the generic application icon
  (`common/launcher-window.swift:1076`): a game's icon is taken from the game's own program when it is set up, and
  the repository holds no game art.
- **Where the icon comes from: fetched from Steam's public artwork when the launcher is installed**, held to a
  fixed size and checksum as the installers' downloads are (his first of three options; the others were art in the
  repository, and an icon kept from an earlier install).
- **A click on a greyed game asks first** whether to install it. That is 3.7's sheet; its words follow his.

### Blockers

1. **The live steps cannot pass as written** (architecture, correctness, builder, test plan).
   - LFL1 ends in the state `manual`; 3.8 refuses `--install` in `manual`; and the file a click writes always
     fetches `release`, which does not hold this version before the release. So LFL2's click cannot install, and
     "both stamps name the branch" cannot be reached. `docs/plans/built-in-update.md:897-899` met the same limit.
   - LFL4: the driver leaves any stamp whose line is not the fetched ref (`common/update-games.sh:111`), and the
     Studio's stamps are `release`: the rehearsed update from the branch would touch nothing.
   - LFL3's second half: a launcher at the fetched version with no game runs nothing, and today's closing rule
     (`common/update-games.sh:147-157`: `RAN > 0`, `SETUP != 0`) then says "No game is set up" and exits 3.
   - **Correction:** LFL2 becomes three steps. *LFL2a*, the refusal in `manual` (no file written, Terminal not
     opened). *LFL2b*, before the release: the launcher's stamp rewritten by hand to `release`, then the click,
     which runs the published `v0.3.1` installer; measured: the tool's answer, the seconds to Terminal's first
     line, every dialog, the lock's life, stop and carry on, the game starting. *LFL2c*, right after `release`
     moves, on a clean account: the published launcher line, a click, an install, both stamps `release` at the
     new version. LFL2c replaces LFL5. LFL4 rewrites the stamps to the branch's line first and puts them back by
     the pasted lines. LFL3 rewrites the launcher's stamp to an older version before its second half. Exit
     criterion 2 names which steps come before the merge and which on the tagged release.
2. **The file handed to Terminal is not "constants only", and the lock comes too late** (builder, security,
   architecture, correctness).
   - It takes `_update/installing-<ID>`, so it must know that folder, whose path has a space and comes from
     `L1UpdateDir`; `_L1U_PROG` (`common/updates.sh:52`) cannot match it, and 3.8 gives no rule.
   - The lock is taken by the file, after the tool said `opened` and the window quit: a second click opens a
     second install, and locks per game let two games' installs run at once, which is two Steams on one account.
   - After a restart a stale lock's process number can belong to a live process, and every install is refused.
   - **Correction (a design change, to be checked again):** the installer takes the lock, not the file. The
     shared core takes one lock for an install as it begins and releases it at every exit, so a pasted line is
     covered too and the file stays constants and the number. One install at a time is that lock's rule. A lock
     older than the Mac's last start is dead (`sysctl kern.boottime` against the link's own time), in the core,
     the tool and the window. The update refuses while an install's lock is live and the install while an
     update's is: both ways, with a test each. Section 14's "nothing in a game's installer changes in slice 1"
     goes: this is a change to the core.
3. **On a Mac with only the launcher, the keyboard reaches no tile** (design). The window selects from the set-up
   apps only (`common/launcher-window.swift:250-253`, `:1183`); arrows need a selection (`:1269`) and Return
   needs a chosen row (`:1255`). **Correction:** with no app, the first not-set-up tile is selected; LFT6 gains
   the case and a mutant; the group's help says "to start it or set it up".
4. **The stated minimum is wrong, and LP1 as written cannot find it** (platform facts).
   - `MainActor.assumeIsolated` (`:1565`, `:1977`) needs a Swift 5.9 compiler. A Mac on macOS 13.0 to 13.4, or
     with older tools on a newer macOS, passes `xcode-select -p`, is asked nothing, and fails at the build.
   - Measured during the pass, and so part of LP1: with `DEVELOPER_DIR=/Library/Developer/CommandLineTools` the
     window compiles on macOS 27.2.1 with Swift 6.4 in 27 s with an empty module cache (4 s warm); compiler and
     SDK both from the tools' folder; the binary is arm64, signed ad hoc by the linker, with no quarantine.
   - **Correction:** the plan says "Command Line Tools 15 or later; built on macOS 27 only" until older compilers
     are tried. Step 3 reads the compiler's version and, below 5.9, says to update the tools in Software Update.
     A failed build names the game's own pasted line as the way that still works. LP1's pass condition is the
     test plan lens's: the compiler found under the tools' folder, the builder's line exits 0, the product
     answers `--svg` and `--list`, both window test files pass under the same variable, three timings recorded.
5. **No live step runs on a Mac without Apple's tools** (platform facts, correctness, test plan). LFL1 is on the
   Studio, where the tools are system-wide; the existing tools stage has never run for real on any Mac of the
   project; exit criterion 9 names a step that cannot observe it. **Correction:** a live step on a Mac or a macOS
   guest with no tools (the launcher needs no Wine, graphics card or Rosetta, so a guest serves), on James's word.
6. **Nothing joins the real installer to the real builder and window** (test plan). LFT2 uses a stand-in builder
   and LFT6 passes `--update-dir`, which wins over the bundle's key (`:34`); a missing key turns the tile into
   "opens the guide" with no error. A release whose window, installed from nothing, cannot install would pass
   every gate. **Correction:** LFT12 in `common/test-make-launcher-app.sh`: a scratch home, the real
   `install-launcher.sh` and builder; the app's `L1UpdateDir` is the scratch `_update`, `--update-tool` prints the
   deployed tool, `--list --games` prints one offer row per table row. Mutants: step 4 after step 5; the table
   not copied.
7. **LFD14's fold is under-designed, and the held copy is the wrong call** (architecture, builder, correctness,
   security, platform facts).
   - In the launcher's installer the overlap is nil (a version test, `mkdir` and `cp`), and the ask as folded
     comes before the macOS stop, so an old Mac gets Apple's box and is then refused. Nothing may be asked under
     `--check`.
   - The stage list the fold asked for, read by the builder and by correctness: in the core nothing before a
     game's setup runs one of Apple's tools. Cities: Skylines II first needs `python3` at its step 6
     (`cities-skylines-2/scripts/setup.sh:297`), so its wait could cover the wrapper, Steam and the whole
     download. Surviving Mars needs `nm` inside its step 4 (`surviving-mars-relaunched/tools/make-engine.sh:103`),
     before Steam and the game, so only the wrapper's and D3DMetal's downloads could overlap. Not shims, measured:
     `plutil`, `codesign`, `sips`, `iconutil`, `curl`, `tar`, `xattr`. A box dismissed at the start would be met
     hours later with nothing downloading: undesigned.
   - "Present" must mean "runs": a stale folder after a macOS upgrade passes `xcode-select -p`; `tools_ok` is
     tried once, perhaps while Apple's package is still being written; the request's result is thrown away
     (`common/install-core.sh:334`), so with no screen session it waits 60 minutes.
   - A held copy of the tools stage cannot be equal to the core's, and LF8 would rewrite both.
   - **Correction:** the ask and the wait become two functions in one small shared file read by the core and by
     the launcher's installer, with the call sites unchanged (no older mutant breaks: the builder checked the
     three anchors). In this plan the launcher's installer asks after its refusals and its macOS test and waits
     before the build. **The games' half (LF8, the wait moved later in the core) leaves this plan for a plan of
     its own**, with the stage list above as its start and the tools-less Mac of blocker 5 as its live step.

### To fix in the rework (each with its lens)

- **Section 9, what is widened** (security). A tile's click runs `release` in every state but `manual`, on a new
  population (launcher-only Macs), with no version and no notes shown; and the game's setup also rebuilds
  14unch3r and restamps the launcher, so a yes to one game is an unannounced update. Say all of it; the sheet says
  that the installer is fetched now from GitHub and may bring a newer 14unch3r; in the state `ready` the click
  says to update first. Record why pinning a click to the installed tag is declined.
- **3.7 reads wrappers any account can write** (security; issue #29). "Begun" and "Installing" come from a
  wrapper's `Info.plist` and `.launcher.lock`. Name #29 in 3.7 and section 9; take "Installing" from the install's
  lock only; give the one-button sheets "Read the Guide".
- **The driver's launcher step, 3.5** (architecture, correctness, builder). `own_app` returns 0 for an absent app
  (`common/make-launcher-app.sh:48`) and cannot be sourced: the driver needs its own "exists and is the builder's
  app". Name the launcher's row in `_l1u_stamps` (`_l1u_state` skips an empty first field, `common/updates.sh:190`)
  and its reader. Give the closing line and exit code for a launcher that is current with no game, and for a stamp
  newer than the fetch.
- **A failed compile now blocks `current`** (architecture): the launcher's stamp makes the window's build count,
  where today it is "never counted as a problem". Decide and say it.
- **Two meanings of "set up"** (architecture): the driver's (wrapper and program) and the window's (the app). A
  game downloaded with its setup unfinished is "begun" to one and "paste its line" to the other.
- **The fallback of section 11 is false** (architecture): without LF5 a launcher-only Mac shows "No games are set
  up". Split LF5 into the listing (a click opens the guide) and the sheet with the install; the fallback is LF1
  to LF3 plus the listing.
- **The guides are read from `main`** (architecture, test plan): the table's addresses are `blob/main`, so a guide
  that leads with the launcher's line before `release` holds the word sends a player to an error. The guide edit
  is its own commit after `release` moves.
- **The contract, 3.6** (architecture, correctness, test plan). Row 9 is false: `l1w_games`
  (`common/wrappers.sh:47`) and the per-game folders of `common/paths.sh:28-31` are second lists a third game
  must join. Row 7: "stop when nobody answers" is true of the licence and Rosetta questions only; "Press Return"
  goes on, and the Desktop question is a fourth kind. No row gives a game its picture: the art's table does now.
  LFT7's "every `read` under a test of the terminal" is not typable as written.
- **The window** (design, builder). The new tiles belong in the first `reload()`, not behind the ownership
  question. `--list` takes no `--update-dir` today. What a click does is decided in `startChosen` (`:1766`), which
  no text mode builds: it needs a pure function and source gates, as the update's sheet has. `runChild` (`:402`)
  returns nothing alike for any failure, so "the older-tool sentence" is every no-answer's. Names for the three
  states; tooltip and spoken words for each (today's spoken words say "opens the set-up guide"). Only the icon is
  grey and at 0.5: the title and second line stay at 1 and 0.88, so the contrast lines hold. "A game that is set
  up is never drawn so" is false: a set-up game that is not installed in Steam is grey today, and tested. The
  second lines fit (measured with the window's fonts); the height stays inside 600 until four rows.
- **The words** (design). The sheet's text says "asks before it fetches anything under a licence", true of one
  game only; "from here" is unclear once the window has quit. The `manual` sentence says "the games" where only the
  launcher may be on a checkout, and the window knows the state before the click, so it shows the one-button
  sheet at once. Three buttons is this window's first: record it in the look's document and capture it.
- **The look's document** (design): section 10 names `docs/plans/launcher-window-look.md`'s statements that end
  (`:159-162`, `:238`, `:242`, `:246`, `:564`, W14's offer expectations at `:475`).
- **Tests** (test plan, builder). LFT8 starts at the tree's version and passes on "holds the tree's version": start
  it older. LFT2 gains: tools arriving mid-wait, tools present but not running, an Intel Mac, a signal during the
  build. The cases that run the written file belong in `common/test-update-games.sh`; add a failed fetch (000,
  404, 500), a hangup, and a record folder whose name holds a space, a quote and `$(touch X)`. A dead install lock
  must not read as installing. LFT1 gains `launcher <ref>` and its mutant. LFT9's "every older mutant still red"
  is a hand-run practice recorded in the as-built header, not a gate, and "none refused" is false at baseline
  (`cities-skylines-2/scripts/test-setup.sh:126` retires one): say so. LFT10's first mutant repeats an existing
  kill. LFL1's pass conditions become measurements, and it gains the dark and light captures.
- **Platform facts to restate** (platform facts). The paste warning of macOS 26.4 is documented by Apple
  (support.apple.com/guide/security/sece3b202c4b): Terminal not opened in 30 days, no developer tooling found,
  the paste from a browser or a message; so the Studio can never show it, and LFL2c's Mac must qualify.
  `softwareupdate` does need an administrator. LFD2's condition is "a member of the Apple Developer Program"
  (99 USD a year; an individual's signature carries the legal name). The compile takes 27 s cold on the Studio and
  the builder prints nothing meanwhile.
- **Small ones** (correctness). The pasted line stands seven times, not six (`cities-skylines-2/README.md:30` too,
  which is that game's guide address). 3.4 step 4 names two folders where both setups test and make three, the
  parent first. `install.sh:21` belongs in section 10. "Three kinds of tile" heads a table of four.

### What the rework still has to decide or probe

- **The art.** Which of Steam's images is the game's own icon, and its address: a probe fetches it for both games
  and compares it with the icon of the set-up app. A table of its own (app ID, address, size, checksum) and not a
  fifth field of `common/games.tsv`, whose shape is published. What a tile shows when the fetch fails or the Mac
  is offline: the generic icon, as today. The launcher's installer then makes a request to Valve, which it does
  not today: the guides say so.
- **Open for James** (each has the rework's default, taken if he says nothing against it):
  1. *How a click-to-install is proven before the release.* Default: the three-step LFL2 of blocker 1, with no
     rehearsal switch in the tool, so the first install from a click on this version's own installer happens
     right after `release` moves (the old pasted lines keep working if it fails). The other way is a switch by
     which the tool follows the line a Mac's stamps name, which lets it be rehearsed from a branch and is more
     code on the path a click runs.
  2. *The games' half of the Command Line Tools wait* (LF8) leaves for a plan of its own. Default: yes.
  3. *A Mac, or a macOS guest, with no Apple tools on it* for the live step of blocker 5. It needs James to make
     one; without it LFD14 and the tools stage stay unmeasured.
  4. *In the state `ready`, a click on a game that is not set up says to update first.* Default: yes.
  5. *The launcher's installer fetches each game's icon from Valve* (his choice of 2026-11-26): the guides gain a
     line saying so.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-26 | 1 | architecture, security, correctness, builder, design, platform facts, test plan | seven agents in two batches, read-only; the builder ran the gates and typed two steps into a scratch tree; platform facts compiled the window with the Command Line Tools alone; every blocker read again by the session | Fable 5.2 | `93868e3` | needs-rework |

Key paths this plan depends on: `install.sh`, `common/games.tsv`,
`common/install-core.sh`, `common/updates.sh`, `common/update-games.sh`, `common/make-launcher-app.sh`,
`common/launcher-window.swift`, `common/wrappers.sh`, `common/paths.sh`, `common/make-wrapper.sh`, both games'
`scripts/install.sh` and `scripts/setup.sh`, and the tests named in section 6.
