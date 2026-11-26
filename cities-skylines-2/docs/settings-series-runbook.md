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
| On a laptop: mains power, lid open, the built-in panel is the only display | `pmset -g batt` | on battery |
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
/tmp/winlist | grep -nE 'layer=0 ' | head -5
```

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

## 6. The MacBook (not run yet)

What is different there, and what the first series should settle:

- **The display.** The built-in panel is the main one, so the launcher's display profile is `mobile`: Retina
  mode on in the Wine registry, and Dynamic Resolution on at a fixed 0.5 with the sharpening filter. The
  series runs with `CS2_PROFILE=off`, so it leaves the registry as the last ordinary start left it, and
  `base` leaves Dynamic Resolution as found. So: start the game once from its app and quit it before the
  first series, and note the `found:` line.
- **The upscaler of 1.6.4 has not been tried together with Retina mode and Dynamic Resolution.** That is the
  first question. Cells, each twice, with `base` between:
  `drs-050` (the laptop's profile, upscaler off), `drs-off` (every pixel of the panel), `drs-off+fsr3`,
  `drs-off+fsr3-bal`, `drs-off+fsr3-perf`, `drs-050+fsr3` (two reductions at once: expected to look soft).
  The edge numbers and `period3` say what was drawn; the frame rate says what it cost.
- **Then the same single-setting cells as on the Studio**, on whichever of the above is kept as that Mac's
  base: `sh-low sh-high sh-off aa-none aa-fxaa aa-smaa-high clouds-off lod-035 lod-050 fog-off vol-off
  ssao-off ssr-off`.
- **Heat is not measured by this.** The benchmark runs uncapped (vsync off) on purpose. A laptop that is
  played on wants the opposite: vsync on, or a lower limit. That is a separate, shorter check.
- **Not known:** the window size the series will see there, whether the panel's 120 Hz changes anything with
  vsync off, and which engine that Mac's wrapper holds. Record all three.
