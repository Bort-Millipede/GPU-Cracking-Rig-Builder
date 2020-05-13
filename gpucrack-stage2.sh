#! /bin/bash

# Stage 2 v0.1.3
# 5/12/2020

###start stage 2###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.1.3"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 2: install NVIDIA driver prerequisites, remove all currently-installed \"nvidia\" packages (if any), and install latest NVIDIA drivers OR blacklist Nouveau drivers\n"

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
	echo -e "Possible error detected in the package manager! Ensure apt/dpkg are working properly and not in use by other processes, then try executing Stage 2 as root again!"
	exit 1
fi

VERBOSE=0
KEEPTMP=0
for var in "$@"
do
	if [ "$var" == "--verbose" ]
	then
		VERBOSE=1
	elif [ "$var" == "--keep-tmp" ]
	then
		KEEPTMP=1
	fi
done

ORIG_DIR=`pwd`
TMP_DIR="$ORIG_DIR/gpucrack-tmp"
mkdir -p $TMP_DIR

echo -e "Installing NVIDIA driver prerequisites, and removing all currently-installed \"nvidia\" packages (if any)."
if [ $VERBOSE -eq 1 ]
then
	apt-get install -y build-essential linux-headers-$(uname -r) wget
	apt-get remove --purge -y nvidia* >&/dev/null
else
	apt-get install -qq -y build-essential linux-headers-$(uname -r) wget
	apt-get remove --purge -qq -y nvidia* >&/dev/null
fi
echo -e "Prerequisites installed!"

VER=`wget -q -O - https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt | cut -d" " -f 1`

if [ ! -f "$TMP_DIR/NVIDIA" ]
then
	if [ $VERBOSE -eq 1 ]
	then
		wget -O $TMP_DIR/NVIDIA https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run
	else
		wget -q -O $TMP_DIR/NVIDIA https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run
	fi
fi

cd $TMP_DIR
chmod +x ./NVIDIA

echo -e "Attempting to install NVIDIA driver or blacklist Nouveau."
./NVIDIA --accept-license --disable-nouveau --no-questions --silent
if [ $? -eq 2 ]
then
	rm NVIDIA
	echo -e "\nBad checksum for downloaded NVIDIA installer! Please re-execute Stage 2 as root to re-download NVIDIA installer."
	echo -e "Alternatively, download the NVIDIA installer manually using the following command before re-executing Stage 2 as root:"
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
		if [ $VERBOSE -eq 1 ]
		then
			update-initramfs -u
		else
			update-initramfs -u >/dev/null
		fi
		echo -e "\nNouveau drivers blacklisted successfully!"
		echo -e "The following Errors displayed by the NVIDIA installer are normal:\n\t\"The Nouveau kernel driver is currently in use by your system...\"\n\t\"Installation has failed...\""
		echo -e "\nIf Stage 2 has been re-executed without rebooting first, the following Warning displayed by the NVIDIA installer is normal:\n\t\"One or more modprobe configuration files to disable Nouveau are already present...\""
		echo -e "\nStage 2 completed, but must be executed again! Please reboot and re-execute Stage 2 as root to install NVIDIA drivers"
	else
		echo -e "\nUnknown installation error occurred! Please check the /var/log/nvidia-installer.log file for more information, and re-execute Stage 2 as root when resolved."
	fi
else
	echo -e "\nNVIDIA drivers (v$VER) installed successfully! The following Warnings displayed by the NVIDIA installer are normal:\n\t\"One or more modprobe configuration files to disable Nouveau are already present...\""
	echo -e "\t\"nvidia-installer was forced to guess the X library path...\""
	if [ $KEEPTMP -eq 0 ]
	then
		rm -rf $TMP_DIR
	else
		echo -e "\nStage 2 temporary files not removed, located at: $TMP_DIR"
	fi
	echo -e "\nStage 2 completed successfully! Please execute Stage 3 as root\n"
fi
unset VER
unset TMP_DIR
unset ORIG_DIR
unset VERBOSE
###end stage 2###

