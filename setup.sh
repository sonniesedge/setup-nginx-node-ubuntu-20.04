#!/bin/bash

DOMAINNAME=whalecoiner.com
USERNAME=deploy

sudo apt update
sudo apt install nginx certbot python3-certbot-nginx nodejs build-essential -y

# ----------------
# CONFIGURE NGINX
# ----------------
# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

# Allow firewall access
sudo ufw allow 'Nginx Full'

# Make sure our user owns it all
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

    # # ACME-challenge
    # location ^~ /.well-known/acme-challenge/ {
    #   root /var/www/_letsencrypt;
    # }

    location / {
        proxy_pass http://localhost:3000;
        # proxy_http_version 1.1;
        # proxy_set_header Upgrade $http_upgrade;
        # proxy_set_header Connection 'upgrade';
        # proxy_set_header Host $host;
        # proxy_cache_bypass $http_upgrade;

        # proxy_http_version                 1.1;
        # proxy_cache_bypass                 $http_upgrade;

        # Proxy headers
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-Port  $server_port;

        # Proxy timeouts
        proxy_connect_timeout              60s;
        proxy_send_timeout                 60s;
        proxy_read_timeout                 60s; 

        # security headers
        add_header X-Frame-Options           "SAMEORIGIN" always;
        add_header X-XSS-Protection          "1; mode=block" always;
        add_header X-Content-Type-Options    "nosniff" always;
        add_header Referrer-Policy           "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy   "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # # . files
        # location ~ /\.(?!well-known) {
        #     deny all;
        # }
    }
    
    # # favicon.ico
    # location = /favicon.ico {
    #     log_not_found off;
    #     access_log    off;
    # }

    # # robots.txt
    # location = /robots.txt {
    #     log_not_found off;
    #     access_log    off;
    # }

    # # gzip
    # gzip              on;
    # gzip_vary         on;
    # gzip_proxied      any;
    # gzip_comp_level   6;
    # gzip_types        text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # # brotli
    # #brotli            on;
    # #brotli_comp_level 6;
    # #brotli_types      text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
}
EOT

# Active the server block
sudo ln -s /etc/nginx/sites-available/$DOMAINNAME /etc/nginx/sites-enabled/

# TODO: Remove the '#' in the following string:
# '# server_names_hash_bucket_size 64;'
sudo sed -i -e 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' c

# Config okay with nginx?
sudo nginx -t

# TODO: Fail script here if not

sudo systemctl restart nginx

# Activate Certbot for this server block
# TODO: need to choose '2' by default (redirect all requests to https)
sudo certbot --nginx -d $DOMAINNAME -d www.$DOMAINNAME

# Renew certbot certificates automatically
sudo systemctl status certbot.timer

sudo systemctl restart nginx

# ------------------------------------
# INSTALL NODE AND PM2, AND CONFIGURE
# ------------------------------------
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04

curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh

sudo bash nodesource_setup.sh

sudo npm install pm2@latest -g

pm2 startup systemd

sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USERNAME --hp /home/$USERNAME

pm2 save
