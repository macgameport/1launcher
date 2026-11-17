#!/bin/bash
# Thin wrapper for the DEFAULT stack (Wine 11 + DXMT). The real launcher is in the runtime folder
# (bash common/paths.sh prints it), because macOS TCC blocks app-bundle execution of scripts inside
# ~/Documents ("Operation not permitted"): the .app shortcut could not run it from here.
# Edit the repo copy and run scripts/setup.sh, not this file. The rule below is common/paths.sh's, inline,
# because this file is copied out of the repo. (A Wine 10 + D3DMetal sibling existed until 2026-11-09.)
D="$HOME/Library/Application Support/1launcher/cities-skylines-2"
[ ! -e "$D" ] && [ -d "$HOME/cs2-patch" ] && [ ! -L "$HOME/cs2-patch" ] && D="$HOME/cs2-patch"
exec bash "${CS2_PATCH_DIR:-$D}/launch-cs2-dxmt11.sh" "$@"
