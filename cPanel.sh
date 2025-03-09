#!/bin/bash
clear

setenforce 0 >> /dev/null 2>&1

# Flush the IP Tables
#iptables -F >> /dev/null 2>&1
#iptables -P INPUT ACCEPT >> /dev/null 2>&1

LOG=/root/cpanel.log

echo "-----------------------------------------------"
echo " Welcome to cPanel Installer"
echo "-----------------------------------------------"
echo "To monitor installation : tail -f /root/cpanel.log"
echo " "

#----------------------------------
# Some checks before we proceed
#----------------------------------

# Gets Distro type.
if [ -f /etc/debian_version ]; then	
	OS_ACTUAL=$(lsb_release -i | cut -f2)
	OS=Ubuntu
	REL=$(cat /etc/issue)
elif [ -f /etc/redhat-release ]; then
	OS=redhat 
	REL=$(cat /etc/redhat-release)
else
	OS=$(uname -s)
	REL=$(uname -r)
fi

if [[ "$REL" == *"CentOS release 6"* ]] || [[ "$REL" == *"CentOS Linux release 7"* ]] || [[ "$REL" == *"CentOS Linux release 8"* ]] || [[ "$REL" == *"CentOS Stream release 8"* ]] || [[ "$REL" == *"CentOS Stream release 9"* ]]; then
        echo "cPanel only supports AlmaLinux 8,9 , CloudLinux 8,9 and  Rocky Linux 8,9"
        echo "Exiting installer"
        exit 1;
fi

if [ "$OS" = Ubuntu ] ; then

	# We dont need to check for Debian
	if [ "$OS_ACTUAL" = Ubuntu ] ; then
	
		VER=$(lsb_release -r | cut -f2)
		
		if  [ "$VER" != "22.04" ]; then
			echo "cPanel only support Ubuntu 22.04 LTS"
			echo "Exiting installer"
			exit 1;
		fi

		if ! [ -f /etc/default/grub ] ; then
			echo "cPanel only supports GRUB 2 for Ubuntu based server"
			echo "Follow the Below guide to upgrade to grub2 :-"
			echo "https://help.ubuntu.com/community/Grub2/Upgrading"
			echo "Exiting installer"
			exit 1;
		fi
		
	fi
	
fi

theos="$(echo $REL | egrep -i '(Ubuntu|AlmaLinux|Rocky)' )"

if [ "$?" -ne "0" ]; then
	echo "cPanel can be installed only on AlmaLinux, Rocky Linux, CloudLinux and Ubuntu"
	echo "Exiting installer"
	exit 1;
fi

#----------------------------------
# Check Repo
#----------------------------------
if [ "$OS" = redhat ] ; then

	# Is yum there ?
	if ! [ -f /usr/bin/yum ] ; then
		echo "YUM wasnt found on the system. Please install YUM !"
		echo "Exiting installer"
		exit 1;
	fi

	# Check if the /etc/selinux/config file exists
	if [ -f /etc/selinux/config ]; then
		# Disable SELinux by changing the config
		sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
		echo "SELinux has been disabled."
		echo "SELinux has been disabled." >> $LOG 2>&1
	fi

	# Check if EPEL repository is installed
	if ! rpm -q epel-release > /dev/null 2>&1; then
		echo "EPEL repository is not installed. Installing..."
		echo "EPEL repository is not installed. Installing..." >> $LOG 2>&1

		# Install EPEL repository
		yum -y install epel-release >> $LOG 2>&1
		echo "EPEL repository is installed."
		echo "EPEL repository is installed." >> $LOG 2>&1

		# Edit EPEL repository
		sed -i 's,#baseurl,baseurl,g' /etc/yum.repos.d/epel.repo
		sed -i 's,download.example/pub/epel,epel.mobinhost.com,g' /etc/yum.repos.d/epel.repo
		sed -i 's,metalink,#metalink,g' /etc/yum.repos.d/epel.repo
		echo "Edit EPEL repository."
		echo "Edit EPEL repository." >> $LOG 2>&1

		# Update EPEL repository
		yum -y update epel-release >> $LOG 2>&1
		echo "EPEL repository is Updated."
		echo "EPEL repository is Updated." >> $LOG 2>&1

		# Disable cisco-openh264 EPEL repository
		if grep -q "enabled=1" /etc/yum.repos.d/epel-cisco-openh264.repo; then
			sed -i 's,enabled=1,enabled=0,g' /etc/yum.repos.d/epel-cisco-openh264.repo
			echo "Disable cisco-openh264 EPEL repository."
			echo "Disable cisco-openh264 EPEL repository." >> $LOG 2>&1
		fi
	else
		echo "EPEL repository is already installed."

		# Disable cisco-openh264 EPEL repository
		if grep -q "enabled=1" /etc/yum.repos.d/epel-cisco-openh264.repo; then
			sed -i 's,enabled=1,enabled=0,g' /etc/yum.repos.d/epel-cisco-openh264.repo
			echo "Disable cisco-openh264 EPEL repository."
			echo "Disable cisco-openh264 EPEL repository." >> $LOG 2>&1
		fi
	fi

	# Get the Network version
	NetworkVersion=$(grep -oP '(?<=VERSION_ID=")[^"]+' /etc/os-release)

	# Check the version
	if [[ "$NetworkVersion" == 8* ]]; then
		# Check NetworkManager
		NetworkStatus=$(systemctl is-active NetworkManager)
		if [[ "$NetworkStatus" == "active" ]]; then
			yum -y install initscripts ipcalc bc
			yum -y install network-scripts --enablerepo=powertools
			systemctl --now disable NetworkManager
			systemctl enable network.service
			systemctl restart network.service
			echo "Network is fixed."
			echo "Network is fixed." >> $LOG 2>&1
		else
			echo "Error: Service is not active!"
			echo "Error: Service is not active!" >> $LOG 2>&1
		fi
	elif [[ "$NetworkVersion" == 9* ]]; then
		yum -y install almalinux-release-devel
		sed -i 's,enabled=1,enabled=0,g' /etc/yum.repos.d/almalinux-devel.repo
		yum -y install initscripts ipcalc bc
		yum -y install network-scripts --enablerepo=devel
		systemctl --now disable NetworkManager
		systemctl enable network.service
		systemctl restart network.service
		echo "Network is fixed."
		echo "Network is fixed." >> $LOG 2>&1
	fi

	# Install need Packages
	yum -y install screen wget nano mlocate zip unzip bzip2 htop nload tcpdump mtr telnet traceroute git chrony
	echo "Install need Packages is Done."
	echo "Install need Packages is Done." >> $LOG 2>&1
fi

#----------------------------------
# Fix for AlamLinux GPG key
# https://almalinux.org/blog/2023-12-20-almalinux-8-key-update/
#----------------------------------
is_alma="$(echo $REL | egrep -i '(AlmaLinux)' )"
if [ "$?" -eq "0" ]; then
	is_it_alma8=$(rpm -E %{rhel})
	if [ $is_it_alma8 -eq 8 ]; then
		is_valid_gpg=$(rpm -q gpg-pubkey-ced7258b-6525146f)
		#If the key is not same then we will need to import it
		if [ "$is_valid_gpg" != "gpg-pubkey-ced7258b-6525146f" ]; then
			rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
		fi
	fi
fi

#----------------------------------
# Download and Install cPanel
#----------------------------------
echo "3) Downloading and Installing cPanel"
echo "3) Downloading and Installing cPanel" >> $LOG 2>&1

mkdir /root/cpanel_profile
touch /root/cpanel_profile/cpanel.config
echo "mysql-version=11.4" > /root/cpanel_profile/cpanel.config

echo "HTTPUPDATE=httpupdate.mobinhost.com" > /etc/cpsources.conf

echo "87.107.110.110 dl.fedoraproject.org" >> /etc/hosts

wget -O /home/latest https://securedownloads.cpanel.net/latest
chmod +x /home/latest
sh /home/latest

#----------------------------------
# Installation Completed
#----------------------------------
echo "Installation Completed"
echo "Installation Completed" >> $LOG 2>&1

ip=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
clear
echo '       ____                  _ '
echo '   ___|  _ \ __ _ _ __   ___| |'
echo '  / __| |_) / _` | '\''_ \ / _ \ |'
echo ' | (__|  __/ (_| | | | |  __/ |'
echo '  \___|_|   \__,_|_| |_|\___|_|'
echo '                                '
echo "Congratulations, cPanel has been successfully installed"
echo " "
echo " "
echo "You can login to the cPanel"
echo "using your ROOT details at the following URL :"
echo "WHM (https): https://$ip:2087/"
echo "OR"
echo "WHM (https): https://$ip:2086/"
echo " "
echo "You will need to reboot this machine to load the correct kernel"
echo -n "Do you want to reboot now ? [y/N]"
read rebBOOT

echo "Thank you for choosing cPanel"

if ([ "$rebBOOT" == "Y" ] || [ "$rebBOOT" == "y" ]); then	
	echo "The system is now being RESTARTED"
	reboot;
fi
