import QtQuick
import qs.Commons
import "Palette.js" as Palette

// Neon-grid court with perspective, scanlines, paddles, and scoreboard.
Item {
  id: root

  property var gameState: null
  property real courtW: 384
  property real courtH: 200
  property bool twoPlayer: false
  property string nearLabel: "YOU"
  property string farLabel: "CPU"
  property bool showAttract: false
  property bool showIntro: false
  property bool showGameOver: false
  property string gameOverWinner: ""
  property string gameOverScore: ""
  property string gameOverSession: ""

  readonly property real aspect: courtW / courtH
  implicitWidth: Style.space(400)
  implicitHeight: Math.round(implicitWidth / aspect) + Style.space(44)

  readonly property real playW: width - Style.space(4)
  readonly property real playH: height - Style.space(44)
  readonly property real sx: playW / courtW
  readonly property real sy: playH / courtH

  readonly property int tick: gameState ? (gameState.tick || 0) : 0

  function mapX(x) { return (x || 0) * sx + (width - playW) / 2 }
  function mapY(y) { return (y || 0) * sy + Style.space(22) }
  function mapR(r) {
    var base = (r || 5) * Math.min(sx, sy)
    var y = gameState && gameState.ball ? gameState.ball.y : courtH / 2
    return base * (0.55 + (y / courtH) * 0.55)
  }

  function courtPoint(nx, ny) {
    var topInset = playW * 0.18
    var botInset = playW * 0.04
    var t = ny / courtH
    var left = (width - playW) / 2 + topInset + (botInset - topInset) * t
    var right = width - (width - playW) / 2 - topInset - (botInset - topInset) * t
    var x = left + (right - left) * (nx / courtW)
    var y = mapY(ny)
    return Qt.point(x, y)
  }

  Rectangle {
    anchors.fill: parent
    color: Palette.bg
    radius: Style.space(2)
  }

  Rectangle {
    x: (width - playW) / 2
    y: Style.space(22)
    width: playW
    height: playH * 0.22
    color: Palette.neonDim
    opacity: 0.35
  }

  Canvas {
    id: courtCanvas
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.fillStyle = Palette.bg
      ctx.fillRect(0, 0, width, height)

      function line(x1, y1, x2, y2, w) {
        var p1 = root.courtPoint(x1, y1)
        var p2 = root.courtPoint(x2, y2)
        ctx.strokeStyle = Palette.neonLine
        ctx.lineWidth = w || 1.5
        ctx.beginPath()
        ctx.moveTo(p1.x, p1.y)
        ctx.lineTo(p2.x, p2.y)
        ctx.stroke()
      }

      line(0, 0, courtW, 0, 2)
      line(0, courtH, courtW, courtH, 2.5)
      line(0, 0, 0, courtH, 1.5)
      line(courtW, 0, courtW, courtH, 1.5)
      line(0, courtH * 0.28, courtW, courtH * 0.28, 1)
      line(0, courtH * 0.72, courtW, courtH * 0.72, 1)
      line(courtW / 2, courtH * 0.28, courtW / 2, courtH * 0.72, 1)

      var n1 = root.courtPoint(0, courtH / 2)
      var n2 = root.courtPoint(courtW, courtH / 2)
      ctx.strokeStyle = Palette.neonBright
      ctx.lineWidth = 2.5
      ctx.beginPath()
      ctx.moveTo(n1.x, n1.y)
      ctx.lineTo(n2.x, n2.y)
      ctx.stroke()
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }

  Repeater {
    model: gameState && gameState.trail ? gameState.trail.length : 0
    delegate: Rectangle {
      required property int index
      property var dot: gameState.trail[index]
      visible: dot
      x: root.mapX(dot ? dot.x : 0) - width / 2
      y: root.mapY(dot ? dot.y : 0) - height / 2
      width: root.mapR(4)
      height: width
      radius: width / 2
      color: Palette.neon
      opacity: dot ? dot.a * 0.45 : 0
    }
  }

  // Far paddle (CPU or P2)
  Item {
    visible: gameState !== null
    x: { var _ = root.tick; root.mapX(gameState ? gameState.cpu.x : courtW / 2) - width / 2 }
    y: root.mapY(gameState ? gameState.cpu.y : 22) - height / 2
    width: (gameState ? gameState.cpu.w : 38) * sx + (gameState && gameState.cpu.swingT > 0 ? 12 : 0)
    height: Style.space(10)

    readonly property color bodyColor: root.twoPlayer ? Palette.cyan : Palette.neon
    readonly property color bodyBright: root.twoPlayer ? Palette.cyanBright : Palette.neonBright
    readonly property color bodyDim: root.twoPlayer ? Palette.cyanDim : Palette.neonDim

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: -Style.space(8)
      width: Style.space(8)
      height: Style.space(10)
      color: parent.bodyDim
    }
    Rectangle {
      anchors.fill: parent
      radius: Style.space(2)
      color: gameState && gameState.cpu.swingT > 0 ? parent.bodyBright : parent.bodyColor
    }
  }

  // Near paddle (P1)
  Item {
    visible: gameState !== null
    x: { var _ = root.tick; root.mapX(gameState ? gameState.player.x : courtW / 2) - width / 2 }
    y: root.mapY(gameState ? gameState.player.y : courtH - 22) - height / 2
    width: (gameState ? gameState.player.w : 44) * sx + (gameState && gameState.player.swingT > 0 ? 14 : 0)
    height: Style.space(11)

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: Style.space(10)
      width: Style.space(10)
      height: Style.space(12)
      color: Palette.neonBright
    }
    Rectangle {
      anchors.fill: parent
      radius: Style.space(2)
      color: gameState && gameState.player.swingT > 0 ? Palette.neonBright : Palette.neon
    }
  }

  Rectangle {
    visible: gameState !== null && gameState.phase === "rally"
    x: { var _ = root.tick; root.mapX(gameState ? gameState.ball.x : courtW / 2) - width / 2 }
    y: root.mapY(gameState ? gameState.ball.y : courtH / 2) - height / 2
    width: root.mapR(gameState ? gameState.ball.r : 5) * 2
    height: width
    radius: width / 2
    color: Palette.neonBright
  }

  Rectangle {
    visible: gameState !== null && gameState.phase === "serve"
    x: root.mapX(gameState ? gameState.ball.x : courtW / 2) - width / 2
    y: root.mapY(gameState ? gameState.ball.y : courtH - 36) - height / 2
    width: root.mapR(5) * 2
    height: width
    radius: width / 2
    color: Palette.neon
    opacity: 0.85

    SequentialAnimation on opacity {
      running: gameState && gameState.phase === "serve"
      loops: Animation.Infinite
      NumberAnimation { from: 0.45; to: 1; duration: 320 }
      NumberAnimation { from: 1; to: 0.45; duration: 320 }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Palette.neonBright
    opacity: gameState && gameState.flashT > 0 ? 0.22 * (gameState.flashT / 420) : 0
    radius: Style.space(2)
  }

  Column {
    anchors.fill: parent
    spacing: 3
    clip: true
    Repeater {
      model: Math.ceil(root.height / 5)
      delegate: Rectangle {
        width: parent.width
        height: 1
        color: Palette.scanline
        opacity: 0.09
      }
    }
  }

  // Point score + player labels (hidden during attract screen)
  Column {
    visible: !root.showAttract && !root.showIntro && !root.showGameOver
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: Style.space(3)
    spacing: Style.space(1)

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(14)

      Column {
        spacing: 0
        Text {
          textFormat: Text.PlainText
          text: root.farLabel
          color: root.twoPlayer ? Palette.cyan : Palette.neonDim
          font.family: Style.font.family
          font.pixelSize: Style.space(8)
          font.letterSpacing: Style.space(1)
          anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
          textFormat: Text.PlainText
          text: gameState ? String(gameState.cpuScore) : "0"
          color: root.twoPlayer ? Palette.cyanBright : Palette.neon
          font.family: Style.font.family
          font.pixelSize: Style.space(18)
          font.bold: true
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }

      Text {
        textFormat: Text.PlainText
        text: ":"
        color: Palette.neonDim
        font.family: Style.font.family
        font.pixelSize: Style.space(16)
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        spacing: 0
        Text {
          textFormat: Text.PlainText
          text: root.nearLabel
          color: Palette.neonDim
          font.family: Style.font.family
          font.pixelSize: Style.space(8)
          font.letterSpacing: Style.space(1)
          anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
          textFormat: Text.PlainText
          text: gameState ? String(gameState.playerScore) : "0"
          color: Palette.neonBright
          font.family: Style.font.family
          font.pixelSize: Style.space(18)
          font.bold: true
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }

  // Serve indicator — arrow at the net pointing to the server
  Item {
    visible: gameState !== null && (gameState.phase === "serve" || gameState.phase === "rally")
             && !root.showAttract && !root.showIntro && !root.showGameOver
    x: root.mapX(courtW / 2) - width / 2
    y: root.mapY(courtH / 2) - height / 2
    width: Style.space(16)
    height: Style.space(16)
    opacity: 0.85

    readonly property bool serverNear: gameState && gameState.server === "player"
    rotation: serverNear ? 180 : 0

    Canvas {
      anchors.fill: parent
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = serverNear ? Palette.neonBright : Palette.cyanBright
        ctx.beginPath()
        ctx.moveTo(width / 2, 2)
        ctx.lineTo(width - 2, height - 2)
        ctx.lineTo(2, height - 2)
        ctx.closePath()
        ctx.fill()
      }
      onWidthChanged: requestPaint()
    }
  }

  MenuAttract {
    active: root.showAttract
    twoPlayer: root.twoPlayer
  }

  MatchIntro {
    active: root.showIntro
  }

  GameOverOverlay {
    active: root.showGameOver
    twoPlayer: root.twoPlayer
    winnerLabel: root.gameOverWinner
    scoreLine: root.gameOverScore
    sessionLine: root.gameOverSession
  }
}
