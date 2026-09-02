.pragma library

var W = 384
var H = 200
var NET_Y = H / 2
var WALL_PAD = 8
var PLAYER_Y = H - 22
var CPU_Y = 22
var PADDLE_W = 44
var CPU_PADDLE_W = 38
var BALL_R = 5
var PLAYER_SPEED = 6.5
var SERVE_WAIT_MS = 1200
var SWING_MS = 180
var POWER_WINDOW_MS = 70

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v))
}

function cpuParams(level) {
  if (level === "easy")
    return { speed: 2.5, reaction: 155, swingRange: 30, missRate: 0.18 }
  if (level === "hard")
    return { speed: 4.1, reaction: 42, swingRange: 42, missRate: 0 }
  return { speed: 3.4, reaction: 80, swingRange: 36, missRate: 0.06 }
}

function create(matchPoints, twoPlayer, difficulty) {
  var mp = parseInt(matchPoints, 10)
  if (!isFinite(mp) || mp < 3) mp = 7
  var diff = difficulty === "easy" || difficulty === "hard" ? difficulty : "normal"
  return {
    phase: "serve",
    twoPlayer: twoPlayer === true,
    difficulty: diff,
    playerScore: 0,
    cpuScore: 0,
    matchPoints: mp,
    server: "player",
    winner: "",
    ball: { x: W / 2, y: PLAYER_Y - 14, vx: 0, vy: 0, r: BALL_R },
    player: { x: W / 2, y: PLAYER_Y, w: PADDLE_W, swingT: 0 },
    cpu: { x: W / 2, y: CPU_Y, w: CPU_PADDLE_W, swingT: 0 },
    trail: [],
    flashT: 0,
    pointWinner: "",
    serveTimer: SERVE_WAIT_MS,
    moveDir: 0,
    topMoveDir: 0,
    events: [],
    cpuTargetX: W / 2,
    cpuReactionT: 0,
    tick: 0
  }
}

function depthScale(y) {
  return clamp(0.55 + (y / H) * 0.55, 0.55, 1.1)
}

function pushTrail(state) {
  var t = state.trail.slice(0)
  t.unshift({ x: state.ball.x, y: state.ball.y, a: 0.55 })
  if (t.length > 3) t.length = 3
  for (var i = 0; i < t.length; i++) t[i].a = 0.55 - i * 0.18
  state.trail = t
}

function launchServe(state) {
  var towardCpu = state.server === "player"
  state.ball.x = W / 2
  state.ball.y = towardCpu ? PLAYER_Y - 14 : CPU_Y + 14
  var dir = towardCpu ? -1 : 1
  state.ball.vx = (Math.random() - 0.5) * 2.4
  state.ball.vy = dir * (4.2 + Math.random() * 0.8)
  state.phase = "rally"
}

function paddleHit(state, paddle, towardTop, power) {
  var b = state.ball
  var half = paddle.w / 2
  var off = (b.x - paddle.x) / half
  var boost = power ? 2.4 : 0
  b.vx = off * (power ? 6.2 : 4.8)
  b.vy = towardTop
    ? -Math.abs(b.vy) - 3.2 - boost
    : Math.abs(b.vy) + 3.2 + boost
  if (Math.abs(b.vy) < 3.5) b.vy = towardTop ? -3.5 : 3.5
  b.y = towardTop ? paddle.y - b.r - 2 : paddle.y + b.r + 2
  state.events.push(power ? "power" : "hit")
}

function tryPaddleHit(state, paddle, towardTop) {
  var b = state.ball
  var half = paddle.w / 2
  var reach = paddle.swingT > 0 ? half + 10 : half + 4
  var dy = Math.abs(b.y - paddle.y)
  if (dy > b.r + 14) return false
  if (Math.abs(b.x - paddle.x) > reach + b.r) return false
  if (towardTop && b.vy < 0) return false
  if (!towardTop && b.vy > 0) return false
  var power = paddle.swingT > (SWING_MS - POWER_WINDOW_MS)
  paddleHit(state, paddle, towardTop, power)
  return true
}

function handleNet(state, prevY) {
  var b = state.ball
  var r = b.r
  var clearSpeed = 2.2

  var crossedDown = prevY + r <= NET_Y && b.y - r > NET_Y
  var crossedUp = prevY - r >= NET_Y && b.y + r < NET_Y
  if (!crossedDown && !crossedUp) return

  if (Math.abs(b.vy) >= clearSpeed) {
    if (crossedDown) b.y = Math.max(b.y, NET_Y + r + 2)
    else b.y = Math.min(b.y, NET_Y - r - 2)
    return
  }

  b.vy = crossedDown ? -Math.max(2.0, Math.abs(b.vy) * 0.55)
                      : Math.max(2.0, Math.abs(b.vy) * 0.55)
  b.vx *= 0.72
  b.y = crossedDown ? NET_Y - r - 2 : NET_Y + r + 2
  state.events.push("bounce")
}

function scorePoint(state, winner) {
  if (winner === "player") state.playerScore++
  else state.cpuScore++
  state.pointWinner = winner
  state.phase = "point"
  state.flashT = 420
  state.serveTimer = SERVE_WAIT_MS
  state.server = (state.playerScore + state.cpuScore) % 2 === 0 ? "player" : "cpu"
  state.ball.vx = 0
  state.ball.vy = 0
  state.events.push("score")
  if (state.playerScore >= state.matchPoints || state.cpuScore >= state.matchPoints) {
    state.winner = state.playerScore >= state.matchPoints ? "player" : "cpu"
    state.phase = "gameover"
    state.events.push("gameover")
  }
}

function moveTop(state, dt, speed) {
  state.cpu.x = clamp(
    state.cpu.x + state.topMoveDir * speed * dt,
    WALL_PAD + state.cpu.w / 2,
    W - WALL_PAD - state.cpu.w / 2
  )
}

function movePlayer(state, dt) {
  state.player.x = clamp(
    state.player.x + state.moveDir * PLAYER_SPEED * dt,
    WALL_PAD + state.player.w / 2,
    W - WALL_PAD - state.player.w / 2
  )
}

function snapshot(state) {
  return {
    phase: state.phase,
    twoPlayer: state.twoPlayer === true,
    difficulty: state.difficulty,
    playerScore: state.playerScore,
    cpuScore: state.cpuScore,
    matchPoints: state.matchPoints,
    server: state.server,
    winner: state.winner,
    ball: {
      x: state.ball.x,
      y: state.ball.y,
      vx: state.ball.vx,
      vy: state.ball.vy,
      r: state.ball.r
    },
    player: {
      x: state.player.x,
      y: state.player.y,
      w: state.player.w,
      swingT: state.player.swingT
    },
    cpu: {
      x: state.cpu.x,
      y: state.cpu.y,
      w: state.cpu.w,
      swingT: state.cpu.swingT
    },
    trail: state.trail.slice(0),
    flashT: state.flashT,
    pointWinner: state.pointWinner,
    serveTimer: state.serveTimer,
    moveDir: state.moveDir,
    topMoveDir: state.topMoveDir,
    events: state.events.slice(0),
    cpuTargetX: state.cpuTargetX,
    cpuReactionT: state.cpuReactionT,
    tick: (state.tick || 0) + 1
  }
}

function step(state, dtMs) {
  if (!state) return state
  state.events = []
  var dt = clamp(dtMs / 16.667, 0.25, 2.5)
  var cpu = cpuParams(state.difficulty)

  if (state.flashT > 0) state.flashT = Math.max(0, state.flashT - dtMs)

  if (state.phase === "point") {
    state.serveTimer -= dtMs
    if (state.serveTimer <= 0) {
      state.pointWinner = ""
      state.phase = "serve"
      state.serveTimer = 400
    }
    return snapshot(state)
  }

  if (state.phase === "gameover") return snapshot(state)

  if (state.phase === "serve") {
    movePlayer(state, dt)
    moveTop(state, dt, state.twoPlayer ? PLAYER_SPEED : cpu.speed)
    state.serveTimer -= dtMs
    state.ball.x = state.server === "player" ? state.player.x : state.cpu.x
    state.ball.y = state.server === "player" ? PLAYER_Y - 14 : CPU_Y + 14
    if (state.serveTimer <= 0) launchServe(state)
    return snapshot(state)
  }

  movePlayer(state, dt)

  if (state.twoPlayer) {
    moveTop(state, dt, PLAYER_SPEED)
  } else {
    state.cpuReactionT -= dtMs
    if (state.cpuReactionT <= 0) {
      state.cpuTargetX = state.ball.x + (Math.random() - 0.5) * cpu.missRate * 80
      state.cpuReactionT = cpu.reaction
    }
    var cdx = state.cpuTargetX - state.cpu.x
    var cpuStep = cpu.speed * dt
    if (Math.abs(cdx) > cpuStep) state.cpu.x += cdx > 0 ? cpuStep : -cpuStep
    else state.cpu.x = state.cpuTargetX
    state.cpu.x = clamp(state.cpu.x, WALL_PAD + state.cpu.w / 2, W - WALL_PAD - state.cpu.w / 2)

    if (state.ball.vy < 0 && state.ball.y < NET_Y + cpu.swingRange && state.cpu.swingT <= 0) {
      if (Math.random() >= cpu.missRate) state.cpu.swingT = SWING_MS
    }
  }

  if (state.player.swingT > 0) state.player.swingT = Math.max(0, state.player.swingT - dtMs)
  if (state.cpu.swingT > 0) state.cpu.swingT = Math.max(0, state.cpu.swingT - dtMs)

  var scale = depthScale(state.ball.y)
  var prevBallY = state.ball.y
  state.ball.x += state.ball.vx * dt * scale
  state.ball.y += state.ball.vy * dt * scale

  pushTrail(state)

  if (state.ball.x - state.ball.r < WALL_PAD) {
    state.ball.x = WALL_PAD + state.ball.r
    state.ball.vx = Math.abs(state.ball.vx) * 0.92
    state.events.push("bounce")
  } else if (state.ball.x + state.ball.r > W - WALL_PAD) {
    state.ball.x = W - WALL_PAD - state.ball.r
    state.ball.vx = -Math.abs(state.ball.vx) * 0.92
    state.events.push("bounce")
  }

  handleNet(state, prevBallY)

  if (tryPaddleHit(state, state.player, true)) { /* hit */ }
  else if (tryPaddleHit(state, state.cpu, false)) { /* hit */ }

  if (state.ball.y + state.ball.r < 0) {
    scorePoint(state, "player")
    return snapshot(state)
  }
  if (state.ball.y - state.ball.r > H) {
    scorePoint(state, "cpu")
    return snapshot(state)
  }

  return snapshot(state)
}

function setMoveDir(state, dir) {
  if (!state) return
  state.moveDir = dir < 0 ? -1 : (dir > 0 ? 1 : 0)
}

function setTopMoveDir(state, dir) {
  if (!state) return
  state.topMoveDir = dir < 0 ? -1 : (dir > 0 ? 1 : 0)
}

function swing(state) {
  if (!state || state.phase !== "rally") return
  state.player.swingT = SWING_MS
}

function swingTop(state) {
  if (!state || state.phase !== "rally") return
  state.cpu.swingT = SWING_MS
}

function courtWidth() { return W }
function courtHeight() { return H }

function difficultyLabel(level) {
  if (level === "easy") return "EASY"
  if (level === "hard") return "HARD"
  return "NORMAL"
}

// Frozen layouts for marketplace preview captures (tools/capture-preview.sh).
function previewState(scene) {
  if (scene === "play") {
    return snapshot({
      phase: "rally",
      twoPlayer: false,
      difficulty: "normal",
      playerScore: 4,
      cpuScore: 3,
      matchPoints: 7,
      server: "player",
      winner: "",
      ball: { x: W * 0.58, y: H * 0.44, vx: 2.2, vy: -3.4, r: BALL_R },
      player: { x: W * 0.64, y: PLAYER_Y, w: PADDLE_W, swingT: 0 },
      cpu: { x: W * 0.36, y: CPU_Y, w: CPU_PADDLE_W, swingT: 40 },
      trail: [
        { x: W * 0.54, y: H * 0.50, a: 0.55 },
        { x: W * 0.50, y: H * 0.56, a: 0.37 },
        { x: W * 0.47, y: H * 0.62, a: 0.19 }
      ],
      flashT: 0,
      pointWinner: "",
      serveTimer: 0,
      moveDir: 0,
      topMoveDir: 0,
      events: [],
      cpuTargetX: W * 0.36,
      cpuReactionT: 0,
      tick: 0
    })
  }
  if (scene === "gameover") {
    return snapshot({
      phase: "gameover",
      twoPlayer: false,
      difficulty: "normal",
      playerScore: 7,
      cpuScore: 4,
      matchPoints: 7,
      server: "player",
      winner: "player",
      ball: { x: W / 2, y: H / 2, vx: 0, vy: 0, r: BALL_R },
      player: { x: W * 0.55, y: PLAYER_Y, w: PADDLE_W, swingT: 0 },
      cpu: { x: W * 0.45, y: CPU_Y, w: CPU_PADDLE_W, swingT: 0 },
      trail: [],
      flashT: 0,
      pointWinner: "",
      serveTimer: 0,
      moveDir: 0,
      topMoveDir: 0,
      events: [],
      cpuTargetX: W / 2,
      cpuReactionT: 0,
      tick: 0
    })
  }
  return null
}
