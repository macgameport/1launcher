#!/bin/bash
# test-make-launcher-app.sh -- common/make-launcher-app.sh builds 14unch3r.app (docs/plans/launcher-window.md,
# 2.3 and 2.6; W6; docs/plans/launcher-window-look.md, W13). Every build goes into a scratch folder, from a scratch copy of common/ that a mutant may
# edit, with HOME at a scratch folder. The built program is only asked for --folders, --list, --icon and
# --update-tool: the window itself is never opened. No game, no Steam, no Wine. The key L1UpdateDir
# (docs/plans/built-in-update.md, 3.3 and 3.5; UT8) is built from a fourth scratch common/, the only one that holds
# paths.sh, with L1_UPDATE_DIR at scratch folders: the builder writes it only when the update tool is deployed
# there, and the window's --update-tool reads what the builder wrote.
#   bash common/test-make-launcher-app.sh            exit 0 = every case passed; exit 2 = swiftc is missing,
#                                                    which is not a pass: nothing was tested
#   MUTANT=1 ...   the app is built straight into the target, not in a build folder; must exit 1
#   MUTANT=2 ...   the new app is moved onto the old one (mv nests it); must exit 1
#   MUTANT=3 ...   a skipped build exits 0; must exit 1
#   MUTANT=4 ...   the own-app test is dropped (a wrapper at the target is replaced); must exit 1
#   MUTANT=5 ...   the window's own folder is not among the folders it reads; must exit 1
#   MUTANT=6 ...   the name check is dropped (a name starting with - builds); must exit 1
#   MUTANT=7 ...   CFBundleIconFile is written when the icon failed; must exit 1
#   MUTANT=8 ...   the small drawing used for no size; must exit 1
#   MUTANT=9 ...   the key L1UpdateDir written when the tool is absent; must exit 1
#   MUTANT=10 ...  the window reading another key than the builder writes; must exit 1
# The real parts joined (docs/plans/launcher-first-install.md, 3.4; LFT12): the tree's real
# common/install-launcher.sh runs the real builder in a scratch home, with stubs only for xcode-select, sw_vers
# and open, and the window it built is asked where its tool is.
#   MUTANT=11 ...  the launcher's installer makes the record's folders and the tool's copy after the build (no
#                  L1UpdateDir in the first window); must exit 1
#   MUTANT=12 ...  the minimum macOS in the Info.plist left at 13.0; must exit 1
#   MUTANT=13 ...  the table of games not copied into the bundle (LFT12's listing case, with LF5a); must exit 1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
for f in make-launcher-app.sh launcher-window.swift games.tsv paths.sh install-launcher.sh updates.sh tools.sh; do
  [ -f "$HERE/$f" ] || { echo "REFUSED: common/$f not found"; exit 2; }
done
xcrun -f swiftc >/dev/null 2>&1 || { echo "REFUSED: swiftc is missing (install the Xcode Command Line Tools); nothing was tested"; exit 2; }
T="$(mktemp -d /tmp/make-launcher-app-test.XXXX)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/repo/common" "$T/home/Applications"
cp "$HERE/make-launcher-app.sh" "$HERE/launcher-window.swift" "$HERE/games.tsv" "$T/repo/common/"
BUILDER="$T/repo/common/make-launcher-app.sh"; SRC="$T/repo/common/launcher-window.swift"
INSTALLER="$T/installer.sh"; cp "$HERE/install-launcher.sh" "$INSTALLER"   # LFT12's copy, which mutant 11 edits

mutated() { echo "REFUSED: mutant did not apply"; exit 2; }
drop() {   # <file> <fixed text>: delete the one line that holds it
  [ "$(grep -cF -- "$2" "$1")" = 1 ] || mutated
  grep -vF -- "$2" "$1" > "$1.new" && mv "$1.new" "$1"
}
case "${MUTANT:-0}" in
  0) ;;
  1) sed -i '' 's|^NEW="\$B/\$NAME.app"$|NEW="$APP"|' "$BUILDER"; grep -q '^NEW="\$APP"$' "$BUILDER" || mutated ;;
  2) sed -i '' 's|^if \[ -e "\$APP" \]; then$|if false; then|' "$BUILDER"; grep -q '^if false; then$' "$BUILDER" || mutated ;;
  3) sed -i '' 's|; exit 3; }$|; exit 0; }|' "$BUILDER"; grep -q '^skip() { .*; exit 0; }$' "$BUILDER" || mutated ;;
  4) sed -i '' 's|^if ! own_app "\$APP"; then$|if false; then|' "$BUILDER"; grep -q '^if false; then$' "$BUILDER" || mutated ;;
  5) sed -i '' 's|^    if let b = ownBundle() {|    if false, let b = ownBundle() {|' "$SRC"; grep -q '^    if false, let b = ownBundle() {' "$SRC" || mutated ;;
  6) drop "$BUILDER" 'echo "--name must not be empty' ;;
  7) sed -i '' 's|^if \[ "\$ICON_OK" = 1 \]; then plutil -replace CFBundleIconFile|if true; then plutil -replace CFBundleIconFile|' "$BUILDER"
     grep -q '^if true; then plutil -replace CFBundleIconFile' "$BUILDER" || mutated ;;
  8) drop "$BUILDER" '"$EXE" --icon "$B/icon-small.png" small' ;;
  9) sed -i '' 's|^  if \[ -n "\$UPDATE_DIR" \] && \[ -f "\$UPDATE_DIR/updates.sh" \] && \[ ! -L "\$UPDATE_DIR/updates.sh" \]; then$|  if [ -n "$UPDATE_DIR" ]; then|' "$BUILDER"
     grep -q '^  if \[ -n "\$UPDATE_DIR" \]; then$' "$BUILDER" || mutated ;;
  10) sed -i '' 's|return text(d\["L1UpdateDir"\])$|return text(d["L1UpdateFolder"])|' "$SRC"; grep -q 'return text(d\["L1UpdateFolder"\])$' "$SRC" || mutated ;;
  11) python3 -I - "$INSTALLER" << 'PY' || mutated
import sys
p = sys.argv[1]; s = open(p).read()
a = "# --- 3. the record's folders, made"; b = "# --- 4. the wait for Apple's tools"; c = "# --- 7. the launcher's own stamp"
assert s.count(a) == 1 and s.count(b) == 1 and s.count(c) == 1
i = s.index(a); j = s.index(b); blk = s[i:j]; s = s[:i] + s[j:]
k = s.index(c); s = s[:k] + blk + s[k:]
open(p, "w").write(s)
PY
      bash -n "$INSTALLER" || mutated ;;
  12) sed -i '' 's|<string>14.0</string>$|<string>13.0</string>|' "$BUILDER"; grep -q '<key>LSMinimumSystemVersion</key>  <string>13.0</string>$' "$BUILDER" || mutated ;;
  13) drop "$BUILDER" 'cp "$GAMES" "$NEW/Contents/Resources/games.tsv"' ;;
  *) echo "REFUSED: no mutant ${MUTANT}"; exit 2 ;;
esac

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
mk() {   # <dest> [builder arguments]: output in $T/out; echoes the exit code. XPATH goes first on PATH
  local d="$1"; shift
  HOME="$T/home" PATH="${XPATH:+$XPATH:}$PATH" /bin/bash "$BUILDER" --dest "$d" "$@" > "$T/out" 2>&1
  echo $?
}
said() { grep -c -- "$1" "$T/out"; }
px() { plutil -extract "$1" raw "$2/Contents/Info.plist" 2>/dev/null; }
snap() { (cd "$1" && { find . -type f -exec shasum {} + | sort; find . | sort; }) | shasum | cut -c1-12; }
leftover() { ls -a "$1" | grep -c '^\.14unch3r-build\.'; }
fake() {   # <bundle> <identifier> [wrapper]: an app of someone else's shape at the target
  mkdir -p "$1/Contents/MacOS"
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>%s</string></dict></plist>\n' "$2" > "$1/Contents/Info.plist"
  echo keep > "$1/Contents/MacOS/keep"
  [ "${3:-}" = wrapper ] && mkdir -p "$1/Contents/SharedSupport/prefix"
  return 0
}

# --- built from nothing
D="$T/apps"; mkdir -p "$D"; A="$D/14unch3r.app"
rc=$(mk "$D")
check "the app is built" "$rc:$([ -x "$A/Contents/MacOS/launcher-window" ] && echo program)" "0:program"
check "  ...its identifier, program, name and display name" "$(px CFBundleIdentifier "$A"):$(px CFBundleExecutable "$A"):$(px CFBundleName "$A"):$(px CFBundleDisplayName "$A")" \
  "local.1launcher.window:launcher-window:14unch3r:14unch3r"
check "  ...its three other names for Spotlight, and no fourth" "$(px CFBundleAlternateNames.0 "$A")|$(px CFBundleAlternateNames.1 "$A")|$(px CFBundleAlternateNames.2 "$A")|$(px CFBundleAlternateNames.3 "$A")" \
  "1launcher|launcher|game launcher|"
check "  ...its plist lints, and its table of games is the repo's" "$(plutil -lint "$A/Contents/Info.plist" >/dev/null 2>&1 && echo lint):$(cmp -s "$A/Contents/Resources/games.tsv" "$T/repo/common/games.tsv" && echo same)" "lint:same"
check "  ...and no build folder is left beside it" "$(leftover "$D")" 0

# --- the program inside the app: where it looks, and what it finds there
check "--folders from inside the app: that HOME's Applications, then the app's own folder" \
  "$(HOME="$T/home" "$A/Contents/MacOS/launcher-window" --folders | tr '\n' '|')" "$T/home/Applications|$(cd "$D" && pwd -P)|"
mkdir -p "$T/home2/Applications"; rc=$(HOME="$T/home2" mk "$T/home2/Applications")
check "--folders when the app is in that HOME's Applications: one line" \
  "$rc:$(HOME="$T/home2" "$T/home2/Applications/14unch3r.app/Contents/MacOS/launcher-window" --folders | tr '\n' '|')" "0:$T/home2/Applications|"
mkdir -p "$D/Fixture.app/Contents"
printf '<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>L1Role</key><string>game</string><key>L1SteamAppID</key><integer>3215050</integer><key>CFBundleDisplayName</key><string>Fixture Game</string></dict></plist>\n' > "$D/Fixture.app/Contents/Info.plist"
check "--list given the app's folder: the fixture game beside it, and not the app itself" \
  "$("$A/Contents/MacOS/launcher-window" --list "$D" | tr '\t' '|')" "game|3215050|unknown|Fixture Game|$D/Fixture.app"

# --- built again over its own older app
echo old > "$A/Contents/Resources/old-file"
rc=$(mk "$D")
check "built again over its own app: exit 0, the old app's extra file gone" "$rc:$([ -e "$A/Contents/Resources/old-file" ] && echo old)" "0:"
check "  ...no app inside the app, and no build folder left" "$([ -e "$A/14unch3r.app" ] && echo nested):$(leftover "$D")" ":0"

# --- skipped: nothing is changed and nothing is left, exit 3
before=$(snap "$D")
mkdir -p "$T/noswift"; printf '#!/bin/bash\nexit 1\n' > "$T/noswift/xcrun"; chmod +x "$T/noswift/xcrun"
check "no swiftc: exit 3, the reason said, the older app and its folder as they were" \
  "$(XPATH="$T/noswift" mk "$D"):$(said 'window: skipped (swiftc is missing'):$(snap "$D")" "3:1:$before"
check "no source: the same" "$(L1_WINDOW_SRC="$T/absent.swift" mk "$D"):$(said 'window: skipped (common/launcher-window.swift is missing'):$(snap "$D")" "3:1:$before"
echo 'this is not Swift' > "$T/bad.swift"
check "a source that does not compile: the same" "$(L1_WINDOW_SRC="$T/bad.swift" mk "$D"):$(said 'window: skipped (the compile failed'):$(snap "$D")" "3:1:$before"

# --- refused: exit 1, both lines said, the bundle untouched
refused() {   # <case> <dest>
  local b="$2/14unch3r.app" s rc
  s=$(snap "$b"); rc=$(mk "$2")
  check "$1: refused with exit 1, both lines said, untouched" \
    "$rc:$(said "^ERROR: $b exists and was not built by this script; nothing removed$")$(said '^If it is a leftover of this script, move it to the Trash and run this again.$'):$(snap "$b")" "1:11:$s"
}
fake "$T/r1/14unch3r.app" local.1launcher.window wrapper; refused "a wrapper-shaped bundle with this app's identifier" "$T/r1"
fake "$T/r2/14unch3r.app" local.someone.else;            refused "a bundle with another identifier" "$T/r2"
mkdir -p "$T/r3"; ln -s "$A" "$T/r3/14unch3r.app";       refused "a symlink to an app of this builder's" "$T/r3"
check "  ...it is still a symlink" "$([ -L "$T/r3/14unch3r.app" ] && echo link)" link

# --- names, checked before anything is touched: exit 2, nothing written
mkdir -p "$T/names"
for n in 'a/b' '-x' '.x'; do
  check "--name '$n': exit 2, nothing written" "$(mk "$T/names" --name "$n"):$(ls -A "$T/names" | wc -l | tr -d ' ')" "2:0"
done
check "--name with no value: exit 2" "$(mk "$T/names" --name ''):$(said '^--name needs a value$')" "2:1"

# --- no table of games in the checkout: built, and said
mkdir -p "$T/nogames/common"; cp "$BUILDER" "$SRC" "$T/nogames/common/"
rc=$(HOME="$T/home" /bin/bash "$T/nogames/common/make-launcher-app.sh" --dest "$T/ng" > "$T/out" 2>&1; echo $?)
check "no common/games.tsv: built, said, and the app holds no table" "$rc:$(said 'common/games.tsv is missing'):$([ -e "$T/ng/14unch3r.app/Contents/Resources/games.tsv" ] && echo table)" "0:1:"

# --- the icon (B6)
check "the icon is in the app, and its plist names it" "$([ -s "$A/Contents/Resources/14unch3r.icns" ] && echo icns):$(px CFBundleIconFile "$A")" "icns:14unch3r.icns"
"$A/Contents/MacOS/launcher-window" --icon "$T/icon.png"
check "  ...drawn at exactly 1024 by 1024 pixels" "$(sips -g pixelWidth -g pixelHeight "$T/icon.png" 2>/dev/null | awk '/pixel/ { printf "%s ", $2 }')" "1024 1024 "
mkdir -p "$T/noicon"; printf '#!/bin/bash\nexit 1\n' > "$T/noicon/iconutil"; chmod +x "$T/noicon/iconutil"
rc=$(XPATH="$T/noicon" mk "$T/ni")
check "iconutil fails: the app is built, its plist names no icon, and it says so" "$rc:$(px CFBundleIconFile "$T/ni/14unch3r.app"):$(said '^    icon:     skipped')" "0::1"

# --- the small form (docs/plans/launcher-window-look.md, 2.6, W13): the three files of 16 and 32 pixels from it,
# the other seven from the full drawing; and all ten from the full one when the small one cannot be drawn
mkdir -p "$T/rec"
printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "%s"\nexec /usr/bin/sips "$@"\n' "$T/sips.log" > "$T/rec/sips"; chmod +x "$T/rec/sips"
sources() {   # each iconset file and the drawing it was scaled from, sorted: icon_16x16.png<icon-small.png ...
  awk '/\.iconset\// { n = split($4, a, "/"); m = split($6, b, "/"); print b[m] "<" a[n] }' "$T/sips.log" | sort | tr '\n' ' '
}
: > "$T/sips.log"; rc=$(XPATH="$T/rec" mk "$T/sm")
check "the files of 16 and 32 pixels come from the small form, the other seven from the full one" "$rc:$(sources)" \
  "0:icon_128x128.png<icon.png icon_128x128@2x.png<icon.png icon_16x16.png<icon-small.png icon_16x16@2x.png<icon-small.png icon_256x256.png<icon.png icon_256x256@2x.png<icon.png icon_32x32.png<icon-small.png icon_32x32@2x.png<icon.png icon_512x512.png<icon.png icon_512x512@2x.png<icon.png "
mkdir -p "$T/nosmall/common"; cp "$BUILDER" "$T/repo/common/games.tsv" "$T/nosmall/common/"
sed 's|if !drawIcon(to: absolute(rest\[0\]), small: rest.count == 2) {|if rest.count == 2 \|\| !drawIcon(to: absolute(rest[0]), small: false) {|' "$SRC" > "$T/nosmall/common/launcher-window.swift"
grep -q 'if rest.count == 2 || !drawIcon' "$T/nosmall/common/launcher-window.swift" || { echo "REFUSED: the program that cannot draw the small form was not made"; exit 2; }
: > "$T/sips.log"; rc=$(HOME="$T/home" PATH="$T/rec:$PATH" /bin/bash "$T/nosmall/common/make-launcher-app.sh" --dest "$T/ns" > "$T/out" 2>&1; echo $?)
check "the small form cannot be drawn: all ten from the full one, and the icon is still packed" \
  "$rc:$(sources | tr ' ' '\n' | grep -c '<icon.png$'):$(px CFBundleIconFile "$T/ns/14unch3r.app")" "0:10:14unch3r.icns"

# --- the update tool's folder (docs/plans/built-in-update.md, 3.3 and 3.5; UT8). The builder reads the folder from
# common/paths.sh beside it, so these builds come from a scratch common/ that holds it; the tool is an empty stub,
# and nothing calls it: --update-tool only says where the window would look.
# where paths.sh puts the folder under a home with nothing set: taken from paths.sh, never spelled here
# (common/test-paths.sh, LT14, lists the files that may spell a root)
UPD3="$(env -u L1_DATA_ROOT -u L1_WORK_ROOT -u L1_UPDATE_DIR HOME="$T/home3" bash "$HERE/paths.sh" 2>/dev/null | sed -n 's/^L1_UPDATE_DIR=//p')"
case "$UPD3" in "$T/home3/"*/_update) ;; *) echo "REFUSED: paths.sh gave no update folder under the scratch home"; exit 2 ;; esac
mkdir -p "$T/upd/common" "$T/u1" "$T/u2" "$T/u3" "$T/u4" "$UPD3"
cp "$BUILDER" "$SRC" "$T/repo/common/games.tsv" "$HERE/paths.sh" "$T/upd/common/"
printf '#!/bin/bash\nexit 0\n' > "$T/u1/updates.sh"
cp "$T/u1/updates.sh" "$T/u4/updates.sh"; cp "$T/u1/updates.sh" "$UPD3/updates.sh"
ln -s "$T/u1/updates.sh" "$T/u3/updates.sh"
mku() {   # <update folder or -> <dest> [<home>]: a build with L1_UPDATE_DIR at the folder (-: not set); echoes the exit code
  if [ "$1" = - ]; then
    env -u L1_UPDATE_DIR HOME="${3:-$T/home}" /bin/bash "$T/upd/common/make-launcher-app.sh" --dest "$2" > "$T/out" 2>&1
  else
    HOME="${3:-$T/home}" L1_UPDATE_DIR="$1" /bin/bash "$T/upd/common/make-launcher-app.sh" --dest "$2" > "$T/out" 2>&1
  fi
  echo $?
}
ut() { local a="$1"; shift; "$a/14unch3r.app/Contents/MacOS/launcher-window" --update-tool ${1+"$@"} 2>&1; }
rc=$(mku "$T/u1" "$T/k1")
check "the update tool is deployed: L1UpdateDir holds its folder, the plist lints, and --update-tool from inside the app prints the tool" \
  "$rc:$(px L1UpdateDir "$T/k1/14unch3r.app"):$(plutil -lint "$T/k1/14unch3r.app/Contents/Info.plist" >/dev/null 2>&1 && echo lint):$(ut "$T/k1")" "0:$T/u1:lint:$T/u1/updates.sh"
rc=$(mku "$T/u2" "$T/k2")
check "the tool is absent at the build: built, no key, and --update-tool prints -" "$rc:$(px L1UpdateDir "$T/k2/14unch3r.app"):$(ut "$T/k2")" "0::-"
cp "$T/u1/updates.sh" "$T/u2/updates.sh"
check "  ...deployed after that build: still -, until the window is built again" "$(ut "$T/k2")" "-"
rc=$(mku "$T/u3" "$T/k3")
check "the tool is a link: no key, and -" "$rc:$(px L1UpdateDir "$T/k3/14unch3r.app"):$(ut "$T/k3")" "0::-"
rc=$(mku - "$T/k4" "$T/home3")
check "L1_UPDATE_DIR not set: the folder is the one paths.sh gives, under that HOME, and its space survives" \
  "$rc:$(px L1UpdateDir "$T/k4/14unch3r.app"):$(ut "$T/k4")" \
  "0:$UPD3:$UPD3/updates.sh"
check "--update-dir wins over the key; a relative one, and one that holds a link, give -" \
  "$(ut "$T/k1" --update-dir "$T/u4")|$(cd "$T" && ut "$T/k1" --update-dir u4)|$(ut "$T/k1" --update-dir "$T/u3")" "$T/u4/updates.sh|-|-"
mv "$T/u1/updates.sh" "$T/u1/gone.sh"
check "the key names a folder whose tool is gone: -" "$(px L1UpdateDir "$T/k1/14unch3r.app"):$(ut "$T/k1")" "$T/u1:-"
check "no paths.sh beside the builder, as in every build further up: no key, and -" "$(px L1UpdateDir "$A"):$(ut "$D")" ":-"

# --- LFT12 (docs/plans/launcher-first-install.md, 3.4): the real parts joined. The launcher's real installer, the
# real builder and the window it builds, in a scratch home. Only xcode-select, sw_vers and open are stubs: the
# compiler is this Mac's. Run with L1_FETCHED_REF=release, so that the Mac is not manual. Without this case a
# window that was installed from nothing and cannot find its tool would pass every other test.
J="$T/join"; JH="$T/jhome"; mkdir -p "$J/common" "$JH" "$T/jbin"
cp "$BUILDER" "$SRC" "$HERE/games.tsv" "$HERE/paths.sh" "$HERE/updates.sh" "$HERE/tools.sh" "$J/common/"
cp "$INSTALLER" "$J/common/install-launcher.sh"
printf '%s\n' '# Changelog' '' '## Unreleased' '' '## v0.4.2 (2026-11-24)' '' 'Words.' > "$J/CHANGELOG.md"
printf '#!/bin/bash\ncase "$1" in -p) echo /Library/Developer/CommandLineTools ;; *) echo "XS $*" >> "%s/jcalls"; exit 1 ;; esac\n' "$T" > "$T/jbin/xcode-select"
printf '#!/bin/bash\necho 27.2.1\n' > "$T/jbin/sw_vers"
printf '#!/bin/bash\necho "OPEN $*" >> "%s/jcalls"\n' "$T" > "$T/jbin/open"
chmod +x "$T/jbin"/*; : > "$T/jcalls"
JU="$JH/Library/Application Support/1launcher/_update"; JA="$JH/Applications/14unch3r.app"
rc=$(env -u L1_UPDATE_DIR -u L1_UPDATE -u L1_DATA_ROOT -u L1_FETCHED_COMMIT HOME="$JH" PATH="$T/jbin:$PATH" L1_FETCHED_REF=release /bin/bash "$J/common/install-launcher.sh" > "$T/jout" 2>&1; echo $?)
check "LFT12 the launcher's installer with the real builder: exit 0, the app built in the scratch home, open called once with it, Apple not asked" \
  "$rc:$([ -x "$JA/Contents/MacOS/launcher-window" ] && echo built):$(grep -c "^OPEN $JA\$" "$T/jcalls"):$(grep -c '^XS ' "$T/jcalls")" "0:built:1:0"
check "LFT12 ...the built app's L1UpdateDir is the scratch record's folder, and --update-tool from inside it prints the deployed tool" \
  "$(px L1UpdateDir "$JA"):$(HOME="$JH" "$JA/Contents/MacOS/launcher-window" --update-tool 2>&1)" "$JU:$JU/updates.sh"
check "LFT12 ...its Info.plist gives the minimum macOS as 14.0, and lints" "$(px LSMinimumSystemVersion "$JA"):$(plutil -lint "$JA/Contents/Info.plist" >/dev/null 2>&1 && echo lint)" "14.0:lint"
check "LFT12 ...the launcher's stamp follows release, and the deployed tool says unknown: the Mac is not manual" \
  "$(cut -f1,2 "$JU/launcher" 2>/dev/null):$(HOME="$JH" bash "$JU/updates.sh" | cut -f1,2)" "release	v0.4.2:unknown	v0.4.2"
# LFT12's listing case (LF5a): the window that was installed from nothing lists the games of its own bundle's table
JT="$JA/Contents/Resources/games.tsv"; JW="$JA/Contents/MacOS/launcher-window"
check "LFT12 the built window, asked with its bundle's table and the scratch Applications: one offer row for each row of the tree's table, each not-set-up" \
  "$(HOME="$JH" "$JW" --list --games "$JT" "$JH/Applications" 2>&1 | awk -F'\t' '$1 == "offer" && $3 == "not-set-up" { n++ } END { print n + 0 }'):$(HOME="$JH" "$JW" --list --games "$JT" "$JH/Applications" 2>&1 | grep -c .)" \
  "$(grep -vc '^#' "$HERE/games.tsv"):$(grep -vc '^#' "$HERE/games.tsv")"
check "LFT12 ...and --grid gives each of those tiles a line that ends with its letters" \
  "$(HOME="$JH" "$JW" --grid --games "$JT" - "$JH/Applications" 2>&1 | awk -F'\t' '$1 == "tile" { printf "%s ", $NF }')" "icon=initials:CS icon=initials:SM "

echo "$fails failure(s)"
[ "$fails" = 0 ]
