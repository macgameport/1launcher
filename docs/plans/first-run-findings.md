# What a new player meets: the findings of the installers' live steps

> **Status:** Triple-checked 2026-11-14 — build-ready-with-fixes (pass 1: six lenses; pass 1b: a fitted
> re-check of that fold; both are folded into the sections they concern and listed in "Review
> corrections"). Drafted 2026-11-13; its six probes (section 3) were done by 2026-11-14. Slice F
> is not built from this plan (2.4). Decisions FD3, FD4 and FD5 were taken as recommended on 2026-11-15
> (section 8); ND1 is open and James's. FD3's design (2.6, item 5) and its row FT4c were written that
> day, after the check, and re-checked on their own ("Review corrections").
>
> Tracking: issue #22. The code it speaks of exists only on the branch `surviving-mars-install` (cut from
> `simple-install`): every `file:line` below is as of that branch at `75470c9`, and holds at `283a464` too (the cited files did not change between them). A path is relative to the
> repository's root. The findings were recorded where they were seen, and stay there as the record:
> SF1 to SF9 in section 9 of `docs/plans/shared-installer.md` (on the branches), MF1 to MF4 in section 5a
> of `docs/plans/surviving-mars-install.md`. This plan is where they are planned.

## 0. What this is for

The live steps of the three installer plans passed, and each showed things a new player would meet that
the plans had not foreseen. They are wanted before the first release (the installer plan's NL3). They
were written down as rows, not planned. This plan groups them into slices, says what must be measured
before each can be designed, designs the ones that can be designed now, and names the decisions that are
James's.

## 1. The findings, grouped

| Slice | Findings | What a player meets | Can be designed now |
|---|---|---|---|
| A. Steam's own update is cut | SF1, SF2, MF2 | Steam is started five times in 90 s, then twenty lines of its log and "Steam did not start after 5 tries" | yes (2.1); four of its five word forms are new (FD4) |
| B. Steam's updater on screen | SF3 | Steam's own "Updating Steam..." window, with a Cancel button, at its first start in a new wrapper; sometimes its "Fatal Error" box | yes, since P1: it cannot be hidden, so it is named (2.10) |
| C. curl's own words | SF4 | `curl: (18) Transferred a partial file` although the next address worked | yes (2.2) |
| D. The macOS 28 notice | SF5 | "App Update Required ... will not open in macOS 28" at the wrapper's first start, and nothing says it is expected | yes (2.3) |
| E. The downloaded app's approval | SF6 | Finder's "not responding" after the approval was stranded | no: James's ND1 first |
| F. A fix not yet available for a new game build | SF7 | "setup finished with 1 problem(s)" and "The install stopped", the same on every later run | not from this plan: the patch scripts cannot say it today (2.4) |
| G. The wrapper's making waits for every other Wine | SF8, MF1 | "making the Wine prefix (about 30 s)" for as long as any other Wine is open | yes, since P2 (2.5) |
| H. A line of bash's in the installer's output | SF9 | perhaps `child setpgid (...): Operation not permitted`; and a test that fails now and then | yes, since P3 (2.9) |
| I. A mod switched off by a new install | MF3, and what P5 showed besides | a save runs, and is saved, without its Paradox mod, here and on the player's other install; and a first start asks again for the game's two agreements and the Paradox account, with the game's own mod warning behind the agreements | yes, since P4 and P5 (2.6); two decisions (FD3, FD5), both taken |
| J. Runtimes the new prefix lacks | MF4 | nothing so far | nothing to build (2.7) |
| K. Small things seen at ML4 and at the re-check | | two lines that say something untrue | yes (2.8) |

## 2. What is true today, and the design where one can be made

### 2.1 Slice A: Steam's own update is cut

**True today.** A new Steam downloads its update (305 to 336 MB) from `cdn.steamstatic.com`. When that
path cuts transfers, Steam's `logs/bootstrap_log.txt` gains lines `Error: Download of package (<name>)
failed after 0 bytes` (29 of them in ML2's failed start) and then `Error: Steam needs to be online to
update. Please confirm your network connection and try again.` The core knows the last line:
`FATAL='Error: (Failed to determine download location|Steam needs to be online)'`
(`common/install-core.sh:35`). On it, `start_until_up` ends that Steam and starts another
(`:180`, `end_steam; continue 2`), up to `MAX_STARTS` (5). When all five have failed the installer prints
"!! Steam did not start after 5 tries. The last lines of its log:" and twenty lines of the log
(`:362-367`), and exits 1. Seen twice: at SL1 and at ML2, both with the default route on a VPN's tunnel.
At SL1 it then worked on another route; at ML2, at ML4 and four times at P1 the same update ran in one
start with the VPN paused (48 to 50 s). At ML2 a transfer of one package by `curl` was cut twice with
curl's exit 18, after 1.1 MB in 6.0 s and after 12.9 MB in 11.7 s. A Steam left at its error box did not
close on `-shutdown` within 30 s; `wineserver -k` closed it and left the 0-byte `.crash` marker, which
`start_until_up` already removes before each start (`:172`).

**Neither fatal line by itself says the path is cut.** At the installer plan's probe
(`docs/plans/simple-install.md`, 1.4) the first start in a new prefix failed 3 of 3: twice with "Failed
to determine download location" and once with "Steam needs to be online", and a second start worked each
time. So both lines keep their restart. What tells a cut path from a first start's stumble is a transfer
of the installer's own.

**What Steam's log gives** (the logs of ML2 and of 2026-11-14, read):

- Every line ends in a carriage return (291 of 291 and 478 of 478). An address cut from a line carries
  it, and `curl` refuses such an address with exit 3.
- An `Add pending download:` line holds a whole address. All are `https://` on a `steamstatic.com` host,
  and most end `_<bytes>` (5 of ML2's 37 do not). In ML2's failed start all 37 are
  `https://cdn.steamstatic.com/client/<file>`; in a start that worked, 14 of 35 are
  `https://client-update.steamstatic.com/<file>`, with no `/client/`, and the largest of all is one of
  those.
- The first such line is a 5.6 MB file; the largest is about 106 MB. ML2's cuts came after 1.1 MB and
  after 12.9 MB, so a small file can pass whole on a path that cuts.
- None of the six logs read holds a home folder's path or an account number.

**Design.**

1. `start_until_up`, on "Steam needs to be online" for the first time in a run, ends that Steam as today
   and returns 2 without starting another. It leaves in a variable of the core (`LOG_FROM`) the number of
   the log's last line before that start. On "Failed to determine download location", and on "needs to
   be online" once the transfer of step 2 has been made, it starts another as today. Every start counts
   in `MAX_STARTS`: the count is a variable of the core too, and the second call does not begin it
   again. When both lines are new in one look, "needs to be online" is the one acted on.
2. The caller then makes one transfer, once in a run:
   - **The address.** From the `Add pending download:` lines after `LOG_FROM`, carriage returns
     removed, those whose whole address matches
     `^https://[A-Za-z0-9.-]+\.steamstatic\.com/(client/)?[A-Za-z0-9._-]+_[0-9]+$` are kept (a line with
     no number at its end is passed over), and of those the one with the largest number after its last
     `_` is used: from ML2's failed log a file of 105,972,111 bytes. With no such address `curl` is not
     run and the result is "not known". Whether a Mac with no network logs any such line is not known;
     if it logs none, its run ends in the plain form, not the "no network" one.
   - **The transfer.**
     `curl -q --proto '=https' --proto-redir '=https' --tlsv1.2 --globoff -fsSL --max-time 20 -o /dev/null -w '%{size_download}' -- "$address"`,
     its error output sent away. (`-q` first: the player's own `curl` settings are not read. Measured
     with curl 8.7.1: `%{size_download}` is printed on a transfer that timed out or was cut; without
     `-f` an error page gives exit 0.)
   - **The result.** Cut: exit 18, 56 or 92 (18 was seen; 56 was measured against a test server; 92,
     a cut HTTP/2 stream, is from curl's documentation). Working: at least 20,000,000 bytes received,
     with exit 0 or 28. No network: exit 6 or 7. Anything else: not known.
3. What follows:
   - **Cut, or no network:** the words of step 4, and exit 4. No further start.
   - **Working, or not known:** `start_until_up` again, as today. If no start brings the client up, the
     words of step 4 for that result, and exit 4. (Today that end is twenty lines of the log and
     exit 1.)
4. The words, two lines and then the log's line. The first form is the one James has seen (the
   shared-installer plan's section 9: "ok"); the other four are new and are FD4.

   Cut, and the Mac's default route is a tunnel (`route -n get default` names an interface that begins
   `utun`):

   ```
     !! Steam could not download its own update: the connection to Valve's server keeps being cut.
        This Mac is using a VPN, which may be the cause. Change the VPN's server or pause it,
        then open the installer again. It carries on from this step.
   ```

   Cut, with no tunnel: the first line, then
   `     Open the installer again in a few minutes. It carries on from this step.`

   No network:

   ```
     !! Steam could not download its own update: this Mac cannot reach Valve's server.
        Check the network, then open the installer again. It carries on from this step.
   ```

   Working, and the starts used up: `  !! Steam could not download its own update, although this Mac
   reaches Valve's server.` and the "in a few minutes" line. Not known, and the starts used up:
   `  !! Steam could not download its own update.` and the "in a few minutes" line. Neither names a VPN:
   nothing was measured that points at one.

   Last, in every form, for someone who asks for help (the home folder as `~`, by the core's `tilde`):

   ```
        Steam's own log, if you ask for help: ~/Applications/<the wrapper>/.../Steam/logs/bootstrap_log.txt
   ```

5. No line of Steam's log is printed in these forms. The failure that has no "needs to be online" in it
   (five starts, each ended some other way) keeps today's words, its twenty lines and exit 1.
6. The core sets `END=quiet` before these exits: its own closing line for 4, "Open the installer again:
   it carries on from here." (`:73`), would say the same thing a second time.
7. The tunnel test only chooses between two second lines after a cut that was measured. It misses a VPN
   whose interface is not `utun` (the built-in IKEv2 and L2TP kinds), one that leaves the default route
   on the network's own interface, and one on the router; it matches tunnels a player may not call a VPN.
   "May be the cause" is true in each of those.
8. A VPN that works is never mentioned, and nothing is tested before a failure.
9. Each guide's "Good to know" gains: "**On a VPN?** Steam's own first update (about 330 MB) is
   sometimes cut on a VPN's route. The installer says so if it happens: pause the VPN or change its
   server, open the installer again, and switch the VPN back on once Steam's sign-in window is up."

**Not designed here:** a box instead of a line (SF2's row). P1 saw no error box of Steam's in four first
starts (2.10), so it learned nothing about one covering the installer's window, and the line stays.

### 2.2 Slice C: curl's own words

**True today.** Steam's installer is fetched from two addresses in turn with
`curl --proto '=https' --tlsv1.2 -fsSL --retry 2 -o ...` (`common/install-core.sh:310-311`). `-S` makes
curl print its error for an address that fails even when the next one works; at SL1 that was
`curl: (18) Transferred a partial file`.

**Design.** Each try's error output goes to a file in the stage's temporary folder. It is shown, under
the installer's own sentence, only when every address has failed, as lines indented by five spaces (the
form of `:365`). The sentence stays as it is (`:313`).

### 2.3 Slice D: the macOS 28 notice

**True today.** At a wrapper's first Wine start macOS 27 showed: "App Update Required. This version of
"CS2fresh" includes a component that will not open in macOS 28, the next major release. An update may be
available on the developer's website." (SL1; James: "don't forget this.") `cities-skylines-2/README.md`
and the root `README.md` say that macOS 28 will not run these games (issue #16); the quick way of each
guide and the installer say nothing of the notice.

**P6, answered 2026-11-14.** James did not see the notice when Surviving Mars's new wrapper was made at
ML4. That is what he saw, not a measurement of what macOS did: nothing was captured, and why the notice
came for one new wrapper (SL1) and was not seen for another (ML4) is not known. Both were made by
`common/make-wrapper.sh` on the same Mac and the same macOS. So the line below keeps its "may", and is
printed for every game.

**Seen again on 2026-11-14 (James's capture, 20:41).** The notice came during the scratch game's second
start, and one to two minutes after two new prefixes of P2 had first started Wine; which of them drew it
is not known. It read `This version of "Claude Code" includes a component ...`: the app the session's
shell ran in. So it has been seen twice with two kinds of name, the wrapper being made (SL1) and the app
the shell ran in. Which name it shows, and when it comes, is not known; what macOS 26 shows is not known
either. The line below quotes no name for that reason.

**Design.** Two lines where Wine first starts, in `common/make-wrapper.sh` before "making the Wine prefix"
(`:135`), printed only when the major number of `sw_vers -productVersion` is 27:

```
  macOS may show "App Update Required ... will not open in macOS 28", now or when the game starts.
  That is expected and nothing needs updating. The game needs macOS 27: do not upgrade to macOS 28.
```

And one sentence in the quick way of each guide (`cities-skylines-2/INSTALL.md`,
`surviving-mars-relaunched/INSTALL.md`): "macOS 27 may show "App Update Required ... will not open in
macOS 28", during the install or when the game starts. That is expected and nothing needs updating:
these games need macOS 27." It ends with a link to the Compatibility section of the root `README.md`.

### 2.4 Slice F: a fix not yet available for a new game build (Cities: Skylines II)

**True today.** When the game is a build newer than the patches know, one patch script finds no pattern,
`repatch.sh` reports it, `setup.sh` ends "=== setup finished with 1 problem(s): see the lines marked !!
above ===" with exit 1 (`cities-skylines-2/scripts/setup.sh:303`), and the core adds "The
install stopped. The lines above say why. Open the installer again to carry on from that step."
(`common/install-core.sh:74`). Opening it again gives the same until a new pattern is published (seen at
SL2, with `patch_cohtml.py` on build 26404411; fixed on 2026-11-12, `e14bbae`).

**Not built from this plan (found at the check, 2026-11-14).** The words this section held rest on
telling "no pattern for this build" from a failure, and nothing can tell them apart today: the 16
patch scripts report a pattern they do not find as they report any other failure, `repatch.sh`'s `run`
counts both alike (`cities-skylines-2/repatch.sh:55-58`), and two of the scripts finish without error
on a pattern that is gone (`:138`; `patches/patch_asset_database.py:92-94` is one). The Cities: Skylines II launcher speaks of
the same state in other words ("Some patches could not be applied. Update and run setup"). So slice F
needs a contract of its own first: an outcome every patch script can report, read script by script; then
the words, FD1, and the launcher's note with them. That is a plan of its own, written after this one is
built; SF7's row says so where it is recorded. FD1 goes with it.

### 2.5 Slice G: the wrapper's making waits for every other Wine

**True today.** `common/make-wrapper.sh:136` runs the template's
`Contents/MacOS/wineskinlauncher WSS-wineprefixcreate`. The prefix is complete within a minute; the
program then waits until no process named `wineserver` runs anywhere on the Mac (`killall -0 wineserver`
in its own loop). At ML2 that was 85 minutes, ended 23 s after a Steam in another wrapper was quit. For
this project it matters twice over: its own second game, or its Steam app, may be the Wine that is open.

**From probe P2 (2026-11-14; the game's `runs/findings-probes-20261114/`, `notes.md` and
`p2-compare.txt`).** Three bare wrappers, each the template's app with the engine moved in, as
`make-wrapper.sh` has them before its step 7:

- **(a) The template's step with no other Wine open: 27 s.** `wineboot` until 16 s; `system.reg` at 17 s;
  a second Wine program from 18 to 21 s; at 23 to 24 s the prefix goes from 1,989 entries to 1,983; the
  program ends at 27 s with exit 0.
- **(c) The same step with another Wine open** (the scratch game of P5): the same course to 21 s and
  1,989 entries, then nothing changes. The program was ended (TERM) after 10 s without change. Against
  (a): the same 1,793 regular files under `drive_c` with the same contents, one installer file's random name aside; the
  same registry, the wrapper's own name in paths, `MachineGuid` and times aside; the same `Info.plist`,
  the name aside. What (c) has and (a) has not: six links in `drive_c/users/Wineskin` to the Mac's own
  Desktop, Documents, Downloads, Music, Pictures and Movies (as `Videos`), and `user.reg` with mode 777
  where (a) has 666. So after its wait the program removes those six links and sets modes (the next
  paragraph but one has every entry's). With the links removed and the mode set, (c)'s list of names is
  (a)'s, and Steam's installer ran in it (exit 0, 7 s).
- **(b) `wineboot -u` by hand** in a prefix folder of its own: 15 s and no wait, but not the same
  prefix. The user's folder carries the Mac user's name and there is no `Wineskin` folder, which every
  path of this project's launchers names; 980 lines of `system.reg` and 17 of `user.reg` differ (the Mac
  driver's keys, font smoothing, the Direct3D key, file associations). It is not used.

**Every entry's mode, compared at the check (2026-11-14, `p2-compare.txt`, from the copies in the
Trash).** Inside the prefix, (a) and (c) differ in the three registry files only, and only because
Steam's installer had since run in (c): Wine writes them again with mode 644, so a mode set on them does
not last. Outside the prefix three entries differ: `Contents/Info.plist` (666 in (a), 755 in (c)),
`Contents/SharedSupport/Logs` (777, 755) and `Logs/LastRunX11.log` (777, 644). So after its wait the
program also sets those modes.

**Design.** Step 7 of `make-wrapper.sh` starts the template's program in the background and looks once a
second. While no other Wine is open nothing differs from today: the program ends by itself, its exit
code is read as now (`:137`), and no time limit is added (the step has none today). The script ends the
program itself only when all of these hold at one look:

- `system.reg`, `user.reg` and `userdef.reg` are in the prefix, `drive_c/users/Wineskin` is a folder
  and not a link, and `user.reg` holds the section `[Software\\Wine\\Mac Driver]` (taken as the sign
  that the program's second Wine step has run: (a) and (c) hold it and (b), made by `wineboot` alone,
  does not; when it is written was not timed. If a later template wrote it after its wait, the script
  would wait as today, which is the safe side);
- no `wineserver` of this user holds this prefix;
- the number of entries in the prefix (`find <prefix> | wc -l`, which does not follow links) has stood
  still for 10 looks;
- at every one of those looks a `wineserver` of this user that does not hold this prefix was running
  (`pgrep -x -U "$(id -u)" wineserver`; the template's own test, `killall -0`, sees this user's only).

"Holds this prefix" is `lsof -p <pid>` naming the prefix's own path, compared as a fixed string
(`grep -F`) against the build folder's resolved path (`pwd -P`). P2 saw it work: 17 looks of (c) found
the prefix's own `wineserver` that way (`p2c-kill.txt`). An `lsof` that fails or prints nothing counts as
"not known", and the program is not ended at that look. The counts of looks are variables at the
script's head, as the core's are (`common/install-core.sh:29-34`).

**Ending it.** TERM to the program's own process (`$!`), at the look that found it alive; then up to 10
looks until it is gone; then `wait <pid>`. All three stand inside `{ ...; } 2> /dev/null`: bash prints a
line "Terminated: 15", with the script's own path in it, at the first command after the program dies, so
a redirection on the `wait` alone comes too late (measured, bash 3.2). The program's exit code is not
read: P2's ended program gave 0, and bash gives 143 for one that does not catch the signal. If it is
still there after the 10 looks the step fails as a failed step does today.

**Then what the program does after its wait**, in this form and no other:

```
for n in Desktop Documents Downloads Music Pictures Videos; do
  p="$SS/prefix/drive_c/users/Wineskin/$n"; [ -L "$p" ] && rm -f -- "$p"
done
chmod 666 "$SS/prefix/system.reg" "$SS/prefix/user.reg" "$SS/prefix/userdef.reg" "$APP/Contents/Info.plist"
chmod 777 "$APP/Contents/SharedSupport/Logs" 2> /dev/null; chmod 777 "$APP/Contents/SharedSupport/Logs"/* 2> /dev/null
```

Neither the loop nor the last `chmod` is the last command of something whose status is read: each ends
with status 1 in ordinary cases (a last name that is no link, an empty `Logs`).

The six links point at the player's own Desktop, Documents, Downloads, Music, Pictures and Movies. A
name with a slash after it, `rm -r`, a pattern under a link, or any command that follows links would
reach into those folders: measured on a scratch link, `rm -rf <link>/` deleted the folder the link
pointed at and left the link. So no step of the script, and no test, uses such a form on the prefix. The
modes are the template's own, copied so that the wrapper is the one a finished run leaves.

It says one line, for whoever reads a transcript later:

```
  Another Windows program is open on this Mac, so the installer finished this step itself.
```

The checks of `:138-140` and step 8 stand. The other Wine is never closed and never named, and nothing
is asked of the player at this step.

**The script's own exit.** `cleanup` (`:90-97`) ends the template's program if it is still running
(TERM; after 5 looks KILL, which is safe for this program: it is not Steam; inside the same kind of
group, since the trap prints bash's line too) before `wineserver -k` and the removal of the build
folder, on every path out. That is needed for Control-C too: a program started
in the background by a script is not reached by it (measured, bash 3.2), where today's foreground
program is.

This rests on the pinned template (`:19-21`): what its program does after the wait was found by
comparing two wrappers, not read from its source. A line in the script's header says that a new pin
repeats that comparison, names and modes; FT3b holds what the script does in the program's place; and
F8 compares a wrapper made this way with one made with no other Wine open.

### 2.6 Slice I: a mod switched off by a new install (Surviving Mars)

**True**, from ML2, ML4 and P5 (the Surviving Mars plan's 1.4; the game's
`runs/findings-probes-20261114/notes.md`):

- Which mods are on is kept with the player's account. `account.dat` in the saves folder travels by
  Steam Cloud; it is a container the tools cannot read (it begins `BPUL`). Its size was once taken for a
  sign; P5 found sizes of 4,673 and 4,675 bytes together with the game's own warning that the mod could
  not be loaded, inside the range written down for "on". A size says nothing, and no design reads it.
- **A new prefix is not logged in to Paradox.** `[PdxSDK] Startup autologin failed NoSessionTokenFound`
  is in the log of every start in a new prefix (ML2, ML4, both of P5's). The game then asks "Account Link
  Found. Your Steam account is linked to a Paradox account. Do you wish to automatically log in to your
  Paradox account?" (James's capture, P5's second start). Until `[Braze] Deinit due to new user`, which
  the notes read as that login, no mod is fetched: P5's first start has no line about a mod at all. The
  mod's file came 1.5 to 2.3 s after that line: at 56.5 s (ML2), 22.9 s (ML4), 45.4 s (P5's second
  start).
- **The account file is written about 19 s after the game's start, with nothing clicked.** P5's first
  start: `Account storage loaded` at 16.4 s, and at 19 s the file pulled from the cloud (4,714 bytes)
  was replaced by one of 4,673 bytes. It was written again when the game's agreements were accepted,
  and Steam uploaded it at exit although no save had been loaded or made.
- **The game says it itself.** At P5's first start it showed "Warning. The following mods couldn't be
  loaded. Open the mod manager for more information: SMR_CommunityFixPack". That box stood behind the
  game's two agreements, which a new install asks for again, and its OK could not be pressed until both
  were scrolled to their end and accepted (James's capture; he has seen that layering three times).
- **A save loaded in that state runs without the mod, and is saved without it.** The game logs one of
  two lines when it loads a save that names a mod it has not loaded: `[mod] Savegame references Mod
  <title> (id <id>, <version>) which is not present` (the mod's file not yet on disk: ML2's and ML4's
  scratch sessions) and `[mod] This savegame tries to load Mod <title> (id <id>, <version>), which is
  present, but not loaded` (ML2's real session; that line goes on with tabs and `Lua <time>` and has no
  carriage return, so it is not matched at its end). A save that was already saved without the mod names it
  no longer, and its load logs nothing about it (ML4's real session).
- **The mod was loaded when the Mod Manager was opened.** At P5's second start: `[PdxSDKMods] Starting
  install of mod: <title>, version: 0, ModID: <number>` at 57.8 s, 12 s after the mod's file came; the
  mod's definition 1.4 s later; within 9 s the 44 "applied" lines and `Loaded mod items for: <id>`.
  James (2026-11-14): he clicked Mod Manager once in that start, after the game's warning, and "it all
  felt like native game interface menus, no errors or weird behaviors". So the warning came at the
  second start too. In the real wrapper's log of 2026-11-13 the same `version: 0` line stands at the
  moment he opened the Mod Manager there, with the "applied" lines 1 s after it. The log of P5's second
  start has one more such line, with `version: 17`, at 2 min 13 s, 9 s before the game was quit; one
  click and two lines fit the second being the mods window closed again, which was not asked.
- A prefix's own `AppData/Roaming/Surviving Mars Relaunched/LocalStorage.lua` is written 1 s after the
  game's first start. It gains `ModIdCache` (a mod's folder to its id) when the mod's definition is
  first loaded.
- "Mod Manager (1)" is on the menu in both states, so the number is no sign.
- The game does not go to a save by itself: it stops at its menu, where the player chooses Load Game
  and then a save (P4: James, with a capture of the menu). The Mod Manager is one click from that menu.
- One log names one mod three ways: a number (`Updated/installed mod 156049`), a title (`Relaunched Fix
  Pack`) and an id (`SMR_CommunityFixPack`). About half its lines end in a carriage return (101 of 204).
  It names the Windows user's folder once (`C:\users\<name>\...`).

**What cannot be done.** Nothing the installer or the launcher says can keep the new prefix's account
file out of the cloud: the game writes it before the menu can be used, and Steam uploads it at exit.
Holding back Steam's upload would hold back saves too. So nothing is built to prevent it, and no code
opens `account.dat` by name or looks into it.

**Design.** The launcher's part stands between markers (`# >>> mod-notes`, `# <<< mod-notes`), as its
update check does (`surviving-mars-relaunched/launch-relaunched.sh:278`), so that its test reads the
functions themselves.

1. **Before the first start.** When the prefix has no `LocalStorage.lua`, the launcher says, before its
   step 1:

   ```
   Before you load or continue a save in this new install: if you use mods from Paradox Mods, they start switched off. Accept the game's two agreements (scroll each to its end), log in to your Paradox account when the game offers it, then open Mod Manager from the main menu.
   ```

   It is one line in the script (272 characters). It is given as the cloud message is (`:409-411`):
   `echo`, and `_alert "<text>" warning` when `QUIET` is 1. It is not a `note` call, so the parity
   test's lists do not change: a notification, which is all `note` gives from the app (`:111-115`),
   shows two lines for a few seconds, and the progress window shows step lines only
   (`common/launch-progress.swift:38`). It comes after the lock is taken (`:184-185`) and before
   `step 1`, so nothing of Steam runs yet, and its text is in the app's log before the alert is up.
   `_alert` waits until it is answered. Unanswered, the launcher waits with the lock held, a second
   launch is refused as it is today, and the progress window closes by its own rule after 15 minutes
   without a new line (`common/launch-progress.swift:71`; its comment at `:65-66` about the longest
   silence is brought up to date). It comes once, at the first start in a prefix, and does not give up
   by itself (FD5, decided 2026-11-15).
2. **After the game exits.** The launcher reads the game's own log of this session:
   `drive_c/users/Wineskin/AppData/Roaming/Surviving Mars Relaunched/logs/Mars.exe-<date>-<time>-<n>.log`
   in the prefix, the one whose name's time is at or after the time the launcher noted before its step
   5 (P5: a start at 20:15:58 gave `Mars.exe-20261114-20.15.58-...`). With no such log it says nothing.
   Carriage returns are dropped from every line. For each of the game's two lines above it takes the
   title (the text between `Mod ` and ` (id `), keeps at most 60 printable characters of it, and says:

   ```
   This session loaded a save that uses the mod <title> while it was switched off: it ran without it, and anything saved in it was saved without it. Open Mod Manager from the main menu before you load a save again.
   ```

   Several mods are named with commas, three at most and then "and <n> more". In a terminal it is a
   `WARNING:` line; from the app an alert, by `_alert` and so as an argument, never as script source.
   It rests on the game's own two lines and on nothing else: a mod the player has switched off on
   purpose is never named. What it misses: a save that had already been saved without the mod
   elsewhere (ML4's real session), which no log can tell from a save that never used it.
3. **The installer's last lines** for this game, in `surviving-mars-relaunched/scripts/setup.sh`'s
   closing block (`:167-171`):
   `  If you use mods from Paradox Mods: at the first start, open the game's Mod Manager before you load a save.`
4. **The guide's paragraph** (`surviving-mars-relaunched/INSTALL.md`, "Good to know"), written again
   from what was seen: "**If you use mods from Paradox Mods.** A new install starts with them switched
   off, and through Steam Cloud they are then switched off on your other install too. At its first
   start the game asks again for its two agreements and for your Paradox account, and warns that the
   mods could not be loaded. Log in, then open Mod Manager from the main menu before you load or
   continue a save, here and then on your other Mac. A save loaded before that runs without its mods
   and is saved without them."
5. **A copy of the saves before the first start** (FD3, decided yes on 2026-11-15; this item and row
   FT4c were written that day and re-checked on their own). It is the one thing here that protects the
   save itself.
   - **When.** In a launch that found no `LocalStorage.lua` (the same look as item 1's, made once,
     before step 1), after the `esac` that closes the cloud check of step 3 (`:272`) and before step 4,
     so for each of the three answers that go on: up to date, failed, and nothing logged. Not earlier:
     before Steam's pull at sign-in a new prefix holds no saves, or old ones. When the cloud check ends
     the launch (a conflict, still syncing), no copy is made. After "failed", or when no sync was
     logged, the copy is of what this Mac holds, which may be nothing or a part: then no copy protects
     the save, and the launcher's own cloud note (`:270-271`) is the only word.
   - **What.** The folder `drive_c/users/Wineskin/Saved Games/Surviving Mars Relaunched` of the prefix,
     whole, when it is not a link (looked at first), is a folder, and holds at least one regular file
     anywhere under it (`find <folder> -type f`, which follows no link; the real folder's top level
     holds one folder and no file). It holds the saves and the account file as Steam pulled them. With
     no such folder, or none with a file in it, nothing is copied and nothing is said: a new player has
     no saves. The folder's name is never written with a slash after it: `cp` follows a link written
     that way (measured).
   - **Where.** `<state folder>/backup/first-start-<YYYYMMDD-HHMMSS>`. `mkdir -p <state folder>/backup`
     comes first (nothing else makes that folder in a new install); if it fails, that is the copy's
     failure. If either the name or the name with `.partial` exists already, nothing is copied: `cp`
     would copy into a folder that is there, and `mv` would move inside one (both measured). The copy
     is made by `cp -Rp -- <folder> <that name>.partial`, its output sent away (on a full disk `cp`
     prints the target's whole path and the numbered folder's name, which is the account's number, and
     the app keeps error output in its log), and renamed when `cp` has exited 0. `cp -R` copies a link
     inside the folder as a link.
   - **The words**, one line:
     `A copy of your saves as they were on this Mac before this install's first start: <the copy's whole path>`,
     the home folder as `~`, and the path as it is when the state folder is not under the home folder.
     It is an `echo`, so it is in the app's log; there is no alert for it. The numbered folder inside
     the copy is not named.
   - **When the copy fails** (a full disk): `WARNING: The saves could not be copied before this first
     start (<the .partial name, with ~>). The game starts all the same.`, what was copied is left as it
     is, and the launch goes on. From the app the line is in the log only: the note of item 1 has
     already said what to do, and a second alert before the game would be answered without being read.
   - **Once.** The look for `LocalStorage.lua` makes it once per install in the ordinary case: the game
     writes that file 1 s after its first start. A first launch that copies and then ends before the
     game has run (an update that does not finish) makes another copy at the next, of full size, under
     a new name; none is ever written over.
   - **Nothing restores it.** No script copies anything out of `backup/`, and the block writes nowhere
     but under `<state folder>/backup`. The guide says where it is and that putting a save back is
     done by hand, with the game and this wrapper's Steam closed; what Steam Cloud then does with it
     was not measured, and the guide says no more than that.
   - The account file inside the copy is copied with the rest and never opened by name or looked
     into: the folder is copied as a whole, and FT6's gate (no line names `account.dat`) holds.

**No live step.** A start from a new prefix on James's account uploads that prefix's account file once
more. The tests run on lines cut from the real logs of ML2, ML3, ML4 and P5 instead.

**The real wrapper's next start (2026-11-14, 22:10; its log read after the game was quit).** It was
the first start of the real wrapper after P5, whose second start had left the mod switched on in the
scratch install and uploaded the account file. The launcher's cloud line was "saves up to date" before
the game and "saves uploaded" after it. In the game's log:

- `Account storage loaded` at 13.427 s, the mod's definition at 13.440 s, the 44 "applied" lines, and
  `Loaded mod items for: SMR_CommunityFixPack` at 15.9 s. There is no `Starting install of mod` line in
  the whole session of 2 hours 2 minutes, so the Mod Manager was not what loaded it.
- `Load Game` at 20.4 s, with `mods: SMR_CommunityFixPack`, and neither of the game's two lines about a
  mod that is not present or not loaded.
- So the state travels both ways in the account file: switched on in the new install and uploaded at
  its exit, the mod was on in the other install at its next start with nothing clicked there. Seen
  once. The guide's "here and then on your other Mac" (item 4) stays as written: it is the form that is
  right whichever install was quit last.
- One line is new: `[PdxSDK] Startup autologin failed Unknown. Took 2031`, where each of the seven
  sessions of 2026-11-13 has `[PdxSDK] Started up` and `[PdxSDKMods] Mod <number> v 17 is up to date`.
  This session has no `[PdxSDKMods]` line at all. The mod loaded all the same, from the file already in
  the prefix. Why the log-in failed is not known. Two things differed from the day before: the scratch
  install had logged in to the same Paradox account earlier that evening ("Account Link Found"), and the
  VPN was on again. Whether the game showed anything about the account at this start has been asked of
  James and is not answered yet.

### 2.7 Slice J: runtimes the new prefix lacks

Nothing is built. A prefix made by the installer has none of the Visual C++ runtimes, `d3dcompiler_47`
or fonts the first wrapper holds, and the game ran in it through a session of 8 minutes (ML4). If longer
play fails for a missing runtime, its source and licence are a decision of their own.

### 2.8 Slice K: two lines that say something untrue

- `surviving-mars-relaunched/scripts/setup.sh` ends with "The game: <app>, also in Spotlight and
  Launchpad" for any app path. That holds only for an app in `~/Applications` or `/Applications`. The
  clause is printed only then.
- After a Mac check that exits 3 (an Intel Mac, a macOS below 14) the core's closing line is "The install
  stopped. The lines above say why. Open the installer again to carry on from that step."
  (`common/install-core.sh:253`, `:74`). Opening it again cannot help. For setup's exit 3, and for
  that code only, the core sets `END=quiet`: setup's own words have said why. Its own line "!! the check
  of this Mac failed (exit 3)" and its exit 1 stay (`surviving-mars-relaunched/scripts/test-install.sh:306-307`
  asserts both). The refusal to install Rosetta (`:250`) keeps its closing line: there, opening the
  installer again does help. Cities: Skylines II's setup never exits 3 from
  `--mac-only`, so its recorded transcript does not change.

### 2.9 Slice H: a line of bash's in the installer's output

**True, from probe P3 (done 2026-11-13; records in the game's `runs/p3-setpgid-20261113/`).** The core
starts Steam with job control switched on for one line, so that Steam gets a process group of its own
(`common/install-core.sh:147-151`). Those lines, with a stub as the program, printed bash's
`child setpgid (<n> to <n>): Operation not permitted` in 4 of 3,200 starts with no terminal, and in 0 of
3,200 under a terminal. The line is written by the forked child before its own redirections take effect,
so it goes wherever the installer's error output goes. With the whole block's error output sent to
`/dev/null` at the outer level it was printed in 0 of 6,400 starts, with and without a terminal; that
part holds by construction, since the child inherits the redirected descriptor. Why the call is refused
was not found. That a player in a Terminal window cannot see the line is not shown, only not seen
(0 against 4 of 3,200 is a small difference).

**Design.** `start_steam`'s three lines stand inside `{ ...; } 2> /dev/null`. Nothing else of the
installer's output is lost by it: the three lines print nothing of their own, and Steam's output already
goes to `/dev/null` (what it does hide is bash's own word if the start itself fails; the five-tries
message then stands alone). Its test is in two parts, and they are not the same kind. The gate is a
source test: the braces' form is there, and the redirection is on the braces, not on the child's line.
Its mutants turn it red every time. The other part is a watch, not a gate: 30,000 starts of the core's
own function with a stub program and input and output redirected (about 25 s) print nothing. Under the
mutant it is not required to turn red: the rate moves with the Mac's load (4 in 3,200 at P3 with a game
running; at the check, 1 in 3,000, and 0 in 9,000 in the builder's runs), so a green run under the
mutant proves nothing and is not counted as a mutant seen red. The transcript of Cities: Skylines II's
installer needs no change.

### 2.10 Slice B: Steam's updater on screen

**True, from probe P1 (2026-11-14; the game's `runs/findings-probes-20261114/`, `notes.md`).** Four
first starts of a Steam that Valve's installer had just put into a new prefix, each in a prefix of its
own, with the launcher's environment and the VPN paused:

| Start | On screen | Client up |
|---|---|---|
| as the installer starts it (`-no-cef-sandbox`) | a window "Steam", 394 by 129, for 51 s, then "Sign in to Steam" | 49 s |
| with `-silent` | the same window for 49 s, then the sign-in window | 50 s |
| with the update files of another prefix's `package/` folder copied in (247 MB) | the same window for 47 s, then the sign-in window | 49 s |
| both | the same window for 46 s, then the sign-in window | 48 s |

The small window is Steam's updater: "Updating Steam...", a bar, "Downloading update (267,963 of
336,229 KB)..." and a Cancel button; the window's own title is "Steam". With the files copied in its bar still read 297,226 of 324,932 KB. No "Fatal
Error" box came and no fatal line was logged in any of the four; all four came up in one start. Not
tried: Steam's own switches for skipping its update, and hiding a window by Wine's means.

**Design.** Neither way hides the window, so the installer names it, where it already names the error
box (`common/install-core.sh:349-350`). The lines are printed whenever Steam is not yet up, on a later
run too, and the core may name no size (its header, `:5-6`; `cities-skylines-2/scripts/test-install.sh`
holds the gate), so they give neither a size nor a time:

```
  Steam for Windows is starting. The first time, a small window that says "Updating Steam..." shows
  Steam downloading its own update: leave it, and do not press its Cancel. A box headed
  "Steam - Fatal Error" can also appear once or twice and close again: click nothing in it.
```

Step 3 of each guide's quick way gives the size: "Before the sign-in window, a small window that says
"Updating Steam..." shows Steam downloading its own update (about 330 MB): leave it, and do not press its
Cancel. A small box headed "Steam - Fatal Error" can also appear once or twice and close again: nothing
in it needs a click. If the installer stops there and says Steam could not download its own update, do
what it says and paste the line again." Nothing else is built: the window is Steam's, it closes by
itself, and what goes wrong behind it is slice A's.

## 3. Probes (all done)

Each is recorded in a run folder of the game it concerns, with a `notes.md`. None changed the real
wrappers. P1, P2 and P5 started Wine or Steam, and were done in one sitting on James's word, on
2026-11-14, with nothing else of Wine running at its start and the VPN paused. They departed from the
rows below in six ways: P1 had a fourth start (`-silent` with the files copied in); P2's other Wine was
P5's scratch game, not this project's Steam app; P2's (a) ran with no other Wine open, since the game
had just been quit, so the wait itself was not timed again (ML2's 85 minutes stand for it); (c) was
ended after 10 s without change, not on a log line; Steam's installer was run in the result of (c),
since (b) was not the same prefix; and P5 started the game twice, because the first start was quit 4 s
after the game's agreements. P3 departed too: the 30 runs of the test were not made, and the starts were
3,200 each way.

| # | Question | How | Needs |
|---|---|---|---|
| P1 (done 2026-11-14: 2.10) | Can Steam's updater and its error box be kept off screen in a new prefix? | A scratch wrapper with Steam's installer run and Steam never started. Started once each way with the launcher's environment: plain, `-silent`, and with the update files already in place from a copy of another prefix's `package/` folder. Recorded with a capture of the Steam windows' region only: what appears, and whether the client comes up | Wine; no sign-in |
| P2 (done 2026-11-14: 2.5) | Can the prefix be made without the template's wait, and is it the same prefix? | With another Wine open (this project's Steam app), in a scratch folder: (a) the template's program, timed, as the control; (b) `wineboot -u` of the engine in a prefix folder made by hand, then what the template's program adds found by `diff -r` of the two prefixes and of the wrapper's `Info.plist`; (c) the template's program ended once the prefix is complete (its log line, or `system.reg` present and `wineserver -w` returned for that prefix). Then Steam's installer run in the result of (b) | Wine; another Wine open on purpose |
| P3 (done 2026-11-13: 2.9) | Why does bash print `child setpgid (...): Operation not permitted`, and can a player see it? | `cities-skylines-2/scripts/test-install.sh` run 30 times, counting the runs that hold the line; then `start_steam` (`common/install-core.sh:147-151`) in a ten-line script of its own, 200 times each: with and without a terminal, and with the block's error output sent to `/dev/null` at the outer level. No Wine: a stub program | nothing: can run at any time |
| P4 (done 2026-11-13: 2.6) | Does the game go to the last save by itself at its start? | James is asked. If he does not know: one start of the real game with nothing pressed for two minutes, and the log read after exit | James |
| P5 (done 2026-11-14: 2.6) | When is the switched-off account file written: at the menu, at the load of a save, or at exit? | In a scratch prefix signed in with James's account, under ML2's steps 1, 5, 6 and 9: the size and time of `account.dat` read every second from the start; quit at the menu with nothing loaded. It uploads a switched-off file once more, so James opens the Mod Manager in the real game afterwards | Wine; James's sign-in; his word |
| P6 (done 2026-11-14: 2.3) | Does Surviving Mars's new wrapper show the macOS 28 notice? | James is asked what he saw at ML4; else it is looked for at the next wrapper made | James |

## 4. Steps

- **F0. The probes of section 3.** All six are done, their results are in section 2, and slices B, G
  and I are designed from them. The plan was checked on 2026-11-14 and the fold re-checked the same
  day.
- **F1. Slice A** in `common/install-core.sh` (2.1), and its sentence in both guides. The existing case
  in which "needs to be online" simply restarts (`cities-skylines-2/scripts/test-install.sh:417-422`)
  is changed on purpose, and the test's `curl` stub is extended (section 5).
- **F2. Slices C and D** (the core, `common/make-wrapper.sh`, both guides).
- **F3. Slice G** in `common/make-wrapper.sh` (2.5), with the stubs its test file lacks.
- **F4. Slice H** (2.9).
- **F5. Slice I** in `surviving-mars-relaunched/launch-relaunched.sh`, the closing line in
  `surviving-mars-relaunched/scripts/setup.sh`, and the guide's paragraph, with the copy of the saves
  (2.6 item 5, FT4c) and one sentence about it in the guide.
- **F6. Slice K** (2.8).
- **F7. Slice B**: the core's three lines and step 3 of each guide (2.10).
- **F8. Live, on James's word, each into a scratch wrapper** (the real ones exist, so the installer
  would find nothing to do):
  - **Slice A**, with the VPN on. First one transfer of a package's address by `curl`: if it is not cut
    (18, 56 or 92), the step is VOID that day and is tried on another of the VPN's servers. Pass: the first
    form's three lines and the log's line, once; one start of Steam (Steam's `bootstrap_log.txt` gains one
    `Startup - updater built` line in the run: ML2's failed start logged one, and a start that works
    logs three, one for each updater in turn); exit 4; no Steam left running. Then, with the VPN paused, the same command goes on to Steam's sign-in window.
  - **Slice G**, with this project's Steam app open. Pass: the wrapper is made within two minutes; the
    one line is said; none of the six links is in `users/Wineskin`; Steam's installer exits 0; the Steam
    app is still open; and the wrapper's list of names and modes is that of one made the same day by
    `common/make-wrapper.sh` alone with no other Wine open. Aside: the wrapper's name, times, the
    randomly named installer file, everything Steam's installer added, and the modes of the three
    registry files (Wine writes them again with 644: 2.5). The run then stops at the game step with "Steam is open in ..." and exit 3
    (`common/install-core.sh:338-343`), which is the expected end.

The recorded transcript of Cities: Skylines II's installer changes in F1 (cases changed and added), F2
(cases added) and F7 (the two lines before Steam's start, in all 29 places): each time it is recorded
again on purpose and the difference is read line by line. Its header's sentence about the commit it was
recorded at is brought up to date.

The work is done on a branch cut from `surviving-mars-install`, itself cut from `simple-install`. It
reaches `main` after the two under it, each merge on James's word.

## 5. Test plan

Every test runs with `HOME` at a scratch folder and every outside program a recording stub, as the two
`test-install.sh` files do. Each mutant is applied to the real source, seen red, and removed. Besides:

- **No test waits for real.** Every wait is counted in looks, the count is a variable at the head of the
  script, and a test rewrites it or meets it with the stub `sleep`.
- **No real process is signalled, and none is read.** `pgrep`, `lsof`, `route`, `sw_vers`, `killall` and
  `pkill` are stubs in every file that needs them (`common/test-make-wrapper.sh` has none of them today,
  and `route` is in no file): without them a test reads the developer's own VPN and Wine. A process that
  stands for another program is one the test starts itself (`/bin/sleep`).
- **No test follows a link out of its scratch folder.** Where the script removes links, each link's
  target is a scratch folder holding a file, and the file must still be there.
- **The shared core is tested in the Cities: Skylines II file**, which has Steam's starts, its log and a
  `curl` stub. F1 extends that stub: by a setting it exits with a given code and prints a byte count for
  `-w` (today it reads `-o` only). The Surviving Mars file has none of that today, and gains nothing for
  slices A, B and C.
- **Fixtures cut from the game's logs** are the marker lines only, with the Windows user's folder name
  and the machine's lines replaced; they are named `.txt` (`*.log` is ignored, `.gitignore:46`); the
  test puts the carriage returns back, since the repository stores none.

| # | Test | What it shows | Mutants, each must turn it red |
|---|---|---|---|
| FT1 | `cities-skylines-2/scripts/test-install.sh`, with the 37 real `Add pending download:` lines of ML2's failed start, carriage returns kept | "needs to be online": that Steam is ended and no other started before the transfer. The address is the largest of the lines after this start (not the first, not one from before it), its carriage return gone; the options are 2.1's. No address, or one that is not `https://<host>.steamstatic.com/client/...`: `curl` is not run. Cut (18; 56; 92) with a tunnel: the first form; with no tunnel, or with `route` failing: the "in a few minutes" line and no word of a VPN. No network (6; 7): its form. In those: no further start, exit 4, the log's line with `~`, no line of Steam's log, and the core's closing line for 4 absent. Working (exit 0 with 20,000,000 bytes; exit 28 with 20,000,000) with a tunnel: another start; when that one comes up, no words at all; when the four starts that are left all end in a fatal line, the "although" form, exit 4, no word of a VPN. Exit 28 with 19,999,999 bytes, exit 0 with 5 MB, exit 22: not known, another start; the four starts that are left all ending in a fatal line give the plain form. Both fatal lines new in one look: "needs to be online" is acted on. A larger address outside the pattern beside a smaller one inside it: the inside one is used. "Failed to determine download location" restarts up to five times, with no transfer. An old "needs to be online" line in the log and a start that works: no transfer. A Steam that comes up is never followed by a transfer or a word of a VPN. Five starts ended some other way: today's words and twenty lines, exit 1 | the transfer skipped and Steam started again; a start made before the transfer; the first address used; the largest chosen before the pattern is applied; the count of starts begun again after the transfer (six starts); an address from before this start; the carriage return left on; an address outside the pattern passed to `curl`; `--max-time` removed; `-f` removed; the VPN sentence with no tunnel; the VPN sentence when the transfer worked; exit 0 with 5 MB counted as working; 28 with 19,999,999 counted as working; no restart when the transfer works; the restart removed for "download location"; the transfer made before any failure; the log's lines printed in these forms; exit 1; the closing line for 4 printed; the path with the home folder; Steam left running at exit 4 |
| FT2 | `cities-skylines-2/scripts/test-install.sh` | the first address of Steam's installer failing with words on its error output and the second working: none of those words on screen (the stub's words are switched on by a setting, so the existing case's transcript stays); both failing: the installer's sentence, then both tries' words indented under it | curl's words printed when the second address works; nothing printed when both fail |
| FT3 | `common/test-make-wrapper.sh`, with a `sw_vers` stub | on 27 the two lines are printed once, before "making the Wine prefix"; on 26, on 28 and with a version that cannot be read: not printed | the lines on every macOS; the lines after the prefix step |
| FT3b | `common/test-make-wrapper.sh`, with a stub in the template's place that makes the prefix's files, the Mac Driver section and the six links, each to a scratch folder holding a file, and then waits | with another `wineserver` (a `/bin/sleep` the test starts, named by the `pgrep` stub): the stub is ended once the prefix has stood still for the set looks; each of the six links is gone, by name; each link's target still holds its file; the three registry files and `Info.plist` have mode 666 and `Logs` 777; the one line is said; no line holds "Terminated"; the wrapper is moved into place; the stand-in process is still alive. A folder named `Documents` that is not a link is left. Not ended: with no other `wineserver`, however long the stub takes; with `system.reg`, `user.reg` or `userdef.reg` missing, `users/Wineskin` a link, or no Mac Driver section; while the prefix still grows; while a `wineserver` holds this prefix, another running beside it; when `lsof` fails; when the other `wineserver` goes away during the still looks (the stub then finishes by itself: no line, exit 0). A build folder reached through a link is matched. The stub exiting 1 by itself with another Wine open: the step fails as today. The stub ignoring TERM: the step fails, and `cleanup` ends it. The script interrupted during the step: no stub left running, the build folder gone. `pgrep` is asked for this user's processes only (`-U`). The file's existing cases pass with a real Wine open on the Mac | ended with no other `wineserver`; a link left; the removal with a slash after the name and `-r` (the target's file is gone); a real folder removed; the modes not set; ended before `system.reg` is there; the Mac Driver section not asked for; the stillness not waited for; the check that no `wineserver` holds this prefix removed; an `lsof` failure read as "holds nothing"; the other Wine closed by the script; the redirection taken off the group that ends the program; the program not ended in `cleanup`; the exit code of an ended program read |
| FT3c | `cities-skylines-2/scripts/test-install.sh` and its transcript | the lines before Steam's first start name the "Updating Steam..." window and its Cancel, and the error box, and no size | the old two lines (added to the mutants that are compared with the transcript, `:519`); a size in the lines (the existing gate) |
| FT4 | `surviving-mars-relaunched/tools/test-mod-notes.sh`, new, reading the launcher's marked block | **The note:** with no `LocalStorage.lua` it is given once, after the lock is taken and before step 1: printed in a terminal; with the app's settings printed first and then one `display alert` to the recording `osascript`; with the file there, not at all. **After exit**, on fixtures: ML2's and ML4's scratch sessions ("which is not present"): the title named; ML2's real session ("present, but not loaded"): named; ML4's real session (definition, load, items after, neither line): no words; ML3's (items before the load): no words; P5's two (no load): no words; a load with no mod at all (ML3's, its mod lines cut): no words; two mods in the game's lines: both named once; four: three and "and 1 more"; a title with `"`, `\`, `$(...)` and an escape character: carried as it is, cut to 60 printable characters, nothing run, one argument to the alert; lines with and without carriage returns give the same; a log whose name is older than the launch: no words; no log, no log folder: no words and no failure. The words go to `_alert` from the app and to a `WARNING:` line in a terminal | the note on every start; the note as a notification; the note before the lock; the note after step 1; the note not printed before its alert; "present, but not loaded" not looked for; "which is not present" not looked for; a session with neither line named; the title placed in the script's source; the newest log read whatever its time; a missing log stops the launcher |
| FT4c | `surviving-mars-relaunched/tools/test-mod-notes.sh`, with `HOME` at a scratch folder and the state folder under it, a space in its path; `cp` and `date` are called by their bare names, so stubs first on `PATH` stand in for them where a case needs one | With no `LocalStorage.lua` and a saves folder whose top level holds one numbered folder and no file, that folder holding two files and a link, and the state folder holding no `backup` yet: one folder `backup/first-start-<stamp>` whose files are those, byte for byte, the link copied as a link; the source unchanged; no `.partial` name left; the one line, with `~`, without the home folder's path and without the numbered folder's name; the scratch tree outside `backup` is the same before and after. In the launcher's own lines the copy stands after the `esac` of the cloud check and before `step 4`, and in no arm of that `case`. With `LocalStorage.lua`: no copy, no line. No saves folder; one with folders and no file; one that is a link to a folder holding a file: no copy, no line, and the link's target untouched. `cp` failing (a stub that makes the folder, prints the target's path and the numbered folder's name on its error output, and exits 1), run in a subshell with a line after it: the `WARNING:` line with the `.partial` name and `~`, the line after it reached, the `.partial` name left, no final name, no line of output holding the home folder's path or the numbered folder's name, no alert asked of `osascript`. `backup` impossible to make (a file of that name): the `WARNING:` line, the launch goes on. The final name there already (the stamp fixed by a `date` stub): nothing copied, nothing inside it changed; the `.partial` name there already: the same | the copy on every start; the copy before the cloud check; the copy only in the arm for "up to date"; the saves moved instead of copied; a saves folder that is a link followed; a failed copy stops the launch; a failed copy renamed to the final name; the home folder's path in the line; an existing copy written over; the `mkdir` removed; `cp`'s output not sent away; files looked for at the top level only |
| FT4b | `common/test-start-steam.sh`, new | the gate: `start_steam`'s lines stand in braces whose error output is sent away, and the child's own line is as before. The watch: 30,000 starts of the core's own function with a stub program and input and output redirected print nothing, and a line printed fails the file | the braces' redirection removed; the redirection moved onto the child's line: the gate, each time. The watch is not counted (2.9) |
| FT5 | `surviving-mars-relaunched/scripts/test-setup.sh`; `surviving-mars-relaunched/scripts/test-install.sh` | "also in Spotlight and Launchpad" for an app in `~/Applications`, and not for a scratch app; `/Applications` at the level of the function that decides it. After a Mac check that exits 3: the core's line "the check of this Mac failed (exit 3)", exit 1, and no "Open the installer again" line; after the refusal of Rosetta the closing line is still there. Cities: Skylines II's transcript is unchanged, and no case is added there. The installer's line about mods is in setup's closing block | the clause for a scratch app; the closing line put back; the closing line dropped after the Rosetta refusal too |
| FT6 | the gates: `common/check-links.py`, `common/check-identifiers.sh` at its residual with the fixtures staged, `cities-skylines-2/scripts/check-experiments.py`, `bash -n` on every script, `common/test-launcher-parity.sh` unchanged, and a source gate that no line of `surviving-mars-relaunched/launch-relaunched.sh`, `scripts/setup.sh`, `scripts/install.sh` or `common/install-core.sh` names `account.dat` outside a comment (the launcher names it in two comments today; three test files hold it in fixtures) | no dead link, no identifier, the ledger whole, the two launchers' shared blocks still alike, the account file untouched | a line of the launcher that reads `account.dat` |

The guides' sentences (slices A, B, D and I) have no test of their own beyond the link check: they are
read against the installer's lines at F8.

## 6. Exit criteria

- The six probes are recorded, and slices B, G and I are designed from them.
- The plan was checked after the probes, its fold was re-checked, and its verdict line is dated.
- F1 to F7 are committed, or recorded as waiting for a decision that is named; FT1 to FT6 pass; every
  listed mutant was applied and seen red (FT4b's watch is not a mutant, and the plan says so).
- F8 passed in both halves, as section 4 states them, or its slice A half is recorded VOID with the
  reason.
- The rows SF1 to SF9 and MF1 to MF4 each say, where they are recorded, which slice built them or why
  not. SF7's says that it waits for a plan of its own.
- Slice I has no live step (2.6), and the fact still owed to its section is in it.

## 7. Rollback

- Every change is to the installers, the launcher's words and the guides: a revert of the commit puts the
  old behaviour back, and no prefix or save is changed by any step. The launcher's copies of the saves
  (2.6 item 5) stay under `backup/` after a revert; they are removed by hand.
- P5 (done) and F8 start Steam on James's account from a scratch prefix; ML2's steps 1, 5, 6 and 9 (the
  Surviving Mars plan) keep that safe and name the way back.
- P2 made prefixes in scratch folders only; they are in the Trash.
- Slice G changes how a wrapper is finished only while another Wine is open. A wrapper made that way and
  found wrong is moved to the Trash and made again with every other Wine closed.

## 8. Decisions, each James's

FD3, FD4 and FD5 were decided on 2026-11-15: asked whether he took them as recommended or wanted to go
through them one by one, James answered "Complete as much as possible", which was read as the first.
Each is a matter of words or of one copy, and a revert puts the old state back (section 7).

| # | Decision | Recommendation |
|---|---|---|
| FD1 | A run in which the only problem is a fix not yet available for a new game build: exit 0 or 1 | Goes with slice F's own plan (2.4). Whichever it is, the core's "Done. Start the game" must not stand under "a fix is not yet available" |
| FD2 | If the game goes to the last save by itself (P4): what then | Not needed: P4 found that it does not |
| FD3 | Whether the launcher keeps a copy of the saves folder before the first start in a new prefix | **Decided 2026-11-15: yes** (2.6 item 5). Yes: it is small (about 250 MB for James's eight saves), it is the way back the guide can point at, and it is made once per install. Never restored by a script |
| FD4 | Slice A's four new word forms (2.1, step 4): cut with no tunnel, no network, "although this Mac reaches Valve's server", and the plain form; and the log's line | **Decided 2026-11-15: as written.** The first form is the one already agreed |
| FD5 | How long the note before the first start keeps coming, and whether its alert gives up by itself (2.6, item 1) | **Decided 2026-11-15: as recommended.** Once, at the first start in a prefix, and it waits until it is answered: it is the one message that must be read, and nothing of Steam runs while it waits. The other way for the second half is an alert that goes away after a time, as the update question's does. It misses a first start that is quit before the Paradox login, as P5's was; the game's own warning and the words after exit cover that. The other way, every start until a save has been loaded in this install, shows it again and again to a player with no mods |
| ND1 | The app is published, or only the pasted line (the installer plan's; slice E waits for it) | open |

## Review corrections (triple-check 2026-11-14)

Pass 1: six lenses on Fable, each against the branch's code (`283a464`) and the run records, none
editing: architecture, safety, correctness, test plan, the words with the platform's facts, and a
builder that built slices G, A, I, H, B, D, C and K in a scratch worktree with their tests (21 files;
30 mutants applied, 27 seen red). Every lens: build-ready-with-fixes. Each blocker was read against the
source before it was accepted. What changed:

| # | Finding | Lens | Where it is folded |
|---|---|---|---|
| X1 | **Blocker.** "Steam needs to be online" was taken for a cut path that a restart cannot cure; the installer plan's own probe has it cured by a second start (1 of 3) | architecture | 2.1: both lines keep their restart; a transfer decides, and only a cut or no network stops the run; FT1 |
| X2 | **Blocker.** Every line of Steam's log ends in a carriage return, so the address as designed is refused by `curl` and every run is "not known" | words, safety | 2.1 "What Steam's log gives", step 2; FT1's fixture and mutant |
| X3 | The first address is a 5.6 MB file, which passes whole on a path that cuts later; "28 with 20 MB" could never be reached | safety, correctness, test plan, builder | 2.1 step 2: the largest; FT1 |
| X4 | The transfer's options, the address's check, what counts as working, an offline Mac told its connection "keeps being cut", the VPN named when nothing was measured, the closing line said twice | safety, words, architecture | 2.1 steps 2 to 6; FD4 |
| X5 | **Blocker.** The six links point at the player's real folders; no command form was given, and no test looked at the targets | safety (form measured by the words lens) | 2.5 "Then what the program does"; FT3b |
| X6 | Slice G: the exit code of an ended program, a program left running on Control-C or failure, the 180 s limit against "however long", conditions that pass when `lsof` fails, no sign that the second Wine step ran, bash's "Terminated" line, `pgrep` seeing other users | architecture, safety, words, builder | 2.5 design, "Ending it", "The script's own exit"; the limit is dropped; FT3b |
| X7 | Slice G's comparison held three paths' modes only | safety | every entry's mode compared the same day (`p2-compare.txt`): `Info.plist` and `Logs` too; 2.5; F8's comparison |
| X8 | **Blocker.** Slice I's rule joined a mod's number to its id, which the log does not do in one line; a healthy first install would be named | correctness, test plan, builder, words | 2.6 item 2: the game's own two lines only, by title; nothing is joined |
| X9 | "Present, but not loaded" begins `This savegame tries to load Mod`, not as the plan wrote it; half the log's lines end in a carriage return; the log names the Windows user; `*.log` is ignored | test plan, builder, safety | 2.6 "True", item 2; section 5's preamble; FT4 |
| X10 | **Blocker.** From the app the first-start note was a notification: two lines for a few seconds, the instruction at its end | words, architecture, correctness | 2.6 item 1: an alert, the instruction first; FT4 |
| X11 | "The game's newest log" had no path and was not tied to this session | architecture, safety, builder | 2.6 item 2 |
| X12 | Slice I: two versions of the note and of the rule; timings without a source (17 s, 23 s); a heading that called a line the Mod Manager's; "in the order it comes" | correctness, words | 2.6 written once; "True" corrected from the logs |
| X13 | **Blocker.** Slice B's words name a size, which the core's own gate forbids; "about a minute" is this Mac's line; the lines print on later runs too | builder, words | 2.10: no size or time in the core's lines, the size in the guides |
| X14 | **Blocker.** Slice F had no test, and rests on telling "no pattern" from a failure, which no patch script can report | test plan, architecture, correctness, words | 2.4: not built from this plan; F6 is slice K alone; FD1 goes with it |
| X15 | The macOS notice: two inferences written as findings (which start drew it; which name it shows) | correctness, words | 2.3 |
| X16 | FT4b's "red about 98 in 100": the rate moves (1 in 3,000 and 0 in 9,000 at the check) | test plan, builder, correctness | 2.9: a gate and a watch; FT4b |
| X17 | Tests would read the developer's own VPN and Wine, wait for real, and one mutant could signal a real process; two mutants could not turn red; an equivalent mutant | test plan, safety, builder | section 5's preamble; FT1, FT3b, FT4 rewritten |
| X18 | The transcript is recorded again in F2 and F7 too; the existing case at `:417-422` is reversed; the Surviving Mars test file has no Steam to test the core with | test plan, builder, architecture | section 4; section 5's preamble |
| X19 | Slice K: which line and exit code stay after exit 3, and the Rosetta refusal | architecture, safety, builder | 2.8; FT5 |
| X20 | F8: no scratch wrapper named, no instrument, slice G's half missing from the exit criteria, the VPN may not cut that day; the merge path | test plan, architecture | section 4 (F8, the last paragraph); section 6 |
| X21 | Smaller: F4's "as P3 decides"; "departed in four ways"; 1,793 files under `drive_c`; the capture's 324,932 KB is a total; the window's title is "Steam" | correctness | 4, 3, 2.5, 2.10 |

Rejected, with the reason: a time limit on the prefix step (today's step has none, and nothing was
measured that sets one); naming the VPN whenever a tunnel is the default route and the result is not
known (James agreed to the words after a transfer that failed, not before); a rule that names a mod
whose definition is loaded and whose items are not (it would name a mod switched off on purpose at
every exit).

Not settled by this pass, and said where it stands: why the real wrapper's log-in to Paradox failed at its
next start (2.6; that start, and James's answer about the Mod Manager, came after the pass and are in
2.6); what macOS 26 shows (2.3); whether a notification's length was measured
(it was not: the note is an alert instead).

### Fold check (pass 1b, 2026-11-14)

One agent on Fable, briefed on the fold alone: every row X1 to X21 against the normative text, the stale
looked for, each new claim opened in the source, and the removal loop and the ending of a program run on
scratch. All 21 rows had landed; nine defects were the fold's own, none needing a design reworked. Each
is folded:

| # | Finding | Where it is folded |
|---|---|---|
| Y1 | The address pattern required `/client/`, which 14 of 35 addresses of a working start lack, the largest among them; lines with no number had no rule | 2.1 "What Steam's log gives", step 2; FT1's case and mutant |
| Y2 | "Five fatal starts follow" after a start already used is six; the count of starts was local to one call | 2.1 step 1; FT1 |
| Y3 | "Ending it" could not pass its own two cases: a `wait` at once blocks for ever on a program that ignores TERM, and a `wait` after the looks lets bash print its line first (measured) | 2.5 "Ending it", "The script's own exit"; FT3b's mutant |
| Y4 | The alert before step 1 had no place and no behaviour when unanswered | 2.6 item 1; FT4; FD5 |
| Y5 | The note is no longer a `note` call, yet F5 and FT6 still changed the parity test's list; the note is 272 characters, not 262 | 2.6 item 1; F5; FT6 |
| Y6 | FT6's new gate on `account.dat` was red before any change (three test files hold the name) | FT6 |
| Y7 | F8's comparison could not be met: Steam's installer adds 43 entries and Wine rewrites the registry files' modes | F8 |
| Y8 | FT4's mutant "the carriage return kept in the title" was equivalent | FT4 |
| Y9 | "A `curl` stub that answers `-w`" is not true of the test file | section 5's preamble; F1 |
| Y10 | Smaller: bash's line holds the script's path, not the build folder's; two patch scripts finish without error on a missing pattern; the second game line's tail; "one decision" for slice I; 18, 56 or 92 in F8; how one start is read at F8; "One line" over two; the loop's and `chmod`'s status; the Mac Driver sign is inferred, not timed; `-U` and "both lines in one look" had no case; an offline Mac may log no address | 2.5, 2.4, 2.6, section 1, section 4, 2.3, FT3b, FT1, 2.1 |

Not measured at either pass, and said where it stands: `curl`'s exit 3 on an address with a carriage
return and its 92 (from the lens's run against a test server and from its documentation); an alert
standing above the progress window (AppKit's levels say so; not seen on screen).

### Fold check of the saves copy (2026-11-15)

FD3's design (2.6 item 5) and row FT4c were written after the check, so one agent on Fable, not editing,
checked that fold alone against `surviving-mars-relaunched/launch-relaunched.sh` on the build branch
(`d9fdac8`), with `/bin/cp` and `mv` run on scratch folders. Verdict: build-ready-with-fixes. The blocker
was read against the launcher before it was accepted. Each is folded:

| # | Finding | Where it is folded |
|---|---|---|
| Z1 | **Blocker.** Nothing makes `backup/` in a new install (the launcher makes `runs/` only, later; setup makes neither), so every copy would fail, with a line in the log only | 2.6 item 5 "Where"; FT4c's case and mutant |
| Z2 | On a full disk `cp` prints the target's whole path and the numbered folder's name, and the app keeps error output in its log | "Where": the output sent away; the warning names the `.partial` path with `~`; FT4c |
| Z3 | "Holds at least one regular file" did not say where: the real folder's top level holds a folder and no file | "What"; FT4c's fixture and mutant |
| Z4 | When no sync is logged the pull may not have begun; the copy then finds nothing and the once-rule is spent. The line said more than is known after "failed" | "When"; the line says "on this Mac" |
| Z5 | "Once": a failed sign-in ends before the copy, so it was the wrong example | "Once" |
| Z6 | `cp` follows a link written with a slash; into an existing `.partial` it copies inside; `mv` onto an existing folder moves inside (all measured) | "What", "Where"; FT4c |
| Z7 | FT4c: the place needed a gate that an arm of the `case` cannot pass; no way to fix the stamp; a `return 1` stops nothing under `set -u` alone, so "stops the launch" must be tested in a subshell; "only write target" had no method | FT4c |
| Z8 | Smaller: section 7 said every change is words; "nothing reads `account.dat`" (`cp` reads its bytes); `~/Library/.../` read as literal | section 7; 2.6 "What cannot be done"; "The words" |

Reasoned and not measured: how early the "nothing logged" answer comes; two wrappers sharing one state
folder in the same second.

## Review log

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-14 | 1 | architecture, safety, correctness, test plan, words and platform facts, builder simulation | six agents, none editing; the builder in a scratch worktree with the tests run; blockers read against the source inline | Fable 5.2 | `surviving-mars-install` at `283a464` (the cited files as at `75470c9`) | build-ready-with-fixes, folded |
| 2026-11-14 | 1b | the fold of pass 1 | one agent, not editing; scratch runs of the removal loop and of ending a program | Fable 5.2 | the same | build-ready-with-fixes, folded |
| 2026-11-15 | 1c | the saves copy (2.6 item 5, FT4c), written after the check | one agent, not editing; `cp` and `mv` run on scratch folders; the blocker read against the launcher inline | Fable 5.2 | `first-run-findings` at `d9fdac8` (the launcher as at `283a464`) | build-ready-with-fixes, folded |

Key paths: `common/install-core.sh`, `common/make-wrapper.sh`, `common/test-make-wrapper.sh`,
`cities-skylines-2/scripts/` (`test-install.sh`, its transcript), `surviving-mars-relaunched/`
(`launch-relaunched.sh`, `scripts/install.sh`, `scripts/setup.sh`, `scripts/test-install.sh`,
`scripts/test-setup.sh`, `INSTALL.md`), `cities-skylines-2/INSTALL.md`,
`common/test-launcher-parity.sh`.
