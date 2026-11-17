# Changelog

One section per release, newest first. A release is a tag, `v<a>.<b>.<c>`, and a page on GitHub whose text is
its section here. What `main` holds and no release names yet is under "Unreleased". The installer's pasted line
installs from the `release` branch, which is moved to a version separately, so a version can exist here before
the pasted line installs it.

## Unreleased

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
