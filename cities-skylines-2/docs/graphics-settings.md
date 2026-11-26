# Graphics settings on a Mac: what each one costs

> **Draft, 2026-11-26.** Measured on one Mac only: a Mac Studio (M5 Max, macOS 27.2, 2560×1440, the Wine 11.16 +
> DXMT engine), game 1.6.4f1. The MacBook has not been measured yet. The method and every run are in
> [`perf-pass-results.md`](perf-pass-results.md).

The numbers come from the game's own benchmark, run 108 times with one setting changed at a time and then the
useful ones combined. The benchmark is a heavy scene: it reads about 40 FPS where a suburb of a real city reads
close to 60. So read the percentages, not the frame rates.

## After updating to 1.6.4, check one setting first

**Options → Graphics → Upscalers.** The update can leave it on "AMD FSR 3, Quality" without your choosing it.
The city is then drawn at two thirds of the resolution and stretched, which looks soft.

| Upscaler | What it does here |
|---|---|
| **Disabled** | Full resolution. The sharpest picture |
| AMD FSR 3, Ultra Quality | Almost no gain (+1.6 %) |
| AMD FSR 3, Quality | +10 %, softer |
| AMD FSR 3, Balanced | +14.5 %, softer still |
| AMD FSR 3, Performance | +17 % |
| AMD FSR 4, Intel XeSS 3 | **Do not choose these.** They do nothing here, and anti-aliasing stops working: full resolution with jagged edges |

## What each setting costs

Against a base of shadows Medium, anti-aliasing TAA, upscaler Disabled and Level of Detail 0.25.

| Setting | Change | Frame rate |
|---|---|---|
| **Level of Detail** | 0.35 | −5 % |
| | 0.5 | −11 % |
| | 1.0 | −26 % |
| **Shadows** | High | −7 % |
| | Low | +5.5 % (shadow edges look stair-stepped up close) |
| | off | +8 % |
| **Volumetric clouds** | off | +4 % |
| Distant clouds | off | nothing measurable |
| Anti-aliasing | any of None, FXAA, SMAA, TAA | within 1.5 % of each other |
| Fog, volumetrics, ambient occlusion, reflections | each off | about +1 % each |

- **Anti-aliasing is nearly free, so choose by the picture.** TAA smooths edges most; SMAA leaves about a third of
  strong edges hard; FXAA sits between.
- **Level of Detail is the one to leave low.** It is paid on the processor, where this port has the least to spare.

## Three places to start

| | Settings | Benchmark |
|---|---|---|
| **Sharp** (the Studio's daily settings) | shadows Medium, TAA, upscaler Disabled | 39.5 FPS |
| **Middle** | the same with clouds off and shadows Low | 44.3 FPS (+12.5 %) |
| **Fast** | shadows Low, clouds off, FSR 3 Balanced | 49.6 FPS (+25.5 %), soft |

Shadows High with Level of Detail 0.35 reads 34.8 FPS. Nothing tried went above 49.6: beyond that the
limit is not in the game's settings.

## What this does not tell you

- **How a large city runs.** The benchmark is one scene. Population and traffic load the processor in ways it
  does not show.
- **A laptop.** The MacBook's profile draws at half resolution with a sharpening filter (Dynamic Resolution),
  and how that sits with the new upscaler has not been measured.
- **Why 1.6.4 is slower.** The same settings read 12.5 % lower than in October on game 1.6.2. macOS changed in
  between as well, so the cause is not known.
