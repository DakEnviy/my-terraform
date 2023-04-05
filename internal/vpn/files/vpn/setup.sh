#!/usr/bin/env bash

set -euxo pipefail

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.conf
sudo sysctl -p

# Firewall configuration
sudo ufw allow OpenSSH
sudo ufw allow 1194/udp
sudo ufw disable
sudo ufw enable

# Enable and start OpenVPN service
sudo systemctl enable --now openvpn-server@server.service

