# Changelog

One section per release, newest first. A release is a tag, `v<a>.<b>.<c>`, and a page on GitHub whose text is
its section here. What `main` holds and no release names yet is under "Unreleased". The installer's pasted line
installs from the `release` branch, which is moved to a version separately, so a version can exist here before
the pasted line installs it.

## Unreleased

**Setup renames the Wine wrappers in `~/Applications`** (docs/plans/wrapper-names.md). Spotlight offered them
beside the game's app, and a wrapper opened directly starts Steam outside the launcher and its lock. The new
names are ones nobody types:

- Cities: Skylines II: `CS2dxmt11.app` (on an older Mac `CS2.app`) becomes `wrapper-949230.app`;
- the Windows Steam, where the engine build made one: `CS2dxmt11-pk110.app` becomes `wrapper-0.app`;
- Surviving Mars: Relaunched: `SurvivingMars.app` becomes `wrapper-3215050.app`.

Every script now finds a wrapper by a mark setup writes into its `Info.plist`, never by its name, so a name is a
label and can be anything. It is a rename with nothing copied, and setup says what it renamed. It stops, before it
changes anything, while the game, a launch or an install is using the game's wrapper; it skips a rename it cannot
make safely, among them while Steam is open in the Windows Steam's wrapper, says why, and tries again at its next
run. `--check` says what a run would do. A new install makes its wrapper under the new name, marked. **At the first start
after the rename macOS may ask once more whether wine64 may use the microphone** (it keeps that answer by the
program's path, which changes with the wrapper's name). Answer it, either way: Steam waits for the answer and then
signs in with its saved login. The launcher says so if the sign-in takes long, and waits ten minutes where it used
to give up after two.

**What stops working until you point it at the new name:** anything of yours that names an old path: a Dock item
made from a wrapper, an alias, a saved command, a Porting Kit entry. The game's app, 14unch3r and S734M.app find a
wrapper whatever its name, after a rename by hand too.

**To keep the old names**, put `L1_KEEP_WRAPPER_NAMES=1` in front of setup, the installer or the pasted line, for
that run. A wrapper named in `CS2_WRAPPER` or `SM_WRAPPER` keeps its name too.

**Going back to an earlier version on a renamed Mac:** Cities: Skylines II still starts, but that version's setup
finds no wrapper; Surviving Mars does not start until its wrapper is renamed back. To rename one back, quit the
game and Steam, `mv` it to its old name, and run setup once: from then on setup leaves it under that name. Both
`INSTALL.md` files say how, in "The Wine wrappers' names" and "The wrapper's name".

## v0.2.0 (2026-11-17)

**Setup moves a Cities: Skylines II install out of the home folder.** Until now everything was in one
folder, `~/cs2-patch`. From this version:

- what the game runs (the launcher, `repatch.sh`, the patch scripts) is in the runtime folder,
  `~/Library/Application Support/1launcher/cities-skylines-2`;
- everything else that was in the old folder (your own notes, test output, source trees), if there is
  anything else, is in the workspace, `~/Library/Developer/1launcher/cities-skylines-2`.

On a Mac that has an install in `~/cs2-patch`, the next run of setup moves it: a rename, with nothing
copied or deleted. It says what it moved, and rebuilds the game's app to start the launcher in its new place.
Setup stops, and moves nothing, while the game or another install is running; if the move cannot be made
safely for another reason, it skips the move, says why, and goes on in `~/cs2-patch` until its next run.
`bash scripts/setup.sh --check` says what a run would do. A new install goes straight to the runtime folder.

**What stops working until you point it at the runtime folder:** anything of yours that names `~/cs2-patch`:
a `.command` launcher copied out of the repository earlier, a shell alias or saved command, a second app made
with `make-shortcut.sh --name`.

**To decline the move**, name the old folder on every run of setup. In a clone:

```bash
CS2_PATCH_DIR=~/cs2-patch bash scripts/setup.sh
```

With the installer's pasted line, the same words and a space in front of it:

```bash
CS2_PATCH_DIR=~/cs2-patch /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)" 1launcher-install 949230
```

**The way back** for a folder that has already moved is in the install guide, under
[If your install was made before the folders moved](https://github.com/macgameport/1launcher/blob/v0.2.0/cities-skylines-2/INSTALL.md):
the moves given there, then the line that declines, on every run. That keeps later fixes coming. `v0.1.0`
after the same moves is for someone who wants the old code as well, and it costs every later fix. The setup
of `v0.1.0`, run on a Mac whose folder has moved, builds a new `~/cs2-patch` beside the new folders.

The pasted line installs from the `release` branch, which is moved to this version separately: until it is,
the pasted line still installs into `~/cs2-patch`.

## v0.1.0 (2026-11-16)

The first tagged release. The repository holds macOS ports of two Windows games, each in its own folder, for
Apple Silicon Macs with Rosetta 2:

- **Cities: Skylines II**, on Wine 11 with DXMT. Setup applies ten patches to the game's files (game build
  26404411, 1.6.4f1). [Install guide](https://github.com/macgameport/1launcher/blob/v0.1.0/cities-skylines-2/INSTALL.md)
- **Surviving Mars: Relaunched**, on Wine 10 with Apple's D3DMetal 3.0. [Install guide](https://github.com/macgameport/1launcher/blob/v0.1.0/surviving-mars-relaunched/INSTALL.md)

Both are installed by one line pasted into Terminal, and both are listed in **14unch3r**, a small window that
starts the game you click. [README](https://github.com/macgameport/1launcher/blob/v0.1.0/README.md)

This is the last version whose setup keeps a Cities: Skylines II install in `~/cs2-patch`. A later version
moves that folder into `~/Library`: the files the game runs to `~/Library/Application Support/1launcher/`.
`v0.2.0` will be the release that names that change, says what it moves and how to decline it.

To stay on this version:

- in a clone of this repository: `git checkout v0.1.0`
- with the installer: the pasted line with `v0.1.0` after the game's Steam app ID, for Cities: Skylines II

```bash
/bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)" 1launcher-install 949230 v0.1.0
```
