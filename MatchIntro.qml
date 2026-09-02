import QtQuick
import qs.Commons
import "Palette.js" as Palette

// Brief match-start flash when ENTER is pressed.
Item {
  id: root

  property bool active: false

  anchors.fill: parent
  visible: opacity > 0.01
  opacity: active ? 1 : 0

  Behavior on opacity {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.space(2)
    color: Palette.bg
    opacity: 0.78
  }

  Column {
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: "READY"
      color: Palette.cyanBright
      font.family: Style.font.family
      font.pixelSize: Style.space(14)
      font.letterSpacing: Style.space(5)
      opacity: 0.85
    }

    Text {
      id: fightText
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: "FIGHT!"
      color: Palette.neonBright
      font.family: Style.font.family
      font.pixelSize: Style.space(28)
      font.bold: true
      font.letterSpacing: Style.space(6)

      scale: root.active ? 1 : 1.35
      Behavior on scale {
        NumberAnimation { duration: 420; easing.type: Easing.OutBack }
      }
    }
  }
}
