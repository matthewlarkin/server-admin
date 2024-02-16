#!/bin/bash

source server-admin/includes/colors.sh
source server-admin/includes/animation.sh

sqlpage_bin="/usr/bin/sqlpage"
sqlpage_url="https://github.com/lovasoa/SQLpage/releases/download/v0.18.3/sqlpage-linux.tgz"

# Functions
function install_sqlpage {
    if [ ! -f "$sqlpage_bin" ]; then
        printf "\n⚠️  ${red}SQLPage is not installed...${reset}\n"
        printf "\n🚜 Installing SQLPage...\n"
        sudo curl -s -L -O $sqlpage_url
        sudo tar -xzf sqlpage-linux.tgz && sudo rm sqlpage-linux.tgz
        sudo mv sqlpage.bin $sqlpage_bin
        sudo chmod 750 $sqlpage_bin
        sudo chown www-data:www-data $sqlpage_bin
    fi
}

function ask_question {
    printf "${yellow}QUESTION${reset}: $1 "
    read response
    echo $response
}

function validate_port {
    port=$1
    while [ -n "$(sudo lsof -i :$port)" ]; do
        printf "\n⚠️ ${red}Something is already running on port ${port}.${reset}\n"
        port=$(ask_question "What port would you like to run the SQLPage service on?")
    done
    echo $port
}

# Main script
printf "\n- - - - - - - - - - - - - - -\n"

# run the nginx script (to make sure nginx is installed and running)
printf "\n🚜 ${blue}Setting up SQLPage...${reset}\n"
bash server-admin/site-setup/nginx.sh

install_sqlpage

printf "\n✅ ${green}SQLPage is installed!${reset}\n"

printf "\n- - - - - - - - - - - - - - -\n\n"

# install the sqlpage website in the home directory
repo=$(ask_question "What is your github repo? <user/repo>:")
domain=$(ask_question "What is the domain name?")
www_included=$(ask_question "Will you be using a 'www' for this domain? (y/n)")
port=$(ask_question "What port would you like to run the SQLPage service running on?")
port=$(validate_port $port)

# Constants
NGINX_AVAILABLE_SITES="/etc/nginx/sites-available"
NGINX_ENABLED_SITES="/etc/nginx/sites-enabled"
SQLPAGE_SERVICE="/etc/systemd/system/sqlpage.service"

# Functions
function clone_repo {
    repo=$1
    sudo git clone "https://github.com/$repo.git" "/var/www/$repo"
    sudo chown -R www-data:www-data "/var/www/$repo"
}

function setup_sqlpage_service {
    port=$1
    repo=$2
    sudo bash -c "cat > $SQLPAGE_SERVICE <<EOF
[Unit]
Description=SQLPage Service
After=network.target

[Service]
ExecStart=$sqlpage_bin -p $port /var/www/$repo
User=www-data
Group=www-data
Restart=always

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl enable sqlpage
    sudo systemctl start sqlpage
}

function setup_nginx {
    domain=$1
    www_included=$2
    repo=$3
    port=$4
    server_name="server_name $domain"
    if [ "$www_included" = "y" ]; then
        server_name="$server_name www.$domain"
    fi
    sudo bash -c "cat > $NGINX_AVAILABLE_SITES/$domain <<EOF
server {
    listen 80;
    $server_name;
    location / {
        proxy_pass http://localhost:$port;
    }
}
EOF"
    sudo ln -s $NGINX_AVAILABLE_SITES/$domain $NGINX_ENABLED_SITES/
    sudo systemctl reload nginx
}

# Main script
clone_repo $repo
setup_sqlpage_service $port $repo
setup_nginx $domain $www_included $repo $port

printf "\n✅ ${green}SQLPage service is running and Nginx is configured!${reset}\n"
printf "\n- - - - - - - - - - - - - - -\n\n"