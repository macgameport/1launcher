# Runbook: a graphics-settings series on one Mac

> **Verified against:** game 1.6.4f1 (build 26404411), the Mac Studio (M5 Max, macOS 27.2, Studio Display,
> Wine 11.16 + DXMT), 2026-11-25. On the MacBook it has not been run: its section below says what is expected
> there and what is not known.

What this measures: how each graphics setting of Cities: Skylines II moves the frame rate of the game's own
benchmark on one Mac, and how hard the edges in the picture are. It answers "which settings are worth their
cost here", not "how fast is the game": the benchmark's scene is heavier than most cities.

It is written so that a session can carry it out without the person at the Mac. Every step is a command, and
every stop rule says what to do. Paths are from the repository root unless they start with `<workspace>`:
`bash common/paths.sh` prints the workspace of this Mac.

## 1. What must be true before a series

| Check | Command | Stop if |
|---|---|---|
| The game runs from its app, and was closed by Quit | `bash cities-skylines-2/scripts/boot-verify.sh` (detached, with a log) | not `VERDICT: PASS` |
| No game, no Wine, no Steam of any kind | `ps -axo comm \| grep -ciE 'wineserver\|wine64\|wine-preloader'`, `pgrep -x steam_osx` | either finds something |
| No Steam on this account on another Mac | ask the person | not confirmed |
| The screen is unlocked and the display is on | the series checks both at every cycle | it says so and stops |
| No Screen Sharing viewer | `pmset -g assertions \| grep "Remote user"` | one is connected: the frame rate reads about 10 % low |
| The driver that closes the game is there | `ls "<workspace>/win-resize-driver.exe"` | absent: build it (the line is in `scripts/win-resize-driver.c`) or copy it from the other Mac |
| On a laptop: mains power, lid open, the built-in panel is the only display | `pmset -g batt`, and `system_profiler SPPowerDataType \| grep Wattage` | on battery, or a charger weaker than the Mac's own: the MacBook's series B of 2026-11-26 ran on a 15 W charger, drained the battery from 100 % to 7 %, and read about 5 FPS from its 28th cycle |
| No other window lies in front of the game | section 3, "the window in front" | one does |

Write down, once, in the series folder's `notes.md`: the Mac, macOS (`sw_vers -productVersion`), the engine
(`"<the game's wrapper>/Contents/SharedSupport/wine/bin/wine64" --version`), the displays and which is main
(`system_profiler SPDisplaysDataType`), and the line the series prints that starts `found:`.

## 2. Running it

A dry run first. It starts nothing and prints what each cell would change in this Mac's `Settings.coc`:

```bash
DRY=1 bash cities-skylines-2/scripts/settings-series.sh base sh-low fsr3 drs-050
```

Then the series, **detached, with a log, and never in the foreground of a tool call** (a tool's timeout kills
the process group, and Steam with it):

```bash
CAPTURE=1 caffeinate -dis bash cities-skylines-2/scripts/settings-series.sh base <cells...> base > "<workspace>/perf-runs/series-1.out" 2>&1
```

Rules for the list of cells:

- **Start and end with `base`, and put a `base` after every three or four cells.** A setting is read against
  the base runs beside it. On the Studio the base moved by 2.3 % in mid-series when another app's window came
  to lie in front of the game, and only the interleaved base runs showed it.
- **One setting per cell first.** Join settings with `+` only after each has been measured alone.
- **Every cell twice**, in two passes, not back to back.
- A cycle takes about four minutes. Fifty cycles is three and a half hours.

While it runs: do not start the game, Steam or a second series; do not edit `settings-series.sh`; do not bring
another app's window over the game. Reading the log is fine.

**Disk.** Game 1.6.4 writes a crash-report dump of about 105 MB at every start. The series removes the ones it made when it ends; if a series is killed, remove them by hand (GOTCHAS, 2026-11-26). Captures are about 10 MB each on a 5K panel: 200 of them is 2 GB.

It always ends by putting `Settings.coc` back and printing `Settings.coc RESTORED (sha256 == before)`. If that
line says FAILED, copy `Settings.coc.before` from the series folder over the game's file before anything else.

## 3. Stop rules, and what each line means

| The log says | Meaning | Do |
|---|---|---|
| `STOP: the game or something of Wine is running` | a precondition | close it properly (`steam.exe -shutdown`, never `kill -9`), start again |
| `VOID: the window is ..., the series wants ...` | the game opened at another size than in the first cycle | the row is not a result. Twice in a row the series stops: find what changed the display |
| `VOID: after the run Settings.coc lacks [...]` | the game did not keep the value | the cell did not measure what it names. Record it as "not taken"; do not retry more than once |
| `VOID: the display was not awake` | the panel slept | wake it; the rows read low with a sleeping panel |
| `note: the exit was not graceful` | the game was ended by a signal | the row stands, but the game did not rewrite `Settings.coc`, so the read-back proves nothing |
| `two cycles in a row failed: the series stops` | | read the last cycle's `.log` in the series folder before starting again |

**The window in front.** The game's window must be the frontmost of the ordinary windows on its display. Check
during the first cycle, once the game is up:

```bash
[ -x /tmp/winlist ] || swiftc -O cities-skylines-2/scripts/winlist.swift -o /tmp/winlist
/tmp/winlist | grep -nE 'layer=0 ' | head -5
```

`/tmp/winlist` is also what the series' captures use, so build it before a series with `CAPTURE=1`; `/tmp` is emptied at a restart.

The list is front to back. A line of another app above the line with `title=Cities` on the same display means
that window covers the game. Hide or move that app's window and start the series again.

## 4. After the series

```bash
swiftc -O cities-skylines-2/scripts/edge-probe.swift -o /tmp/edge-probe
for f in "<workspace>/perf-runs/settings-<TS>"/*.png; do /tmp/edge-probe "$f"; done > "<workspace>/perf-runs/settings-<TS>/edge-probe.txt"
```

Read the two tables the same way as the Studio's, in [`perf-pass-results.md`](perf-pass-results.md):

- **Frame rate:** the last block of the log, each run against the base runs beside it. Two runs of a cell
  that differ by more than 1 % are not a result yet: run the cell a third time.
- **Edges:** `hard` is the share of strong edges that are one hard jump. Without anti-aliasing it was about
  0.65 on the Studio, with SMAA about 0.3, with FXAA 0.16, with TAA 0.07 to 0.13. Compare the same capture
  second across cells (`-t30` with `-t30`): the camera moves, so compare the numbers, never pixels.
- **`period3`:** three numbers that are equal when the picture is drawn at the window's size. FSR 3 at
  Quality draws at two thirds and stretches by 1.5, which shows as one of the three standing apart.

Captures stay in the workspace. A capture is the game's window only; it still must not be committed without a
row in [`images/AUDIT.md`](images/AUDIT.md).

## 5. What not to conclude

- **Not "the game runs at N FPS".** The benchmark is one heavy scene. A city of a few thousand people ran at
  a steady 60 on the Studio while the benchmark read 40.
- **Not across game versions.** The same settings read 47.8 on 1.6.2f1 in October and 42.0 on 1.6.4f1 in
  November on the same Mac; macOS had changed too, so the cause is not known.
- **Not across Macs by percentage alone.** A setting that costs 7 % where the graphics card is the limit can
  cost nothing where it is not.
- **Not from the results row's `resolution` field.** It is the stored value. The window's size is in
  `Player.log`, and the series gates on that.
- **Not that a setting "took" because it is in the file.** FSR 4 and XeSS 3 stayed in `Settings.coc` on the
  Studio and the picture came out with no anti-aliasing at all: the edge numbers showed it, the file did not.

## 6. The MacBook: the first session, step by step (series A and series B run 2026-11-26)

For the session on the MacBook. Do the steps in order; each has a stop rule. Nothing here changes an engine, a
launcher, a wrapper or a save, and nothing is posted anywhere. The person's `Settings.coc` is put back by the
script. Results go into `docs/perf-pass-results.md` as a new section, with a row in `EXPERIMENTS.md`; captures
stay in the workspace.

**What is different on that Mac.** The built-in panel is the main display, so the launcher's display profile is
`mobile`: Retina mode on in the Wine registry, and Dynamic Resolution on at a fixed 0.5 with the sharpening
filter. The upscaler of 1.6.4 has not been tried together with those two. That is the first question; the
single settings are the second.

**Ask the person first:** mains power, lid open, nothing else to be done on the Mac for about four hours (both series), no
Steam open on any other Mac, no Screen Sharing. One Steam on the account at a time.

### Step 0: the checkout and the game

Every command below is run from the root of that Mac's checkout of this repository.

```bash
git pull --ff-only origin main
```

```bash
grep -m1 buildid "$(bash common/wrappers.sh find game 949230)/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_949230.acf"
```

- Stop if `scripts/settings-series.sh` is not in the checkout after the pull.
- The build must be `26404411` (1.6.4f1). If it is older: start the game from its app, let the launcher apply
  the update, quit, and begin again at this step. Do not measure an older build with this list.

### Step 1: the game starts, and the profile is applied

```bash
nohup bash cities-skylines-2/scripts/boot-verify.sh > "$(bash common/paths.sh | sed -n 's/^CS2_WORK=//p')/boot-verify-before-series.log" 2>&1 &
```

- Wait for it to end (about four minutes) and read the log's last lines. Stop unless it says `VERDICT: PASS`.
- This start also runs the display profile, so the registry and Dynamic Resolution are as in play.
- If `common/paths.sh` prints the workspace under another name, use that folder: the line above only names a
  place for the log.

### Step 2: the checks of section 1, and the notes

Run every check in the table of section 1. Then write `notes.md` (macOS, engine, displays, power) as that
section says; the series folder does not exist yet, so keep the notes beside the log of step 3 and move them in.

### Step 3: a dry run

```bash
DRY=1 bash cities-skylines-2/scripts/settings-series.sh base drs-050 drs-off drs-off+fsr3 drs-off+fsr3-bal drs-off+fsr3-perf drs-050+fsr3
```

- It starts nothing. Stop if any cell prints `make_cell FAILED`: the file on this Mac has a shape the script does
  not know. Send the `found:` line and the failing cell's output to the person; do not edit the script to pass.
- Keep the `found:` line. `Dynamic Resolution enabled true (minScale 0.5` is expected. If it says `false`, the
  profile did not run: go back to step 1.

### Step 4: series A, the display and the upscaler (16 cycles, about 70 minutes at the Studio's pace)

`base` leaves Dynamic Resolution as found, so on this Mac it is the laptop's profile. `drs-050` is run once to
show that it equals `base`.

```bash
W="$(bash common/paths.sh | sed -n 's/^CS2_WORK=//p')"; mkdir -p "$W/perf-runs"; CAPTURE=1 nohup caffeinate -dis bash cities-skylines-2/scripts/settings-series.sh base drs-050 drs-off drs-off+fsr3 base drs-off+fsr3-bal drs-off+fsr3-perf drs-050+fsr3 base drs-off drs-off+fsr3 drs-off+fsr3-bal base drs-off+fsr3-perf drs-050+fsr3 base > "$W/perf-runs/macbook-series-A.out" 2>&1 &
```

- After the first cycle is up, do the "window in front" check of section 3.
- Do not poll the log more than every few minutes. The series is over when it prints `DONE`.
- Stop rules: section 3. If the series stops itself, read the last cycle's `.log` before anything else.

### Step 5: read series A before going on

- The last block of the log has each run against the base runs beside it.
- Edge numbers: section 4. **Choose the probe's step from the window:** the series prints `window of this
  series: <w>x<h>`. If a capture's width equals `<w>`, run `/tmp/edge-probe <file> 1`; if it is twice `<w>`,
  leave the step at 2.
- What to report: the frame rate of each of the six, their `hard` and `period3` numbers, and which cells the
  game did not keep (a `VOID: ... lacks` line).
- Do not pick a new base. Series B runs on `base` as found, so that it needs no decision.

### Step 6: series B, one setting at a time (33 cycles, about two and a quarter hours at the Studio's pace)

```bash
W="$(bash common/paths.sh | sed -n 's/^CS2_WORK=//p')"; CAPTURE=1 nohup caffeinate -dis bash cities-skylines-2/scripts/settings-series.sh base sh-low sh-high sh-off base aa-none aa-fxaa aa-smaa-high base vclouds-off lod-035 lod-050 base fog-off ssao-off ssr-off base sh-low sh-high sh-off base aa-none aa-fxaa aa-smaa-high base vclouds-off lod-035 lod-050 base fog-off ssao-off ssr-off base > "$W/perf-runs/macbook-series-B.out" 2>&1 &
```

- Start it only when series A printed `DONE` and `Settings.coc RESTORED`.
- If time is short, give the script only the first 17 cells of this list (through the fifth `base`): that is one
  complete pass. Do not stop a running series by hand. If it must stop (the Mac has to move), wait until no Wine
  runs, end the series and its `caffeinate`, then look for a `launch-cs2` process: a launcher already started for
  the next cycle outlives the series and goes on to start Steam (2026-11-26). End it before Steam starts, or shut
  its Steam down with `steam.exe -shutdown`, never `kill -9`.

### Step 7: write it up

- A section in `docs/perf-pass-results.md` shaped like the Studio's: the method line with this Mac's facts, the
  table, then what it says. Say what was not measured.
- Compare with the Studio only where section 5 allows it.
- A row in `EXPERIMENTS.md` (the next free `C` number is the highest plus one), then
  `python3 cities-skylines-2/scripts/check-experiments.py`, `python3 common/check-links.py` and
  `ACCEPT=9 bash common/check-identifiers.sh`. Commit the documents only.

### Not part of this list

- **Heat.** These runs are uncapped on purpose (vsync off). For play on a laptop the opposite is wanted.
  Surviving Mars has its own check: `surviving-mars-relaunched/README.md`, "Known limits".
- **A second display.** Measure the built-in panel only.
- **Not known before the first run:** the window size the series will see, whether 120 Hz changes anything with
  vsync off, and how long a cycle takes there (the Studio's is four minutes).
