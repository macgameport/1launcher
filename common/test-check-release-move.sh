#!/bin/bash
# test-check-release-move.sh -- runs common/check-release-move.sh (LT21) in a scratch repo whose `origin` is a
# scratch bare repo, never the published one. Nothing outside the scratch folder is read or written: the gate
# and common/updates.sh, whose version rule its fifth question reads, are copied into it, and HOME and TMPDIR
# are folders in it.
#   bash common/test-check-release-move.sh     exit 0 = every case passed
#   MUTANT=1 ...    the tag test is dropped; must exit 1
#   MUTANT=2 ...    the main test is dropped; must exit 1
#   MUTANT=3 ...    the fourth question's tag changed to v0.2.0 (WT13, docs/plans/wrapper-names.md); must exit 1
# The fifth question (UT10, docs/plans/built-in-update.md, 3.7); each must exit 1:
#   MUTANT=4 ...    "a v tag names the commit" is dropped
#   MUTANT=5 ...    "the changelog's first version heading is that tag's name" is dropped
#   MUTANT=6 ...    "that version is newer than origin/release's" is dropped
#   MUTANT=7 ...    "origin has no tag named release" is dropped
#   MUTANT=8 ...    a tag is compared by its object, not by the commit it names
#   MUTANT=9 ...    the question is asked only when the commit holds common/updates.sh, not when release does
#   MUTANT=10 ...   with no common/updates.sh beside the gate, the question passes
#   MUTANT=11 ...   the gate does not remove its temporary file (not in the plan's table)
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/check-release-move.sh" ] || { echo "REFUSED: check-release-move.sh not found"; exit 2; }
[ -f "$HERE/updates.sh" ] || { echo "REFUSED: updates.sh not found"; exit 2; }
T="$(mktemp -d /tmp/check-release-move-test.XXXX)"
trap 'rm -rf "$T"' EXIT
cp "$HERE/check-release-move.sh" "$T/gate.sh"
cp "$HERE/updates.sh" "$T/updates.sh"
drop() {   # <fixed text>: delete the one line of the copy that holds it
  [ "$(grep -cF -- "$1" "$T/gate.sh")" = 1 ] || { echo "REFUSED: mutant did not apply"; exit 2; }
  grep -vF -- "$1" "$T/gate.sh" > "$T/gate.new" && mv "$T/gate.new" "$T/gate.sh"
}
case "${MUTANT:-0}" in
  0) ;;
  1) drop '    if [ -z "$T" ]; then'
     sed -i '' 's/^    elif git merge-base --is-ancestor "\$T" "\$C"; then/    if [ -z "$T" ] || git merge-base --is-ancestor "$T" "$C"; then/' "$T/gate.sh" ;;
  2) drop 'if git merge-base --is-ancestor "$C" origin/main; then'
     drop 'else echo "FAIL  ${C:0:7} is not on origin/main"; bad=1; fi' ;;
  3) sed -i '' 's/^released common\/wrappers.sh v0.3.0$/released common\/wrappers.sh v0.2.0/' "$T/gate.sh"; grep -q 'wrappers.sh v0.2.0' "$T/gate.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  4) drop '  [ -n "$tags" ] || { echo "FAIL  no v tag names' ;;
  5) drop '  [ -z "$tags" ] || [ "$named" = 1 ] || { echo "FAIL' ;;
  6) drop '  [ -z "$H" ] || l1u_newer "$H" "$R" || { echo "FAIL' ;;
  7) drop '  [ -z "$remote" ] || { echo "FAIL  origin has a tag named release' ;;
  8) sed -i '' 's|git rev-parse --verify -q "refs/tags/\$t^{commit}"|git rev-parse --verify -q "refs/tags/$t"|' "$T/gate.sh"
     grep -qF 'git rev-parse --verify -q "refs/tags/$t")" = "$C"' "$T/gate.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  9) drop '  git cat-file -e "origin/release:common/updates.sh" 2>/dev/null && asked=1' ;;
  10) sed -i '' 's|{ echo "FAIL  the version rule (common/updates.sh) is not in this checkout"; bad=1; return; }|{ echo "ok    the version rule (common/updates.sh) is not in this checkout"; return; }|' "$T/gate.sh"
     grep -qF 'echo "ok    the version rule' "$T/gate.sh" || { echo "REFUSED: mutant did not apply"; exit 2; } ;;
  11) drop "  trap 'rm -f \"\$LOG\"' EXIT" ;;
  *) echo "REFUSED: no mutant $MUTANT"; exit 2 ;;
esac
mkdir -p "$T/home" "$T/tmp" "$T/alone/common"
cp "$T/gate.sh" "$T/alone/common/check-release-move.sh"   # the gate alone: no updates.sh beside it
export HOME="$T/home" TMPDIR="$T/tmp" L1_UPDATE_DIR="$T/home/_update"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q --bare "$T/origin.git"
git init -q -b main "$T/w"
cd "$T/w" || exit 2
git remote add origin "$T/origin.git"
commit() { mkdir -p "$(dirname "$1")"; echo "$2" > "$1"; git add "$1"; git commit -q -m "$2"; git rev-parse HEAD; }
A="$(commit README.md a)"
git push -q origin main && git push -q origin main:release
B="$(commit README.md b)"                 # documents only, on main
C="$(commit common/paths.sh paths)"       # holds the file, no tag yet
git push -q origin main
git checkout -q -b side "$A"
S="$(commit side.txt s)"                  # on no main
git checkout -q main
fails=0
expect() {   # <want rc> <commit> <name> [<text the output must hold>]; GATE names another copy of the gate
  out="$(bash "${GATE:-$T/gate.sh}" "$2" 2>&1)"; rc=$?
  if [ "$rc" = "$1" ] && { [ -z "${4:-}" ] || printf '%s' "$out" | grep -qF -- "$4"; }; then echo "PASS  $3"
  else echo "FAIL  $3 (rc $rc, want $1)"; printf '%s\n' "$out" | sed 's/^/        /'; fails=$((fails + 1)); fi
}
expect 0 "$B" "a commit of main without common/paths.sh"
expect 1 "$C" "common/paths.sh with no tag" "v0.2.0 does not exist"
expect 1 "$S" "a commit on no main" "is not on origin/main"
git tag -a v0.2.0 -m v0.2.0 "$C" && git push -q origin v0.2.0
expect 0 "$C" "the commit v0.2.0 names"
D="$(commit README.md d)"; git push -q origin main
expect 0 "$D" "a later commit of main"
git tag -d v0.2.0 >/dev/null && git push -q origin :refs/tags/v0.2.0
git tag -a v0.2.0 -m v0.2.0 "$D" && git push -q origin v0.2.0
expect 1 "$C" "v0.2.0 names a later commit" "is not it or an ancestor"
# WT13: a commit that holds common/wrappers.sh moves only with v0.3.0 as it or an ancestor
W="$(commit common/wrappers.sh wrappers)"; git push -q origin main
expect 1 "$W" "WT13 common/wrappers.sh with no v0.3.0" "v0.3.0 does not exist"
git tag -a v0.3.0 -m v0.3.0 "$W" && git push -q origin v0.3.0
expect 0 "$W" "WT13 the commit v0.3.0 names, v0.2.0 an ancestor"
# UT10 (docs/plans/built-in-update.md, 3.7): with common/updates.sh on the commit or on origin/release, the
# commit must be a tagged release: a v tag names it, its changelog's first version heading is that tag's name
# and newer than origin/release's, and origin has no tag named release
ALONE="$T/alone/common/check-release-move.sh"
changelog() {   # <version>...: CHANGELOG.md with a section for each, staged for the next commit
  { echo "# Changelog"; echo; echo "## Unreleased"; for v in "$@"; do echo; echo "## $v (2026-11-24)"; echo; echo "- a change"; done; } > CHANGELOG.md
  git add CHANGELOG.md
}
expect 0 "$W" "UT10 no common/updates.sh on the commit or on release: not asked" "nor origin/release holds common/updates.sh"
GATE="$ALONE" expect 0 "$W" "UT10 not asked: the gate alone, with no common/updates.sh beside it, still passes" "nor origin/release holds common/updates.sh"
changelog v0.4.1 v0.3.0
U="$(commit common/updates.sh updates)"; git push -q origin main
expect 1 "$U" "UT10 common/updates.sh on an untagged commit" "no v tag names ${U:0:7}"
git tag -a installer-1 -m installer-1 "$U" && git push -q origin installer-1
expect 1 "$U" "UT10 an installer-1 tag alone" "no v tag names ${U:0:7}"
git tag -a v0.4.0 -m v0.4.0 "$U" && git push -q origin v0.4.0
expect 1 "$U" "UT10 tagged v0.4.0 with the heading v0.4.1" "is tagged v0.4.0 and the first version heading of its CHANGELOG.md is v0.4.1"
git tag -d v0.4.0 >/dev/null && git push -q origin :refs/tags/v0.4.0
git tag -a v0.4.1 -m v0.4.1 "$U" && git push -q origin v0.4.1
expect 0 "$U" "UT10 tagged v0.4.1, heading v0.4.1; release has no changelog, which counts as -" "is the tagged release v0.4.1, newer than origin/release's (-)"
git push -q origin "$A:refs/tags/release"
expect 1 "$U" "UT10 a tag named release on the remote" "origin has a tag named release"
git push -q origin :refs/tags/release
git push -q origin "$U:release"     # release now holds common/updates.sh and a changelog at v0.4.1
expect 1 "$U" "UT10 tagged, heading equal, not newer than release's" "v0.4.1, the first version heading of ${U:0:7}'s CHANGELOG.md, is not newer than origin/release's (v0.4.1)"
changelog v0.4.2 v0.4.1 v0.3.0
V="$(commit README.md v)"; git push -q origin main
git tag -a v0.4.2 -m v0.4.2 "$V" && git push -q origin v0.4.2
expect 0 "$V" "UT10 all right: tagged v0.4.2, heading v0.4.2, release at v0.4.1" "is the tagged release v0.4.2, newer than origin/release's (v0.4.1)"
GATE="$ALONE" expect 1 "$V" "UT10 the gate alone in a scratch common/, on a release that holds the file" "FAIL  the version rule (common/updates.sh) is not in this checkout"
git rm -q common/updates.sh
G="$(commit README.md g)"; git push -q origin main   # the file removed; release still holds it
if git cat-file -e "$G:common/updates.sh" 2>/dev/null; then echo "REFUSED: the fixture's last commit still holds common/updates.sh"; exit 2; fi
expect 1 "$G" "UT10 a commit without the file on a release that has it is asked" "no v tag names ${G:0:7}"
if [ -z "$(ls -A "$T/tmp")" ]; then echo "PASS  UT10 the gate left no file in the temporary folder"
else echo "FAIL  UT10 the gate left a file in the temporary folder"; ls -A "$T/tmp" | sed 's/^/        /'; fails=$((fails + 1)); fi
git push -q -f origin "$S:release"
expect 1 "$D" "release is not an ancestor" "would not be a fast-forward"
bash "$T/gate.sh" >/dev/null 2>&1; rc=$?
if [ "$rc" = 64 ]; then echo "PASS  no commit given"; else echo "FAIL  no commit given (rc $rc, want 64)"; fails=$((fails + 1)); fi
echo
echo "$fails failure(s)"
[ "$fails" = 0 ]
