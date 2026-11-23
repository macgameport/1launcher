# A built-in update: 14unch3r says when a new version is out, and one click runs the installer again

**Status: not yet checked. Run `check it` before any build.** Written 2026-11-23 on the branch
`built-in-update`, cut from `wrapper-names` at `efe176b`; every `file:line` below was read at that commit.
Tracking: no issue yet (opening one is a public post, on James's word).

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
  whether the game is there.
- The root `install.sh` fetches `https://github.com/macgameport/1launcher/archive/<ref>.tar.gz` (`:95-97`),
  reads the commit from the archive's header (`:106`), prints it (`:121`), exports `L1_FETCHED_REF` (`:122`)
  and runs the game's installer (`:123`). The ref defaults to `release`. A `git archive` of the tree at
  `efe176b` is 16.5 MB gzipped.
- The installer app (`common/make-installer-app.sh:5-6`, and its program further down) writes a `.command`
  file into a temporary folder and opens it in Terminal, where it fetches the root `install.sh` and runs it:
  "opening it again is the update". No installer app has been released.

### 1.2 What an installed Mac knows about itself

Nothing. The commit is printed and the temporary folder removed (`install.sh:93`, `:121`). No setup writes a
version, a ref or a commit anywhere: `git grep` for a version record in `common/`, both `scripts/` folders
and `install.sh` finds only `CFBundleVersion` constants (`common/make-launcher-app.sh:113`,
`common/make-installer-app.sh:134`). `L1_FETCHED_REF` is read by Cities: Skylines II's setup for its words
only (`cities-skylines-2/scripts/setup.sh:99`, `:139`, `:225`, `:432`, `:458`).

### 1.3 The window

- 14unch3r lists the apps in `~/Applications` whose `Info.plist` carries `L1Role`
  (`common/launcher-window.swift:1-6`), and after a start it quits.
- It already shows a ported game that is not set up, as an offer: a row of role `offer`
  (`:31`), made by `offerRows` (`:470`) from `games.tsv` for each game with no game row **that Steam's own
  package cache says the account owns** (`askOwned`, `:436`). Its second line is "Not set up on this Mac.
  Opens the set-up guide." (`:165`), and a click opens the guide in the browser.
- The table it reads is the copy inside its own bundle, `Contents/Resources/games.tsv` (`:1270`), which
  `common/make-launcher-app.sh:76` copies at build time. So a game added to the repository shows as an offer
  only after a setup has run again and rebuilt the window.
- Anything that could stall the window is asked of a child process with a time limit (`runChild`, `:390`).
  Its one question is an `NSAlert` shown as a sheet, with the safe answer first (`:1441-1448`). Its menu
  holds one item, "Quit 14unch3r" (`:1318-1319`). Its one preference is `lastAppID` (`:1466`).
- Both setups build it: `surviving-mars-relaunched/scripts/setup.sh:215-216`, and Cities: Skylines II's
  (header, `:28-29`).

### 1.4 The launchers

- Each launcher's only update step is the game's own, through Steam (`step 4 "Checking for a game update…"`,
  `surviving-mars-relaunched/launch-relaunched.sh:460`; `cities-skylines-2/launchers/launch-cs2-dxmt11.sh:395`).
- `note` (`launch-relaunched.sh:122`) is "something the player should see even while the progress window is
  up": a line in the log and, from the app, a notification.
- A deployed launcher reads only files setup put beside it (the find-wrapper block, `launch-relaunched.sh:71-80`),
  and `common/test-launcher-parity.sh` holds the blocks the two launchers share equal byte for byte and
  records every `note` call (its rules 5, 6 and 9).

### 1.5 What GitHub answers (measured from the Studio, `/usr/bin/curl` 8.7.1, macOS 27.2)

| Asked | Answer |
|---|---|
| `https://raw.githubusercontent.com/macgameport/1launcher/release/CHANGELOG.md`, twice | 200, 1,853 bytes, 0.25 s and 0.17 s; `cache-control: max-age=300`; `content-type: text/plain; charset=utf-8` |
| the same with `--max-filesize 100` | curl exit 56, "Maximum file size exceeded", nothing kept |
| a ref that does not exist, raw and archive, with `-f` | **curl exit 56**, "The requested URL returned error: 404" |
| the same archive address with `--http1.1` | curl exit 22 |
| the first version heading of `CHANGELOG.md` at each tag | `v0.1.0`: `## v0.1.0 (2026-11-16)`; `v0.2.0`: `## v0.2.0 (2026-11-17)`; `## Unreleased` is above it in both |
| `release` on GitHub | at `ce2fcd0` (the commit `v0.1.0` names); **not protected**; the repository has no rulesets |

So one small request to an address family the project already depends on for ever (the pasted line reads
`raw.githubusercontent.com/.../release/install.sh`) says which version `release` holds and what changed in
it. An answer can be up to five minutes old.

### 1.6 A defect found on the way

`install.sh:98` tells "GitHub has no such ref" from "GitHub could not be reached" by curl's exit code 22, and
so does the installer app's program. On this Mac curl exits 56 for a 404 over HTTP/2. So a ref that does not
exist is reported as "GitHub could not be reached (curl exit 56). Check the network", and the installer app's
"This installer has been withdrawn or has moved" can never be printed. `common/test-bootstrap.sh` serves its
fixtures from a stub curl, so it could not see this. Step U0 fixes it.

### 1.7 Conferring with the sibling repositories

`grep -rIlE 'self-update|auto-update|check for updates'` over the siblings' `docs/` and `CLAUDE.md` finds
nothing about an app that updates itself (the hits are about other things that update automatically). No
precedent to adopt, none declined.

## 2. Target

1. A Mac set up by the pasted line knows which version of 1launcher each game was set up from.
2. At most once a day, when 14unch3r opens or a game starts, the Mac asks GitHub which version `release`
   holds. If the network is down, nothing is said and the game starts as before.
3. When a newer version is out, 14unch3r shows it, with what changed. One click, and a yes, opens Terminal
   and runs the installer again for every game set up on that Mac. Nothing is ever installed without that yes.
4. A game added to the repository reaches every such Mac with the update: after it, the window offers the
   game to the players whose Steam account owns it, as it offers an unported game today.
5. A Mac set up from a checkout (the Studio, the MacBook, a contributor's) is never offered an update and
   never asks GitHub anything.

## 3. Design

### 3.1 The record

A new folder beside the games' state folders: `<data root>/_update`, where the data root is
`common/paths.sh`'s `L1_DATA_ROOT` (`~/Library/Application Support/1launcher`). `paths.sh` gains
`L1_UPDATE_DIR="${L1_UPDATE_DIR:-$L1_DATA_ROOT/_update}"` and prints it as a seventh line. The name starts
with `_`, which no game folder can (`install.sh:25` admits `^[a-z0-9][a-z0-9-]*$` only).

| File in `_update/` | What | Written by |
|---|---|---|
| `installed/<Steam app ID>` | one line, four fields, tab-separated: the line the game follows, the version, the commit, the time (epoch seconds) | that game's setup, at its end |
| `offer` | one line: the version `release` held at the last fetch, and that fetch's time | the check |
| `notes.md` | `CHANGELOG.md` as last fetched | the check |
| `noted` | the version the launchers last announced | the check, for a launcher |
| `off` | if it exists, nothing is ever fetched. Made by hand | the player |
| `updates.sh` | the deployed copy of `common/updates.sh` | each setup |

- **The line a game follows** is `L1_FETCHED_REF` when the root `install.sh` fetched the tree (`release` for
  every player), and the word `checkout` otherwise.
- **The version** is the first line of the tree's `CHANGELOG.md` that matches
  `^## v(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5}) \(`, written `v<a>.<b>.<c>`, or `-`
  when there is none. `CLAUDE.md` § Releases already fixes that heading form, and the release commands
  refuse a tag whose section is not found.
- **The commit** is the 40 hex digits the root `install.sh` read from the archive (`:106`), which it now
  exports as `L1_FETCHED_COMMIT`, or `-`.
- A stamp is written beside its place and renamed over it, as setup writes every copy.
- A setup writes its stamp when it has finished its work: exit 0, and for Cities: Skylines II exit 5 too
  (finished, a fix not out yet for this game build). With `--check`, `--mac-only` or `--dest` it writes none.
- The key is the Steam app ID, the one name of a game that never changes (`CLAUDE.md` § Published addresses).

### 3.2 `common/updates.sh`: the rule for what is installed and what is on offer

One file, in the form of `common/wrappers.sh`: read with `.` it defines functions and exports nothing; run
it prints. Read with `.`, it needs `L1_UPDATE_DIR` set by the caller (setup, after `paths.sh`). Run, it uses
`L1_UPDATE_DIR` if set and otherwise the folder it lies in, which for the deployed copy is `_update` itself:
so no deployed file spells the data root.

Functions:

- `l1u_version_of <file>`: the version as defined above, read from the first 1 MiB; returns 1 when none.
- `l1u_newer <x> <y>`: 0 when `x` is a later version than `y`, the three numbers compared as numbers. `-`
  counts as `v0.0.0`.
- `l1u_stamp <app ID> <tree root>`: writes `installed/<app ID>` as 3.1 says.
- `l1u_state`: prints one line, `<word><TAB><installed><TAB><offered>`. In this order:
  1. `off`, if `off` exists;
  2. `none`, if `installed/` holds no stamp (a stamp is a regular file whose name is a whole number and whose
     one line has the four fields; anything else in the folder is passed over);
  3. `manual`, if any stamp's line is not `release`;
  4. `unknown`, if `offer` is absent or does not parse;
  5. `ready`, if the offered version is newer than the **lowest** installed version;
  6. `current` otherwise.
- `l1u_refresh [--now]`: does nothing when the state is `off`, `none` or `manual`. Without `--now` it does
  nothing when `offer` parses and its time is less than 86,400 s before now and not after now. Otherwise:
  `curl --proto '=https' --tlsv1.2 -fsS --max-time 10 --max-filesize 1048576 -o <a new file in _update>
  https://raw.githubusercontent.com/macgameport/1launcher/release/CHANGELOG.md`. A non-zero exit, a file
  over 1 MiB, or a file with no version heading: the new file is removed, `offer` and `notes.md` stay as they
  were, and it returns 1. Else the file is renamed to `notes.md`, then `offer` is written beside and renamed.
  It refuses to write anywhere unless `installed/` is a folder, so a run in the repository's own `common/`
  writes nothing.

Run as a program:

| Call | Prints | Exit |
|---|---|---|
| `updates.sh` | the state line | 0 |
| `updates.sh --refresh [--now]` | the state line, after `l1u_refresh` | 0, or 1 when a fetch was tried and failed |
| `updates.sh --notes` | from `notes.md`, every section whose version is newer than the lowest installed one, newest first, as the text it is; after 200 lines or 12,000 bytes, one last line with the address of the changelog on `release` | 0; 1 when there is nothing to print |
| `updates.sh --noted` | the offered version, when the state is `ready` and `noted` does not already hold that version; it then writes `noted` | 0 then, 1 otherwise |
| `updates.sh --open` | nothing: it writes the `.command` of 3.4 and opens it in Terminal | 0; 1 when the file or Terminal could not be had, with one sentence |

Test variables, in the form of `L1_KILL` and `L1_OWNED_HELPER`: `L1_UPDATE_DIR`, and `L1_UPDATE_NOW`, an
epoch that stands for now. `curl` and `open` are called by name, so a test puts stubs first on `PATH`, as
`common/test-bootstrap.sh` does.

**Why the version and not the commit.** The version is what the player is shown, and its section is the text
of what changed, so one request serves both. It works only if `release` never holds a commit that is not a
release, which 3.6 makes a gate. **Why "newer" and not "different".** `raw.githubusercontent.com` may answer
with a copy up to five minutes old (1.5). Right after an update the old answer names the version just left,
and "different" would offer it back. Numbers compared as numbers cannot offer an older version.

### 3.3 The setups

Both `cities-skylines-2/scripts/setup.sh` and `surviving-mars-relaunched/scripts/setup.sh`:

1. read `common/paths.sh` (Surviving Mars's setup does not today: it spells its state folder itself,
   `:151`) and `common/updates.sh`;
2. copy `common/updates.sh` to `_update/updates.sh`, written beside and renamed, with the same
   own-folder test they apply to the runtime folder;
3. write one line, the absolute path of `_update`, into a file `update-dir` beside the deployed launcher;
4. as their last act before the closing words, call `l1u_stamp`.

`common/make-launcher-app.sh` writes the same path into the window's `Info.plist` as `L1UpdateDir`, with
`plutil`, as the game apps carry `L1Prefix`.

Two setups deploy the same file, and the later one wins. Within one update both come from one tree. A game
left on an older version beside one updated by hand could put an older `updates.sh` back; the next update
replaces it. Accepted, and said here so that nobody finds it later as a surprise.

### 3.4 The update itself

**The button's file** (`updates.sh --open`). In a new folder from `mktemp -d` it writes
`Update 1launcher.command`, in the installer app's form (`common/make-installer-app.sh`, the heredoc `EOS`):
it removes itself on exit, fetches `https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh`
with the pasted line's own curl options, runs it as `/bin/bash -c "$S" 1launcher-install update`, and ends
with "You can close this window." Then `open -a Terminal <file>`. The whole of it is the pasted line with
the word `update` where the app ID stands.

**The root `install.sh`** takes `update` as its first word: `install.sh update [<ref>]`.

- From a checkout it fetches nothing and says: "This is a checkout: update it with git pull, then run each
  game's scripts/setup.sh." Exit 2.
- Fetched, after the checks it makes today, it needs `common/update-games.sh` in what it fetched (else:
  "This version of 1launcher has no update step.", exit 1), exports `L1_FETCHED_REF` and `L1_FETCHED_COMMIT`,
  and runs `bash <tree>/common/update-games.sh`, returning its exit code.
- `update` is the only word that is not a number that it accepts. A game is still named by its Steam app ID
  and by nothing else, and every other word still gets "not a Steam app ID".

So the code that drives an update is always the newest (it comes with the fetch), and the only thing an
installed Mac holds is the address of the root `install.sh`, which is already never moved.

**`common/update-games.sh`** (new; run only by the root `install.sh`, from the fetched tree):

1. refuses unless `L1_FETCHED_REF` is set (exit 2), then reads `paths.sh`, `updates.sh` and `wrappers.sh`
   from its own tree;
2. with no stamp in `installed/`: says that no game on this Mac was set up by a version that records it,
   and to open each game's installer once (the address of the repository's front page). Exit 3;
3. for each stamp, in the order of the app IDs:
   - its line is not `L1_FETCHED_REF`: "`<title>`: set up from `<line>`, not from `<ref>`. Left as it is.";
   - the tree's `games.tsv` has no row for it, or the row's folder has no `scripts/install.sh`:
     "!! `<app ID>`: this version has no installer for it." Counted as failed;
   - `l1w_find game <app ID>` finds no wrapper, or one with no prefix: the stamp is removed and it says
     "`<title>`: no longer set up on this Mac. Skipped." (Without this, an update would start a new install
     of a game the player removed: a download of up to 100 GB nobody asked for.);
   - else a heading line with the title, and `bash <tree>/<folder>/scripts/install.sh` with no option, its
     input the Terminal's;
4. a closing block: one line per game with what happened, then "Everything is up to date: 1launcher
   `<version>`." or "Not everything was updated. Do what the lines above say, then update again from
   14unch3r.";
5. exit 1 if an installer failed (any code but 0, 3 and 5), else 3 if one stopped (3), else 0.

**No answer is ever given for the player.** The installers run without `--yes`. In Terminal each can ask what
it asks today: Surviving Mars's installer asks before it fetches anything of Apple's
(`surviving-mars-relaunched/scripts/install.sh`, the question before step 3), and an installer stops with
exit 3 while the game is running. An update that needs a new engine therefore asks first, in the same words
as a new install.

**The free-space caution.** `core_space` says nothing when the wrapper exists and `game_state` is
`installed` or `update` (step U0). It is called after `core_begin` has chosen the wrapper, which sets what
`game_state` reads (`use_wrapper`, `common/install-core.sh:148-157`).

### 3.5 The window

- At open, when its `Info.plist` has `L1UpdateDir` (or `L1_UPDATE_DIR` is set, for the tests) and
  `<dir>/updates.sh` is a regular file, the window asks `/bin/bash <dir>/updates.sh` through `runChild` with
  a 5 s limit, and reads the state line. No network is touched by that call.
- **State `ready`:** one more row, of a new role `update`, in a group of its own below the offers, under the
  label "Update". Its icon is the app's own mark, its title "1launcher `<offered>`", its second line "Update
  ready. Click to read what is new." It is drawn as a game row is (not dimmed) and is never the row selected
  at open, so Return still starts the last game.
- Then, off the main thread, the window asks `updates.sh --refresh` with a 15 s limit. If the state word it
  returns differs from the one shown, the list is shown again. The window never waits for the network.
- **A click on the update row** opens a sheet, an `NSAlert` as the one question the window has today:
  - title: "1launcher `<offered>` is ready";
  - text: "This Mac has `<installed>`. The update opens Terminal and runs the installer again for each game
    set up here. It changes nothing while a game is running.";
  - below it, in a scrolling text view (plain text, not editable, selectable, no link detection), what
    `updates.sh --notes` printed;
  - buttons: "Not Now" first (Return and Escape, as "Don't Start" is today), then "Update".
  - If a row is `busy`, the sheet is instead "Quit `<title>` first", with one button.
- **"Update"** runs `updates.sh --open` through `runChild` (10 s). Exit 0: the window quits, as after a
  start. Otherwise the failure sheet, with the sentence the tool printed.
- **The menu** gains "Check for Updates…" above "Quit 14unch3r". It runs `updates.sh --refresh --now`
  (15 s, off the main thread) and then shows: the sheet above for `ready`; "1launcher `<installed>` is the
  newest version." for `current`; "GitHub could not be reached." when the refresh failed or the state is
  `unknown`; "This Mac's games were set up from a checkout. Update with git pull, then each game's
  setup." for `manual`; "Checking for updates is switched off on this Mac." for `off`; "No game on this Mac
  records its version yet. Open a game's installer once." for `none`. With no `L1UpdateDir` the item is
  absent.
- **The text modes.** `--list`, `--grid` and `--act` take `--update-dir <dir>` as they take `--games <tsv>`,
  and then hold the update row, so every test of it runs with no window, against a folder of fixtures and a
  stub `updates.sh`.

### 3.6 The launchers

One block, the same in both launchers, placed after the lock is held and before step 1, and compared byte
for byte by `common/test-launcher-parity.sh` (a new rule 10, in the form of rule 9):

```bash
# >>> update-notice (the same in both launchers: common/test-launcher-parity.sh compares the copies)
# docs/plans/built-in-update.md, 3.6. One notice per new version of 1launcher, and a look at GitHub in the
# background at most once a day. Neither can delay or stop a start: the file is read, never waited for.
_l1u="$(cat "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/update-dir" 2>/dev/null)"
if [ -n "$_l1u" ] && [ -f "$_l1u/updates.sh" ]; then
  _l1v="$(bash "$_l1u/updates.sh" --noted 2>/dev/null)" && note "1launcher $_l1v is ready. Open 14unch3r to update."
  ( bash "$_l1u/updates.sh" --refresh < /dev/null > /dev/null 2>&1 & )
fi
unset _l1u _l1v
# <<< update-notice
```

The repository's own launcher has no `update-dir` beside it, so it does nothing there. The notice is said
once per version per Mac (`noted`), whichever game is started first.

### 3.7 The release gate, and the published addresses

`common/check-release-move.sh` gains a fifth question, asked when `<commit>` holds `common/updates.sh`:

5. a `v` tag names `<commit>` itself; the first version heading of `<commit>:CHANGELOG.md` is that tag; and
   it is newer than the first version heading of `origin/release:CHANGELOG.md`.

Reason: an installed Mac learns of an update only by a version heading that rises. A move of `release` to a
commit between two releases would reach new installs and no installed Mac.

`CLAUDE.md` § Published addresses gains: the root `CHANGELOG.md` is never moved, and the form of its version
headings is read by every installed Mac; `install.sh update` is a published word; and `release` moves only
to a commit a `v` tag names.

### 3.8 Trust, and what this sends

- **What runs.** The update runs code fetched from the `release` branch over HTTPS, exactly as the pasted
  line does. It adds no new trust; it makes the same trust recur. Whoever can move `release` can run code on
  every Mac whose owner clicks Update. So: nothing is installed without a yes (UD1); the sheet says which
  version and shows its notes before the yes; and `release` should be protected on GitHub against force
  pushes and deletion before this is published (UD5; today it is not, 1.5).
- **What is only read.** The check fetches one text file and runs none of it. The file is bounded at 1 MiB,
  its version is taken by one fixed pattern, and its text is shown as plain text.
- **What it sends.** One request for a public file, at most once a day per Mac. GitHub's servers see the
  Mac's network address and the time, as for any page loaded from GitHub. Nothing about the Mac, the player
  or the games is sent: no identifier, no version, no list of games. The guides say this, and how to switch
  it off (`off`, UD4).
- **Who is never asked.** A Mac whose state is `manual`, `none` or `off` fetches nothing.

### 3.9 New games

Adding a game stays what it is today: a folder with its installer, a row in `common/games.tsv`, a row in
`common/wrappers.sh`'s table, its tests, a release. With this plan the release then reaches installed Macs:
the update rebuilds 14unch3r with the new table, and the window offers the game to players whose Steam
account owns it (1.3). The offer still opens the game's set-up guide, which holds the pasted line (UD7).

## 4. Steps

Each step is one or more commits on `built-in-update`, with its tests in the same commit and every mutant of
section 6 applied and seen red before the step is called done.

- **U0. Two fixes found on the way.** `install.sh` and the installer app's program tell a missing ref by
  the HTTP code (`curl -w '%{http_code}'`), not by curl's exit code; `core_space` is silent on a finished
  install. Tests UT1, UT2.
- **U1. The record and the rule.** `common/paths.sh` (`L1_UPDATE_DIR`), `common/updates.sh`,
  `common/test-updates.sh`; the root `install.sh` exports `L1_FETCHED_COMMIT`; both setups deploy and stamp
  (3.3). Tests UT3, UT4, UT5.
- **U2. The update.** `install.sh update`, `common/update-games.sh`, `common/test-update-games.sh`,
  `updates.sh --open`. Tests UT6, UT7.
- **U3. The window.** The row, the sheet, the menu item, `L1UpdateDir`, the text modes. Test UT8.
- **U4. The launchers.** The block, `update-dir`, rule 10. Test UT9.
- **U5. The gate and the words.** `common/check-release-move.sh` question 5 (UT10); `CLAUDE.md` (the
  `_update` folder under "The only places outside the repo", the published addresses, `common/` in the
  layout table); the root `README.md`, both `INSTALL.md` files and Surviving Mars's `README.md` (how to
  update; what is sent; how to switch it off); `CHANGELOG.md` under Unreleased; this plan's as-built header.
- **U6. Live steps, merge, release.** Section 7. The branch is merged into `main` with `--no-ff` after
  `wrapper-names` is (that plan's W3b), because both change the setups. Its release is the next second-number
  release after `v0.3.0`.

## 5. Who notices what

| Who | What they notice |
|---|---|
| A player set up before this version | Nothing, until they paste the installer line once more. The release notes of this version say so. From then on the window tells them. |
| A player set up by this version or later | At most once a day one request to GitHub. When a version is out: a row in 14unch3r, and one notification at the next start of a game. Nothing else changes until they click Update. |
| A player who clicks Update | A Terminal window, the installer's own lines for each game (seconds per game where nothing is new), and its questions if a step needs one. |
| The Studio and the MacBook | No row, no notice, no request: their games are stamped `checkout`. The menu item says why. |
| James, at a release | `release` moves only to a tagged commit (the gate's fifth question). A move of `release` now reaches installed Macs within a day, not only new installs. |

## 6. Tests

Every test runs with `HOME`, `TMPDIR` and `L1_UPDATE_DIR` at scratch folders, starts nothing of Wine, and
touches no network: `curl`, `open` and (where named) `date` are stubs on `PATH`. A mutant is applied to the
source and must be seen red (exit 1, not REFUSED).

| Test | Where | What it shows | Mutants |
|---|---|---|---|
| UT1 | `common/test-bootstrap.sh`, whose stub curl gains an HTTP code and an exit code of its own to return | A 404 with curl exit 56 and a 404 with exit 22 both give "GitHub has no ...", exit 1; a failure with no HTTP answer gives "could not be reached"; the installer app's program has the same two branches (`common/test-make-installer-app.sh`) | the test put back on the exit code 22; the 404 branch dropped |
| UT2 | both games' `scripts/test-install.sh` | A finished install with less free space than `NEED_GB`: no `CAUTION`; a Mac with no wrapper and the same space: the `CAUTION` as today; a wrapper with the game not yet installed: the `CAUTION` | the condition dropped; the condition inverted |
| UT3 | `common/test-updates.sh` (new) | `l1u_version_of`: the first version heading under `## Unreleased`; none when there is none; a heading with a leading zero, a fourth number or no date is not a version; only the first 1 MiB is read. `l1u_newer`: `v0.10.0` over `v0.9.9`; equal is not newer; `-` is lowest. `l1u_state`: each of the six words, in 3.2's order, from fixture folders, among them: two stamps of which one is `checkout` gives `manual`; two `release` stamps at different versions use the lower; a stray file and a folder in `installed/` are passed over; an `offer` older than the installed version gives `current` | `l1u_newer` made a comparison of text; "lowest" made "highest"; the `manual` rule dropped; the order of `off` and `none` swapped |
| UT4 | the same file | `l1u_refresh`: within a day of the last fetch, curl is not called; after a day, and with `--now`, it is, with exactly the options of 3.2; a failed curl, an over-size file and a file with no heading each leave `offer` and `notes.md` byte for byte as they were and return 1; in the states `off`, `none` and `manual` curl is never called; with no `installed/` folder nothing is written; `--notes` prints the newer sections only, newest first, and the closing line when it cuts; `--noted` prints once per version and then exits 1 | the day test dropped; the temporary file renamed before it is checked; the state test before the fetch dropped; `--noted` not writing `noted` |
| UT5 | both games' `scripts/test-setup.sh` | After a setup that finishes: `installed/<app ID>` holds `checkout`, the tree's version, `-`; with `L1_FETCHED_REF=release` and `L1_FETCHED_COMMIT` set: `release` and that commit; `_update/updates.sh` is byte for byte `common/updates.sh`; `update-dir` beside the launcher holds the path; a setup that stops or fails writes no stamp and leaves an older one as it was; `--check` writes none; Cities: Skylines II's exit 5 writes one | the stamp written before the app is built; the stamp written on failure; `update-dir` not written |
| UT6 | `common/test-bootstrap.sh` | `install.sh update`, fetched: the fixture's `common/update-games.sh` is run with `L1_FETCHED_REF` and `L1_FETCHED_COMMIT`, and its exit code is returned; a fixture without it: the sentence, exit 1; from a checkout: the sentence, exit 2, curl not called; `Update`, `updates` and a folder's name are still "not a Steam app ID"; the per-game path also exports `L1_FETCHED_COMMIT` | the word accepted in any case; the checkout case made to run the driver; the exit code dropped |
| UT7 | `common/test-update-games.sh` (new), with stub installers that record their arguments, their input and the order, and a stub wrapper tree | Two stamps on `release`: both installers run, in the order of the IDs, with no argument; a stamp on `checkout`: its installer is not run and the line says so; a stamp whose wrapper is gone: the stamp is removed, no installer run; an ID with no row: counted as failed; exits 0, 3 and 1 as 3.4 says, with 5 counted as done; no `--yes` anywhere in the file; `L1_FETCHED_REF` unset: exit 2; `updates.sh --open`: the file's text is the pasted line with `update`, it is executable, and `open -a Terminal` got its path | the wrapper test dropped; `--yes` added; a stamp on another line run anyway; 5 counted as failed |
| UT8 | `common/test-launcher-window.sh`, `common/test-make-launcher-app.sh` | With `--update-dir` and a stub tool saying `ready`: `--list` and `--grid` hold the update row last, in its own group, with 3.5's two lines, not dimmed; the row selected at open is unchanged; `--act` click on it gives the sheet's four parts; with a busy row, the other sheet; "Update" calls the tool with `--open` and quits on 0, shows the failure on 1; each other state shows no row; a tool that hangs is given up after the limit and the list is as without it; the menu item's sentence for each state; `L1UpdateDir` is in the built `Info.plist`, and the grid's contrast lines still pass for the new row | the row made the default; the limit removed from the call; "Update" made the first button; the row shown for `current` |
| UT9 | `common/test-launcher-parity.sh` (rule 10), each game's launcher-notes test | The two blocks are equal byte for byte; with `--noted` giving a version: exactly one `note` with 3.6's sentence; giving nothing: none; the refresh is started in the background and its output goes nowhere; with no `update-dir`: nothing is run; a tool that sleeps does not delay step 1 | one byte changed in one copy; the `&` dropped; the `note` made unconditional |
| UT10 | `common/test-check-release-move.sh` | A commit holding `common/updates.sh`: untagged fails; tagged but with another first heading fails; tagged, heading equal but not newer than `release`'s fails; all three right passes; a commit without the file is not asked | each of the three conditions dropped in turn |
| UT11 | the gates | `common/check-links.py`, `common/check-identifiers.sh`, `bash -n` on every changed script, every other test file of the repository, and every older mutant of each test file touched still red | none |

**Not tested, and said so:** what Terminal shows; whether macOS asks anything when 14unch3r opens a
`.command` (UL1); how the sheet's text view looks (UL1, by eye); GitHub's own answers beyond the stub (UL1
reads the real one).

## 7. Live steps (each on James's word)

- **UL1. The check and the sheet, on the Studio, with nothing real changed.** A scratch `_update` holding
  one hand-written stamp on `release` at `v0.0.9`, and a 14unch3r built into a scratch folder that points at
  it. Open it: the real `release` is fetched once; the row appears; the sheet shows the real notes. Capture
  the window's region only. Press "Update" once, and close the Terminal window before it fetches: this
  measures whether macOS asks anything when the window opens Terminal. Record what each showed.
- **UL2. The update, rehearsed from the branch, on the Studio's Surviving Mars** (which is set up from what
  is published). With the branch pushed, a scratch `_update` holding one stamp for 3215050 on the line
  `built-in-update`, run by hand the pasted line with `update built-in-update`. Pass: the installer's seven
  steps, setup, a new stamp at the branch's version, the game starts from its app afterwards. Record how long
  the run took. The Studio's real `_update` is then `manual`, as it should be.
- **UL3. The same on the MacBook**, for both games, after its `wrapper-names` step (W3).
- **UL4. The first real offer.** At the first release after the one that carries this plan: a Mac set up by
  the pasted line shows the row within a day, and Update brings it to the new version. Until that release
  this path cannot run from end to end, and the plan's as-built header says so.

## 8. Exit criteria

1. Every test of section 6 passes and every mutant listed was applied and seen red.
2. UL1 to UL3 passed and are recorded in this file with what was measured.
3. A Mac set up from a checkout makes no request: shown by UT4 and by the Studio's state after UL2.
4. The guides say how a player updates, what is sent, and how to switch it off; `CLAUDE.md` names the
   `_update` folder and the new published addresses.
5. UD5 is settled one way or the other before `release` is moved to the version that carries this.
6. The as-built header is written at the build, with UL4 named as still to come.

## 9. Decisions for James

| | Question | Recommended |
|---|---|---|
| UD1 | May an update ever install without a yes? | No. Always the sheet, always a click. |
| UD2 | Where does the update run: in Terminal, as the install did, or inside the window with a progress bar? | Terminal, in this plan. It is the installer app's own way, it lets an installer ask its questions, and the player sees every line that runs. A progress view inside the window can follow once this has run on real Macs. |
| UD3 | From now on, does `release` move only to a commit that a `v` tag names (the gate's fifth question)? | Yes. It is what makes "a newer version is out" a fact an installed Mac can read. |
| UD4 | How often is GitHub asked, and can it be switched off? | At most once a day; a file `off` in `_update` switches it off; the guides say what is sent. |
| UD5 | Protect `release` on GitHub against force pushes and deletion, before this is published? | Yes. It is a setting of the repository, so it is yours to change or to tell me to change. |
| UD6 | Do the games' own launchers say when a version is out, for a player who never opens 14unch3r? | Yes: one notification per version per Mac. |
| UD7 | Does an offer for a game that is not set up still open its guide, or start the installer from the window? | The guide, in this plan. Starting an install from the window is a plan of its own: it is the installer's first-run path, with the findings that has. |
| UD8 | Fix the two defects of step U0 in this plan? | Yes. The update prints the same words and would carry the same wrong sentence. |
| UD9 | Which number does the release that carries this take? | The second number rises: it asks a player with an install to paste the line once more. |

## 10. Rollback

- **Before `release` moves:** nothing has reached a player. Revert the commits on `main`.
- **After:** a wrong release gets a successor (`CLAUDE.md` § Releases); installed Macs are offered it within
  a day. A player goes back to an older version by pasting the line with that version's tag after the app
  ID; the stamp then names that tag, the state is `manual`, and nothing is offered until the plain line is
  pasted again.
- **The check alone:** `off` stops it on one Mac. If GitHub's answer ever stops parsing, every Mac reads
  `unknown` and offers nothing: the failure is silence, never a wrong offer.
- **Files:** the `_update` folder holds no game data. Moving it to the Trash puts a Mac back to "no record";
  the next setup writes it again.

## 11. Not in this plan

- **An install started from the window** (UD7).
- **A progress view inside the window** (UD2).
- **Engine changes**, among them the `ntdll.dll` change of issue #30 and an engine of Wine 11.20 or later.
  They need a plan of their own. What this plan gives them: an installer step that swaps an engine, as
  Surviving Mars's step 4 does for D3DMetal, is run by the update on every installed Mac, and asks first
  where it fetches something new.
- **Silent updates, a schedule, a background agent.** Nothing runs when no app of the project is open.
- **Signing.** Nothing fetched is signed, as nothing is today. Protecting `release` (UD5) is what this plan
  does about who can change it.
- **Macs set up before this version.** They need one paste of the installer line; nothing reaches them
  before that.
- **Removing a game.** There is no uninstaller. An update passes over a game whose wrapper is gone and
  removes its stamp (3.4).

## Review log

Not yet checked.

Key paths: `install.sh`, `common/install-core.sh`, `common/paths.sh`, `common/wrappers.sh`,
`common/games.tsv`, `common/launcher-window.swift`, `common/make-launcher-app.sh`,
`common/make-installer-app.sh`, `common/check-release-move.sh`, `common/test-bootstrap.sh`,
`common/test-launcher-parity.sh`, `common/test-launcher-window.sh`, `cities-skylines-2/scripts/install.sh`,
`cities-skylines-2/scripts/setup.sh`, `cities-skylines-2/launchers/launch-cs2-dxmt11.sh`,
`surviving-mars-relaunched/scripts/install.sh`, `surviving-mars-relaunched/scripts/setup.sh`,
`surviving-mars-relaunched/launch-relaunched.sh`, `CHANGELOG.md`, `CLAUDE.md`.
