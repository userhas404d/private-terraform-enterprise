#!/bin/bash

# update yum
sudo yum -update

## install required packages
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

## set target docker repository to stable
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# install the latest version of docker
yum -y install docker-ce-17.06.2.ce

# start docker
systemctl start docker

# ensure docker starts on reboot
systemctl enable docker

# create docker group and add DOCKER_USER
sudo usermod -aG docker maintuser

# add required ports to firewall
# selinux causes firewalld updates to hang during cfn-init
firewall-offline-cmd --direct --add-rule ipv4 filter INPUT_direct 50 -p tcp -m tcp --dport 443 -j ACCEPT
firewall-cmd --restart
