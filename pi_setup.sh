#!/bin/bash

#
#
# Make sure the permissions for this folder are 700 and $USER is the owner
#
#

###########################################

# Script to build Pis

###########################################

#
# User acct, hostname, & timezone
#

# Set locale & timezone
update-locale LANG=en_GB.UTF-8 LC_MESSAGES=POSIX
timedatectl set-timezone America/Chicago

# Ask for hostname
read -p "Enter new hostname: " new_hostname

# Set hostname
hostnamectl set-hostname $new_hostname
echo "127.0.1.1 $new_hostname" >> /etc/hosts

# Ask for username
read -p "Enter new username: " new_user

# Set username
adduser $new_user

# Add new user to sudo
usermod -aG sudo $new_user

#
# apt update/upgrade & cronjob
#

# Update packages now
apt update
apt upgrade -y
apt autoremove -y

# Create cronjob for apt update/upgrade and autoremove unused packages
cp ./apt-upgrade.sh /usr/local/bin
chown $new_user /usr/local/bin/apt-upgrade.sh
chmod +x /usr/local/bin/apt-upgrade.sh
echo "0 3 * * 3 root /usr/local/bin/apt-upgrade.sh >> /var/log/apt/automaticupdates.log" >> /etc/crontab

#
# SSH config
#

# Prompt to create SSH on remote hostname
echo "Create SSH key pair on remote PC (ie: your Windows machine)"

# Move SSH pubkey to Pi

#
# Lock down SSH permissions
#

# RootLogin
sed -i -e "/PermitRootLogin/s/yes/no/" /etc/ssh/sshd_config
sed -i -e "/#PermitRootLogin/s/#//"

# PubKey Auth
sed -i -e "/PubkeyAuthentication/s/no/yes/" /etc/ssh/sshd_config
sed -i -e "/#PubkeyAuthentication/s/#//"

# PW Auth
sed -i -e "/PasswordAuthentication/s/no/yes/" /etc/ssh/sshd_config
sed -i -e "/#PasswordAuthentication/s/#//"

# GSSAPIAuthentication = yes
sed -i -e "/GSSAPIAuthentication/s/no/yes/" /etc/ssh/sshd_config
sed -i -e "/^GSSAPIAuthentication/s/GSSAPIAuthentication/#GSSAPIAuthentication/"

# GSSAPICleanupCredentials = no
sed -i -e "/GSSAPICleanupCredentials/s/yes/no/" /etc/ssh/sshd_config
sed -i -e "/^GSSAPICleanupCredentials/s/GSSAPIAuthentication/#GSSAPIAuthentication/"

# UsePAM
sed -i -e "/UsePAM/s/no/yes/" /etc/ssh/sshd_config
sed -i -e "/#UsePAM/s/#//"


#
# Docker
#

# Install Docker; install_docker.sh script will add user to Docker group
./install_docker.sh

# Create cronjob to auto-update containers
# Create cronjob to auto-prune containers/images

#
# Folder structure
#

# Build folder/file structure as follows
# /
#   |—dockerdata
#     |—certs
#     |—compose
#       |—docker-compose.yaml
#       |—secrets
#       |—dev
#         |—docker-compose.dev.yaml
# chown on above folders
# chmod 755 on above folders

#
# NFS shares
#

# Prompt for NFS shares to be created on remote system
# Build folders locally for NFS to mount
# Apply folder permissions
# Mount NFS in /etc/fstab

# Delete ubuntu account