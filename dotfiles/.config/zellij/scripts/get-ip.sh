#!/bin/bash
# VPN (tun0) IP for the zellij zjstatus bar; falls back to eth0 when no tunnel.
ip=$(ip -4 -o addr show tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
[ -z "$ip" ] && ip=$(ip -4 -o addr show eth0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
echo "${ip:-down}"
