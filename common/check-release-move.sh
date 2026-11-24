#!/bin/bash
# check-release-move.sh <commit> -- the gate before every `git push origin <commit>:release`
# (docs/plans/local-files-layout.md, LT21). Run from the checkout whose `origin` is the published repo.
# It fetches `main`, `release` and the tags from `origin`, then asks five things of <commit>:
#   1. `origin/release` is an ancestor of it: the move is a fast-forward;
#   2. it is on `origin/main`: what players get is what `main` already holds;
#   3. if it holds `common/paths.sh` (the code that moves install folders), the tag `v0.2.0` exists and
#      names it or an ancestor of it: the move reaches players only after the release that announces it;
#   4. if it holds `common/wrappers.sh` (the code that renames the Wine wrappers, docs/plans/wrapper-names.md),
#      the tag `v0.3.0` exists and names it or an ancestor of it, for the same reason. The gate cannot hold the
#      order of the two moves: `v0.3.0` is past `v0.2.0`, so a move to it takes the folder move too, and the
#      third question then passes by itself. That order is James's word, not the gate's (that plan, 3.8).
#   5. if it holds `common/updates.sh` (the code by which an installed Mac learns of a newer version,
#      docs/plans/built-in-update.md, 3.7), or `origin/release` already does (so that a commit that removes
#      the file cannot switch the question off), it is a tagged release: a `v` tag's commit (the commit the
#      tag names, not the tag object) is it; the first version heading of its `CHANGELOG.md` is that tag's
#      name; that version is newer than the first version heading of `origin/release:CHANGELOG.md` (no file
#      or no heading there counts as `-`, lower than every version); and `origin` has no tag named `release`.
#      An installed Mac learns of an update only by a version heading that rises: a move to a commit between
#      two releases would reach new installs and no installed Mac. What a version is and which of two is
#      newer is the rule of `common/updates.sh` beside this file, read with `.`; when the question is asked
#      and that file is not there, the question fails.
# It prints one line per question (for the fifth, when it does not hold, one line for each part that does
# not) and moves nothing. It never reads or names an `installer-*` tag. For the fifth question it writes one
# file in the temporary folder, a copy of a `CHANGELOG.md` to read its heading from, and removes it.
#   exit 0 = all five hold; 1 = one or more do not (each named), or the fetch failed; 64 = usage
set -u
[ $# = 1 ] || { echo "usage: check-release-move.sh <commit>"; exit 64; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not inside a git checkout"; exit 64; }
git fetch -q origin main release 2>/dev/null && git fetch -q origin 'refs/tags/v*:refs/tags/v*' 2>/dev/null \
  || { echo "FAIL: could not fetch main, release and the v tags from origin"; exit 1; }
C="$(git rev-parse --verify -q "$1^{commit}")" || { echo "FAIL: $1 is not a commit"; exit 1; }
bad=0
if git merge-base --is-ancestor origin/release "$C"; then echo "ok    origin/release is an ancestor of ${C:0:7}"
else echo "FAIL  origin/release is not an ancestor of ${C:0:7}: the push would not be a fast-forward"; bad=1; fi
if git merge-base --is-ancestor "$C" origin/main; then echo "ok    ${C:0:7} is on origin/main"
else echo "FAIL  ${C:0:7} is not on origin/main"; bad=1; fi
released() {   # <file> <tag>: a commit that holds the file moves only when the tag is it or an ancestor
  local T
  if git cat-file -e "$C:$1" 2>/dev/null; then
    T="$(git rev-parse --verify -q "$2^{commit}")"
    if [ -z "$T" ]; then echo "FAIL  ${C:0:7} holds $1 and the tag $2 does not exist"; bad=1
    elif git merge-base --is-ancestor "$T" "$C"; then echo "ok    ${C:0:7} holds $1 and $2 (${T:0:7}) is it or an ancestor"
    else echo "FAIL  ${C:0:7} holds $1 and $2 (${T:0:7}) is not it or an ancestor of it"; bad=1; fi
  else echo "ok    ${C:0:7} does not hold $1"; fi
}
released common/paths.sh v0.2.0
released common/wrappers.sh v0.3.0
heading() {   # <revision>: the first version heading of its CHANGELOG.md, or nothing
  git cat-file -e "$1:CHANGELOG.md" 2>/dev/null && git show "$1:CHANGELOG.md" > "$LOG" 2>/dev/null || return 0
  l1u_version_of "$LOG"
}
tagged() {   # the fifth question: from common/updates.sh on, release moves only to the commit of a tagged release
  local HERE t tags="" named=0 H R remote ok=1 asked=0
  git cat-file -e "$C:common/updates.sh" 2>/dev/null && asked=1
  git cat-file -e "origin/release:common/updates.sh" 2>/dev/null && asked=1
  [ "$asked" = 1 ] || { echo "ok    neither ${C:0:7} nor origin/release holds common/updates.sh"; return; }
  HERE="$(cd "$(dirname "$0")" && pwd)"
  [ -f "$HERE/updates.sh" ] || { echo "FAIL  the version rule (common/updates.sh) is not in this checkout"; bad=1; return; }
  . "$HERE/updates.sh"
  LOG="$(mktemp "${TMPDIR:-/tmp}/check-release-move.XXXXXX")" || { echo "FAIL  could not make a temporary file"; bad=1; return; }
  trap 'rm -f "$LOG"' EXIT
  for t in $(git for-each-ref --format='%(refname:strip=2)' 'refs/tags/v*'); do
    [ "$(git rev-parse --verify -q "refs/tags/$t^{commit}")" = "$C" ] && tags="$tags${tags:+ }$t"
  done
  H="$(heading "$C")"
  R="$(heading origin/release)"; [ -n "$R" ] || R=-
  for t in $tags; do [ "$t" = "$H" ] && named=1; done
  [ -n "$tags" ] || { echo "FAIL  no v tag names ${C:0:7}: from common/updates.sh on, release moves only to the commit of a tagged release"; ok=0; }
  [ -z "$tags" ] || [ "$named" = 1 ] || { echo "FAIL  ${C:0:7} is tagged $tags and the first version heading of its CHANGELOG.md is ${H:-missing}"; ok=0; }
  [ -z "$H" ] || l1u_newer "$H" "$R" || { echo "FAIL  $H, the first version heading of ${C:0:7}'s CHANGELOG.md, is not newer than origin/release's ($R): no installed Mac would learn of it"; ok=0; }
  remote="$(git ls-remote --tags origin release 2>/dev/null)" || { echo "FAIL  could not ask origin whether it has a tag named release"; ok=0; }
  [ -z "$remote" ] || { echo "FAIL  origin has a tag named release: the name must mean the branch alone"; ok=0; }
  if [ "$ok" = 1 ]; then echo "ok    ${C:0:7} is the tagged release $H, newer than origin/release's ($R), and origin has no tag named release"
  else bad=1; fi
}
tagged
exit "$bad"
