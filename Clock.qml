import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Masaüstü analog saati.
// Ayar dosyası bar menüsünden (BarWidget.qml) yazılır; bu dosya izler.
PanelWindow {
  id: root

  readonly property string settingsPath: Quickshell.env("HOME")
      + "/.config/omarchy/analog-clock.conf"

  property int clockSize: 200
  property string corner: "tr"
  property bool clockEnabled: true

  readonly property bool onLeft: corner === "tl" || corner === "bl"
  readonly property bool onBottom: corner === "bl" || corner === "br"
  readonly property int edge: 48
  readonly property real cx: clockSize / 2
  readonly property color minuteColor: "#1565c0"
  readonly property color secondColor: "#d32f2f"

  anchors {
    top: !root.onBottom
    bottom: root.onBottom
    left: root.onLeft
    right: !root.onLeft
  }
  margins {
    top: root.onBottom ? 0 : root.edge
    bottom: root.onBottom ? root.edge : 0
    left: root.onLeft ? root.edge : 0
    right: root.onLeft ? 0 : root.edge
  }
  implicitWidth: clockSize
  implicitHeight: clockSize
  visible: clockEnabled

  color: "transparent"
  WlrLayershell.namespace: "berat-analog-clock"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  FileView {
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applySettings(text())
    onFileChanged: reload()
    onLoadFailed: root.applySettings("")
  }

  function applySettings(raw) {
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*(\w+)\s*=\s*(.+?)\s*$/)
      if (!m) continue
      if (m[1] === "size") {
        var n = Number(m[2])
        if (isFinite(n) && n >= 120 && n <= 420) root.clockSize = Math.round(n)
      } else if (m[1] === "corner") {
        if (["tl", "tr", "bl", "br"].indexOf(m[2]) !== -1) root.corner = m[2]
      } else if (m[1] === "enabled") {
        root.clockEnabled = m[2] !== "0" && m[2] !== "false"
      }
    }
  }

  // ─── Kadran ────────────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: "#ffffff"
    border.width: Math.max(2, root.clockSize * 0.012)
    border.color: "#000000"
  }

  // Roma rakamları
  Repeater {
    model: ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]

    Text {
      required property int index
      required property string modelData

      readonly property real ang: index * Math.PI / 6
      readonly property real r: root.clockSize * 0.33

      x: root.cx + Math.sin(ang) * r - width / 2
      y: root.cx - Math.cos(ang) * r - height / 2

      text: modelData
      color: "#111111"
      font.family: "serif"
      font.bold: true
      font.pixelSize: Math.max(9, root.clockSize * 0.092)
    }
  }

  // ─── Akrepler ──────────────────────────────────────────────────────────────
  component Hand: Rectangle {
    id: hand

    required property real handLength
    required property real handAngle
    required property real tail
    required property real thickness
    required property color handColor
    property bool animated: false

    width: hand.thickness
    height: hand.handLength + hand.tail
    radius: width / 2
    color: hand.handColor
    x: root.cx - hand.thickness / 2
    y: root.cx - hand.handLength

    transform: Rotation {
      origin.x: hand.width / 2
      origin.y: hand.handLength
      angle: hand.handAngle

      Behavior on angle {
        enabled: hand.animated
        NumberAnimation {
          duration: 150
          easing.type: Easing.Linear
        }
      }
    }
  }

  // Akrep — siyah
  Hand {
    handLength: root.clockSize * 0.26
    thickness: Math.max(4, root.clockSize * 0.035)
    tail: root.clockSize * 0.05
    handColor: "#111111"
    handAngle: (clock.hours % 12) * 30 + clock.minutes * 0.5 + clock.seconds / 120
    animated: true
  }

  // Yelkovan — mavi
  Hand {
    handLength: root.clockSize * 0.38
    thickness: Math.max(3, root.clockSize * 0.024)
    tail: root.clockSize * 0.06
    handColor: root.minuteColor
    handAngle: clock.minutes * 6 + clock.seconds * 0.1
    animated: true
  }

  // Saniye — kırmızı
  Hand {
    handLength: root.clockSize * 0.44
    thickness: Math.max(1.5, root.clockSize * 0.008)
    tail: root.clockSize * 0.08
    handColor: root.secondColor
    handAngle: clock.seconds * 6
  }

  // Göbek
  Rectangle {
    width: root.clockSize * 0.06
    height: width
    radius: width / 2
    x: root.cx - width / 2
    y: root.cx - height / 2
    color: "#111111"
  }

  Rectangle {
    width: root.clockSize * 0.022
    height: width
    radius: width / 2
    x: root.cx - width / 2
    y: root.cx - height / 2
    color: root.secondColor
  }

  // Tıklama: bar'daki ayar menüsünü açar
  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached(["omarchy-shell", "berat.analog-clock", "toggle"])
  }
}
