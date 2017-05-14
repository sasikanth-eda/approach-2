#!/usr/bin/bash

USER_PASSWORD="$1"
NODE_PREFIX="$2"
NODE_COUNT="$3"
NSD_COUNT="$4"
FILESYSTEM_NAME="$5"
CLUSTER_NAME="$6"

# Password-less ssh setup with all other nodes in the cluster
for (( node=1; node<$NODE_COUNT; node++ ))
do
    sshpass -p $USER_PASSWORD ssh-copy-id -i /root/.ssh/id_rsa.pub $NODE_PREFIX$node
done

# Populate host entries
for (( node=0; node<$NODE_COUNT; node++ ))
do
    ipaddr=`sshpass -p $USER_PASSWORD ssh $NODE_PREFIX$node hostname -I`
    printf "$ipaddr   $NODE_PREFIX$node\n" >> /etc/hosts
done

# Prepare nodelist
rm -fr /root/nodes.cfg

for (( node=0; node<$NODE_COUNT; node++ ))
do
    if [[ $NODE_COUNT -le 4 ]]
    then
       # If the number of nodes in the cluster definition is less than 4,
       # all nodes will be designated as quorum nodes.
       printf "$NODE_PREFIX$node:quorum\n" >> /root/nodes.cfg
    elif [[ $NODE_COUNT -ge 4 && $NODE_COUNT -le 9 ]]
    then
        # If the number of nodes in the cluster definition is between 4 and 9
        # inclusive, 3 nodes will be designated as quorum nodes.
        if [[ $node -lt 4 ]]
        then
            printf "$NODE_PREFIX$node:quorum\n" >> /root/nodes.cfg
        else
            printf "$NODE_PREFIX$node:\n" >> /root/nodes.cfg
        fi
    elif [[ $NODE_COUNT -ge 10 && $NODE_COUNT -le 18 ]]
    then
        # If the number of nodes in the cluster definition is between 10 and 18
        # inclusive, 5 nodes will be designated as quorum nodes.
        if [[ $node -lt 6 ]]
        then
            printf "$NODE_PREFIX$node:quorum\n" >> /root/nodes.cfg
        else
            printf "$NODE_PREFIX$node:\n" >> /root/nodes.cfg
        fi
    elif [[ $NODE_COUNT -ge 18 ]]
    then
        # If the number of nodes in the cluster definition is greater than 18,
        # 7 nodes will be designated as quorum nodes.
        if [[ $node -lt 8 ]]
        then
            printf "$NODE_PREFIX$node:quorum\n" >> /root/nodes.cfg
        else
            printf "$NODE_PREFIX$node:\n" >> /root/nodes.cfg
        fi
    fi
done

/usr/lpp/mmfs/bin/mmcrcluster -C $CLUSTER_NAME -N /root/nodes.cfg -p $NODE_PREFIX"0" -r /usr/bin/ssh -R /usr/bin/scp
/usr/lpp/mmfs/bin/mmchlicense server --accept -N all

# Prepare nsd definition
rm -rf /root/nsd.txt
for (( node=0; node<$NSD_COUNT; node++ ))
do
    echo "%nsd:    device=/dev/sdc     servers=$NODE_PREFIX$node    usage=dataAndMetadata" >> /root/nsd.txt
done
/usr/lpp/mmfs/bin/mmcrnsd -F /root/nsd.txt

/usr/lpp/mmfs/bin/mmstartup -a
sleep 240

# Create FILESYSTEM
/usr/lpp/mmfs/bin/mmcrfs /gpfs0 $FILESYSTEM_NAME -F /root/nsd.txt -A yes -B 512k;
/usr/lpp/mmfs/bin/mmmount all -a
