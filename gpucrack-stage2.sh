#! /bin/bash

# Stage 2 v0.2
# 5/X/2020

###start stage 2###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.1.2"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 2: install NVIDIA driver prerequisites, remove all currently installed nvidia packages, and install NVIDIA drivers OR blacklist Nouveau drivers\n"

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

ORIG_DIR=`pwd`
TMP_DIR="$ORIG_DIR/gpucrack-tmp"
mkdir -p $TMP_DIR

apt install -y build-essential linux-headers-$(uname -r) wget

apt remove --purge -y nvidia* >&/dev/null

VER=`wget -q -O - https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt | cut -d" " -f 1`

if [ ! -e "$TMP_DIR/NVIDIA" ]
then
	wget https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run -O $TMP_DIR/NVIDIA
fi

cd $TMP_DIR
chmod +x ./NVIDIA

./NVIDIA --accept-license --disable-nouveau --no-questions --silent
if [ $? -eq 2 ]
then
	rm NVIDIA
	echo -e "\nBad checksum for downloaded NVIDIA installer! Please re-execute Stage 2 as root to re-download NVIDIA installer."
	echo -e "Alternatively, download the NVIDIA installer manually with the following command before re-executing Stage 2 as root:"
	echo -e "\twget https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run -O $TMP_DIR/NVIDIA"
	cd $ORIG_DIR
	unset VER
	unset TMP_DIR
	unset ORIG_DIR
	exit 2
fi

cd $ORIG_DIR

modinfo nvidia > /dev/null 2>&1
if [ $? -ne 0 ]
then
	if [ -f /etc/modprobe.d/nvidia-installer-disable-nouveau.conf ]
	then
		update-initramfs -u
		echo -e "\nNouveau drivers blacklisted successfully! The following Errors displayed by the NVIDIA installer are normal:\n\t\"The Nouveau kernel driver is currently in use by your system...\"\n\t\"Installation has failed...\""
		echo -e "\nStage 2 completed but must be executed again. Please reboot and re-execute Stage 2 as root to install NVIDIA drivers"
	else
		echo -e "\nUnknown installation error occurred! Please check the /var/log/nvidia-installer.log file for more informaton"
	fi
else
	echo -e "\nNVIDIA drivers (v$VER) installed successfully! The following Warnings displayed by the NVIDIA installer are normal:\n\t\"One or more modprobe configuration files to disable Nouveau are already present...\""
	echo -e "\t\"nvidia-installer was forced to guess the X library path...\""
	echo -e "\nStage 2 completed successfully! Please execute Stage 3 as root\n"
	rm $TMP_DIR/NVIDIA
fi
unset VER
unset TMP_DIR
unset ORIG_DIR
###end stage 2###

