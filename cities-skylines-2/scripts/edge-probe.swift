// edge-probe.swift -- how hard are the edges in a capture of the game's window? (2026-11-25, s164 series)
//
//   swiftc -O edge-probe.swift -o /tmp/edge-probe
//   /tmp/edge-probe <capture.png> [step]
//
// The window is 2560x1440 game pixels on a 5K panel, so a capture holds each game pixel as step x step
// device pixels (step 2; pass 1 for a capture that is already at game size). On the game-pixel grid, along
// rows and along columns, it looks for STRONG edges between two flat runs:
//     a b | c d e f   with |b-a| small, |f-e| small, |e-b| >= 40 of 255
// and asks how much of the whole step e-b is taken by its largest single jump (b->c, c->d or d->e).
//   share 1.0  = the edge is one hard jump: no anti-aliasing touched it
//   share ~0.5 = a ramp over two or three pixels: blended
// Printed: edges found, mean share, and the part of edges with share >= 0.9 ("hard"). Also the period-3
// test used on 2026-11-25 for an upscaled picture (edge strength by x mod 3: equal = not stretched 1.5x).
// It reads; it changes nothing. The camera moves in the benchmark, so compare distributions, not pixels.
import AppKit

let args = CommandLine.arguments
guard args.count >= 2, let data = try? Data(contentsOf: URL(fileURLWithPath: args[1])),
      let rep = NSBitmapImageRep(data: data) else { print("usage: edge-probe <png> [step]"); exit(2) }
let step = args.count > 2 ? Int(args[2]) ?? 2 : 2
let w = rep.pixelsWide / step, h = rep.pixelsHigh / step
guard let p = rep.bitmapData, w > 16, h > 16 else { print("image too small or no bitmap"); exit(2) }
let spp = rep.samplesPerPixel, bpr = rep.bytesPerRow
var L = [Float](repeating: 0, count: w * h)
for y in 0..<h { for x in 0..<w {
  let o = (y * step) * bpr + (x * step) * spp
  L[y * w + x] = 0.299 * Float(p[o]) + 0.587 * Float(p[o + 1]) + 0.114 * Float(p[o + 2])
} }
func scan(_ dx: Int, _ dy: Int) -> (n: Int, mean: Double, hard: Double) {
  var n = 0, sum = 0.0, hard = 0
  let x1 = w - 5 * dx - 1, y1 = h - 5 * dy - 1
  var y = 0
  while y < y1 { var x = 0; while x < x1 {
    func v(_ k: Int) -> Float { L[(y + k * dy) * w + (x + k * dx)] }
    let a = v(0), b = v(1), c = v(2), d = v(3), e = v(4), f = v(5)
    let total = abs(e - b)
    if total >= 40, abs(b - a) < 6, abs(f - e) < 6 {
      let big = max(abs(c - b), abs(d - c), abs(e - d))
      let s = Double(min(big / total, 1)); n += 1; sum += s; if s >= 0.9 { hard += 1 }
    }
    x += 1 }; y += 1 }
  return (n, n > 0 ? sum / Double(n) : 0, n > 0 ? Double(hard) / Double(n) : 0)
}
let hx = scan(1, 0), vy = scan(0, 1)
var m3 = [Double](repeating: 0, count: 3), c3 = [Double](repeating: 0, count: 3)
for y in stride(from: 0, to: h, by: 2) { for x in 1..<w { m3[x % 3] += Double(abs(L[y * w + x] - L[y * w + x - 1])); c3[x % 3] += 1 } }
let p3 = (0..<3).map { m3[$0] / c3[$0] }; let pm = p3.reduce(0, +) / 3
print(String(format: "%@  %dx%d  rows: n=%d mean=%.3f hard=%.3f  cols: n=%d mean=%.3f hard=%.3f  period3: %.2f %.2f %.2f",
  (args[1] as NSString).lastPathComponent, w, h, hx.n, hx.mean, hx.hard, vy.n, vy.mean, vy.hard, p3[0] / pm, p3[1] / pm, p3[2] / pm))
