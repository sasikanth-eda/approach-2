#!/usr/bin/bash

USER_PASSWORD="$1"

yum install -y epel-release sshpass

mkdir -p /root/.ssh
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' -q -P ""

echo 'Host *' >> /root/.ssh/config
echo 'StrictHostKeyChecking no' >> /root/.ssh/config

# Enable root login
echo $USER_PASSWORD | passwd --stdin root
hostname=`hostname`
# Enable password less ssh login within the node
sshpass -p $USER_PASSWORD ssh-copy-id -i /root/.ssh/id_rsa.pub $hostname
