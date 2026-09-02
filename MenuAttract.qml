import QtQuick
import qs.Commons
import "Palette.js" as Palette

// Vintage synthwave attract screen drawn over the court at the menu.
Item {
  id: root

  property bool active: false
  property bool twoPlayer: false

  anchors.fill: parent
  visible: opacity > 0.01
  opacity: active ? 1 : 0

  Behavior on opacity {
    NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.space(2)
    color: Palette.bg
    opacity: 0.72
  }

  Canvas {
    id: art
    anchors.fill: parent
    property real sunPulse: 1

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onSunPulseChanged: requestPaint()

    SequentialAnimation on sunPulse {
      running: root.active
      loops: Animation.Infinite
      NumberAnimation { from: 0.94; to: 1.06; duration: 2200; easing.type: Easing.InOutSine }
      NumberAnimation { from: 1.06; to: 0.94; duration: 2200; easing.type: Easing.InOutSine }
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      var w = width
      var h = height
      var horizon = h * 0.46
      var cx = w / 2
      var pulse = sunPulse

      var sky = ctx.createLinearGradient(0, 0, 0, horizon)
      sky.addColorStop(0, "#120018")
      sky.addColorStop(1, "#030308")
      ctx.fillStyle = sky
      ctx.fillRect(0, 0, w, horizon)

      var sunR = Math.min(w, h) * 0.17 * pulse
      ctx.fillStyle = Palette.neon
      ctx.globalAlpha = 0.22
      ctx.beginPath()
      ctx.arc(cx, horizon - sunR * 0.15, sunR * 1.15, 0, Math.PI * 2)
      ctx.fill()
      ctx.globalAlpha = 0.55
      ctx.fillStyle = Palette.neonBright
      ctx.beginPath()
      ctx.arc(cx, horizon - sunR * 0.15, sunR, 0, Math.PI * 2)
      ctx.fill()
      ctx.globalAlpha = 1

      ctx.strokeStyle = Palette.bg
      ctx.lineWidth = 2
      for (var i = 0; i < 5; i++) {
        var sy = horizon - sunR * 0.15 - sunR * 0.35 + i * sunR * 0.18
        ctx.beginPath()
        ctx.moveTo(cx - sunR, sy)
        ctx.lineTo(cx + sunR, sy)
        ctx.stroke()
      }

      ctx.strokeStyle = Palette.cyan
      ctx.globalAlpha = 0.28
      ctx.lineWidth = 1
      var rows = 7
      for (var r = 0; r <= rows; r++) {
        var t = r / rows
        var gy = horizon + (h - horizon) * t * t
        ctx.beginPath()
        ctx.moveTo(0, gy)
        ctx.lineTo(w, gy)
        ctx.stroke()
      }
      var cols = 9
      for (var c = -cols; c <= cols; c++) {
        ctx.beginPath()
        ctx.moveTo(cx + c * w * 0.04, horizon)
        ctx.lineTo(cx + c * w * 0.42, h)
        ctx.stroke()
      }
      ctx.globalAlpha = 1

      ctx.fillStyle = Palette.neonDim
      ctx.globalAlpha = 0.55
      ctx.beginPath()
      ctx.moveTo(0, horizon)
      ctx.lineTo(w * 0.12, horizon - h * 0.07)
      ctx.lineTo(w * 0.22, horizon - h * 0.03)
      ctx.lineTo(w * 0.34, horizon - h * 0.11)
      ctx.lineTo(w * 0.48, horizon - h * 0.04)
      ctx.lineTo(w * 0.58, horizon - h * 0.13)
      ctx.lineTo(w * 0.72, horizon - h * 0.05)
      ctx.lineTo(w * 0.86, horizon - h * 0.09)
      ctx.lineTo(w, horizon - h * 0.02)
      ctx.lineTo(w, horizon)
      ctx.closePath()
      ctx.fill()
      ctx.globalAlpha = 1

      ctx.strokeStyle = Palette.neonLine
      ctx.lineWidth = 1.5
      function bracket(x, y, sx, sy) {
        var len = Math.min(w, h) * 0.07
        ctx.beginPath()
        ctx.moveTo(x, y + sy * len)
        ctx.lineTo(x, y)
        ctx.lineTo(x + sx * len, y)
        ctx.stroke()
      }
      bracket(w * 0.06, h * 0.08, 1, 1)
      bracket(w * 0.94, h * 0.08, -1, 1)
      bracket(w * 0.06, h * 0.92, 1, -1)
      bracket(w * 0.94, h * 0.92, -1, -1)
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: Style.space(4)
    width: parent.width * 0.88

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: "NEON VALLEY"
      color: Palette.cyanBright
      font.family: Style.font.family
      font.pixelSize: Style.space(11)
      font.letterSpacing: Style.space(6)
      opacity: 0.9
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: "VOLLEY"
      color: Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(34)
      font.bold: true
      font.letterSpacing: Style.space(8)
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(28)
        height: Style.space(3)
        radius: 1
        color: root.twoPlayer ? Palette.cyanDim : Palette.neon
        opacity: root.twoPlayer ? 0.35 : 1
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: root.twoPlayer ? "2P LOCAL" : "1P VS CPU"
        color: root.twoPlayer ? Palette.cyan : Palette.neonBright
        font.family: Style.font.family
        font.pixelSize: Style.space(10)
        font.bold: true
        font.letterSpacing: Style.space(2)
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        width: Style.space(28)
        height: Style.space(3)
        radius: 1
        color: root.twoPlayer ? Palette.cyan : Palette.neon
        opacity: root.twoPlayer ? 1 : 0.35
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Rectangle {
      id: ballDot
      width: Style.space(10)
      height: Style.space(10)
      radius: width / 2
      color: Palette.neonBright
      anchors.horizontalCenter: parent.horizontalCenter

      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 0.35; to: 1; duration: 480 }
        NumberAnimation { from: 1; to: 0.35; duration: 480 }
      }
    }

    Text {
      id: pressPrompt
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: "▶  PRESS ENTER"
      color: Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(11)
      font.letterSpacing: Style.space(2)

      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 0.25; to: 1; duration: 620; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 1; to: 0.25; duration: 620; easing.type: Easing.InOutQuad }
      }
    }
  }

  Rectangle {
    id: sweepBar
    width: parent.width
    height: Style.space(3)
    color: Palette.neonBright
    opacity: 0.07
    y: -height

    SequentialAnimation on y {
      running: root.active
      loops: Animation.Infinite
      NumberAnimation { from: -sweepBar.height; to: root.height + sweepBar.height; duration: 3200; easing.type: Easing.InOutQuad }
    }
  }
}
