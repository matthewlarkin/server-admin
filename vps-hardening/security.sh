#!/bin/bash

source server-admin/includes/colors.sh
source server-admin/includes/animation.sh

# Security Tools Installation and Configuration on Ubuntu 22.04 VPS
# This is the second part of the VPS hardening process (after initial-setup.sh)
# This step is intended to be run as the new (non-root) user created in initial-setup.sh

echo "🌿 Step 2: Installing and Configuring Security Tools 🌿"

# Fail2Ban Installation
fail2ban_installation_commands="
    sudo apt install fail2ban -y
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
"
run_with_animation "$fail2ban_installation_commands" "Fail2Ban installed and configured successfully."

# Firewall Setup with UFW
ufw_setup_commands="
    sudo apt install ufw -y
    sudo ufw default deny incoming
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw enable
"
run_with_animation "$ufw_setup_commands" "UFW installed and configured successfully."

# Check UFW status
run_with_animation "sudo ufw status" "UFW status checked successfully."

# Automated Security Updates
automated_security_updates_commands="
    sudo apt install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
"
run_with_animation "$automated_security_updates_commands" "Unattended-upgrades installed and configured successfully."