# The launcher first: one pasted line installs 14unch3r, and its window installs the games

**Status: check-it'd 2026-11-26 — needs-rework (pass 3). Reworked twice on 2026-11-26; the third pass found two
faults of the second fold, each cured by one sentence, and James then changed one decision (the picture of a game
that is not installed is drawn by the program, not fetched). Neither is folded yet: the block "Third-pass
re-check" near the foot says what the third fold must do, and where it disagrees with the sections above, it is
right. A fitted fourth pass comes before any build.** Draft written 2026-11-25. No build may start from
this file until it is checked again and carries a verdict that allows it. Nothing below is built. Sections 1 to
14 hold the corrected design: every blocker and every item of pass 1 (the section "Review corrections" near the
foot) and of pass 2 (its block "Second-pass re-check") is folded into them, and each says where. **The second
fold is new material that no lens has read.** The third pass is one fitted check of that fold, as all three
reviewers of pass 2 asked: it reads what rework 2 changed against the code and against the rest of this file,
and a fleet comes back only if it finds a fault of structure. What it should read hardest: the pictures' file
and its three callers (3.10), the order of the steps (section 4), the lock's added rules (3.8), the live step on
the iMac (LFL7), and the words rework 2 wrote (RC27). Every `file:line` of the draft was read on `main` at
`91cfb63` (2026-11-25), and pass 1 read them again at `93868e3`. The first rework read the lines it cites newly
at `dc990de`, and the second at `e40cd4d` (both 2026-11-26); no code file cited here differs between those
commits, and the guides' line numbers are of `dc990de`. A path is relative to the repository root. Tracking: no
issue yet; one is opened when the check is done.

**Decisions: taken by James on 2026-11-26** (section 13). His own: the install view goes on the roadmap (LFD1);
14unch3r is compiled on the player's Mac until the project is a member of the Apple Developer Program (LFD2); a
game that is not set up shows the game's own icon, greyed, with words that say it is not installed and can be,
and the icon is fetched from Steam's public artwork when the launcher is installed (LFD4); a click on it asks
first; Apple's Command Line Tools are asked for first (LFD14); and the launcher's installer stops below macOS
14. Four more are the rework's defaults, which he saw and did not object to (RD1 to RD4), and the two reworks
made choices of their own that he has not seen (RC1 to RC20 the first, RC21 to RC27 the second): section 13
lists both, so that he can overrule any.

**How to read the marks.** **[read]**: read in the code or a plan, by the session that wrote the draft or by
the rework. **[record]**: taken from another plan's record of a measurement, or from what a lens of pass 1
measured or read, and not repeated here. **[inferred]**: follows from what was read, and was not run.
**[not known]**: the code and the plans do not answer it; it is a probe or a decision below. The draft measured
nothing. Pass 1 measured one thing, the compile with Apple's tools alone (LP1, section 7). The rework ran two
commands in a scratch folder (the time `stat -f %m` gives for a link, and the form of `sysctl -n
kern.boottime`) and nothing else: no test, build, app, Wine or network request. The second rework read code and
ran searches, the link check and the identifier check, and measured nothing.

This plan's steps are LF0 to LF7 (LF4 and LF5 each in two parts, a and b). **They are built in this order: LF0,
LF1, LF2, LF3, LF5a, LF4a, LF4b, LF5b, LF6, LF7** (section 4 says why LF5a stands before LF4a). Its tests are
LFT1 to LFT14, its probes LP1 to LP4, its live steps LFL1 to LFL4 (LFL2 in three parts: a, b and c) and LFL6 to
LFL9, and its decisions LFD1 to LFD14, RD1 to RD4 and RC1 to RC27.

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
  (`:138-148`). Every other word that is not digits gets "not a Steam app ID" (`:88`), and the script's header
  says so in words: "update is the one first word that is not a number" (`:21`). The usage line that follows
  (`:89`) is said for the empty word and for a wrong word alike. A ref is judged by one rule for every path
  (`:93-96`), and from a checkout a game's ref is judged and then not used (`:98-108`).
- **A game is found by its ID in the fetched table [read].** `game_folder` (`install.sh:30-32`) takes the row
  of `common/games.tsv` whose first field is the ID, only if the row has exactly four fields and its folder
  matches `^[a-z0-9][a-z0-9-]*$`, and the script then runs `<folder>/scripts/install.sh` with the options
  (`:149-159`), after exporting `L1_FETCHED_REF` and `L1_FETCHED_COMMIT` (`:156-157`).
- **The table [read].** `common/games.tsv`: two rows of four tab-separated fields: Steam app ID, folder, title,
  the address of the set-up guide (949230 and 3215050). Three programs read it and insist on four fields:
  `install.sh:31`, `common/update-games.sh:135`, `common/launcher-window.swift:467`. Two more read a field by
  its place without that test: `common/make-installer-app.sh:47-51` and
  `surviving-mars-relaunched/scripts/setup.sh:269`. Both guide addresses are `blob/main`: a guide is read from
  `main`, not from `release`.
- **What is published [read].** `CLAUDE.md` § Published addresses: the root `install.sh` and
  `common/games.tsv` never move; a row's first field never changes; a published thing names a game by its
  Steam app ID; `install.sh update` is a published word; `release` moves only to a commit a `v` tag names. The
  pasted line stands in seven places, each with an ID (`README.md:32`; `cities-skylines-2/README.md:30`, the
  file the table gives as that game's guide; `cities-skylines-2/INSTALL.md:23`, `:475`, `:538`;
  `surviving-mars-relaunched/INSTALL.md:26`, `:180`). Three of them carry a variable before the line (`:475`,
  `:538`, `:180`).

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
  Rosetta question and Surviving Mars's question stop, exit 3; "Press Return to continue" goes on (it is only
  asked at a terminal, `cities-skylines-2/scripts/setup.sh:106-109`); and the Desktop question counts as no.
  Besides the questions it tells the player what to do in other windows: Apple's box
  for its Command Line Tools (`common/install-core.sh:333-335`), Steam's sign-in and its Install button
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
- **What that stage takes for "present" [read].** `xcode-select -p` succeeding (`common/install-core.sh:328`).
  With the folder there and the game's part not running it stops, exit 1, and asks Apple for nothing
  (`:329`); Cities: Skylines II's mutant 24 holds exactly that (`cities-skylines-2/scripts/test-install.sh:139`).
  Without the folder it sends the request and throws its exit code away (`:333`), then polls `xcode-select -p`
  alone (`:337-341`) and tries the part once (`:342`). Under `--check` it asks nothing (`:331`). Where a tool
  of Apple's is first run in each game's install is in section 14. **[record: pass 1]** This stage has never
  run for real on a Mac of the project: every Mac it ran on had the tools.
- **Its exits [read].** One trap on EXIT, `on_exit` (`common/install-core.sh:71-87`), releases the wrapper's
  lock and says the closing line; the traps on INT, TERM and HUP end in `exit` and so reach it (`:90-93`).
- **Nothing stops two installs at once, or an install beside an update [read].** The core's one lock is the
  wrapper's `.launcher.lock`: looked at in `core_begin` (`:288-293`), taken in `core_lock` (`:383-388`). It
  is one per wrapper, so two games' installs do not meet. The update's lock, `updating`
  (`common/update-games.sh:46-63`), is looked at by no installer.
- **A second Steam [read].** Before it starts Steam for a game that is not yet downloaded, the core looks for
  a Steam for Windows of another prefix and stops with exit 3: its line begins "Steam is open in <wrapper>."
  and says to quit that Steam and open the installer again (`common/install-core.sh:427-435`). Its own comment
  says what it does not see: "This sees a Steam for Windows of another prefix on this Mac, and nothing else."
  The look comes at the game's step, after Wine and Steam for Windows are already in place.
- **A full disk [read].** `core_space` prints a caution when less than the game's `NEED_GB` is free and goes
  on (`common/install-core.sh:346-357`). `common/make-wrapper.sh:84-86` refuses to make a wrapper with under
  6 GB free. Nothing else in the installers looks at free space. **[not known]**: what Steam under Wine does
  when the disk fills during the game's download, and so whether the installer's wait (`:476-501`), which ends
  only when the game is installed or Steam is gone, would then wait for ever.
- **A wrapper is marked when it is made [read].** `core_wine` runs `common/make-wrapper.sh` with `--mark game
  <ID>` (`common/install-core.sh:363`); the marker is written before the finished wrapper is moved into place
  (`common/make-wrapper.sh:11-12`), and a wrapper whose making stopped leaves nothing (`:16-17`).
- **Neither setup fetches anything [read].** A search of both setups for `curl` finds no line: what a setup
  needs from the network, its installer has fetched before it. (3.10 changes this for one small file per game.)
- **The transcript [read].** `cities-skylines-2/scripts/test-install.sh:870-881` compares what the installer
  printed in every case with `scripts/test-install.golden` and fails on any difference; it is recorded again
  only on purpose, with `GOLDEN=record` (`:82-83`). Surviving Mars's test file has no such transcript, and no
  case of the tools stage: its stub `xcode-select` always answers 0
  (`surviving-mars-relaunched/scripts/test-install.sh:219`).

### 1.3 14unch3r, its builder, and what it shows

- **It is compiled on the player's Mac [read].** `common/make-launcher-app.sh:62` needs `xcrun -f swiftc` and
  otherwise skips with exit 3 ("install the Xcode Command Line Tools"); `:71` compiles
  `common/launcher-window.swift` (1,984 lines) with `swiftc -O`; `:76-77` copies `common/games.tsv` into the
  bundle; `:132-137` writes `L1UpdateDir` into its `Info.plist` only when `_update/updates.sh` is already
  there; `:140-151` swaps the finished app in. Its `LSMinimumSystemVersion` is 13.0 (`:115`). Its exit 3
  stands for three things: `swiftc` missing, the source missing, the compile failed (`:12-13`, `:61-63`,
  `:71-73`). Its test `own_app` (`:46-53`) answers 0 for an app that is absent.
- **Only a game's setup builds it [read].** Cities: Skylines II's setup builds it after, and only if, the
  game's own app was built (`cities-skylines-2/scripts/setup.sh:526-543`); Surviving Mars's setup builds it at
  `surviving-mars-relaunched/scripts/setup.sh:249-250`. Cities: Skylines II's setup stops unless a wrapper
  with Steam and the game in it is there (`cities-skylines-2/scripts/setup.sh:278-293`, `:303-305`); what
  Surviving Mars's setup does with no wrapper was not read for this draft. Neither setup is offered to a
  player as a way to get the window alone, so today there is no way to have the window before a game.
- **A row is a set-up game [read].** The window lists the apps in `~/Applications` whose `Info.plist` carries
  `L1Role` `game` or `steam`, a game also `L1SteamAppID` (`common/launcher-window.swift:131-151`). Its state
  comes from files alone (`:168-173`): `busy` when the prefix's `.launcher.lock` names a live process, else
  `ready` or `absent` by Steam's manifest for the game. A lock is live when it is a link whose target is
  digits only and names a process that answers (`:153-165`).
- **A game that is not set up shows only when Steam's cache says the account owns it [read].** `offerRows`
  (`:483-507`) reads `packageinfo.vdf` of the prefixes of the rows that are there, and returns nothing when
  there is no such file (`:491`). `docs/plans/launcher-window.md`, 2.5, says so in words: "A Mac with no game
  set up has no prefix to read and so shows no offer." With no tile at all the window shows "No games are set
  up on this Mac yet." and the README's address (`:799-800`, `:1743`).
- **A click on an offer opens the guide in the browser [read].** `startChosen` (`:1769`) hands an offer to
  `launch`, which runs `/usr/bin/open <address>` and leaves the window open (`:1799`). The address must start
  `https://github.com/` (`:495`). The words: "Not set up on this Mac. Opens the set-up guide." (`:177`); on
  the tile "Not set up. Opens its guide." (`:966`); spoken, "opens the set-up guide in your browser" (`:971`).
- **How an offer is drawn [read].** With the generic application icon (`:1076`), through `greyed()` at
  `Look.dimAlpha`, 0.5 (`:794`, `:1077-1079`): `dim()` is true of every offer and of an `absent` row (`:976`).
  The title is drawn at alpha 1 and the second line at 0.88 (`:1086-1095`). The repository holds no game art:
  a set-up game's icon comes from its own app (`:1076`).
- **The selection is among the set-up apps [read].** `defaultRow(apps, last:)` (`:250-253`, called at
  `:1183`) is given the apps and not the offers; the arrows need a selection (`:1269`) and Return a chosen row
  (`:1255`). The group's help is "Click a game, or press Return, to start it." (`:1151`).
- **Starting a game asks only about another game in use [read].** `blocker` (`:263-267`) returns a row of
  another prefix whose state is `busy`; `startChosen` then shows the question "`<title>` is still in use." with
  "Don't Start" and "Start Anyway" (`:1772`, `:1775-1790`), and the text mode `--second` prints `ask` and the
  title, or `go` (`:1532`). It reads rows, so it knows nothing of a Steam whose wrapper has no app.
- **Its states and text modes [read].** `enum State` has `busy`, `absent`, `ready`, `unknown`, `owned`
  (`:44`); `--list` prints the state's word and takes `--games` and no `--update-dir` (`:1518-1524`). The
  update's sheet has text modes of its own (`--update-sheet`, `--update-answer`, `--update-open`: `:25-28`),
  its answer is a pure function (`sheetAnswer`, `:729`), and source gates count its lines
  (`common/test-launcher-window.sh:975-984`). `runChild` answers nothing alike for an exit that is not 0, the
  time limit and a crash (`:399-402`). The window reads states again when it becomes the active app
  (`:1724-1726`).
- **The table it reads is the copy in its own bundle [read].** `:1611`. So a game added to the repository
  shows only after some setup has run again and rebuilt the window (`docs/plans/built-in-update.md`, 1.3).
- **It already finds a marked wrapper [read].** `markedWrapper` (`:216`) looks in a folder for the one app
  marked `game-wrapper` with a given `L1SteamAppID`; `rows(in:)` uses it after a hand rename (`:238-240`).
- **A built app opens with no question [record].** `docs/plans/launcher-window.md:158-159`: the bundle a
  compiled skeleton sat in "starts through `open` with no signing step". **The whole file's compile, measured
  by pass 1's platform lens (LP1):** with Apple's Command Line Tools alone and no Xcode, on the Studio, macOS
  27.2.1, Swift 6.4: 27 s with an empty module cache and 4 s warm; the binary is arm64, signed ad hoc by the
  linker, with no quarantine. The builder prints nothing while it compiles. The source uses
  `MainActor.assumeIsolated` (`:1565`, `:1977`), which needs a Swift 5.9 compiler **[record]**. Its tests have
  run on macOS 27 only.

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
  the sheet it looks for a game in use and then shows "Quit <title> first." (`:1854`). `--open` looks at the
  state and at nothing else before it writes (`common/updates.sh:309-310`).
- **Measured at UL1 [record]** (`docs/plans/built-in-update.md`, "UL1 on the Studio"): between the click and
  Terminal's first line macOS showed no dialog that held it up, and the lines were printed within eleven
  seconds. One run, on the Studio, with nobody at the screen.
- **The driver passes over a Mac with no game [read].** `common/update-games.sh:149-150` says "No game is set
  up on this Mac." and exits 3 (`:157`). It runs each set-up game's installer with no option (`:122`), and
  each of those setups rebuilds the window. "Everything is up to date" needs an installer to have run
  (`:147`). It leaves a game whose stamp is on another line than the one fetched (`:111`) or newer than the
  fetch (`:114-116`), and refuses a fetch older than what was offered (`:68-76`). Its lock is the link
  `updating`, whose target is its process number, taken over when the holder is gone (`:46-58`).
- **Two of the window's sentences speak of games only [read].** For the state `manual`, "Check for Updates…"
  answers with `Look.checkoutText`, "Its games were set up from a checkout. Update with git pull, then run each
  game's setup.", or `Look.namedText`, "A game here was set up from a named version. Paste its installer line
  from the guide to follow new versions again." (`common/launcher-window.swift:708`, `:829-830`;
  `common/test-launcher-window.sh:923`, `:925` expect them).
- **`off` is judged before the stamps are read [read].** `_l1u_state` returns the word `off` as soon as the
  file is there (`common/updates.sh:188`), before the loop that finds a stamp on another line (`:189-198`): in
  `off` the state says nothing of `manual` or `ready`.
- **The tool's options and output lines are a contract between versions on one Mac [read].**
  `common/updates.sh:24-26`: "a later version may add an option or a field at the end of a line, and never
  changes or removes one." The window takes only the six state words it knows
  (`common/launcher-window.swift:671-680`).

### 1.5 What macOS does with an installer that is downloaded

- **An installer app was stranded by Gatekeeper [record].** `docs/plans/simple-install.md`, its header's
  record of NL2 (2026-11-12), and `docs/plans/shared-installer.md`, section 9, SF6: an unsigned app downloaded
  by Safari was refused, approved with Open Anyway, and then held by macOS at a Touch ID box whose fallback
  button was pressed; every later open ended in Finder's "not responding" until the process was ended from
  Terminal. One run; the cause is inferred there. James decided on 2026-11-16 (ND1, the decision of
  `docs/plans/simple-install.md`, recorded in `docs/plans/first-run-findings.md`, section 8): only the pasted
  line is published. No installer app has been released (`CLAUDE.md`).
- **Read for that plan, not measured [record]** (`docs/plans/simple-install.md`, 1.5): a file fetched with
  `curl` carries no quarantine attribute, and Gatekeeper acts on quarantined items; an app built on the Mac
  itself opens with no question; a Developer ID with notarization needs membership of the Apple Developer
  Program, 99 USD a year, and an individual's signature carries the legal name (declined, K3); macOS 26.4 and
  later can refuse a pasted Terminal command with "Possible malware, paste blocked", which the user can
  override. That plan's NL4, which measures the pasted line on such a Mac, has not been run.
- **The paste warning is Apple's own, with conditions [record: pass 1's platform lens, from Apple's page
  support.apple.com/guide/security/sece3b202c4b; the rework did not open it].** macOS 26.4 and later warns
  when Terminal has not been opened in over 30 days, no developer tooling is detected on the Mac, and the
  paste comes from a browser, Messages or Mail; there is a grace of 24 hours after the system is set up. So
  the Studio, which has the tools, can never show it, and a Mac that could is one without them (LFL7).
- **`softwareupdate` can install the tools without Apple's box, and needs an administrator for it [record:
  the same lens].**

### 1.6 Conferring with the sibling repositories

Not done for the draft, and still not done by the rework, which was held to this repository: a search over
the siblings' `docs/` is one command (`grep -rIlE 'install the launcher|launcher first' ~/github/*/docs`),
and its result, a precedent adopted or a decline with its reason, is written here. It is listed under "What
this draft could not verify".

## 2. Target

1. One pasted line that names no game installs 14unch3r on a Mac that has nothing of this project.
2. Its window lists every game this project ports: the ones set up, the ones not set up, one whose install was
   begun and not finished, and one whose install is running. A game that is not set up shows its own icon,
   greyed, and says that it is not set up and can be installed.
3. A click on a game that is not set up asks whether to install it now, and a yes runs that game's installer.
   Nothing is installed without that yes.
4. Every published line keeps working unchanged: each game's line with its ID, and `install.sh update`.
5. A game added in a later release reaches an installed launcher by the built-in update, and is then a tile
   like the others.
6. A new game is written against a contract that a test holds.
7. One install runs at a time on a Mac, whichever way it was started, and never beside an update.

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
| What is new to build and to test | One option of the deployed tool, the sheets of 3.7, and for each a text mode of the kind the update's sheet has (`--update-sheet`, `--update-answer`, `--update-open`: `common/launcher-window.swift:25-28`) | A terminal view or a protocol, a process owner, a progress model, and tests for each |

So: Terminal in this plan. It is what UD2 chose for the update, for the same reasons, and it adds no second
way for an installer to talk. An install view is a plan of its own (section 14), and what it would need from
the installers, questions that have names, is worth knowing before a third game's installer is written.

**Decided 2026-11-26 (LFD1): Terminal in this plan, "but put in the roadmap".** The roadmap of the root
`README.md` names this plan (`README.md:91-93`) and names the view as an item of its own (`README.md:97-98`)
**[read]**: nothing is owed there.

### 3.2 What must happen before a window can appear: build it there (LFD2, LFD14)

On a Mac with nothing, in order **[inferred from 1.2, 1.3]**: Terminal and the paste; the fetch of the
repository; Apple's Command Line Tools, if absent (Apple's own box, Install, Agree, a download of ten minutes
or more by the installer's own words); the compile; the app. Not needed for the window: Rosetta, Wine, Steam,
any licence question of a game.

| | Build it on the Mac (today's way) | Ship a built app |
|---|---|---|
| Before the first window | Apple's Command Line Tools, then a compile: 27 s with an empty module cache, 4 s warm, on the Studio (LP1) | A download of the app |
| Is that wait extra? | No: every game's step 2 asks for the same tools (1.2), so a player who goes on to any game pays it once either way. It moves to the front | It would save the wait only for a player who installs the launcher and no game |
| Gatekeeper | An app built on the Mac opens with no question (1.3, 1.5); LP1 found the binary signed ad hoc by the linker and with no quarantine | Fetched by curl inside the pasted line: **[inferred, not measured]** no quarantine, so no question, if the build is signed ad hoc. Downloaded by a browser: refused, Open Anyway, and SF6's stranding (1.5) |
| Signing | None | For a browser download to open cleanly: a Developer ID and notarization, which need membership of the Apple Developer Program (99 USD a year; an individual's signature carries the legal name; declined, K3) |
| What a player can read | The source that is compiled | A binary. The project would have to build it, test it on each macOS it claims, and publish it at an address that can then never move |
| A new published thing | None | The binary's address and its tag, for ever |
| An update of the window | The update compiles the new source, as now | A second download path beside the tree, or both ways kept |

So: build it there. The cost is honest and is said in the guide: the first window comes after Apple's tools.
Shipping a built app stays possible later without changing this plan's design, and is not in it (section 14).

**Decided 2026-11-26 (LFD2): compiled on the player's Mac "until we are a registered developer".** The
condition, written out: until the project is a member of the Apple Developer Program. A free developer account
gives no Developer ID, so it does not meet it. Until then nothing of this plan ships a binary.

**The minimum macOS (James, 2026-11-26, said of pass 1's blocker 4: "None of these games would run anything
that old. I think realistically we can come up several versions.").**

- **The launcher's installer stops below macOS 14.** No game of the project runs below it: the root
  `README.md`, "Compatibility", lists every macOS before 14 as not supported for both games, and Surviving
  Mars's setup stops there (`surviving-mars-relaunched/scripts/setup.sh:65-69`) **[read]**.
- **It cautions below macOS 26**, with one line and no stop: older than anything either game was run on
  (`cities-skylines-2/scripts/setup.sh:255-264` cautions on 14 to 25; the README's "Tested" row starts at 26).
  The boundaries are whole numbers: 13.6 stops, 14.0 goes on with the caution, 25.9 is cautioned, 26.0 is not.
  The lines themselves are in 3.4, step 1.
- **The window's stated minimum becomes 14**: the bundle's `LSMinimumSystemVersion` is written as `14.0`
  (`common/make-launcher-app.sh:115`, today `13.0`), in step LF2.
- **A compiler check stays, for tools left behind by an upgrade.** The window's source uses
  `MainActor.assumeIsolated` (`common/launcher-window.swift:1565`, `:1977`), which needs a Swift 5.9 compiler
  **[record: pass 1's platform lens]**. Every macOS from 14 on is served Command Line Tools 15 or later, whose
  compiler is 5.9 or later **[record, the same lens; not measured]**, so the check is one line: the installer
  reads `xcrun swiftc --version`, and below 5.9 says "Apple's Command Line Tools on this Mac are older than
  14unch3r needs (Swift `<version>`, and it needs 5.9). Update them in Software Update, then paste the line
  again." and stops, exit 3. A version it cannot read does not stop it: the build decides.
  - **The two numbers are compared as numbers**, the first and then the second: 5.10 is later than 5.9, and a
    compare of "5.10" with "5.9" as decimals would stop a good compiler.
  - **The version is taken from the words `Swift version <a>.<b>`, wherever they stand in the output**, so both
    forms are read: the line that begins `Apple Swift version`, and the one that has `swift-driver version:`
    before those words **[record: pass 2's correctness reviewer; the rework ran no compiler]**.
- **A failed build names the way that still works:** "14unch3r could not be built on this Mac. Each game can
  still be installed by its own line: the guide lists them, at https://github.com/macgameport/1launcher" with
  the compiler's first error, exit 1.
- **What has been measured:** the window was built and run on macOS 27 only. LP1 (section 7) is the one
  measurement with Apple's tools alone, and it needs only the compilers macOS 14 and later deliver. **No step of
  this plan meets a compiler older than Swift 6.4:** every Mac of its live steps is on macOS 27, LFL7's too. So
  the as-built header and the guides say "built on macOS 27 only" until an older one is met (LF6, LF7).

**Decided 2026-11-26 (LFD14, "agree"): Apple's Command Line Tools are asked for first.** Asked by James on
2026-11-25, the day the first player from outside the project was about to run an installer: this is the
longest step that is not a game's download.

- **What needs the tools today [read].** Cities: Skylines II names `python3`, for its patches
  (`cities-skylines-2/scripts/install.sh:42`); Surviving Mars names `nm`, for its engine swap
  (`surviving-mars-relaunched/scripts/install.sh:45`); and 14unch3r is compiled with `swiftc`
  (`common/make-launcher-app.sh:62`, `:71`). The games' own apps compile only their progress panel with it and
  go on without (`cities-skylines-2/scripts/make-shortcut.sh:222-227`,
  `surviving-mars-relaunched/make-app.sh:127-130`). So a built window alone would not remove the tools from
  either game's install.
- **One small shared file, `common/tools.sh` (new)**, read with `.` by the shared core and by the launcher's
  installer. It holds two functions and nothing else; the caller defines `say` and sets `POLL`, `TOOLS_POLLS`
  and `TOOLS_PART_POLLS` first.
  - `tools_ask`: runs `xcode-select --install`, keeps its exit code and returns it. When the request was taken
    (0) it says the two lines the core says today (`common/install-core.sh:334-335`). When it was not, it says
    other words: "Apple's box could not be opened from here. It may be open already; if no box is showing, run
    xcode-select --install in Terminal at the Mac itself. This window goes on by itself when the tools are
    there." It never stops by itself. **[not known]** which exit code the request gives with a box already
    up: LFL7 reads it, and the rule may be tightened then. What it gives with no screen session stays not
    known: no step reads it (pass 2 struck the reading over a remote login, section 7).
  - `tools_wait <test of the part>`: called only after `tools_ask`, so only in a run that began with no tools'
    folder. Every `POLL` seconds, at most `TOOLS_POLLS` times, it asks `xcode-select -p`, and once that
    succeeds it runs the caller's test of the part (never before: without the tools, running one of them opens
    Apple's box itself, `common/install-core.sh:328`). It returns 0 when both hold; 1 when the polls ran out
    with no tools; 2 when `xcode-select -p` succeeds and the part still does not run `TOOLS_PART_POLLS` polls
    later (24 in both callers, two minutes: Apple's package may still be writing its files when the folder
    appears). Today the part is tried once (`common/install-core.sh:342`). **This settle is for a folder that
    appeared during this run, and for no other:** a folder that was there at the start is judged at once, by
    the caller, before any ask.
- **In the core, the call sites stay.** Only `common/install-core.sh:333-342` becomes the two calls: the
  request, its two lines, the loop, and the one try of the part. Four things keep their place and their text,
  because older mutants and one test line are anchored on them:
  - the test at `:328` (Cities: Skylines II's mutants 24 and 28:
    `cities-skylines-2/scripts/test-install.sh:139`, `:133`);
  - `TOOLS_POLLS=720` at `:34` (the `sed` at `:492` of that file); `TOOLS_PART_POLLS=24` is set on a line of
    its own after it;
  - the text `are not installed yet."; exit 4; }`, which stays in the core, literally, on the line said when
    `tools_wait` returns 1. Mutant 27's `sed` (`:132`) is applied to the game's installer and the core and to
    no other file (`mutate`, `:99-100`), so that sentence and its `exit 4` cannot move into `common/tools.sh`
    (pass 1's builder named the first two anchors; the first rework found this one, and pass 2 that it must
    stay in the core word for word **[read]**);
  - the core's answer to a folder that is there with a part that does not run: exit 1 with "Reinstall them"
    and no request (`:329`; mutant 24 holds exactly that).

  When `tools_wait` returns 2 the core says its sentence of `:342`. The new file joins the core's test of its
  own files (`:29`) and the scratch trees of both games' `scripts/test-install.sh`.
- **In the launcher's installer "present" means "runs", and a folder that is there is never asked about.** The
  part is: `xcrun -f swiftc` succeeds, `xcrun --show-sdk-path` prints a folder that exists, and `xcrun swiftc
  --version` runs. With `xcode-select -p` failing, the installer asks and waits. With the folder there and the
  part not running (a folder left stale by a macOS upgrade) it stops at once, as the core does today (`:329`),
  and Apple is not asked: a request on a Mac that has the folder brings no box **[record: pass 2]**. Its
  sentence, then and when the wait returns 2: "Apple's Command Line Tools are installed, but their swiftc does
  not run. Update them in Software Update, then paste the line again.", exit 1.
- **The order in the launcher's installer** (3.4): its refusals first, the macOS test and the look at the
  record's folders among them, so that a Mac it refuses never gets Apple's box; then the ask; then the
  record's folders are made; then the wait; then the compiler check; then the pictures; then the build. **The
  overlap there is about nothing**: between the ask and the wait stand three `mkdir`s and a `cp`. The ask is
  first because the order is then the same in every installer, and the gain belongs to the games' installers,
  in a plan of their own (section 14). Under `--check` a game's installer asks nothing, as today
  (`common/install-core.sh:331`).
- **Not chosen:** asking through `softwareupdate` without Apple's box (it needs an administrator's password,
  which the installer has never asked for **[record: pass 1's platform lens]**), and needing fewer of the tools
  (a Python that is not Apple's, `nm` replaced, built apps: each a dependency or a published thing the project
  does not have).

### 3.3 The no-game form of the root `install.sh` (LFD3)

A new first word, `launcher`, beside `update`:

    /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)" 1launcher-install launcher

- It is tested for where `update` is, before the test of the first word (`install.sh:78`), in a branch of
  its own, so that the lines for a game and for `update`, on which the older mutants of
  `common/test-bootstrap.sh` are anchored, keep their text. Pass 1's builder typed a branch into a scratch
  tree: the existing tests stayed green and the older mutants red **[record]**. One way that leaves every
  existing line as it is **[inferred]**: a mark, and `0` in the ID's place as `update` has it; a block for a
  checkout after the ref rule (`:96`) and before the checkout's path for a game (`:98`); and a block after
  the fetch, beside `update`'s (`:138`).
- It takes a ref and nothing else, as `update` does: `install.sh launcher [<ref>]`. An option after it is a
  usage error, exit 2, nothing fetched.
- **The ref passes the ref rule** of `install.sh:93-96`, the same lines that judge a game's ref: `launcher
  a..b` is "not a branch, tag or commit of this repository", exit 2, nothing fetched. `launcher <ref>` fetches
  that ref and no other.
- Fetched, it needs `common/install-launcher.sh` in what it fetched (else: "This version of 1launcher has no
  installer for the launcher. Paste a game's installer line from the guide instead.", exit 1), exports
  `L1_FETCHED_REF` and `L1_FETCHED_COMMIT`, and runs that script with no argument, returning its exit code.
  With a ref, the root `install.sh` of one version runs the launcher's installer of another: so that script's
  path, its call with no argument and its exit codes are a contract between versions, as the driver's are
  (section 9).
- From a checkout it fetches nothing and runs the checkout's `common/install-launcher.sh` ("Using this
  checkout of 1launcher (nothing is fetched)."), unlike `update`: a maintainer builds the window this way.
  A ref given there is judged by the ref rule and then not used, exactly as a game's is from a checkout
  (`install.sh:98-108` never reads it) (RC11).
- **What changes for the lines that exist: nothing.** A first word of digits takes the same path as today,
  line for line. `update` takes the same path. With no word the script still fetches nothing and exits 2; its
  words gain one line, after the usage line and **only when the word is empty**: "To install the launcher,
  which lists the games: the word launcher." The usage line (`install.sh:89`) is shared with "not a Steam app
  ID", which does not get the new line. Every other word is still "not a Steam app ID".
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
update. It takes no option: any argument is a usage error, exit 2. **It is built in two steps.** LF2 builds
everything below but the lock; LF4a adds the lock, and each of its lines below is marked "(LF4a)". Between
the two steps the script names no function of the lock, so the fallback release of section 11 holds a script
that is whole.

1. **Refusals**, before anything is asked or made.
   - As root: the core's sentence (`common/install-core.sh:95`), exit 1.
   - Its own files (`paths.sh`, `updates.sh`, `tools.sh`, `fetch.sh`, `fetch-art.sh`, `make-launcher-app.sh`,
     `launcher-window.swift`, `games.tsv`, `game-art.tsv`) missing: "The installer's own files are gone (macOS
     clears old temporary files).", exit 4.
   - **This Mac** (LFD12). Each line below is the installer's own; each game's own check decides for that
     game (Cities: Skylines II cautions on Intel, Surviving Mars stops:
     `cities-skylines-2/scripts/setup.sh:248-254`, `surviving-mars-relaunched/scripts/setup.sh:60-63`).
     - macOS below 14: "This Mac has macOS `<version>`. 14unch3r needs macOS 14 or later, and so does every
       game it lists. Update macOS, then paste the line again.", exit 3.
     - macOS 14 to 25, no stop: "CAUTION: macOS `<version>` is older than anything this project has been run
       on (macOS 26 and 27). 14unch3r may work; each game checks this Mac for itself when it is installed."
       It is modelled on the setups' own (`cities-skylines-2/scripts/setup.sh:262`,
       `surviving-mars-relaunched/scripts/setup.sh:77`).
     - A version that cannot be read, no stop: "CAUTION: the macOS version could not be read, so this Mac
       cannot be compared with what has been tested.", the setups' sentence
       (`cities-skylines-2/scripts/setup.sh:258`, `surviving-mars-relaunched/scripts/setup.sh:67`).
     - An Intel processor (`sysctl -n hw.optional.arm64` is not 1, the setups' own test), no stop: "CAUTION:
       this Mac has an Intel processor. Nothing of this project has been run on one. 14unch3r may work; each
       game checks this Mac for itself when it is installed." It is modelled on Cities: Skylines II's
       (`cities-skylines-2/scripts/setup.sh:253`).
   - **The record's folders, looked at and not yet made.** The folder that holds `_update`, then `_update`,
     then `_update/installed`: each one that is there must be a real folder of the player's own that group
     and others cannot write to (the setups' test, `cities-skylines-2/scripts/setup.sh:347-352`). One that is
     not: "`<folder>` is not a folder of your own that only you can write to. In Terminal: chmod go-w
     `<folder>`, then try again.", exit 1, with nothing written and Apple not asked. The folder is printed in
     full and inside double quotes in the command, since its path holds a space.
   - **(LF4a) Another install or an update is running** (3.8's lock, looked at and not yet taken; with no
     record's folder nothing can be running): "An install is running in another Terminal window (process
     `<n>`). Wait for it to finish, then paste the line again." or "An update of 1launcher is running in
     another Terminal window (process `<n>`). Wait for it to finish, then paste the line again.", exit 3. Not
     under an update: there the driver holds the update's lock itself (3.8 says when `L1_UPDATE=1` is
     believed).
2. **Apple's Command Line Tools: judged, and asked for when absent** (3.2). The folder there and `swiftc` not
   running: the Software Update sentence, exit 1, and no request. The folder absent: the ask.
3. **The record's folders, made.** The three of step 1, the parent first: the missing ones are made with
   `mkdir` and `chmod go-w`, as both setups do (`cities-skylines-2/scripts/setup.sh:347-378`,
   `surviving-mars-relaunched/scripts/setup.sh:194-203`). **(LF4a)** Then the install's lock is taken (3.8; if
   it cannot be, or an update's lock is live by then, step 1's sentence and exit 3). Then `common/updates.sh`
   is copied to `_update/updates.sh`, written beside and renamed. All of it before the build, so that the
   first window already has `L1UpdateDir` (`common/make-launcher-app.sh:132-137`).
4. **Apple's Command Line Tools: the wait** (3.2), only after an ask, with the 60 minutes and the sentences of
   the core. No tools in time: "Apple's Command Line Tools are not installed yet." and "Paste the line again:
   it carries on from here.", exit 4. The tools there and `swiftc` still not running after the settle: the
   Software Update sentence, exit 1.
5. **The compiler check** (3.2): below Swift 5.9 it says so and stops, exit 3.
6. **The pictures** (3.10): `bash common/fetch-art.sh`, whose exit code is not read. It fetches each game's
   picture that is not there yet, says one line for one it could not fetch, and never stops this script.
7. **The build.** `bash common/make-launcher-app.sh`. Its exit 3 (skipped: `swiftc` or the source is missing,
   or the compile failed, `common/make-launcher-app.sh:61-63`, `:71-73`) is a failure here, exit 1, with its
   line shown and the sentence of 3.2 that names each game's own line and the guide's address: for a game's
   setup the window is an extra, here it is the whole point. The builder prints nothing while it compiles, so
   the installer says first: "Building 14unch3r. This can take a minute; nothing is printed meanwhile."
8. **The stamp.** The launcher's own stamp (3.5), written only after a build that worked.
9. **The close.** **(LF4a)** The lock is released first, before the window is opened: a window that opened
   under a live lock would answer every click on a game with "An install is running". Then "Done. 14unch3r is
   in Applications: open it and choose a game. You can close this window." and `open
   ~/Applications/14unch3r.app` (LFD6). With `L1_UPDATE=1` the line is "Done. 14unch3r is rebuilt.", with no
   word about the Terminal window, which the update's own closing line speaks of (`common/updates.sh:328`),
   and the app is not opened. For these two things the variable alone decides, from LF2 on; only the lock asks
   for a live `updating` beside it (3.8). On a signal: the core's "Stopped." line with "Paste the line again:
   it carries on from here." **(LF4a)** The lock is released at every other exit too, by a trap on EXIT that
   the traps on INT, TERM and HUP reach, in the core's form (`common/install-core.sh:87-93`).

Exit codes: 0 done, 1 failed, 2 an argument, 3 will not go on, 4 cannot go on by itself. They are a contract
with the root `install.sh` of another version (3.3, section 9).

- **A first build that fails leaves `_update/updates.sh` and no stamp.** The state is then `none`, nothing is
  asked of GitHub and nothing is offered; pasting the line again carries on. Accepted, and said.
- **It does not keep the Mac awake.** A game's installer starts `caffeinate` (`common/install-core.sh:297`)
  because it downloads for hours. This script downloads two small pictures; Apple's download is Apple's own
  process, and the wait goes on after a sleep (RC16).

### 3.5 The record, the update, and how a new game arrives (LFD5)

**The launcher gets a stamp of its own.** A new file `_update/launcher`, one line in the form of a game's
stamp: the line it follows, the version, the commit, the time (`docs/plans/built-in-update.md`, 3.1), read
and matched by the same rule. It is not in `installed/`, whose names are app IDs. `common/updates.sh` gains:

- `l1u_stamp_launcher <tree root>`, which writes it, as `l1u_stamp` writes a game's (`:132-146`);
- `l1u_stamp_of_launcher`, its reader: it prints the line and the version, or returns 1 when the file does
  not count. `l1u_stamp_of` cannot serve: it takes an app ID and nothing else (`:167`);
- in `_l1u_stamps`, one more row for the launcher's stamp, whose first field is the word `launcher` where a
  game's row has its app ID. `_l1u_state` skips only a row with an empty first field (`:190`) and reads the
  line and the version of every other, so the state's rules count the launcher with no further change: a Mac
  with the launcher alone on `release` is `unknown`, then `current` or `ready`, and is asked once a day like
  any other; a launcher built from a checkout makes the Mac `manual`; the lowest version among the launcher
  and the games is "installed". Pass 1's builder typed the row in and saw those three states **[record]**.

Nothing that exists changes its form: no state word is added, no line changes (1.4's contract). An older
`updates.sh`, put back by a setup from an older tag, does not see the file and calls a launcher-only Mac
`none`: nothing is offered there until the next setup. Accepted, and said.

**Who writes it, and the rule for a build that failed.** `common/install-launcher.sh` (3.4, step 8), and each
game's setup on the line after a build of the window that worked into `~/Applications` (not with `--dest`,
`SM_APP`, `--check` or `--mac-only`): the window that setup just built is that tree's. Without this, a game
installed from an older launcher would leave the launcher's stamp behind and the window would offer an update
a minute after an install.

**On that same line each game's setup fetches the pictures** (3.10; LF2): after a build of the window that
worked into `~/Applications`, and under the same four exceptions, it runs `bash common/fetch-art.sh` and does
not read its exit code. It runs the file only when the file is there: each installer has tested for it before
its setup (3.10), and a checkout holds it. Not under `L1_UPDATE=1`: in an update the driver fetches once for
the whole run (below), where N setups would each try, and each wait out an unreachable server. So a game's own
pasted line on a Mac with nothing brings the window and its pictures, as the launcher's line does (RC21).

**The stamp is written only by a build that worked** (RC10). Today a setup never counts the window's build as
a problem (`cities-skylines-2/scripts/setup.sh:531-532`, `surviving-mars-relaunched/scripts/setup.sh:248`),
and that stays true of the setup's own exit code. But with a stamp the build now counts for the state: a
compile that fails, say after a macOS upgrade left old tools behind, leaves the older stamp as it is, and the
Mac stays `ready` until a build works. That is the truth, the window there is the old one, and it is said
where it happens:

- the setup, after its "not built" line: "14unch3r stays at `<the older version>`. It will go on offering
  this update until it can be built: the line above says why." (only when an older launcher stamp is there);
- the update's driver, whose launcher step then runs `common/install-launcher.sh` itself, sees it fail and
  counts it: the closing block names 14unch3r as not rebuilt, "Not everything was updated", exit 1. So one
  update with N games set up tries the compile N + 1 times. Accepted.

A Mac with no launcher stamp at all (set up by `v0.3.1` or earlier) is as today when its build fails: no
stamp is written, and the state is judged from the games alone.

**The update's driver** (`common/update-games.sh`) gains one step after its walk of the games.

- **Its own test that the launcher is there**: `~/Applications/14unch3r.app` is a real folder and not a link,
  has no `Contents/SharedSupport`, and its `Info.plist` carries the builder's identifier,
  `local.1launcher.window`. The builder's own test cannot serve: `own_app`
  (`common/make-launcher-app.sh:46-53`) returns 0 for an app that is absent, and the builder is a script that
  cannot be read with `.`. A source gate in the driver's test holds the identifier equal to the builder's
  `ID=` line (`:27`).
- **The pictures, first and always.** When that test finds the app, the driver runs `bash
  <tree>/common/fetch-art.sh` before it reads any stamp, and does not read its exit code. Should that file
  be gone (macOS clears old temporary files), the step is passed over without a word; the driver's own test
  of its files (`common/update-games.sh:33`) keeps its text. No rule below can skip it: not a launcher that a
  game's setup has just stamped, which is every ordinary update of a Mac with a
  game; not a launcher on another line; not a Mac from `v0.3.1` with no launcher stamp. When every picture is
  already the file its row names, the step makes no request (3.10). This is how a player coming from `v0.3.1`,
  and the tile of a game added in a later release, get their pictures. With no app it is not run: there is no
  window to draw them.
- no launcher stamp: nothing more is done for it and nothing is said (a Mac from `v0.3.1`, whose games' setups
  write the stamp at this update);
- a stamp, and neither the app nor a game set up: the stamp is removed, as a game's is
  (`common/update-games.sh:98-103`): an update does not bring back what the player removed;
- a stamp on another line than the one fetched: "14unch3r: set up from `<line>`, so it is left as it is.",
  counted as left;
- a stamp newer than what was fetched: "14unch3r is at `<version>`, newer than what GitHub sent (`<T>`). Left
  as it is.", counted as left, as a game's is (`:114-116`);
- a stamp already at the fetched version (a game's setup wrote it in this run, or nothing is newer): the
  launcher's installer is not called, since the window is that version's already, and the launcher counts as
  up to date. The pictures step has run by then, above;
- else `bash <tree>/common/install-launcher.sh`, counted like a game's installer: 0 updated, 3 left, any
  other code failed.

**The closing block** (`:147-157` today). "Everything is up to date: 1launcher `<T>`." is said, with exit 0,
when nothing was left and nothing failed and either something ran or the launcher is here with its stamp at
the fetched version: so a launcher that is current, on a Mac with no game, gets that line and exit 0. "No game
is set up on this Mac.", exit 3, is said only when neither a game nor the launcher is here. A launcher left on
another line or as newer: "Not everything was updated. Do what the lines above say.", exit 3. A launcher whose
installer failed: exit 1.

The window's sentence for the update (`Look.updateText`, `common/launcher-window.swift:815`) becomes true of
a launcher-only Mac: "Update opens Terminal and runs the installer again for 14unch3r and each game set up
here. It may ask you a question there."

**"Set up" has two meanings, and both stay.** To the driver a game is set up when its wrapper has a prefix
and the game's program (`common/update-games.sh:82-91`). To the window it is set up when its app is in
`~/Applications` (1.3). They differ for a game that was downloaded and whose setup never finished: a wrapper
with the program, no app, no stamp. The window shows it as "Install not finished. Click to carry on." (3.7).
The driver counts it as set up, finds no stamp, and says its sentence of today, "set up by a version that
keeps no record. Paste its installer line once", counted as left, exit 3 (`:106-108`). Both lead to the same
act, the game's installer run once more; the driver's sentence keeps its text (RC18).

**So a new game arrives like this.** It is released: a folder, a row, a row for its picture, a version heading
that rises. Within a day each installed launcher's check reads the heading (1.4) and shows its foot line; the
sheet's notes are the changelog, which names the game. Update rebuilds the window with the new table, and the
driver's launcher step fetches the new picture whichever script rebuilt the window (above), and the game is a
tile. This is the chain the update already has (`docs/plans/built-in-update.md`, 3.9); what this plan adds is
that it also runs on a Mac with the launcher alone, and that the tile installs.

**The alternative**, fetching the table of games in the daily check so that a new game shows before any
update: not recommended. It would be a second file read from the network into the window, with titles and
addresses that are then shown and opened; the window an old launcher would show the tile in could be too old
for what the new game needs of it; and an installed Mac would learn of a release by two routes that can
disagree. The update is one route, and the player reads what changed before saying yes.

### 3.6 The contract a game meets

Most of it exists and is only written down here; rows 7 to 10 are new as rules. A new test,
`common/test-game-contract.sh` (LFT7), holds what can be held without running anything of Wine.

| # | A game provides | Where it is read today |
|---|---|---|
| 1 | A row in `common/games.tsv`: exactly four tab-separated fields; a Steam app ID of digits that never changes; a folder matching `^[a-z0-9][a-z0-9-]*$`; a title (a label); a guide's address starting `https://github.com/` | `install.sh:30-32`; `common/update-games.sh:135`; `common/launcher-window.swift:467`, `:495` |
| 2 | A row in `common/wrappers.sh`: `l1w_row` (the wrapper variable, the old names, the game's program under the prefix) and its ID in `l1w_games` | `common/wrappers.sh:27-47`; `common/update-games.sh:82-91` |
| 3 | `<folder>/scripts/install.sh`: sets the core's settings and functions, reads `common/install-core.sh`, calls the stages in order; makes its wrapper with the game's marker; every step skipped when done, so that a run with no option is both the install and the update; before its setup it tests that the pictures' files are there (`common/fetch-art.sh`, `common/game-art.tsv`, `common/fetch.sh`), with setup's other files | `common/install-core.sh:8-26`, `:363` |
| 4 | Its options: `--check` (starts, downloads and changes nothing), `--yes`, `--no-setup`. Its exit codes: 0, 1, 2, 3, 4, and 5 only if its setup can finish without every fix | `cities-skylines-2/scripts/install.sh:8-18` |
| 5 | `<folder>/scripts/setup.sh`: `--mac-only`, `--check`, `--yes`; builds the game's app in `~/Applications` with `L1Role` `game`, `L1SteamAppID` and `L1Prefix`; builds 14unch3r and, when that build worked, writes the launcher's stamp and runs `common/fetch-art.sh` for the pictures (not under `L1_UPDATE=1`); deploys `updates.sh` and `update-dir`; writes the game's stamp; asks nothing optional under `L1_UPDATE=1` | `docs/plans/built-in-update.md`, 3.3; `docs/plans/launcher-window.md`, 2.1; 3.5 here |
| 6 | Its launcher holds the shared blocks | `common/test-launcher-parity.sh` |
| 7 | **What it may ask the player.** Only in Terminal, only when its input is a terminal, each answered by `--yes`. Never a password, never `sudo` (the core refuses root). Four kinds, and what each does when nobody answers: **consent** before something of a third party's is fetched under a licence, and **Rosetta**: stop, exit 3. **A Mac outside what was tested**, "Press Return to continue": it goes on (`cities-skylines-2/scripts/setup.sh:106-109`). **An optional extra** (the Desktop shortcut, `:566-575`): the answer is no, and it is not asked under `L1_UPDATE=1`; it is asked in an install started from the window, which is no update. Every question is counted in a header line of the file that asks it, in the form `# Terminal questions: <n>`, which LFT7 reads. LF6 adds the line to five files; their counts today, by LFT7's rule **[read]**: Cities: Skylines II's installer 0 and its setup 2 (`cities-skylines-2/scripts/setup.sh:108`, `:575`), Surviving Mars's installer 1 (`surviving-mars-relaunched/scripts/install.sh:150`) and its setup 1 (`surviving-mars-relaunched/scripts/setup.sh:86`), the core 1 (`common/install-core.sh:312`). What the player does in other windows (Steam's sign-in, its Install button) is said in `words_play` and the core's words | new as a rule; true of both installers today (1.2) |
| 8 | **Its needs as plain words.** `WORDS_NEED` and `NEED_GB` are one-line literals with no `$` and no backtick, so that a later slice can show them before a yes (section 11, slice 2) | new as a rule; true today (`cities-skylines-2/scripts/install.sh:32`, `:36`; `surviving-mars-relaunched/scripts/install.sh:36`, `:40`) |
| 9 | **The lists a game joins, all of them.** Besides its row in `common/games.tsv` (row 1): its ID in `l1w_games` and its row in `l1w_row` (row 2; `common/wrappers.sh:47`); its folders outside the repository in `common/paths.sh` (`:28-31` holds one pair per game today); and its picture's row (row 10). The window knows a game only by its row in `common/games.tsv`, and the installer is found by the root `install.sh` from the ID: nothing in the window or the tool names a game | new as a rule; pass 1's draft said no second list existed, which was false |
| 10 | **Its picture.** A row in `common/game-art.tsv` (3.10): the app ID, an address on one of the hosts the row rule names, the size in bytes (at most 1,048,576), the sha256 | new |

Row 2 is a second table keyed by the ID, held in code. It stays as it is: joining it with `games.tsv` would
change the shape of a file that three programs read with "exactly four fields" (1.1), and a root `install.sh`
cached for five minutes at a move of `release` would read the new shape with the old rule.

**A row in `common/games.tsv` now means that the window offers the game.** Until this plan a row only made an
ID findable. So `CLAUDE.md` gains a rule in step LF6: no row reaches `release` before the game's installer
works there, and no row is ever removed (a row's first field already never changes).

### 3.7 What the window shows (LFD4)

Four states of a tile, and where each comes from:

| Shown as | When | Read from |
|---|---|---|
| A game, as today (`ready`, `absent`, `busy`) | An app with `L1Role` `game` and the ID is in `~/Applications` | The app's `Info.plist`, Steam's manifest and the prefix's lock (1.3). Unchanged |
| **Not set up** | The table has the game, no such app is there, and no wrapper in `~/Applications` carries the game's marker | The bundle's `games.tsv`; `markedWrapper` (1.3) |
| **Begun** | No such app, and exactly one wrapper carries the game's marker | The wrapper's `Info.plist`: `L1Role` `game-wrapper` and `L1SteamAppID` |
| **Installing** | No such app, the install's lock is live, and the file beside it names this game (3.8) | `_update/installing` and `_update/installing-game`, and nothing else |

- **Their names.** `enum State` (`common/launcher-window.swift:44`) gains three cases, printed by `--list` as
  `not-set-up`, `begun` and `installing`. The case `owned` stays and keeps its meaning with one more word: not
  set up, and a cache says the account has the game. So the line `--list` prints for today's kind of offer
  does not change (RC12). The role of all four is `offer`.
- **`--list` and the other text modes.** Today `--list` takes `--games` and no `--update-dir`
  (`common/launcher-window.swift:1518-1524`). Its new form: `--list [--games <tsv>] [--update-dir <dir>]
  <folder>...`. With `--games` it prints one offer row for every game of the table that has no app, in the
  state the files give; with `--update-dir` the install's lock is read there, and without it no row is
  `installing`. `--grid` and `--act` already take both options (`:23-24`).
- **The new tiles are in the first `reload()`.** They are built from files alone: the table, the folders'
  marked wrappers, the lock. Today's offers come later, when a child has answered whether the account owns
  the game (`askOffers`, `:1712-1722`); that question stays where it is, and its answer changes one thing, a
  tile's second line. No tile appears or moves when it arrives.
- **"Installing" is read from the install's lock only**, never from a wrapper's `.launcher.lock`: that lock is
  also held by a game that is starting, and it lies in a folder other accounts can write to (below).
- **"Installing" is read when the window opens and each time it becomes the active app** (`:1724-1726`), and
  again at a click. An install that ends while the window is in front is shown as running until one of those.
- **The wrappers' markers say how far an install got; the app says it is finished; `_update/installed/` says
  which version, and nothing about a tile.** A stamp is written only when a setup has finished, and then the
  app is there too. The one case where they differ, a stamp and a wrapper with the game in it but no app (the
  player deleted the app), shows as "begun", and a click runs the installer, which rebuilds the app.
- **Every game of the table is listed, whether or not Steam says the account owns it.** On a Mac with nothing
  there is no Steam to ask (1.3), so "only what you own" would show an empty window to exactly the player this
  plan is for. The group's label becomes "Not set up on this Mac" (today "You also own",
  `common/launcher-window.swift:801`); it measures 123 points in the label's font **[record: pass 1's design
  lens]**. The installer's first lines already say that a Steam account that owns the game is needed
  (`common/install-core.sh:269`). A game that is set up is never hidden (D7, unchanged).
- **The picture (LFD4, decided 2026-11-26: "a ghosted or greyed out copy of the icon noting that it's not
  installed and can be").** A tile in one of the four offer states draws the game's own picture (3.10)
  through `greyed()` at `Look.dimAlpha`, 0.5, where today it draws the generic application icon the same way
  (`common/launcher-window.swift:1076-1079`). Only the icon is grey: the title is drawn at alpha 1 and the
  second line at `Look.secondAlpha`, 0.88 (`:1086-1095`), so the contrast lines hold. `dim()` (`:976`) is
  already true of every offer. When the picture is not there, the tile draws the generic application icon,
  greyed, exactly as today.
- **What is grey, said exactly.** A set-up game in the state `ready` or `busy` is never grey. A set-up game
  that is `absent` (not installed in Steam) stays grey, as today and as tested (D23,
  `docs/plans/launcher-window-look.md:564`).
- **A wrapper under an old name with no marker** (a Mac not yet renamed, `docs/plans/wrapper-names.md`) is
  not seen by the window, which reads markers only: such a game shows as "not set up" where "begun" would be
  truer. The click is right either way: the installer finds the wrapper by `common/wrappers.sh`'s rule and
  carries on. Said, and left.
- **Other accounts can change what a tile says (issue #29).** An installer-made wrapper has `Contents`
  writable by every account of the Mac (`docs/plans/wrapper-names.md:447-451`). Another account can therefore
  write or remove a game's marker, and so make this window show "Install not finished" for a game that was
  never begun, or "Not set up" for one that was (two wrappers marked alike count as none,
  `common/launcher-window.swift:228`). It cannot make a tile say "Installing": that comes from `_update`, a
  folder only the player can write to. A planted marker changes a tile's words and not what a click runs: the
  click asks, and a yes runs the game's installer from `release`, as for any tile. What that installer then
  does with a wrapper another account has changed is #29 itself, today's state for every pasted line, and not
  made worse here.
- **With no tile at all** (no table in the bundle) the window says what it says today.

**The selection and the keys.** Today the window selects among the set-up apps only: `defaultRow(apps, last:)`
(`common/launcher-window.swift:250-253`, called at `:1183`); the arrows need a selection (`:1269`) and Return needs
a chosen row (`:1255`). So on a Mac with the launcher alone the keyboard would reach no tile. With no app, the
first tile of the offers is selected: the pick at `:1183` becomes `defaultRow(apps, last:) ?? offers.first`. The
arrows then move among the offers as among any tiles, and Return or Space does what a click does. The group's help
(`:1151`) becomes "Click a game, or press Return, to start it or set it up."

**The words of a tile**, measured by pass 1's design lens to fit the tile at the window's fonts **[record]**:

| State | Second line | Tooltip's sentence | Spoken |
|---|---|---|---|
| not set up | "Not set up. Click to install." | "Not set up on this Mac. Click to install." | "`<title>`, not set up on this Mac, asks before it installs" |
| not set up, and a cache says the account has it | "In your Steam library. Click to install." | the same as above | the same as above |
| begun | "Install not finished. Click to carry on." | "Install not finished. Click to carry on." | "`<title>`, install not finished, asks before it carries on" |
| installing | "Installing in Terminal." | "Installing in Terminal." | "`<title>`, installing in Terminal" |
| any of them, with no tool (below) | "Not set up. Opens its guide." (today's) | today's | today's (`:971`) |

**What a click does is one pure function, `clickAnswer`**, as `sheetAnswer` is for the update (`:729`). Today
the choice is made inside `startChosen` (`:1766-1773`), which no text mode can build. The function takes the
row, the update's state as the window holds it, whether a tool is there, the title of a game in use if any,
and whether an install's lock is live, and returns one name; `--act start` prints that name, and the window
does what it says. For a tile that is not set up or begun, the first line that applies, in this order and no
other (a Mac that is `manual` with an install running gets line 2, not line 4):

1. **No tool** (no `L1UpdateDir`, or no `updates.sh` there): `guide`. The tile opens its guide, as an offer
   does today, and its words say so. Nothing is taken away from such a Mac.
2. **The state is `manual`**: `tell-manual`, at once, with no question first, since the window knows the state
   before the click. "`<title>` is not installed from this window on this Mac." / "14unch3r or a game here was
   set up from a checkout or a named version. From a checkout: bash `<folder>`/scripts/install.sh. Otherwise
   paste the game's line from its guide." `<folder>` is the game's folder, the second field of its row in the
   bundle's table. (LFD8)
3. **The state is `ready`**: `tell-update-first` (RD4). "Update 1launcher first." / "A newer version is out.
   Click the line at the foot of this window to update, then click the game again."
4. **An install is running** (the lock is live, for any game): `tell-installing`. "An install is running in
   Terminal." / "Only one install runs at a time. Its Terminal window shows how far it is; click this game
   again when it has finished."
5. **A game is in use**: `tell-quit-first`. "Quit `<title>` first." / "Installing a game needs Steam, and only
   one Steam at a time can use your account. Quit `<title>`, then click the game again."
6. **Else** (the state is `unknown`, `current`, `none` or `off`, or the tool gave no state): `ask-install`,
   the sheet below. A tile that is `installing` never gets here: line 4 stands before it. In `off` the state
   word hides a stamp on another line (1.4), so the window cannot know there that the Mac is on a checkout: it
   asks, and the tool, which reads the stamps itself in `off`, refuses with its sentence (3.8).

The four sheets of lines 2 to 5 have two buttons: "OK", the first and the default, and "Read the Guide", which
opens the row's address (RC17). **A short sheet never answers `open`:** its answer is `nothing` for the first
button and for Escape, and `guide` for the second, by the same pure function as the asking sheet's, which is
given the sheet's name.

**The sheet that asks** (LFD4: "clicking the icon should prompt and ask the user if they're ready to install
the game"). Nothing runs before its answer.

- Message: "Install `<title>` now?" For a begun game: "Carry on installing `<title>` now?"
- Text: "Terminal opens and runs the game's installer, fetched now from GitHub; it may also bring a newer
  14unch3r. It says first what the game needs, and may ask you a question there. It waits while you sign in to
  Steam and the game downloads. You can stop it at any time; open 14unch3r and click the game again to carry
  on."
- Buttons, the safe one first and the default, as every sheet of the window has it: "Not Now", "Install"
  (begun: "Carry On"), and "Read the Guide".
- **This is the window's first sheet with three buttons.** It is recorded in
  `docs/plans/launcher-window-look.md` and captured at LFL1. The alert's own key loop is left as it is: the
  update's sheet joins its first and its last button into a loop with the notes (`:1869-1873`), which with
  three buttons would pass the middle one by. Escape gives the first button, as in every sheet (the monitor).
- **Its answer is a pure function too, `installAnswer`**: given the sheet's name and a button, only the second
  button of the asking sheet gives `open`; its third gives `guide`; the first and Escape give `nothing`.
- **The text modes**, named after the update's (`--update-sheet`, `--update-answer`, `--update-open`,
  `common/launcher-window.swift:25-28`): `--install-sheet <name>` prints a sheet's message, text and buttons;
  `--install-answer <name> <first|second|third|escape>` prints what `installAnswer` gives; `--install-open`
  runs the tool with `--install <ID>` and prints `quit`, or the failure's sentence. The function that makes the
  rows of the games that are not set up, from the table, the folders' marked wrappers and the lock, is
  `tableOffers`, beside today's `offerRows` (`:483`), which keeps the question of ownership.
- On `open` the window asks the tool to open the install (3.8), off the main thread as for the update, and
  quits when it answers `opened`. `failed` and a sentence: that sentence, with the guide one click away.
- **Every other answer is one sentence.** `runChild` (`:399-402`) returns nothing alike for an exit that is
  not 0, for the time limit and for a crash, so the window cannot tell an older tool from a broken one:
  "This Mac's update tool could not start the install. Paste the game's installer line from its guide.", and
  the guide.

**The size.** `docs/plans/built-in-update.md`, UD10, measured a tile at 174 points and the window's limit at
600 (`Look.most`, `:777`). With the new group the window stays inside 600 until there are two rows of apps and
two rows of games not set up, which measure 654 and scroll **[record: pass 1's design lens]**. With two games
that is far off.

**Starting a game that is set up while an install runs.** The install's Steam is one more Steam on the
account: a set-up game started meanwhile pushes it off, which is LFD13's own reason. `blocker` (`:263-267`)
sees only rows, and the wrapper being installed has no app, so today's rule would start the game without a
word. So a live install's lock counts as a blocker for every start of a game or of the Steam app, after the
rule for a game in use: the window shows its question sheet, as it does for a busy game (`ask`, `:1775-1790`),
with the same two buttons, "Don't Start" the first and the default, and "Start Anyway". (RC26) Its words: "An install
is running in Terminal." / "Starting `<title>` now takes the installer's Steam offline, and the download
stops until the installer is opened again. Wait for the install to finish, or start anyway." `--act start`
prints `ask-install-running` for it, and `--second` gains nothing: it has no `--update-dir` to read a lock
from. Built in LF5b, with the lock's rule in Swift.

The words above are published text. Pass 2's reviewer of the words read the first rework's and replaced six of
them (lines 2 to 5 above, and sentences of 3.4, 3.5, 3.8 and 3.10); those replacements are in place, word for
word. What rework 2 wrote itself, and nobody has read, is listed at RC27.

### 3.8 One install at a time: the lock, and `updates.sh --install <Steam app ID>`

**The lock is the installer's, not the window's.** Pass 1's draft had the file handed to Terminal take a lock
per game. That was too late (the tool had already answered and the window quit), too narrow (two games could
install at once: two Steams on one account), and it put a path with a space into a file that was to hold
constants. So:

- **One lock for any install: the link `_update/installing`**, in the launchers' lock form, as the update's
  lock is (`common/update-games.sh:46-58`): its target is the process number of the installer that holds it.
  The window can read it by the rule it has for a launcher's lock (`common/launcher-window.swift:153-165`: a
  link, a target of digits only, a process that answers).
- **Which game: a file beside it, `_update/installing-game`**, one line, the Steam app ID. **Every taker
  removes it right after it took the link**, whoever left it: a file left by a holder that was killed must not
  name its game under the next holder's lock. A game's installer then writes it beside its place and renames
  it over, so that no reader meets half a line, and removes it just before it lets the link go. It is read
  only while the link is live, as a plain file that is not a link, and its line is matched whole against the
  app ID's form. A file that is absent or does not match names no game: then no tile says "Installing", and a
  click still gets the sheet of 3.7's line 4. The launcher's own installer holds the link and writes no such
  file (RC1).
- **One rule, in `common/updates.sh`**, which is where every rule of `_update` lives: `l1u_lock_live <name>`,
  `l1u_lock_take <name>` and `l1u_lock_release <name>`, for the names `installing` and `updating`. The core,
  the launcher's installer, the driver and the tool read that file from their own tree (both games'
  installers already test that it is there: `cities-skylines-2/scripts/install.sh:113`,
  `surviving-mars-relaunched/scripts/install.sh:231`). The window holds the same rule in Swift, and one set of
  fixtures tests both (LFT13).
- **A take is proved by reading the link back.** After its `ln -s`, `l1u_lock_take` reads the link with
  `readlink`, and holds the lock only if the target is its own process number. Else it refuses. Two cases need
  it: a folder planted at the lock's name, into which `ln -s` would put a link and report success; and two
  takers that both found one dead holder, where the take-over's remove and link are two acts
  (`common/update-games.sh:53-54`) and a taker can find another's number where it meant to put its own. For
  the second case the read narrows the gap and does not close it **[inferred]**: a taker whose link is
  replaced after it read it back still believes it holds. What then stands is today's state, and the
  wrapper's own lock.
- **The driver's own lines that take `updating` keep their text, and gain one line before them.** Its mutants
  11 and 13 are anchored on `if ! take_lock; then` and `trap release_lock EXIT`
  (`common/test-update-games.sh:55`, `:57`; `common/update-games.sh:59`, `:63`). The one new line stands before
  the take: an `updating` that is not live by the rule below, the Mac's last start among it, is removed. Without
  it a number left in `updating` by a restart, now some other process's, would refuse every update (`:52`) and,
  through "update first" (RD4), every install from the window on a Mac that is `ready` (RC2, changed by rework
  2).
- **Live means:** the link's target is a process number; that process answers `kill -0`; and the link is not
  older than the Mac's last start. The last part is new. After a restart a number left in a link can belong to
  some other live process, and every install would be refused for as long as it lived. So the link's own time
  (`stat -f %m` on the link, which does not follow it: measured by the rework on a link whose target did not
  exist) is compared with the seconds in `sysctl -n kern.boottime` (its form, measured: `{ sec = <seconds>,
  usec = <n> }` and a date), and an older link is dead. A boot time that cannot be read leaves the first two parts
  alone. In Swift: `lstat` and `sysctlbyname`. A dead lock is taken over in the launchers' way
  (`common/update-games.sh:52-54`).
- **The boot rule compares two clocks, and it fails open.** The link's time is the file system's and the
  start's is the kernel's: a clock set back between a start and an install, or a link written with an old
  time, makes a live lock read as dead. Then a second install can start beside the first, which is today's
  state with no lock at all, and the wrapper's own lock and the wrapper maker's refusals still stand (below).
  The other way round, a dead lock read as live, ends at the next restart.
- **`sysctl` is run through a named variable, `L1_SYSCTL`** (default `/usr/sbin/sysctl`), as curl and `open`
  are through `L1_CURL` and `L1_OPEN`: every function of `common/updates.sh` that runs a program sets `PATH`
  itself (`:41`), so a stub first on a test's `PATH` would never be found.
- **When the core takes it:** in `core_begin`, after its refusals for a wrapper in use and a running game and
  before anything is downloaded, where it starts `caffeinate` today (`common/install-core.sh:296-297`). Not
  under `--check`, which changes nothing. Not under an update: the driver holds `updating` for the whole run
  and has already looked (RC4). **`L1_UPDATE=1` is believed only while an update's lock is live:** the
  variable alone, left in a shell or set by hand, takes no install out of the lock. With the variable set and
  no live `updating`, the core and the launcher's installer take the lock as in any other run. The core reads
  the one folder from `common/paths.sh`, as the driver does (`common/update-games.sh:36`), and makes the
  record's three folders by 3.4's rule when they are not there: a game's line pasted on a Mac with nothing has
  no `_update` yet. A folder that fails the test stops the install here, exit 1, with 3.4's sentence for it
  ("... is not a folder of your own that only you can write to. In Terminal: chmod go-w `<folder>`, then try
  again."); today the same Mac fails at the setup, after every download (RC3). `paths.sh`, `updates.sh` and
  `tools.sh` join the core's test of its own files (`:29`).
- **It is released at every exit.** The core has one trap on EXIT, `on_exit`, and its traps on INT, TERM and
  HUP all end in `exit` and so reach it (`common/install-core.sh:71-93`): Control-C, a closed window and a
  kill release the lock. The release goes beside the wrapper lock's (`:73`), under a mark of its own, not the
  variable `LOCK`, which `core_begin` unsets (`:278`) and `core_after_setup` rewrites (`:377`). A `kill -9`
  and a power cut leave the link: the dead-holder rule and the boot rule clear it.
- **A pasted line takes it too**, since it runs the same core. So do both ways of starting the same game
  twice.
- **Install and update exclude each other, both ways.** Each side takes its own lock first and then looks at
  the other's, so of two that start together at least one stops. The order, take and then look, is what makes
  that true, and a test holds it on each side (LFT13). Every sentence names the holder's process, as the
  core's line for a wrapper in use does today (`common/install-core.sh:291`).
  - The core, having taken `installing`, finds `updating` live: it lets go and stops, exit 3: "An update of
    1launcher is running in another Terminal window (process `<n>`). Wait for it to finish, then open the
    installer again."
  - The core cannot take `installing`: exit 3: "Another install is running in another Terminal window
    (process `<n>`). Wait for it to finish, then open the installer again."
  - `common/update-games.sh`, having taken `updating`, finds `installing` live: exit 3: "An install is running
    in another Terminal window (process `<n>`). Wait for it to finish, then update again."
  - `updates.sh --open` refuses while `installing` is live: `failed` and "An install is running in Terminal.
    Wait for it to finish, then update." Today it looks at the state only (`common/updates.sh:309-310`).
  - `updates.sh --install` refuses while either is live (below).
- **What is not covered.** A setup run by hand from a checkout takes no lock. A lock read as dead by the boot
  rule's two clocks is not held (above). The installer of `v0.3.1`, and
  every version before this one, takes none: an install started from one of them is not seen by the window or
  by a newer installer, and the older guards are all there is (the wrapper's lock,
  `common/install-core.sh:383-388`; the wrapper maker's refusals, `common/make-wrapper.sh:14-17`). That is
  what LFL2b runs (section 7); LFL8 is there so that the lock is seen before the release all the same.
  Between the tool's `opened` and the moment the installer takes the lock lie
  the two fetches, some seconds: a second click in that gap opens a second Terminal, whose installer is then
  refused by the lock.

**The option.** A new option of `common/updates.sh`, beside `--open`, and built like it (1.4). Its header's
line for the file `off`, "if it exists, nothing is ever fetched" (`:10`), is corrected in this step: `off`
switches off the daily check, and an update or an install the player clicks still fetches.

- The ID is matched whole against `^[1-9][0-9]{0,9}$` before anything is written. Anything else: `failed` and
  a sentence, nothing written.
- It refuses, with `failed` and one sentence each, nothing written and Terminal not opened:
  - the state `manual`: "14unch3r or a game here was set up from a checkout or a named version. From a
    checkout, run the game's scripts/install.sh; otherwise paste the game's line from its guide." (LFD8). The
    tool has the ID and no table, so it cannot name the folder as the window's sheet does;
  - **the state `off` with a stamp on a line that is not `release`:** the same sentence. In `off` the state
    word is returned before the stamps are read (`common/updates.sh:188`), so the tool reads the stamps' lines
    itself there (`_l1u_stamps`, the launcher's row with them): without this, switching the daily check off
    would make a Mac on a checkout install from `release`;
  - **a record folder that is not the default one:** the same sentence. The file the tool writes names no
    folder, and the installer it starts keeps its record in the default place of `common/paths.sh` (`:16`,
    `:32`): from a record anywhere else, a scratch one of a test or a live step among them, the install would
    write its lock and its stamps where this tool and its window do not look. The tool spells the default
    itself (the deployed copy has no `paths.sh` beside it), and a source gate holds its spelling equal to
    those two lines;
  - the state `ready`: "A newer 1launcher is out. Update first, then click the game again." (RD4);
  - `updating` live: "An update is running in Terminal. Wait for it to finish, then click the game again.";
  - `installing` live: "An install is running in Terminal. Its Terminal window shows how far it is.";
  - the record's folder not the player's own: "This Mac's record of versions is not a folder of your own that
    only you can write to. In Terminal: chmod go-w `<folder>`, then try again."

  The states `none`, `unknown`, `current` and `off` open, `off` only with every stamp on `release`: `off`
  switches off the daily check, and this is the player's own click.
- It writes `Install with 1launcher.command`, mode 755, into a new temporary folder
  (`1launcher-install.XXXXXX`): **constants only, but for curl's path and the matched number.** The file takes
  no lock and names no folder. It clears the screen, fetches the root `install.sh` of `release` into a file
  beside itself, judged by the answer's code as `--open`'s file does (`:322-324`), and runs `/bin/bash -c "$S"
  1launcher-install <ID>`: the published line for that game, word for word. So an install from the window and
  an install from the guide are one path from there on, lock and all.
- A fetch that fails (no answer, 404, 500): the installer is not run, one sentence ("GitHub could not be
  reached. Check the network, then open 14unch3r and click the game again."), exit 1.
- Its closing line, by the installer's exit code: 0, "Installed. Open 14unch3r to play. You can close this
  window."; 5, the same with "A Mac fix is not out yet for this build of the game: the lines above say more.";
  3 or 4, or a signal, "Not finished. To carry on, open 14unch3r and click the game again. You can close this
  window."; else "The install did not finish: the lines above say why. To try again, open 14unch3r and click
  the game." It removes itself and its folder at every exit.
- It hands the file to Terminal with `open -a Terminal` and prints `opened`, or `failed` and one sentence.

**An older tool.** A window built by this version, beside an `updates.sh` put back by a setup from an older
tag, gets a usage error for `--install`. The window reads that as no answer, like every other failure of the
tool, and says 3.7's one sentence for it.

### 3.9 Failure and resume

| What happens | What the player meets | Where from |
|---|---|---|
| The paste of the launcher line is cut, or the fetch fails | "GitHub could not be reached ..." or nothing run: the script is all functions and calls the last on its last line | `install.sh:28-29`, `:121-128` **[read]** |
| macOS refuses the pasted line ("Possible malware, paste blocked") | The player can override it; the guide says so. On which Macs: 1.5 | 1.5 **[record]** |
| The Mac is on a macOS below 14 | "This Mac has macOS `<version>`. 14unch3r needs macOS 14 or later, and so does every game it lists. Update macOS, then paste the line again.", exit 3, before Apple is asked for anything | 3.4 |
| The record's folder is not the player's own, or others can write to it | "`<folder>` is not a folder of your own that only you can write to. In Terminal: chmod go-w `<folder>`, then try again.", exit 1, before Apple is asked for anything; from a game's line, before anything is downloaded | 3.4, 3.8 |
| Apple's box cannot be opened | The other words of `tools_ask`, and the wait goes on | 3.2 |
| Apple's tools are not installed within 60 minutes | Exit 4, "Paste the line again: it carries on from here." | 3.4, the core's rule (`common/install-core.sh:339`) |
| The tools' folder is there and `swiftc` does not run (a stale folder after a macOS upgrade) | "Update them in Software Update", exit 1, at once and with no request to Apple | 3.2 |
| The tools arrive during the wait and `swiftc` does not run within two minutes | The same sentence, exit 1 | 3.2 |
| The tools are older than Swift 5.9 | "Update them in Software Update", exit 3 | 3.2 |
| A picture cannot be fetched, or is not the file the table names | One line that names the game; the tile shows the picture it had, or the generic icon; the install, the setup or the update goes on | 3.10 |
| The compile fails | Exit 1 with the compiler's first error and the sentence that names each game's own line and the guide's address. No app, no stamp; an older 14unch3r and an older stamp stay as they were (`common/make-launcher-app.sh:16-19`) | 3.4, 3.5 |
| The compile fails during an update | The Mac stays `ready`; the update says 14unch3r was not rebuilt, exit 1 | 3.5 |
| A game's install is stopped: Control-C, the Terminal window closed, the Mac restarted | "Stopped." in Terminal; the lock is released, or after a restart is older than the start and dead; Steam is left as it is; at the next open the window shows the game as begun, or as not set up if no wrapper was made yet, and a click carries on | 1.2, 3.7, 3.8 |
| The installer stops at a question (exit 3) or cannot go on (exit 4) | Its own lines say why; the closing line says to click the game again | 3.8 |
| A game is running in another wrapper | The window's sheet says to quit it, before Terminal opens | 3.7 |
| A Steam for Windows is open in another wrapper and no game runs (the Steam app, S734M) | The window cannot see it: "A Steam app is never busy: nothing locks the store wrapper" (`common/launcher-window.swift:167`). The installer stops at the game's step, exit 3, and says which wrapper (1.2). Clicking again after quitting it carries on from there | 1.2 **[read]** |
| The macOS Steam app is open | **[not known]**: the installer does not look for it (1.2), and what then happens to the session was not read. LP3 | 1.2 |
| Less free space than the game needs | The installer's caution, and it goes on (1.2). Under 6 GB: the wrapper is not made, exit 1 | 1.2 **[read]** |
| The disk fills during the game's download | **[not known]** (1.2). LP2 | |
| A second click while an install runs | "An install is running in Terminal." and that only one runs at a time | 3.7, 3.8 |
| A game that is set up is started while an install runs | The window asks first, as for a game in use: "Don't Start", "Start Anyway" | 3.7 |
| A Mac in the state `off` that is on a checkout, and a click on a game | The window asks; the tool refuses after the yes, with the sentence for a checkout | 3.7, 3.8 |
| A click, or an update, while an install runs that an older version started | Not seen: the older installer takes no lock. The installers' own guards apply | 3.8 |
| An update is started while an install runs, or the other way round | The second one stops with its sentence, exit 3 | 3.8 |
| The window's tool is older than the window, or does not answer | "This Mac's update tool could not start the install. Paste the game's installer line from its guide." | 3.7 |
| The temporary copy of the repository is cleared by macOS during a long run | The installers' own sentence and exit 4; a click fetches again | `cities-skylines-2/scripts/install.sh:109-115` **[read]** |
| The window is opened again while an install runs, and the setup at its end rebuilds 14unch3r under it | **[not known]**: the bundle of a running window is moved aside and removed. The same can happen today with a pasted line. Read off the screen at LFL2b | 1.3 |

### 3.10 The games' pictures (LFD4)

James chose where the icon of a game that is not set up comes from: "the first option", fetched from Steam's
public artwork when the launcher is installed, held to a fixed size and checksum like the installers'
downloads. The repository holds no game art and gains none.

- **A table of its own: `common/game-art.tsv` (new).** Four tab-separated fields: the Steam app ID, the
  address, the size in bytes, the sha256. It is not a fifth field of `common/games.tsv`, whose four fields
  are a published shape that three programs insist on (1.1). A row is used only when every field matches
  whole: the ID as an app ID; the address as `https://`, then a host of a short fixed list, then `/` and plain
  characters (letters, digits, `.`, `_`, `/`, `-`); the size as digits, and at most 1,048,576, which is the
  most the window reads; the checksum as 64 hex digits. **The hosts are a list fixed after LP4**, which finds
  where Valve serves the image. The list stands in two places, the row rule of `common/fetch-art.sh` and LFT7,
  and a source gate holds them equal; a row for any other host is passed over. The contract's test holds that
  each row's ID has a row in `common/games.tsv` (LFT7).
- **One small file does the fetching: `common/fetch-art.sh` (new).** It is run, `bash common/fetch-art.sh`,
  and never read with `.`: it has three callers, each with a `say` of its own, and the setups' `say` takes two
  arguments (`cities-skylines-2/scripts/setup.sh:94`, `surviving-mars-relaunched/scripts/setup.sh:52`), so a
  file that printed through its caller's would print three ways.
  - *What it takes.* No argument (any argument but `--verify`, below, is one usage line with nothing
    fetched). From the environment: the record's folder, read from `common/paths.sh` of
    its own tree as the driver reads it (`common/update-games.sh:36`), and `L1_CURL`, which names a stub for
    the tests, as in `common/updates.sh`. Beside itself it reads `common/game-art.tsv`, `common/games.tsv`
    (for a game's title) and `common/fetch.sh` (for `sha`).
  - *What it does.* Nothing unless `_update` is there and is the player's own: it never makes `_update`, which
    each caller has made by then. It makes `_update/art` when that is missing, by the rule of the record's
    folders, and does nothing when `art` is there and is not such a folder. It removes temporary files of its
    own in `art` that are older than ten minutes, as the daily check does for its own
    (`common/updates.sh:222`). Then, for each row that passes the row rule: when `_update/art/<ID>` is a plain
    file that is not a link and has the row's size and checksum, nothing, **and no request**; otherwise one
    fetch.
  - *What it prints.* Nothing for a picture that is there or was fetched. One line for each picture it could
    not fetch (below). Nothing else.
  - *Its exit code.* 0, whatever happened: no caller reads it, and none can be failed by it. With a file of
    its own missing, or no record's folder, it prints nothing and exits 0.
  - *One more mode, for the maintainer:* `bash common/fetch-art.sh --verify` fetches every row's picture into
    a temporary folder of its own, keeps nothing and writes nothing into `_update`, prints one line per row
    (`<ID> ok`, `<ID> changed`, or `<ID> not reached`), and exits 0 only when every row is `ok`. It is the
    check that says when Valve has changed an image: run before a release is tagged (LF7), so that a row is
    corrected in that release and not found wrong by players. It is not part of
    `common/check-release-move.sh`: a changed image greys no tile and stops no install (RC22).
- **Who calls it: every route that puts a window on a Mac** (RC21). The launcher's installer (3.4, step 6).
  Each game's setup, after a build of the window that worked, and not in an update (3.5). The update's driver,
  always, when its own test finds the app, and before it reads a stamp (3.5). So a Mac with nothing gets the
  pictures whichever line was pasted first; a Mac set up by `v0.3.1` gets them at its first update; and a game
  added in a later release gets its picture at the update that brings its tile. A picture that is already
  there costs no request, so an ordinary update asks Valve for nothing.
  - Each game's installer tests that `common/fetch-art.sh`, `common/game-art.tsv` and `common/fetch.sh` are
    there before it runs its setup, with the installer's own sentence and exit 4, in a loop of their own: the
    line that tests `common/updates.sh` and `common/games.tsv` keeps its text, since mutant 74 of Cities:
    Skylines II's test is anchored on it (`cities-skylines-2/scripts/install.sh:113`;
    `cities-skylines-2/scripts/test-install.sh:181`).
  - A setup run by hand from a checkout fetches too: one rule for every route. Until now neither setup made
    a request of the network (1.2).
- **The fetch, written out.** `fetch` of `common/fetch.sh` cannot serve: it stops its caller on any failure
  (`die`, `:18-24`) and has no time limit, and a picture must never stop or hold up an install. The line, in
  the form of the daily check's (`common/updates.sh:225`):

      curl -q --proto '=https' --tlsv1.2 -sS --max-time 20 --max-filesize <size> --max-redirs 0 -o <temp> -w '%{http_code}' <address>

  with `<size>` the row's and `<temp>` a new file in `_update/art`. The answer is kept only when all four
  hold: curl exits 0; the answer's code is 200; the file's size is the row's; its sha256 is the row's (the
  two tests of `common/fetch.sh:21-22`, with that file's `sha`). No redirect is followed. Twenty seconds a
  picture is the most the step can hold a caller up (RC9).
- **A changed row keeps the old file until the new one verifies.** The answer is written to the temporary
  file and renamed over `_update/art/<ID>` only after the four tests. A fetch that fails removes the
  temporary file and leaves whatever was at `art/<ID>`: after a release that corrects a row, a Mac that is
  offline at its update keeps showing the picture it had.
- **Where it is kept: `_update/art/<Steam app ID>`**, a third folder inside the record's, made by the same
  rule. Not inside the app: 14unch3r is rebuilt by every game's setup and at every update
  (`cities-skylines-2/scripts/setup.sh:531-543`, `surviving-mars-relaunched/scripts/setup.sh:249-250`), and a
  picture inside the bundle would be gone after the first of those builds that could not reach Valve. The
  window already knows the folder, from `L1UpdateDir`.
- **What the window does with it.** For a tile in an offer state it reads `<update folder>/art/<ID>` as a
  plain file that is not a link, of at most 1 MiB (`readPlainFile`, as for every file it reads). **It bounds
  the picture's size in pixels:** the width and the height are read from the file's header before anything is
  decoded, and a picture over 1,024 pixels a side is passed over, since a small file can name a very large
  image **[inferred: the reading by `CGImageSource`'s properties was not tried]**. LP4 may lower that number.
  **It greys the picture once per `reload()`**, and holds the grey image with the tile; `draw` paints what is
  held. Today `greyed()` is called inside `draw`, at every paint (`common/launcher-window.swift:1077-1078`),
  which for the small generic icon costs little. A picture that is absent, too large or no image: the generic
  application icon, as today. The window does not check the checksum again: the folder is the player's own,
  and the tool the window runs lies in the same folder, so a checksum there would guard nothing the tool's
  place does not (RC9). `--grid` prints, as a new last field of a tile's line, where its picture came from:
  `art`, `generic` or `app`.
- **When the fetch fails**, the answer is not the file the table names, or the Mac is offline: nothing new is
  kept, and the file says one line for that game: "The picture of `<title>` could not be fetched; 14unch3r
  shows a plain icon for it while it is not set up. Pasting the line again tries again." Any pasted line and
  any update tries again. Never a stop, and no change to any caller's exit code.
- **Which picture, and its address: [not known], LP4.** Steam publishes several images per game, and this
  session could not look: which of them is the game's own icon, at which address, in which format and size,
  and whether its bytes are the same at every fetch (a checksum needs that) are measured by LP4 before the
  table is written. The tile draws the icon at 64 points (`Look.icon`, `:779`), so a picture under 128 pixels
  square will look soft: if Steam's nearest image is smaller, that is a finding for James before LF2.
- **What is new for a player's privacy.** A request to Valve's servers for a public image is then made by
  every route of the list above: the launcher's line, a game's own line, and an update, each only for a
  picture that is not on the Mac yet or whose row changed. Valve sees the Mac's address, the time, and curl's
  name as the program that asked. Every game's picture is asked for, so the request does not say which games
  the player has. It is said in three places: both guides and the root README (LF7's guide commit), and this
  release's section of `CHANGELOG.md` (LF6), which a player with an install reads in the update's sheet before
  the yes that makes the request. A game's installer already fetches Steam's own installer from Valve
  (`common/install-core.sh:31`).
- **A new thing the project depends on** (section 9): the addresses. If Valve moves or changes an image, the
  checksum fails: a Mac that has the old picture keeps it, a new Mac shows the generic icon, and a release
  corrects the row. `--verify` says so before a release is tagged.
- **A new game adds its row** (the contract's row 10).

## 4. Steps

Each step is one or more commits on a branch `launcher-first-install`, with its tests in the same commit and
every mutant of section 6 applied and seen red before the step is called done.

**The order of the build: LF0, LF1, LF2, LF3, LF5a, LF4a, LF4b, LF5b, LF6, LF7.** The steps keep their
labels and are written below in that order. LF5a, the listing, stands before LF4a, the lock, for two reasons.
The fallback release of section 11 is the first four code steps, LF1, LF2, LF3 and LF5a, and must be whole
without a line of the lock. And nothing before LF4a may call a function LF4a makes: so LF2's installer has no
lock and LF3's driver no look at an install's lock, and both gain them in LF4a, with the tests and mutants
that hold them. Pass 2 found the first rework's order, in which LF2 and LF3 had lock cases before the lock
existed, unbuildable.

**The transcript.** Any step that changes a line the installer, the core or the real setup prints in a case of
`cities-skylines-2/scripts/test-install.sh` ends with `test-install.golden` recorded again on purpose and the
difference read (1.2): LF2 and LF4a for certain, since they change the core; LF1 and LF3 if that file then
fails on its transcript.

- **LF0. The probes that gate** (section 7), before the code they gate. LP1 is measured in part (pass 1); its
  remaining conditions are met before LF1. LP4 is run before LF2 writes `common/game-art.tsv`. LP2 and LP3
  gate nothing here: what they find is the installers' to fix.
- **LF1. The record.** `common/updates.sh`: the launcher's stamp, its writer and reader, and its row in the
  state; both setups write it after a build of the window that worked, and say the line of 3.5 when one
  failed. `CLAUDE.md`'s line for `_update` names every new file and folder first (LFD9: `launcher`,
  `installing`, `installing-game`, `art/`), before anything writes them. Tests LFT3 (the stamp), LFT5 (the
  stamp).
- **LF2. The tools file, the launcher's installer without its lock, the pictures and the word.**
  `common/tools.sh`, and the core reading it at `common/install-core.sh:333-342`, with `TOOLS_PART_POLLS`;
  `common/install-launcher.sh`, every line of 3.4 that is not marked "(LF4a)"; `common/game-art.tsv` and
  `common/fetch-art.sh`, called by the launcher's installer and by both setups, and tested for by both games'
  installers (3.10); the root `install.sh`'s word `launcher` and the one new line for the empty word; the
  builder's `LSMinimumSystemVersion` of `14.0`. Tests LFT1, LFT2 (all but its cases marked "with LF4a"), LFT5
  (the pictures), LFT11, LFT14. **The step ends with the transcript recorded again:** the core changed, so
  `GOLDEN=record bash cities-skylines-2/scripts/test-install.sh` is run on purpose, and the difference between
  the old `test-install.golden` and the new is read line by line and named in the commit: every changed line
  must be one this step meant to change (1.2).
- **LF3. The update.** `common/update-games.sh`'s step for the launcher: its own test that the app is there,
  the pictures before any stamp is read, the stamp's rules, and the closing block. `Look.updateText`,
  `Look.checkoutText` and `Look.namedText` (section 10). No look at an install's lock yet. Test LFT4 (all but
  its case and its mutant marked "with LF4a").
- **LF5a. The listing.** Every game of the table is a tile from the first `reload()`, in the states not set
  up and begun, made by `tableOffers`; the picture, bounded and greyed once per reload; the group's label; the
  selection with no app; the group's help. A click opens the game's guide, with today's words, and needs no
  tool. No tile is `installing` yet: the lock's rule in Swift comes with LF5b. Tests LFT6 (its listing cases
  but the one marked "with LF5b"), LFT10 (but its case of a running install), LFT12 (but its last case).
- **LF4a. The install's lock.** The three functions in `common/updates.sh`, with `L1_SYSCTL` and the read-back
  after a take; the core takes the lock in `core_begin` and releases it in `on_exit`; **the launcher's
  installer gains every line of 3.4 marked "(LF4a)"**: the look in its refusals, the take in step 3, the
  release before the window is opened and at every exit; **the driver gains its look at `installing`** and
  the one line that removes a stale `updating`; `--open` refuses during an install. Both setups are not
  touched by this part. Tests LFT13 (but the window's cases), **and the cases and mutants of LFT2 and LFT4
  that are marked "with LF4a"**. The core changed again, so this step too ends with the transcript recorded
  again and its difference read.
- **LF4b. The tool's `--install`**, and the corrected header line for `off`. Tests LFT3 (`--install`), LFT8.
- **LF5b. The sheets and the install.** The state installing; `clickAnswer`; the sheet that asks and the four
  short sheets, with `installAnswer`; the question before a set-up game is started while an install runs; the
  words of 3.7 for a Mac with a tool; the three text modes. Tests LFT6 (the rest), LFT10 (its case of a
  running install), LFT12 (its last case), LFT13 (the window's cases).
- **LF6. The contract and the words.** `common/test-game-contract.sh` (LFT7), and the header line `# Terminal
  questions: <n>` in the five files it reads (3.6, row 7); `CLAUDE.md` (the layout table's rows for
  `install.sh` and `common/`, § Published addresses, the rule for a row of the table, and under "Releases" the
  line that `bash common/fetch-art.sh --verify` is run before a tag); the statements of section 10;
  `CHANGELOG.md` under Unreleased, which says what a player will notice and names the request to Valve and
  what Valve sees (3.10); this plan's as-built header, which says "built on macOS 27 only" (3.2). **Not the
  guides' first step**: see LF7.
- **LF7. Live steps, merge, release, and then the guides** (section 7). In this order: the live steps that
  come before the merge; the merge; LFL7, on `main`; `bash common/fetch-art.sh --verify`; the tag and the move
  of `release`, by the gate; LFL2c; and only then **one commit of its own on `main`** that makes the guides
  lead with the launcher's line, each keeping its game's own line as the second way, that adds the line about
  the request to Valve (3.10), and that says the window is built on macOS 27 only. The files: the root
  `README.md`, `cities-skylines-2/README.md`, `cities-skylines-2/INSTALL.md` and
  `surviving-mars-relaunched/INSTALL.md`. The table's guide addresses are `blob/main` (`common/games.tsv`), so
  a guide is read by players the moment it is on `main`: a guide that led with the launcher's line before
  `release` holds the word would send them to "not a Steam app ID: launcher" (LFD10). The seven places the
  pasted line stands today are in 1.1.

## 5. Who notices what

| Who | What they notice |
|---|---|
| A new player | One line to paste. Apple's box for its tools, a wait, then a window with the games, each with its icon in grey. A click, a question, a yes, and Terminal runs the game's installer as the guide's line would |
| A player set up before this version | Nothing until they update. Then: a game that is not set up shows as a tile, with its own picture, whether or not Steam says they own it; a click on it asks, and installs. Their pasted lines work as before. A second install, or an update, started while one runs now stops and says so; a game started while an install runs is asked about first |
| A player with the launcher and no game | By itself at most one request a day to GitHub, as for any installed Mac (`docs/plans/built-in-update.md`, 3.8), and the foot line when a version is out. A click on a game while a newer version is out says to update first |
| A player whose install stopped | The game's tile says the install is not finished; a click carries on |
| A player on a macOS below 14 | The launcher's line stops and says why. A game's own line does what it does today |
| A player whose Mac cannot build the window | The sentence that each game can still be installed by its own line. After a failed build during an update, 14unch3r keeps offering that update until a build works |
| A Mac where a game or the launcher was set up from a checkout or a named version (the maintainer's two Macs, at times) | The state is `manual`: a tile's click says at once why it does not install from `release` and offers the guide (LFD8) |
| Anyone who pastes any installer line, or updates | One request to Valve's servers for each game's picture that is not on the Mac yet, said in the guides and in the release's notes; none once the pictures are there |
| James, at a release | A new game's release notes are what tells every installed player that the game exists. `launcher` is one more word that can never be withdrawn. A row of the table now shows in every window, so no row goes to `release` before its installer works |

## 6. Tests

Every test runs with `HOME`, `TMPDIR` and `L1_UPDATE_DIR` at scratch folders, starts nothing of Wine, compiles
only where the existing window tests already do, and touches no network: `L1_CURL`, `L1_OPEN` and `L1_SYSCTL`
name stubs (for `install.sh`, a stub `curl` first on `PATH`, as today). A test whose record must be at the
default place (the tool's `--install`, 3.8) puts it there under its scratch `HOME`. A mutant is applied to the
source and must be seen red (exit 1, not REFUSED). New mutants take the numbers after each file's last. The
last numbers at `dc990de`, read by the rework as the highest label of each file's list of mutants: 19 in
`common/test-bootstrap.sh`, 86 in `common/test-launcher-window.sh`, 10 in `common/test-make-launcher-app.sh`,
23 in `common/test-updates.sh`, 19 in `common/test-update-games.sh`; 76 in Cities: Skylines II's
`scripts/test-install.sh`, so its new ones start at 77 (`:74` names 75 and 76 **[read]**; the first rework
misread it), and 41 in Surviving Mars's; 62 in Cities: Skylines II's `scripts/test-setup.sh` and 27 in
Surviving Mars's. Pass 1's builder confirmed the others **[record]**. A case or a mutant marked "with LF4a" or
"with LF5b" is written and seen red in that step, not in the step its row's other cases belong to (section 4).

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| LFT1 | `common/test-bootstrap.sh` | `install.sh launcher`, fetched: the fixture's `common/install-launcher.sh` is run with `L1_FETCHED_REF` and `L1_FETCHED_COMMIT` and no argument, and its exit code is returned. **`launcher <ref>`**: curl is called with that ref's address and no other, and `L1_FETCHED_REF` is the ref. **`launcher a..b`**: "not a branch, tag or commit", exit 2, curl not called, no script run. `launcher x --yes` and `launcher --check`: usage, exit 2, nothing fetched. A fixture without the script: the sentence, exit 1. From a checkout: the checkout's script is run and curl is not called, with a ref too; `launcher a..b` from a checkout is exit 2. `Launcher`, `launchers` and `14unch3r` are still "not a Steam app ID", **and that answer does not hold the new line**. **With no word: exit 2, curl not called, "Say which game", the usage line and the new line, and no script run.** Every existing case for an app ID and for `update` passes with no expected line changed | the word accepted in any case; no word made to install the launcher; arguments passed on to the script; the script's exit code dropped; the checkout case made to fetch; the ref ignored and `release` fetched; the ref rule skipped for `launcher`; the new line said for a wrong word too |
| LFT2 | `common/test-install-launcher.sh` (new): stubs for `xcode-select`, `xcrun`, `sw_vers`, `sysctl` and `open`, a recording stand-in for `common/fetch-art.sh`, and a stand-in for the window's builder that records its call and what existed then | **With the tools:** the three folders made, the parent first, none writable by others; `_update/updates.sh` byte for byte the tree's and there before the builder was called; the pictures' file called once, with no argument; the builder called once with no option; `_update/launcher` holds `checkout`, the tree's version, `-` and `L1_UPDATE_NOW`, and with `L1_FETCHED_REF=release` that line and the commit; `open` called once with the app's path; the closing line, with "You can close this window."; with `L1_UPDATE=1` no `open`, and the line "Done. 14unch3r is rebuilt."; `xcode-select --install` never called. **The order**, from the record of calls: the macOS test and the look at the record's folders before any call of `xcode-select`; the request before the first folder is made; the wait's last poll before the compiler's version is read; that before the pictures' file; that before the builder. **Without the tools:** `xcode-select --install` called once and the two lines; with the request answering 1, the other words and the wait still runs; the tools arriving after three polls, then the build; never arriving: exit 4 with its two sentences, builder not called; arriving with `swiftc` not running at two polls and running at the third: the build; arriving with `swiftc` never running: after `TOOLS_PART_POLLS` (shortened by a `sed`, as the core's test shortens its polls) exit 1 with the Software Update sentence, builder not called. **Tools there at the start, `swiftc` not running**, and the same with `xcrun --show-sdk-path` failing: exit 1 at once with the Software Update sentence, `xcode-select --install` never called, no poll slept, builder not called. **The compiler:** Swift 5.8: exit 3 with its sentence, builder not called; 5.9, 5.10 and 6.4 go on, each in both forms of the version's line (3.2); a version that cannot be read goes on. **This Mac:** a `sw_vers` that says 13.6: exit 3, its sentence with `13.6` in it, `xcode-select` never called, nothing made; 14.0: the caution for an older macOS, exit 0; 25.9: the same; 26.0: no caution; a version that cannot be read: its caution, exit 0; an Intel processor: its caution, exit 0. **The build failing:** the builder's exit 3 and exit 1: exit 1, the sentence that names each game's own line and the guide's address, no stamp written, an older stamp left byte for byte, `open` not called. **TERM while the builder runs:** no stamp, an older stamp byte for byte, no `open`, the "Stopped." line. **The pictures' file failing:** its stand-in exiting 1 after printing a line: the line is shown, the build goes on, exit 0. As root: refused. A `_update` others can write: exit 1 with the `chmod` sentence, `xcode-select` never called, nothing written. An own file missing, each of the nine in turn: exit 4. Any argument: exit 2. **With LF4a, the lock:** held when the builder is called, its target this script's process; an `installing-game` left by another holder is gone, and none is written; the lock is gone when `open` is called, and after every exit above, the TERM among them; a live `installing` or `updating` of another process: exit 3, the process in the sentence, `xcode-select` never called; in an update (`L1_UPDATE=1` and a live `updating`) no lock is taken and that `updating` does not stop it; with `L1_UPDATE=1` and no live `updating` the lock is taken | the stamp written before the build; the stamp written when the build was skipped; `updates.sh` deployed after the builder; the wait for the tools dropped; the build begun before the wait ends; `open` called after a failure; the own-folder test dropped; the request moved before the macOS test; the compiler check dropped; the versions compared as decimals; 14.0 refused; the caution below 26 dropped; a folder that is there with a broken part asked about; the pictures' file not called; a picture's failure made a stop. **With LF4a:** the lock not released on a signal; the lock still held when the window is opened; `L1_UPDATE=1` believed with no live `updating` |
| LFT3 | `common/test-updates.sh` (the stamp, the refusals); `common/test-update-games.sh` (the written file, run: beside the cases of `--open`'s file, whose helper `cmd()` is at `:259`) | **The stamp.** Only `_update/launcher` on `release` with no `offer`: `unknown`, and a refresh calls curl; with a newer `offer`: `ready`; on `checkout`: `manual`; beside game stamps at a higher version: "installed" is the launcher's; `l1u_stamp_of_launcher` prints its line and version; a launcher file that is a link, has two lines, five fields or a version `a[$(touch <file>)]`: passed over, the state is `none` and `<file>` does not exist; every existing case passes unchanged. **`--install`, refused**, with `failed`, nothing written and `L1_OPEN` not called: an ID of `0`, `12x`, eleven digits, `a[$(touch <file>)]`; the state `manual`, with its sentence; **the state `off` with one stamp on `checkout`, the same sentence**; **a record at a scratch folder that is not the default place, the same sentence**; the state `ready` ("Update first"); a live `installing`; a live `updating`; a `_update` others can write, with the `chmod` sentence. A dead `installing` (no such process, or older than the Mac's start) does not refuse. **`--install`, opened**, with the record at the default place under the scratch `HOME`, in each of the states `none`, `unknown`, `current` and `off` (every stamp on `release`): `L1_OPEN` got `-a Terminal` and the file's path. A source gate: the tool's spelling of the default place equals the two lines of `common/paths.sh` (`:16`, `:32`). **The written file**: mode 755; begins with `clear`; holds neither the word `installing` nor the record folder's path; run, it records `$0` as `1launcher-install` and `$1` as the ID, one word and nothing after it; it says the closing line for exit 0, 3, 4, 5 and 1 and exits with that code; with the fetch answering 000, 404 and 500 the installer is not run, the file is gone, exit 1; a hangup while the stub installer sleeps: the file and its folder are gone; with `HOME` and `TMPDIR` under a folder whose name holds a space, a quote and `$(touch X)` it opens and runs, and `X` is absent afterwards | the ID written unmatched; the refusal in `manual` dropped; in `off`, the stamps' lines not judged; the test of the record's place dropped; the refusal in `ready` dropped; the refusal for `updating` dropped; the refusal for `installing` dropped; `release` made `main` in the file's address; the launcher's stamp left out of the state; the launcher's stamp read without its match; a second word passed to the installer; the installer run after a fetch that failed |
| LFT4 | `common/test-update-games.sh`, with a recording stand-in for `common/fetch-art.sh` in the fixture's tree | A Mac with the launcher's stamp on `release` at `v0.0.9`, its app, and no game: the pictures' file is run once, with no argument, and after it the fixture's `common/install-launcher.sh`, with no argument; the closing line is "Everything is up to date", exit 0. **The same with the stamp at the tree's version:** the pictures' file is run once and the installer not at all; the same line, exit 0. **A game's setup stamped the launcher, and the pictures step still ran:** with a game whose stand-in setup wrote the launcher's stamp at the tree's version, the record of calls holds the game's installer, then the pictures' file once, and no call of the launcher's installer. A stamp newer than the tree: the pictures' file run, the launcher left, its sentence, exit 3. The stamp on `checkout`: the pictures' file run, the launcher left, its sentence, exit 3. The app there and no launcher stamp (a Mac from `v0.3.1` whose game was left): the pictures' file run once, and nothing said of the launcher. A stamp, no app, no game: the pictures' file not run, the stamp removed, "No game is set up on this Mac.", exit 3. **The app's test:** at the app's path a link, a bundle with `Contents/SharedSupport`, and a bundle with another identifier each count as no app, and the pictures' file is not run. The pictures' file exiting 1: the closing line and the exit code are what they were. The launcher's script failing: exit 1, the closing block names 14unch3r, and the games before it were still run. Neither a launcher stamp nor an app (every case the file has today): passes unchanged. A source gate: the identifier in the driver is the builder's `ID=`. **With LF4a:** a live `installing`: exit 3 with its sentence and the process, no installer run, and `updating` is gone afterwards; a `updating` whose link is older than the Mac's start, its target a live process: removed, and the update runs; a source gate: the take of `updating` stands before the look at `installing` | the launcher's script run every time; pictures skipped when the launcher is current; the pictures' file run with no app; a launcher on another line run anyway; "No game is set up" said after the launcher was updated; its failure not counted; the stamp kept when the app is gone; a current launcher with no game made exit 3; the app's test made true for an absent app. **With LF4a:** the look at `installing` dropped; the look made before the take; the line that removes a stale `updating` dropped |
| LFT5 | both games' `scripts/test-setup.sh`, with a recording stand-in for `common/fetch-art.sh` in the scratch tree | **The stamp (LF1).** After a setup whose stand-in builder exits 0: `_update/launcher` holds the line and the tree's version. The builder exiting 3, with an older launcher stamp there: that stamp left byte for byte, the line "14unch3r stays at ... the line above says why." said, the game's own stamp still written, the setup's exit code what it was. The same with no older stamp: no launcher stamp and no such line. With `--dest` (Cities: Skylines II) and `SM_APP` (Surviving Mars), `--check` and `--mac-only`: nothing written. **The pictures (LF2).** After a builder that exits 0: the pictures' file called once, with no argument, after the builder. Not called: when the builder exits 3; under `L1_UPDATE=1`; with `--dest`, `SM_APP`, `--check` or `--mac-only`. The stand-in exiting 1 after printing a line: the setup's exit code is what it was | the stamp written when the builder skipped; the stamp written for another destination; the "stays at" line said with no older stamp; the pictures fetched when the window was not built; the pictures fetched in an update |
| LFT6 | `common/test-launcher-window.sh`, through text modes | **The listing.** `--list --games` with no app at all: one row per game of the table, role `offer`, state `not-set-up` (today: no row); with one wrapper marked for the game and no app: `begun`; with two wrappers marked alike: `not-set-up`; with LF5b: with `--update-dir` and a live `installing` whose game file names the game: `installing`; with a dead one: not (LFT13 holds the lock's cases); without `--update-dir`: never `installing`; a game that is set up has no offer row; a row whose address is not on github.com is dropped, as today; a cache that says owned gives the state `owned` and the second line "In your Steam library. Click to install.", and changes nothing else. **`--grid`**, with an offers-only fixture (no app): the group's label "Not set up on this Mac"; the group's help with "or set it up"; the first offer is `selected`; each state's second line, tooltip and spoken words of 3.7; with no `--update-dir`, today's guide words; `paint`'s contrast lines for `title`, `second` and `label` at 4.5 or more; the window's height with three groups. **The keys**, with no app: `--act right`, `left`, `down`, `up` move among the offers, and `--act return` prints the click's name. **The click** (`--act start`, which prints what `clickAnswer` gives), one case per line of 3.7's list: no tool gives `guide` and the address, exactly as an offer today; `manual` gives `tell-manual`; `ready` gives `tell-update-first`; a live install gives `tell-installing`; a busy game gives `tell-quit-first` and its title; `unknown`, `current`, `none` and `off` each give `ask-install`. **The order of the lines**, in cases where two apply: `manual` with an install running gives `tell-manual`; `ready` with an install running gives `tell-update-first`; an install running with a game in use gives `tell-installing`. A set-up game still gives `start`; **a set-up game with an install running gives `ask-install-running`**, and with a busy game of another prefix as well, today's question for that game. In none of them was the tool called with `--install`. **The sheets**, in the text mode `--install-sheet <name>`: for each name its message, its text and its buttons in order: "Not Now", "Install", "Read the Guide"; for a begun game "Carry On" and the other message; for the four short sheets "OK", "Read the Guide", and `tell-manual`'s text holds the game's folder from the table; for `ask-install-running` "Don't Start", "Start Anyway". **The answer**, in the text mode `--install-answer <name> <button>`: for the asking sheet only the second button gives `open`, the third gives `guide`, the first and Escape give `nothing`; **for each of the four short sheets the first button and Escape give `nothing`, the second gives `guide`, and no button gives `open`**. **The opening**, in the text mode `--install-open`: a stub tool saying `opened` gives `quit`; `failed` and a sentence gives the sentence; a tool that exits 2, one that prints nothing, and one that sleeps past the limit each give the one sentence of 3.7. **Source gates**, as the update's sheet has (`common/test-launcher-window.sh:975-984`), each a count: `"--install"` occurs once, in one function, which is called on two lines, in the text mode and in the window after a test of the answer for `open`; every line that shows a sheet has just before it a line that sets `sheet` (today 5 of 5; the new count is the builder's to state); the window reaches the tool only in blocks sent off the main thread | "Install" made the first button; the first button made to give `open`; the third button made to give `open`; a set-up game listed as not set up; `begun` shown without a marker; the tool called before the sheet's answer; the ID passed to the tool unmatched; the limit removed from the call; the tiles hidden when ownership is not known; the fallback with no tool dropped; with no app, no tile selected; the test for a game in use dropped; the test for a running install dropped; `manual` made to ask; `ready` made to ask; the order of `manual` and a running install turned round; a short sheet's second button made to give `open`; a set-up game started with no question while an install runs |
| LFT7 | `common/test-game-contract.sh` (new), on a tree given as its argument | For every row of `common/games.tsv`: four fields and each one's form; the folder is there; `scripts/install.sh` and `scripts/setup.sh` are there and pass `bash -n`; the installer sets every setting of the core's list, with `GAME_APPID` the row's ID and `GAME_TITLE` the row's title; it reads `common/install-core.sh`; `WORDS_NEED` and `NEED_GB` are one-line literals; `l1w_row game <ID>` returns 0 and `l1w_games` prints the ID; `common/game-art.tsv` has one row for the ID, of four fields in their forms, its address on a host of the list and its size at most 1,048,576; a source gate: the list of hosts in this test equals the one in the row rule of `common/fetch-art.sh`; the installer tests for the pictures' three files before its setup; the guide's address names a file of the tree; the installer's header lists the exit codes. **The questions, by a rule that can be typed:** a terminal read is a line on which `read` is a command, which holds no `<`, and which is not the test of a `while`. For each one in the installer, the core and the setup, `-t 0` stands on its own line or on one of the ten lines above it (today the farthest is nine: `cities-skylines-2/scripts/setup.sh:566` and `:575`), and the number of terminal reads in each of the five files (both installers, both setups, the core) is the number in its header line `# Terminal questions: <n>` (3.6, row 7; LF6 writes the lines; today the installers have 0 and 1, the setups 2 and 1, the core 1). And the reverse: every ID of `l1w_games` and every row of `common/game-art.tsv` has a row in the table | on a scratch copy of the tree: an ID taken out of `l1w_games`; a `GAME_APPID` that is not the row's; a guide's address with no file; `WORDS_NEED` holding `$(date)`; a terminal read with no `-t 0` in reach; a fifth field in a row; the picture's row taken out; a picture's row for an ID the table does not have; a picture's row on a host not in the list; a `# Terminal questions:` line one too low |
| LFT8 | each game's `scripts/test-install.sh`, in the case that keeps the real `setup.sh` | **The parts joined.** The fixture, by name: the record at the default place under the scratch `HOME` (anywhere else the tool refuses, 3.8), a marked wrapper of the game with no app (a begun install), the launcher's stamp alone on `release` at `v0.0.9`, and `offer` at `v0.0.9`, so that the state is `current` and the tool opens. `updates.sh --install <ID>` with stubs; then `offer` is set to the tree's version, as a daily check would have found it; the written file run; through the root `install.sh`, the installer and the real setup. Then the game's stamp and the launcher's stamp both hold the tree's version, the state is `current` (with the launcher's stamp left at `v0.0.9` it would be `ready`), and no lock is left. The draft began at the tree's version, where "holds the tree's version" was true before anything ran; pass 1 asked for an older start with `offer` at the tree's version, which RD4 now refuses, so `offer` is raised after the tool has opened | the written file made to run `update`; the lock left behind; the setup's launcher stamp dropped |
| LFT9 | the gates, and a sweep by hand | **Gates, run at every step:** `common/check-links.py`, `common/check-identifiers.sh` at its residual, `bash -n` on every changed script, and every other test file of the repository. **Not a gate, and said so:** that every older mutant of each test file touched is still red. No script runs them all. They are swept by hand at the build, once, on a frozen commit, and the as-built header records that commit, the number of runs, the number seen red, and by name the ones that are retired and answer REFUSED on purpose (`cities-skylines-2/scripts/test-setup.sh:126` retires its mutant 36 today) | none |
| LFT10 | `common/test-launcher-window.sh`, through `--grid` | **The picture (LFD4).** With one game set up and one not, and the picture's file in `<update dir>/art/<ID>`: the tile of the game that is not set up ends its `--grid` line with `art` and carries `dim`; the set-up game's ends with `app` and does not carry `dim`. Without the file: `generic`. With a file that is a link, one over 1 MiB, one that is no image, and an image whose header names more than 1,024 pixels a side: `generic`. The same for a begun wrapper and, with LF5b, for a running install. A source gate: `greyed(` is called nowhere inside a `draw` (today once, `common/launcher-window.swift:1078`). That an offer is `dim` is held already (`common/test-launcher-window.sh:635-637`), so no new mutant is spent on it | the picture's file never looked for; a missing picture not falling back to the generic icon; a link taken as the picture; the bound on the picture's pixels dropped |
| LFT11 | `common/test-install-launcher.sh`; Cities: Skylines II's `scripts/test-install.sh`, where every case of the tools stage is; Surviving Mars's `scripts/test-install.sh` only for its scratch tree | **The tools file (LFD14).** The launcher's installer: LFT2's cases of the order, the request's answer, the settle and the folder that is there at the start. The core, reading the same file, in Cities: Skylines II's test: every existing case of the tools stage passes with no expected line changed (`scripts/test-install.sh:488-496`), with the real `common/tools.sh` in the scratch tree; the older mutants 24, 27 and 28 are still red, 27 through the line that stays in the core; new cases: the tools arrive, the part fails at two polls and runs at the third: the install goes on; the request answering 1: `tools_ask`'s other words are said and the wait still runs; `TOOLS_PART_POLLS=24` stands in the core. With `common/tools.sh` missing: the core's sentence for its own files, exit 4. **Surviving Mars's test has no case of the tools stage and gains none:** its stub `xcode-select` always answers 0 (`:219`), so it shows only that the core still reads the real `common/tools.sh` from its scratch tree, with every case passing as before. The step ends with the transcript recorded again (section 4) | the two minutes dropped (the part tried once); `tools.sh` left out of the core's test of its own files; the request's exit code thrown away (the first words said after a request that was not taken) |
| LFT12 | `common/test-make-launcher-app.sh` | **The real parts joined.** In a scratch `HOME`, with the tree's real `common/install-launcher.sh`, the real builder and the window it builds (stubs only for `xcode-select`, `sw_vers` and `open`, and `L1_CURL` for the pictures), run with `L1_FETCHED_REF=release` so that the Mac is not `manual`: the built app's `L1UpdateDir` is the scratch `_update`; its `Info.plist` gives `LSMinimumSystemVersion` as `14.0`; `--update-tool` prints the deployed tool's path; `_update/art/<ID>` is there for each row of the pictures' table, through the real `common/fetch-art.sh`; `--list --games <the bundle's table> <the scratch Applications>` prints one offer row for each row of the table. **With LF5b, its last case:** `--act start` on the first tile, with `--update-dir` at that `_update`, prints `ask-install`. LFT2 cannot show this (its builder is a stand-in) and LFT6 cannot (it passes `--update-dir`, which wins over the bundle's key: `common/launcher-window.swift:34`): without this test a window that was installed from nothing and cannot install would pass every gate | the folders and the tool's copy made after the build (no `L1UpdateDir` in the first window); the table not copied into the bundle; the minimum left at `13.0` |
| LFT13 | `common/test-updates.sh`; both games' `scripts/test-install.sh`; `common/test-update-games.sh`; `common/test-launcher-window.sh` | **The install's lock.** *The rule, in shell:* a link to a live process is live; to a dead one, to no number and a plain file are not; a link to a live process whose own time is before the Mac's start (set back with `touch -h`) is not; with the start's time unreadable (`L1_SYSCTL` at a stub that fails) the first two parts decide; take, take again by another process (refused), release, take over of a dead one; **a folder at the lock's name: the take refuses, and nothing is left inside the folder**; a take removes an `installing-game` that another holder left. *The core:* the lock is held from `core_begin` on, its target the installer's process, and `installing-game` holds the game's ID, written by a rename (a source gate: nothing is written onto that name in place); it is gone after an exit of 0, 1, 3 and 4 and after INT, TERM and HUP; a second install while one runs: exit 3 with its sentence, nothing downloaded; a lock older than the start is taken over; a live `updating`: exit 3 and `installing` not left behind; under `--check` nothing is made and no lock taken; under `L1_UPDATE=1` with a live `updating` no lock is taken and that `updating` does not stop it; under `L1_UPDATE=1` with no live `updating` the lock is taken as in any run; a source gate: in `core_begin` the take of `installing` stands before the look at `updating`; with no record's folders they are made, the parent first; a `_update` others can write: exit 1 with the `chmod` sentence before anything is downloaded. *The update:* the driver stops during an install (LFT4); `--open` answers `failed` and its sentence during an install and writes nothing. *The window, on the same fixtures:* live gives `installing`; dead, a plain file and older than the start do not; a game file that is absent, a link, or not an ID names no game, and the click still gives `tell-installing`; a wrapper's live `.launcher.lock` with no install lock is not `installing`; a set-up game's start with a live install gives `ask-install-running` (LFT6) | the lock not taken; not released at an exit; not released on a signal; the start's rule dropped in shell; the start's rule dropped in Swift; the core's look at `updating` dropped; the core's look made before its take; the read-back after the take dropped; a game file left by another holder not removed; the game file not written; the lock taken under `--check`; `L1_UPDATE=1` believed with no live `updating`; a wrapper's lock read as installing; `--open`'s refusal dropped |
| LFT14 | `common/test-fetch-art.sh` (new): `HOME` and the record at scratch folders, a fixture tree with its own `common/game-art.tsv` and `common/games.tsv`, and `L1_CURL` at a stub that records its arguments and serves a fixture | **The pictures' file.** With the record's folders there and no `art`: `art` is made, not writable by others; for each row curl is called once, with the options of 3.10 in their order (`--max-time 20`, `--max-filesize` with the row's size, `--max-redirs 0`, the row's address last), and the right file is kept at `_update/art/<ID>`; nothing is printed, exit 0. **A second run calls curl not at all.** A wrong size, a wrong checksum, an answer's code of 404 and of 301, curl exiting 28 (its time limit) and curl exiting 6 (no network): the one line with the game's title, no file kept, no temporary file left, exit 0. **A changed row:** with an old file there and the row's checksum changed, a fetch that fails leaves the old file byte for byte, and one that works replaces it. **The row rule:** an address that is not `https://`, holds a space, or is on a host not in the list; a size over 1,048,576; a checksum of 63 digits; an ID with no row in `common/games.tsv`: each passed over, curl not called. **The folders:** no `_update`: nothing made, curl not called, exit 0; a `_update` others can write: the same; `art` a link: the same. A temporary file of its own older than ten minutes is removed, a newer one left. An argument that is not `--verify`: the usage line, curl not called, exit 0. **`--verify`:** every row served right: `<ID> ok` for each, exit 0, and nothing written under the record's folder; one row served changed: `<ID> changed`, exit 1; curl failing: `<ID> not reached`, exit 1 | the test of a picture's checksum dropped; the test of its size dropped; the time limit dropped from the curl line; a picture that is there fetched again; the old file removed before the new one verified; a failure made exit 1; the host's rule dropped; the limit on a row's size dropped; `--verify` made to write into the record |

**Existing tests that change, by name** (each to be confirmed by the second pass's builder lens, which reads
the files): `common/test-launcher-window.sh` (the offer cases that expect no row without an owning cache, the
group's label at `:634`, the group's help, the header's list of modes, the count of sheet lines in source gate
1, and the two texts for `manual` that `--update-menu` answers, `:923` and `:925`, which section 10 rewrites);
`common/test-bootstrap.sh` (the no-word case gains one expected line); `common/test-update-games.sh` (the
"No game is set up" case gains a launcher-less fixture by name; its fixture tree gains a stand-in for
`common/fetch-art.sh`); both games' `scripts/test-setup.sh` (the "writes nothing" snapshots list
`_update/launcher`; their scratch trees gain a recording stand-in for `common/fetch-art.sh`, so that no case
of a real setup reaches curl); both games' `scripts/test-install.sh` (their scratch trees hold empty stand-ins
for `common/paths.sh` and `common/updates.sh` today, `cities-skylines-2/scripts/test-install.sh:96-98`: the
core now reads both and `common/tools.sh`, so the real files go in, and every case that is not `--check` then
finds the record's folders made in its scratch home; they gain stand-ins for the pictures' three files, which
the installers test for, and a case each for one of them missing, exit 4);
**`cities-skylines-2/scripts/test-install.golden`**, the transcript `scripts/test-install.sh:870-881` compares:
it differs after every step that changes a printed line, and is recorded again there on purpose (section 4);
`common/test-make-launcher-app.sh` (the minimum in the `Info.plist`, if a case reads it);
`common/test-mac-inventory.sh` and `common/check-deploy.sh` (`_update` gains files and a folder).

**Not tested, and said so:** what Terminal shows and whether macOS asks anything when 14unch3r opens the
install's file (LFL2b); the sheets on screen, their focus, Return, Escape and the key loop of three buttons
(LFL9 for all of them; LFL2a and LFL2b for the two a real state reaches); a compile with Apple's tools alone
on a macOS older than 27, or with a compiler older than Swift 6.4 (LP1 has 27 only, and no step meets one);
Apple's box, its request's exit codes and the wait on a Mac without the tools (LFL7), and what the request
gives with no screen session (no step); a Mac that really has nothing (LFL1, LFL7); a real install from a
click, from the sign-in to the game's start (LFL2b, LFL2c); the lock during a real install (LFL8, and from a
click LFL2c); a window left open while its bundle is rebuilt (LFL2b); the pictures as Valve serves them (LP4,
then `--verify` before each tag, and LFL1, LFL4 and LFL7 on real Macs); macOS's refusal of a pasted command
(LFL7).

## 7. Probes and live steps (each on James's word)

**Probes.**

- **LP1. The compile with Apple's tools alone. Measured in part, by pass 1's platform lens, 2026-11-26
  [record]:** on the Studio, macOS 27.2.1, with `DEVELOPER_DIR=/Library/Developer/CommandLineTools`, the
  window compiled with Swift 6.4 in 27 s with an empty module cache and 4 s warm; compiler and SDK both came
  from the tools' folder; the binary is arm64, signed ad hoc by the linker, and carries no quarantine. So 3.2
  holds on macOS 27. **Its pass condition, to be met in full before LF1** (pass 1's test-plan lens): the
  compiler found is under the tools' folder; the builder's own line exits 0; the product answers `--svg` and
  `--list`; both window test files (`common/test-launcher-window.sh`, `common/test-make-launcher-app.sh`) pass
  under the same variable; three timings are recorded (cold, warm, and the builder whole). It needs only the
  compilers macOS 14 and later deliver. **[not known]** whether an older one of those (Swift 5.9, 5.10, 6.0)
  compiles the file: no Mac of the project has one, and no step of this plan meets one, since LFL7's Mac is on
  macOS 27 as well. Until one is met, the as-built header and the guides say "built on macOS 27 only" (3.2).
- **LP2. A full disk during Steam's download.** In a scratch wrapper on a small disk image: what Steam shows,
  what its manifest's fields read, and whether Steam stays up. Decides whether the installer's wait needs a
  rule, as a finding for the installers (it is true of a pasted line today) and not as part of this plan.
- **LP3. The macOS Steam app open during an install.** Read first: `cities-skylines-2/GOTCHAS.md`'s entry of
  the session with the macOS Steam running (commit `a9de979` names it; not read for this draft). Then, if it
  does not answer: one install step with it open.
- **LP4. The pictures (a network fetch, on James's word), before LF2 writes the table.** For both games:
  which of Steam's public images is the game's own icon, and at which address; fetched, and compared by eye
  with the icon of the set-up app in the Studio's `~/Applications`; its format, its size in pixels, its size
  in bytes and its sha256; whether `NSImage` reads it; and whether the bytes are the same at a second fetch an
  hour later and from a second address of Valve's, if it has one. Recorded here, and only then is
  `common/game-art.tsv` written. If no public image is the icon, if the nearest is under 128 pixels square, or
  if its bytes are not stable, the table cannot be written as designed, and James chooses again among his
  three options (section 13, LFD4).

**Live steps.** Before the merge: LFL1, LFL9, LFL2a, LFL8, LFL2b, LFL3 and LFL4. After the merge and before
the tag: LFL7, from `main`. On the tagged release: LFL2c. With its own game: LFL6. They are written below in
that order, but for LFL8 and LFL9, which stand after the steps they are run before. The fallback release of
section 11 runs fewer of them, named there.

- **LFL1. The launcher from nothing.** On a new macOS user account on the Studio, which James makes (Apple's
  Command Line Tools are the system's, so the account is new to the project and not to Apple's tools): the
  branch's root `install.sh` fetched and run with `launcher launcher-first-install`.
  - **Who types, and how its files reach the record.** A session cannot act in another account. James signs
    in to the new account at the Studio's screen and types; the commands to type are a short list written
    into this file before the step; their output goes to a folder both accounts can read, which James names
    (it is a new place outside the repository: his word and a line in `CLAUDE.md` first), and it is removed
    with the account.
  - **Pass, each a measurement:** the built app's `--list --games <the bundle's table> ~/Applications` prints
    two offer rows, both `not-set-up`; the first field of `_update/launcher` is the branch's name; `bash
    _update/updates.sh` prints `manual`; `_update/art` holds one file per game, each with the size and the
    sha256 its row names; the list of names holding `1launcher` under that account's
    `~/Library` (one `find ~/Library -name '*1launcher*'`, names only) equals what `CLAUDE.md` names. That
    `find` looks above a `1launcher` folder, which `CLAUDE.md` forbids a session; here James runs it, in an
    account that holds nothing else, or strikes it (section "What this draft could not verify").
  - **Recorded:** every line Terminal shows; every dialog of macOS; the seconds from the paste to the window.
  - **Captured, the window's region only, in the dark and in the light appearance:** the window with both
    games shown by their own pictures in grey and the first one selected; and once more with one picture's
    file moved out of `_update/art` and the window opened again, which shows the generic icon for that game
    (exit criterion 9's capture with no picture). The file is put back. The sheets are all captured at LFL9;
    the two a real state reaches are seen again at LFL2a and LFL2b.
- **LFL2a. The refusal in `manual`.** In that account as LFL1 left it. A click on a game: the short sheet for
  `manual`, at once. And by hand: `bash _update/updates.sh --install 3215050` prints `failed` and its
  sentence. Pass: no folder `1launcher-install.*` under `$TMPDIR`, no `_update/installing`, and Terminal did
  not open a window. Tried here too: Return and Escape on the sheet, and "Read the Guide".
- **LFL2b. A game from the window, before the release.** In that account, with every other Steam on the Mac
  quit. The launcher's stamp is rewritten by hand to `release` and the tree's version, so that the state is
  no longer `manual`. A click on Surviving Mars (the smaller download): the sheet with three buttons is read
  and captured, with the system in the dark and in the light appearance; Return, Escape and the Tab key's
  round of the three buttons are tried first, then "Install". **The file fetches `release`, so the installer that runs is the
  published one of `v0.3.1`**, not this branch's. James signs in to Steam.
  - **Measured:** the tool answers `opened`; the seconds from the click to Terminal's first line, and every
    dialog of macOS between; once during the download the Terminal window is closed, 14unch3r opened (the tile
    says the install is not finished, and is captured so, in both appearances: exit criterion 9's capture of
    a begun install), a click, and the install carries on; once 14unch3r is left open while
    the setup at the end rebuilds it; the game starts from its app.
  - **Known beforehand, and recorded as such:** `v0.3.1`'s setup puts back the window and the tool of
    `v0.3.1`. After this step the window is that version's: it shows a game that is not set up only when
    Steam's cache in the new prefix says the account owns it, under "You also own", and a click on it opens
    the guide (1.3). And `v0.3.1`'s installer takes no install lock, so **the lock's life cannot be observed
    here**. LFL8 shows it before the release, with this branch's installer started by a pasted line; from a
    click it is first seen at LFL2c.
  - **Afterwards:** `install.sh launcher launcher-first-install` again, which puts this branch's window and
    tool back.
- **LFL8. The lock, before the release (RC20).** In that account, between LFL2a and LFL2b, with nothing
  installed yet. The pasted line of Cities: Skylines II with the branch as its ref (`... 1launcher-install
  949230 launcher-first-install`), which runs this branch's installer and core. It is stopped during the
  download of Wine: no Steam is started and nobody signs in. **Measured while it runs:** `_update/installing`
  is a link to the installer's process and `installing-game` holds 949230; 14unch3r, opened meanwhile, says
  "Installing in Terminal." on that game's tile, which is captured so in both appearances (exit criterion 9's
  capture of a running install); the same line pasted in a second Terminal window stops with
  "Another install is running"; `install.sh update launcher-first-install` in a second window stops with its
  sentence, and leaves no `updating`. **After Control-C:** "Stopped.", both files gone, and the tile says the
  install is not finished, or not set up if no wrapper was made yet. The state there is `manual`, so a click
  on the tile gives the sheet for `manual`: the sheet for a running install is LFL2c's to show.
- **LFL3. The update on that account.** The launcher's stamp and the game's are rewritten by hand to `v0.0.9`
  on the branch's line; `install.sh update launcher-first-install`. Pass: the game's installer runs, the
  window is rebuilt, and both stamps hold the branch's version; `_update/art` holds both pictures as before
  (the driver's pictures step ran, and with both files there it had nothing to ask for). **Its second half:**
  the game's wrapper and app go to the Trash and its stamp is removed, **and the launcher's stamp is rewritten
  to `v0.0.9` again** (left at the fetched version, the update would run nothing). Then the update: the
  launcher alone is updated, "Everything is up to date", exit 0. And once more at once: nothing is run, the
  same line, exit 0.
- **LFL4. An install that exists** (the MacBook, or the Studio's own account). Its stamps follow `release`,
  and the driver leaves every stamp that is not on the fetched line (`common/update-games.sh:111`), so **the
  stamps are first rewritten by hand to the branch's line**. Then the rehearsed update from the branch.
  - **Pass:** `cities-skylines-2/scripts/boot-verify.sh` ends in `VERDICT: PASS`; Surviving Mars starts from
    its app; each game's stamp and the launcher's stamp hold, field by field, the branch's line, the branch's
    version and the commit that was fetched; no tile is shown for a game that is set up there; the lock
    `updating` is gone.
  - **The pictures arrived, and by the driver.** `_update/art` holds one file per game, each with the size
    and the sha256 its row names. On this Mac both games' setups ran under the update and stamped the
    launcher, so the launcher's installer was not called and the setups fetched nothing: the files can only
    have come from the driver's own step (3.5). This is the case pass 2's first blocker was about, seen on a
    real install.
  - **Afterwards both pasted lines from `release` are run**, which put the Mac back on the published version
    with its games' stamps on `release`. **And `_update/launcher`, which this step left, goes to the Trash:**
    `v0.3.1` does not read it, and left on the branch's line it would make that Mac `manual` on the day this
    version is released. `_update/art` may stay: it holds two public pictures.
- **LFL7. A Mac with none of Apple's tools (RD3): Erin's iMac, after the merge and before the tag.**
  - **The Mac (James, 2026-11-26).** An iMac at home, Erin's computer, on macOS 27, with two accounts that
    have never held anything of the project: Erin's, and James's own, kept there for troubleshooting. Apple's
    tools are "very unlikely" on it (his word). They install for the whole Mac, and the paste warning needs a
    Mac that has none (1.5). So the order below is fixed, and it is the reverse of the one this step had
    first, which pass 2 found could never show the warning.
  - **When, and from which ref.** After the merge into `main` and before the release is tagged: a tag cannot
    be moved, so what this step finds must still be mendable on `main`. The ref is `main`. The line stands
    here, so that a browser shows it on this file's page and it is copied from there:

        /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/main/install.sh)" 1launcher-install launcher main

  - **Before anything, in Finder, in James's own account.** Go to Folder, for
    `/Library/Developer/CommandLineTools` and for `/Applications/Xcode.app`: both must be absent. About This
    Mac: the macOS version and the chip. Nothing is typed into Terminal for this, in either account: a
    Terminal opened in Erin's account would end the 30 days the warning needs, and running one of Apple's
    tools to look for them can itself bring Apple's box (`common/install-core.sh:328`). If either folder is
    there, the step cannot measure what it is for: it stops, that is recorded here, and exit criterion 3's
    "or" applies.
  - **First, Erin's account: the one run that reads both the paste warning and Apple's box.** It is the
    account whose Terminal has been unopened longest, and nobody opens Terminal in it before the paste. With
    her at the Mac or by her leave: Safari shows this file's page on `main`, the line is copied there,
    Terminal is opened, and the line is pasted.
    - *Read off the screen, in order.* What macOS shows at the paste, and what must be done to go on: the
      guides' words for it come from here. The installer's first lines. Apple's box and its words. **Whether
      the box asks for a password: Erin is an administrator on her own Mac (James, 2026-11-26), so if one is
      asked it is hers to type.** Which of `tools_ask`'s two sets of words the installer said, which is whether the
      first request was taken (3.2). **Before Install is pressed**, in a second Terminal window:
      `xcode-select --install; echo $?`, the request's exit code with a box already up. Then Install and
      Agree: the minutes and the megabytes of Apple's download; the seconds from Apple's box saying it is
      done to the installer's line "Building 14unch3r." (the poll, the settle and the pictures); the seconds
      of the compile; the window, with both games in grey by their own pictures.
    - *Pass, each a measurement*, typed into that Terminal window after the installer's closing line: the
      built app's `--list --games <the bundle's table> ~/Applications` prints two offer rows, both
      `not-set-up`; the first field of `_update/launcher` is `main`; `bash _update/updates.sh` prints
      `manual`; `_update/art` holds one file per game, each with the size its row names; `xcrun swiftc
      --version` prints the compiler's version, which is recorded. And off the screen: the installer went on
      by itself once Apple's box was done, and 14unch3r opened. LFL1's `find` is not run here: her
      `~/Library` holds her own things.
  - **Second, James's own account: the path with the tools there, and nothing more.** The same line. It
    cannot show the paste warning, since the Mac has developer tools by then, and it brings no box. Read:
    the seconds from the paste to the window, with a compile that has an empty module cache. Pass: the same
    measurements.
  - **Struck: the reading with no screen session.** It needed Remote Login switched on on someone else's
    Mac. What `xcode-select --install` gives there stays not known (3.2).
  - **A launcher kept there is in the state `manual`**, having been set up from `main`: a click on a game
    says so and installs nothing (3.7, line 2). It installs games only after the release, once the published
    line is pasted in that account. That is said to her before she decides to keep it.
  - **What the step leaves on her Mac, said to her before it runs:** Apple's Command Line Tools (1.3 GB on
    the Studio, for the whole Mac; removed with `sudo rm -rf /Library/Developer/CommandLineTools`, an
    administrator's act); in each account used, `~/Applications/14unch3r.app`, the folder
    `~/Library/Application Support/1launcher/_update` with the two pictures in it, and the window's one
    preferences file. No Wine, Steam or Rosetta. Each goes to the Trash afterwards unless she wants the
    launcher kept.
  - Without this step LFD14's ask, the shared wait and the stage it replaces stay unmeasured: that stage has
    never run for real on any Mac of the project **[record: pass 1]**. It does not answer LP1's open
    question: this Mac's compiler is as new as the Studio's.
- **LFL2c. The published line, right after `release` moves** (it replaces the published-line step of the
  draft). On a clean account: the launcher's line of 3.3, pasted. The guides do not hold that line yet (they
  change after this step, LF7), so it is copied from this file's page; a line copied from a guide here would
  be a game's own. Then the window; a click and an install of one game. Pass: both stamps on `release` at the
  new version; the state `current`; **the lock live during the run** (`_update/installing` names the
  installer's process, `installing-game` the game, and a 14unch3r opened meanwhile says "Installing in
  Terminal."), **and gone after**; a click on the other game during the run gives the sheet for a running
  install; the game starts; the other game is shown as not set up, by its own picture. On the Studio the
  paste warning cannot show (the tools are there): LFL7 is where it is read. If this step fails, each game's
  own line works as before, and the guides have not yet been changed (LF7).
- **LFL9. Every sheet, on the Studio, with nothing real changed** (in the form of the update's UL1,
  `docs/plans/built-in-update.md`, section 7). Before the merge, after LFL1. Two of the sheets,
  `tell-update-first` and `tell-quit-first`, reach no screen in any other step.
  - **The fixture.** A scratch `_update` holding the branch's `updates.sh`, and a 14unch3r built into a
    scratch folder with `L1_UPDATE_DIR` at that scratch `_update`, so that its `L1UpdateDir` names it
    (`common/make-launcher-app.sh:129-137`). It is opened with `open -n <app> --args <a scratch folder>`,
    and that folder holds one fixture app marked as Cities: Skylines II, whose program starts nothing, so
    that no real game is listed and none can be started. Surviving Mars has no app there and is the tile
    that is clicked. Each state is made by hand-written files, and the window is brought to the front again
    after each change, which makes it read them:
    1. the launcher's stamp alone, on `release` at the branch's version, and no `offer` (the state
       `unknown`): the sheet that asks, "Install Surviving Mars: Relaunched now?";
    2. the same, with a fixture wrapper in the folder that carries Surviving Mars's marker: "Carry on
       installing ...", with "Carry On";
    3. the stamp's line rewritten to `checkout`: `tell-manual`, whose text names the game's folder;
    4. the stamp at `v0.0.9` on `release` and an `offer` of a higher version: `tell-update-first`, with the
       foot line in the same window;
    5. state 1 again, with `installing` a link to a live process (a `sleep` started for it) and
       `installing-game` holding 3215050: the tile says "Installing in Terminal.", and a click gives
       `tell-installing`;
    6. state 1 again, with the fixture game's prefix holding a `.launcher.lock` that names a live process:
       `tell-quit-first`, with that game's title in both sentences;
    7. state 5 again, and a double-click on the fixture game: the question with "Don't Start" and "Start
       Anyway"; "Don't Start" is pressed.
  - **Pass, each read off the screen or a file.** Each sheet's message, text and buttons are what
    `--install-sheet <name>` prints for it. On each, Return and Escape close it with nothing run; on the
    sheet with three buttons the Tab key goes round all three, and "Read the Guide" opens the game's guide
    in the browser. Then, in state 1, "Install" is pressed once: the window shows the tool's sentence for a
    record that is not at the default place (3.8), which is how a fixture can start nothing. Afterwards:
    Terminal has opened no window, no folder `1launcher-install.*` is under `$TMPDIR`, and the scratch
    `_update` holds only what was written by hand.
  - **Captured**, the window's region only, with the system in light and in dark: every sheet of the seven
    states.
  - **Afterwards** the scratch app is deleted and then unregistered with `lsregister -u`, as
    `common/test-launcher-window.sh` does for its own; the `sleep`s are ended; the scratch folders are
    removed.
- **LFL6. The third game.** Its first install on a player's Mac is from the window. This is the contract's
  own test, and it belongs to that game's plan.

## 8. Exit criteria

1. Every test of section 6 passes, and every mutant listed was applied and seen red. The sweep of the older
   mutants (LFT9) is recorded in the as-built header with its commit, its counts and the retired ones by name.
2. **The probes before what they gate.** LP1's pass condition was met in full before LF1 was begun, and its
   numbers are in this file. LP4 was run before `common/game-art.tsv` was written, and its addresses, sizes
   and checksums are in this file.
3. **The live steps, by when.** Before the merge into `main`: LFL1, LFL9, LFL2a, LFL8, LFL2b, LFL3 and LFL4
   passed and are recorded here with what was measured. After the merge and before the tag: LFL7 passed and
   is recorded, or James has said in this file that it could not be run (the iMac had the tools after all, or
   was not to be had) and the release goes without it, and the as-built header then names the tools stage and
   the paste warning as unmeasured (RC19). On the tagged release, after the suites and
   `common/check-release-move.sh` on that commit: LFL2c passed. LFL6 is named in the as-built header as still
   to come.
4. The three kinds of line keep working, shown on the tagged commit by `common/test-bootstrap.sh` (LFT1), run
   there with every other test file: each game's line with its ID, `install.sh update`, and `install.sh
   launcher`; and with no word nothing is fetched.
5. `common/test-game-contract.sh` passes for both games, and `CLAUDE.md` names it as what a new game is
   written against.
6. `CLAUDE.md` names the new files and the folder of `_update` (`launcher`, `installing`, `installing-game`,
   `art/`), the word `launcher` and the pictures' addresses under § Published addresses, the rule for a row
   of the table, `common/install-launcher.sh`, `common/tools.sh`, `common/fetch-art.sh` and
   `common/game-art.tsv` in the layout table, and under "Releases" the run of `bash common/fetch-art.sh
   --verify` before a tag. The statements of section 10 are corrected in their files.
7. **The guides.** After LFL2c, and in a commit of its own: the root `README.md` and both games' guides lead
   with the launcher's line, keep each game's own line, say that an install or an update asks Valve's servers
   for the games' pictures, and say that 14unch3r is built on macOS 27 only. All seven places of 1.1 were
   looked at, and each either changed or was left on purpose (three are lines for one game with a variable
   before them). The release's section of `CHANGELOG.md` names the request to Valve and what Valve sees.
8. The design audit gate is done for the window's new tiles and sheets: the existing look's constants are
   used, the contrast lines for `title`, `second` and `label` are at 4.5 or more with an offers-only fixture,
   every sheet was seen on screen in both appearances (LFL9), and `docs/plans/launcher-window-look.md` is
   extended, the three-button sheet among it.
9. **The picture.** A game that is not set up, a begun install and a running install each show the game's own
   picture in grey, in a capture of the window in the dark and in the light appearance (LFD4): not set up at
   LFL1, begun at LFL2b, running at LFL8; and with the picture's file taken away the generic icon, at LFL1.
   LFT10 and LFT14 pass. **The pictures reach a Mac that already has a game:** after the update of LFL4,
   `_update/art` held every game's picture, fetched by the driver through `common/fetch-art.sh` and not by
   the launcher's installer, which that update did not call. `bash common/fetch-art.sh --verify` answered
   `ok` for every row before the tag.
10. **The lock.** LFT13 passes; at LFL8 the lock was seen live during an install started by a pasted line,
    an update and a second install started meanwhile each stopped with its sentence, and the lock was gone
    after; at LFL2c the same was seen for an install started by a click; at LFL9 a game started during an
    install was asked about first.
11. **The tools.** On a Mac below macOS 14 the launcher's installer stops before it asks Apple for anything
    (LFT2). On a Mac without Apple's tools it asks for them right after its refusals, and LFL7 records the
    seconds from the paste to Apple's box and from the tools' arrival to the window (LFD14); or criterion 3's
    waiver stands, and the as-built header says that this was not measured.
12. The as-built header is written at the build, with what was not measured named, "built on macOS 27 only"
    among it: no step met a compiler older than Swift 6.4.
13. **The order and the transcript.** The steps were built in the order of section 4, and no commit before
    LF4a's names a function of the lock. `cities-skylines-2/scripts/test-install.golden` was recorded again
    in each step that changed a printed line, and each such commit names the lines that changed.

## 9. What is published, and can never be withdrawn

- **The word `launcher`** of the root `install.sh`, from the release whose `release` holds it, and the pasted
  line that ends in it. Like `update`, it is a first word that is not a number and names no game.
- **Nothing that is published changes.** The root `install.sh` and `common/games.tsv` do not move; the table
  keeps its four fields; a game is still named by its Steam app ID in every line; `install.sh update` does
  what it does; `release` still moves only to a tagged commit, by the gate.
- **A contract between versions of the repository:** `common/install-launcher.sh`. The root `install.sh` of
  `release` runs it from whatever ref it fetched (`launcher <ref>`), as it runs the driver of the fetched tree
  for `update`. So three things can never change once `release` holds the word: the script's path, its call
  with no argument, and the meaning of its exit codes (3.4). The form `launcher <ref>` is published with the
  word.
- **A contract on the player's Mac, not an address:** `updates.sh --install <ID>` and its two answers
  (`opened`, `failed` and a sentence); the file `_update/launcher` and its four fields; the lock
  `_update/installing`, its form and the file `_update/installing-game` beside it; the folder `_update/art`
  and its file names. By the tool's own rule (1.4) a later version may add to these and never changes or
  removes one. The lock is read across versions in one more way: an installer of this version and one of a
  later version, run on one Mac, must agree on it.
- **Not published:** `common/tools.sh`, `common/fetch-art.sh` and `common/game-art.tsv`. Each is read or run
  only by code of the same tree, so each may be renamed with it.
- **A new thing the project depends on: the pictures' addresses at Valve** (3.10). They are not the
  project's, and Valve may move or change an image at any time. Then the checksum fails: a Mac that has the
  picture keeps it, a new Mac shows the generic icon, and a release corrects the row. Nothing stops. `bash
  common/fetch-art.sh --verify`, run before a tag, says when it has happened.
- **A new request from a player's Mac, on every route.** The launcher's line, a game's own line and an update
  each ask Valve's servers for every game's picture that is not on the Mac yet (3.10): a game's install does
  so too, through its setup, and not only the launcher's. Valve sees the Mac's address, the time, and curl's
  name. It is said in the guides' line (LF7) and in this release's section of `CHANGELOG.md` (LF6), which a
  player reads in the update's sheet before the yes.
- **A row of the table is shown.** From this version on every row of `common/games.tsv` on `release` is a
  tile in every window built from it. So no row reaches `release` before its installer works, and none is
  removed (3.6).

**What this widens, said in full.** Today whoever can move `release` reaches an installed Mac by one click on
Update, after the notes of the new version were shown (`docs/plans/built-in-update.md`, 3.8). After this plan:

- **A click on a game's tile runs code from `release` too**, in every state but `manual` and, by RD4, `ready`:
  so in `unknown`, `current`, `none` and `off`. In `off` the player has switched the daily check off, and the
  click still fetches: `off` was never a promise that nothing is fetched on a click (3.8 corrects the header
  line that said so).
- **On a new population:** a Mac with the launcher and no game runs nothing of this project from the network
  today, because there is no such Mac.
- **With no version and no notes shown.** The update's sheet shows what changed before a yes. The install's
  sheet cannot: it says that the installer is "fetched now from GitHub" and "may also bring a newer 14unch3r",
  and no more.
- **A yes to one game can update the launcher unannounced.** The game's setup rebuilds 14unch3r from the tree
  it came with and writes the launcher's stamp (3.5). When `release` has moved since the Mac's last daily
  check, the state is still `current`, the click is not held back by RD4, and the window that opens after the
  install is the newer one. The other games on that Mac stay at their version and are then offered the update
  in the ordinary way.
- **The update's guard has no counterpart here.** The driver refuses a fetch that is older than what the Mac
  was already offered (`common/update-games.sh:68-76`); a copy of `install.sh` cached for some minutes after
  a move of `release` can send the older version. A click has no such test. What follows is an install at the
  older version and, within a day, an offer of the newer: it mends itself.
- **Why a click is not pinned to the installed version's tag.** It would close the last three points: the
  click would run exactly the version whose notes the player once accepted. It is declined because the
  installer writes the line it was fetched from into the stamp, and any stamp whose line is not `release`
  makes the Mac `manual` (`common/updates.sh:192`): a Mac whose game was installed by a click would never be
  offered an update again. To avoid that the tool, the root `install.sh` and the stamp's rule would each need
  a second meaning of "which line", on the path every click runs.
- **What does not change:** it trusts nobody new, since `release` is moved by the same hands, forward only,
  under the rulesets on `release` and on the tags; the yes is still asked; the list of games the window shows
  comes from its own bundle, built from a tree a yes installed, never from the network; the tool refuses
  every ID that is not a whole number, and the file it writes holds no other value of the Mac's but curl's
  path.
- **What another account of the same Mac can do** is #29, unchanged: it can change what a tile says (3.7),
  and it could already change a wrapper that a launcher runs.

## 10. Statements this plan ends

Each is corrected in its file in step LF6, with a pointer here; the guides' first step is corrected in LF7's
own commit.

- `docs/plans/built-in-update.md`, UD7, 3.9 and section 11: "The offer still opens the game's set-up guide";
  "An install started from the window" as not planned.
- `docs/plans/launcher-window.md`, 2.5: "Only `owned` adds a row"; "A Mac with no game set up has no prefix to
  read and so shows no offer." And `:333`: the bundle's `LSMinimumSystemVersion` as `13.0`.
- `docs/plans/launcher-window-look.md`, each with an "Extended by" note that names this plan, as
  `docs/plans/built-in-update.md` added them: `:159-162` (offers under the label "You also own", and "a tile
  with a generic icon and no app behind it"); `:239` (the two sentences of an offer); `:242` ("An offer's icon
  is the generic application icon"); `:246` ("an offer opens its guide"); `:564`, D23 ("The
  window cannot open a game's own Steam to install it"); and W14's expectations for an offer at `:475`.
- `docs/plans/surviving-mars-install.md`, MD8: "A later slice, with its own plan."
- `docs/plans/shared-installer.md`, 2.2: "There is no default game", with `update` as its one exception. There
  is still no default game; there are two words.
- `install.sh:21`: "update is the one first word that is not a number".
- `common/make-launcher-app.sh:6` and `common/launcher-window.swift:3`: who builds the window, and what a row
  is.
- `common/updates.sh:10`: "if it exists, nothing is ever fetched" (in step LF4b).
- `common/launcher-window.swift:815`, `Look.updateText`: "for each game set up here" (3.5 has the new
  sentence; in step LF3).
- `common/launcher-window.swift:829-830`, the two answers of "Check for Updates…" on a Mac that is `manual`,
  which a launcher's stamp makes untrue: a Mac can now be `manual` through the launcher alone. In step LF3,
  with `common/test-launcher-window.sh:923` and `:925`. `Look.checkoutText` becomes "14unch3r or a game here
  was set up from a checkout. Update with git pull, then run install.sh launcher and each game's setup."
  `Look.namedText` becomes "14unch3r or a game here was set up from a named version. Paste the installer line
  from the guide again to follow new versions."
- `CLAUDE.md`, the layout table's row for `install.sh` ("given a game's Steam app ID ...").
- The guides' first step, each of which is a game's own line today, in the seven places of 1.1.

## 11. Phasing

**Slice 1, this plan (LF0 to LF7): useful by itself.** One line installs the launcher; its window lists every
game with its own icon; a click and a yes run a game's installer in Terminal; a stopped install is seen and
carried on; one install runs at a time; the update keeps a launcher-only Mac current; a test holds the
contract.

**The fallback inside it is exactly LF1, LF2, LF3 and LF5a**, the first four code steps of section 4's order,
released if the live steps of the window's install find trouble. No line of LF4a, LF4b or LF5b is in it: the
launcher's installer is the one LF2 built, with no lock, and it calls nothing that does not exist. The
launcher is then installable by itself, its window lists every game by its own picture, and a click on one
that is not set up opens its guide, with today's words. That is less than the idea and breaks nothing.
Without LF5a it would not hold: a launcher-only Mac would show "No games are set up on this Mac yet." and
nothing to click (pass 1 found the draft's fallback, LF1 to LF3 alone, false for that reason; pass 2 found
the first rework's, in which LF2 called the lock of LF4a, unbuildable).

- **What LF6 and LF7 then do.** LF6 for what was built: the contract's test, `CLAUDE.md`, the statements of
  section 10 but those about an install from the window (UD7, MD8 and D23 stand), the changelog, the
  as-built header, which names the fallback. LF7 in its order. Its guide commit keeps each game's own line
  first and names the launcher's line second, as the way to have the window before a game: a window that
  cannot install should not be the guides' first step (RC23).
- **Its live steps.** Before the merge: LFL1 (its pass as written, but that a click on a tile opens the
  guide), LFL3 and LFL4. After the merge and before the tag: LFL7. After `release` moves: LFL2c cut to the
  launcher's line, the window with both games in grey, and a click that opens a guide. Not run, since what
  they show is not in it: LFL2a, LFL2b, LFL8 and LFL9.
- **Its exit criteria.** 1, for the tests of those four steps and the cases not marked "with LF4a" or "with
  LF5b"; 2; 3, for the live steps just named; 4; 5; 6, without `installing` and `installing-game`, which
  nothing writes; 7, with the guides' order as above; 8, for the tiles and not the sheets; 9, for a game that
  is not set up, a begun install and the picture taken away, and for LFL4's pictures; 11; 12; 13. Not 10: it
  has no lock.

**What can wait, each a plan or a slice of its own:**

- **Slice 2: what the sheet says before a yes.** The game's needs in its own words (the contract's row 8,
  taken from each installer when the window is built) and this Mac's free space beside them (LFD7, LFD11).
  And the installer's look for another Steam moved to its first step, so that it stops before anything is
  downloaded.
- **Slice 3: an install view inside the window** (3.1), after slice 1 has run on real Macs. On the roadmap
  since 2026-11-26 (LFD1).
- **The games' half of the wait for Apple's tools** (section 14): a plan of its own.
- **A built and signed 14unch3r, and a double-click form of the launcher's installer**, once the project is a
  member of the Apple Developer Program (LFD2; 1.5).
- **The third game**, written against 3.6, with LFL6 as its live step.

## 12. Rollback

- **Before `release` moves:** nothing has reached a player. Revert the commits on `main`. The guides have
  not been changed yet (LF7).
- **After, a wrong release:** a successor, which installed Macs are offered within a day, **while the check,
  the window's update parts and the driver of the wrong release work** (`docs/plans/built-in-update.md`,
  section 10: the same limit, and the same reason to run the suites on the tagged commit). A wrong tile or a
  wrong sheet cannot stop that route: the update's parts are separate. A wrong lock can: an installer that
  never releases `installing` would stop every later update with "An install is running". The boot rule
  bounds that at the next restart, and the file can go to the Trash (below).
- **The word:** it cannot be withdrawn. If the launcher's installer must be stopped, the word stays and its
  script says what to paste instead.
- **A player going back:** a game's line with an older tag after the ID, as today. An older setup rebuilds
  the window without the install parts, leaves `_update/launcher` and `_update/art` unread, and takes no
  install lock.
- **Files:** `_update/launcher`, `_update/art` and a stale `installing`, `installing-game` or `updating` hold
  no game data and can go to the Trash, the three locks only while no install and no update is running.
  14unch3r goes to the Trash like any app; with no game set up, the next update
  then removes its stamp (3.5).
- **After the live steps:** the scratch account is deleted by James, with the shared folder of its outputs.
  What LFL7 left on Erin's iMac, and how each thing is removed, is in that step; Apple's tools stay there
  unless an administrator removes them. After LFL4 both pasted lines put that Mac back and its launcher's
  stamp goes to the Trash (section 7). LFL9's scratch app and folders are removed in that step. Nothing else
  of the Studio's own account was touched.

## 13. Decisions for James

| | Question | Recommended, and why |
|---|---|---|
| LFD1 | Does a game's install from the window run in Terminal, as the update does, or in an install view of the window's own? | Terminal, in this plan (3.1). The installers already ask, wait, stop and carry on there, and all of that is built and measured; an install view needs a way for every installer to hand its questions to a window, a process that outlives the window, and tests for both. Worth a plan of its own once this has run on real Macs. If you already know you want the view, say so now: the third game's installer should then name its questions from the start |
| LFD2 | Is 14unch3r still compiled on the player's Mac, or is a built app shipped? | Compiled there (3.2). The wait for Apple's tools is one every game's installer has anyway; a built app needs either a signature in a legal name or the route that stranded an approval at SL2, and a binary's address that could never move |
| LFD3 | The line that names no game: a new word, `launcher`, or the bare line with nothing after the quote? And is `launcher` the word? | The word `launcher` (3.3). The bare line is an error today, on purpose and under test; a paste cut short should say so and not install something; and a word leaves the bare line free for ever. `launcher` reads as what it installs; `14unch3r` is the app's name but hard to say and to type |
| LFD4 | Does the window list every game the project ports, or only those Steam says the account owns? | Every game (3.7). A Mac with nothing has no Steam to ask, so the other rule shows an empty window to the player this is for. Where ownership is known the tile says so |
| LFD5 | How does an installed launcher learn of a new game: by the built-in update, or by fetching the table of games each day? | By the update (3.5): one route, and the player reads what changed before saying yes. The table from the network would be a second route that can disagree, shown in a window that may be too old for the game |
| LFD6 | After the click on "Install", does the window quit, as after an update? And does the launcher's installer open 14unch3r when it is done? | Yes to both. A window left open would be rebuilt under itself at the end of the install; and after the paste the player's next step is in the window |
| LFD7 | Before a yes, should the sheet say what the game needs (its size, its download) in the game's own words? | Yes, as slice 2 (section 11). Slice 1's sheet says that the installer says it first. It is a small change with its own test, and keeping it out keeps slice 1 to one new option and its sheets |
| LFD8 | On a Mac in the state `manual` (a game or the launcher set up from a checkout or a named version): does a tile's click install from `release` anyway? | No: it says why and offers the guide (3.7, 3.8). Such a Mac asks GitHub nothing today, and mixing lines on one Mac is what `manual` exists to name. It is your two Macs' usual state, so on them the tiles would not install: say if you want the other answer |
| LFD9 | The new files outside the repository, all inside the folder `CLAUDE.md` already names: `_update/launcher`, `_update/installing`, `_update/installing-game` and the folder `_update/art` | Yes. `CLAUDE.md`'s line for `_update` gains them in step LF1, before anything writes them. (The draft asked about the first and a lock per game; the lock's form and the pictures' folder are the rework's, RC1 and RC9, and need this word again) |
| LFD10 | When do the guides lead with the launcher's line, and which number does the release take? | The guides change in a commit of their own right after `release` holds the word (LF7), and the release's notes say that the old lines still work; each game's own line stays in its guide as the second way. The second number rises: a player with an install will notice new tiles. You took the third for `v0.3.1` against the same rule, so this is asked and not assumed |
| LFD11 | When less space is free than the game needs: does the window refuse, or caution? | Caution, in slice 2, as the installer does (1.2): a player may be about to free space or to install without the DLC |
| LFD12 | On an Intel Mac, or a macOS outside what is tested, does the launcher's installer stop? | It says so and goes on; only a macOS below 14, where no game of the project runs, stops it (your word of 2026-11-26, below). The two games already judge an Intel Mac differently, so the judgment belongs to each game |
| LFD13 | One install at a time, whatever the game? | Yes (3.8): each install starts a Steam, and one Steam at a time can use an account. Since the rework the rule is the installer's own lock, so it holds for a pasted line too |
| LFD14 | (Added 2026-11-26, from James's request of 2026-11-25.) Are Apple's Command Line Tools asked for first? | Yes (3.2): in the launcher's installer in this plan. The games' installers, where the wait could overlap the downloads, get a plan of their own (RD2) |

**Decided by James on 2026-11-26.** His words are in quotes.

- **LFD1: Terminal, "ok but put in the roadmap".** An install view inside the window goes on the roadmap.
- **LFD2: compiled on the Mac "until we are a registered developer".** Written as: until the project is a
  member of the Apple Developer Program.
- **LFD4: every game, and "uninstalled games should be gray scale or ghosted".** Refined during the check:
  "If a game is not installed it should show a ghosted or greyed out copy of the icon noting that it's not
  installed and can be." So the tile shows the game's own icon, greyed, with words that say it is not set up
  and can be installed. Where the icon comes from: "the first option" of three, fetched from Steam's public
  artwork when the launcher is installed, held to a fixed size and checksum (the other two: art in the
  repository, and an icon kept from an earlier install). And: "clicking the icon should prompt and ask the
  user if they're ready to install the game": 3.7's sheet, whose message is that question.
- **LFD14: "agree".**
- **The minimum macOS**, said of pass 1's blocker 4: "None of these games would run anything that old. I
  think realistically we can come up several versions." Folded as: the launcher's installer stops below macOS
  14 and cautions below 26, and the window's stated minimum is 14 (3.2).
- **LFD3 and LFD5 to LFD13: as recommended.**

**The rework's defaults, taken with his knowledge on 2026-11-26; he can still change them.** Pass 1 laid
them before him as open, each with this default, and he did not object.

- **RD1. How a click-to-install is proven before the release:** LFL2 becomes LFL2a, LFL2b and LFL2c, and the
  tool gets no rehearsal switch. So the first install from a click through this version's own installer
  happens right after `release` moves; if it fails, each game's own line works as before. The other way was
  a switch by which the tool follows the line the Mac's stamps name: rehearsable from a branch, and more code
  on the path every click runs.
- **RD2. The games' half of the wait for Apple's tools leaves this plan** for a plan of its own (section 14).
- **RD3. A live step on a Mac with none of Apple's tools** (LFL7). James named the Mac the same day: Erin's
  iMac. No guest is made.
- **RD4. In the state `ready`, a click on a game that is not set up says to update first.**

**The rework's own choices, which James has not seen.** Each is one he can overrule; the section named holds
the reasoning.

- **RC1.** The install's lock is one link, `_update/installing`, and the game it installs is named by a file
  beside it, `_update/installing-game` (3.8). The other way was the ID in the lock's name, which cannot
  exclude two games' installs from each other.
- **RC2.** The lock's rule lives in `common/updates.sh` as three functions, read by the core, the launcher's
  installer, the driver and the tool; the driver's own lines for `updating` keep their text, and since
  rework 2 one line before them removes an `updating` that is not live by the rule, the Mac's last start
  among it (3.8, RC25).
- **RC3.** The core takes the lock in `core_begin` and makes the record's folders there; a record folder that
  is not the player's own stops a game's install at its start, where today it stops at the setup (3.8).
- **RC4.** Under `L1_UPDATE=1` an installer takes no install lock and does not look at `updating`; since
  rework 2 only while an update's lock is live (3.8, RC25).
- **RC5.** The launcher's own installer takes the same lock (3.4).
- **RC6.** The shared tools file is `common/tools.sh` with `tools_ask` and `tools_wait`; a part is tried for
  two minutes after the tools' folder appears; in the core a present folder with a broken part still stops
  with no request, as its mutant 24 holds, and "present means runs" applies in the launcher's installer
  (3.2). Changed by rework 2: there too a folder that is there with a broken part stops at once (RC24).
- **RC7.** When Apple's request is not taken, the installer says other words and goes on waiting; it does not
  stop (3.2). LFL7 may tighten this.
- **RC8.** A compiler below Swift 5.9 is exit 3, "will not go on" (3.2).
- **RC9.** The pictures: a table `common/game-art.tsv`; kept in `_update/art/<ID>`, not in the app; fetched
  with a bounded curl line and the checksum rule of `common/fetch.sh`, not with its `fetch` function; the
  window does not check the checksum again (3.10).
- **RC10.** The launcher's stamp is written only by a build that worked; a build that fails during an update
  leaves the Mac `ready` and the update exits 1 (3.5).
- **RC11.** From a checkout, `install.sh launcher <ref>` judges the ref and then does not use it, as for a
  game (3.3).
- **RC12.** The states' names are `not-set-up`, `begun` and `installing`; `owned` stays, for "not set up, and
  in the Steam library" (3.7).
- **RC13.** Words the design lens has not read: the sheets for `manual` and for "update first", every `failed`
  sentence of `--install`, the installers' sentences for the lock, and the launcher's installer's own lines
  (3.2, 3.4, 3.7, 3.8). Pass 2's reviewer of the words has read them since and replaced a number of them; what
  is unread now is RC27's list.
- **RC14.** The order of a click's tests: no tool, `manual`, `ready`, an install running, a game in use, the
  question (3.7).
- **RC15.** The numbering: steps LF4a, LF4b, LF5a, LF5b; new tests LFT12 and LFT13; the tools-less Mac's
  step is LFL7.
- **RC16.** The launcher's installer does not keep the Mac awake (3.4).
- **RC17.** The four short sheets have two buttons, "OK" and "Read the Guide" (3.7).
- **RC18.** The driver's sentence for a game that is downloaded and not set up keeps its text (3.5).
- **RC19.** LFL7 comes after the merge and before the tag (rework 2: it was "before `release` moves", and a
  tag cannot be moved); if it cannot be run, the release may go on James's written word, with the tools stage
  and the paste warning named as unmeasured (section 8).
- **RC20.** A live step that pass 1 did not ask for: LFL8, which starts this branch's installer by a game's
  pasted line with the branch as its ref and stops it during Wine's download, so that the lock, the tile
  "Installing" and the exclusion with an update are seen before the release. No rehearsal switch is added to
  the tool for it (RD1 stands).

**The second rework's own choices (2026-11-26), which James has not seen either.** Pass 2 said what to
correct; these are where the fold had to choose how.

- **RC21.** The pictures step is a file of its own, `common/fetch-art.sh`, run and not read with `.`, which
  exits 0 whatever happened. Besides the two callers pass 2 named (the launcher's installer, and the driver
  whenever the app is there), **each game's setup calls it** after a build of the window that worked, so a
  game's own pasted line brings the pictures too **and makes the request to Valve**; not in an update, where
  the driver fetches once. The other way was to leave a game's line without pictures: the other game's tile
  would then show the generic icon until that Mac's first update. A setup run by hand from a checkout fetches
  as well (3.5, 3.10).
- **RC22.** `fetch-art.sh --verify` is the check that says when Valve has changed an image: run by hand
  before a tag and named under "Releases" in `CLAUDE.md`, not a question of `common/check-release-move.sh`.
  The list of hosts is fixed after LP4. The window passes over a picture of more than 1,024 pixels a side
  (3.10).
- **RC23.** In the fallback release the guides keep each game's own line first and name the launcher's line
  second, since that window cannot install; its live steps and exit criteria are section 11's lists.
- **RC24.** The tools: the settle's polls are named `TOOLS_PART_POLLS`; in the launcher's installer a folder
  that is there with a `swiftc` that does not run stops at once and is not asked about (pass 2's word, which
  changes RC6); the record's folders are looked at among the refusals, before the ask (3.2, 3.4).
- **RC25.** The lock's added rules are pass 2's, and how each is done is the rework's: the read-back after a
  take, which narrows a race and does not close it; `L1_SYSCTL`; one line in the driver that removes a stale
  `updating` (this changes RC2); `L1_UPDATE=1` believed only with a live `updating` (this narrows RC4); **every
  lock sentence names the holder's process**, the driver's and the launcher's installer's too, where pass 2's
  item can be read as the core's line alone; `--install` refuses from a record folder that is not the default
  one, by a default the tool spells itself, and in `off` judges the stamps' lines itself (3.8).
- **RC26.** A live install counts as a blocker for the start of a set-up game or of the Steam app; the
  question's words, and its name `ask-install-running` (3.7).
- **RC27.** Names, and words nobody has read. *Names:* `common/test-fetch-art.sh` as LFT14; the live step
  LFL9; the text modes `--install-sheet`, `--install-answer` and `--install-open`; the functions
  `clickAnswer`, `installAnswer` and `tableOffers`; the header line `# Terminal questions: <n>`. *Words
  written by rework 2* (pass 2's replacements are in place word for word and are not in this list): the
  stop below macOS 14 as one line with the version in it, the caution below macOS 26, the caution for a
  version that cannot be read and the Intel caution (3.4); the installer's closing line in an update, "Done.
  14unch3r is rebuilt." (3.4); the tool's sentence for `manual`, which cannot name a folder (3.8); the
  question before a game is started during an install (3.7); the middle of the pictures' line, "14unch3r
  shows a plain icon for it while it is not set up" (3.10); the three answers `--verify` prints (3.10). *In
  LFL7:* the line is copied from this file's page on `main`; whether the first request was taken is read from
  the installer's words, and the exit code with a box up from a second Terminal window.

## 14. Not in this plan

- **An install view inside the window**, and questions that have names (3.1; slice 3).
- **A built or signed 14unch3r**, and a double-click installer of the launcher (3.2): until the project is a
  member of the Apple Developer Program (LFD2).
- **The games' half of the wait for Apple's tools: a plan to be written** (RD2). In a game's installer the
  wait could fall inside the downloads; that means moving it later in the shared core, and it is not done
  here. Its starting facts, read by pass 1's builder and correctness lenses **[record]**, and for the two
  lines cited read again by the rework **[read]**:
  - in the core, nothing before a game's setup runs one of Apple's tools;
  - Cities: Skylines II first needs `python3` at its step 6 (`cities-skylines-2/scripts/setup.sh:297`), so its
    wait could cover the wrapper, Steam and the whole download;
  - Surviving Mars needs `nm` inside its step 4 (`surviving-mars-relaunched/tools/make-engine.sh:103`), before
    Steam and the game, so only the wrapper's and D3DMetal's downloads could overlap;
  - these are not shims of the tools, and run without them: `plutil`, `codesign`, `sips`, `iconutil`, `curl`,
    `tar`, `xattr`;
  - a box dismissed at the start would be met hours later, with nothing downloading: that case has no design;
  - its live step needs a Mac without Apple's tools, which Erin's iMac no longer is once LFL7 has run; and
    it starts from `common/tools.sh`, which this plan makes.
- **The table of games fetched from the network** (3.5).
- **Game art in the repository** (3.10).
- **Removing a game.** There is no uninstaller; the guides' Uninstall sections stand.
- **Buying a game, or signing in to Steam, from the window.** The installer still sends the player to Steam's
  own window.
- **Installing two games in one go.** One click, one game, one at a time.
- **A change to `common/games.tsv`'s shape**, or joining it with `common/wrappers.sh`'s table (3.6).
- **The installers' own steps, but for five changes.** The games' installers do change in this plan, and
  the draft's sentence that said otherwise is gone: both setups write the launcher's stamp (LF1); both setups
  run `common/fetch-art.sh` after they built the window, and both installers test that its files are there
  (LF2); the shared core reads `common/tools.sh` for its tools stage (LF2); the shared core takes the
  install's lock (LF4a); and the five files gain the header line that counts their questions (LF6). Nothing
  else of an installer's steps changes. LP2 and LP3 may find things that are theirs to fix.
- **A lock for a setup run by hand** (3.8).
- **What `xcode-select --install` gives with no screen session**, and a build of the window with a compiler
  older than Swift 6.4: no step of this plan reads either (3.2, LP1).
- **Macs set up before `v0.3.1`.** They need one paste per game before any update reaches them
  (`docs/plans/built-in-update.md`, section 11).
- **The third game itself.**

## What this draft could not verify

- **Whether 14unch3r compiles with a compiler older than Swift 6.4**, and so on a macOS older than 27 (LP1
  has one measurement, on macOS 27.2.1). That Command Line Tools 15, on macOS 14, bring Swift 5.9 or later is
  pass 1's platform lens's word, not a measurement.
- **That a file fetched by curl and a built app with no quarantine open with no question on a new Mac.**
  Read in `docs/plans/simple-install.md`, 1.5, which cites it and did not measure it; the Studio's own builds,
  and LP1's binary, are the only measurements.
- **What macOS shows when 14unch3r hands an install's file to Terminal on a Mac that has never done it.** UL1
  saw no dialog, once, on the Studio.
- **Apple's box and its request:** what `xcode-select --install` exits with when it puts up the box and with
  a box already up, whether a standard account is asked for an administrator, and how long after the folder
  appears the tools run (LFL7). What it gives with no screen session: no step reads it. That a request on a
  Mac which has the tools' folder brings no box is pass 2's record. The stage this plan shares out has never
  run for real on a Mac of the project. Whether Erin's iMac is free of the tools is read in Finder when LFL7
  begins, not before.
- **The second form of the line `swiftc --version` prints** (3.2) is pass 2's record: rework 2 ran no
  compiler.
- **That the size in pixels can be read from a picture's header before it is decoded** (3.10): [inferred],
  not tried.
- **Apple's page on the paste warning** (1.5) was read by pass 1's platform lens, not by the rework, which
  made no network request.
- **Everything about the pictures at Valve** (LP4): which image, its address, its format and size, whether
  its bytes are stable, whether `NSImage` reads it. If LP4 fails, 3.10 does not hold as written.
- **What Steam does on a full disk, and with the macOS Steam app open** (LP2, LP3).
- **That `touch -h` sets a link's own time** (LFT13's fixture): **[inferred]**, not run. A clock set back
  between a start and an install can make a fresh lock look older than the start: the boot rule fails open
  there, and 3.8 now says so. How far the read-back after a take narrows the race of two takers was reasoned
  and not run.
- **Which existing test cases change.** The list in section 6 is from the files' headers and the lines cited,
  not from a read of each file. In particular, how many cases of both games' `scripts/test-install.sh` meet
  the record's folders once the core makes them was not counted, nor how many cases of both games'
  `scripts/test-setup.sh` reach the pictures' call, nor which lines of `test-install.golden` each step
  changes: the steps read that difference when they record it.
- **Which older mutants are anchored on the lines this plan touches** in the two setups,
  `common/update-games.sh` and `common/updates.sh`. For `common/install-core.sh` the rework read four anchors
  of the tools stage (3.2) and looked for none on `core_begin` or `on_exit`, where the lock goes. Pass 1's
  builder typed in LF1's row and LF2's word and saw the older mutants of those two files stay red. Rework 2
  read three more **[read]**: mutant 74 of Cities: Skylines II's `scripts/test-install.sh` on the installer's
  line that tests for `common/updates.sh` and `common/games.tsv` (`:181`); mutants 11 and 13 of
  `common/test-update-games.sh` on the driver's take and its trap (`:55`, `:57`); and mutants 62 and 63 of
  the first file on two lines inside `on_exit` (`:170-171`), which keep their text when the lock's release is
  added beside `common/install-core.sh:73`. A search of both games' `scripts/test-install.sh` for the core's
  own-files line and its `caffeinate` line found no mutant on either. The setups and `common/updates.sh` were
  not searched in this way.
- **The hosts the pictures may come from** (3.10) are not known before LP4, so the list in the row rule and
  in LFT7 cannot be written before it.
- **The numbers pass 1's design lens measured** (the second lines fit the tile; the label is 123 points; 654
  points with four rows) are its record. The words the reworks wrote (RC13, RC27) were not measured against
  the tile or the sheet, and pass 2's replacements for the short sheets are longer than what they replace.
- **The `find` of LFL1** looks above a `1launcher` folder in `~/Library`, which `CLAUDE.md` forbids. It is
  written as James's own act in an empty account; if he would rather not, the measurement falls back to the
  places `CLAUDE.md` names, each looked at by its path.
- (Struck by the session that audited the rework: the root `README.md`'s "Roadmap" does hold the install view,
  as its own item, "An install that runs inside the 14unch3r window"; nothing is owed there.)
- **The siblings' precedents** (1.6): the search is still not run.
- **Line numbers** are of `91cfb63`, and of `dc990de` for the guides and for what the rework cites. Three of
  the files read are long and were read in parts: `common/launcher-window.swift` (by the draft: its header,
  `:128-312`, `:440-508`, `:639-836`, `:1606-1984`; by the rework also `:955-1000`, `:1055-1100`,
  `:1140-1192`, `:1248-1275`, `:1401-1440`, `:1505-1530`), and the two setups (their headers and the lines
  cited). Rework 2 read at `e40cd4d`: `common/updates.sh`, `common/update-games.sh`, `common/fetch.sh` and
  `common/paths.sh` whole; `common/install-core.sh` at `:1-110`, `:260-400` and `:425-436`; the window's
  source at `:10-46`, `:153-176`, `:263-275`, `:396-412`, `:700-712`, `:790-836`, `:986-1000`, `:1070-1082`,
  `:1524-1537`, `:1760-1812` and `:1846-1880`; Cities: Skylines II's `scripts/test-install.sh` at `:1-30`,
  `:70-100`, `:126-142`, `:170-182`, `:486-498`, `:712-726`, `:822-830` and `:866-888`; and both setups at
  the lines it cites. A claim about a part not listed here is marked [inferred] or [record], or is absent.

## Review corrections (check-it 2026-11-26, pass 1): needs-rework

Seven lenses, each an agent on Fable reading the plan against the code at `93868e3`: architecture, security,
correctness, a builder, design, Apple platform facts, and the test plan. Two said needs-rework (architecture, test
plan) and five build-ready-with-fixes. Every blocker below was then read in the code or the plan by the session
that ran the pass, and holds. **Reworked 2026-11-26: every blocker and every item below is folded into sections
1 to 14, and each carries a line "Folded (rework 1)" that says where.** This section is kept as the record of
what pass 1 found, in its words; where it and the sections above differ, the sections above are the design.
The fold is unchecked: a second pass reads it.

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
- **The minimum macOS**, of blocker 4: "None of these games would run anything that old. I think realistically we
  can come up several versions."

Folded (rework 1): 3.7 (the picture, the sheet), 3.10 (the pictures), 3.2 (the minimum), section 13.

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
   - Folded (rework 1): section 7 (LFL2a, LFL2b, LFL2c, LFL3, LFL4), section 8 (criterion 3), 3.5 (the closing
     block), LFT4, section 13 (RD1).
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
   - Folded (rework 1): 3.8 (the lock, the option), 3.4 (steps 1 and 3), 3.7 (the state installing), 3.9, LF4a,
     LFT13, LFT3, LFL8, section 8 (criterion 10), section 9, section 12, section 14, section 13 (RC1 to RC5,
     RC20).
3. **On a Mac with only the launcher, the keyboard reaches no tile** (design). The window selects from the set-up
   apps only (`common/launcher-window.swift:250-253`, `:1183`); arrows need a selection (`:1269`) and Return
   needs a chosen row (`:1255`). **Correction:** with no app, the first not-set-up tile is selected; LFT6 gains
   the case and a mutant; the group's help says "to start it or set it up".
   Folded (rework 1): 1.3, 3.7 (the selection and the keys), LF5a, LFT6.
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
   - Folded (rework 1), with James's word on the minimum in place of "Command Line Tools 15 or later": 3.2 (the
     minimum macOS, the compiler check), 3.4 (steps 1, 5 and 7), 1.3, LP1, LFT2, section 8 (criterion 11),
     section 13 (RC8).
5. **No live step runs on a Mac without Apple's tools** (platform facts, correctness, test plan). LFL1 is on the
   Studio, where the tools are system-wide; the existing tools stage has never run for real on any Mac of the
   project; exit criterion 9 names a step that cannot observe it. **Correction:** a live step on a Mac or a macOS
   guest with no tools (the launcher needs no Wine, graphics card or Rosetta, so a guest serves), on James's word.
   Folded (rework 1): LFL7, section 8 (criteria 3 and 11), section 13 (RD3, RC19).
6. **Nothing joins the real installer to the real builder and window** (test plan). LFT2 uses a stand-in builder
   and LFT6 passes `--update-dir`, which wins over the bundle's key (`:34`); a missing key turns the tile into
   "opens the guide" with no error. A release whose window, installed from nothing, cannot install would pass
   every gate. **Correction:** LFT12 in `common/test-make-launcher-app.sh`: a scratch home, the real
   `install-launcher.sh` and builder; the app's `L1UpdateDir` is the scratch `_update`, `--update-tool` prints the
   deployed tool, `--list --games` prints one offer row per table row. Mutants: step 4 after step 5; the table
   not copied.
   Folded (rework 1): LFT12 (section 6), LF5a.
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
   - Folded (rework 1): 3.2 (`common/tools.sh`, the order, "present means runs"), 3.4, 1.2, LF2, LFT2, LFT11,
     section 14 (the games' half and its starting facts), section 13 (RD2, RC6, RC7). The rework found a fourth
     anchor the builder's three did not name: mutant 27 of Cities: Skylines II's `scripts/test-install.sh`
     (`:132`), on the "not installed yet" line; 3.2 keeps that line in the core.

### To fix in the rework (each with its lens)

- **Section 9, what is widened** (security). A tile's click runs `release` in every state but `manual`, on a new
  population (launcher-only Macs), with no version and no notes shown; and the game's setup also rebuilds
  14unch3r and restamps the launcher, so a yes to one game is an unannounced update. Say all of it; the sheet says
  that the installer is fetched now from GitHub and may bring a newer 14unch3r; in the state `ready` the click
  says to update first. Record why pinning a click to the installed tag is declined.
  Folded (rework 1): section 9 ("What this widens, said in full"), 3.7 (the sheet's text), 3.8, RD4.
- **3.7 reads wrappers any account can write** (security; issue #29). "Begun" and "Installing" come from a
  wrapper's `Info.plist` and `.launcher.lock`. Name #29 in 3.7 and section 9; take "Installing" from the install's
  lock only; give the one-button sheets "Read the Guide".
  Folded (rework 1): 3.7, section 9, LFT13, RC17.
- **The driver's launcher step, 3.5** (architecture, correctness, builder). `own_app` returns 0 for an absent app
  (`common/make-launcher-app.sh:48`) and cannot be sourced: the driver needs its own "exists and is the builder's
  app". Name the launcher's row in `_l1u_stamps` (`_l1u_state` skips an empty first field, `common/updates.sh:190`)
  and its reader. Give the closing line and exit code for a launcher that is current with no game, and for a stamp
  newer than the fetch.
  Folded (rework 1): 3.5, LFT3, LFT4.
- **A failed compile now blocks `current`** (architecture): the launcher's stamp makes the window's build count,
  where today it is "never counted as a problem". Decide and say it.
  Folded (rework 1): 3.5 (the stamp is written only by a build that worked), 3.9, LFT5, section 5, RC10.
- **Two meanings of "set up"** (architecture): the driver's (wrapper and program) and the window's (the app). A
  game downloaded with its setup unfinished is "begun" to one and "paste its line" to the other.
  Folded (rework 1): 3.5 ("Set up" has two meanings), RC18.
- **The fallback of section 11 is false** (architecture): without LF5 a launcher-only Mac shows "No games are set
  up". Split LF5 into the listing (a click opens the guide) and the sheet with the install; the fallback is LF1
  to LF3 plus the listing.
  Folded (rework 1): section 4 (LF5a, LF5b), section 11.
- **The guides are read from `main`** (architecture, test plan): the table's addresses are `blob/main`, so a guide
  that leads with the launcher's line before `release` holds the word sends a player to an error. The guide edit
  is its own commit after `release` moves.
  Folded (rework 1): 1.1, LF7, section 8 (criterion 7), section 10, section 12.
- **The contract, 3.6** (architecture, correctness, test plan). Row 9 is false: `l1w_games`
  (`common/wrappers.sh:47`) and the per-game folders of `common/paths.sh:28-31` are second lists a third game
  must join. Row 7: "stop when nobody answers" is true of the licence and Rosetta questions only; "Press Return"
  goes on, and the Desktop question is a fourth kind. No row gives a game its picture: the art's table does now.
  LFT7's "every `read` under a test of the terminal" is not typable as written.
  Folded (rework 1): 3.6 (rows 7, 9 and 10, and the rule for a row), LFT7, 1.2.
- **The window** (design, builder). The new tiles belong in the first `reload()`, not behind the ownership
  question. `--list` takes no `--update-dir` today. What a click does is decided in `startChosen` (`:1766`), which
  no text mode builds: it needs a pure function and source gates, as the update's sheet has. `runChild` (`:402`)
  returns nothing alike for any failure, so "the older-tool sentence" is every no-answer's. Names for the three
  states; tooltip and spoken words for each (today's spoken words say "opens the set-up guide"). Only the icon is
  grey and at 0.5: the title and second line stay at 1 and 0.88, so the contrast lines hold. "A game that is set
  up is never drawn so" is false: a set-up game that is not installed in Steam is grey today, and tested. The
  second lines fit (measured with the window's fonts); the height stays inside 600 until four rows.
  Folded (rework 1): 3.7 throughout, 1.3, LFT6, LFT10, LFT13.
- **The words** (design). The sheet's text says "asks before it fetches anything under a licence", true of one
  game only; "from here" is unclear once the window has quit. The `manual` sentence says "the games" where only the
  launcher may be on a checkout, and the window knows the state before the click, so it shows the one-button
  sheet at once. Three buttons is this window's first: record it in the look's document and capture it.
  Folded (rework 1): 3.7 (the words, the sheets), 3.8, LFL1, LFL2b, section 8 (criterion 8), RC13.
- **The look's document** (design): section 10 names `docs/plans/launcher-window-look.md`'s statements that end
  (`:159-162`, `:238`, `:242`, `:246`, `:564`, W14's offer expectations at `:475`).
  Folded (rework 1): section 10 (the offer's row of that table is `:239`).
- **Tests** (test plan, builder). LFT8 starts at the tree's version and passes on "holds the tree's version": start
  it older. LFT2 gains: tools arriving mid-wait, tools present but not running, an Intel Mac, a signal during the
  build. The cases that run the written file belong in `common/test-update-games.sh`; add a failed fetch (000,
  404, 500), a hangup, and a record folder whose name holds a space, a quote and `$(touch X)`. A dead install lock
  must not read as installing. LFT1 gains `launcher <ref>` and its mutant. LFT9's "every older mutant still red"
  is a hand-run practice recorded in the as-built header, not a gate, and "none refused" is false at baseline
  (`cities-skylines-2/scripts/test-setup.sh:126` retires one): say so. LFT10's first mutant repeats an existing
  kill. LFL1's pass conditions become measurements, and it gains the dark and light captures.
  Folded (rework 1): section 6 (LFT1, LFT2, LFT3, LFT8, LFT9, LFT10, LFT13), LFL1. LFT8 does not start with
  `offer` at the tree's version: RD4 would refuse the click, so `offer` is raised after the tool has opened.
- **Platform facts to restate** (platform facts). The paste warning of macOS 26.4 is documented by Apple
  (support.apple.com/guide/security/sece3b202c4b): Terminal not opened in 30 days, no developer tooling found,
  the paste from a browser or a message; so the Studio can never show it, and LFL2c's Mac must qualify.
  `softwareupdate` does need an administrator. LFD2's condition is "a member of the Apple Developer Program"
  (99 USD a year; an individual's signature carries the legal name). The compile takes 27 s cold on the Studio and
  the builder prints nothing meanwhile.
  Folded (rework 1): 1.5, 3.2, 3.4 (step 7), LFL7, LFL2c.
- **Small ones** (correctness). The pasted line stands seven times, not six (`cities-skylines-2/README.md:30` too,
  which is that game's guide address). 3.4 step 4 names two folders where both setups test and make three, the
  parent first. `install.sh:21` belongs in section 10. "Three kinds of tile" heads a table of four.
  Folded (rework 1): 1.1, 3.4 (step 3), section 10, 3.7, and the other small ones of the correctness lens in
  1.1 to 1.5, 3.1, 3.2 and 3.4.

### What the rework still has to decide or probe

- **The art.** Which of Steam's images is the game's own icon, and its address: a probe fetches it for both games
  and compares it with the icon of the set-up app. A table of its own (app ID, address, size, checksum) and not a
  fifth field of `common/games.tsv`, whose shape is published. What a tile shows when the fetch fails or the Mac
  is offline: the generic icon, as today. The launcher's installer then makes a request to Valve, which it does
  not today: the guides say so.
  Folded (rework 1): 3.10, LP4, LFT2, LFT10, section 9, 3.6 (row 10).
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
  Folded (rework 1): section 13 (RD1 to RD4, as the rework's defaults, taken with his knowledge), 3.10 and LF7
  (the guides' line).

### Second-pass re-check (2026-11-26, pass 2): needs-rework, narrowly

Three reviewers on Fable read the rework at `a36692b`: correctness with a build on paper, security, and one for
architecture, the tests and live steps, and the words. About 180 new statements about the code were opened: about
174 hold. The lock's design holds, and so does the pictures' trust. **Three blockers, each a fault of the fold,
each read again in the plan by the session:** two reviewers called the plan build-ready-with-fixes and one
needs-rework; all three asked for one fitted check of the fold that follows, not another fleet.
**Reworked 2026-11-26 (rework 2): every blocker and every item below is folded into sections 1 to 14, and each
carries a line "Folded (rework 2)" that says where.** This block is kept as the record of what pass 2 found, in
its words; where it and the sections above differ, the sections above are the design. That fold is unchecked:
the fitted third pass reads it. The choices the fold had to make are RC21 to RC27 (section 13).

**Blockers**

1. **On a Mac that has a game, the pictures are never fetched** (all three reviewers). Only the launcher's
   installer fetches (3.4 step 6; 3.10); the driver skips that script when a game's setup has just written the
   launcher's stamp (3.5), which is every ordinary update, and the setups fetch nothing. So every player coming
   from `v0.3.1`, every player whose first paste was a game's line, and every new game's tile shows the generic
   icon for good, against James's own decision; LFT4 as written pins the fault. **Correction:** the pictures step
   becomes a small file of its own (`common/fetch-art.sh`), called by the launcher's installer and always by the
   driver's launcher step when its own test finds the app, before the stamp tests; it makes no request when every
   file matches. Say what a game's own pasted line does. LFT4 gains the case and the mutant "pictures skipped when
   the launcher is current". A changed row keeps the old file until the new one verifies.
   Folded (rework 2): 3.10 (the file, its callers, the fetch, a changed row), 3.4 (steps 1 and 6), 3.5 (the
   setups' call; the driver's step, "The pictures, first and always"; the bullet for a stamp at the fetched
   version), 3.6 (rows 3, 5 and 10), 3.9, LF2 and LF3, section 5, LFT2, LFT4, LFT5, LFT12, LFT14, LFL1, LFL3,
   LFL4, section 8 (criteria 6, 7 and 9), section 9, section 14, RC21 and RC22. A game's own pasted line
   fetches too, through its setup.
2. **Steps LF2 and LF3 cannot pass their own tests in the order given** (correctness, architecture). The
   launcher's installer takes the lock and LFT2 and LFT4 have lock cases and lock mutants, but the lock is built in
   LF4a, after them; the fallback release of section 11 then ships an installer that calls functions that are not
   there. **Correction:** the order is LF1, LF2, LF3, LF5a, LF4a, LF4b, LF5b. LF2's installer has no lock; the lock
   cases and mutants of LFT2 and LFT4 are listed under LF4a, where the launcher's installer and the driver gain the
   lock. Section 11 names the fallback's steps (LF1 to LF3 and LF5a), its live steps and its exit criteria.
   Folded (rework 2): the reading guide at the head, section 4 (the order, and every step's text), 3.4 (the
   lines marked "(LF4a)"), section 6 (the cases and mutants of LFT2, LFT4, LFT6, LFT10 and LFT12 marked "with
   LF4a" or "with LF5b"), section 11 (the fallback, its live steps and criteria), section 8 (criterion 13),
   RC23.
3. **LFL7's order cannot show the paste warning** (correctness, architecture; the order was written by the
   session, not the rework). The warning needs a Mac with no developer tools (1.5); the step put James's account
   first, which installs the tools for the whole Mac, and then called Erin's account "the paste warning's case".
   **Correction:** the first paste is in the account whose Terminal has been unopened longest (Erin's), with the
   tools absent: that one run reads the warning and Apple's box. The second account is the with-tools path only.
   The pre-check is done in Finder (Go to Folder for `/Library/Developer/CommandLineTools` and
   `/Applications/Xcode.app`; About This Mac), not in Terminal. The step gains a pass condition (LFL1's); the
   request's exit codes are read before Install is pressed; the ssh reading is struck (it needs Remote Login
   switched on on someone else's Mac); the ref is named (`main` after the merge); it runs before the tag, since
   a tag cannot be moved; a launcher kept there is in the state `manual` and installs nothing until the published
   line is pasted after the release. LP1 and section 11 still say "LFL7's guest". No step meets a compiler below
   6.4, so the as-built header and the guide say "built on macOS 27 only".
   Folded (rework 2): LFL7, rewritten; the live steps' order at the head of section 7; LP1; 3.2 ("What has
   been measured", `tools_ask`); LF6 and LF7; section 8 (criteria 3, 7, 11 and 12); section 12; section 13
   (RD3, RC19, RC27); section 14; "What this draft could not verify". The guest was in LP1 and section 12,
   and is gone from both.

**To fix in the same fold**

- **The golden transcript** (correctness): `cities-skylines-2/scripts/test-install.sh:870-881` fails when the
  transcript differs from `test-install.golden`, and it will. The steps that touch the core each end with the
  golden recorded again and the difference read; the file is named under the tests that change.
  Folded (rework 2): 1.2, section 4 ("The transcript", LF2, LF4a), section 6 (existing tests that change;
  LFT11), section 8 (criterion 13).
- **Mutant numbers:** the last of `cities-skylines-2/scripts/test-install.sh` is 76, so new ones start at 77.
  Folded (rework 2): section 6, its first paragraph.
- **The tools file:** `common/install-core.sh:333-342` changes, not `:333-341`; the 24 polls of the part get a
  name set by the caller. The line `are not installed yet."; exit 4; }` stays in the core, literally: mutant 27's
  `sed` reaches only the core. A tools folder that is there with a part that does not run stops at once with the
  Software Update sentence, as the core does today; the two-minute settle applies only when the folder appeared
  during this run. The own-folder test of `_update` (no write) joins step 1 of the launcher's installer, before
  the ask.
  Folded (rework 2): 3.2 (`common/tools.sh`, the call sites, "present means runs", the order), 3.4 (steps 1,
  2 and 4), 3.9, LF2, LFT2, LFT11, RC6 and RC24.
- **`off` hides `manual` and `ready`** (`common/updates.sh:188` returns before the stamps are read): in `off`,
  `--install` judges the stamps' lines itself, so that a Mac on a checkout does not install from `release`.
  Folded (rework 2): 1.4, 3.7 (line 6), 3.8 (the option's refusals), 3.9, LFT3, LFT6, RC25.
- **The lock** (security, correctness, architecture). Every taker removes `installing-game` right after taking
  the link, and a game then writes it beside its place and renames. After `ln`, `readlink` must equal the taker's
  own number, else it refuses (a folder planted at the name; two takers of one dead holder). The driver gains one
  line: a `updating` that is not live by the boot rule is removed before the lock is taken, so a stale one cannot
  block both the update and, through "update first", the install. `L1_UPDATE=1` is believed only while an update's
  lock is live. With a record folder that is not the default, `--install` refuses with the `manual` sentence. The
  boot rule compares two clocks and fails open (a live lock read as dead lets a second install start, today's
  state): say so. The launcher's installer releases the lock before it opens the window. Section 12 names
  `updating` among the files a player may remove. LFT13's stub for `sysctl` needs a named test variable: every
  function of `updates.sh` sets `PATH` itself (`:41`).
  Folded (rework 2): 3.8 (the game file, the read-back, the driver's line, the two clocks, `L1_SYSCTL`,
  `L1_UPDATE=1`, the refusal for a record folder elsewhere), 3.4 (step 9), LF4a, section 6 (its first
  paragraph, LFT2, LFT3, LFT4, LFT8, LFT13), section 12, section 14, RC2, RC4, RC25.
- **Starting a set-up game while an install runs** pushes the installer's Steam off, which is LFD13's own
  reason: the window treats a live install as it treats a busy game (Don't Start, Start Anyway).
  Folded (rework 2): 1.3, 3.7 ("Starting a game that is set up while an install runs"), 3.9, LF5b, section 5,
  LFT6, LFT13, LFL9, section 8 (criterion 10), RC26.
- **The picture's fetch, pinned** (security). The hosts are a short list fixed after LP4, held by the installer's
  row rule and by LFT7; a row over 1,048,576 bytes is refused (the window reads at most that); the curl line is
  written out (`-q --proto '=https' --tlsv1.2 -sS --max-time 20 --max-filesize <size> --max-redirs 0 -o <temp>
  -w '%{http_code}' <address>`), kept only on exit 0, code 200, the size and the checksum; stale temporary files
  are cleared. The window bounds the picture's pixel size and greys it once per reload, not at every paint. The
  request to Valve is said in this release's changelog section, which a player reads before the yes, and names
  what Valve sees (the address, the time, curl's name). A check before a release move says when Valve has
  changed an image.
  Folded (rework 2): 3.10 (the table's row rule, the fetch written out, what the window does, the privacy
  paragraph, `--verify`), 3.6 (row 10), LF5a, LF6, LF7, LFT7, LFT10, LFT14, section 8 (criteria 6, 7 and 9),
  section 9, RC22.
- **Section 9:** `common/install-launcher.sh` is run by the root `install.sh` of `release` from whatever ref it
  fetched: its path, its call with no argument and its exit codes are a contract, as the driver's are, and so is
  the form `launcher <ref>`.
  Folded (rework 2): section 9 ("A contract between versions of the repository"; "Not published"), 3.3, 3.4
  (the exit codes).
- **Existing sentences that a launcher's stamp makes untrue** join section 10: `checkoutText` and `namedText`
  (`common/launcher-window.swift:829-830`). New words: "14unch3r or a game here was set up from a checkout.
  Update with git pull, then run install.sh launcher and each game's setup." and "14unch3r or a game here was set
  up from a named version. Paste the installer line from the guide again to follow new versions."
  Folded (rework 2): 1.4, section 10, LF3, section 6 (existing tests that change).
- **The words** (replacements, exact). `tell-manual`: "`<title>` is not installed from this window on this
  Mac." / "14unch3r or a game here was set up from a checkout or a named version. From a checkout: bash
  `<folder>`/scripts/install.sh. Otherwise paste the game's line from its guide." `tell-update-first`: "A newer
  version is out. Click the line at the foot of this window to update, then click the game again."
  `tell-installing`: "Only one install runs at a time. Its Terminal window shows how far it is; click this game
  again when it has finished." `tell-quit-first`: "Quit `<title>`", not "Quit it". The core's lock line names the
  process, as the driver's does. The record folder's line: "... is not a folder of your own that only you can
  write to. In Terminal: chmod go-w `<folder>`, then try again." macOS below 14: the version found, and "Update
  macOS, then paste the line again."; the caution below 26 and the Intel caution have no text yet: write them.
  The pictures' fallback: "The picture of `<title>` could not be fetched ... Pasting the line again tries
  again." The build: "This can take a minute; nothing is printed meanwhile." A failed build adds the guide's
  address. The setup's line for a failed build: "... until it can be built: the line above says why." The closing
  line adds "You can close this window." "Apple's Command Line Tools" is the project's term throughout.
  Folded (rework 2): 3.7 (lines 2 to 5), 3.8 (the lock's sentences, the tool's refusals), 3.4 (steps 1, 7 and
  9), 3.2 (the compiler's sentence, the failed build), 3.5 (the setup's line), 3.10 (the pictures' line), 3.9,
  LFT2, LFT5. The tool's own sentence for `manual` cannot name the game's folder and is the rework's (RC27),
  as are the two cautions. Every lock sentence names the process (RC25).
- **Live steps and criteria.** A step in the form of the update's UL1 (a scratch `_update`, a fixture app,
  hand-written stamps, offer and lock) shows all five sheets in both appearances before the merge:
  `tell-update-first` and `tell-quit-first` reach no screen otherwise. LFL2c pastes "the guide's launcher line",
  which the guides do not hold until after it: give it the line. The captures criterion 9 wants (begun,
  installing, no picture) are assigned to LFL2b, LFL8 and LFL1. LFL4's pass is boot-verify PASS, Surviving Mars
  starts, and the stamps' fields; it removes the launcher's stamp it left. Criterion 4 names its test.
  Criterion 11 carries the waiver's "or". LFL2b's "no tiles for games not set up" is wrong for `v0.3.1`'s window
  once a prefix exists.
  Folded (rework 2): LFL9 (new), LFL2c, LFL1, LFL2b, LFL8, LFL4, section 8 (criteria 3, 4, 8, 9 and 11).
- **Tests with no mutant or no case.** The order of the click's tests (a combined case: `manual` with an install
  running); a short sheet never answers `open`; the macOS stop and both cautions at their boundaries (14.0,
  26.0); Swift 5.10 against 5.9 (a decimal compare would stop it) and both forms of `--version`; `tools_ask`
  keeping the request's exit code; the take-then-look order of the two locks; LFT12 goes on to `--act start`
  giving `ask-install`; `LSMinimumSystemVersion`; the picture's size test and its time limit. LFT6's three "new
  text modes", the click's pure function and the function that makes the not-set-up rows need names. LFT7's
  count of terminal reads against "the number its header lists" has no header to read: define the header line and
  say LF6 adds it to five files. LFT11 names Surviving Mars's test file, which has no tools case.
  Folded (rework 2): LFT2, LFT4, LFT6, LFT7, LFT10, LFT11, LFT12, LFT13, LFT14; 3.7 (the names `clickAnswer`,
  `installAnswer`, `tableOffers` and the three text modes); 3.6 (row 7, the header line); LF6.
- **Struck:** 3.1's "the README does not yet name the view" (it does, `README.md:97`).
  Folded (rework 2): 3.1.

### Third-pass re-check (2026-11-26, pass 3): needs-rework, narrowly; and one decision changed

One reviewer on Fable, fitted to the second fold (`446ef08`). Every item of the second-pass block was traced to
its sections, its step, its test and mutant, its live step and its exit criterion; about 75 of the second fold's
citations were opened and all hold. The labels are each defined once, and the order of steps is stated the same
way in all four places. Two faults fail a step or a test as written; the session read both in the code.
**Nothing below is folded into sections 1 to 14 yet.**

**The decision James changed (2026-11-26, after pass 2):** "Maybe we should just include a placeholder icon in
the repo", and of the two ways put to him, "The first": **a game that is not installed shows a placeholder drawn
by the program, one per game: a greyed tile with the game's initials, in the window's own style. No image file,
and nothing fetched from Valve.** The game's real icon appears once the game is set up, taken from the game's own
program as today. This replaces his choice of earlier that day (the icon fetched from Steam's public artwork).
What it removes from sections 1 to 14: `common/game-art.tsv`, `common/fetch-art.sh` and every call of it (the
launcher's installer, both setups, the driver), the folder `_update/art`, the probe LP4, the test row for the
fetch, the contract's row for a game's art, the request to Valve and its lines in section 9, the guides and the
changelog, and the decisions the reworks made about the fetch. What it adds: a function that draws the
placeholder from the game's title (the rule for the initials, written out, with the three titles the project
knows as its examples: "Cities: Skylines II", "Surviving Mars: Relaunched", "Workers & Resources: Soviet
Republic"), drawn in the window's own greys by the rule a greyed tile has; a field of `--grid` that names what a
tile draws, so a test can read it; a test with its mutants; a capture at a live step.

**Faults of the second fold**

1. **LFL9 cannot pass as written** (a step in the update's UL1 form that shows the five sheets). The window
   chains a refresh after the state at every open (`common/launcher-window.swift:1831-1835`); with a stamp on
   `release` and no `tried`, the tool fetches `release`'s changelog and writes `tried`, `offer` and `notes.md`
   (`common/updates.sh:212-225`). So "the scratch `_update` holds only what was written by hand" fails, its first
   state is not `unknown`, and its fourth state's `offer` is replaced. **Paste into the fixture:** "It also holds
   `tried` with the present time (`date +%s`), written by hand before the first open: the window's refresh then
   fetches and writes nothing (`common/updates.sh:216-219`), state 1 stays `unknown`, and state 4 keeps its
   `offer`."
2. **LFT6's cases are not split between LF5a and LF5b.** `--list` prints no second line
   (`common/launcher-window.swift:1523`), and LF5a builds today's words, yet the listing cases assigned to LF5a
   expect "In your Steam library. Click to install."; one case alone carries "with LF5b". **Paste into LFT6:**
   "With LF5b: the second line of `owned`; in `--grid`, each state's words with `--update-dir`; `--act return`;
   and everything from 'The click' to the end of this row. Every other case is LF5a's, with today's guide words
   for every offer." LF5a then reads "Tests LFT6 (every case not marked 'with LF5b')".

**Smaller, same fold**

- Criterion 11 wants "the seconds from the paste to Apple's box", which the rewritten LFL7 does not take: after
  "The installer's first lines." add "The seconds from the installer's first line to Apple's box.", and give the
  criterion the same words.
- The fallback release's criterion for captures names a begun-install capture that only LFL2b takes, and the
  fallback does not run LFL2b: a begun tile is then held by the tests alone, and the as-built header says it was
  not captured.
- LF2's tests gain "LFT12 but its listing case and its last case"; LF5a keeps the listing case
  (`LSMinimumSystemVersion` would otherwise first be tested two steps after it is set).
- LFL9 says "double-click": a tile acts on one click (`common/launcher-window.swift:1217`).
- "Every sentence names the holder's process" is true of what an installer or the driver prints in Terminal, not
  of the tool's answers to the window; say which, and say whether the driver's own line
  (`common/update-games.sh:60`) changes.
- LFL7 cannot read "whether a standard account is asked for an administrator" (the account is an
  administrator's): "whether an administrator is asked for a password; a standard account stays not known".
- The fallback's LF6 takes `installing` and `installing-game` out of `CLAUDE.md` again, since LF1 put them there
  and the fallback has no lock.
- LFL7 adds: "If macOS shows nothing at the paste, that is recorded, and the as-built header names the paste
  warning as unmeasured."
- A citation: `caffeinate` is at `:297`, not `:296-297`.
- Moot with the changed decision: the pass's note that the pictures' file ran twice in an update with only the
  launcher.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-26 | 1 | architecture, security, correctness, builder, design, platform facts, test plan | seven agents in two batches, read-only; the builder ran the gates and typed two steps into a scratch tree; platform facts compiled the window with the Command Line Tools alone; every blocker read again by the session | Fable 5.2 | `93868e3` | needs-rework |
| 2026-11-26 | 2, on the rework | correctness with a build on paper; security; architecture, tests, live steps and words | three agents, read-only; each blocker read again in the plan by the session | Fable 5.2 | `a36692b` | needs-rework, narrowly: three blockers of the fold |
| 2026-11-26 | 3, fitted to the second fold | one reviewer: every item traced to section, step, test, live step and criterion; the fold's citations opened | one agent, read-only; both faults read again in the code by the session | Fable 5.2 | `446ef08` | needs-rework, narrowly: two faults of the fold, each one sentence |

Key paths this plan depends on: `install.sh`, `common/games.tsv`,
`common/install-core.sh`, `common/updates.sh`, `common/update-games.sh`, `common/make-launcher-app.sh`,
`common/launcher-window.swift`, `common/wrappers.sh`, `common/paths.sh`, `common/make-wrapper.sh`, both games'
`scripts/install.sh` and `scripts/setup.sh`, and the tests named in section 6.
