#!/bin/bash
set -e

echo "Deploying to Target Server: $TARGET_USER@$TARGET_IP"

ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" << EOF
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
HTTP_STATUS=\$(curl -o /dev/null -s -w "%{http_code}\n" http://\$TARGET_IP:8080/health)

if [ "\$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Deployment verified successfully! HTTP Status: \$HTTP_STATUS"
else
  echo "❌ Verification failed! HTTP Status: \$HTTP_STATUS"
  exit 1
fi
