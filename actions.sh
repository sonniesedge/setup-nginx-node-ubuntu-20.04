#!/bin/bash

HOSTNAME=whalecoiner
DOMAINNAME=whalecoiner.com
DOMAINALIASES=(www.whalecoiner.com whalecoiner.net www.whalecoiner.net whalecoiner.org www.whalecoiner.org)
EMAILADDRESS=charlie@sonniesedge.co.uk
SETUPLOG=/var/log/serversetup.log

DOMAINALIASES_COMMA_SEPARATED=$(printf '%s,' "${DOMAINALIASES[@]}")
DOMAINALIASES_COMMA_SEPARATED="${DOMAINALIASES_COMMA_SEPARATED%,}"
DOMAINALIASES_SPACE_SEPARATED=$(printf '%s ' "${DOMAINALIASES[@]}")
DOMAINALIASES_SPACE_SEPARATED="${DOMAINALIASES_SPACE_SEPARATED% }"

DEPLOYUSER=deploy
SUDOUSER=charlie

log ()
{
echo "$(date "+%m%d%Y %T"): $1" >> $SETUPLOG
}

log "-------------------------"
log "| CONFIG"
log "-------------------------"
log "DOMAINNAME: $DOMAINNAME"
log "DOMAINALIASES: ${DOMAINALIASES[@]}"
log "DOMAINALIASES_COMMA_SEPARATED: $DOMAINALIASES_COMMA_SEPARATED"
log "DOMAINALIASES_SPACE_SEPARATED: $DOMAINALIASES_SPACE_SEPARATED"
log "DEPLOYUSER: $DEPLOYUSER"
log "SUDOUSER: $SUDOUSER"

# -------------------------------
# CREATE USERS AND CONFIGURE SSH
# -------------------------------
# https://askubuntu.com/questions/94060/run-adduser-non-interactively

# Deploy user
log "Creating $DEPLOYUSER"

adduser --gecos "" --disabled-password $DEPLOYUSER
# --gecos is for skipping the "Full name,Room number,Work phone,Home phone" stuff when creating a new user
# https://en.wikipedia.org/wiki/Gecos_field for the history buffs
mkdir -p /home/$DEPLOYUSER/.ssh
touch /home/$DEPLOYUSER/.ssh/authorized_keys
chown -R $DEPLOYUSER:$DEPLOYUSER /home/$DEPLOYUSER/.ssh
chmod 700 /home/$DEPLOYUSER/.ssh
chmod 644 /home/$DEPLOYUSER/.ssh/authorized_keys

cat <<EOT >> /etc/sshd_config
ClientAliveInterval 120
ClientAliveCountMax 720
EOT

cat <<EOT >>/home/$DEPLOYUSER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyJ7K96iFzBFADuS71quXKmcoguMhypW8GiEwQ8e16limTbFpQOxl6aGnlHBqjk3FrwtR8k5t3L3e+HzFbF+wpQEjAUHJn8AshJBrQYzT7mFlMx2fUhUU1H6KxrcEwK1TGsUjxWQn2+fLRL0ZAl5zwSfqAVMIQhZcE/7ADZkaShZMfFDFmW3Gtqp+UCCBHfFcGKIQy+fvJguNds67MuRh2fJwxEu0E7iv74wG2O937oUPSUxP36azGJ7l3nZz2smKogVhpiOlKfXm6PoBeqleTRhfw+aoWoZ5LUWeLkr+4gB59p8XsfyJJoW9CtP6MZMtjOlxv/7GYRWlv+bekVM2fF1ek/Csw0EjtgjlQohaWhW4EklnJ5fNtR0NVMR4L9Bn2ll73mbwf+/4Rx/CD+pffdYV0YTws7M/z32qbUc+IHOSbHGeFhnNCMbk8I4rLgm7/sNvtb3uF7S9Y8Ewe012LvCSCPwrVuHMobKGbJt2F7ZeOlk3Uf+oG0iRTEU7Ngmq8EofrMubhSFUjcC4KzhlUSu/fniAsFJPk2zVyPtU205NwdyWEY7+RCyvwwHHV0yMuhbBc99eUUKpBQI94PaZfAicCsLQSVN9ldQ5vvh7CKJrUJRfq2yCmmRG0EhmSjpB8YUcgT9RdM7kD+76BG0MLMv4ThDNnuCLSnMHnTjMP7w==
EOT

# Sudo user
log "Creating $SUDOUSER" >> $SETUPLOG
# TODO: supply encrypted password for this user
# adduser --gecos "" --disabled-password $SUDOUSER
useradd -m $SUDOUSER -p '$1$cPANTVBa$766MM8lsGv/W3MeLRoWrj0' -s /bin/bash 
usermod -aG sudo $SUDOUSER
mkdir -p /home/$SUDOUSER/.ssh
touch /home/$SUDOUSER/.ssh/authorized_keys
chown -R $SUDOUSER:$SUDOUSER /home/$SUDOUSER/.ssh
chmod 700 /home/$SUDOUSER/.ssh
chmod 644 /home/$SUDOUSER/.ssh/authorized_keys

cat <<EOT >>/home/$SUDOUSER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1SuXSEyv07abIrcbkw/U7uhgJdTsIffiG7XOLIgELG6KphYsIlC/lnoq5P0xj9oZ7W28zX+qIkg/PUSMQS3uJpynBS1y43v51Eac6SzhtH56SrAhMDfVJTclMaUAIMnTb0lN/vhD6w6bsz95AoWwInHja/4J3a1aso0qWwdyrLFZ8Y5vDLokn27EdKuqZAPfzk3VIF+zh1OXnnP3XeeTsAqzVOPdzTc1XlAEokgnmizjgIuXOn6yIMAct24r6TIgwQPBMPjP5pN7gtwY1StZXk62N6s1pm7obXLaJYeHGIHNhKbz3YW9hy23hbBOPA4WD406rICIg2NxF7GXccBAo9V46glpncWtTnBbpmItXXJ842gW+NpuHks2mn3evVFw70KRO2z2H/YmZoCBFXzxNbPquaZPaT7i+u8JrUSQz8Sn3XVgmXSzDIqraJxQtKVKx95MyLd1UTwcMeMf4zmsnfdgBjhIIGS3k8B9QlZxDbYhmhL+/FW14gG7zU7lze0lrgXqbH+5LBHyfyg98GzJKOGj9a6b3bvbAJcSl4PxJIpEISHAh57DkN76UPFT0dloUic2GjJ+sRLr7cdJvoUfCJ5pk7i19jhb8pZM09bG/QEJEkOIFH6ZtkT1miGLZzD5tHt9ORuZlq3aWhP2yRuKsA51gCY+d1KJuj636+LsY9Q==
EOT

# Ensure SSH password logins are disabled
log "Disabling SSH password logins"
grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null
echo $?
if [ $? ] >0; then
  sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

# Disable SSH root login
log "Disabling SSH root login"
grep -q 'PermitRootLogin no' /etc/ssh/sshd_config 2>/dev/null
echo $?
if [ $? ] >0; then
  sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i -e 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
fi

log "Updating local apt data"
apt-get -qq update

# log "Installing nginx"
# apt-get install nginx  -y 2>> $SETUPLOG
# log "Installing certbot"
# apt-get install certbot  -y 2>> $SETUPLOG
# log "Installing python3-certbot-nginx"
# apt-get install python3-certbot-nginx  -y 2>> $SETUPLOG
# log "Installing build-essential"
# apt-get install build-essential  -y 2>> $SETUPLOG
# log "Installing libssl-dev"
# apt-get install libssl-dev  -y 2>> $SETUPLOG
# log "Installing whois"
# apt-get install whois  -y 2>> $SETUPLOG
# log "Installing unattended-upgrades"
# apt-get install unattended-upgrades  -y 2>> $SETUPLOG
# log "Installing mailutils"
# apt-get install mailutils -y 2>> $SETUPLOG

debconf-set-selections <<< "postfix postfix/mailname string $DOMAINNAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install nginx certbot python3-certbot-nginx build-essential libssl-dev whois unattended-upgrades mailutils -y

# Setup unattended security upgrades
log "Setting up unattended upgrades"

cat <<EOT > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        // "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
        "${distro_id}ESMApps:${distro_codename}-apps-security";
        "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Mail "$EMAILADDRESS";
Unattended-Upgrade::MailReport "always";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
EOT


cat <<EOT > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOT



# ----------------
# CONFIGURE NGINX
# ----------------
# https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04

# Allow access through firewall for Nginx
log "Allowing nginx through firewall"
ufw allow 'Nginx Full'

# Make sure our lovely user owns it all
log "Creating app directories"
mkdir -p /var/www/$DOMAINNAME/public
mkdir -p /var/www/$DOMAINNAME/content
mkdir -p /var/www/$DOMAINNAME/data
chown -R $DEPLOYUSER:$DEPLOYUSER /var/www/$DOMAINNAME
chmod -R 755 /var/www/$DOMAINNAME

## Add a server block for the site
log "Adding nginx server block for $DOMAINNAME"
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
log "Activating server block"
ln -s /etc/nginx/sites-available/$DOMAINNAME /etc/nginx/sites-enabled/

# https://gist.github.com/muhammadghazali/6c2b8c80d5528e3118613746e0041263
# sed -i -e 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' /etc/nginx/nginx.conf

# Config okay with nginx?
nginx -t

log "Restarting nginx"
systemctl restart nginx

# # Activate Certbot for this server block
# log "Adding certbot LetsEncrypt certificate"
# certbot --nginx --noninteractive -d $DOMAINALIASES_COMMA_SEPARATED  --redirect --agree-tos -m charlie@sonniesedge.co.uk

# # Renew certbot certificates automatically
# log "Adding auto-renew for certbot"
# systemctl status certbot.timer

# log "Restarting nginx"
# systemctl restart nginx




# ------------------------------------
# SETUP EMAIL 
# ------------------------------------
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-20-04

# Use DigitalOcean droplet API to get the real public IP address
echo "$(curl http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address) $DOMAINNAME $HOSTNAME" >> /etc/hosts

echo "$HOSTNAME" >> /etc/hostname

cat <<EOT > /etc/postfix/main.cf
# See /usr/share/postfix/main.cf.dist for a commented, more complete version
# myorigin=/etc/mailname

smtpd_banner = \$myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# TLS parameters
# smtpd_tls_cert_file=/etc/letsencrypt/live/$DOMAINNAME/fullchain.pem
# smtpd_tls_key_file=/etc/letsencrypt/live/$DOMAINNAME/privkey.pem
smtpd_tls_security_level=may

smtp_tls_CApath=/etc/ssl/certs
smtp_tls_security_level=may
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
# myhostname = /etc/hostname
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = localhost.\$mydomain, localhost, \$myhostname
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = all
EOT

# Restart Postfix
systemctl restart postfix

# Forward all root email to $EMAILADDRESS
echo "postmaster: $EMAILADDRESS" > /etc/aliases
newaliases








# ------------------------------------
# INSTALL NODE AND PM2, AND CONFIGURE
# ------------------------------------
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04

log "Installing node"

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt-get install -y nodejs

npm install pm2@latest -g

env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $DEPLOYUSER --hp /home/$DEPLOYUSER

log "Switching to $SUDOUSER to activate pm2"
su - $SUDOUSER
pm2 startup systemd

echo "Just to let you know that the Droplet was destroyed and rebuilt using the build script." | mail -s "Rebuild alert" $EMAILADDRESS

# pm2 save
