#!/bin/bash

# This script sets up NGINX as a reverse proxy with Let's Encrypt SSL for a site
# It also sets up a systemd service for the site in case the server reboots

read -p "Enter your domain name to secure with SSL (e.g., example.com): " domain
read -p "Enter the port your site is/will be listening on (e.g., 9200): " port
# Setup for the systemd service
read -p "project_name: " project_name
read -p "Project directory: " project_directory
read -p "Executable name: " executable_name
read -p "User:Group (leave blank for current user): " user_group

# Function to check if a program is installed
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install NGINX
install_nginx() {
    if is_installed nginx; then
        echo "NGINX is already installed."
    else
        echo "Installing NGINX..."
        sudo apt update
        sudo apt install nginx -y
        echo "NGINX installed."
    fi
}

# Function to install Certbot
install_certbot() {
    if is_installed certbot; then
        echo "Certbot is already installed."
    else
        echo "Installing Certbot and its NGINX plugin..."
        sudo apt install certbot python3-certbot-nginx -y
        echo "Certbot installed."
    fi
}

# Function to set up NGINX configuration for a site
setup_nginx_config() {

    config_path="/etc/nginx/sites-available/$domain"
    echo "Setting up NGINX configuration for $domain..."

    # Create NGINX configuration
    sudo bash -c "cat > $config_path" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    return 301 https://$domain\$request_uri;
}

server {
    listen 443 ssl;
    server_name www.$domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    return 301 https://$domain\$request_uri;
}

server {
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Backup default NGINX configuration and remove symbolic link if it exists
    sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    sudo rm /etc/nginx/sites-enabled/default

    # Enable site configuration
    sudo ln -s $config_path /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    echo "Configuration for $domain set up."
}

# Function to obtain SSL certificate for a domain
obtain_ssl_certificate() {
    sudo certbot --nginx -d "$domain" -d "www.$domain"
}

# Main process for setting up NGINX and Certbot
install_nginx
setup_nginx_config
install_certbot
obtain_ssl_certificate

echo "NGINX reverse proxy setup complete for $domain."

# Use the current user if user_group is not provided
if [ -z "$user_group" ]; then
    user_group=$(whoami)
fi

# Create and enable the systemd service
echo "Creating and starting service for $project_name..."
sudo bash -c "cat > /etc/systemd/system/$project_name.service" << EOF
[Unit]
Description=$project_name website
After=network.target

[Service]
WorkingDirectory=$project_directory
ExecStart=$executable_name
Restart=on-failure
User=${user_group%:*}
Group=${user_group#*:}

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $project_name.service
sudo systemctl start $project_name.service
sudo systemctl status $project_name.service

echo "$project_name service setup complete."
