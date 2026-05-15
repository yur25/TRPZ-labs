#!/bin/bash
set -e

echo "Deploying to Target Server: $TARGET_USER@$TARGET_IP"

# Copy systemd service file to target VM
scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no systemd/mywebapp-docker.service "$TARGET_USER@$TARGET_IP":/tmp/mywebapp-docker.service

# shellcheck disable=SC2087
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" << EOF
  # Install systemd service
  sudo cp /tmp/mywebapp-docker.service /etc/systemd/system/mywebapp-docker.service
  sudo systemctl daemon-reload
  sudo systemctl enable mywebapp-docker.service

  # Authenticate Docker on target VM with GHCR
  echo "$GHCR_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
  
  # Pull latest stable release
  docker pull $IMAGE
  
  # Restart systemd to apply container updates
  sudo systemctl restart mywebapp-docker.service
EOF

echo "Wait 10s for the container to initialize..."
sleep 10

echo "Running post-deploy health check..."
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://"$TARGET_IP"/health)

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Deployment verified successfully! HTTP Status: $HTTP_STATUS"
else
  echo "❌ Verification failed! HTTP Status: $HTTP_STATUS"
  exit 1
fi
