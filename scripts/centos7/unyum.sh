#!/bin/bash

grep --quiet mirrorlist /etc/yum.repos.d/CentOS-Base.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/CentOS-Base.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i -e "s/https:\/\/mirrors.edge.kernel.org\/centos\//http:\/\/mirror.centos.org\/centos\//g" /etc/yum.repos.d/CentOS-Base.repo

grep --quiet mirrorlist /etc/yum.repos.d/epel.repo && \
sed -i -e "s/^baseurl/#baseurl/g" /etc/yum.repos.d/epel.repo && \
sed -i -e "s/^#mirrorlist/mirrorlist/g" /etc/yum.repos.d/epel.repo
sed -i -e "s/https:\/\/mirrors.edge.kernel.org\/fedora-epel\//http:\/\/download.fedoraproject.org\/pub\/epel\//g" /etc/yum.repos.d/epel.repo 
