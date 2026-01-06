#!/bin/bash
set -euo pipefail

echo "[INFO] Starting EC2 user-data script..."

echo "[INFO] Updating system packages..."
dnf update -y

echo "[INFO] Installing Docker and Git..."
dnf install -y docker git

echo "[INFO] Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

echo "[INFO] Installing Docker Compose plugin..."
dnf install -y docker-compose-plugin

echo "[INFO] Adding ec2-user to docker group..."
usermod -aG docker ec2-user

echo "[INFO] Creating /var/www directory..."
mkdir -p /var/www
chown -R ec2-user:ec2-user /var/www

echo "[SUCCESS] EC2 instance ready: Docker installed and configured."
