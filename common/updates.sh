#!/bin/bash
# updates.sh: the one place that holds the rule for which version of 1launcher this Mac's games were set up
# from, and which version is on offer (docs/plans/built-in-update.md, 3.1 and 3.2). Everything it keeps is in
# one folder, L1_UPDATE_DIR (common/paths.sh: <data root>/_update):
#   installed/<Steam app ID>   the stamp: the line the game follows, the version, the commit, the time
#   launcher                   14unch3r's own stamp, in the same form (docs/plans/launcher-first-install.md, 3.5)
#   offer                      the version `release` held at the last fetch that worked, and its time
#   tried                      the time of the last attempt to fetch, whether it worked or not
#   notes.md                   CHANGELOG.md as last fetched
#   noted                      the version the launchers last announced, and how often (1 or 2)
#   off                        if it exists, nothing is ever fetched (made by hand)
#   installing                 the lock of a running install (docs/plans/launcher-first-install.md, 3.8): a link
#                              whose target is the installer's process number, as `updating` is the update's
#   installing-game            beside it, one line: the Steam app ID of the game being installed
#
#   . updates.sh             defines the l1u_* functions (exports nothing; safe under set -eu, and to source
#                            twice). The caller sets L1_UPDATE_DIR first (setup does, after paths.sh).
#   bash updates.sh                    the state line: <word> TAB <installed> TAB <offered> TAB <detail>
#   bash updates.sh --refresh [--now]  the state line with a fifth field: fetched, failed or skipped
#   bash updates.sh --notes            the fetched notes of every version newer than the installed one, cleaned
#   bash updates.sh --noted            the offered version, at most twice for one version (for a launcher)
#   bash updates.sh --open             opened, after it wrote the update's file and handed it to Terminal; or
#                                      failed TAB <one sentence>. It refuses unless the state is ready
#   bash updates.sh --version-of <f>   that file's version, or nothing
# Sourced, the functions a caller uses: l1u_own, l1u_stamp <app ID> <tree root>, l1u_stamp_of <app ID>,
# l1u_stamp_launcher <tree root>, l1u_stamp_of_launcher,
# l1u_state, l1u_version_of <file>, l1u_newer <x> <y>, l1u_refresh [--now], l1u_notes, l1u_noted, l1u_open,
# and the one rule for the two locks: l1u_lock_live <name>, l1u_lock_take <name>, l1u_lock_release <name>,
# for the names installing and updating.
# Run, it uses L1_UPDATE_DIR if set and otherwise the folder it lies in, which for the deployed copy is the
# folder itself. Every call exits 0 when it could answer and says the outcome in its output. The options and
# the output lines are a contract between versions on one Mac: a later version may add an option or a field
# at the end of a line, and never changes or removes one.
#
# The words of the state line, in this order: off (the file `off` exists) | none (no stamp) | manual (a stamp
# follows a line that is not `release`; <detail> is that line) | unknown (no offer yet) | ready (the offer is
# newer than the lowest installed version) | current. A field with no value is `-`. 14unch3r's stamp counts as a
# game's does: a Mac with the launcher alone has a state, and the lowest version among it and the games is the
# installed one.
#
# Every value read from the folder is matched whole before it is used, and nothing in it is ever read with
# `.` or eval: under bash 3.2 a value such as a[$(cmd)] in an arithmetic place runs cmd. A file that is a
# link, is not a regular file, is over 4,096 bytes or fails its match counts as absent.
# The update's file (--open; plan 3.4) is "Update 1launcher.command" in a new temporary folder. It holds
# constants only, but for curl's path; it fetches the root install.sh of `release` into a file beside itself,
# runs it with the one word update, says in one line what happened, and removes itself and its folder.
# Test variables: L1_UPDATE_DIR; L1_UPDATE_NOW, an epoch that stands for now; L1_CURL (default /usr/bin/curl)
# and L1_OPEN (default /usr/bin/open), the two programs a test replaces. L1_CURL is written into the update's
# file only when it is a plain absolute path, and /usr/bin/curl otherwise. L1_SYSCTL (default /usr/sbin/sysctl)
# is the program asked for the Mac's last start, for a lock's rule.
# Every function that runs a program sets PATH itself: a launcher calls this with Wine's bin first on PATH.

_L1U_VER='^v(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})$'
_L1U_HEAD='^## (v(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})\.(0|[1-9][0-9]{0,5})) \('
_L1U_TIME='^[0-9]{1,12}$'
_L1U_LINE='^[A-Za-z0-9._/-]{1,100}$'
_L1U_COMMIT='^[0-9a-f]{40}$'
_L1U_ID='^[1-9][0-9]{0,9}$'
_L1U_SIZE='^[0-9]{1,15}$'
_L1U_URL='https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/CHANGELOG.md'
_L1U_MORE='More: https://github.com/macgameport/1launcher/blob/release/CHANGELOG.md'
_L1U_PROG='^/[A-Za-z0-9._/-]{1,200}$'

_l1u_is_version() { [ "$1" = - ] || [[ "$1" =~ $_L1U_VER ]]; }

# <file> <fields>: 0 when the file is one line of exactly that many non-empty tab-separated fields; they are
# left in _l1u_a to _l1u_d. Read on one descriptor: the first line, then a second read that must find nothing.
_l1u_read() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$1" n="$2" size rest="" more="" r2=0
  _l1u_a=""; _l1u_b=""; _l1u_c=""; _l1u_d=""
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  size="$(stat -f %z "$f" 2>/dev/null)" || return 1
  [[ "$size" =~ $_L1U_SIZE ]] || return 1
  [ "$size" -le 4096 ] || return 1
  { IFS=$'\t' read -r _l1u_a _l1u_b _l1u_c _l1u_d rest || true; IFS= read -r more || r2=1; } < "$f" 2>/dev/null || return 1
  [ "$r2" = 1 ] && [ -z "$more" ] && [ -z "$rest" ] || return 1
  case "$n" in
    1) [ -n "$_l1u_a" ] && [ -z "$_l1u_b$_l1u_c$_l1u_d" ] ;;
    2) [ -n "$_l1u_a" ] && [ -n "$_l1u_b" ] && [ -z "$_l1u_c$_l1u_d" ] ;;
    4) [ -n "$_l1u_a" ] && [ -n "$_l1u_b" ] && [ -n "$_l1u_c" ] && [ -n "$_l1u_d" ] ;;
    *) return 1 ;;
  esac
}

# now, as epoch seconds: L1_UPDATE_NOW when it is a time, else the clock
_l1u_now() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin
  if [[ "${L1_UPDATE_NOW:-}" =~ $_L1U_TIME ]]; then printf '%s\n' "$((10#$L1_UPDATE_NOW))"; else date +%s; fi
}

# <folder>: 0 when it is a real folder of this user's that group and others cannot write to
_l1u_own1() {
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -f %u "$1" 2>/dev/null)" = "$(id -u)" ] || return 1
  case "$(stat -f %Lp "$1" 2>/dev/null)" in ''|*[2367]?|*[2367]) return 1 ;; esac
  return 0
}
l1u_own() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin
  _l1u_own1 "$L1_UPDATE_DIR" && _l1u_own1 "$L1_UPDATE_DIR/installed"
}

# <file>: its version, the first heading "## v<a>.<b>.<c> (" in its first 1 MiB; returns 1 when there is none
l1u_version_of() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin line
  [ -f "$1" ] || return 1
  head -c 1048576 "$1" 2>/dev/null | {
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"
      if [[ "$line" =~ $_L1U_HEAD ]]; then printf '%s\n' "${BASH_REMATCH[1]}"; exit 0; fi
    done
    exit 1
  }
}

# <x> <y>: 0 when x is a later version than y, the three numbers compared as numbers; `-` is lower than
# every version. Returns 1 unless both are a version or `-`.
l1u_newer() {
  local x="$1" y="$2" a b i
  _l1u_is_version "$x" && _l1u_is_version "$y" || return 1
  [ "$x" = - ] && return 1
  [ "$y" = - ] && return 0
  x="${x#v}"; y="${y#v}"
  for i in 1 2 3; do
    a="${x%%.*}"; b="${y%%.*}"; x="${x#*.}"; y="${y#*.}"
    [ "$((10#$a))" -gt "$((10#$b))" ] && return 0
    [ "$((10#$a))" -lt "$((10#$b))" ] && return 1
  done
  return 1
}

# <file> <content>: written beside its place and renamed over it; returns 1 when it could not
_l1u_put() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin t
  t="$(mktemp "$(dirname "$1")/.put.XXXXXX" 2>/dev/null)" || return 1
  if printf '%s\n' "$2" > "$t" 2>/dev/null && mv -f "$t" "$1" 2>/dev/null; then return 0; fi
  rm -f "$t" 2>/dev/null; return 1
}

# <file> <tree root>: writes a stamp to that file: the line (L1_FETCHED_REF, or `checkout` when the tree was
# not fetched), the tree's version, the commit (L1_FETCHED_COMMIT) and the time. Returns 1 when it could not.
_l1u_stamp_to() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$1" tree="$2" line=checkout ver commit=- now
  l1u_own || return 1
  if [ -n "${L1_FETCHED_REF:-}" ]; then
    [[ "$L1_FETCHED_REF" =~ $_L1U_LINE ]] || return 1
    line="$L1_FETCHED_REF"
  fi
  ver="$(l1u_version_of "$tree/CHANGELOG.md")" || ver=-
  _l1u_is_version "$ver" || ver=-
  # the commit belongs to a fetch: one left in the environment says nothing about a checkout
  [ "$line" != checkout ] && [[ "${L1_FETCHED_COMMIT:-}" =~ $_L1U_COMMIT ]] && commit="$L1_FETCHED_COMMIT"
  now="$(_l1u_now)"; [[ "$now" =~ $_L1U_TIME ]] || return 1
  _l1u_put "$f" "$line"$'\t'"$ver"$'\t'"$commit"$'\t'"$now"
}
# <app ID> <tree root>: writes that game's stamp, installed/<app ID>. Returns 1 when it could not.
l1u_stamp() {
  [[ "$1" =~ $_L1U_ID ]] || return 1
  _l1u_stamp_to "$L1_UPDATE_DIR/installed/$1" "$2"
}
# <tree root>: writes 14unch3r's own stamp, the file `launcher` (docs/plans/launcher-first-install.md, 3.5): for
# whoever has just built the window from that tree, and only after a build that worked. Returns 1 when it could not.
l1u_stamp_launcher() { _l1u_stamp_to "$L1_UPDATE_DIR/launcher" "$1"; }

# <file>: 0 when it is a stamp that counts: one line of four fields, each matched whole. Its line and its version
# are left in _l1u_a and _l1u_b.
_l1u_stamp_ok() {
  _l1u_read "$1" 4 || return 1
  [[ "$_l1u_a" =~ $_L1U_LINE ]] && _l1u_is_version "$_l1u_b" || return 1
  [ "$_l1u_c" = - ] || [[ "$_l1u_c" =~ $_L1U_COMMIT ]] || return 1
  [[ "$_l1u_d" =~ $_L1U_TIME ]]
}

# The stamps that count, one per line in the order of the app IDs as numbers: <id> TAB <line> TAB <version>.
# In installed/, a name that is not an app ID, a link, a folder and a file that fails its match are passed over.
# After the games, 14unch3r's own stamp when it counts: a row whose first field is the word `launcher` where a
# game's row has its app ID.
_l1u_stamps() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f id
  for f in "$L1_UPDATE_DIR/installed"/*; do
    id="${f##*/}"
    [[ "$id" =~ $_L1U_ID ]] || continue
    _l1u_stamp_ok "$f" || continue
    printf '%s\t%s\t%s\n' "$id" "$_l1u_a" "$_l1u_b"
  done | sort -n
  if _l1u_stamp_ok "$L1_UPDATE_DIR/launcher"; then printf 'launcher\t%s\t%s\n' "$_l1u_a" "$_l1u_b"; fi
}

# <app ID>: prints "<line> TAB <version>" of that game's stamp and returns 0; returns 1 when it has no stamp
# that counts. (For the setups' closing words and for the update's driver.)
l1u_stamp_of() {
  local id line ver
  [[ "$1" =~ $_L1U_ID ]] || return 1
  while IFS=$'\t' read -r id line ver; do
    if [ "$id" = "$1" ]; then printf '%s\t%s\n' "$line" "$ver"; return 0; fi
  done <<EOF
$(_l1u_stamps)
EOF
  return 1
}

# prints "<line> TAB <version>" of 14unch3r's own stamp and returns 0; returns 1 when it has no stamp that counts.
# (l1u_stamp_of takes an app ID and nothing else.)
l1u_stamp_of_launcher() {
  _l1u_stamp_ok "$L1_UPDATE_DIR/launcher" || return 1
  printf '%s\t%s\n' "$_l1u_a" "$_l1u_b"
}

# --- the locks (docs/plans/launcher-first-install.md, 3.8): `installing`, held by whichever installer runs, and
# `updating`, held by the update's driver. Each is a link in the record's folder, in the launchers' lock form: its
# target is the holder's process number. One rule for both, read by the shared installer, the launcher's
# installer, the driver and this tool; the window holds the same rule in Swift.
_L1U_LOCK='^(installing|updating)$'
# the Mac's last start as epoch seconds; returns 1 when it cannot be read. `sysctl -n kern.boottime` prints
# "{ sec = <seconds>, usec = <n> } <a date>".
_l1u_boot() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin out
  out="$("${L1_SYSCTL:-/usr/sbin/sysctl}" -n kern.boottime 2>/dev/null)" || return 1
  [[ "$out" =~ sec\ =\ ([0-9]{1,12}), ]] || return 1
  printf '%s\n' "$((10#${BASH_REMATCH[1]}))"
}
# <name>: 0 when that lock is live, and L1U_HOLDER is then its holder's process number. Live means: a link whose
# target is a process number; that process answers; and the link is not older than the Mac's last start. After
# a restart a number left in a link can be some other process's: the link's own time (stat does not follow it)
# is compared with the start's, and an older link is dead. A start that cannot be read leaves the first two
# parts to decide. The two times are two clocks, so the rule fails open: a clock set back can make a live lock
# read as dead, which is the state of a Mac with no lock at all.
l1u_lock_live() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$L1_UPDATE_DIR/$1" h boot t
  L1U_HOLDER=""
  [[ "$1" =~ $_L1U_LOCK ]] || return 1
  [ -L "$f" ] || return 1
  h="$(readlink "$f" 2>/dev/null)" || return 1
  [[ "$h" =~ $_L1U_ID ]] || return 1
  kill -0 "$h" 2>/dev/null || return 1
  if boot="$(_l1u_boot)"; then
    t="$(stat -f %m "$f" 2>/dev/null)" || return 1
    [[ "$t" =~ $_L1U_TIME ]] || return 1
    [ "$((10#$t))" -ge "$boot" ] || return 1
  fi
  L1U_HOLDER="$h"
}
# <name>: 0 when this process holds that lock from now on. A live lock of another process is refused; a dead
# one is taken over in the launchers' way. The take is proved by reading the link back: a folder planted at the
# lock's name would take the link inside itself and report success, and of two takers that both found one dead
# holder only the one whose number the link holds goes on (the read narrows that gap and does not close it).
# A take of `installing` removes installing-game, whoever left it: a file left by a holder that was killed must
# not name its game under the next holder's lock.
l1u_lock_take() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$L1_UPDATE_DIR/$1" h
  [[ "$1" =~ $_L1U_LOCK ]] || return 1
  if ! ln -s "$$" "$f" 2>/dev/null; then
    l1u_lock_live "$1" && return 1
    h="$(readlink "$f" 2>/dev/null)"
    [ "$(readlink "$f" 2>/dev/null)" = "$h" ] && rm -f "$f" 2>/dev/null
    ln -s "$$" "$f" 2>/dev/null || return 1
  fi
  if [ ! -L "$f" ] || [ "$(readlink "$f" 2>/dev/null)" != "$$" ]; then
    [ -d "$f" ] && [ ! -L "$f" ] && rm -f "$f/$$" 2>/dev/null   # the link a planted folder took
    return 1
  fi
  [ "$1" = installing ] && rm -f "$L1_UPDATE_DIR/installing-game" 2>/dev/null
  return 0
}
# <name>: lets the lock go when this process holds it; with `installing`, the file that names the game first
l1u_lock_release() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$L1_UPDATE_DIR/$1"
  [[ "$1" =~ $_L1U_LOCK ]] || return 0
  [ -L "$f" ] && [ "$(readlink "$f" 2>/dev/null)" = "$$" ] || return 0
  [ "$1" = installing ] && rm -f "$L1_UPDATE_DIR/installing-game" 2>/dev/null
  rm -f "$f" 2>/dev/null
  return 0
}

# the offered version, or nothing: `offer` is one line, the version and the time of the fetch
_l1u_offer() {
  _l1u_read "$L1_UPDATE_DIR/offer" 2 || return 1
  [[ "$_l1u_a" =~ $_L1U_VER ]] && [[ "$_l1u_b" =~ $_L1U_TIME ]] || return 1
  printf '%s\n' "$_l1u_a"
}

# Sets L1U_WORD, L1U_INSTALLED, L1U_OFFERED and L1U_DETAIL (a field with no value is `-`); l1u_state prints them.
_l1u_state() {
  local id line ver low="" manual=""
  L1U_WORD=""; L1U_INSTALLED=-; L1U_DETAIL=-
  L1U_OFFERED="$(_l1u_offer)" || L1U_OFFERED=-
  if [ -e "$L1_UPDATE_DIR/off" ] || [ -L "$L1_UPDATE_DIR/off" ]; then L1U_WORD=off; return 0; fi
  while IFS=$'\t' read -r id line ver; do
    [ -n "$id" ] || continue
    if [ -z "$low" ] || l1u_newer "$low" "$ver"; then low="$ver"; fi
    [ -z "$manual" ] && [ "$line" != release ] && manual="$line"
  done <<EOF
$(_l1u_stamps)
EOF
  if [ -z "$low" ]; then L1U_WORD=none; return 0; fi
  L1U_INSTALLED="$low"
  if [ -n "$manual" ]; then L1U_WORD=manual; L1U_DETAIL="$manual"; return 0; fi
  if [ "$L1U_OFFERED" = - ]; then L1U_WORD=unknown; return 0; fi
  if l1u_newer "$L1U_OFFERED" "$low"; then L1U_WORD=ready; else L1U_WORD=current; fi
}
l1u_state() {
  _l1u_state
  printf '%s\t%s\t%s\t%s\n' "$L1U_WORD" "$L1U_INSTALLED" "$L1U_OFFERED" "$L1U_DETAIL"
}

# [--now]: asks GitHub which version `release` holds, at most once a day. Sets L1U_FETCH to fetched, failed
# or skipped. In the states off, none and manual nothing is ever fetched. No rule reads curl's exit code for
# more than zero or not.
l1u_refresh() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin force="${1:-}" now t tmp code rc size ver have curl="${L1_CURL:-/usr/bin/curl}"
  L1U_FETCH=skipped
  _l1u_state
  case "$L1U_WORD" in off|none|manual) return 0 ;; esac
  now="$(_l1u_now)"; [[ "$now" =~ $_L1U_TIME ]] || { L1U_FETCH=failed; return 0; }
  if [ "$force" != --now ] && _l1u_read "$L1_UPDATE_DIR/tried" 1 && [[ "$_l1u_a" =~ $_L1U_TIME ]]; then
    t="$((10#$_l1u_a))"
    if [ "$t" -le "$now" ] && [ "$((now - t))" -lt 86400 ]; then return 0; fi
  fi
  L1U_FETCH=failed
  l1u_own || return 0
  find "$L1_UPDATE_DIR" -maxdepth 1 -type f -name '.fetch.*' -mmin +10 -delete 2>/dev/null
  _l1u_put "$L1_UPDATE_DIR/tried" "$now" || return 0
  tmp="$(mktemp "$L1_UPDATE_DIR/.fetch.XXXXXX" 2>/dev/null)" || return 0
  code="$("$curl" -q --proto '=https' --tlsv1.2 -sS --max-time 10 --max-filesize 1048576 -o "$tmp" -w '%{http_code}' "$_L1U_URL" 2>/dev/null)"; rc=$?
  size="$(stat -f %z "$tmp" 2>/dev/null)"
  if [ "$rc" = 0 ] && [ "$code" = 200 ] && [[ "$size" =~ $_L1U_SIZE ]] && [ "$size" -le 1048576 ] \
     && ver="$(l1u_version_of "$tmp")" && [[ "$ver" =~ $_L1U_VER ]]; then
    have="$(_l1u_offer)" || have=-
    if l1u_newer "$have" "$ver"; then
      rm -f "$tmp"   # an answer up to five minutes old must not lower the offer
    else
      mv -f "$tmp" "$L1_UPDATE_DIR/notes.md" 2>/dev/null && _l1u_put "$L1_UPDATE_DIR/offer" "$ver"$'\t'"$now" || { rm -f "$tmp"; return 0; }
    fi
    L1U_FETCH=fetched
  else
    rm -f "$tmp"
  fi
  return 0
}

# The fetched notes of every version newer than the lowest installed one, newest first, cleaned so that a
# window can show them as they come: a version heading loses its "## "; the lines of a paragraph are joined
# with one space (a list item's indented lines join their item); fence lines are dropped and the lines between
# them kept as they are; ** and backticks are removed; control characters but newline and tab are removed.
# It stops before the line that would pass 200 lines or 12,000 bytes, and then names where the rest is.
l1u_notes() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin low a=-1 b=0 c=0 f="$L1_UPDATE_DIR/notes.md"
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  _l1u_state; low="$L1U_INSTALLED"
  if [[ "$low" =~ $_L1U_VER ]]; then low="${low#v}"; a="${low%%.*}"; low="${low#*.}"; b="${low%%.*}"; c="${low#*.}"; fi
  head -c 1048576 "$f" | LC_ALL=C tr -d '\000-\010\013-\037\177' | LC_ALL=C awk -v a0="$a" -v b0="$b" -v c0="$c" -v more="$_L1U_MORE" '
    function emit(s) {
      if (stopped) return
      if (lines + 1 > 200 || bytes + length(s) + 1 > 12000) { print more; stopped = 1; return }
      print s; lines++; bytes += length(s) + 1
    }
    function clean(s) { gsub(/\*\*/, "", s); gsub(/`/, "", s); return s }
    function flush() { if (buf != "") { emit(clean(buf)); buf = "" } }
    function newer(h,   p, n) {
      sub(/^## v/, "", h); sub(/ \(.*$/, "", h); n = split(h, p, ".")
      if (n != 3) return 0
      if (p[1] + 0 != a0 + 0) return p[1] + 0 > a0 + 0
      if (p[2] + 0 != b0 + 0) return p[2] + 0 > b0 + 0
      return p[3] + 0 > c0 + 0
    }
    { sub(/\r$/, "") }
    /^```/ { flush(); fence = !fence; next }
    fence { if (show) emit($0); next }
    /^## / {
      flush()
      if ($0 ~ /^## v(0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?)\.(0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?)\.(0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?) \(/ && newer($0)) {
        if (shown) emit("")
        show = 1; shown = 1; blank = 0; emit(clean(substr($0, 4)))
      } else show = 0
      next
    }
    !show { next }
    /^[ \t]*$/ { flush(); if (!blank) emit(""); blank = 1; next }
    { blank = 0 }
    /^(- |[0-9]+\. )/ { flush(); buf = $0; next }
    { line = $0; if (buf != "") { sub(/^[ \t]+/, "", line); buf = buf " " line } else buf = line }
    END { flush() }'
}

# For a launcher: prints the offered version when the state is ready and `noted` does not yet hold that
# version with the count 2, and then writes `noted` with the count raised. Otherwise it prints nothing.
l1u_noted() {
  local n=1
  _l1u_state
  [ "$L1U_WORD" = ready ] || return 0
  if _l1u_read "$L1_UPDATE_DIR/noted" 2 && [[ "$_l1u_a" =~ $_L1U_VER ]] && { [ "$_l1u_b" = 1 ] || [ "$_l1u_b" = 2 ]; } \
     && [ "$_l1u_a" = "$L1U_OFFERED" ]; then
    [ "$_l1u_b" = 2 ] && return 0
    n=2
  fi
  l1u_own || return 0
  _l1u_put "$L1_UPDATE_DIR/noted" "$L1U_OFFERED"$'\t'"$n" || return 0
  printf '%s\n' "$L1U_OFFERED"
}

# The button's file (plan 3.4): prints `opened` after it wrote "Update 1launcher.command" into a new temporary
# folder and handed it to Terminal, or `failed` TAB one sentence. It refuses unless the state is ready. The
# file holds constants only, but for curl's path: L1_CURL when that is a plain absolute path (so that a test
# can serve the fetch), else /usr/bin/curl. The installer is fetched into a file and never taken from curl's
# standard output, where the answer's code (-w) would become the script's last line.
l1u_open() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin d f curl=/usr/bin/curl
  _l1u_state
  if [ "$L1U_WORD" != ready ]; then printf 'failed\t%s\n' "No update is waiting."; return 0; fi
  # an install and an update keep out of each other's way (docs/plans/launcher-first-install.md, 3.8)
  if l1u_lock_live installing; then printf 'failed\t%s\n' "An install is running in Terminal. Wait for it to finish, then update."; return 0; fi
  [[ "${L1_CURL:-}" =~ $_L1U_PROG ]] && curl="$L1_CURL"
  d="$(mktemp -d "${TMPDIR:-/tmp}/1launcher-update.XXXXXX" 2>/dev/null)" \
    || d="$(mktemp -d /tmp/1launcher-update.XXXXXX 2>/dev/null)" \
    || { printf 'failed\t%s\n' "A temporary folder could not be made. Restart the Mac, then try the update again."; return 0; }
  f="$d/Update 1launcher.command"
  if ! { printf '%s\n' '#!/bin/bash' "CURL='$curl'"; cat << 'EOS'
# Written by 1launcher (updates.sh --open): the update. It removes itself and its folder when it exits.
F="$(dirname "$0")/.1launcher-fetch.$$"
trap 'rm -f "$0" "$F"; rmdir "$(dirname "$0")" 2>/dev/null' EXIT
clear
echo "Fetching the installer from github.com/macgameport/1launcher ..."
code="$("$CURL" -q --proto '=https' --tlsv1.2 -sSL -o "$F" -w '%{http_code}' https://raw.githubusercontent.com/macgameport/1launcher/refs/heads/release/install.sh)"; rc=$?
S="$(cat "$F" 2>/dev/null)"; rm -f "$F"
if [ "$rc" = 0 ] && [ "$code" = 200 ]; then
  /bin/bash -c "$S" 1launcher-install update; rc=$?
  echo
  case "$rc" in
    0) echo "Updated. You can close this window." ;;
    3) echo "Not everything was updated: see the lines above. You can close this window." ;;
    *) echo "The update did not finish: see the lines above. You can close this window." ;;
  esac
  exit "$rc"
fi
echo
if [ "$code" = 404 ]; then echo "This version of 1launcher cannot update an install. Paste the installer line from the guide instead."
else echo "GitHub could not be reached. Check the network, then try the update again."; fi
echo "You can close this window."
exit 1
EOS
  } > "$f" 2>/dev/null || ! chmod 755 "$f" 2>/dev/null; then
    rm -f "$f"; rmdir "$d" 2>/dev/null
    printf 'failed\t%s\n' "The update's file could not be written. Restart the Mac, then try the update again."; return 0
  fi
  if ! "${L1_OPEN:-/usr/bin/open}" -a Terminal "$f" > /dev/null 2>&1; then
    rm -f "$f"; rmdir "$d" 2>/dev/null
    printf 'failed\t%s\n' "Terminal could not be opened for the update."; return 0
  fi
  echo opened
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  if [ -z "${L1_UPDATE_DIR:-}" ]; then L1_UPDATE_DIR="$(cd "$(/usr/bin/dirname "$0")" && pwd)"; fi
  case "${1:-}" in
    '') l1u_state ;;
    --refresh)
      l1u_refresh "${2:-}"; _l1u_state
      printf '%s\t%s\t%s\t%s\t%s\n' "$L1U_WORD" "$L1U_INSTALLED" "$L1U_OFFERED" "$L1U_DETAIL" "$L1U_FETCH" ;;
    --notes) l1u_notes ;;
    --noted) l1u_noted ;;
    --version-of) l1u_version_of "${2:-}" || true ;;
    --open) l1u_open ;;
    *) echo "usage: updates.sh [--refresh [--now] | --notes | --noted | --open | --version-of <file>]" >&2; exit 2 ;;
  esac
  exit 0
fi
