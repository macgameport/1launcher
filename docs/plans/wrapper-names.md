# Wrapper names — find a wrapper by a marker, then give it a name nobody types

**Status: Drafted 2026-11-18 — not yet checked.** No code is written from this file until it has been through
`check it` and the probes of W0 have run. Tracking: #26 (refs #26; one checkbox per phase there, as #22 has them).

The fault: Spotlight offers the Wine wrappers beside, and on one Mac above, the game apps. A wrapper opened
directly starts its own Steam outside the launcher and its lock. The wrappers cannot simply be renamed, because
their file names are spelled as addresses across the code and on players' Macs.

This plan does three things, in this order: the scripts find a wrapper by a marker in its `Info.plist`; the
wrappers then take names that match no word a player types; a move step renames the wrappers that exist.

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
| `CS2dxmt11.app` | wrapper (the game's) | Steambuild Metal | `com.S734M451538131.wineskin` | none | none | none |
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
  wrappers. Which app Spotlight's window puts first was not measured here.
- **`1L` is not a free prefix.** It returns `14unch3r.app`, through its alternate name "1launcher". A wrapper
  named `1L-949230.app` would very likely join that list for the two keys `1l` on the way to "1launcher". The
  word split of such a name was not measured (probe P2). And `-store` in `1L-949230-store.app` would likely
  answer to `store`, a word in `S734M.app`'s alternate name "Steam Store".
- **The ranking fault is not reproducible on the Studio.** No wrapper here has a last-used date. On the MacBook
  the wrapper had been opened from Spotlight once (#26). `mdfind` shows what is in the index, not the order of
  Spotlight's window.
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
| `make-steam-shortcut.sh` | `--wrapper`, else `CS2dxmt11-pk110.app`; the donor `CS2dxmt11.app`; the clone at `:105`; **the path is written into `S734M.app`'s `launch` file** at `:143` | `:40-41` |
| the folder mover | its own copy of setup's list | `scripts/move-install.sh:43` |
| `mac-inventory.sh` | six names it "knows from the Studio" | `common/mac-inventory.sh:138`, `:146`, `:169` |
| SM launcher | `SM_WRAPPER`, else the spelled path | `surviving-mars-relaunched/launch-relaunched.sh:69` |
| SM setup, installer, app builder | the same default, spelled again | `scripts/setup.sh:88`, `scripts/install.sh:52`, `make-app.sh:25` |
| SM engine and split tools | the spelled paths | `tools/make-engine.sh:83`, `tools/split-wrapper.sh:23-25` |
| the shared installer | takes the path from the game's `game_wrapper`, exports the game's variable | `common/install-core.sh:145-154`, `:350-352` |
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
- **10 tests of those** (the golden file among them).
- **20 research:** 19 scripts and `test-licence-wait-probe.sh`. 13 of the 19 read `CS2_WRAPPER` and fall back to
  the spelled path; 6 spell it with no override (`capture-freeze.sh`, `livedrag-probe.sh`, `run-minrepro.sh`,
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
| The game apps' `launch` files | hold the launcher's path, not the wrapper's | `make-shortcut.sh` (the `SCRIPT=` line), `make-app.sh:65` |
| The launch lock | `<prefix>/.launcher.lock`, inside the wrapper: it moves with it | `launch-relaunched.sh:166` |
| The Dock | one project item, `Cities Skylines II.app`; no wrapper | `defaults read com.apple.dock persistent-apps` |
| LaunchServices | each wrapper is registered once, by its path | `lsregister -dump` |
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
  bundle identifier, which may matter. Not readable.
- Whether macOS checks a renamed wrapper again at its first start (the Surviving Mars wrapper once took about
  four minutes), and whether a privacy grant follows the rename.
- Whether Wine Mono's four stale lines matter. The clone precedent says a renamed wrapper runs; boot-verify is the gate.
- `~/Library/LaunchAgents` and other folders of `~/Library` outside a `1launcher` folder.
- Whether the template's own launcher keeps keys it does not know when it rewrites `Info.plist`
  (`common/make-wrapper.sh:140`). Our launchers never run it after the wrapper is made.
- The `Info.plist` of a wrapper made by the published installer (`common/make-wrapper.sh`). None exists on the Studio.

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
| The MacBook | has the store wrapper (`launcher-window.md`, step 8); its Surviving Mars wrapper "was made the old way" (`surviving-mars-install.md`, ML5); its folders moved on 2026-11-17 (L3); its Surviving Mars wrapper was opened from Spotlight once and is Spotlight's top hit for "surviving mars" (#26) | records only, not measured |
| A player's Mac | one wrapper per installed game, made by `common/make-wrapper.sh` at `~/Applications/CS2dxmt11.app` or `~/Applications/SurvivingMars.app`. No store wrapper unless they ran `make-steam-shortcut.sh` by hand: neither setup runs it | the code |

## 2. Target

1. No code file finds a wrapper by a spelled name, except one list of old names kept for Macs not moved yet.
2. A wrapper's file name is a label. Renaming it by hand, to anything, breaks no start of a game.
3. No wrapper in `~/Applications` is returned by Spotlight for a word a player types: `surviving`, `mars`,
   `smr`, `cities`, `skylines`, `cs2`, `steam`, `store`, `s734m`, `launcher`, `1launcher`, `14`.
4. Existing wrappers are renamed by setup, by a rename only, with nothing copied; setup says what it renamed.
5. 14unch3r lists the same apps as before.

## 3. Design

**3.1 The marker.** Two keys in the wrapper's `Contents/Info.plist`, in the vocabulary the apps already use:

| Key | Type | Value |
|---|---|---|
| `L1Role` | string | `game-wrapper` or `steam-wrapper` |
| `L1SteamAppID` | integer | the game's Steam app ID; on a `game-wrapper` only |

- The identity of a game's wrapper is (role, app ID). The app ID is Valve's, opaque, and already the key by which
  everything published names a game (root `CLAUDE.md`, "Published addresses"). The role is a comparison string,
  the looser family of the keys-and-labels rule.
- The Windows Steam's wrapper has a role and no app ID: it serves every game on the account, and tying it to
  949230, as `1L-949230-store` would, is the kind of readable coupling the rule warns about.
- 14unch3r lists an app only when `L1Role` is exactly `game` or `steam` (`launcher-window.swift:126-127`), so no
  build of it, old or new, lists a marked wrapper. WT6 holds that.
- Written with `plutil -replace`, checked with `plutil -lint`, the file's mode put back to what it was
  (`test-make-wrapper.sh:422` holds it at 666). `plutil -extract … raw` reads it, as
  `make-steam-shortcut.sh:65` already does.
- *Considered:* a marker file in the prefix beside `.launcher.lock`. It would survive anything that rewrites
  `Info.plist`. Rejected for now: `Info.plist` is where the three app builders and the window already look, and
  nothing of ours rewrites it. Probe P3 can reverse this.

**3.2 One resolver.** A new file, `common/wrappers.sh`, in the form of `common/paths.sh`: sourced, it defines
functions and exports nothing; run, it prints.

```
bash common/wrappers.sh find game 949230     # the path of that game's wrapper
bash common/wrappers.sh find steam           # the Windows Steam's wrapper
bash common/wrappers.sh list                 # every marked wrapper: role, app ID, path with ~
```

`find` answers in this order:

1. The game's variable (`CS2_WRAPPER`, `SM_WRAPPER`), when set: as today, and it is how a move is declined.
2. The marker: the direct children of `~/Applications` that are real folders named `*.app` and carry the role
   and app ID asked for. One: that is the answer.
3. No marked wrapper: the old names, in today's order, for a Mac not moved yet. `CS2dxmt11.app`, `CS2.app`,
   `/Applications/CS2dxmt11.app` for 949230; `SurvivingMars.app` for 3215050; `CS2dxmt11-pk110.app` for the
   Windows Steam. This list is the only place in the code that spells them.
4. Still none, for a game: the app in `~/Applications` that holds the game's program, which the CS2 launcher
   does today (`:39-41`). Surviving Mars gains the same.

Exit 0 with one path; 1 with none; 2 when two wrappers carry the same marker, each printed with `~`. A caller
that gets 2 stops and says to move one to the Trash or name one in the game's variable. Two can happen: a
wrapper cloned by hand carries its donor's marker.

Deployed files cannot read the checkout, so setup copies `wrappers.sh` beside each launcher: into the runtime
folder for Cities: Skylines II, into the state folder for Surviving Mars. A launcher, `repatch.sh` and the badge
patch look for it beside themselves, then in the checkout's `common/`. The installers' own-files lists
(`cities-skylines-2/scripts/install.sh:115`, `surviving-mars-relaunched/scripts/setup.sh:123`) gain it.
*Considered:* the function inlined in both launchers and held equal by `common/test-launcher-parity.sh`, as the
lock code is. Rejected: there are four deployed readers, one of them Python.

**3.3 Names and place.** The recommended names (WD3): `wrapper-949230.app`, `wrapper-3215050.app`, and
`wrapper-0.app` for the Windows Steam's (0: no game). `common/make-wrapper.sh:58-59` accepts them. The rule that
builds a name is one function in `wrappers.sh`. Because of 3.1 the name carries no load, so a later change of
mind about it is a rename and nothing else.

The place stays `~/Applications` (WD2), unless probe P2 selects otherwise:

| P2 outcome | Branch |
|---|---|
| A scratch app with the new name answers to none of the target's words, and is not shown where a player browses apps | **A: rename in place.** The design above |
| It answers to no word, but macOS lists it wherever apps are browsed (the Apps view, Launchpad's successor) | A, and WD6 (make a directly opened wrapper harmless) moves from "later" to "next" |
| It still answers to a word through the bundle name or another attribute | A, and the move also sets `CFBundleName` to the file name |
| A folder named `*.noindex` in `~/Applications` keeps an app out of Spotlight | **B is available:** `~/Applications/1launcher.noindex/`, added to step 2 of the resolver. Chosen only if A's first row fails |

*Rejected:* a symlink left at the old name (it puts the typed name back); `chflags hidden` (D6); moving the
wrappers under `~/Library` (the local-files plan decided "`~/Applications` is the standard place", and its data
root has a space, which Wine trees are kept off).

**3.4 The move is a script.** `common/move-wrappers.sh [--dry-run] [--held-by <pid>] <role> [<app ID>]`, with
the output and exit contract of `cities-skylines-2/scripts/move-install.sh`: line 1 is `state: none`,
`state: old` or `state: part-way`; then `stop:` or `skip:` per reason; `would move:`, `moved:` or `not moved:`
per rename; every path with `~`; exit 0, 1 (skipped) or 3 (stop: setup must not go on).

- **What it moves.** A wrapper found under one of the old names of 3.2 step 3. It writes the marker, then
  renames. `part-way` is a marked wrapper still under an old name: the rename is finished. A marked wrapper under
  any other name is left alone, whatever the name: that is someone's own rename, and target 2 says it may be.
- **Which old-named app is the wrapper.** For a game: the one the resolver's step 3 returns, and it must have
  `Contents/SharedSupport/prefix` and `wine/bin/wine64`. For the Windows Steam: the wrapper that a generated
  `S734M.app` names in its `L1Prefix`, else `CS2dxmt11-pk110.app`.
- **Stop** (nothing moved, setup stops): the wrapper's launch lock is held by a live process other than
  `--held-by`; or any process has a file open under the wrapper, read from `lsof` output by path as
  `move-install.sh:55-58` reads working directories, never from a command line. That covers the game, Steam, its
  web helpers and the wineserver of that wrapper, and nothing of another wrapper.
- **Skip** (nothing moved, setup goes on with the old name): the game's variable is set; the target name
  exists; the wrapper or `~/Applications` is a symlink or not the user's own; `Info.plist` does not parse or
  cannot be written; two candidates.
- **When.** Each game's setup runs it for its own wrapper before it first asks for the wrapper
  (`cities-skylines-2/scripts/setup.sh:114`, after the folder move; `surviving-mars-relaunched/scripts/setup.sh:88`).
  Cities: Skylines II's setup also runs it for the Windows Steam's wrapper when one exists. `--check` reports
  what a run would do.
- **After it, in the same setup run.** The game's app is rebuilt, as every run does, and its `L1Prefix` now
  comes from the resolver. 14unch3r is rebuilt, as every run does. `S734M.app` is rebuilt when it exists and is
  the builder's own bundle: new, because no setup runs `make-steam-shortcut.sh` today and its `launch` file holds
  the wrapper's path (WD5 asks whether that file should resolve at run time instead).

**3.5 Makers and cloners.**

- The installers' default for a wrapper they make is the new name (`game_wrapper` in each game's `install.sh`).
  `common/install-core.sh` marks the wrapper right after `make-wrapper.sh` succeeds (`:352`), which is after
  the template's own launcher has written `Info.plist`.
- `make-steam-shortcut.sh` marks its clone `steam-wrapper` straight after the copy (`:105`), replacing the
  donor's marker, and finds donor and store through the resolver.
- `tools/split-wrapper.sh` marks its clone `game-wrapper` 3215050 and takes its default name from the rule.
- `common/mac-inventory.sh` reports marked wrappers by role and app ID, and still names the old ones.

**3.6 Research scripts.** Recommended (WD4): all 19 take the resolver, in a commit of their own. The 13 that
read `CS2_WRAPPER` change one default; the 6 that spell the path gain the same line, and `capture-freeze.sh:54`
takes the name from the path found. Reason: `cell-fingerprint.sh` gates every render cell and `boot-verify.sh`
is the boot proof, so the standing instruments must follow; and a census test (WT12) is only simple if no
script is excepted. Cost: 19 one-line edits that only `bash -n` and the census test check, since the experiments
are not re-run. Dated records, the ledger's old rows and `config.json` files already written keep the names
they were written with, as O6 of the local-files plan decided for paths.

**3.7 Documents.** Living documents name a wrapper by its role ("the game's wrapper", "the Windows Steam's
wrapper") and give `bash common/wrappers.sh list` as the way to print the paths, so they are true before and
after a Mac's wrappers move. Both `CLAUDE.md` files, the two games' `README.md` and `INSTALL.md`, `GOTCHAS.md`'s
standing rules and `docs/agent-brief.md`. The root `CLAUDE.md`'s `common/` row gains the two new files and their
tests. Plans and dated findings stay as written. One mapping sentence, as the game's `CLAUDE.md` has for
`~/cs2-patch`, says which old name is which wrapper.

**3.8 Releases.** The change asks someone with an install to notice something, so the second number rises:
**`v0.3.0`**. Built on a branch, `wrapper-names`, pushed and merged into nothing until the Studio's live steps
pass, so that `main` can still take a game-update fix. `common/check-release-move.sh` gains a fourth question:
a commit that holds `common/wrappers.sh` moves to `release` only when `v0.3.0` exists and is it or an ancestor.

How each install reaches the new names:

| Install made by | Path |
|---|---|
| The pasted line, while `release` is at `v0.1.0` | nothing changes until `release` moves. If it moves straight to `v0.3.0`, the next run of the installer does both moves in one setup run: the folder, then the wrapper (WT11) |
| The pasted line, after `release` has moved to `v0.2.0` | the next run of the installer after `release` moves to `v0.3.0` renames the wrapper |
| A clone on `main` | the next `git pull` and setup after the merge |
| Someone holding `v0.1.0` or `v0.2.0` on a Mac already moved | Cities: Skylines II still starts: that launcher finds the renamed wrapper by the game inside it (1.6). Its setup says there is no wrapper, its installer would make a second one, and the Surviving Mars launcher of those versions finds nothing. The way through is the game's variable naming the new path; the notes say so |

The section for `CHANGELOG.md`, to be written at the build from what was built:

- Setup renames the game's Wine wrapper in `~/Applications`: the old and new names, per game.
- Why: Spotlight offered the wrapper beside the game's app, and a wrapper opened directly starts Steam outside
  the launcher.
- It is a rename with nothing copied; setup says what it renamed; it stops while the game, Steam or an install
  is using the wrapper, and skips when it cannot be done safely.
- What stops working until pointed at the new name: anything of the player's own that names the old path (a
  Dock item made from the wrapper, an alias, a saved command, a Porting Kit entry).
- To decline: the game's variable with the old path, in a clone and with the pasted line, as `v0.2.0`'s section
  shows for the folder.
- Going back to an earlier version on a moved Mac: the row above.

## 4. Phases

Each phase ends green before the next starts. Live steps, and anything public, run only on James's word.

### W0 — decisions and probes (no code)

1. James answers WD1 to WD8 (section 8).
2. **P1, read-only, the MacBook.** `common/mac-inventory.sh`, then the `mdls` and `mdfind` lines of 1.2 there.
   Records which wrappers exist, their last-used dates, and what `mdfind` returns for `surviving mars` and `cs2`.
3. **P2, writes a scratch app, the Studio.** A folder `~/Applications/wrapper-999999.app` holding only an
   `Info.plist` with the three wrappers' `CFBundleName`, version and copyright strings and a `launch` file that
   exits. `mdimport` it. Then: `mdfind` for every word of target 3 and for `w`, `wr`, `wrapper`, `999999`;
   the same with the scratch app named `1L-999999.app` (the issue's form); the same inside
   `~/Applications/1launcher.noindex/`. James types the words into Spotlight and looks at the Apps view. Both
   scratch items go to the Trash afterwards. The outcome selects a row of 3.3's table and settles WD3.
4. **P3, read-only where possible.** On a wrapper made by `common/make-wrapper.sh` (a scratch one, made as the
   installer plan's live steps made them, then put in the Trash): its `Info.plist` names and what `mdls` shows.
   If James agrees to open that scratch wrapper once directly: whether the template's launcher keeps `L1Role`.
   If it drops the key, 3.1's marker moves to a file in the prefix.
5. The plan is checked. The probes' results are folded in first, so the check reads the measured design.

### W1 — the repo (branch `wrapper-names`)

1.1 `common/wrappers.sh` and `common/test-wrappers.sh` (WT1 to WT5, WT12).
1.2 `common/move-wrappers.sh` and `common/test-move-wrappers.sh` (WT7 to WT9).
1.3 The deployed readers: both launchers, `repatch.sh`, the badge patch; both setups copy `wrappers.sh` and run
    the mover; the three app builders; `make-steam-shortcut.sh`'s clone; `split-wrapper.sh`; `make-engine.sh`;
    both installers and `install-core.sh`'s marking; `move-install.sh:43`; `mac-inventory.sh`. Their tests and
    the golden file.
1.4 14unch3r: no code change; WT6 added to `common/test-launcher-window.sh`.
1.5 The research scripts (3.6), a commit of their own.
1.6 `common/check-release-move.sh`'s fourth question and its test (WT13).
1.7 Documents (3.7), and this plan's as-built header.
1.8 Every test file exits 0 on the branch; every mutant of section 6 applied to real source and seen red.

### W2 — the Studio

James is told first; every Steam of the account is closed with `steam.exe -shutdown`, never `kill -9`.

1. `bash scripts/setup.sh --check` for each game: it names the three renames and nothing else.
2. Cities: Skylines II's setup. It renames the game's wrapper and the Windows Steam's, and rebuilds the game's
   app, `S734M.app` and 14unch3r. Then `scripts/boot-verify.sh`, detached with a log: `VERDICT: PASS`.
3. Surviving Mars's setup. It renames that wrapper. The game is started from 14unch3r and reaches its menu; the
   time from start to window is noted against the last start before the rename.
4. `S734M.app` opens the store.
5. `bash common/wrappers.sh list` prints three marked wrappers; `--list` of 14unch3r prints two games and one
   Steam app, all `ready`; `lsregister -dump` holds no old wrapper path, or the stale ones are recorded.
6. `mdfind` for every word of target 3: no wrapper. James types `surviving mars`, `cs2` and `steam` into
   Spotlight: the top hit is the game's app, the game's app and `S734M.app`.
7. The acceptance test of the keys-and-labels rule, by hand: one wrapper renamed to an arbitrary name, the game
   started from its app, then the name put back.
8. What names the old paths outside the repo: the 9 memory files; anything James finds in Porting Kit.
9. Merge the branch into `main`; `v0.3.0` cut on it, by the commands of the root `CLAUDE.md` (WD7).

### W3 — the MacBook

A visit of its own, after W2. P1's record is the starting point. Steps 1 to 7 of W2 there. Step 6 is the one
that matters most: it is the Mac where the fault was seen, and the only one with a wrapper Spotlight has learned.

### W4 — `release`

On James's word, on the commit he names: the test files pass, `common/check-release-move.sh` passes, then
`git push origin <commit>:release`; the root `CLAUDE.md`'s "Published since" sentence records it. Then the pasted
line, run on the Studio, reports nothing to move. WD8 is the order of this against ON1 of the local-files plan.

## 5. Who notices what

| Audience | Effect | Mitigation |
|---|---|---|
| Players who installed with the pasted line | nothing until `release` moves. Then, at their next run of the installer, the wrapper in `~/Applications` has a new name and the game's app works as before | setup prints the rename; `v0.3.0`'s notes |
| Someone who starts the game by opening the wrapper | that habit is the fault. The wrapper is no longer found under its old name; the game's app and 14unch3r are | the notes name the game's app |
| Someone with their own Dock item, alias or saved command naming a wrapper | it stops working until pointed at the new name | the notes; setup's line gives both names |
| People with a clone | the same, from the merge, at their next pull and setup | `--check` says what a run would do |
| Anyone holding `v0.1.0` or `v0.2.0` on a moved Mac | 3.8's last row | the notes; the game's variable |
| New installs | the wrapper is made under the new name and marked at birth | WT10 |
| Someone playing one game while the other game's setup runs | nothing: the mover looks only at the wrapper it was told about | WT8 |
| Porting Kit, if it lists the wrappers | its entry would name a path that is gone. Not checked (1.5) | W2 step 8 |
| Claude sessions | memory and both `CLAUDE.md` files name the old paths | 3.7; W2 step 8 |

## 6. Test plan

A mutant is a named change to real source that must turn the test red; each is applied and seen red at the
build, then restored. Tests run in a scratch home and never touch the real `~/Applications`.

| # | Test | Passes when | Mutant |
|---|---|---|---|
| WT1 | `find` by marker | with a wrapper of an arbitrary name marked `game-wrapper` 949230 among unmarked apps, `find game 949230` prints it, exit 0 | the resolver's step 2 removed: it falls to the old names and finds none |
| WT2 | the game's variable wins | with `CS2_WRAPPER` set and a marked wrapper present, the variable's path is printed | step 1 moved after step 2 |
| WT3 | old names, only while nothing is marked | an unmarked `CS2dxmt11.app` is found; with a marked wrapper beside it, the marked one is | the "no marked wrapper" condition dropped from step 3 |
| WT4 | two markers | two wrappers marked alike: exit 2, both paths printed with `~`, nothing chosen | the count check replaced by "take the first" |
| WT5 | what is not a wrapper | a symlink named `*.app`, an app in a subfolder, an `Info.plist` that does not parse, and `L1Role` `game` are all passed over | the symlink test removed |
| WT6 | 14unch3r does not list wrappers | `launcher-window --list`, with marked wrappers of both roles in the folder, prints the game apps and the Steam app only | the guard at `launcher-window.swift:127` widened to accept any role that starts `game` or `steam` |
| WT7 | the move | an old-named wrapper is marked, renamed, and the output is `state: old` and one `moved:` line; a second run is `state: none`; the `Info.plist` mode is unchanged and the file lints | the marker written after the rename, with the run stopped between the two: the wrapper is then found by no step |
| WT8 | the stops | a live holder of the launch lock, and a process with a file open under the wrapper, each give exit 3 and no rename; a process with a file open under another wrapper does not | the open-files probe pointed at `~/Applications` instead of the wrapper |
| WT9 | the skips, and a hand rename | the variable set, the target name taken, a symlinked wrapper: exit 1, nothing renamed. A marked wrapper under a name of the tester's own is `state: none` and keeps its name | the "old names only" condition dropped: the mover renames the hand-named wrapper |
| WT10 | a new install | the installer, with fixtures, makes the wrapper under the new name and it carries the marker; the golden file shows the new name | the marking line removed from `install-core.sh` |
| WT11 | both moves in one run | a scratch home in the `v0.1.0` layout (`~/cs2-patch`, `CS2dxmt11.app`): one run of setup moves the folder, renames the wrapper, and the app's `launch` file and `L1Prefix` name the new places | the mover called before the folder move |
| WT12 | the census | `git grep -l` for the old wrapper names in code files equals a list kept in the test: `common/wrappers.sh`, `common/mac-inventory.sh`, the fixtures of named tests, the one dated record | an old name put back into `repatch.sh` |
| WT13 | the release gate | a commit holding `common/wrappers.sh` fails without `v0.3.0`, passes with it as an ancestor | the fourth question's tag changed to `v0.2.0` |
| WT14 | the store's app | after a move, a rebuilt `S734M.app`'s `launch` file names the renamed wrapper, and a foreign `S734M.app` is not touched | the rebuild made unconditional |
| WT15 | deployed copies | a launcher in a scratch runtime folder with `wrappers.sh` beside it, and no checkout, finds a marked wrapper; with neither, it stops with one plain line | setup's copy of `wrappers.sh` removed |
| WT16 | clones | `make-steam-shortcut.sh`'s clone of a marked game wrapper carries `steam-wrapper` and no app ID | the re-marking after `:105` removed: `find game 949230` then exits 2 |

Live, not automatable: W2 steps 2 to 7 and W3. A green suite does not show what Spotlight's window puts first.

## 7. Exit criteria

1. WT1 to WT16 pass on the branch, every mutant seen red, every other test file still exits 0.
2. W2 and W3 pass on both Macs, with the boot-verify verdict and the Spotlight results recorded in this file.
3. `git grep` finds the old wrapper names in no code file outside WT12's list.
4. `v0.3.0` exists with its page, and the root `CLAUDE.md` records where `release` stands.
5. #26's checkboxes are ticked; anything found and not fixed has an issue of its own.

## 8. Decisions for James

| # | Question | Recommendation |
|---|---|---|
| WD1 | The marker: `L1Role` `game-wrapper` / `steam-wrapper` with `L1SteamAppID`, in `Info.plist` | Yes, as 3.1. It reuses the keys three builders and the window already know, and no build of 14unch3r lists it. P3 can move it to a file in the prefix |
| WD2 | The place: rename in `~/Applications`, or also move into a folder Spotlight skips | Rename in place. The measurements say the file name is the only thing a player's word matches. P2 decides whether a `.noindex` folder is needed; the resolver makes either cheap |
| WD3 | The names. The issue's `1L-…` shares a prefix with "1launcher" (`mdfind 1L` returns `14unch3r.app`), and `-store` is a word of `S734M.app`'s alternate names | `wrapper-949230.app`, `wrapper-3215050.app`, `wrapper-0.app`, confirmed by P2. Since the name is only a label after this plan, a wrong choice costs one rename |
| WD4 | How far into the research scripts | All 19, in a commit of their own (3.6). The other choice: only the standing instruments, with the rest on WT12's list and broken on a moved Mac until someone needs them |
| WD5 | Should `S734M.app`'s `launch` file find the wrapper at run time, by carrying a copy of `wrappers.sh`, instead of holding its path | Yes. It is the one file that a hand rename would break, and target 2 says a hand rename breaks nothing. 14unch3r's use of `L1Prefix` stays as it is: a stale one only costs the "running" state until the next setup |
| WD6 | A renamed wrapper can still be double-clicked in Finder. Should a directly opened wrapper be made harmless (its `CFBundleExecutable` replaced by a file that opens the game's app) | Not in this plan: an issue of its own. It changes Porting Kit's bundle further and needs its own probe. It becomes the next thing if P2 shows the wrappers where apps are browsed |
| WD7 | Who merges and cuts `v0.3.0` | As O10 and ON1 had it for `v0.2.0`: the session merges and cuts it once W2's steps 1 to 8 are green; `release` is a separate act on his word |
| WD8 | The order against ON1 (`release` to `v0.2.0`) | Independent. ON1 stays his word and does not wait for this plan, which has probes and a check ahead of it. If `release` is still at `v0.1.0` when `v0.3.0` exists, it can go straight there: WT11 covers both moves in one run |

## 9. Rollback

- **Before the merge:** the branch is dropped. Nothing on any Mac changed except what the probes made, which
  went to the Trash.
- **A Mac that was moved:** rename each wrapper back by hand with the game and Steam closed, and run setup with
  the game's variable naming the old path; or leave the marker in place and run setup from `main`, which finds
  the wrapper by its marker under either name. The marker is harmless to every earlier version.
- **After `release` has moved:** `release` only moves forward. A fault gets a successor version; meanwhile the
  decline line of the notes keeps an install on its old name.
- **Recorded before W2 step 2 on each Mac:** the three wrapper names and the output of `--check`.

## 10. Not in this plan

- **Making a directly opened wrapper harmless** (WD6).
- **A guard in the launchers against a second game or a second Steam.** `docs/plans/launcher-window.md` already
  lists it as not built. Since the split, no lock serialises the Windows Steam against a game's wrapper.
- **The wrappers' shared bundle identifier** (`com.S734M451538131.wineskin`). Three apps with one identifier may
  confuse LaunchServices and Spotlight's ranking; changing it touches what the template's tools key on.
- **Moving the wrappers out of `~/Applications`**, unless P2 selects branch B.
- **14unch3r resolving a prefix by marker** when `L1Prefix` is stale.
- **Renaming `S734M.app`, the game apps or 14unch3r.** They are the things meant to be clicked.
- **Porting Kit's own records.** Not readable under this project's rule; James looks, at W2 step 8.
- **Spotlight's Search Privacy list** as a fix. It is a per-Mac system setting the owner changes by hand; #26
  names it as the stopgap until this plan is built.
- **Re-running the experiments** whose scripts 3.6 edits.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|

Key paths: `common/paths.sh` · `common/install-core.sh` · `common/make-wrapper.sh` · `common/mac-inventory.sh` ·
`common/launcher-window.swift` · `common/check-release-move.sh` · `common/games.tsv` ·
`cities-skylines-2/launchers/launch-cs2-dxmt11.sh` · `cities-skylines-2/repatch.sh` ·
`cities-skylines-2/scripts/` `setup.sh`, `install.sh`, `move-install.sh`, `make-shortcut.sh`,
`make-steam-shortcut.sh`, `boot-verify.sh`, `install-webhelper-shim.sh`, `patch-modconflict-badge.py`,
`cell-fingerprint.sh` and the 18 other research scripts of 1.4 · `surviving-mars-relaunched/launch-relaunched.sh`,
`make-app.sh`, `scripts/setup.sh`, `scripts/install.sh`, `tools/make-engine.sh`, `tools/split-wrapper.sh` ·
`CHANGELOG.md` · both `CLAUDE.md` · `docs/plans/local-files-layout.md`, `docs/plans/launcher-window.md`.
