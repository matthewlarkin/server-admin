# VPS Hardening for Ubuntu 22.04

Ensuring the security of your Virtual Private Server (VPS) is crucial. This guide provides steps to harden your Ubuntu 22.04 VPS, focusing on SSH access, firewall settings, and various security tools.

🌿 - - - 🌿 - - - 🌿

## Initial Setup with SSH Access

### SSH into Server
First, access your server using SSH.

```sh
ssh root@{{my_new_ip_address}}
```

### Create a Non-Root User
It's safer to operate as a non-root user.

```sh
adduser {{my_new_user}}
usermod -aG sudo {{my_new_user}}
```

### Set Up SSH for New User
Transfer SSH keys to the new user for secure access.

```bash
mkdir -p /home/{{my_new_user}}/.ssh
cp /root/.ssh/authorized_keys /home/{{my_new_user}}/.ssh/
chown -R {{my_new_user}}:{{my_new_user}} /home/{{my_new_user}}/.ssh
chmod 700 /home/{{my_new_user}}/.ssh
chmod 600 /home/{{my_new_user}}/.ssh/authorized_keys
```

### Secure SSH Configuration
Modify SSH settings to enhance security.

```bash
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd
exit
```

### SSH as New User
Log in as the new user to continue the setup.

```bash
ssh {{my_new_user}}@{{my_new_ip_address}}
```

### Update System Packages
Keep your system updated for security patches.

```bash
sudo apt update && sudo apt upgrade -y
```

🌿 - - - 🌿 - - - 🌿

## Installing and Configuring Security Tools

### Fail2Ban Installation
Install Fail2Ban to prevent brute force attacks.

```bash
sudo apt install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

### Firewall Setup with UFW
Configure Uncomplicated Firewall (UFW) for basic security.

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw status
```

### Automated Security Updates
Set up unattended upgrades for automatic security updates.

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### Log Monitoring with Logwatch
Install and configure Logwatch for regular log monitoring.

```bash
sudo apt install logwatch -y
sudo cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/logwatch.conf
```

### Rootkit Scanners
Install and configure tools to detect rootkits.

```bash
# RKHunter
sudo apt install rkhunter -y
sudo sed -i 's/CRON_DAILY_RUN="false"/CRON_DAILY_RUN="true"/g' /etc/default/rkhunter
sudo rkhunter --check
sudo rkhunter --update
sudo mkdir -p /var/log/rkhunter
sudo chmod 700 /var/log/rkhunter
# Setup a Weekly RKHunter scan
sudo crontab -e
# 0 0 * * * sudo rkhunter --update && sudo rkhunter --cronjob --report-warnings-only > /var/log/rkhunter/rkhunter_$(date +\%Y-\%m-\%d).log

# CHKRootKit
sudo apt install chkrootkit -y
sudo chkrootkit

# Lynis
sudo apt install lynis -y
sudo lynis audit system
sudo mkdir -p /var/log/lynis
sudo chmod 700 /var/log/lynis
# Weekly Lynis audit
sudo crontab -e
# 0 3 * * 0 sudo lynis audit system > /var/log/lynis/lynis_weekly_audit_$(date +\%Y-\%m-\%d).log
```
