#!/bin/bash

DOMAINNAME=whalecoiner.com


# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'

sudo mkdir -p /var/www/$DOMAINNAME/html
sudo chown -R $USER:$USER /var/www/$DOMAINNAME/html
sudo chmod -R 755 /var/www/$DOMAINNAME

sudo tee -a /etc/nginx/sites-available/$DOMAINNAME > /dev/null <<EOT
server {
        listen 80;
        listen [::]:80;

        root /var/www/whalecoiner.com/html;
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
}
EOT

sudo ln -s /etc/nginx/sites-available/$DOMAINNAME /etc/nginx/sites-enabled/

# Remove the '#' in the following string:
# '# server_names_hash_bucket_size 64;'
sudo sed -i -e 's/abc/XYZ/g' /etc/nginx/nginx.conf


# Config okay?
sudo nginx -t

sudo systemctl restart nginx


# Certbot

sudo apt install certbot python3-certbot-nginx

# TODO: need to choose '2' by default (redirect all requests to https)
sudo certbot --nginx -d $DOMAINNAME -d www.$DOMAINNAME

# Renew certs automatically
sudo systemctl status certbot.timer

sudo systemctl restart nginx


# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04

curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh

sudo bash nodesource_setup.sh

sudo apt-get install nodejs

sudo apt-get install build-essential

sudo npm install pm2@latest -g

pm2 startup systemd

sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USERNAME --hp /home/$USERNAME

pm2 save
