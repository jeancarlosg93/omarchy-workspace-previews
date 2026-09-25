import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
    previewOpen = false
  }

  property int previewWorkspaceId: -1
  property Item previewButton: null
  property bool previewOpen: false
  property bool buttonHovered: false
  readonly property var previewWorkspace: workspaceById(previewWorkspaceId)
  readonly property var previewWindows: previewWorkspace ? previewWorkspace.toplevels.values : []
  readonly property var previewMonitor: previewWindows.length && previewWindows[0].monitor
    ? previewWindows[0].monitor
    : (previewWorkspace && previewWorkspace.monitor ? previewWorkspace.monitor : Hyprland.focusedMonitor)

  function enterWorkspace(id, button) {
    hideTimer.stop()
    previewWorkspaceId = id
    previewButton = button
    buttonHovered = true
    hoverTimer.restart()
  }

  function leaveWorkspace(button) {
    if (previewButton !== button) return
    buttonHovered = false
    hoverTimer.stop()
    hideTimer.restart()
  }

  function close() {
    previewOpen = false
    hoverTimer.stop()
    hideTimer.stop()
  }

  Timer {
    id: hoverTimer
    interval: 250
    onTriggered: {
      root.previewOpen = root.buttonHovered
      if (root.previewOpen) Hyprland.refreshToplevels()
    }
  }

  Timer {
    id: hideTimer
    interval: 300
    onTriggered: if (!root.buttonHovered && !preview.containsMouse) root.previewOpen = false
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: workspaceButton
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.8
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        HoverHandler {
          onHoveredChanged: {
            if (hovered) root.enterWorkspace(workspaceButton.modelData, workspaceButton)
            else root.leaveWorkspace(workspaceButton)
          }
        }
      }
    }
  }

  PopupCard {
    id: preview
    anchorItem: root.previewButton || root
    bar: root.bar
    owner: root
    triggerMode: "hover"
    open: root.previewOpen
    contentWidth: fittedContentWidth(320)
    contentHeight: fittedContentHeight(Style.space(30) + Math.round(contentWidth * (root.previewMonitor ? root.previewMonitor.height / root.previewMonitor.width : 9 / 16)), 300)

    onContainsMouseChanged: {
      if (containsMouse) hideTimer.stop()
      else if (!root.buttonHovered) hideTimer.restart()
    }

    Column {
      anchors.fill: parent
      spacing: Style.space(1)

      TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.focusWorkspace(root.previewWorkspaceId)
      }

      Text {
        width: parent.width
        height: Style.space(28)
        text: "Workspace " + root.previewWorkspaceId
        color: Color.popups.text
        font.family: root.bar ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      Rectangle {
        id: workspaceCanvas
        width: parent.width
        height: Math.max(1, parent.height - Style.space(30))
        radius: Math.max(4, Style.cornerRadius)
        color: Color.background
        clip: true

        Text {
          anchors.centerIn: parent
          visible: root.previewWindows.length === 0
          text: "Empty workspace"
          color: Color.muted
          font.family: root.bar ? root.bar.fontFamily : "sans-serif"
          font.pixelSize: Style.font.body
        }

        Repeater {
          model: root.previewWindows

          Rectangle {
            required property var modelData
            readonly property var geometry: modelData ? modelData.lastIpcObject : null
            readonly property var monitor: root.previewMonitor
            readonly property real scaleX: monitor ? workspaceCanvas.width / monitor.width : 1
            readonly property real scaleY: monitor ? workspaceCanvas.height / monitor.height : 1
            x: geometry && geometry.at && monitor ? Math.max(0, (geometry.at[0] - monitor.x) * scaleX) : 0
            y: geometry && geometry.at && monitor ? Math.max(0, (geometry.at[1] - monitor.y) * scaleY) : 0
            width: geometry && geometry.size ? Math.max(1, geometry.size[0] * scaleX) : workspaceCanvas.width
            height: geometry && geometry.size ? Math.max(1, geometry.size[1] * scaleY) : workspaceCanvas.height
            radius: Math.max(2, Style.cornerRadius / 2)
            color: Color.popups.background
            clip: true

            ScreencopyView {
              id: windowCapture
              anchors.fill: parent
              captureSource: modelData ? (modelData.wayland || modelData.handle) : null
              live: root.previewOpen && captureSource !== null
              visible: hasContent
            }
          }
        }
      }
    }
  }
}
