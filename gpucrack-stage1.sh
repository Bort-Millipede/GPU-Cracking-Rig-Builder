#! /bin/bash

# Stage 1 v0.1
# 4/8/2017

###start stage 1###
echo -e "GPU Password Cracking Builder (NVIDIA only) v0.1"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 1: remove multiarch (32-bit) support from operating system and install all available updates.\n"

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root! exiting..." 
   exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo "Error: this script is only compatible with 64-bit Debian-based Linux systems! exiting..."
	exit 1
fi

dpkg --remove-architecture i386 > /dev/null 2>&1
apt-get install -y aptitude
aptitude -y update
aptitude -y full-upgrade
sync
echo -e "\nStage 1 complete, 32-bit support removed and system updated! Please reboot and execute stage 2 as root"
###end stage 1###
