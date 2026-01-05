#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git

systemctl enable docker
systemctl start docker

# Docker Compose plugin
dnf install -y docker-compose-plugin

# Add ec2-user to docker group
usermod -aG docker ec2-user

# (Tuỳ) Tạo thư mục deploy
mkdir -p /var/www
chown -R ec2-user:ec2-user /var/www

# NOTE:
# Ở bước này bạn có thể:
# - git clone repo chứa docker-compose.yml
# - hoặc copy compose từ CI/CD
# Ví dụ placeholder:
# su - ec2-user -c "cd /opt/apps && git clone <YOUR_REPO_URL> app"

# Placeholder: không tự chạy compose để tránh fail nếu chưa có file.
echo "EC2 ready: Docker installed."
