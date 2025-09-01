# ha-orb-sensor

## Overview

This project is a fork of the original, which was designed for supervised Home Assistant environments where add-ons can be installed and managed directly through the Home Assistant interface.

This fork adapts the project to run in standard Home Assistant Docker environments, which do not include the supervised add-on management system.

This container runs an [Orb](https://www.orb.net) sensor in your Home Assistant environment. Doing so allows you to monitor the network responsiveness and reliability of your Home Assistant instance from your mobile device or computer from anywhere in the world. You may choose to receive a push notification on your Android or iOS device any time your Home Assistant instance cannot reach the network or experiences deterioriated connectivity.

## Installation

1. git clone
2. build
3. use

## Configuration

```yaml
  orb-sensor:
    image: docker.io/library/ha-orb-sensor:local
    container_name: orb-sensor
    network_mode: host
    environment:
    - MQTT_HOST=XXX.XXX.XXX.XXX
    - MQTT_PORT=1883
    - MQTT_USER=orb
    - MQTT_PASS=XXXXXXXXXX
    volumes:
      - "${DOCKER_ROOT}/orb-sensor/config:/root/.config/orb"
    restart: always
```

## Data Storage

The container stores its data in `/data/.config/orb` which is the default persistent storage provided by Home Assistant

## Architecture Support

This build supports multiple architectures (aarch64, amd64, armv7).

## MQTT Integration

It will expose the following entities under the Orb Sensor device:

- Orb Score (overall)
- Bandwidth Score
- Reliability Score
- Responsiveness Score
- Bandwidth Upload
- Bandwidth Download
- Lag
- Packet Loss
