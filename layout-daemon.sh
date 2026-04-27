#!/bin/bash
# Niri Vertical Monitor — vertically stacks windows on specified monitors.
# Usage: layout-daemon.sh MONITOR1 MONITOR2 ...
# Example: layout-daemon.sh DP-4 HDMI-A-2

declare -A target_monitors
declare -A processed_windows  # window_id -> workspace_id

for monitor in "$@"; do
    target_monitors["$monitor"]=1
done

if [ ${#target_monitors[@]} -eq 0 ]; then
    echo "[niri-layout] No monitor specified. Exiting." >&2
    exit 1
fi

echo "[niri-layout] Monitoring: ${!target_monitors[*]}"

# Uses process substitution so the while loop runs in the main shell,
# keeping access to associative arrays between iterations.
while read -r event rest; do

    # --- Window closed: remove from tracking ---
    if [[ "$event" == "close" ]]; then
        wid="$rest"
        if [[ -n "${processed_windows[$wid]}" ]]; then
            unset "processed_windows[$wid]"
        fi
        continue
    fi

    # --- Window opened or changed ---
    read -r wid wsid <<< "$rest"

    # Invalid workspace (window still being mapped)
    if [[ "$wsid" == "null" || -z "$wsid" ]]; then continue; fi

    if [[ -n "${processed_windows[$wid]}" ]]; then
        if [[ "${processed_windows[$wid]}" == "$wsid" ]]; then
            # Same workspace → notification/title changed. Ignore.
            continue
        else
            # Changed workspace → reprocess
            unset "processed_windows[$wid]"
        fi
    fi

    # Finds the monitor associated with the workspace
    output=$(niri msg --json workspaces 2>/dev/null | jq -r ".[] | select(.id == $wsid) | .output // empty")
    [[ -z "$output" ]] && continue

    # Applies only to configured monitors
    if [[ -n "${target_monitors[$output]}" ]]; then
        sleep 0.2
        niri msg action focus-window --id "$wid" 2>/dev/null
        niri msg action consume-or-expel-window-left 2>/dev/null
        processed_windows[$wid]="$wsid"
        echo "[niri-layout] Layout applied: window $wid → $output (workspace $wsid)"
    fi

done < <(niri msg --json event-stream 2>/dev/null | jq --unbuffered -r '
    if .WindowOpenedOrChanged != null then
        "open \(.WindowOpenedOrChanged.window.id) \(.WindowOpenedOrChanged.window.workspace_id // "null")"
    elif .WindowClosed != null then
        "close \(.WindowClosed.id)"
    else empty
    end
')

echo "[niri-layout] Stream ended." >&2
