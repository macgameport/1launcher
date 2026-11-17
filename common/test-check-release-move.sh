#!/bin/bash
# test-check-release-move.sh -- runs common/check-release-move.sh (LT21) in a scratch repo whose `origin` is a
# scratch bare repo, never the published one. Nothing outside the scratch folder is read or written.
#   bash common/test-check-release-move.sh     exit 0 = every case passed
#   MUTANT=1 ...    the tag test is dropped; must exit 1
#   MUTANT=2 ...    the main test is dropped; must exit 1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/check-release-move.sh" ] || { echo "REFUSED: check-release-move.sh not found"; exit 2; }
T="$(mktemp -d /tmp/check-release-move-test.XXXX)"
trap 'rm -rf "$T"' EXIT
cp "$HERE/check-release-move.sh" "$T/gate.sh"
drop() {   # <fixed text>: delete the one line of the copy that holds it
  [ "$(grep -cF -- "$1" "$T/gate.sh")" = 1 ] || { echo "REFUSED: mutant did not apply"; exit 2; }
  grep -vF -- "$1" "$T/gate.sh" > "$T/gate.new" && mv "$T/gate.new" "$T/gate.sh"
}
case "${MUTANT:-0}" in
  0) ;;
  1) drop 'if [ -z "$T" ]; then'
     sed -i '' 's/^  elif git merge-base --is-ancestor "\$T" "\$C"; then/  if [ -z "$T" ] || git merge-base --is-ancestor "$T" "$C"; then/' "$T/gate.sh" ;;
  2) drop 'if git merge-base --is-ancestor "$C" origin/main; then'
     drop 'else echo "FAIL  ${C:0:7} is not on origin/main"; bad=1; fi' ;;
  *) echo "REFUSED: no mutant $MUTANT"; exit 2 ;;
esac
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
expect() {   # <want rc> <commit> <name> [<text the output must hold>]
  out="$(bash "$T/gate.sh" "$2" 2>&1)"; rc=$?
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
git push -q -f origin "$S:release"
expect 1 "$D" "release is not an ancestor" "would not be a fast-forward"
bash "$T/gate.sh" >/dev/null 2>&1; rc=$?
if [ "$rc" = 64 ]; then echo "PASS  no commit given"; else echo "FAIL  no commit given (rc $rc, want 64)"; fails=$((fails + 1)); fi
echo
echo "$fails failure(s)"
[ "$fails" = 0 ]
