#!/bin/bash
# test-make-wrapper.sh -- common/make-wrapper.sh with HOME at a scratch folder (docs/plans/simple-install.md,
# NT1). A stub curl copies fixture archives made here: the engine a tar under its .tar.7z name, the template a
# tar inside a tar whose files carry a quarantine attribute, as the real ones are (measured 2026-11-10). The
# pins are rewritten in a scratch copy. The template's launcher is a stub that records its call and makes a
# fake prefix; wine64 and wineserver are stubs. So are sw_vers, pgrep, lsof, killall and pkill: this Mac's own
# macOS and its processes are never read, and the only processes signalled are ones started here. The stub
# sleep makes a look 0.02 s and counts it, so nothing waits for real. No network, no Wine, nothing written
# outside the scratch folder (the real ~/Applications is listed before and after), and every link made here
# points into the scratch folder.
#   bash common/test-make-wrapper.sh             exit 0 = every case passed
#   MUTANT=1  ...  the sha256 not compared; must exit 1
#   MUTANT=2  ...  step 1's existence test removed (an existing target replaced); must exit 1
#   MUTANT=3  ...  step 9's test before the move removed; must exit 1
#   MUTANT=4  ...  the build folder left behind on failure; must exit 1
#   MUTANT=5  ...  a failed prefix still moved to the target; must exit 1
#   MUTANT=6  ...  L1_DOWNLOADS used without the sha256; must exit 1
#   MUTANT=7  ...  the bundle not renamed before the prefix is made; must exit 1
#   MUTANT=8  ...  both quarantine guards removed; must exit 1
#   MUTANT=9  ...  a live build folder removed; must exit 1
#   MUTANT=10 ...  a pin changed in the script alone; must exit 1
#   MUTANT=11 ...  a default engine put back; must exit 1
#   FT3 (docs/plans/first-run-findings.md, 2.3), the line about macOS 28's notice:
#   MUTANT=12 ...  the lines on every macOS; must exit 1
#   MUTANT=13 ...  the lines after the prefix step; must exit 1
#   FT3b (docs/plans/first-run-findings.md, 2.5), the template's program ended while another Wine is open:
#   MUTANT=14 ...  ended with no other wineserver; must exit 1
#   MUTANT=15 ...  a link left; must exit 1
#   MUTANT=16 ...  the removal with a slash after the name and -r (the scratch target's file is gone); must exit 1
#   MUTANT=17 ...  a real folder removed; must exit 1
#   MUTANT=18 ...  the modes of the registry files and Info.plist not set; must exit 1
#   MUTANT=19 ...  the modes of Logs not set; must exit 1
#   MUTANT=20 ...  ended before system.reg is there; must exit 1
#   MUTANT=21 ...  the Mac Driver section not asked for; must exit 1
#   MUTANT=22 ...  the stillness not waited for; must exit 1
#   MUTANT=23 ...  the check that no wineserver holds this prefix removed; must exit 1
#   MUTANT=24 ...  an lsof failure read as "holds nothing"; must exit 1
#   MUTANT=25 ...  the other Wine closed by the script (the stand-in started here); must exit 1
#   MUTANT=26 ...  the redirection taken off the group that ends the program; must exit 1
#   MUTANT=27 ...  the program not ended in cleanup; must exit 1
#   MUTANT=28 ...  the exit code of an ended program read; must exit 1
#   MUTANT=29 ...  the redirection taken off cleanup's group; must exit 1
#   MUTANT=30 ...  the prefix's path not resolved before lsof's lines are compared; must exit 1
#   MUTANT=31 ...  pgrep asked for every user's wineservers; must exit 1
#   MUTANT=32 ...  users/Wineskin taken as a folder when it is a link; must exit 1
#   MUTANT=33 ...  ended before userdef.reg is there; must exit 1
#   MUTANT=34 ...  the marking removed (WT10, docs/plans/wrapper-names.md); must exit 1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REAL="$HERE/make-wrapper.sh"
LAUNCHER="$HERE/../cities-skylines-2/launchers/launch-cs2-dxmt11.sh"
CS2_INSTALL="$HERE/../cities-skylines-2/scripts/install.sh"
REALHOME="$HOME"
T="$(mktemp -d /tmp/make-wrapper-test.XXXX)"
OTHER=""; OWN=""   # two sleeps started below, standing for another wrapper's wineserver and the new prefix's
trap '[ -n "$OTHER$OWN" ] && kill $OTHER $OWN 2>/dev/null; hdiutil detach -quiet "$T/cs-mnt" 2>/dev/null; rm -rf "$T"' EXIT
S="$T/make-wrapper.sh"; cp "$REAL" "$S"; cp "$HERE/fetch.sh" "$T/fetch.sh"; cp "$HERE/wrappers.sh" "$T/wrappers.sh"
mutate() {  # <sed expression> <grep that proves it applied>: in the copy or in its fetch.sh
  sed -i '' "$1" "$S" "$T/fetch.sh"; cat "$S" "$T/fetch.sh" | grep -q -- "$2" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  1) mutate 's#|| \[ "\$got" != "\$want" \]; then$#; then#' 'bytes" \] ; then$' ;;
  2) mutate 's#^{ \[ -e "\$TARGET" \] || \[ -L "\$TARGET" \]; } \&\& die "\$(tilde "\$TARGET") already exists.*#: step1#' '^: step1$'
     mutate 's#^{ \[ -e "\$TARGET" \] || \[ -L "\$TARGET" \]; } \&\& die "\$(tilde "\$TARGET") appeared while.*#rm -rf "$TARGET"#' '^rm -rf "\$TARGET"$' ;;
  3) mutate 's#^{ \[ -e "\$TARGET" \] || \[ -L "\$TARGET" \]; } \&\& die "\$(tilde "\$TARGET") appeared while.*#: step9#' '^: step9$' ;;
  4) mutate 's#^  rm -rf "\$B"$#  :#' '^  :$' ;;
  5) mutate 's#^\[ "\$rc" = 0 \] || fail_log "\$B/prefix.log" "the prefix was not made.*#: prefix#' '^: prefix$' ;;
  6) mutate 's#if \[ "\$(stat -f %z "\$out")" = "\$bytes" \] \&\& \[ "\$(sha "\$out")" = "\$want" \]; then#if true; then#' 'if true; then' ;;
  7) mutate 's#^mv "\$APP0" "\$APP" || die .*#APP="$APP0"#' '^APP="\$APP0"$' ;;
  8) mutate 's#/usr/bin/tar --no-mac-metadata -xf "\$B/t1/#/usr/bin/tar -xf "$B/t1/#' '/usr/bin/tar -xf "\$B/t1/'
     mutate 's#^xattr -dr com.apple.quarantine "\$TOP".*#: guard#' '^: guard$' ;;
  9) mutate 's#if kill -0 "\$p" 2>/dev/null; then#if false; then#' 'if false; then' ;;
  10) mutate 's#^TEMPLATE_SHA=fbe276bb.*#TEMPLATE_SHA=1111111111111111111111111111111111111111111111111111111111111111#' '^TEMPLATE_SHA=1111' ;;
  11) mutate 's#^CHECK=0; TARGET=""; ENGINE_URL=""; ENGINE_BYTES=""; ENGINE_SHA=""$#CHECK=0; TARGET=""; ENGINE_URL=x; ENGINE_BYTES=1; ENGINE_SHA=x#' '^CHECK=0; TARGET=""; ENGINE_URL=x' ;;
  12) mutate 's#^case "\$(sw_vers -productVersion 2>/dev/null)" in 27|27\.\*)$#case 27 in 27|27.*)#' '^case 27 in 27|27\.\*)$' ;;
  13) mutate '/^case "\$(sw_vers -productVersion/,/^esac$/{H;d;};/^# 8\. /{x;p;x;}' '^case "\$(sw_vers -productVersion'   # the block moved to before step 8
      [ "$(grep -n -e '^case "\$(sw_vers -productVersion' -e '^# 8\. ' "$S" | tail -n 1 | cut -d: -f2 | cut -c1-4)" = '# 8.' ] \
        && [ "$(grep -n -e '^case "\$(sw_vers -productVersion' -e 'WSS-wineprefixcreate' "$S" | tail -n 1 | cut -d: -f2 | cut -c1-4)" = 'case' ] \
        || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  14) mutate 's#if \[ "\$c" = "\$last" \] \&\& \[ "\$OTHER" = 1 \]; then still#if [ "$c" = "$last" ]; then still#' 'if \[ "\$c" = "\$last" \]; then still' ;;
  15) mutate 's#\[ -L "\$p" \] \&\& rm -f -- "\$p"$#[ -L "$p" ] \&\& : left#' '\[ -L "\$p" \] && : left$' ;;
  16) mutate 's#\[ -L "\$p" \] \&\& rm -f -- "\$p"$#[ -L "$p" ] \&\& rm -rf -- "${p:?}/"#' '\[ -L "\$p" \] && rm -rf -- "\${p:?}/"$' ;;   # only ever met by the links this file makes
  17) mutate 's#\[ -L "\$p" \] \&\& rm -f -- "\$p"$#rm -rf -- "${p:?}"#' '; rm -rf -- "\${p:?}"$' ;;
  18) mutate 's#^  chmod 666 "\$SS/prefix/system.reg".*#  : modes#' '^  : modes$' ;;
  19) mutate 's#^  chmod 777 "\$APP/Contents/SharedSupport/Logs".*#  : modes#' '^  : modes$' ;;
  20) mutate 's#^  \[ -f "\$SS/prefix/system.reg" \] \&\& \[ -f "\$SS/prefix/user.reg" \]#  [ -f "$SS/prefix/user.reg" ]#' '^  \[ -f "\$SS/prefix/user.reg" \] ' ;;
  21) mutate 's#^    \&\& grep -qF .*Mac Driver.*#    \&\& true#' '^    && true$' ;;
  22) mutate 's#if \[ "\$still" -ge "\$STILL_LOOKS" \] \&\&#if [ "$still" -ge 0 ] \&\&#' 'if \[ "\$still" -ge 0 \] &&' ;;
  23) mutate 's#-ge "\$STILL_LOOKS" \] \&\& \[ "\$OWN" = 0 \] \&\&#-ge "$STILL_LOOKS" ] \&\&#' '-ge "\$STILL_LOOKS" \] && \[ "\$UNSURE" = 0 \]' ;;
  24) mutate 's#^    else UNSURE=1$#    else OTHER=1#' '^    else OTHER=1$' ;;
  25) mutate 's#then OWN=1; else OTHER=1; fi#then OWN=1; else OTHER=1; kill "$s"; fi#' 'else OTHER=1; kill "\$s"; fi' ;;   # $s is a pid the pgrep stub named: a sleep started here
  26) mutate 's#^      } 2> /dev/null$#      }#' '^      }$' ;;
  27) mutate 's#^  if \[ -n "\$LP" \]; then .*#  if false; then#' '^  if false; then$' ;;
  28) mutate 's#kill -0 "\$LP" || { wait "\$LP"; LP=""; }#kill -0 "$LP" || { wait "$LP"; rc=$?; LP=""; }#' '{ wait "\$LP"; rc=\$?; LP=""; }'
      mutate 's#^  rc=0 .*#  : rc#' '^  : rc$' ;;
  29) mutate 's#^    } 2> /dev/null$#    }#' '^    }$' ;;
  30) mutate 's#^HOLD="\$(cd "\$B" \&\& pwd -P)/\$NAME/Contents/SharedSupport/prefix"#HOLD="$SS/prefix"#' '^HOLD="\$SS/prefix"' ;;
  31) mutate 's#pgrep -x -U "\$ME" wineserver#pgrep -x wineserver#' 'pgrep -x wineserver' ;;
  32) mutate 's# \&\& \[ ! -L "\$SS/prefix/drive_c/users/Wineskin" \]##' '^    && \[ -d "\$SS/prefix/drive_c/users/Wineskin" \] \\$' ;;
  33) mutate 's# \&\& \[ -f "\$SS/prefix/userdef.reg" \]##' '\[ -f "\$SS/prefix/user.reg" \] \\$' ;;
  34) mutate 's#^  e="\$(l1w_mark "\$APP" .*#  e=""  \# MUTANT-34#' 'MUTANT-34' ;;
esac

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

# --- the pins, as published (docs/plans/simple-install.md, 1.3), before the copy's pins are rewritten
pinned() { sed -n "s/^$1=\"\{0,1\}\([^\"]*\)\"\{0,1\}$/\1/p" "${2:-$S}"; }
check "pins: the engine's address, size and sha256 (in Cities: Skylines II's installer)" "$(pinned ENGINE_URL "$CS2_INSTALL") $(pinned ENGINE_BYTES "$CS2_INSTALL") $(pinned ENGINE_SHA "$CS2_INSTALL")" \
  "https://github.com/vitor251093/porting-kit-engines/releases/download/wineskin/WS12Wine11.0_DXMT-v0.80.tar.7z 180784324 afdaab97e84ec7064b8fddf47192c95b18b8bbb9cc3aa4d81060a57d7b4dced0"
check "pins: the template's address, size and sha256" "$(pinned TEMPLATE_URL) $(pinned TEMPLATE_BYTES) $(pinned TEMPLATE_SHA)" \
  "https://github.com/vitor251093/porting-kit-wrappers/releases/download/Wineskin-3.0.6-2/Wineskin.app.tar.7z 53110672 fbe276bba96d5582b99c511117abb1e035a988b8c1aeefe27c32df266a07907a"
ENGINE_URL="$(pinned ENGINE_URL "$CS2_INSTALL")"; TEMPLATE_URL="$(pinned TEMPLATE_URL)"
ENGINE="$(basename "$ENGINE_URL")"; TEMPLATE="$(basename "$TEMPLATE_URL")"

# --- the source
check "the library path is exported with the launcher's own line" \
  "$(grep -cxF "$(grep -m1 '^export DYLD_FALLBACK_LIBRARY_PATH=' "$LAUNCHER")" "$REAL")" 1
check "no nohup, env, setsid or kill -9 outside comments" \
  "$(grep -v '^[[:space:]]*#' "$REAL" | grep -cE '(^|[^-[:alnum:]_])(nohup|setsid)([^[:alnum:]_]|$)|(^|[^[:alnum:]_-])env |kill -9')" 0

# --- fixtures
F="$T/fix"; mkdir -p "$F/src" "$F/good" "$F/bad"
mk_template() {   # <out> [two-apps|no-launcher|no-freetype|no-gnutls|no-inotify]
  local d="$F/src/tpl" a; rm -rf "$d"; mkdir -p "$d/in" "$d/out"
  a="$d/in/Wineskin-3.0.6-2.app"; mkdir -p "$a/Contents/MacOS" "$a/Contents/Frameworks" "$a/Contents/SharedSupport/Logs"
  for l in libfreetype.6.dylib libgnutls.30.dylib libinotify.0.dylib libSDL2.dylib; do : > "$a/Contents/Frameworks/$l"; done
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<plist version="1.0"><dict><key>CFBundleName</key><string>Wineskin</string></dict></plist>' > "$a/Contents/Info.plist"
  case "${2:-}" in
    no-freetype) rm "$a/Contents/Frameworks/libfreetype.6.dylib" ;;
    no-gnutls) rm "$a/Contents/Frameworks/libgnutls.30.dylib" ;;
    no-inotify) rm "$a/Contents/Frameworks/libinotify.0.dylib" ;;
    two-apps) mkdir -p "$d/in/Other.app/Contents" ;;
  esac
  if [ "${2:-}" != no-launcher ]; then
    cat > "$a/Contents/MacOS/wineskinlauncher" << 'L'
#!/bin/bash
b="$(cd "$(dirname "$0")/../.." && pwd)"
echo "LAUNCHER $* bundle=$(basename "$b")" >> "$LAUNCHER_CALLS"
[ -n "${STUB_MAKE_TARGET:-}" ] && { mkdir -p "$STUB_MAKE_TARGET"; echo mine > "$STUB_MAKE_TARGET/mark"; }
p="$b/Contents/SharedSupport/prefix"
mkdir -p "$p/drive_c/windows" "$p/drive_c/users/Wineskin"
[ -n "${STUB_NO_SYSREG:-}" ] || : > "$p/system.reg"
[ -n "${STUB_NO_USERS:-}" ] && rm -rf "$p/drive_c/users/Wineskin"
echo "prefix made for $HOME/x"
if [ -n "${STUB_WAITS:-}" ]; then
  # FT3b: the rest of a prefix as the real program has it at its wait (userdef.reg, user.reg with the Mac
  # Driver section and mode 777, Info.plist, a log, the six links), then the wait, counted in the script's
  # looks, then what the real program does after it. The links' targets are under the scratch folder or
  # nothing is made.
  case "${STUB_TARGETS:-}" in "${STUB_SCRATCH:-/nowhere}"/*) ;; *) echo "LAUNCHER refused: targets not in the scratch folder" >> "$LAUNCHER_CALLS"; exit 9 ;; esac
  looks() { wc -l < "$LOOKS" | tr -d ' '; }
  if [ -n "${STUB_IGNORE_TERM:-}" ]; then trap 'echo "LAUNCHER TERM ignored" >> "$LAUNCHER_CALLS"' TERM
  else trap 'echo "LAUNCHER TERM at look $(looks)" >> "$LAUNCHER_CALLS"; trap - TERM; kill -TERM $$' TERM   # dies of the signal, as a program that does not catch it
  fi
  echo $$ >> "$STUB_PIDS"
  u="$p/drive_c/users/Wineskin"
  touch "$b/Contents/Info.plist"; chmod 755 "$b/Contents/Info.plist"
  : > "$b/Contents/SharedSupport/Logs/LastRunX11.log"
  if [ -n "${STUB_WINESKIN_LINK:-}" ]; then rmdir "$u"; ln -s "$STUB_TARGETS/Wineskin" "$u"
  else
    for l in Desktop Documents Downloads Music Pictures Videos; do
      t="$l"; [ "$l" = Videos ] && t=Movies
      ln -s "$STUB_TARGETS/$t" "$u/$l"
    done
    [ -n "${STUB_REAL_DOCS:-}" ] && { unlink "$u/Documents"; mkdir "$u/Documents"; echo mine > "$u/Documents/kept"; }
  fi
  [ -n "${STUB_NO_USERDEF:-}" ] || : > "$p/userdef.reg"
  if [ -z "${STUB_NO_USERREG:-}" ]; then
    printf '%s\n' 'WINE REGISTRY Version 2' '' > "$p/user.reg.new"
    [ -n "${STUB_NO_MACDRIVER:-}" ] || printf '%s\n' '[Software\\Wine\\Mac Driver] 1763150000' '"RetinaMode"="n"' >> "$p/user.reg.new"
    chmod 777 "$p/user.reg.new"; mv "$p/user.reg.new" "$p/user.reg"
  fi
  k=0; base="$(looks)"
  while [ "$k" -lt "${STUB_GROW:-0}" ]; do   # one more file in the prefix at each of the script's next looks
    if [ "$(looks)" -gt "$((base + k))" ]; then
      k=$((k + 1)); g="$(looks)"; : > "$p/grown$k"
      [ "$k" = "$STUB_GROW" ] && echo "LAUNCHER grown at look $g" >> "$LAUNCHER_CALLS"
    else /bin/sleep 0.01
    fi
  done
  w="$STUB_WAITS"; [ "$w" = 0 ] && w=300   # 0 is "for ever": 300 looks or 60 s here, so that no case can hang
  while [ "$(looks)" -lt "$w" ] && [ "$SECONDS" -lt 60 ]; do /bin/sleep 0.01; done
  if [ -z "${STUB_WINESKIN_LINK:-}" ]; then   # unlink takes a link away and never what it points at
    for l in Desktop Documents Downloads Music Pictures Videos; do [ -L "$u/$l" ] && unlink "$u/$l"; done
  fi
  [ -f "$p/user.reg" ] && chmod 666 "$p/user.reg"
  echo "LAUNCHER ended by itself at look $(looks)" >> "$LAUNCHER_CALLS"
fi
[ -n "${STUB_LAUNCHER_FAIL:-}" ] && exit 1   # a whole prefix and a failure: only the exit code tells
exit 0
L
    chmod +x "$a/Contents/MacOS/wineskinlauncher"
  fi
  xattr -w com.apple.quarantine "0082;00000000;Test;" "$a/Contents/Frameworks/libSDL2.dylib"
  [ -f "$a/Contents/MacOS/wineskinlauncher" ] && xattr -w com.apple.quarantine "0082;00000000;Test;" "$a/Contents/MacOS/wineskinlauncher"
  (cd "$d/in" && /usr/bin/tar -cf "$d/out/Wineskin.app.tar" .)
  (cd "$d/out" && /usr/bin/tar -cf "$1" Wineskin.app.tar)
}
mk_engine() {   # <out> [no-wine64|silent]
  local d="$F/src/eng"; rm -rf "$d"; mkdir -p "$d/wswine.bundle/bin" "$d/wswine.bundle/lib"
  case "${2:-}" in
    no-wine64) ;;
    silent) printf '#!/bin/bash\n' > "$d/wswine.bundle/bin/wine64" ;;
    *) printf '#!/bin/bash\necho wine-11.0\n' > "$d/wswine.bundle/bin/wine64" ;;
  esac
  printf '#!/bin/bash\necho "WINESERVER $* prefix=$WINEPREFIX" >> "$WINESERVER_CALLS"\n' > "$d/wswine.bundle/bin/wineserver"
  chmod +x "$d/wswine.bundle/bin"/*
  (cd "$d" && /usr/bin/tar -cf "$1" wswine.bundle)
}
mk_template "$F/good/$TEMPLATE"; mk_engine "$F/good/$ENGINE"
pin() { sed -i '' "s#^$1=.*#$1=$2#" "$S"; }
sz() { stat -f %z "$1"; }
sh256() { shasum -a 256 "$1" | awk '{ print $1 }'; }
EB=""; ES=""
pin_to() {   # <folder>: the copy's template pin, and the engine options, made those of the fixtures in <folder>
  EB="$(sz "$1/$ENGINE")"; ES="$(sh256 "$1/$ENGINE")"
  pin TEMPLATE_BYTES "$(sz "$1/$TEMPLATE")"; pin TEMPLATE_SHA "$(sh256 "$1/$TEMPLATE")"
}
pin_to "$F/good"; cp "$S" "$S.good"; EB_GOOD="$EB"; ES_GOOD="$ES"

# --- stubs
mkdir -p "$T/bin"
cat > "$T/bin/curl" << 'C'
#!/bin/bash
echo "CURL $*" >> "$CURL_CALLS"
[ -n "${STUB_CURL_EXIT:-}" ] && exit "$STUB_CURL_EXIT"
out=""; url=""
while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2 ;; *) url="$1"; shift ;; esac; done
cp "$FIXDIR/$(basename "$url")" "$out"
C
printf '#!/bin/bash\necho "Filesystem 1024-blocks Used Available Capacity Mounted"\necho "/dev/x 999999999 1 ${STUB_DF_KB:-99999999} 1%% /"\n' > "$T/bin/df"
printf '#!/bin/bash\nif [ "$1" = -u ] && [ -n "${STUB_ROOT:-}" ]; then echo 0; else exec /usr/bin/id "$@"; fi\n' > "$T/bin/id"
# sw_vers -productVersion: STUB_MACOS, 27.2 unless a case sets it; "none" is a version that cannot be read
cat > "$T/bin/sw_vers" << 'V'
#!/bin/bash
v="${STUB_MACOS:-27.2}"
[ "$v" = none ] && exit 1
if [ "$*" = -productVersion ]; then echo "$v"; else printf 'ProductName:\t\tmacOS\nProductVersion:\t\t%s\nBuildVersion:\t\t00A000\n' "$v"; fi
V
# sleep: a look is 0.02 s, and each is a line in $LOOKS, which the launcher stub counts its wait in
printf '#!/bin/bash\necho x >> "$LOOKS"\nexec /bin/sleep 0.02\n' > "$T/bin/sleep"
# pgrep: the pids in STUB_SERVERS (sleeps started here, standing for wineservers), until look STUB_SERVERS_UNTIL
cat > "$T/bin/pgrep" << 'P'
#!/bin/bash
echo "PGREP $*" >> "$PGREP_CALLS"
[ -n "${STUB_SERVERS:-}" ] || exit 1
[ -n "${STUB_SERVERS_UNTIL:-}" ] && [ "$(wc -l < "$LOOKS")" -ge "$STUB_SERVERS_UNTIL" ] && exit 1
printf '%s\n' $STUB_SERVERS
P
# lsof -p <pid>: a pid in STUB_OWN holds the prefix being made (named by its resolved path, as the real one
# names it), any other pid holds another wrapper's. STUB_LSOF_FAIL: exit 1; STUB_LSOF_EMPTY: nothing printed
cat > "$T/bin/lsof" << 'O'
#!/bin/bash
echo "LSOF $*" >> "$LSOF_CALLS"
[ "$1" = -p ] || exit 1
[ -n "${STUB_LSOF_FAIL:-}" ] && exit 1
[ -n "${STUB_LSOF_EMPTY:-}" ] && exit 0
echo "COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME"
case " ${STUB_OWN:-} " in
  *" $2 "*) for d in "${STUB_BUILD_IN:-$HOME/Applications}"/.l1-wrapper.*/*.app/Contents/SharedSupport/prefix; do
              [ -d "$d" ] && echo "wineserver $2 player cwd DIR 1,4 96 7 $(cd "$d" && pwd -P)"
            done ;;
  *) echo "wineserver $2 player cwd DIR 1,4 96 7 /Volumes/elsewhere/Other.app/Contents/SharedSupport/prefix" ;;
esac
O
printf '#!/bin/bash\necho "KILLALL $*" >> "$SWEEP_CALLS"\nexit 1\n' > "$T/bin/killall"
printf '#!/bin/bash\necho "PKILL $*" >> "$SWEEP_CALLS"\nexit 1\n' > "$T/bin/pkill"
chmod +x "$T/bin"/*
export LAUNCHER_CALLS="$T/launcher.calls" CURL_CALLS="$T/curl.calls" WINESERVER_CALLS="$T/wineserver.calls"
export PGREP_CALLS="$T/pgrep.calls" LSOF_CALLS="$T/lsof.calls" SWEEP_CALLS="$T/sweep.calls" LOOKS="$T/looks"
export STUB_PIDS="$T/stub.pids" STUB_SCRATCH="$T"
: > "$SWEEP_CALLS"
real_apps() { ls -A "$REALHOME/Applications" 2>/dev/null | shasum | cut -c1-12; }
REAL_BEFORE="$(real_apps)"

n=0
newh() {
  n=$((n + 1)); H="$T/h$n"; mkdir -p "$H/Applications"; : > "$LAUNCHER_CALLS"; : > "$CURL_CALLS"; : > "$WINESERVER_CALLS"
  : > "$PGREP_CALLS"; : > "$LSOF_CALLS"; : > "$LOOKS"; : > "$STUB_PIDS"
  TG="$T/tg$n"; export STUB_TARGETS="$TG"   # what the launcher stub's links point at: folders here, a file in each
  for l in Desktop Documents Downloads Music Pictures Movies Wineskin; do mkdir -p "$TG/$l"; echo "the player's" > "$TG/$l/file"; done
}
W="Applications/wrapper-949230.app"
eng() { echo --engine-url "$ENGINE_URL" --engine-bytes "$EB" --engine-sha "$ES"; }   # no space in any of them
run() {   # the copy, HOME at $H (newh first, in the calling shell); output in $H.out; echoes the exit code.
  # The engine options always; --wrapper ~/Applications/wrapper-949230.app unless the arguments name one.
  local w=""; case " $* " in *" --wrapper "*) ;; *) w="$H/$W" ;; esac
  env -u CS2_WRAPPER -u L1_DOWNLOADS HOME="$H" PATH="$T/bin:$PATH" FIXDIR="${FIXDIR:-$F/good}" \
    ${DL:+L1_DOWNLOADS="$DL"} bash "$S" $(eng) ${w:+--wrapper "$w"} "$@" > "$H.out" 2>&1 < /dev/null
  echo $?
}
left() { ls -A "$H/Applications" 2>/dev/null | grep -c '^\.l1-wrapper'; }
calls() { wc -l < "$1" | tr -d ' '; }
said() { grep -c -- "$1" "$H.out"; }

# --- made
newh; check "made: exit 0" "$(run)" 0
check "  ...wine64, prefix/system.reg, users/Wineskin and Frameworks at the target; no build folder left" \
  "$([ -x "$H/$W/Contents/SharedSupport/wine/bin/wine64" ] && echo y):$([ -f "$H/$W/Contents/SharedSupport/prefix/system.reg" ] && echo y):$([ -d "$H/$W/Contents/SharedSupport/prefix/drive_c/users/Wineskin" ] && echo y):$([ -f "$H/$W/Contents/Frameworks/libinotify.0.dylib" ] && echo y):$(left)" "y:y:y:y:0"
check "  ...no file of it carries the quarantine attribute" "$(xattr -lr "$H/$W" 2>/dev/null | grep -c quarantine)" 0
check "  ...the launcher called once, with WSS-wineprefixcreate, from a bundle named as the target" \
  "$(cat "$LAUNCHER_CALLS")" "LAUNCHER WSS-wineprefixcreate bundle=wrapper-949230.app"
check "  ...curl called twice, with exactly the two published addresses" \
  "$(calls "$CURL_CALLS"):$(grep -c " $TEMPLATE_URL\$" "$CURL_CALLS"):$(grep -c " $ENGINE_URL\$" "$CURL_CALLS")" "2:1:1"
check "  ...curl given the https-only options" "$(grep -c -- '--proto =https --tlsv1.2 -fL --retry 2' "$CURL_CALLS")" 2
check "  ...wineserver waited for, in the new prefix" "$(grep -c "WINESERVER -w prefix=.*/wrapper-949230.app/Contents/SharedSupport/prefix\$" "$WINESERVER_CALLS")" 1
check "  ...the wrapper's path printed with ~, and the home folder nowhere in the output" "$(said 'made ~/Applications/wrapper-949230.app'):$(grep -c "$H" "$H.out")" "1:0"
newh; rm -rf "$H/Applications"; check "no ~/Applications yet: made, the folder made" "$(run):$([ -d "$H/$W/Contents/SharedSupport/prefix" ] && echo y)" "0:y"
newh; mkdir -p "$T/else$n"; check "--wrapper elsewhere: made there" "$(run --wrapper "$T/else$n/My Wrapper.app"):$([ -f "$T/else$n/My Wrapper.app/Contents/SharedSupport/prefix/system.reg" ] && echo y)" "0:y"
newh; mkdir -p "$T/cw$n"
rc="$(env -u L1_DOWNLOADS CS2_WRAPPER="$T/cw$n/W.app" HOME="$H" PATH="$T/bin:$PATH" FIXDIR="$F/good" bash "$S" $(eng) > "$H.out" 2>&1; echo $?)"
check "CS2_WRAPPER is not read: no --wrapper is exit 2, nothing made" "$rc:$([ -d "$T/cw$n/W.app" ] && echo made || echo none)" "2:none"
for drop in --engine-url --engine-bytes --engine-sha; do
  newh; set -- $(eng); a=(); while [ $# -gt 0 ]; do [ "$1" = "$drop" ] || a+=("$1" "$2"); shift 2; done
  rc="$(env -u L1_DOWNLOADS HOME="$H" PATH="$T/bin:$PATH" FIXDIR="$F/good" bash "$S" "${a[@]}" --wrapper "$H/$W" > "$H.out" 2>&1; echo $?)"
  check "two of the three engine options (no $drop): exit 2, nothing downloaded" "$rc:$(calls "$CURL_CALLS")" "2:0"
done
newh; rc="$(env -u L1_DOWNLOADS HOME="$H" PATH="$T/bin:$PATH" FIXDIR="$F/good" bash "$S" --wrapper "$H/$W" > "$H.out" 2>&1; echo $?)"
check "no engine options: exit 2, nothing downloaded, nothing made" "$rc:$(calls "$CURL_CALLS"):$([ -e "$H/$W" ] && echo made || echo none)" "2:0:none"
newh; mkdir -p "$H/Applications/.l1-wrapper.dead1/x"; echo 999999 > "$H/Applications/.l1-wrapper.dead1/pid"
check "a build folder left by a dead install: removed, and the wrapper made" "$(run):$(left):$(said 'removed a build folder')" "0:0:1"

# --- refused before anything: nothing made, no build folder left, curl not called
refused() {   # <name> <exit> [<want exit>]
  check "$1: exit ${3:-1}, nothing at the target, no build folder, nothing downloaded" \
    "$2:$([ -e "$H/$W/Contents/SharedSupport" ] && echo made || echo none):$(left):$(calls "$CURL_CALLS")" "${3:-1}:none:0:0"
}
newh; mkdir -p "$H/$W"; echo keep > "$H/$W/mark"
check "target exists as a folder: exit 1, left as it was, nothing downloaded" "$(run):$(cat "$H/$W/mark"):$(calls "$CURL_CALLS"):$(left)" "1:keep:0:0"
newh; echo file > "$H/$W"
check "target exists as a file: exit 1, left as it was, nothing downloaded" "$(run):$(cat "$H/$W"):$(calls "$CURL_CALLS")" "1:file:0"
newh; ln -s "$T/nowhere" "$H/$W"
check "target is a dangling link: exit 1, left as it was, nothing downloaded" "$(run):$([ -L "$H/$W" ] && echo link):$(calls "$CURL_CALLS")" "1:link:0"
newh; refused "a relative path" "$(run --wrapper Applications/X.app)"
newh; refused "a name not ending .app" "$(run --wrapper "$H/Applications/wrapper-949230")"
newh; refused "a name with a character the template launcher cannot take" "$(run --wrapper "$H/Applications/CS2;x.app")"
newh; refused "a folder that does not exist" "$(run --wrapper "$T/nofolder$n/X.app")"
newh; refused "too little space" "$(STUB_DF_KB=1000 run)"
newh; refused "run as root" "$(STUB_ROOT=1 run)"
newh; mkdir -p "$H/Applications/.l1-wrapper.live1"; echo $$ > "$H/Applications/.l1-wrapper.live1/pid"
check "another install's live build folder: exit 3, it is left, nothing downloaded" \
  "$(run):$([ -d "$H/Applications/.l1-wrapper.live1" ] && echo kept):$(calls "$CURL_CALLS")" "3:kept:0"
check "a wrong option: exit 2" "$(bash "$S" --nope > /dev/null 2>&1; echo $?)" 2
check "--wrapper with no value: exit 2" "$(bash "$S" --wrapper > /dev/null 2>&1; echo $?)" 2
CS=""
if hdiutil create -quiet -size 20m -fs 'Case-sensitive APFS' -volname l1cstest "$T/cs.dmg" 2>/dev/null \
   && mkdir -p "$T/cs-mnt" && hdiutil attach -quiet -nobrowse -mountpoint "$T/cs-mnt" "$T/cs.dmg" 2>/dev/null; then
  CS=1; mkdir -p "$T/cs-mnt/Apps"
  newh; refused "a folder on a case-sensitive volume" "$(run --wrapper "$T/cs-mnt/Apps/X.app")"
  check "  ...and it says why" "$(said 'tells capitals from small letters')" 1
  hdiutil detach -quiet "$T/cs-mnt"
fi
check "the case-sensitive disk image could be made and mounted" "${CS:-no}" 1

# --- failed after a download: nothing made, no build folder left
failed() {   # <name> <exit>
  check "$1: exit 1, nothing at the target, no build folder" "$2:$([ -e "$H/$W" ] && echo made || echo none):$(left)" "1:none:0"
}
newh; failed "curl fails with an HTTP error" "$(STUB_CURL_EXIT=22 run)"; check "  ...says it is no longer published" "$(said 'no longer published')" 1
newh; failed "curl fails otherwise" "$(STUB_CURL_EXIT=6 run)"; check "  ...says to check the network" "$(said 'Check the network')" 1
ES=0000; newh; failed "a wrong sha256 of the engine" "$(run)"; check "  ...both checksums said" "$(grep -c 'sha256 [0-9a-f]\{64\}, where .* sha256 0000 was expected' "$H.out")" 1
ES="$ES_GOOD"; cp "$S.good" "$S"; pin TEMPLATE_SHA 0000; newh; failed "a wrong sha256 of the template" "$(run)"
cp "$S.good" "$S"; EB=5; newh; failed "a wrong size" "$(run)"; EB="$EB_GOOD"
bad() {   # <template kind> <engine kind>: fixtures in $F/bad, the copy pinned to them
  rm -f "$F/bad"/*; mk_template "$F/bad/$TEMPLATE" "$1"; mk_engine "$F/bad/$ENGINE" "$2"; cp "$S.good" "$S"; pin_to "$F/bad"
}
for k in two-apps no-launcher no-freetype no-gnutls no-inotify; do
  newh; bad "$k" ok; failed "a template: $k" "$(FIXDIR="$F/bad" run)"
done
newh; bad ok no-wine64; failed "an engine without wine64" "$(FIXDIR="$F/bad" run)"
newh; bad ok silent; failed "wine64 --version prints nothing" "$(FIXDIR="$F/bad" run)"
cp "$S.good" "$S"; EB="$EB_GOOD"; ES="$ES_GOOD"
newh; failed "the template's launcher exits 1 after making a whole prefix" "$(STUB_LAUNCHER_FAIL=1 run)"
check "  ...its last lines shown, with the home folder as ~" "$(said 'prefix made for ~/x'):$(grep -c "$H" "$H.out")" "1:0"
newh; failed "the prefix has no system.reg" "$(STUB_NO_SYSREG=1 run)"
check "  ...its last lines shown, with the home folder as ~" "$(said 'prefix made for ~/x'):$(grep -c "$H" "$H.out")" "1:0"
newh; failed "the prefix has no users/Wineskin" "$(STUB_NO_USERS=1 run)"
newh; T9="$H/$W"; rc="$(STUB_MAKE_TARGET="$T9" run)"
check "the target appears while the prefix is made: exit 1, its folder left as it was, nothing nested" \
  "$rc:$(cat "$T9/mark"):$(ls -A "$T9" | tr '\n' ' '):$(left)" "1:mine:mark :0"
check "  ...caught before the move" "$(said 'appeared while the wrapper was being made')" 1

# --- FT3: macOS 28's notice is foretold on macOS 27, before Wine first starts, and on no other macOS
notice() { grep -E 'App Update Required|nothing needs updating|making the Wine prefix' "$H.out" | tr '\n' '|'; }
N1='  macOS may show "App Update Required ... will not open in macOS 28", now or when the game starts.'
N2='  That is expected and nothing needs updating. The game needs macOS 27: do not upgrade to macOS 28.'
newh; check "macOS 27.2: the two lines about the notice, once, before the prefix step" "$(run):$(notice)" "0:$N1|$N2|  making the Wine prefix (about 30 s)|"
newh; check "macOS 27 with no minor number: said" "$(STUB_MACOS=27 run):$(notice)" "0:$N1|$N2|  making the Wine prefix (about 30 s)|"
for v in 26.4 28.0 127.2 none; do
  newh; check "macOS $v: not said, the wrapper made" "$(STUB_MACOS="$v" run):$(notice):$(said 'macOS')" "0:  making the Wine prefix (about 30 s)|:0"
done

# --- FT3b: the template's program waits for as long as any other Wine is open; step 7 ends it itself
looks_of() { sed -n "s/^$1=\([0-9]*\) .*/\1/p" "$REAL"; }
STILL="$(looks_of STILL_LOOKS)"
check "the looks are counted by three variables at the script's head" "$STILL:$(looks_of END_LOOKS):$(looks_of EXIT_LOOKS)" "10:10:5"
check "the header says that a new pin of the template repeats the comparison, names and modes" \
  "$(sed -n '2,/^set -u$/p' "$REAL" | grep -c 'a new pin of the template repeats the comparison, names and modes')" 1
/bin/sleep 300 & OTHER=$!
/bin/sleep 300 & OWN=$!
other_alive() { if kill -0 "$OTHER" 2>/dev/null; then echo alive; else echo gone; fi; }
PX="Contents/SharedSupport/prefix"; UW="$PX/drive_c/users/Wineskin"
links_left() { local l o=""; for l in Desktop Documents Downloads Music Pictures Videos; do [ -L "$1/$UW/$l" ] && o="$o$l "; done; echo "$o"; }
ALLKEPT="Desktop Documents Downloads Music Pictures Movies Wineskin "
kept() { local l o=""; for l in $ALLKEPT; do [ "$(cat "$TG/$l/file" 2>/dev/null)" = "the player's" ] && o="$o$l "; done; echo "$o"; }
modes() { stat -f %Lp "$1/$PX/system.reg" "$1/$PX/user.reg" "$1/$PX/userdef.reg" "$1/Contents/Info.plist" "$1/Contents/SharedSupport/Logs" "$1/Contents/SharedSupport/Logs/LastRunX11.log" 2>&1 | tr '\n' ' '; }
how() { sed -n '2,$p' "$LAUNCHER_CALLS" | sed 's/ at look [0-9]*$//' | tr '\n' '|'; }   # how the launcher stub left its wait
term_look() { sed -n 's/^LAUNCHER TERM at look //p' "$LAUNCHER_CALLS" | head -n 1; }
bash_lines() { grep -ciE 'terminated|killed|no such process' "$H.out"; }
stub_gone() {   # the launcher stub of the case just run: gone; or alive, and then ended here (this file started it)
  local q; q="$(tail -n 1 "$STUB_PIDS" 2>/dev/null)"
  case "$q" in ''|*[!0-9]*) echo none; return ;; esac
  if kill -0 "$q" 2>/dev/null; then kill -KILL "$q" 2>/dev/null; echo alive; else echo gone; fi
}
ONE='  Another Windows program is open on this Mac, so the installer finished this step itself.'

newh; check "another wineserver, a whole prefix that stands still, --mark game 949230: made, exit 0" "$(STUB_WAITS=0 STUB_SERVERS="$OTHER" run --mark game 949230)" 0
check "  ...marked, the marking after the modes are set (WT10)" "$(plutil -extract L1Role raw -o - "$H/$W/Contents/Info.plist" 2>/dev/null)" game-wrapper
check "  ...the program ended by this script, once, after the still looks and not before, and gone" \
  "$(how):$([ "$(term_look)" -ge "$STILL" ] && echo late):$(stub_gone)" "LAUNCHER TERM|:late:gone"
check "  ...each of the six links gone, by name, and nothing else in users/Wineskin" "$(links_left "$H/$W"):$(ls -A "$H/$W/$UW" | tr '\n' ' ')" ":"
check "  ...each link's target still holds its file" "$(kept)" "$ALLKEPT"
check "  ...the three registry files and Info.plist have mode 666, Logs and the file in it 777" "$(modes "$H/$W")" "666 666 666 666 777 777 "
check "  ...the one line said once, after the prefix line" "$(grep -E 'making the Wine prefix|Another Windows program' "$H.out" | tr '\n' '|')" "  making the Wine prefix (about 30 s)|$ONE|"
check "  ...no line of bash's about the ended program" "$(bash_lines)" 0
check "  ...the wrapper moved into place, no build folder left" "$([ -f "$H/$W/$PX/system.reg" ] && [ -x "$H/$W/Contents/SharedSupport/wine/bin/wine64" ] && echo y):$(left)" "y:0"
check "  ...pgrep asked for this user's wineservers only, lsof for the one pgrep named" \
  "$(sort -u "$PGREP_CALLS"):$(sort -u "$LSOF_CALLS")" "PGREP -x -U $(/usr/bin/id -u) wineserver:LSOF -p $OTHER"
check "  ...the stand-in for the other Wine is still alive" "$(other_alive)" alive
[ "$(other_alive)" = alive ] || { echo "the stand-in was ended: stopping here, so that its number is not named again"; exit 1; }
newh; check "a folder named Documents that is not a link: made" "$(STUB_WAITS=0 STUB_REAL_DOCS=1 STUB_SERVERS="$OTHER" run):$(stub_gone)" "0:gone"
check "  ...it and its file are left, the five links gone, their targets' files there" \
  "$(cat "$H/$W/$UW/Documents/kept" 2>/dev/null):$(links_left "$H/$W"):$(ls -A "$H/$W/$UW" | tr '\n' ' '):$(kept)" "mine::Documents :$ALLKEPT"
newh; check "the prefix grows for 5 more looks: made" "$(STUB_WAITS=0 STUB_GROW=5 STUB_SERVERS="$OTHER" run)" 0
g="$(sed -n 's/^LAUNCHER grown at look //p' "$LAUNCHER_CALLS")"; t="$(term_look)"
check "  ...ended only once it had stood still for the set looks after that, with all it grew" \
  "$([ -n "$g" ] && [ -n "$t" ] && [ "$t" -ge "$((g + STILL))" ] && echo y):$(ls "$H/$W/$PX" | grep -c '^grown'):$(stub_gone)" "y:5:gone"

not_ended() {   # <name> <exit of a run whose launcher stub leaves its wait by itself, after 25 looks>
  check "$1: not ended by this script, the line not said, made" "$2:$(how):$(said 'finished this step itself'):$(bash_lines):$(stub_gone)" "0:LAUNCHER ended by itself|:0:0:gone"
}
newh; not_ended "no other wineserver, however long the program takes" "$(STUB_WAITS=25 STUB_SERVERS= run)"
check "  ...pgrep was asked, and lsof was not" "$(sort -u "$PGREP_CALLS"):$(calls "$LSOF_CALLS")" "PGREP -x -U $(/usr/bin/id -u) wineserver:0"
newh; not_ended "another wineserver, no user.reg" "$(STUB_WAITS=25 STUB_NO_USERREG=1 STUB_SERVERS="$OTHER" run)"
newh; not_ended "another wineserver, no userdef.reg" "$(STUB_WAITS=25 STUB_NO_USERDEF=1 STUB_SERVERS="$OTHER" run)"
newh; not_ended "another wineserver, no Mac Driver section in user.reg" "$(STUB_WAITS=25 STUB_NO_MACDRIVER=1 STUB_SERVERS="$OTHER" run)"
newh; not_ended "another wineserver, users/Wineskin a link" "$(STUB_WAITS=25 STUB_WINESKIN_LINK=1 STUB_SERVERS="$OTHER" run)"
check "  ...the folder the link points at still holds its file" "$(kept)" "$ALLKEPT"
newh; check "another wineserver, no system.reg: not ended by this script, the line not said; exit 1 as today" \
  "$(STUB_WAITS=25 STUB_NO_SYSREG=1 STUB_SERVERS="$OTHER" run):$(how):$(said 'finished this step itself'):$(said 'it has no system.reg'):$(stub_gone):$(left)" "1:LAUNCHER ended by itself|:0:1:gone:0"
newh; not_ended "a wineserver holds this prefix, another running beside it" "$(STUB_WAITS=25 STUB_SERVERS="$OWN $OTHER" STUB_OWN="$OWN" run)"
newh; not_ended "only this prefix's own wineserver" "$(STUB_WAITS=25 STUB_SERVERS="$OWN" STUB_OWN="$OWN" run)"
newh; not_ended "lsof fails" "$(STUB_WAITS=25 STUB_LSOF_FAIL=1 STUB_SERVERS="$OTHER" run)"
newh; not_ended "lsof prints nothing" "$(STUB_WAITS=25 STUB_LSOF_EMPTY=1 STUB_SERVERS="$OTHER" run)"
newh; not_ended "the other wineserver goes away during the still looks" "$(STUB_WAITS=25 STUB_SERVERS="$OTHER" STUB_SERVERS_UNTIL=6 run)"
newh; mkdir -p "$T/real$n"; ln -s "$T/real$n" "$T/lnk$n"
not_ended "a build folder reached through a link: the prefix's own wineserver is still matched" \
  "$(STUB_WAITS=25 STUB_SERVERS="$OWN $OTHER" STUB_OWN="$OWN" STUB_BUILD_IN="$T/lnk$n" run --wrapper "$T/lnk$n/X.app")"
check "  ...made there" "$([ -f "$T/real$n/X.app/$PX/system.reg" ] && echo y)" y

newh; failed "the program exits 1 by itself after 4 looks, another wineserver running" "$(STUB_WAITS=4 STUB_LAUNCHER_FAIL=1 STUB_SERVERS="$OTHER" run)"
check "  ...said as today, and not ended by this script" "$(said 'the prefix was not made (the template.s launcher exited 1)'):$(how):$(stub_gone)" "1:LAUNCHER ended by itself|:gone"
newh; failed "the program ignores TERM" "$(STUB_WAITS=0 STUB_IGNORE_TERM=1 STUB_SERVERS="$OTHER" run)"
check "  ...asked by the step, then by cleanup, which ends it; said why; no line of bash's" \
  "$(how):$(stub_gone):$(said 'did not end when asked'):$(bash_lines)" "LAUNCHER TERM ignored|LAUNCHER TERM ignored|:gone:1:0"
check "  ...the links' targets still hold their files after the build folder's removal" "$(kept)" "$ALLKEPT"

# Interrupted during the step, by TERM to the script alone. A real Control-C is INT to the whole foreground
# group, which a program started in the background does not get (measured, bash 3.2); INT cannot be sent
# from here, since this file may itself be run with INT ignored. Either way the signal does not reach the
# program, and only cleanup can end it.
newh
STUB_WAITS=0 env -u CS2_WRAPPER -u L1_DOWNLOADS HOME="$H" PATH="$T/bin:$PATH" FIXDIR="$F/good" \
  bash "$S" $(eng) --wrapper "$H/$W" --mark game 949230 > "$H.out" 2>&1 < /dev/null &
sp=$!
i=0; while { [ ! -s "$STUB_PIDS" ] || [ "$(calls "$LOOKS")" -lt 3 ]; } && [ "$i" -lt 500 ]; do /bin/sleep 0.02; i=$((i + 1)); done
{ kill -TERM "$sp"; wait "$sp"; rc=$?; } 2> /dev/null
check "interrupted during the step: exit 143, the program ended by cleanup and gone, the build folder gone, nothing at the target" \
  "$rc:$(how):$(stub_gone):$(left):$([ -e "$H/$W" ] && echo made || echo none)" "143:LAUNCHER TERM|:gone:0:none"
check "  ...no line of bash's, and the links' targets still hold their files" "$(bash_lines):$(kept)" "0:$ALLKEPT"

check "the stand-in for the other Wine is alive after every case, and neither killall nor pkill was ever called" "$(other_alive):$(calls "$SWEEP_CALLS")" "alive:0"
kill "$OTHER" "$OWN" 2>/dev/null; wait "$OTHER" "$OWN" 2>/dev/null; OTHER=""; OWN=""

# --- marked (WT10)
newh; check "made with --mark game 949230: exit 0" "$(run --mark game 949230)" 0
grep -q . "$H.out" && [ "$(said made)" = 0 ] && sed "s/^/   | /" "$H.out"
mk() { plutil -extract "$1" raw -o - "$H/$W/Contents/Info.plist" 2>/dev/null || echo none; }
check "  ...the finished wrapper carries the marker, and no L1RenamePending" "$(mk L1Role):$(mk L1SteamAppID):$(mk L1RenamePending)" "game-wrapper:949230:none"
newh; check "made with --mark steam: the marker steam-wrapper, no app ID" "$(run --mark steam):$(mk L1Role):$(mk L1SteamAppID)" "0:steam-wrapper:none"
newh; check "--mark game with no app ID: a wrong option, exit 2" "$(run --mark game)" 2

# --- L1_DOWNLOADS
DL="$T/dl"; mkdir -p "$DL"; cp "$F/good/$ENGINE" "$DL/"
newh; check "L1_DOWNLOADS with a matching engine: made, curl called for the template only" \
  "$(run):$(calls "$CURL_CALLS"):$(grep -c "$ENGINE" "$CURL_CALLS")" "0:1:0"
echo tampered >> "$DL/$ENGINE"
newh; check "a non-matching one: dropped with a line, and downloaded" \
  "$(run):$(calls "$CURL_CALLS"):$(said 'not the file this was tested with: downloading it instead')" "0:2:1"
DL=""

# --- --check
newh; rm -rf "$H/Applications"
check "--check: exit 0, says what it would download, writes nothing, does not make ~/Applications" \
  "$(run --check):$(said 'would make ~/Applications/wrapper-949230.app'):$(calls "$CURL_CALLS"):$([ -e "$H/Applications" ] && echo made || echo none)" "0:1:0:none"
newh; check "--check with too little space: exit 1" "$(STUB_DF_KB=1000 run --check)" 1
check "--help prints the usage" "$(bash "$S" --help | grep -c 'exit 0 = made')" 1

check "nothing written to the real ~/Applications" "$(real_apps)" "$REAL_BEFORE"
echo "$fails failure(s)"
[ "$fails" = 0 ]
