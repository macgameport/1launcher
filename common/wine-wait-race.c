/* wine-wait-race.c -- issue #30: a race in Wine's ntdll between RtlWaitOnAddress and RtlWakeAddressAll.
 *
 * Wine 10.0 to 11.19 clear a waiter's entry->addr before they unlink the entry, and the waiter tests addr
 * without the queue lock when its wait returns; a waiter that times out in that gap returns, its stack (where
 * the entry lives) is reused, and the waker writes what it finds there into the previous entry's next link.
 * Upstream changed the order in 81e52628 (first in wine-11.20).
 *
 * The gap is a few instructions long, so the waker has to be stopped inside it for as long as a waiter needs
 * to time out. The scheduler does that rarely (the crash came 2 h 22 min into a session). This program does
 * it often: beside the threads in short timed RtlWaitOnAddress waits on NADDR addresses that share one of
 * ntdll's 256 futex queues (the queue is (addr >> 4) % 256, so the addresses are 4096 bytes apart) and the
 * threads that call RtlWakeAddressAll and RtlWakeAddressSingle on them, one more thread per waker suspends
 * it at a random moment for <hold> microseconds and resumes it, which is what a preemption is. After every
 * wait a waiter writes 0x102 (STATUS_TIMEOUT, the value the crash found) over the stack its wait used. A
 * broken link faults at the write or at the next walk of the queue, and the access violation is reported.
 *
 *   wine-wait-race.exe [seconds [waiters [wakers [hold]]]]
 *       defaults 60, 2 x processors, processors / 4, 200; hold 0 = no suspending, the scheduler alone
 *   exit 0 = no fault in that time, 3 = an access violation (one line "FAULT: ..."), 2 = refused
 *
 * Build: x86_64-w64-mingw32-gcc -O2 -o wine-wait-race.exe wine-wait-race.c
 * Run it with common/wine-wait-race.sh, which uses a scratch prefix. */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

#define NADDR 2
#define STRIDE (4096 / sizeof(LONG64))

typedef NTSTATUS (WINAPI *wait_fn)(const void *, const void *, SIZE_T, const LARGE_INTEGER *);
typedef void (WINAPI *wake_fn)(const void *);

static wait_fn pWait;
static wake_fn pWakeAll, pWakeSingle;
static ULONG_PTR ntdll_base;
static DWORD start_ms;
static int hold_us;
static LONGLONG qpc_per_us;
static volatile LONG stop, stop_suspending;
static LONG64 slots[NADDR * STRIDE] __attribute__((aligned(4096)));
static volatile LONG64 waits, timeouts, wakes, suspends;
static volatile ULONG_PTR sink;

static void say(const char *s)
{
    DWORD n;
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), s, (DWORD)strlen(s), &n, NULL);
}

static LONG CALLBACK on_fault(EXCEPTION_POINTERS *ep)
{
    char line[256];
    EXCEPTION_RECORD *r = ep->ExceptionRecord;
    ULONG_PTR pc = (ULONG_PTR)r->ExceptionAddress;
    int in_ntdll = pc - ntdll_base < 0x1000000;

    if (r->ExceptionCode != EXCEPTION_ACCESS_VIOLATION) return EXCEPTION_CONTINUE_SEARCH;
    snprintf(line, sizeof(line), "FAULT: access violation, %s of 0x%llx, at %s+0x%llx, thread 0x%lx, %.1f s\n",
             r->ExceptionInformation[0] ? "write" : "read", (unsigned long long)r->ExceptionInformation[1],
             in_ntdll ? "ntdll" : "pc", (unsigned long long)(in_ntdll ? pc - ntdll_base : pc),
             GetCurrentThreadId(), (GetTickCount() - start_ms) / 1000.0);
    say(line);
    TerminateProcess(GetCurrentProcess(), 3);
    return EXCEPTION_CONTINUE_SEARCH;
}

static __attribute__((noinline)) void scribble(void)
{
    volatile ULONG_PTR buf[256];
    int i;

    for (i = 0; i < 256; i++) buf[i] = 0x102;
    sink = buf[0];
}

static unsigned next_rand(unsigned *s)
{
    *s = *s * 1103515245u + 12345u;
    return *s >> 8;
}

static void spin_us(unsigned us)
{
    LARGE_INTEGER t0, t;

    QueryPerformanceCounter(&t0);
    do QueryPerformanceCounter(&t);
    while (t.QuadPart - t0.QuadPart < us * qpc_per_us);
}

static DWORD WINAPI waiter(void *arg)
{
    unsigned seed = (unsigned)(ULONG_PTR)arg * 2654435761u + 1;
    unsigned span = hold_us ? hold_us : 20;
    LONG64 cmp = 0, n = 0, t = 0;
    LARGE_INTEGER timeout;

    while (!stop)
    {
        unsigned r = next_rand(&seed);
        timeout.QuadPart = -10 * (LONGLONG)(1 + r % span);   /* 1 microsecond to <hold> */
        if (pWait(&slots[(r >> 12) % NADDR * STRIDE], &cmp, sizeof(cmp), &timeout) == STATUS_TIMEOUT) t++;
        scribble();
        n++;
    }
    InterlockedAdd64(&waits, n);
    InterlockedAdd64(&timeouts, t);
    return 0;
}

static DWORD WINAPI waker(void *arg)
{
    unsigned seed = (unsigned)(ULONG_PTR)arg * 40503u + 7;
    LONG64 n = 0;

    while (!stop)
    {
        unsigned r = next_rand(&seed);
        const void *a = &slots[r % NADDR * STRIDE];
        if (r & 0x700) pWakeAll(a);
        else pWakeSingle(a);
        n++;
    }
    InterlockedAdd64(&wakes, n);
    return 0;
}

static DWORD WINAPI suspender(void *arg)
{
    HANDLE target = arg;
    unsigned seed = GetCurrentThreadId() * 69069u + 3;
    LONG64 n = 0;

    while (!stop_suspending)
    {
        spin_us(1 + next_rand(&seed) % hold_us);
        if (SuspendThread(target) == (DWORD)-1) break;
        spin_us(hold_us);
        ResumeThread(target);
        n++;
    }
    InterlockedAdd64(&suspends, n);
    return 0;
}

int main(int argc, char **argv)
{
    SYSTEM_INFO si;
    LARGE_INTEGER freq;
    HMODULE nt = GetModuleHandleA("ntdll.dll");
    int seconds, nwait, nwake, nsusp, i;
    HANDLE *th, *su;
    char line[256];

    GetSystemInfo(&si);
    seconds = argc > 1 ? atoi(argv[1]) : 60;
    nwait = argc > 2 ? atoi(argv[2]) : 2 * (int)si.dwNumberOfProcessors;
    nwake = argc > 3 ? atoi(argv[3]) : (int)si.dwNumberOfProcessors / 4;
    hold_us = argc > 4 ? atoi(argv[4]) : 200;
    if (nwake < 1) nwake = 1;
    pWait = (wait_fn)GetProcAddress(nt, "RtlWaitOnAddress");
    pWakeAll = (wake_fn)GetProcAddress(nt, "RtlWakeAddressAll");
    pWakeSingle = (wake_fn)GetProcAddress(nt, "RtlWakeAddressSingle");
    QueryPerformanceFrequency(&freq);
    qpc_per_us = freq.QuadPart / 1000000;
    if (seconds < 1 || nwait < 1 || hold_us < 0 || qpc_per_us < 1 || !pWait || !pWakeAll || !pWakeSingle)
    {
        say("REFUSED: bad arguments, or ntdll has no RtlWaitOnAddress\n");
        return 2;
    }
    ntdll_base = (ULONG_PTR)nt;
    nsusp = hold_us ? nwake : 0;
    AddVectoredExceptionHandler(1, on_fault);
    snprintf(line, sizeof(line), "%d s, %d waiters, %d wakers, hold %d us, %lu processors, %d addresses in one "
             "queue\n", seconds, nwait, nwake, hold_us, si.dwNumberOfProcessors, NADDR);
    say(line);

    th = calloc(nwait + nwake, sizeof(*th));
    su = calloc(nwake, sizeof(*su));
    start_ms = GetTickCount();
    for (i = 0; i < nwait + nwake; i++)
        th[i] = CreateThread(NULL, 0, i < nwait ? waiter : waker, (void *)(ULONG_PTR)(i + 1), 0, NULL);
    for (i = 0; i < nsusp; i++) su[i] = CreateThread(NULL, 0, suspender, th[nwait + i], 0, NULL);
    for (i = 0; i < seconds; i++)
    {
        Sleep(1000);
        if ((i + 1) % 10 == 0)
        {
            snprintf(line, sizeof(line), "%d s, no fault\n", i + 1);
            say(line);
        }
    }
    stop_suspending = 1;
    for (i = 0; i < nsusp; i++) WaitForSingleObject(su[i], INFINITE);
    stop = 1;
    for (i = 0; i < nwait + nwake; i++) WaitForSingleObject(th[i], INFINITE);
    snprintf(line, sizeof(line), "CLEAN: %lld waits (%lld timed out), %lld wakes, %lld suspends, %d s\n",
             (long long)waits, (long long)timeouts, (long long)wakes, (long long)suspends, seconds);
    say(line);
    return 0;
}
