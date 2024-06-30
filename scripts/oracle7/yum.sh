#!/bin/bash -eux

# Tell yum to retry 128 times before failing, so unattended installs don't skip packages when errors occur.
printf "\nretries=128\ndeltarpm=0\nmetadata_expire=0\nmirrorlist_expire=0\n" >> /etc/yum.conf

# Setup the GPG key.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle

# Update the base install first.
yum --assumeyes update

# The basic utilities we'd expect to find.
yum --assumeyes install deltarpm net-tools yum-utils bash-completion man-pages vim-enhanced mlocate sysstat bind-utils jwhois wget dos2unix unix2dos lsof telnet net-tools coreutils grep gawk sed curl psmisc rsync

# Update the locate database.
[ -f /etc/cron.daily/mlocate.cron ] && /etc/cron.daily/mlocate.cron
[ -f /etc/cron.daily/mlocate ] && /etc/cron.daily/mlocate

# Schedule a reboot, but give the computer time to cleanly shutdown the
# network interface first.
( shutdown --reboot --no-wall +1 ) &
exit 0

