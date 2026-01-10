#!/usr/bin/env bash

# Obviously let's start ironbar first and then add this line:
# exec-once = ~/.local/bin/wifi-ssid.sh

# Wait until ironbar is ready
until ironbar var set wifi_ssid "" 2>/dev/null; do
  sleep 0.5
done

# Get the wireless interface name
get_wifi_interface() {
  local iface
  for iface in /sys/class/net/wl*; do
    if [[ -d "$iface" ]]; then
      basename "$iface"
      return
    fi
  done
}

update_ssid() {
  local ssid
  local iface

  iface=$(get_wifi_interface)

  if [[ -n "$iface" ]]; then
    ssid=$(iwctl station "$iface" show 2>/dev/null | sed -n 's/.*Connected network[[:space:]]*//p' | xargs)
  fi

  if [[ -z "$ssid" ]]; then
    ssid="disconnected"
  fi

  ironbar var set wifi_ssid "$ssid"
}

# Set initial value
update_ssid

# Monitor wireless events and update on changes
iw event | while read -r _; do
  update_ssid
done
