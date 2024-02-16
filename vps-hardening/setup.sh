#!/bin/bash

# User Creation and SSH Configuration on Ubuntu 22.04 VPS
# This is the first part of the VPS hardening process (before security-setup.sh)
# This step is intended to be run as root once you have logged in to the VPS

echo "🌿 Step 1: User Creation and SSH Configuration 🌿"

# Create a Non-Root User
read -p "Enter a new username to create: " my_new_user
if adduser $my_new_user && usermod -aG sudo $my_new_user; then
    echo "User $my_new_user created and added to sudo group."
else
    echo "Failed to create user $my_new_user."
    exit 1
fi

# Set Up SSH for New User
ssh_dir="/home/$my_new_user/.ssh"
if mkdir -p $ssh_dir && cp /root/.ssh/authorized_keys $ssh_dir/ && chown -R $my_new_user:$my_new_user $ssh_dir && chmod 700 $ssh_dir && chmod 600 $ssh_dir/authorized_keys; then
    echo "SSH setup for $my_new_user completed."
else
    echo "SSH setup for $my_new_user failed."
    exit 1
fi

# Create the server-admin directory in the new user's home
server_admin_dir="/home/$my_new_user/server-admin"
if sudo mkdir -p $server_admin_dir && sudo chown -R $my_new_user:$my_new_user $server_admin_dir && sudo cp -r /root/server-admin/* $server_admin_dir/; then
    echo "server-admin directory setup for $my_new_user completed."
else
    echo "server-admin directory setup for $my_new_user failed."
    exit 1
fi

# Secure SSH Configuration
if sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && sudo systemctl restart sshd; then
    echo "SSH configuration updated. Please log in as the new user to continue with the setup."
else
    echo "Failed to update SSH configuration."
    exit 1
fi