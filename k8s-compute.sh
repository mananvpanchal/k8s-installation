#!/bin/bash

set -e

firewall-cmd --permanent \
    --add-port=10250/tcp \
    --add-port=30000-32767/tcp \
    --add-port=8472/udp
firewall-cmd --permanent \
    --add-source=10.244.0.0/16 \
    --add-source=10.96.0.0/12
firewall-cmd --permanent \
    --add-masquerade

firewall-cmd --reload

echo
echo "======================================="
echo "Compute plane node firewall configured."
echo "======================================="
