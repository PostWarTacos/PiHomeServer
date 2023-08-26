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
read -p "Upgrading installed packages. Press enter to continue." useless_answer
apt update
apt upgrade -y
apt autoremove -y

# Create cronjob for apt update/upgrade and autoremove unused packages
read -p "Creating cronjob to auto-upgrade installed packages. Press enter to continue." useless_answer
cp ./apt_upgrade.sh /usr/local/bin
chown $new_user /usr/local/bin/apt_upgrade.sh
chmod +x /usr/local/bin/apt_upgrade.sh
echo "0 3 * * 3 root /usr/local/bin/apt_upgrade.sh >> /var/log/apt/auto_apt_updates.log" >> /etc/crontab

#
# SSH config
#

# Prompt to create SSH on remote hostname
read -p "This step will create an SSH key pair for user to access server without password, so long as the remote PC has the private key. Do you wish to complete this step? (y/n) " ssh_answer
if [ $ssh_answer == 'y' ] || [ $ssh_answer == 'Y' ]; then

  export $new_user

  read -p "User must create SSH key pair on remote PC. Suggest using pubkey_create_win.ps1 (if remote PC is Windows) or pubkey_create_nix.sh (if remote PC is *nix) found on https://github.dev/PostWarTacos/PiHomeServer. Press enter when action is completed." useless_answer

  # Move SSH pubkey to Pi. Done from remote PC with pubkey_create script

  #
  # Lock down SSH permissions
  #

  # RootLogin
  sed -i -e "/PermitRootLogin/s/yes/no/" /etc/ssh/sshd_config
  sed -i -e "/#PermitRootLogin/s/#//" /etc/ssh/sshd_config

  # PubKey Auth
  sed -i -e "/PubkeyAuthentication/s/no/yes/" /etc/ssh/sshd_config
  sed -i -e "/#PubkeyAuthentication/s/#//" /etc/ssh/sshd_config

  # PW Auth
  sed -i -e "/PasswordAuthentication/s/no/yes/" /etc/ssh/sshd_config
  sed -i -e "/#PasswordAuthentication/s/#//" /etc/ssh/sshd_config

  # GSSAPIAuthentication = yes
  sed -i -e "/GSSAPIAuthentication/s/no/yes/" /etc/ssh/sshd_config
  sed -i -e "/^GSSAPIAuthentication/s/GSSAPIAuthentication/#GSSAPIAuthentication/" /etc/ssh/sshd_config

  # GSSAPICleanupCredentials = no
  sed -i -e "/GSSAPICleanupCredentials/s/yes/no/" /etc/ssh/sshd_config
  sed -i -e "/^GSSAPICleanupCredentials/s/GSSAPIAuthentication/#GSSAPIAuthentication/" /etc/ssh/sshd_config

  # UsePAM
  sed -i -e "/UsePAM/s/no/yes/" /etc/ssh/sshd_config
  sed -i -e "/#UsePAM/s/#//" /etc/ssh/sshd_config
fi

#
# Docker
#

# Install Docker; install_docker.sh script will add user to Docker group
read -p "Installing Docker. Press enter to continue." useless_answer
./install_docker.sh

# Create cronjob to auto-update containers & to auto-prune containers/images
read -p "Creating cronjob to auto-update containers and auto-prune unused containers and images. Press enter to continue." useless_answer
cp ./upgrade_containers.sh /usr/local/bin
chown $new_user /usr/local/bin/upgrade_containers.sh
chmod +x /usr/local/bin/upgrade_containers.sh
echo "0 */3 * * * root /usr/local/bin/upgrade_containers.sh >> /var/log/apt/auto_container_updates.log" >> /etc/crontab

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

read -p "Building Docker folder structure. Press enter to continue." useless_answer

mkdir -p /dockerdata/certs
mkdir -p /dockerdata/compose/secrets
mkdir -p /dockerdata/compose/dev
touch /dockerdata/compose/docker-compose.yaml
touch /dockerdata/compose/dev/docker-compose.dev.yaml
chown $new_user -R /dockerdata
chmod 755 -R /dockerdata

#
# NFS shares
#

read -p "This step will create an NFS share on remote and connect to it. Do you wish to complete this step? (y/n) " nfs_answer
if [ $nfs_answer == 'y' ] || [ $nfs_answer == 'Y' ]; then
  # Prompt for NFS shares to be created on remote system
  read -p "User must create NFS shares on remote PC. Press enter when action is completed." useless_answer
  echo "Installing NFS utilities"
  apt install nfs-common
  read -p "Enter IP address of remote PC: " remote_ip
  read -p "Enter full path of the NFS share created on remote PC (/volume1/Plex): " remote_nfs

  # Build folders locally for NFS to mount
  read -p "Creating local folder for NFS share. Enter folder name that will be locally accessible and connected to the NFS share on remote PC (ex: /Plex): " local_nfs
  mkdir $local_nfs

  # Apply folder permissions
  chown $new_user -R $local_nfs
  chmod 755 -R $local_nfs

  # Mount NFS in /etc/fstab
  # <file system>                       <dir>           <type>  <options>       <dump>  <pass>
  chown $USER /etc/fstab
  echo "$remote_ip:$remote_nfs          $local_nfs      nfs     defaults        0       0" >> /etc/fstab
  chown root /etc/fstab
  echo "NFS share should appear at $local_nfs after reboot "
fi

# Manually delete ubuntu account after logging to $new_user
read -p "PiHomeServer setup is complete. Please manually delete the default ubuntu account. Host requires reboot. Do you wish to reboot now? (y/n) " reboot_answer
if [ $reboot_answer == 'y' ] || [ $reboot_answer == 'Y' ]; then
    reboot
fi
