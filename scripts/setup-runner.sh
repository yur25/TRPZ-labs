#!/bin/bash
# Run this on the Self-Hosted Runner Ubuntu 24.04 VM

sudo apt-get update
sudo apt-get install -y curl tar nodejs

RUNNER_USER="github-runner"
sudo useradd -m -s /bin/bash $RUNNER_USER
sudo -u $RUNNER_USER mkdir -p /home/$RUNNER_USER/actions-runner

RUNNER_VERSION="2.316.1"
cd /home/$RUNNER_USER/actions-runner
sudo -u $RUNNER_USER curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
sudo -u $RUNNER_USER tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "Run this manually as github-runner: ./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN"
echo "Then install it as a service: sudo ./svc.sh install && sudo ./svc.sh start"
