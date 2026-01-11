#!/bin/bash
# Auto-switch default audio sink/source to Bluetooth when connected
# Monitors BlueZ for device connection events
#
# Run as: bt-auto-switch.sh (monitors continuously)
# Or:     bt-auto-switch.sh switch (one-shot switch to BT if connected)

set -euo pipefail

LOG_TAG="bt-auto-switch"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    logger -t "$LOG_TAG" "$*" 2>/dev/null || true
}

wait_for_bt_audio() {
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if wpctl status 2>/dev/null | grep -qE "bluez_output\.[^[:space:]]+"; then
            return 0
        fi
        sleep 0.5
        ((attempt++))
    done
    return 1
}

get_bluetooth_sink_id() {
    wpctl status 2>/dev/null | grep -E "bluez_output\." | head -1 | sed 's/[^0-9]*\([0-9]*\)\..*/\1/'
}

get_bluetooth_source_id() {
    wpctl status 2>/dev/null | grep -E "bluez_input\." | head -1 | sed 's/[^0-9]*\([0-9]*\)\..*/\1/'
}

switch_to_bluetooth() {
    log "Switching to Bluetooth audio..."

    if ! wait_for_bt_audio; then
        log "Timeout waiting for Bluetooth audio device"
        return 1
    fi

    local sink_id
    sink_id=$(get_bluetooth_sink_id)

    if [ -n "$sink_id" ]; then
        log "Setting Bluetooth sink (id=$sink_id) as default"
        if wpctl set-default "$sink_id"; then
            log "Sink switch successful"
        else
            log "Sink switch failed"
        fi
    else
        log "No Bluetooth sink found"
    fi

    local source_id
    source_id=$(get_bluetooth_source_id)

    if [ -n "$source_id" ]; then
        log "Setting Bluetooth source (id=$source_id) as default"
        if wpctl set-default "$source_id"; then
            log "Source switch successful"
        else
            log "Source switch failed"
        fi
    fi
}

monitor_bluetooth() {
    log "Starting Bluetooth connection monitor..."

    # Monitor BlueZ for Connected property changes
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" 2>/dev/null |
    while read -r line; do
        if echo "$line" | grep -q "Connected"; then
            read -r next_line
            if echo "$next_line" | grep -q "true"; then
                log "Bluetooth device connected"
                # Small delay to let audio profile initialize
                sleep 2
                switch_to_bluetooth
            fi
        fi
    done
}

case "${1:-monitor}" in
    switch)
        switch_to_bluetooth
        ;;
    monitor|"")
        monitor_bluetooth
        ;;
    *)
        echo "Usage: $0 [switch|monitor]"
        echo "  switch  - One-shot switch to Bluetooth if available"
        echo "  monitor - Continuously monitor for BT connections (default)"
        exit 1
        ;;
esac
