# Perf-pass results — measured table

> Protocol: [docs/plans/perf-pass.md](plans/perf-pass.md) §2. Instrument: the game's built-in
> benchmark (`-benchmark`, patch 1.5.7f1) — verified working under Wine 11.16 + DXMT 2026-08-23:
> auto-loads a bundled stress city at boot, runs ~1,994 frames, writes structured results
> (min/avg/max/p95 + full per-frame series) to `Benchmark.coc`. All readings below are **R-bench**
> (autonomous cycles via `scripts/perf-bench.sh`); raw run logs live outside the repo.

## Scene + regime facts (R-bench)

- The benchmark scene is **far heavier than the daily city** (~22 FPS vs 44.9) and is
  **predominantly CPU/sim-bound**: `gpuBoundPercent` 11.6–16.6% across runs, ~2.9 sim ticks per
  frame, CPU-game spikes to 457 ms. It stresses exactly the late-game regime.
- **Consequence — primary metric per lever class on this scene:** GPU levers are judged on
  **gpuMs avg/p95** (which responds directly) rather than averageFps (diluted when only ~15% of
  frames are GPU-bound); CPU-sim levers on **averageFps + cpuGameMs**; pacing levers on the
  frame-time stdev / 1%-low — and pacing verdicts are confirmed on the lighter daily scene, where
  the cap actually binds.

## Noise floor (M0 on the benchmark scene) — 2026-08-23/24

⚠ Caveat: these samples ran on the **pre-pin profile** (DynamicRes=Automatic still on). Settings
confirmed by screenshot 2026-08-24 09:29 (after James's pin): Global=Custom ·
**DynamicRes=Disabled (pinned)** · AA=Low SMAA · Clouds=Med · Fog=on · Volumetrics=Low · AO=Med ·
GI=Off · **Reflections=Low** (drifted from the V3 block's "Med" at some point — one more reason
the clean re-baseline matters) · DoF=Off · MotionBlur=Off · Shadows=Low · Terrain/Water/LOD=Med ·
**Texture=Med**. The `m0-clean-*` rows below are the authoritative floor; the Benchmark tab also
exists in Options (menu entry confirmed).

| cell | avgFps | gpuMs avg / p95 | cpuMs avg / p95 | frame stdev | 1%-low FPS | load s |
|---|---|---|---|---|---|---|
| m0-baseline-1 | 22.35 | 44.3 / 65.5 | 33.5 / 48.8 | 13.5 | 15.4 | 45.7 |
| m0-baseline-2 | 21.62 | 44.2 / 61.6 | 35.1 / 51.3 | 11.7 | 16.0 | 47.0 |
| m0-baseline-3 | 22.65 | 39.3 / 52.2 | 32.7 / 45.1 | 11.8 | 16.7 | 45.4 |

**Noise floor (avgFps): max−min = 1.03 FPS ≈ 4.6% of the 22.2 mean. KEEP margin = max(floor,
1 FPS) = 1.03 FPS on this scene (≈4.7%), per plan §2.** Note gpuMs avg spread is wider
(39.3–44.3, ~11%) — GPU-lever verdicts on this scene need either a delta beyond that spread or
more samples per cell.

## Instrument validation (plan §2 cell) — RESOLVED 2026-08-24

One probe cycle with `MTL_HUD_LOGGING_ENABLED=1` + `MTL_HUD_PATH=<dir>` set: the path dir stayed
**empty** and the unified log shows **zero** `metal-HUD` samples — Apple's HUD post-hoc logging
is **dead under Wine on macOS 26** (the check pass's binary-scan lens was right; the tech-talk
documentation does not apply here). Verdict: **the benchmark's own per-frame series is the
primary stats instrument** (strictly better anyway); daily-scene readings fall back to
HUD-eyeball min/typ/max over the fixed window, stated per row. The probe's benchmark result
(22.68 avgFps, gpuMs 41.6) sits inside the floor band — the HUD vars don't perturb measurements.

## Lever cells

| lever | value | load-verified? | reading (R-bench) | verdict | notes |
|---|---|---|---|---|---|
| B1 `d3d11.preferredMaxFrameRate` | 40 | ✅ `Found config env: d3d11.preferredMaxFrameRate=40` (both DLLs) | avgFps 22.75 · gpuMs 40.8/54.5 · stdev 12.8 · 1%-low 17.2 | **mechanism VERIFIED · effect here DEAD (expected)** | The cap only binds on frames faster than 25 ms; this scene averages ~44 ms GPU, so a null avgFps result is the *predicted* outcome (plan §3B). 1%-low was the best of all four runs — consistent with mild tail-smoothing, but within noise. Pacing judgment happens on the daily scene per plan; the cell's real yield is proving the DXMT_CONFIG → load-verify → measure chain end to end. |

## Cycle mechanics (measured)

One autonomous cycle ≈ 5–6 min: Steam cold start + 45 s licence + boot + 45 s benchmark load +
~90 s run + teardown (SIGTERM at idle menu exits cleanly; launcher then shuts Steam down
gracefully). Chain of three ran unattended, zero failures.

## Resolution-lever family (§3A + C1) — ADJUDICATED LIVE 2026-08-24, family closed

James ran the whole quality/FPS trade himself in one morning session (live HUD + eyeballs; exact
per-view FPS numbers are scene-dependent and not comparable to R-bench rows). Mechanism findings
first — all measured, all new for this stack:

1. **Fullscreen Windowed locks the backbuffer to desktop resolution.** The in-game Screen
   Resolution dropdown is INERT in borderless: 1280×720 saved to Settings.coc, confirmed across
   a relaunch, HUD input res stayed 1920×1080. Unity-standard borderless behavior, now verified
   under Wine/DXMT.
2. **Therefore the MetalFX spatial swapchain is unusable in borderless** — the input resolution
   can never drop below desktop res, so the only reachable configs are supersampling (input
   1080p → 1620p target: measured live — softer AND slower; the factor trap in its display-mode
   form). MetalFX itself WORKS (HUD `Scaling: Spatial` + input/target lines confirmed) — the
   route dies on display-mode grounds, not DXMT grounds.
3. **Street names are world-rendered (painted on roads), not UI-layer text** — every scaling
   route softens them. This killed the "DRS keeps text sharp" hypothesis for the one text class
   that matters most in play.
4. **DRS Constant defaults to 50% scale** (`minScale: 0.5`, filter `EdgeAdaptiveScaling` in
   Settings.coc) — the scale control only appears with DRS=Constant + SHOW ADVANCED.

Verdicts (James as TRADE judge):

| Config | Look | Verdict |
|---|---|---|
| Native 1080p, Low SMAA | sharp, "a bit jagged" edges | superseded by AA bump |
| 720p / 900p nearest-neighbor stretch | "not as good" / "ok, not great" | REVERT |
| MetalFX supersample (1080→1620, borderless-forced) | soft, unreadable street text | REVERT |
| DRS Constant @ default 50% | "looks bad" at ~50 FPS | REVERT |
| **Native 1080p + High SMAA (+ outline MSAA8x), DRS Disabled** | **"looks good"** | **KEEP — the daily driver** |
| DRS Constant @ 75–80% (slider) | untried | OPEN — optional FPS-back dial |

**Current daily config on record:** 1920×1080 Fullscreen Windowed @120Hz · DRS Disabled ·
**AA High SMAA** (up from Low — the one quality *spend* of the day) · VSync on · max frame
latency 2 · rest of the settings block unchanged. Benchmark cells for this config: pending the
next idle window (nothing auto-arms — post-collision protocol).

Also visually confirmed from the Options screens: the **max-frame-latency slider exists** (B2
live, set 2) · the **DLSS upscaler entry is present but greyed** on Apple GPU (A4 gating seen in
the UI) · **VSync-on doesn't bind** at sub-40 FPS on a 120 Hz panel (kept on, consistent across
cells).

## The autonomous settings series (P2 matrix) — 2026-08-24, 9 cells, zero human input

**Method unlock first:** a controlled experiment proved complete value edits to `Settings.coc`
are honored by the game (functional proof: edited `minScale` 0.75→0.5 → benchmark gpuMs dropped
−17%, file persisted, config restored byte-for-byte; GOTCHAS refined — the old trap is *partial*
flips). That made the whole settings matrix autonomous: per cell, backup → unique-anchor regex
edit → benchmark cycle → persistence check → restore (`~/cs2-patch/perf-runs/settings-series.py`).

**Base config** (James's adjudicated finalist): 1080p Fullscreen Windowed · DRS Custom 75%
FSR1.0/EASU · High SMAA · the lean settings block. Base R-bench: **24.02 FPS · gpuMs 40.5 ·
cpuGameMs 25.9 · 1%-low 15.2**. (Beats the pre-pin 22.2 baseline while looking better.)
Noise: avgFps floor 1.03; gpuMs spread ~±2.3.

| Cell | avgFps Δ | gpuMs Δ | Verdict |
|---|---|---|---|
| s2 LOD 0.5→0.25 | **+4.74** | **−6.4** (and cpuGame −5.5!) | **WINNER — a double lever** (GPU + CPU); best 1%-lows (22.9). Cost: pop-in — **accepted** (James, 2026-08-24: "pretty solid") |
| s3 Shadows off | +3.52 | −6.4 | big/ugly; a half-res-shadows middle cell is queued for later |
| s4 Small-ticket sweep | +0.91 | −4.2 | real GPU ms, diluted on the CPU-heavy scene; marginal per visual cost |
| s5 Texture up (mipbias 1→0) | +0.43 | −3.7 | **free quality win — KEEP** |
| s6 AA High→Low SMAA | +0.23 | −4.7 | High SMAA costs ~5 gpuMs; the jaggedness fix's known price, kept |
| s1 DRS off (native) | −1.11 | +1.0 | **finalists tie within noise → sharpness is free → native wins** |
| s0 Upscale filter TAAU | −1.62 | **+9.2, p95 110 ms, 1%-low 8.0** | **LANDMINE — never use TAAU under DXMT** (temporal path pathological) |

**s7 composed** (native + High SMAA + LOD 0.25 + mipbias 0): **26.80 FPS (+11.6%) · gpuMs 35.9 ·
cpuGameMs 20.3 · 1%-low 23.59 (+55% vs base — better than the base config's *average* feel).**
Sub-additive vs the naive sum (expected; native returns DRS's savings), CPU win survives
composition. On the GPU-bound daily scene the average-FPS gain should exceed the stress-scene's.

**Recommended daily driver (CONFIRMED — James's pop-in verdict 2026-08-24: "pretty solid", accepted):** DRS **Disabled** · **High SMAA** ·
**levelOfDetail 0.25** · **mipbias 0** · everything else per the lean block. Revert = restore
any `.bak`/series-base snapshot or re-select in Options.

## Retina series (rt-, 2026-08-26/27) — laptop panel, current daily config

> Protocol + full mechanism: [docs/plans/retina-swapchain-experiment.md](plans/retina-swapchain-experiment.md).
> Baseline = the accepted daily driver (DRS Disabled · High SMAA · LOD 0.25 · mipbias 0) on the
> **built-in panel** (no external display) — the first rt- rows ever measured there (every earlier
> row in this doc ran 1920×1080 external-era; not comparable). ⚠ The results-row `resolution`
> field reports Unity's *display-mode* view, not the swapchain (GOTCHAS § Retina mode, trap 1);
> render resolution below is from `Player.log` "Window resolution" + HUD.

| cell | render res | gpuMs avg | avgFps | 1%-low | note |
|---|---|---|---|---|---|
| rt-b0-1/2/3 | 1512×982 | 35.56 / 27.84 / 32.31 (**median 32.31**) | 29.25–31.21 | 26.3–35.0 | fresh same-panel baseline |
| rt-r0, r0-3, r0-4 | **3024×1964 native** | 36.42 / 42.11 / 34.70 (**median 36.42**) | 24.7–25.2 | ~23 | **+12.7% median gpuMs for 4× pixels** — scene is sim-bound; expect ~+4 ms absolute on GPU-bound daily play |
| rt-r0-2 | 1920×1200 (saved-res latch) | 33.52 | 26.59 | — | accidental curve point (GOTCHAS trap 2) |
| rt-profile-mobile | **3024×1964 native + DRS 0.5 + CAS** | 36.50 | 24.73 | 22.53 | **the shipped MOBILE profile**, E2E boot through the launcher hook (2026-08-27). ⚠ 0.5's saving is invisible on this sim-bound scene — see the probe row and the live-city table |
| rt-drsprobe-025 | native + DRS **0.25** (discriminator) | **32.64** | **29.22** | **32.6** | proves DRS-by-disk is live (every metric moved far beyond repeat noise) + prices the 0.25 option |

**Live-city spot readings** (HUD, James's session 2026-08-26 — the GPU-bound regime where the
bench's sim-bound numbers understate pixel cost):

| config | GPU ms | FPS |
|---|---|---|
| 1512×982 swapchain (pre-retina daily) | 25.4 | 40.3 |
| 3024×1964 native, DRS off | 45.9 | 22.4 |
| 3024×1964 + DRS 0.5 + CAS (mobile profile) | ≈ the 1512 cost by construction (same internal pixels) — James's next session is the confirming read | ~40 expected |

| rt-home-1 | 3840×2160 (⚠ retina-doubled 1× Dell — the T10 defect) | 75.35 | 14.49 | — | first dock: RetinaMode doubles ALL displays globally, so the 1080p external rendered 4K supersampled (GOTCHAS third addendum) |
| rt-home-2 | **1920×1080 native 1:1 (the fixed HOME profile)** | **36.49** | **27.25** | 24.13 | v2 helper flips retina off pre-boot on home; all three resolution instruments agree for the first time |

**Resolution of the series (2026-08-27):** retina ADOPTED — James's in-game dropdown selection
persisted the full tuple and holds across relaunch (verified by the rt-profile-mobile boot), so
the earlier "not adopted / launcher assert" verdict is superseded. The launcher auto-asserts per
display context (`cs2-display-profile.sh` v2: **mobile = retina on + native swapchain + DRS 0.5
CAS · home/external = retina off + DRS off, true native 1:1** —
docs/plans/launcher-display-profiles.md). T10 (first dock, 2026-08-27) found and fixed the home
defect above; both configs now carry measured rows. The 2026-08-23/24 1920×1080 rows further up
ran a different quality profile and don't transfer.

## Studio series (2026-10-10) — Mac Studio M5 Max, Apple Studio Display, `home` profile

> First rows on this machine (every row above ran on the M3 Max MacBook) and on this panel. Game
> 1.6.2f1, engine wine-11.16 + DXMT, launcher `b5fb8ac`. Settings read from `Settings.coc` before
> the run = the accepted daily driver (DRS **disabled**, High SMAA, LOD 0.25, mipbias 0). Render
> resolution from `Player.log` on every cycle: `Window resolution: 2560x1440` (the results row's
> `resolution` field says 1920×1080 — GOTCHAS § Retina mode, TRAP 1). Issue #2.

| cell | avgFps | gpuMs avg / p95 | cpuGameMs | 1%-low (cpuFrame p99) | gpuBound % | load s |
|---|---|---|---|---|---|---|
| studio-home-1440-1 | 44.11 | 22.6 / 55.3 | 11.7 | 14.9 | 20.4 | 34.4 |
| studio-home-1440-2 | 47.78 | 17.4 / 22.1 | 10.5 | 41.1 | 19.6 | 31.7 |
| studio-home-1440-3 | 47.87 | 17.5 / 22.4 | 10.2 | 40.2 | 18.2 | 31.3 |

- **Cycle 1 is a warm-up outlier** (p99 67 ms vs 24 ms): first benchmark on new hardware, whose new
  Metal `pipelineCacheUUID` means shader caches rebuild (ledger 2026-10-10). Repeat spread of 2–3
  is 0.09 FPS. Quote the median of 2–3: **47.8 FPS · gpuMs 17.5 · cpuGame 10.4 · 1%-low ~41.**
- **Against the accepted daily driver** (s7 composed: 26.80 FPS · gpuMs 35.9 · cpuGame 20.3 ·
  1%-low 23.6 — M3 Max, 1920×1080): **+78 % FPS at 1.78× the pixels**, gpuMs roughly halved,
  cpuGame halved. Hardware and resolution both changed, so this is not a lever reading — it says the
  new working point is far above the one James accepted, not why.
- ⚠ **These ran with in-game VSync ON** (`"vSync": true`, as every saved base), which on a 60 Hz
  panel is a 60 FPS min-duration cap (`d3d11_swapchain.cpp:762-766`) — against the plan's
  vsync-off rule (found by the 2026-10-10 re-check). The cap can only hold numbers DOWN, so the
  verdict below stands; the rows are not a noise floor and not P3–P5 baselines (Studio M0 is).
- **Display state (added 2026-10-10 22:1x):** these three ran with the display AWAKE (user activity
  18:22:06, display on 18:22:07–18:43:20). Later rows `teardown-test-*`, `studio-m0-vsoff-warmup` and
  `studio-awake-control-vson` ran with the panel ASLEEP under a locked session (gpuBound 2–9 %,
  gpuMs 21–24) and are **VOID as measurements** — GOTCHAS § Measurement traps (locked display).
- **Verdict for #2's `home-hidpi` row: not needed for performance on this machine** — at native
  2560×1440 the scene stays sim-dominated (gpuBound 18–20 %) and every metric beats the accepted
  baseline. ⚠ The bench understates pixel cost on the GPU-bound live city (retina series: 25.4 →
  45.9 ms live for 4× pixels on the M3 Max), so the closing measurement is one live-city HUD reading
  (`CS2_HUD=1`) in James's next session.

### Studio M0 attempt 2 (2026-10-10 22:40–23:05) — unlocked, display awake, but SCREEN-SHARED

All five cycles: display awake, session unlocked, graceful WM_CLOSE exit — and a Screen Sharing viewer
connected throughout (`screensharingd` "Remote user is connected" from 22:40:00). Vsync-off was applied
before each cycle (the game writes `true` back on every graceful exit); Settings.coc restored after.

| cell | vSync | avgFps | gpuMs avg | gpuBound % | cpuGameMs | 1%-low (cpuFrame p99) |
|---|---|---|---|---|---|---|
| studio-m0-vson-control | on | 43.24 | 22.1 | 14.6 | 12.8 | 32.6 |
| studio-m0-vsoff-warmup | off | 43.56 | 22.6 | 2.8 | 11.6 | 36.8 |
| studio-m0-vsoff-1 | off | 43.32 | 20.6 | 5.9 | 11.9 | 36.3 |
| studio-m0-vsoff-2 | off | 41.22 | 26.8 | 17.5 | 14.2 | 15.6 |
| studio-m0-vsoff-3 | off | 42.68 | 22.0 | 17.4 | 13.2 | 30.7 |

- **~10 % below C75 (47.8) at the same config with the display awake** — the difference is the
  Screen Sharing stream (C75 had none: no `screensharingd` assertion 17:00–18:45). **Not a Studio
  M0**: it is a floor for the screen-shared condition only (vsync-off 1–3: 41.22–43.32, 2.1 FPS ≈ 5 %).
- **Vsync has no measurable effect here**: the vsync-on control sits inside the vsync-off spread —
  expected, a 60 FPS cap does not bind on ~23 ms frames. Whether the edit is honoured at all is still
  unproven (no effect either way to see), so P3's vsync cell needs a scene that reaches 60.
- `gpuBoundPercent` swings 2.8–17.5 % between identical vsync-off runs — **not a stable metric**; do
  not use it as a regime indicator.
- Valid M0 conditions, now recorded per row by perf-bench (`display_awake`, `locked`,
  `screen_shared`): display awake, session unlocked, **no Screen Sharing viewer**.


### Studio M0 (2026-10-12 15:20–15:52) — VALID. Floor and margins fixed (ledger C76)

Conditions, recorded per row by perf-bench: display awake, session unlocked, **no Screen Sharing**,
graceful WM_CLOSE teardown, Player.log `Window resolution: 2560x1440` on every cycle (the series
stops otherwise). Each cycle: `"vSync": false` and `"displayMode": "FullscreenWindow"` set as
complete-value edits with the game closed; `CS2_PROFILE=off` so the launcher profile cannot rewrite
the baseline's DRS block; Screenmanager "Use Native"=1 written by the series (the profile's other
half). Settings.coc restored after the series (sha256). Script: `~/cs2-patch/perf-runs/studio-m0-20261012.sh`.

| cell | avgFps | gpuMs avg / p95 | cpuGameMs | cpuMs p95 | gpuBound % | cpuFrame 1%-low | simTicks |
|---|---|---|---|---|---|---|---|
| warm-up (daily, discarded) | 47.62 | 17.1 / 19.0 | 10.0 | 17.3 | 12.8 | 45.2 | 8338 |
| daily-1 | 47.69 | 17.0 / 18.6 | 9.9 | 16.8 | 15.7 | 46.7 | 8310 |
| daily-2 | 47.73 | 17.1 / 19.4 | 9.9 | 16.9 | 13.5 | 45.2 | 8330 |
| daily-3 | 47.82 | 17.2 / 19.8 | 9.9 | 16.9 | 12.8 | 47.2 | 8309 |
| base-1 | 44.91 | 17.2 / 20.2 | 10.2 | 19.1 | 22.8 | 40.8 | 8304 |
| base-2 | 45.09 | 17.4 / 23.5 | 10.1 | 19.3 | 22.5 | 40.4 | 8309 |
| base-3 | 45.06 | 17.0 / 18.8 | 10.2 | 19.2 | 24.0 | 40.7 | 8312 |

- **Noise floor (avgFps max−min): daily driver 0.13 FPS (0.3 %), clean baseline 0.18 FPS (0.4 %).**
  Both are under the plan's ~1 FPS minimum, so **KEEP margin = 1 FPS ≈ 2.2 % of the clean baseline
  (45.02)**, and the **composed-profile margin for P5 is fixed at the same 1 FPS (2.2 %)** — the plan
  names no separate rule for it, so the KEEP rule is applied to both (2026-10-12; revisit if P5 wants
  a stricter bar). The M3 Max P0 floor (1.03 FPS ≈ 4.7 %) becomes the M3 Max stratum.
- Daily driver beats the clean baseline by **+2.73 FPS (+6.1 %)**, with a better 1%-low (45–47 vs ~40.6).
- Vsync off reads the same as C75's vsync-on 47.8: the bench never reaches the 60 FPS cap here.
- `gpuBoundPercent` was stable this time (daily 13–16, base 22–24) — unlike the screen-shared attempt.
- ⚠ **`CS2_PROFILE=off` is not "settings untouched":** the profile is two writes, and off also drops
  "Use Native"=1. The game resets that to 0 on exit (after any in-game resolution change it remembers
  the old size), so a first attempt without it ran at **1920×1080** and is VOID (TS 151106, 2 cycles).


### P3 B1 — frame cap 30 on the bench (2026-10-12 16:20–16:30)

`DXMT_CONFIG="d3d11.preferredMaxFrameRate=30"`, daily driver, same guards as Studio M0 (vsync off,
FullscreenWindow, `CS2_PROFILE=off` + Use Native=1, `Window resolution: 2560x1440` gated, display awake,
unlocked, not shared). Script `~/cs2-patch/perf-runs/p3-b1-cap30-20261012.sh`.

| cell | avgFps | cpuFrame stdev / p99 ms / 1%-low | gpuFrame stdev / p99 ms | simTicks |
|---|---|---|---|---|
| p3-b1-cap30-1 | 29.99 | 4.76 / 26.1 / 38.4 | 10.86 / 31.2 | 8226 |
| p3-b1-cap30-2 | 29.77 | 9.05 / 37.7 / 26.6 | 14.58 / 32.8 | 8036 |
| uncapped (Studio M0 daily-1..3) | 47.69–47.82 | 3.45–3.91 / 21.2–22.1 / 45.2–47.2 | — | 8309–8330 |

- **The cap engages exactly** (29.99 / 29.77) — mechanism load-verified on the Studio.
- **Pacing is not smoother at the cap on this scene**: frame-time stdev 1.3–2.5× uncapped, p99 up, and
  the two runs disagree (run 2 clearly worse). ⚠ Under a cap part of each frame is the deliberate present
  wait, and the bench's frame stats may count it differently — indicative, not a verdict.
- simTicks 1–3 % lower than uncapped over the same fixed window.
- ~~A cap of 60 cannot bind on a 48 FPS bench (≡ uncapped here)~~ — **measured 2026-10-13, see the next section:** the average is unchanged, but cpuFrame averages ~14 ms, so single fast frames are held and the tail moves a little. On 60 Hz, vsync-on ≡ cap 60 in play (not measured as a cell).
- **B1 stays a feel decision (plan §3 B1)**, but the bench gives no reason to prefer 30: live play on
  the Studio already holds 60 with vsync on in the cities that exist (#2). Candidate for the daily
  profile: vsync on (= cap 60), no `preferredMaxFrameRate`.

### P3 B1 — frame cap 60, with a same-session control (2026-10-13 13:32–13:51)

`DXMT_CONFIG="d3d11.preferredMaxFrameRate=60"` ×2, then the **uncapped daily driver ×2 as the session
control** (plan §2), same guards as the cap-30 cells. Scripts `~/cs2-patch/perf-runs/p3-b1-cap60-20261013.sh`,
`p3-ctl-uncapped-20261013.sh`. ⚠ The control ran *after* the cap cells: the session opened without it
(an omission, caught on reading the cap rows). Order would favour the cap, not the control (cooler machine first).

| cell | avgFps | cpuFrame stdev / p99 ms / 1%-low | gpuFrame stdev / p99 ms / 1%-low | gpuBound % | simTicks |
|---|---|---|---|---|---|
| p3-b1-cap60-1 | 47.87 | 4.10 / 25.9 / 38.6 | 7.91 / 23.2 / 43.1 | 23.8 | 8301 |
| p3-b1-cap60-2 | 47.47 | 4.75 / 26.5 / 37.8 | 8.16 / 23.8 / 42.0 | 23.8 | 8330 |
| control uncapped-1 | 47.77 | 3.85 / 24.8 / 40.3 | 7.46 / 22.9 / 43.6 | 21.0 | 8320 |
| control uncapped-2 | 47.91 | 3.57 / 24.1 / 41.5 | 7.21 / 22.3 / 44.8 | 19.1 | 8303 |
| later control uncapped-1 (14:32, B2 session) | 47.74 | 4.52 / 26.0 / 38.4 | 7.64 / 22.8 / 43.8 | 20.3 | 8282 |
| later control uncapped-2 (14:37) | 47.38 | 4.66 / 30.2 / 33.1 | 9.22 / 29.3 / 34.1 | 27.5 | 8301 |
| Studio M0 daily-1..3 (2026-10-12) | 47.69–47.82 | 3.45–3.91 / 21.2–22.1 / 45.2–47.2 | 5.94–6.29 / 18.1–19.0 / 52.8–55.1 | 12.8–15.7 | 8309–8330 |

- **Session control passes on the average** (mean 47.84 vs M0 47.75, inside the 0.13 floor), so the cells count.
- **But the tails drifted between days with the average flat:** today's uncapped cpuFrame p99 is 24–25 ms vs
  21–22, 1%-low 40–42 vs 45–47, gpuBound 19–21 % vs 13–16 %. Cause unknown. **Compare tail metrics only
  against a same-session control** — the cap-60 rows read against M0 alone looked like a 4–5 ms tail cost,
  of which most is this drift (EXPERIMENTS C77).
- ~~**Cap 60 vs its own control:** … the two cap runs sit outside both control runs on each tail metric … may cost a
  little at the tail.~~ **Withdrawn 14:41 the same day:** two more uncapped runs (the B2 session's control, rows above)
  read cpuFrame p99 26.0 / 30.2 ms and 1%-low 38.4 / 33.1. Today's four uncapped runs span p99 24.1–30.2 and 1%-low
  33.1–41.5; the cap runs (25.9 / 26.5, 38.6 / 37.8) sit inside that spread. **Cap 60 is indistinguishable from
  uncapped on this scene, average and tails.** The earlier "outside both control runs" was two control runs read as
  if they bounded the spread.
- B1 is measured at both values. The daily choice stays on feel; nothing here argues for `preferredMaxFrameRate`.
  Next in P3: B2 (in-game max-frame-latency slider), then the vsync decision.

### P3 B2 — in-game Maximum frame latency 1 vs the default 2 (2026-10-13 15:19–15:38)

James found the slider (Options → Graphics → Main, under VSync; it read **2**), set **1** and quit. A snapshot diff
showed it lands in `Settings.coc` as `"maxFrameLatency": 1` beside `"vSync"` and is **written only when not the default 2**.
Series `~/cs2-patch/perf-runs/p3-b2-20261013.sh`: lat 1 ×2 (the key as the game wrote it), then the default ×2 with the key
removed — the bracketing control — same guards as B1 (vsync off, FullscreenWindow, `CS2_PROFILE=off` + Use Native,
2560×1440 gated, graceful, awake, unlocked, not shared). Settings.coc restored to James's lat-1 file (sha256).
Session control before it (14:32): 47.74 / 47.38.

| cell | avgFps | cpuFrame avg / stdev / p99 ms / 1%-low | gpuFrame avg / p99 ms / 1%-low | gpuBound % | gpuMs avg | simTicks |
|---|---|---|---|---|---|---|
| p3-b2-lat1-1 | 41.54 | 15.13 / 3.78 / 24.3 / 41.2 | 24.03 / 36.9 / 27.1 | 99.1 | 24.03 | 8316 |
| p3-b2-lat1-2 | 41.71 | 15.03 / 4.00 / 25.8 / 38.7 | 23.93 / 36.5 / 27.4 | 99.1 | 23.93 | 8317 |
| p3-b2-lat2ctl-1 (default) | 47.97 | 14.41 / 3.62 / 23.3 / 43.0 | 3.96 / 22.2 / 45.1 | 21.4 | 17.26 | 8320 |
| p3-b2-lat2ctl-2 (default) | 48.14 | 14.38 / 3.46 / 23.4 / 42.8 | 3.90 / 22.3 / 44.9 | 20.8 | 17.43 | 8340 |

- **Latency 1 = −6.4 FPS (−13 %), REVERT.** Far outside the 1 FPS margin and every spread seen today; both pairs are tight.
- The mechanism shows in the columns: at 1 the frame goes **99 % GPU-bound** and the measured GPU time rises 17.3 → 24.0 ms —
  with one frame in flight the CPU and GPU stop overlapping, so each frame pays both in series. CPU-side times barely move.
- Input latency would drop by about one frame (~21 ms at 48 FPS); for a city builder that is not worth 13 %.
- **The default 2 stays.** B2 closed. ⚠ James's `Settings.coc` still carries `"maxFrameLatency": 1` until it is set back.
- The bracketing control (47.97 / 48.14) sits at or above M0 (47.75); the 14:32 control's slow run (47.38) did not recur.

### P4 D2 — `memorysetup-bucket-allocator-block-count=4` (2026-10-13 20:00–20:27)

First P4 cell, run as plan §3D pass 3 specifies: `~/cs2-patch/perf-runs/p4-series.sh d2` — C C L L C C, daily-driver
Settings.coc (vsync off, FullscreenWindow, `CS2_PROFILE=off` + Use Native), `CS2_UPDATE=skip`, boot.config key count +
`build-guid` asserted before and after every cycle, each cycle gated on 2560×1440 and on `scripts/p4-signals.py`.
The line was appended after c2 and deleted after l2 (sha256 back to the pre-series hash); Settings.coc restored (sha256).
All six cycles graceful, display awake, unlocked, not shared.

| cycle | avgFps | cpuGameMs avg | cpuFrame avg / stdev / p99 / 1%-low | gpuBound % | simTicks | bucket Used Blocks | failed / frame |
|---|---|---|---|---|---|---|---|
| c1 | 47.39 | 10.69 | 14.42 / 8.30 / 24.5 / 40.9 | 19.6 | 8213 | 1 | 1038.3 |
| c2 | 48.00 | 10.66 | 14.38 / 3.59 / 23.6 / 42.4 | 19.4 | 8314 | 1 | 1040.1 |
| **l1** | **48.02** | 10.49 | 14.27 / 3.58 / 24.0 / 41.7 | 21.5 | 8321 | **4** | **852.7** |
| **l2** | **48.07** | 10.52 | 14.29 / 3.37 / 23.8 / 42.0 | 20.9 | 8330 | **4** | **843.2** |
| c3 | 47.98 | 10.48 | 14.23 / 3.50 / 23.7 / 42.1 | 19.6 | 8318 | 1 | 1057.9 |
| c4 | 47.53 | 10.61 | 14.38 / 3.86 / 24.5 / 40.7 | 18.5 | 8323 | 1 | 1058.2 |

- **Load-verified:** Used Block count 1 → 4 on both lever cycles, back to 1 on c3/c4; slow-path failures per frame
  −18 % (848 vs 1,039–1,058). The key is honoured and does what it says.
- **Verdict DEAD** (plan §2 [CPU-sim] rule): lever mean 48.04 vs control mean 47.72 = **+0.32 FPS**, inside the 1 FPS
  margin. Both lever cycles sit at the top of the control range (max control 48.00) — a hint of a sub-margin gain, not a
  measurable one. cpuGameMs and cpuFrame match the controls; simTicks guard clear (lever 8,321 / 8,330 vs controls' min 8,213).
- Not kept: a sub-margin gain does not justify a launcher boot.config re-assert (plan §3D/P5). Closed.
- c1, the session's first cycle, again carried the session's worst tail (cpuFrame stdev 8.30, simTicks 8,213) — the
  same first-run pattern as the 14:32 control. The bracket absorbs it; worth watching in D1.

### P4 D1a — `job-worker-count=12` (2026-10-14 19:32–19:59)

Same series and gates as D2 (`p4-series.sh d1 12`; C C L L C C; boot.config line appended after c2, deleted after l2, sha256
back to the pre-series hash; Settings.coc restored). All six cycles graceful at 2560×1440, display awake, unlocked, not shared.
D1a is the first pre-registered D1 value (plan §3D, pass 3).

| cycle | avgFps | cpuGameMs avg | cpuFrame avg / stdev / p99 / 1%-low | gpuBound % | simTicks | highest Job.Worker |
|---|---|---|---|---|---|---|
| c1 | 47.77 | 10.45 | 14.23 / 3.83 / 23.6 / 42.5 | 20.3 | 8329 | 16 |
| c2 | 48.09 | 10.37 | 14.08 / 4.10 / 22.4 / 44.7 | 19.2 | 8319 | 16 |
| **l1** | **47.86** | **9.81** | 13.52 / 4.21 / 22.1 / 45.2 | **14.3** | 8310 | **11** |
| **l2** | **47.87** | **9.85** | 13.61 / 3.98 / 22.5 / 44.5 | **15.3** | 8307 | **11** |
| c3 | 48.12 | 10.29 | 14.04 / 3.86 / 22.3 / 44.8 | 20.0 | 8313 | 16 |
| c4 | 48.06 | 10.14 | 13.92 / 3.37 / 22.2 / 45.0 | 19.9 | 8316 | 16 |

- **Load-verified:** highest `[ALLOC_TEMP_Job.Worker N]` 16 → 11 → 16 (12 workers on the lever cycles).
- **Verdict DEAD:** lever mean 47.86 vs control mean 48.01 = **−0.15 FPS**, inside the 1 FPS margin; simTicks guard clear.
- **The CPU side did get cheaper** — cpuGameMs 9.81 / 9.85 vs 10.14–10.45 (−5 %), cpuFrame avg 13.5–13.6 vs 13.9–14.2,
  gpuBound 14–15 % vs 19–20 % — **yet FPS did not move**, so job-thread contention is not what bounds the frame here:
  the frame time (~21 ms) is set elsewhere than the CPU work the benchmark measures (~14 ms). Corroboration, not a verdict.
- **Pre-registered next step:** D1a is not a KEEP → **D1b = 16**; if D1b is not a KEEP either, D1 closes.

### P4 D1b — `job-worker-count=16` (2026-10-15 15:25–15:52) — D1 and P4 closed

Same series and gates (`p4-series.sh d1 16`). All six cycles graceful at 2560×1440, awake, unlocked, not shared;
boot.config and Settings.coc back to their pre-series sha256.

| cycle | avgFps | cpuGameMs avg | cpuFrame avg / stdev / p99 / 1%-low | gpuBound % | simTicks | highest Job.Worker |
|---|---|---|---|---|---|---|
| c1 | 48.08 | 10.27 | 13.97 / 3.96 / 23.1 / 43.3 | 19.1 | 8337 | 16 |
| c2 | 48.19 | 10.19 | 13.89 / 3.28 / 22.4 / 44.7 | 19.6 | 8333 | 16 |
| **l1** | **47.97** | **9.82** | 13.53 / 4.10 / 22.0 / 45.5 | 16.7 | 8321 | **15** |
| **l2** | **48.07** | **9.76** | 13.44 / 3.54 / 21.9 / 45.6 | 15.2 | 8326 | **15** |
| c3 | 48.05 | 10.39 | 14.13 / 3.81 / 25.0 / 39.9 | 21.2 | 8307 | 16 |
| c4 | 47.89 | 10.00 | 13.69 / 3.77 / 21.4 / 46.7 | 16.3 | 8331 | 16 |

- **Load-verified** (16 → 15 → 16). **Verdict DEAD:** lever mean 48.02 vs control mean 48.05 = **−0.04 FPS**.
- **D1 CLOSED** by the pre-registered rule (D1a DEAD → D1b = 16 → DEAD). Neither value is kept.
- **Both D1 values lower the game's CPU time by the same ~0.4 ms** (cpuGameMs 9.76–9.85 at 12 and at 16 vs 10.00–10.45 in
  their controls) — so one fewer job worker than the default 17 on 18 cores already removes whatever contention there is —
  **and neither moves FPS.**

## P4 summary (2026-10-13 … 15)

| row | verdict | load signal |
|---|---|---|
| D1 `job-worker-count` 12, 16 | **DEAD** (−0.15, −0.04 FPS) · CLOSED | highest Job.Worker 11 / 15 ✅ |
| D2 `memorysetup-bucket-allocator-block-count=4` | **DEAD** (+0.32 FPS) | Used Blocks 4, failures −18 %/frame ✅ |
| D3 `memorysetup-temp-allocator-size-main` | **CLOSED/SKIP** — precondition absent (overflow is a load-time constant) | — |
| D5 High Power Mode | **CLOSED/SKIP** — no such mode on the Studio | — |

**What P4 established:** on the Studio benchmark the frame takes ~21 ms while the CPU work the game measures takes ~14 ms
(cpuFrame avg), and making that CPU work 5 % cheaper (D1) or cutting allocator slow paths 18 % (D2) leaves FPS where it was.
The frame is bounded outside the game's own CPU and GPU timings — presentation/pacing through Wine + DXMT + Metal under
Rosetta, or main-thread waits the benchmark does not count. No Unity boot.config lever reaches that; nothing from P4 goes into P5,
so no launcher re-assert is needed.

## P5 — pass outcome (2026-10-16)

- **Composed profile = the 2026-08-24 daily driver, unchanged** (P3 and P4 kept nothing). Its gate measurement is
  Studio M0's same-session series: daily driver 47.69 / 47.73 / 47.82 vs clean baseline 44.91 / 45.09 / 45.06 —
  **+2.73 FPS (+6.1 %)**, beyond the 1 FPS composed margin. Sixteen daily-driver runs since (controls in P3/P4
  sessions, 2026-10-13…15) read 47.38–48.19, so the profile has not drifted.
- **Aspiration (≥25 %) not met, and why:** on the Mac Studio the benchmark frame (~21 ms) is bounded outside the
  ~14 ms of CPU work the game measures (C81): cheaper game CPU (D1), fewer allocator slow paths (D2), frame caps (B1)
  and frame-queue depth (B2) all left FPS where it was or lowered it. On the M3 Max (GPU-bound at 1080p) the same
  profile gave +11.6 % on the stress scene. The next lever is below the game — presentation through Wine + DXMT +
  Metal under Rosetta — and outside this pass's scope.
- **Shipped:** `README.md` § Performance (machine-labelled), AGW draft second footnote, GOTCHAS 2026-10-16.
  **Still open:** P3's vsync decision (by feel) and D4 (second display unplugged).

## 1.6.4 on the Mac Studio: the upscaler, shadows and anti-aliasing (2026-11-25)

Not a benchmark: one reading each of Metal's counter (`CS2_HUD=1`), read off a capture of a suburb
(Amasa, saved in 1.6.2f1) in the Fullscreen Window, 2560x1440, 60 Hz, vsync on, Level of Detail 0.25, upscaler
disabled, the simulation running. The camera moved a little between captures, so trust the order more than the gaps.
Each row's settings were read from `Settings.coc` at the time.

| Shadows | Anti-aliasing | FPS | GPU | Frame interval |
|---|---|---|---|---|
| High (map 4096) | TAA | 54.96 | 18.39 ms | 18.19 ms |
| **Medium (2048)** | **TAA** | **58.54** | **17.34 ms** | **17.08 ms** |
| Medium (2048) | SMAA High | 55.81 | 17.97 ms | 17.92 ms |

- **Kept (James): Medium + TAA.** Low shadows (1024, terrain shadows off) were the daily driver's; their edges were
  seen stair-stepped on the road. Low was not read with the counter.
- **Seen, cause not known:** the thin dark line along a kerb is a hard dashed line with SMAA and with TAA, before and
  after a fresh start, and tower crane masts are drawn with gaps (Level of Detail 0.25 is a guess). No same-camera
  comparison of None, SMAA and TAA was made, so whether anti-aliasing changes the picture on 1.6.4 is open.
- **FSR 3 at Quality** was on by itself before this and is not in the table: its frame rate was not read. GOTCHAS,
  2026-11-25. Outputs: the workspace, `city-164f1-20261125/`.

## The settings series on 1.6.4f1 (2026-11-25, 17:43 to 23:35): every graphics setting, one at a time

**Method.** The built-in benchmark, one setting changed per run, unattended: `scripts/settings-series.sh` (run that
night from the workspace as `s164-series.sh`; the repo script makes the same `Settings.coc`, byte for byte, for all 22
cells below). Mac Studio M5 Max, macOS 27.2, Studio Display 60 Hz, the daily engine (Wine 11.16 + DXMT), game 1.6.4f1.
Every cycle: `Window resolution: 2560x1440` gated from `Player.log`, vsync off, `CS2_PROFILE=off` + Use Native=1,
display awake, unlocked, no Screen Sharing viewer, the cell's keys read back from `Settings.coc` after a graceful exit.
**83 cycles in two series, none void.** The second series (51 cycles) also captured the game's window at 10, 30, 50 and
70 s into the scene (204 captures) for `scripts/edge-probe.swift`; captures did not move the frame rate (base 39.53 with,
39.55 without).

**The base** is what was kept that afternoon: shadows Medium, TAA, upscaler disabled, Level of Detail 0.25, fog,
volumetrics, ambient occlusion, reflections and clouds on. It read **39.55 FPS** (12 runs, sd 0.11) in the first series
and 39.44 to 39.60 in the first ten base runs of the second.

"vs base" is each run against the base runs before and after it in its own series. "Hard edges" is the share of strong
edges in a capture that are a single hard jump (1.0 = no smoothing at all), at 30 / 50 / 70 s; the camera moves, so
these are distributions, not the same pixels.

| Setting changed | Runs | FPS | vs base | GPU ms | Hard edges 30 / 50 / 70 s |
|---|---|---|---|---|---|
| **base** | 26 | 39.40 | | 28.0 | 0.07 / 0.08 / 0.13 |
| Shadows off | 2 | 42.52 | +8.1 % | 20.9 | 0.06 / 0.07 / 0.14 |
| Shadows Low | 3 | 41.72 | +5.5 % | 24.8 | 0.07 / 0.07 / 0.14 |
| Shadows High | 3 | 36.69 | −7.2 % | 31.2 | 0.08 / 0.08 / 0.12 |
| Anti-aliasing None | 3 | 40.09 | +1.4 % | 26.2 | 0.70 / 0.62 / 0.64 |
| Anti-aliasing FXAA | 3 | 40.07 | +1.3 % | 27.0 | 0.16 / 0.15 / 0.16 |
| Anti-aliasing SMAA Low | 3 | 39.94 | +1.0 % | 26.8 | 0.32 / 0.30 / 0.27 |
| Anti-aliasing SMAA High | 3 | 39.77 | +0.6 % | 26.6 | 0.28 / 0.35 / 0.37 |
| Upscaler FSR 3, Ultra Quality | 2 | 39.68 | +1.6 % | 26.9 | 0.05 / 0.07 / 0.07 |
| Upscaler FSR 3, Quality (the game's default) | 3 | 43.61 | +10.2 % | 19.2 | 0.05 / 0.06 / 0.04 |
| Upscaler FSR 3, Balanced | 2 | 44.70 | +14.5 % | 17.9 | 0.04 / 0.05 / 0.09 |
| Upscaler FSR 3, Performance | 2 | 45.77 | +17.2 % | 17.4 | 0.04 / 0.05 / 0.11 |
| Upscaler FSR 4 | 2 | 39.67 | +1.5 % | 27.6 | 0.69 / 0.60 / 0.62 |
| Upscaler XeSS 3 | 2 | 39.62 | +1.3 % | 27.0 | 0.66 / 0.59 / 0.64 |
| Level of Detail 0.35 | 2 | 37.08 | −5.1 % | 29.9 | 0.08 / 0.08 / 0.15 |
| Level of Detail 0.5 | 3 | 35.17 | −11.1 % | 28.9 | 0.07 / 0.07 / 0.17 |
| Level of Detail 1.0 | 3 | 29.17 | −26.3 % | 30.5 | 0.06 / 0.07 / 0.13 |
| Fog off | 2 | 40.03 | +1.3 % | 29.0 | 0.09 / 0.08 / 0.11 |
| Volumetrics off | 2 | 39.75 | +0.6 % | 27.1 | 0.07 / 0.08 / 0.14 |
| Ambient occlusion off | 2 | 39.94 | +1.0 % | 27.2 | 0.08 / 0.08 / 0.13 |
| Reflections off | 2 | 40.05 | +1.3 % | 27.6 | 0.08 / 0.07 / 0.14 |
| Clouds off (volumetric and distance) | 2 | 42.07 | +6.7 % | 25.7 | 0.08 / 0.07 / 0.12 |
| Shadows Low + SMAA High (October's daily driver) | 4 | 41.81 | +6.2 % | 24.3 | 0.26 / 0.33 / 0.36 |

The FPS column is the mean over both series; the last four base runs of the second (below) pull the base's mean to 39.40.

**What it says**

- **Anti-aliasing is nearly free, and TAA smooths most.** The four methods differ by 1.4 % in frame rate. In hard edges
  they differ sevenfold: none 0.65, SMAA 0.3, FXAA 0.16, TAA 0.07 to 0.13. This closes the question left open that
  afternoon: anti-aliasing does change the picture on 1.6.4, and SMAA leaves about a third of strong edges untouched.
  Whether the thin kerb line James saw is among those was not looked at one line at a time.
- **FSR 4 and XeSS 3 do not work here, and choosing one removes anti-aliasing.** Both values stayed in `Settings.coc`,
  and the picture and the frame rate were those of anti-aliasing None (hard edges 0.6 to 0.7). So on this stack the
  upscaler list has one working entry besides Disabled: FSR 3.
- **FSR 3 buys 10 to 17 %.** Quality draws at two thirds of the window and stretches by 1.5: one of the three
  `period3` numbers stood 11 % apart from the others, as measured by hand that afternoon. Ultra Quality buys almost
  nothing. Its edges read softer than TAA's at every level, which fits the fuzz James saw.
- **Three settings carry the cost on the graphics side:** shadow quality (Low +5.5 %, High −7.2 %), clouds (+6.7 % off)
  and the upscaler. Fog, volumetrics, ambient occlusion and reflections are worth about 1 % each.
- **Level of Detail is the expensive one, and it is paid on the processor:** 0.5 costs 11 % and 1.0 costs 26 %, with
  the processor's part of the frame going from 15.1 ms to 19.8 ms. 0.25 is the value to keep.
- **No single setting went above 46 FPS, and the fastest combination reached 49.6** (below). With FSR 3 at
  Performance the graphics card's part of the frame is 17.4 ms and the processor's 14.7 ms, and the frame still takes
  21.8 ms: the frame is longer than either part the game measures, as the October pass found (C81).
- **The stored resolution is ignored in the Fullscreen Window.** Two runs with 1920x1080 written into `Settings.coc`
  read as base runs (the window stayed 2560x1440). The results row's `resolution` field is the stored value, as the
  October sections already say; October's 47.8 FPS was at a 2560x1440 window.
- **The same settings are 12.5 % slower than in October.** Shadows Low + SMAA High with no upscaler read 47.8 FPS on
  1.6.2f1 and macOS 27.0.1 (C75), and 41.8 here on 1.6.4f1 and macOS 27.2, with the same engine, window and
  `Settings.coc` keys otherwise. Which of the two changed it is not known. **The README's 47.8 is October's number.**

**A window in front of the game costs 2.3 %.** From the 40th cycle of the second series the base read 38.58 to 38.69
(four runs) where it had read 39.44 to 39.60 (ten runs). At 22:38 the session had opened a tab in Chrome, which made
Chrome the active app; from the next start the game's window opened behind Chrome's (seen later in the window list,
which is front to back). Every "vs base" above is against the base runs beside it, so the step does not carry into the
percentages; the two FPS columns of cells run on both sides of it are a little apart for this reason. The runbook's
"window in front" check comes from this.

### Settings combined (2026-11-26, 00:02 to 01:46): 25 cycles, none void

The same method, run from the repo script (`scripts/settings-series.sh`, folder `settings-20261126-000204`), each
combination twice with base runs between; the base read 38.90 to 39.62 (seven runs).

| Combination (the rest as the base) | FPS, two runs | vs base | GPU ms |
|---|---|---|---|
| Shadows High + Level of Detail 0.35 | 34.80 / 34.90 | −11.7 % | 31.7 |
| **base** (shadows Medium, TAA, no upscaler) | 38.90 to 39.62 | | 27.8 |
| Distant clouds off | 39.72 / 39.59 | +0.8 % | 26.4 |
| Volumetric clouds off | 41.04 / 40.92 | +4.3 % | 26.1 |
| Shadows Low + clouds off | 43.96 / 44.66 | +12.5 % | 22.3 |
| Shadows Low + clouds, fog, volumetrics, ambient occlusion and reflections off | 45.51 / 46.07 | +16.0 % | 20.9 |
| Clouds off + FSR 3 Quality | 45.91 / 45.75 | +16.3 % | 17.8 |
| Shadows Low + SMAA High + FSR 3 Quality (October's daily driver as the 1.6.4 update leaves it) | 46.28 / 46.03 | +17.2 % | 17.5 |
| Shadows Low + clouds off + FSR 3 Quality | 47.69 / 48.37 | +21.9 % | 17.2 |
| Shadows Low + clouds off + FSR 3 Balanced | 49.63 / 49.62 | +25.5 % | 17.0 |

- **The gains add up, a little short of their sum:** shadows Low (+5.5 %) with clouds off (+6.7 %) gives +12.5 %; with
  FSR 3 Quality (+10.2 %) on top, +21.9 %.
- **The cloud cost is the volumetric clouds** (+4.3 % off); the distant ones are within the noise.
- **The October file explains why nobody noticed the slowdown.** A player who never opened the settings after the
  update runs October's daily driver with FSR 3 on, which reads 46.2 here against October's 47.8: the upscaler hides
  most of the 12.5 %, at two thirds of the resolution.
- **The whole range on this Mac is 34.8 to 49.6 FPS** in the benchmark, from the richest picture tried to the fastest.
  The four effect groups together are worth about 3.5 % once shadows and clouds are down.
- **The benchmark is heavier than play.** Metal's counter read 58.5 FPS at the base settings in a suburb of a real city
  that afternoon (the section before the series), where the benchmark reads 39.5.
