#! /bin/bash

# Stage 1 v0.1.2
# 12/7/2018

###start stage 1###
echo -e "GPU Password Cracking Builder (NVIDIA only) v0.1.2"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 1: remove multiarch (32-bit) support from operating system and install all available updates.\n"

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be executed as root! exiting..." 
   exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo "Error: this script is only compatible with 64-bit Debian-based Linux systems! exiting..."
	exit 1
fi

dpkg --remove-architecture i386 > /dev/null 2>&1
apt install -y aptitude
aptitude -y update
aptitude -y full-upgrade
sync
echo -e "\n32-bit support removed and system updated!"
echo -e "Stage 1 completed successfully! Please reboot and execute Stage 2 as root."
###end stage 1###

