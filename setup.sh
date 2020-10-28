#!/bin/bash

sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx HTTP'

sudo mkdir -p /var/www/whalecoiner.com/html
sudo chown -R $USER:$USER /var/www/whalecoiner.com/html
sudo chmod -R 755 /var/www/whalecoiner.com
