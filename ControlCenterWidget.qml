import QtQuick
import Quickshell
import qs.Widgets

// O widget correto para o Centro de Controle é NIconButtonHot,
// conforme a documentação oficial do Noctalia.
NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    readonly property bool isRunning: pluginApi?.mainInstance?.daemonRunning ?? false

    icon: isRunning ? "dashboard" : "dashboard-off"
    tooltipText: {
        if (!(pluginApi?.pluginSettings?.enabled ?? false)) return "Niri Layout — Desativado"
        var mons = pluginApi?.pluginSettings?.monitors ?? []
        if (mons.length === 0) return "Niri Layout — Sem monitores"
        return "Niri Layout — " + (isRunning ? "Rodando" : "Parado")
    }

    onClicked: {
        if (pluginApi?.mainInstance?.toggleEnabled) {
            pluginApi.mainInstance.toggleEnabled()
        }
    }
}
