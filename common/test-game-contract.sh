#!/bin/bash
# test-game-contract.sh -- the contract a game meets (docs/plans/launcher-first-install.md, 3.6; LFT7), held for
# every row of common/games.tsv of a tree, without running anything of Wine, of Steam or of an installer: files
# are read, two scripts are parsed with bash -n, and common/wrappers.sh is read for its table. A new game is
# written against this file.
#   bash common/test-game-contract.sh [<tree>]     exit 0 = every row meets it; the tree defaults to this one
#   MUTANT=<n> bash common/test-game-contract.sh   on a scratch copy of the tree; each must exit 1
#     1 an ID taken out of l1w_games               2 a GAME_APPID that is not the row's
#     3 a guide's address with no file             4 WORDS_NEED holding $(date)
#     5 a terminal read with no -t 0 in reach      6 a fifth field in a row
#     7 a `# Terminal questions:` line one too low
# What it holds, per row: four tab-separated fields (a Steam app ID of digits, a folder that is a plain name, a
# title, a guide's address on github.com that names a file of the tree); the folder with scripts/install.sh and
# scripts/setup.sh, which parse; the installer sets every setting of the core's list, GAME_APPID the row's ID and
# GAME_TITLE the row's title, reads common/install-core.sh, and lists its exit codes in its header; WORDS_NEED
# and NEED_GB are one-line literals with no $ and no backtick; common/wrappers.sh knows the game (l1w_row game
# <ID>, and the ID in l1w_games). And the reverse: every ID of l1w_games has a row. The questions: a terminal
# read is a line on which read is a command, which holds no <, and which is not the test of a while; for each one
# in the installer, the core and the setup, -t 0 stands on its own line or on one of the ten lines above it, and
# the number of them in each file is the number in its header line `# Terminal questions: <n>`.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TREE="${1:-$(cd "$HERE/.." && pwd)}"
M="${MUTANT:-0}"
T=""
trap '[ -n "$T" ] && rm -rf "$T"' EXIT
fails=0
check() {  # <name> <got> <want>
  if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi
}
[ -f "$TREE/common/games.tsv" ] || { echo "REFUSED: $TREE holds no common/games.tsv"; exit 2; }

if [ "$M" != 0 ]; then   # a scratch copy of what is read, with one thing changed
  T="$(mktemp -d /tmp/game-contract-test.XXXX)"
  mkdir -p "$T/tree/common"
  cp "$TREE/common/games.tsv" "$TREE/common/wrappers.sh" "$TREE/common/install-core.sh" "$T/tree/common/"
  while IFS=$'\t' read -r id folder title guide rest <&3; do
    [ -d "$TREE/$folder/scripts" ] || continue
    mkdir -p "$T/tree/$folder/scripts"; cp "$TREE/$folder/scripts/install.sh" "$TREE/$folder/scripts/setup.sh" "$T/tree/$folder/scripts/"
    g="${guide#https://github.com/macgameport/1launcher/blob/main/}"
    [ "$g" != "$guide" ] && [ -f "$TREE/$g" ] && { mkdir -p "$(dirname "$T/tree/$g")"; cp "$TREE/$g" "$T/tree/$g"; }
  done 3< "$TREE/common/games.tsv"
  FIRST="$(awk -F'\t' 'NR == 1 { print $2 }' "$T/tree/common/games.tsv")"; FID="$(awk -F'\t' 'NR == 1 { print $1 }' "$T/tree/common/games.tsv")"
  before="$(cd "$T/tree" && find . -type f -exec shasum {} + | LC_ALL=C sort | shasum)"
  case "$M" in
    1) sed -i '' "s/^l1w_games() { echo $FID; /l1w_games() { /" "$T/tree/common/wrappers.sh" ;;
    2) sed -i '' 's/^GAME_APPID=.*/GAME_APPID=1/' "$T/tree/$FIRST/scripts/install.sh" ;;
    3) awk -F'\t' -v OFS='\t' 'NR == 1 { $4 = $4 ".gone" } { print }' "$T/tree/common/games.tsv" > "$T/t" && mv "$T/t" "$T/tree/common/games.tsv" ;;
    4) sed -i '' 's/^WORDS_NEED=.*/WORDS_NEED="about $(date) free"/' "$T/tree/$FIRST/scripts/install.sh" ;;
    5) sed -i '' 's/ \[ -t 0 \]; then printf /; then printf /' "$T/tree/common/install-core.sh" ;;
    6) awk -F'\t' -v OFS='\t' 'NR == 1 { $0 = $0 OFS "a fifth field" } { print }' "$T/tree/common/games.tsv" > "$T/t" && mv "$T/t" "$T/tree/common/games.tsv" ;;
    7) f="$T/tree/common/install-core.sh"; n="$(sed -n 's/^# Terminal questions: \([0-9][0-9]*\)$/\1/p' "$f")"
       sed -i '' "s/^# Terminal questions: $n\$/# Terminal questions: $((n - 1))/" "$f" ;;
    *) echo "REFUSED: no mutant $M"; exit 2 ;;
  esac
  [ "$(cd "$T/tree" && find . -type f -exec shasum {} + | LC_ALL=C sort | shasum)" != "$before" ] || { echo "REFUSED: mutant $M did not apply"; exit 2; }
  TREE="$T/tree"
fi

TABLE="$TREE/common/games.tsv"; CORE="$TREE/common/install-core.sh"; WRAPPERS="$TREE/common/wrappers.sh"
SETTINGS="$(sed -n '/^for _v in /,/; do$/p' "$CORE" | tr -s ' \\\n' ' ' | sed 's/^for _v in //; s/; do *$//')"
check "the core names the settings a game's installer sets" "$([ "$(printf '%s\n' $SETTINGS | wc -l | tr -d ' ')" -ge 10 ] && echo listed)" listed

# the lines of a file that are terminal reads, as "<line number>:<line>"
reads() { grep -n -E '(^|[;&|]|[[:space:]]then|[[:space:]]do|[[:space:]]else)[[:space:]]*read[[:space:]]+-' "$1" | grep -v '<' | grep -v -E '^[0-9]+:[[:space:]]*while[[:space:]]'; }
questions() {   # <file> <its name in the checks>: its terminal reads, each with -t 0 in reach, counted in its header line
  local f="$1" name="$2" n=0 far=0 ln declared
  while IFS=: read -r ln rest; do
    [ -n "$ln" ] || continue
    n=$((n + 1))
    sed -n "$(( ln > 10 ? ln - 10 : 1 )),${ln}p" "$f" | grep -q -- '-t 0' || far=$((far + 1))
  done << EOF
$(reads "$f")
EOF
  declared="$(sed -n 's/^# Terminal questions: \([0-9][0-9]*\)$/\1/p' "$f")"
  check "$name: every terminal read has -t 0 on its own line or within the ten lines above it" "$far" 0
  check "$name: its header line counts its terminal reads" "${declared:-none}" "$n"
}
questions "$CORE" "common/install-core.sh"

rows=0
while IFS= read -r line <&3; do
  case "$line" in '#'*|'') continue ;; esac
  rows=$((rows + 1))
  nf="$(printf '%s\n' "$line" | awk -F'\t' '{ print NF }')"
  IFS=$'\t' read -r id folder title guide rest << EOF
$line
EOF
  check "row $rows: exactly four tab-separated fields" "$nf" 4
  check "row $rows ($id): a Steam app ID of digits, a folder that is a plain name, a title, a guide on github.com" \
    "$([[ "$id" =~ ^[1-9][0-9]{0,9}$ ]] && echo id):$([[ "$folder" =~ ^[a-z0-9][a-z0-9-]*$ ]] && echo folder):$([ -n "$title" ] && echo title):$([ "${guide#https://github.com/}" != "$guide" ] && echo guide)" "id:folder:title:guide"
  [[ "$folder" =~ ^[a-z0-9][a-z0-9-]*$ ]] || continue
  I="$TREE/$folder/scripts/install.sh"; S="$TREE/$folder/scripts/setup.sh"
  check "$folder: the folder is there, with scripts/install.sh and scripts/setup.sh, and both parse" \
    "$([ -d "$TREE/$folder" ] && echo folder):$([ -f "$I" ] && bash -n "$I" 2>/dev/null && echo installer):$([ -f "$S" ] && bash -n "$S" 2>/dev/null && echo setup)" "folder:installer:setup"
  [ -f "$I" ] && [ -f "$S" ] || continue
  missing=""
  for v in $SETTINGS; do grep -q "^$v=" "$I" || missing="$missing $v"; done
  check "$folder: its installer sets every setting of the core's list" "${missing:-none}" none
  check "$folder: GAME_APPID is the row's ID and GAME_TITLE the row's title" \
    "$(sed -n 's/^GAME_APPID=\([0-9]*\)[[:space:]]*\(#.*\)\{0,1\}$/\1/p' "$I"):$(sed -n 's/^GAME_TITLE="\(.*\)"[[:space:]]*\(#.*\)\{0,1\}$/\1/p' "$I")" "$id:$title"
  check "$folder: its installer reads common/install-core.sh" "$(grep -c '^\. .*/common/install-core\.sh"\{0,1\}$' "$I")" 1
  check "$folder: WORDS_NEED and NEED_GB are one-line literals, with no \$ and no backtick" \
    "$(grep -c -E '^WORDS_NEED="[^"$`\\]+"[[:space:]]*(#.*)?$' "$I"):$(grep -c -E '^NEED_GB=[0-9]+[[:space:]]*(#.*)?$' "$I")" "1:1"
  check "$folder: its installer's header lists the exit codes 0 to 4" \
    "$(sed -n '2,/^set -u$/p' "$I" | grep '^#' | tr '\n' ' ' | grep -c -E 'exit 0 = .*[^0-9]1 = .*[^0-9]2 = .*[^0-9]3 = .*[^0-9]4 = ')" 1
  check "$folder: common/wrappers.sh knows the game: l1w_row game $id returns 0, and l1w_games prints the ID" \
    "$( ( . "$WRAPPERS"; l1w_row game "$id"; echo "$?:$(l1w_games | grep -cx "$id")" ) 2>/dev/null )" "0:1"
  g="${guide#https://github.com/macgameport/1launcher/blob/main/}"
  check "$folder: the guide's address names a file of the tree" "$([ "$g" != "$guide" ] && [ -f "$TREE/$g" ] && echo file)" file
  questions "$I" "$folder/scripts/install.sh"
  questions "$S" "$folder/scripts/setup.sh"
done 3< "$TABLE"
check "the table holds at least one game" "$([ "$rows" -ge 1 ] && echo rows)" rows
norow=""
for id in $( ( . "$WRAPPERS"; l1w_games ) 2>/dev/null ); do
  awk -F'\t' -v id="$id" '$1 == id { f = 1 } END { exit !f }' "$TABLE" || norow="$norow $id"
done
check "the reverse: every ID of l1w_games has a row in the table" "${norow:-none}" none

echo "$fails failure(s)"
[ "$fails" = 0 ]
