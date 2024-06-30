#!/bin/bash -ux

# Create the vagrant user account.
adduser -D -s /bin/bash vagrant

# Enable exit/failure on error.
# set -eux

printf "vagrant\nvagrant\n" | passwd vagrant
cat <<-EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !fqdn
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/vagrant

# Create the vagrant user ssh directory.
mkdir -pm 700 /home/vagrant/.ssh

# Create an authorized keys file and insert the insecure public vagrant key.
cat <<-EOF > /home/vagrant/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF

#cat /home/vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
sudo cp /home/vagrant/containerd_config.toml /etc/containerd/config.toml

# Ensure the permissions are set correct to avoid OpenSSH complaints.
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh


# Mark the vagrant box build time.
date --utc > /etc/vagrant_box_build_time

# Truncate the motd file.
truncate -s 0 /etc/motd

# Workaround issues with setting the hostname in older Vagrant releases.
if [ ! -f /etc/init.d/network ]; then ln -s /etc/init.d/networking /etc/init.d/network ; fi
if [ ! -d /etc/sysconfig/ ]; then mkdir -p /etc/sysconfig/ ; fi
cat <<-EOF > /etc/sysconfig/network
HOSTNAME="`hostname`"
EOF
