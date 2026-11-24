#!/bin/bash
# wine-wait-race.sh -- issue #30: builds common/wine-wait-race.c and runs it under the Wine in a given folder,
# in a scratch prefix made for the run and removed after it. No wrapper, prefix or game is touched, and no
# Steam is started.
#   bash common/wine-wait-race.sh <wine folder> [seconds [waiters [wakers [hold]]]]
#   <wine folder> holds bin/wineserver and bin/wine64 or bin/wine, e.g. a copy of a wrapper's
#   Contents/SharedSupport/wine. Exit: 0 no fault in that time, 3 a fault, 2 refused or no verdict.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
D="${1:-}"
[ $# -gt 0 ] && shift
[ -n "$D" ] && [ -x "$D/bin/wineserver" ] || { echo "REFUSED: give a Wine folder that holds bin/wineserver"; exit 2; }
WINE="$D/bin/wine64"
[ -x "$WINE" ] || WINE="$D/bin/wine"
[ -x "$WINE" ] || { echo "REFUSED: no bin/wine64 or bin/wine in $D"; exit 2; }
command -v x86_64-w64-mingw32-gcc >/dev/null || { echo "REFUSED: x86_64-w64-mingw32-gcc not found"; exit 2; }
T="$(mktemp -d /tmp/wine-wait-race.XXXX)"
trap 'WINEPREFIX="$T/prefix" "$D/bin/wineserver" -k 2>/dev/null; rm -rf "$T"' EXIT
x86_64-w64-mingw32-gcc -O2 -o "$T/wine-wait-race.exe" "$HERE/wine-wait-race.c" || { echo "REFUSED: the build failed"; exit 2; }
N="$D/lib/wine/x86_64-windows/ntdll.dll"
[ -f "$N" ] && echo "ntdll.dll: $(stat -f %z "$N") bytes, sha256 $(shasum -a 256 "$N" | cut -c1-16)"
SECS="${1:-60}"
case "$SECS" in ''|*[!0-9]*) echo "REFUSED: seconds must be a number"; exit 2;; esac
WINEPREFIX="$T/prefix" WINEDEBUG=-all MVK_CONFIG_LOG_LEVEL=0 WINEDLLOVERRIDES="mscoree,mshtml=" "$WINE" "$T/wine-wait-race.exe" "$@" > "$T/out" 2>&1 &
pid=$!
# After a fault the program's own exit can hang (the threads it kills hold what the exit waits for), so the
# verdict is read from its output, and a program still there 5 seconds after its verdict, or 90 seconds after
# the time it was given, is ended through its wineserver.
i=0; seen=0
while kill -0 "$pid" 2>/dev/null; do
    sleep 1; i=$((i + 1))
    grep -qE '^(FAULT|CLEAN|REFUSED):' "$T/out" && seen=$((seen + 1))
    if [ "$seen" -ge 5 ] || [ "$i" -ge $((SECS + 90)) ]; then
        WINEPREFIX="$T/prefix" "$D/bin/wineserver" -k 2>/dev/null
        break
    fi
done
wait "$pid" 2>/dev/null
grep -vE 'mvk-info|^[[:space:]]' "$T/out"
if grep -q '^FAULT:' "$T/out"; then rc=3
elif grep -q '^CLEAN:' "$T/out"; then rc=0
else echo "REFUSED: the program gave no verdict"; rc=2
fi
echo "exit $rc"
exit $rc
