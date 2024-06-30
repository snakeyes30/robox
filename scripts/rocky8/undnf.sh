#!/bin/bash

grep --quiet mirrorlist /etc/yum.repos.d/epel.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/epel.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/epel.repo

grep --quiet mirrorlist /etc/yum.repos.d/Rocky-BaseOS.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/Rocky-BaseOS.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/Rocky-BaseOS.repo

grep --quiet mirrorlist /etc/yum.repos.d/Rocky-AppStream.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/Rocky-AppStream.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/Rocky-AppStream.repo

grep --quiet mirrorlist /etc/yum.repos.d/Rocky-PowerTools.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/Rocky-PowerTools.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/Rocky-PowerTools.repo

grep --quiet mirrorlist /etc/yum.repos.d/Rocky-Extras.repo  && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/Rocky-Extras.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/Rocky-Extras.repo

grep --quiet mirrorlist /etc/yum.repos.d/Rocky-Plus.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/Rocky-Plus.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/Rocky-Plus.repo

exit 0

