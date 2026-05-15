#!/bin/bash
set -e

echo "Deploying to Target Server: $TARGET_USER@$TARGET_IP"

# shellcheck disable=SC2087
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" << EOF
  # Authenticate Docker on target VM with GHCR
  echo "$GHCR_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
  
  # Pull specific image release
  docker pull $IMAGE
  
  # Register image tag internally via systemd EnvironmentFile
  sudo mkdir -p /etc/default
  echo "IMAGE=$IMAGE" | sudo tee /etc/default/mywebapp
  
  # Restart systemd to apply container updates
  sudo systemctl restart mywebapp-docker.service
EOF

echo "Wait 10s for the container to initialize..."
sleep 10

echo "Running post-deploy health check..."
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://"$TARGET_IP":8080/health/alive || echo "Failed")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "вњ… Deployment verified successfully! HTTP Status: $HTTP_STATUS"
else
  echo "вќЊ Verification failed! HTTP Status: $HTTP_STATUS"
  echo "Fetching Docker logs to diagnose the issue..."
  ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "sudo docker logs mywebapp || docker logs mywebapp"
  exit 1
fi
