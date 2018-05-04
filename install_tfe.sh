#!/bin/bash
# -----------------------------------------------------------------------------
# DESCRIPTION
# The Terraform Enterprise Install script installs and configures ServiceNow on
# the ec2 instances.
#
# filename - install_tfe.sh
#
# README
# Stored in S3, it is called via the cloudformation template and run locally
# on the instance
#
# CHANGELOG
# Version 1.0 - TCM - 20180504
#
# -----------------------------------------------------------------------------
__SCRIPTNAME="install-servicenow.sh"

set -eu
set -x

#TFE_MOUNT="/opt/data"
DOCKER_USER="maintuser"

PATH="/sbin:/bin:/usr/sbin:/usr/bin"

log()
{
    # Logs messages to logger and stdout
    # Reads log messages from $1 or stdin
    if [[ "${1-UNDEF}" != "UNDEF" ]]
    then
        # Log message is $1
        logger -i -t "${__SCRIPTNAME}" -s -- "$1" 2> /dev/console
        echo "${__SCRIPTNAME}: $1"
    else
        # Log message is stdin
        while IFS= read -r IN
        do
            log "$IN"
        done
    fi
}  # ----------  end of function log  ----------

die()
{
    [ -n "$1" ] && log "$1"
    log "${__SCRIPTNAME} failed"'!'
    exit 1
}  # ----------  end of function die  ----------

log "${__SCRIPTNAME} starting!"

# setup the docker repository

## install required packages
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2 || \
  die "Failed to install the requied docker packges! Exit code was $?"
log "requied pacakges for docker installed successfull."

## set target docker repository to stable
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo || \
    die "Failed to add docker repository! Exit code was $?"
log "Docker reposiory configured successfully"

# install the latest version of docker
yum -y install docker-ce || \
    die "Failed to docker! Exit code was $?"
log "Completed installing docker"

# start docker
systemctl start docker || \
   die "Failed to start docker! Exit code was $?"
log "Docker started successfully"

# ensure docker starts on reboot
systemctl enable docker || \
   die "Failed to set docker to auto-start! Exit code was $?"
log "Docker set to auto-start successfully"

# create docker group and add DOCKER_USER
sudo usermod -aG docker ${DOCKER_USER} || \
  die "Failed to add maintuser to docker group! Exit code was $?"
log "maintuser added to docker group successfully"

# add required ports to firewall
ports=(80 443)
for i in "${ports[@]}"
do
  :
  #selinux causes firewalld updates to hang during cfn-init
  firewall-offline-cmd --direct --add-rule ipv4 filter INPUT_direct 50 -p tcp -m tcp --dport $i -j ACCEPT && \
  log "Added firewalld rule to enable TCP $i inbound. Requires firewalld reload to take affect." || \
    die "Failed to create firewalld rule for port: $i! Exit code was $?"
done
firewall-cmd --restart | log && \
log "Reloaded firewalld. ServiceNow specific rule is in affect." || \
  die "Failed to restart firewalld! Exit code was $?"
log "Configured firewalld to enable required inbound TCP connections"

#tfe install
#autostart
