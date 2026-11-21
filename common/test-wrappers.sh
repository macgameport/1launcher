#!/bin/bash
# test-wrappers.sh -- common/wrappers.sh, the resolver of a game's Wine wrapper (docs/plans/wrapper-names.md,
# section 6: WT1 to WT5c, and WT12, the census of old names). No game, no Wine; scratch homes only.
#   bash common/test-wrappers.sh    exit 0 = every case passed
#   MUTANT=1  step 2 (the marker) removed                          WT1
#   MUTANT=2  step 1 (the player's wrapper) moved after step 2     WT2
#   MUTANT=3  steps 2 and 3 swapped                                WT3 (a)
#   MUTANT=4  the prefix test dropped from step 3                  WT3 (b)
#   MUTANT=5  the count check replaced by "take the first"         WT4
#   MUTANT=6  the symlink test removed                             WT5 (a)
#   MUTANT=7  the quarantine test removed                          WT5 (b)
#   MUTANT=8  the wine64 test removed                              WT5 (c)
#   MUTANT=9  the tests dropped from step 4                        WT5 (d)
#   MUTANT=10 the group-or-others test applied to Contents too     WT5 (e)
#   MUTANT=11 Surviving Mars's row loses its program path          WT5b (a)
#   MUTANT=12 step 4's "marked otherwise" test removed             WT5b (b)
#   MUTANT=13 a row removed from the table                         WT5c (a)
#   MUTANT=14 list printing the path as it is                      WT5c (b)
#   MUTANT=15 the prefix test dropped from incomplete              WT5c (c)
#   MUTANT=16 incomplete reading every old name                    WT5c (d)
#   MUTANT=17 an old name put back into the census copy's repatch.sh                      WT12 (a)
#   MUTANT=18 the Windows Steam's old name put back into the copy's make-steam-shortcut.sh WT12 (b)
# Each must exit 1.
set -u
REPO="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
T="$(mktemp -d /tmp/test-wrappers.XXXXXX)"; trap 'rm -rf "$T"' EXIT
W="$T/wrappers.sh"; cp "$REPO/common/wrappers.sh" "$W"
# WT12 runs over a scratch copy of the files git knows (tracked, and new ones not ignored), never the checkout
C="$T/census"; mkdir -p "$C"
(cd "$REPO" && git ls-files -z --cached --others --exclude-standard | while IFS= read -r -d '' f; do [ -f "$f" ] && printf '%s\0' "$f"; done \
  | tar --null -T - -cf -) | (cd "$C" && tar xf -)
mutate() { perl -0pi -e "$1" "$3"; grep -q -- "$2" "$3" || { echo "REFUSED: mutant did not apply"; exit 2; }; }
case "${MUTANT:-0}" in
  1) mutate 's/\n  l1w_by_marker "\$role" "\$id"\n/\n  L1W_COUNT=0 # MUTANT-1\n/' 'MUTANT-1' "$W" ;;
  2) mutate 's/(  # 1\. .*?)(  # 2\. .*?)(  # 3\. )/$2  # MUTANT-2\n$1$3/s' 'MUTANT-2' "$W" ;;
  3) mutate 's/(  # 2\. .*?)(  # 3\. .*?)(  # 4\. )/$2  # MUTANT-3\n$1$3/s' 'MUTANT-3' "$W" ;;
  4) mutate 's/\n    \[ -d "\$a\/Contents\/SharedSupport\/prefix" \] \|\| continue\n/\n    : # MUTANT-4\n/' 'MUTANT-4' "$W" ;;
  5) mutate 's/if \[ "\$L1W_COUNT" = 1 \]; then printf .%s\\n. "\$L1W_HITS"; return 0; fi/if [ "\$L1W_COUNT" -ge 1 ]; then printf "%s\\n" "\$L1W_HITS" | head -n 1; return 0; fi # MUTANT-5/' 'MUTANT-5' "$W" ;;
  6) mutate 's/\n  if \[ -L "\$a" \]; then echo "a symlink"; return 1; fi\n/\n  : # MUTANT-6\n/' 'MUTANT-6' "$W" ;;
  7) mutate 's/\n  if xattr -p com\.apple\.quarantine [^\n]*\n/\n  : # MUTANT-7\n/' 'MUTANT-7' "$W" ;;
  8) mutate 's/\n  if \[ ! -x "\$a\/Contents\/SharedSupport\/wine\/bin\/wine64" \][^\n]*\n/\n  : # MUTANT-8\n/' 'MUTANT-8' "$W" ;;
  9) mutate 's/\n      l1w_fails "\$a" >\/dev\/null \|\| continue\n/\n      : # MUTANT-9\n/' 'MUTANT-9' "$W" ;;
  10) mutate 's/(\n  case "\$m" in [^\n]*\n)/$1  case "\$(stat -f %Lp "\$a\/Contents" 2>\/dev\/null)" in *[2367]?|*[2367]) echo "writable by group or others"; return 1 ;; esac # MUTANT-10\n/' 'MUTANT-10' "$W" ;;
  11) mutate 's/L1W_PROGRAM="\$L1W_PROGRAM_SM" ;;/L1W_PROGRAM="" ;; # MUTANT-11/' 'MUTANT-11' "$W" ;;
  12) mutate 's/\n      \[ -z "\$\(l1w_key "\$a" L1Role\)" \] \|\| continue\n/\n      : # MUTANT-12\n/' 'MUTANT-12' "$W" ;;
  13) mutate 's/    game:3215050\)\n.*?L1W_PROGRAM_SM" ;;\n/    # MUTANT-13\n/s' 'MUTANT-13' "$W" ;;
  14) mutate 's/echo "\$role \$id \$\(l1w_tilde "\$a"\)\$note"/echo "\$role \$id \$a\$note" # MUTANT-14/' 'MUTANT-14' "$W" ;;
  15) mutate 's/if \[ -d "\$first" \] && \[ ! -d "\$first\/Contents\/SharedSupport\/prefix" \]; then/if [ -d "\$first" ] \&\& : MUTANT-15; then/' 'MUTANT-15' "$W" ;;
  16) mutate 's/(\n  \[ "\$1" = game \] && l1w_row game "\$\{2:-\}" \|\| return 1\n)/$1  while IFS= read -r first; do if [ -d "\$first" ] && [ ! -d "\$first\/Contents\/SharedSupport\/prefix" ]; then printf "%s\\n" "\$first"; return 0; fi; done <<< "\$L1W_OLD"; return 1 # MUTANT-16\n/' 'MUTANT-16' "$W" ;;
  17) printf '%s\n' 'APP="$HOME/Applications/CS2dxmt11.app"   # MUTANT-17' >> "$C/cities-skylines-2/repatch.sh" ;;
  18) printf '%s\n' 'STORE="$HOME/Applications/CS2dxmt11-pk110.app"   # MUTANT-18' >> "$C/cities-skylines-2/scripts/make-steam-shortcut.sh" ;;
esac
pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1"; echo "   got:  $2"; echo "   want: $3"; fi; }

CS2P="drive_c/Program Files (x86)/Steam/steamapps/common/Cities Skylines II/Cities2.exe"
SMP="drive_c/Program Files (x86)/Steam/steamapps/common/Project Spark/Mars.exe"
STP="drive_c/Program Files (x86)/Steam/steam.exe"
n=0
newhome() { n=$((n + 1)); H="$T/h$n"; mkdir -p "$H/Applications" "$H/SystemApplications"; }
# mkw <path> <bare|cs2|sm|steam> [<role> [<app ID>]]: a fixture wrapper, its bundle folder 755
mkw() {
  local a="$1" k="$2"
  mkdir -p "$a/Contents/SharedSupport/prefix" "$a/Contents/SharedSupport/wine/bin"
  printf '#!/bin/sh\nexit 0\n' > "$a/Contents/SharedSupport/wine/bin/wine64"; chmod 755 "$a/Contents/SharedSupport/wine/bin/wine64"
  cat > "$a/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleName</key><string>Steambuild Metal</string><key>NSBGOnly</key><string>1</string></dict></plist>
EOF
  case "$k" in
    cs2) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$CS2P")"; : > "$a/Contents/SharedSupport/prefix/$CS2P" ;;
    sm) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$SMP")"; : > "$a/Contents/SharedSupport/prefix/$SMP" ;;
    steam) mkdir -p "$(dirname "$a/Contents/SharedSupport/prefix/$STP")"; : > "$a/Contents/SharedSupport/prefix/$STP" ;;
  esac
  [ -n "${3:-}" ] && plutil -replace L1Role -string "$3" "$a/Contents/Info.plist"
  [ -n "${4:-}" ] && plutil -replace L1SteamAppID -integer "$4" "$a/Contents/Info.plist"
  chmod 755 "$a"
}
R() { env -u CS2_WRAPPER -u SM_WRAPPER HOME="$H" L1_SYSTEM_APPS="$H/SystemApplications" "$@"; }
fnd() { R bash "$W" find "$@" 2>/dev/null; echo "rc=$?"; }   # <role> [<id>]: output, then rc=<code>
oneline() { tr '\n' '|' | sed 's/|$//'; }

# --- WT1: found by its marker, whatever its name
newhome; mkw "$H/Applications/Anything At All.app" bare game-wrapper 949230; mkw "$H/Applications/Other.app" bare; mkw "$H/Applications/Third.app" cs2
check "WT1 a marked bare wrapper among unmarked apps is found" "$(fnd game 949230 | oneline)" "$H/Applications/Anything At All.app|rc=0"
check "WT1 ...and nothing for the other game" "$(fnd game 3215050 | oneline)" "rc=1"

# --- WT2: a wrapper named by the player wins, taken as it is
newhome; mkw "$H/elsewhere/mine.app" bare; mkw "$H/Applications/m.app" bare game-wrapper 949230
check "WT2 the named wrapper is printed, its trailing slash gone" "$(R CS2_WRAPPER="$H/elsewhere/mine.app/" bash "$W" find game 949230; echo "rc=$?")" "$H/elsewhere/mine.app
rc=0"
check "WT2 a named path that does not exist is printed too" "$(R CS2_WRAPPER="$H/nowhere.app" bash "$W" find game 949230)" "$H/nowhere.app"
check "WT2 SM_WRAPPER for Surviving Mars, and not for Cities: Skylines II" \
  "$(R SM_WRAPPER="$H/elsewhere/mine.app" bash "$W" find game 3215050)|$(R SM_WRAPPER="$H/elsewhere/mine.app" bash "$W" find game 949230)" "$H/elsewhere/mine.app|$H/Applications/m.app"

# --- WT3: old names, only while nothing is marked
newhome; mkw "$H/Applications/CS2dxmt11.app" bare
check "WT3 an unmarked bare CS2dxmt11.app is found" "$(fnd game 949230 | oneline)" "$H/Applications/CS2dxmt11.app|rc=0"
newhome; mkdir -p "$H/Applications/CS2dxmt11.app/Contents"; mkw "$H/Applications/CS2.app" bare
check "WT3 an old-named app with no prefix is passed over for the next name" "$(fnd game 949230 | oneline)" "$H/Applications/CS2.app|rc=0"
newhome; mkw "$H/SystemApplications/CS2dxmt11.app" bare
check "WT3 the system folder's CS2dxmt11.app, last" "$(fnd game 949230 | oneline)" "$H/SystemApplications/CS2dxmt11.app|rc=0"
newhome; mkw "$H/Applications/SurvivingMars.app" bare; mkw "$H/Applications/CS2dxmt11-pk110.app" bare
check "WT3 Surviving Mars's and the Windows Steam's old names" "$(fnd game 3215050 | oneline)|$(fnd steam | oneline)" \
  "$H/Applications/SurvivingMars.app|rc=0|$H/Applications/CS2dxmt11-pk110.app|rc=0"
newhome; mkw "$H/Applications/CS2dxmt11.app" bare; mkw "$H/Applications/zz.app" bare game-wrapper 949230
check "WT3 with a marked bare wrapper beside it, the marked one is printed" "$(fnd game 949230 | oneline)" "$H/Applications/zz.app|rc=0"
newhome; mkw "$H/Applications/CS2dxmt11.app" bare steam-wrapper
check "WT3 an old-named app marked for another role is not this game's" "$(fnd game 949230 | oneline)" "rc=1"

# --- WT4: two markers
newhome; mkw "$H/Applications/a.app" bare game-wrapper 949230; mkw "$H/Applications/b.app" bare game-wrapper 949230
out="$(R bash "$W" find game 949230 2>/dev/null)"; rc=$?; err="$(R bash "$W" find game 949230 2>&1 >/dev/null)"
check "WT4 two wrappers marked alike: exit 2, standard output empty" "$rc|$out" "2|"
check "WT4 ...both paths on standard error, with ~" "$(printf '%s\n' "$err" | grep -c '^  ~/Applications/[ab]\.app$')" 2
check "WT4 ...and the line says what to do" "$(printf '%s\n' "$err" | grep -c 'Move one to the Trash, or name the one to use in CS2_WRAPPER')" 1
check "WT4 ...nothing of the home folder's name" "$(printf '%s\n' "$err" | grep -c "$H")" 0

# --- WT5: what is not a candidate, each alone and marked
nc() {   # <label> <setup command> <the test list names>
  newhome; eval "$2"
  check "WT5 not a candidate: $1 (find)" "$(fnd game 949230 | oneline)" "rc=1"
  check "WT5 not a candidate: $1 (list names the test)" "$(R bash "$W" list | grep -c "(passed over: $3)")" 1
}
nc "a symlink to a whole marked wrapper" 'mkw "$H/real/w.app" bare game-wrapper 949230; ln -s "$H/real/w.app" "$H/Applications/w.app"' "a symlink"
nc "an app in a subfolder" 'mkw "$H/Applications/Games/w.app" bare game-wrapper 949230' "not a direct child of ~/Applications"
nc "an Info.plist that does not parse" 'mkw "$H/Applications/w.app" bare; printf "<plist><dict><key>L1Role</key><string>game-wrapper" > "$H/Applications/w.app/Contents/Info.plist"' "its Info.plist does not parse"
nc "L1Role game" 'mkw "$H/Applications/w.app" bare game 949230' "L1Role game is not a wrapper.s"
nc "no prefix" 'mkw "$H/Applications/w.app" bare game-wrapper 949230; rm -rf "$H/Applications/w.app/Contents/SharedSupport/prefix"' "no prefix"
nc "no wine64" 'mkw "$H/Applications/w.app" bare game-wrapper 949230; chmod 644 "$H/Applications/w.app/Contents/SharedSupport/wine/bin/wine64"' "no wine64"
nc "a folder writable by group" 'mkw "$H/Applications/w.app" bare game-wrapper 949230; chmod 775 "$H/Applications/w.app"' "writable by group or others"
nc "a quarantine attribute" 'mkw "$H/Applications/w.app" bare game-wrapper 949230; xattr -w com.apple.quarantine "0081;00000000;Safari;" "$H/Applications/w.app"' "quarantined"
newhome; mkw "$H/Applications/w.app" bare game-wrapper 3215050
check "WT5 not a candidate: another app ID (find)" "$(fnd game 949230 | oneline)" "rc=1"
check "WT5 ...list shows it under its own ID" "$(R bash "$W" list)" "game-wrapper 3215050 ~/Applications/w.app"
uc() {   # <label> <setup command>: an unmarked game fixture under an unknown name, alone: step 4 asks the same tests
  newhome; eval "$2"; check "WT5 step 4 passes over $1" "$(fnd game 949230 | oneline)" "rc=1"
}
uc "a symlink" 'mkw "$H/real/g.app" cs2; ln -s "$H/real/g.app" "$H/Applications/g.app"'
uc "a folder writable by group" 'mkw "$H/Applications/g.app" cs2; chmod 775 "$H/Applications/g.app"'
uc "a quarantined app" 'mkw "$H/Applications/g.app" cs2; xattr -w com.apple.quarantine "0081;00000000;Safari;" "$H/Applications/g.app"'
newhome; mkw "$H/Applications/p3.app" bare game-wrapper 949230
chmod 777 "$H/Applications/p3.app/Contents" "$H/Applications/p3.app/Contents/SharedSupport/prefix"; chmod 666 "$H/Applications/p3.app/Contents/Info.plist"
check "WT5 a candidate shaped as P3 read an installer-made wrapper (folder 755, Contents and prefix 777)" "$(fnd game 949230 | oneline)" "$H/Applications/p3.app|rc=0"

# --- WT5b: step 4
newhome; mkw "$H/Applications/Unknown Name.app" cs2
check "WT5b an unmarked game fixture under an unknown name: Cities: Skylines II" "$(fnd game 949230 | oneline)" "$H/Applications/Unknown Name.app|rc=0"
newhome; mkw "$H/Applications/Unknown Name.app" sm
check "WT5b ...and Surviving Mars" "$(fnd game 3215050 | oneline)" "$H/Applications/Unknown Name.app|rc=0"
newhome; mkw "$H/Applications/store clone.app" cs2 steam-wrapper
check "WT5b one that holds the program but is marked steam-wrapper is passed over" "$(fnd game 949230 | oneline)" "rc=1"

# --- WT5c: the table, name, list, incomplete
rows=0; missing=""
while IFS="$(printf '\t')" read -r id _; do
  case "$id" in ''|\#*) continue ;; esac
  rows=$((rows + 1))
  bash -c '. "$1"; l1w_row game "$2"' _ "$W" "$id" || missing="$missing $id"
done < "$REPO/common/games.tsv"
check "WT5c every game of games.tsv has a row in the table ($rows games)" "${missing:-none}" "none"
check "WT5c name prints the three names" "$(bash "$W" name game 949230)|$(bash "$W" name game 3215050)|$(bash "$W" name steam)" \
  "wrapper-949230.app|wrapper-3215050.app|wrapper-0.app"
check "WT5c name refuses a game with no app ID" "$(bash "$W" name game 2>/dev/null; echo "rc=$?")" "rc=1"
newhome; mkw "$H/Applications/wrapper-949230.app" cs2 game-wrapper 949230; mkw "$H/Applications/wrapper-0.app" steam steam-wrapper
plutil -replace L1RenamePending -bool true "$H/Applications/wrapper-0.app/Contents/Info.plist"; mkw "$H/Applications/CS2dxmt11.app" bare
mkdir -p "$H/Applications/Cities Skylines II.app/Contents"; printf '%s' '<plist version="1.0"><dict><key>L1Role</key><string>game</string></dict></plist>' > "$H/Applications/Cities Skylines II.app/Contents/Info.plist"
check "WT5c list prints role, app ID and ~ path of each marked wrapper, and nothing else" "$(R bash "$W" list)" \
  "steam-wrapper - ~/Applications/wrapper-0.app  (rename pending)
game-wrapper 949230 ~/Applications/wrapper-949230.app"
check "WT5c ...and nothing of the home folder's name" "$(R bash "$W" list | grep -c "$H")" 0
inc() { R bash "$W" incomplete game "$@" 2>/dev/null; echo "rc=$?"; }
newhome; mkdir -p "$H/Applications/CS2dxmt11.app/Contents"
check "WT5c incomplete: CS2dxmt11.app with no prefix is printed" "$(inc 949230 | oneline)" "$H/Applications/CS2dxmt11.app|rc=0"
newhome; mkw "$H/Applications/CS2dxmt11.app" bare
check "WT5c incomplete: exit 1 when it has a prefix" "$(inc 949230 | oneline)" "rc=1"
newhome
check "WT5c incomplete: exit 1 when it is not there" "$(inc 949230 | oneline)" "rc=1"
newhome; mkdir -p "$H/Applications/CS2.app/Contents" "$H/SystemApplications/CS2dxmt11.app/Contents"
check "WT5c incomplete: exit 1 for a CS2.app or a system-folder CS2dxmt11.app with no prefix" "$(inc 949230 | oneline)" "rc=1"
newhome; mkdir -p "$H/Applications/SurvivingMars.app/Contents"
check "WT5c incomplete: SurvivingMars.app with no prefix is printed" "$(inc 3215050 | oneline)" "$H/Applications/SurvivingMars.app|rc=0"

# --- sourced: under set -eu, twice, exporting nothing
newhome; mkw "$H/Applications/x.app" bare game-wrapper 949230
out="$(R bash -c 'set -eu; before="$(env | sort)"; . "$1"; . "$1"; p="$(l1w_find game 949230)"; after="$(env | sort)"
  [ "$before" = "$after" ] && echo "$p" || echo "exports changed"' _ "$W" 2>&1)"
check "sourced twice under set -eu, nothing exported" "$out" "$H/Applications/x.app"

# --- the one write (l1w_mark): mode kept, CFBundleName only when it is the old name, the identifier untouched
newhome; mkw "$H/Applications/old.app" bare; chmod 666 "$H/Applications/old.app/Contents/Info.plist"
P="$H/Applications/old.app/Contents/Info.plist"
plutil -replace CFBundleName -string old "$P"; plutil -replace CFBundleIdentifier -string com.oldname123.wineskin "$P"
R bash -c '. "$1"; l1w_mark "$HOME/Applications/old.app" game 949230 1 old wrapper-949230' _ "$W"
check "l1w_mark writes the marker, renames the stored name, keeps the identifier and the mode" \
  "$(plutil -extract L1Role raw "$P")|$(plutil -extract L1SteamAppID raw "$P")|$(plutil -extract L1RenamePending raw "$P")|$(plutil -extract CFBundleName raw "$P")|$(plutil -extract CFBundleIdentifier raw "$P")|$(stat -f %Lp "$P")|$(ls -A "$H/Applications/old.app/Contents" | oneline)" \
  "game-wrapper|949230|true|wrapper-949230|com.oldname123.wineskin|666|Info.plist|SharedSupport"
R bash -c '. "$1"; l1w_mark "$HOME/Applications/old.app" steam - 0 x y' _ "$W"
check "l1w_mark to the Windows Steam's role: no app ID, no pending, another stored name left alone" \
  "$(plutil -extract L1Role raw "$P")|$(plutil -extract L1SteamAppID raw "$P" 2>/dev/null || echo none)|$(plutil -extract L1RenamePending raw "$P" 2>/dev/null || echo none)|$(plutil -extract CFBundleName raw "$P")" \
  "steam-wrapper|none|none|wrapper-949230"
printf 'not a plist' > "$P"
check "l1w_mark refuses an Info.plist that does not parse, and leaves it" "$(R bash -c '. "$1"; l1w_mark "$HOME/Applications/old.app" game 949230 1 2>&1; echo "rc=$?"' _ "$W" | oneline)|$(cat "$P")" \
  "~/Applications/old.app's Info.plist does not parse|rc=1|not a plist"

# --- WT12: the census. Code files (no .md) that spell an old wrapper name, against the list kept here.
ALLOWED="common/test-wrappers.sh
common/wrappers.sh
docs/wine-bugs/measurement-engine1116.txt"
got="$(cd "$C" && grep -rlE 'CS2dxmt11|SurvivingMars(\.app|[^A-Za-z]|$)|CS2\.app' --exclude='*.md' . 2>/dev/null | sed 's#^\./##' | LC_ALL=C sort)"
check "WT12 the code files that spell an old wrapper name are the census list" "$got" "$(printf '%s\n' "$ALLOWED" | LC_ALL=C sort)"

echo "test-wrappers: $pass passed, $fail failed"
[ "$fail" = 0 ]
