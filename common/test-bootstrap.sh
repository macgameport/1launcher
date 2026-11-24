#!/bin/bash
# test-bootstrap.sh -- the root install.sh (docs/plans/simple-install.md, 2.4 and NT4; docs/plans/
# shared-installer.md, 2.2 and ST5), with HOME and TMPDIR at scratch folders and a stub curl that serves
# fixture archives. Every fixture holds a common/games.tsv; the fixture's game installer records its
# arguments, what L1_FETCHED_REF it was given, and the folder it lies in, on one line, and what L1_FETCHED_COMMIT
# and CS2_PATCH_DIR it was given in two side files. One fixture is cut with git archive
# from a scratch repository, so that it carries its commit in its header as GitHub's archives do. No network.
# Every fixture but one holds a common/update-games.sh too, a recorder of its arguments and of the two
# variables (docs/plans/built-in-update.md, 3.4; UT6).
#   bash common/test-bootstrap.sh            exit 0 = every case passed
#   MUTANT=1 ...  the temporary folder kept; must exit 1
#   MUTANT=2 ...  the installer's exit code dropped; must exit 1
#   MUTANT=3 ...  a ref with .. fetched; must exit 1
#   MUTANT=4 ...  the checkout's case decided by $0; must exit 1
#   MUTANT=5 ...  L1_FETCHED_REF not set; must exit 1
#   MUTANT=6 ...  a default game put back; must exit 1
#   MUTANT=7 ...  a folder's name taken as the first word; must exit 1
#   MUTANT=8 ...  the folder taken from the word, not from the table; must exit 1
#   MUTANT=9 ...  a table of IDs and folders written into the script; must exit 1
#   MUTANT=10 ..  with no game named, the list got by fetching first; must exit 1
#   MUTANT=11 ..  a variable put in front of the pasted line dropped before the game's installer; must exit 1
#   MUTANT=12 ..  curl's exit code 22 put back as the test for "no such ref"; must exit 1
#   MUTANT=13 ..  every answer but 200 read as "no such ref"; must exit 1
#   MUTANT=14 ..  L1_FETCHED_COMMIT not exported (built-in-update 3.3; UT5, also); must exit 1
# The word update (built-in-update 3.4; UT6); each must exit 1:
#   MUTANT=15 ..  the word accepted in any case (Update)
#   MUTANT=16 ..  what follows the word passed on to the driver (the refusal of an option dropped)
#   MUTANT=17 ..  the checkout case made to run the checkout's driver
#   MUTANT=18 ..  the driver's exit code dropped
#   MUTANT=19 ..  the short form of the archive's address put back for release (UT6, also)
# The stub curl honours -o and -w as curl does: the body goes to the file and the answer's code to standard
# output. STUB_CURL_CODE is that code (200 when unset; 000 = no answer, nothing written) and STUB_CURL_EXIT
# curl's exit (0 when unset): for a 404 the real one exits 0 without -f, 22 or 56 with it (built-in-update 1.5).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
REAL="$REPO/install.sh"
T="$(mktemp -d /tmp/bootstrap-test.XXXX)"
trap 'rm -rf "$T"' EXIT
S="$T/install.sh"; cp "$REAL" "$S"
mutate() {  # <sed expression> <grep that proves it applied>
  sed -i '' "$1" "$S"; grep -q -- "$2" "$S" || { echo "REFUSED: mutant did not apply"; exit 2; }
}
case "${MUTANT:-0}" in
  1) mutate "s#^  trap 'rm -rf \"\$L1_TMP\"' EXIT\$#  :#" '^  :$' ;;
  2) mutate 's#^  bash "\$top/\$folder/scripts/install.sh" "\$@"$#  bash "$top/$folder/scripts/install.sh" "$@"; true#' 'install.sh" "\$@"; true$' ;;
  3) mutate 's#-\*|/\*|\*\.\.\*|\*//\*)#-*|/*|*//*)#' '^    -\*|/\*|\*//\*)' ;;
  4) mutate 's#^  self="\${BASH_SOURCE\[0\]:-}"$#  self="$0"#' '^  self="\$0"$' ;;
  5) mutate 's#^  export L1_FETCHED_REF="\$ref"$#  :#' '^  :$' ;;
  6) mutate 's#^  local id="" ref=release #  local id=949230 ref=release #' '^  local id=949230 ' ;;
  7) mutate "s#^    ''|\*\[!0-9\]\*)\$#    ''|*[!0-9a-z-]*)#" "^    ''|\*\[!0-9a-z-\]\*)\$" ;;
  8) mutate 's#^  folder="\$(game_folder "\$top/common/games.tsv" "\$id")"$#  folder="$id"#' '^  folder="\$id"$' ;;
  9) mutate 's#^  awk -F.*#  case "$2" in 949230) echo cities-skylines-2 ;; esac#' '^  case "\$2" in 949230) echo cities-skylines-2 ;; esac$' ;;
  10) mutate 's#^      return 2 ;;$#      ;;#' '^      ;;$' ;;
  11) mutate 's#^  bash "\$top/\$folder/scripts/install.sh" "\$@"$#  unset CS2_PATCH_DIR; bash "$top/$folder/scripts/install.sh" "$@"#' '^  unset CS2_PATCH_DIR; bash ' ;;
  12) mutate 's#^  if \[ "\$code" = 404 \]; then$#  if [ "$rc" = 22 ]; then#' '^  if \[ "\$rc" = 22 \]; then$' ;;
  13) mutate 's#^  if \[ "\$code" = 404 \]; then$#  if [ "$code" != 200 ]; then#' '^  if \[ "\$code" != 200 \]; then$' ;;
  14) mutate 's#^  if \[ -n "\$commit" \]; then export L1_FETCHED_COMMIT=.*#  :#' '^  :$' ;;
  15) mutate 's#^  if \[ "\$id" = update \]; then$#  if [ "$(printf "%s" "$id" | tr A-Z a-z)" = update ]; then#' '^  if \[ "\$(printf "%s" "\$id" | tr A-Z a-z)" = update \]; then$' ;;
  16) mutate 's#^    if \[ \$\# -gt 0 \]; then echo "update takes no option: .*#    :#' '^    :$'
      mutate 's#^    bash "\$top/common/update-games.sh"$#    bash "$top/common/update-games.sh" "$@"#' '^    bash "\$top/common/update-games.sh" "\$@"$' ;;
  17) mutate 's#^    if \[ -n "\$table" \]; then echo "This is a checkout: .*#    if [ -n "$table" ]; then bash "$here/common/update-games.sh"; return $?; fi#' '^    if \[ -n "\$table" \]; then bash "\$here/common/update-games.sh"; return \$?; fi$' ;;
  18) mutate 's#^    bash "\$top/common/update-games.sh"$#    bash "$top/common/update-games.sh"; true#' '^    bash "\$top/common/update-games.sh"; true$' ;;
  19) mutate 's#^  \[ "\$ref" = release \] && url=.*#  :#' '^  :$' ;;
esac

fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}

# --- fixtures: each a repository with its table; the recorder says which game folder it was run from
F="$T/fix"; mkdir -p "$F"
REC='#!/bin/bash
here="$(cd "$(dirname "$0")/.." && pwd)"
echo "INSTALLER args=$* ref=${L1_FETCHED_REF:-} from=$(basename "$(dirname "$here")") game=$(basename "$here")" >> "$CALLS"
echo "${CS2_PATCH_DIR:-}" > "$CALLS.patchdir"
echo "${L1_FETCHED_COMMIT-unset}" > "$CALLS.commit"
exit "${STUB_INSTALL_EXIT:-0}"'
DRV='#!/bin/bash
here="$(cd "$(dirname "$0")/.." && pwd)"
echo "DRIVER args=$* argc=$# ref=${L1_FETCHED_REF:-} commit=${L1_FETCHED_COMMIT-unset} from=$(basename "$here")" >> "$CALLS"
exit "${STUB_DRIVER_EXIT:-0}"'
table() {   # <root> [the first game's folder]: the table, with a game that has no installer and a row gone wrong
  mkdir -p "$1/common"
  printf '949230\t%s\tCities: Skylines II\thttps://example.invalid/%s/README.md\n' "${2:-cities-skylines-2}" "${2:-cities-skylines-2}" > "$1/common/games.tsv"
  printf '3215050\tother-game\tAnother Game\thttps://example.invalid/other-game/README.md\n' >> "$1/common/games.tsv"
  printf '777\t../x\tA Row Gone Wrong\thttps://example.invalid/x\n' >> "$1/common/games.tsv"
}
repo() {    # <root> [the first game's folder]: a fixture repository
  mkdir -p "$1/${2:-cities-skylines-2}/scripts" "$1/other-game"
  printf '%s\n' "$REC" > "$1/${2:-cities-skylines-2}/scripts/install.sh"; : > "$1/other-game/README.md"
  table "$1" "${2:-}"
  printf '%s\n' "$DRV" > "$1/common/update-games.sh"
}
G="$T/gitrepo"; repo "$G"
( cd "$G" && git init -q . && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -q -m fixture \
  && git archive --format=tar.gz --prefix=1launcher-release/ HEAD > "$F/good.tar.gz" )
COMMIT="$(git -C "$G" rev-parse HEAD)"
repo "$F/plain/1launcher-x"; ( cd "$F/plain" && tar -czf "$F/plain.tar.gz" 1launcher-x )
repo "$F/renamed/1launcher-x" a-new-name; ( cd "$F/renamed" && tar -czf "$F/renamed.tar.gz" 1launcher-x )
repo "$F/nodriver/1launcher-x"; rm "$F/nodriver/1launcher-x/common/update-games.sh"; ( cd "$F/nodriver" && tar -czf "$F/nodriver.tar.gz" 1launcher-x )
repo "$F/two/a"; mkdir -p "$F/two/b"; ( cd "$F/two" && tar -czf "$F/two.tar.gz" a b )
mkdir -p "$F/link"; ln -s "$F/plain/1launcher-x" "$F/link/1launcher-x"; ( cd "$F/link" && tar -czf "$F/link.tar.gz" 1launcher-x )
echo "not an archive" > "$F/broken.tar.gz"
mkdir -p "$T/bin"
cat > "$T/bin/curl" << 'C'
#!/bin/bash
echo "CURL $*" >> "$CALLS"
out=""; w=0; while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2 ;; -w) w=1; shift 2 ;; *) shift ;; esac; done
code="${STUB_CURL_CODE:-200}"
if [ "$code" = 200 ]; then cp "$FIX" "$out"; elif [ "$code" != 000 ]; then echo "$code: an error page" > "$out"; fi
[ "$w" = 1 ] && printf '%s' "$code"
exit "${STUB_CURL_EXIT:-0}"
C
printf '#!/bin/bash\nif [ "$1" = -u ] && [ -n "${STUB_ROOT:-}" ]; then echo 0; else exec /usr/bin/id "$@"; fi\n' > "$T/bin/id"
chmod +x "$T/bin"/*
export CALLS="$T/calls"
TM="$T/tmp"; mkdir -p "$TM" "$T/empty" "$T/home"
left() { ls -A "$TM" | wc -l | tr -d ' '; }
calls() { grep -c -- "$1" "$CALLS"; }
URL='https://github.com/macgameport/1launcher/archive'
FRONT='https://github.com/macgameport/1launcher'
# the pasted form: bash -c "<the script's text>" [name [arguments]], from folder $1
pasted() {   # <folder> <fixture> [name and arguments]: output in $T/out; echoes the exit code
  local d="$1" fix="$2"; shift 2; : > "$CALLS"
  ( cd "$d" && env HOME="$T/home" TMPDIR="$TM" PATH="$T/bin:$PATH" FIX="$fix" /bin/bash -c "$(cat "$S")" "$@" > "$T/out" 2>&1 < /dev/null; echo $? )
}
asfile() {   # <script path> <fixture> [arguments]
  local f="$1" fix="$2"; shift 2; : > "$CALLS"
  ( cd "$T/empty" && env HOME="$T/home" TMPDIR="$TM" PATH="$T/bin:$PATH" FIX="$fix" bash "$f" "$@" > "$T/out" 2>&1 < /dev/null; echo $? )
}
said() { grep -c -- "$1" "$T/out"; }

check "the file's last line is the call of main" "$(tail -n 1 "$REAL")" 'main "$@"'
check "the script names no game's folder" "$(grep -cE 'cities-skylines-2|surviving-mars-relaunched' "$REAL")" 0

# --- a variable put in front of the pasted line reaches the game's installer (docs/plans/local-files-layout.md, LT23)
rc="$(CS2_PATCH_DIR=/x/named-folder pasted "$T/empty" "$F/good.tar.gz" x 949230)"
check "CS2_PATCH_DIR in front of the pasted line arrives at the game's installer" "$rc:$(cat "$CALLS.patchdir")" "0:/x/named-folder"

# --- the pasted form always fetches, and finds the game's folder in the table it fetched
rc="$(pasted "$T/empty" "$F/good.tar.gz" x 949230)"
check "pasted with an ID, from an empty folder: fetches the release branch by its full name, runs that row's installer, exit 0" \
  "$rc:$(grep -c "^CURL --proto =https --tlsv1.2 -sSL --retry 2 -o .* -w %{http_code} $URL/refs/heads/release.tar.gz\$" "$CALLS"):$(grep -c '^INSTALLER args= ref=release from=1launcher-release game=cities-skylines-2$' "$CALLS")" "0:1:1"
check "  ...says the commit it fetched" "$(said "^1launcher at commit $COMMIT\$")" 1
check "  ...and exports it as L1_FETCHED_COMMIT, the 40 digits alone, beside L1_FETCHED_REF (built-in-update 3.3)" "$(cat "$CALLS.commit")" "$COMMIT"
check "  ...and leaves no temporary folder" "$(left)" 0
rc="$(STUB_INSTALL_EXIT=7 pasted "$T/empty" "$F/good.tar.gz" x 949230)"
check "the installer's exit code is this script's" "$rc:$(left)" "7:0"
rc="$(pasted "$T/empty" "$F/good.tar.gz" 1launcher-install 949230 simple-install --check --yes)"
check "pasted with a name and arguments: the ref fetched, by its short name as before, the options passed on" \
  "$rc:$(calls " $URL/simple-install.tar.gz\$"):$(calls 'refs/heads'):$(grep -c '^INSTALLER args=--check --yes ref=simple-install ' "$CALLS")" "0:1:0:1"
rc="$(L1_FETCHED_COMMIT=0123456789abcdef0123456789abcdef01234567 pasted "$T/empty" "$F/plain.tar.gz" x 949230)"
check "an archive with no commit in its header: says so, and goes on" "$rc:$(said '^1launcher: commit not read$'):$(calls '^INSTALLER')" "0:1:1"
check "  ...no L1_FETCHED_COMMIT is exported then, and one left in the environment does not pass for this fetch's" "$(cat "$CALLS.commit")" unset
rc="$(pasted "$T/empty" "$F/renamed.tar.gz" x 949230)"
check "the game's folder renamed and its row changed: the same ID reaches it" \
  "$rc:$(grep -c '^INSTALLER args= ref=release from=1launcher-x game=a-new-name$' "$CALLS")" "0:1"
# --- the repository's own table: every game in it has an installer, and the bootstrap hands over to each
BOTH="$F/both/1launcher-x"; mkdir -p "$BOTH/common"; cp "$REPO/common/games.tsv" "$BOTH/common/"
rows=0; have=0
while IFS="$(printf '\t')" read -r id folder title guide; do
  rows=$((rows + 1)); [ -f "$REPO/$folder/scripts/install.sh" ] && have=$((have + 1))
  mkdir -p "$BOTH/$folder/scripts"; printf '%s\n' "$REC" > "$BOTH/$folder/scripts/install.sh"
done < "$REPO/common/games.tsv"
( cd "$F/both" && tar -czf "$F/both.tar.gz" 1launcher-x )
check "every game in common/games.tsv has scripts/install.sh in its folder" "$have:$([ "$rows" -ge 2 ] && echo two-or-more)" "$rows:two-or-more"
rc="$(pasted "$T/empty" "$F/both.tar.gz" x 3215050)"
check "the repository's table: 3215050 reaches Surviving Mars's installer" "$rc:$(grep -c '^INSTALLER args= ref=release from=1launcher-x game=surviving-mars-relaunched$' "$CALLS"):$(calls '^INSTALLER')" "0:1:1"
rc="$(pasted "$T/empty" "$F/both.tar.gz" 1launcher-install 949230 release --check)"
check "  ...and 949230 reaches Cities: Skylines II's, with its options" "$rc:$(grep -c '^INSTALLER args=--check ref=release from=1launcher-x game=cities-skylines-2$' "$CALLS"):$(calls '^INSTALLER')" "0:1:1"
CO="$T/checkout"; mkdir -p "$CO/cities-skylines-2/scripts" "$CO/other-game"; cp "$S" "$CO/install.sh"; table "$CO"
printf '%s\n' "$DRV" > "$CO/common/update-games.sh"
printf '#!/bin/bash\necho "LOCAL args=$*" >> "$CALLS"\n' > "$CO/cities-skylines-2/scripts/install.sh"
rc="$(pasted "$CO" "$F/good.tar.gz" x 949230)"
check "pasted from inside a checkout: still fetches, the local installer is not run" "$rc:$(calls '^CURL'):$(calls '^LOCAL'):$(calls '^INSTALLER')" "0:1:0:1"
rc="$(pasted "$CO" "$F/good.tar.gz" install.sh 949230)"
check "  ...even with install.sh as its name word" "$rc:$(calls '^CURL'):$(calls '^LOCAL')" "0:1:0"

# --- as a file in a checkout: nothing fetched, the checkout's own table read
rc="$(asfile "$CO/install.sh" "$F/good.tar.gz" 949230)"
check "as a file beside the table: curl not called, the checkout's installer run" "$rc:$(calls '^CURL'):$(grep -c '^LOCAL args=$' "$CALLS"):$(said 'Using this checkout')" "0:0:1:1"
rc="$(asfile "$CO/install.sh" "$F/good.tar.gz" 949230 some-ref --check)"
check "  ...a ref is ignored there, options passed on" "$rc:$(calls '^CURL'):$(grep -c '^LOCAL args=--check$' "$CALLS")" "0:0:1"
rc="$(asfile "$CO/install.sh" "$F/good.tar.gz" 3215050)"
check "  ...a game with no installer there: exit 2, the list, and no fetch to look further" \
  "$rc:$(calls '^CURL'):$(said '^This checkout has no installer for app 3215050'):$(said '^  949230  Cities: Skylines II$'):$(said 'Another Game')" "2:0:1:1:0"
rc="$(asfile "$S" "$F/good.tar.gz" 949230)"
check "as a file with no table beside it: fetches" "$rc:$(calls '^CURL'):$(calls '^INSTALLER')" "0:1:1"

# --- no game named: there is no default; nothing fetched
rc="$(pasted "$T/empty" "$F/good.tar.gz")"
check "pasted with no word: exit 2, nothing fetched, the usage line and the front page, no installer run" \
  "$rc:$(calls '^CURL'):$(said '^Say which game'):$(said '^usage: install.sh <Steam app ID>'):$(said "listed at $FRONT\$"):$(calls '^INSTALLER')" "2:0:1:1:1:0"
rc="$(pasted "$T/empty" "$F/good.tar.gz" x --check)"
check "  ...options alone: the same, they do not stand for a game" "$rc:$(calls '^CURL'):$(said '^Say which game')" "2:0:1"
rc="$(pasted "$T/empty" "$F/good.tar.gz" x cities-skylines-2)"
check "a folder's name as the first word: exit 2, nothing fetched, said not to be an ID" "$rc:$(calls '^CURL'):$(said '^not a Steam app ID: cities-skylines-2$')" "2:0:1"
rc="$(asfile "$CO/install.sh" "$F/good.tar.gz")"
check "no word, as a file in a checkout: exit 2, nothing fetched, that checkout's games listed by ID and title" \
  "$rc:$(calls '^CURL'):$(said '^  949230  Cities: Skylines II$'):$(said 'Another Game'):$(said 'A Row Gone Wrong')" "2:0:1:0:0"

# --- the word update (docs/plans/built-in-update.md, 3.4; UT6): it names no game, and hands over to the driver
#     that came with the fetch
rc="$(pasted "$T/empty" "$F/good.tar.gz" 1launcher-install update)"
check "update, pasted: fetches release by its full name, runs the fetched driver with no argument, the ref and the commit; exit 0" \
  "$rc:$(calls '^CURL'):$(calls " $URL/refs/heads/release.tar.gz\$"):$(grep -c "^DRIVER args= argc=0 ref=release commit=$COMMIT from=1launcher-release\$" "$CALLS")" "0:1:1:1"
check "  ...no game's installer is run, the commit is said, and no temporary folder is left" "$(calls '^INSTALLER'):$(said "^1launcher at commit $COMMIT\$"):$(left)" "0:1:0"
for x in 3 1 7; do
  rc="$(STUB_DRIVER_EXIT=$x pasted "$T/empty" "$F/good.tar.gz" 1launcher-install update)"
  check "the driver's exit code $x is this script's" "$rc:$(calls '^DRIVER'):$(left)" "$x:1:0"
done
rc="$(pasted "$T/empty" "$F/good.tar.gz" 1launcher-install update some-ref)"
check "update with a ref: that ref fetched by its short name, and given to the driver" \
  "$rc:$(calls " $URL/some-ref.tar.gz\$"):$(calls 'refs/heads'):$(grep -c '^DRIVER args= argc=0 ref=some-ref ' "$CALLS")" "0:1:0:1"
rc="$(L1_FETCHED_COMMIT=0123456789abcdef0123456789abcdef01234567 pasted "$T/empty" "$F/plain.tar.gz" x update)"
check "update, an archive with no commit in its header: no L1_FETCHED_COMMIT reaches the driver" "$rc:$(grep -c '^DRIVER args= argc=0 ref=release commit=unset from=1launcher-x$' "$CALLS")" "0:1"
rc="$(pasted "$CO" "$F/good.tar.gz" x update)"
check "update, pasted from inside a checkout: still fetches, and runs the fetched driver, not the checkout's" \
  "$rc:$(calls '^CURL'):$(calls '^DRIVER .* from=1launcher-release$'):$(calls '^DRIVER')" "0:1:1:1"
upbad() { check "$1: usage, exit 2, nothing fetched, no driver run" "$2:$(calls '^CURL'):$(calls '^DRIVER'):$(said "$3")" "2:0:0:1"; }
upbad "update x --yes" "$(pasted "$T/empty" "$F/good.tar.gz" x update x --yes)" '^update takes no option: --yes (usage: install.sh update \[<ref>\])$'
upbad "update --check" "$(pasted "$T/empty" "$F/good.tar.gz" x update --check)" '^update takes no option: --check '
upbad "update with a third word" "$(pasted "$T/empty" "$F/good.tar.gz" x update release extra)" '^one word too many: extra '
upbad "update with a ref that has .." "$(pasted "$T/empty" "$F/good.tar.gz" x update '../x')" '^not a branch, tag or commit of this repository: \.\./x$'
rc="$(pasted "$T/empty" "$F/nodriver.tar.gz" x update)"
check "update, what was fetched has no driver: the sentence, exit 1, nothing run, no folder left" \
  "$rc:$(said '^This version of 1launcher cannot update an install\. Paste the installer line from the guide instead\.$'):$(calls '^DRIVER'):$(calls '^INSTALLER'):$(left)" "1:1:0:0:0"
rc="$(asfile "$CO/install.sh" "$F/good.tar.gz" update)"
check "update from a checkout: the sentence, exit 2, curl not called, the checkout's driver not run" \
  "$rc:$(said "^This is a checkout: update it with git pull, then run each game's scripts/setup.sh\.\$"):$(calls '^CURL'):$(calls '^DRIVER')" "2:1:0:0"
for w in Update updates UPDATE; do
  rc="$(pasted "$T/empty" "$F/good.tar.gz" x "$w")"
  check "the word $w is still not a Steam app ID: exit 2, nothing fetched, no driver run" "$rc:$(calls '^CURL'):$(calls '^DRIVER'):$(said "^not a Steam app ID: $w\$")" "2:0:0:1"
done

# --- refused with nothing fetched
bad() { check "$1: exit 2, nothing fetched" "$2:$(calls '^CURL')" "2:0"; }
bad "a ref with a space" "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 'a b')"
bad "a ref with ;" "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 'a;b')"
bad "a ref with .." "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 '../../other/repo/archive/main')"
bad "a ref with //" "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 'a//b')"
bad "a ref starting /" "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 '/etc')"
bad "a game named ../x" "$(pasted "$T/empty" "$F/good.tar.gz" x '../x')"
bad "a game with a capital" "$(pasted "$T/empty" "$F/good.tar.gz" x 'Cities')"
bad "an ID with a letter in it" "$(pasted "$T/empty" "$F/good.tar.gz" x '949230a')"
bad "a third leading word" "$(pasted "$T/empty" "$F/good.tar.gz" x 949230 release extra)"
rc="$(STUB_ROOT=1 pasted "$T/empty" "$F/good.tar.gz" x 949230)"
check "run as root: exit 1, nothing fetched" "$rc:$(calls '^CURL')" "1:0"

# --- an ID the fetched table does not answer: exit 2 with its list, no installer run, no folder left
nogame() { check "$1: exit 2 after the fetch, no installer run, no folder left" "$2:$(calls '^CURL'):$(calls '^INSTALLER'):$(left)" "2:1:0:0"; }
nogame "an ID with no row" "$(pasted "$T/empty" "$F/good.tar.gz" x 12345)"
check "  ...names the games that have an installer, by ID and title" "$(said '^There is no installer for app 12345'):$(said '^  949230  Cities: Skylines II$'):$(said 'Another Game')" "1:1:0"
nogame "an ID whose folder has no installer" "$(pasted "$T/empty" "$F/good.tar.gz" x 3215050)"
nogame "an ID whose row names no plain folder" "$(pasted "$T/empty" "$F/good.tar.gz" x 777)"

# --- failures: exit 1 with a line, no folder left, no installer run
failed() { check "$1: exit 1, no installer run, no folder left" "$2:$(calls '^INSTALLER'):$(left)" "1:0:0"; }
failed "the fetch fails: no answer" "$(STUB_CURL_CODE=000 STUB_CURL_EXIT=6 pasted "$T/empty" "$F/good.tar.gz" x 949230)"
check "  ...says to check the network, with curl's exit, and not that the ref is missing" "$(said 'GitHub could not be reached (curl exit 6, answer 000). Check the network'):$(said 'GitHub has no')" "1:0"
# UT1 (built-in-update U0): a 404 is "no such ref" whatever curl's exit; any other answer is "could not be reached"
for x in 0 22 56; do
  failed "GitHub has no such ref (404, curl exit $x)" "$(STUB_CURL_CODE=404 STUB_CURL_EXIT=$x pasted "$T/empty" "$F/good.tar.gz" x 949230)"
  check "  ...says so, points at the front page and at no folder, and does not blame the network" \
    "$(said '^GitHub has no "release" of 1launcher'):$(said "^  $FRONT\$"):$(said 'INSTALL.md'):$(said 'Check the network')" "1:1:0:0"
done
for c in 403 500; do
  failed "GitHub answers $c" "$(STUB_CURL_CODE=$c pasted "$T/empty" "$F/good.tar.gz" x 949230)"
  check "  ...could not be reached, with the code, and not \"no such ref\"" "$(said "GitHub could not be reached (curl exit 0, answer $c). Check the network"):$(said 'GitHub has no')" "1:0"
done
failed "what came is not an archive" "$(pasted "$T/empty" "$F/broken.tar.gz" x 949230)"
failed "an archive with two top folders" "$(pasted "$T/empty" "$F/two.tar.gz" x 949230)"
failed "an archive whose top entry is a link" "$(pasted "$T/empty" "$F/link.tar.gz" x 949230)"
failed "update, GitHub has no such ref (404)" "$(STUB_CURL_CODE=404 pasted "$T/empty" "$F/good.tar.gz" x update)"
check "  ...no driver run" "$(calls '^DRIVER'):$(said '^GitHub has no "release" of 1launcher')" "0:1"

echo "$fails failure(s)"
[ "$fails" = 0 ]
