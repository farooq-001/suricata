#!/bin/bash

# Prompt for SPAN_PORT
read -p "Enter SPAN_PORT: " SPAN_PORT

# Echo the entered SPAN_PORT value
echo "SPAN_PORT is set to: $SPAN_PORT"

# Create necessary directories
mkdir -p /root/docker/suricata

# Create the docker-compose.yml file
cat <<EOF > /root/docker/suricata/docker-compose.yml
version: '3.8'

services:
  suricata:
    image: dtagdevsec/suricata:24.04.1
    container_name: suricata
    volumes:
      - /opt/sensor/conf/etc/capture/blusapphire.yaml:/opt/sensor/conf/etc/capture/blusapphire.yaml
      - /var/log/capture:/var/log/capture
      - /opt/sensor/conf/etc/capture/rules:/opt/sensor/conf/etc/capture/rules
    network_mode: host
    privileged: true
    command: ["suricata", "-i", "$SPAN_PORT", "-c", "/opt/sensor/conf/etc/capture/blusapphire.yaml"]
    restart: unless-stopped
EOF

echo "Docker Compose file created at /root/docker/suricata/docker-compose.yml"
