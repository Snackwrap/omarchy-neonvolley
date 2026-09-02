import QtQuick
import Quickshell.Io

// Plays short WAV samples via paplay. Fails silently if audio is unavailable.
Item {
  id: root

  property bool enabled: true
  property int bounceCooldownMs: 60
  property int lastBounceMs: 0

  function localPath(name) {
    var url = Qt.resolvedUrl("assets/sfx/" + name + ".wav").toString()
    if (url.indexOf("file://") === 0) url = decodeURIComponent(url.slice(7))
    return url
  }

  function play(name) {
    if (!enabled) return
    if (name === "bounce") {
      var now = Date.now()
      if (now - lastBounceMs < bounceCooldownMs) return
      lastBounceMs = now
    }
    sfxProc.command = ["paplay", "--volume=45000", localPath(name)]
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
  }
}
