# tools.sh -- the ask for Apple's Command Line Tools and the wait for them (docs/plans/launcher-first-install.md,
# 3.2, LFD14): read with `.` by the shared installer (common/install-core.sh) and by the launcher's installer
# (common/install-launcher.sh), never run by itself. It holds two functions and nothing else. The caller defines
# say, and sets POLL (seconds between two looks), TOOLS_POLLS (how many looks for the tools' folder) and
# TOOLS_PART_POLLS (how many more for the part) first.
#
# Both are for a run that began with no tools' folder. A folder that was there at the start is judged at once,
# by the caller, before any ask: a request on a Mac that has the folder brings no box.

# Asks Apple for the tools and says what the player then does. It returns the request's own exit code, and
# never stops by itself: when the request was not taken it says other words, and the caller's wait goes on.
tools_ask() {
  local rc=0
  xcode-select --install > /dev/null 2>&1 || rc=$?
  if [ "$rc" = 0 ]; then
    say "A box from Apple has opened; it may be behind this window. Press Install, then Agree."
    say "The download comes from Apple and can take 10 minutes or more. This window goes on by itself when it is done."
  else
    say "Apple's box could not be opened from here. It may be open already; if no box is showing, run xcode-select --install in Terminal at the Mac itself. This window goes on by itself when the tools are there."
  fi
  return "$rc"
}

# <test of the part> [<its arguments> ...]: called only after tools_ask. Every POLL seconds, at most TOOLS_POLLS
# times, it asks xcode-select -p; once that succeeds it runs the caller's test of the part, and never before:
# without the tools, running one of them opens Apple's box itself. Returns 0 when both hold; 1 when the polls
# ran out with no tools; 2 when the folder is there and the part still does not run TOOLS_PART_POLLS polls
# later (Apple's package may still be writing its files when the folder appears).
tools_wait() {
  local i=0 j=0
  until xcode-select -p > /dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -gt "$TOOLS_POLLS" ] && return 1
    sleep "$POLL"
  done
  until "$@"; do
    j=$((j + 1))
    [ "$j" -gt "$TOOLS_PART_POLLS" ] && return 2
    sleep "$POLL"
  done
  return 0
}
