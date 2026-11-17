#!/bin/bash
# check-release-move.sh <commit> -- the gate before every `git push origin <commit>:release`
# (docs/plans/local-files-layout.md, LT21). Run from the checkout whose `origin` is the published repo.
# It fetches `main`, `release` and the tags from `origin`, then asks three things of <commit>:
#   1. `origin/release` is an ancestor of it: the move is a fast-forward;
#   2. it is on `origin/main`: what players get is what `main` already holds;
#   3. if it holds `common/paths.sh` (the code that moves install folders), the tag `v0.2.0` exists and
#      names it or an ancestor of it: the move reaches players only after the release that announces it.
# It prints one line per question and moves nothing. It never reads or names an `installer-*` tag.
#   exit 0 = all three hold; 1 = one or more do not (each named), or the fetch failed; 64 = usage
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
if git cat-file -e "$C:common/paths.sh" 2>/dev/null; then
  T="$(git rev-parse --verify -q 'v0.2.0^{commit}')"
  if [ -z "$T" ]; then echo "FAIL  ${C:0:7} holds common/paths.sh and the tag v0.2.0 does not exist"; bad=1
  elif git merge-base --is-ancestor "$T" "$C"; then echo "ok    ${C:0:7} holds common/paths.sh and v0.2.0 (${T:0:7}) is it or an ancestor"
  else echo "FAIL  ${C:0:7} holds common/paths.sh and v0.2.0 (${T:0:7}) is not it or an ancestor of it"; bad=1; fi
else echo "ok    ${C:0:7} does not hold common/paths.sh"; fi
exit "$bad"
