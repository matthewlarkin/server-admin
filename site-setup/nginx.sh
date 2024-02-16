#!/bin/bash

# set up nginx for unbuntu 22.04
sudo apt install -y nginx

# set up systemd service to automatically start nginx on server boot
sudo systemctl enable nginx

# start the nginx service
sudo systemctl start nginx