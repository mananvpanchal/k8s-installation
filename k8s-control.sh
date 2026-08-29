#!/bin/bash
set -e

echo "Configuring firewall..."

firewall-cmd --permanent \
    --add-port=6443/tcp \
    --add-port=2379-2380/tcp \
    --add-port=10250/tcp \
    --add-port=10257/tcp \
    --add-port=10259/tcp \
    --add-port=8472/udp
firewall-cmd --permanent \
    --add-source=10.244.0.0/16 \
    --add-source=10.96.0.0/12
firewall-cmd --permanent \
    --add-masquerade

firewall-cmd --reload

echo "Initializing cluster..."

kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --service-cidr=10.96.0.0/12
    
echo
echo "======================================="
echo "Control plane node configured."
echo "======================================="
