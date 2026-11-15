#!/bin/bash
# make-wrapper.sh -- make a Wineskin wrapper from two public files of Porting Kit's releases, with no Porting
# Kit app (docs/plans/simple-install.md, 2.2; docs/plans/shared-installer.md, 2.1): the Wineskin
# template, pinned here, and the engine, pinned by the game's installer and given as three options, each
# checked against a fixed sha256, then the prefix made by the template's own launcher, as Wineskin Winery
# makes it. Measured on the Studio, 2026-11-10: about 40 s once the two files are here.
#
#   bash common/make-wrapper.sh ENGINE --wrapper <path.app>           # make it (an absolute path)
#   bash common/make-wrapper.sh ENGINE --wrapper <path.app> --check   # say what it would do; write nothing
#   where ENGINE is --engine-url <url> --engine-bytes <n> --engine-sha <sha256>, all three
#
#   exit 0 = made (or, with --check, could be made); 1 = refused or failed, said why, nothing left;
#   2 = a wrong option; 3 = another install is making a wrapper in that folder.
# It never replaces anything: the target must not exist. It builds in a hidden folder beside the target,
# .l1-wrapper.XXXXXX, removed when it exits, and moves the finished wrapper in last.
# L1_DOWNLOADS=<folder> names a folder of the two files already downloaded: a copy of one is used only if
# its size and sha256 match.
# Step 7 does, in the place of the template's program, what that program does after its wait
# (docs/plans/first-run-findings.md, 2.5). That was found by comparing two wrappers made from this pin, not
# read from its source: a new pin of the template repeats the comparison, names and modes.
set -u
TEMPLATE_URL="https://github.com/vitor251093/porting-kit-wrappers/releases/download/Wineskin-3.0.6-2/Wineskin.app.tar.7z"
TEMPLATE_BYTES=53110672
TEMPLATE_SHA=fbe276bba96d5582b99c511117abb1e035a988b8c1aeefe27c32df266a07907a
NEED_KB=$((6 * 1024 * 1024))
STILL_LOOKS=10   # step 7 looks once a second: the prefix has stood still for this many before its maker is ended
END_LOOKS=10     # the looks an ended maker is given to go
EXIT_LOOKS=5     # the looks cleanup gives it before KILL

tilde() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
say() { echo "  $*"; }
die() { echo "  !! $*"; exit 1; }

CHECK=0; TARGET=""; ENGINE_URL=""; ENGINE_BYTES=""; ENGINE_SHA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --wrapper) if [ $# -lt 2 ] || [ -z "$2" ]; then echo "--wrapper needs a value"; exit 2; fi
               TARGET="$2"; shift 2 ;;
    --engine-url|--engine-bytes|--engine-sha)
               if [ $# -lt 2 ] || [ -z "$2" ]; then echo "$1 needs a value"; exit 2; fi
               case "$1" in --engine-url) ENGINE_URL="$2" ;; --engine-bytes) ENGINE_BYTES="$2" ;; *) ENGINE_SHA="$2" ;; esac
               shift 2 ;;
    -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)"; exit 2 ;;
  esac
done
{ [ -n "$ENGINE_URL" ] && [ -n "$ENGINE_BYTES" ] && [ -n "$ENGINE_SHA" ]; } \
  || { echo "--engine-url, --engine-bytes and --engine-sha are all needed (try --help)"; exit 2; }
case "$ENGINE_BYTES" in *[!0-9]*) echo "--engine-bytes must be a number"; exit 2 ;; esac
[ -n "$TARGET" ] || { echo "--wrapper is needed (try --help)"; exit 2; }
[ "$(id -u)" = 0 ] && die "do not run this as root (with sudo): it would leave files only root can change in your home folder"

# 1. the target
case "$TARGET" in /*) ;; *) die "the wrapper's path must be absolute: $TARGET" ;; esac
TARGET="${TARGET%/}"
NAME="$(basename "$TARGET")"
printf '%s' "$NAME" | grep -Eq '^[A-Za-z0-9._ -]+\.app$' \
  || die "the wrapper's name must be letters, digits, spaces, dots, hyphens or underscores, ending .app: $NAME"
{ [ -e "$TARGET" ] || [ -L "$TARGET" ]; } && die "$(tilde "$TARGET") already exists; this script never replaces anything"

# 2. its folder: made if it is ~/Applications, on a volume that ignores case, with room
DIR="$(dirname "$TARGET")"
if [ ! -d "$DIR" ]; then
  if [ "$DIR" = "$HOME/Applications" ] && [ "$CHECK" = 0 ]; then mkdir -p "$DIR" || die "$(tilde "$DIR") could not be made"
  elif [ "$DIR" != "$HOME/Applications" ]; then die "the folder $(tilde "$DIR") does not exist"
  fi
fi
HAVE="$DIR"; while [ ! -d "$HAVE" ]; do HAVE="$(dirname "$HAVE")"; done
[ -d "$(printf '%s' "$HAVE" | tr '[:lower:]' '[:upper:]')" ] \
  || die "$(tilde "$HAVE") is on a volume that tells capitals from small letters; Steam and the game need one that does not"
FREE_KB="$(df -k "$HAVE" 2>/dev/null | awk 'NR == 2 { print $4 }')"
case "$FREE_KB" in ''|*[!0-9]*) die "the free space of $(tilde "$HAVE") could not be read" ;; esac
[ "$FREE_KB" -ge "$NEED_KB" ] || die "the wrapper needs 6 GB free; $(tilde "$HAVE") has $((FREE_KB / 1024 / 1024)) GB"
if [ "$CHECK" = 1 ]; then
  say "would make $(tilde "$TARGET"), downloading two files of Porting Kit's:"
  say "  $TEMPLATE_URL ($((TEMPLATE_BYTES / 1000000)) MB)"
  say "  $ENGINE_URL ($((ENGINE_BYTES / 1000000)) MB)"
  exit 0
fi

# 3. older build folders, then this one
for old in "$DIR"/.l1-wrapper.*; do
  [ -d "$old" ] || continue
  p="$(cat "$old/pid" 2>/dev/null)"
  case "$p" in ''|*[!0-9]*) ;; *) if kill -0 "$p" 2>/dev/null; then
    echo "  !! another install is making a wrapper in $(tilde "$DIR") (process $p). Wait for it, or quit it, then try again."
    exit 3
  fi ;; esac
  rm -rf "$old" && say "removed a build folder left by an install that stopped: $(tilde "$old")"
done
B="$(mktemp -d "$DIR/.l1-wrapper.XXXXXX")" || die "a build folder could not be made in $(tilde "$DIR")"
echo $$ > "$B/pid"
APP="$B/$NAME"
SS="$APP/Contents/SharedSupport"
LP=""   # the template's program, while step 7 has it running
cleanup() {
  if [ -n "$LP" ]; then   # Control-C does not reach a program started in the background. KILL: it is not Steam
    { kill -TERM "$LP"   # bash prints its line about a killed job at the next command: all of it in one group
      i=0; while kill -0 "$LP" && [ "$i" -lt "$EXIT_LOOKS" ]; do sleep 1; i=$((i + 1)); done
      kill -0 "$LP" && kill -KILL "$LP"
      wait "$LP"
    } 2> /dev/null
  fi
  if [ -x "$SS/wine/bin/wineserver" ] && [ -d "$SS/prefix" ]; then   # without the library path it exits 134
    WINEPREFIX="$SS/prefix" DYLD_FALLBACK_LIBRARY_PATH="$APP/Contents/Frameworks:$SS/wine/lib:/usr/lib:/usr/local/lib" \
      "$SS/wine/bin/wineserver" -k >/dev/null 2>&1
  fi
  rm -rf "$B"
}
trap cleanup EXIT
fail_log() {   # <log> <message>: the last twenty lines of a step's output, then die
  echo "  -- the last lines of its output:"
  tail -n 20 "$1" 2>/dev/null | sed "s#$HOME#~#g" | sed 's/^/     /'
  die "$2"
}

# 4. the two files
. "$(dirname "$0")/fetch.sh"
fetch "$TEMPLATE_URL" "$TEMPLATE_BYTES" "$TEMPLATE_SHA" "$B/template.tar.7z"
fetch "$ENGINE_URL" "$ENGINE_BYTES" "$ENGINE_SHA" "$B/engine.tar.7z"

# 5. the template: a 7-Zip file holding one tar, whose files carry a quarantine attribute (measured)
mkdir "$B/t1" "$B/t" "$B/e"
/usr/bin/tar -xf "$B/template.tar.7z" -C "$B/t1" > "$B/tar.log" 2>&1 || fail_log "$B/tar.log" "the template could not be unpacked"
INNER="$(ls -A "$B/t1")"
if [ "$(printf '%s\n' "$INNER" | grep -c .)" = 1 ] && [ -f "$B/t1/$INNER" ] && [ "${INNER%.tar}" != "$INNER" ]; then
  /usr/bin/tar --no-mac-metadata -xf "$B/t1/$INNER" -C "$B/t" > "$B/tar.log" 2>&1 || fail_log "$B/tar.log" "the template's inner archive could not be unpacked"
  TOP="$B/t"
else
  TOP="$B/t1"
fi
xattr -dr com.apple.quarantine "$TOP" 2>/dev/null
n=0; for a in "$TOP"/*.app; do [ -d "$a" ] && [ ! -L "$a" ] && { n=$((n + 1)); APP0="$a"; }; done
[ "$n" = 1 ] || die "the template holds $n apps at its top, not one"
[ -x "$APP0/Contents/MacOS/wineskinlauncher" ] || die "the template has no Contents/MacOS/wineskinlauncher"
for l in libfreetype libgnutls libinotify; do
  ls "$APP0/Contents/Frameworks/$l"* > /dev/null 2>&1 || die "the template has no $l under Contents/Frameworks"
done
mv "$APP0" "$APP" || die "the template could not be renamed"   # its launcher writes this name into Info.plist

# 6. the engine: XZ data under a .7z name (measured)
/usr/bin/tar --no-mac-metadata -xf "$B/engine.tar.7z" -C "$B/e" > "$B/tar.log" 2>&1 || fail_log "$B/tar.log" "the engine could not be unpacked"
[ -x "$B/e/wswine.bundle/bin/wine64" ] && [ -x "$B/e/wswine.bundle/bin/wineserver" ] \
  || die "the engine has no wswine.bundle/bin/wine64 and wineserver"
mkdir -p "$SS" && mv "$B/e/wswine.bundle" "$SS/wine" || die "the engine could not be moved into the wrapper"

# 7. the prefix, made by the template's own launcher. Wine first starts here, and macOS 27 may then show its
# notice about macOS 28: nothing else says it is expected (docs/plans/first-run-findings.md, 2.3)
case "$(sw_vers -productVersion 2>/dev/null)" in 27|27.*)
  say 'macOS may show "App Update Required ... will not open in macOS 28", now or when the game starts.'
  say 'That is expected and nothing needs updating. The game needs macOS 27: do not upgrade to macOS 28.' ;;
esac
say "making the Wine prefix (about 30 s)"
# The program makes the prefix and then waits until no wineserver runs on the Mac: with another Wine open
# that is for as long as it stays open (85 minutes, once). So it runs in the background and is looked at once
# a second. With no other Wine open nothing differs: it ends by itself and its exit code is read. This script
# ends it only when, at one look, the prefix is whole, no wineserver holds it, and it has stood still for
# STILL_LOOKS looks with another wineserver running at each. The other Wine is never closed.
HOLD="$(cd "$B" && pwd -P)/$NAME/Contents/SharedSupport/prefix"   # the prefix as lsof names it
ME="$(id -u)"
prefix_whole() {   # the Mac Driver section is the sign that the program's second Wine step has run
  [ -f "$SS/prefix/system.reg" ] && [ -f "$SS/prefix/user.reg" ] && [ -f "$SS/prefix/userdef.reg" ] \
    && [ -d "$SS/prefix/drive_c/users/Wineskin" ] && [ ! -L "$SS/prefix/drive_c/users/Wineskin" ] \
    && grep -qF '[Software\\Wine\\Mac Driver]' "$SS/prefix/user.reg"
}
servers() {   # this user's wineservers. OWN: one holds this prefix; OTHER: one does not; UNSURE: lsof did not say
  local s o; OWN=0; OTHER=0; UNSURE=0
  for s in $(pgrep -x -U "$ME" wineserver 2>/dev/null); do
    if o="$(lsof -p "$s" 2>/dev/null)" && [ -n "$o" ]; then
      if printf '%s\n' "$o" | grep -qF "$HOLD"; then OWN=1; else OTHER=1; fi
    else UNSURE=1
    fi
  done
}
"$APP/Contents/MacOS/wineskinlauncher" WSS-wineprefixcreate > "$B/prefix.log" 2>&1 &
LP=$!; ended=0; still=0; last=""
while kill -0 "$LP" 2>/dev/null; do
  if prefix_whole; then
    c="$(find "$SS/prefix" 2>/dev/null | wc -l | tr -d ' ')"; servers   # find does not follow links
    if [ "$c" = "$last" ] && [ "$OTHER" = 1 ]; then still=$((still + 1)); else still=0; fi
    last="$c"
    if [ "$still" -ge "$STILL_LOOKS" ] && [ "$OWN" = 0 ] && [ "$UNSURE" = 0 ]; then
      # TERM, the looks and the wait in one group: bash prints "Terminated: 15" at the first command after
      # the program dies, so a redirection on the wait alone comes too late. No wait while it is still there.
      { kill -TERM "$LP"
        i=0; while kill -0 "$LP" && [ "$i" -lt "$END_LOOKS" ]; do sleep 1; i=$((i + 1)); done
        kill -0 "$LP" || { wait "$LP"; LP=""; }
      } 2> /dev/null
      ended=1; break
    fi
  else still=0; last=""
  fi
  sleep 1
done
if [ "$ended" = 1 ]; then
  [ -z "$LP" ] || fail_log "$B/prefix.log" "the prefix was not made (the template's launcher did not end when asked)"
  # What the program does after its wait, in this form and no other. The six links point at the player's own
  # folders: a slash after the name, -r, or a pattern under a link would reach into them.
  for n in Desktop Documents Downloads Music Pictures Videos; do
    p="$SS/prefix/drive_c/users/Wineskin/$n"; [ -L "$p" ] && rm -f -- "$p"
  done
  chmod 666 "$SS/prefix/system.reg" "$SS/prefix/user.reg" "$SS/prefix/userdef.reg" "$APP/Contents/Info.plist"
  chmod 777 "$APP/Contents/SharedSupport/Logs" 2> /dev/null; chmod 777 "$APP/Contents/SharedSupport/Logs"/* 2> /dev/null
  say "Another Windows program is open on this Mac, so the installer finished this step itself."
  rc=0   # an ended program's exit code is not read: 143 for one that does not catch the signal
else
  wait "$LP"; rc=$?; LP=""
fi
[ "$rc" = 0 ] || fail_log "$B/prefix.log" "the prefix was not made (the template's launcher exited $rc)"
for f in system.reg drive_c/windows drive_c/users/Wineskin; do
  [ -e "$SS/prefix/$f" ] || fail_log "$B/prefix.log" "the prefix was not made: it has no $f"
done

# 8. Wine itself, with the library path exported as the launcher exports it
export WINEPREFIX="$SS/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$APP/Contents/Frameworks:$SS/wine/lib:/usr/lib:/usr/local/lib"
"$SS/wine/bin/wineserver" -w > /dev/null 2>&1 &
w=$!; i=0; while kill -0 "$w" 2>/dev/null && [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done
kill -0 "$w" 2>/dev/null && "$SS/wine/bin/wineserver" -k > /dev/null 2>&1
V="$("$SS/wine/bin/wine64" --version 2>/dev/null | head -n 1)"
case "$V" in wine-*) ;; *) die "wine64 --version did not answer" ;; esac

# 9. into place, last
{ [ -e "$TARGET" ] || [ -L "$TARGET" ]; } && die "$(tilde "$TARGET") appeared while the wrapper was being made; nothing was replaced"
mv "$APP" "$TARGET" || die "the wrapper could not be moved to $(tilde "$TARGET")"
if [ ! -x "$TARGET/Contents/MacOS/wineskinlauncher" ]; then
  [ -d "$TARGET/$NAME" ] && mv "$TARGET/$NAME" "$APP"   # mv onto a folder that appeared nests the bundle: take it back
  die "$(tilde "$TARGET") appeared while the wrapper was being moved in; nothing of it was replaced"
fi

# 10.
say "made $(tilde "$TARGET") ($(du -sh "$TARGET" | awk '{ print $1 }'), $V)"
say "Wine and the wrapper are Porting Kit's, used as published: https://www.portingkit.com"
exit 0
