#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git

systemctl enable docker
systemctl start docker

dnf install -y docker-compose-plugin

usermod -aG docker ec2-user

mkdir -p /var/www
chown -R ec2-user:ec2-user /var/www

echo "EC2 ready: Docker installed."
