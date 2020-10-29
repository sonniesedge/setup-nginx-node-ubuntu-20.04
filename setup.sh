#!/bin/bash

# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'

sudo mkdir -p /var/www/whalecoiner.com/html
sudo chown -R $USER:$USER /var/www/whalecoiner.com/html
sudo chmod -R 755 /var/www/whalecoiner.com

sudo tee -a /etc/nginx/sites-available/whalecoiner.com > /dev/null <<EOT
server {
        listen 80;
        listen [::]:80;

        root /var/www/whalecoiner.com/html;
        index index.html index.htm index.nginx-debian.html;

        server_name whalecoiner.com www.whalecoiner.com;

        location / {
                try_files $uri $uri/ =404;
        }
}
EOT

sudo ln -s /etc/nginx/sites-available/whalecoiner.com /etc/nginx/sites-enabled/

# Remove the '#' in the following string:
# '# server_names_hash_bucket_size 64;'
sudo sed -i -e 's/abc/XYZ/g' /etc/nginx/nginx.conf


# Config okay?
sudo nginx -t

sudo systemctl restart nginx


# Certbot

sudo apt install certbot python3-certbot-nginx

# TODO: need to choose '2' by default (redirect all requests to https)
sudo certbot --nginx -d whalecoiner.com -d www.whalecoiner.com

# Renew certs automatically
sudo systemctl status certbot.timer
