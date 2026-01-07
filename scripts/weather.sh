#!/usr/bin/env bash

# Obviously let's start ironbar first and then add this line:
# exec-once = ~/.local/bin/weather.sh

LOCATION="Prague"
UPDATE_INTERVAL=600  # 10 minutes

# Wait until ironbar is ready
until ironbar var set weather "" 2>/dev/null; do
  sleep 0.5
done

update_weather() {
  local temp_c
  temp_c=$(curl -s "wttr.in/${LOCATION}?format=j1" | jq -r '.current_condition[0].temp_C')

  if [[ -z "$temp_c" || "$temp_c" == "null" ]]; then
    temp_c="N/A"
  else
    temp_c="${temp_c}°C"
  fi

  ironbar var set weather -- "$temp_c"
}

# Set initial value
update_weather

# Update periodically
while true; do
  sleep "$UPDATE_INTERVAL"
  update_weather
done
