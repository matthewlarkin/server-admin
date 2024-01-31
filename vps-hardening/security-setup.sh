#!/bin/bash

# Security Tools Installation and Configuration on Ubuntu 22.04 VPS
# This is the second part of the VPS hardening process (after initial-setup.sh)
# This step is intended to be run as the new (non-root) user created in initial-setup.sh

echo "🌿 Step 2: Installing and Configuring Security Tools 🌿"

# Update System Packages
sudo apt update && sudo apt upgrade -y

# Fail2Ban Installation
sudo apt install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban

# Firewall Setup with UFW
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw status

# Automated Security Updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Log Monitoring with Logwatch
sudo apt install logwatch -y
sudo cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/logwatch.conf

# Rootkit Scanners
sudo apt install rkhunter chkrootkit lynis -y
sudo sed -i 's/CRON_DAILY_RUN="false"/CRON_DAILY_RUN="true"/g' /etc/default/rkhunter
sudo rkhunter --check
sudo rkhunter --update
sudo mkdir -p /var/log/rkhunter
sudo chmod 700 /var/log/rkhunter
sudo mkdir -p /var/log/lynis
sudo chmod 700 /var/log/lynis

# We'll get an error with WEB_CMD if we don't set it to null,
# but since we're doing unattended updates, we shouldn't need it

# Adding crontab entries
(crontab -l 2>/dev/null; echo "0 0 * * * sudo rkhunter --update && sudo rkhunter --cronjob --report-warnings-only > /var/log/rkhunter/rkhunter_$(date +\\%Y-\\%m-\\%d).log") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * 0 sudo lynis audit system > /var/log/lynis/lynis_weekly_audit_$(date +\\%Y-\\%m-\\%d).log") | crontab -

echo "Security tools installed and configured. Remember to manually set up crontab for regular RKHunter and Lynis scans."
