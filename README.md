# Niri Vertical Monitor

Plugin for [Noctalia Shell](https://noctalia.dev) that automatically stacks windows in a vertical layout on monitors of your choice — integrated with the [Niri](https://github.com/YaLTeR/niri) compositor.

## What it does

Every time a window is opened or moved to one of the configured monitors, the daemon positions it below the others, always forming a vertical column. It works correctly with:

- Windows emitting notifications (does not reposition)
- Closed windows (clears from tracking)
- Windows moved between workspaces (reapplies the layout when returning)

## Installation

### 1. Copy the plugin

```bash
cp -r niri-vertical-monitor ~/.config/noctalia/plugins/
chmod +x ~/.config/noctalia/plugins/niri-vertical-monitor/layout-daemon.sh
```

### 2. Restart Noctalia

```bash
killall qs && qs -c noctalia-shell
```

### 3. Enable and configure

1. Open Noctalia Settings
2. Go to **Plugins → Niri Vertical Monitor → Configure**
3. Select the monitors where the layout should be applied
4. Enable the main toggle
5. Click **Save**

## IPC

You can control the daemon via command line or keybind:

```bash
# Toggle enabled/disabled
qs ipc call plugin:niri-vertical-monitor toggle

# Enable
qs ipc call plugin:niri-vertical-monitor enable

# Disable
qs ipc call plugin:niri-vertical-monitor disable

# Restart (after changing monitors manually)
qs ipc call plugin:niri-vertical-monitor reload
```

Example keybind in Niri (`~/.config/niri/config.kdl`):

```kdl
binds {
    Mod+Shift+L { spawn "qs" "ipc" "call" "plugin:niri-vertical-monitor" "toggle"; }
}
```
