# The sign-in wait starts Steam again when Steam gives up, and no `-shutdown` goes to a Steam that is not there

Written 2026-11-24 on the branch `signin-restart`, cut from `built-in-update` at `42a7fd7`. Issue #32 (its
second and third subjects; its first, keeping Steam from asking at all, is not here).

> **Status: NOT yet checked.** Run `check it` on this file before the first commit of the build. Nothing is
> built. The measurements in section 3 were taken on scratch copies under `/tmp/sr-plan/` with stub programs:
> no Wine, no Steam, no game was started for this plan.

Words used below: **the block** is `launch-feedback`, the text both launchers hold byte for byte
(`common/test-launcher-parity.sh`, rule 1). **A look** is one turn of `signin_wait`'s loop, every 3 s.
**The question** is macOS asking whether `wine64` may use the microphone. **The call** is
`steam.exe -shutdown`.

## 0. Decided by James (2026-11-24; not open)

1. The launcher copes. While the sign-in wait lasts, a Steam that was seen and has left is started again, so
   that an answer within the ten minutes still brings the game up.
2. The call is not sent when no Steam of that prefix is running.
3. It ships before `release` next moves, in the same release as the built-in update, whose guides say `v0.3.1`.
4. Keeping Steam from asking for the microphone is issue #32's own first subject, and not in this plan.

## 1. What is true today

Measured 2026-11-24 on both Macs (`docs/plans/wrapper-names.md`, "W3 steps 1 to 7", step 7, and the note "Read
again from the Studio"; `cities-skylines-2/GOTCHAS.md:2611-2644`; the Studio's watch is `probe-issue32/run-1.log`
in the Surviving Mars workspace):

| When (Studio, seconds after the start) | What |
|---|---|
| 3 | the first `steam.exe` holds the prefix; a webhelper at 6 |
| 10 | Steam's connectivity test begins; macOS puts the question in the same second |
| 48 | the launcher's hint line |
| 192 | no `steam.exe` (3 min 2 s after the test began, no result line); its webhelper is still there at this look and gone at the next, 3 s later |
| 204 | the launcher has counted 15 s and run `stop_steam`; its call holds the prefix **as a Steam client** (`bootstrap_log.txt`: "Steam Client launched with: ... -shutdown", then an update check) |
| 386 | that client is gone too (3 min 1 s after its own test began) |
| 390 | "ERROR: Steam did not sign in by itself..." |

The MacBook's run was the same in shape: the launcher's call at 3 min 27 s, and the question answered only
after both Steams had left; the next start ran. Answered within about a minute, the same start goes on (the
Studio at W2b after 68 s; the MacBook at W3 step 3).

The code:

- **The wait.** `signin_wait <step> <test> [<alive>]`, in the block: `cities-skylines-2/launchers/launch-cs2-dxmt11.sh:77-96`
  and `surviving-mars-relaunched/launch-relaunched.sh:138-157`. It ends early, with 1, once Steam was seen and
  has then been gone for five looks in a row (`:90` and `:151`). Its own comment says why: "no answer brings
  back a Steam that died" (`:81-82`, `:142-143`). That is the sentence this plan makes untrue.
- **Cities: Skylines II starts Steam** at `launch-cs2-dxmt11.sh:313` (the `.crash` marker removed) and `:320`
  (`"$WINE" "$STEAM" -silent -no-cef-sandbox >/dev/null 2>&1 & disown`), under the comment that forbids
  `nohup`, `env`, `setsid` and `bash -c` (`:314-319`). `BEFORE` is set at `:304`, before the test of whether
  Steam is already up; `signed_in` (`:303`) reads the connection log from `BEFORE` and asks for a webhelper.
  The call of the wait is `:322`; when it fails the launcher dies and **sends nothing to Steam**.
- **Surviving Mars starts Steam** at `launch-relaunched.sh:375-378` (`BEFORE`, the marker, the comment, the
  start). `signed_in` (`:368`) reads the log from `BEFORE` and asks for `steam_exe_up`. The call of the wait is
  `:380`, and when it fails it runs `stop_steam` before it dies.
- **`stop_steam`** (`launch-relaunched.sh:359-366`) runs the call in the foreground, with no test first
  (`:360`), then waits up to 20 s for `steam_exe_up` to turn false, then `wineserver -k` if it has not, then
  a plain TERM to what is left of the family. It is called at `:380` (the wait failed), `:399` and `:401` (a
  cloud conflict, a sync that did not end; only when this launch started Steam) and `:542` (after the game).
- **Cities: Skylines II after the game** (`launch-cs2-dxmt11.sh:443`) runs the call in the foreground too,
  with no test first, then the same three stages inline (`:444-474`). So a Steam that left during play (a
  crash, the player's own quitting, another Mac signing in) makes this call a client as well; that it has not
  been seen there is not a reason to leave it.
- **The instruments.** `cities-skylines-2/scripts/boot-verify.sh:246` and
  `surviving-mars-relaunched/tools/licence-wait-probe.sh:85` start a launcher with `L1_SIGNIN_SECS=120`, and
  wait 240 s (`boot-verify.sh:256`) and 300 s (`licence-wait-probe.sh:88`) for the game.
- **The tests.** `common/test-launch-feedback.sh` drives the block with stubs (88 cases, mutants 1 to 18);
  `common/test-launcher-parity.sh` rule 10 (`:305-324`, mutants 17 to 24) fixes the form of the call line as
  `signin_wait <number> <function> steam_exe_up || ...`. Its highest rule is 11 and its highest mutant 28.
  Nothing tests `stop_steam` or the shutdown after the game.
- **The words.** `CHANGELOG.md:49-55` (in the published section `v0.3.0`), `surviving-mars-relaunched/INSTALL.md:165-168`,
  `cities-skylines-2/INSTALL.md:516-519` and its Troubleshooting row `:553` all say that with the question
  left open Steam gives up after about three minutes and the start ends.

## 2. Target

- A question answered at any time up to about nine and a half minutes after the start brings the game up from
  that start, with nothing for the player to do but answer.
- A question never answered ends the launch once, at about ten minutes, with today's message, and no Steam of
  the prefix left running.
- Neither launcher ever runs the call in the foreground, and neither sends it when no Steam of its prefix is
  up. If Steam leaves between the test and the call, the launcher is held 20 s more, not three minutes, and
  the client the call became is ended.
- A Steam that dies at once is not started again. A Steam that stays up without signing in (an expired
  token) is today's timeout, unchanged. The instruments end as today.

## 3. Measured for this plan (fixtures; bash 3.2.57)

All under `/tmp/sr-plan/`. The function of 4.1 was run as written there.

**3.1 The wait, on a model of Steam with a clock that `sleep` moves** (`proto.sh`, `sim.sh`). The model: a
Steam holds the prefix 3 s after its start; with the question open it leaves 189 s after its start (the
Studio's 192 less 3); it signs in 25 s after the later of its start and the answer.

| Case | Result | Ends at | Steams started | Restart lines |
|---|---|---|---|---|
| never answered | 1 | 600 s | 3 | 2 |
| never answered, Steam leaving after 180 s | 1 | 576 s | 3 | 2 |
| never answered, today's call (no fourth word) | 1 | 201 s | 1 | 0 |
| answered at 68 s | 0 | 93 s | 1 | 0 |
| answered at 200 s (no Steam up at that moment) | 0 | 228 s | 2 | 1 |
| answered at 300 s | 0 | 327 s | 2 | 1 |
| answered at 500 s | 0 | 525 s | 3 | 2 |
| Steam dies after 6 s | 1 | 18 s | 1 | 0 |
| Steam dies after 57 s | 1 | 69 s | 1 | 0 |
| Steam dies every 63 s, never signs in | 1 | 225 s | 3 | 2 |
| Steam stays up, never signs in (expired token) | 1 | 600 s | 1 | 0 |
| no Steam for 9 s (its updater), then back | 0 | as without the gap | 1 | 0 |
| the Steam started again is first seen 12 s after its start | goes on | | | |
| the Steam started again is never seen | 1 | 216 s | 2 | 1 |

- **The latest answer that still brings the game up: 573 s.** Every answer from 3 s to 573 s, in steps of 3,
  ended with 0; 576 s to 600 s ended with 1. So the promise is "about nine and a half minutes", not ten.
- **With `L1_SIGNIN_SECS=120`: no restart for any lifetime.** 41 runs (Steam leaving after 3, 6, ... 120 s,
  and never): 0 with a restart line, and the three compared with today's call ended at the same second (120,
  42 and 102 s). The smallest limit at which any lifetime gives a restart is 135 s (60 s lived, 15 s gone,
  60 s left).
- **The existing tests with the new block.** The function of 4.1 put into scratch copies of both launchers:
  `test-launch-feedback.sh` 88 of 88 and `test-launcher-parity.sh` 61 of 61 still pass, both launchers parse.
  **Three existing mutants no longer bite:** 14 and 15 are refused (their lines changed), and **16 applies by
  its proof text and stays green**, because its `sed` no longer matches the line while the text it greps for
  is a prefix of the unchanged line. Step R1 rewrites the three.

**3.2 Starting through a function named in a word** (`start-test.sh`, with a compiled C program in place of
`wine64`, because any script would itself be started by a system program). A function that holds
`"$WINE" ... >/dev/null 2>&1 & disown`, called as `"$4"` from inside `signin_wait`:

- the child got `DYLD_FALLBACK_LIBRARY_PATH` unchanged, at the first start and at the restart;
- the same program started with `env`, with `nohup` or through `/bin/bash -c` got it **stripped**, all three;
- the function's `BEFORE=` was seen by the caller, the marker file it removes was gone after each call, the
  shell's job table was empty, and bash printed no line of its own.

**3.3 The call, bounded** (`stop-test.sh`, `stop-test2.sh`; a stub `wine64` that, with no "Steam" up, becomes
a client that stays, and is not seen as `steam.exe` for its first 4 s):

| Form | Case | Time | Left running afterwards |
|---|---|---|---|
| today's (`stop_steam` as it is) | no Steam up; the client stays 40 s (181 s live) | 42 s | 0 |
| A: the test, and the call in the background | Steam leaves between the test and the call | 2 s | **1: the client** |
| B: A, and the call's own process is waited for | the same | 23 s | 0 (`wineserver -k` once) |
| B | a Steam up, the call forwarded | 3 s | 0 |
| B | no Steam up | 2 s, no call | 0 |

Form A returns at once because its first look for `steam.exe` comes before the client holds the prefix, and
then nothing ends the client. So the bound needs the call's own process id. Form B is what 4.4 specifies.

## 4. Design

### 4.1 The restart is in the block: a fourth word

```bash
signin_wait() {   # <step> <test> [<alive> [<start>]]: wait for Steam's sign-in; 0 = signed in, 1 = not
  local limit="${L1_SIGNIN_SECS:-600}" t=0 hinted=0 seen=0 gone=0 lived=0 again=0
  case "$limit" in ''|*[!0-9]*|????*) limit=600 ;; esac
  while [ "$t" -lt "$limit" ]; do
    "$2" && return 0
    if [ "$hinted" = 0 ] && [ "$t" -ge 45 ]; then hinted=1; step "$1" "Still signing in. If macOS asks a question, answer it…"; fi
    if [ -n "${3:-}" ]; then
      if "$3"; then seen=1; gone=0; lived=$((lived + 3))
      elif [ "$seen" = 1 ]; then
        gone=$((gone + 3))
        if [ "$gone" -ge 15 ]; then
          [ -n "${4:-}" ] && [ "$lived" -ge 60 ] && [ "$again" -lt 2 ] && [ $((limit - t)) -ge 60 ] || return 1
          again=$((again + 1)); gone=0; lived=0
          step "$1" "Starting Steam again. If macOS asks a question, answer it…"
          "$4" || return 1
        fi
      fi
    fi
    sleep 3; t=$((t + 3))
  done
  "$2" && return 0
  return 1
}
```

The comment lines under the first line are rewritten to say this (the sentence "no answer brings back a Steam
that died" goes).

**Why in the block.** The rule for when to start again is the same for both games and is the part that can
be wrong; it belongs where rule 1 keeps one text and where `test-launch-feedback.sh` already drives it with
stubs. What differs between the launchers is one command line, and that stays in each launcher (4.2).

**The rules, each with its reason.**

| Rule | Value | Why |
|---|---|---|
| Steam counts as gone | five looks in a row without it (15 s), as today | Steam is away for a few seconds when its updater replaces it; the installer's measure too. A gap shorter than that changes nothing, so the updater's own restart is never doubled |
| It is started again only if it had been seen for | 20 looks (60 s) since it was last started | A Steam that crashes at once fails the same way again. A sign-in with no question took 8 to 30 s on every start measured; the Steam that gave up at the question had been seen for 189 s. 60 is between, on the far side of the IPv6 wait (23 to 27 s to the logon call) |
| At most | 2 restarts in one wait | With Steam leaving after about 3 min, two restarts fill the ten minutes (3.1). The number bounds a Steam that leaves every minute or two for a reason nobody has seen: without it, seven starts in ten minutes |
| Not when less than | 60 s of the wait are left | A start needs up to about 30 s to sign in; a Steam started later than that would be left signing in while the launcher gives up. Then the wait ends at once, with 1, as today: nothing is gained by waiting on with no Steam. It is also what keeps the instruments as they are (4.6) |
| After a restart | `seen` stays 1, the counts of `gone` and `lived` start at 0 | So a Steam that does not come up within 15 s of being started again ends the wait (measured live: 3 s at the first start, at most 9 s at the client of the call). `seen=0` would wait the rest of the ten minutes for nothing: the reason a first Steam is waited for (macOS's "Verifying..." sheet on a wrapper not opened for long) does not hold three minutes into a launch |
| The start word returns non-zero | the wait ends with 1 | a launcher's start may refuse; neither does today |
| No fourth word | today's behaviour, to the second | a caller that cannot start Steam is not broken (3.1, row 3) |

**The cases the task names.**

- *A Steam that crashes at once, again and again:* never started again (lived under 60 s). After a restart
  the count starts again, so a restarted Steam that leaves within a minute ends the wait.
- *An expired token:* Steam stays up; nothing here fires; 600 s as today.
- *Steam's own updater:* inside the 15 s; nothing fires.
- *A Steam started by someone else meanwhile* (the wrapper opened by hand): `"$3"` sees it, because it tests
  the prefix and not a process id; `gone` goes back to 0 and nothing is started. The test and the start are
  the same look, some milliseconds apart (one `lsof` per `steam.exe`), and the launcher holds the wrapper's
  lock, so no second launcher starts one. A Steam in another wrapper is not this prefix's and is not counted.
- *The player quits Steam while waiting:* it cannot be told from Steam leaving by itself, so it is started
  again, at most twice, and the line says so. A player who wants the launch to end closes the progress window
  and the game's app; a third quitting ends it with the message.
- *The webhelpers of the Steam that left:* not waited for, and not swept. They were gone 3 s after
  `steam.exe` both times it left by itself (section 1), the restart comes 12 s after that, and the client of
  the call came up beside none 12 s after the first Steam left. A first start today does not look for
  leftovers either. If RL1 shows a restart beside a leftover webhelper going wrong, that is a finding to fold,
  not something to build for unseen.

### 4.2 Each launcher gives its start as a function, and uses it for the first start too

One function per launcher, `start_steam`, defined after `signed_in` and before the `if steam_exe_up`. (The
installer's `common/install-core.sh:159` has a function of the same name; the launchers do not read that
file, and the parity test's new rule looks only in the launchers.)

Cities: Skylines II:

```bash
start_steam() {   # start this prefix's Steam in the background: the first start, and signin_wait's restarts
  BEFORE=$(wc -l < "$CL" 2>/dev/null || echo 0)
  # a stale 0-byte .crash marker makes steam.exe exit 1 and never start — clear it first
  rm -f "$WINEPREFIX/drive_c/Program Files (x86)/Steam/.crash" 2>/dev/null
  # ⚠ NEVER `nohup` here ... (today's comment, :314-319, moved whole and unchanged)
  "$WINE" "$STEAM" -silent -no-cef-sandbox >/dev/null 2>&1 & disown
}
```

and in the branch that starts Steam: `start_steam`, `STARTED_STEAM=1`, then
`signin_wait 2 signed_in steam_exe_up start_steam || die "..."` with today's words. The line `BEFORE=` at
`:304` stays, so that the variable is set on the path where Steam was already running (the launcher runs
under `set -u`).

Surviving Mars: the same, with `"$STEAM_WINE"` and its one-line comment; today's `:375-378` become the
function's body, and the branch reads `STARTED=1`, `start_steam`,
`signin_wait 1 signed_in steam_exe_up start_steam || { stop_steam; die "..."; }`.

**Why a function and not a command in a variable.** The start line is written once per launcher, in the
launcher's own text, with `& disown` as the last thing on it; the block calls it by name in the launcher's own
shell. Nothing is `eval`ed, nothing goes through `env`, `nohup`, `setsid` or `bash -c`, so nothing strips
`DYLD_*` (measured, 3.2). The comment that forbids those four stands directly over the only line it is about,
and the first start and every restart are that one line, so the marker is removed before each start by
construction.

### 4.3 What counts as signed in after a restart; `STARTED` and `STARTED_STEAM`

- `start_steam` sets `BEFORE` again, so `signed_in` reads only what the Steam just started has logged. Without
  it, a logon line of a Steam that then left inside one look would count for the next Steam the moment that
  one held the prefix, and the game would be started against a Steam not yet signed in. The log lines
  themselves, and each launcher's second condition (a webhelper; `steam_exe_up`), are unchanged.
- `STARTED` and `STARTED_STEAM` keep their meaning, "this launch started the Steam that is running": they are
  set once, before the wait, and a restart does not change them. The licence wait runs after `signin_wait`
  returns 0, so it counts from the sign-in of whichever Steam signed in. Surviving Mars's `stop_steam` at
  `:399` and `:401` still runs only for a Steam this launch started.

### 4.4 The call: only to a Steam that is up, never in the foreground, and bounded

Surviving Mars, `stop_steam`:

```bash
stop_steam() {
  _sd=""
  if steam_exe_up; then   # with no Steam of this prefix up, the call itself becomes a Steam client (issue #32)
    "$STEAM_WINE" "$STEAM" -shutdown >/dev/null 2>&1 & _sd=$!; disown
    for _ in $(seq 1 20); do steam_exe_up || kill -0 "$_sd" 2>/dev/null || break; sleep 1; done
    kill -0 "$_sd" 2>/dev/null || _sd=""
  fi
  steam_exe_up && "$ENGINE/bin/wineserver" -k >/dev/null 2>&1
  sleep 2
  [ -n "$_sd" ] && kill "$_sd" 2>/dev/null   # the call still there after 22 s: plain TERM, never -9
  _strays="$(steam_family)"
  [ -n "$_strays" ] && kill $_strays 2>/dev/null   # plain TERM, never -9
}
```

Cities: Skylines II, after the game (`:443-448`): the same first stage inline, with `"$WINE"`, its
`for i in $(seq 1 20)` loop given the same second condition, and an `else` that prints
"  Steam is not running: nothing to shut down." The words "(steam -shutdown failed; falling back)" go: a call
in the background has no exit code to read, and the line the fallback prints (`:451`) says the same. Its
fallback (`:450-457`), the sweep of strays (`:461-467`), the nudge of a lingering `wineserver` (`:469-472`)
and the count of what is left (`:473-474`) stay as they are, with one line added before the sweep:
`[ -n "$_sd" ] && kill "$_sd" 2>/dev/null`.

Which places need the test: **both**, at every use. Surviving Mars's `stop_steam` is one function, so its four
callers get it at once; Cities: Skylines II has the one place. Its failed sign-in (`:322`) sends nothing
today and still sends nothing.

**Is a bound needed as well as the test? Yes, and it needs the call's own process id** (3.3). Between the
test and the call Steam can leave; the call then becomes a client that the first look does not yet see. With
the call in the background and its process waited for beside `steam_exe_up`, the launcher is held 20 s at
most, `wineserver -k` ends the session the client joined, and a TERM goes to the call's process if it is
still there. All three stages after the call run as today, in today's order, whether or not the call was
sent. `wine64` in all three wrappers on the Studio is a Mach-O program, not a script, so `$!` is the process
that becomes `steam.exe`.

Each launcher's stopping code gets a pair of markers, `# >>> stop-steam` and `# <<< stop-steam` (around the
function in one, around the inline lines from the `echo "Game exited` line's successor to the `echo` of the
count in the other), so that a test can cut it out. The two texts are **not** made the same bytes: they differ in
`"$WINE"` and `"$STEAM_WINE"`, in how `wineserver` is reached, and in what they print, and making the
shutdown one shared block is unification work, not this plan's.

### 4.5 What the player reads

- **At 45 s:** the existing line, unchanged.
- **At a restart:** `Starting Steam again. If macOS asks a question, answer it…` (58 characters; the window's
  label takes 62), sent as a step with the caller's number, so the progress window shows it and, with no
  window, it is a notification. Something must be said: the log of a launch that started Steam three times
  has to show it, and the window must not look stuck for ten minutes. It repeats the instruction because the
  window shows only the last line, and at that moment the instruction is the one thing that helps. At most
  two such lines in a launch.
- **The final message:** both launchers' words stay as they are. "If macOS asked a question ..., answer it and
  start the game again" is still what to do, and after an answer the next start ran on both Macs. The first
  sentence of each is quoted by tests and a probe.
- The progress window stays up while the log grew within 900 s (`common/launch-progress.swift:65-73`); its
  comment names the wait after the hint line as the longest silence, a little over 9 minutes, and that is
  still so for a Steam that stays up (an expired token). No change there.

### 4.6 The instruments end as today

No line of `boot-verify.sh` or of either `licence-wait-probe.sh` changes. With 120 s there is no restart for
any lifetime of Steam (3.1: 41 of 41, and the arithmetic: 60 s lived, 15 s gone and 60 s left need 135 s).
What does change for them is `stop_steam` after a failed wait in the Surviving Mars probe: it is bounded at
about 25 s where it was unbounded, which is inside the probe's 300 s. `boot-verify.sh --selftest` judges logs
and starts nothing.

### 4.7 Words elsewhere

| Where | What changes |
|---|---|
| `CHANGELOG.md`, `## Unreleased` | a new paragraph, drafted in section 6 (R4). **The section `## v0.3.0` is not touched:** it is published, it says what `v0.3.0` does, and that is still true of `v0.3.0`. The rule for a wrong release (a first line naming its successor) is for a release that is wrong, and this one is not |
| `surviving-mars-relaunched/INSTALL.md:165-168`, `cities-skylines-2/INSTALL.md:516-519` | the sentences from "Answered within about a minute" on, rewritten from what RL1 and RL2 show; draft in section 6. They name the version, as the built-in update's guides do: before `v0.3.1` the start ended after about three minutes |
| `cities-skylines-2/INSTALL.md:553` (Troubleshooting, "Steam did not auto-login") | "Steam itself gives up after about three minutes and the launcher then stops" becomes: the launcher starts Steam again, and stops after ten minutes |
| `cities-skylines-2/GOTCHAS.md:2611-2644` | "Not built: ..." becomes what was built, with this plan's name; a line on form A of 3.3 (a call put in the background is not bounded unless its own process is waited for); the dated measurements stay |
| both launchers' headers (`launch-cs2-dxmt11.sh:22-23`, `launch-relaunched.sh:66-67`) | one clause: within that time a Steam that leaves is started again, at most twice |
| root `CLAUDE.md`, "In progress" | one sentence for this plan, at each state it reaches |
| `surviving-mars-relaunched/README.md:102` | nothing: what it says of `L1_SIGNIN_SECS` stays true |
| `docs/plans/wrapper-names.md` | nothing: a dated record |

## 5. Not in this plan

- Keeping Steam from asking for the microphone (issue #32's first subject; it needs a probe).
- Answering the question for the player, or seeing whether one is on screen.
- `S734M.app`: it has no wait and sends no call.
- One shared block for stopping Steam in both launchers.
- What Cities: Skylines II does with a Steam that is up and not signed in when its wait fails (it leaves it,
  as today).
- A sweep of leftover webhelpers before a start.
- A connection log that Steam has rotated during the wait (`BEFORE` then points past its end): as today.
- The update block and the installer: neither starts Steam through this code.

## 6. Steps

All on the branch `signin-restart`. Each step ends with its tests green and its new mutants applied and seen
red, then put back and seen green.

- **R0. Before code.** `check it` on this file, and the verdict line. `git log 42a7fd7..HEAD` over the key
  paths of the review log; if `built-in-update` or `main` moved under them, read the cited lines again.
- **R1. The block.** `signin_wait` as in 4.1, the same bytes in both launchers, its comment rewritten.
  `test-launch-feedback.sh`: the new cases (RT1) and mutants 19 to 26; **mutants 14, 15 and 16 rewritten for
  the changed lines, 16 with a proof text the unchanged line does not satisfy** (3.1).
- **R2. `start_steam` and the call lines** in both launchers (4.2). `test-launcher-parity.sh`: rule 10's
  pattern for the call line takes the fourth word, its mutants 17, 18, 22 and 24 follow the new line; the new
  rule 12 and mutants 29 to 36 (RT2).
- **R3. The call** (4.4) in both launchers, with the markers. The new `common/test-launcher-steam.sh` (RT3).
- **R4. The words** (4.7), as drafts where they depend on the live steps:
  - `CHANGELOG.md`, Unreleased: "**A start no longer ends because a question from macOS was left open**
    (docs/plans/signin-restart.md). After a wrapper is renamed macOS asks once more whether wine64 may use the
    microphone, and Steam gives up waiting for the answer after about three minutes. The launcher now starts
    Steam again, at most twice, and says so, so an answer within about nine minutes brings the game up from the
    same start. Left unanswered, the start ends after ten minutes with the message it had; before, that message
    came after three and a half to six and a half minutes, and Surviving Mars then held the wrapper three
    minutes longer."
  - both `INSTALL.md`: "Answer it, either way. From v0.3.1 the launcher waits ten minutes for the answer: Steam
    itself gives up after about three, and the launcher starts it again and says so. If the start ends with
    "..." all the same, answer the question and start the game again."
- **R5. The whole suite.** Every tracked test file (46 today, 47 with the new one), run directly, never under
  `nohup`, each with its real exit code. The identifier and link checks.
- **R6. The live steps** (section 8), on James's word, then the words of R4 made to say what was seen, the
  as-built header on this file, `CLAUDE.md`, and a comment on issue #32 (written with "refs", never a closing
  word: the issue stays open for its first subject).

The merge follows the built-in update's: this branch goes into `built-in-update` or into `main` after it,
whichever James names; it does not move `release`.

## 7. Tests

The numbers follow each file's highest today: `test-launch-feedback.sh` 18, `test-launcher-parity.sh` 28
(rules: 11). The new file starts at 1.

| ID | File | What is asserted | Mutants (each applied, seen red, put back) |
|---|---|---|---|
| RT1 | `common/test-launch-feedback.sh`, for each launcher's block, with a fourth word that counts its calls | Seen 20 looks, gone 5: the start word is called once at that look, one restart line as step 4 (the test's number, neither launcher's), the wait goes on; then signed in: 0. Seen 19 looks, gone 5: 1 at once, no call. Three departures of a Steam seen 20 looks each: two calls, 1 at the third. With 57 s left: no call, 1 at once; with 60 s left: a call. After a restart, never seen for 5 looks: 1, one call. After a restart, seen 10 looks and gone: 1, no second call. The start word returning 1: 1 at once, after its one line. No fourth word: every existing `alivecase` result unchanged, and the departure case ends with 1 and no restart line. `L1_SIGNIN_SECS=120`, Steam leaving after each of 1 to 40 looks: no call in any. The restart line is a step: one notification with no window, none with it. Nothing on stderr in any case | 19 the lifetime test dropped; 20 the count of restarts dropped; 21 the test of the time left dropped; 22 `seen` set to 0 at a restart; 23 `lived` not set to 0 at a restart; 24 the start word's failure ignored; 25 the restart line dropped; 26 the restart made when no fourth word is given (`-n` test dropped). And 14, 15, 16 rewritten |
| RT2 | `common/test-launcher-parity.sh`, rule 10 (changed) and rule 12 (new) | Rule 10: the call is `signin_wait <number> <function> steam_exe_up start_steam \|\| ...`. Rule 12, per launcher: `start_steam` is defined once, outside the block; the launcher holds exactly one line, comments apart, with `-silent -no-cef-sandbox`, it is in that function, and it ends `>/dev/null 2>&1 & disown`; before it in the function stand a `BEFORE=` line and the `rm -f` of the `.crash` marker; no line of the function, comments apart, holds `nohup`, `setsid`, `env `, `exec ` or `bash -c`; the branch that starts Steam calls `start_steam` once on a line of its own; the restart text in the block is one plain literal of at most 62 characters; the launcher holds one pair of `stop-steam` markers, exactly one line with `-shutdown` comments apart, inside them, ending `& _sd=$!; disown`, under an `if steam_exe_up; then` | 29 one launcher's call without the fourth word; 30 `nohup` put before the start line in one launcher; 31 the `rm -f` of the marker taken out of one function; 32 the `BEFORE=` line taken out of one function; 33 a second start line outside the function in one launcher; 34 the restart text made 63 characters, in both; 35 the `&` taken off one launcher's call (foreground again); 36 the `if steam_exe_up` taken off one launcher's call |
| RT3 | new `common/test-launcher-steam.sh`: each launcher's `start_steam` and its `stop-steam` piece, cut out and run under `set -u` with stub programs (a stub `wine64` that records its arguments; with no stub Steam up it becomes a client that waits on a pipe the test holds, and is not seen as Steam for its first looks; a stub `wineserver` that records and ends stub Steams; `sleep` recorded, not slept). A watchdog of 10 s fails any case that does not return | `start_steam`: one child with the three arguments, the marker gone, `BEFORE` equal to the log's line count at that moment, at a first and at a second call; bash prints nothing. Stopping: with no Steam up, no call, no `wineserver -k`, returns; with one up, one call, the piece returns once it is gone, no `wineserver -k`; with one up that ignores the call, `wineserver -k` once after 20 recorded seconds; **Steam leaving between the test and the call: the piece returns while the client still waits on its pipe, `wineserver -k` was called, and the client was sent a TERM**; a leftover webhelper stub after all that gets a TERM and never a KILL; Cities: Skylines II's piece prints its "nothing to shut down" line and its count line | 1 the `if steam_exe_up` test dropped; 2 the call put in the foreground; 3 the call's process no longer waited for (form A of 3.3: must leave the client); 4 the `wineserver -k` fallback dropped; 5 the TERM to the call's process dropped; 6 the sweep of strays dropped; 7 `rm -f` dropped from `start_steam`; 8 `kill` made `kill -9` in the sweep |
| RT4 | every tracked test file | exit 0, with real exit codes; among them `test-mod-notes.sh` (it finds the "Starting Steam and signing in…" step line by its text), both `test-update-check.sh`, `test-licence-wait-probe.sh`, `test-launch-progress.sh`, Surviving Mars's `test-setup.sh` (it compares the installed launcher with the repo's, byte for byte) | the existing ones are not run again, except those this plan rewrites |
| RT5 | `bash cities-skylines-2/scripts/boot-verify.sh --selftest` | every judge branch as before | none |

What RT3 cannot show, and RT2's source gate stands for: that the child keeps `DYLD_*`. A test would need a
compiled program (any script is started by a system program, which strips them); 3.2 measured it once, and
rule 12 forbids the four words that break it, as `test-make-steam-shortcut.sh` does for the store's start.

## 8. Live steps (on James's word; the Studio; nothing of Wine running on the MacBook meanwhile)

Before them: both setups from the branch, so the installed launchers are the branch's (`--check` first; no
rename is named). Each rename is by hand, of the Surviving Mars wrapper, to a name it has never had, with
nothing of Wine running, and is put back afterwards; a name that has been answered is not asked again, so
RL1 and RL2 need two different names. Outputs in `signin-restart-rl/` in the Surviving Mars workspace; the
watch is `probe-issue32/run.sh`'s (the processes of the prefix every 3 s, the launcher's last line, the three
logs afterwards).

| Step | What | Pass | Essential? |
|---|---|---|---|
| RL1 | Attended. The game started from its app; James leaves the question until the window has shown "Starting Steam again..." (a little after 3 min 20 s), then answers it | The game reaches its menu **from that start**; the launcher's log holds the hint once and the restart line once or twice; `bootstrap_log.txt` holds no "launched with ... -shutdown" line since the start; after the game is closed, saves uploaded, Steam down, no lock, no crash marker. Recorded besides: whether macOS put the question again for the second Steam (the privacy log), how long after the answer the logon came, and what of the first Steam's family was there at the restart | **Yes.** It is the decided behaviour, and it rests on one thing nobody has seen: that an answer releases a Steam other than the one the question was first put for |
| RL2 | Unattended, the question never answered (James away, as on 2026-11-24) | The launcher's "Steam did not sign in by itself" comes between 9 min 30 s and 10 min 30 s after the start; the log holds two restart lines; no "launched with ... -shutdown" line; nothing of the prefix left running 30 s after the message; no lock, no crash marker. James then dismisses the question, and the name is put back | **Yes.** It is the measured failure run again, and the only place the real Steam, not a stub, shows that no client comes of the call |
| RL3 | The name back; one ordinary start of Surviving Mars, and `boot-verify.sh` (detached, with a log) for Cities: Skylines II | Surviving Mars: no hint line, no restart line, menu, saves uploaded. Cities: Skylines II: `VERDICT: PASS`, `GRACEFUL: yes`, "Residual Steam-family processes in this prefix: 0" | Yes for boot-verify (its start and its shutdown were both rewritten and no rename can put the question to that wrapper's engine); the ordinary Surviving Mars start may be RL1's own second start |

Not a live step: the case of 3.3 (Steam leaving between the test and the call). It cannot be timed by hand;
RT3 holds it.

If RL1 fails because the answer does not release the second Steam: stop. The restart then brings the game up
only for an answer given while no Steam waits, and decision 1's premise is wrong; that goes back to James with
what was seen, before anything is merged.

## 9. Exit criteria

1. The verdict line of `check it` on this file, and its corrections folded.
2. RT1 to RT5 green; every new mutant (feedback 19 to 26 and the rewritten 14 to 16; parity 29 to 36 and the
   rewritten 17, 18, 22, 24; the new file's 1 to 8) applied to the real files and seen red, then green again.
3. The two `launch-feedback` blocks equal byte for byte (rule 1).
4. RL1, RL2 and RL3 passed, their outputs recorded at this file's foot.
5. `CHANGELOG.md` (Unreleased), both `INSTALL.md`, `GOTCHAS.md` and both launchers' headers say what RL1 and
   RL2 showed and no more; the section `## v0.3.0` is byte for byte what it was (`git diff` over its lines
   is empty).
6. No line of `boot-verify.sh` or of either licence probe changed.
7. Issue #32 carries a comment naming what was built and what is still open; it is open.
8. `release` has not moved.

## 10. Rollback

Nothing here writes a file outside the repo, changes a format, or touches a wrapper. Before the merge: drop
the branch. After it and before `release` moves: `git revert` of the branch's commits (or of the merge), then
both setups on each Mac that ran the branch's launchers, which put `main`'s back; `boot-verify.sh` after. A
Mac that keeps the new launcher meanwhile is not harmed by it: with no question from macOS it starts Steam
once, as before. After `release` has moved: a successor release, by the repo's release rules.

## 11. Decisions for James

Only one is open.

- **RD1. The line at a restart.** Recommended: "Starting Steam again. If macOS asks a question, answer it…".
  It is what the player reads at the moment it matters, in the window and as a notification. The other way
  is a line that says why ("Steam stopped waiting. Starting it again…"), which names nothing the player can
  do.

Settled here, for the check to challenge and not for James to decide: 60 s, two restarts, 60 s left, no sweep
of webhelpers, the final messages unchanged.

## Review log

Key paths: `cities-skylines-2/launchers/launch-cs2-dxmt11.sh`, `surviving-mars-relaunched/launch-relaunched.sh`,
`common/test-launch-feedback.sh`, `common/test-launcher-parity.sh`, `cities-skylines-2/scripts/boot-verify.sh`,
`surviving-mars-relaunched/tools/licence-wait-probe.sh`, `cities-skylines-2/scripts/licence-wait-probe.sh`,
`common/launch-progress.swift`, `CHANGELOG.md`, both `INSTALL.md`, `cities-skylines-2/GOTCHAS.md`.

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
