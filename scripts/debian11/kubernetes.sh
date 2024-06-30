#!/bin/bash

retry() {
  local COUNT=1
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && tput setaf 1
      echo -e "\n${*} failed... retrying ${COUNT} of 10.\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && tput setaf 1
    echo -e "\nThe command failed 10 times.\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && tput sgr0
  }

  return "${RESULT}"
}


error() {
        if [ $? -ne 0 ]; then
                printf "\n\napt failed...\n\n";
                exit 1
        fi
}


retry apt-get --assume-yes install \
            apt-transport-https \
                ca-certificates \
                    curl \
                        gnupg-agent \
                            software-properties-common
 curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
 add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/debian \
               $(lsb_release -cs) \
                  stable"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo rm /etc/containerd/config.toml
retry apt-get --assume-yes update
#retry apt-get --assume-yes  install containerd.io=1.2.13-2   docker-ce=5:19.03.11~3-0~debian-buster  docker-ce-cli=5:19.03.11~3-0~debian-buster  kubelet kubeadm kubectl nfs-common dnsutils
retry apt-get --assume-yes  install containerd.io  nfs-common dnsutils
retry apt-get --assume-yes  install kubernetes-cni
retry apt-get --assume-yes  install kubelet
retry apt-get --assume-yes  install kubeadm
retry apt-get --assume-yes  install kubectl
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

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

echo "fs.inotify.max_user_instances=1048" >> /etc/sysctl.d/40-max-user-watches.conf
echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
# Apply sysctl params without reboot
sudo sysctl --system

sudo cp /home/vagrant/containerd_config.toml /etc/containerd/config.toml
sudo mkdir -p /etc/containerd
sudo systemctl restart containerd

cat <<EOF |
/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
{
	rotate 4
	weekly
	missingok
	notifempty
	compress
	delaycompress
	sharedscripts
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
EOF
cat /etc/resolv.conf
dig +short @8.8.8.8 k8s.gcr.io
sudo kubeadm config images pull -v=10
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
#sudo kubeadm config images pull -v=10 2>&1
sudo echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
sudo echo "$outchannel mysyslog,/var/log/syslog,1048576"  >> /etc/rsyslog.d/50-default.conf
sudo systemctl restart systemd-journald
sudo systemctl restart  rsyslog.service

