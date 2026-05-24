# Lab 4 - Infrastructure as Code

This repository contains the Terraform and Ansible configuration for deploying the `mywebapp` Node.js application onto two Virtual Machines.

## Architecture

* **Worker VM**: Runs the Node.js application (`mywebapp`) and Nginx as a reverse proxy. Nginx listens on port 80.
* **DB VM**: Runs the MariaDB database. Configured to only accept connections from the Worker VM.

## Deployment Instructions

### Prerequisites
* KVM/QEMU and libvirt installed and configured.
* Terraform installed.
* Ansible installed.
* Ensure you have public SSH key configured at `~/.ssh/id_rsa.pub` (this is automatically injected via cloud-init to the `ansible` user).

### 1. Provisioning (Terraform)

Navigate to the `Lab4/terraform/` directory:

```bash
cd Lab4/terraform/
```

Initialize terraform and apply the configuration, which will download an Ubuntu 22.04 Cloud Base image, create two VMs (`vm-worker` and `vm-db`), and place our public SSH key inside the `ansible` user.

```bash
terraform init
terraform apply -auto-approve
```

Terraform automatically updates `Lab4/ansible/inventory.ini` using the dynamically assigned IPs.

### 2. Configuration Management (Ansible)

Once the VMs have booted, navigate to the `Lab4/ansible/` directory.

Wait approximately 30-60 seconds to ensure Cloud-Init finishes booting the minimal base OS initially.

```bash
cd ../ansible/
ansible-playbook playbook.yml
```

The playbook executes three main stages:
1. **common** (applied to all): Creates standard users (`student`, `teacher` with password `12345678`) and sets up `/home/student/gradebook` with the correct task variant (N=26).
2. **db** (applied to VM db): Installs MariaDB, configures it to listen to `Workers` IP only, and secures the DB behind UFW firewall so only the worker node and SSH traffic is allowed.
3. **workers** (applied to VM workers): 
   - Installs Node.js LTS and user `operator` (restricted sudo permissions).
   - Syncs application codebase.
   - Deploys the templated systemd service.
   - Sets up `nginx` as a reverse proxy with configuration templates pointing to the templated application port.

## Verification
Navigate to http://<Worker_IP> to test the application!
