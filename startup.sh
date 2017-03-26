#!/bin/bash

# Variables
HOSTNAME=$1
USER=alex
HOMEIP=64.121.113.10

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
apt-get -y update && apt-get -y upgrade

# TODO - uncomment '# precedence ::ffff:0:0/96 100' in /etc/gai.conf

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

# install our vnc server and window manager
apt-get install -y vnc4server
apt-get install -y xfce4 


# install java
apt-get install -y software-properties-common python-software-properties # so we can actually add-apt-repository
apt-get install -y git
add-apt-repository ppa:webupd8team/java
apt-get update
# can't autoinstall, there's a GUI :<
apt-get install oracle-java8-installer

mkdir -p /home/$USER/.vnc
rm /home/$USER/.vnc/xstartup
ln -s /etc/X11/xinit/xinitrc /home/$USER/.vnc/xstartup
chmod 755 /home/$USER/.vnc/xstartup
chown -R $USER:$USER /home/$USER

vncserver -localhost :1
