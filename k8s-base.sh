#!/bin/bash

set -e

echo "Updating system..."
dnf update -y

# disabling swap
touch /etc/systemd/zram-generator.conf

echo "Installing dependencies..."
dnf install -y iptables iproute-tc
    
echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "Configuring sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "Installing kubernetes..."
dnf install -y kubernetes1.34 kubernetes1.34-client kubernetes1.34-kubeadm kubernetes1.34-systemd
    
echo "Configuring SELinux..."
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "Starting services..."

systemctl enable crio
systemctl enable kubelet

systemctl start crio

echo
echo "======================================="
echo "Base installation complate"
echo "======================================="


# ================= Network ====================
HOSTNAME=$1
IP=$2

hostnamectl set-hostname "$HOSTNAME"

nmcli connection modify enp0s3 \
    ipv4.method manual \
    ipv4.addresses ${IP}/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns 192.168.1.1 \
    ipv4.ignore-auto-dns yes

nmcli connection up enp0s3

echo
echo "======================================="
echo "Network configured."
echo "======================================="
