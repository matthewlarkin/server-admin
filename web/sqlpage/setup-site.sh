#!/bin/bash

source colors.sh

printf "\n - - - - - - - - - - - - - - - - - - -\n"
printf "\n- - - - - 🌳 SQLPage Setup 🌳 - - - - -\n"
printf "\n - - - - - - - - - - - - - - - - - - -\n"

bash web/nginx/install.sh
bash web/sqlpage/install.sh

# install the sqlpage website in the home directory
printf "\n- - - 🌿 Project Details 🌿 - - -\n"
printf "GitHub repo <user/repo>: " && read repo
printf "Domain name: " && read domain
printf "Include www (y/n): " && read www_included
printf "SQLPage port: " && read port

# check if something is currently running on the port
while [ -n "$(sudo lsof -i :$port)" ]; do
    printf "${yellow}Port ${port} is already in use!${RESET}"
    printf "SQLPage port: " && read port
done

printf "\n- - - - - - - - - - - - - - -\n"

bash web/verify-domain.sh "$domain"
bash web/var-www.sh

# list available SSH keys
printf "\n🔑 ${YELLOW}Available SSH keys:${RESET}\n"
ls -al ~/.ssh
printf "\nDo you have an SSH key setup for this server and GitHub? (y/n) "

[[ $REPLY == [yY] ]] && printf "\n🔑 ${GREEN}Great!${RESET}\n" || bash setup-ssh-key.sh

printf "\n👏 ${GREEN}Awesome!${RESET}\n"

printf "\n🚜 Cloning the repo into /var/www/...\n"

# clone the repo into /var/www/
git clone git@github.com:$repo.git
sudo mv $repo_name /var/www/

# check that the repo was cloned to the correct location
if [ ! -d "/var/www/$repo_name" ]; then
    printf "\n⚠️ ${RED}Something went wrong. The repo was not cloned into /var/www/.\n${RESET}" && exit 1
fi

printf "\n✅ ${GREEN}Repo cloned into /var/www/!${RESET}\n"

printf "\n- - - - - - - - - - - - - - -\n"

printf "\n🚜 Setting up the SQLPage configuration file\n"
# use jq to edit the existing sqlpage.json file. We need to make the property "port" equal to the port we want to run the service on
# check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
    printf "\n⚠️ ${RED}jq is not installed.${RESET}\n"
    printf "\n🚜 Installing jq...\n"
    sudo apt install -y jq
fi

sqlpage_config_dir="/var/www/$repo_name/sqlpage"
sqlpage_config_file="$sqlpage_config_dir/sqlpage.json"

# Create the directory if it does not exist
sudo mkdir -p "$sqlpage_config_dir"

# Check if the file exists and contains valid JSON
if sudo test -s "$sqlpage_config_file" && sudo jq empty "$sqlpage_config_file" >/dev/null 2>&1; then
    # File exists and contains valid JSON, modify it
    temp_file=$(mktemp)
    sudo jq ".port = \"$port\" | .environment = \"production\"" "$sqlpage_config_file" > "$temp_file" && sudo mv "$temp_file" "$sqlpage_config_file"
else
    # File does not exist or does not contain valid JSON, create it
    echo "{\"port\": \"$port\", \"environment\": \"production\"}" | sudo tee "$sqlpage_config_file" > /dev/null
fi

sudo chown www-data:www-data /var/www/$repo_name/sqlpage/sqlpage.json

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

# restart the sqlpage service for good measure
printf "\n🚜 Restarting the SQLPage service...\n"
sudo systemctl restart sqlpage-$repo_name

printf "\n\n🚀 ${GREEN}SQLPage is now running at https://$domain!${RESET}\n\n"
printf "\n\nIf everything went well, we should be able to visit https://$domain\n
and see the SQLPage website!\n\nYou may want to check the status of the SQLPage\n
service by running 'sudo systemctl status sqlpage-$repo_name' and the nginx service\n
by running 'sudo systemctl status nginx'.\n\nAnd make sure you've set up the SQLPage\n
configuration file at /var/www/$repo_name/sqlpage/sqlpage.json.\n\n"