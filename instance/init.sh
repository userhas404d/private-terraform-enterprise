#!/bin/bash

# add MidServer Pulbic key

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCOKe6oesuIF0nUCYZ+PAVm6L/Pes0Tapr++zksPFUMJm+pqtmYElO3wF46brND4lHGIHJp7mmgVESam7U7VHYT/UfTGBYr4LHU+ylEFjNuwr9RspE5wOK0fQ0eyUMJE5jU/LLzP+A+34dYMHDWm4R7vtRRZqb9krHO5UqXsibK0wHH3qCBq/szx8ilkNNyiQMIzr8xwDOr6lPNQM9VT5V9ZlXF2KQPqb8r4fFWllZZ1mYQhTeCJAN1CMK2Yu5WDC+eilO8zCoGG/TkmVwLFMLBPJTxzelA+le2JkhWpukiJRnxJwpdIcfeFYIkt8zAZDSOSrxKs2WG/D36N54fg33n linux-mid-server" >> ~/.ssh/authorized_keys

# update yum
yum -update

## install required packages
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

## set target docker repository to stable
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# install the latest version of docker
# yum -y install docker-ce-17.06.2.ce
yum -y install docker-ce

# ensure docker starts on reboot
systemctl enable docker

# create docker group and add DOCKER_USER
usermod -aG docker maintuser

# add required ports to firewall
# selinux causes firewalld updates to hang during cfn-init
firewall-offline-cmd --zone=public --add-port=9870-9890/tcp
firewall-offline-cmd --zone=public --add-port=443/tcp
firewall-offline-cmd --zone=public --add-port=80/tcp
firewall-offline-cmd --zone=public --add-port=8800/tcp

systemctl restart firewalld

# https://docs.docker.com/storage/storagedriver/device-mapper-driver/#manage-devicemapper

pvcreate /dev/xvdg
vgcreate docker /dev/xvdg
lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
lvconvert -y \
--zero n \
-c 512K \
--thinpool docker/thinpool \
--poolmetadata docker/thinpoolmeta

touch /etc/lvm/profile/docker-thinpool.profile
echo "activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}" > /etc/lvm/profile/docker-thinpool.profile

lvchange --metadataprofile docker-thinpool docker/thinpool
lvs -o+seg_monitor

mkdir -p /etc/docker/
touch  /etc/docker/daemon.json
echo "{
    \"storage-driver\": \"devicemapper\",
    \"storage-opts\": [
    \"dm.thinpooldev=/dev/mapper/docker-thinpool\",
    \"dm.use_deferred_removal=true\",
    \"dm.use_deferred_deletion=true\"
    ]
}" > /etc/docker/daemon.json

systemctl start docker
service docker start

# https://github.com/moby/moby/issues/16137
nmcli connection modify docker0 connection.zone trusted
systemctl stop NetworkManager.service
firewall-offline-cmd --zone=trusted --change-interface=docker0
systemctl start NetworkManager.service
nmcli connection modify docker0 connection.zone trusted
systemctl restart docker.servicer

# download the tfe license file
aws s3 cp s3://tfe-startup-scripts/plus3-it.rli tmp/license.rli

# create replicated unattended installer config
cat > /etc/replicated.conf <<EOF
{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "ptfe-pwd",
  "TlsBootstrapType": "self-signed",
  "LogLevel": "info",
  "ImportSettingsFrom": "/tmp/replicated-settings.json",
  "LicenseFileLocation": "/tmp/license.rli"
  "BypassPreflightChecks": true
}
EOF
cat > /tmp/replicated-settings.json <<EOF
{
  "hostname": {
    "value": ""
  }
  "installation_type": {
    "value": "production"
  },
  "production_type": {
    "value": "disk"
  },
  "disk_path": {
    "value": "/data"
  },
  "letsencrypt_auto": {
    "value": "1"
  },
  "letsencrypt_email": {
    "value": "null@null.com"
  },
}
EOF

curl https://install.terraform.io/ptfe/stable > tmp/tfe-install.sh
chmod +x tmp/tfe-install.sh && ./tmp/tfe-install.sh no-proxy
