#!/bin/sh
sudo apt-get install nfs-kernel-server
sudo bash -c "echo \
'$R4L_EXP/driver     127.0.0.1(insecure,rw,sync,no_root_squash)' \
    >> /etc/exports"
sudo /etc/init.d/rpcbind restart
sudo /etc/init.d/nfs-kernel-server restart