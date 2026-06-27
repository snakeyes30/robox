#!/bin/bash

set -euo pipefail

# Retry helper
retry() {
  local COUNT=1
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    "${@}" && break
    RESULT=$?
    echo "Command failed... retrying ${COUNT}/10." >&2
    COUNT=$((COUNT + 1))
    sleep $((COUNT * 2))
  done
  return "${RESULT}"
}

# ---------------------------------------
# 1. Base packages
# ---------------------------------------
retry apt-get update
retry apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common lsb-release

# ---------------------------------------
# 2. Docker repo (for containerd.io)
# ---------------------------------------
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list

# ---------------------------------------
# 3. Kubernetes repo
# ---------------------------------------
KUBE_VERSION=1.32
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBE_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBE_VERSION/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

retry apt-get update

# ---------------------------------------
# 4. Install core components
# ---------------------------------------
retry apt-get install -y containerd.io nfs-common dnsutils
retry apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ---------------------------------------
# 5. Configure containerd (clean and modern)
# ---------------------------------------
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i '/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc\]/,/\[.*\]/ s/runtime_type =.*/runtime_type = "io.containerd.runc.v2"/' /etc/containerd/config.toml

# ---------------------------------------
# 6. Load required kernel modules
# ---------------------------------------
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# ---------------------------------------
# 7. Configure sysctl for Kubernetes
# ---------------------------------------
tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
echo "fs.inotify.max_user_instances=1048" >> /etc/sysctl.d/40-max-user-watches.conf
sysctl --system

# ---------------------------------------
# 8. Restart containerd
# ---------------------------------------
systemctl restart containerd

# ---------------------------------------
# 9. Ensure iptables uses legacy
# ---------------------------------------
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# ---------------------------------------
# 10. Optional log rate limiting
# ---------------------------------------
echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

# ---------------------------------------
# 11. Optional test of image pull & DNS
# ---------------------------------------
dig +short @1.1.1.1 k8s.gcr.io || true
kubeadm config images pull -v=10 || true

