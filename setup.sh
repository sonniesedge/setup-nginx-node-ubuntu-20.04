#!/bin/bash

DOMAINNAME=whalecoiner.com
DOMAINALIASES=(www.whalecoiner.com whalecoiner.net www.whalecoiner.net whalecoiner.org www.whalecoiner.org)

DOMAINALIASES_COMMA_SEPARATED=$(printf '%s,' "${DOMAINALIASES[@]}")
DOMAINALIASES_COMMA_SEPARATED="${DOMAINALIASES_COMMA_SEPARATED%,}"
DOMAINALIASES_SPACE_SEPARATED=$(printf '%s ' "${DOMAINALIASES[@]}")
DOMAINALIASES_SPACE_SEPARATED="${DOMAINALIASES_SPACE_SEPARATED% }"

DEPLOYUSER=deploy
SUDOUSER=charlie

echo "-------------------------"
echo "| CONFIG"
echo "-------------------------"
echo "DOMAINNAME: $DOMAINNAME"
echo "DOMAINALIASES: ${DOMAINALIASES[@]}"
echo "DOMAINALIASES_COMMA_SEPARATED: $DOMAINALIASES_COMMA_SEPARATED"
echo "DOMAINALIASES_SPACE_SEPARATED: $DOMAINALIASES_SPACE_SEPARATED"
echo "DEPLOYUSER: $DEPLOYUSER"
echo "SUDOUSER: $SUDOUSER"

apt-get -qq update
apt-get install nginx certbot python3-certbot-nginx nodejs build-essential libssl-dev -y 

# -------------------------------
# CREATE USERS AND CONFIGURE SSH
# -------------------------------
# https://askubuntu.com/questions/94060/run-adduser-non-interactively

# Deploy user
echo ">>>> Creating $DEPLOYUSER"
adduser --gecos "" --disabled-password $DEPLOYUSER
# --gecos is for skipping the "Full name,Room number,Work phone,Home phone" stuff when creating a new user
# https://en.wikipedia.org/wiki/Gecos_field for the history buffs
mkdir -p /home/$DEPLOYUSER/.ssh
touch /home/$DEPLOYUSER/.ssh/authorized_keys
chown -R $DEPLOYUSER:$DEPLOYUSER /home/$DEPLOYUSER/.ssh
chmod 700 /home/$DEPLOYUSER/.ssh
chmod 644 /home/$DEPLOYUSER/.ssh/authorized_keys

cat <<EOT >>/home/$DEPLOYUSER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyJ7K96iFzBFADuS71quXKmcoguMhypW8GiEwQ8e16limTbFpQOxl6aGnlHBqjk3FrwtR8k5t3L3e+HzFbF+wpQEjAUHJn8AshJBrQYzT7mFlMx2fUhUU1H6KxrcEwK1TGsUjxWQn2+fLRL0ZAl5zwSfqAVMIQhZcE/7ADZkaShZMfFDFmW3Gtqp+UCCBHfFcGKIQy+fvJguNds67MuRh2fJwxEu0E7iv74wG2O937oUPSUxP36azGJ7l3nZz2smKogVhpiOlKfXm6PoBeqleTRhfw+aoWoZ5LUWeLkr+4gB59p8XsfyJJoW9CtP6MZMtjOlxv/7GYRWlv+bekVM2fF1ek/Csw0EjtgjlQohaWhW4EklnJ5fNtR0NVMR4L9Bn2ll73mbwf+/4Rx/CD+pffdYV0YTws7M/z32qbUc+IHOSbHGeFhnNCMbk8I4rLgm7/sNvtb3uF7S9Y8Ewe012LvCSCPwrVuHMobKGbJt2F7ZeOlk3Uf+oG0iRTEU7Ngmq8EofrMubhSFUjcC4KzhlUSu/fniAsFJPk2zVyPtU205NwdyWEY7+RCyvwwHHV0yMuhbBc99eUUKpBQI94PaZfAicCsLQSVN9ldQ5vvh7CKJrUJRfq2yCmmRG0EhmSjpB8YUcgT9RdM7kD+76BG0MLMv4ThDNnuCLSnMHnTjMP7w==
EOT

# Sudo user
echo ">>>> Creating $SUDOUSER"
adduser --gecos "" --disabled-password $SUDOUSER
mkdir -p /home/$SUDOUSER/.ssh
touch /home/$SUDOUSER/.ssh/authorized_keys
chown -R $SUDOUSER:$SUDOUSER /home/$SUDOUSER/.ssh
chmod 700 /home/$SUDOUSER/.ssh
chmod 644 /home/$SUDOUSER/.ssh/authorized_keys

cat <<EOT >>/home/$SUDOUSER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1SuXSEyv07abIrcbkw/U7uhgJdTsIffiG7XOLIgELG6KphYsIlC/lnoq5P0xj9oZ7W28zX+qIkg/PUSMQS3uJpynBS1y43v51Eac6SzhtH56SrAhMDfVJTclMaUAIMnTb0lN/vhD6w6bsz95AoWwInHja/4J3a1aso0qWwdyrLFZ8Y5vDLokn27EdKuqZAPfzk3VIF+zh1OXnnP3XeeTsAqzVOPdzTc1XlAEokgnmizjgIuXOn6yIMAct24r6TIgwQPBMPjP5pN7gtwY1StZXk62N6s1pm7obXLaJYeHGIHNhKbz3YW9hy23hbBOPA4WD406rICIg2NxF7GXccBAo9V46glpncWtTnBbpmItXXJ842gW+NpuHks2mn3evVFw70KRO2z2H/YmZoCBFXzxNbPquaZPaT7i+u8JrUSQz8Sn3XVgmXSzDIqraJxQtKVKx95MyLd1UTwcMeMf4zmsnfdgBjhIIGS3k8B9QlZxDbYhmhL+/FW14gG7zU7lze0lrgXqbH+5LBHyfyg98GzJKOGj9a6b3bvbAJcSl4PxJIpEISHAh57DkN76UPFT0dloUic2GjJ+sRLr7cdJvoUfCJ5pk7i19jhb8pZM09bG/QEJEkOIFH6ZtkT1miGLZzD5tHt9ORuZlq3aWhP2yRuKsA51gCY+d1KJuj636+LsY9Q==
EOT

# Ensure SSH password logins are disabled
echo ">>>> Disabling SSH password logins"
grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null
echo $?
if [ $? ] >0; then
  sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

# Disable SSH root login
echo ">>>> Disabling SSH root login"
grep -q 'PermitRootLogin no' /etc/ssh/sshd_config 2>/dev/null
echo $?
if [ $? ] >0; then
  sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i -e 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
fi

# ----------------
# CONFIGURE NGINX
# ----------------
# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

# Allow access through firewall for Nginx
echo ">>>> Allowing nginx through firewall"
ufw allow 'Nginx Full'

# Make sure our lovely user owns it all
echo ">>>> Creating app directories"
mkdir -p /var/www/$DOMAINNAME/public
mkdir -p /var/www/$DOMAINNAME/content
mkdir -p /var/www/$DOMAINNAME/data
chown -R $DEPLOYUSER:$DEPLOYUSER /var/www/$DOMAINNAME
chmod -R 755 /var/www/$DOMAINNAME

## Add a server block for the site
echo ">>>> Adding nginx server block for $DOMAINNAME"
tee -a /etc/nginx/sites-available/$DOMAINNAME >/dev/null <<EOT
server {
    listen 80;
    listen [::]:80;

    root /var/www/$DOMAINNAME/public;
    index index.html index.htm index.nginx-debian.html;

    server_name $DOMAINNAME $DOMAINALIASES_SPACE_SEPARATED;

    # # ACME-challenge
    # location ^~ /.well-known/acme-challenge/ {
    #   root /var/www/_letsencrypt;
    # }

    location / {

        proxy_pass http://localhost:3000;


        # proxy_set_header HOST $host;
        # proxy_set_header X-Forwarded-Proto $scheme;
        # proxy_set_header X-Real-IP $remote_addr;
        # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # proxy_http_version 1.1;
        

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;

        proxy_http_version                 1.1;
        proxy_cache_bypass                 \$http_upgrade;

        # Proxy headers
        proxy_set_header Upgrade           \$http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host  \$host;
        proxy_set_header X-Forwarded-Port  \$server_port;

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
    location = /favicon.ico {
        log_not_found off;
        access_log    off;
    }

    # # robots.txt
    location = /robots.txt {
        log_not_found off;
        access_log    off;
    }

    # # gzip
    gzip              on;
    gzip_vary         on;
    gzip_proxied      any;
    gzip_comp_level   6;
    gzip_types        text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # # brotli
    # #brotli            on;
    # #brotli_comp_level 6;
    # #brotli_types      text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
}
EOT

# Active the server block
echo ">>>> Activating server block"
ln -s /etc/nginx/sites-available/$DOMAINNAME /etc/nginx/sites-enabled/

# https://gist.github.com/muhammadghazali/6c2b8c80d5528e3118613746e0041263
# sed -i -e 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' /etc/nginx/nginx.conf

# Config okay with nginx?
nginx -t

echo ">>>> Restarting nginx"
systemctl restart nginx

# Activate Certbot for this server block
echo ">>>> Adding certbot LetsEncrypt certificate"
certbot --nginx --noninteractive -d $DOMAINALIASES_COMMA_SEPARATED  --redirect --agree-tos -m charlie@sonniesedge.co.uk

# Renew certbot certificates automatically
echo ">>>> Adding auto-renew for certbot"
systemctl status certbot.timer

echo ">>>> Restarting nginx"
systemctl restart nginx

# ------------------------------------
# INSTALL NODE AND PM2, AND CONFIGURE
# ------------------------------------
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04

echo ">>>> Installing node"

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt-get install -y nodejs

npm install pm2@latest -g

env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $DEPLOYUSER --hp /home/$DEPLOYUSER

# echo ">>>> Switching to $SUDOUSER to activate pm2"
# su - $SUDOUSER
pm2 startup systemd

# pm2 save
