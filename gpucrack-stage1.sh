#! /bin/bash

# Stage 1 v0.2
# 7/22/2021

###start Stage 1###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.2"
echo -e "Jeffrey Cap (Bort-Millipede)"
echo -e "\nStage 1: remove multiarch (32-bit) support from operating system (if enabled), and install all available updates.\n"

if [[ $EUID -ne 0 ]]
then
	echo -e "Error: This script must be executed as root! exiting..." 
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo -e "Error: this script is only compatible with 64-bit systems! exiting..."
	exit 1
fi

if [ ! -f "/etc/debian_version" ]
then
	echo -e "Error: this script is only compatible with Debian-based Linux systems! exiting..."
	exit 1
fi

apt-get -qq install `dpkg --get-selections | grep "install" | cut -f1 | head -n1` >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo -e "Possible error detected in the package manager! Ensure apt/dpkg are working properly and are not in use by other processes, then try executing Stage 1 as root again!"
	exit 1
fi

VERBOSE=0
for var in "$@"
do
	if [ "$var" == "--verbose" ]
	then
		VERBOSE=1
	fi
done

MULTIARCH=`dpkg --print-foreign-architectures`
if [[ ${#MULTIARCH} -ne 0 ]]
then
	for a in $MULTIARCH
	do
		dpkg --remove-architecture "$a" > /dev/null 2>&1
	done
	echo -e "Multiarch support removed!"
else
	echo -e "Multiarch support not enabled, so nothing to remove!"
fi

echo -e "\nUpdating system..."
if [ $VERBOSE -eq 1 ]
then
	apt-get update -y
	apt-get full-upgrade -y
else
	apt-get update -y -qq 
	apt-get full-upgrade -y -qq
fi
sync

echo -en "\n"
if [[ ${#MULTIARCH} -ne 0 ]]
then
	echo -en "32-bit support removed and "
fi
echo -e "System updated!"
echo -e "Stage 1 completed successfully! Please reboot and execute Stage 2 as root.\n"
unset MULTIARCH
unset VERBOSE
###end Stage 1###

