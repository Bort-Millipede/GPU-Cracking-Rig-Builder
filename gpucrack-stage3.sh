#! /bin/bash

# Stage 3 v0.2
# 5/X/2020

###start stage 3###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.1.2"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 3: install hashcat and John The Ripper with GPU support, and create wordlists directory (if not already created)\n"

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

TMP_DIR="gpucrack-tmp"
mkdir -p $TMP_DIR
ORIG_DIR=`pwd`
cd $TMP_DIR
TMP_DIR=`pwd`

#build/install hashcat#
HC=-1
git clone https://github.com/hashcat/hashcat.git
cd hashcat
git submodule update --init
make clean
make
./hashcat -I
if [ $? -eq 255 ]
then
	echo -e "Error occurred in hashcat while attempting to communicate with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following configuration parameter is added to this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
else
	make install
	echo -e "\nhashcat built and installed system-wide successfully!\n"
	HC=0
fi
#end build/install hashcat#
cd $TMP_DIR


#build/install john#
JTR=-1
apt install -y libssl-dev yasm libgmp-dev libpcap-dev libnss3-dev libkrb5-dev pkg-config libbz2-dev zlib1g-dev opencl-headers ocl-icd-libopencl1 ocl-icd-opencl-dev nvidia-opencl-dev

REXGEN=1
which rexgen > /dev/null 2>&1
if [ $? -eq 0 ]
then
	VER=`rexgen -v 2>&1 | head -n1 | cut -d"-" -f 2`
	if [ "$VER" == "2.0.8" ]
	then
		REXGEN=0
	fi
fi
if [ $REXGEN -eq 1 ]
then 
	apt install -y cmake bison flex
	git clone https://github.com/vay3t/rexgen-john.git rexgen
	cd rexgen/src/
	mkdir -p build
	cd build
	cmake ..
	make
	make install
	ldconfig
	cd $TMP_DIR
else
	echo -e "\nRexgen v2.0.8 already installed. Now building john"
fi
unset REXGEN

git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john
cd john/src
./configure --enable-rexgen
make clean
make -j4
../run/john --list=opencl-devices 2>&1 | grep "No OpenCL-capable "
if [ $? -eq 0 ]
then
	echo -e "Error occurred in john while attempting to communicate with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
else
	make install
	cd ../run
	mkdir -p /usr/share/john
	rm -rf /usr/share/john/*
	cp -prf * /usr/share/john/
	chmod -R a+w /usr/share/john
	echo -e "\njohn built and installed successfully to /usr/share/john!"
	JTR=0
fi
#end build/install john#

cd $ORIG_DIR

#create wordlists directory (if not already created)#
if [ ! -d /usr/share/wordlists ]
then
	mkdir -p /usr/share/wordlists
	chmod 777 /usr/share/wordlists
	echo -e "\nWordlists directory (/usr/share/wordlists) created!"
fi
#end create wordlists directory#

if [ $HC -eq 0 ]
then
	echo -e "\nhashcat built and installed system-wide successfully!"
	echo -e "To ensure all is working, hashcat installation should be tested as follows (will likely take a long time to complete!):"
	echo -e "\thashcat --benchmark"
else
	echo -e "hashcat built successfully but was unable to communicate with GPU device(s), so was not installed. Please resolve this issue then re-execute stage 3 as root to install hashcat"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
fi
if [ $JTR -eq 0 ]
then
	echo -e "\njohn built and installed to /usr/share/john successfully!"
	echo -e "To ensure all is working, john installation should be tested as follows (will likely take a long time to complete!):"
	echo -e "\tcd /usr/share/john\n\t./john --test=0 --format=opencl"
	echo -e "\t\tNOTE: This will only test john with GPU-enabled crack formats with the first GPU. To test additional GPUs, consult the John GPU page: https://openwall.info/wiki/john/GPU)"
else
	echo -e "john built successfully but was unable to communicate with GPU device(s), so was not installed. Please resolve this issue then re-execute stage 3 as root to install john"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
fi
if [ $HC -eq 0 ] && [ $JTR -eq 0 ]
then
	echo -e "\nStage 3 completed successfully! hashcat and john built and installed, and Wordlists directory created!"
	rm -rf $TMP_DIR
else
	echo -e "\nStage 3 completed with errors. Please resolve the issue(s), then re-execute stage 3 as root to install hashcat and john"
fi

unset TMP_DIR
unset ORIG_DIR
unset HC
unset JTR
###end stage 3###

