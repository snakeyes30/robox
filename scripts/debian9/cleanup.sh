#!/bin/bash

error() {
  if [ $? -ne 0 ]; then
    printf "\n\napt failed...\n\n";
    exit 1
  fi
}

# To allow for automated installs, we disable interactive configuration steps.
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Keep the daily apt updater from deadlocking our cleanup operations.
systemctl --quiet is-active apt-daily.timer && systemctl stop apt-daily.timer
systemctl --quiet is-active apt-daily.service && systemctl stop apt-daily.service
systemctl --quiet is-active apt-daily-upgrade.timer && systemctl apt-daily-upgrade.timer
systemctl --quiet is-active apt-daily-upgrade.service && systemctl apt-daily-upgrade.service

# Cleanup unused packages.
apt-get -y purge installation-report &>/dev/null || true
apt-get --assume-yes autoremove; error
apt-get --assume-yes autoclean; error
apt-get --assume-yes purge; error

# Restore the system default apt retry value.
[ -f /etc/apt/apt.conf.d/20retries ] && rm --force /etc/apt/apt.conf.d/20retries

# Remove the random seed so a unique value is used the first time the box is booted.
systemctl --quiet is-active systemd-random-seed.service && systemctl stop systemd-random-seed.service
[ -f /var/lib/systemd/random-seed ] && rm --force /var/lib/systemd/random-seed
