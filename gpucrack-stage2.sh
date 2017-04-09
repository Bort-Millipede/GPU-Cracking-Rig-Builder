#! /bin/bash

# Stage 2 v0.1
# 4/8/2017

###start stage 2###
echo -e "GPU Password Cracking Builder (NVIDIA only) v0.1"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 2: install build-essential and latest linux-headers, remove all currently installed nvidia packages, and install NVIDIA drivers OR blacklist nouveau\n"

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root! exiting..." 
   exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo "Error: this script is only compatible with 64-bit Debian-based Linux systems! exiting..."
	exit 1
fi

TMP_DIR="gpucrack-tmp"
mkdir -p $TMP_DIR
ORIG_DIR=`pwd`

aptitude install -y build-essential linux-headers-$(uname -r)

aptitude remove -y nvidia*

VER=(`wget -q -O - http://download.nvidia.com/XFree86/Linux-x86_64/latest.txt`)

if [ ! -e "$TMP_DIR/NVIDIA" ]
then
	wget http://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER.run -O $TMP_DIR/NVIDIA
fi

cd $TMP_DIR
chmod +x ./NVIDIA

./NVIDIA --accept-license --disable-nouveau --no-questions --silent
if [ $? -eq 2 ]
then
	rm NVIDIA
	echo -e "\nBad checksum for downloaded NVIDIA installer, please re-run stage 2 as root to re-download NVIDIA installer"
	cd $ORIG_DIR
	rm -r $TMP_DIR
	unset VER
	unset TMP_DIR
	unset ORIG_DIR
	exit 2
fi

cd $ORIG_DIR

modinfo nvidia > /dev/null 2>&1
if [ $? -ne 0 ]
then
	update-initramfs -u
	echo -e "\nNouveau drivers blacklisted! The following Errors displayed by the NVIDIA installer are normal:\n\t\"The Nouveau kernel driver is currently in use by your system...\"\n\t\"Installation has failed...\""
	echo -e "\nPlease reboot and re-execute stage 2 as root to install NVIDIA drivers"
else
	echo -e "\nStage 2 complete, NVIDIA drivers installed! The following Warnings displayed by the NVIDIA installer are normal:\n\t\"One or more modprobe configuration files to disable Nouveau are already present...\""
	echo -e "\t\"nvidia-installer was forced to guess the X library path...\"\n\t\"Unable to find a suitable destination to install 32-bit compatibility libraries...\""
	echo -e "\nPlease execute stage 3 as root"
	rm -rf $TMP_DIR
fi
unset VER
unset TMP_DIR
unset ORIG_DIR
###end stage 2###