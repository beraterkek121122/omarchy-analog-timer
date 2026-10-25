import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Bar menüsü: masaüstü saatini boyutlandırır ve köşesini seçer.
// Ayarları settings.conf dosyasına yazar; Clock.qml izleyip uygular.
Panel {
  id: root

  moduleName: "berat.analog-clock"
  ipcTarget: "berat.analog-clock"

  readonly property string settingsPath: Quickshell.env("HOME")
      + "/.config/omarchy/analog-clock.conf"

  property int clockSize: 200
  property string clockCorner: "tr"
  property bool clockEnabled: true

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property color fg: bar ? bar.foreground : Commons.Color.foreground
  readonly property color accentColor: Commons.Color.accent
  readonly property var corners: [
    { key: "tl", glyph: "↖" },
    { key: "tr", glyph: "↗" },
    { key: "bl", glyph: "↙" },
    { key: "br", glyph: "↘" }
  ]

  function applySettings(raw) {
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*(\w+)\s*=\s*(.+?)\s*$/)
      if (!m) continue
      if (m[1] === "size") {
        var n = Number(m[2])
        if (isFinite(n) && n >= 120 && n <= 420) root.clockSize = Math.round(n)
      } else if (m[1] === "corner") {
        if (["tl", "tr", "bl", "br"].indexOf(m[2]) !== -1) root.clockCorner = m[2]
      } else if (m[1] === "enabled") {
        root.clockEnabled = m[2] !== "0" && m[2] !== "false"
      }
    }
  }

  function persist() {
    writer.command = ["sh", "-c",
      "printf 'enabled=%s\\nsize=%s\\ncorner=%s\\n' '"
      + (root.clockEnabled ? "1" : "0") + "' '" + root.clockSize + "' '" + root.clockCorner + "' > '"
      + root.settingsPath + "'"]
    writer.running = true
  }

  function setSize(value) {
    root.clockSize = Math.max(120, Math.min(420, Math.round(value)))
    persist()
  }

  function setCorner(value) {
    root.clockCorner = value
    persist()
  }

  function setEnabled(value) {
    root.clockEnabled = value
    persist()
  }

  FileView {
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applySettings(text())
    onFileChanged: reload()
    onLoadFailed: root.applySettings("")
  }

  Process {
    id: writer
  }

  // ─── Bar ikonu ─────────────────────────────────────────────────────────────
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf017"
    tooltipText: "Analog saat ayarları"
    onPressed: root.toggle()
  }

  // ─── Menü ──────────────────────────────────────────────────────────────────
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: 14

      Text {
        text: "Analog Saat"
        color: root.fg
        font.bold: true
        font.pixelSize: Style.font.title
      }

      // Göster / gizle
      Item {
        width: parent.width
        implicitHeight: Math.max(showLabel.implicitHeight, showSwitch.implicitHeight)

        Text {
          id: showLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Göster"
          color: root.fg
          font.pixelSize: Style.font.body
        }

        ToggleSwitch {
          id: showSwitch
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          foreground: root.fg
          accent: root.accentColor
          checked: root.clockEnabled
          onToggled: root.setEnabled(!root.clockEnabled)
        }
      }

      // Boyut
      Item {
        width: parent.width
        implicitHeight: Math.max(sizeLabel.implicitHeight, sizeValue.implicitHeight, minusButton.height)

        Text {
          id: sizeLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Boyut"
          color: root.fg
          font.pixelSize: Style.font.body
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          StepButton {
            id: minusButton
            glyph: "−"
            onActivated: root.setSize(root.clockSize - 20)
          }

          Text {
            id: sizeValue
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignHCenter
            text: root.clockSize + " px"
            color: root.fg
            font.pixelSize: Style.font.body
          }

          StepButton {
            glyph: "+"
            onActivated: root.setSize(root.clockSize + 20)
          }
        }
      }

      // Konum
      Item {
        width: parent.width
        implicitHeight: Math.max(cornerLabel.implicitHeight, cornerRow.height)

        Text {
          id: cornerLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Konum"
          color: root.fg
          font.pixelSize: Style.font.body
        }

        Row {
          id: cornerRow
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Repeater {
            model: root.corners

            StepButton {
              required property var modelData
              glyph: modelData.glyph
              active: root.clockCorner === modelData.key
              onActivated: root.setCorner(modelData.key)
            }
          }
        }
      }

      Text {
        width: parent.width
        text: "Değişiklikler anında uygulanır."
        color: root.fg
        opacity: 0.6
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  component StepButton: Rectangle {
    id: step

    property string glyph: ""
    property bool active: false
    signal activated

    width: 34
    height: 30
    radius: 6
    color: step.active
      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
      : "transparent"
    border.width: 1
    border.color: step.active ? root.accentColor : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.28)

    Text {
      anchors.centerIn: parent
      text: step.glyph
      color: step.active ? root.accentColor : root.fg
      font.pixelSize: Style.font.body
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: step.activated()
    }
  }
}
