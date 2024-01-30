
# Using NGINX as a Reverse Proxy for Multiple Sites
This guide is tailored for Ubuntu 20.04 LTS.

## Install NGINX
NGINX is an open-source software that serves as a high-performance HTTP server and reverse proxy.
To install NGINX, use the following commands:
```bash
sudo apt update
sudo apt install nginx
```

## Install Certbot
Certbot is an open-source tool that automates the process of obtaining certificates from Let’s Encrypt to enable HTTPS on websites.
To install Certbot, execute:
```bash
sudo apt install certbot python3-certbot-nginx
```

## SSL
To obtain a certificate when your domains are pointed to the server, run:
```bash
sudo certbot --nginx -d example.com -d www.example.com
```

## Setup NGINX Configuration for Each Site
Create a new configuration file for each site. Assuming our sites are listening on specific ports (such as 9200, 9201, 9202, etc), use the following configuration:

### example.com
```bash
sudo vim /etc/nginx/sites-available/example.com.conf
```
Then, add the following configuration:
```conf
server {
    listen 443 ssl;
    server_name example.com;  # Your domain

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;  # SSL certificate
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;  # SSL certificate key

    location / {
        proxy_pass http://localhost:9200;  # Website port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}
```
Enable the site configuration:
```bash
sudo ln -s /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-enabled/
```

## Applying Changes
After making changes to the NGINX configuration, run the following command to apply the changes:
```bash
sudo nginx -t
sudo systemctl reload nginx
```
