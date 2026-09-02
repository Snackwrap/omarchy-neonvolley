.pragma library

function empty() {
  return {
    cpu: { you: 0, cpu: 0 },
    two: { p1: 0, p2: 0 }
  }
}

function parse(raw) {
  var base = empty()
  if (!raw || String(raw).length === 0 || String(raw).length > 4096) return base
  try {
    var d = JSON.parse(String(raw))
    if (d.cpu) {
      base.cpu.you = parseInt(d.cpu.you, 10) || 0
      base.cpu.cpu = parseInt(d.cpu.cpu, 10) || 0
    }
    if (d.two) {
      base.two.p1 = parseInt(d.two.p1, 10) || 0
      base.two.p2 = parseInt(d.two.p2, 10) || 0
    }
  } catch (e) { /* keep defaults */ }
  return base
}

function serialize(stats) {
  return JSON.stringify(stats)
}

function isValidPayload(raw) {
  if (typeof raw !== "string") return false
  if (raw.length === 0 || raw.length > 4096) return false
  try {
    JSON.parse(raw)
    return true
  } catch (e) {
    return false
  }
}

function record(stats, mode, winner) {
  var s = parse(serialize(stats))
  if (mode === "two") {
    if (winner === "player") s.two.p1++
    else s.two.p2++
  } else {
    if (winner === "player") s.cpu.you++
    else s.cpu.cpu++
  }
  return s
}

function reset(stats) {
  return empty()
}

function sessionLine(stats, mode) {
  if (mode === "two")
    return "MATCHES  P1 " + stats.two.p1 + "  ·  P2 " + stats.two.p2
  return "MATCHES  YOU " + stats.cpu.you + "  ·  CPU " + stats.cpu.cpu
}
