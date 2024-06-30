#!/bin/sh -eux

retry() {
  local COUNT=1
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && [ ! -z "$TERM" ] && tput setaf 1
      echo -e "\\n${*} failed... retrying ${COUNT} of 10.\\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && [ ! -z "$TERM" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && [ ! -z "$TERM" ] && tput setaf 1
    echo -e "\\nThe command failed 10 times.\\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && [ ! -z "$TERM" ] && tput sgr0
  }

  return "${RESULT}"
}

getBin() {
BINNAME=$1
if [[ -z "${KUBERNETES_VERSION}" ]]; then
  KUBERNETES_VERSION=$(curl -s -k -L https://storage.googleapis.com/kubernetes-release/release/stable.txt)
fi

  curl -L -k https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/${BINNAME} >${BINNAME}
  chmod a+x ${BINNAME}
  cp ${BINNAME} /usr/local/bin/
}

retry apk add
            apt-transport-https \
                ca-certificates \
                    curl \
                        gnupg-agent \
                            software-properties-common

getBin kubeadm
getBin kubectl
getBin kubelet
 echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories

retry apk add cni-plugins containerd nfs-utils bind-tools cri-tools@testing

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo rc-update add containerd
sudo service containerd  start
# Apply sysctl params without reboot
sudo sysctl -p

sudo mkdir -p /etc/containerd
#sudo systemctl restart containerd


cat /etc/resolv.conf
dig +short @8.8.8.8 k8s.gcr.io
#sudo kubeadm config images pull -v=10
