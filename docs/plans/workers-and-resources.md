# Workers & Resources: Soviet Republic, the third game: what it will need

**Status: investigation, drafted 2026-11-27 on James's question ("should we investigate what we think will be
needed for w&r?"). Not checked, and not a plan to build from.** It gathers what is known and what must be
measured first. The plan to build comes after the probes in section 4, and it is checked before any code.
Order (James, 2026-11-25): Surviving Mars's Utopia update is tested first, then this game.

## 1. What is known

**From the store (official), read 2026-11-27 through the Steam store API
(`https://store.steampowered.com/api/appdetails?appids=784150`):**
- Steam app ID **784150**. Developer 3Division, publisher Hooded Horse. 1.0 released 2024-06-20.
- Windows only: no macOS build, no Linux build.
- 64-bit Windows 10. DirectX 11 minimum, "12 recommended". Storage 9 GB. RAM 6 GB minimum, 8 GB recommended.
- Single-player. No third-party DRM, no external account, and no anti-cheat listed. Steam Workshop, and a level
  editor.
- Also sold DRM-free on GOG and on Epic, so the game itself does not need Steam to run. Whether the Steam
  build is wrapped with Steam's DRM is not known.

**From this Mac:** Steam's package cache in the two game wrappers (both written 2026-11-24 and 25) says the
account owns 784150 (`launcher-window --owned 784150 <packageinfo.vdf>` answers `owned`). The Windows Steam's
cache, older, answers `not-owned`.

**Community, unverified:**
- **The renderer is D3D11.** Players report DirectX 11.1, and no D3D12, Vulkan or OpenGL path is known
  (Steam forum, 2024-06-27). So it is a candidate for both of the project's engines: Wine 11 with DXMT
  (Cities: Skylines II's) and Wine 10 with D3DMetal 3.0 (Surviving Mars's).
- **It has its own start window** at every launch, with "Play and save" buttons for Win7 and for
  Win8.1/Win10, plus sound settings (dedoimedo, 2024-02-02). A ProtonDB report skips it by starting another
  executable; the names are not known yet.
- **ProtonDB rates it platinum** (196 reports, 2026-11-27,
  `https://www.protondb.com/api/v1/reports/summaries/784150.json`). Under Proton:
  - Sound is the recurring fault: garbled or shrill, mostly when a save loads. The fixes are the Win7 button
    and native `xaudio2_7` (`WINEDLLOVERRIDES="xaudio2_7=n,b"`). CodeWeavers' forum has an "xwma issue"
    thread.
- **Mac reports are few and disagree** (applegamingwiki, macgamingdb, Steam forum):

  | Route | Result |
  |---|---|
  | CrossOver 25.0, M4 Pro | "Good", 34–40 fps at 1080p medium |
  | CrossOver 24.0.1, M1 Max, macOS 15 (2024-09) | does not load, Wine error at boot |
  | Whisky (GPTK), 2024-03 | start window, then a black screen and a Wine error |
  | Parallels on Windows 11 ARM | runs well |

  Nothing is reported for DXMT, for D3DMetal 3.0 or for plain Wine.
- Saves sit in the game folder (`media_soviet\save`), with Steam Cloud on. Workshop mods come through the Steam
  client.
- Updates are frequent: four between 2025-12 and 2026-06. All are content; none is known to change the
  renderer.
- PCGamingWiki and CodeWeavers' pages refused automated reading (HTTP 403). They are worth reading in a
  browser before the probes.

## 2. What the repo asks of a new game

A new game is a folder of this repo, written against `common/test-game-contract.sh`, and it joins three
lists (`CLAUDE.md`). Measured against today's tree:

- **The folder.** A plain name, for example `workers-and-resources/`. It holds
  `scripts/install.sh` and `scripts/setup.sh`, which must parse, plus the game's launcher, the builder of its
  app, and a guide.
- **The installer's settings**, as `surviving-mars-relaunched/scripts/install.sh` sets them:
  - `GAME_TITLE`, `GAME_APPID=784150`.
  - `GAME_DIR` and `GAME_EXE`, which are not known yet (section 4).
  - `WRAPPER_VAR`, `STEPS` and `NEED_GB`.
  - `ENGINE_URL`, `ENGINE_BYTES` and `ENGINE_SHA` for the chosen engine.
  - The one-line `WORDS_*` literals, `TOOLS_PART` and `STEAM_ARGS`.
  - A `# Terminal questions: <n>` header that matches its reads.
- **`common/games.tsv`**: one row with the ID, the folder, the title and the guide's address. **This row goes
  on `main` only when the installer works**: a row is a tile in every 14unch3r from the release that carries
  it, and no row is ever removed.
- **`common/wrappers.sh`**:
  - a `game:784150` case in `l1w_row`, with its variable and its program path under the prefix;
  - the ID added to `l1w_games`.
- **`common/paths.sh`**: the game's two folders, its state and its workspace.
- **The window needs nothing new.** The tile's placeholder for this title is "WR" by the rule kept as RC29.

## 3. The shape most likely, to be confirmed by the probes

The closest template is Surviving Mars, not Cities: Skylines II. It is a Steam game in its own wrapper, with
no patches to the game's files, and a launcher that starts Steam and then the game. Cities: Skylines II
carries ten patch scripts for its .NET code, and nothing suggests this game needs any.

Which engine is the main open question.
- **DXMT** is what the project knows best for D3D11.
- **D3DMetal 3.0** ran Surviving Mars where D3DMetal 2.1 did not.

The first probe settles it by booting both. The installer's step count follows from it: Surviving Mars's
seven steps if D3DMetal is chosen (its D3DMetal step), Cities: Skylines II's six if DXMT is.

## 4. Probes before a plan (each on James's word, on the Studio)

Each runs in a scratch wrapper, with nothing of the three real wrappers touched. That means a fresh wrapper
from `common/make-wrapper.sh`, or an APFS clone, as `surviving-mars-relaunched/tools/split-wrapper.sh` made
Surviving Mars's. One Steam on the account at a time.

- **WP1. Boot on each engine.** Install the game in the scratch wrapper's Steam, then start it on Wine 11 +
  DXMT and on Wine 10 + D3DMetal 3.0. Pass: the main menu is reached and a save loads. Record:
  - the executables in the game folder;
  - the start window and its two buttons;
  - the Wine and engine log lines on a failure;
  - the seconds to the menu.
  - These answer `GAME_DIR`, `GAME_EXE` and the engine.
- **WP2. Sound.** Load a save on each mode (Win7 and Win10) and listen. If it is garbled, try native
  `xaudio2_7`, and record where that DLL would come from. A redistributable fetched by the installer is a new
  kind of download for the project, with its own fixed size and checksum (`common/fetch.sh`).
- **WP3. The start window.** Can the launcher go past it, by another executable or by an argument? If not,
  the player clicks it each time, and the guide says which button to press.
- **WP4. Steam.** Does the Steam build start with Steam not running? This says whether the launcher needs the
  licence wait Surviving Mars has (15 s). It also checks whether Steam Cloud and Workshop work in the wrapper.
- **WP5. A first number.** The frame rate in a mid-sized city at the Studio's resolution, as a reference
  only. Not a performance pass.

## 5. Open risks, most serious first

1. **It may not boot on either engine.** Two of the three Mac reports through Wine failed at boot, and none
   is for our engines.
2. **Sound** under Wine, and where native `xaudio2_7` would come from.
3. **The start window** at every launch.
4. **Its weight late in a game:** it is a heavy simulation, and on this Mac it runs under Rosetta.
5. **Frequent updates.** These matter only if a patch to the game's files turns out to be needed.

## 6. Questions for James

- **Which Mac runs WP1.** The Studio, with nothing else running.
- **The folder's name.** `workers-and-resources` is suggested. The name is a label: the published address is
  the Steam ID, so a rename later is only a change to its row.
- **The DLC.** Which DLC the account owns, and whether the first install installs it.
