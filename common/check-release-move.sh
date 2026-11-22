#!/bin/bash
# check-release-move.sh <commit> -- the gate before every `git push origin <commit>:release`
# (docs/plans/local-files-layout.md, LT21). Run from the checkout whose `origin` is the published repo.
# It fetches `main`, `release` and the tags from `origin`, then asks four things of <commit>:
#   1. `origin/release` is an ancestor of it: the move is a fast-forward;
#   2. it is on `origin/main`: what players get is what `main` already holds;
#   3. if it holds `common/paths.sh` (the code that moves install folders), the tag `v0.2.0` exists and
#      names it or an ancestor of it: the move reaches players only after the release that announces it;
#   4. if it holds `common/wrappers.sh` (the code that renames the Wine wrappers, docs/plans/wrapper-names.md),
#      the tag `v0.3.0` exists and names it or an ancestor of it, for the same reason. The gate cannot hold the
#      order of the two moves: `v0.3.0` is past `v0.2.0`, so a move to it takes the folder move too, and the
#      third question then passes by itself. That order is James's word, not the gate's (that plan, 3.8).
# It prints one line per question and moves nothing. It never reads or names an `installer-*` tag.
#   exit 0 = all four hold; 1 = one or more do not (each named), or the fetch failed; 64 = usage
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
exit "$bad"
