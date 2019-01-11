#!/usr/bin/env bash

# script for installing Docker in an EC2 instance

set -e

sudo yum update -y
sudo amazon-linux-extras install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo reboot
