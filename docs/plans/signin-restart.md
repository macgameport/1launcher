# The sign-in wait starts Steam again when Steam gives up, and no `-shutdown` goes to a Steam that is not there

Written 2026-11-24 on the branch `signin-restart`, cut from `built-in-update` at `8b1e71e`. Issue #32 (its
second and third subjects; its first, keeping Steam from asking at all, is not here).

> **Status: check-it'd 2026-11-24 — build-ready-with-fixes (pass 1, folded); R0b, the probe, ran the same night: `RELEASED`, so the build goes on.**
> The measurements in section 3 were taken on scratch copies under `/tmp/sr-plan/` with stub programs: no Wine,
> no Steam, no game was started for them. The corrections of the check are folded into the sections below and
> listed in "Review corrections" at the foot.

> **🔧 As-built (2026-11-24): partial — R0b passed; R1 to R4 built on the branch `signin-restart` (pushed, not merged,
> not in `release`); RL2 passed on the Studio the same night; RL1 and RL3 are to come.** Built by a builder agent from this plan; both launchers' changes
> read by the session, and the gates run again by it: all 47 test files, and all 75 mutants of the three files of
> section 7 red (`test-launch-feedback.sh` 1 to 28, `test-launcher-parity.sh` 1 to 36, `test-launcher-steam.sh`
> 1 to 11). Deviations:
> - **`start_steam` with no connection log prints one line** of bash's ("No such file or directory"): the failed
>   `<` is reported before its `2>/dev/null` applies, as on the same line before this plan. RT3 asserts that one
>   line and nothing else.
> - **Feedback mutant 17's case runs 300 failing looks, not 100,000:** with the new `10#` line that mutant waits
>   without end, where it used to end on an error.
> - **One test file outside this change is intermittent:** `common/test-launcher-window.sh`, "--start of an app
>   still alive", failed in 2 of 10 runs one after another with `open`'s error -600, and in none of 6 at once. The
>   file and the window are the update branch's, unchanged. Not fixed here.
>
> **Verify against:** both launchers (the `launch-feedback` block, `start_steam`, the piece between
> `# >>> stop-steam` and `# <<< stop-steam`), `common/test-launch-feedback.sh`, `common/test-launcher-parity.sh`
> (rules 10 and 12), `common/test-launcher-steam.sh`.

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

- **An answer within about nine minutes** of the start brings the game up from that start, with nothing for
  the player to do but answer.
- A question never answered ends the launch once, with today's message, after 600 counted seconds, which are
  about 10 min 20 s on the clock (3.1). **Surviving Mars then leaves no Steam of the prefix running**
  (`stop_steam`). **Cities: Skylines II's `die` sends nothing to Steam, as today**, and no stop is added
  there: its third Steam leaves by itself about three lifetimes and 30 s after the start, which at the 189 to
  192 s measured falls on either side of the message, so it may still be up for some seconds after it.
- Neither launcher ever runs the call in the foreground, and neither sends it when no Steam of its prefix is
  up. If Steam leaves between the test and the call, the launcher is held 60 s, not three minutes, and the
  client the call became is ended. Where today the launcher waits on the call for as long as the call blocks,
  it now waits 60 s (4.4).
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
  ended with 0; 576 s to 600 s ended with 1. The promise made everywhere is therefore "an answer within about
  nine minutes", not ten.
- **The model's seconds are counted, not clock seconds.** The wait counts 3 s per look and does not count the
  look itself, which costs 23 ms with no Steam and 77 ms with one (the check's measure, `lsof` per
  `steam.exe`): 200 looks are at least 615 s, and the message of a wait that runs out comes about 10 min 20 s
  after the start. RL2's window is set by that.
- **With `L1_SIGNIN_SECS=120`: no restart for any lifetime.** 41 runs (Steam leaving after 3, 6, ... 120 s,
  and never): 0 with a restart line, and the three compared with today's call ended at the same second (120,
  42 and 102 s). The smallest limit at which any lifetime gives a restart is 132 s when Steam is seen at the
  first look (20 looks seen, the fifth look without it at 72 s, 60 s left); the model, where Steam is first
  seen at the second look, gives 135 s.
- **The existing tests with the new block.** The function of 4.1 put into scratch copies of both launchers:
  `test-launch-feedback.sh` 88 of 88 and `test-launcher-parity.sh` 61 of 61 still pass, both launchers parse.
  **Three existing mutants no longer bite:** 14 and 15 are refused (their lines changed), and **16 applies by
  its proof text and stays green**, because its `sed` no longer matches the line while the text it greps for
  is a prefix of the unchanged line. Step R1 rewrites the three (RT1 says how).
- **A limit with a leading zero.** `L1_SIGNIN_SECS=090` passes the `case` and reaches `$((limit - t))`, where
  bash prints "value too great for base" and abandons the whole list `signin_wait ... || die`: neither the
  wait's 1 nor the `die` happens, and the launcher goes on with no Steam (the check reproduced it). 4.1 makes
  the value a decimal number first.

**3.2 Starting through a function named in a word** (`start-test.sh`, with a compiled C program in place of
`wine64`, because any script would itself be started by a system program). A function that holds
`"$WINE" ... >/dev/null 2>&1 & disown`, called as `"$4"` from inside `signin_wait`:

- the child got `DYLD_FALLBACK_LIBRARY_PATH` unchanged, at the first start and at the restart;
- the same program started with `env`, with `nohup` or through `/bin/bash -c` got it **stripped**, all three;
- the function's `BEFORE=` was seen by the caller, the marker file it removes was gone after each call, the
  shell's job table was empty, and bash printed no line of its own.

**3.3 The call, bounded** (`stop-test.sh`, `stop-test2.sh`, and for the form of 4.4 `stop-test3.sh`; real
seconds). The stub `wine64`: with a stub Steam up it forwards the call, Steam goes some seconds later, and the
call itself returns when the case says; with none up it becomes a client that stays, seen as `steam.exe` from
its fourth second on, or never. The stub `wineserver -k` ends the stub Steam and a client that is seen as one;
it does not end a call that is not.

First, why the test alone is not enough (the forms the first draft compared):

| Form | Case | Time | Left running afterwards |
|---|---|---|---|
| today's (`stop_steam` as it is) | no Steam up; the client stays 40 s (181 s live) | 42 s | 0 |
| the test, and the call in the background, nothing more | Steam leaves between the test and the call | 2 s | **1: the client** |

That form returns at once because its first look for `steam.exe` comes before the client holds the prefix,
and then nothing ends the client. So the bound needs the call's own process id.

The form of 4.4 (the second look, 60 s for the call's process, then the 20 looks):

| Case | Time | Calls | `wineserver -k` | Left at the return | 3 s later |
|---|---|---|---|---|---|
| no Steam up | 3 s | 0 | 0 | nothing | nothing |
| a Steam up; the call forwarded and back at once; Steam gone 1 s later | 5 s | 1 | 0 | nothing | nothing |
| a Steam up, the first look false | 5 s | 1 | 0 | nothing | nothing |
| Steam leaves between the test and the call; the client is seen as Steam after 4 s | 63 s | 1 | 1, and it ends the client | nothing | nothing |
| the same; the client is never seen as Steam | 63 s | 1 | 1, which does not end it | the call's process, with the TERM sent | nothing |
| a Steam up that ignores the call (the call dies at once) | 24 s | 1 | 1 | nothing | nothing |
| the call blocks 40 s while Steam needs 40 s | 43 s | 1 | 0 | nothing | nothing |
| the call blocks for ever; Steam stays | 63 s | 1 | 1 | the call's process, with the TERM sent | nothing |
| the call blocks for ever; Steam gone after 5 s | 63 s | 1 | 1 | the call's process, with the TERM sent | nothing |

Where the call's process is "left at the return", its TERM had been sent and it was gone at the next look, 3 s
later (bash runs a TERM trap when its current `sleep` ends). In the last row `wineserver -k` runs although
Steam is gone, because the call is still there: that is the rule of 4.4, step 5, and costs nothing. `kill -0`
on an exited, disowned child: false.

## 4. Design

### 4.1 The restart is in the block: a fourth word

```bash
signin_wait() {   # <step> <test> [<alive> [<start>]]: wait for Steam's sign-in; 0 = signed in, 1 = not
  local limit="${L1_SIGNIN_SECS:-600}" t=0 hinted=0 seen=0 gone=0 lived=0 again=0
  case "$limit" in ''|*[!0-9]*|????*) limit=600 ;; esac
  limit=$((10#$limit))
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
that died" goes). `limit=$((10#$limit))` stands after the `case`, which has already let through nothing but
one to three digits: `090` is 90, where without it the new `$((limit - t))` is an error that ends the launch's
sign-in step without a word (3.1).

**Why in the block.** The rule for when to start again is the same for both games and is the part that can
be wrong; it belongs where rule 1 keeps one text and where `test-launch-feedback.sh` already drives it with
stubs. What differs between the launchers is one command line, and that stays in each launcher (4.2).

**The rules, each with its reason.**

| Rule | Value | Why |
|---|---|---|
| Steam counts as gone | five looks in a row without it (15 s), as today | When Steam's updater replaces it, nothing holds the prefix for a moment. That gap was seen once, and it was shorter than one of the installer's polls of 5 s (`cities-skylines-2/GOTCHAS.md`, 2026-11-10); the installer waits three polls, and 15 s is that margin. A gap shorter than it changes nothing, so the updater's own restart is never doubled |
| It is started again only if it had been seen for | 20 looks (60 s) since it was last started | A Steam that crashes at once fails the same way again. A sign-in with no question took 8 to 30 s on every start measured; the Steam that gave up at the question had been seen for 189 s. 60 is between, on the far side of the IPv6 wait (23 to 27 s to the logon call) |
| At most | 2 restarts in one wait | With Steam leaving after about 3 min, two restarts fill the ten minutes (3.1). The number bounds a Steam that leaves every minute or two for a reason nobody has seen: without it, seven starts in ten minutes |
| Not when less than | 60 s of the wait are left | A start needs up to about 30 s to sign in; a Steam started later than that would be left signing in while the launcher gives up. Then the wait ends at once, with 1, as today: nothing is gained by waiting on with no Steam. It is also what keeps the instruments as they are (4.6) |
| After a restart | `seen` stays 1, the counts of `gone` and `lived` start at 0 | So a Steam that does not come up within 15 s of being started again ends the wait. Live, a Steam held the prefix within one look of its start both times: the first at 3 s, and the client of the call at 204 s, the look at which the call was made. `seen=0` would wait the rest of the ten minutes for nothing: the reason a first Steam is waited for (macOS's "Verifying..." sheet on a wrapper not opened for long) does not hold three minutes into a launch. **What is left then:** Surviving Mars runs `stop_steam`, which sends the call only if a Steam has come up meanwhile and sweeps the family either way. Cities: Skylines II dies and sends nothing: a Steam that comes up later than those 15 s stays up, and the next launch meets it as "Steam is already running" (and dies with "Steam is running but not logged in" if it never signed in), as today after any failed wait |
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
start_steam() {   # start this prefix's Steam in the background: the first start, and the sign-in wait's restarts
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

The comment on the function's first line must not hold the word `signin_wait`: parity rule 10 counts every
line outside the block that holds it, comments on code lines included, and wants one. Both launchers say "the
sign-in wait's restarts". The function stands before the `BEFORE=` line of `:304`.

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
  if steam_exe_up || { sleep 1; steam_exe_up; }; then   # with no Steam of this prefix up, the call itself becomes a Steam client (issue #32)
    "$STEAM_WINE" "$STEAM" -shutdown >/dev/null 2>&1 & _sd=$!; disown
    for _ in $(seq 1 60); do kill -0 "$_sd" 2>/dev/null || { _sd=""; break; }; sleep 1; done
    [ -z "$_sd" ] && for _ in $(seq 1 20); do steam_exe_up || break; sleep 1; done
  fi
  { steam_exe_up || [ -n "$_sd" ]; } && "$ENGINE/bin/wineserver" -k >/dev/null 2>&1
  sleep 2
  [ -n "$_sd" ] && kill -0 "$_sd" 2>/dev/null && kill "$_sd" 2>/dev/null   # the call still there: plain TERM, never -9
  _strays="$(steam_family)"
  [ -n "$_strays" ] && kill $_strays 2>/dev/null   # plain TERM, never -9
}
```

In order:

1. **The test, with a second look.** One false look must not leave a running Steam without its call (a look
   is `pgrep` and `lsof`, and a Steam being replaced by its updater is missed by one). So a false first look
   is followed, 1 s later, by a second.
2. **The call, in the background, its process id kept.**
3. **The call's own process is given 60 s.** Nobody has measured whether a forwarded call returns before the
   running Steam is gone or only after it, and `cities-skylines-2/EXPERIMENTS.md:60` records one that blocked
   past three minutes. Today the launcher waits on the call without limit, and 20 s for Steam follow. 60 s
   and not 20: the case the limit exists for (Steam leaving in the milliseconds between the test and the
   call) is rare, and ending a Steam that is still uploading saves is worse than a rare hold of a minute.
   Steam's own log has "Shutdown" within 5 s of the upload on the seven Surviving Mars exits of 2026-11-24,
   and within 1 to 2 s on fourteen of Cities: Skylines II.
4. **Only after that process has gone, today's loop: up to 20 looks for `steam_exe_up` to turn false.** If
   the call is still there after its 60 s, the loop is skipped.
5. **`wineserver -k` when Steam is still up or the call is still there**, then `sleep 2`, then a plain TERM
   to the call's process if it is still alive, then the sweep of strays, as today.

`kill -0` on a child that has exited and was disowned is false in bash 3.2.57: the shell reaps it and no
zombie answers (measured by both lenses of the check and again on the stub, 3.3). The loop of step 3 rests on
that.

Cities: Skylines II, after the game (`:443-447`): the same stages inline, between the markers. The piece
**begins with `_sd=""`** (the launcher runs under `set -u`, and the lines after the `if` read it), then the
same `if` with `"$WINE"`, its two loops written with `for i in`, and an `else` that prints
"  Steam is not running: nothing to shut down." The words "(steam -shutdown failed; falling back)" go: a call
in the background has no exit code to read, and the line the fallback prints (`:451`) says the same. Its
fallback (`:450-457`) is entered on `if steam_exe_up || [ -n "$_sd" ]; then`; the sweep of strays
(`:461-467`), the nudge of a lingering `wineserver` (`:469-472`) and the count of what is left (`:473-474`)
stay as they are, with one line added before the sweep:
`[ -n "$_sd" ] && kill -0 "$_sd" 2>/dev/null && kill "$_sd" 2>/dev/null`.

**Cities: Skylines II has no wait for the cloud upload before the call** (Surviving Mars has one,
`launch-relaunched.sh:520-527`): its call goes out the moment the game's process has ended, as today. This
plan does not add one; the 60 s of step 3 are what keeps the new code from being harsher than today's on a
Steam that is still uploading.

Which places need the test: **both**, at every use. Surviving Mars's `stop_steam` is one function, so its four
callers get it at once; Cities: Skylines II has the one place. Its failed sign-in (`:322`) sends nothing
today and still sends nothing.

**Is a bound needed as well as the test? Yes, and it needs the call's own process id** (3.3). Between the
test and the call Steam can leave; the call then becomes a client that the first look does not yet see, and a
form that only looks for `steam.exe` returns at once and leaves it. **The honest consequence of the bound:**
where the call blocks while Steam is still up, today's launcher waits as long as the call does, and the new
one ends the wine session after 60 s. RL3 records, for both games, the seconds from the call to its process
leaving and to `steam.exe` gone, so that the 60 is judged against what the real Steam does. `wine64` in all
three wrappers on the Studio is a Mach-O program, not a script, so `$!` is the process that becomes
`steam.exe`.

Each launcher's stopping code gets a pair of markers, `# >>> stop-steam` and `# <<< stop-steam`: around the
function in Surviving Mars; in Cities: Skylines II the opening marker stands after the
`echo "Game exited ..."` line and the closing one after the `echo` of the count, before the closing `note`. A
test cuts the piece out by them. The two texts are **not** made the same bytes: they differ in `"$WINE"` and
`"$STEAM_WINE"`, in how `wineserver` is reached, and in what they print, and making the shutdown one shared
block is unification work, not this plan's.

### 4.5 What the player reads

- **At 45 s:** the existing line, unchanged.
- **At a restart:** `Starting Steam again. If macOS asks a question, answer it…` (58 characters; the window's
  label takes 62), sent as a step with the caller's number, so the progress window shows it and, with no
  window, it is a notification. Something must be said: the log of a launch that started Steam three times
  has to show it, and the window must not look stuck for ten minutes. It repeats the instruction because the
  window shows only the last line, and at that moment the instruction is the one thing that helps. At most
  two such lines in a launch. **If R0b shows that macOS puts the question a second time for the second Steam,
  this line and the guides must say so** ("macOS may ask again: answer it again"), within the 62 characters;
  the wording then goes to James with RD1.
- **The final message:** both launchers' words stay as they are. "If macOS asked a question ..., answer it and
  start the game again" is still what to do, and after an answer the next start ran on both Macs. The first
  sentence of each is quoted by tests and a probe.
- The progress window stays up while the log grew within 900 s (`common/launch-progress.swift:65-73`); its
  comment names the wait after the hint line as the longest silence, a little over 9 minutes, and that is
  still so for a Steam that stays up (an expired token). No change there.

### 4.6 The instruments end as today

No line of `boot-verify.sh` or of either `licence-wait-probe.sh` changes. With 120 s there is no restart for
any lifetime of Steam (3.1: 41 of 41, and the arithmetic: a restart needs 132 s at the least). What does
change for them is `stop_steam` after a failed wait in the Surviving Mars probe: where it waited on the call
without limit and then 20 s, it now waits at most 60 s for the call and then 20 s, about 85 s in all, and
120 s and 85 s are inside the probe's 300 s. `boot-verify.sh --selftest` judges logs and starts nothing.

### 4.7 Words elsewhere

| Where | What changes |
|---|---|
| `CHANGELOG.md`, `## Unreleased` | a new paragraph, drafted in section 6 (R4). **The section `## v0.3.0` is not touched:** it is published, it says what `v0.3.0` does, and that is still true of `v0.3.0`. The rule for a wrong release (a first line naming its successor) is for a release that is wrong, and this one is not |
| `surviving-mars-relaunched/INSTALL.md:165-168`, `cities-skylines-2/INSTALL.md:516-519` | the sentences from "Answered within about a minute" on, rewritten from what R0b, RL1 and RL2 show; draft in section 6. They name the version, as the built-in update's guides do: before `v0.3.1` the start ended after about three minutes |
| `cities-skylines-2/INSTALL.md:553` (Troubleshooting, "Steam did not auto-login") | "Steam itself gives up after about three minutes and the launcher then stops" becomes: the launcher starts Steam again, and stops after ten minutes |
| `cities-skylines-2/GOTCHAS.md:2611-2644` | "Not built: ..." becomes what was built, with this plan's name; a line that a call put in the background is not bounded unless its own process is waited for (3.3), and one that a limit with a leading zero is an error in arithmetic; the dated measurements stay |
| both launchers' headers (`launch-cs2-dxmt11.sh:22-23`, `launch-relaunched.sh:66-67`) | one clause: within that time a Steam that leaves is started again, at most twice |
| root `CLAUDE.md`, the Layout table's `common/` row | `test-launcher-steam.sh` named, with what it tests (each launcher's start of Steam and its stopping of it) |
| root `CLAUDE.md`, "In progress" | one sentence for this plan, at each state it reaches |
| `surviving-mars-relaunched/README.md:102` | nothing: what it says of `L1_SIGNIN_SECS` stays true |
| `docs/plans/wrapper-names.md` | nothing: a dated record |

## 5. Not in this plan

- Keeping Steam from asking for the microphone (issue #32's first subject; it needs a probe).
- Answering the question for the player, or seeing whether one is on screen.
- `S734M.app`: it has no wait and sends no call.
- One shared block for stopping Steam in both launchers.
- What Cities: Skylines II does with a Steam that is up and not signed in when its wait fails (it leaves it,
  as today; section 2).
- A wait for the cloud upload before Cities: Skylines II's call (4.4).
- A sweep of leftover webhelpers before a start.
- A connection log that Steam has rotated during the wait (`BEFORE` then points past its end): as today.
- The update block and the installer: neither starts Steam through this code.

## 6. Steps

All on the branch `signin-restart`. Each step from R1 on ends with its tests green and its new mutants applied
and seen red, then put back and seen green.

- **R0. Before code.** `check it` on this file is done (pass 1, the review log). Before R0b:
  `git log b88112c..HEAD` over the key paths of the review log; if `built-in-update` or `main` moved under
  them, read the cited lines again.
- **R0b. The probe of RL1's premise, before any code** (on James's word, with him at the Studio, nothing of
  Wine running on either Mac). Nobody has seen whether an answer releases a Steam other than the one the
  question was first put for; the restart is worth building only if it does. The script is written and has
  not been run: `probe-issue32/probe-restart.sh <a name never used>` in the Surviving Mars workspace. It
  starts Steam only, no game and no launcher: it renames the Surviving Mars wrapper to the fresh name, holds
  the launch lock, starts Steam, lets that Steam leave by itself (about 3 min), starts a second 15 s later,
  and James answers the question 30 s after that. It puts the lock and the name back and prints one
  `VERDICT:` line and whether macOS put the question a second time. (It reads `common/wrappers.sh` from the
  worktree it names in its `REPO=` line: read that line before the run.) What each verdict means:

  | Verdict | Then |
  |---|---|
  | `RELEASED` | the second Steam signed in after the answer: R1 begins |
  | `NOT-RELEASED` | **stop: no code.** Decision 1's premise is wrong as built here; back to James with what was seen (the restart would then help only for an answer given while no Steam waits) |
  | `SIGNED-IN-UNANSWERED` | the second Steam signed in with the question still open: the restart works without the answer. Recorded, and R1 begins; the words of 4.5 and R4 are then drafted again from it before RL1 |
  | `VOID` | a precondition failed (its line says which): put right, and run again with another fresh name |

  **If macOS asked twice**, 4.5's line and both guides say so, and RL1's pass condition counts two answers.
  The verdict, the two times and the "asked again" line are recorded at this file's foot before R1.
- **R1. The block.** `signin_wait` as in 4.1, the same bytes in both launchers, its comment rewritten.
  `test-launch-feedback.sh`: the new cases (RT1) and mutants 19 to 28; **mutants 14, 15 and 16 rewritten for
  the changed lines, 16 with a proof text the unchanged line does not satisfy** (3.1; RT1 has the three).
- **R2. `start_steam` and the call lines** in both launchers (4.2). `test-launcher-parity.sh`: rule 10's
  pattern for the call line takes the fourth word, its mutants 17, 18, 22 and 24 follow the new line; the new
  rule 12 and mutants 29 to 36 (RT2).
- **R3. The call** (4.4) in both launchers, with the markers. The new `common/test-launcher-steam.sh` (RT3).
- **R4. The words** (4.7), as drafts where they depend on the probe and the live steps:
  - `CHANGELOG.md`, Unreleased: "**A start no longer ends because a question from macOS was left open**
    (docs/plans/signin-restart.md). After a wrapper is renamed macOS asks once more whether wine64 may use the
    microphone, and Steam gives up waiting for the answer after about three minutes. The launcher now starts
    Steam again, at most twice, and says so, so an answer within about nine minutes brings the game up from the
    same start. Left unanswered, the start ends after a little over ten minutes with the message it had. Before,
    Surviving Mars's message came about six and a half minutes after the start, three of them spent in a
    shutdown call that had itself become a Steam; that call is no longer sent when no Steam is running."
    Cities: Skylines II's earlier time, about three and a half minutes, follows from its code and was not
    measured, so the notes do not give it.
  - both `INSTALL.md`: "Answer it, either way. From v0.3.1 an answer within about nine minutes still brings
    the game up: Steam itself gives up after about three, and the launcher starts it again and says so. If the
    start ends with "..." all the same, answer the question and start the game again."
- **R5. The whole suite.** Every tracked test file (46 today, 47 with the new one), run directly, never under
  `nohup`, each with its real exit code. The identifier and link checks.
- **R6. The live steps** (section 8), on James's word, then the words of R4 made to say what was seen, the
  as-built header on this file, `CLAUDE.md`, and a comment on issue #32 (written with "refs", never a closing
  word: the issue stays open for its first subject).

The merge follows the built-in update's: this branch goes into `built-in-update` or into `main` after it,
whichever James names; it does not move `release`.

## 7. Tests

The numbers follow each file's highest today: `test-launch-feedback.sh` 18, `test-launcher-parity.sh` 28
(rules: 11). The new file starts at 1. The check's builder built all of this in a scratch clone and saw
every gate green and every mutant red; what it had to work out for itself is written into the rows.

| ID | File | What is asserted | Mutants (each applied, seen red, put back) |
|---|---|---|---|
| RT1 | `common/test-launch-feedback.sh`, for each launcher's block, with a fourth word that counts its calls | Seen 20 looks, gone 5: the start word is called once at that look, one restart line as step 4 (the test's number, neither launcher's), the wait goes on; then signed in: 0. Seen 19 looks, gone 5: 1 at once, no call. Three departures of a Steam seen 20 looks each: two calls, 1 at the third. With 57 s left: no call, 1 at once; with 60 s left: a call. After a restart, never seen for 5 looks: 1, one call. **After a restart, first seen at the fourth look: the wait goes on.** After a restart, seen 10 looks and gone: 1, no second call. The start word returning 1: 1 at once, after its one line. No fourth word: every existing `alivecase` result unchanged, and the departure case ends with 1 and no restart line. `L1_SIGNIN_SECS=120`, Steam leaving after each of 1 to 40 looks: no call in any. **`L1_SIGNIN_SECS=090`, never signed in: 1 after 90 s, with and without the third and fourth words, and nothing on stderr.** The restart line is a step: one notification with no window, none with it. Nothing on stderr in any case | 19 the lifetime test dropped; 20 the count of restarts dropped; 21 the test of the time left dropped; 22 `seen` set to 0 at a restart; 23 `lived` not set to 0 at a restart; 24 the start word's failure ignored; 25 the restart line dropped; 26 the restart made when no fourth word is given (`-n` test dropped); **27 the `10#` dropped (`limit=$((limit))`); 28 `gone` not set to 0 at a restart.** Rewritten: **14** the line `elif [ "$seen" = 1 ]; then` made `else`, proved by that line's absence; **15** `if [ "$gone" -ge 15 ]; then` made `if false; then`; **16** `gone=0; ` taken out of the line that begins `if "$3"; then seen=1;`, proved by the text `if "$3"; then seen=1; lived=$((lived + 3))`, which the unchanged line does not hold |
| RT2 | `common/test-launcher-parity.sh`, rule 10 (changed) and rule 12 (new) | Rule 10: the call is `signin_wait <number> <function> steam_exe_up start_steam \|\| ...`, and it stays the launcher's only line outside the block that holds the word `signin_wait` (so `start_steam`'s comment says "the sign-in wait's"). Rule 12, per launcher: `start_steam` is defined once, outside the block; the launcher holds exactly one line, comments apart, with `-silent -no-cef-sandbox`, it ends `>/dev/null 2>&1 & disown`, and it is the last line of that function; before it in the function stand a `BEFORE=$(wc -l < "$CL" ...` line and the `rm -f` of the `.crash` marker, once each; no line of the function, comments apart, holds `nohup`, `setsid`, `env `, `exec ` or `bash -c`; a line that is `start_steam` alone stands once, between the step line "Starting Steam and signing in…" and the `signin_wait` call; the restart text in the block (the line `step "$1" "..."` at ten spaces) is one plain literal of at most 62 characters and the block holds "Starting Steam again" once; the launcher holds one `# >>> stop-steam` and one `# <<< stop-steam`; exactly one line with `-shutdown`, comments apart, in the whole launcher, inside the markers, ending `>/dev/null 2>&1 & _sd=$!; disown`, and directly under the line `if steam_exe_up \|\| { sleep 1; steam_exe_up; }; then` | 29 one launcher's call without the fourth word; 30 `nohup` put before the start line in one launcher; 31 the `rm -f` of the marker taken out of one function; 32 the `BEFORE=` line taken out of one function; 33 a second start line outside the function in one launcher; 34 the restart text made 63 characters, in both; 35 the `& _sd=$!; disown` taken off one launcher's call (the foreground again); 36 one launcher's `if` over the call made `if true; then`. Following the new call line: 17, 18 and 22 with the fourth word in their patterns; **24 the third word taken out and the fourth left** (`signin_wait 1 signed_in start_steam \|\| `) |
| RT3 | new `common/test-launcher-steam.sh`: each launcher's `start_steam` and its `stop-steam` piece, cut out and run in a fresh bash under `set -u` with stubs. `wine64` records its arguments; given the call with a stub Steam up it ends that Steam (or not, or later, as the case says) and returns when the case says; with none up it becomes a client that waits on a pipe nobody writes to and records a TERM if one is sent. `wineserver` records its arguments and `WINEPREFIX` and how many sleeps came before it; `-k` ends the stub Steam and a client that is attributed, and **never the client that is not**. `sleep` is **recorded and cut to 0.05 s**, so the 60 and the 20 are counted in recorded sleeps and the call in the background gets to run. `steam_exe_up` and `steam_family` are the harness's: the stub Steam is a file; an attributed client is seen as `steam.exe` from a later look on; **the family never lists the client that is not attributed**. `pgrep` finds nothing. A watchdog of 10 s fails any case that does not return and ends what it left | `start_steam`, at a first and a second call and with no connection log yet: returns 0, one child with Steam's path and the two options as three arguments, the marker gone, **`BEFORE` equal as a number** to the log's line count at that moment (`wc -l` pads it), no job left, bash prints nothing. Stopping: no Steam up: no call, no `wineserver -k`, the recorded sleeps are the 1 of the second look and the 2, returns. One up: one call, the 20 looks begin only after the call has returned, returns once Steam is gone, no `wineserver -k`. One up, the first look false: one call all the same. One up that ignores the call: `wineserver -k` once for this prefix after 20 recorded seconds. The call blocks 40 recorded seconds while Steam needs 40: no `wineserver -k`. The call blocks for ever with Steam up: `wineserver -k` once after 60 recorded seconds, and the call's TERM recorded. **Race (a), Steam leaves between the test and the call and the client is attributed: the piece returns after 60 recorded seconds, `wineserver -k` once, the client ended by it. Race (b), the client is never attributed: `wineserver -k` once (the call is still there) and it does not end the client; the client's TERM trap is recorded.** A leftover webhelper stub gets a TERM and never a KILL. Cities: Skylines II's piece prints its "nothing to shut down" line when none is up, and its count line always; neither piece reads an unset variable | 1 the test over the call dropped (the call sent with none up); 2 the call put in the foreground (the watchdog); 3 the call's own process no longer waited for: the loop of 60 ends at its first look, so in race (a) `wineserver -k` comes with no recorded wait and before the client is attributed; the TERM still reaches the call, so the mutant is judged on the recorded sleeps; 4 the `wineserver -k` fallback dropped, **judged on race (a)**; 5 the TERM to the call's process dropped, **judged on race (b)**; 6 the sweep of strays dropped; 7 `rm -f` dropped from `start_steam`; 8 `kill` made `kill -9` in the sweep; 9 the second look dropped from the test over the call; 10 the 60 made 20 (the case of 40 and 40 then gets a `wineserver -k`); 11 `_sd=""` dropped from the head of Cities: Skylines II's piece (unset variable with no Steam up) |
| RT4 | every tracked test file | exit 0, with real exit codes; among them `test-mod-notes.sh` (it finds the "Starting Steam and signing in…" step line by its text), both `test-update-check.sh`, `test-licence-wait-probe.sh`, `test-launch-progress.sh`, Surviving Mars's `test-setup.sh` (it compares the installed launcher with the repo's, byte for byte) | the existing ones are not run again, except those this plan rewrites |
| RT5 | `bash cities-skylines-2/scripts/boot-verify.sh --selftest` | every judge branch as before | none |

What RT3 cannot show, and RT2's source gate stands for: that the child keeps `DYLD_*`. A test would need a
compiled program (any script is started by a system program, which strips them); 3.2 measured it once, and
rule 12 forbids the words that break it, as `test-make-steam-shortcut.sh` does for the store's start.

## 8. Live steps (on James's word; the Studio; nothing of Wine running on the MacBook meanwhile)

R0b (section 6) comes before all of them and before any code. Before RL1: both setups from the branch, so the
installed launchers are the branch's (`--check` first; no rename is named). Each rename is by hand, of the
Surviving Mars wrapper, to a name it has never had (R0b's included), with nothing of Wine running, and is put
back afterwards; a name that has been answered is not asked again, so R0b, RL1 and RL2 need three different
names. Outputs in `signin-restart-rl/` in the Surviving Mars workspace; the watch is `probe-issue32/run.sh`'s
(the processes of the prefix every 3 s, the launcher's last line, the three logs afterwards).

| Step | What | Pass | Essential? |
|---|---|---|---|
| RL1 | Attended. The game started from its app; James leaves the question until the window has shown "Starting Steam again..." (a little after 3 min 20 s), then answers it (twice, if R0b showed that macOS asks again) | The game reaches its menu **from that start**; the launcher's log holds the hint once and the restart line once or twice; `bootstrap_log.txt` holds no "launched with ... -shutdown" line since the start; after the game is closed, saves uploaded, Steam down, no lock, no crash marker. Recorded besides: whether macOS put the question again for the second Steam (the privacy log), how long after the answer the logon came, and what of the first Steam's family was there at the restart | **Yes.** R0b has shown the premise with Steam alone; this shows the decided behaviour with the launcher, the progress window and the game |
| RL2 | Unattended, the question never answered (James away, as on 2026-11-24) | The launcher's "Steam did not sign in by itself" comes **between 9 min 30 s and 11 min 15 s** after the start, **and the second is recorded** (600 counted seconds are about 10 min 20 s, and `stop_steam` follows); the log holds two restart lines; no "launched with ... -shutdown" line; nothing of the prefix left running 30 s after the message; no lock, no crash marker. James then dismisses the question, and the name is put back | **Yes.** It is the measured failure run again, and the only place the real Steam, not a stub, shows that no client comes of the call |
| RL3 | The name back; one ordinary start of Surviving Mars, and `boot-verify.sh` (detached, with a log) for Cities: Skylines II; at each game's exit a watch of one look a second | Surviving Mars: no hint line, no restart line, menu, saves uploaded. Cities: Skylines II: `VERDICT: PASS`, `GRACEFUL: yes`, "Residual Steam-family processes in this prefix: 0". **Recorded for both games: the seconds from the call to its own process leaving, and from the call to `steam.exe` gone**, and whether `wineserver -k` ran. A call that outlives 60 s with Steam still up is a finding to fold before the merge, not a pass | Yes for boot-verify (its start and its shutdown were both rewritten and no rename can put the question to that wrapper's engine on the Studio); the ordinary Surviving Mars start may be RL1's own second start |
| RL4 | Optional, on the MacBook: Cities: Skylines II's wrapper renamed by hand to a fresh name, the game started, the question (if macOS puts one to that wrapper's engine there) left open | Recorded, not judged: whether macOS asks; if it does, the restart lines, the second of the "Steam did not auto-login" message, and whether a Steam of the prefix is still up after it and for how long (section 2) | No. It is the only way to see Cities: Skylines II's path at the question; nothing rests on it |

Not a live step: the races of 3.3 (Steam leaving between the test and the call). They cannot be timed by
hand; RT3 holds them.

If RL1 fails although R0b said `RELEASED`: stop, and back to James with what was seen, before anything is
merged.

## 9. Exit criteria

1. The verdict line of `check it` on this file, and its corrections folded (done: pass 1).
2. R0b run, its verdict `RELEASED` or `SIGNED-IN-UNANSWERED`, recorded at this file's foot with whether macOS
   asked twice, **before the first commit of code**.
3. RT1 to RT5 green; every new mutant (feedback 19 to 28 and the rewritten 14 to 16; parity 29 to 36 and the
   rewritten 17, 18, 22, 24; the new file's 1 to 11) applied to the real files and seen red, then green again.
4. The two `launch-feedback` blocks equal byte for byte (rule 1).
5. RL1, RL2 and RL3 passed, their outputs recorded at this file's foot, among them RL2's second and RL3's
   two times for each game.
6. `CHANGELOG.md` (Unreleased), both `INSTALL.md`, `GOTCHAS.md` and both launchers' headers say what R0b, RL1
   and RL2 showed and no more, and promise "an answer within about nine minutes" wherever they promise; the
   section `## v0.3.0` is byte for byte what it was (`git diff` over its lines is empty).
7. No line of `boot-verify.sh` or of either licence probe changed.
8. Issue #32 carries a comment naming what was built and what is still open; it is open.
9. `release` has not moved.

## 10. Rollback

Nothing here writes a file outside the repo, changes a format, or touches a wrapper (R0b and the live steps
rename one by hand and put it back). Before the merge: drop the branch. After it and before `release` moves:
`git revert` of the branch's commits (or of the merge), then both setups on each Mac that ran the branch's
launchers, which put `main`'s back; `boot-verify.sh` after. A Mac that keeps the new launcher meanwhile is
not harmed by it: with no question from macOS it starts Steam once, as before. After `release` has moved: a
successor release, by the repo's release rules.

## 11. Decisions for James

Only one is open.

- **RD1. The line at a restart.** Recommended: "Starting Steam again. If macOS asks a question, answer it…".
  It is what the player reads at the moment it matters, in the window and as a notification. The other way
  is a line that says why ("Steam stopped waiting. Starting it again…"), which names nothing the player can
  do. If R0b shows that macOS asks a second time, the line must say so, and the wording comes back with that.

Settled here and passed by the check: 60 s seen, two restarts, 60 s left, no sweep of webhelpers, the final
messages unchanged, 60 s for the call's own process.

## R0b on the Studio (2026-11-24, on James's word: "Yes, start it", with him there): `RELEASED`

`probe-restart.sh` in the Surviving Mars workspace's `probe-issue32/` (output `restart-2.log`). The wrapper was
renamed by hand to `mic-probe-1124c.app`, its launch lock held, Steam alone started with the launcher's environment
and start line, and the name put back.

| When | What |
|---|---|
| 21:05:23 | the first Steam started |
| 21:05:32 | its connectivity test began; macOS put the question, once |
| 21:08:34 | the first Steam gone by itself, 191 s after its start, the question still open |
| 21:08:46 | the second Steam started, the same way |
| 21:08:47 | its connectivity test began and stood |
| 21:09:25 | James answered (the one request, `authValue=2`) |
| 21:09:26 | the second Steam's test went on, one second later |
| 21:09:51 | it had signed in, 65 s after its start |

**So an answer releases a Steam that was started after the question was put, and macOS does not ask again.**
4.5's line needs no change. Afterwards: no Steam, no lock, no crash marker, three marked wrappers.

**A first run, the same evening, was VOID, and why matters to every instrument here.** Started from a Claude
session's shell (`restart-1.log`, `mic-probe-1124b.app`), Steam signed in at once: macOS's privacy log names the
session's program (`com.anthropic.claude-code`) as the responsible process, which already had the microphone, and
put no question. Started by an app of the form the games' apps have, `wine64` itself is responsible and is asked.
So **RL1 and RL2 start the game from its app and never from a session's shell**, and the boot-verify runs of W2
and W3 (`docs/plans/wrapper-names.md`), started from sessions, could not have met the question for Cities:
Skylines II: its first start from its own app after the rename may still ask.

## RL2 on the Studio (2026-11-24, 22:28): passed; the run was meant as RL1 (James: "Yes, start RL1") and nobody answered

Before it: both setups run from the branch at `d9fbc18` (exit 0 each, nothing renamed, 10 of 10 patch scripts), so
both installed launchers are the branch's; both stamps are on the line `checkout`, the state `manual`. Started with
`open` of the game's app, the wrapper renamed by hand to `mic-probe-1124d.app`. Output: `signin-restart-rl/rl1.log`.

| Seconds after the start | What |
|---|---|
| 10 | macOS put the question, once in the whole run; it was never answered |
| 48 | the hint |
| 192 | the first Steam gone by itself |
| 204 | "Starting Steam again…", the second Steam |
| 386 | the second gone |
| 399 | "Starting Steam again…", the third Steam |
| 581 | the third gone |
| 597 | "Steam did not sign in by itself": **9 min 57 s**, inside the window of 9 min 30 s to 11 min 15 s |

Two restart lines in the launcher's log, with the message after them. **No Steam client was started with
`-shutdown`** (0 in Steam's bootstrap log since the start; on 2026-11-24 at 01:16 there was one, and the message
came at 6 min 30 s with that client's three minutes in it). Nothing of the prefix was up at any look from the
message on (18 s of looks, then the watch's own count at 26 s), no lock, no crash marker, the name put back. The
wait ended before its ten counted minutes because the third Steam had left and two restarts had been used.

Not seen in this run: an answer. RL1 is still to come, under another name.

## Review corrections (check it 2026-11-24, pass 1)

Two lenses (correctness; risk) and a builder that built the plan in a scratch clone and ran every gate and
every mutant. Both verdicts: build-ready-with-fixes, no blocker. Each finding, and where it went:

| # | Finding | Where it went |
|---|---|---|
| 1 | `L1_SIGNIN_SECS=090` is an error in the new arithmetic and abandons the `signin_wait ... \|\| die` list: the launcher goes on with no Steam | 3.1 (last bullet); 4.1 (the code and the paragraph under it); RT1 (the case, mutant 27); 4.7 (GOTCHAS) |
| 2 | RL1's premise, that an answer releases a second Steam, has not been seen, and is cheap to see before any code | the status line; R0b (section 6) with its four verdicts; 4.5; 4.7; section 8 (the first paragraph, RL1); exit criterion 2; RD1 |
| 3 | 4.4's bound of 20 s on the call was unmeasured against a forwarded call that returns late (`EXPERIMENTS.md:60`), and one false look left a running Steam without its call | section 2 (third bullet); 3.3 (the table replaced, nine cases measured again); 4.4 (rewritten: the second look, 60 s for the call's process, then the 20 looks; `_sd=""` at the head of the inline piece; no cloud wait in Cities: Skylines II said); 4.6; section 5; RT2 (rule 12's line over the call); RT3 (cases, mutants 9 to 11); RL3 (the two times); exit criteria 3 and 5 |
| 4 | `start_steam`'s comment held the word `signin_wait`, which parity rule 10 counts | 4.2 (the code and the paragraph under it); RT2 |
| 5 | "No Steam of the prefix left running" was true of Surviving Mars only | section 2 (second bullet); 4.1 (the row "After a restart"); section 5; RL4 |
| 6 | 600 counted seconds are about 10 min 20 s on the clock; the promise was worded two ways | section 2; 3.1 (two bullets); R4's drafts; RL2 (the window, the second recorded); exit criteria 5 and 6 |
| 7 | The changelog draft counted Surviving Mars's three minutes in the call twice and gave Cities: Skylines II a time nobody measured | R4 |
| 8 | No case for a restarted Steam that is seen late, and no mutant for `gone=0` at a restart | RT1 (the case, mutant 28) |
| 9 | RT3's race was one case and could not tell the `wineserver -k` from the TERM; `sleep` and `BEFORE` under-specified; several things the builder had to find for itself | RT3 (races (a) and (b), mutants 3, 4, 5 judged as written there, `sleep` cut to 0.05 s, `BEFORE` as a number, what the stubs must not do); RT1 (how 14, 15, 16 are rewritten); RT2 (24; what rule 12 checks, line by line); 4.4 (where the markers and `_sd=""` stand) |
| 10 | Minor: 135 s is 132; the client of the call held the prefix at 204 s, at the look of the call; `:443-448`; the updater's gap; what is left when a restarted Steam is never seen; `kill -0` on an exited disowned child; `CLAUDE.md`'s `common/` row; an optional RL4 | 3.1 and 4.6; 4.1 (two rows); 4.4; 4.1 (first row); 4.1 (the row "After a restart"); 4.4 and 3.3; 4.7; section 8 |

**Folded differently from the finding, and why.** Finding 9 asked for race (b) to show "no `wineserver -k`".
With finding 3's rule (`wineserver -k` when Steam is up **or the call is still there**) the call is still
there in race (b), so `wineserver -k` does run, once; it does not end the client, and the TERM does. RT3 says
that, and the stub measured it (3.3, fifth row). Mutants 4 and 5 are still judged on (a) and (b).

## Review log

Key paths: `cities-skylines-2/launchers/launch-cs2-dxmt11.sh`, `surviving-mars-relaunched/launch-relaunched.sh`,
`common/test-launch-feedback.sh`, `common/test-launcher-parity.sh`, `cities-skylines-2/scripts/boot-verify.sh`,
`surviving-mars-relaunched/tools/licence-wait-probe.sh`, `cities-skylines-2/scripts/licence-wait-probe.sh`,
`common/launch-progress.swift`, `CHANGELOG.md`, both `INSTALL.md`, `cities-skylines-2/GOTCHAS.md`.

| Date | Pass | Lenses | Method | Model | Verified against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-24 | 1 | correctness; risk; builder simulation | two review agents, not editing; one builder in a scratch clone, every gate and every mutant run; the fold by the plan's author, with 3.3 measured again on stubs | Fable 5.2 | `b88112c` | build-ready-with-fixes, folded; R0b before any code |
