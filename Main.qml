import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    // Public state — read by BarWidget, ControlCenterWidget and Settings
    readonly property bool daemonRunning: daemon.running
    property var  availableMonitors: []
    property bool detectingMonitors: false
    property string detectError: ""

    // Guard against infinite restart loop
    property int _restartAttempts: 0
    property int _maxRestarts: 5
    property var _monBuf: []

    // ── Monitor detection (called by Settings via mainInstance) ────────────────
    function detectMonitors() {
        _monBuf = []
        detectingMonitors = true
        detectError = ""
        monitorProc.running = true
    }

    Process {
        id: monitorProc
        running: false
        command: ["sh", "-c", "niri msg --json outputs 2>/dev/null | jq -r '.[].name'"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var name = line.trim()
                if (name) root._monBuf.push(name)
            }
        }

        onRunningChanged: {
            if (!running) {
                root.detectingMonitors = false
                if (root._monBuf.length > 0) {
                    root.availableMonitors = root._monBuf.slice()
                    Logger.i("NiriLayout", "Monitors:", root.availableMonitors.join(", "))
                } else {
                    root.detectError = "No monitor detected — check if niri and jq are in PATH"
                    Logger.w("NiriLayout", root.detectError)
                }
            }
        }
    }

    // ── Public API ─────────────────────────────────────────────────────────────
    function reloadDaemon() {
        Logger.i("NiriLayout", "Reload requested")
        _restartAttempts = 0
        stopDaemon()
        restartTimer.start()
    }

    function stopDaemon() {
        restartTimer.stop()
        if (daemon.running) {
            daemon.running = false
            Logger.i("NiriLayout", "Daemon stopped")
        }
    }

    function toggleEnabled() {
        if (!pluginApi) return
        var next = !(pluginApi.pluginSettings.enabled ?? false)
        pluginApi.pluginSettings.enabled = next
        pluginApi.saveSettings()
        if (next) {
            _restartAttempts = 0
            restartTimer.start()
        } else {
            stopDaemon()
        }
        ToastService.showNotice("Niri Layout: " + (next ? "enabled" : "disabled"))
    }

    // ── Process lifecycle ──────────────────────────────────────────────────────
    Timer {
        id: restartTimer
        interval: 400
        repeat: false
        onTriggered: _doStart()
    }

    function _doStart() {
        if (!(pluginApi?.pluginSettings?.enabled ?? false)) return

        var mons = pluginApi?.pluginSettings?.monitors ?? []
        if (mons.length === 0) {
            Logger.w("NiriLayout", "No monitor configured")
            ToastService.showNotice("Niri Layout: configure at least one monitor in settings")
            return
        }

        var scriptPath = pluginApi.pluginDir + "/layout-daemon.sh"
        daemon.command = ["bash", scriptPath].concat(mons)
        daemon.running = true
        Logger.i("NiriLayout", "Daemon started:", mons.join(", "))
    }

    Process {
        id: daemon
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim()) Logger.d("NiriLayout", line)
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim()) Logger.w("NiriLayout", "[stderr]", line)
            }
        }

        onRunningChanged: {
            if (!running
                && (pluginApi?.pluginSettings?.enabled ?? false)
                && root._restartAttempts < root._maxRestarts)
            {
                root._restartAttempts++
                Logger.w("NiriLayout", "Process terminated — restarting",
                         root._restartAttempts + "/" + root._maxRestarts)
                restartTimer.interval = 400 + (600 * root._restartAttempts)
                restartTimer.start()
            }
        }
    }

    // ── Initialization ─────────────────────────────────────────────────────────
    onPluginApiChanged: {
        if (!pluginApi) return
        Logger.i("NiriLayout", "Plugin loaded — enabled:",
                 pluginApi.pluginSettings.enabled,
                 "monitors:", JSON.stringify(pluginApi.pluginSettings.monitors ?? []))
        detectMonitors()
        if (pluginApi.pluginSettings.enabled ?? false) {
            restartTimer.start()
        }
    }

    Component.onDestruction: stopDaemon()

    // ── IPC ────────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "plugin:niri-vertical-monitor"

        function toggle()  { root.toggleEnabled() }

        function enable() {
            if (!pluginApi || (pluginApi.pluginSettings.enabled ?? false)) return
            pluginApi.pluginSettings.enabled = true
            pluginApi.saveSettings()
            root._restartAttempts = 0
            restartTimer.start()
            ToastService.showNotice("Niri Layout: enabled")
        }

        function disable() {
            if (!pluginApi || !(pluginApi.pluginSettings.enabled ?? false)) return
            pluginApi.pluginSettings.enabled = false
            pluginApi.saveSettings()
            root.stopDaemon()
            ToastService.showNotice("Niri Layout: disabled")
        }

        function reload() {
            if (!pluginApi) return
            root.reloadDaemon()
            ToastService.showNotice("Niri Layout: daemon restarted")
        }
    }
}
