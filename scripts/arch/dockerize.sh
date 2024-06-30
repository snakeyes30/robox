#!/bin/bash


# Cleanup.
# TODO.

# Stop services to avoid tarring sockets.
# TODO.


# Setup the login message instructions.
if [[ ! "$PACKER_BUILD_NAME" =~ ^generic-.*$ ]]; then
  printf "Magma Daemon Development Environment\nTo download and compile magma, just execute the magma-build.sh script.\n\n" > /etc/motd
fi

# Add a profile directive to send docker logins to the home directory.
printf "if [ \"\$PS1\" ]; then\n  cd \$HOME\nfi\n" > /etc/profile.d/home.sh

# Setup the locale, and arrogantly assume everyone lives in the US.
localedef -c -i en_US -f UTF-8 en_US.UTF-8

rm -rf /var/cache/pacman/*
rm -rf /var/log/*
rm -rf /tmp/*

# Fix /run/lock breakage since it's not tmpfs in docker
umount /run
systemd-tmpfiles --create --boot

# Make sure login works
[ -f /var/run/nologin ] && rm /var/run/nologin

# Mark the docker box build time.
date --utc > /etc/docker_box_build_time

# Randomize the root password and then lock the root account.
LOCKPWD=`dd if=/dev/urandom count=128 status=none | md5sum | awk -F' ' '{print $1}'`
printf "$LOCKPWD\n$LOCKPWD\n" | passwd root
passwd --lock root

if [ -f /var/lib/dbus/machine-id ]; then
  truncate -s 0 /var/lib/dbus/machine-id
fi

if [ -f /etc/machine-id ]; then
  truncate -s 0 /etc/machine-id
fi

# tar --create --numeric-owner --one-file-system --directory=/ --file=/tmp/$PACKER_BUILD_NAME.tar \
# --exclude=/tmp/$PACKER_BUILD_NAME.tar --exclude=/boot --exclude=/run/* --exclude=/var/spool/postfix/private/* .

# Exclude the extraction files from the tarball.
printf "/tmp/excludes\n" > /tmp/excludes
printf "/tmp/$PACKER_BUILD_NAME.tar\n" >> /tmp/excludes

# Exclude all of the special files from the tarball.
find -L $(ls -1 -d /* | grep -Ev "sys|dev|proc") -type b -print 1>>/tmp/excludes 2>/dev/null
find -L $(ls -1 -d /* | grep -Ev "sys|dev|proc") -type c -print 1>>/tmp/excludes 2>/dev/null
find -L $(ls -1 -d /* | grep -Ev "sys|dev|proc") -type p -print 1>>/tmp/excludes 2>/dev/null
find -L $(ls -1 -d /* | grep -Ev "sys|dev|proc") -type s -print 1>>/tmp/excludes 2>/dev/null
find /var/log/ -type f -print 1>>/tmp/excludes 2>/dev/null
find /etc/sysconfig/network-scripts/ -name "ifcfg-*" -print 1>>/tmp/excludes 2>/dev/null
find /tmp -type f -or -type d -print | grep --invert-match --extended-regexp "^/tmp/$|^/tmp$" >> /tmp/excludes

# Remove the files associated with these packages since containers don't need them.
# PACKAGES=`pacman kernel kernel-devel kernel-headers kernel-tools kernel-tools-libs bind-libs bind-libs-lite dhclient dhcp-common dhcp-libs dracut-network e2fsprogs e2fsprogs-libs ebtables ethtool firewalld grub2 grub2-tools grubby initscripts iproute iptables kexec-tools libmnl libnetfilter_conntrack libnfnetlink libselinux-python python-slip python-slip-dbus snappy sysvinit-tools linux-firmware | grep --invert "not installed"`

# Manually exclude certain files/directories from the list.
# rpm -q --list $PACKAGES | grep --invert "/usr/share/bash-completion/completions" | \
#   grep --invert "/etc/profile.d" >> /tmp/excludes

# Remove the leading slash so the names match up with tar.
sed --in-place "s/^\///g" /tmp/excludes

# Tarball the filesystem.
tar --create --numeric-owner --preserve-permissions --one-file-system \
  --directory=/ --file=/tmp/$PACKER_BUILD_NAME.tar --exclude=/etc/firewalld \
  --exclude=/boot --exclude=/proc --exclude=/lost+found --exclude=/mnt --exclude=/sys \
  --exclude=/var/run/udev --exclude=/run/udev -X /tmp/excludes /

if [ $? != 0 ] || [ ! -f /tmp/$PACKER_BUILD_NAME.tar ]; then
  printf "\n\nTarball generation failed.\n\n"
  passwd --unlock root
  printf "locked\nlocked\n" | passwd root
  exit 1
else
  printf "\nTarball generation succeeded.\n"
fi

passwd --unlock root
printf "locked\nlocked\n" | passwd root
