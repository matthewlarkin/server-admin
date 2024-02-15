# check if nginx is installed
if ! [ -x "$(command -v nginx)" ]; then
  echo "⚠️ nginx is not installed. Installing nginx..."
  sudo apt install -y nginx
else
  echo "✅ nginx is installed"
fi

# check if nginx is running
if ! systemctl is-active --quiet nginx; then
  echo "⚠️ nginx is not running. Starting nginx..."
  sudo systemctl start nginx
else
  echo "✅ nginx is running"
fi

# check if nginx is enabled
if ! systemctl is-enabled --quiet nginx; then
  echo "⚠️ nginx is not enabled. Enabling nginx..."
  sudo systemctl enable nginx
else
  echo "✅ nginx is enabled"
fi