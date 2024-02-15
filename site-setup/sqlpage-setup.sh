#!/bin/bash

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
MUTED='\033[1;30m'
RESET='\033[0m'

printf "\n- - - - - - - - - - - - - - -\n"

# run the nginx script (to make sure nginx is installed and running)
printf "\n🚜 ${BLUE}Setting up SQLPage...${RESET}\n"
bash server-admin/site-setup/nginx.sh


# if /usr/bin/sqlpage does not exist yet
if [ ! -f "/usr/bin/sqlpage" ]; then
    printf "\n⚠️  ${RED}SQLPage is not installed...${RESET}\n"
    printf "\n🚜 Installing SQLPage...\n"
    sudo curl -s -L -O https://github.com/lovasoa/SQLpage/releases/download/v0.18.3/sqlpage-linux.tgz
    sudo tar -xzf sqlpage-linux.tgz && sudo rm sqlpage-linux.tgz
    sudo mv sqlpage.bin /usr/bin/sqlpage
    sudo chmod 750 /usr/bin/sqlpage
    sudo chown www-data:www-data /usr/bin/sqlpage
fi

printf "\n✅ ${GREEN}SQLPage is installed!${RESET}\n"

printf "\n- - - - - - - - - - - - - - -\n\n"


# install the sqlpage website in the home directory
printf "${YELLOW}QUESTION${RESET}: What is your github repo? ${MUTED}<user/repo>: ${RESET}"
read repo
printf "${YELLOW}QUESTION${RESET}: What is the domain name? "
read domain
printf "${YELLOW}QUESTION${RESET}: Will you be using a 'www' for this domain? (y/n) "
read www_included
printf "${YELLOW}QUESTION${RESET}: What port would you like to run the SQLPage service running on? "
read port


printf "\n- - - - - - - - - - - - - - -\n"

# check if something is currently running on the port
while [ -n "$(sudo lsof -i :$port)" ]; do
    printf "\n⚠️ ${RED}Something is already running on port ${port}.${RESET}\n"
    read -p "${YELLOW}QUESTION${RESET}: What port would you like to run the SQLPage service on? " port
done
printf "\n✅ ${GREEN}Port ${port} is available!\n${RESET}"


printf "\n- - - - - - - - - - - - - - -\n"

public_ip=$(curl -s ifconfig.me)
printf "\n${YELLOW}QUESTION${RESET}: Have you already setup the DNS for this domain? You'll need to point A records to ${BLUE}${public_ip}${RESET} (y/n) "
read dns_setup

printf "\n- - - - - - - - - - - - - - -\n"


while [ $dns_setup != "y" ]; do
    printf "\n🙄 Okay, go set up the DNS for $domain, and when you're done, come back here and say 'y' to continue. (y) "
    read dns_setup
done

# split the repo into $user and $repo_name vars
IFS='/' read -r -a repo_array <<< "$repo"
user=${repo_array[0]}
repo_name=${repo_array[1]}

# check that /var/www/ exists
printf "\n👏 Great, let's check in on /var/www/...\n"
if [ ! -d "/var/www" ]; then
    echo "🚜 /var/www/ does not exist. Creating /var/www/..."
    sudo mkdir -p /var/www
fi

printf "\n✅ ${GREEN}/var/www/ created!${RESET}\n\n"

read -p "Have you set up an SSH key on this server and set it up on GitHub? (y/n)" ssh_setup
while [ $ssh_setup != "y" ]; do
    printf "\n🙄 Okay, go setup the SSH key, and when you're done, come back here and say 'y' to continue. (y) "
    read ssh_setup
done

printf "\n👏 ${GREEN}Awesome!${RESET}\n"

printf "\n🚜 Cloning the repo into /var/www/...\n"

# clone the repo into /var/www/
sudo git clone git@github.com:$repo.git
sudo mv $repo_name /var/www/

printf "\n✅ ${GREEN}Repo cloned into /var/www/!${RESET}\n"

printf "\n- - - - - - - - - - - - - - -\n"

printf "\n🚜 Setting up the SQLPage configuration file\n"
# use jq to edit the existing sqlpage.json file. We need to make the property "port" equal to the port we want to run the service on
sudo jq '.port = '$port'' /var/www/$repo_name/sqlpage/sqlpage.json > /var/www/$repo_name/sqlpage/sqlpage.json.tmp && sudo mv /var/www/$repo_name/sqlpage/sqlpage.json.tmp /var/www/$repo_name/sqlpage/sqlpage.json

# setup the sqlpage service for this repo
printf "\n🚜 Setting up SQLPage service (for autostart on server boot)... 🚜\n"

# create the sqlpage.service file
sudo touch /etc/systemd/system/sqlpage-$repo_name.service

# write the sqlpage.service file
sudo tee /etc/systemd/system/sqlpage-$repo_name.service > /dev/null <<EOT
[Unit]
Description=SQLPage Service for $domain
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/$repo_name
ExecStart=/usr/bin/sqlpage
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# reload the systemd daemon
printf "\n🚜 Reloading the systemd daemon...\n"
sudo systemctl daemon-reload

# start the sqlpage service
printf "\n🚜 Starting the SQLPage service...\n"
sudo systemctl start sqlpage-$repo_name

# enable the sqlpage service
printf "\n🚜 Enabling the SQLPage service...\n"
sudo systemctl enable sqlpage-$repo_name

# create the nginx config file
printf "\n🚜 Creating the nginx config file...\n"
sudo touch /etc/nginx/sites-available/$repo_name

# write the nginx config file that will reverse proxy to the sqlpage service and redirect traffic to https
printf "\n🚜 Writing your project's nginx config file...\n"
sudo tee /etc/nginx/sites-available/$repo_name > /dev/null <<EOT
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://localhost:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOT

# create a symbolic link to the sites-enabled directory
printf "\n🚜 Creating a symbolic link to the sites-enabled directory...\n"
sudo ln -s /etc/nginx/sites-available/$repo_name /etc/nginx/sites-enabled/$repo_name

# setup certbot for the domain
if ! [ -x "$(command -v certbot)" ]; then
    printf "\n⚠️ ${RED}Certbot is not installed.${RESET}\n"
    printf "\n🚜 Installing Certbot...\n"
    sudo apt install -y certbot python3-certbot-nginx
fi
sudo certbot --nginx -d $domain

# restart nginx
printf "\n🚜 Restarting nginx...\n"
sudo systemctl restart nginx

printf "\n\n🚀 ${GREEN}SQLPage is now running at https://$domain!${RESET}\n\n"
printf "\n\nIf everything went well, we should be able to visit https://$domain\n
and see the SQLPage website!\n\nYou may want to check the status of the SQLPage\n
service by running 'sudo systemctl status sqlpage-$repo_name' and the nginx service\n
by running 'sudo systemctl status nginx'.\n\nAnd make sure you've set up the SQLPage\n
configuration file at /var/www/$repo_name/sqlpage/sqlpage.json.\n\n"