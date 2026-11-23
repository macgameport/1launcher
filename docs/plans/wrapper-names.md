# Wrapper names — find a wrapper by a marker, then give it a name nobody types

**Status: check-it'd 2026-11-21 — build-ready-with-fixes (pass 3, the W0 fold re-checked, folded).** W0 is done:
P0 to P5 are recorded in section 1 (2026-11-18 and 19), James answered section 8 (2026-11-20), and step 8's fold
and its re-check are at the foot ("W0 fold", 2026-11-21). W1 is built on the branch `wrapper-names` (as-built
header below); W2 ran on the Studio on 2026-11-23, in part: its three wrappers are renamed, steps 1 to 5 and the index half of step 6 are recorded at the foot ("W2 on the Studio"), every step is recorded, and W2 found that macOS asks about the microphone again after a rename, which stalls the first start and must be folded into this plan and checked before W3; the MacBook's reads of W3 step 0 are taken at the first
visit there. The
findings of every pass and where each went are at the foot ("Review corrections"). Tracking: #26 (refs #26; one checkbox per phase there, as #22 has them).

> **🔧 As-built (2026-11-21): partial — W1 built on the branch `wrapper-names` (pushed, not merged, not in
> `release`); W2 to W4 not started.** Commits: `32de2b5` (1.1, the resolver), `9cf6365` (1.2, the mover),
> `5d8d263` and `6e9a3cf` (1.3 to 1.5: makers, installers, launchers, setups, the other readers, 14unch3r),
> `78328e1`, `e9f7431`, `0fc680a` (the new cases: WT4b, WT11, WT14 to WT17), `422b183` (the tests that read a
> real wrapper), `a2f935d` (1.6, the 19 research scripts), `11c1fd1` (1.7, the release gate, and WT12's list), and
> the documents commit that carries this header. Every test file passes; every mutant of section 6 was applied to
> a copy of the real source and seen red, then restored (W1's step 1.9). Deviations from the text above:
> - **How a launcher tells its repo copy from a deployed one.** Not by depth alone: the repo's copy is the one
>   whose game folder holds `scripts/setup.sh` (`launchers/..` for Cities: Skylines II, `.` for Surviving Mars,
>   the `WRAPPER_GAMEDIR` each launcher sets above the shared block). A deployed copy so never looks above its
>   `1launcher` folder. `repatch.sh` and the badge patch use the same test.
> - **Output the plan did not fix.** The mover prints `would finish:` / `finished:` for a part-way wrapper under a
>   name not old (no rename), and for two wrappers marked alike prints its state and a `skip:` (exit 1). Setup's
>   header relays a skip's reasons only under `--check`; in a run the rename step prints them once. Setup closes
>   with a `Renamed:` block (both names, how to decline) beside `Moved:`.
> - **WT12's list** is thirteen files: the resolver, the dated record, and eleven test files whose fixtures hold
>   old-name behaviour on purpose. `test-setup.sh` MUTANT=36 is retired (its list is gone; `test-wrappers.sh`
>   MUTANT=4 holds the case) and `test-move-install.sh` MUTANT=7 re-aimed at the resolver's call.
>
> Verify against: `common/wrappers.sh`, `common/move-wrappers.sh`, `common/install-core.sh`,
> `common/make-wrapper.sh`, `common/launcher-window.swift`, `common/check-release-move.sh`,
> `cities-skylines-2/scripts/setup.sh`, `surviving-mars-relaunched/scripts/setup.sh`, both `scripts/install.sh`,
> both launchers (the `find-wrapper` block), and the tests `common/test-wrappers.sh`, `common/test-move-wrappers.sh`.

The fault: Spotlight offers the Wine wrappers beside, and on one Mac above, the game apps. A wrapper opened
directly starts its own Steam outside the launcher and its lock. The wrappers cannot simply be renamed, because
their file names are spelled as addresses across the code and on players' Macs.

This plan does three things, in this order: the scripts find a wrapper by a marker in its `Info.plist`; the
wrappers then take names that match no word a player types; a move step renames the wrappers that exist. Before
any of it was built, W0 tested on the Studio whether a rename removes the fault (P1: it does there); the MacBook,
where Spotlight learned a wrapper, is tested at W3, and nothing is merged until it passes.

## 0. Decisions already made (issue #26, 2026-11-17)

| # | Decision | Source |
|---|---|---|
| D1 | A plan first, checked before any code | #26, proposal 1 |
| D2 | Scripts find a wrapper by an opaque marker in its `Info.plist`, as 14unch3r finds game apps by `L1Role`, and not by file name | #26, proposal 1 |
| D3 | The wrappers take names nobody types, built from the Steam app ID | #26, proposal 2. The exact names are open: section 1.2 measured a collision in the issue's examples (WD3) |
| D4 | Existing wrappers are moved by a step modelled on the install-folder move of `docs/plans/local-files-layout.md` | #26, proposal 3 |
| D5 | Rejected names: "SMR launcher", "SMR 14unch3r" (they look like the thing to click) | #26 |
| D6 | `chflags hidden` is not the fix: tried on the MacBook, Spotlight kept the wrappers | #26, "Tried" |

D2 to D4 are the issue's proposal, and this plan treats them as a hypothesis. Where the measurements below point
somewhere else, section 8 puts the question to James.

## 1. Where things are today

Measured 2026-11-18 on the Studio (its host name read with `scutil --get LocalHostName` and left out of this file), macOS 27.2.1 (26B131), tree `911e69a`. Everything here was read,
nothing written. Surviving Mars was running in its wrapper during the measurements. The MacBook and players'
Macs were not measured (1.7).

### 1.1 What is in `~/Applications`

| App | Kind | `CFBundleName` | `CFBundleIdentifier` | `L1Role` | `L1SteamAppID` | `L1Prefix` |
|---|---|---|---|---|---|---|
| `CS2dxmt11.app` | wrapper (the game's) | Steambuild Metal | of the form `com.<name><digits>.wineskin` | none | none | none |
| `CS2dxmt11-pk110.app` | wrapper (the Windows Steam's) | Steambuild Metal | the same | none | none | none |
| `SurvivingMars.app` | wrapper (the game's) | Steambuild Metal | the same | none | none | none |
| `Cities Skylines II.app` | game app | Cities Skylines II | `local.cs2.dxmt11.launcher` | `game` | 949230 | `~/Applications/CS2dxmt11.app/Contents/SharedSupport/prefix` |
| `Surviving Mars Relaunched.app` | game app | Surviving Mars Relaunched | `local.sm-patch.relaunched.launcher` | `game` | 3215050 | `~/Applications/SurvivingMars.app/Contents/SharedSupport/prefix` |
| `S734M.app` | the Windows Steam app | S734M | `local.cs2.steamstore` | `steam` | none | `~/Applications/CS2dxmt11-pk110.app/Contents/SharedSupport/prefix` |
| `14unch3r.app` | the window | 14unch3r | `local.1launcher.window` | none | none | none |

- The three wrappers' `Info.plist` files have one size (4,223 bytes), one date and mode 666. None holds its own
  file name (`grep -c`: 0 in each). All three carry `NSBGOnly = 1` and declare no `CFBundleURLTypes`.
- `codesign -dv`: ad hoc, `Info.plist=not bound`. `codesign --verify` already fails on all three ("code has no
  resources but signature indicates they must be present"). So a key written into `Info.plist` breaks no seal
  that holds today.
- `CS2dxmt11.app` is 119 GB by Spotlight's size. A wrapper can only be renamed, never copied.

### 1.2 What Spotlight's index holds

`mdls` on each app:

| App | `kMDItemDisplayName` | `kMDItemAlternateNames` | `kMDItemLastUsedDate` | `kMDItemUseCount` |
|---|---|---|---|---|
| `CS2dxmt11.app` | `CS2dxmt11.app` | the file name only | null | null |
| `CS2dxmt11-pk110.app` | `CS2dxmt11-pk110.app` | the file name only | null | null |
| `SurvivingMars.app` | `SurvivingMars.app` | the file name only | null | null |
| `Cities Skylines II.app` | its file name | CS2 · Cities Skylines 2 · Cities: Skylines II | 2026-11-17 | 2 |
| `Surviving Mars Relaunched.app` | its file name | Surviving Mars · Surviving Mars: Relaunched · SMR | 2026-11-18 | 8 |
| `S734M.app` | its file name | Windows Steam · Steam Store · CS2 Steam Store | 2026-11-15 | 4 |
| `14unch3r.app` | its file name | 1launcher · launcher · game launcher | 2026-11-18 | 3 |

`mdfind -onlyin ~/Applications "<word>"` (the plain query, which searches every text attribute), top-level apps only:

| Word | Apps returned |
|---|---|
| `mars`, `surviving` | `Surviving Mars Relaunched.app`, **`SurvivingMars.app`** |
| `cs2` | `Cities Skylines II.app`, `S734M.app`, **`CS2dxmt11-pk110.app`**, **`CS2dxmt11.app`** |
| `cities` | `Cities Skylines II.app` |
| `steam`, `s734m` | `S734M.app` |
| `1L` | `14unch3r.app` |
| `Steambuild`, `wineskin`, `949230`, `3215050` | none |
| `PortingKit`, `Paul The Tall` | the three wrappers (their copyright and version strings) |

What this settles, and what it does not:

- **The wrappers match a player's words through the file name only.** "Steambuild Metal" is in no indexed
  attribute here: `steam` returns `S734M.app` alone. So on wrappers of this make a rename takes away every word
  a player types. The task brief's worry that the bundle name matches "steam" is not borne out on this Mac.
- **The issue's unmeasured line about Cities: Skylines II holds for the index:** `cs2` returns both of its
  wrappers, and Spotlight's window puts both of them first (P0, below).
- **`1L` is not a free prefix.** It returns `14unch3r.app`, through its alternate name "1launcher". A wrapper
  named `1L-949230.app` would very likely join that list for the two keys `1l` on the way to "1launcher". The
  word split of such a name was not measured (probe P2). And `-store` in `1L-949230-store.app` would likely
  answer to `store`, a word in `S734M.app`'s alternate name "Steam Store".
- **The Studio shows the fault too, with no use history behind it (P0, 2026-11-18).** The index
  was read first and was as the table above. Then James typed the words into Spotlight's window, opened
  nothing, and read the rows:

  | Typed | Measured: Spotlight's window, top first | Use data (`mdls`, same day) |
  |---|---|---|
  | `surviving mars` | the field completes to "SurvivingMars.app"; Top Hit **`SurvivingMars.app`**, the wrapper; then two folders and three Markdown files. `Surviving Mars Relaunched.app` is not among the six rows shown | wrapper: no last-used date, no use count; game's app: last used 2026-11-18, use count 8 |
  | `steam` | Top Hit `/Applications/Steam.app` (the macOS Steam); then the two CrossOver Steam apps and their two Support Center apps in `~/Applications/CrossOver/`, then a folder. No wrapper; `S734M.app` is not among the six rows shown | — |
  | `cs2` | the field completes to "CS2dxmt11.app"; Top Hit **`CS2dxmt11.app`**, the game's wrapper; then **`CS2dxmt11-pk110.app`**, the Windows Steam's; then two images. Neither `Cities Skylines II.app` nor `S734M.app`, both of which carry "CS2" as an alternate name, is among the four rows shown | both wrappers: no last-used date, no use count |

  Inferred, not measured: the wrappers outrank the game's apps with no use behind them (Surviving Mars's
  wrapper against its game's app's eight uses), so on this Mac the fault comes from the file name and not from a
  pick Spotlight learned. `SurvivingMars` meets both words typed, and `CS2dxmt11` starts with `cs2`; the game's
  apps and `S734M.app` meet them only through alternate names, which the window ranks lower.
  Folded (W0 step 8, 2026-11-21): P1 was asked on the Studio; and W2 step 6's pass condition for every word typed
  is now "no wrapper among the rows", with the place of the game's app and of `S734M.app` recorded, because a
  first row of `S734M.app` for `steam` cannot be met on a Mac with the macOS Steam installed, whatever the
  wrappers are called. The CrossOver rows stay in the measurement: a player's Mac may carry other Steams too, and
  they hide no wrapper.
- **P1, run on the Studio by James's choice (2026-11-18): a rename takes the wrapper out of the window, and the
  game's app does not take its place.** With nothing of Wine running and no file in it open, `SurvivingMars.app`
  was renamed by `mv` to `wrapper-3215050.app` and `mdimport`ed; `mdfind` dropped the old name within 3 s, and
  `surviving` and `mars` then returned `Surviving Mars Relaunched.app` alone (the new name answers to `wrapper`
  and `3215050` only). James typed, opening nothing:

  | Typed | Measured: Spotlight's window, top first |
  |---|---|
  | `surv` | the field completes to "surviving-mars-relaunched"; Top Hit the repo's folder of that name; then a TV show, a folder, a Markdown file, a web result. No wrapper; no app |
  | `surviving mars` | the field completes to the same folder, Top Hit; then a folder, a Markdown file, two web results. No wrapper; no app |

  James: the window "flashed what we wanted", then showed these rows. Then the wrapper was renamed back
  (`L1Prefix` of the game's app resolves again). So what P1 asked is answered for the Studio: the rename takes
  the wrapper out, completion included, at once. What it shows besides is not in target 3: **the game's app is
  not offered in its place.** It is an application to Spotlight (`kMDItemContentType` application-bundle, kind
  Application, `CFBundlePackageType` APPL, as for `14unch3r.app` and `S734M.app`) and is in the index for both
  words. Not measured yet: whether it is in the window's Applications filter. Read from `lsregister -dump`, not
  yet known to bear on it: Launch Services holds a second app with the game's app's bundle identifier,
  `local.sm-patch.relaunched.launcher`, the scratch copy of the Surviving Mars plan's ML4 in that game's
  `runs/ml4-20261113/scratch-app/`; and records for `~/.Trash/S734M.app`, `~/.Trash/Install Cities Skylines II.app`
  and a probe wrapper `CS2probe3`. The MacBook's learned pick (#26) was not probed.

  Then, with the wrapper back under its old name, James typed `surviving mars` with the window's Applications
  filter on. Measured: `Surviving Mars Relaunched.app` first, `SurvivingMars` (the wrapper) second. So the game's
  app is in the window and, among apps, ranks above the wrapper. Inferred: the fault is in the one Top Hit of the
  window without a filter, which on this Mac went to the wrapper (P0) and, with the wrapper renamed, to the
  repo's folder `surviving-mars-relaunched` (its name meets the words as closely as the app's). That folder is a
  checkout's, and a player who installed by the pasted line has none (nor a folder of screenshots by that name),
  so on a player's Mac the rename may leave the game's app as the Top Hit, and on this one it does not. Which
  of the two a player meets is a reading on a Mac with no checkout (the MacBook has one too). Folded (W0 step 8):
  the game's app as the Top Hit is not a target (target 3 asks only that no wrapper is offered); W2 and W3 record
  where it stands, with and without the Applications filter; a Mac with no checkout is not among this plan's live
  steps, and section 5 says so.
- **Spotlight splits a name where letters meet digits, and matches from the start of each piece** (pass 1's
  platform lens: `11`, `dxmt`, `cs` and `pk110` each return the two `CS2dxmt11` wrappers). So a new name is judged
  piece by piece, and P2 states its pass rule that way.
- Nothing inside a wrapper is returned as an app (`Wineskin.app` inside each is not in the list).

### 1.3 How the scripts find a wrapper today

| Script | How | Where |
|---|---|---|
| CS2 launcher | `CS2_WRAPPER`, else `~/Applications/CS2dxmt11.app`, `~/Applications/CS2.app`, `/Applications/CS2dxmt11.app`, else any app in `~/Applications` that holds `Cities2.exe` | `cities-skylines-2/launchers/launch-cs2-dxmt11.sh:33-42` |
| CS2 setup | `CS2_WRAPPER`, else the first of `CS2dxmt11.app CS2.app` with a prefix | `scripts/setup.sh:77`, `:103-114` |
| CS2 setup, badge step | the spelled path, "whatever CS2_WRAPPER says" | `scripts/setup.sh:326-334` |
| CS2 installer | its own copy of the launcher's list, else the spelled default | `scripts/install.sh:49-51`, `:83-90` |
| `repatch.sh` | `CS2_GAME_DIR`, else the spelled path | `repatch.sh:16` |
| badge patch | the spelled path, no override | `scripts/patch-modconflict-badge.py:58-62` |
| `boot-verify.sh`, `install-webhelper-shim.sh` | `CS2_WRAPPER`, else the spelled path | `:91`, `:25` |
| `make-shortcut.sh` | the spelled path, for the game path and `L1Prefix` | `:81` |
| `make-steam-shortcut.sh` | `--wrapper`, else `CS2dxmt11-pk110.app`; the donor `CS2dxmt11.app`; the clone at `:105`, made whenever the store wrapper has no prefix (`:95-116`); **the path is written into `S734M.app`'s `launch` file** at `:143` | `:40-41` |
| the folder mover | its own copy of setup's list, read only when it is run by hand with no `--lock` | `scripts/move-install.sh:42`, `:92-96` |
| `mac-inventory.sh` | six names it "knows from the Studio" | `common/mac-inventory.sh:138`, `:146`, `:169` |
| SM launcher | `SM_WRAPPER`, else the spelled path | `surviving-mars-relaunched/launch-relaunched.sh:69` |
| SM setup, installer, app builder | the same default, spelled again | `scripts/setup.sh:88`, `scripts/install.sh:52`, `make-app.sh:25` |
| SM engine and split tools | the spelled paths | `tools/make-engine.sh:83`, `tools/split-wrapper.sh:23-25` |
| the shared installer | takes the path from the game's `game_wrapper`, then **exports the game's variable** (`use_wrapper`, called from `core_begin` and after a wrapper is made), so each setup it runs sees that variable whether or not the player gave it | `common/install-core.sh:145-154`, `:280`, `:356` |
| 14unch3r | lists apps whose `L1Role` is `game` or `steam`, nothing else; reads `L1Prefix` for the lock | `common/launcher-window.swift:126-127`, `:135`, `:146` |

Two facts the design leans on. The launchers already attribute processes by open files against the prefix
(`launch-cs2-dxmt11.sh:165`, `launch-relaunched.sh:273`), not by the wrapper's name; the one name-based test
left in the CS2 launcher takes the name from the path it found (`:94`, `:437`). And the launchers are deployed
copies that find their files beside themselves (`docs/plans/local-files-layout.md` 3.2): they cannot read a file
in the checkout.

### 1.4 Census (`git grep`, code files, `*.md` left out)

| Name | Files | Lines | Notes |
|---|---|---|---|
| `SurvivingMars.app` | 12 | 26 | all under `surviving-mars-relaunched/`: 6 scripts, 6 tests |
| `CS2dxmt11.app` | 42 | 213 | 127 of the lines are `scripts/test-install.golden` |
| `CS2dxmt11-pk110` | 4 | 6 | `make-steam-shortcut.sh`, `split-wrapper.sh`, `mac-inventory.sh`, one dated `.txt` |
| `S734M.app` | 10 | 39 | the app meant to be clicked: its name stays |
| `CS2.app` | 8 | 23 | an older wrapper name, still on the lists |
| `L1Role`, `L1Prefix`, `L1SteamAppID` | 10 | 64 | 3 writers, 1 reader, 6 tests |

The 42 files that spell `CS2dxmt11.app`:

- **11 player-facing:** the launcher, `repatch.sh`, `scripts/` `install.sh`, `setup.sh`, `make-shortcut.sh`,
  `make-steam-shortcut.sh`, `move-install.sh`, `boot-verify.sh`, `patch-modconflict-badge.py`,
  `install-webhelper-shim.sh`, and `common/mac-inventory.sh`.
- **10 tests of those** (the golden file among them). Counting every old name, and not this one alone, 21 test
  files spell `CS2dxmt11`, `SurvivingMars.app` or `CS2.app` (`git grep -l` at `d50cf33`); section 6's second table
  names the ones that change.
- **20 research:** 19 scripts and `test-licence-wait-probe.sh`. 13 of the 19 read `CS2_WRAPPER` and fall back to
  the spelled path, some in more than one place (`drag-session.sh:49` and `:92`, `t1-spike.sh` twice); 6 spell it
  with no override (`capture-freeze.sh`, `livedrag-probe.sh`, `run-minrepro.sh`,
  `run-minrepro2.sh`, `run-minrepro3.sh`, `shimmer-probe.sh`), and `capture-freeze.sh:54` also attributes a
  wineserver by the name in its command line.
- **1 dated record:** `docs/wine-bugs/measurement-engine1116.txt`.

Documents: `CS2dxmt11.app`, `SurvivingMars.app` or `CS2dxmt11-pk110` appear in 26 `.md` files. The living ones
are the four `README.md` and `INSTALL.md` files of the two games, both `CLAUDE.md` files, `GOTCHAS.md` and
`docs/patch-inventory.md`; the rest are plans and dated findings.

### 1.5 What else holds a wrapper's path

| Place | Finding | How |
|---|---|---|
| The game apps' `L1Prefix` | hold the wrapper path (1.1) | read |
| `S734M.app/Contents/MacOS/launch` | holds `WRAPPER=<path>` | `make-steam-shortcut.sh:143` |
| The game apps' `launch` files | Cities: Skylines II's holds the launcher's path and not the wrapper's. **Surviving Mars's holds both**: `SCRIPT=` and `GAME_EXE=`, the game's program inside the wrapper, which its "already running" test compares with a command line; a second pattern there (`C:\…\Project Spark\Mars.exe`) does not depend on the path | `make-shortcut.sh` (the `SCRIPT=` line), `make-app.sh:65-66`, `:76-80` |
| The launch lock | `<prefix>/.launcher.lock`, inside the wrapper: it moves with it | `launch-relaunched.sh:166` |
| The Dock | one project item, `Cities Skylines II.app`; no wrapper | `defaults read com.apple.dock persistent-apps` |
| LaunchServices | each wrapper is registered once, by its path | `lsregister -dump` |
| The wrappers' bundle identifier | one value in all three, of the form `com.<name><digits>.wineskin`. Its name part is the first wrapper's name on this Mac, so it reads as made per wrapper by Porting Kit and copied by each clone, not as a constant of the template. The value itself is left out of this file (review corrections, S23) | `plutil -extract` |
| A `steam://` handler | none: no wrapper declares a URL scheme | 1.1 |
| The Wine registry in each prefix | the font entries hold the wrapper's own path (6 lines in each). `SurvivingMars.app`, a clone of another wrapper, holds its own name there and the donor's 0 times, so Wine rewrites them at start. `CS2dxmt11.app` has 4 more lines: Wine Mono's install source | `grep -c` on the `.reg` files |
| Steam's library files in each prefix | no wrapper path (0 files) | `grep -l` on `config/*.vdf`, `steamapps/*.vdf` |
| Symlinks in the bundle | relative (`drive_c`, `Logs`, `dosdevices/c:`); none holds the wrapper's path | `readlink` |
| 14unch3r's preferences | the last app ID, a number | `launcher-window.swift:1385`, `:1444` |
| Claude memory for this repo | 9 files name a wrapper | `grep -l` |
| The scheduled task `reddit-watch-cs2` | no wrapper name | `grep -rl` |
| Engine variables | `CS2_ENGINE` and `SM_ENGINE` name Wine trees under `~/Library/Developer/1launcher/`, not a wrapper; `make-engine.sh:83` reads `wine.d3dm21-BAK` inside the wrapper | read |

**Not checked:**

- Porting Kit's library. It is under `~/Library/Application Support`, above a `1launcher` folder, which this
  project never searches. Each wrapper holds a `pk_backup.wsi3`, so Porting Kit made them and may list them.
- What Spotlight has learned about past picks, and whether a renamed app keeps its rank. The wrappers share one
  bundle identifier, which may matter. Not readable. **In part by P1 (1.2):** on the Studio, where no wrapper had
  a use count, a rename took the wrapper out of the window at once. The MacBook's learned pick is W3 step 6.
- ~~Whether macOS checks a renamed wrapper again at its first start (the Surviving Mars wrapper once took about
  four minutes), and whether a privacy grant follows the rename.~~ **Read by P4 (below):** no new check by
  macOS, no prompt of any kind, a first start 7 to 9 s slower.
- Whether Wine Mono's four stale lines matter. The clone precedent says a renamed wrapper runs; boot-verify is the gate.
- `~/Library/LaunchAgents` and other folders of `~/Library` outside a `1launcher` folder.
- Whether the template's own launcher keeps keys it does not know when it rewrites `Info.plist`
  (`common/make-wrapper.sh:140`). Our launchers never run it after the wrapper is made. **In part by P3
  (below):** its rewrite on Quit keeps them; its first-run write at `:140` was not exercised.
- ~~The `Info.plist` of a wrapper made by the published installer.~~ **Read by P3 (2026-11-18).** A wrapper was
  made on the Studio by `common/make-wrapper.sh` as `~/Applications/l1-p3-scratch.app`, with Cities: Skylines
  II's engine pin and the template, both from the copies already in the workspace (sha256 checked by the
  script; nothing downloaded); exit 0, 1.3 GB. Its `Info.plist` is kept in the workspace,
  `wrapper-names-p3/Info.plist`, not in this file. Measured:
  - **It holds its file name, in one key:** `CFBundleName` = `l1-p3-scratch` (the name without `.app`; `grep -c`
    of the name in the file: 1). The Studio's Porting Kit wrappers hold "Steambuild Metal" there instead.
  - **Its bundle identifier is made from its file name:** form `com.<the name without its hyphens><digits>.wineskin`.
    So a player's wrapper carries its old name in its identifier after a rename, and 3.1 leaves it (privacy
    grants are keyed on it); that is a label left stale, not a key read by anything of ours. WD11: such an
    identifier holds the wrapper's own name and digits, nothing of a person.
  - `NSBGOnly` = 1; no `CFBundleURLTypes`. `codesign -dv`: ad hoc, `Info.plist=not bound`, Mach-O x86_64; `codesign
    --verify` fails as on the Studio's three. Spotlight: `kMDItemDisplayName` and `kMDItemAlternateNames` are the
    file name only, so `CFBundleName` is not among the names Spotlight holds.
  - **Modes:** the bundle folder `drwxr-xr-x`, the user's own; `Contents` `drwxrwxrwx`; `Info.plist` `-rw-rw-rw-`;
    the prefix `drwxrwxrwx`; 2,043 entries inside are writable by group or others. No extended attribute at all on
    the bundle (no quarantine). So it passes 3.2's tests of a candidate as written, because they judge the bundle
    folder itself; a test that also judged `Contents` or anything inside would pass over every installer-made
    wrapper. 3.3's P3 row is not selected.
  - **Opened once directly, on James's word: the marker survives.** `L1Role` `game-wrapper`, `L1SteamAppID`
    `999999` (an ID no game has) and `L1RenamePending` `probe` were added with `plutil -insert` (58 keys, mode
    666 kept). James double-clicked the wrapper: the template's launcher showed Wineskin's settings window
    (Install Software, Winetricks, Advanced, Quit), since the wrapper names no program, and started no Wine.
    While it was open the file was byte-identical. On **Quit** it was rewritten: still 58 keys, the three
    marker keys unchanged, mode 666, and one value changed, **`use start.exe` from 1 to 0**. So Wineskin's own
    rewrite keeps keys it does not know, and 3.1's marker stays in `Info.plist`; the "considered" file in the
    prefix is not needed. Not exercised: the template launcher's first-run write at `make-wrapper.sh:140`,
    which runs only while the prefix is made. The flipped `use start.exe` belongs with WD6 (a wrapper opened
    directly), not with this plan.
- **P2, the Studio (2026-11-18): the new names answer to no word a player types.** Three scratch apps, each
  holding P3's `Info.plist` as made (its bundle identifier, so the old name, kept; `CFBundleName` set to the new
  name), the Wineskin icon, and a stub `wineskinlauncher` that exits: `~/Applications/wrapper-999999.app`,
  `~/Applications/1L-999999.app`, and `~/Applications/1launcher.noindex/wrapper-999998.app`. `mdimport`ed; all
  three registered with Launch Services. Then put in the Trash with the `.noindex` folder.

  | Read | Measured |
  |---|---|
  | `mdfind -onlyin ~/Applications`, each of target 3's twelve words | no scratch app for any |
  | the same, the names' pieces | `wrapper-999999`: `w`, `wr`, `wrapper`, `999999`, `99`, and `1` (through an attribute other than its name; nobody types `1` alone). `1L-999999`: `1l`, `1`, `l`, `999999`, `99`; not `1launcher` or `14` |
  | the bundle identifier | not matched: `scratch` and `l1p3scratch` return the P3 wrapper only, by its file name |
  | the `.noindex` app | in no query, not even by its file name |
  | Spotlight's window, `wrapper` | three files; no app |
  | Spotlight's window, `w` | completes to "iA Writer.app", Top Hit; then Citrix Workspace. No scratch app |
  | Spotlight's window, `1l` | completes to "1launcher", the repo's folder, Top Hit; then files. No scratch app |
  | Applications filter, `w` | `wrapper-999999` not shown |
  | The Apps view | none of the three. James: "steam appears in the dock, none of these" |

  So 3.3's row A holds for the names: no target word, no attribute other than the file name that a target
  word reaches, and not where apps are browsed. WD3: `wrapper-<ID>` meets P2's rule, and in the window it did
  not appear even for its own word; `1L-<ID>` met it too on this Mac, but its `1l` is the start of "1launcher".
  A `.noindex` folder keeps an app out of the index (branch B is available, and not needed after P1). Caveat:
  the scratch apps were minutes old and never opened; a renamed wrapper keeps its own history (P1 is that
  case).
- **P4, the Studio (2026-11-18): a rename costs a few seconds at the first start, and nothing else.** With
  nothing of Wine or Steam running and no file of it open, `SurvivingMars.app` was renamed by hand to
  `wrapper-3215050.app`, and the installed launcher was run with `SM_WRAPPER` naming it (`SM_QUIET=1`, as the
  app runs it; log in the workspace's `wrapper-names-p4/`). The game played for 38 minutes and was quit from
  its menu; the launcher uploaded the saves, shut Steam down and exited 0. The name was then put back, and the
  game's app's `L1Prefix` resolves again.

  | Read | Before (the last three starts, 2026-11-16 and 18, by the app) | After the rename |
  |---|---|---|
  | launcher start to the game's window (to step 5, plus `frame-fix`'s first sighting) | 26, 26, 28 s | 35 s |
  | of which, to Steam's logon `OK` (`connection_log.txt`) | 10 and 12 s | 15 s |
  | of which, logon to step 5 (the 15 s licence wait, the cloud and update checks) | 15 and 15 s | 19 s |
  | a check by macOS (`log show`, `com.apple.syspolicy.exec`) | one Gatekeeper scan of an unsigned single file in the first second of each start read (06:25 and 15:20), result 2 | the same, once, result 2 |
  | Steam's sign-in | saved login, logon `OK` | saved login, logon `OK`; no prompt. James: no dialog of any kind appeared |

  Against W0 step 5's thresholds: 7 to 9 s slower, inside the 30 s; no new check by macOS; no sign-in prompt,
  so nothing stops the plan. Not explained: `syspolicyd` made more certificate checks during this start
  (101 `SecTrustEvaluateIfNecessary` lines in the minute, against 34 and 23), none naming a file. One start
  only: whether the extra seconds come from the new path or are the spread of Steam's sign-in is not
  separated. Folded (W0 step 8) into section 5's row "everyone, at the first start after the rename" and 3.8's
  notes: 7 to 9 s in one start.
- **P5, the Studio (2026-11-18 and 19): nothing holds the wrapper when the installer reaches its setup step.**
  The real Surviving Mars installer was run three times with `SM_WRAPPER` naming a new scratch wrapper,
  `~/Applications/l1-p5-scratch.app`, which the first run made from the cached downloads (`L1_DOWNLOADS`, each
  checked by size and sha256): Wine 10.0, D3DMetal 3.0, Steam for Windows. With `SM_WRAPPER` set the installer
  stops before step 7, at the moment setup would run; a watcher read 3.4's probe there and 15 s later. Then both
  scratch wrappers (P3's and P5's) went to the Trash.

  | Run | Path | During the download | At the setup step | 15 s later |
  |---|---|---|---|---|
  | 1 | the download path: James signed in, chose Install, and the installer saw 10 GB arrive and closed Steam | `lsof -t` on the named files: 16 processes, the wrapper's `wineserver`, Wine's services, `steam.exe`, `steamservice.exe` and six `steamwebhelper.exe`; the same 16 had a file of the wrapper open | none | none |
  | 2 | the game already installed: no Steam started | not taken | none | none |
  | 3 | the same | not taken | none | none |

  So 3.4's first row holds: **as written**. The core's background `wsrv -w` (`install-core.sh:493-494`) did not
  outlive Steam's shutdown in run 1. The probe saw every Wine process of a live wrapper through two named files
  (only `wine64` and `wineserver` exist in this wrapper's `bin/`), including a `wineserver` started by the path
  `wine/lib/wine/../../bin/wineserver`, since `lsof` matches the file and not the path typed.

  **Where the server keeps its socket:** `/private/tmp/.wine-<uid>/server-<device>-<inode>/`, the prefix
  folder's device and inode in hex (matched by `stat` for the scratch wrapper, `16d47a0`, and the Studio's
  `SurvivingMars.app`, `e8a4bc`). The server's working folder is that one, and it holds a socket there while it
  runs; once it ends, an empty `lock` file and the folder stay. An `mv` within the volume keeps the prefix's
  inode, so the place is the same under the old name and the new one. Folded (W0 step 8): the probe does not add
  that folder. It is not needed to see this installer's processes, which hold the named files anyway, and what
  it alone would catch, a server run by an engine outside the wrapper, is covered by the lock when the game is
  started by its launcher (3.4, "What it misses"). Matching a socket by its path with `lsof` was not measured.

  Run 1's first attempt (2026-11-18) stopped at step 6 with exit 4: Steam's own first update (242 MB) was cut
  again and again ("Exhausted list of download hosts"), the pattern F8 met through the VPN. Read after that
  stop: no holder and no process with a file of the wrapper. Once James had changed the VPN's server, the
  update took 14 s. Also met: the D3DMetal licence question needs a terminal; run from a tab no one was looking
  at, it waited unseen. A player runs the pasted line in their own Terminal, and the installer app opens one
  (`common/make-installer-app.sh:107`), so this was the probe's setup and not a finding.

### 1.6 What is published

`release` is at `ce2fcd0`, which is `v0.1.0`. `v0.2.0` is `9c2cf7a`; `origin/main` is `911e69a`, 19 commits past
`release`. `release` has not taken the folder move (ON1 of the local-files plan: on James's word). At both tags:
the CS2 launcher has the "any app that holds the game" fallback; CS2's setup knows only `CS2dxmt11.app CS2.app`;
the Surviving Mars launcher knows only `SurvivingMars.app`; the installer makes a wrapper at the default name
when it finds none.

### 1.7 The Macs

| Mac | Wrappers | Source |
|---|---|---|
| The Studio | three, as 1.1. The Surviving Mars wrapper was made by `tools/split-wrapper.sh` on 2026-11-07, a clone of the Porting Kit wrapper; it has never been opened directly | measured |
| The MacBook | has the store wrapper (`launcher-window.md`, step 8); its Surviving Mars wrapper "was made the old way" (`surviving-mars-install.md`, ML5); its folders moved on 2026-11-17 (L3); its Surviving Mars wrapper was opened from Spotlight once and is Spotlight's top hit for "surviving mars" (#26) | records only, not measured. P1 ran on the Studio instead; the MacBook's reads are W3 step 0 |
| A player's Mac | one wrapper per installed game, made by `common/make-wrapper.sh` at `~/Applications/CS2dxmt11.app` or `~/Applications/SurvivingMars.app`. No store wrapper unless they ran `make-steam-shortcut.sh` by hand: neither setup runs it | the code |

## 2. Target

1. No code file finds a wrapper by a spelled name, except one table of old names kept for Macs not moved yet.
2. A wrapper's file name is a label. Renaming it by hand, to anything, breaks no start of a game: not from the
   game's app, not from 14unch3r, not from a terminal. `S734M.app` opens the store after a hand rename too (3.9;
   WD5 is the choice to narrow this instead).
3. No wrapper in `~/Applications` is returned by Spotlight for a word a player types: `surviving`, `mars`,
   `smr`, `cities`, `skylines`, `cs2`, `steam`, `store`, `s734m`, `launcher`, `1launcher`, `14`; and Spotlight's
   window, completion included, offers no wrapper for `surviving mars`, `cs2` or `steam`. That holds on the
   MacBook too, where Spotlight has learned a wrapper (P1 found it so on the Studio, for `surviving mars`; W3
   step 6 tests the MacBook).
   Which row the window then puts first is recorded and is not a target: on a Mac with a checkout it can be the
   repo's folder of the game's name (P1).
4. Existing wrappers are renamed by setup, by a rename only, with nothing copied; setup says what it renamed.
   This holds on both routes: a clone's `setup.sh`, and the pasted line's installer.
5. 14unch3r lists the same apps as before.
6. A setup run that fails part of the way leaves a game that still starts.

## 3. Design

**3.1 The marker.** Two keys in the wrapper's `Contents/Info.plist`, in the vocabulary the apps already use, and
one more that lives only while a rename is under way:

| Key | Type | Value |
|---|---|---|
| `L1Role` | string | `game-wrapper` or `steam-wrapper` |
| `L1SteamAppID` | integer | the game's Steam app ID; on a `game-wrapper` only |
| `L1RenamePending` | boolean | `true` from just before the mover's rename until just after it; absent at every other time |

- The identity of a game's wrapper is (role, app ID). The app ID is Valve's, opaque, and already the key by which
  everything published names a game (root `CLAUDE.md`, "Published addresses"). The role is a comparison string,
  the looser family of the keys-and-labels rule.
- The Windows Steam's wrapper has a role and no app ID: it serves every game on the account, and tying it to
  949230, as `1L-949230-store` would, is the kind of readable coupling the rule warns about.
- 14unch3r lists an app only when `L1Role` is exactly `game` or `steam` (`launcher-window.swift:126-127`), so no
  build of it, old or new, lists a marked wrapper. WT6 holds that.
- **One write.** The keys are put into a copy of the file in the same folder (`plutil -replace` and `-remove` on
  the copy, then `plutil -lint`), the copy takes the original's mode (`test-make-wrapper.sh:422` holds it at
  666), and the copy is renamed over the original. A wrapper with no `Info.plist`, or one that does not parse, is
  never marked: the function returns 1 and says so. `plutil -extract … raw` reads the keys, as
  `make-steam-shortcut.sh:65` already reads another.
- **The file name stored inside.** An installer-made wrapper holds its own file name in `Info.plist`, in
  `CFBundleName`, without `.app` (P3); the Studio's Porting Kit wrappers hold "Steambuild Metal" there and so
  nothing to change. The mover's write also sets `CFBundleName`, when it equals the old name without `.app`, to the new
  name without `.app`, in that same one write; P3 found the name in no other key, so no other key is touched. This is part of the move, not a branch of a table. It is not
  what clears Spotlight: `CFBundleName` is not among the names Spotlight holds (1.2: the Studio's wrappers hold
  "Steambuild Metal" there, and `Steambuild` returns no app). `CFBundleIdentifier` is
  never rewritten by the move, though an installer-made one is built from the old name (P3): privacy grants are
  keyed on it.
- Mode 666 means another account on the Mac can write or remove a marker. 3.2's rules for a candidate are what
  stand between a planted bundle and a launcher that runs `wine64` from it. They judge the bundle folder only
  (3.2), so they do not stop another account changing `wine64` or the marker inside an existing wrapper whose
  `Contents` is writable by all, as an installer-made one's is (P3). That is today's state, not made worse by
  this plan, and is #29.
- *Considered:* a marker file in the prefix beside `.launcher.lock`. It would survive anything that rewrites
  `Info.plist`. Rejected: `Info.plist` is where the three app builders and the window already look, nothing of
  ours rewrites it, and Wineskin's own rewrite of it, when a wrapper is opened directly and quit, kept the three
  marker keys (P3).

**3.2 One resolver.** A new file, `common/wrappers.sh`, in the form of `common/paths.sh`: sourced, it defines
functions and exports nothing; run, it prints.

```
bash common/wrappers.sh find game 949230     # the path of that game's wrapper
bash common/wrappers.sh find steam           # the Windows Steam's wrapper
bash common/wrappers.sh name game 949230     # the file name a new wrapper of that game is given
bash common/wrappers.sh list                 # every marked wrapper: role, app ID, path with ~
bash common/wrappers.sh incomplete game 949230   # the app at the game's first old name, when it has no prefix
```

*What it knows about a game.* A deployed copy cannot read `common/games.tsv`, so `wrappers.sh` holds its own
table, one row per game: the app ID, the game's variable (`CS2_WRAPPER`, `SM_WRAPPER`), the old names in today's
order, and the game's program as a path under the prefix (`…/Cities Skylines II/Cities2.exe`,
`…/Project Spark/Mars.exe`). The Windows Steam has a row with no ID, no variable and one old name. This table is
the only place in the code that spells an old name, and WT5c fails when `games.tsv` has a game the table lacks.

*`find` answers in this order:*

1. **A wrapper named by the player:** the game's variable, when a person gave it (below). The path is printed
   with a trailing slash taken off and is not judged: what each caller then requires of it is what it requires
   today (the launcher takes it as it is, `launch-cs2-dxmt11.sh:34`; Cities: Skylines II's setup wants a prefix
   in it, `setup.sh:105-106`; the installer may make a wrapper there). `find steam` has no variable:
   `make-steam-shortcut.sh` keeps its `--wrapper` option, which wins over the resolver in that script.
2. **The marker:** the direct children of `~/Applications` that carry the role and app ID asked for and pass
   every test of a candidate (below). One: that is the answer. A marker with `L1RenamePending` counts.
3. **No marked wrapper:** the table's old names, in today's order, each wanted with a prefix as today:
   `~/Applications/CS2dxmt11.app`, `~/Applications/CS2.app`, `/Applications/CS2dxmt11.app` for 949230;
   `~/Applications/SurvivingMars.app` for 3215050; `~/Applications/CS2dxmt11-pk110.app` for the Windows Steam.
4. **Still none, for a game:** the app in `~/Applications` that holds the game's program, which the CS2 launcher
   does today (`:40-42`). Surviving Mars gains the same. Unlike today's loop, whose glob follows a symlink and
   asks nothing of the app, step 4 asks every test of a candidate (below) but the marker: an app that step 2
   passed over for a failed test is not handed back here because it holds the game. An app that carries a marker
   of another role or another ID is passed over too: a store clone made by hand, without the strip at
   `make-steam-shortcut.sh:113-114`, would hold `Cities2.exe`.

*A candidate of step 2* is a real folder and not a symlink, named `*.app`, a direct child of `~/Applications`,
owned by this user and not writable by group or others (what `own_folder` asks, `move-install.sh:48-53`), with
`Contents/SharedSupport/prefix` and an executable `Contents/SharedSupport/wine/bin/wine64`, and with no
`com.apple.quarantine` attribute on the bundle. A marked app that fails a test is passed over, and `list` names
it with the test it failed. The Studio's three wrappers pass (mode 755, the user's own, no quarantine attribute:
read 2026-11-18), and so does an installer-made one (P3: bundle folder `drwxr-xr-x`, the user's own, no extended
attribute). **The tests judge the bundle folder itself and nothing inside it:** the template's launcher, and
`make-wrapper.sh:203-204` where it ended that launcher itself (`:196`), leave modes 666 and 777 inside, and P3's wrapper had `Contents` and the prefix writable by all and 2,043 entries
writable by group or others, so a test of `Contents` or below would pass over every installer-made wrapper. WT5
holds this. The MacBook's wrappers are read at W3 step 0, before its setup runs.

*Exit:* 0 with one path on standard output; 1 with none; 2 when two candidates carry the same marker, with one
line on standard error per path, each with `~`, and nothing on standard output. Two can happen: a wrapper cloned
by hand carries its donor's marker. **Every caller treats 2 as a stop of its own, never as "none":** the
launchers show their failure line and start nothing; each setup and installer exits 1 before it changes
anything; `repatch.sh` exits 1. The line says to move one to the Trash or to name one in the game's variable.
WT4b holds each caller.

*`incomplete`.* The old names are spelled only in this file, and the installer has to tell "no wrapper" from
"an old-named app that is not a whole wrapper" (3.4). `incomplete game <app ID>` looks at one place only, the
game's first old name in `~/Applications`, which is the path today's installers default to
(`~/Applications/CS2dxmt11.app`, `~/Applications/SurvivingMars.app`): it prints that path when it is a folder
with no `Contents/SharedSupport/prefix`, exit 0, and exits 1 otherwise. It is asked only after `find` has exited
1. The other old names are left out on purpose, so that today's stop is kept and not widened: a `CS2.app` or a
`/Applications/CS2dxmt11.app` with no prefix gets a wrapper made beside it today
(`cities-skylines-2/scripts/install.sh:83-90`, `install-core.sh:273-279`) and still does, and an app in the
system folder may not be the player's to move to the Trash.

*Who gave the variable.* The installer exports the game's variable itself once it has chosen a wrapper
(`install-core.sh:153`), so inside a setup run by the installer a set variable says nothing about the player.
`core_begin` therefore exports `L1_WRAPPER_GIVEN`, `1` when the game's variable was non-empty as the installer
was started and `0` when not, before it calls `game_wrapper` (`:272`). Each setup, as its first act on the
subject: when its `*_VIA_INSTALLER` is `1` and `L1_WRAPPER_GIVEN` is `0`, it unsets the game's variable. From
there on, in setup, the mover, the resolver and the app builders, "a wrapper was named" means one thing: the
variable is non-empty, and a person put it there. With `*_VIA_INSTALLER=1` and `L1_WRAPPER_GIVEN` not set at
all, the variable is kept: the cautious reading, under which nothing is renamed. Pass 1's builder built this
and its installer tests stayed green. Dropping the installer's export instead is not possible: Surviving Mars's
installer test has a setup stub that reads it.

*Deployed copies, and one reader.* Setup copies `wrappers.sh` beside each launcher: into the runtime folder for
Cities: Skylines II, into the state folder for Surviving Mars. A deployed file looks for it beside itself and
nowhere else. The repo's own copies of the same files look beside themselves and then at one fixed place each,
by their own depth in the tree (`launchers/` two levels up into `common/`, `repatch.sh` one level up), found
from `BASH_SOURCE` and not `$0`. The few lines that do this are the same in both launchers, and
`common/test-launcher-parity.sh` gains the rule that holds them equal. The Cities: Skylines II launcher is the
one deployed reader on a start: it resolves once and hands the game folder to `repatch.sh` in `CS2_GAME_DIR`,
as it does today (`:228`), and now to the badge patch too, which reads `CS2_GAME_DIR` in place of its spelled
path. Run by hand with no `CS2_GAME_DIR`, `repatch.sh` sources the file beside it and the badge patch runs
`bash <beside itself>/wrappers.sh find game 949230`; either stops with one plain line when the file is not
there. The installers source `common/wrappers.sh` from their own tree, and no longer hold a copy of the
launcher's function. The bookkeeping that follows:

- `common/check-deploy.sh:16-20` lists `wrappers.sh`; `move-install.sh:45`'s runtime names gain it;
- both setups' own-files checks (`cities-skylines-2/scripts/setup.sh:69-74`,
  `surviving-mars-relaunched/scripts/setup.sh:123`) and both installers' (`cities-skylines-2/scripts/install.sh:115`,
  `surviving-mars-relaunched/scripts/install.sh:216`) gain `common/wrappers.sh` and `common/move-wrappers.sh`;
- the state folder has no `check-deploy.sh` of its own, so Surviving Mars's `scripts/test-setup.sh` compares the
  deployed file with `cmp` (WT15).

*Considered:* the function inlined in both launchers and held equal by the parity test, as the lock code is.
Rejected: `repatch.sh` and the Python badge patch are run by hand too, and the installers and both setups need
the same rule.

**3.3 Names and place.** The names (WD3, decided 2026-11-20): `wrapper-949230.app`, `wrapper-3215050.app`, and
`wrapper-0.app` for the Windows Steam's (0: no game). `common/make-wrapper.sh:58-59` accepts them. The rule that
builds a name is the `name` function of `wrappers.sh`, and nothing else spells a new name. Because of 3.1 the
name carries no load, so a later change of mind about it is a rename and nothing else.

P2's pass rule, by the pieces Spotlight splits a name into (1.2): a wrapper may answer to the pieces of its own
name (`w`, `wr`, `wrapper`, the digits) and to nothing in target 3's list. P2 measured it: `mdfind` returns
`wrapper-999999.app` for `w`, `wr`, `wrapper`, `999999`, `99` and `1`, and for no word of target 3; Spotlight's
window showed it for none of `w`, `1l` and `wrapper`, nor did the Applications filter for `w` or the Apps view.
P2's apps were scratch apps minutes old and never opened; a renamed wrapper keeps its own history (P1).

The place stays `~/Applications` (WD2, decided 2026-11-20: rename in place). Each probe outcome and what W0
measured:

| Probe outcome | Branch | Measured in W0 |
|---|---|---|
| P1: on the MacBook, after a hand rename, Spotlight's window no longer offers the wrapper for `surviving mars`. P2: a scratch app made from an installer-made wrapper's whole `Info.plist`, under the new name, answers to none of the target's words and is not shown where a player browses apps | **A: rename in place.** The design of this section | **Selected.** P1 on the Studio: the renamed wrapper left the window at once, completion included. P2: as the row says. The MacBook's half of P1 is W3 step 6 (WD2) |
| P2: it answers to no word, but macOS lists it wherever apps are browsed (the Apps view, Launchpad's successor) | A, and WD6 (make a directly opened wrapper harmless) moves from "later" to "next" | Not met: no scratch app in the Apps view |
| P2: it still answers to a word through an attribute other than the file name | A, and the move also rewrites that attribute, in 3.1's one write. Never `CFBundleIdentifier` (3.1); and 1.2's plain queries return no wrapper through it, so this row is unlikely to be about the identifier | Not met: the identifier is not matched (P2), nor `CFBundleName` (1.2: `Steambuild` returns no app) |
| P3: an installer-made wrapper fails a test of a candidate (3.2): its bundle folder is writable by group or others, or it carries a quarantine attribute | The tests are fitted to what P3 reads before any code is written (or on the branch, for what W3 step 0 reads): a test that every player's wrapper fails would make step 2 pass over all of them. The fitted rule is written into 3.2, and WT5 follows it | Not met: the bundle folder passes. What is inside fails, so 3.2 now says the tests judge the folder only, and WT5 holds it |
| P1: Spotlight still offers the renamed wrapper for the words it learned | A rename does not fix the fault where it was seen. **B** is tried in the same visit: the wrapper moved by hand into `~/Applications/1launcher.noindex/`. If B clears it, that folder becomes the place, and step 2 of the resolver and the mover's target follow. If B does not, the plan stops and goes back to James with WD6 as the candidate | Not met on the Studio, which had learned nothing. Held for W3 step 6: there the build exists, so B is a change on the branch before the merge |
| P2: a folder named `*.noindex` in `~/Applications` does not keep an app out of Spotlight | B is not available; the P1 row above then has only WD6 | Not met: the `.noindex` app was in no query, so B is available |

*Rejected:* a symlink left at the old name (it puts the typed name back); `chflags hidden` (D6); moving the
wrappers under `~/Library` (the local-files plan decided "`~/Applications` is the standard place", and its data
root has a space, which Wine trees are kept off).

**3.4 The move is a script.** `common/move-wrappers.sh [--dry-run] [--held-by <pid>] [--holders-skip] <role> [<app ID>]`, with
the output contract of `cities-skylines-2/scripts/move-install.sh`: line 1 is `state: none`, `state: old` or
`state: part-way`; then `stop:` or `skip:` per reason; `would move:`, `moved:` or `not moved:` per rename; every
path with `~`. Exit 0 (renamed, finished an earlier rename, or nothing to do), 1 (skipped), 2 (the rename
failed after the marker was written: the next run finishes it), 3 (stop).

*States.*

| State | What is there | What a run does |
|---|---|---|
| `old` | an unmarked wrapper under an old name of 3.2's table, in `~/Applications` | writes the marker with `L1RenamePending`, renames, removes `L1RenamePending` |
| `part-way` | a wrapper that carries `L1RenamePending`, under any name | renames it if it is still under an old name and the target is free, then removes the key. Under any other name (the target, after a run killed just past its rename; or a name of the owner's own) it removes the key and renames nothing |
| `none` | anything else. Among it: a marked wrapper with no `L1RenamePending` under an old name, which is someone's own rename back (a rollback, a repaired Dock item), and a marked wrapper under any name of the owner's choosing | nothing. Target 2 says a name may be anything |

The marker is written before the rename, so there is no moment at which a wrapper is under a new name and
unmarked: a run killed between the two leaves a marked wrapper that step 2 of the resolver finds. To have setup
rename a renamed-back wrapper again, rename it by hand to what `bash common/wrappers.sh name …` prints.

*Which old-named app is the candidate.*

- **For a game:** the app that step 3 of the resolver returns, and it must pass every test of a candidate of
  3.2 but the marker. An old-named app outside `~/Applications` (`/Applications/CS2dxmt11.app`) is never
  moved: it is skipped with a line, and step 3 goes on finding it under its old name.
- **For the Windows Steam:** `~/Applications/CS2dxmt11-pk110.app`, and only when it passes the same tests, holds
  `steam.exe`, is not the wrapper `find game` returns for any game of the table, and holds no game's program.
  One that already carries a marker, of either role, is not in state `old`: it is `state: none`, exit 0, and
  not a skip. A generated `S734M.app` is a cross-check and not a source: when its
  `L1Prefix` names another wrapper than the candidate, nothing is moved and a `skip:` line names both. So an
  `S734M.app` once built with `--wrapper` at the game's wrapper cannot make the mover mark the game's wrapper as
  the store's.

*Stop* (nothing moved; exit 3):

- the wrapper's launch lock is held by a live process other than `--held-by`;
- for a game's wrapper, without `--holders-skip`, a process holds one of the wrapper's own named files open.

*The open-files probe.* It is never a scan: `lsof -u` took 30.3 s for 64,104 lines on the Studio (pass 1's
builder), and `lsof +D` would walk a 119 GB tree. It is `lsof -t -- <files>` on named files, 0.19 s each on the
same Mac: the files that exist among `wineserver`, `wine64`, `wine`, `wine64-preloader` and `wine-preloader` in
the wrapper's `Contents/SharedSupport/wine/bin/`, which every Wine process of that wrapper holds open as its
program. P5 measured that: during a download it listed all 16 processes of the wrapper's Wine, `steam.exe` and
its web helpers among them, through `wine64` and `wineserver`, the two of the five that wrapper has, and a
`wineserver` started by a path through `wine/lib/wine/../../bin/` among them. Its output is read, not its exit code
(`move-install.sh:54-55` says why). It has a hook of its own, `L1_WMOVE_PROBE=<program>`, called as
`<program> holders <wrapper>` and printing one process per line; `L1_MOVE_PROBE` is the folder mover's and is
not reused, because that stub's call count is tested (LT24). A second test variable,
`L1_WMOVE_STOP_AFTER=rename`, ends the mover straight after its rename (WT7d): its test sits on the line after
the `mv`, above everything else the mover does, so a marker written late falls below it. Tests stub the probe, but for one case that runs the real
call on a scratch program (WT8). What it misses: a Wine server left by an engine outside the wrapper
(`CS2_ENGINE`, `SM_ENGINE`), which holds none of the wrapper's named files (it and its game do hold files in the prefix). Its socket's place is known (P5,
1.5: `/private/tmp/.wine-<uid>/server-<device>-<inode>/` of the prefix) and is not added to the probe: the
lock and each setup's own "the game is running" test cover a game started by its launcher in that case, and
only a hand-run engine is left, which is the developer's own.

*Skip* (nothing moved; exit 1; setup goes on under the old name and says so):

- nothing is to be renamed this run: `L1_KEEP_WRAPPER_NAMES=1`, or the game's wrapper was named by the player
  (3.2; the Windows Steam's role has no variable, so this reason is the game role's alone);
- with `--holders-skip`, which setup passes only under an installer: a process holds one of a game's wrapper's
  named files (the P5 table below);
- **for the Windows Steam's wrapper, a process holds one of its named files.** Steam open in the store wrapper
  is the ordinary state while someone is buying, and that wrapper has no lock; it keeps its old name this run,
  one line says so, and the game's setup goes on;
- the target name exists;
- the wrapper or `~/Applications` is a symlink or not the user's own (a symlinked wrapper so stays under its old
  name, where a search still finds it; the line says that);
- the wrapper is outside `~/Applications`;
- `Info.plist` is missing, does not parse or cannot be written;
- two candidates;
- the store candidate fails one of its tests above.

*The order of the tests.* `state: none` and every skip that does not come from the probe are decided before a
stop is looked for. Then the lock is read, and then the open-files probe, each only for a wrapper that every
earlier test would let be renamed. The two skips that come from the probe (the Windows Steam's holder, and a
game's under `--holders-skip`) are therefore decided after the lock, and the lock's stop wins: a live lock
holder that is not `--held-by` gives exit 3 whether or not a file holder is there too. So a run with
`L1_KEEP_WRAPPER_NAMES=1`, or with the game's wrapper named by the player, exits 1 beside a held lock or an open
Steam, and never 3. Pass 2's builder measured the other order: a `skip:` line, then a `stop:` line and exit 3,
which would stop a declining player's setup where today it runs. No line the mover prints holds the word
"Spotlight": Surviving Mars's `scripts/test-setup.sh:107` counts that word in setup's output.

*To decline.* `L1_KEEP_WRAPPER_NAMES=1` in front of setup, of an installer, or of the pasted line: one word,
the same for both games, with no path to type (WD9). It holds for that run only, as the folder's decline does;
setup's line says so and prints the variable as a literal. A wrapper named by the player keeps that wrapper's
name too, because a named wrapper is used as it is; it is not a decline for the Windows Steam's wrapper, which
that run still renames.

*When, in each setup.* Stated once, because pass 1 found the first draft's order contradicted the code.

Cities: Skylines II (`cities-skylines-2/scripts/setup.sh`):

1. The wrapper is found once, above the header, where `:114` finds it today, now by the resolver. Exit 2 of the
   resolver stops setup here. Both are inside `MAC_ONLY=0`, as the own-files check is (`:70`): a `--mac-only`
   run needs no wrapper, is outside the check that `wrappers.sh` is there, and its exit 1 is read by the
   installer as "Rosetta is missing" (`install-core.sh:296-297`).
2. The header prints a `wrapper:` line beside the `move:` line, from `move-wrappers.sh --dry-run`. `--check`
   ends after the preflight as today, having said what a run would rename.
3. **Before anything is changed,** a stop of that dry run stops setup with exit 3, in the words of the folder
   move's stop. A stop is only looked for when there is something to rename (`state: old` or `part-way`): on a
   Mac already moved, setup runs beside an open Steam as it does today. It comes before the folder move (`:261`) on purpose: a stop after the folder had moved and
   before the app was rebuilt would leave an app that names a launcher that is gone.
4. The folder move, as today, with the lock of the wrapper found in step 1.
5. The copies into the runtime folder, `wrappers.sh` among them.
6. The mover for the game's wrapper, then for the Windows Steam's when one exists. A stop that appears only now
   (something started since step 3) is reported as a skip, and setup goes on under the old name. Exit 2 is
   reported with the mover's own lines, setup goes on with the marked wrapper under its old name, and the run
   ends with one problem counted, as a patch failure is today.
7. `WRAPPER`, `PREFIX`, `GDIR` and the badge step's folder (`:326-334`) are resolved again.
8. The badge step, the game's app (its `L1Prefix` from the path of step 7), 14unch3r, and `S734M.app` (below).

Surviving Mars (`surviving-mars-relaunched/scripts/setup.sh`):

1. That `common/wrappers.sh` and `common/move-wrappers.sh` are there is tested first, in the words of the
   own-files check, which itself comes only at `:123-125`: without this a missing file would fail as a shell
   error at the first call. Then the wrapper is found by the resolver where `:88` spells it today; the
   running-game and lock stops (`:99`, `:105`) follow as today; then the dry run's stop, exit 3.
2. The state folder's tests and the own-files check (`:120`, `:124`), `--check`'s exit, which now also prints the
   dry run's `wrapper:` line, and the copies (`:142-143`), `wrappers.sh` among them. Nothing has been renamed if any of these exits.
3. The mover. Then the wrapper is resolved again, and `make-app.sh` is given the game's program inside it.
4. The game's app and 14unch3r, as today. If the app is not built (`:152`), the wrapper is already renamed, and
   the game still starts: the deployed launcher is the new one and finds the wrapper by its marker (target 6).

*Through the installer.* What changes in `common/install-core.sh` and the two `scripts/install.sh`:

- `core_begin` exports `L1_WRAPPER_GIVEN` (3.2).
- Each `game_wrapper` asks the resolver. When `find` exits 1 it asks `incomplete` (3.2): if that prints an app,
  `game_wrapper` sets `W` to it, so that `core_begin` meets it with today's line, "looks incomplete … Move it to
  the Trash" (`install-core.sh:275-279`), and nothing is made beside it. That is the one app today's installers
  stop on, and no other: `incomplete` does not look at the rest of the old names (3.2). Without that verb the line is never
  reached: the old names are spelled only in `wrappers.sh`, and `W` would be `name`'s answer, a second wrapper
  beside the broken one. Only when both come back empty is `W` the default for a wrapper to be made:
  `~/Applications/` and `name`'s answer.
- **One behaviour changes for Cities: Skylines II.** An old-named `CS2.app` with a prefix and no game is left
  alone by today's installer, which makes `CS2dxmt11.app` beside it (`scripts/install.sh:83-90`). Step 3 of the
  resolver returns it, so the installer now installs the game into it and the mover then renames it: one wrapper
  per game, and the one that setup and the launcher find.
- Setup, run by the installer, unsets the variable the installer exported (3.2) and passes
  `--holders-skip` and `--held-by "$PPID"` to the mover, as the folder move does (`setup.sh:144`), so the installer's own hold on the
  lock is let through. The dry run before anything is changed (step 3 for Cities: Skylines II, step 1 for
  Surviving Mars) is given both options too: without them it would stop the installer with exit 3 on its own lock.
- **After setup returns, the installer resolves again.** Its `APP`, `WINEPREFIX` and `LOCK` name the old path,
  and `release_lock` (`:121`) would miss, leaving the installer's process number in the renamed wrapper's lock.
  A dead holder is treated as stale by the launchers' lock code (`:111-114`), but a reused number would read as "in use".
  So the core gains `core_after_setup <setup's exit code>`. When `L1_WRAPPER_GIVEN` is `0` it asks the resolver
  in a subshell that has unset the game's variable, points `APP`, `WINEPREFIX` and `LOCK` at the wrapper that
  comes back, and returns the code it was given; the exit trap then removes the installer's own link. Each
  `scripts/install.sh` keeps its own setup line as it is (`install.sh:121`, `:222`), calls
  `core_after_setup $?` on the next line, and exits with `$?` as today. Pass 2's builder built it this way. A
  core function that ran setup itself would need a new setting, because the two lines differ
  (`CS2_VIA_INSTALLER`, `SM_VIA_INSTALLER`), and moving the line turns both installer tests' mutants on it red
  for the wrong reason (`MUTANT=15`, and Surviving Mars's `MUTANT=14`, anchored to the end of the line). The
  subshell is `( unset SM_WRAPPER; … )`: a command run through `env` is forbidden in the installers by Cities:
  Skylines II's `scripts/test-install.sh:180-181`.
- **Surviving Mars's stop before its step 7** (`scripts/install.sh:209-214`) today fires whenever `SM_WRAPPER`
  was given, on the ground that the game's app starts the default wrapper. After this plan the app starts what
  the resolver finds. The stop therefore fires only when the given wrapper is not the one `find game 3215050`
  returns with the variable unset (asked in a subshell, as above; the two paths compared in their `pwd -P`
  forms, which is the form `core_begin` gives `W` at `:274`): an install into some other wrapper is still a
  test and gets no app, and a
  player who names the wrapper the app would use anyway gets setup.
- **Is anything of the installer's still using the wrapper when setup runs?** From the code: where the installer
  started Steam it closes it, waits, and ends the Wine server (`:479-492`); where the game was already installed
  it starts nothing. The download path can itself leave a holder: `:493-494` starts `wsrv -w` in the background
  and stops watching it after 15 s without ending it, and that process runs the wrapper's own
  `wine/bin/wineserver`, a file on the probe's list. So a wrapper whose game was downloaded in this run could
  have a holder at the setup step. P5 measured it (1.5): in three runs of the real installer into a new
  scratch wrapper made by `make-wrapper.sh`, one of them through the download path, no holder at the setup step
  and none 15 s later; `wsrv -w` did not outlive Steam's shutdown. So the first row below is selected.
  `--holders-skip` stays as written: it costs nothing when there is no holder, and it is what keeps the fourth
  row, a player's own Steam open before the installer began, from failing an install. The second row's wait is
  not built. W2 still has a live step through `install.sh` and not setup alone:

| P5 outcome | Design |
|---|---|
| no holder at the setup step, in three runs | as written. **Selected by P5 (2026-11-18 and 19)** |
| a Wine server of that prefix still up, the core's own `wsrv -w` among them | under the installer, setup first waits for it with `wineserver -w`, bounded at 15 s as the core's own wait is, then runs the dry run. **Not built (P5)** |
| a holder at the setup step | built whatever P5 found, and what `--holders-skip` is for: under an installer a file holder is a `skip:` and not a stop. The wrapper keeps its old name for this run, one line says the next run renames it, and an install is never failed by a rename. The lock's stop is unchanged: the installer's own hold is let through by `--held-by` |
| a holder that is the player's own Steam, open in that wrapper before the installer began | under an installer the same skip, and its line says to quit Steam and open the installer again to have the wrapper renamed. In a setup run by hand it stays a stop |

*After the move, in the same setup run.* The game's app is rebuilt, as every run does, and its `L1Prefix` comes
from the wrapper resolved again. 14unch3r is rebuilt, as every run does. `S734M.app` is rebuilt when it exists
and is the builder's own bundle, through a new `--no-clone` mode of `make-steam-shortcut.sh`: with no store
wrapper it builds nothing and says so, where a plain run would clone the game's wrapper (`:95-116`). Setup never
makes an `S734M.app` or a store wrapper that was not there.

**3.5 Makers and cloners.**

- `common/make-wrapper.sh` gains `--mark <role> [<app ID>]` and writes the marker itself, after the template's
  launcher has written `Info.plist` and before its last step moves the wrapper into place (`:224-226`). So an
  installer that dies between making and marking cannot leave an unmarked wrapper under a new name.
  `common/install-core.sh` passes the option (`:350`, `:352`). An unmarked app under a new name can then only
  be made by hand; step 4 of the resolver finds it if it holds the game, and otherwise `make-wrapper.sh`
  refuses to replace it, as it refuses today.
- The installers' default for a wrapper they make is `name`'s answer; neither `scripts/install.sh` spells a
  default (`cities-skylines-2/scripts/install.sh:83-90`, `surviving-mars-relaunched/scripts/install.sh:52`).
- `make-steam-shortcut.sh` marks its clone `steam-wrapper` straight after the copy (`:105`), replacing the
  donor's marker and app ID and removing any `L1RenamePending`, and finds donor and store through the resolver.
- `tools/split-wrapper.sh` marks its clone `game-wrapper` 3215050 and takes the clone's and the store's
  defaults from the resolver. Its donor has no default any more: the name it defaulted to (`:23`) now belongs
  to the generated Steam app, so the donor is given in `SPLIT_DONOR`.
- `tools/make-engine.sh:83` and `make-app.sh:25` take the wrapper from the resolver.
- `common/mac-inventory.sh` reports marked wrappers by role and app ID, and still names the old ones
  (`:138`, `:146`, `:169`).

**3.6 Research scripts.** Recommended (WD4): all 19 take the resolver, in a commit of their own. The 13 that
read `CS2_WRAPPER` change each place they spell the default; the 6 that spell the path gain the same line, and
`capture-freeze.sh:54` takes the name from the path found. Reason: `cell-fingerprint.sh` gates every render cell
and `boot-verify.sh` is the boot proof, so the standing instruments must follow; and a census test (WT12) is only
simple if no script is excepted. Cost: edits that only `bash -n` and the census test check, since the
experiments are not re-run. Dated records, the ledger's old rows and `config.json` files already written keep
the names they were written with, as O6 of the local-files plan decided for paths.

**3.7 Documents.** Living documents name a wrapper by its role ("the game's wrapper", "the Windows Steam's
wrapper") and give `bash common/wrappers.sh list` as the way to print the paths, so they are true before and
after a Mac's wrappers move. Both `CLAUDE.md` files, the two games' `README.md` and `INSTALL.md`, `GOTCHAS.md`'s
standing rules and `docs/agent-brief.md`. The root `CLAUDE.md`'s `common/` row gains the two new files and their
tests. Plans and dated findings stay as written. One mapping sentence, as the game's `CLAUDE.md` has for
`~/cs2-patch`, says which old name is which wrapper. The two `INSTALL.md` files gain the decline line and the
way back (section 9).

**3.8 Releases.** The change asks someone with an install to notice something, so the second number rises:
**`v0.3.0`**. Built on a branch, `wrapper-names`, pushed, and merged only after both Macs' live steps pass
(WD7), so that `main` can still take a game-update fix and nothing reaches a clone before the Mac that showed
the fault has been through it. The tag is cut on the merge, never before W3: a tag is not moved, and the MacBook
is the only Mac that can show whether the fault is gone.

`common/check-release-move.sh` gains a fourth question: a commit that holds `common/wrappers.sh` moves to
`release` only when `v0.3.0` exists and is it or an ancestor. **The gate cannot hold ON1.** `v0.3.0` is past
`v0.2.0`, so a move of `release` to it takes the folder move too, and the third question passes by itself. That
order is held by James's word and not by the gate: W4's question to him names both moves.

How each install reaches the new names:

| Install made by | Path |
|---|---|
| The pasted line, while `release` is at `v0.1.0` | nothing changes until `release` moves. If it moves straight to `v0.3.0`, the next run of the installer does both moves in one setup run: the folder, then the wrapper (WT11, WT17) |
| The pasted line, after `release` has moved to `v0.2.0` | the next run of the installer after `release` moves to `v0.3.0` renames the wrapper |
| A clone on `main` | the next `git pull` and setup after the merge |
| Someone holding `v0.1.0` or `v0.2.0` on a Mac already moved | **Cities: Skylines II** still starts: that launcher finds the renamed wrapper by the game inside it (1.6). That version's setup says there is no wrapper. Its installer finds the renamed wrapper the same way the launcher does (`install.sh:83-90`) and uses it; it makes a wrapper at the old name only when the renamed one holds no game. **Surviving Mars:** the launcher of those versions knows one spelled path and finds nothing, and its installer would make a wrapper at the old name beside the renamed one. The way through for both is to rename the wrapper back by hand (section 9); the new setup later leaves a renamed-back wrapper alone (3.4) |

The section for `CHANGELOG.md`, to be written at the build from what was built:

- Setup renames the game's Wine wrapper in `~/Applications`: the old and new names, per game.
- Why: Spotlight offered the wrapper beside the game's app, and a wrapper opened directly starts Steam outside
  the launcher.
- It is a rename with nothing copied; setup says what it renamed; it stops while the game, a launch or an
  install is using the game's wrapper, and skips when it cannot be done safely, among them while Steam is open
  in the Windows Steam's wrapper.
- The first start after the rename can take a few seconds longer (P4: 7 to 9 s on the Studio, one start);
  Steam stays signed in and macOS asks nothing.
- What stops working until pointed at the new name: anything of the player's own that names the old path (a
  Dock item made from the wrapper, an alias, a saved command, a Porting Kit entry).
- To decline: `L1_KEEP_WRAPPER_NAMES=1`, printed as a literal, in a clone and with the pasted line, for that run.
- Going back to an earlier version on a moved Mac: the row above.

**3.9 After a hand rename: the window and the Steam app.** Two readers hold a wrapper's path from the last
setup run, and target 2 has to say what a hand rename does to them (WD5).

- **14unch3r.** A stale `L1Prefix` is not only a lost "running" state. `state(of:)` returns `.absent` when the
  file it looks for under the prefix is not there (`launcher-window.swift:157-160`), the row is dimmed (`:765`)
  and reads "Not installed in Steam. See its set-up guide." (`:168`). Recommended: when the folder `L1Prefix`
  names does not exist, the window takes the prefix of the one app in the same folder whose `L1Role` is
  `game-wrapper` with the row's app ID (`steam-wrapper` for the Steam row). It already reads every app's
  `Info.plist` there, it runs nothing from the wrapper, and with none or two it stays as today.
- **`S734M.app`.** Its `launch` file holds `WRAPPER=<path>` (`make-steam-shortcut.sh:143`). Recommended: the
  builder also writes the path of the runtime folder's `wrappers.sh`, and the file, when `$WRAPPER` has no
  `wine64`, asks it for `find steam` before it shows its alert. No third copy of `wrappers.sh` is made.
- **Surviving Mars's app.** Its `GAME_EXE=` line (1.5) only feeds the "already running" notice, which has a
  second pattern that does not depend on the path. It is left as it is and is right again after the next setup.

If WD5 is answered "narrow": neither change is built, target 2 reads "from the game's app or a terminal", and
the notes say that the window and the Steam app follow a hand rename at the next setup run.

## 4. Phases

Each phase ends green before the next starts. Live steps, and anything public, run only on James's word.

### W0 — decisions and probes (no code)

The probes come before the design is frozen, in this order. Each records its result in section 1 of this file.
Those that write anything are on James's word, so WD10 is answered first; the other decisions wait for the
results (step 7). **Done to step 8's fold (2026-11-18 to 21):** P0 to P5 ran on the Studio on 2026-11-18 and 19,
P1 there and not on the MacBook (by James's choice; its MacBook half is W3 step 0 and step 6); James answered
section 8 on 2026-11-20; the fold is the "W0 fold" at the foot. What is left of W0 is step 8's re-check.

1. **P0, the Studio, nothing written.** James types `surviving mars`, `cs2` and `steam` into Spotlight and the
   order of the window's first rows is written down. It replaces the unmeasured line of 1.2.
2. **P1, the MacBook: the fault itself.** (Ran on the Studio, 1.2; the MacBook's reads are W3 step 0.) Read-only first: `common/mac-inventory.sh`; the `mdls` and `mdfind`
   lines of 1.2; `xattr -l`, the mode and the owner of each wrapper; whether its store wrapper passes the store
   candidate's tests of 3.4 (if it does not, it keeps its old name there and W3's step 6 cannot pass on `cs2`,
   so the rule is fitted before any code); the use count and last-used date of the
   Surviving Mars wrapper; and what Spotlight's window shows for `surviving mars` and `cs2`, written down as
   the "before". Then, with nothing of Wine running there: the Surviving Mars wrapper is renamed by hand to the
   recommended name; `mdfind` is polled until the old name is gone from it; James types the same words and the
   window's order is written down; the wrapper is renamed back. The outcome selects a row of 3.3's table. If
   the wrapper is still offered, branch B is tried in the same visit.
3. **P3, a scratch wrapper, the Studio.** (Ran 2026-11-18, 1.5: the marker survives.) A wrapper made by `common/make-wrapper.sh` under a scratch name, as
   the installer plan's live steps made them, then put in the Trash. Recorded: its whole `Info.plist` (kept in
   the workspace, not in this file), which keys hold its file name, `mdls`, `codesign -dv`, its mode, owner and
   attributes, the mode of the bundle folder itself and of `Contents` (3.3's candidate row), and the form of
   its bundle identifier. If James agrees to open it once directly: whether the
   template's launcher keeps `L1Role` when it rewrites the file. If it drops the key, 3.1's marker moves to a
   file in the prefix.
4. **P2, scratch apps, the Studio. After P3,** because it copies P3's `Info.plist` and not the Studio's own
   wrappers': a folder `~/Applications/wrapper-999999.app` holding that file whole (the stored name set to the
   new one, `NSBGOnly`, the package type and the icon as found) and a stub program that exits. `mdimport` it.
   Then `mdfind` for every word of target 3 and for the name's own pieces; the same with the issue's form,
   `1L-999999.app`; the same inside `~/Applications/1launcher.noindex/`. James types the words and looks at the
   Apps view. Everything goes to the Trash afterwards. 3.3 has the pass rule and the branches; it settles WD3.
5. **P4, the Studio: what a rename costs.** With nothing of Wine running: the Surviving Mars wrapper is renamed
   by hand, the game is started with `SM_WRAPPER` naming it, and three things are recorded: the time from start
   to the game's window against the last start before the rename; whether macOS checked the wrapper again;
   whether Steam was still signed in without a prompt. Then the name is put back. A start slower by more than
   30 s, or a new check by macOS, goes into section 5 and the notes as something a player will meet. A Steam
   sign-in prompt stops the plan until its cause is known: a rename that signs every player out is not shipped
   on this evidence.
6. **P5, the installer's setup step.** (Ran 2026-11-18 and 19, 1.5: no holder; the socket's place found.) With the scratch wrapper of P3 before it goes to the Trash, or a fixture
   run of the real installer in it as the installer plan's live steps did: at the moment the installer would
   run setup, `lsof -t` on 3.4's named files, and the place and holder of the prefix's server socket, three
   times. At least one of the three goes through the download path, the game downloaded by the installer in
   that run (as the Surviving Mars plan's ML4 did into a scratch wrapper), because that is the path that starts
   `wsrv -w` and stops watching it (`install-core.sh:493-494`); in that run the holders are read again 15 s
   later. 3.4's table says what each outcome changes.
7. James answers WD1 to WD9 and WD11 (section 8), with the probes' results in front of him.
8. The results are folded into sections 1 and 3, and the plan is checked again. No code before that check passes.

### W1 — the repo (branch `wrapper-names`)

**Built 2026-11-21** (the as-built header at the top says what and where; every item below is done).

1.1 `common/wrappers.sh` and `common/test-wrappers.sh` (WT1 to WT5c, WT12).
1.2 `common/move-wrappers.sh` and `common/test-move-wrappers.sh` (WT7 to WT9c).
1.3 `common/make-wrapper.sh`'s `--mark`; `common/install-core.sh` (`L1_WRAPPER_GIVEN`, the option passed,
    `core_after_setup`); both `scripts/install.sh` (`game_wrapper` with `incomplete`, the call on the line after
    setup's); Surviving Mars's stop before step 7 (WT10, WT11).
1.4 The deployed readers: both launchers, `repatch.sh`, the badge patch; both setups in the order of 3.4;
    `common/check-deploy.sh`; `move-install.sh:42` and `:45`; `boot-verify.sh` and `install-webhelper-shim.sh`
    (1.3: each takes its default from the resolver); the three app builders;
    `make-steam-shortcut.sh`'s clone, `--no-clone` and start-time lookup; `split-wrapper.sh`; `make-engine.sh`;
    `mac-inventory.sh`. Their tests, the golden file, and every row of section 6's second table (WT14 to WT18).
1.5 14unch3r: the prefix found by marker when `L1Prefix` is stale (3.9, if WD5 is yes); WT6 and WT6b in
    `common/test-launcher-window.sh`.
1.6 The research scripts (3.6), a commit of their own.
1.7 `common/check-release-move.sh`'s fourth question and its test (WT13).
1.8 Documents (3.7), `CHANGELOG.md`'s section under `## Unreleased`, and this plan's as-built header.
1.9 Every test file that exits 0 at `d50cf33` exits 0 on the branch (`common/check-identifiers.sh` exits 1 on
    `main` already, with 9 hits, by pass 1's builder: it is not this plan's and is recorded, not fixed here);
    every mutant of section 6 applied to real source and seen red, then restored.

### W2 — the Studio

James is told first; every Steam of the account is closed with `steam.exe -shutdown`, never `kill -9`. Recorded
before step 2: the three wrapper names, each wrapper's `Info.plist` copied into the workspace, and `--check`'s
output.

1. `bash scripts/setup.sh --check` for each game: Cities: Skylines II's names two renames, the game's wrapper
   and the Windows Steam's; Surviving Mars's names one; neither names anything else.
2. Cities: Skylines II's setup, from the branch. It renames the game's wrapper and the Windows Steam's, and
   rebuilds the game's app, `S734M.app` and 14unch3r. Then `scripts/boot-verify.sh`, detached with a log:
   `VERDICT: PASS`.
3. **Surviving Mars through its installer, not its setup:** `bash surviving-mars-relaunched/scripts/install.sh`
   from the branch, with the game installed, so that it goes straight to its setup step with the installer's
   own lock held and its own export in the environment. Pass: the wrapper is renamed; the installer exits 0;
   no `.launcher.lock` is left in the renamed wrapper. Then the game is started from 14unch3r and reaches its
   menu. Pass: the time from start to window is within 30 s of P4's "before", and Steam is signed in without a
   prompt.
4. `S734M.app` opens the store, signed in without a prompt.
5. `bash common/wrappers.sh list` prints three marked wrappers and no `L1RenamePending`; `--list` of 14unch3r
   prints two games and one Steam app, all `ready`. `lsregister -dump` is read for the three old paths, and for
   the records that carry a game app's bundle identifier (P1 found a second, the scratch copy of the Surviving
   Mars plan's ML4), and the counts are written down; they are a record, not a pass condition.
6. Spotlight. `mdfind` is polled, up to 60 s after an `mdimport` of each renamed wrapper, until the old names
   are gone. Then, for every word of target 3: no wrapper is returned, **and the positive control is**: the
   game's app, `S734M.app` or 14unch3r that 1.2's table shows for that word still is. James types
   `surviving mars`, `cs2` and `steam`, opening nothing. Pass, for each: no wrapper among the window's rows, and
   the field does not complete to a wrapper's name. Recorded beside P0's rows, not a pass condition: the Top Hit
   and the places of the game's app and `S734M.app` (P0: the macOS Steam takes `steam`'s Top Hit; P1: the repo's
   folder took `surviving mars`'s). Then `surviving mars` and `cs2` with the Applications filter on. Pass: no
   wrapper among the rows. Recorded, not a pass condition: whether the game's app is among them, and its place
   (P1 had it first for `surviving mars`, with the wrapper still under its old name; `cs2` was never read so).
7. The acceptance test of the keys-and-labels rule, by hand, on the Surviving Mars wrapper: renamed to
   `anything-at-all.app`; the game started from its app, then from 14unch3r (its row `ready`, if WD5 is yes);
   quit; the name put back to what `wrappers.sh name` prints. On the Windows Steam's wrapper: renamed,
   `S734M.app` opened, the name put back.
8. What names the old paths outside the repo: the 9 memory files; anything James finds in Porting Kit.

### W3 — the MacBook

A visit of its own, after W2, on the branch (`git fetch`, then the branch checked out). P1 ran on the Studio
(W0), so the MacBook's "before" is taken here, first:

0. **P1's MacBook half, read-only, before anything of the branch runs.** `common/mac-inventory.sh`; the `mdls`
   and `mdfind` lines of 1.2; `xattr -l`, the mode and the owner of each wrapper's bundle folder; whether its
   store wrapper passes the store candidate's tests of 3.4; the use count and last-used date of the Surviving
   Mars wrapper; and what Spotlight's window shows for `surviving mars`, `cs2` and `steam`, without and with
   the Applications filter, written down. If a wrapper fails a test of a candidate (3.2), or the store wrapper
   fails a store candidate's test of 3.4 (left under its old name it answers to `cs2`, so step 6 could not
   pass), setup is not run: the rule is fitted on the branch as 3.3's P3 row says, WT5 or WT9b follows, W2's
   affected steps are run again on the Studio, and W3 starts again. These reads write nothing, so they are taken
   at the first visit to the MacBook, before the build if one comes first; and W0 step 2's hand rename of the
   Surviving Mars wrapper and back (WD10 covers it) is offered at that visit too, because it is the one reading
   that can select branch B before the build instead of after it.

Then steps 1 to 7 of W2 there; its step 3 is Surviving Mars's installer too, and its wrapper there "was made the
old way". Its store wrapper is renamed only if step 0 found it a candidate. Step 6 is the one that matters most:
it is the Mac where the fault was seen, and the only one with a wrapper Spotlight has learned (WD2). Pass for
it: as W2 step 6, set against step 0's "before". If the window still offers the renamed wrapper, nothing is
merged: the branch stays, and branch B is tried by hand in the same visit (3.3's P1 row). If B clears it, B is
a rework of the checked design, not a step of this one: 3.2's step 2 and a candidate's "direct child of
`~/Applications`", 3.3's place, 3.4's mover and target, and WT5's "an app in a subfolder is passed over" all
change, and the rework must say how a wrapper already renamed and marked, which is `state: none` to today's
mover, reaches the folder. It is checked again before it is built, then W2 runs again on the Studio before
W3.

### W3b — merge and `v0.3.0`

After W2 and W3 are green: the branch is merged into `main` with `--no-ff`, pushed, and `v0.3.0` is cut on the
merge by the commands of the root `CLAUDE.md` (WD7). `CHANGELOG.md`'s section is read against what was built
before the tag.

### W4 — `release`

On James's word, on the commit he names, and with the question put to him in these terms: this move takes the
wrapper rename and, if `release` is still at `v0.1.0`, the folder move of ON1 with it. Then: the test files
pass, `common/check-release-move.sh` passes, `git push origin <commit>:release`; the root `CLAUDE.md`'s
"Published since" sentence records it. Then the pasted line, run on the Studio, renames nothing and exits 0.

## 5. Who notices what

| Audience | Effect | Mitigation |
|---|---|---|
| Players who installed with the pasted line | nothing until `release` moves. Then, at their next run of the installer, the wrapper in `~/Applications` has a new name and the game's app works as before. This route is the installer's, which exports the game's variable itself: 3.2's rule is what lets the rename happen there | setup prints the rename; `v0.3.0`'s notes; WT11 |
| Someone who starts the game by opening the wrapper | that habit is the fault. The wrapper is no longer found under its old name; the game's app and 14unch3r are | the notes name the game's app |
| Someone with their own Dock item, alias or saved command naming a wrapper | it stops working until pointed at the new name | the notes; setup's line gives both names |
| Someone with Steam open in the Windows Steam's wrapper while setup runs | the game's setup goes on; the store wrapper keeps its old name this run and one line says so; the next run renames it | 3.4's skip; WT8 |
| Someone whose running game, or another launch or install that holds the wrapper's lock, is using the game's wrapper | setup stops before it changes anything, exit 3, and says to try again when it has finished. A file holder under an installer is the next row | 3.4, step 3 of each order; WT8, WT17 |
| Someone whose game the installer downloaded in the same run | the install finishes. If something of that wrapper's Wine is still up at the setup step, the wrapper keeps its old name this run, one line says so, and the next run renames it | 3.4's P5 table; WT11 |
| Someone with an old-named `CS2.app` that has a prefix and no game | the installer installs the game into it and renames it, where today it makes a second wrapper beside it | 3.4; WT11 |
| People with a clone | the same, from the merge, at their next pull and setup | `--check` says what a run would do |
| Someone who declines | `L1_KEEP_WRAPPER_NAMES=1` for that run; both games, both routes. Surviving Mars's installer no longer stops short of its app for a player who names the wrapper the app uses | 3.4; WT9, WT11 |
| Anyone holding `v0.1.0` or `v0.2.0` on a moved Mac | 3.8's last row: Cities: Skylines II starts; Surviving Mars does not until its wrapper is renamed back | the notes; section 9 |
| Someone whose setup fails after the rename | the game still starts from its app: the new launcher was copied before the rename | 3.4's orders; WT17 |
| Someone who renames a wrapper by hand | every start of a game works. 14unch3r and `S734M.app` follow at once if WD5 is yes, else at the next setup run | 3.9; W2 step 7 |
| New installs | the wrapper is made under the new name and marked before it is moved into place | WT10 |
| Someone playing one game while the other game's setup runs | nothing: the mover looks only at the named files of the wrapper it was told about | WT8 |
| A player with a wrapper in `/Applications` | it keeps its old name and is found as before | 3.4; WT9 |
| Everyone, at the first start after the rename | a first start a few seconds slower (P4: 7 to 9 s on the Studio, one start, not separated from the spread of Steam's sign-in); no new check by macOS and no sign-in prompt | the notes, from P4 (3.8) |
| A player who types the game's name into Spotlight | the wrapper is no longer offered. What the window puts first instead is whatever else matches best: on a Mac with a checkout, the repo's folder of the game's name (P1); with the Applications filter the game's app was first while the wrapper was still there (P1, `surviving mars` only). On a Mac with no checkout, which a player who used the pasted line has, not measured: no live step of this plan runs on one | the notes name the game's app and 14unch3r; W2 and W3 step 6 record the rows |
| Porting Kit, if it lists the wrappers | its entry would name a path that is gone. Not checked (1.5) | W2 step 8 |
| Claude sessions | memory and both `CLAUDE.md` files name the old paths | 3.7; W2 step 8 |

## 6. Test plan

A mutant is a named change to real source that must turn the test red; each is applied and seen red at the
build, then restored. Tests run in a scratch home and never touch the real `~/Applications`; the system folder
of step 3 is read from a test variable there.

Three fixtures, named in the table because pass 1 found mutants that stayed green on the wrong one. **Bare:** a
wrapper with a prefix and a stub `wine64`, and no game's program. **Game:** bare, plus the game's program.
**Steam:** bare, plus `steam.exe`. A resolver or mover test whose mutant leaves an unmarked wrapper behind uses
bare or steam, because step 4 of the resolver finds a game fixture whatever its name, unless it fails a test of a candidate or
carries another marker. A fourth, for WT9b alone, is the **named store:** a steam fixture at the store's old
name that `CS2_WRAPPER` names. Where a test needs a live program inside a fixture, it is a bash script that
sleeps: a copy of `/bin/sleep` placed there is killed by macOS (signal 9, pass 2's builder).

| # | Test | Passes when | Mutant |
|---|---|---|---|
| WT1 | `find` by marker | a bare wrapper of an arbitrary name marked `game-wrapper` 949230, among unmarked apps: `find game 949230` prints it, exit 0 | step 2 removed: exit 1 |
| WT2 | a wrapper named by the player wins | with `CS2_WRAPPER` naming an unmarked bare wrapper and a marked one beside it, the named path is printed, its trailing slash gone; a named path that does not exist is printed too | step 1 moved after step 2: the marked one is printed |
| WT3 | old names, only while nothing is marked | an unmarked bare `CS2dxmt11.app` is found; an old-named app with no prefix is passed over for the next name; with a marked bare wrapper beside it, the marked one is printed | (a) steps 2 and 3 swapped (b) the prefix test dropped from step 3 (the case `test-setup.sh` MUTANT=36 held) |
| WT4 | two markers | two bare wrappers marked alike: exit 2, both paths on standard error with `~`, standard output empty | the count check replaced by "take the first" |
| WT4b | every caller stops on 2 | with two wrappers marked alike: the CS2 launcher and the Surviving Mars launcher start no Wine; each setup and each installer exits 1 with nothing copied or built; `repatch.sh` exits 1; and every one of them prints the duplicates line, asserted in each | in each caller in turn, 2 treated as 1. In Cities: Skylines II's setup the exit code and "nothing copied" cannot see this mutant, because a setup that finds no wrapper already ends so (`setup.sh:225-226`): there it is red by the line alone |
| WT5 | what is not a candidate | each of these, marked, is passed over, and `list` names the test it failed: a symlink named `*.app` whose target is a whole marked wrapper; an app in a subfolder; an `Info.plist` that does not parse; `L1Role` `game`; another app ID; no prefix; no `wine64`; a folder writable by group; a `com.apple.quarantine` attribute. The symlink, group-writable and quarantine cases are repeated on an unmarked game fixture under an unknown name, alone in the folder: `find` exits 1, because step 4 asks the same tests. **And what is a candidate:** a marked bare wrapper shaped as P3 read an installer-made one, its bundle folder 755 and the user's own, `Contents` and the prefix 777, `Info.plist` 666, is found, exit 0 | (a) the symlink test removed (b) the quarantine test removed (c) the `wine64` test removed (d) the tests dropped from step 4: the quarantined game fixture is printed (e) the group-or-others test applied to `Contents` as well as the bundle folder: the P3-shaped wrapper is passed over |
| WT5b | step 4 | an unmarked game fixture under an unknown name is found, for Surviving Mars as for Cities: Skylines II; one that holds the program but is marked `steam-wrapper` is passed over | (a) Surviving Mars's row loses its program path (b) the "marked otherwise" test removed |
| WT5c | the table, `name` and `list` | every game of `common/games.tsv` has a row; `name` prints the three names of 3.3; `list` prints role, app ID and `~` path of each marked wrapper and nothing of the home folder's name; `incomplete game 949230` prints `~/Applications/CS2dxmt11.app` when it has no prefix, and exits 1 when it has one, when it is not there, and for a `CS2.app` or a system-folder `CS2dxmt11.app` with no prefix | (a) a row removed (b) `list` printing the path as it is (c) the prefix test dropped from `incomplete`: a whole old-named wrapper is printed (d) `incomplete` reading every old name: the prefix-less `CS2.app` is printed |
| WT6 | 14unch3r does not list wrappers | `launcher-window --list`, with marked wrappers of both roles in the folder, prints the game apps and the Steam app only | the guard at `launcher-window.swift:127` widened to accept any role that starts `game` or `steam` |
| WT6b | 14unch3r after a hand rename (WD5) | a game app whose `L1Prefix` names a folder that is gone, with one marked wrapper of its app ID beside it: the row is `ready`; with two: as today | the lookup removed: the row is `absent` |
| WT7 | the move | a bare old-named wrapper: `state: old`, one `moved:` line, exit 0; it carries the marker and no `L1RenamePending`; `Info.plist` lints and has its old mode; a `CFBundleName` equal to the old name without `.app` becomes the new name without `.app`, as P3 found in an installer-made wrapper, while one that reads "Steambuild Metal" and the `CFBundleIdentifier` are unchanged; a second run is `state: none` | (a) the marker not written: `find` exits 1 on the bare fixture (b) the stored-name rewrite removed: `CFBundleName` keeps the old name |
| WT7b | part-way is finished | a wrapper under an old name with the marker and `L1RenamePending`: `state: part-way`, one `moved:`, exit 0, the key gone. The same keys on a wrapper under a name of the tester's own: `state: part-way`, no `moved:` line, exit 0, the key gone and the name kept | (a) the part-way branch removed (b) part-way renaming whatever the name is: the hand-named wrapper is renamed |
| WT7c | a failed rename | with `mv` made to fail: `not moved:`, exit 2, the marker and `L1RenamePending` present, the name unchanged, and `find` prints the old path; a second run with `mv` working is `state: part-way` and finishes | the key not written with the marker: the next run reads `state: none` and never finishes |
| WT7d | killed after the rename | on a steam fixture, with `L1_WMOVE_STOP_AFTER=rename`: the wrapper is under the new name and `find steam` prints it; a second run, without the variable, is `state: part-way`, renames nothing and removes `L1RenamePending` under the new name | the marker written after the rename, placed below the `L1_WMOVE_STOP_AFTER` test: `find steam` exits 1. Placed above that test the mutant is green here and only WT7c sees it |
| WT8 | the stops, and the probe | a live holder of the launch lock: exit 3, no rename; the same holder named in `--held-by`: renamed. A holder reported by the stubbed probe, game role: exit 3. Steam role: exit 1 and a `skip:` line. The real probe, unstubbed, with a scratch program, a bash script, running as the fixture's `wine/bin/wineserver`: exit 3; the same program running from another fixture wrapper: renamed. With `--holders-skip`, game role: a holder reported by the probe gives exit 1, one `skip:` line and no `stop:` line; a live lock holder not named in `--held-by` still gives exit 3, with and without a probe holder beside it. A recording `lsof` on `PATH` shows every call as `-t --` with file operands | (a) the probe given every wrapper's files (b) the steam-role holder left a stop (c) `--held-by` ignored (d) the call replaced by a scan by user (e) `--holders-skip` widened to the lock: exit 1 with a lock holder |
| WT9 | the skips, and names left alone | each gives exit 1 and renames nothing: `L1_KEEP_WRAPPER_NAMES=1`; a wrapper named by the player; the target name taken; a symlinked wrapper; a wrapper not the user's own; one in the system folder; no `Info.plist`; one that does not parse; one that cannot be written; two candidates. With a live holder of the lock, and with a holder reported by the probe, `L1_KEEP_WRAPPER_NAMES=1` and a wrapper named by the player still give exit 1, one `skip:` line and no `stop:` line. A marked wrapper with no `L1RenamePending` under an old name, and one under a name of the tester's own, are `state: none` and keep their names. Steam role, with `CS2_WRAPPER` naming another wrapper: the store wrapper is renamed, exit 0. No line of any case holds the word "Spotlight" | (a) part-way read from "marked and old-named" without the key: the renamed-back wrapper is renamed again (b) candidates taken from step 2 as well: the hand-named wrapper is renamed (c) the keep-names test dropped (d) the lock and the probe read before the skips: exit 3 with a holder (e) the named-by-the-player reason applied to the steam role: exit 1 and the store wrapper keeps its name |
| WT9b | the store candidate | each is a `skip:` and marks nothing: `S734M.app`'s `L1Prefix` names the game's wrapper; `CS2dxmt11-pk110.app` holds `Cities2.exe`; it has no `steam.exe`; it is the named-store fixture. One that already carries `game-wrapper` is `state: none`, exit 0, with no `skip:` line and its marker unchanged | the "not the game's wrapper" test removed: the named-store fixture ends up marked `steam-wrapper`. On a game fixture this mutant is equivalent, because the "holds no game's program" test still skips it; that is what the fourth fixture is for |
| WT9c | `--dry-run` | the lines read `would move:`, the exit is the real run's, and the wrapper's name and the bytes of its `Info.plist` are unchanged | the marker written in a dry run |
| WT10 | a new install | `common/test-make-wrapper.sh`: with `--mark game 949230` the finished wrapper carries the marker, and a run killed before the last step leaves nothing at the target. Both `scripts/test-install.sh`: the recorded call of the stub maker holds `--mark game <ID>` and the new name; the golden file shows the new name | (a) the marking removed from `make-wrapper.sh` (b) the option dropped in `install-core.sh` |
| WT11 | the installer's route | in a new case of each `scripts/test-install.sh` whose scratch copy keeps the real `setup.sh`, `wrappers.sh` and `move-wrappers.sh` (every other case there runs a recording stub of setup, written at `:186` and `:151`): through `cities-skylines-2/scripts/install.sh` and through Surviving Mars's, with fixtures, the game installed, an old-named wrapper and no variable given: the wrapper is renamed and marked, the app's `L1Prefix` names it, the installer exits 0 and no `.launcher.lock` is left in it. With the variable given by the caller: nothing renamed, and the line says a wrapper was named. With `*_VIA_INSTALLER=1`, the variable set and `L1_WRAPPER_GIVEN` not set, setup alone: nothing renamed. Surviving Mars with `SM_WRAPPER` naming the wrapper the resolver would find: setup runs and the app is built; naming another: the stop before step 7. An old-named app with no prefix and no other wrapper: exit 1 with the "looks incomplete" line, and the stub maker was not called. A `CS2.app` with no prefix and no other wrapper: the stub maker is called with the new name, as it is called with the old default today. An old-named `CS2.app` with a prefix and no game: the installer uses it and no wrapper is made. With a holder reported by the probe: the installer exits 0 with one `skip:` line and nothing renamed | (a) the export removed from `core_begin` (b) setup's unset removed (c) `core_after_setup` removed, at each installer's call in turn: a lock is left. Without the real-setup case in Cities: Skylines II's test, its removal there stays green (d) the unset default read as "not given" (e) Surviving Mars's stop put back to "whenever given" (f) `game_wrapper` not asking `incomplete`: a wrapper is made beside the broken one (g) `--holders-skip` not passed by setup: the installer exits 3 |
| WT12 | the census | over a scratch copy of the tracked files, not the working tree: the code files that match `CS2dxmt11`, `SurvivingMars` before `.app` or a non-letter, or `CS2.app` equal a list kept in the test: `common/wrappers.sh`, the fixtures of named tests, the one dated record. `CS2dxmt11` also catches `CS2dxmt11-pk110` and names spelled without `.app` (`mac-inventory.sh:138`) | (a) an old name put back into the copy's `repatch.sh` (b) `CS2dxmt11-pk110` put back into `make-steam-shortcut.sh` |
| WT13 | the release gate | a commit holding `common/wrappers.sh` fails without `v0.3.0`, passes with it as an ancestor | the fourth question's tag changed to `v0.2.0` |
| WT14 | the store's app | after a move, a rebuilt `S734M.app`'s `launch` file names the renamed wrapper. With no store wrapper and no `S734M.app` before setup, there is none after, and no wrapper was cloned. A foreign `S734M.app` is not touched. With `$WRAPPER` gone and a marked store wrapper elsewhere, the `launch` file finds it (WD5) | (a) `--no-clone` dropped from setup's call: a clone appears (b) the rebuild not run after a move (c) the start-time lookup removed |
| WT15 | deployed copies | both `scripts/test-setup.sh`: after a run the deployed `wrappers.sh` exists and `cmp` finds it equal to the repo's; `common/check-deploy.sh` counts it. A launcher in a scratch runtime folder with the file beside it and no checkout finds a marked wrapper; the same for `repatch.sh` run by hand, the badge patch run by hand, and `launch-relaunched.sh` in a scratch state folder; with the file gone, each stops with one plain line | (a) setup's copy of the file removed, in each setup (b) the look beside itself dropped, in each reader (c) the line removed from `check-deploy.sh` |
| WT16 | clones | `make-steam-shortcut.sh`'s clone of a marked bare donor, made in a scratch folder, carries `steam-wrapper`, no app ID and no `L1RenamePending`. `split-wrapper.sh`'s clone carries `game-wrapper` 3215050 | (a) the re-marking after `:105` removed: `find game 949230` exits 2 (b) the marking removed from `split-wrapper.sh`: `find steam` exits 2 |
| WT17 | the order in each setup | **Both moves in one run:** a scratch home in the `v0.1.0` layout (`~/cs2-patch`, `CS2dxmt11.app`): one run of Cities: Skylines II's setup moves the folder, renames the wrapper, and the app's `launch` file, its `L1Prefix` and the badge step's folder name the new places. **A stop comes first:** with a holder reported, setup exits 3 and the folder has not moved and nothing was copied. **Surviving Mars:** with an own file missing, setup exits 1 and the wrapper keeps its name; with the app builder made to fail, setup exits 1, the wrapper is renamed, the deployed launcher and `wrappers.sh` are there, and that launcher's `find` prints the renamed wrapper. **The header and `--check`:** with an old-named wrapper, `--check` of each setup prints one `wrapper:` line with `would move:` and both names, exits 0 and changes nothing; on a home already moved the line says nothing is to be renamed. **`--mac-only`:** Cities: Skylines II's setup with `--mac-only`, two wrappers marked alike and no `wrappers.sh` in its `common/` exits as it does today. **Surviving Mars with `wrappers.sh` missing:** exit 1 in the own-files words, before any call of the resolver | (a) `WRAPPER` not resolved again after the move: `L1Prefix` names the old path (b) the dry run's stop moved after the folder move (c) Surviving Mars's mover moved before the copies: the wrapper is renamed in the first case (d) the dry run dropped from the header: no `wrapper:` line (e) the `MAC_ONLY=0` guard taken off the resolver's call: `--mac-only` exits 1 (f) Surviving Mars's early test of the two files removed: a shell error in place of the own-files words |
| WT18 | the inventory | `common/mac-inventory.sh` reports each marked wrapper by role and app ID, and still names an unmarked old one | the marker not read |

Existing tests that change, by name. Pass 1's builder met each of these.

| File | What changes |
|---|---|
| `cities-skylines-2/scripts/test-setup.sh` | MUTANT=36 (`:45`, `:105`) patches the loop over `WRAPPERS`, which is gone: retired there and rehomed as WT3's second mutant. The two badge cases (`:224`, `:383`) assert a warning that names the spelled wrapper; they become "the badge step uses the wrapper setup found". The probe stub (`:136`) is joined by one for `L1_WMOVE_PROBE`: without it every run would reach the real `lsof` (pass 2's builder: the file then ran 98 s against 56 s, each case still under 20 s; the stub stays). "A common/ with paths.sh and no window builder" (`:297`) makes its `common/` by hand: the harness copies `wrappers.sh` and `move-wrappers.sh` into it, or the own-files check fails the case. New cases: WT15, WT17 |
| `cities-skylines-2/scripts/test-move-install.sh` | MUTANT=7 (`:12`, `:33`) patches the same list in `move-install.sh`'s by-hand lock fallback: rewritten against the resolver (the builder's rewrite went red) |
| `cities-skylines-2/scripts/test-install.sh` and `test-install.golden` | the "copies held identical to the launcher's" rule (`:169`) and `launchers_choice` (`:374-386`) end for `find_wrapper`: the installer sources the resolver. "A wrapper without a prefix folder" (`:393`) keeps its result, exit 1 and nothing deleted, under the rule of 3.4. The golden file is recorded again (127 lines name `CS2dxmt11`). "A wrapper to be made, with a game running in another wrapper: made, not taken for ours" (`:462`) expects the old default name in the maker's recorded call and takes `name`'s answer. New cases: WT10, and WT11 in a case that keeps the real setup |
| `surviving-mars-relaunched/scripts/test-install.sh` | its mutants 11 ("setup run with `SM_WRAPPER` given") and 20 ("`SM_WRAPPER` read after `core_begin`") are rewritten for 3.4's stop and `L1_WRAPPER_GIVEN` (as they stand, 11 refuses to apply and 20 stays green: pass 2's builder); "the engine is given the temporary folder's pieces" (`:234`) expects the old default path in the engine's recorded call and takes the new one; its stub maker records `--mark`; its fixture wrappers gain an `Info.plist`. New cases: WT10, and WT11 in a case that keeps the real setup |
| `surviving-mars-relaunched/scripts/test-setup.sh` | the launcher's function held identical; the closing-line case (`:107`) counts the word "Spotlight" in setup's output and stays at 0, which is why no line of the mover holds it (3.4); new cases WT15, WT17 |
| `cities-skylines-2/scripts/test-make-steam-shortcut.sh` | its rule that every build has a `--from` that does not exist (`:3-5`) gains one exception, WT16's scratch donor; `--no-clone` and the start-time lookup (WT14) |
| `common/test-make-wrapper.sh` | `--mark` (WT10); the mode case at `:422` now also holds after a marking |
| `common/test-mac-inventory.sh` | `:158-159` ("one of the six this script knows", "a wrapper it knows is reported") follow WT18 |
| `common/test-launcher-parity.sh` | a rule for the lines by which each launcher finds `wrappers.sh` |
| `common/test-launcher-window.sh` | WT6, WT6b |
| `common/test-check-release-move.sh` | WT13 |
| The other test files among the 21 of 1.4 | each either keeps an old name as a fixture and goes on WT12's list, or takes the name from `wrappers.sh name`. Which, per file, is settled at the build and checked by WT12 |

Live, not automatable: W0's probes (run 2026-11-18 and 19, recorded in section 1), W2 steps 2 to 7, W3 (step 0
among them) and W4. A green suite does not show what Spotlight's window puts first. No live step renames an
installer-made wrapper: W2 and W3 run on Porting Kit clones, whose `CFBundleName` is "Steambuild Metal", and W4's
pasted line renames nothing. So the `CFBundleName` rewrite, and a start of the game after it, rest on WT7 alone.
The risk is small: P5's scratch wrapper, made by the installer with its own name in `CFBundleName`, ran Steam
and took the game's download; the rewrite only changes that one string.

## 7. Exit criteria

1. W0: P0 to P5 are recorded in section 1, each with what it settled: a row of 3.3's table for P1, P2 and P3, a
   row of 3.4's for P5, the "before" for P0, and P4's three readings against its thresholds. The plan has
   passed a re-check after them. Recorded 2026-11-21: P1 and P2 row A, P3 no row (the bundle folder passes),
   P5 "as written", P0's "before" in 1.2, P4 inside every threshold; the re-check is in the Review log.
2. WT1 to WT18 pass on the branch, every mutant seen red on the fixture section 6 names for it (pass 2 found
   three that are equivalent on any other: WT4b's in Cities: Skylines II's setup, WT7d's, WT9b's), every row of
   section 6's second table done, and every test file that exits 0 at `d50cf33` still exits 0.
3. W2 and W3 pass on both Macs, with each step's pass condition, the boot-verify verdict and the Spotlight
   results recorded in this file, P0's and P1's "before" beside them, and W3 step 0's reads recorded before the
   MacBook's setup ran.
4. `git grep` finds the old wrapper names in no code file outside WT12's list.
5. `v0.3.0` exists with its page, cut after W3.
6. W4: `release` has moved on James's word, the root `CLAUDE.md` records where it stands, and the pasted line run
   on the Studio renamed nothing and exited 0. Until then this plan is built but not published, and its header
   says so.
7. #26's checkboxes are ticked; anything found and not fixed has an issue of its own. Known at the W0 fold, opened
   2026-11-21 on James's word: #27, WD6 (a wrapper opened directly); #28, the game's app not offered in
   Spotlight's window without a filter even when no wrapper is (P1); and #29, what another account can change
   inside a wrapper whose `Contents` is writable by all (P3, 3.1).

## 8. Decisions for James

| # | Question | Recommendation |
|---|---|---|
| WD1 | The marker: `L1Role` `game-wrapper` / `steam-wrapper` with `L1SteamAppID` in `Info.plist`, and `L1RenamePending` while a rename is under way | Yes, as 3.1. It reuses the keys three builders and the window already know, and no build of 14unch3r lists it. The third key is what lets a rename back by hand stay put. P3 can move the marker to a file in the prefix |
| WD2 | The place: rename in `~/Applications`, or also move into a folder Spotlight skips | Rename in place, if P1 shows the rename clears the fault on the MacBook. The measurements say the file name is the only thing a player's word matches; what Spotlight has learned is the unknown, and P1 tests it before any code. 3.3 has the branch for each outcome |
| WD3 | The names. The issue's `1L-…` shares a prefix with "1launcher" (`mdfind 1L` returns `14unch3r.app`), and `-store` is a word of `S734M.app`'s alternate names | `wrapper-949230.app`, `wrapper-3215050.app`, `wrapper-0.app`, confirmed by P2. `mdfind` returns them for `w`; Spotlight's window did not show one for `w` (P2, scratch apps never opened). Since the name is only a label after this plan, a wrong choice costs one rename |
| WD4 | How far into the research scripts | All 19, in a commit of their own (3.6). The other choice: only the standing instruments, with the rest on WT12's list and broken on a moved Mac until someone needs them |
| WD5 | After a hand rename, should 14unch3r and `S734M.app` find the wrapper again by themselves (3.9), or is target 2 narrowed to "from the game's app or a terminal" | Build both. Without them the window shows the game as "Not installed in Steam" and the Steam app shows its alert until the next setup run, and the rule's own test, rename on a whim and nothing breaks, fails at W2 step 7. The cost is one lookup in Swift over plists the window already reads, and four lines in a generated file |
| WD6 | A renamed wrapper can still be double-clicked in Finder. Should a directly opened wrapper be made harmless (its `CFBundleExecutable` replaced by a file that opens the game's app) | Not in this plan: an issue of its own. It changes Porting Kit's bundle further and needs its own probe. It becomes the next thing if P2 shows the wrappers where apps are browsed, and the only candidate if P1 shows that neither a rename nor a `.noindex` folder clears what Spotlight learned |
| WD7 | When the branch is merged and `v0.3.0` cut, and by whom | After W3, the MacBook's live step, by the session, as O10 had it for `v0.2.0`. The MacBook is the only Mac that showed the fault, a tag is never moved, and nobody is waiting. The other choice, merge after W2 and tag after W3, gives clones the rename before the Mac that matters has run it |
| WD8 | The order against ON1 (`release` to `v0.2.0`) | Independent, and held by his word alone: the gate cannot tell a move to `v0.3.0` from "both moves at once" (3.8). If `release` is still at `v0.1.0` when `v0.3.0` exists, it can go straight there, and W4's question to him says in so many words that the folder move goes with it. WT17 covers both moves in one run |
| WD9 | How a player declines | `L1_KEEP_WRAPPER_NAMES=1`, for that run: one word for both games and both routes, no path to type. The first draft's way, the game's variable with the old path, did not work through the pasted line for Surviving Mars and is what the installer itself sets. A wrapper named by the player still means "use this one as it is" |
| WD10 | The probes that write, each on his word: P1's hand rename of the MacBook's Surviving Mars wrapper and back (and, if needed, its move into a `.noindex` folder and back); P2's scratch apps; P3's and P5's scratch wrapper, a download of about 237 MB, and for P5 one download of a game into it by the installer (3.4's download path, as ML4 did); P4's hand rename of the Studio's Surviving Mars wrapper, one start of the game, and back | Yes to all five, in W0's order. P1 is the one that can save the whole build: it is the first test of whether a rename fixes the fault where it was seen |
| WD11 | The wrappers' bundle identifier was printed in this file at `d50cf33`, which is pushed. It holds no account or person's name; its name part is the first wrapper's name and its digits look made per wrapper (1.5). Pass 2: the template's launcher writes it per wrapper (`make-wrapper.sh:140`), and it is in this file at no commit after `d50cf33` | Leave the history as it is and keep the value out from here on, as this rework does. P3 says whether an installer-made wrapper gets its own. If he would rather it were gone from the history, that is a rewrite of a pushed branch and his call alone |

**Answered 2026-11-20 (W0 step 7), with P0 to P5's results in front of James: every decision as recommended.**
WD10 was answered first, yes to all five probes, and they ran on 2026-11-18 and 19. WD1: the marker in
`Info.plist` (P3: Wineskin's rewrite keeps it). WD2: rename in place, branch A; P1 ran on the Studio, not the
MacBook, so W3's step 6 is the MacBook's test, and nothing is merged if it fails (3.3's P1 row). WD3:
`wrapper-<ID>`. WD4: all 19. WD5: build both. WD6: an issue of its own, not this plan (#27). WD7: merge and `v0.3.0`
after W3. WD8: independent of ON1. WD9: `L1_KEEP_WRAPPER_NAMES=1`. WD11: history left, the value kept out.

The table's rows are the questions as they were put, written before the probes; where a row's conditions name a
probe, this paragraph and 3.3's "Measured in W0" column hold. WD1's "P3 can move the marker" did not happen.
WD2's "P1 tests it before any code" is W3 step 6, after the code and before the merge. WD6's two conditions:
"next" if P2 showed the wrappers where apps are browsed (it did not), and "the only candidate" if neither a
rename nor a `.noindex` folder clears what Spotlight learned, which W3 step 6 now decides.

## 9. Rollback

- **Before W2:** the branch is dropped. Nothing on any Mac changed except what the probes made, which
  went to the Trash, and the two hand renames of P1 and P4, which were put back in the same step.
- **A Mac that was moved, to go back to the old names:** with the game and Steam closed, rename each wrapper back
  by hand. The marker stays and is harmless to every earlier version, and because it carries no
  `L1RenamePending` the new setup leaves the wrapper under its old name from then on (3.4, WT9). Then run setup
  once: it rebuilds the apps with the old path. `L1_KEEP_WRAPPER_NAMES=1` is for a Mac not moved yet; it is not
  needed after a rename back.
- **A Mac that was moved, to stay moved on an older version:** nothing to do for Cities: Skylines II. Surviving
  Mars at `v0.1.0` or `v0.2.0` needs its wrapper renamed back, as above (3.8's last row).
- **A rename that was skipped** (a decline, a holder under an installer, a store wrapper with Steam open):
  nothing to undo. The wrapper is under its old name and every script finds it there, by the old name when it
  is not marked and by its marker when the skipped run was finishing a part-way rename; the next run that is
  not skipped renames it.
- **A rename that failed half-way** (exit 2): the wrapper is marked and under its old name; every script finds it
  by the marker; the next setup run finishes it.
- **After `release` has moved:** `release` only moves forward. A fault gets a successor version; meanwhile the
  decline line of the notes keeps an install not yet moved on its old name, on both routes and for both games.
- **Recorded before W2 step 2 and W3 on each Mac:** the three wrapper names, each `Info.plist`, and the output
  of `--check`.

## 10. Not in this plan

- **Making a directly opened wrapper harmless** (WD6: #27). P3 gives it a fact:
  a wrapper opened directly and quit has its `use start.exe` flipped from 1 to 0 by Wineskin's rewrite.
- **A guard in the launchers against a second game or a second Steam.** `docs/plans/launcher-window.md` already
  lists it as not built. Since the split, no lock serialises the Windows Steam against a game's wrapper.
- **The wrappers' shared bundle identifier** (1.5). Three apps with one identifier may confuse LaunchServices and
  Spotlight's ranking; changing it touches what the template's tools key on. P3: an installer-made wrapper gets
  an identifier of its own, built from its first file name. So wrappers cloned from another (the Studio's
  three; a store wrapper `make-steam-shortcut.sh:105` cloned; a `split-wrapper.sh` clone) share one, and two
  installer-made wrappers do not. The MacBook's are unread.
- **Moving the wrappers out of `~/Applications`**, unless W3 step 6 selects branch B (3.3).
- **The game's app as Spotlight's Top Hit** (P1). Not a target (target 3): what else is on the Mac decides it.
  #28.
- **Modes inside an installer-made wrapper** (P3: `Contents` and the prefix writable by all). As today; #29
  (3.1).
- **Renaming `S734M.app`, the game apps or 14unch3r.** They are the things meant to be clicked.
- **Porting Kit's own records.** Not readable under this project's rule; James looks, at W2 step 8.
- **Spotlight's Search Privacy list** as a fix. It is a per-Mac system setting the owner changes by hand; #26
  names it as the stopgap until this plan is built.
- **Re-running the experiments** whose scripts 3.6 edits.
- **A wrapper in `/Applications`.** It is found and used, and never renamed.
- **`common/check-identifiers.sh`'s 9 hits on `main`.** Older than this plan.

## Review corrections (check it 2026-11-18, pass 1)

Six lenses against `d50cf33`: architecture, platform facts and the builder `build-ready-with-fixes`;
correctness, rollout with security, and the test plan `needs-rework`. The builder (Opus 5.5) built W1 in a
scratch worktree and ran the tests and mutants. Pass verdict: needs-rework. The session re-read B1 and B3 in the
code before the rework; the rework opened each cited file again. Four blockers and 23 should-fix items; all were
folded, with the five changes listed under "Rejected or changed". Pass 2 found S6, S17 and S18 folded only in
part (the second pass, below).

| # | Finding | Lenses | Folded into |
|---|---|---|---|
| B1 | The installer exports the game's variable before it runs setup (`install-core.sh:153`, from `:280` and `:356`), and the first draft skipped the move whenever that variable was set. No run of the pasted line would ever have renamed | architecture, correctness, rollout, builder (built the fix) | 1.3; 3.2 ("Who gave the variable", `L1_WRAPPER_GIVEN`); 3.4 (skip row, "Through the installer"); section 5 row 1; WT11 with five mutants; target 4 |
| B2 | A rename inside an installer run left the installer's `APP`, `WINEPREFIX` and `LOCK` on the old path, and nothing said whether the installer's own Steam or Wine server still held the wrapper | correctness | 3.4 ("After setup returns, the installer resolves again"; the P5 table); W0 step 6; W2 step 3 through `install.sh`; WT11's lock assertion |
| B3 | Declining for Surviving Mars through the pasted line could not work: its installer stops before its app whenever `SM_WRAPPER` is given (`install.sh:209-214`) | rollout | 3.4 ("To decline", and the stop's new condition); WD9; section 5; section 9; 3.8's notes; WT9, WT11 |
| B4 | Three mutants could not turn their tests red (the resolver's step 4 found the fixture anyway; the order mutant was equivalent; the test placed the deployed file itself), a half-way rename had no test, and the marking mutant stayed green in Surviving Mars's installer test | test plan, builder | section 6: the three fixtures; WT7 to WT7d; WT10 (new, two places); WT15; WT17 |
| S1 | A scan with `lsof` took 30.3 s, four times per setup, past the tests' 20 s limit | builder | 3.4 ("The open-files probe"); `L1_WMOVE_PROBE`; WT8; second table (`test-setup.sh`) |
| S2 | Steam open in the store wrapper would have stopped the game's setup | architecture, rollout, correctness, builder | 3.4 (skip row); section 5; WT8 |
| S3 | A wrapper renamed back on purpose would have been renamed again as "part-way" | rollout | 3.1 (`L1RenamePending`); 3.4 (states); section 9; WT7b, WT7c, WT9 |
| S4 | The store candidate was taken from `S734M.app`'s `L1Prefix`, which can name the game's wrapper | rollout | 3.4 (the store candidate); WT9b |
| S5 | Setup's rebuild of `S734M.app` could clone a wrapper | rollout, test plan | 3.4 (`--no-clone`); WT14 |
| S6 | A marked app outranked the known names with nothing asked of it | rollout | 3.2 (a candidate of step 2; measured on the Studio's three); WT5 |
| S7 | The first draft said a stale `L1Prefix` costs only the "running" state. It dims the row and says "Not installed in Steam" | architecture | 3.9; target 2; WD5; WT6b; W2 step 7 |
| S8 | 1.5 said no game app's `launch` file holds the wrapper's path. Surviving Mars's does | correctness | 1.5; 3.9; 3.4 (Surviving Mars, step 3) |
| S9 | An installer-made wrapper very likely holds its file name in `Info.plist`, and the scratch app of P2 copied the Studio's instead | architecture, platform | 1.5; 3.1 (the stored name); W0 (P3 before P2); 3.3's table; WT7 |
| S10 | The fault itself was never probed before the build, and the tag was cut before the MacBook's step | architecture, platform | 1.2; W0 (P0, P1); 3.3 (the P1 rows); 3.8 and W3b (the tag after W3); WD2, WD7, WD10; target 3 |
| S11 | The cost of a rename was first measured at a live step, with no threshold | platform | W0 (P4, with its thresholds); W2 steps 3 and 4; section 5 |
| S12 | A failed Surviving Mars setup could leave a renamed wrapper and an old launcher | rollout | 3.4 (Surviving Mars's order); target 6; WT17 |
| S13 | "Before it first asks for the wrapper, after the folder move" described an order the code does not have | correctness, builder | 3.4 ("When, in each setup"); WT17 |
| S14 | A wrapper in `/Applications`, once renamed, would have been found by no step | correctness | 3.4 (never moved); section 5; section 10; WT9 |
| S15 | An unmarked wrapper under a new name had no state, and a wrapper with no `Info.plist` no rule | correctness | 3.5 (`make-wrapper.sh --mark`, before its last step); 3.1; 3.4 (skip row); WT10; second table |
| S16 | Deployed-copy bookkeeping: `check-deploy.sh`, the mover's runtime names, no deploy check for the state folder, a fallback to "the checkout" that a deployed file cannot make, four deployed readers | architecture | 3.2 ("Deployed copies, and one reader"); 3.9 (no third copy); WT15; second table |
| S17 | Unspecified: how a name maps to an app ID in a deployed copy; a variable for `find steam`; where exit 2 goes; the installer's rule for an old-named app with no prefix; Surviving Mars's default | builder | 3.2 (the table, step 1, exit); 3.4 ("Through the installer"); 3.5; WT4b, WT5c |
| S18 | Features with no test | test plan | WT5b, WT5c, WT9, WT9b, WT9c, WT10, WT16, WT18 |
| S19 | Existing tests that change were not named | test plan | section 6's second table; 1.4 |
| S20 | The census read the working tree and missed two of the names | test plan | WT12 |
| S21 | Live steps that could not fail, had no bound or no "before", and W4 in no exit criterion | test plan, rollout | W2 steps 3 to 7; W3; section 7 |
| S22 | The fourth question lets `release` take the folder move without ON1's word | rollout | 3.8; W4; WD8 |
| S23 | The wrappers' bundle identifier was printed without knowing whether it is the template's constant | rollout | 1.1, 1.5, section 10 (the value removed); WD11; P3 |
| minor | The folder mover's list is at `:42`; step 1 covered three behaviours; several research scripts spell the default more than once; a second plist reader; `split-wrapper.sh`'s donor default; mode 666; a symlinked wrapper stays visible; step 4 and other markers; a Wine server of an outside engine; one keystroke shows three wrappers; the old Cities: Skylines II installer finds a renamed wrapper | several | 1.3, 1.4; 3.1; 3.2; 3.3; 3.4; 3.5; 3.8's last row |

Rejected or changed:

- **S16's last suggestion, in part.** "One deployed reader, not four" is taken for a start of the game. It is
  not taken for `repatch.sh` and the badge patch run by hand, which both `CLAUDE.md` files document: they keep a
  lookup of their own, beside themselves only.
- **A minor: the installer's own-files loop "at about `:111`".** It is at `:115`, as the first draft had it
  (`grep -n`). The other half of that note is right: `setup.sh:123` is Surviving Mars's setup, not its
  installer, and 3.2 now names both.
- **B3's first option** (change the stop only for a wrapper equal to the old default) is replaced by a rule
  that does not spell a default, and by a decline that does not go through the game's variable at all.
- **S10's "or"** is taken on both sides: the fault is probed in W0 and the tag waits for W3.
- **The test-file count.** Pass 1 said 18 test files spell an old name. Counted over the three patterns at
  `d50cf33` it is 21, and 1.4 says how it was counted.

### Rework (2026-11-18)

One agent (Fable 5.2) rewrote sections 2 to 10 in place and corrected section 1, against `d50cf33`. It opened
`common/install-core.sh`, `common/make-wrapper.sh`, `common/check-deploy.sh`, `common/check-release-move.sh`,
`common/launcher-window.swift`, both games' `scripts/setup.sh` and `scripts/install.sh`, both launchers,
`repatch.sh`, the badge patch, `move-install.sh`, `make-shortcut.sh`, `make-steam-shortcut.sh`, `make-app.sh`,
`split-wrapper.sh` and the test lines section 6 cites. It read the mode, owner and attributes of the Studio's
three wrappers and their bundle identifiers, and wrote nothing outside this file. It built nothing and gave no
verdict: pass 2, below, checked this text.

Choices the rework made, for the re-check to challenge:

1. The decline is a variable of its own, and a wrapper named by the player is a separate reason, for the game's
   wrapper only (pass 2's fold).
2. The installer keeps its export; setup undoes it when the player did not give it, and reads "not set at all"
   as given.
3. The rename runs after the copies in both setups, with its stop tested once before anything is changed; a
   stop that appears later in the same run is downgraded to a skip.
4. The marker is written by `make-wrapper.sh` before its last step, not by the installer afterwards.
5. A renamed-back wrapper stays put for good, and the way to undo that is a hand rename.
6. 14unch3r's lookup and `S734M.app`'s start-time lookup are in scope, behind WD5.
7. The branch is merged only after the MacBook's step, and the MacBook runs the branch.
8. `S734M.app` reads the runtime folder's copy of `wrappers.sh` and gets none of its own.

Not verified: every mutant (none was run by the rework; the builder's results are quoted where the findings
gave them); the line numbers of `v0.1.0` and `v0.2.0` in 3.8's last row, which are today's; the form of a
bundle identifier beyond the three on the Studio; where a Wine server keeps its socket; that `lsof -t` on a
program file lists every process running it under Rosetta (the builder timed the call, P5 and WT8's unstubbed
case test what it returns); the MacBook.

### Second pass: fitted re-check of the rework (2026-11-18) — build-ready-with-fixes, folded

Two agents against `ea4de42`. A fold verification (Fable 5.2, read-only): build-ready-with-fixes. A builder
re-check (Opus 5.5) that built the installer's path, the mover's states and the least of the resolver in a
scratch worktree, ran the tests and the mutants, and removed the worktree: build-ready-with-fixes. No blocker.
The builder confirmed B1, B2 and B3 fixed as built; WT7 to WT9c's mutants 1 to 13 red; WT11's five red through
Surviving Mars's real setup and mover; three red in Cities: Skylines II's `test-setup.sh`; and the real probe:
a program run as the fixture's `wine/bin/wineserver` gives exit 3, and from another wrapper the rename goes
through. This fold opened the cited code again for each finding before it was written in.

| # | Finding | Lens | Folded into |
|---|---|---|---|
| N1 | Step 4 of the resolver undid S6: a marked app that failed a candidate's test was handed back if it held the game, and today's glob follows a symlink (`launch-cs2-dxmt11.sh:40-42`) | both | 3.2 (step 4 asks the tests but the marker); section 6's fixtures; WT5 (repeated on a game fixture, mutant d) |
| N2 | The "looks incomplete" line could not be reached: the old names are only in `wrappers.sh`, so a second wrapper would be made beside an old-named app with no prefix. And an old-named `CS2.app` with a prefix and no game is now used | fold, builder | 3.2 (`incomplete`); 3.4 ("Through the installer", two bullets); section 5; W1 1.3; WT5c; WT11 (two cases, mutant f) |
| N3 | With a decline or a named wrapper and a holder, the mover printed a skip and a stop and exited 3 (measured) | both | 3.4 ("The order of the tests"; the skip row); WT9 (two cases, mutant d) |
| N4 | The installer's download path leaves `wsrv -w` unwatched after 15 s (`install-core.sh:493-494`), a holder on the probe's list | fold | 3.4 (the holder question; the P5 table's new row; `--holders-skip`); W0 step 6; WD10; section 5; section 9; WT11 (mutant g) |
| N5 | WT4b's mutant is equivalent in Cities: Skylines II's setup (`setup.sh:225-226`) | fold | WT4b: the duplicates line asserted in every caller |
| N6 | No branch for an installer-made wrapper that fails a candidate's test (`make-wrapper.sh:203-204`) | fold | 3.2 (a candidate); 3.3's table (a P3 row); W0 step 3 |
| N7 | Cities: Skylines II's installer test stubs setup, so its call after setup was untested | builder | WT11 (a case with the real setup in each installer test, mutant c at each call); second table |
| N8a | "One core function runs setup" cannot be built without a new setting, and breaks `MUTANT=15` and `MUTANT=14` | builder | 3.4 (`core_after_setup` on the line after each setup line); W1 1.3 |
| N8b | The unset must be a subshell's: a command run through `env` is forbidden in the installers (`test-install.sh:180-181`) | builder | 3.4 (two places) |
| N8c | Surviving Mars's setup calls the resolver at `:88`, before its own-files check at `:123-125` | builder | 3.4 (Surviving Mars, step 1); WT17 (mutant f) |
| N8d | Cities: Skylines II's step 1 also ran for `--mac-only`, whose exit 1 the core reads as "Rosetta is missing" | builder | 3.4 (Cities: Skylines II, step 1); WT17 (mutant e) |
| N8e | WT9b's second case contradicted the state table: a marked wrapper is `state: none` | builder | 3.4 (the store candidate); WT9b |
| N9 | Three existing cases break and were not named; two of Surviving Mars's mutants as they stand | builder | section 6's second table (four rows) |
| N10 | WT9b's mutant is equivalent on a game fixture; WT7d's is red only below the stop-after test; the word "Spotlight" must stay out of the mover's lines | builder | section 6 (the fourth fixture); WT9b; 3.4 (where the test sits; the order paragraph; the symlink row's words); WT7d; WT9; second table |
| N11 | What part-way does under a name that is neither old nor the target was unstated | builder | 3.4 (states); WT7b (a case, mutant b) |
| N12 | Setup's `wrapper:` line and `--check`'s words had a live step and no test | fold | 3.4 (Surviving Mars, step 2); WT17 (the header case, mutant d) |
| minor | `boot-verify.sh` and `install-webhelper-shim.sh` were in no W1 step; exit criterion 1 asked every probe for a row; the stop's comparison is of `pwd -P` forms; WT7d's next run; P1 reads the MacBook's store wrapper; W2 step 1's count of renames; the count before "Rejected or changed"; the move never rewrites `CFBundleIdentifier`; the bundle identifier is written per wrapper by the template's launcher; a test program is a bash script | both | W1 1.4; section 7; 3.4; WT7d; W0 step 2 and W3; W2 step 1; the pass-1 paragraph above; 3.1 and 3.3; WD11; section 6 and WT8 |

Rejected or changed:

- **Two of the minor cites.** Pass 2 gave Surviving Mars's `setup.sh` exit as `:151` and the launcher's hand-over
  of `CS2_GAME_DIR` as `:227`. `grep -n` at `ea4de42`: the `exit 1` after "was not built" is at `:152` and the
  line that sets `CS2_GAME_DIR` is at `:228`, as this file had them. Left as they were. The launcher's loop in
  step 4 was one line off and is now `:40-42`.
- **N4's recommendation is taken as a recommendation.** `--holders-skip` and the P5 row are written in; P5 can
  still select the row above it alone.
- **N10's fixture** needed one thing said that neither pass said: "named by the player" is a reason for the
  game's role only, since the Windows Steam's role has no variable (3.4's skip row).
- **The bundle identifier.** Pass 2 named its name part. This file still does not.

Not verified by this fold: the new mutants (WT5 d, WT5c c, WT7b b, WT9 d, WT11 f and g, WT17 d to f) were not
run; `incomplete` and `--holders-skip` are this fold's names for what the findings asked for and were not built
by the builder.

#### Fitted check of the fold (2026-11-18) — build-ready-with-fixes stands, folded

One agent (Fable 5.2) against `c5201a2`; eight items, each confirmed in the code or in this file before it was
folded, none rejected.

1. `incomplete` widened today's stop to every old name: limited to the one path today's installers default to.
   3.2; 3.4; WT5c (mutant d); WT11 (the `CS2.app` case).
2. `--holders-skip` had no test at the mover: WT8 (two cases, mutant e).
3. "Named by the player, game role only" had no mutant: WT9 (a steam-role case, mutant e).
4. The order paragraph could not hold for the two skips that come from the probe: 3.4 (the lock before the
   probe; the lock's stop wins).
5. A named wrapper no longer equals the decline: 3.4 ("To decline"); the rework's choice 1.
6. The stop list lacked the option, and the dry run was not said to get both options: 3.4 (two places).
7. A skipped part-way wrapper is marked: section 9.
8. Section 5's stop row overlapped the installer-holder row: scoped to a running game and the lock.

Not run: the new mutants (WT5c d, WT8 e, WT9 e).

## W0 fold (2026-11-21, W0 step 8)

The session (Opus 5.5) folded P0 to P5 and James's answers of 2026-11-20 into the plan. No code had moved under
the plan's key paths since `c5201a2` (`git log c5201a2..HEAD` over them: empty), so its cites stand. Each finding
and where it went:

| # | From | Finding | Folded into |
|---|---|---|---|
| F1 | P0 | `steam`'s Top Hit is the macOS Steam whatever the wrappers are called, and neither the game's app nor `S734M.app` was among the rows for `cs2`: a pass condition of "the first row is X" cannot be met | W2 step 6 (pass: no wrapper among the rows and no completion to a wrapper's name; the rows recorded); W3; 1.2 |
| F2 | P1 | On the Studio a rename took the wrapper out of the window at once; the Top Hit went to the repo's folder, not the game's app; with the Applications filter the game's app was first | target 3; 3.3's table (row A selected, a "Measured in W0" column); W2 step 6 (the filter); section 5 (a new row); 1.2 |
| F3 | P1 | P1 ran on the Studio, so the MacBook's reads (inventory, modes, the store candidate, the "before") were never taken, and W0 step 2 wanted them before any code | W3 step 0 (new: read-only, first thing in the visit or at any earlier one; a failed candidate test sends the branch back before setup runs); exit criterion 3; 1.7; the header |
| F4 | P1 | Launch Services holds a second app with the Surviving Mars app's bundle identifier (ML4's scratch copy) | W2 step 5 (a count recorded, not a pass condition) |
| F5 | P2 | No target word, no other attribute, not in the Apps view; `.noindex` keeps an app out; `mdfind` matches `w` but the window did not show it | 3.3 (the paragraph on `w`; the table's P2 rows); WD3's row |
| F6 | P3 | An installer-made wrapper holds its name in `CFBundleName` (without `.app`) and its identifier is built from the name; its bundle folder passes 3.2's tests while `Contents` and the prefix are writable by all | 3.1 (the stored name, definite; the identifier left); 3.2 (the tests judge the bundle folder only); 3.3's P3 row (not met); WT5 (a P3-shaped case, mutant e); WT7 (`CFBundleName`, mutant b); section 10 |
| F7 | P3 | Wineskin's rewrite on Quit keeps the marker keys | 3.1 ("Considered": rejected on evidence); 1.5's "Not checked"; section 8's paragraph |
| F8 | P3 | Opened directly, a wrapper's `use start.exe` flips from 1 to 0 on Quit | section 10's WD6 line (for its issue, not this plan) |
| F9 | P4 | 7 to 9 s slower at the first start, one start; no new macOS check; no sign-in prompt | section 5's row; 3.8's notes; 1.5's "Not checked" |
| F10 | P5 | No holder at the setup step in three runs, one through the download path | 3.4 (the P5 table's first row selected; `--holders-skip` kept for a player's own Steam; the `wineserver -w` wait not built) |
| F11 | P5 | `lsof -t` on the named files listed all 16 processes of a live wrapper, `steam.exe` among them, through two files | 3.4 ("The open-files probe") |
| F12 | P5 | The server socket's place is `/private/tmp/.wine-<uid>/server-<device>-<inode>/` of the prefix | 3.4 ("What it misses": known, not added to the probe, with the reason); 1.5 |

Decided by this fold and open to the re-check: the socket's folder is not added to the probe (F12); W3 step 0
replaces "before any code" for the MacBook's reads (F3), which a failed read turns into a second Studio run of
W2's affected steps; the game's app as the Top Hit is not a target (F2).

Not done by this fold: no mutant was run; nothing was measured on the MacBook.

### Re-check of the W0 fold (2026-11-21) — build-ready-with-fixes, folded

One agent (Fable 5.2, read-only) against `d6f3afe`: F1 to F12 match section 1's records; the code cites hold
(`install-core.sh:136`, `:479-494`, `make-wrapper.sh:196-204`, `move-install.sh:48-53`); WT5 (e) and WT7 (b) can
turn red on their fixtures. It agreed with the fold's three choices, (b) with the nudge folded under S2. Six
should-fix items and eleven minor; the session opened `make-wrapper.sh:194-206` and `make-steam-shortcut.sh:103-107`
before folding M3 and S5. None rejected.

| # | Finding | Folded into |
|---|---|---|
| S1 | W2 step 6's filtered pass asked the game's app to be among the rows for `cs2`, never read so: the unmeetable kind F1 removed | W2 step 6 (pass: no wrapper; the app's place recorded) |
| S2 | No path at W3 for a MacBook store wrapper that fails 3.4's store tests: left under its old name it answers to `cs2` | W3 step 0 (the same send-back; WT9b); and the reads, with W0 step 2's hand rename, offered at the first visit |
| S3 | Branch B at W3 was under-specified: renamed wrappers are `state: none`, and B changes 3.2, 3.3, 3.4 and WT5 | W3 (B is a rework, checked before it is built, W2 again before W3) |
| S4 | Section 9's first bullet was false once W2 has run | section 9 ("Before W2") |
| S5 | Section 10 said only the Studio's clones share an identifier; every clone shares its donor's | section 10 |
| S6 | 3.1's security sentence read stronger than tests on the bundle folder alone hold | 3.1; exit criterion 7; section 10 |
| minor | M1 P1's reach (`surviving mars` only, filter with the wrapper present); M2 P2's caveat; M3 who sets the modes inside; M4 `CFBundleName`'s evidence is 1.2; M5 W0 steps 2, 3 and 6 marked as run; M6 3.3's P3 row usable on the branch; M7 the P5 table's rows 2 and 3; M8 "named files"; M9 `steam` at W3 step 0; M10 P4's bound; M11 3.1 narrowed to `CFBundleName`, what P3 found and WT7 tests | target 3; section 5; 3.1; 3.2; 3.3; 3.4; W0; W3; 1.5; WD3's row |
| gap | No live step renames an installer-made wrapper; P1's Top Hit finding has no issue | section 6 ("Live, not automatable"); exit criterion 7; section 10 |

The issues exit criterion 7 names were opened on James's word the same day, #27 to #29, and the verdict was posted
on #26.

## W2 on the Studio (2026-11-23): done; every step recorded; one finding to fold and check before W3

On James's word ("W2 on the Studio"), from the branch at `efe176b`. He confirmed before the first start that
Steam was closed everywhere else on the account. Recorded before step 2, in `<workspace>/wrapper-names-w2/`: the
three names, each wrapper's `Info.plist`, and both `--check` outputs; the outputs of every step are there too.

| Step | What ran | Result |
|---|---|---|
| 1 | `setup.sh --check` for each game | **Pass.** Cities: Skylines II's names two renames (the game's wrapper and the Windows Steam's), Surviving Mars's one, neither anything else |
| 2 | Cities: Skylines II's setup; then `boot-verify.sh`, detached | **Pass.** Setup exit 0 in 10 s: `CS2dxmt11.app` to `wrapper-949230.app`, `CS2dxmt11-pk110.app` to `wrapper-0.app`, 10 of 10 patch scripts, the game's app, 14unch3r and `S734M.app` rebuilt. Boot-verify `20261123-151732`: game up at +45 s, menu reached, graceful exit, `VERDICT: PASS`, Steam down, no crash marker |
| 3 | Surviving Mars's installer | **Pass.** Exit 0 in 5 s, steps 1 to 6 `OK`, `SurvivingMars.app` to `wrapper-3215050.app`, no `.launcher.lock` left |
| 3 | the game started from 14unch3r, first try (15:22:10) | **Failed.** "Steam did not sign in by itself." Steam's logs stop one second after its start: its connectivity test was started and never reported, and no logon was tried in the two minutes the launcher waits. The launcher stopped Steam and showed its alert; nothing was left running and no crash marker |
| 3 | the same, second try (15:27:22) | **Pass.** Window 47 s after the start (P4's "before": 26, 26, 28 s; so 19 to 21 s slower, inside the 30 s). Steam's connectivity test took 5 s and the logon came 30 s after the start, `OK` with the saved login and no prompt. Menu reached (the game's log judged PASS after it closed); closed by a window-close message; "Steam Cloud: saves uploaded."; Steam down; no lock, no crash marker |
| 4 | `S734M.app` opened | **Pass by the logs; the window was not looked at.** Steam in `wrapper-0.app` logged on `OK` with the saved login and no prompt, but 2 min after its start: its connectivity test took 99 s. Shut down with `steam.exe -shutdown`; nothing left holding the wrapper; no crash marker |
| 5 | `wrappers.sh list`; 14unch3r `--list`; `lsregister -dump` | **Pass.** Three marked wrappers, no `L1RenamePending`; two games and one Steam app, all `ready`. Launch Services: 0 path lines for each old name and 1 for each new; records with the Surviving Mars app's identifier 2, with 14unch3r's 3, with `S734M.app`'s 1 (a record, not a condition) |
| 6 | `mdimport` of each wrapper, then `mdfind` | **Index half: pass.** The old names were gone at the first look. `surviving`, `mars`, `smr`: `Surviving Mars Relaunched.app` alone. `cities`, `skylines`: `Cities Skylines II.app` alone. `cs2`: that app and `S734M.app`. `steam`, `store`, `s734m`: `S734M.app`. `launcher`, `1launcher`, `14`: `14unch3r.app`. No wrapper for any of the twelve words; `wrapper` returns the three. **Typed half, by James at the Studio the same day:** `surviving mars`: **pass.** The field completes to "surviving-mars-relaunched", the repo's folder, which is the Top Hit; then the folder "Surviving Mars Relaunched" in Pictures; then a Markdown file. No wrapper among the rows and no completion to one; no app among them either. James: the right thing "flashes up while typing but then settles on this" (as at P1, and what issue #28 is about). With the Applications filter on, the game's app is identified correctly. `steam`: **pass.** The field completes to "Steam.app", the macOS Steam, which is the Top Hit; then the two CrossOver Steam apps and their two Support Center apps. No wrapper among the five rows and no completion to one; `S734M.app` is not among them (as at P0). `cs2`: **pass.** The field shows "cs2 — Ask Siri" and completes to nothing; the rows are a music album named "Cs2" and two images of the repo (`cs2-on-macos.png`, `cs2-paradox-mods.jpg`). No wrapper among the three rows shown, where before the rename the field completed to the game's wrapper and both wrappers came first (P0); neither `Cities Skylines II.app` nor `S734M.app` is among them. With the Applications filter on, `surviving mars`: **pass.** One row, `Surviving Mars Relaunched.app`, and no wrapper (before the rename the wrapper came second). For `cs2` the window offers **no Applications filter at all** (James): it has no application to show for the word, so no wrapper, and not the game's app or `S734M.app` either, although `mdfind` returns both through their alternate names. Recorded for issue #28: the window does not offer an app by an alternate name alone |
| 3, again | a third start, from the game's app (15:42:26), to see whether only the first is slow | Steam's connectivity test 1 s, logon 27 s after the start, window after 44 s, menu reached, saves uploaded |
| 4, again | `S734M.app` a second time (15:44:54) | connectivity test 1 s, logon 19 s after the open, shut down clean |
| 7 | Surviving Mars's wrapper renamed by hand to `anything-at-all.app`; the resolver and 14unch3r's row (`ready`) found it at once | **The rule holds; the first start after the rename failed as in step 3.** From the game's app (15:46:03): Steam's connectivity test took 116 s and the launcher gave up with "Steam did not sign in by itself". From 14unch3r (15:49:06): logon after 27 s, window after 44 s, menu reached, saves uploaded. The name put back to `wrapper-3215050.app` (what `wrappers.sh name` prints); the start after that (15:50:56): connectivity test 0 s, window after 44 s, menu reached |
| 7 | the Windows Steam's wrapper renamed by hand to `some-other-name.app`; `S734M.app` opened (15:54:20) | **Pass, slowly.** `S734M.app` found the wrapper by its mark; Steam logged on with the saved login 104 s after the open (connectivity test 77 s); shut down clean; the name put back to `wrapper-0.app`. Afterwards: three marked wrappers, the window's three rows `ready`, and `mdfind` returns no app for `anything` or `some-other` |
| 8 | what names the old paths outside the repo | the memory notes were given a line with the new names; Porting Kit not looked at |

**Two things W2 found that the plan did not expect.**

1. **After a rename macOS asks again whether Wine may use the microphone, and Steam's start waits for the
   answer.** Established from the system log, five times out of five. One second after Steam starts in a
   wrapper under a path it has not run from before, `tccd` logs a prompt for the microphone
   (`AUTHREQ_PROMPTING: service=kTCCServiceMicrophone`) whose subject is the **path** of the wrapper's
   `wine64`; Steam logs nothing more until the question is answered.

   | Start | Asked | Answered | What Steam's log shows |
   |---|---|---|---|
   | Surviving Mars, first after setup's rename | 15:22:13 | not within the launcher's 120 s | no connectivity result; the launcher's "Steam did not sign in by itself" |
   | the Windows Steam, first after setup's rename | 15:31:57 | 15:33:35, allowed | connectivity test 99 s |
   | Surviving Mars as `anything-at-all.app` | 15:46:12 | 15:48:07, allowed | connectivity test 116 s; the launcher gave up |
   | the Windows Steam as `some-other-name.app` | 15:54:34 | 15:55:49, allowed | connectivity test 77 s |
   | Cities: Skylines II after setup's rename (boot-verify) | never asked | | game up at +45 s as always |

   Every later start from a path that has been answered is quick again (connectivity test 0 to 1 s), and so is
   a start after a rename back to a path answered earlier that day. So the stall is as long as a person takes
   to answer, and a launcher that waits 120 s for the sign-in fails when nobody answers in time. The answers
   above were James's, at the Studio. **Not explained:** why P4 (2026-11-18, the same hand rename) saw no
   question, and why the wrapper with the self-built engine is never asked. **Besides that**, with the
   question out of the way, a start of Surviving Mars is about 17 s slower than before the rename, every
   time: logon 27 to 30 s after the start (8 to 12 s before), window after 44 to 47 s (26 to 28 s before);
   inside W0's 30 s, and not explained.

   **What it changes in this plan, to be folded and checked before W3:** section 5's row "a first start a few
   seconds slower" and the notes of `v0.3.0` are wrong for these wrappers: the first start after the update
   shows a question from macOS about the microphone and waits for it. A player who does not see it (it can be
   behind the progress window) gets "Steam did not sign in by itself". The choices are James's: say it in
   the notes and in the launcher's step line; let the launcher wait for as long as the question is up; or keep
   Steam from asking for the microphone at all. Section 9's rollback is touched too: a rename back to an old
   name is a path answered before, so it does not ask again.
2. **Somebody at the Studio started Surviving Mars during step 2.** At 15:17:36, four seconds after
   boot-verify began, Finder opened 14unch3r, and 2.5 s later 14unch3r started the game's app (read in the
   system log: Finder's action, the launch of 14unch3r, its `open`, the launch of the game's app). No
   screen-sharing or remote login was logged, and it was not a command of this session. The game ran from the
   old-named wrapper for 67 s and was closed; its Steam had been pushed offline by step 2's ("Session
   Replaced" at 15:18:00), so that session's saves were not uploaded then (the second try of step 3 uploaded
   afterwards). Step 2's verdict stands: the two Steams were in different wrappers and boot-verify judges the
   game's own log. James, asked the same day: "Yes, that was us." So it was a person at the Studio, and W2's later starts wait until he says the Studio is free.

**State when W2 stopped:** the three wrappers under the names setup gave them, each marked, each started at least once since its rename with the microphone question answered; nothing of Wine or Steam running; no lock and no crash marker in any of them. The outputs of every start are in `<workspace>/wrapper-names-w2/`, with the two small scripts that followed them.

**Also seen:** the macOS Steam's helper `ipcserver` was running throughout (not a client, left alone); the
Surviving Mars wrapper carries the one-byte `ntdll.dll` of issue #30 since that morning, which a rename does
not touch.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-18 | 1 (full) | architecture · correctness · rollout + security · test-plan · platform-facts · builder-simulation | 6 agents; the builder built W1 in a scratch worktree and ran the tests and mutants; B1 and B3 re-read in the code by the session; reworked by one agent the same day, audited two-sided; re-checked as pass 2 | Fable 5.2 (five lenses), Opus 5.5 (builder-simulation) | `d50cf33` | needs-rework |
| 2026-11-18 | 2 (fitted re-check of the rework) | fold verification · builder re-check | 2 agents; the builder built the installer's path, the mover's states and the least of the resolver in a scratch worktree and ran the tests and mutants; findings folded by one agent the same day, each cited line opened again, audited two-sided | Fable 5.2 (fold verification), Opus 5.5 (builder) | `ea4de42` | build-ready-with-fixes (folded) |
| 2026-11-18 | fitted check of the pass-2 fold | fold verification | 1 agent; eight items folded the same day, audited two-sided | Fable 5.2 | `c5201a2` | build-ready-with-fixes, folded |
| 2026-11-21 | 3 (W0 fold: P0 to P5 and WD1 to WD11 folded, then re-checked) | fold verification against section 1 and the code | the fold by the session; 1 read-only agent re-checked it; six should-fix and eleven minor folded the same day, audited two-sided | Opus 5.5 (fold), Fable 5.2 (re-check) | `d6f3afe` (code unchanged since `c5201a2`) | build-ready-with-fixes, folded |

Key paths: `common/paths.sh` · `common/install-core.sh` · `common/make-wrapper.sh` · `common/mac-inventory.sh` ·
`common/launcher-window.swift` · `common/check-release-move.sh` · `common/check-deploy.sh` · `common/games.tsv` ·
`common/test-launcher-parity.sh` · `cities-skylines-2/launchers/launch-cs2-dxmt11.sh` ·
`cities-skylines-2/repatch.sh` · `cities-skylines-2/scripts/` `setup.sh`, `install.sh`, `move-install.sh`,
`make-shortcut.sh`, `make-steam-shortcut.sh`, `boot-verify.sh`, `install-webhelper-shim.sh`,
`patch-modconflict-badge.py`, `cell-fingerprint.sh`, `test-setup.sh`, `test-install.sh`, `test-move-install.sh`
and the 18 other research scripts of 1.4 · `surviving-mars-relaunched/launch-relaunched.sh`, `make-app.sh`,
`scripts/setup.sh`, `scripts/install.sh`, `scripts/test-install.sh`, `scripts/test-setup.sh`, `tools/make-engine.sh`,
`tools/split-wrapper.sh` · `CHANGELOG.md` · both `CLAUDE.md` · `docs/plans/local-files-layout.md`,
`docs/plans/launcher-window.md`.
