import QtQuick
import qs.Commons
import "Palette.js" as Palette

// Match-end overlay with winner and updated session tally.
Item {
  id: root

  property bool active: false
  property string winnerLabel: ""
  property string scoreLine: ""
  property string sessionLine: ""
  property bool twoPlayer: false

  anchors.fill: parent
  visible: opacity > 0.01
  opacity: active ? 1 : 0

  Behavior on opacity {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.space(2)
    color: Palette.bg
    opacity: 0.82
  }

  Canvas {
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var w = width
      var h = height
      ctx.strokeStyle = Palette.neonLine
      ctx.lineWidth = 1.5
      ctx.strokeRect(w * 0.08, h * 0.12, w * 0.84, h * 0.76)
      ctx.strokeStyle = Palette.cyanDim
      ctx.strokeRect(w * 0.1, h * 0.14, w * 0.8, h * 0.72)
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }

  Column {
    anchors.centerIn: parent
    spacing: Style.space(8)
    width: parent.width * 0.86

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: "MATCH OVER"
      color: Palette.neonDim
      font.family: Style.font.family
      font.pixelSize: Style.space(10)
      font.letterSpacing: Style.space(4)
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: root.winnerLabel + " WINS"
      color: root.twoPlayer ? Palette.cyanBright : Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(22)
      font.bold: true
      font.letterSpacing: Style.space(3)
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: root.scoreLine
      color: Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(16)
      font.bold: true
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: root.sessionLine
      color: Palette.cyan
      font.family: Style.font.family
      font.pixelSize: Style.space(10)
      font.letterSpacing: Style.space(1)
      opacity: 0.9
    }

    Text {
      id: rematchHint
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: "ENTER — rematch   TAB — mode"
      color: Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(10)
      font.letterSpacing: Style.space(1)

      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 0.35; to: 1; duration: 700 }
        NumberAnimation { from: 1; to: 0.35; duration: 700 }
      }
    }
  }
}
