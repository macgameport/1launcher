// launcher-window.swift -- 14unch3r: one window that lists this project's games and starts the one chosen.
// common/make-launcher-app.sh compiles it into 14unch3r.app/Contents/MacOS/launcher-window. A row is an app
// whose Info.plist carries L1Role: each game's own app and the Steam app, as their builders write them. A
// start opens that app with /usr/bin/open, as a double-click does, and the window quits: the app keeps its
// own process tree, consent records and progress window. A game of the bundle's table (common/games.tsv) that has
// no such app is a row too, an offer: a grey tile with the game's initials, drawn by this program
// (docs/plans/launcher-first-install.md, 3.7 and 3.10). Plans: docs/plans/launcher-window.md, 2.2 and 2.5, and
// docs/plans/launcher-window-look.md (the tiles, the mark, the icon, the SVG and the Desktop alias), and
// docs/plans/built-in-update.md, 3.5 (the update parts: a line at the foot of the grid when a newer version of
// 1launcher is out, its sheet, and the menu item; all of it only when the update tool is deployed).
//
//   launcher-window [--games <tsv>] [--update-dir <dir>] [<folder>...]   the window; with no folder, those of --folders
//   launcher-window --list [--games <tsv>] <folder>...      one line per row: role, app id or -, state,
//                                                           title, path; tab-separated, no headings. With
//                                                           --games, one offer row for every game of the table
//                                                           that has no app here: not-set-up, begun (one
//                                                           wrapper carries its marker) or owned
//   launcher-window --default <last app id or -> <folder>... the path of the row selected at open, or nothing
//   launcher-window --second <app path> <folder>...         go, or ask<TAB><title of the game in use>
//   launcher-window --start <app path> [new]                started, or failed<TAB><sentence>; exit 0 or 1
//   launcher-window --owned <app id> <packageinfo.vdf>...   owned, not-owned or unknown
//   launcher-window --folders                               the folders the window reads, one per line
//   launcher-window --icon <out.png> [small]                the icon, 1024 by 1024; small: the form for 16 and 32 px
//   launcher-window --icon-at [small] <x,y>...              ink, body or clear, per pixel of that icon
//   launcher-window --svg <out.svg>                         the icon form as SVG, for the README
//   launcher-window --alias <app> <alias path> [make]       have, other or none; with make, made or failed<TAB>...
//   launcher-window --grid [--games <tsv>] [--update-dir <dir>] <last id or -> <folder>...   the grid's layout, text, AX and colours
//   launcher-window --act <step,...> [--games <tsv>] [--update-dir <dir>] <last id or -> <folder>...   what keys and clicks do to it
//   launcher-window --update-sheet --update-dir <dir> <folder>...   the update's sheet: message, text, buttons, notes; or none
//   launcher-window --update-menu --update-dir <dir> <fetched|failed|skipped|->   what "Check for Updates…" answers
//   launcher-window --update-open --update-dir <dir>        runs the tool with --open: quit, or failure<TAB>message<TAB>sentence
//   launcher-window --update-answer <first|second|escape>   open or nothing: what a button of the update's sheet does
//   launcher-window --update-tool [--update-dir <dir>]      the update tool's path, or -; with no option, from L1UpdateDir
// Every mode but the window prints and returns before any window is made; --grid and --act build the window's
// own grid, with no window. Any other use prints a usage line and exits 2. Tests: common/test-launcher-window.sh.
//
// The update tool is <dir>/updates.sh (common/updates.sh, deployed by each setup), where <dir> is L1UpdateDir of
// this program's own Info.plist or --update-dir, which wins. Only the window and --update-tool read the key: every
// other text mode looks for the tool only when it is given --update-dir. The tool is run in one place, askUpdate,
// as a child with a time limit; the window never runs it on the main thread, and nothing it fetches is run.
//
// The list is not a boundary of trust: whoever can put an app into ~/Applications can also edit the
// unsigned shims already there, and a start goes through LaunchServices as a double-click does.
import AppKit

enum Role: String { case game, steam, offer }
// The last three are an offer's (docs/plans/launcher-first-install.md, 3.7): owned is "not set up, and a cache of
// Steam's says the account has the game"; begun is "no app, and exactly one wrapper carries the game's marker".
enum State: String { case busy, absent, ready, unknown, owned, notSetUp = "not-set-up", begun }

struct Row {
    let role: Role
    let appID: Int?       // a game's Steam app id: its key (D3). The title is a label
    var title: String     // as shown: with the file name too when two rows share a title
    let sortTitle: String
    let path: String      // the app as it was reached, or an offer's guide address
    let key: String       // the resolved path: one app reached twice is one row
    var prefix: String?   // L1Prefix, or after a hand rename of the wrapper, the prefix of the one marked wrapper
    var state: State
}

let fm = FileManager.default
let steamDir = "/drive_c/Program Files (x86)/Steam"

func realPath(_ p: String) -> String? {
    guard let r = realpath(p, nil) else { return nil }
    defer { free(r) }
    return String(cString: r)
}

// A folder or app path as given, made absolute, with no trailing slash. Not standardizingPath: that drops
// a leading /private, and one app reached through /tmp and /private/tmp must still be told apart by the
// resolved path, not by a cleaned-up spelling.
func absolute(_ p: String) -> String {
    var s = p
    while s.count > 1 && s.hasSuffix("/") { s.removeLast() }
    return s.hasPrefix("/") ? s : fm.currentDirectoryPath + "/" + s
}

// The bytes of a plain file, read from the opened file: nil for a symlink, a folder, a FIFO (O_NONBLOCK, so
// that one cannot hold the open), a file of more than `limit` bytes, or a failed read.
func readPlainFile(_ path: String, limit: Int) -> Data? {
    let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
    guard fd >= 0 else { return nil }
    defer { close(fd) }
    var st = stat()
    guard fstat(fd, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG else { return nil }
    var data = Data()
    var buf = [UInt8](repeating: 0, count: 65536)
    while data.count <= limit {
        let n = read(fd, &buf, min(buf.count, limit + 1 - data.count))
        if n < 0 && errno == EINTR { continue }
        if n < 0 { return nil }
        if n == 0 { return data }
        data.append(buf, count: n)
    }
    return nil
}

func lastID(_ s: String) -> Int? {   // a decimal app id from 1 to 2147483647, else none
    guard !s.isEmpty, s.utf8.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }), let n = Int(s), n >= 1, n <= 2147483647 else { return nil }
    return n
}

// A plist integer from 1 to 2147483647. Swift's `as? Int` would take <true/> as 1 and <real>5</real> as 5.
func appID(_ v: Any?) -> Int? {
    guard let n = v as? NSNumber else { return nil }
    if CFGetTypeID(n) == CFBooleanGetTypeID() { return nil }
    if CFNumberIsFloatType(n) { return nil }
    let i = n.int64Value
    return i >= 1 && i <= 2147483647 ? Int(i) : nil
}

func text(_ v: Any?) -> String? {
    guard let s = v as? String, !s.isEmpty else { return nil }
    return s
}

// A tab or a line break becomes a space, so that a title is one field of one line.
func oneLine(_ s: String) -> String { String(s.map { $0 == "\t" || $0.isNewline ? " " : $0 }) }

func title(of d: [String: Any], file: String) -> String {
    let base = String(file.dropLast(4))
    let raw = text(d["CFBundleDisplayName"]) ?? text(d["CFBundleName"]) ?? base
    return oneLine(raw)
}

func hasControl(_ s: String) -> Bool {
    s.contains(where: { $0.isNewline }) || s.unicodeScalars.contains(where: { $0.properties.generalCategory == .control })
}

// A row: a direct child whose name ends .app in any case, a folder and not a symlink, whose
// Contents/Info.plist is a plain file of at most 1 MiB that parses and says L1Role game or steam; a game
// also needs L1SteamAppID as a whole number. A name holding a control character is passed over: no
// builder writes one (plan 2.1), and it would break the lines of --list.
func row(_ folder: String, _ name: String) -> Row? {
    guard name.lowercased().hasSuffix(".app"), !hasControl(name) else { return nil }
    let path = (folder == "/" ? "" : folder) + "/" + name
    var st = stat()
    guard lstat(path, &st) == 0, (st.st_mode & S_IFMT) == S_IFDIR else { return nil }
    guard let data = readPlainFile(path + "/Contents/Info.plist", limit: 1_048_576) else { return nil }
    guard let d = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { return nil }
    let roleText = d["L1Role"] as? String
    guard roleText == "game" || roleText == "steam" else { return nil }
    let role: Role = roleText == "steam" ? .steam : .game
    var id: Int? = nil
    if role == .game {
        guard let n = appID(d["L1SteamAppID"]) else { return nil }
        id = n
    }
    var prefix: String? = nil
    if let p = d["L1Prefix"] as? String, p.hasPrefix("/"), p.hasSuffix("/Contents/SharedSupport/prefix") { prefix = p }
    let t = title(of: d, file: name)
    let key = realPath(path) ?? path
    return Row(role: role, appID: id, title: t, sortTitle: t, path: path, key: key, prefix: prefix, state: .unknown)
}

// A launcher holds <prefix>/.launcher.lock, a symlink whose target is its process number, from its start
// until it exits. Alive is the launchers' own rule: a kill that succeeds, so a number that now belongs to
// another user's process is not alive. 0 and 1 are never a launcher (kill(0, 0) asks about this process's
// own group), and a target that is not digits only is none (Int32("+7") is 7).
func lockHeldByLiveProcess(_ prefix: String) -> Bool {
    let lock = prefix + "/.launcher.lock"
    var st = stat()
    guard lstat(lock, &st) == 0, (st.st_mode & S_IFMT) == S_IFLNK else { return false }
    guard let t = try? fm.destinationOfSymbolicLink(atPath: lock) else { return false }
    guard !t.isEmpty, t.utf8.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }) else { return false }
    guard let pid = Int32(t), pid >= 2, pid <= 99999 else { return false }
    return kill(pid, 0) == 0
}

// From files alone, with no process matching. A Steam app is never busy: nothing locks the store wrapper.
func state(of r: Row) -> State {
    guard let p = r.prefix else { return .unknown }
    let marker = r.role == .steam ? p + steamDir + "/steam.exe" : p + steamDir + "/steamapps/appmanifest_\(r.appID ?? 0).acf"
    if r.role == .game, lockHeldByLiveProcess(p) { return .busy }
    return fm.fileExists(atPath: marker) ? .ready : .absent
}

func secondLine(_ r: Row) -> String {
    switch (r.state, r.role) {
    case (_, .offer): return "Not set up on this Mac. Opens the set-up guide."
    case (.busy, _): return "In use: starting, running or closing"
    case (.absent, .steam): return "Windows Steam not found. Build this app again."
    case (.absent, _): return "Not installed in Steam. See its set-up guide."
    case (.ready, .steam): return "Steam for Windows, run under Wine"
    default: return ""
    }
}

func rank(_ r: Role) -> Int { r == .game ? 0 : r == .steam ? 1 : 2 }

// Games, then Steam apps, then offers; each group by title without regard to case, then by path.
func ordered(_ rows: [Row]) -> [Row] {
    rows.sorted { a, b in
        if rank(a.role) != rank(b.role) { return rank(a.role) < rank(b.role) }
        let c = a.sortTitle.caseInsensitiveCompare(b.sortTitle)
        if c != .orderedSame { return c == .orderedAscending }
        return a.path < b.path
    }
}

// Rows with the same title, without regard to case, also show their file name.
func titled(_ rows: [Row]) -> [Row] {
    var count: [String: Int] = [:]
    for r in rows { count[r.sortTitle.lowercased(), default: 0] += 1 }
    return rows.map { r in
        guard count[r.sortTitle.lowercased(), default: 0] > 1 else { return r }
        var r = r
        r.title = "\(r.sortTitle) (\((r.path as NSString).lastPathComponent))"
        return r
    }
}

// Every row in the folders, states read now. A folder given twice, or the same folder by two spellings,
// adds nothing the second time: the first spelling of an app is the one kept.
// After a hand rename of a wrapper the L1Prefix an app was built with names a folder that is gone. The wrapper
// carries a marker in its Info.plist (docs/plans/wrapper-names.md, 3.1 and 3.9): L1Role game-wrapper with the game's
// L1SteamAppID, or steam-wrapper. The one app in the same folder that carries the row's marker gives the prefix;
// with none or two, nothing does. Nothing is run from the wrapper: its Info.plist is read as every app's is.
func markedPaths(_ folder: String, _ names: [String], role: Role, appID want: Int?) -> [String] {
    var hits: [String] = []
    for name in names where name.lowercased().hasSuffix(".app") && !hasControl(name) {
        let path = (folder == "/" ? "" : folder) + "/" + name
        var st = stat()
        guard lstat(path, &st) == 0, (st.st_mode & S_IFMT) == S_IFDIR else { continue }
        guard let data = readPlainFile(path + "/Contents/Info.plist", limit: 1 << 20) else { continue }   // a row's limit
        guard let d = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { continue }
        let mark = d["L1Role"] as? String
        if role == .steam, mark == "steam-wrapper" { hits.append(path) }
        if role == .game, mark == "game-wrapper", let id = want, appID(d["L1SteamAppID"]) == id { hits.append(path) }
    }
    return hits
}
func markedWrapper(_ folder: String, _ names: [String], role: Role, appID want: Int?) -> String? {
    let hits = markedPaths(folder, names, role: role, appID: want)
    return hits.count == 1 ? hits[0] + "/Contents/SharedSupport/prefix" : nil
}

func rows(in folders: [String]) -> [Row] {
    var seen = Set<String>(), found: [Row] = []
    for f in folders.map(absolute) {
        guard let names = try? fm.contentsOfDirectory(atPath: f) else { continue }
        for name in names.sorted() {
            guard var r = row(f, name), !seen.contains(r.key) else { continue }
            seen.insert(r.key)
            if let p = r.prefix, !fm.fileExists(atPath: p), let w = markedWrapper(f, names, role: r.role, appID: r.appID) {
                r.prefix = w
            }
            r.state = state(of: r)
            found.append(r)
        }
    }
    return ordered(titled(found))
}

// The row selected when the window opens: the game recorded last if it is listed (the first by path if two
// apps share it), else the first game, else the first row of any kind.
func defaultRow(_ rows: [Row], last: Int?) -> Row? {
    if let id = last, let r = rows.filter({ $0.role == .game && $0.appID == id }).min(by: { $0.path < $1.path }) { return r }
    return rows.first(where: { $0.role == .game }) ?? rows.first
}

func samePrefix(_ a: String?, _ b: String?) -> Bool {
    guard let a = a, let b = b else { return false }
    return a == b || (realPath(a) != nil && realPath(a) == realPath(b))
}

// One game at a time (D6): the game in use whose Steam a start of `chosen` would take offline, the first by
// the list's order, or nil to start without asking. A row with the busy row's own prefix shares its
// launcher, and an offer starts no Steam; a chosen row with no prefix could be any game, so it is asked.
func blocker(_ chosen: Row, _ rows: [Row]) -> Row? {
    guard chosen.role == .game || chosen.role == .steam else { return nil }
    let busy = rows.filter { $0.role == .game && $0.state == .busy && !samePrefix($0.prefix, chosen.prefix) }
    return busy.first
}

func openArguments(_ target: String, new: Bool) -> [String] { new ? ["-n", target] : [target] }

// /usr/bin/open, as a double-click does, the target one argument and no shell, waited for: it returns at
// once, and the app keeps starting after this program exits. -n for a row in use: a plain open of a script
// app that is still alive starts nothing. NSWorkspace.openApplication does not fit: for a script app its
// handler runs when the script ends. Nil when open exited 0, else its sentence.
func start(_ target: String, new: Bool) -> String? {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = openArguments(target, new: new)
    let err = Pipe()
    p.standardError = err
    p.standardOutput = FileHandle.nullDevice
    p.standardInput = FileHandle.nullDevice
    do { try p.run() } catch { return oneLine(error.localizedDescription) }
    let said = err.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    if p.terminationReason == .exit && p.terminationStatus == 0 { return nil }
    let s = oneLine(String(decoding: said, as: UTF8.self)).trimmingCharacters(in: .whitespaces)
    return s.isEmpty ? "open ended with status \(p.terminationStatus)." : s
}

// ~/Applications, with $HOME when it is set (NSHomeDirectory() ignores it), and the folder that holds this
// program's own app when it runs from inside one. Not /Applications: no builder writes there by default.
func ownBundle() -> String? {
    guard let exe = Bundle.main.executablePath.flatMap(realPath) else { return nil }
    let macos = (exe as NSString).deletingLastPathComponent
    let contents = (macos as NSString).deletingLastPathComponent
    let app = (contents as NSString).deletingLastPathComponent
    guard (macos as NSString).lastPathComponent == "MacOS", (contents as NSString).lastPathComponent == "Contents",
          app.lowercased().hasSuffix(".app") else { return nil }
    return app
}

func windowFolders() -> [String] {
    let env = ProcessInfo.processInfo.environment["HOME"] ?? ""
    let home = absolute(env.isEmpty ? NSHomeDirectory() : env)
    var all = [(home == "/" ? "" : home) + "/Applications"]
    if let b = ownBundle() { all.append((b as NSString).deletingLastPathComponent) }
    var out: [String] = [], seen = Set<String>()
    for f in all where seen.insert(realPath(f) ?? f).inserted { out.append(f) }
    return out
}

// ------------------------------------------------------------------------------------------------ offers
// --owned reads Steam's own cache of the account's packages, <prefix>/drive_c/Program Files (x86)/Steam/
// appcache/packageinfo.vdf, in the layout section 1 of the plan measured. Every number little-endian and
// put together from bytes: a magic, 0x06565527 (no token) or 0x06565528 (an 8-byte token), and a universe;
// then per package a 32-bit id, 20 bytes, a change number, the token, and one binary KeyValues tree; then
// the id 0xFFFFFFFF and nothing after it. Every read is checked against the end, and anything else makes
// the whole file unknown. No fixture of the tests is cut from a real file: they write their own.
struct Reader {
    let b: [UInt8]
    var at = 0
    mutating func byte() -> UInt8? {
        guard at < b.count else { return nil }
        at += 1
        return b[at - 1]
    }
    mutating func number(_ size: Int) -> UInt64? {
        guard b.count - at >= size else { return nil }
        var v: UInt64 = 0
        for k in 0..<size { v |= UInt64(b[at + k]) << UInt64(8 * k) }
        at += size
        return v
    }
    mutating func skip(_ size: Int) -> Bool {
        guard b.count - at >= size else { return false }
        at += size
        return true
    }
    // up to a zero, within the file and within `limit` bytes, the zero included
    mutating func zeroEnded(within limit: Int) -> ArraySlice<UInt8>? {
        let end = b.count - at <= limit ? b.count : at + limit
        guard let z = b[at..<end].firstIndex(of: 0) else { return nil }
        defer { at = z + 1 }
        return b[at..<z]
    }
    // The nodes after a nested node's name, up to its 8. `depth` is that node's: the document is 0, a
    // package's root 1, and 8 the deepest allowed. Types: 0 nested, 1 string, 2 32-bit integer, 7 64-bit
    // integer, 8 end. A package's app ids are the integer children of an `appids` node directly under its
    // root; `appids` says this node is one.
    mutating func children(depth: Int, appids: Bool, ids: inout Set<UInt64>) -> Bool {
        while true {
            guard let type = byte() else { return false }
            if type == 8 { return true }
            guard let name = zeroEnded(within: 256) else { return false }
            switch type {
            case 0:
                guard depth < 8 else { return false }
                guard children(depth: depth + 1, appids: depth == 1 && name.elementsEqual("appids".utf8), ids: &ids) else { return false }
            case 1:
                guard zeroEnded(within: Int.max) != nil else { return false }
            case 2, 7:
                guard let v = number(type == 2 ? 4 : 8) else { return false }
                if appids { ids.insert(v) }
            default:
                return false
            }
        }
    }
}

// The app ids a file lists, or nil when it is not cleanly read.
func ownedIDs(_ data: Data) -> Set<UInt64>? {
    var r = Reader(b: [UInt8](data))
    guard let magic = r.number(4), magic >> 8 == 0x065655, magic & 0xFF == 0x27 || magic & 0xFF == 0x28, r.skip(4) else { return nil }
    let token = magic & 0xFF == 0x28
    var ids = Set<UInt64>()
    while true {
        guard let package = r.number(4) else { return nil }
        if package == 0xFFFF_FFFF { return r.at == r.b.count ? ids : nil }
        guard r.skip(20), r.skip(4) else { return nil }
        if token { guard r.skip(8) else { return nil } }
        guard r.children(depth: 0, appids: false, ids: &ids) else { return nil }
    }
}

// owned: a cleanly read file lists the id. not-owned: at least one file read cleanly and none lists it.
// unknown: no file read cleanly. A file must be plain, not a symlink, and at most 16 MiB as read.
func ownership(of id: Int, in files: [String]) -> String {
    var clean = false
    for file in files {
        guard let data = readPlainFile(file, limit: 16_777_216), let ids = ownedIDs(data) else { continue }
        if ids.contains(UInt64(id)) { return "owned" }
        clean = true
    }
    return clean ? "not-owned" : "unknown"
}

// A child in its own process group, its output read as it comes: nil unless it exited 0 within `limit`
// seconds. At the limit the whole group is killed, so a helper's own children go too, and nothing left
// holding the pipe can hold up the caller. `adding` sets variables for the child over this program's own.
func runChild(_ exe: String, _ argv: [String], limit: Double, adding: [String: String] = [:]) -> String? {
    var fds: [Int32] = [-1, -1]
    guard pipe(&fds) == 0 else { return nil }
    var actions: posix_spawn_file_actions_t? = nil
    var attr: posix_spawnattr_t? = nil
    posix_spawn_file_actions_init(&actions)
    posix_spawnattr_init(&attr)
    defer { posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attr) }
    posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0)
    posix_spawn_file_actions_adddup2(&actions, fds[1], 1)
    posix_spawn_file_actions_addopen(&actions, 2, "/dev/null", O_WRONLY, 0)
    posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT))
    posix_spawnattr_setpgroup(&attr, 0)
    let cargs: [UnsafeMutablePointer<CChar>?] = ([exe] + argv).map { strdup($0) } + [nil]
    let env = ProcessInfo.processInfo.environment.merging(adding) { _, new in new }
    let cenv: [UnsafeMutablePointer<CChar>?] = env.map { strdup("\($0.key)=\($0.value)") } + [nil]
    defer { (cargs + cenv).forEach { free($0) } }
    var pid: pid_t = 0
    let spawned = posix_spawn(&pid, exe, &actions, &attr, cargs, cenv)
    close(fds[1])
    defer { close(fds[0]) }
    guard spawned == 0 else { return nil }
    _ = fcntl(fds[0], F_SETFL, O_NONBLOCK)
    let deadline = Date().addingTimeInterval(limit)
    var out = Data(), status: Int32 = 0, exited = false, ended = false
    var buf = [UInt8](repeating: 0, count: 4096)
    while !(exited && ended) && Date() < deadline {
        if ended {
            usleep(20_000)
        } else {
            var p = pollfd(fd: fds[0], events: Int16(POLLIN), revents: 0)
            _ = poll(&p, 1, 20)
            let n = read(fds[0], &buf, buf.count)
            if n > 0 && out.count < 65536 { out.append(buf, count: n) }
            if n == 0 { ended = true }
        }
        if !exited && waitpid(pid, &status, WNOHANG) == pid { exited = true }
    }
    if !(exited && ended) { kill(-pid, SIGKILL) }
    if !exited { waitpid(pid, &status, 0); return nil }
    guard ended, status & 0x7F == 0, (status >> 8) & 0xFF == 0 else { return nil }
    return String(decoding: out, as: UTF8.self)
}

// Neither the window nor --list reads a packageinfo.vdf in its own process: each asks a child, the program
// named by L1_OWNED_HELPER or else itself, with --owned and a 5 s limit, so that no file can stop the window
// or hold up its list. A child that crashes, runs out of time, fails or says anything else: unknown.
func askOwned(_ id: Int, _ files: [String]) -> String {
    let named = ProcessInfo.processInfo.environment["L1_OWNED_HELPER"] ?? ""
    let helper = named.isEmpty ? (Bundle.main.executablePath ?? CommandLine.arguments[0]) : named
    guard let out = runChild(helper, ["--owned", String(id)] + files, limit: 5) else { return "unknown" }
    let word = out.split(separator: "\n").first.map(String.init) ?? ""
    return ["owned", "not-owned", "unknown"].contains(word) ? word : "unknown"
}

struct Ported { let id: Int; let title: String; let address: String }

// common/games.tsv: app id, folder, title and set-up guide address, tab-separated, one line per game. A line
// starting # is passed over, and so is one that is not four fields with a whole-number id and a title.
func portedGames(_ path: String) -> [Ported] {
    guard let data = readPlainFile(path, limit: 1_048_576) else { return [] }
    var out: [Ported] = []
    for line in String(decoding: data, as: UTF8.self).split(whereSeparator: { $0.isNewline }) {
        if line.hasPrefix("#") { continue }
        let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard f.count == 4, let id = lastID(f[0]), !f[2].isEmpty else { continue }
        out.append(Ported(id: id, title: oneLine(f[2]), address: f[3]))
    }
    return out
}

final class Answers: @unchecked Sendable {
    let lock = NSLock()
    var words: [String]
    init(_ n: Int) { words = Array(repeating: "unknown", count: n) }
}

// The offers (2.5): each ported game with no game row that some row's packageinfo.vdf says the account
// owns. Only those files are read, and with no row that has a prefix there is nothing to ask. A guide
// address must start https://github.com/. A game that is set up is never hidden (D7): this only adds rows.
// The children are asked side by side, so the list waits at most one limit.
func offerRows(_ table: String, _ rows: [Row]) -> [Row] {
    let have = Set(rows.compactMap { $0.role == .game ? $0.appID : nil })
    var files: [String] = []
    for r in rows {
        guard let p = r.prefix else { continue }
        let f = p + steamDir + "/appcache/packageinfo.vdf"
        if !files.contains(f) { files.append(f) }
    }
    guard !files.isEmpty else { return [] }
    var asked: [Ported] = []
    for g in portedGames(table) {
        guard !have.contains(g.id) else { continue }
        guard g.address.hasPrefix("https://github.com/") else { continue }
        if !asked.contains(where: { $0.id == g.id }) { asked.append(g) }
    }
    let answers = Answers(asked.count)
    let questions = asked, from = files
    DispatchQueue.concurrentPerform(iterations: questions.count) { i in
        let word = askOwned(questions[i].id, from)
        answers.lock.lock(); answers.words[i] = word; answers.lock.unlock()
    }
    return ordered(zip(asked, answers.words).filter { $0.1 == "owned" }.map { g, _ in
        Row(role: .offer, appID: g.id, title: g.title, sortTitle: g.title, path: g.address, key: "offer \(g.id)", prefix: nil, state: .owned)
    })
}

// The games that are not set up (docs/plans/launcher-first-install.md, 3.7): one offer row for every game of the
// table that has no game row, whether or not Steam says the account owns it. They are made from files alone, the
// table and the folders' marked wrappers, so the window has them at its first reload. A game with exactly one
// wrapper that carries its marker is begun: its install was started and its setup never finished. With none, or
// with two marked alike, it is not set up. A guide address must start https://github.com/, as for offerRows.
func tableOffers(_ table: String, _ folders: [String], _ rows: [Row]) -> [Row] {
    let have = Set(rows.compactMap { $0.role == .game ? $0.appID : nil })
    var listed: [(String, [String])] = []
    for f in folders.map(absolute) {
        if let names = try? fm.contentsOfDirectory(atPath: f) { listed.append((f, names)) }
    }
    var out: [Row] = [], seen = Set<Int>()
    for g in portedGames(table) {
        guard !have.contains(g.id), !seen.contains(g.id), g.address.hasPrefix("https://github.com/") else { continue }
        seen.insert(g.id)
        var wrappers = Set<String>()   // one wrapper reached by two spellings of a folder is one
        for (f, names) in listed {
            for w in markedPaths(f, names, role: .game, appID: g.id) { wrappers.insert(realPath(w) ?? w) }
        }
        out.append(Row(role: .offer, appID: g.id, title: g.title, sortTitle: g.title, path: g.address, key: "offer \(g.id)",
                       prefix: nil, state: wrappers.count == 1 ? .begun : .notSetUp))
    }
    return ordered(out)
}

// What a cache of Steam's changes (offerRows asks it): a game that is not set up, and that the account has,
// reads owned. No tile appears, goes or moves by it.
func withOwnership(_ offers: [Row], _ owned: [Row]) -> [Row] {
    let ids = Set(owned.compactMap { $0.appID })
    return offers.map { r in
        var r = r
        if r.state == .notSetUp, let id = r.appID, ids.contains(id) { r.state = .owned }
        return r
    }
}

func usage() -> Never {
    FileHandle.standardError.write(Data("""
    usage: launcher-window [--games <tsv>] [--update-dir <dir>] [<folder>...]   the window
           launcher-window --list [--games <tsv>] <folder>...
           launcher-window --default <last app id or -> <folder>...
           launcher-window --second <app path> <folder>...
           launcher-window --start <app path> [new]
           launcher-window --owned <app id> <packageinfo.vdf>...
           launcher-window --folders
           launcher-window --icon <out.png> [small]
           launcher-window --icon-at [small] <x,y>...
           launcher-window --svg <out.svg>
           launcher-window --alias <app> <alias path> [make]
           launcher-window --grid [--games <tsv>] [--update-dir <dir>] <last app id or -> <folder>...
           launcher-window --act <step,...> [--games <tsv>] [--update-dir <dir>] <last app id or -> <folder>...
           launcher-window --update-sheet --update-dir <dir> <folder>...
           launcher-window --update-menu --update-dir <dir> <fetched|failed|skipped|->
           launcher-window --update-open --update-dir <dir>
           launcher-window --update-answer <first|second|escape>
           launcher-window --update-tool [--update-dir <dir>]

    """.utf8))
    exit(2)
}

// ------------------------------------------------------------------------------------------------ the mark
// docs/plans/launcher-window-look.md, 2.5. In a square box, x to the right and y up, both from 0 to 1. The numbers
// live here alone: markPath draws them and markSVG writes them, since an NSBezierPath arc cannot be read back as an
// SVG arc.
enum Mark {
    static let centre = (0.5, 0.5)
    static let radius = 0.42
    static let from = -58.0
    static let to = 238.0
    static let one: [(Double, Double)] = [(0.30, 0.605), (0.455, 0.76), (0.455, 0.08)]
    static let four: [(Double, Double)] = [(0.545, 0.08), (0.545, 0.76), (0.715, 0.585), (0.545, 0.545)]
    static let stroke = 0.05
    static let smallStroke = 0.085   // the form for 16 and 32 pixels: the full one is a grey blur at 16 (2.6, D24)
}

func markPath(in b: NSRect, stroke: Double = Mark.stroke) -> NSBezierPath {
    func p(_ q: (Double, Double)) -> NSPoint { NSPoint(x: b.minX + q.0 * b.width, y: b.minY + q.1 * b.height) }
    let path = NSBezierPath()
    path.appendArc(withCenter: p(Mark.centre), radius: Mark.radius * b.width, startAngle: Mark.from, endAngle: Mark.to, clockwise: false)
    for line in [Mark.one, Mark.four] {
        path.move(to: p(line[0]))
        for q in line.dropFirst() { path.line(to: p(q)) }
    }
    path.lineWidth = stroke * b.width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    return path
}

// The icon, plan 2.6: exactly 1024 by 1024 pixels, the rounded square 824 wide, the mark in a box of 640; the
// small form's box is 704.
let iconBody = NSRect(x: 100, y: 100, width: 824, height: 824)
let iconBox = iconBody.insetBy(dx: 92, dy: 92)
let smallBox = iconBody.insetBy(dx: 60, dy: 60)

func iconBitmap(small: Bool) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let shape = NSBezierPath(roundedRect: iconBody, xRadius: 185, yRadius: 185)
    NSGradient(starting: NSColor(white: 0.32, alpha: 1), ending: NSColor(white: 0.13, alpha: 1))?.draw(in: shape, angle: -90)
    NSColor.white.setStroke()
    markPath(in: small ? smallBox : iconBox, stroke: small ? Mark.smallStroke : Mark.stroke).stroke()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawIcon(to path: String, small: Bool) -> Bool {
    guard let png = iconBitmap(small: small)?.representation(using: .png, properties: [:]) else { return false }
    return FileManager.default.createFile(atPath: path, contents: png)
}

// --icon-at, plan 2.6: x and y from the top left. Alpha under 0.5 is clear, red over 0.9 is ink, else body.
func iconKind(_ rep: NSBitmapImageRep, _ x: Int, _ y: Int) -> String {
    guard x >= 0, y >= 0, x < 1024, y < 1024, let c = rep.colorAt(x: x, y: y) else { return "clear" }
    return c.alphaComponent < 0.5 ? "clear" : c.redComponent > 0.9 ? "ink" : "body"
}

// --svg, plan 2.8: the icon form, five lines. The path's numbers come from Mark; the rest is literal.
func markSVG() -> String {
    func f(_ v: Double) -> String { String(format: "%.2f", v) }
    let side = Double(iconBox.width), left = Double(iconBox.minX), top = Double(iconBox.maxY)
    func pt(_ q: (Double, Double)) -> String { f(left + side * q.0) + " " + f(top - side * q.1) }
    func on(_ degrees: Double) -> (Double, Double) {
        (Mark.centre.0 + Mark.radius * cos(degrees * .pi / 180), Mark.centre.1 + Mark.radius * sin(degrees * .pi / 180))
    }
    let r = f(side * Mark.radius)
    var d = "M" + pt(on(Mark.from)) + "A\(r) \(r) 0 \(Mark.to - Mark.from > 180 ? 1 : 0) 0 " + pt(on(Mark.to))
    for line in [Mark.one, Mark.four] { d += "M" + line.map(pt).joined(separator: "L") }
    return """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="100 100 824 824" role="img" aria-label="14unch3r">
    <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#525252"/><stop offset="1" stop-color="#212121"/></linearGradient></defs>
    <rect x="100" y="100" width="824" height="824" rx="185" fill="url(#g)"/>
    <path d="\(d)" fill="none" stroke="#FFFFFF" stroke-width="\(f(side * Mark.stroke))" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>

    """
}

// ------------------------------------------------------------------------------------------------ the alias
// --alias, plan 2.9: have, other or none, from lstat first. An existing path is never written: writeBookmarkData
// would overwrite it, so it is called only when nothing is there.
func aliasState(_ app: String, _ path: String) -> String {
    var st = stat()
    guard lstat(path, &st) == 0 else { return "none" }
    guard (st.st_mode & S_IFMT) == S_IFREG else { return "other" }
    let u = URL(fileURLWithPath: path)
    guard (try? u.resourceValues(forKeys: [.isAliasFileKey]))?.isAliasFile == true,
          let to = try? URL(resolvingAliasFileAt: u, options: [.withoutUI, .withoutMounting]),
          let a = realPath(to.path), let b = realPath(app) else { return "other" }
    return a == b ? "have" : "other"
}

func makeAlias(_ app: String, _ path: String) -> String? {   // nil when written, else the system's sentence
    do {
        let d = try URL(fileURLWithPath: app).bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
        try URL.writeBookmarkData(d, to: URL(fileURLWithPath: path))
        return nil
    } catch { return oneLine(error.localizedDescription) }
}

// ------------------------------------------------------------------------------------------------ the update
// docs/plans/built-in-update.md, 3.5. The tool is common/updates.sh as a setup deployed it (3.2): every call of
// it exits 0 and says the outcome in its output, and its options and lines are a contract between versions. The
// window takes its decisions and builds its sheets only from the pure functions here, and each has a text mode.
struct UpdateState {
    let word: String        // off, none, manual, unknown, ready or current
    let installed: String   // the lowest installed version, or -
    let offered: String     // the version on offer, or -
    let detail: String      // for manual: the line a game follows
    let fetch: String?      // after --refresh: fetched, failed or skipped
}

// The calls of the tool and their limits in seconds: the window and the text modes use the same ones. The
// fifth call, --open, is openUpdate's alone.
enum Call {
    static let state: ([String], Double) = ([], 5)                             // touches no network
    static let refresh: ([String], Double) = (["--refresh"], 15)               // at most one fetch a day
    static let refreshNow: ([String], Double) = (["--refresh", "--now"], 15)   // the menu item
    static let notes: ([String], Double) = (["--notes"], 5)
}

// A version as the tool writes one (3.1): v, then three numbers of one to six digits with no leading zero.
func isVersion(_ s: String) -> Bool {
    guard s.hasPrefix("v") else { return false }
    let parts = s.dropFirst().split(separator: ".", omittingEmptySubsequences: false)
    return parts.count == 3 && parts.allSatisfy { p in
        !p.isEmpty && p.count <= 6 && p.utf8.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }) && (p == "0" || !p.hasPrefix("0"))
    }
}

// The tool's answer, parsed: only its first line counts, and fields past those known here are ignored. None
// unless the word is one of the six and both versions are a version or -; ready needs a version on offer.
func updateState(_ answer: String) -> UpdateState? {
    let line = answer.split(separator: "\n", omittingEmptySubsequences: false).first.map(String.init) ?? ""
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard f.count >= 3, ["off", "none", "manual", "unknown", "ready", "current"].contains(f[0]) else { return nil }
    guard f[1] == "-" || isVersion(f[1]), f[2] == "-" || isVersion(f[2]) else { return nil }
    if f[0] == "ready" && f[2] == "-" { return nil }
    let fetch = f.count > 4 && ["fetched", "failed", "skipped"].contains(f[4]) ? f[4] : nil
    return UpdateState(word: f[0], installed: f[1], offered: f[2], detail: f.count > 3 ? f[3] : "-", fetch: fetch)
}

// The line at the foot of the grid: only when a newer version is out.
func footText(_ s: UpdateState?) -> String? {
    guard let s = s, s.word == "ready" else { return nil }   // no line in any other state
    return Look.foot(s.offered)
}

// The sheet of a version that is out, or none when the state is not ready. With a game in use it is the other
// sheet: one button, no notes, and nothing to answer. `notes` is what --notes printed; nothing, or no answer,
// gives the one line with the address.
struct SheetWords { let message: String; let text: String; let buttons: [String]; let notes: [String]? }
func updateSheet(_ s: UpdateState?, _ notes: String?, _ busyTitle: String?) -> SheetWords? {
    guard let s = s, s.word == "ready" else { return nil }
    if let t = busyTitle { return SheetWords(message: Look.quitFirst(t), text: Look.quitFirstText, buttons: [Look.ok], notes: nil) }
    var lines = (notes ?? "").split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeLast() }
    return SheetWords(message: Look.out(s.offered), text: (s.installed == "-" ? "" : Look.has(s.installed) + " ") + Look.updateText,
                      buttons: [Look.notNow, Look.update], notes: lines.isEmpty ? [Look.notesAddress] : lines)
}

// What "Check for Updates…" answers, in the order of the plan's table: the sheet, or an alert's message and
// text. `fetch` is the fifth field of the refresh's answer; no usable answer is row 6.
enum MenuAnswer { case sheet, alert(String, String) }
func menuAnswer(_ s: UpdateState?, _ fetch: String?) -> MenuAnswer {
    guard let s = s else { return .alert(Look.unreadMessage, Look.unreadText) }
    switch s.word {
    case "off": return .alert(Look.offMessage, Look.offText)
    case "none": return .alert(Look.noneMessage, Look.noneText)
    case "manual": return .alert(Look.manualMessage, s.detail == "checkout" ? Look.checkoutText : Look.namedText)
    case "ready": return .sheet
    default:
        if fetch == "failed" || s.word != "current" { return .alert(Look.unreadMessage, Look.unreadText) }   // row 6, before row 7
        return .alert(Look.newest(s.installed), Look.newestText)
    }
}

// After --open: opened, and the window quits as after a start; failed<TAB><sentence>, and that sentence is shown;
// anything else, or no answer, and the tool is said not to have answered.
enum AfterOpen { case quit, failure(String) }
func afterOpen(_ output: String?) -> AfterOpen {
    let line = (output ?? "").split(separator: "\n", omittingEmptySubsequences: false).first.map(String.init) ?? ""
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    if f.first == "opened" { return .quit }
    if f.first == "failed", f.count >= 2, !f[1].isEmpty { return .failure(f[1]) }
    return .failure(Look.noAnswer)
}

// Which button of the update's sheet runs the update: the second, "Update", and nothing else. The first, "Not
// Now", is also what Escape gives (the key monitor ends a sheet as its first button).
func sheetAnswer(_ button: NSApplication.ModalResponse) -> String {
    button == .alertSecondButtonReturn ? "open" : "nothing"
}

// The tool in a folder, or none: the folder is an absolute path, and updates.sh in it is a regular file and not
// a link. None means no update parts at all.
func updateTool(_ dir: String) -> String? {
    guard dir.hasPrefix("/") else { return nil }
    let tool = dir + "/updates.sh"
    var st = stat()
    guard lstat(tool, &st) == 0, (st.st_mode & S_IFMT) == S_IFREG else { return nil }
    return tool
}

// L1UpdateDir, as common/make-launcher-app.sh wrote it into this program's own app (3.3), or none.
func updateKey() -> String? {
    guard let app = ownBundle(), let data = readPlainFile(app + "/Contents/Info.plist", limit: 1 << 20),   // a row's limit
          let d = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { return nil }
    return text(d["L1UpdateDir"])
}

// The one place the tool is run, by the window and by every text mode: /bin/bash <tool>, as a child with a time
// limit, with L1_UPDATE_DIR set for it to the folder in use. None when it did not exit 0 within the limit.
func askUpdate(_ tool: String, _ arguments: [String], limit: Double) -> String? {
    runChild("/bin/bash", [tool] + arguments, limit: limit, adding: ["L1_UPDATE_DIR": (tool as NSString).deletingLastPathComponent])
}

// One call's answer as a state, and for ready the notes with it, so that no child runs between a click on the
// foot line and its sheet.
func askState(_ tool: String, _ call: ([String], Double)) -> (UpdateState?, String?) {
    let state = askUpdate(tool, call.0, limit: call.1).flatMap(updateState)
    return (state, state?.word == "ready" ? askUpdate(tool, Call.notes.0, limit: Call.notes.1) : nil)
}

// The update itself: the tool writes the file Terminal runs and hands it over. Called on two lines only: by
// --update-open, and by the window after sheetAnswer said open.
func openUpdate(_ tool: String) -> AfterOpen {
    afterOpen(askUpdate(tool, ["--open"], limit: 10))
}

// ------------------------------------------------------------------------------------------------ the grid
// Plan 2.1 to 2.4: every size, colour and alpha of the window, read by the drawing and by --grid's paint lines.
// Statics, so that the text modes above the window can use them.
enum Look {
    static let tileW: CGFloat = 120, tileH: CGFloat = 146, margin: CGFloat = 24, gap: CGFloat = 8, rowGap: CGFloat = 8
    static let perRow = 4
    static let groupGap: CGFloat = 28
    static let least: CGFloat = 444
    static let most: CGFloat = 600
    static let top: CGFloat = 4, bottom: CGFloat = 22, labelAbove: CGFloat = 8, labelH: CGFloat = 16, labelBelow: CGFloat = 4
    static let icon: CGFloat = 64, iconTop: CGFloat = 6, titleGap: CGFloat = 9, secondGap: CGFloat = 4
    static let textW: CGFloat = 112
    static let titleLines = 2
    static let secondLines = 2
    static let titleLine: CGFloat = 15, secondLine: CGFloat = 13
    static let titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
    static let secondFont = NSFont.systemFont(ofSize: 10.5)
    static let labelFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
    static let secondAlpha: CGFloat = 0.88
    static let labelAlpha: CGFloat = 0.88
    static let shadowAlpha: CGFloat = 0.75, shadowBlur: CGFloat = 3
    static let pill = NSColor(srgbRed: 0, green: 0x59 / 255.0, blue: 0xD1 / 255.0, alpha: 1)   // not the accent (D15)
    static let plateFill: CGFloat = 0.16, hoverFill: CGFloat = 0.08
    static let outlineAlpha: CGFloat = 0.75
    static let outlineWidth: CGFloat = 1.5   // shows the selection by lightness, where the pill shows it by hue (D16)
    static let dimAlpha: CGFloat = 0.5
    static let topWhite: CGFloat = 0.24, bottomWhite: CGFloat = 0.09
    static let glow = NSColor(calibratedRed: 0.35, green: 0.45, blue: 0.75, alpha: 0.22)
    static let markAlpha: CGFloat = 0.075
    static let startOnPress = false
    static let noGames = "No games are set up on this Mac yet."
    static let readme = "https://github.com/macgameport/1launcher/blob/main/README.md"
    static let label = "Not set up on this Mac"

    // The placeholder of a game that is not set up (docs/plans/launcher-first-install.md, 3.10): the body of the
    // app's own icon, in its place and with its two whites, and the game's initials where the mark is. The radius
    // is of 1,024, as iconBody is; iconBitmap keeps its own literals, so the app's icon does not move with these.
    static let initialsTop: CGFloat = 0.32, initialsBottom: CGFloat = 0.13
    static let initialsRadius: CGFloat = 185
    static let initialsAlpha: CGFloat = 0.88
    static let initialsFont = NSFont.systemFont(ofSize: 22, weight: .semibold)
    static let initialsPad: CGFloat = 5

    // The update parts (docs/plans/built-in-update.md, 3.5). The foot line has the label's look: labelFont, white
    // at labelAlpha, labelH high, labelAbove below the last row; so the grid grows by 24 points with it. Its hit
    // area is its text's rectangle grown by footGrowX at the sides and footGrowY above and below; under the
    // pointer that area is filled white at hoverFill, with the radius footRadius. Every sentence of the update is
    // here: the window's own code holds none.
    static let footGrowX: CGFloat = 6, footGrowY: CGFloat = 4, footRadius: CGFloat = 4
    static let notesW: CGFloat = 380, notesH: CGFloat = 180, notesInset: CGFloat = 4
    static let notesFont = NSFont.systemFont(ofSize: 11)
    static func foot(_ version: String) -> String { "1launcher \(version) is out. Click to see what changed." }
    static func footSpoken(_ version: String) -> String { "1launcher \(version) is out, shows what changed" }
    static func out(_ version: String) -> String { "1launcher \(version) is out." }
    static func has(_ version: String) -> String { "This Mac has \(version)." }
    static let updateText = "Update opens Terminal and runs the installer again for 14unch3r and each game set up here. It may ask you a question there."
    static let notNow = "Not Now", update = "Update", ok = "OK"
    static let notesLabel = "What changed"
    static let notesAddress = "What changed: https://github.com/macgameport/1launcher/blob/release/CHANGELOG.md"
    static func quitFirst(_ title: String) -> String { "Quit \(title) first." }
    static let quitFirstText = "The update leaves a running game as it is. Quit it, then update."
    static let notOpened = "The update did not open."
    static let noAnswer = "The update tool did not answer."
    static let checkItem = "Check for Updates\u{2026}", checkKey = "u"
    static let offMessage = "Checking for updates is switched off on this Mac."
    static let offText = "The install guide says how to switch it on."
    static let noneMessage = "This Mac is not yet set up for updates."
    static let noneText = "Paste each game's installer line once more. After that, 14unch3r says when a new version is out."
    static let manualMessage = "No update is offered on this Mac."
    static let checkoutText = "14unch3r or a game here was set up from a checkout. Update with git pull, then run install.sh launcher and each game's setup."
    static let namedText = "14unch3r or a game here was set up from a named version. Paste the installer line from the guide again to follow new versions."
    static let unreadMessage = "The list of versions could not be read from GitHub."
    static let unreadText = "Check the network and try again later."
    static func newest(_ version: String) -> String { "1launcher \(version) is the newest version." }
    static let newestText = "A game set up before updates were recorded is not counted until its line is pasted once."
}

// The title bar's height, from a plain titled window: 32 on macOS 27, 28 before. With .fullSizeContentView,
// frameRect(forContentRect:) adds nothing (plan 2.2).
func titleBar() -> CGFloat {
    NSWindow.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: [.titled, .closable]).height - 100
}

struct Layout {
    var size = NSSize.zero
    var frames: [NSRect] = []
    var cells: [(Int, Int)] = []   // row and column, from 1
    var label: NSPoint? = nil
    var foot: NSRect? = nil   // the foot line's text (docs/plans/built-in-update.md, 3.5)
}

// Plan 2.1: games and Steam apps are one block, offers another; within a block the rows share one left edge, and
// each block is centred, so a game does not move when the offers arrive and the window widens about its middle.
// The foot line, when there is one and a tile to stand under: its text's width rounded up, centred, labelAbove
// below the last row, offers included, and labelH high; then the bottom margin as without it.
func gridLayout(_ apps: [Row], _ offers: [Row], foot: String? = nil) -> Layout {
    var out = Layout(), blocks: [[(y: CGFloat, xs: [CGFloat], w: CGFloat)]] = [[], []]
    var y = Look.top, rows = 0, labelY: CGFloat? = nil
    for (bi, group) in [apps, offers].enumerated() {
        for start in stride(from: 0, to: group.count, by: Look.perRow) {
            let part = Array(group[start..<min(start + Look.perRow, group.count)])
            if bi == 1 && start == 0 {
                if rows > 0 { y += Look.labelAbove }
                labelY = y
                y += Look.labelH + Look.labelBelow
            } else if rows > 0 { y += Look.rowGap }
            var x: CGFloat = 0, xs: [CGFloat] = []
            for (i, r) in part.enumerated() {
                if i > 0 { x += r.role == .steam && part[i - 1].role == .game ? Look.groupGap : Look.gap }
                xs.append(x)
                x += Look.tileW
            }
            blocks[bi].append((y, xs, x))
            rows += 1
            y += Look.tileH
        }
    }
    let widest = blocks.joined().map { $0.w }.max() ?? 0
    let width = max(widest + 2 * Look.margin, Look.least)
    for (bi, block) in blocks.enumerated() {
        let blockW = block.map { $0.w }.max() ?? 0
        let left = ((width - blockW) / 2).rounded()
        for line in block {
            let row = out.cells.last.map { $0.0 + 1 } ?? 1
            for (ci, x) in line.xs.enumerated() {
                out.frames.append(NSRect(x: left + x, y: line.y, width: Look.tileW, height: Look.tileH))
                out.cells.append((row, ci + 1))
            }
        }
        if bi == 1, let ly = labelY { out.label = NSPoint(x: left, y: ly) }
    }
    if let line = foot, rows > 0 {
        let w = plain(line, Look.labelFont).size().width.rounded(.up)
        out.foot = NSRect(x: ((width - w) / 2).rounded(), y: y + Look.labelAbove, width: w, height: Look.labelH)
        y += Look.labelAbove + Look.labelH
    }
    out.size = NSSize(width: width, height: (rows == 0 ? Look.top + Look.tileH : y) + Look.bottom)
    return out
}

// The mark behind the tiles, plan 2.5, in a view whose y runs up from its bottom edge: a side of 0.75 of the width,
// its left edge not rounded, its bottom 0.08 of its side below the window's bottom edge.
func markBox(width: CGFloat) -> NSRect {
    let side = (0.75 * width).rounded()
    return NSRect(x: (width - side) / 2, y: -(0.08 * side).rounded(), width: side, height: side)
}

// Plan 2.1: the offset nearest the one before at which the tile's frame, grown by 4 above and 22 below, is shown.
func scrollOffset(for f: NSRect, from before: CGFloat, shown: CGFloat) -> CGFloat {
    let top = f.minY - Look.top, bottom = f.maxY + Look.bottom
    if top < before { return max(0, top) }
    if bottom > before + shown { return bottom - shown }
    return before
}

func plain(_ s: String, _ font: NSFont) -> NSAttributedString { NSAttributedString(string: s, attributes: [.font: font]) }

func firstGlyph(_ run: CTRun) -> CGGlyph {
    var g = CGGlyph(0)
    CTRunGetGlyphs(run, CFRange(location: 0, length: 1), &g)
    return g
}

// One line at most Look.textW wide, cut by CTLineCreateTruncatedLine (plan 2.4). The run that holds the ellipsis
// reports the range it stands for, so the string shown is the string with that range replaced.
func cut(_ s: String, _ font: NSFont, _ type: CTLineTruncationType) -> String {
    let line = CTLineCreateWithAttributedString(plain(s, font))
    if CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) <= Look.textW { return s }
    let token = CTLineCreateWithAttributedString(plain("\u{2026}", font))
    guard let short = CTLineCreateTruncatedLine(line, Double(Look.textW), type, token),
          let mark = (CTLineGetGlyphRuns(token) as? [CTRun])?.first.map(firstGlyph) else { return "\u{2026}" }
    for run in CTLineGetGlyphRuns(short) as? [CTRun] ?? [] where CTRunGetGlyphCount(run) == 1 && firstGlyph(run) == mark {
        let r = CTRunGetStringRange(run)
        return (s as NSString).replacingCharacters(in: NSRange(location: r.location, length: r.length), with: "\u{2026}")
    }
    return s
}

// Word-wrapped at Look.textW, at most `most` lines, the last cut at its tail when there is more.
func wrap(_ s: String, _ font: NSFont, most: Int) -> [String] {
    let ns = s as NSString
    let setter = CTFramesetterCreateWithAttributedString(plain(s, font))
    let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0),
                                         CGPath(rect: CGRect(x: 0, y: 0, width: Look.textW, height: 10_000), transform: nil), nil)
    let ranges = (CTFrameGetLines(frame) as? [CTLine] ?? []).map { CTLineGetStringRange($0) }
    func part(_ from: Int, _ to: Int) -> String {
        ns.substring(with: NSRange(location: from, length: to - from)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if ranges.count <= most { return ranges.map { part($0.location, $0.location + $0.length) } }
    var out = ranges.prefix(most - 1).map { part($0.location, $0.location + $0.length) }
    out.append(cut(part(ranges[most - 1].location, ns.length), font, .end))
    return out
}

// The title as a tile shows it (2.4). Two apps with one title: the title on line 1, and on line 2 the file name
// cut in its middle, so that its end stays, where copies differ.
func shownTitle(_ r: Row) -> [String] {
    if r.title != r.sortTitle {
        return [cut(r.sortTitle, Look.titleFont, .end),
                cut((r.path as NSString).lastPathComponent, Look.titleFont, .middle)]
    }
    return wrap(r.title, Look.titleFont, most: Look.titleLines)
}

// The second line as a tile shows it (2.4): three sentences are shortened there. The full one is VoiceOver's.
func shownSecond(_ r: Row) -> String {
    if r.role == .offer { return "Not set up. Opens its guide." }
    if r.state == .absent { return r.role == .steam ? "Windows Steam not found" : "Not installed in Steam" }
    return secondLine(r)
}
func spoken(_ r: Row) -> String {
    if r.role == .offer { return "\(r.title), not set up on this Mac, opens the set-up guide in your browser" }
    let second = secondLine(r)
    return second.isEmpty ? r.title : "\(r.title), \(second)"
}
// Grey tiles (2.4, D23): what cannot start as it is. An offer is grey by its placeholder, which is drawn in grey
// at full strength; a set-up game or a Steam app that is absent is grey by greyed() at Look.dimAlpha.
func dim(_ r: Row) -> Bool { r.role == .offer || r.state == .absent }

// The placeholder (docs/plans/launcher-first-install.md, 3.10). The letters of a title: the first two initials.
// A word's initial is its first letter or digit, made upper case; a word with neither gives none ("&"); a word
// after the first that is only a number, in digits or in the capitals I, V and X, gives none ("II", "2"). The
// title is a label: the letters are worked out each time and stored nowhere.
func initials(_ title: String) -> String {
    var out = ""
    for (i, word) in title.split(whereSeparator: { $0.isWhitespace }).enumerated() where out.count < 2 {
        let core = word.filter { $0.isLetter || $0.isNumber }
        guard let first = core.first else { continue }
        if i > 0, core.allSatisfy({ $0.isNumber }) || core.allSatisfy({ "IVX".contains($0) }) { continue }
        if let upper = String(first).uppercased().first { out.append(upper) }
    }
    return out
}
// Which picture a tile draws: its app's own icon, or the placeholder with these letters. The drawing and
// --grid both ask this, so what a test reads is what the window draws.
enum TileIcon { case app, initials(String) }
func tileIcon(_ r: Row) -> TileIcon { r.role == .offer ? .initials(initials(r.sortTitle)) : .app }
// The placeholder's square in a picture of that rectangle: iconBody's place, scaled from its 1,024
func placeholderSquare(_ rect: NSRect) -> NSRect {
    let k = rect.width / 1024
    return NSRect(x: rect.minX + iconBody.minX * k, y: rect.minY + iconBody.minY * k, width: iconBody.width * k, height: iconBody.height * k)
}
// The body alone, into the current context, whose y runs up: the rounded square, lighter at its top
func drawPlaceholderBody(in rect: NSRect) {
    let r = Look.initialsRadius * rect.width / 1024
    let shape = NSBezierPath(roundedRect: placeholderSquare(rect), xRadius: r, yRadius: r)
    NSGradient(starting: NSColor(white: Look.initialsTop, alpha: 1), ending: NSColor(white: Look.initialsBottom, alpha: 1))?.draw(in: shape, angle: -90)
}
// The letters as drawn, and their rectangle in a picture of that rectangle: centred in the square on one line,
// and drawn smaller, in proportion, when they are wider than the square less the pad at each side.
func placeholderLetters(_ letters: String, in rect: NSRect) -> (NSAttributedString, NSRect) {
    let square = placeholderSquare(rect), room = square.width - 2 * Look.initialsPad
    func drawn(_ font: NSFont) -> NSAttributedString {
        NSAttributedString(string: letters, attributes: [.font: font, .foregroundColor: NSColor(white: 1, alpha: Look.initialsAlpha)])
    }
    var text = drawn(Look.initialsFont)
    let w = text.size().width
    if w > room, w > 0, let smaller = NSFont(descriptor: Look.initialsFont.fontDescriptor, size: Look.initialsFont.pointSize * room / w) {
        text = drawn(smaller)
    }
    let size = text.size()
    return (text, NSRect(x: square.midX - size.width / 2, y: square.midY - size.height / 2, width: size.width, height: size.height))
}
// The picture of a game that is not set up, Look.icon points a side, drawn from the title's letters and from
// constants alone, at the screen's own scale each time: no bitmap is kept, and no file or request is behind it.
func placeholderIcon(_ title: String) -> NSImage {
    let letters = initials(title)
    return NSImage(size: NSSize(width: Look.icon, height: Look.icon), flipped: false) { rect in
        drawPlaceholderBody(in: rect)
        if !letters.isEmpty {
            let (text, at) = placeholderLetters(letters, in: rect)
            text.draw(at: at.origin)
        }
        return true
    }
}

// Plan 2.7: what a key does. The window's monitor and --act both ask this; the arrows are the grid's keyDown.
enum KeyAction: String { case start, quit, endSheet = "end-sheet", pass }
func keyAction(_ code: UInt16, sheetUp: Bool) -> KeyAction {
    switch code {
    case 49: return sheetUp ? .pass : .start   // Space: under a sheet an alert's buttons keep it
    case 36, 76: return sheetUp ? .pass : .start   // Return, Enter
    case 53: return sheetUp ? .endSheet : .quit   // Escape: "Don't Start" in the question
    default: return .pass
    }
}

func greyed(_ image: NSImage) -> NSImage {
    let px = Int(Look.icon * 2)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return image }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    image.draw(in: NSRect(x: 0, y: 0, width: px, height: px))   // a bitmap's own context counts in pixels
    NSGraphicsContext.restoreGraphicsState()
    guard let grey = rep.converting(to: .genericGamma22Gray, renderingIntent: .default) else { return image }
    grey.size = NSSize(width: Look.icon, height: Look.icon)
    let out = NSImage(size: grey.size)
    out.addRepresentation(grey)
    return out
}

func textShadow() -> NSShadow {
    let sh = NSShadow()
    sh.shadowColor = NSColor(white: 0, alpha: Look.shadowAlpha)
    sh.shadowBlurRadius = Look.shadowBlur
    sh.shadowOffset = NSSize(width: 0, height: -1)
    return sh
}

func centred(_ s: String, _ font: NSFont, alpha: CGFloat, shadow: Bool) -> NSAttributedString {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineBreakMode = .byClipping
    var a: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: para, .foregroundColor: NSColor(white: 1, alpha: alpha)]
    if shadow { a[.shadow] = textShadow() }
    return NSAttributedString(string: s, attributes: a)
}

final class TileView: NSView {
    let row: Row
    let cell: (Int, Int)
    let title: [String]
    let second: [String]
    weak var grid: GridView?
    var selected = false { didSet { if selected != oldValue { needsDisplay = true } } }
    var hovered = false { didSet { if hovered != oldValue { needsDisplay = true } } }

    init(_ r: Row, frame: NSRect, cell: (Int, Int)) {
        row = r
        self.cell = cell
        title = shownTitle(r)
        let s = shownSecond(r)
        second = s.isEmpty ? [] : wrap(s, Look.secondFont, most: Look.secondLines)
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(spoken(r))
        let full = secondLine(r)
        toolTip = full.isEmpty ? r.title : r.title + "\n" + full
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }

    // The tooltip would otherwise be read again after the label (plan 2.4).
    override func accessibilityHelp() -> String? { nil }
    // The selected tile is VoiceOver's: a move with the arrows is spoken, and Return starts the tile just read.
    override func isAccessibilityFocused() -> Bool { selected }
    override func setAccessibilityFocused(_ f: Bool) { if f { grid?.focus(self) } }
    override func accessibilityPerformPress() -> Bool { grid?.pressed(self) ?? false }

    var iconRect: NSRect { NSRect(x: (bounds.width - Look.icon) / 2, y: Look.iconTop, width: Look.icon, height: Look.icon) }
    var plateRect: NSRect { iconRect.insetBy(dx: -7, dy: -6) }
    var titleRect: NSRect {
        NSRect(x: (bounds.width - Look.textW) / 2, y: iconRect.maxY + Look.titleGap, width: Look.textW, height: CGFloat(title.count) * Look.titleLine)
    }
    var secondRect: NSRect {
        NSRect(x: titleRect.minX, y: titleRect.maxY + Look.secondGap, width: Look.textW, height: CGFloat(second.count) * Look.secondLine)
    }

    override func draw(_ dirty: NSRect) {
        if selected || hovered {
            NSColor(white: 1, alpha: selected ? Look.plateFill : Look.hoverFill).setFill()
            NSBezierPath(roundedRect: plateRect, xRadius: 10, yRadius: 10).fill()
            if selected && Look.outlineWidth > 0 {
                let w = Look.outlineWidth
                let line = NSBezierPath(roundedRect: plateRect.insetBy(dx: w / 2, dy: w / 2), xRadius: 10 - w / 2, yRadius: 10 - w / 2)
                line.lineWidth = w
                NSColor(white: 1, alpha: Look.outlineAlpha).setStroke()
                line.stroke()
            }
        }
        switch tileIcon(row) {
        case .app:   // the app's own icon; grey, through greyed() at dimAlpha, only when it cannot start as it is
            let image = NSWorkspace.shared.icon(forFile: row.path), grey = dim(row)
            (grey ? greyed(image) : image).draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: grey ? Look.dimAlpha : 1,
                                                respectFlipped: true, hints: nil)
        case .initials:   // the placeholder: grey by its own constants, painted at full strength (3.10)
            placeholderIcon(row.sortTitle).draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        if selected {
            let w = min(title.map { plain($0, Look.titleFont).size().width }.max() ?? 0, Look.textW).rounded(.up)
            Look.pill.setFill()
            NSBezierPath(roundedRect: NSRect(x: titleRect.midX - w / 2, y: titleRect.minY, width: w, height: titleRect.height).insetBy(dx: -5, dy: -1),
                         xRadius: 4, yRadius: 4).fill()
        }
        for (i, s) in title.enumerated() {
            centred(s, Look.titleFont, alpha: 1, shadow: !selected)
                .draw(with: NSRect(x: titleRect.minX, y: titleRect.minY + CGFloat(i) * Look.titleLine, width: Look.textW, height: Look.titleLine),
                      options: [.usesLineFragmentOrigin])
        }
        for (i, s) in second.enumerated() {
            centred(s, Look.secondFont, alpha: Look.secondAlpha, shadow: true)
                .draw(with: NSRect(x: secondRect.minX, y: secondRect.minY + CGFloat(i) * Look.secondLine, width: Look.textW, height: Look.secondLine),
                      options: [.usesLineFragmentOrigin])
        }
    }
}

// The foot line (docs/plans/built-in-update.md, 3.5): a subview of the grid, added after the tiles, so VoiceOver
// reaches it after them. It is no tile: the arrows pass it by and it is never selected. Its frame is its hit
// area; the grid takes its clicks, as it takes the tiles'.
final class FootView: NSView {
    let line: String
    weak var grid: GridView?
    var hovered = false { didSet { if hovered != oldValue { needsDisplay = true } } }

    init(_ line: String, spoken: String, frame: NSRect) {
        self.line = line
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(NSAccessibility.Role.button)
        setAccessibilityLabel(spoken)
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    override func accessibilityPerformPress() -> Bool { grid?.footPressed() ?? false }

    var textRect: NSRect { bounds.insetBy(dx: Look.footGrowX, dy: Look.footGrowY) }
    override func draw(_ dirty: NSRect) {
        if hovered {
            NSColor(white: 1, alpha: Look.hoverFill).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: Look.footRadius, yRadius: Look.footRadius).fill()
        }
        NSAttributedString(string: line, attributes: [.font: Look.labelFont, .foregroundColor: NSColor(white: 1, alpha: Look.labelAlpha)])
            .draw(with: textRect, options: [.usesLineFragmentOrigin])
    }
}

// The tiles, plan 2.7: the window's only key view. Hit testing is its own function over the tile frames.
final class GridView: NSView {
    var tiles: [TileView] = []
    var selection: Int? = nil
    var armed: String? = nil   // the key of the tile a press armed
    var footState: UpdateState? = nil   // what the foot line is drawn from at the next show: the caller sets it
    var foot: FootView? = nil
    var footArmed = false      // a press armed the foot line
    var labelAt: NSPoint? = nil
    var offset: CGFloat = 0
    var lastArrow = false
    var onStart: (Row) -> Void = { _ in }
    var onQuit: () -> Void = {}
    var onFoot: () -> Void = {}   // a click on the foot line: the window shows the update's sheet
    var blocked: () -> Bool = { false }
    var hoverArea: NSTrackingArea?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Games")
        setAccessibilityHelp("Click a game, or press Return, to start it or set it up.")
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { false }   // a first click only activates the window

    var chosen: Row? { selection.map { tiles[$0].row } }
    var shown: CGFloat { min(frame.height, Look.most) }
    func unblocked() -> Bool { !blocked() }   // nothing while a start is under way or a sheet is up

    // Fills the grid, at open and at every reload. The selection stays on the same app, else defaultRow's.
    func show(rows apps: [Row], offers: [Row], last: Int?) {
        let keep = chosen?.key
        let line = footText(footState)
        let l = gridLayout(apps, offers, foot: line)
        tiles.forEach { $0.removeFromSuperview() }
        tiles = (apps + offers).enumerated().map { TileView($1, frame: l.frames[$0], cell: l.cells[$0]) }
        for t in tiles { t.grid = self; addSubview(t) }
        foot?.removeFromSuperview()
        foot = nil
        if let text = line, let r = l.foot, let s = footState {   // after the tiles, at every show
            let f = FootView(text, spoken: Look.footSpoken(s.offered), frame: r.insetBy(dx: -Look.footGrowX, dy: -Look.footGrowY))
            f.grid = self
            addSubview(f)
            foot = f
        }
        footArmed = false
        labelAt = l.label
        setFrameSize(l.size)
        armed = nil   // a reload disarms
        selection = nil
        // with no app at all the first offer is selected, so that the keys reach a tile on a Mac with the launcher alone
        let pick = tiles.firstIndex { $0.row.key == keep } ?? (defaultRow(apps, last: last) ?? offers.first).flatMap { d in tiles.firstIndex { $0.row.key == d.key } }
        if let i = pick { select(i, announce: tiles[i].row.key != keep) } else { offset = 0 }
        window?.invalidateCursorRects(for: self)
        needsDisplay = true
    }

    func select(_ i: Int, announce: Bool = true) {
        let was = selection
        selection = i
        for (k, t) in tiles.enumerated() { t.selected = k == i }
        let before = enclosingScrollView?.contentView.bounds.minY ?? offset
        offset = scrollOffset(for: tiles[i].frame, from: before, shown: shown)
        // With the foot line, a tile of the last row is shown down to the grid's end.
        if let line = footRect, tiles[i].cell.0 == tiles.last?.cell.0 { offset = scrollOffset(for: tiles[i].frame.union(line), from: offset, shown: shown) }
        if let sv = enclosingScrollView {
            sv.contentView.scroll(to: NSPoint(x: 0, y: offset))
            sv.reflectScrolledClipView(sv.contentView)
        }
        if announce && was != i { NSAccessibility.post(element: tiles[i], notification: .focusedUIElementChanged) }
    }

    func tile(at p: NSPoint) -> Int? { tiles.firstIndex { NSPointInRect(p, $0.frame) } }

    // A press selects and arms its tile; the row returned is started now, which is none: a start is a release.
    func press(at p: NSPoint) -> Row? {
        armed = nil
        guard unblocked(), let i = tile(at: p) else { return nil }
        armed = tiles[i].row.key
        select(i)
        return Look.startOnPress ? tiles[i].row : nil
    }
    // A release on the armed tile, with a click count of 1, starts it; anything else starts nothing.
    func release(at p: NSPoint, clicks: Int) -> Row? {
        defer { armed = nil }
        guard unblocked(), clicks == 1, let i = tile(at: p), tiles[i].row.key == armed else { return nil }
        return tiles[i].row
    }
    func pressed(_ t: TileView) -> Bool {   // VoiceOver's press
        guard unblocked(), let i = tiles.firstIndex(where: { $0 === t }) else { return false }
        select(i)
        onStart(t.row)   // the press action starts the tile
        return true
    }
    func focus(_ t: TileView) {
        if let i = tiles.firstIndex(where: { $0 === t }) { select(i) }
    }

    // The foot line, by the tiles' rule: a press arms it, and a release on it with a click count of 1 is its
    // click, with blocked asked first. It selects nothing and starts nothing.
    var footRect: NSRect? { foot.map { $0.frame.insetBy(dx: Look.footGrowX, dy: Look.footGrowY) } }
    func onFootLine(_ p: NSPoint) -> Bool { foot.map { NSPointInRect(p, $0.frame) } ?? false }
    func pressFoot(at p: NSPoint) -> Bool {
        footArmed = false
        guard unblocked(), onFootLine(p) else { return false }
        footArmed = true
        return true
    }
    func releaseFoot(at p: NSPoint, clicks: Int) -> Bool {
        defer { footArmed = false }
        guard unblocked(), clicks == 1, onFootLine(p), footArmed else { return false }
        return true
    }
    func footPressed() -> Bool {   // VoiceOver's press
        guard unblocked(), foot != nil else { return false }
        onFoot()   // the press action is the click
        return true
    }

    // Return, Enter and Space start the selection (through blocked); Escape quits.
    func perform(_ a: KeyAction) -> Bool {
        switch a {
        case .start:
            guard unblocked(), let r = chosen else { return false }
            onStart(r)
            return true
        case .quit:
            onQuit()
            return true
        case .endSheet, .pass:
            return false
        }
    }

    // Left and Right through the whole order; Up and Down to the nearest tile in x of the next row, the left one
    // on a tie. Both stay put at an end.
    func arrow(_ code: UInt16) -> Bool {
        guard unblocked(), let i = selection, [123, 124, 125, 126].contains(code) else { return false }
        switch code {
        case 123, 124:
            select(max(0, min(i + (code == 124 ? 1 : -1), tiles.count - 1)))
        default:
            let from = tiles[i], d = code == 125 ? 1 : -1
            let next = tiles.indices.filter { tiles[$0].cell.0 == from.cell.0 + d }
            if let to = next.min(by: { abs(tiles[$0].frame.midX - from.frame.midX) < abs(tiles[$1].frame.midX - from.frame.midX) }) { select(to) }
        }
        return true
    }

    override func keyDown(with e: NSEvent) {
        lastArrow = arrow(e.keyCode)
        if !lastArrow { super.keyDown(with: e) }
    }
    override func mouseDown(with e: NSEvent) {
        _ = pressFoot(at: convert(e.locationInWindow, from: nil))
        if let r = press(at: convert(e.locationInWindow, from: nil)) { onStart(r) }
    }
    override func mouseUp(with e: NSEvent) {
        if releaseFoot(at: convert(e.locationInWindow, from: nil), clicks: e.clickCount) { onFoot() }
        if let r = release(at: convert(e.locationInWindow, from: nil), clicks: e.clickCount) { onStart(r) }
    }

    // Hover only in the key window, where a click acts (plan 2.4).
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let h = hoverArea { removeTrackingArea(h) }
        let h = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(h)
        hoverArea = h
    }
    func hover(at p: NSPoint?) {
        let i = p.flatMap { tile(at: $0) }
        for (k, t) in tiles.enumerated() { t.hovered = k == i }
        foot?.hovered = p.map(onFootLine) ?? false
    }
    override func mouseMoved(with e: NSEvent) { hover(at: convert(e.locationInWindow, from: nil)) }
    override func mouseExited(with e: NSEvent) { hover(at: nil) }
    override func resetCursorRects() {
        for t in tiles { addCursorRect(t.frame, cursor: .pointingHand) }
        if let f = foot { addCursorRect(f.frame, cursor: .pointingHand) }
    }

    var labelRect: NSRect? {
        labelAt.map { NSRect(x: $0.x, y: $0.y, width: plain(Look.label, Look.labelFont).size().width.rounded(.up), height: Look.labelH) }
    }
    override func draw(_ dirty: NSRect) {
        guard let r = labelRect else { return }
        NSAttributedString(string: Look.label, attributes: [.font: Look.labelFont, .foregroundColor: NSColor(white: 1, alpha: Look.labelAlpha)])
            .draw(with: r, options: [.usesLineFragmentOrigin])
    }
}

// The one place a grid is made (plan 2.7, section 6): the window, --grid and --act all use it.
@MainActor func makeGrid() -> GridView { GridView(frame: .zero) }

// Plan 2.3: the gradient, the glow and the mark, under the title bar too.
final class BackgroundView: NSView {
    override func draw(_ dirty: NSRect) {
        NSGradient(starting: NSColor(white: Look.topWhite, alpha: 1), ending: NSColor(white: Look.bottomWhite, alpha: 1))?.draw(in: bounds, angle: -90)
        let c = NSPoint(x: bounds.width * 0.15, y: bounds.height)
        NSGradient(starting: Look.glow, ending: .clear)?.draw(fromCenter: c, radius: 0, toCenter: c, radius: bounds.width * 0.7, options: [])
        NSColor(white: 1, alpha: Look.markAlpha).setStroke()
        markPath(in: markBox(width: bounds.width)).stroke()
    }
}

func num(_ v: CGFloat) -> String { v == v.rounded() ? String(Int(v)) : String(Double(v)) }

// WCAG: sRGB relative luminance, and the ratio of two of them.
func luminance(_ c: (CGFloat, CGFloat, CGFloat)) -> CGFloat {
    func lin(_ v: CGFloat) -> CGFloat { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
}
func ratio(_ a: (CGFloat, CGFloat, CGFloat), _ b: (CGFloat, CGFloat, CGFloat)) -> CGFloat {
    let x = luminance(a), y = luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
}
func white(_ alpha: CGFloat, over b: (CGFloat, CGFloat, CGFloat)) -> (CGFloat, CGFloat, CGFloat) {
    (alpha + (1 - alpha) * b.0, alpha + (1 - alpha) * b.1, alpha + (1 - alpha) * b.2)
}

// --grid's line `paint initials` (docs/plans/launcher-first-install.md, 3.10): the lowest ratio of the letters'
// colour against the placeholder's body under them, over every tile that draws a placeholder with letters; or -
// when none does. The body is drawn with no letters into a bitmap of its own, a pixel to a point.
@MainActor func initialsRatio(_ grid: GridView) -> String {
    var lowest: CGFloat? = nil
    let side = Int(Look.icon), box = NSRect(x: 0, y: 0, width: Look.icon, height: Look.icon)
    for t in grid.tiles {
        guard case .initials(let letters) = tileIcon(t.row), !letters.isEmpty else { continue }
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4,
                                         hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep), let data = rep.bitmapData else { continue }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        drawPlaceholderBody(in: box)
        NSGraphicsContext.restoreGraphicsState()
        let at = placeholderLetters(letters, in: box).1
        for y in max(0, Int(at.minY.rounded(.down)))..<min(side, Int(at.maxY.rounded(.up))) {
            for x in max(0, Int(at.minX.rounded(.down)))..<min(side, Int(at.maxX.rounded(.up))) {
                let p = data + (side - 1 - y) * rep.bytesPerRow + x * 4   // the bitmap's rows run down, the picture's y up
                let b = (CGFloat(p[0]) / 255, CGFloat(p[1]) / 255, CGFloat(p[2]) / 255)
                let r = ratio(white(Look.initialsAlpha, over: b), b)
                if lowest == nil || r < lowest! { lowest = r }
            }
        }
    }
    return lowest.map { String(format: "%.2f", $0) } ?? "-"
}

// --grid's paint lines (section 4): the real background at the window's size, bar included, and the lowest ratio
// of each kind of text over every pixel under any rectangle of that kind.
@MainActor func paintLines(_ grid: GridView) -> [String] {
    let bar = titleBar(), w = Int(grid.frame.width), h = Int(grid.shown + bar)
    let back = BackgroundView(frame: NSRect(x: 0, y: 0, width: w, height: h))
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let data = rep.bitmapData else { return [] }
    back.cacheDisplay(in: back.bounds, to: rep)
    func under(_ rects: [NSRect]) -> [(CGFloat, CGFloat, CGFloat)] {   // grid points, y down from the grid's top
        var out: [(CGFloat, CGFloat, CGFloat)] = []
        for r in rects {
            for y in Int(r.minY.rounded(.down))..<Int(r.maxY.rounded(.up)) {
                let py = y + Int(bar)
                guard py >= 0, py < h else { continue }
                for x in max(0, Int(r.minX.rounded(.down)))..<min(w, Int(r.maxX.rounded(.up))) {
                    let p = data + py * rep.bytesPerRow + x * 4
                    out.append((CGFloat(p[0]) / 255, CGFloat(p[1]) / 255, CGFloat(p[2]) / 255))
                }
            }
        }
        return out
    }
    func lowest(_ rects: [NSRect], _ alpha: CGFloat) -> String {
        let px = under(rects)
        guard !px.isEmpty else { return "-" }
        return String(format: "%.2f", px.map { ratio(white(alpha, over: $0), $0) }.min()!)
    }
    func inGrid(_ t: TileView, _ r: NSRect) -> NSRect { r.offsetBy(dx: t.frame.minX, dy: t.frame.minY) }
    let p = Look.pill.usingColorSpace(.sRGB) ?? Look.pill
    let pill = (p.redComponent, p.greenComponent, p.blueComponent)
    var lines = [["paint", "pill", String(format: "#%02X%02X%02X", Int((pill.0 * 255).rounded()), Int((pill.1 * 255).rounded()), Int((pill.2 * 255).rounded())),
                  String(format: "%.2f", ratio((1, 1, 1), pill))].joined(separator: "\t")]
    lines.append(["paint", "title", lowest(grid.tiles.map { inGrid($0, $0.titleRect) }, 1)].joined(separator: "\t"))
    lines.append(["paint", "second", lowest(grid.tiles.filter { !$0.second.isEmpty }.map { inGrid($0, $0.secondRect) }, Look.secondAlpha)].joined(separator: "\t"))
    lines.append(["paint", "label", lowest([grid.labelRect, grid.footRect].compactMap { $0 }, Look.labelAlpha)].joined(separator: "\t"))
    lines.append(["paint", "initials", initialsRatio(grid)].joined(separator: "\t"))
    if Look.outlineWidth > 0, let i = grid.selection {
        let px = under([inGrid(grid.tiles[i], grid.tiles[i].plateRect)])
        let onBack = px.map { ratio(white(Look.outlineAlpha, over: $0), $0) }.min() ?? 0
        let onPlate = px.map { b -> CGFloat in let fill = white(Look.plateFill, over: b); return ratio(white(Look.outlineAlpha, over: fill), fill) }.min() ?? 0
        lines.append(["paint", "outline", String(format: "%.2f", onBack), String(format: "%.2f", onPlate)].joined(separator: "\t"))
    } else {
        lines.append(["paint", "outline", "-"].joined(separator: "\t"))
    }
    return lines
}

// --grid and --act, plan section 4: the real views, with no window.
@MainActor func gridMode(_ mode: String, _ given: [String]) {
    var rest = given, steps: [String] = []
    if mode == "--act" {
        guard let s = rest.first else { usage() }
        steps = s.split(separator: ",").map(String.init)
        rest.removeFirst()
    }
    let (table, afterTable) = gamesOption(rest)
    let (updateDir, more) = updateOption(afterTable)
    guard more.count >= 2 else { usage() }
    let folders = Array(more.dropFirst())
    let found = rows(in: folders)
    let offers = table.map { withOwnership(tableOffers($0, folders, found), offerRows($0, found)) } ?? []
    let last = lastID(more[0])
    let grid = makeGrid()
    // The foot line, as the window draws it from the tool's first answer: asked only when --update-dir is given.
    grid.footState = updateDir.flatMap(updateTool).flatMap { askUpdate($0, Call.state.0, limit: Call.state.1) }.flatMap(updateState)
    grid.show(rows: found, offers: offers, last: last)
    func out(_ f: [String]) { print(f.joined(separator: "\t")) }
    if mode == "--grid" {
        let box = markBox(width: grid.frame.width)
        out(["size", num(grid.frame.width), num(grid.frame.height)])
        out(["window", num(grid.frame.width), num(grid.shown)])
        out(["mark", num(box.width), num(box.minX), num(-box.minY)])
        out(["group", grid.accessibilityRole()?.rawValue ?? "-", grid.accessibilityLabel() ?? "-", grid.accessibilityHelp() ?? "-"])
        if let at = grid.labelAt { out(["label", num(at.x), num(at.y), Look.label]) }
        for (i, t) in grid.tiles.enumerated() {
            out(["tile", String(t.cell.0), String(t.cell.1), num(t.frame.minX), num(t.frame.minY), t.row.role.rawValue,
                 grid.selection == i ? "selected" : "-", dim(t.row) ? "dim" : "-", t.accessibilityRole()?.rawValue ?? "-",
                 t.accessibilityLabel() ?? "-", t.accessibilityHelp().flatMap { $0.isEmpty ? nil : $0 }.map(oneLine) ?? "-",
                 String(t.title.count), t.title.joined(separator: " | "), t.second.isEmpty ? "-" : t.second.joined(separator: " "),
                 { if case .initials(let letters) = tileIcon(t.row) { return "icon=initials:" + letters } else { return "icon=app" } }()])
        }
        if let f = grid.foot, let r = grid.footRect {
            out(["foot", num(r.minX), num(r.minY), num(r.width), num(r.height), f.line, f.accessibilityRole()?.rawValue ?? "-", f.accessibilityLabel() ?? "-"])
        }
        if grid.tiles.isEmpty { out(["empty", Look.noGames, Look.readme]) }
        let first = grid.acceptsFirstMouse(for: nil) || grid.tiles.contains { $0.acceptsFirstMouse(for: nil) }
        out(["first-click", first ? "starts" : "activates"])
        paintLines(grid).forEach { print($0) }
        return
    }
    var started: Row? = nil, quit = false, blocked = false, footed = false
    grid.onStart = { started = $0 }
    grid.onQuit = { quit = true }
    grid.onFoot = { footed = true }
    grid.blocked = { blocked }
    let codes: [String: UInt16] = ["left": 123, "right": 124, "down": 125, "up": 126, "return": 36, "enter": 76, "space": 49, "escape": 53]
    func point(_ s: String) -> NSPoint? {
        let f = s.split(separator: ":").dropFirst().compactMap { Double($0) }
        return f.count == 2 ? NSPoint(x: f[0], y: f[1]) : nil
    }
    func tileNumber(_ s: String) -> TileView? {
        guard let n = Int(s.split(separator: ":").last ?? ""), n >= 1, n <= grid.tiles.count else { return nil }
        return grid.tiles[n - 1]
    }
    for s in steps {
        started = nil
        quit = false
        footed = false
        var word = ["nothing"]
        let selected = { ["selected", grid.chosen?.title ?? "-"] }
        if let code = codes[s], code >= 123 {
            guard let e = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
                                           characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code) else { usage() }
            grid.keyDown(with: e)
            if grid.lastArrow { word = selected() }
        } else if let code = codes[s] ?? (s.hasPrefix("sheet:") ? codes[String(s.dropFirst(6))] : nil) {
            let a = keyAction(code, sheetUp: s.hasPrefix("sheet:"))
            if a == .pass || a == .endSheet { word = [a.rawValue] } else { _ = grid.perform(a) }
        } else if s.hasPrefix("press:"), let p = point(s) {
            let onFoot = grid.pressFoot(at: p)
            if let r = grid.press(at: p) { started = r } else if grid.armed != nil { word = selected() } else if onFoot { word = ["armed", "foot"] }
        } else if s.hasPrefix("release:") || s.hasPrefix("release2:"), let p = point(s) {
            if grid.releaseFoot(at: p, clicks: s.hasPrefix("release2:") ? 2 : 1) { grid.onFoot() }
            started = grid.release(at: p, clicks: s.hasPrefix("release2:") ? 2 : 1)
        } else if s == "foot" {   // a press and a release at the middle of the foot line
            let c = grid.footRect.map { NSPoint(x: $0.midX, y: $0.midY) }
            if let c = c, grid.pressFoot(at: c), grid.releaseFoot(at: c, clicks: 1) { grid.onFoot() }
        } else if s == "axpress:foot" {
            _ = grid.foot?.accessibilityPerformPress()
        } else if s.hasPrefix("axpress:"), let t = tileNumber(s) {
            _ = t.accessibilityPerformPress()
        } else if s.hasPrefix("axfocus:"), let t = tileNumber(s) {
            t.setAccessibilityFocused(true)
            word = selected()
        } else if s == "block" || s == "unblock" {
            blocked = s == "block"
            word = selected()
        } else if s == "reload" {
            grid.show(rows: found, offers: offers, last: last)
            word = selected()
        } else { usage() }
        if let r = started { word = ["start", r.path] } else if quit { word = ["quit"] } else if footed { word = ["sheet", "update"] }
        let focus = grid.tiles.firstIndex { $0.isAccessibilityFocused() }.map { String($0 + 1) } ?? "-"
        out([s] + word + ["focus", focus, "offset", num(grid.offset)])
    }
}

// -psn_ is what older systems added when Finder started an app.
let args = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-psn_") }

// `[--games <tsv>] rest`: the table of ported games, and what follows it
func gamesOption(_ a: [String]) -> (String?, [String]) {
    guard a.first == "--games" else { return (nil, a) }
    guard a.count >= 2 else { usage() }
    return (a[1], Array(a.dropFirst(2)))
}

// `[--update-dir <dir>] rest`: the folder that holds the update tool, and what follows it
func updateOption(_ a: [String]) -> (String?, [String]) {
    guard a.first == "--update-dir" else { return (nil, a) }
    guard a.count >= 2 else { usage() }
    return (a[1], Array(a.dropFirst(2)))
}

if let mode = args.first, mode.hasPrefix("-"), mode != "--games", mode != "--update-dir" {
    let rest = Array(args.dropFirst())
    switch mode {
    case "--list":
        let (table, folders) = gamesOption(rest)
        guard !folders.isEmpty else { usage() }
        let found = rows(in: folders)
        for r in found + (table.map { withOwnership(tableOffers($0, folders, found), offerRows($0, found)) } ?? []) {
            print([r.role.rawValue, r.appID.map(String.init) ?? "-", r.state.rawValue, r.title, r.path].joined(separator: "\t"))
        }
    case "--default":
        guard rest.count >= 2 else { usage() }
        if let r = defaultRow(rows(in: Array(rest.dropFirst())), last: lastID(rest[0])) { print(r.path) }
    case "--second":
        guard rest.count >= 2 else { usage() }
        let list = rows(in: Array(rest.dropFirst()))
        let k = realPath(absolute(rest[0])) ?? absolute(rest[0])
        if let c = list.first(where: { $0.key == k }), let b = blocker(c, list) { print("ask\t\(b.title)") } else { print("go") }
    case "--start":
        guard rest.count == 1 || (rest.count == 2 && rest[1] == "new"), !rest[0].isEmpty else { usage() }
        if let why = start(rest[0], new: rest.count == 2) { print("failed\t\(why)"); exit(1) }
        print("started")
    case "--folders":
        guard rest.isEmpty else { usage() }
        for f in windowFolders() { print(f) }
    case "--owned":
        guard rest.count >= 2, let id = lastID(rest[0]) else { usage() }
        print(ownership(of: id, in: Array(rest.dropFirst())))
    case "--icon":
        guard rest.count == 1 || (rest.count == 2 && rest[1] == "small"), !rest[0].isEmpty else { usage() }
        if !drawIcon(to: absolute(rest[0]), small: rest.count == 2) { FileHandle.standardError.write(Data("launcher-window: the icon could not be drawn or written\n".utf8)); exit(1) }
    case "--icon-at":
        let small = rest.first == "small"
        guard rest.count > (small ? 1 : 0), let rep = iconBitmap(small: small) else { usage() }
        for p in rest.dropFirst(small ? 1 : 0) {
            let f = p.split(separator: ",").compactMap { Int($0) }
            guard f.count == 2 else { usage() }
            print(iconKind(rep, f[0], f[1]))
        }
    case "--svg":
        guard rest.count == 1, !rest[0].isEmpty else { usage() }
        if !fm.createFile(atPath: absolute(rest[0]), contents: Data(markSVG().utf8)) { FileHandle.standardError.write(Data("launcher-window: the SVG could not be written\n".utf8)); exit(1) }
    case "--alias":
        guard rest.count == 2 || (rest.count == 3 && rest[2] == "make"), !rest[0].isEmpty, !rest[1].isEmpty else { usage() }
        let app = absolute(rest[0]), path = absolute(rest[1])
        let state = aliasState(app, path)
        guard rest.count == 3, state == "none" else { print(state); exit(0) }
        if let why = makeAlias(app, path) { print("failed\t\(why)"); exit(1) }
        print("made")
    case "--grid", "--act":
        MainActor.assumeIsolated { gridMode(mode, rest) }
    case "--update-sheet":
        let (dir, folders) = updateOption(rest)
        guard let d = dir, !folders.isEmpty else { usage() }
        let (state, notes) = updateTool(d).map { askState($0, Call.state) } ?? (nil, nil)
        let inUse = rows(in: folders).first(where: { $0.role == .game && $0.state == .busy })
        guard let words = updateSheet(state, notes, inUse?.title) else { print("none"); break }
        print("message\t\(words.message)")
        print("text\t\(words.text)")
        for b in words.buttons { print("button\t\(b)") }
        for n in words.notes ?? [] { print("note\t\(n)") }
    case "--update-menu":
        let (dir, more) = updateOption(rest)
        guard let d = dir, more.count == 1, ["fetched", "failed", "skipped", "-"].contains(more[0]) else { usage() }
        let state = updateTool(d).flatMap { askUpdate($0, Call.state.0, limit: Call.state.1) }.flatMap(updateState)
        switch more[0] == "-" ? menuAnswer(nil, nil) : menuAnswer(state, more[0]) {   // -: no answer to the refresh
        case .sheet: print("sheet")
        case .alert(let message, let text): print("alert\t\(message)\t\(text.isEmpty ? "-" : text)")
        }
    case "--update-open":
        let (dir, more) = updateOption(rest)
        guard let d = dir, more.isEmpty else { usage() }
        switch updateTool(d).map({ openUpdate($0) }) ?? afterOpen(nil) {
        case .quit: print("quit")
        case .failure(let why): print("failure\t\(Look.notOpened)\t\(why)")
        }
    case "--update-answer":
        let buttons: [String: NSApplication.ModalResponse] = ["first": .alertFirstButtonReturn, "second": .alertSecondButtonReturn,
                                                              "escape": .alertFirstButtonReturn]   // Escape: as the key monitor ends a sheet
        guard rest.count == 1, let b = buttons[rest[0]] else { usage() }
        print(sheetAnswer(b))
    case "--update-tool":
        let (dir, more) = updateOption(rest)
        guard more.isEmpty else { usage() }
        print((dir ?? updateKey()).flatMap(updateTool) ?? "-")
    default:
        usage()
    }
    exit(0)
}

// ---------------------------------------------------------------------------------------------- the window
let (gamesGiven, afterGames) = gamesOption(Array(args))
let (updateGiven, foldersGiven) = updateOption(afterGames)
guard !foldersGiven.contains(where: { $0.hasPrefix("-") }) else { usage() }
let readFrom = foldersGiven.isEmpty ? windowFolders() : foldersGiven
let gamesTable = gamesGiven ?? ownBundle().map { $0 + "/Contents/Resources/games.tsv" }
let updateFolder = updateGiven ?? updateKey()   // --update-dir wins over L1UpdateDir

final class LauncherWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { NSApp.terminate(nil) }
}

@MainActor
final class Launcher: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    enum Sheet { case none, question(NSWindow), failure(NSWindow) }
    var appRows: [Row] = []
    var owned: [Row] = []   // what a cache of Steam's says the account has, when its answer has come (askOffers)
    var sheet = Sheet.none
    var starting = false
    var opened = false
    // The update parts (docs/plans/built-in-update.md, 3.5). With no tool there are none: no foot line, no menu item.
    let tool = updateFolder.flatMap(updateTool)
    var held: UpdateState? = nil   // the tool's last usable answer: reload() draws the foot line from it and asks nothing
    var notes: String? = nil       // kept with a state of ready, so that no child runs between a click and the sheet
    var checking = false           // the menu item's question is out: the item is disabled until its answer
    let window = LauncherWindow(contentRect: NSRect(x: 0, y: 0, width: Look.least, height: 204),
                                styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
    let back = BackgroundView()
    let grid = makeGrid()
    let scroll = NSScrollView()
    let empty = NSView()
    let none = NSTextField(labelWithString: Look.noGames)
    let address = NSTextField(labelWithString: Look.readme)
    let bar = titleBar()
    var sheetUp: Bool { if case .none = sheet { return false } else { return true } }

    func applicationDidFinishLaunching(_ n: Notification) {
        let menu = NSMenu(), item = NSMenuItem(), appMenu = NSMenu()
        if tool != nil {
            appMenu.addItem(withTitle: Look.checkItem, action: #selector(checkForUpdates(_:)), keyEquivalent: Look.checkKey).target = self
            appMenu.addItem(.separator())
        }
        appMenu.addItem(withTitle: "Quit 14unch3r", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = appMenu
        menu.addItem(item)
        NSApp.mainMenu = menu

        window.title = "14unch3r"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setAccessibilityTitle("14unch3r game launcher")
        window.isReleasedWhenClosed = false
        window.delegate = self
        let content = window.contentView!
        back.frame = content.bounds
        back.autoresizingMask = [.width, .height]
        content.addSubview(back)

        grid.onStart = { [unowned self] _ in self.startChosen(nil) }
        grid.onQuit = { NSApp.terminate(nil) }
        grid.onFoot = { [unowned self] in self.showUpdate() }
        grid.blocked = { [unowned self] in self.starting || self.sheetUp }
        scroll.documentView = grid
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        content.addSubview(scroll)

        none.font = NSFont.systemFont(ofSize: 13)
        none.textColor = .white
        none.alignment = .center
        address.font = NSFont.systemFont(ofSize: 11)
        address.textColor = NSColor(white: 1, alpha: 0.88)
        address.alignment = .center
        address.isSelectable = true
        empty.addSubview(none)
        empty.addSubview(address)
        content.addSubview(empty)

        // Plan 2.7: keyAction says what a key does; the grid does it. The arrows pass on to the grid's keyDown.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] e in
            switch keyAction(e.keyCode, sheetUp: self.sheetUp) {
            case .pass:
                return e
            case .endSheet:
                switch self.sheet {
                case .question(let w), .failure(let w): self.window.endSheet(w, returnCode: .alertFirstButtonReturn)
                case .none: break
                }
            case let a:
                _ = self.grid.perform(a)
            }
            return nil
        }

        reload()
        window.center()
        window.initialFirstResponder = grid
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(grid)
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        opened = true
        askOffers()
        askUpdates()
    }

    func askOffers() {
        guard let table = gamesTable else { return }
        let found = appRows
        DispatchQueue.global(qos: .utility).async {
            let o = offerRows(table, found)
            DispatchQueue.main.async {
                self.owned = o
                if !o.isEmpty { self.reload() }
            }
        }
    }

    func applicationDidBecomeActive(_ n: Notification) {
        if opened && !starting { reload() }
        if opened { ask(Call.state) { state, notes in self.take(state, notes) } }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return false
    }

    var chosen: Row? { grid.chosen }

    // States are read when the window opens, each time it becomes the active app, and just before a start.
    // The selection stays on the same app when it is still listed.
    func reload() {
        appRows = rows(in: readFrom)
        // every game of the table that has no app here, from files alone (3.7): they are there at the first reload
        let offers = gamesTable.map { withOwnership(tableOffers($0, readFrom, appRows), owned) } ?? []
        grid.footState = held
        grid.show(rows: appRows, offers: offers, last: appID(UserDefaults.standard.object(forKey: "lastAppID")))
        empty.isHidden = !grid.tiles.isEmpty
        scroll.isHidden = grid.tiles.isEmpty
        fit()
    }

    // The window follows the grid; its top edge and its horizontal middle stay where they were.
    func fit() {
        let shown = grid.shown
        let size = NSSize(width: grid.frame.width, height: shown + bar)
        var f = window.frame
        f.origin.y += f.height - size.height
        f.origin.x += ((f.width - size.width) / 2).rounded()
        f.size = size
        window.setFrame(f, display: true, animate: false)
        scroll.frame = NSRect(x: 0, y: 0, width: size.width, height: shown)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: grid.offset))
        scroll.reflectScrolledClipView(scroll.contentView)
        empty.frame = scroll.frame
        let middle = (shown / 2).rounded()
        none.frame = NSRect(x: 16, y: middle + 2, width: size.width - 32, height: 18)
        address.frame = NSRect(x: 16, y: middle - 20, width: size.width - 32, height: 16)
    }

    @objc func startChosen(_ sender: Any?) {
        guard !starting, case .none = sheet else { return }
        guard let picked = chosen else { return }
        if picked.role == .offer { launch(picked, new: false); return }
        reload()
        guard let r = appRows.first(where: { $0.key == picked.key }) else { NSSound.beep(); return }
        if let b = blocker(r, appRows) { ask(about: b, starting: r) } else { launch(r, new: r.state == .busy) }
    }

    func ask(about b: Row, starting r: Row) {
        let a = NSAlert()
        a.alertStyle = .warning
        a.messageText = "\(b.title) is still in use."
        a.informativeText = "Starting \(r.title) now takes \(b.title)'s Steam offline. \(b.title) can keep running, but saves it has not uploaded yet stay on this Mac and do not reach Steam Cloud."
        a.addButton(withTitle: "Don't Start")   // the first button is the default: Return, and Escape too (the monitor)
        a.addButton(withTitle: "Start Anyway")
        sheet = .question(a.window)
        a.beginSheetModal(for: window) { answer in
            self.sheet = .none
            guard answer == .alertSecondButtonReturn else { return }
            self.reload()
            let now = self.appRows.first(where: { $0.key == r.key }) ?? r
            self.launch(now, new: now.state == .busy)
        }
    }

    func launch(_ r: Row, new: Bool) {
        starting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let why = start(r.path, new: new)
            DispatchQueue.main.async {
                self.starting = false
                if let why = why { self.failed(r, why); return }
                if r.role == .offer { return }   // the guide is in the browser; the list stays
                if r.role == .game, let id = r.appID {
                    UserDefaults.standard.set(id, forKey: "lastAppID")
                    UserDefaults.standard.synchronize()
                }
                NSApp.terminate(nil)
            }
        }
    }

    func failed(_ r: Row, _ why: String) {
        let a = NSAlert()
        a.alertStyle = .warning
        a.messageText = r.role == .offer ? "The set-up guide of \(r.title) did not open." : "\(r.title) did not start."
        a.informativeText = why
        a.addButton(withTitle: "OK")
        sheet = .failure(a.window)
        a.beginSheetModal(for: window) { _ in self.sheet = .none }
    }

    // ---- the update parts (docs/plans/built-in-update.md, 3.5)
    // The one way to the tool from here: asked off the main thread, the answer handed back on it. The window
    // never waits for it, and reload() never comes here.
    func ask(_ call: ([String], Double), then: @escaping @MainActor (UpdateState?, String?) -> Void) {
        guard let tool = tool else { return }
        DispatchQueue.global(qos: .utility).async {
            let (state, notes) = askState(tool, call)
            DispatchQueue.main.async { then(state, notes) }
        }
    }

    // At open, with the offers: the state, which touches no network; then, chained once after its answer, the
    // refresh, which fetches at most once a day.
    func askUpdates() {
        ask(Call.state) { state, notes in
            self.take(state, notes)
            self.ask(Call.refresh) { state, notes in self.take(state, notes) }
        }
    }

    // An answer replaces what is held; no answer, or one that is not usable, is dropped. The list is shown again
    // only when the word or the offered version differs, and not under a sheet or a start: reload() asks nothing.
    func take(_ state: UpdateState?, _ notes: String?) {
        guard let s = state else { return }
        let differs = s.word != held?.word || s.offered != held?.offered
        held = s
        self.notes = notes
        if differs && !starting && !sheetUp { reload() }
    }

    // The foot line's click and the menu item both come here, with the state and the notes that are held. A game
    // in use, read now, gives the other sheet instead: an update leaves a running game as it is.
    func showUpdate() {
        guard !starting, !sheetUp, let tool = tool else { return }
        reload()
        let inUse = appRows.first(where: { $0.role == .game && $0.state == .busy })
        guard let words = updateSheet(held, notes, inUse?.title) else { return }
        let a = NSAlert()
        a.alertStyle = .informational
        a.messageText = words.message
        a.informativeText = words.text
        for b in words.buttons { a.addButton(withTitle: b) }   // the first button is the default: Return, and Escape too (the monitor)
        guard let lines = words.notes else {
            sheet = .failure(a.window)   // a game is in use: one button, and nothing to answer
            a.beginSheetModal(for: window) { _ in self.sheet = .none }
            return
        }
        let box = notesView(lines.joined(separator: "\n"))
        a.accessoryView = box   // set before the alert is shown
        a.layout()
        if let first = a.buttons.first, let second = a.buttons.last, let view = box.documentView {
            a.window.initialFirstResponder = first   // focus at open is "Not Now", not the notes
            first.nextKeyView = second               // the key loop: the buttons, then the notes
            second.nextKeyView = view
            view.nextKeyView = first
        }
        sheet = .question(a.window)   // the update's question
        a.beginSheetModal(for: window) { answer in
            self.sheet = .none
            self.answered(answer, tool)
        }
        DispatchQueue.main.async { (box.documentView as? NotesText)?.armed = true }   // not while the sheet opens: NotesText
    }

    // The notes open at their first line, the newest version's heading. Measured at the live step UL1 of
    // docs/plans/built-in-update.md: with keyboard navigation off no button can hold the keyboard, so the sheet
    // gave it to the notes as it opened, and AppKit then scrolled the view, with an animation, until its middle
    // was in sight (450 points in 178: the notes opened 136 points down). So the notes do not take the keyboard
    // while the sheet opens. They take it from the next turn of the run loop on (the Tab key, with keyboard
    // navigation on) and at a click, which is what selecting text needs.
    final class NotesText: NSTextView {
        var armed = false
        override var acceptsFirstResponder: Bool { armed }
        override func mouseDown(with event: NSEvent) {
            armed = true
            super.mouseDown(with: event)
        }
    }

    // What changed, under the sheet's text: a scroll view with a plain text view in it, read-only, selectable (a
    // right-click copies; the app has no Edit menu), nothing detected in it. No colour comes from Look: the alert
    // takes the window's dark appearance, as the other sheets do.
    func notesView(_ notes: String) -> NSScrollView {
        let box = NSScrollView(frame: NSRect(x: 0, y: 0, width: Look.notesW, height: Look.notesH))
        box.borderType = .bezelBorder
        box.hasVerticalScroller = true
        box.autohidesScrollers = true
        box.drawsBackground = false
        let view = NotesText(frame: NSRect(origin: .zero, size: box.contentSize))
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = false
        view.isAutomaticLinkDetectionEnabled = false
        view.isAutomaticDataDetectionEnabled = false
        view.drawsBackground = false
        view.textContainerInset = NSSize(width: Look.notesInset, height: Look.notesInset)
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.string = notes
        view.font = Look.notesFont
        view.textColor = .labelColor
        view.setAccessibilityLabel(Look.notesLabel)
        box.documentView = view
        return box
    }

    // Only the second button, "Update", runs anything: the tool writes the update's file and hands it to
    // Terminal, asked off the main thread with `starting` set as for a start. Opened: the window quits, as after
    // a start. Else `starting` is cleared and a sheet says why.
    func answered(_ answer: NSApplication.ModalResponse, _ tool: String) {
        guard sheetAnswer(answer) == "open" else { return }
        starting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let after = openUpdate(tool)
            DispatchQueue.main.async {
                if case .failure(let why) = after {
                    self.starting = false
                    self.tell(Look.notOpened, why)
                    return
                }
                NSApp.terminate(nil)
            }
        }
    }

    // An alert with one button, as a sheet.
    func tell(_ message: String, _ text: String) {
        let a = NSAlert()
        a.alertStyle = .informational
        a.messageText = message
        a.informativeText = text
        a.addButton(withTitle: Look.ok)
        sheet = .failure(a.window)   // one button: Return and Escape both end it
        a.beginSheetModal(for: window) { _ in self.sheet = .none }
    }

    // "Check for Updates…": nothing while a sheet is up or a start is under way. With a version held as out, its
    // sheet at once. Otherwise the tool is asked to fetch now, the item is disabled meanwhile, and the answer is
    // shown; one that arrives under a sheet or a start is dropped.
    @objc func checkForUpdates(_ sender: Any?) {
        guard !starting, !sheetUp, !checking else { return }
        if held?.word == "ready" { showUpdate(); return }
        checking = true
        ask(Call.refreshNow) { state, notes in
            self.checking = false
            guard !self.starting, !self.sheetUp else { return }
            self.take(state, notes)
            switch menuAnswer(state, state?.fetch) {
            case .sheet: self.showUpdate()
            case .alert(let message, let text): self.tell(message, text)
            }
        }
    }
    func validateMenuItem(_ item: NSMenuItem) -> Bool { !checking }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.appearance = NSAppearance(named: .darkAqua)   // before the window is made: Launcher's init makes it
    let launcher = Launcher()
    app.delegate = launcher
    app.run()
}
