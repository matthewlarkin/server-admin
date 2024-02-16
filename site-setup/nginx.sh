#!/bin/bash

source server-admin/includes/colors.sh
source server-admin/includes/animation.sh

# Check if nginx is installed
nginx_installation_commands="
    [ -x \"$(command -v nginx)\" ] || sudo apt install -y nginx
"
run_with_animation "$nginx_installation_commands" "nginx is installed."

# Check if nginx is running
nginx_running_commands="
    systemctl is-active --quiet nginx || sudo systemctl start nginx
"
run_with_animation "$nginx_running_commands" "nginx is running."

# Check if nginx is enabled
nginx_enabled_commands="
    systemctl is-enabled --quiet nginx || sudo systemctl enable nginx
"
run_with_animation "$nginx_enabled_commands" "nginx is enabled."