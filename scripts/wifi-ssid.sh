#!/usr/bin/env bash

# Obviously let's start ironbar first and then add this line:
# exec-once = ~/.local/bin/wifi-ssid.sh

# Wait until ironbar is ready
until ironbar var set wifi_ssid "" 2>/dev/null; do
  sleep 0.5
done

update_ssid() {
  local ssid
  ssid=$(iwgetid -r)

  if [[ -z "$ssid" ]]; then
    ssid="disconnected"
  fi

  ironbar var set wifi_ssid "$ssid"
}

# Set initial value
update_ssid

# Monitor NetworkManager events and update on changes
nmcli monitor | while read -r _; do
  update_ssid
done
