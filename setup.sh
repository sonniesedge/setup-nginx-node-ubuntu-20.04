#!/bin/bash

DOMAINNAME=whalecoiner.com
USERNAME=deploy

# INSTALL AND CONFIGURE NGINX
# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'

sudo mkdir -p /var/www/$DOMAINNAME/html
sudo chown -R $USER:$USER /var/www/$DOMAINNAME/html
sudo chmod -R 755 /var/www/$DOMAINNAME

## Add a server block for the site
sudo tee -a /etc/nginx/sites-available/$DOMAINNAME >/dev/null <<EOT
server {
    listen 80;
    listen [::]:80;

    root /var/www/$DOMAINNAME/html;
    index index.html index.htm index.nginx-debian.html;

    server_name $DOMAINNAME www.$DOMAINNAME;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    # favicon.ico
    location = /favicon.ico {
        log_not_found off;
        access_log    off;
    }

    # robots.txt
    location = /robots.txt {
        log_not_found off;
        access_log    off;
    }

    # gzip
    gzip              on;
    gzip_vary         on;
    gzip_proxied      any;
    gzip_comp_level   6;
    gzip_types        text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # brotli
    #brotli            on;
    #brotli_comp_level 6;
    #brotli_types      text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
}
EOT

sudo ln -s /etc/nginx/sites-available/$DOMAINNAME /etc/nginx/sites-enabled/

# TODO: Remove the '#' in the following string:
# '# server_names_hash_bucket_size 64;'
sudo sed -i -e 's/abc/XYZ/g' /etc/nginx/nginx.conf

# Config okay?
sudo nginx -t

sudo systemctl restart nginx

# Install Certbot
sudo apt install certbot python3-certbot-nginx

# TODO: need to choose '2' by default (redirect all requests to https)
sudo certbot --nginx -d $DOMAINNAME -d www.$DOMAINNAME

# Renew certs automatically
sudo systemctl status certbot.timer

sudo systemctl restart nginx

# INSTALL NODE AND PM2
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04

curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh

sudo bash nodesource_setup.sh

sudo apt-get install nodejs

sudo apt-get install build-essential

sudo npm install pm2@latest -g

pm2 startup systemd

sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USERNAME --hp /home/$USERNAME

pm2 save
