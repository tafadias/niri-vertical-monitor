import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property bool isEnabled:  pluginApi?.pluginSettings?.enabled ?? false
    readonly property bool isRunning:  pluginApi?.mainInstance?.daemonRunning ?? false
    readonly property var  monitors:   pluginApi?.pluginSettings?.monitors ?? []
    readonly property bool noMonitors: monitors.length === 0

    readonly property color dotColor: {
        if (!isEnabled)  return Color.mSurfaceVariant
        if (noMonitors)  return Color.mTertiary
        if (isRunning)   return Color.mPrimary
        return Color.mError
    }

    implicitWidth:  row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight
    color:          Style.capsuleColor
    radius:         Style.radiusM

    ToolTip.visible: hov.containsMouse
    ToolTip.delay:   600
    ToolTip.text: {
        if (!root.isEnabled)  return "Niri Layout — Desativado"
        if (root.noMonitors)  return "Niri Layout — Nenhum monitor configurado"
        return "Niri Layout — " + (root.isRunning ? "Rodando" : "Parado")
               + "\n" + root.monitors.join(", ")
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
            icon: "dashboard"
            color: root.isRunning ? Color.mPrimary : Color.mSurfaceVariant
            Layout.preferredWidth:  Style.iconSizeS
            Layout.preferredHeight: Style.iconSizeS
        }

        Rectangle {
            width: 7; height: 7; radius: 4
            color: root.dotColor
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        NText {
            text: root.noMonitors ? "layout" : root.monitors.join(" · ")
            color: root.isRunning ? Color.mOnSurface : Color.mSurfaceVariant
            pointSize: Style.fontSizeXS
        }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (pluginApi?.mainInstance?.toggleEnabled) {
                pluginApi.mainInstance.toggleEnabled()
            }
        }
    }
}
