#!/bin/bash
# Target VM Setup Script (Self-Hosted Runner Target Environment)
set -e

echo "Updating system and installing foundational dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg ufw

echo "Installing Docker Engine..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker Repository natively for Ubuntu
# shellcheck source=/dev/null
. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $VERSION_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Applying Systemd Deployment Hooks..."
# Pre-initialize environment file to prevent systemd crash on the very first run
sudo mkdir -p /etc/default
if [ ! -f /etc/default/mywebapp ]; then
    echo "IMAGE=ghcr.io/yur25/trpz-labs/mywebapp:stable" | sudo tee /etc/default/mywebapp
fi

echo "Installing and Configuring Reverse Proxy (Nginx)..."
sudo apt-get install -y nginx
cat << 'EOF' | sudo tee /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
sudo systemctl restart nginx

echo "Configuring Firewall Settings..."
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
echo "y" | sudo ufw enable

echo "вњ… Target VM provisioning successfully completed!"