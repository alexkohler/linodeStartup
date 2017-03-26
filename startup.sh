#!/bin/bash

# Variables
HOSTNAME=$1
USER=alex
HOMEIP=$2

if [ -z "${HOSTNAME}" ]; then
    echo "hostname not set"
	exit 1
fi

if [ -z "${USER}" ]; then
    echo "user not set"
	exit 1
fi

if [ -z "${HOMEIP}" ]; then
    echo "home IP not set"
	exit 1
fi

# update debian
export DEBIAN_FRONTEND=noninteractive # don't bother me with prompts
export APT_LISTCHANGES_FRONTEND=none
# in case ipv6 is misbehaving while we update 
sed -i "s/# precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
apt-get -y update && apt-get -y upgrade

# Update hostname
sed -i "s/debian/$HOSTNAME/g" /etc/hosts
hostnamectl set-hostname $HOSTNAME

# set timezone - not really required, we'll just be in UTC, I'd rather not navigate through the GUI if I don't have to :)
# dpkg-reconfigure tzdata

# User creation
apt-get install sudo
adduser $USER
adduser $USER sudo

# SECURING DA SERVER 
# disable root login via ssh
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# listen to ssh connections only over ipv4
echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config

# sync our changes
systemctl restart sshd

# install fail2ban
apt-get install -y fail2ban

# create local jail
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# whitelist our home IP.
sed -i "s/ignoreip = 127.0.0.1\/8/ignoreip = 127.0.0.1\/8 $HOMEIP/" /etc/fail2ban/jail.local

# rest of the default configuration is good enough. Onward!

# install some goodies
apt-get install -y vnc4server
apt-get install -y xfce4 
apt-get install -y git
apt-get install -y midori

# install java
echo -e 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main\ndeb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main\n' > test
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
apt-get update
# can't autoinstall, there's a GUI :<
apt-get install oracle-java8-installer

su alex
vncserver -localhost :1
