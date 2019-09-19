#!/usr/bin/env bash

# script for installing Docker in an EC2 instance

set -e

sudo yum update -y
sudo amazon-linux-extras install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo mkdir -p /data
sudo chmod 777 /data
sudo chown ec2-user /data

echo "*   hard  nofile  65535" | sudo tee --append /etc/security/limits.conf
echo "*   soft  nofile  65535" | sudo tee --append /etc/security/limits.conf

sudo reboot
