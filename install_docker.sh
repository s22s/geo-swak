#!/usr/bin/env bash

sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

device0="/dev/nvme1n1"
mntpnt0="/data"
if [ -b "$device0" ]
then
    sudo mkdir ${mntpnt0}
    sudo chown -R ec2-user:ec2-user ${mntpnt0}
    sudo mkfs -t ext4 ${device0}
    sudo cp /etc/fstab /etc/fstab.orig
    echo "${device0} ${mntpnt0} ext4 relatime,noexec 0 2" | sudo tee -a /etc/fstab
    sudo mount -a
    sudo chmod 777 ${mntpnt0}
else
    echo "${device0} does not exist"
fi

sudo reboot
