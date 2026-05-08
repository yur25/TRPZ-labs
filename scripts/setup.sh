#!/bin/bash

# ==============================================================================
# Web Service Automation Setup Script
# Student Parameters: V2=1, V3=3, V5=2
# App Name: mywebapp | Port: 5200 | Database: MariaDB | Task: Simple Inventory
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# 1. Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit 1
fi

echo "Starting system setup..."

# 2. Update packages and install prerequisites
echo "Installing MariaDB, Nginx, and prerequisites..."
apt-get update -y
apt-get install -y curl dirmngr apt-transport-https lsb-release ca-certificates mariadb-server nginx sudo

# 3. Install Node.js (Latest LTS)
echo "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# 4. User and Permissions Management
echo "Configuring OS Users..."

# Function to create user, set default password, and force change on next login
create_user_with_pass() {
    local username=$1
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        echo "$username:12345678" | chpasswd
        chage -d 0 "$username" # Force password change on first login
        echo "Created user: $username"
    else
        echo "User $username already exists."
    fi
}

# 4.1. student and teacher (Full Sudo rights)
create_user_with_pass student
create_user_with_pass teacher
usermod -aG sudo student
usermod -aG sudo teacher

# 4.2. Gradebook file creation
echo "26" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

# 4.3. mywebapp (Minimal rights system user)
if ! id "mywebapp" &>/dev/null; then
    useradd -r -s /bin/false mywebapp
    echo "Created system user: mywebapp"
fi

# 4.4. operator (Restricted user)
create_user_with_pass operator
# Configure sudoers for operator safely
cat <<EOF > /etc/sudoers.d/operator
operator ALL=(ALL) /bin/systemctl start mywebapp, /bin/systemctl stop mywebapp, /bin/systemctl restart mywebapp, /bin/systemctl status mywebapp, /usr/sbin/nginx -s reload, /bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator

# 5. Lock default cloud user account
# Usually 'ubuntu' on AWS/Ubuntu Cloud Images, 'debian' on Debian, or 'ec2-user'.
for u in ubuntu debian ec2-user; do
    if id "$u" &>/dev/null; then
        usermod -L "$u"
        echo "Locked default user: $u"
    fi
done

# 6. Database Setup (MariaDB)
echo "Configuring MariaDB..."
systemctl enable mariadb
systemctl start mariadb

mysql -e "CREATE DATABASE IF NOT EXISTS mywebappdb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'mywebappuser'@'localhost' IDENTIFIED BY 'mywebappsecret';"
mysql -e "GRANT ALL PRIVILEGES ON mywebappdb.* TO 'mywebappuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 7. Application Deployment
echo "Deploying Application..."
# Assuming script is run from inside the 'scripts' directory of the repository
REPO_ROOT=$(dirname $(dirname $(realpath $0)))

# Prepare application directory
rm -rf /opt/mywebapp
mkdir -p /opt/mywebapp/app
cp -r $REPO_ROOT/app/* /opt/mywebapp/app/

# Set ownership and install dependencies
cd /opt/mywebapp/app
npm install --production
chown -R mywebapp:mywebapp /opt/mywebapp

# 8. NGINX Configuration
echo "Configuring NGINX..."
cp $REPO_ROOT/nginx/mywebapp.conf /etc/nginx/sites-available/mywebapp
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl enable nginx

# 9. Systemd Configuration
echo "Configuring Systemd..."
cp $REPO_ROOT/systemd/mywebapp.service /etc/systemd/system/
systemctl daemon-reload

# Start socket activated elements if needed by replacing mywebapp.service with socket
# However, assignment says "Later, upgrade the service to use systemd socket activation". 
# So the setup script will use the standard service deployment.

systemctl enable mywebapp.service
systemctl start mywebapp.service

echo "========================================================"
echo "Deployment Complete!"
echo "App listening securely behind NGINX at http://localhost/"
echo "========================================================"
