#!/bin/bash
# install.sh -- the way in for a Mac with no checkout of this repository (docs/plans/simple-install.md, 2.4;
# docs/plans/shared-installer.md, 2.2). It fetches the repository into a temporary folder, finds the game's
# folder in common/games.tsv by the game's Steam app ID, hands over to that game's own installer
# (<folder>/scripts/install.sh), and removes the temporary folder again. Run from a checkout, it uses the
# checkout. With the word update in place of an ID it names no game: it fetches the same way and hands over to
# common/update-games.sh of what it fetched, which runs the installer of every game set up on this Mac
# (docs/plans/built-in-update.md, 3.4).
#
#   /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macgameport/1launcher/release/install.sh)" 1launcher-install <Steam app ID>
#   bash install.sh <Steam app ID> [<ref>] [options for the game's installer ...]
#   ... install.sh)" 1launcher-install update [<ref>]     (what the update's button in 14unch3r runs)
#
# A game is named by its Steam app ID, the first field of its row in common/games.tsv, and never by its
# folder: what is published (the pasted line, the installer app) then holds nothing a renamed folder breaks.
# There is no default game: with no ID this says so and stops. The ref defaults to release, the branch that
# moves forward only on purpose; release is fetched by its full name (refs/heads/release), so that a tag of that
# name could not be taken for the branch. Everything from the first option on goes to the game's installer. With
# the pasted form, the words after the closing quote are a name for the script and then its arguments:
#   ... install.sh)" 1launcher-install 949230 release --check
# update is the one first word that is not a number; every other such word is "not a Steam app ID". It takes a
# ref and nothing else, no option among them. From a checkout it fetches nothing and says how a checkout is
# updated.
#   exit: the game installer's own code, or with update the driver's (0 = everything updated, 1 = something
#   failed, 3 = something was left as it is); 1 = the fetch failed, or what it brought is not this repository
#   or cannot update an install; 2 = no game named, a game with no installer, a wrong ref or word, an option
#   after update, or update from a checkout.
# The whole script is functions, the last of them called on its last line, so a download cut short runs
# nothing.
game_folder() {   # <table> <id>: the folder in that ID's row, if the row is whole and the folder a plain name
  awk -F'\t' -v id="$2" '$1 == id && NF == 4 && $2 ~ /^[a-z0-9][a-z0-9-]*$/ { print $2; exit }' "$1" 2>/dev/null
}
games_with_installer() {   # <table> <root>: the ID and title of every row whose folder holds an installer
  local i f t g
  echo "The games that have an installer:"
  while IFS=$'\t' read -r i f t g; do
    case "$i" in ''|*[!0-9]*) continue ;; esac
    printf '%s' "$f" | grep -Eq '^[a-z0-9][a-z0-9-]*$' || continue
    [ -f "$2/$f/scripts/install.sh" ] && echo "  $i  $t"
  done < "$1" 2>/dev/null
  return 0
}
main() {
  set -u
  local id="" ref=release words=0 self here="" table="" folder top url rc commit n e code update=0
  local front="https://github.com/macgameport/1launcher"
  local usage="usage: install.sh <Steam app ID> [<ref>] [options]"
  L1_TMP=""   # not local: the EXIT trap runs after this function has returned

  if [ "$(id -u)" = 0 ]; then
    echo "Do not run the installer as root (with sudo): it would leave files only root can change in your home folder."
    return 1
  fi
  while [ $# -gt 0 ]; do
    case "$1" in
      -*) break ;;
      *) words=$((words + 1))
         case "$words" in
           1) id="$1" ;;
           2) ref="$1" ;;
           *) echo "one word too many: $1 ($usage)"; return 2 ;;
         esac
         shift ;;
    esac
  done

  # A checkout: this file is a real file with the table of games beside it. Under bash -c (the pasted line,
  # the installer app) BASH_SOURCE is empty, so those always fetch, whatever folder Terminal is in.
  self="${BASH_SOURCE[0]:-}"
  if [ -n "$self" ] && [ -f "$self" ]; then
    here="$(cd "$(dirname "$self")" && pwd)"
    [ -f "$here/common/games.tsv" ] && table="$here/common/games.tsv"
  fi

  # The word update names no game (docs/plans/built-in-update.md, 3.4): it takes a ref and nothing else, and
  # a checkout is not updated by a fetch. It is asked for here, before the test of the first word, which would
  # call it "not a Steam app ID"; 0 is no game's ID and stands in its place only to pass that test.
  if [ "$id" = update ]; then
    if [ $# -gt 0 ]; then echo "update takes no option: $1 (usage: install.sh update [<ref>])"; return 2; fi
    if [ -n "$table" ]; then echo "This is a checkout: update it with git pull, then run each game's scripts/setup.sh."; return 2; fi
    update=1; id=0
  fi

  # No game named, or a word that is not an ID: nothing is fetched. A checkout has the table and lists its
  # games; the pasted line and the app have none yet, and name the page that lists them.
  case "$id" in
    ''|*[!0-9]*)
      if [ -n "$id" ]; then echo "not a Steam app ID: $id"; else echo "Say which game: the first word is its Steam app ID."; fi
      echo "$usage"
      if [ -n "$table" ]; then games_with_installer "$table" "$here"; else echo "The games and their IDs are listed at $front"; fi
      return 2 ;;
  esac
  case "$ref" in
    -*|/*|*..*|*//*) echo "not a branch, tag or commit of this repository: $ref"; return 2 ;;
  esac
  if ! printf '%s' "$ref" | grep -Eq '^[A-Za-z0-9._/-]+$'; then echo "not a branch, tag or commit of this repository: $ref"; return 2; fi

  if [ -n "$table" ]; then
    folder="$(game_folder "$table" "$id")"
    if [ -z "$folder" ] || [ ! -f "$here/$folder/scripts/install.sh" ]; then
      echo "This checkout has no installer for app $id."
      games_with_installer "$table" "$here"
      return 2
    fi
    echo "Using this checkout of 1launcher (nothing is fetched)."
    bash "$here/$folder/scripts/install.sh" "$@"
    return $?
  fi

  L1_TMP="$(mktemp -d "${TMPDIR:-/tmp}/1launcher-fetch.XXXXXX")" || { echo "A temporary folder could not be made."; return 1; }
  trap 'rm -rf "$L1_TMP"' EXIT
  local tmp="$L1_TMP"
  url="https://github.com/macgameport/1launcher/archive/$ref.tar.gz"
  # release by its full name, so that a tag named release could not be taken for the branch (both names
  # give the same commit: docs/plans/built-in-update.md, 1.5)
  [ "$ref" = release ] && url="https://github.com/macgameport/1launcher/archive/refs/heads/release.tar.gz"
  echo "Fetching 1launcher ($ref) from github.com/macgameport/1launcher ..."
  # The answer is judged by its code and never by which non-zero exit curl gave: for a 404 curl 8.7.1 exits
  # 56 over HTTP/2 and 22 over HTTP/1.1. So no -f; the code comes on standard output, the archive in the file.
  code="$(curl --proto '=https' --tlsv1.2 -sSL --retry 2 -o "$tmp/repo.tar.gz" -w '%{http_code}' "$url")"; rc=$?
  if [ "$code" = 404 ]; then
    echo "GitHub has no \"$ref\" of 1launcher. The current way in is at:"
    echo "  $front"
    return 1
  elif [ "$rc" != 0 ] || [ "$code" != 200 ]; then
    echo "GitHub could not be reached (curl exit $rc, answer ${code:-none}). Check the network, then try again."
    return 1
  fi
  commit="$(gzip -dc "$tmp/repo.tar.gz" 2>/dev/null | head -c 1024 | LC_ALL=C grep -a -o 'comment=[0-9a-f]\{40\}' | head -n 1)"
  mkdir "$tmp/x"
  if ! tar -xzf "$tmp/repo.tar.gz" -C "$tmp/x" 2>/dev/null; then echo "What GitHub sent could not be unpacked."; return 1; fi
  n=0; top=""
  for e in "$tmp/x"/* "$tmp/x"/.[!.]*; do
    [ -e "$e" ] || [ -L "$e" ] || continue
    n=$((n + 1)); top="$e"
  done
  if [ "$n" != 1 ] || [ -L "$top" ] || [ ! -d "$top" ]; then echo "What GitHub sent is not one folder of this repository."; return 1; fi
  if [ "$update" = 1 ]; then   # the update: the driver that came with the fetch, so it is always the newest
    if [ ! -f "$top/common/update-games.sh" ]; then
      echo "This version of 1launcher cannot update an install. Paste the installer line from the guide instead."
      return 1
    fi
    if [ -n "$commit" ]; then echo "1launcher at commit ${commit#comment=}"; else echo "1launcher: commit not read"; fi
    export L1_FETCHED_REF="$ref"
    if [ -n "$commit" ]; then export L1_FETCHED_COMMIT="${commit#comment=}"; else unset L1_FETCHED_COMMIT; fi
    bash "$top/common/update-games.sh"
    return $?
  fi
  folder="$(game_folder "$top/common/games.tsv" "$id")"
  if [ -z "$folder" ] || [ ! -f "$top/$folder/scripts/install.sh" ]; then
    echo "There is no installer for app $id."
    games_with_installer "$top/common/games.tsv" "$top"
    return 2
  fi
  if [ -n "$commit" ]; then echo "1launcher at commit ${commit#comment=}"; else echo "1launcher: commit not read"; fi
  export L1_FETCHED_REF="$ref"
  if [ -n "$commit" ]; then export L1_FETCHED_COMMIT="${commit#comment=}"; else unset L1_FETCHED_COMMIT; fi
  bash "$top/$folder/scripts/install.sh" "$@"
  return $?
}
main "$@"
