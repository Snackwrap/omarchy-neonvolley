import QtQuick
import Quickshell.Io

// Plays short WAV samples via paplay. Fails silently if audio is unavailable.
Item {
  id: root

  property bool enabled: true
  property int bounceCooldownMs: 60
  property int lastBounceMs: 0

  readonly property string paplayBin: "/usr/bin/paplay"
  readonly property var allowedSfx: ({
    bounce: true, gameover: true, hit: true, power: true, score: true, start: true
  })

  property int sfxStartedMs: 0

  function localPath(name) {
    if (!allowedSfx[name]) return ""
    var url = Qt.resolvedUrl("assets/sfx/" + name + ".wav").toString()
    if (url.indexOf("file://") === 0) url = decodeURIComponent(url.slice(7))
    return url
  }

  function stopAll() {
    sfxProc.running = false
    sfxStartedMs = 0
  }

  function play(name) {
    if (!enabled) return
    if (!allowedSfx[name]) return
    var path = localPath(name)
    if (!path) return
    if (name === "bounce") {
      var now = Date.now()
      if (now - lastBounceMs < bounceCooldownMs) return
      lastBounceMs = now
    }
    if (sfxProc.running) sfxProc.running = false
    sfxProc.command = [paplayBin, "--volume=45000", path]
    sfxStartedMs = Date.now()
    sfxProc.running = true
  }

  function handleEvents(events) {
    if (!events || !events.length) return
    for (var i = 0; i < events.length; i++) {
      var e = events[i]
      if (e === "hit") play("hit")
      else if (e === "bounce") play("bounce")
      else if (e === "score") play("score")
      else if (e === "start") play("start")
      else if (e === "power") play("power")
      else if (e === "gameover") play("gameover")
    }
  }

  Process {
    id: sfxProc
    running: false
    onExited: root.sfxStartedMs = 0
  }

  Timer {
    interval: 1000
    running: sfxProc.running
    repeat: true
    onTriggered: {
      if (root.sfxStartedMs && Date.now() - root.sfxStartedMs > 5000)
        root.stopAll()
    }
  }

  Component.onDestruction: stopAll()
}
