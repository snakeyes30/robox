text
reboot --eject
lang en_US.UTF-8
keyboard us
timezone US/Pacific
rootpw --plaintext locked

zerombr
clearpart --all --initlabel
autopart --type=lvm --nohome

firewall --enabled --service=ssh
network --device eth0 --bootproto dhcp --noipv6 --hostname=rhel9.localdomain
bootloader --timeout=1 --append="net.ifnames=0 biosdevname=0 no_timer_check vga=792 nomodeset text"

%addon com_redhat_kdump --disable --reserve-mb=128
%end

%packages
@core
authconfig
sudo
-fprintd-pam
-intltool
-iwl*-firmware
-microcode_ctl
%end

%post

# Duplicate the install media so the DVD can be ejected.
mount /dev/cdrom /mnt/ || mount /dev/disk/by-label/RHEL-*-BaseOS-* /mnt/ || exit 1
cp --recursive /mnt/BaseOS/ /media/ && cp --recursive /mnt/AppStream/ /media/ || exit 1

sed -i -e "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i -e "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config

cat <<-EOF > /etc/udev/rules.d/60-scheduler.rules
# Set the default scheduler for various device types and avoid the buggy bfq scheduler.
ACTION=="add|change", KERNEL=="sd[a-z]|sg[a-z]|vd[a-z]|hd[a-z]|xvd[a-z]|dm-*|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/scheduler}="mq-deadline"
EOF

umount /mnt/

%end
