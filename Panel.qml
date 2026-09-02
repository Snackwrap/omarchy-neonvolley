import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "GameEngine.js" as Engine
import "Palette.js" as Palette
import "Scores.js" as Scores

// Neon Volley: menu → play → gameover inside a keyboard-focused popup.
Panel {
  id: root
  moduleName: "com.leafbox.neonvolley"
  ipcTarget: "com.leafbox.neonvolley"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property var panelFrame: null
  property string phase: "menu"
  property var gameState: null
  property bool holdLeft: false
  property bool holdRight: false
  property bool holdTopLeft: false
  property bool holdTopRight: false
  property string menuMode: ""
  property string menuDifficulty: ""
  property var sessionStats: Scores.empty()
  property string lastRecordedWinner: ""
  property int lastRecordedTick: -1
  property bool introActive: false

  readonly property string scoresPath:
    Quickshell.env("HOME") + "/.local/state/omarchy/plugins/com.leafbox.neonvolley/scores.json"

  function boolSetting(name, dflt) {
    var v = setting(name, dflt)
    return v === true || v === "true" || v === 1
  }

  readonly property int matchPoints: {
    var v = parseInt(String(setting("matchPoints", 7)), 10)
    return (isFinite(v) && v >= 3 && v <= 21) ? v : 7
  }
  readonly property bool soundOn: boolSetting("sound", true)
  readonly property string configMode: {
    var m = String(setting("mode", "cpu"))
    return m === "two" ? "two" : "cpu"
  }
  readonly property string playMode: menuMode !== "" ? menuMode : configMode
  readonly property bool twoPlayer: playMode === "two"
  readonly property string configDifficulty: {
    var d = String(setting("difficulty", "normal"))
    return (d === "easy" || d === "hard") ? d : "normal"
  }
  readonly property string playDifficulty: menuDifficulty !== "" ? menuDifficulty : configDifficulty
  readonly property string difficultyLabel: Engine.difficultyLabel(playDifficulty)
  readonly property string debugPreviewScene: String(setting("debugPreviewScene", "off"))
  readonly property bool previewFrozen: debugPreviewScene === "play" || debugPreviewScene === "gameover"
  readonly property bool debugGeometry: boolSetting("debugGeometry", false)

  readonly property string nearLabel: twoPlayer ? "P1" : "YOU"
  readonly property string farLabel: twoPlayer ? "P2" : "CPU"

  readonly property bool inPlay: phase === "play" || (gameState && (gameState.phase === "rally" || gameState.phase === "serve" || gameState.phase === "point"))

  readonly property string label: {
    if (inPlay && gameState) return gameState.playerScore + "–" + gameState.cpuScore
    if (phase === "gameover" && gameState && gameState.winner === "player") return "WIN"
    if (phase === "gameover" && gameState) return "LOSS"
    return "NV"
  }

  readonly property string tooltip: {
    if (inPlay && gameState)
      return "Neon Volley  " + nearLabel + " " + gameState.playerScore + " – " + farLabel + " " + gameState.cpuScore
    if (phase === "gameover" && gameState) {
      var w = gameState.winner === "player" ? nearLabel : farLabel
      return w + " wins the match — Enter to rematch"
    }
    return "Neon Volley — Enter to play"
  }

  readonly property string sessionLine: Scores.sessionLine(sessionStats, playMode)

  function openFromHotkey() { open() }

  function startMatch() {
    gameState = Engine.create(matchPoints, twoPlayer, playDifficulty)
    phase = "play"
    introActive = true
    introTimer.restart()
    lastRecordedWinner = ""
    lastRecordedTick = -1
    if (sfxLoader.item) sfxLoader.item.play("start")
    Qt.callLater(function() {
      if (gameInput) gameInput.forceActiveFocus()
    })
  }

  function resetMatch() {
    gameState = null
    phase = "menu"
    introActive = false
    holdLeft = false
    holdRight = false
    holdTopLeft = false
    holdTopRight = false
    lastRecordedWinner = ""
    lastRecordedTick = -1
  }

  function cycleDifficulty() {
    if (twoPlayer) return
    var order = ["easy", "normal", "hard"]
    var i = order.indexOf(playDifficulty)
    if (i < 0) i = 1
    menuDifficulty = order[(i + 1) % order.length]
  }

  function resetScores() {
    sessionStats = Scores.reset(sessionStats)
    scoresSaveProc.payload = Scores.serialize(sessionStats)
    scoresSaveProc.running = true
  }

  readonly property string gameOverWinnerLabel: {
    if (!gameState || gameState.phase !== "gameover") return ""
    return gameState.winner === "player" ? nearLabel : farLabel
  }

  readonly property string gameOverScoreLine: {
    if (!gameState) return ""
    return nearLabel + " " + gameState.playerScore + "  ·  " + farLabel + " " + gameState.cpuScore
  }

  Timer {
    id: introTimer
    interval: 880
    onTriggered: root.introActive = false
  }

  function applyMoveInput() {
    if (!gameState) return
    var pDir = 0
    if (holdLeft && !holdRight) pDir = -1
    else if (holdRight && !holdLeft) pDir = 1
    Engine.setMoveDir(gameState, pDir)

    var tDir = 0
    if (holdTopLeft && !holdTopRight) tDir = -1
    else if (holdTopRight && !holdTopLeft) tDir = 1
    Engine.setTopMoveDir(gameState, tDir)
  }

  function cycleMenuMode() {
    var next = playMode === "cpu" ? "two" : "cpu"
    menuMode = next
    if (next === "two") menuDifficulty = ""
  }

  function recordMatchWin() {
    if (!gameState || gameState.phase !== "gameover") return
    var tick = gameState.tick || 0
    if (gameState.winner === lastRecordedWinner && tick === lastRecordedTick) return
    sessionStats = Scores.record(sessionStats, playMode, gameState.winner)
    lastRecordedWinner = gameState.winner
    lastRecordedTick = tick
    scoresSaveProc.payload = Scores.serialize(sessionStats)
    scoresSaveProc.running = true
  }

  Component.onCompleted: {
    scoresDirProc.running = true
    scoresReader.running = true
  }

  Process {
    id: scoresDirProc
    running: false
    command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/omarchy/plugins/com.leafbox.neonvolley"]
  }

  Process {
    id: scoresSaveProc
    property string payload: ""
    running: false
    command: ["bash", "-c",
      "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"",
      "--", root.scoresPath, payload]
  }

  Process {
    id: scoresReader
    running: false
    command: ["timeout", "1", "cat", "--", root.scoresPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.sessionStats = Scores.parse(String(text || ""))
      }
    }
  }

  FileView {
    path: root.scoresPath
    watchChanges: true
    preload: false
    printErrors: false
    onFileChanged: scoresReadTimer.restart()
  }

  Timer {
    id: scoresReadTimer
    interval: 250
    onTriggered: scoresReader.running = true
  }

  onPhaseChanged: {
    if (phase === "play")
      Qt.callLater(function() { if (gameInput) gameInput.forceActiveFocus() })
    else if (keyCatcher)
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    if (phase === "gameover") recordMatchWin()
  }

  function applyPreviewScene() {
    var scene = debugPreviewScene
    if (scene === "off" || scene === "") {
      resetMatch()
      return
    }
    if (scene === "play") {
      gameState = Engine.previewState("play")
      phase = "play"
      introActive = false
      return
    }
    if (scene === "gameover") {
      gameState = Engine.previewState("gameover")
      phase = "gameover"
      introActive = false
      return
    }
    resetMatch()
  }

  onOpenedChanged: {
    if (!opened) {
      resetMatch()
      gameLoop.stop()
      return
    }
    menuMode = configMode
    menuDifficulty = configDifficulty
    holdLeft = false
    holdRight = false
    holdTopLeft = false
    holdTopRight = false
    scoresReader.running = true
    applyPreviewScene()
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
    if (debugGeometry) geometryTimer.restart()
  }

  Timer {
    id: geometryTimer
    interval: 900
    onTriggered: root.reportGeometry()
  }

  Connections {
    target: root.debugGeometry ? root.panelFrame : null
    function onHeightChanged() { geometryTimer.restart() }
  }

  function reportGeometry() {
    if (!panelFrame) return
    var inset = panel.padding + Math.max(1, Style.space(2))
    var origin = panelFrame.mapToGlobal(0, 0)
    console.log("NEON_VOLLEY_GEOMETRY "
                + Math.round(origin.x - inset) + " " + Math.round(origin.y - inset) + " "
                + Math.round(panelFrame.width + inset * 2) + " "
                + Math.round(panelFrame.height + inset * 2))
  }

  Timer {
    id: gameLoop
    interval: 16
    repeat: true
    running: root.opened && root.phase === "play" && root.gameState !== null && !root.previewFrozen
    onTriggered: {
      root.applyMoveInput()
      var prev = root.gameState
      root.gameState = Engine.step(prev, interval)
      if (root.gameState.phase === "gameover" && root.phase !== "gameover")
        root.phase = "gameover"
      if (sfxLoader.item) sfxLoader.item.handleEvents(root.gameState.events)
    }
  }

  Loader {
    id: sfxLoader
    source: Qt.resolvedUrl("Sfx.qml")
    onLoaded: {
      if (item) item.enabled = root.soundOn
    }
  }

  onSoundOnChanged: {
    if (sfxLoader.item) sfxLoader.item.enabled = soundOn
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: String(root.setting("popupPosition", "icon")) === "center"
    focusTarget: root.phase === "play" ? gameInput : keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(contentCol.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.phase === "play"

      Component.onCompleted: root.panelFrame = keyCatcher

      onActivateRequested: {
        if (root.phase === "menu" || root.phase === "gameover") root.startMatch()
      }

      onTabRequested: function(direction) {
        if (root.phase === "menu" || root.phase === "gameover") root.cycleMenuMode()
      }

      onTextKey: function(t) {
        if (root.phase !== "menu" && root.phase !== "gameover") return
        if (t === "r" || t === "R") root.resetScores()
        else if ((t === "d" || t === "D") && !root.twoPlayer) root.cycleDifficulty()
      }

      onCloseRequested: root.close()

      Item {
        id: gameInput
        anchors.fill: parent
        focus: root.phase === "play"
        activeFocusOnTab: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.phase !== "play") return
          var k = event.key
          var t = event.text

          if (k === Qt.Key_Escape) {
            root.close()
            event.accepted = true
            return
          }

          // P1 (near): arrows
          if (k === Qt.Key_Left) {
            root.holdLeft = true
            root.applyMoveInput()
            event.accepted = true
            return
          }
          if (k === Qt.Key_Right) {
            root.holdRight = true
            root.applyMoveInput()
            event.accepted = true
            return
          }
          if (k === Qt.Key_Space) {
            if (root.gameState) Engine.swing(root.gameState)
            event.accepted = true
            return
          }

          // P2 / solo extras: A/D; in 1P vs CPU either arrows or A/D move the near paddle
          if (t === "a" || t === "A") {
            if (root.twoPlayer) root.holdTopLeft = true
            else root.holdLeft = true
            root.applyMoveInput()
            event.accepted = true
            return
          }
          if (t === "d" || t === "D") {
            if (root.twoPlayer) root.holdTopRight = true
            else root.holdRight = true
            root.applyMoveInput()
            event.accepted = true
            return
          }

          // P2 swing in 2P
          if (root.twoPlayer && (k === Qt.Key_Return || k === Qt.Key_Enter)) {
            if (root.gameState) Engine.swingTop(root.gameState)
            event.accepted = true
          }
        }

        Keys.onReleased: function(event) {
          var k = event.key
          var t = event.text
          if (k === Qt.Key_Left) {
            root.holdLeft = false
            root.applyMoveInput()
            event.accepted = true
          } else if (k === Qt.Key_Right) {
            root.holdRight = false
            root.applyMoveInput()
            event.accepted = true
          } else if (t === "a" || t === "A") {
            if (root.twoPlayer) root.holdTopLeft = false
            else root.holdLeft = false
            root.applyMoveInput()
            event.accepted = true
          } else if (t === "d" || t === "D") {
            if (root.twoPlayer) root.holdTopRight = false
            else root.holdRight = false
            root.applyMoveInput()
            event.accepted = true
          }
        }
      }

      Column {
        id: contentCol
        width: parent.width
        spacing: Style.space(8)

        TitleHeader {
          width: parent.width
          sessionLine: root.sessionLine
        }

        Court {
          id: court
          width: parent.width
          gameState: root.gameState
          courtW: Engine.courtWidth()
          courtH: Engine.courtHeight()
          twoPlayer: root.twoPlayer
          nearLabel: root.nearLabel
          farLabel: root.farLabel
          showAttract: root.phase === "menu"
          showIntro: root.introActive
          showGameOver: root.phase === "gameover"
          gameOverWinner: root.gameOverWinnerLabel
          gameOverScore: root.gameOverScoreLine
          gameOverSession: root.sessionLine
        }

        Item {
          width: parent.width
          height: root.phase === "gameover" ? 0 : overlayText.implicitHeight + Style.space(4)
          visible: root.phase !== "gameover"

          Text {
            id: overlayText
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            color: Palette.neonBright
            font.family: Style.font.family
            font.pixelSize: Style.space(11)
            text: {
              if (root.phase === "menu") {
                var modeName = root.twoPlayer ? "2P LOCAL" : ("1P VS CPU  ·  " + root.difficultyLabel)
                return modeName + "\nTAB — mode"
                  + (root.twoPlayer ? "" : "   D — difficulty")
                  + "   R — reset matches\n"
                  + (root.twoPlayer
                    ? "P1 ← → + SPACE   P2 A/D + ENTER"
                    : "← → or A/D — move   SPACE — swing (hold timing for power)")
                  + "   ESC — close"
              }
              if (root.phase === "gameover")
                return ""
              if (root.gameState && root.gameState.phase === "point") {
                var p = root.gameState.pointWinner === "player" ? root.nearLabel : root.farLabel
                return p + " SCORES"
              }
              if (root.gameState && root.gameState.phase === "serve") {
                var srv = root.gameState.server === "player" ? root.nearLabel : root.farLabel
                return srv + " TO SERVE"
              }
              return root.twoPlayer
                ? "P1 ← → SPACE   P2 A/D ENTER"
                : "← → or A/D — move   SPACE — power swing"
            }
          }
        }
      }
    }
  }
}
