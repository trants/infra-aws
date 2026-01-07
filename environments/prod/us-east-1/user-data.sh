#!/bin/bash
set -euo pipefail

echo "[INFO] Starting EC2 user-data script..."

echo "[INFO] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "[INFO] Installing prerequisites..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip

echo "[INFO] Installing PHP CLI and extensions (required for Composer only)..."
apt-get install -y \
    php-cli \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip

echo "[INFO] Adding Docker's official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "[INFO] Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[INFO] Installing Docker Engine and Docker Compose..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[INFO] Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

echo "[INFO] Adding ubuntu user to docker group..."
usermod -aG docker ubuntu

echo "[INFO] Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

echo "[INFO] Verifying Composer installation..."
composer --version

echo "[INFO] Creating /var/www directory..."
mkdir -p /var/www
chown -R ubuntu:ubuntu /var/www

echo "[SUCCESS] EC2 instance ready: Docker and Composer installed. PHP CLI is only for running Composer, application runs in Docker."
