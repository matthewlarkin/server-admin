# run the nginx script (to make sure nginx is installed and running)
$(../site-setup/nginx.sh)

# install sqlpage if not already installed
# check if sqlpage is installed
if ! [ -x "$(command -v sqlpage)" ]; then
    echo "⚠️ sqlpage is not installed. Installing sqlpage..."
    sudo curl -s -L -O https://github.com/lovasoa/SQLpage/releases/download/v0.18.3/sqlpage-linux.tgz
    sudo tar -xzf sqlpage-linux.tgz && sudo rm sqlpage-linux.tgz
    sudo mv sqlpage.bin /usr/bin/sqlpage
    sudo chmod 750 /usr/bin/sqlpage
fi

# install the sqlpage website in the home directory
read -p "☝️ What is your github repo? (user/repo): " repo

# split the repo into $user and $repo_name vars
IFS='/' read -r -a repo_array <<< "$repo"
user=${repo_array[0]}
repo_name=${repo_array[1]}

# check that /var/www/ exists
if [ ! -d "/var/www" ]; then
  echo "⚠️ /var/www/ does not exist. Creating /var/www/..."
  sudo mkdir -p /var/www
else
  echo "✅ /var/www/ exists"
fi

# clone the repo into /var/www/
sudo git clone git@github.com:$repo.git /var/www/$repo_name

# cd into the repo
cd /var/www/$repo_name

/usr/bin/sqlpage .

echo "🌿 Opening SQLPage config file... 🌿"
# countdown for three seconds, displaying on terminal
for i in {3..1}; do echo $i && sleep 1; done

# open the sqlpage.json file in vim
sudo vim ./sqlpage/sqlpage.json

# setup the sqlpage service for this repo
echo "🌿 Setting up SQLPage service... 🌿"

# create the sqlpage.service file
sudo touch /etc/systemd/system/sqlpage-$repo_name.service

# write the sqlpage.service file
sudo tee /etc/systemd/system/sqlpage-$repo_name.service > /dev/null <<EOT
[Unit]
Description=SQLPage Service for $repo_name
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/var/www/$repo_name
ExecStart=/usr/bin/sqlpage
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# start the sqlpage service
sudo systemctl start sqlpage-$repo_name

# enable the sqlpage service
sudo systemctl enable sqlpage-$repo_name

# check the status of the sqlpage service
sudo systemctl status sqlpage-$repo_name