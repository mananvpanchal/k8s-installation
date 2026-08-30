#!/bin/bash

set -e

echo "Updating system..."
dnf update -y

echo "Disabling swap..."
touch /etc/systemd/zram-generator.conf
swapoff -a

echo "Installing iproute-tc..."
dnf install -y containernetworking-plugins iproute-tc

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

echo "Configuring SELinux..."
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo mkdir -p /etc/crio/crio.conf.d

cat <<'EOF' | sudo tee /etc/crio/crio.conf.d/20-cni.conf
[crio.network]
plugin_dirs = [
    "/usr/libexec/cni/",
    "/opt/cni/bin/"
]
EOF

cat <<'EOF' | sudo tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.35/rpm/repodata/repomd.xml.key
EOF

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "Installing cri-o and kubernetes..."
dnf install -y cri-o
dnf install -y kubelet kubeadm kubectl --setopt=disable_excludes=kubernetes

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

CONNECTION=$(nmcli -g GENERAL.CONNECTION device show enp0s3)

nmcli connection modify "$CONNECTION" \
    ipv4.method manual \
    ipv4.addresses ${IP}/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns 192.168.1.1 \
    ipv4.ignore-auto-dns yes

nmcli connection up "$CONNECTION"

echo
echo "======================================="
echo "Network configured."
echo "======================================="
echo "Restarting... in 1 min. Reconnect with IP: ${IP}, once up"
sudo shutdown -r
