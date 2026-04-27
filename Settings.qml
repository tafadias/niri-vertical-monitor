import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property bool editEnabled:  pluginApi?.pluginSettings?.enabled  ?? false
    property var  editMonitors: pluginApi?.pluginSettings?.monitors ?? []

    readonly property var main: pluginApi?.mainInstance ?? null

    spacing: 12

    // ── Toggle ─────────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Column {
            Layout.fillWidth: true
            spacing: 3

            NText {
                text: "Enable layout daemon"
                color: Color.mOnSurface
                pointSize: Style.fontSizeS
            }
            NText {
                text: "Vertically stacks windows on selected monitors"
                color: Color.mSurfaceVariant
                pointSize: Style.fontSizeXS
            }
        }

        // Simple visual toggle
        Rectangle {
            id: toggleTrack
            width: 44; height: 24; radius: 12
            color: root.editEnabled ? Color.mPrimary : Color.mSurfaceVariant

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                id: toggleThumb
                width: 18; height: 18; radius: 9
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.editEnabled ? parent.width - width - 3 : 3

                Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.editEnabled = !root.editEnabled
            }
        }
    }

    // ── Divider ────────────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.mSurfaceVariant
        opacity: 0.4
    }

    // ── Monitors header ────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Column {
            Layout.fillWidth: true
            spacing: 3

            NText {
                text: "Monitors"
                color: Color.mOnSurface
                pointSize: Style.fontSizeS
            }
            NText {
                text: {
                    if (root.main?.detectingMonitors ?? false) return "Detecting…"
                    var n = (root.main?.availableMonitors ?? []).length
                    return n > 0 ? n + " monitor(s) detected" : "No monitor detected"
                }
                color: Color.mSurfaceVariant
                pointSize: Style.fontSizeXS
            }
        }

        // Refresh button
        Rectangle {
            width: 28; height: 28; radius: 6
            color: refreshArea.containsMouse ? Color.mSurfaceVariant : "transparent"

            NIcon {
                anchors.centerIn: parent
                icon: "refresh"
                color: Color.mOnSurface
            }

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !(root.main?.detectingMonitors ?? false)
                onClicked: root.main?.detectMonitors()
            }
        }
    }

    // Detection error
    NText {
        text: root.main?.detectError ?? ""
        color: Color.mError
        pointSize: Style.fontSizeXS
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        visible: (root.main?.detectError ?? "") !== ""
    }

    // ── Monitors list ──────────────────────────────────────────────────────────
    Repeater {
        model: root.main?.availableMonitors ?? []

        delegate: RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Simple checkbox
            Rectangle {
                width: 20; height: 20; radius: 4
                color: isChecked ? Color.mPrimary : "transparent"
                border.color: isChecked ? Color.mPrimary : Color.mSurfaceVariant
                border.width: 2

                property bool isChecked: root.editMonitors.indexOf(modelData) !== -1

                NIcon {
                    anchors.centerIn: parent
                    icon: "check"
                    color: "white"
                    visible: parent.isChecked
                    width: 14; height: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var name = modelData
                        var list = root.editMonitors.slice()
                        var pos  = list.indexOf(name)
                        if (pos === -1) list.push(name)
                        else           list.splice(pos, 1)
                        root.editMonitors = list
                    }
                }
            }

            NText {
                text: modelData
                color: Color.mOnSurface
                pointSize: Style.fontSizeS
                Layout.fillWidth: true
            }
        }
    }

    // Saved monitors but offline
    Repeater {
        model: {
            if (root.main?.detectingMonitors ?? true) return []
            var avail = root.main?.availableMonitors ?? []
            return root.editMonitors.filter(function(m) { return avail.indexOf(m) === -1 })
        }

        delegate: RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 20; height: 20; radius: 4
                color: Color.mTertiary
                border.color: Color.mTertiary
                border.width: 2

                NIcon {
                    anchors.centerIn: parent
                    icon: "check"
                    color: "white"
                    width: 14; height: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var name = modelData
                        var list = root.editMonitors.slice()
                        var pos  = list.indexOf(name)
                        if (pos !== -1) list.splice(pos, 1)
                        root.editMonitors = list
                    }
                }
            }

            NText {
                text: modelData + " (offline)"
                color: Color.mSurfaceVariant
                pointSize: Style.fontSizeS
                Layout.fillWidth: true
            }
        }
    }

    // ── Divider ────────────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.mSurfaceVariant
        opacity: 0.4
    }

    // ── IPC Hint ───────────────────────────────────────────────────────────────
    NText {
        text: "IPC: qs ipc call plugin:niri-vertical-monitor toggle"
        color: Color.mSurfaceVariant
        pointSize: Style.fontSizeXS
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    // ── Save ───────────────────────────────────────────────────────────────────
    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.enabled  = root.editEnabled
        pluginApi.pluginSettings.monitors = root.editMonitors
        pluginApi.saveSettings()
        Logger.i("NiriLayout", "Saved — enabled:", root.editEnabled,
                 "monitors:", root.editMonitors.join(", "))
        if (root.main) root.main.reloadDaemon()
    }
}
