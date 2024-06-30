 #!/bin/bash -x

retry() {
  local COUNT=1
  local DELAY=0
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
      echo -e "\n${*} failed... retrying ${COUNT} of 10.\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput setaf 1
    echo -e "\nThe command failed 10 times.\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && [ -n "$TERM" ] && tput sgr0
  }

  return "${RESULT}"
}

# Tell dnf to retry 128 times before failing, so unattended installs don't skip packages when errors occur.
printf "\nretries=128\ndeltarpm=0\nmetadata_expire=300\n" >> /etc/dnf/dnf.conf

# Disable the subscription manager plugin.
if [ -f /etc/yum/pluginconf.d/subscription-manager.conf ]; then
  sed --in-place "s/^enabled=.*/enabled=0/g" /etc/yum/pluginconf.d/subscription-manager.conf
fi

# And disable the subscription maangber via the alternate dnf config file.
if [ -f /etc/dnf/plugins/subscription-manager.conf ]; then
  sed --in-place "s/^enabled=.*/enabled=0/g" /etc/dnf/plugins/subscription-manager.conf
fi

# Alma Repo Setup
sed -i -e "s/^#[ ]\?baseurl/baseurl/g" /etc/yum.repos.d/almalinux-baseos.repo
sed -i -e "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/almalinux-baseos.repo

sed -i -e "s/^#[ ]\?baseurl/baseurl/g" /etc/yum.repos.d/almalinux-appstream.repo
sed -i -e "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/almalinux-appstream.repo

sed -i -e "s/^#[ ]\?baseurl/baseurl/g" /etc/yum.repos.d/almalinux-extras.repo
sed -i -e "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/almalinux-extras.repo

sed -i -e "s/^#[ ]\?baseurl/baseurl/g" /etc/yum.repos.d/almalinux-plus.repo
sed -i -e "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/almalinux-plus.repo

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9

# EPEL Repo Setup
retry dnf --quiet --assumeyes --enablerepo=extras install epel-release

sed --in-place 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/epel.repo
sed --in-place 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel.repo

if [ -f /etc/yum.repos.d/epel-playground.repo ]; then
  sed --in-place 's/metalink\=http:/metalink\=https:/g' /etc/yum.repos.d/epel-cisco-openh264.repo
  sed --in-place 's/\(metalink\=.*\)$/\1\&protocol\=https/g' /etc/yum.repos.d/epel-cisco-openh264.repo
fi

# Disable the testing repo.
if [ -f /etc/yum.repos.d/epel-testing.repo ]; then
  sed --in-place 's/metalink\=http:/metalink\=https:/g'  /etc/yum.repos.d/epel-testing.repo
  sed --in-place 's/\(metalink\=.*\)$/\1\&protocol\=https/g'  /etc/yum.repos.d/epel-testing.repo
  sed --in-place "s/^/# /g" /etc/yum.repos.d/epel-testing.repo
  sed --in-place "s/# #/##/g" /etc/yum.repos.d/epel-testing.repo
fi

# Disable the playground repo.
if [ -f /etc/yum.repos.d/epel-playground.repo ]; then
  sed --in-place 's/metalink\=http:/metalink\=https:/g'  /etc/yum.repos.d/epel-playground.repo
  sed --in-place 's/\(metalink\=.*\)$/\1\&protocol\=https/g'  /etc/yum.repos.d/epel-playground.repo
  sed --in-place "s/^/# /g" /etc/yum.repos.d/epel-playground.repo
  sed --in-place "s/# #/##/g" /etc/yum.repos.d/epel-playground.repo
fi

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9

# Update the base install first.
retry dnf --assumeyes update

# Install the basic packages we'd expect to find.
retry dnf --assumeyes install sudo dmidecode dnf-utils bash-completion man man-pages mlocate vim-enhanced bind-utils wget dos2unix unix2dos lsof tar telnet net-tools coreutils grep gawk sed curl patch sysstat make cmake libarchive autoconf automake libtool gcc-c++ libstdc++-devel gcc cpp ncurses-devel glibc-devel glibc-headers kernel-headers psmisc python39 rsync

