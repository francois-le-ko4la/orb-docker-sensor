#!/bin/sh

CONFIG_PATH=/data/options.json
#MQTT_PAUSE=$(jq -r '.mqtt_frequency // 5' $CONFIG_PATH 2>/dev/null || echo 5)

# Read MQTT config from environment variables
MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASS="${MQTT_PASS:-}"
MQTT_PAUSE="${MQTT_PAUSE:-5}"

echo "Local MQTT configuration:"
echo "  Host: $MQTT_HOST"
echo "  Port: $MQTT_PORT"
echo "  User: $MQTT_USER"
echo "  Pass: *****"
echo "  Pause: $MQTT_PAUSE seconds"

if [ -z "$MQTT_HOST" ] || [ -z "$MQTT_PORT" ] || [ -z "$MQTT_USER" ] || [ -z "$MQTT_PASS" ]; then
  echo "Error: Missing MQTT configuration"
  exit 1
fi

DISCOVERY_TOPIC_PREFIX="homeassistant/sensor"
STATE_TOPIC="orb/status"

# Define the sensors to publish
mapping="
Score|orb_score.display|%
Bandwidth Score|orb_score.components.bandwidth_score.display|%
Bandwidth Upload|orb_score.components.bandwidth_score.components.upload_bandwidth_kbps.value|kbps
Bandwidth Download|orb_score.components.bandwidth_score.components.download_bandwidth_kbps.value|kbps
Reliability Score|orb_score.components.reliability_score.display|%
Lag|orb_score.components.responsiveness_score.components.internet_lag_us.value|us
High Packet Loss Proportion|orb_score.components.reliability_score.components.internet_loss_status.value * 100|%
Responsiveness Score|orb_score.components.responsiveness_score.display|%
"

# Publish Home Assistant MQTT Discovery once
echo "$mapping" | while IFS='|' read name field unit; do
  [ -z "$name" ] && continue
  unique_id=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')
  DISCOVERY_TOPIC="${DISCOVERY_TOPIC_PREFIX}/orb_${unique_id}/config"

  payload=$(cat <<EOF
{
  "name": "${name}",
  "state_topic": "${STATE_TOPIC}",
  "unit_of_measurement": "${unit}",
  "value_template": "{{ (value_json.${field}) | round(0) }}",
  "unique_id": "orb_${unique_id}",
  "device": {
    "identifiers": ["orb"],
    "name": "Orb Sensor",
    "manufacturer": "Orb Forge",
    "model": "Orb Agent"
  }
}
EOF
)

  mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "$DISCOVERY_TOPIC" -m "$payload" -r
done

# Periodic state updates
while true; do
  ORB_OUTPUT="$(/app/orb summary || echo '{}')"
  mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "$STATE_TOPIC" -m "$ORB_OUTPUT" -r
  sleep "$MQTT_PAUSE"
done

