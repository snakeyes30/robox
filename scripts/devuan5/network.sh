#!/bin/bash -eux

# Set the hostname, and then ensure it will resolve properly.
if [[ "$PACKER_BUILD_NAME" =~ ^generic-devuan5-(vmware|hyperv|libvirt|parallels|virtualbox)-(x64|x32|a64|a32|p64|p32|m64|m32)$ ]]; then
  printf "devuan5.localdomain\n" > /etc/hostname
  printf "\n127.0.0.1 devuan5.localdomain\n\n" >> /etc/hosts
else
  printf "magma.localdomain\n" > /etc/hostname
  printf "\n127.0.0.1 magma.localdomain\n\n" >> /etc/hosts
fi

# The network interface and DHCP client are configured by the installer
# via the preseed config, to avoid IP address changes during a reboot.
( /sbin/shutdown -r +1 ) &
echo "Rebooting..."
exit 0
