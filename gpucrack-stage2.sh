#! /bin/bash

# Stage 2 v0.2
# 7/XX/2021

###start Stage 2###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.2"
echo -e "Jeffrey Cap (Bort-Millipede)"
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
	echo -e "Possible error detected in the package manager! Ensure apt/dpkg are working properly and are not in use by other processes, then try executing Stage 2 as root again!"
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

echo -e "Installing NVIDIA driver prerequisites, and removing all currently-installed \"nvidia\" packages (if any).\n"
if [ $VERBOSE -eq 1 ]
then
	apt-get install -y build-essential linux-headers-$(uname -r) wget
	apt-get remove --purge -y nvidia* >&/dev/null
else
	apt-get install -qq -y build-essential linux-headers-$(uname -r) wget
	apt-get remove --purge -qq -y nvidia* >&/dev/null
fi
echo -e "Prerequisites installed!\n"

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

echo -e "Attempting to install NVIDIA driver or blacklist Nouveau.\n"
NVIDIA_LOG=$TMP_DIR/nvidia-installer.log
if [ -f "$NVIDIA_LOG" ]
then
	NVIDIA_LOG=$TMP_DIR/nvidia-installer_second.log
fi

./NVIDIA --disable-nouveau --no-questions --silent --log-file-name=$NVIDIA_LOG
if [ $? -eq 2 ]
then
	rm NVIDIA
	echo -e "\nBad checksum for downloaded NVIDIA installer! Please re-execute Stage 2 as root to re-download NVIDIA installer."
	echo -e "Alternatively, download the NVIDIA installer manually using the following command before re-executing Stage 2 as root:"
	if [ $VERBOSE -eq 1 ]
	then
		echo -e "\twget -O $TMP_DIR/NVIDIA https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run\n"
	else
		echo -e "\twget -q -O $TMP_DIR/NVIDIA https://us.download.nvidia.com/XFree86/Linux-x86_64/$VER/NVIDIA-Linux-x86_64-$VER-no-compat32.run\n"
	fi
	cd $ORIG_DIR
	unset VER
	unset TMP_DIR
	unset ORIG_DIR
	unset NVIDIA_LOG
	exit 2
elif [ $? -eq 1 ]
then
	grep "WARNING: You do not appear to have an NVIDIA GPU supported by" $NVIDIA_LOG >/dev/null
	W=$?
	grep "ERROR: Unable to load the kernel module 'nvidia.ko'" $NVIDIA_LOG >/dev/null
	E=$?
	if [ $W -eq 0 ] || [ $E -eq 0 ]
	then
		echo -e "\nNVIDIA GPU(s) not detected by NVIDIA installer, as indicated by the following displayed messages:"
		echo -e "\t\"WARNING: You do not appear to have an NVIDIA GPU supported by...\"\n\t\"ERROR: Unable to load the kernel module 'nvidia.ko'...\""
		echo -e "Please verify the proper installation of NVIDIA GPU(s) and reboot before re-executing Stage 2 as root!\n"
		cd $ORIG_DIR
		unset VER
		unset TMP_DIR
		unset ORIG_DIR
		unset NVIDIA_LOG
		unset W
		unset E
		exit 3
	fi
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
		echo -e "The following messages displayed by the NVIDIA installer are normal:\n\t\"ERROR: The Nouveau kernel driver is currently in use by your system...\"\n\t\"ERROR: Installation has failed...\""
		grep "WARNING: One or more modprobe configuration files to disable Nouveau are already present at" $NVIDIA_LOG >/dev/null
		if [ $? -eq 0 ]
		then
			echo -e "\nAdditionally, if Stage 2 has been re-executed without rebooting first, the following message displayed by the NVIDIA installer is normal:"
			echo -e "\t\"WARNING: One or more modprobe configuration files to disable Nouveau are already present at...\""
		fi
		echo -e "\nStage 2 completed, but must be executed again! Please reboot and re-execute Stage 2 as root to install NVIDIA drivers!\n"
	else
		echo -e "\nUnknown installation error occurred! Please check the $NVIDIA_LOG file for more information, and re-execute Stage 2 as root when resolved.\n"
	fi
else
	echo -e "\nNVIDIA drivers (v$VER) installed successfully! The following messages displayed by the NVIDIA installer are normal:"
	echo -e "\t\"WARNING: One or more modprobe configuration files to disable Nouveau are already present at...\"\n\t\"WARNING: nvidia-installer was forced to guess the X library path...\""
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
unset NVIDIA_LOG
###end Stage 2###

