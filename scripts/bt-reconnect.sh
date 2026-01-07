#!/bin/bash
# Reconnect Bluetooth headphones after resume from sleep
# Called by systemd sleep hook

set -euo pipefail

# Populate here MAC address of the headphones
HEADPHONES_MAC=""
LOG_TAG="bt-reconnect"

log() {
  logger -t "$LOG_TAG" "$*" 2>/dev/null || true
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

reconnect() {
  log "Attempting to reconnect to $HEADPHONES_MAC..."

  # Wait for bluetooth adapter to initialize
  sleep 3

  # Ensure adapter is powered
  bluetoothctl power on
  sleep 1

  # Try to connect (may fail if headphones went to sleep)
  if bluetoothctl connect "$HEADPHONES_MAC"; then
    log "Reconnection successful"
  else
    log "Reconnection failed - headphones may be off or out of range"
  fi
}

case "${1:-}" in
reconnect)
  reconnect
  ;;
*)
  echo "Usage: $0 reconnect"
  exit 1
  ;;
esac
