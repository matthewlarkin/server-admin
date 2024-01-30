# Starting services automatically on system boot
- - - - -
We can write system services that start automatically when the system boots. This is useful for services that need to be running in the background all the time, such as a web server (like SQLPage) or a database server.

Using SQLPage as an example, we can create a service file at `/etc/systemd/system/sqlpage.service` that looks like this:

**create a service file**
```bash
sudo vim /etc/systemd/system/sqlpage.service
```

```ini
[Unit]
Description=SQLPage Service
After=network.target

[Service]
WorkingDirectory=/var/www/chikomo-marimba
ExecStart=/usr/local/bin/sqlpage
Restart=on-failure
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
```

This file tells systemd to start the service when the system boots, and to restart it if it fails. It also tells systemd to run the service as the `www-data` user and group, which is typically good for web servers.

Now, we can enable and start the service:
```bash
sudo systemctl enable sqlpage.service
sudo systemctl start sqlpage.service
```

If we make changes to the service file, we'll need to reload the systemd daemon and enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl restart sqlpage.service
# then check the status of the service
sudo systemctl status sqlpage.service
```