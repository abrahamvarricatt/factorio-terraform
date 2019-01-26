#!/bin/bash

apt update
apt install git
touch /var/lib/cloud/instance/locale-check.skip

# user setup
adduser --disabled-password --gecos '' factorio
cd /opt
chgrp -R factorio .
chmod g+w .

# download
sudo su - factorio -c "cd /opt && git clone https://github.com/Bisa/factorio-init.git"
# cd /opt
# git clone https://github.com/Bisa/factorio-init.git
sudo su - factorio -c "cd /opt/factorio-init/ && cp config.example config"
# cd /opt/factorio-init/
# cp config.example config
sudo su - factorio -c "cd ~ && cp /tmp/factorio_headless_x64_0.16.51.tar.xz ."
# cd ~
# wget -O factorio_headless_x64_0.16.51.tar.xz  https://www.factorio.com/get-download/0.16.51/headless/linux64

# installation
sudo su - factorio -c "cd ~ && /opt/factorio-init/factorio install /home/factorio/factorio_headless_x64_0.16.51.tar.xz"
# /opt/factorio-init/factorio install /home/factorio/factorio_headless_x64_0.16.51.tar.xz

# settings copy
sudo su - factorio -c "cp /tmp/server-settings.json /opt/factorio/data/server-settings.json"
# cd /opt/factorio/data
# cp server-settings.example.json server-settings.json

# copy over save file to use
sudo su - factorio -c "cp /tmp/server-save.zip /opt/factorio/saves/server-save.zip"

# start factorio background service
cp /opt/factorio-init/factorio.service.example /etc/systemd/system/factorio.service
systemctl daemon-reload
systemctl start factorio
systemctl enable factorio
