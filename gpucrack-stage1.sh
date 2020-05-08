#! /bin/bash

# Stage 1 v0.2
# 5/X/2020

###start stage 1###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.1.2"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 1: remove multiarch (32-bit) support from operating system (if enabled), and install all available updates.\n"

if [[ $EUID -ne 0 ]]
then
	echo "Error: This script must be executed as root! exiting..." 
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo "Error: this script is only compatible with 64-bit systems! exiting..."
	exit 1
fi

if [ ! -f "/etc/debian_version" ]
then
	echo "Error: this script is only compatible with Debian-based Linux systems! exiting..."
	exit 1
fi

MULTIARCH=`dpkg --print-foreign-architectures`
if [[ ${#MULTIARCH} -ne 0 ]]
then
	for a in $MULTIARCH
	do
		dpkg --remove-architecture "$a" > /dev/null 2>&1
	done
fi
apt -y update
apt -y full-upgrade
sync

echo -en "\n"
if [[ ${#MULTIARCH} -ne 0 ]]
then
	echo -en "32-bit support removed and "
fi
echo -e "System updated!"
echo -e "Stage 1 completed successfully! Please reboot and execute Stage 2 as root."
###end stage 1###

